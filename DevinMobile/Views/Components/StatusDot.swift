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

/// Larger status icon using SF Symbols with native pulse effect for active states.
struct StatusIcon: View {
    let status: SessionStatus

    private var shouldPulse: Bool {
        switch status {
        case .running, .working, .resumed, .resumeRequested, .resumeRequestedFrontend:
            true
        default:
            false
        }
    }

    var body: some View {
        Image(systemName: status.systemImage)
            .font(.title3)
            .foregroundStyle(status.color)
            .symbolEffect(.pulse, isActive: shouldPulse)
            .frame(width: 28, alignment: .center)
    }
}
