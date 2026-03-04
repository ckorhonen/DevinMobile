import Foundation

struct Playbook: Codable, Identifiable, Hashable, Sendable {
    static func == (lhs: Playbook, rhs: Playbook) -> Bool { lhs.playbookId == rhs.playbookId }
    func hash(into hasher: inout Hasher) { hasher.combine(playbookId) }

    let playbookId: String
    let title: String
    let body: String
    let macro: String?
    let accessType: String?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?

    var id: String { playbookId }
}

struct CreatePlaybookRequest: Encodable, Sendable {
    let title: String
    let body: String
    let macro: String?
}

struct UpdatePlaybookRequest: Encodable, Sendable {
    let title: String?
    let body: String?
    let macro: String?
}
