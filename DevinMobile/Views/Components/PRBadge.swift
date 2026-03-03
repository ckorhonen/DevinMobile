import SwiftUI

struct PRBadge: View {
    let pullRequest: PullRequest
    var prState: PRState? = nil

    private var tintColor: Color {
        prState?.color ?? .devinBlue
    }

    var body: some View {
        HStack(spacing: 4) {
            if let state = prState {
                Circle()
                    .fill(state.color)
                    .frame(width: 6, height: 6)
            }

            Image(systemName: "arrow.triangle.pull")
                .font(.caption2)

            if let label = pullRequest.displayLabel {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }

            if let repoName = pullRequest.shortRepoName {
                Text(repoName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(tintColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tintColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Badge for V3 pull requests with state.
struct V3PRBadge: View {
    let pr: V3PullRequest

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(pr.resolvedState.color)
                .frame(width: 6, height: 6)

            Image(systemName: "arrow.triangle.pull")
                .font(.caption2)

            if let label = pr.displayLabel {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }

            if let repoName = pr.shortRepoName {
                Text(repoName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(pr.resolvedState.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(pr.resolvedState.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
