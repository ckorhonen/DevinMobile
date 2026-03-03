import SwiftUI

enum AppTab: Hashable {
    case sessions
    case settings
    case search
}

struct RootView: View {
    @State private var selectedTab: AppTab = .sessions
    @State private var searchText = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Sessions", systemImage: "bubbles.and.sparkles", value: .sessions) {
                SessionListView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SessionSearchView(searchText: $searchText)
                        .navigationTitle("Search")
                }
                .searchable(text: $searchText, prompt: "Sessions, status, tags…")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
