import SwiftUI

extension Color {
    static let devinGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let devinYellow = Color(red: 0.95, green: 0.77, blue: 0.06)
    static let devinBlue = Color(red: 0.32, green: 0.56, blue: 0.95)
    static let devinGray = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let devinRed = Color(red: 0.95, green: 0.3, blue: 0.25)
    static let devinOrange = Color(red: 0.95, green: 0.6, blue: 0.15)
}

extension SessionStatus {
    var color: Color {
        switch self {
        case .running, .working, .resumed: .devinGreen
        case .blocked: .devinYellow
        case .stopped: .devinRed
        case .finished: .devinBlue
        case .expired: .devinGray
        case .suspendRequested, .suspendRequestedFrontend: .devinOrange
        case .resumeRequested, .resumeRequestedFrontend: .devinYellow
        }
    }

    var label: String {
        switch self {
        case .running, .working: "Working"
        case .blocked: "Blocked"
        case .stopped: "Stopped"
        case .finished: "Finished"
        case .expired: "Expired"
        case .resumed: "Resumed"
        case .suspendRequested, .suspendRequestedFrontend: "Pausing"
        case .resumeRequested, .resumeRequestedFrontend: "Resuming"
        }
    }

    var systemImage: String {
        switch self {
        case .running, .working, .resumed: "circle.fill"
        case .blocked: "exclamationmark.circle.fill"
        case .stopped: "stop.circle.fill"
        case .finished: "checkmark.circle.fill"
        case .expired: "clock.fill"
        case .suspendRequested, .suspendRequestedFrontend: "pause.circle.fill"
        case .resumeRequested, .resumeRequestedFrontend: "play.circle.fill"
        }
    }
}
