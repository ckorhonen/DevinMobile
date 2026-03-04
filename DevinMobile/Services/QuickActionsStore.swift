import Foundation

@Observable
@MainActor
final class QuickActionsStore {
    private static let userDefaultsKey = "customQuickActions"

    private(set) var allActions: [QuickAction] = []

    init() {
        reload()
    }

    func visibleActions(status: SessionStatus?, hasPR: Bool) -> [QuickAction] {
        allActions.filter { $0.isVisible(for: status, hasPR: hasPR) }
    }

    // MARK: - CRUD

    func add(label: String, prompt: String, condition: QuickActionCondition) {
        let maxOrder = allActions.map(\.sortOrder).max() ?? -1
        let action = QuickAction(
            id: UUID(),
            label: label,
            prompt: prompt,
            condition: condition,
            isBuiltIn: false,
            sortOrder: maxOrder + 1
        )
        allActions.append(action)
        persistCustomActions()
    }

    func update(_ action: QuickAction) {
        guard !action.isBuiltIn else { return }
        guard let index = allActions.firstIndex(where: { $0.id == action.id }) else { return }
        allActions[index] = action
        persistCustomActions()
    }

    func delete(_ action: QuickAction) {
        guard !action.isBuiltIn else { return }
        allActions.removeAll { $0.id == action.id }
        persistCustomActions()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        var custom = allActions.filter { !$0.isBuiltIn }
        custom.move(fromOffsets: fromOffsets, toOffset: toOffset)
        // Reassign sort orders starting after built-ins
        let builtInMax = Self.builtIns.map(\.sortOrder).max() ?? -1
        for i in custom.indices {
            custom[i].sortOrder = builtInMax + 1 + i
        }
        allActions = Self.builtIns + custom
        persistCustomActions()
    }

    // MARK: - Built-ins

    private static let builtIns: [QuickAction] = [
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            label: "What's the status?",
            prompt: "What's the current status?",
            condition: .always, isBuiltIn: true, sortOrder: 0
        ),
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            label: "Continue working",
            prompt: "Continue working, use your best judgment.",
            condition: .whenBlocked, isBuiltIn: true, sortOrder: 1
        ),
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            label: "Show changes",
            prompt: "Show me what you've changed",
            condition: .whenRunning, isBuiltIn: true, sortOrder: 2
        ),
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            label: "Review PR",
            prompt: "Review PR feedback and address issues",
            condition: .whenPRExists, isBuiltIn: true, sortOrder: 3
        ),
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            label: "Create a PR",
            prompt: "Create a PR for your changes",
            condition: .whenRunning, isBuiltIn: true, sortOrder: 4
        ),
        QuickAction(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            label: "Check CI",
            prompt: "Check CI status",
            condition: .whenPRExists, isBuiltIn: true, sortOrder: 5
        ),
    ]

    // MARK: - Persistence

    private func reload() {
        var actions = Self.builtIns
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let custom = try? decoder.decode([QuickAction].self, from: data) {
            actions += custom
        }
        allActions = actions.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func persistCustomActions() {
        let custom = allActions.filter { !$0.isBuiltIn }
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        if let data = try? encoder.encode(custom) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
