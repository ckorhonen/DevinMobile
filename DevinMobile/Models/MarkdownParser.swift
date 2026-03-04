import Foundation

enum MarkdownParser: Sendable {

    static func parse(_ input: String) -> [MarkdownBlock] {
        let lines = input.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip blank lines
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Fenced code block
            if trimmed.hasPrefix("```") {
                let language = extractLanguage(from: trimmed)
                var codeLines: [String] = []
                index += 1
                while index < lines.count {
                    if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        index += 1
                        break
                    }
                    codeLines.append(lines[index])
                    index += 1
                }
                blocks.append(.codeBlock(language: language, code: codeLines.joined(separator: "\n")))
                continue
            }

            // Heading
            if let heading = parseHeading(trimmed) {
                blocks.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("- ") {
                        items.append(String(l.dropFirst(2)))
                    } else if l.hasPrefix("* ") {
                        items.append(String(l.dropFirst(2)))
                    } else if l.isEmpty {
                        break
                    } else {
                        // Continuation line — append to last item
                        if !items.isEmpty {
                            items[items.count - 1] += " " + l
                        }
                        index += 1
                        continue
                    }
                    index += 1
                }
                blocks.append(.unorderedList(items: items))
                continue
            }

            // Ordered list
            if parseOrderedListItem(trimmed) != nil {
                var items: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if let text = parseOrderedListItem(l) {
                        items.append(text)
                    } else if l.isEmpty {
                        break
                    } else {
                        // Continuation line
                        if !items.isEmpty {
                            items[items.count - 1] += " " + l
                        }
                        index += 1
                        continue
                    }
                    index += 1
                }
                blocks.append(.orderedList(items: items))
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                var quoteLines: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("> ") {
                        quoteLines.append(String(l.dropFirst(2)))
                    } else if l == ">" {
                        quoteLines.append("")
                    } else {
                        break
                    }
                    index += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: "\n")))
                continue
            }

            // Paragraph — accumulate non-special lines
            var paraLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                let t = l.trimmingCharacters(in: .whitespaces)
                if t.isEmpty || t.hasPrefix("```") || isHeading(t)
                    || t.hasPrefix("- ") || t.hasPrefix("* ")
                    || t.hasPrefix("> ") || t == ">"
                    || parseOrderedListItem(t) != nil {
                    break
                }
                paraLines.append(l)
                index += 1
            }
            if !paraLines.isEmpty {
                blocks.append(.paragraph(text: paraLines.joined(separator: "\n")))
            }
        }

        return blocks
    }

    // MARK: - Helpers

    private static func extractLanguage(from line: String) -> String? {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        let afterTicks = stripped.dropFirst(3).trimmingCharacters(in: .whitespaces)
        return afterTicks.isEmpty ? nil : afterTicks
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var level = 0
        for char in line {
            if char == "#" { level += 1 } else { break }
        }
        guard level >= 1, level <= 6 else { return nil }
        guard line.count > level else { return nil }
        let afterHashes = line[line.index(line.startIndex, offsetBy: level)]
        guard afterHashes == " " else { return nil }
        let text = String(line.dropFirst(level + 1))
        return (level, text)
    }

    private static func isHeading(_ line: String) -> Bool {
        parseHeading(line) != nil
    }

    private static func parseOrderedListItem(_ line: String) -> String? {
        // Match "1. text", "2) text", etc.
        var i = line.startIndex
        guard i < line.endIndex, line[i].isNumber else { return nil }
        while i < line.endIndex, line[i].isNumber {
            i = line.index(after: i)
        }
        guard i < line.endIndex, line[i] == "." || line[i] == ")" else { return nil }
        i = line.index(after: i)
        guard i < line.endIndex, line[i] == " " else { return nil }
        i = line.index(after: i)
        return String(line[i...])
    }
}
