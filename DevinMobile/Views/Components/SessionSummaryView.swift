import SwiftUI

struct SessionSummaryView: View {
    let summary: String
    var isGenerating: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(Color.devinPurple)

            if isGenerating {
                Text("Generating summary...")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                Text(markdownSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var markdownSummary: AttributedString {
        (try? AttributedString(markdown: summary)) ?? AttributedString(summary)
    }
}
