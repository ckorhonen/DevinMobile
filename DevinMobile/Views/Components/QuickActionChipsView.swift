import SwiftUI

struct QuickActionChipsView: View {
    let actions: [QuickAction]
    let onSelect: (QuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(actions) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        Text(action.label)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
