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

                // V3 PR badge with state, falling back to v1
                if let v3PR = session.primaryPullRequest {
                    HStack(spacing: 6) {
                        V3PRBadge(pr: v3PR)

                        if session.allPullRequests.count > 1 {
                            Text("+\(session.allPullRequests.count - 1) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let pr = session.pullRequest, pr.number != nil {
                    PRBadge(pullRequest: pr)
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
