import SwiftUI

struct PRBadge: View {
    let pullRequest: PullRequest

    var body: some View {
        HStack(spacing: 4) {
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
        .foregroundStyle(Color.devinBlue)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.devinBlue.opacity(0.1))
        .clipShape(Capsule())
    }
}
