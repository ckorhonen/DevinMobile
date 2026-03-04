import SwiftUI

struct SessionSearchView: View {
    @Binding var searchText: String
    @State private var viewModel = SessionSearchViewModel()
    @Environment(\.persistenceManager) private var persistence

    var body: some View {
        Group {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView {
                    Label("Search Sessions", systemImage: "magnifyingglass")
                } description: {
                    Text("Search by title, status, or tags.")
                }
            } else {
                let results = viewModel.filteredSessions(for: searchText)
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(results) { session in
                            NavigationLink(value: session) {
                                SessionRowView(session: session)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Session.self) { session in
            SessionDetailView(sessionId: session.id, initialSession: session)
        }
        .task {
            if let persistence { viewModel.configure(persistence: persistence) }
            await viewModel.loadSessions()
        }
    }
}
