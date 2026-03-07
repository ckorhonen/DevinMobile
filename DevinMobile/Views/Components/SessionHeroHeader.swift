import SwiftUI

/// Header for session detail view showing status, title, and stat pills.
struct SessionHeroHeader: View {
    let session: Session
    let pullRequests: [V3PullRequest]
    var category: SessionCategory?

    private var status: SessionStatus { session.resolvedStatus }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status eyebrow
            Label(status.label, systemImage: status.systemImage)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.12), in: Capsule())

            // Title
            Text(session.title ?? "Untitled Session")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(3)

            // Stat pills
            FlowLayout(spacing: 8) {
                if let acus = session.acusConsumed, acus > 0 {
                    StatPill(
                        icon: "bolt.fill",
                        value: String(format: "%.1f ACU", acus),
                        color: .devinGreen
                    )
                }

                if let created = session.createdAt {
                    StatPill(
                        icon: "clock",
                        value: created.asRelativeDate,
                        color: .devinGray
                    )
                }

                if let pr = pullRequests.first {
                    StatPill(
                        icon: "arrow.triangle.pull",
                        value: [pr.shortRepoName, pr.displayLabel]
                            .compactMap { $0 }
                            .joined(separator: " "),
                        color: pr.resolvedState.color
                    )
                }

                if let category {
                    StatPill(
                        icon: category.systemImage,
                        value: category.label,
                        color: category.color
                    )
                }

                if let tags = session.tags, !tags.isEmpty {
                    StatPill(
                        icon: "tag",
                        value: tags.count == 1 ? tags[0] : "\(tags.count) tags",
                        color: .devinBlue
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
