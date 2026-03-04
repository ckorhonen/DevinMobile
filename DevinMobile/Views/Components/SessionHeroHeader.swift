import SwiftUI

/// Rich hero header for session detail view with generative MeshGradient background.
/// Extends behind the navigation bar for edge-to-edge visual impact.
struct SessionHeroHeader: View {
    let session: Session
    let pullRequests: [V3PullRequest]

    private var status: SessionStatus { session.resolvedStatus }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SessionHeaderBackground(
                sessionId: session.sessionId,
                statusColor: status.color,
                height: 280
            )
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 10) {
                // Status eyebrow
                Label(status.label, systemImage: status.systemImage)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                // Title
                Text(session.title ?? "Untitled Session")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // Stat pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let acus = session.acusConsumed, acus > 0 {
                            StatPill(
                                icon: "bolt.fill",
                                value: String(format: "%.1f ACU", acus),
                                color: .white,
                                style: .glass
                            )
                        }

                        if let created = session.createdAt {
                            StatPill(
                                icon: "clock",
                                value: created.asRelativeDate,
                                color: .white,
                                style: .glass
                            )
                        }

                        if let pr = pullRequests.first {
                            let state = pr.resolvedState
                            StatPill(
                                icon: "arrow.triangle.pull",
                                value: [pr.shortRepoName, pr.displayLabel]
                                    .compactMap { $0 }
                                    .joined(separator: " "),
                                color: .white,
                                style: .glass
                            )
                        }

                        if let tags = session.tags, !tags.isEmpty {
                            StatPill(
                                icon: "tag",
                                value: tags.count == 1 ? tags[0] : "\(tags.count) tags",
                                color: .white,
                                style: .glass
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(height: 280)
    }
}
