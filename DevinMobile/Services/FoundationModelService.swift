import Foundation
import FoundationModels

actor FoundationModelService {
    static let shared = FoundationModelService()

    private init() {}

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: - Session Category

    func categorize(title: String?, messages: [DevinMessage]) async throws -> SessionCategory {
        let session = LanguageModelSession {
            """
            You are a classifier. Given a software engineering session title and opening messages, \
            classify the session into exactly one category. Focus on the primary intent of the user's request.
            """
        }

        let prompt = buildCategoryPrompt(title: title, messages: messages)
        let response = try await session.respond(to: prompt, generating: SessionCategory.self)
        return response.content
    }

    // MARK: - Session Summary

    func summarize(title: String?, messages: [DevinMessage]) async throws -> SessionSummary {
        let session = LanguageModelSession {
            """
            You are a summarizer. Given a software engineering session, produce a concise 1-2 sentence \
            summary of what was accomplished or discussed. Focus on outcomes and key decisions.
            """
        }

        let prompt = buildSummaryPrompt(title: title, messages: messages)
        let response = try await session.respond(to: prompt, generating: SessionSummary.self)
        return response.content
    }

    // MARK: - Knowledge Note Draft

    func draftKnowledgeNote(title: String?, messages: [DevinMessage]) async throws -> KnowledgeNoteDraft {
        let session = LanguageModelSession {
            """
            You are an assistant that extracts reusable knowledge from software engineering conversations. \
            Given a session between a user and an AI coding agent, extract a knowledge note that captures \
            patterns, instructions, or best practices that would be useful for future sessions. \
            The trigger should describe when this knowledge applies. \
            The body should contain actionable instructions, not a summary of the conversation.
            """
        }

        let prompt = buildKnowledgePrompt(title: title, messages: messages)
        let response = try await session.respond(to: prompt, generating: KnowledgeNoteDraft.self)
        return response.content
    }

    // MARK: - Prompt Building

    private func buildCategoryPrompt(title: String?, messages: [DevinMessage]) -> String {
        var parts: [String] = []

        if let title, !title.isEmpty {
            parts.append("Session title: \(title)")
        }

        // Use first 3 user messages for category signal
        let userMessages = messages
            .filter { $0.resolvedSource == .user }
            .prefix(3)

        for msg in userMessages {
            let trimmed = String(msg.message.prefix(500))
            parts.append("User: \(trimmed)")
        }

        parts.append("Classify this session.")
        return parts.joined(separator: "\n\n")
    }

    private func buildSummaryPrompt(title: String?, messages: [DevinMessage]) -> String {
        var parts: [String] = []

        if let title, !title.isEmpty {
            parts.append("Session title: \(title)")
        }

        // Use last 10 messages for summary (conclusion is most informative)
        let recentMessages = messages.suffix(10)

        for msg in recentMessages {
            let source = msg.resolvedSource == .user ? "User" : "Devin"
            let trimmed = String(msg.message.prefix(300))
            parts.append("\(source): \(trimmed)")
        }

        parts.append("Summarize what was accomplished in this session.")
        return parts.joined(separator: "\n\n")
    }

    private func buildKnowledgePrompt(title: String?, messages: [DevinMessage]) -> String {
        var parts: [String] = []

        if let title, !title.isEmpty {
            parts.append("Session title: \(title)")
        }

        // Use a spread of messages — first 3 for context, last 7 for outcomes
        // Deduplicate by index to handle messages with nil eventId
        let count = messages.count
        let firstRange = 0..<min(3, count)
        let lastRange = max(0, count - 7)..<count
        let selectedIndices = Set(firstRange).union(Set(lastRange)).sorted()
        let selected = selectedIndices.map { messages[$0] }

        for msg in selected {
            let source = msg.resolvedSource == .user ? "User" : "Devin"
            let trimmed = String(msg.message.prefix(400))
            parts.append("\(source): \(trimmed)")
        }

        parts.append("Extract a reusable knowledge note from this conversation.")
        return parts.joined(separator: "\n\n")
    }
}
