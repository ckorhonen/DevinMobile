import SwiftUI

struct StatusFilterChips: View {
    @Binding var selected: SessionStatusFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SessionStatusFilter.allCases) { filter in
                    Button {
                        withAnimation(.snappy) {
                            selected = (selected == filter) ? .all : filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selected == filter ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selected == filter
                                    ? filter.color.opacity(0.2)
                                    : Color(.systemGray6)
                            )
                            .foregroundStyle(selected == filter ? filter.color : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
