import SwiftUI

struct RunPlaybookSheet: View {
    let playbook: Playbook

    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(playbook.title)
                        .font(.headline)
                    Text(playbook.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                } header: {
                    Text("Playbook")
                }

                Section {
                    TextField("Additional instructions (optional)", text: $prompt, axis: .vertical)
                        .lineLimit(2...6)
                } header: {
                    Text("Prompt")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await runPlaybook() }
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
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Run Playbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func runPlaybook() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let sessionPrompt = prompt.isEmpty ? playbook.title : prompt
        let request = CreateSessionRequest(
            prompt: sessionPrompt,
            playbookId: playbook.id,
            title: nil,
            maxAcuLimit: nil
        )

        do {
            let _: CreateSessionResponse = try await APIClient.shared.perform(
                .createSession, body: request
            )
            dismiss()
        } catch let error as DevinAPIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
