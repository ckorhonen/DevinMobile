import Foundation
import SwiftUI

// MARK: - Status Filter

enum SessionStatusFilter: String, CaseIterable, Sendable, Identifiable {
    case all = "All"
    case working = "Working"
    case blocked = "Blocked"
    case finished = "Finished"
    case stopped = "Stopped"
    case expired = "Expired"

    var id: String { rawValue }

    var matchingStatuses: Set<SessionStatus> {
        switch self {
        case .all: Set(SessionStatus.allCases)
        case .working: [.running, .working, .resumed, .resumeRequested, .resumeRequestedFrontend]
        case .blocked: [.blocked]
        case .finished: [.finished]
        case .stopped: [.stopped]
        case .expired: [.expired, .suspendRequested, .suspendRequestedFrontend]
        }
    }

    var color: Color {
        switch self {
        case .all: .primary
        case .working: .devinGreen
        case .blocked: .devinYellow
        case .finished: .devinBlue
        case .stopped: .devinRed
        case .expired: .devinGray
        }
    }

    private static let defaultsKey = "sessionStatusFilter"

    static var persisted: SessionStatusFilter {
        guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
              let value = SessionStatusFilter(rawValue: raw) else {
            return .all
        }
        return value
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }
}

// MARK: - Repo Filter Sentinel

enum RepoFilter: Equatable, Sendable {
    case all
    case repo(String)
    case noPR
}

// MARK: - View Model

@Observable
@MainActor
final class SessionListViewModel {
    var sessions: [Session] = []
    var loadingState: LoadingState<[Session]> = .idle
    var statusFilter: SessionStatusFilter = SessionStatusFilter.persisted {
        didSet { statusFilter.persist() }
    }
    var selectedRepo: RepoFilter = .all
    var isCreatingSession = false
    var showNewSessionSheet = false
    var showArchived = false
    var toast: ToastItem?
    var isRefreshing = false

    // Pagination
    private var endCursor: String?
    private var v1Offset = 0
    private var hasMore = true
    private var isLoadingMore = false
    private var hasPaginatedBeyondFirstPage = false
    private var useV3: Bool { APIConfiguration.v3BaseURL != nil }
    private var userEmail: String? { KeychainService.getUserEmail() }
    private var persistence: PersistenceManager?
    private var pollingTask: Task<Void, Never>?

    /// Unique repos extracted from loaded sessions' PR URLs.
    var availableRepos: [String] {
        let repos = sessions.compactMap(\.repoFullName)
        return Array(Set(repos)).sorted()
    }

    var filteredSessions: [Session] {
        let base = showArchived ? (persistence?.cachedArchivedSessions() ?? []) : sessions

        var result = base

        // Status filter
        if statusFilter != .all {
            result = result.filter { statusFilter.matchingStatuses.contains($0.resolvedStatus) }
        }

        // Repo filter
        switch selectedRepo {
        case .all:
            break
        case .repo(let name):
            result = result.filter { $0.repoFullName == name }
        case .noPR:
            result = result.filter { $0.allPullRequests.isEmpty }
        }

        return result
    }

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    // MARK: - Loading

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

        endCursor = nil
        v1Offset = 0
        hasMore = true
        hasPaginatedBeyondFirstPage = false

        if useV3 {
            await loadSessionsV3()
        } else {
            await loadSessionsV1()
        }
        isRefreshing = false
    }

    func refreshSessions() async {
        isRefreshing = true
        endCursor = nil
        v1Offset = 0
        hasMore = true
        hasPaginatedBeyondFirstPage = false

        if useV3 {
            await loadSessionsV3()
        } else {
            await loadSessionsV1()
        }
        isRefreshing = false
    }

    private func loadSessionsV3() async {
        do {
            let response: PaginatedResponse<V3SessionItem> = try await APIClient.shared.perform(
                .listSessionsV3(first: 50, after: nil)
            )
            let mapped = response.items.map { $0.toSession() }
            persistence?.upsertSessions(mapped)
            sessions = persistence?.cachedSessions() ?? mapped
            endCursor = response.endCursor
            hasMore = response.hasNextPage
            loadingState = .loaded(sessions)
        } catch {
            // Fall back to v1 on failure
            await loadSessionsV1()
        }
    }

    private func loadSessionsV1() async {
        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            sessions = persistence?.cachedSessions() ?? response.sessions
            v1Offset = response.sessions.count
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
    }

    func loadMoreIfNeeded(currentItem: Session) async {
        guard hasMore, !isLoadingMore else { return }
        guard let lastItem = sessions.last, lastItem.id == currentItem.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        if useV3 {
            guard let cursor = endCursor else { return }
            do {
                let response: PaginatedResponse<V3SessionItem> = try await APIClient.shared.perform(
                    .listSessionsV3(first: 50, after: cursor)
                )
                let mapped = response.items.map { $0.toSession() }
                persistence?.upsertSessions(mapped)
                sessions.append(contentsOf: mapped)
                endCursor = response.endCursor
                hasMore = response.hasNextPage
                hasPaginatedBeyondFirstPage = true
                loadingState = .loaded(sessions)
            } catch {
                // Silent fail
            }
        } else {
            do {
                let response: SessionListResponse = try await APIClient.shared.perform(
                    .listSessions(limit: 50, offset: v1Offset, userEmail: userEmail)
                )
                persistence?.upsertSessions(response.sessions)
                sessions.append(contentsOf: response.sessions)
                v1Offset += response.sessions.count
                hasMore = response.sessions.count >= 50
                loadingState = .loaded(sessions)
            } catch {
                // Silent fail
            }
        }
    }

    // MARK: - Create / Archive

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

    /// Immediately fetches fresh data then starts the 30s polling loop.
    /// Call on scene phase `.active` to eliminate the 30s stale-data gap.
    func resumeAndPoll() {
        Task {
            await pollSessions()
        }
        startPolling()
    }

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
        if useV3 {
            // Skip if user has paginated beyond page 1 — poll only fetches the
            // first page and would discard additional pages if assigned.
            guard !hasPaginatedBeyondFirstPage else { return }

            do {
                let response: PaginatedResponse<V3SessionItem> = try await APIClient.shared.perform(
                    .listSessionsV3(first: 50, after: nil)
                )
                let mapped = response.items.map { $0.toSession() }
                persistence?.upsertSessions(mapped)
                let fresh = persistence?.cachedSessions() ?? mapped

                if sessionsHaveChanges(current: sessions, incoming: fresh) {
                    sessions = fresh
                    loadingState = .loaded(sessions)
                }
            } catch {
                // Silent fail
            }
        } else {
            guard v1Offset <= 50 else { return }

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
                // Silent fail
            }
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

        for (c, i) in zip(current, incoming) {
            if c.sessionId != i.sessionId { return true }
        }

        return false
    }
}
