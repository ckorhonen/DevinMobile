import SwiftUI

struct MessageBubbleView: View {
    let messages: [DevinMessage]
    let isLastDevinTurn: Bool
    let sessionStatus: SessionStatus?

    private var source: MessageSource {
        messages.first?.resolvedSource ?? .user
    }

    private var isUser: Bool {
        source == .user
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            // Turn header
            HStack(spacing: 6) {
                if isUser {
                    Spacer()
                    if let timestamp = messages.first?.resolvedTimestamp {
                        Text(timestamp.asRelativeDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(.tint)
                    Text("Devin")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if let timestamp = messages.first?.resolvedTimestamp {
                        Text(timestamp.asRelativeDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Messages in turn
            ForEach(messages) { message in
                Group {
                    if isUser {
                        Text(message.message)
                            .font(.body)
                    } else {
                        MarkdownContentView(markdown: message.message)
                    }
                }
                .padding(12)
                .background {
                    if isUser {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.tint.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.background.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                .id(message.id)
            }
        }
    }
}
