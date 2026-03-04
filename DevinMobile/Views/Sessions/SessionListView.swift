import SwiftUI

struct SessionListView: View {
    @State private var viewModel = SessionListViewModel()
    @State private var navigationPath = NavigationPath()
    @Environment(\.persistenceManager) private var persistence
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                filterBar

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
                if !viewModel.showArchived {
                    await viewModel.refreshSessions()
                }
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
                    viewModel.resumeAndPoll()
                case .inactive, .background:
                    viewModel.stopPolling()
                @unknown default:
                    break
                }
            }
            .toastOverlay(toast: $viewModel.toast)
            .onReceive(NotificationCenter.default.publisher(for: .didTapSessionNotification)) { notification in
                guard let sessionId = notification.userInfo?["sessionId"] as? String else { return }
                // Find the session in our loaded list, or create a minimal one for navigation
                if let session = viewModel.sessions.first(where: { $0.sessionId == sessionId }) {
                    navigationPath.append(session)
                }
                NotificationManager.shared.clearNotifications(for: sessionId)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            if !viewModel.availableRepos.isEmpty {
                RepoFilterButton(
                    repos: viewModel.availableRepos,
                    selectedRepo: $viewModel.selectedRepo
                )

                Divider()
                    .frame(height: 20)
            }

            StatusFilterChips(selected: $viewModel.statusFilter)
        }
        .padding(.leading, viewModel.availableRepos.isEmpty ? 0 : 16)
        .padding(.vertical, 8)
    }

    private var sessionList: some View {
        List {
            ForEach(viewModel.filteredSessions) { session in
                NavigationLink(value: session) {
                    SessionRowView(session: session, category: persistence?.cachedSessionAI(for: session.sessionId).category)
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
                    if !viewModel.showArchived {
                        await viewModel.loadMoreIfNeeded(currentItem: session)
                    }
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
        } else if viewModel.statusFilter == .working {
            ContentUnavailableView {
                Label("No Active Sessions", systemImage: "bubbles.and.sparkles")
            } description: {
                Text("Start a new session or check other filters.")
            } actions: {
                Button("New Session") {
                    viewModel.showNewSessionSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.statusFilter != .all {
            ContentUnavailableView {
                Label("No \(viewModel.statusFilter.rawValue) Sessions", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No sessions match this filter.")
            } actions: {
                Button("Show All") {
                    viewModel.statusFilter = .all
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
