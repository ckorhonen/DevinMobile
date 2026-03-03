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
    var toast: ToastItem?
    var showTerminateConfirmation = false
    var isTerminating = false

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
                tags: detail.tags
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

    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        messageText = ""

        let request = SendMessageRequest(message: text)
        do {
            try await APIClient.shared.performVoid(
                .sendMessage(sessionId: sessionId), body: request
            )
            // Refresh to get the updated messages
            await loadSessionAndMessages()
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
            messageText = text // Restore on failure
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

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
