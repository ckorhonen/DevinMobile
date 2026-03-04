import Foundation

@Observable
@MainActor
final class SessionSearchViewModel {
    var sessions: [Session] = []
    var loadingState: LoadingState<[Session]> = .idle

    private var persistence: PersistenceManager?
    private var userEmail: String? { KeychainService.getUserEmail() }

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    func filteredSessions(for query: String) -> [Session] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()

        return sessions.filter { session in
            if let title = session.title, title.lowercased().contains(lowered) {
                return true
            }
            if session.resolvedStatus.rawValue.lowercased().contains(lowered) {
                return true
            }
            if let tags = session.tags, tags.contains(where: { $0.lowercased().contains(lowered) }) {
                return true
            }
            return false
        }
    }

    func loadSessions() async {
        if let persistence {
            let cached = persistence.cachedSessions()
            if !cached.isEmpty {
                sessions = cached
                loadingState = .loaded(sessions)
            }
        }

        if sessions.isEmpty {
            loadingState = .loading
        }

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 200, offset: 0, userEmail: userEmail)
            )
            persistence?.upsertSessions(response.sessions)
            sessions = persistence?.cachedSessions() ?? response.sessions
            loadingState = .loaded(sessions)
        } catch let error as DevinAPIError {
            if sessions.isEmpty {
                loadingState = .error(ErrorInfo(error))
            }
        } catch {
            if sessions.isEmpty {
                loadingState = .error(ErrorInfo(message: error.localizedDescription))
            }
        }
    }
}
