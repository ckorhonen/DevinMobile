import SwiftUI

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Sessions", systemImage: "bubbles.and.sparkles", value: 0) {
                SessionListView()
            }

            Tab("Knowledge", systemImage: "book.pages", value: 1) {
                KnowledgeListView()
            }

            Tab("Playbooks", systemImage: "play.rectangle.on.rectangle", value: 2) {
                PlaybookListView()
            }

            Tab("Settings", systemImage: "gearshape", value: 3) {
                SettingsView()
            }
        }
    }
}
