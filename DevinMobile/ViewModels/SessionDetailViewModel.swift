import Foundation
import SwiftUI

@Observable
@MainActor
final class SessionDetailViewModel {
    let sessionId: String
    var session: Session?
    var messages: [DevinMessage] = []
    var loadingState: LoadingState<[DevinMessage]> = .idle
    var messageText = ""
    var isSending = false
    var isUploading = false
    var pendingAttachments: [PendingAttachment] = []
    var toast: ToastItem?
    var showTerminateConfirmation = false
    var isTerminating = false

    // AI-generated insights
    var category: SessionCategory?
    var summary: String?
    var isGeneratingAI = false
    var knowledgeNoteDraft: KnowledgeNoteDraft?
    var showKnowledgeNoteEditor = false
    var isGeneratingKnowledgeNote = false

    private var pollingTask: Task<Void, Never>?
    private var persistence: PersistenceManager?

    /// Groups consecutive messages by the same source into "turns"
    var messageTurns: [[DevinMessage]] {
        guard !messages.isEmpty else { return [] }
        var turns: [[DevinMessage]] = []
        var currentTurn: [DevinMessage] = [messages[0]]

        for i in 1..<messages.count {
            if messages[i].resolvedSource == messages[i - 1].resolvedSource {
                currentTurn.append(messages[i])
            } else {
                turns.append(currentTurn)
                currentTurn = [messages[i]]
            }
        }
        turns.append(currentTurn)
        return turns
    }

    var isSessionActive: Bool {
        session?.isActive ?? false
    }

    var allPullRequests: [V3PullRequest] {
        session?.allPullRequests ?? []
    }

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    func loadSessionAndMessages() async {
        // Show cached messages immediately if available
        if let persistence, messages.isEmpty {
            let cached = persistence.cachedMessages(for: sessionId)
            if !cached.isEmpty {
                messages = cached
                loadingState = .loaded(messages)
            }
        }

        if messages.isEmpty {
            loadingState = .loading
        }

        do {
            // v1: GET /sessions/{id} returns session + messages inline
            let detail: SessionDetailResponse = try await APIClient.shared.perform(
                .getSession(id: sessionId)
            )
            session = Session(
                sessionId: detail.sessionId,
                status: detail.status,
                statusEnum: detail.statusEnum,
                title: detail.title,
                createdAt: detail.createdAt,
                updatedAt: detail.updatedAt,
                acusConsumed: detail.acusConsumed,
                url: detail.url,
                pullRequest: detail.pullRequest,
                structuredOutput: detail.structuredOutput,
                playbookId: detail.playbookId,
                tags: detail.tags,
                pullRequests: nil,
                isArchived: nil
            )
            messages = detail.messages ?? []
            loadingState = .loaded(messages)

            persistence?.upsertMessages(messages, sessionId: sessionId)
        } catch let error as DevinAPIError {
            if messages.isEmpty {
                loadingState = .error(ErrorInfo(error))
            } else {
                toast = .error(error.localizedDescription)
            }
        } catch {
            if messages.isEmpty {
                loadingState = .error(ErrorInfo(message: error.localizedDescription))
            } else {
                toast = .error(error.localizedDescription)
            }
        }
    }

    func addAttachment(_ attachment: PendingAttachment) {
        guard pendingAttachments.count < 5 else {
            toast = .error("Maximum 5 attachments")
            return
        }
        pendingAttachments.append(attachment)
    }

    func removeAttachment(id: UUID) {
        pendingAttachments.removeAll { $0.id == id }
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !pendingAttachments.isEmpty
    }

    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = pendingAttachments
        guard !text.isEmpty || !attachments.isEmpty else { return }

        isSending = true
        messageText = ""
        pendingAttachments = []

        // Upload attachments first
        var attachmentURLs: [String] = []
        if !attachments.isEmpty {
            isUploading = true
            for attachment in attachments {
                do {
                    let url = try await APIClient.shared.uploadFile(
                        .uploadAttachment,
                        fileData: attachment.data,
                        fileName: attachment.fileName,
                        mimeType: attachment.mimeType
                    )
                    attachmentURLs.append(url)
                } catch let error as DevinAPIError {
                    toast = .error("Upload failed: \(error.localizedDescription)")
                    messageText = text
                    pendingAttachments = attachments
                    isSending = false
                    isUploading = false
                    return
                } catch {
                    toast = .error("Upload failed: \(error.localizedDescription)")
                    messageText = text
                    pendingAttachments = attachments
                    isSending = false
                    isUploading = false
                    return
                }
            }
            isUploading = false
        }

        // Build message with attachment references
        var messageParts: [String] = []
        if !text.isEmpty { messageParts.append(text) }
        for url in attachmentURLs {
            messageParts.append("ATTACHMENT:\"\(url)\"")
        }
        let finalMessage = messageParts.joined(separator: "\n")

        let request = SendMessageRequest(message: finalMessage)
        do {
            try await APIClient.shared.performVoid(
                .sendMessage(sessionId: sessionId), body: request
            )
            await loadSessionAndMessages()
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
            messageText = text
        } catch {
            toast = .error(error.localizedDescription)
            messageText = text
        }

        isSending = false
    }

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                guard let self, self.isSessionActive else { break }
                await self.loadSessionAndMessages()
            }
        }
    }

    func terminateSession() async {
        isTerminating = true
        defer { isTerminating = false }

        do {
            try await APIClient.shared.performVoid(.deleteSession(id: sessionId))
            session = session.map {
                var updated = $0
                updated.statusEnum = SessionStatus.stopped.rawValue
                return updated
            }
            if let persistence, let updated = session {
                persistence.upsertSessions([updated])
            }
            stopPolling()
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
        } catch {
            toast = .error(error.localizedDescription)
        }
    }

    // MARK: - AI Insights

    func generateAIInsights() async {
        // Category is stable (intent doesn't change), so always use cache if available.
        // Summary reflects outcomes, so only use cache for completed sessions.
        if let persistence {
            let cached = persistence.cachedSessionAI(for: sessionId)
            if let cachedCategory = cached.category {
                category = cachedCategory
            }
            if !isSessionActive, let cachedSummary = cached.summary {
                summary = cachedSummary
            }
        }

        // For completed sessions, skip generation if both are already cached.
        if !isSessionActive && category != nil && summary != nil { return }

        guard await FoundationModelService.shared.isAvailable else { return }
        guard !messages.isEmpty else { return }

        isGeneratingAI = true
        defer { isGeneratingAI = false }

        let title = session?.title
        let msgs = messages
        let needsCategory = category == nil
        let needsSummary = summary == nil

        // Generate category and summary concurrently
        async let categoryResult: SessionCategory? = needsCategory
            ? (try? await FoundationModelService.shared.categorize(title: title, messages: msgs))
            : nil

        async let summaryResult: SessionSummary? = needsSummary
            ? (try? await FoundationModelService.shared.summarize(title: title, messages: msgs))
            : nil

        let (newCategory, newSummary) = await (categoryResult, summaryResult)

        if let newCategory {
            category = newCategory
        }
        if let newSummary {
            summary = newSummary.text
        }

        // Always persist category; only persist summary for completed sessions
        persistence?.updateSessionAI(
            sessionId: sessionId,
            category: (newCategory ?? category)?.rawValue,
            summary: isSessionActive ? nil : (newSummary?.text ?? summary)
        )
    }

    func generateKnowledgeNoteDraft() async {
        guard await FoundationModelService.shared.isAvailable else { return }
        guard !messages.isEmpty else { return }

        isGeneratingKnowledgeNote = true
        defer { isGeneratingKnowledgeNote = false }

        do {
            let draft = try await FoundationModelService.shared.draftKnowledgeNote(
                title: session?.title,
                messages: messages
            )
            knowledgeNoteDraft = draft
            showKnowledgeNoteEditor = true
        } catch {
            toast = .error("Failed to generate knowledge note")
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
