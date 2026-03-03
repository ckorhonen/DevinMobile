import SwiftUI

struct SessionListView: View {
    @State private var viewModel = SessionListViewModel()
    @Environment(\.persistenceManager) private var persistence
    @Environment(\.scenePhase) private var scenePhase

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
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        viewModel.showArchived.toggle()
                    } label: {
                        Label(
                            viewModel.showArchived ? "Show Active" : "Show Archived",
                            systemImage: viewModel.showArchived ? "tray.full" : "archivebox"
                        )
                    }
                }
            }
            .refreshable {
                await viewModel.refreshSessions()
            }
            .sheet(isPresented: $viewModel.showNewSessionSheet) {
                NewSessionSheet { prompt, playbookId in
                    await viewModel.createSession(prompt: prompt, playbookId: playbookId)
                }
            }
            .task {
                if let persistence { viewModel.configure(persistence: persistence) }
                if viewModel.loadingState.value == nil {
                    await viewModel.loadSessions()
                }
            }
            .onAppear {
                viewModel.startPolling()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    viewModel.startPolling()
                case .inactive, .background:
                    viewModel.stopPolling()
                @unknown default:
                    break
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
                    if viewModel.showArchived {
                        Button {
                            viewModel.unarchiveSession(id: session.id)
                        } label: {
                            Label("Unarchive", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.devinBlue)
                    } else {
                        Button {
                            viewModel.archiveSession(id: session.id)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
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

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.showArchived {
            ContentUnavailableView {
                Label("No Archived Sessions", systemImage: "archivebox")
            } description: {
                Text("Sessions you archive will appear here.")
            } actions: {
                Button("Show Active Sessions") {
                    viewModel.showArchived = false
                }
                .buttonStyle(.bordered)
            }
        } else {
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
}
