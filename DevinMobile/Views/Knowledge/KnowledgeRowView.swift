import SwiftUI

struct KnowledgeRowView: View {
    let note: KnowledgeNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.name)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(note.resolvedTrigger)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let updated = note.updatedAt ?? note.createdAt {
                Text(updated.asRelativeDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
