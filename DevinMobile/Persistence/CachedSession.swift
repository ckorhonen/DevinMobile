import Foundation
import SwiftData

@Model
final class CachedSession {
    @Attribute(.unique) var sessionId: String
    var status: String?
    var statusEnum: String?
    var title: String?
    var createdAt: String?
    var updatedAt: String?
    var acusConsumed: Double?
    var url: String?
    var prURL: String?
    var prTitle: String?
    var prNumber: Int?
    var playbookId: String?
    var tagsJSON: String?

    // V3 fields
    var pullRequestsJSON: String?
    var isArchivedFromAPI: Bool = false

    // Local-only fields
    var isHidden: Bool = false
    var isArchived: Bool = false
    var lastFetched: Date = Date()
    var lastViewedAt: Date?

    // AI-generated fields (local-only, not overwritten by API)
    var generatedCategory: String?
    var generatedSummary: String?

    @Relationship(deleteRule: .cascade, inverse: \CachedMessage.session)
    var messages: [CachedMessage] = []

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    func update(from api: Session) {
        self.status = api.status
        self.statusEnum = api.statusEnum
        self.title = api.title
        self.createdAt = api.createdAt
        self.updatedAt = api.updatedAt
        self.acusConsumed = api.acusConsumed
        self.url = api.url
        self.prURL = api.pullRequest?.url
        self.prTitle = api.pullRequest?.title
        self.prNumber = api.pullRequest?.number
        self.playbookId = api.playbookId
        if let tags = api.tags, let data = try? JSONEncoder().encode(tags) {
            self.tagsJSON = String(data: data, encoding: .utf8)
        } else {
            self.tagsJSON = nil
        }
        if let prs = api.pullRequests, let data = try? JSONEncoder().encode(prs) {
            self.pullRequestsJSON = String(data: data, encoding: .utf8)
        } else {
            self.pullRequestsJSON = nil
        }
        if let archived = api.isArchived {
            self.isArchivedFromAPI = archived
        }
        self.lastFetched = Date()
    }

    func toAPIModel() -> Session {
        var tags: [String]?
        if let json = tagsJSON, let data = json.data(using: .utf8) {
            tags = try? JSONDecoder().decode([String].self, from: data)
        }
        var pr: PullRequest?
        if prURL != nil || prTitle != nil || prNumber != nil {
            pr = PullRequest(url: prURL, title: prTitle, number: prNumber)
        }
        var v3PRs: [V3PullRequest]?
        if let json = pullRequestsJSON, let data = json.data(using: .utf8) {
            v3PRs = try? JSONDecoder().decode([V3PullRequest].self, from: data)
        }
        return Session(
            sessionId: sessionId,
            status: status,
            statusEnum: statusEnum,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            acusConsumed: acusConsumed,
            url: url,
            pullRequest: pr,
            structuredOutput: nil,
            playbookId: playbookId,
            tags: tags,
            pullRequests: v3PRs,
            isArchived: isArchived || isArchivedFromAPI
        )
    }
}
