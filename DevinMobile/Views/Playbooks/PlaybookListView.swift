import SwiftUI

struct PlaybookListView: View {
    @State private var viewModel = PlaybookListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    if viewModel.playbooks.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        playbookList
                    }
                case .loaded:
                    if viewModel.playbooks.isEmpty {
                        emptyState
                    } else {
                        playbookList
                    }
                case .error(let info):
                    ContentUnavailableView {
                        Label("Unable to Load", systemImage: info.systemImage)
                    } description: {
                        Text(info.message)
                    } actions: {
                        Button(info.actionLabel) {
                            Task { await viewModel.loadPlaybooks() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Playbooks")
            .refreshable {
                await viewModel.loadPlaybooks()
            }
            .task {
                if viewModel.loadingState.value == nil {
                    await viewModel.loadPlaybooks()
                }
            }
        }
    }

    private var playbookList: some View {
        List {
            ForEach(viewModel.playbooks) { playbook in
                NavigationLink(value: playbook) {
                    PlaybookRowView(playbook: playbook)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.deletePlaybook(id: playbook.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Playbook.self) { playbook in
            PlaybookDetailView(playbook: playbook)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Playbooks", systemImage: "play.rectangle.on.rectangle")
        } description: {
            Text("Playbooks define reusable workflows for Devin.")
        }
    }
}
