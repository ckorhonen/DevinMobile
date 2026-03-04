import SwiftUI
import SwiftData

@main
struct DevinMobileApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer
    let persistenceManager: PersistenceManager

    init() {
        let schema = Schema([
            CachedSession.self,
            CachedMessage.self,
            CachedKnowledgeNote.self,
            CachedPlaybook.self,
        ])
        let config = ModelConfiguration(
            "DevinMobileCache",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }
        persistenceManager = PersistenceManager(context: container.mainContext)
        persistenceManager.pruneStaleMessages()

        // Share the container with the background refresh manager
        BackgroundRefreshManager.shared.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environment(\.persistenceManager, persistenceManager)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                BackgroundRefreshManager.shared.scheduleRefresh()
            }
        }
    }
}
