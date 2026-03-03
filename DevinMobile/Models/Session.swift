import Foundation

enum SessionStatus: String, Codable, CaseIterable, Sendable {
    case running
    case working
    case blocked
    case stopped
    case finished
    case expired
    case suspendRequested = "suspend_requested"
    case suspendRequestedFrontend = "suspend_requested_frontend"
    case resumeRequested = "resume_requested"
    case resumeRequestedFrontend = "resume_requested_frontend"
    case resumed
}

struct Session: Codable, Identifiable, Hashable, Sendable {
    static func == (lhs: Session, rhs: Session) -> Bool { lhs.sessionId == rhs.sessionId }
    func hash(into hasher: inout Hasher) { hasher.combine(sessionId) }

    let sessionId: String
    let status: String?
    let statusEnum: String?
    let title: String?
    let createdAt: String?
    let updatedAt: String?
    let acusConsumed: Double?
    let url: String?
    let pullRequest: PullRequest?
    let structuredOutput: [String: AnyCodableValue]?
    let playbookId: String?
    let tags: [String]?

    var id: String { sessionId }

    var resolvedStatus: SessionStatus {
        // Try statusEnum first, then status
        if let statusEnum, let s = SessionStatus(rawValue: statusEnum) { return s }
        if let status, let s = SessionStatus(rawValue: status) { return s }
        return .running
    }

    var isActive: Bool {
        let s = resolvedStatus
        return s == .running || s == .working || s == .blocked || s == .resumed || s == .resumeRequested || s == .resumeRequestedFrontend
    }

    /// Compares mutable fields to detect content changes.
    /// Unlike `==` which only compares `sessionId` for identity,
    /// this checks fields that can change over a session's lifetime.
    func hasContentChanges(from other: Session) -> Bool {
        self.status != other.status
            || self.statusEnum != other.statusEnum
            || self.title != other.title
            || self.updatedAt != other.updatedAt
            || self.acusConsumed != other.acusConsumed
            || self.tags != other.tags
    }
}

struct PullRequest: Codable, Sendable {
    let url: String?
    let title: String?
    let number: Int?
}

/// Wrapper for GET /v1/sessions response
struct SessionListResponse: Decodable, Sendable {
    let sessions: [Session]
}

struct CreateSessionRequest: Encodable, Sendable {
    let prompt: String
    let playbookId: String?
    let title: String?
    let maxAcuLimit: Int?
}

struct CreateSessionResponse: Decodable, Sendable {
    let sessionId: String
    let url: String?
    let isNewSession: Bool?
}

