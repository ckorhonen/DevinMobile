import Foundation

enum MarkdownBlock: Sendable, Equatable {
    case paragraph(text: String)
    case heading(level: Int, text: String)
    case codeBlock(language: String?, code: String)
    case unorderedList(items: [String])
    case orderedList(items: [String])
    case blockquote(text: String)
}
