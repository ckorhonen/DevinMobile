import SwiftUI

struct LoadingStateView<T: Sendable, Content: View>: View {
    let state: LoadingState<T>
    let emptyTitle: String
    let emptyDescription: String
    let emptyIcon: String
    let onRetry: () async -> Void
    @ViewBuilder let content: (T) -> Content

    init(
        state: LoadingState<T>,
        emptyTitle: String = "Nothing Here",
        emptyDescription: String = "",
        emptyIcon: String = "tray",
        onRetry: @escaping () async -> Void,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.emptyIcon = emptyIcon
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            DelayedProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        case .error(let info):
            ContentUnavailableView {
                Label("Unable to Load", systemImage: info.systemImage)
            } description: {
                Text(info.message)
            } actions: {
                Button(info.actionLabel) {
                    Task { await onRetry() }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
