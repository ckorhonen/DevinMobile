import SwiftUI

struct NoteEditorView: View {
    @State private var viewModel: NoteEditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(note: KnowledgeNote? = nil) {
        _viewModel = State(initialValue: NoteEditorViewModel(note: note))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Note name", text: $viewModel.name)
                }

                Section("Trigger") {
                    TextField("When should Devin use this?", text: $viewModel.trigger, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Content") {
                    TextEditor(text: $viewModel.body)
                        .frame(minHeight: 150)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }
}
