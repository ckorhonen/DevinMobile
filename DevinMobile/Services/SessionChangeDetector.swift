import Foundation
import SwiftData

/// Represents a detected session state transition worth notifying about.
struct SessionStateChange: Sendable {
    let session: Session
    let oldStatus: SessionStatus
    let newStatus: SessionStatus
}

/// Fetches fresh sessions from the API and diffs against SwiftData cache
/// to detect status transitions worth notifying about.
@MainActor
final class SessionChangeDetector {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Fetches sessions and returns any that transitioned to a notifiable state.
    func detectChanges() async -> [SessionStateChange] {
        // 1. Snapshot current cached statuses before fetch
        let oldStatuses = snapshotStatuses()

        // 2. Fetch fresh sessions from API
        let freshSessions: [Session]
        do {
            freshSessions = try await fetchSessions()
        } catch {
            return []
        }

        // 3. Upsert into cache (so next wake sees updated state)
        upsertToCache(freshSessions)

        // 4. Diff: find sessions whose status changed to something notifiable
        var changes: [SessionStateChange] = []
        for session in freshSessions {
            let newStatus = session.resolvedStatus
            guard isNotifiable(newStatus) else { continue }

            let oldStatus = oldStatuses[session.sessionId]
            // Don't notify if status hasn't actually changed
            if let oldStatus, oldStatus == newStatus { continue }

            changes.append(SessionStateChange(
                session: session,
                oldStatus: oldStatus ?? .running,
                newStatus: newStatus
            ))
        }

        return changes
    }

    // MARK: - Private

    private func snapshotStatuses() -> [String: SessionStatus] {
        var descriptor = FetchDescriptor<CachedSession>(
            predicate: #Predicate { !$0.isHidden && !$0.isArchived && !$0.isArchivedFromAPI }
        )
        descriptor.fetchLimit = 200
        let cached = (try? context.fetch(descriptor)) ?? []
        var result: [String: SessionStatus] = [:]
        for session in cached {
            let status = session.statusEnum ?? session.status ?? "running"
            if let s = SessionStatus(rawValue: status) {
                result[session.sessionId] = s
            }
        }
        return result
    }

    private func fetchSessions() async throws -> [Session] {
        if APIConfiguration.v3BaseURL != nil {
            let response: PaginatedResponse<V3SessionItem> = try await APIClient.shared.perform(
                .listSessionsV3(first: 50, after: nil)
            )
            return response.items.map { $0.toSession() }
        } else {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: KeychainService.getUserEmail())
            )
            return response.sessions
        }
    }

    private func upsertToCache(_ sessions: [Session]) {
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

    /// Only notify for terminal/actionable states.
    private func isNotifiable(_ status: SessionStatus) -> Bool {
        switch status {
        case .blocked, .finished, .stopped, .expired, .suspendRequested, .suspendRequestedFrontend:
            return true
        default:
            return false
        }
    }
}
