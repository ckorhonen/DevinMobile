import Foundation

@Observable
@MainActor
final class PlaybookListViewModel {
    var playbooks: [Playbook] = []
    var loadingState: LoadingState<[Playbook]> = .idle
    var toastMessage: String?

    func loadPlaybooks() async {
        loadingState = .loading

        do {
            let response: [Playbook] = try await APIClient.shared.perform(.listPlaybooks)
            playbooks = response
            loadingState = .loaded(playbooks)
        } catch let error as DevinAPIError {
            loadingState = .error(ErrorInfo(error))
        } catch {
            loadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
    }

    func deletePlaybook(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deletePlaybook(id: id))
            playbooks.removeAll { $0.id == id }
            loadingState = .loaded(playbooks)
        } catch let error as DevinAPIError {
            toastMessage = error.localizedDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }
}
