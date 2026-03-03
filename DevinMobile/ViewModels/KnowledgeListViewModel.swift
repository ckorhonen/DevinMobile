import Foundation

@Observable
@MainActor
final class KnowledgeListViewModel {
    var notes: [KnowledgeNote] = []
    var loadingState: LoadingState<[KnowledgeNote]> = .idle
    var toastMessage: String?

    private var persistence: PersistenceManager?

    func configure(persistence: PersistenceManager) {
        self.persistence = persistence
    }

    func loadNotes() async {
        // Show cached data immediately if available
        if let persistence {
            let cached = persistence.cachedNotes()
            if !cached.isEmpty {
                notes = cached
                loadingState = .loaded(notes)
            }
        }

        if notes.isEmpty {
            loadingState = .loading
        }

        do {
            let response: KnowledgeListResponse = try await APIClient.shared.perform(.listKnowledge)
            persistence?.upsertNotes(response.knowledge)
            notes = persistence?.cachedNotes() ?? response.knowledge
            loadingState = .loaded(notes)
        } catch let error as DevinAPIError {
            if notes.isEmpty {
                loadingState = .error(ErrorInfo(error))
            } else {
                toastMessage = error.localizedDescription
            }
        } catch {
            if notes.isEmpty {
                loadingState = .error(ErrorInfo(message: error.localizedDescription))
            } else {
                toastMessage = error.localizedDescription
            }
        }
    }

    func deleteNote(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deleteNote(id: id))
            persistence?.deleteNote(id)
            notes.removeAll { $0.id == id }
            loadingState = .loaded(notes)
        } catch let error as DevinAPIError {
            toastMessage = error.localizedDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }
}
