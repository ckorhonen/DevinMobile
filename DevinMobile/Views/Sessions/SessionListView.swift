import SwiftUI

struct SessionListView: View {
    @State private var viewModel = SessionListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    if viewModel.sessions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        sessionList
                    }
                case .loaded:
                    if viewModel.filteredSessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }
                case .error(let info):
                    ContentUnavailableView {
                        Label("Unable to Load", systemImage: info.systemImage)
                    } description: {
                        Text(info.message)
                    } actions: {
                        Button(info.actionLabel) {
                            Task { await viewModel.loadSessions() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showNewSessionSheet = true
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadSessions()
            }
            .sheet(isPresented: $viewModel.showNewSessionSheet) {
                NewSessionSheet { prompt, playbookId in
                    await viewModel.createSession(prompt: prompt, playbookId: playbookId)
                }
            }
            .task {
                if viewModel.loadingState.value == nil {
                    await viewModel.loadSessions()
                }
            }
        }
    }

    private var sessionList: some View {
        List {
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(SessionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(viewModel.filteredSessions) { session in
                NavigationLink(value: session) {
                    SessionRowView(session: session)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteSession(id: session.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.archiveSession(id: session.id) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.orange)
                }
                .task {
                    await viewModel.loadMoreIfNeeded(currentItem: session)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Session.self) { session in
            SessionDetailView(sessionId: session.id, initialSession: session)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Sessions", systemImage: "bubbles.and.sparkles")
        } description: {
            Text("Start a new session to get Devin working on something.")
        } actions: {
            Button("New Session") {
                viewModel.showNewSessionSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
