import Foundation

@Observable
@MainActor
final class PlaybookListViewModel {
    var playbooks: [Playbook] = []
    var loadingState: LoadingState<[Playbook]> = .idle
    var toast: ToastItem?

    private var persistence: PersistenceManager?

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    func loadPlaybooks() async {
        // Show cached data immediately if available
        if let persistence {
            let cached = persistence.cachedPlaybooks()
            if !cached.isEmpty {
                playbooks = cached
                loadingState = .loaded(playbooks)
            }
        }

        if playbooks.isEmpty {
            loadingState = .loading
        }

        do {
            let response: [Playbook] = try await APIClient.shared.perform(.listPlaybooks)
            persistence?.upsertPlaybooks(response)
            playbooks = persistence?.cachedPlaybooks() ?? response
            loadingState = .loaded(playbooks)
        } catch let error as DevinAPIError {
            if playbooks.isEmpty {
                loadingState = .error(ErrorInfo(error))
            } else {
                toast = .error(error.localizedDescription)
            }
        } catch {
            if playbooks.isEmpty {
                loadingState = .error(ErrorInfo(message: error.localizedDescription))
            } else {
                toast = .error(error.localizedDescription)
            }
        }
    }

    func deletePlaybook(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deletePlaybook(id: id))
            persistence?.deletePlaybook(id)
            playbooks.removeAll { $0.id == id }
            loadingState = .loaded(playbooks)
        } catch let error as DevinAPIError {
            toast = .error(error.localizedDescription)
        } catch {
            toast = .error(error.localizedDescription)
        }
    }
}
