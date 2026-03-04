import Foundation

// MARK: - Quick Action Condition

enum QuickActionCondition: String, Codable, CaseIterable, Sendable {
    case always
    case whenBlocked
    case whenRunning
    case whenPRExists

    var displayName: String {
        switch self {
        case .always: "Always (session active)"
        case .whenBlocked: "When blocked"
        case .whenRunning: "While working"
        case .whenPRExists: "When PR exists"
        }
    }
}

// MARK: - Quick Action

struct QuickAction: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var label: String
    var prompt: String
    var condition: QuickActionCondition
    var isBuiltIn: Bool
    var sortOrder: Int

    func isVisible(for status: SessionStatus?, hasPR: Bool) -> Bool {
        switch condition {
        case .always:
            return true
        case .whenBlocked:
            return status == .blocked
        case .whenRunning:
            return status == .running || status == .working
        case .whenPRExists:
            return hasPR
        }
    }
}
