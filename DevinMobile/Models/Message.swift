import Foundation

struct DevinMessage: Codable, Identifiable, Sendable {
    let eventId: String?
    let type: String?
    let message: String
    let timestamp: String?
    let origin: String?
    let userId: String?
    let username: String?
    let createdAt: String?

    var id: String { eventId ?? UUID().uuidString }

    var resolvedSource: MessageSource {
        // v1 uses "origin" — user messages have origin like "slack", "api", "frontend"
        // devin messages have origin like "devin", "machine" or type differentiates
        if let origin {
            let lower = origin.lowercased()
            if lower == "devin" || lower == "machine" {
                return .devin
            }
            return .user
        }
        // Fallback to type field
        if let type {
            let lower = type.lowercased()
            if lower.contains("user") || lower.contains("human") {
                return .user
            }
        }
        return .devin
    }

    var resolvedTimestamp: String? {
        timestamp ?? createdAt
    }
}

enum MessageSource: String, Codable, Sendable {
    case user
    case devin
}

struct SendMessageRequest: Encodable, Sendable {
    let message: String
}

/// V1 GET /sessions/{id} returns messages inline
struct SessionDetailResponse: Decodable, Sendable {
    let sessionId: String
    let status: String?
    let statusEnum: String?
    let title: String?
    let createdAt: String?
    let updatedAt: String?
    let url: String?
    let pullRequest: PullRequest?
    let acusConsumed: Double?
    let messages: [DevinMessage]?
    let structuredOutput: [String: AnyCodableValue]?
    let playbookId: String?
    let tags: [String]?
}
