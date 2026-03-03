import SwiftUI

struct PlaybookDetailView: View {
    @State private var viewModel: PlaybookDetailViewModel
    @State private var showRunSheet = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(playbook: Playbook) {
        _viewModel = State(initialValue: PlaybookDetailViewModel(playbook: playbook))
    }

    var body: some View {
        ScrollView {
            if let playbook = viewModel.playbook {
                VStack(alignment: .leading, spacing: 20) {
                    Text(playbook.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let macro = playbook.macro, !macro.isEmpty {
                        Label(macro, systemImage: "terminal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text(playbook.body)
                        .font(.body)

                    if let created = playbook.createdAt {
                        Text("Created \(created.asRelativeDate)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Playbook")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Run") {
                    showRunSheet = true
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Delete", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showRunSheet) {
            if let playbook = viewModel.playbook {
                RunPlaybookSheet(playbook: playbook)
            }
        }
        .confirmationDialog("Delete Playbook?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deletePlaybook() {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if viewModel.playbook == nil {
                await viewModel.loadPlaybook()
            }
        }
    }
}
