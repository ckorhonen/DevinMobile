import SwiftUI

private struct QuickActionsStoreKey: EnvironmentKey {
    static let defaultValue: QuickActionsStore? = nil
}

extension EnvironmentValues {
    var quickActionsStore: QuickActionsStore? {
        get { self[QuickActionsStoreKey.self] }
        set { self[QuickActionsStoreKey.self] = newValue }
    }
}
