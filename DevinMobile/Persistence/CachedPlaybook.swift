import Foundation
import SwiftData

@Model
final class CachedPlaybook {
    @Attribute(.unique) var playbookId: String
    var title: String
    var body: String
    var macro: String?
    var accessType: String?
    var createdBy: String?
    var createdAt: String?
    var updatedAt: String?
    var lastFetched: Date = Date()

    init(playbookId: String, title: String, body: String) {
        self.playbookId = playbookId
        self.title = title
        self.body = body
    }

    func update(from api: Playbook) {
        self.title = api.title
        self.body = api.body
        self.macro = api.macro
        self.accessType = api.accessType
        self.createdBy = api.createdBy
        self.createdAt = api.createdAt
        self.updatedAt = api.updatedAt
        self.lastFetched = Date()
    }

    func toAPIModel() -> Playbook {
        Playbook(
            playbookId: playbookId,
            title: title,
            body: body,
            macro: macro,
            accessType: accessType,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
