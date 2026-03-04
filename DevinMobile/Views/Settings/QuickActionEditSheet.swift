import SwiftUI

struct QuickActionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chip: QuickAction?
    let store: QuickActionsStore?

    @State private var label = ""
    @State private var prompt = ""
    @State private var condition: QuickActionCondition = .always

    private var isValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("e.g. Summarize progress", text: $label)
                }
                Section("Message") {
                    TextField("Message to send to Devin...", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Show When") {
                    Picker("Condition", selection: $condition) {
                        ForEach(QuickActionCondition.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(chip == nil ? "Add Action" : "Edit Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if let chip {
                label = chip.label
                prompt = chip.prompt
                condition = chip.condition
            }
        }
    }

    private func save() {
        guard let store else { return }
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if var existing = chip {
            existing.label = trimmedLabel
            existing.prompt = trimmedPrompt
            existing.condition = condition
            store.update(existing)
        } else {
            store.add(label: trimmedLabel, prompt: trimmedPrompt, condition: condition)
        }
    }
}
