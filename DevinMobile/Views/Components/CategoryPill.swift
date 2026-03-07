import SwiftUI

struct CategoryPill: View {
    let category: SessionCategory

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.systemImage)
                .font(.system(size: 8, weight: .bold))
            Text(category.label)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .fixedSize()
        .foregroundStyle(category.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(category.color.opacity(0.15), in: Capsule())
    }
}
