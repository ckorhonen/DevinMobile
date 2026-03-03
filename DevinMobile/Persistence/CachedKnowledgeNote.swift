import Foundation
import SwiftData

@Model
final class CachedKnowledgeNote {
    @Attribute(.unique) var noteId: String
    var name: String
    var body: String
    var triggerDescription: String?
    var trigger: String?
    var folderId: String?
    var parentFolderId: String?
    var accessType: String?
    var createdAt: String?
    var updatedAt: String?
    var lastFetched: Date = Date()

    init(noteId: String, name: String, body: String) {
        self.noteId = noteId
        self.name = name
        self.body = body
    }

    func update(from api: KnowledgeNote) {
        self.name = api.name
        self.body = api.body
        self.triggerDescription = api.triggerDescription
        self.trigger = api.trigger
        self.folderId = api.folderId
        self.parentFolderId = api.parentFolderId
        self.accessType = api.accessType
        self.createdAt = api.createdAt
        self.updatedAt = api.updatedAt
        self.lastFetched = Date()
    }

    func toAPIModel() -> KnowledgeNote {
        KnowledgeNote(
            noteId: noteId,
            name: name,
            body: body,
            triggerDescription: triggerDescription,
            trigger: trigger,
            folderId: folderId,
            parentFolderId: parentFolderId,
            accessType: accessType,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
