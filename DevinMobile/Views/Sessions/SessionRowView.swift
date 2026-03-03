import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(status: session.resolvedStatus)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title ?? "Untitled Session")
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    StatusBadge(status: session.resolvedStatus)

                    Text((session.createdAt ?? "").asRelativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let acus = session.acusConsumed, acus > 0 {
                Text(String(format: "%.1f ACU", acus))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
