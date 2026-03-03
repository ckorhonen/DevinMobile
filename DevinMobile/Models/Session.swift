import Foundation

// MARK: - Session Status (v1)

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

// MARK: - PR State

enum PRState: String, Codable, Sendable {
    case open
    case closed
    case merged

    var label: String {
        switch self {
        case .open: "Open"
        case .merged: "Merged"
        case .closed: "Closed"
        }
    }
}

// MARK: - V3 Pull Request

struct V3PullRequest: Codable, Sendable, Hashable, Identifiable {
    let prUrl: String
    let prState: String?

    var id: String { prUrl }

    var resolvedState: PRState {
        guard let prState else { return .open }
        return PRState(rawValue: prState) ?? .open
    }

    /// Parses the PR URL into GitHub components (owner, repo, number).
    var gitHubComponents: PullRequest.GitHubComponents? {
        guard let url = URL(string: prUrl),
              url.host == "github.com" || url.host == "www.github.com"
        else { return nil }

        let parts = url.pathComponents
        guard parts.count >= 5,
              parts[3] == "pull",
              let prNumber = Int(parts[4])
        else { return nil }

        return PullRequest.GitHubComponents(owner: parts[1], repo: parts[2], number: prNumber)
    }

    var shortRepoName: String? {
        gitHubComponents?.repo
    }

    var repoFullName: String? {
        guard let c = gitHubComponents else { return nil }
        return "\(c.owner)/\(c.repo)"
    }

    var displayLabel: String? {
        guard let number = gitHubComponents?.number else { return nil }
        return "PR #\(number)"
    }

    var gitHubAppURL: URL? {
        guard var components = URLComponents(string: prUrl) else { return nil }
        components.scheme = "github"
        return components.url
    }

    var gitHubWebURL: URL? {
        URL(string: prUrl)
    }
}

// MARK: - Session (v1 canonical model)

struct Session: Codable, Identifiable, Hashable, Sendable {
    static func == (lhs: Session, rhs: Session) -> Bool { lhs.sessionId == rhs.sessionId }
    func hash(into hasher: inout Hasher) { hasher.combine(sessionId) }

    let sessionId: String
    let status: String?
    var statusEnum: String?
    let title: String?
    let createdAt: String?
    let updatedAt: String?
    let acusConsumed: Double?
    let url: String?
    let pullRequest: PullRequest?
    let structuredOutput: [String: AnyCodableValue]?
    let playbookId: String?
    let tags: [String]?

    // V3 fields
    let pullRequests: [V3PullRequest]?
    let isArchived: Bool?

    var id: String { sessionId }

    var resolvedStatus: SessionStatus {
        if let statusEnum, let s = SessionStatus(rawValue: statusEnum) { return s }
        if let status, let s = SessionStatus(rawValue: status) { return s }
        return .running
    }

    var isActive: Bool {
        let s = resolvedStatus
        return s == .running || s == .working || s == .blocked || s == .resumed || s == .resumeRequested || s == .resumeRequestedFrontend
    }

    /// Unified access to all PRs — prefers v3 array, falls back to v1 singular.
    var allPullRequests: [V3PullRequest] {
        if let prs = pullRequests, !prs.isEmpty { return prs }
        if let pr = pullRequest, let url = pr.url {
            return [V3PullRequest(prUrl: url, prState: nil)]
        }
        return []
    }

    var primaryPullRequest: V3PullRequest? {
        allPullRequests.first
    }

    /// Extracts "owner/repo" from the first PR URL.
    var repoFullName: String? {
        primaryPullRequest?.repoFullName
    }

    func hasContentChanges(from other: Session) -> Bool {
        self.status != other.status
            || self.statusEnum != other.statusEnum
            || self.title != other.title
            || self.updatedAt != other.updatedAt
            || self.acusConsumed != other.acusConsumed
            || self.tags != other.tags
    }
}

// MARK: - V1 Pull Request

struct PullRequest: Codable, Sendable {
    let url: String?
    let title: String?
    let number: Int?
}

// MARK: - V3 Session Item (for decoding v3 list response)

struct V3SessionItem: Codable, Sendable {
    let sessionId: String
    let status: String?
    let statusDetail: String?
    let title: String?
    let createdAt: Int?
    let updatedAt: Int?
    let acusConsumed: Double?
    let url: String?
    let pullRequests: [V3PullRequest]?
    let isArchived: Bool?
    let playbookId: String?
    let tags: [String]?

    func toSession() -> Session {
        let mappedStatus = Self.mapV3Status(status: status, detail: statusDetail)

        let createdAtISO = createdAt.map {
            Date(timeIntervalSince1970: Double($0)).iso8601String
        }
        let updatedAtISO = updatedAt.map {
            Date(timeIntervalSince1970: Double($0)).iso8601String
        }

        // Build a v1 PullRequest from the first v3 PR for backwards compat
        var legacyPR: PullRequest?
        if let first = pullRequests?.first {
            let components = first.gitHubComponents
            legacyPR = PullRequest(
                url: first.prUrl,
                title: nil,
                number: components?.number
            )
        }

        return Session(
            sessionId: sessionId,
            status: mappedStatus,
            statusEnum: mappedStatus,
            title: title,
            createdAt: createdAtISO,
            updatedAt: updatedAtISO,
            acusConsumed: acusConsumed,
            url: url,
            pullRequest: legacyPR,
            structuredOutput: nil,
            playbookId: playbookId,
            tags: tags,
            pullRequests: pullRequests,
            isArchived: isArchived
        )
    }

    /// Maps v3 status + status_detail → v1 SessionStatus raw values.
    private static func mapV3Status(status: String?, detail: String?) -> String {
        switch (status, detail) {
        case ("running", "working"): return "working"
        case ("running", "waiting_for_user"): return "blocked"
        case ("running", "waiting_for_approval"): return "blocked"
        case ("running", "finished"): return "finished"
        case ("running", _): return "working"
        case ("exit", _): return "finished"
        case ("error", _): return "stopped"
        case ("suspended", "user_request"): return "suspend_requested"
        case ("suspended", _): return "expired"
        case ("resuming", _): return "resume_requested"
        case ("new", _), ("claimed", _): return "running"
        default: return status ?? "running"
        }
    }
}

// MARK: - Date ISO 8601 Output

extension Date {
    var iso8601String: String {
        Date.iso8601Full.string(from: self)
    }
}

// MARK: - V1 Response Wrappers

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
