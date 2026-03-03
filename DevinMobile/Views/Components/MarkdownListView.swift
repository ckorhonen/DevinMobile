import SwiftUI

struct MarkdownListView: View {
    let items: [String]
    let ordered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if ordered {
                        Text("\(index + 1).")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                    } else {
                        Text("\u{2022}")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .center)
                    }

                    inlineMarkdownText(item)
                }
            }
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    private func inlineMarkdownText(_ text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(.body)
        } else {
            Text(text)
                .font(.body)
        }
    }
}
