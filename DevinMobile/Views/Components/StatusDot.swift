import SwiftUI

struct StatusDot: View {
    let status: SessionStatus
    var size: CGFloat = 10

    @State private var isPulsing = false

    private var shouldPulse: Bool {
        status == .running || status == .working
    }

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                shouldPulse
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                if shouldPulse {
                    isPulsing = true
                }
            }
    }
}
