import SwiftUI

enum ToastVariant: Codable, Hashable, Sendable {
    case error
    case success
    case info

    var color: Color {
        switch self {
        case .error: .devinRed
        case .success: .devinGreen
        case .info: .devinBlue
        }
    }

    var systemImage: String {
        switch self {
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}

struct ToastItem: Codable, Hashable, Sendable {
    let message: String
    let variant: ToastVariant

    static func error(_ message: String) -> ToastItem {
        ToastItem(message: message, variant: .error)
    }

    static func success(_ message: String) -> ToastItem {
        ToastItem(message: message, variant: .success)
    }

    static func info(_ message: String) -> ToastItem {
        ToastItem(message: message, variant: .info)
    }
}
