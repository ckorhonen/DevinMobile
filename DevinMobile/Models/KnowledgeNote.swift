import Foundation

struct KnowledgeNote: Codable, Identifiable, Sendable {
    let noteId: String?
    let name: String
    let body: String
    let triggerDescription: String?
    let trigger: String?
    let folderId: String?
    let parentFolderId: String?
    let accessType: String?
    let createdAt: String?
    let updatedAt: String?

    var id: String { noteId ?? UUID().uuidString }

    var resolvedTrigger: String {
        triggerDescription ?? trigger ?? ""
    }
}

struct KnowledgeListResponse: Decodable, Sendable {
    let knowledge: [KnowledgeNote]
}

struct CreateNoteRequest: Encodable, Sendable {
    let name: String
    let body: String
    let triggerDescription: String
}

struct UpdateNoteRequest: Encodable, Sendable {
    let name: String?
    let body: String?
    let triggerDescription: String?
}
