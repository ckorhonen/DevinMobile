import SwiftUI

struct MarkdownContentView: View {
    let markdown: String
    private let blocks: [MarkdownBlock]

    init(markdown: String) {
        self.markdown = markdown
        self.blocks = MarkdownParser.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let text):
                    inlineMarkdownText(text)
                case .heading(let level, let text):
                    headingView(level: level, text: text)
                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                case .unorderedList(let items):
                    MarkdownListView(items: items, ordered: false)
                case .orderedList(let items):
                    MarkdownListView(items: items, ordered: true)
                case .blockquote(let text):
                    BlockquoteView(text: text)
                }
            }
        }
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

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        let content: Text = if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
        } else {
            Text(text)
        }

        switch level {
        case 1: content.font(.title).fontWeight(.bold)
        case 2: content.font(.title2).fontWeight(.bold)
        case 3: content.font(.title3).fontWeight(.semibold)
        case 4: content.font(.headline)
        case 5: content.font(.subheadline).fontWeight(.semibold)
        default: content.font(.subheadline)
        }
    }
}

// MARK: - BlockquoteView

struct BlockquoteView: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.devinGray.opacity(0.5))
                .frame(width: 3)

            Group {
                if let attributed = try? AttributedString(
                    markdown: text,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                ) {
                    Text(attributed)
                } else {
                    Text(text)
                }
            }
            .font(.body)
            .foregroundStyle(.secondary)
            .padding(.leading, 10)
        }
        .padding(.vertical, 2)
    }
}
