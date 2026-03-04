import SwiftUI

struct KnowledgeListView: View {
    @State private var viewModel = KnowledgeListViewModel()
    @State private var showEditor = false
    @State private var editingNote: KnowledgeNote?
    @Environment(\.persistenceManager) private var persistence

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle, .loading:
                if viewModel.notes.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    noteList
                }
            case .loaded:
                if viewModel.notes.isEmpty {
                    emptyState
                } else {
                    noteList
                }
            case .error(let info):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: info.systemImage)
                } description: {
                    Text(info.message)
                } actions: {
                    Button(info.actionLabel) {
                        Task { await viewModel.loadNotes() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Knowledge")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingNote = nil
                    showEditor = true
                } label: {
                    Label("New Note", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.loadNotes()
        }
        .sheet(isPresented: $showEditor) {
            Task { await viewModel.loadNotes() }
        } content: {
            NoteEditorView(note: editingNote)
        }
        .task {
            if let persistence { viewModel.configure(persistence: persistence) }
            if viewModel.loadingState.value == nil {
                await viewModel.loadNotes()
            }
        }
        .toastOverlay(toast: $viewModel.toast)
    }

    private var noteList: some View {
        List {
            ForEach(viewModel.notes) { note in
                KnowledgeRowView(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingNote = note
                        showEditor = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteNote(id: note.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Knowledge Notes", systemImage: "book.pages")
        } description: {
            Text("Knowledge notes help Devin understand your codebase and preferences.")
        } actions: {
            Button("Create Note") {
                editingNote = nil
                showEditor = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
