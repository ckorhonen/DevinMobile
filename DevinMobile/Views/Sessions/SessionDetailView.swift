import SwiftUI

struct SessionDetailView: View {
    @State private var viewModel: SessionDetailViewModel
    @State private var showPRSheet = false
    @State private var showCompactTitle = false
    @FocusState private var isComposerFocused: Bool
    @Environment(\.persistenceManager) private var persistence
    @Environment(\.quickActionsStore) private var quickActionsStore
    @Environment(\.openURL) private var openURL

    init(sessionId: String, initialSession: Session? = nil) {
        _viewModel = State(initialValue: SessionDetailViewModel(sessionId: sessionId))
        if let session = initialSession {
            // Pre-populate session data
        }
    }

    private var visibleActions: [QuickAction] {
        guard viewModel.isSessionActive, let store = quickActionsStore else { return [] }
        return store.visibleActions(
            status: viewModel.session?.resolvedStatus,
            hasPR: !viewModel.allPullRequests.isEmpty
        )
    }

    var body: some View {
        messageList
            .safeAreaInset(edge: .bottom) {
                ComposerView(
                    viewModel: viewModel,
                    isFocused: $isComposerFocused,
                    visibleActions: visibleActions
                )
            }
        .navigationTitle(viewModel.session?.title ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(showCompactTitle ? .automatic : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let session = viewModel.session {
                    HStack(spacing: 6) {
                        Text(session.title ?? "Session")
                            .font(.headline)
                            .lineLimit(1)
                        StatusBadge(status: session.resolvedStatus)
                    }
                    .opacity(showCompactTitle ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showCompactTitle)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if !viewModel.allPullRequests.isEmpty {
                    Button {
                        let prs = viewModel.allPullRequests
                        if prs.count == 1, let webURL = prs[0].gitHubWebURL {
                            openGitHubPR(appURL: prs[0].gitHubAppURL, webURL: webURL)
                        } else {
                            showPRSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if let state = viewModel.allPullRequests.first?.resolvedState {
                                Circle()
                                    .fill(state.color)
                                    .frame(width: 8, height: 8)
                            }
                            Label("Pull Requests", systemImage: "arrow.triangle.pull")
                                .labelStyle(.iconOnly)
                        }
                    }
                }

                if let url = viewModel.session?.url, let webURL = URL(string: url) {
                    Link(destination: webURL) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                if viewModel.isSessionActive {
                    Button("Terminate Session", role: .destructive) {
                        viewModel.showTerminateConfirmation = true
                    }
                }
            }
        }
        .task {
            if let persistence { viewModel.configure(persistence: persistence) }
            await viewModel.loadSessionAndMessages()
        }
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .confirmationDialog(
            "Terminate Session?",
            isPresented: $viewModel.showTerminateConfirmation
        ) {
            Button("Terminate", role: .destructive) {
                Task { await viewModel.terminateSession() }
            }
        } message: {
            Text("This will permanently stop Devin from working on this session. This cannot be undone.")
        }
        .toastOverlay(toast: $viewModel.toast)
        .sheet(isPresented: $showPRSheet) {
            PRDetailSheet(pullRequests: viewModel.allPullRequests)
        }
    }

    @ViewBuilder
    private var messageList: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            if viewModel.messages.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                scrollableMessages
            }
        case .loaded:
            if viewModel.messages.isEmpty {
                ContentUnavailableView {
                    Label("No Messages", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Send a message to start the conversation.")
                }
            } else {
                scrollableMessages
            }
        case .error(let info):
            ContentUnavailableView {
                Label("Unable to Load", systemImage: info.systemImage)
            } description: {
                Text(info.message)
            } actions: {
                Button(info.actionLabel) {
                    Task { await viewModel.loadSessionAndMessages() }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var scrollableMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header with generative background
                    if let session = viewModel.session {
                        SessionHeroHeader(
                            session: session,
                            pullRequests: viewModel.allPullRequests
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { _, newY in
                                        let threshold: CGFloat = -100
                                        let shouldShow = newY < threshold
                                        if shouldShow != showCompactTitle {
                                            showCompactTitle = shouldShow
                                        }
                                    }
                            }
                        )
                    }

                    LazyVStack(spacing: 16) {
                        let turns = viewModel.messageTurns
                        ForEach(Array(turns.enumerated()), id: \.element.first?.id) { index, turn in
                            let isLastDevin = turn.first?.resolvedSource == .devin && index == turns.count - 1
                            MessageBubbleView(
                                messages: turn,
                                isLastDevinTurn: isLastDevin,
                                sessionStatus: viewModel.session?.resolvedStatus
                            )
                        }

                        if viewModel.isSessionActive {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Devin is working...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                            .transition(.opacity)
                            .id("bottom-indicator")
                        }
                    }
                    .padding()
                }
            }
            .coordinateSpace(name: "scroll")
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isComposerFocused = false
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation {
                    let scrollTarget = viewModel.isSessionActive ? "bottom-indicator" : viewModel.messages.last?.id
                    if let target = scrollTarget {
                        proxy.scrollTo(target, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func openGitHubPR(appURL: URL?, webURL: URL) {
        if let appURL {
            openURL(appURL) { accepted in
                if !accepted {
                    openURL(webURL)
                }
            }
        } else {
            openURL(webURL)
        }
    }

}
