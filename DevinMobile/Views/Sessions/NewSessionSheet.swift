import SwiftUI

struct NewSessionSheet: View {
    let onSubmit: (String, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var selectedPlaybookId: String?
    @State private var playbooks: [Playbook] = []
    @State private var isSubmitting = false

    private var isValid: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What should Devin work on?", text: $prompt, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Prompt")
                }

                Section {
                    Picker("Playbook", selection: $selectedPlaybookId) {
                        Text("None").tag(nil as String?)
                        ForEach(playbooks) { playbook in
                            Text(playbook.title).tag(playbook.id as String?)
                        }
                    }
                } header: {
                    Text("Playbook (optional)")
                }

                Section {
                    Button {
                        isSubmitting = true
                        Task {
                            await onSubmit(prompt, selectedPlaybookId)
                            isSubmitting = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Label("Start Session", systemImage: "play.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                do {
                    let response: [Playbook] = try await APIClient.shared.perform(.listPlaybooks)
                    playbooks = response
                } catch {
                    // Playbooks are optional — silent fail
                }
            }
        }
    }
}
