import Foundation
@preconcurrency import UserNotifications

/// Manages local notification permissions and delivery for session state changes.
@MainActor
final class NotificationManager: Sendable {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    func requestPermissionIfNeeded() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    // MARK: - Session Notifications

    /// Posts a local notification for a session state transition.
    /// Deduplicates by session+status so repeated background wakes don't spam.
    nonisolated func notifySessionChange(
        sessionId: String,
        title: String?,
        oldStatus: SessionStatus,
        newStatus: SessionStatus
    ) {
        guard let info = notificationInfo(for: newStatus) else { return }

        let sessionTitle = title ?? "Untitled Session"
        let content = UNMutableNotificationContent()
        content.title = info.title
        content.body = sessionTitle
        content.sound = .default
        content.userInfo = [
            "sessionId": sessionId,
            "action": "openSession",
        ]

        // Use session+status as identifier to deduplicate
        let identifier = "session-\(sessionId)-\(newStatus.rawValue)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Removes pending/delivered notifications for a session (e.g., when user opens it).
    nonisolated func clearNotifications(for sessionId: String) {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { notifications in
            let ids = notifications
                .filter { $0.request.content.userInfo["sessionId"] as? String == sessionId }
                .map(\.request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    // MARK: - Notification Content

    private struct NotificationInfo {
        let title: String
    }

    private nonisolated func notificationInfo(for status: SessionStatus) -> NotificationInfo? {
        switch status {
        case .blocked:
            return NotificationInfo(title: "Devin needs your input")
        case .finished:
            return NotificationInfo(title: "Session completed")
        case .stopped:
            return NotificationInfo(title: "Session stopped")
        case .expired, .suspendRequested, .suspendRequestedFrontend:
            return NotificationInfo(title: "Session expired")
        default:
            return nil
        }
    }
}
