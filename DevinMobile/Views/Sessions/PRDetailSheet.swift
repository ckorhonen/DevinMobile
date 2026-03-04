import SwiftUI

struct PRDetailSheet: View {
    let pullRequests: [V3PullRequest]
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                ForEach(pullRequests) { pr in
                    VStack(alignment: .leading, spacing: 8) {
                        // Status badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(pr.resolvedState.color)
                                .frame(width: 8, height: 8)
                            Text(pr.resolvedState.label)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(pr.resolvedState.color.opacity(0.15))
                        .clipShape(Capsule())

                        // PR number + repo
                        if let components = pr.gitHubComponents {
                            Text("\(components.owner)/\(components.repo) #\(components.number)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text(pr.prUrl)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Button {
                            if let appURL = pr.gitHubAppURL {
                                openURL(appURL) { accepted in
                                    if !accepted, let webURL = pr.gitHubWebURL {
                                        openURL(webURL)
                                    }
                                }
                            } else if let webURL = pr.gitHubWebURL {
                                openURL(webURL)
                            }
                        } label: {
                            Label("View on GitHub", systemImage: "arrow.up.right")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Pull Requests")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
