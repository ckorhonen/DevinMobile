import SwiftUI
import SwiftData

@main
struct DevinMobileApp: App {
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
    }

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environment(\.persistenceManager, persistenceManager)
        }
        .modelContainer(container)
    }
}
