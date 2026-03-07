import SwiftUI

/// Compact stat capsule for the session hero header.
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    var style: Style = .tinted

    enum Style {
        case tinted
        case glass
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .fixedSize()
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            switch style {
            case .tinted:
                Capsule().fill(color.opacity(0.12))
            case .glass:
                Capsule().fill(.ultraThinMaterial)
            }
        }
    }
}
