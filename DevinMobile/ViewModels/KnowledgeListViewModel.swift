import Foundation

@Observable
@MainActor
final class KnowledgeListViewModel {
    var notes: [KnowledgeNote] = []
    var loadingState: LoadingState<[KnowledgeNote]> = .idle
    var toastMessage: String?

    func loadNotes() async {
        loadingState = .loading

        do {
            let response: KnowledgeListResponse = try await APIClient.shared.perform(.listKnowledge)
            notes = response.knowledge
            loadingState = .loaded(notes)
        } catch let error as DevinAPIError {
            loadingState = .error(ErrorInfo(error))
        } catch {
            loadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
    }

    func deleteNote(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deleteNote(id: id))
            notes.removeAll { $0.id == id }
            loadingState = .loaded(notes)
        } catch let error as DevinAPIError {
            toastMessage = error.localizedDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }
}
