import Foundation
import SwiftData

@Observable
@MainActor
final class PersistenceManager {
    private let context: ModelContext

    private let staleDuration: TimeInterval = 5 * 60
    private let messageRetentionDays: Int = 7
    private let maxMessagesPerSession: Int = 500

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Sessions

    func cachedSessions() -> [Session] {
        var descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate { !$0.isHidden && !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toAPIModel() }
    }

    func isSessionCacheStale() -> Bool {
        var descriptor = FetchDescriptor<CachedSession>(
            sortBy: [SortDescriptor(\.lastFetched, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let newest = try? context.fetch(descriptor).first else { return true }
        return newest.lastFetched.timeIntervalSinceNow < -staleDuration
    }

    func upsertSessions(_ sessions: [Session]) {
        for apiSession in sessions {
            let sessionId = apiSession.sessionId
            let descriptor = FetchDescriptor<CachedSession>(
                predicate: #Predicate<CachedSession> { $0.sessionId == sessionId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: apiSession)
            } else {
                let cached = CachedSession(sessionId: apiSession.sessionId)
                cached.update(from: apiSession)
                context.insert(cached)
            }
        }
        try? context.save()
    }

    func cachedArchivedSessions() -> [Session] {
        let descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate { $0.isArchived && !$0.isHidden },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toAPIModel() }
    }

    func setSessionArchived(_ sessionId: String, archived: Bool) {
        let descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate<CachedSession> { $0.sessionId == sessionId }
        )
        if let session = try? context.fetch(descriptor).first {
            session.isArchived = archived
            try? context.save()
        }
    }

    func setSessionHidden(_ sessionId: String, hidden: Bool) {
        let descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate<CachedSession> { $0.sessionId == sessionId }
        )
        if let session = try? context.fetch(descriptor).first {
            session.isHidden = hidden
            try? context.save()
        }
    }

    func deleteSession(_ sessionId: String) {
        let descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate<CachedSession> { $0.sessionId == sessionId }
        )
        if let session = try? context.fetch(descriptor).first {
            context.delete(session)
            try? context.save()
        }
    }

    // MARK: - Messages

    func cachedMessages(for sessionId: String) -> [DevinMessage] {
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate<CachedMessage> { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toAPIModel() }
    }

    func upsertMessages(_ messages: [DevinMessage], sessionId: String) {
        // Mark the session as recently viewed
        let sessionDescriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate<CachedSession> { $0.sessionId == sessionId }
        )
        let cachedSession = try? context.fetch(sessionDescriptor).first
        cachedSession?.lastViewedAt = Date()

        for apiMessage in messages {
            guard let stableId = apiMessage.eventId else { continue }
            let descriptor = FetchDescriptor<CachedMessage>(
                predicate: #Predicate<CachedMessage> { $0.eventId == stableId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: apiMessage, sessionId: sessionId)
            } else {
                let cached = CachedMessage(
                    eventId: stableId,
                    sessionId: sessionId,
                    message: apiMessage.message
                )
                cached.update(from: apiMessage, sessionId: sessionId)
                cached.session = cachedSession
                context.insert(cached)
            }
        }
        try? context.save()

        trimMessages(for: sessionId)
    }

    private func trimMessages(for sessionId: String) {
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate<CachedMessage> { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor),
              all.count > maxMessagesPerSession else { return }

        for msg in all.dropFirst(maxMessagesPerSession) {
            context.delete(msg)
        }
        try? context.save()
    }

    // MARK: - Knowledge Notes

    func cachedNotes() -> [KnowledgeNote] {
        let descriptor = FetchDescriptor<CachedKnowledgeNote>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toAPIModel() }
    }

    func upsertNotes(_ notes: [KnowledgeNote]) {
        let apiIds = Set(notes.compactMap(\.noteId))

        for apiNote in notes {
            guard let noteId = apiNote.noteId else { continue }
            let descriptor = FetchDescriptor<CachedKnowledgeNote>(
                predicate: #Predicate<CachedKnowledgeNote> { $0.noteId == noteId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: apiNote)
            } else {
                let cached = CachedKnowledgeNote(
                    noteId: noteId, name: apiNote.name, body: apiNote.body
                )
                cached.update(from: apiNote)
                context.insert(cached)
            }
        }

        // Remove notes no longer in the API response
        let allDescriptor = FetchDescriptor<CachedKnowledgeNote>()
        if let allCached = try? context.fetch(allDescriptor) {
            for cached in allCached where !apiIds.contains(cached.noteId) {
                context.delete(cached)
            }
        }
        try? context.save()
    }

    func deleteNote(_ noteId: String) {
        let descriptor = FetchDescriptor<CachedKnowledgeNote>(
            predicate: #Predicate<CachedKnowledgeNote> { $0.noteId == noteId }
        )
        if let note = try? context.fetch(descriptor).first {
            context.delete(note)
            try? context.save()
        }
    }

    // MARK: - Playbooks

    func cachedPlaybooks() -> [Playbook] {
        let descriptor = FetchDescriptor<CachedPlaybook>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toAPIModel() }
    }

    func upsertPlaybooks(_ playbooks: [Playbook]) {
        let apiIds = Set(playbooks.map(\.playbookId))

        for apiPlaybook in playbooks {
            let playbookId = apiPlaybook.playbookId
            let descriptor = FetchDescriptor<CachedPlaybook>(
                predicate: #Predicate<CachedPlaybook> { $0.playbookId == playbookId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: apiPlaybook)
            } else {
                let cached = CachedPlaybook(
                    playbookId: apiPlaybook.playbookId,
                    title: apiPlaybook.title,
                    body: apiPlaybook.body
                )
                cached.update(from: apiPlaybook)
                context.insert(cached)
            }
        }

        // Remove playbooks no longer in the API response
        let allDescriptor = FetchDescriptor<CachedPlaybook>()
        if let allCached = try? context.fetch(allDescriptor) {
            for cached in allCached where !apiIds.contains(cached.playbookId) {
                context.delete(cached)
            }
        }
        try? context.save()
    }

    func deletePlaybook(_ playbookId: String) {
        let descriptor = FetchDescriptor<CachedPlaybook>(
            predicate: #Predicate<CachedPlaybook> { $0.playbookId == playbookId }
        )
        if let playbook = try? context.fetch(descriptor).first {
            context.delete(playbook)
            try? context.save()
        }
    }

    // MARK: - Maintenance

    func pruneStaleMessages() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -messageRetentionDays, to: .now)!
        let descriptor = FetchDescriptor<CachedSession>()
        guard let allSessions = try? context.fetch(descriptor) else { return }
        let staleSessions = allSessions.filter { session in
            session.lastViewedAt == nil || session.lastViewedAt! < cutoff
        }
        for session in staleSessions {
            for message in session.messages {
                context.delete(message)
            }
            session.messages = []
        }
        try? context.save()
    }

    func clearAllCache() {
        try? context.delete(model: CachedMessage.self)
        try? context.delete(model: CachedSession.self)
        try? context.delete(model: CachedKnowledgeNote.self)
        try? context.delete(model: CachedPlaybook.self)
        try? context.save()
    }
}
