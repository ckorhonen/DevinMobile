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
    var toastMessage: String?

    private var offset = 0
    private var hasMore = true
    private var isLoadingMore = false
    private var userEmail: String? { KeychainService.getUserEmail() }

    var filteredSessions: [Session] {
        switch filter {
        case .all:
            return sessions
        case .active:
            return sessions.filter { $0.isActive }
        case .finished:
            return sessions.filter { !$0.isActive }
        }
    }

    func loadSessions() async {
        loadingState = .loading
        offset = 0
        hasMore = true

        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: userEmail)
            )
            sessions = response.sessions
            offset = response.sessions.count
            hasMore = response.sessions.count >= 50
            loadingState = .loaded(sessions)
        } catch let error as DevinAPIError {
            loadingState = .error(ErrorInfo(error))
        } catch {
            loadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
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
            toastMessage = error.localizedDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func deleteSession(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deleteSession(id: id))
            sessions.removeAll { $0.id == id }
            loadingState = .loaded(sessions)
        } catch let error as DevinAPIError {
            toastMessage = error.localizedDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func archiveSession(id: String) async {
        // v1 doesn't have archive — just remove from list locally
        sessions.removeAll { $0.id == id }
        loadingState = .loaded(sessions)
    }
}
