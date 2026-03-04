import SwiftUI

struct PlaybookRowView: View {
    let playbook: Playbook

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(playbook.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(playbook.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let created = playbook.createdAt {
                Text(created.asRelativeDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
