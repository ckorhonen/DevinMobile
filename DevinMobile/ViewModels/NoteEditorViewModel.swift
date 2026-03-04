import Foundation

@Observable
@MainActor
final class NoteEditorViewModel {
    var name = ""
    var body = ""
    var trigger = ""
    var isSaving = false
    var errorMessage: String?

    private let existingNote: KnowledgeNote?

    var isEditing: Bool { existingNote != nil }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(note: KnowledgeNote? = nil) {
        self.existingNote = note
        if let note {
            self.name = note.name
            self.body = note.body
            self.trigger = note.resolvedTrigger
        }
    }

    init(prefilledName: String, prefilledBody: String, prefilledTrigger: String) {
        self.existingNote = nil
        self.name = prefilledName
        self.body = prefilledBody
        self.trigger = prefilledTrigger
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        do {
            if let note = existingNote {
                let request = UpdateNoteRequest(
                    name: name,
                    body: body,
                    triggerDescription: trigger
                )
                try await APIClient.shared.performVoid(.updateNote(id: note.id), body: request)
            } else {
                let request = CreateNoteRequest(
                    name: name,
                    body: body,
                    triggerDescription: trigger
                )
                let _: KnowledgeNote = try await APIClient.shared.perform(.createNote, body: request)
            }
            return true
        } catch let error as DevinAPIError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
