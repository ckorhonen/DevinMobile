import Foundation

struct PendingAttachment: Identifiable, Sendable {
    let id = UUID()
    let data: Data
    let fileName: String
    let mimeType: String
    let thumbnail: Data?

    var isImage: Bool { mimeType.hasPrefix("image/") }

    var displayName: String {
        fileName.count > 20 ? String(fileName.prefix(17)) + "..." : fileName
    }
}

struct SessionAttachment: Codable, Identifiable, Sendable {
    let attachmentId: String
    let name: String
    let url: String
    let source: String?
    let contentType: String?

    var id: String { attachmentId }
}
