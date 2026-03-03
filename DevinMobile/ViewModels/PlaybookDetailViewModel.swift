import Foundation

@Observable
@MainActor
final class PlaybookDetailViewModel {
    var playbook: Playbook?
    var loadingState: LoadingState<Playbook> = .idle
    var toastMessage: String?

    let playbookId: String

    init(playbookId: String) {
        self.playbookId = playbookId
    }

    init(playbook: Playbook) {
        self.playbookId = playbook.id
        self.playbook = playbook
        self.loadingState = .loaded(playbook)
    }

    func loadPlaybook() async {
        loadingState = .loading
        do {
            let p: Playbook = try await APIClient.shared.perform(.getPlaybook(id: playbookId))
            playbook = p
            loadingState = .loaded(p)
        } catch let error as DevinAPIError {
            loadingState = .error(ErrorInfo(error))
        } catch {
            loadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
    }

    func deletePlaybook() async -> Bool {
        do {
            try await APIClient.shared.performVoid(.deletePlaybook(id: playbookId))
            return true
        } catch let error as DevinAPIError {
            toastMessage = error.localizedDescription
            return false
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }
}
