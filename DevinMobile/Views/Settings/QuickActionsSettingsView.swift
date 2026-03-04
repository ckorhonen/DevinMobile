import SwiftUI

struct QuickActionsSettingsView: View {
    @Environment(\.quickActionsStore) private var store
    @State private var showAddSheet = false
    @State private var chipToEdit: QuickAction?

    private var builtInActions: [QuickAction] {
        store?.allActions.filter(\.isBuiltIn) ?? []
    }

    private var customActions: [QuickAction] {
        store?.allActions.filter { !$0.isBuiltIn } ?? []
    }

    var body: some View {
        List {
            Section {
                ForEach(builtInActions) { action in
                    actionRow(action)
                }
            } header: {
                Text("Built-in")
            } footer: {
                Text("Built-in actions cannot be edited or removed.")
            }

            Section("Custom") {
                if customActions.isEmpty {
                    Text("No custom actions yet.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(customActions) { action in
                        actionRow(action)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    store?.delete(action)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button("Edit") {
                                    chipToEdit = action
                                }
                                .tint(.devinBlue)
                            }
                    }
                    .onMove { from, to in
                        store?.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
        }
        .navigationTitle("Quick Actions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    if !customActions.isEmpty {
                        EditButton()
                    }
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            QuickActionEditSheet(chip: nil, store: store)
        }
        .sheet(item: $chipToEdit) { action in
            QuickActionEditSheet(chip: action, store: store)
        }
    }

    private func actionRow(_ action: QuickAction) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(action.label)
                .font(.body)
            Text(action.prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(action.condition.displayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
