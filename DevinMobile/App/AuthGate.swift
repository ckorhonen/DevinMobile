import SwiftUI

struct AuthGate: View {
    @State private var hasKey = false
    @State private var isChecking = true

    var body: some View {
        Group {
            if isChecking {
                ProgressView()
            } else if hasKey {
                RootView()
                    .environment(\.logout, LogoutAction { hasKey = false })
            } else {
                NavigationStack {
                    APIKeySetupView {
                        hasKey = true
                    }
                }
            }
        }
        .onAppear {
            hasKey = KeychainService.hasAPIKey
            isChecking = false
        }
    }
}

// Environment key so any view can trigger logout
struct LogoutAction: Sendable {
    let action: @Sendable @MainActor () -> Void
    @MainActor func callAsFunction() { action() }
}

private struct LogoutKey: EnvironmentKey {
    static let defaultValue = LogoutAction { }
}

extension EnvironmentValues {
    var logout: LogoutAction {
        get { self[LogoutKey.self] }
        set { self[LogoutKey.self] = newValue }
    }
}
