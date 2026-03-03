import Foundation
import SwiftData

@Model
final class CachedMessage {
    @Attribute(.unique) var eventId: String
    var sessionId: String
    var type: String?
    var message: String
    var timestamp: String?
    var origin: String?
    var userId: String?
    var username: String?
    var createdAt: String?
    var lastFetched: Date = Date()

    var session: CachedSession?

    init(eventId: String, sessionId: String, message: String) {
        self.eventId = eventId
        self.sessionId = sessionId
        self.message = message
    }

    func update(from api: DevinMessage, sessionId: String) {
        self.sessionId = sessionId
        self.type = api.type
        self.message = api.message
        self.timestamp = api.timestamp
        self.origin = api.origin
        self.userId = api.userId
        self.username = api.username
        self.createdAt = api.createdAt
        self.lastFetched = Date()
    }

    func toAPIModel() -> DevinMessage {
        DevinMessage(
            eventId: eventId,
            type: type,
            message: message,
            timestamp: timestamp,
            origin: origin,
            userId: userId,
            username: username,
            createdAt: createdAt
        )
    }
}
