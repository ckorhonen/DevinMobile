import SwiftUI

struct SessionRowView: View {
    let session: Session
    var category: SessionCategory?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            StatusDot(status: session.resolvedStatus)

            VStack(alignment: .leading, spacing: 5) {
                Text(session.title ?? "Untitled Session")
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Repo pill
                    if let repo = session.primaryPullRequest?.shortRepoName {
                        Text(repo)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.12), in: Capsule())
                    }

                    // PR state pill with merge-state background
                    if let pr = session.primaryPullRequest, let label = pr.displayLabel {
                        let state = pr.resolvedState
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.pull")
                                .font(.system(size: 8, weight: .bold))
                            Text(label)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(prForeground(state))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(state.color.opacity(0.15), in: Capsule())
                    }

                    if let category {
                        CategoryPill(category: category)
                    }

                    if session.allPullRequests.count > 1 {
                        Text("+\(session.allPullRequests.count - 1)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Text((session.createdAt ?? "").asRelativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func prForeground(_ state: PRState) -> Color {
        switch state {
        case .open: .devinGreen
        case .merged: .devinPurple
        case .closed: .devinRed
        }
    }
}
