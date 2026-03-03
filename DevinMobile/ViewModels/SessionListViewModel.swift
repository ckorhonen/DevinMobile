import Foundation
import SwiftUI

enum SessionFilter: String, CaseIterable, Sendable {
    case all = "All"
    case active = "Active"
    case finished = "Finished"
}

@Observable
@MainActor
final class SessionListViewModel {
    var sessions: [Session] = []
    var loadingState: LoadingState<[Session]> = .idle
    var filter: SessionFilter = .all
    var isCreatingSession = false
    var showNewSessionSheet = false
    var showArchived = false
    var toast: ToastItem?
    var isRefreshing = false

    private var offset = 0
    private var hasMore = true
    private var isLoadingMore = false
    private var userEmail: String? { KeychainService.getUserEmail() }
    private var persistence: PersistenceManager?
    private var pollingTask: Task<Void, Never>?

    var filteredSessions: [Session] {
        let base = showArchived ? (persistence?.cachedArchivedSessions() ?? []) : sessions

        switch filter {
        case .all:
            return base
        case .active:
            return base.filter { $0.isActive }
        case .finished:
            return base.filter { !$0.isActive }
        }
    }

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    func loadSessions() async {
        // Show cached data immediately if available
        if let persistence {
            let cached = persistence.cachedSessions()
            if !cached.isEmpty {
                sessions = cached
                loadingState = .loaded(sessions)

                if !persistence.isSessionCacheStale() {
                    return
                }

                isRefreshing = true
            }
        }

        if sessions.isEmpty {
            loadingState = .loading
        }

        offset = 0
        hasMore = true

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            sessions = persistence?.cachedSessions() ?? response.sessions
            offset = response.sessions.count
            hasMore = response.sessions.count >= 50
            loadingState = .loaded(sessions)
        } catch let error as DevinAPIError {
            if sessions.isEmpty {
                loadingState = .error(ErrorInfo(error))
            } else {
                toast = .error(error.localizedDescription)
            }
        } catch {
            if sessions.isEmpty {
                loadingState = .error(ErrorInfo(message: error.localizedDescription))
            } else {
                toast = .error(error.localizedDescription)
            }
        }
        isRefreshing = false
    }

    func refreshSessions() async {
        isRefreshing = true
        offset = 0
        hasMore = true

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            sessions = persistence?.cachedSessions() ?? response.sessions
            offset = response.sessions.count
            hasMore = response.sessions.count >= 50
            loadingState = .loaded(sessions)
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
        } catch {
            toast = .error(error.localizedDescription)
        }
        isRefreshing = false
    }

    func loadMoreIfNeeded(currentItem: Session) async {
        guard hasMore, !isLoadingMore else { return }
        guard let lastItem = filteredSessions.last, lastItem.id == currentItem.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: offset, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            sessions.append(contentsOf: response.sessions)
            offset += response.sessions.count
            hasMore = response.sessions.count >= 50
            loadingState = .loaded(sessions)
        } catch {
            // Silent fail on load-more
        }
    }

    func createSession(prompt: String, playbookId: String? = nil) async {
        isCreatingSession = true
        defer { isCreatingSession = false }

        let request = CreateSessionRequest(
            prompt: prompt,
            playbookId: playbookId,
            title: nil,
            maxAcuLimit: nil
        )

        do {
            let _: CreateSessionResponse = try await APIClient.shared.perform(
                .createSession, body: request
            )
            showNewSessionSheet = false
            await loadSessions()
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
        } catch {
            toast = .error(error.localizedDescription)
        }
    }

    func archiveSession(id: String) {
        persistence?.setSessionArchived(id, archived: true)
        sessions.removeAll { $0.id == id }
        loadingState = .loaded(sessions)
    }

    func unarchiveSession(id: String) {
        persistence?.setSessionArchived(id, archived: false)
        if let persistence {
            sessions = persistence.cachedSessions()
            loadingState = .loaded(sessions)
        }
    }

    // MARK: - Polling

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                guard let self else { break }
                await self.pollSessions()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func pollSessions() async {
        // Skip if user has paginated beyond page 1 — poll only fetches the
        // first page and would discard additional pages if assigned.
        guard offset <= 50 else { return }

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            let fresh = persistence?.cachedSessions() ?? response.sessions

            if sessionsHaveChanges(current: sessions, incoming: fresh) {
                sessions = fresh
                loadingState = .loaded(sessions)
            }
        } catch {
            // Silent fail — don't show error toasts for background poll failures
        }
    }

    private func sessionsHaveChanges(current: [Session], incoming: [Session]) -> Bool {
        guard current.count == incoming.count else { return true }

        let currentById = Dictionary(current.map { ($0.sessionId, $0) }, uniquingKeysWith: { _, latest in latest })

        for session in incoming {
            guard let existing = currentById[session.sessionId] else {
                return true
            }
            if session.hasContentChanges(from: existing) {
                return true
            }
        }

        // Check ordering
        for (c, i) in zip(current, incoming) {
            if c.sessionId != i.sessionId { return true }
        }

        return false
    }
}
