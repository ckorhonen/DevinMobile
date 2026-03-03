import SwiftUI

private struct PersistenceManagerKey: EnvironmentKey {
    static let defaultValue: PersistenceManager? = nil
}

extension EnvironmentValues {
    var persistenceManager: PersistenceManager? {
        get { self[PersistenceManagerKey.self] }
        set { self[PersistenceManagerKey.self] = newValue }
    }
}
