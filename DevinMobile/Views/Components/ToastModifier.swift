import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .font(.subheadline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.devinRed.gradient)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var duration: Duration = .seconds(3)

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let message {
                    ToastView(message: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.2), value: message)
            .onChange(of: message) { _, newValue in
                if newValue != nil {
                    Task { @MainActor in
                        try? await Task.sleep(for: duration)
                        if self.message == newValue {
                            self.message = nil
                        }
                    }
                }
            }
    }
}

extension View {
    func toast(message: Binding<String?>, duration: Duration = .seconds(3)) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}
