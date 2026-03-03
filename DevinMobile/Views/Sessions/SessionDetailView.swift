import SwiftUI

struct SessionDetailView: View {
    @State private var viewModel: SessionDetailViewModel
    @FocusState private var isComposerFocused: Bool
    @Environment(\.persistenceManager) private var persistence

    init(sessionId: String, initialSession: Session? = nil) {
        _viewModel = State(initialValue: SessionDetailViewModel(sessionId: sessionId))
        if let session = initialSession {
            // Pre-populate session data
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            composerBar
        }
        .navigationTitle(viewModel.session?.title ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let session = viewModel.session {
                    HStack(spacing: 6) {
                        Text(session.title ?? "Session")
                            .font(.headline)
                            .lineLimit(1)
                        StatusBadge(status: session.resolvedStatus)
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
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

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField("Message Devin...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isComposerFocused)

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}
