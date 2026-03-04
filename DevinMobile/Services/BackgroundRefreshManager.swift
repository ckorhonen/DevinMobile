import Foundation
import BackgroundTasks
import SwiftData
import CoreMotion
import UIKit

/// Manages BGAppRefreshTask scheduling and execution for background session monitoring.
@MainActor
final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "com.devin.session-refresh"

    private let motionActivityManager = CMMotionActivityManager()
    var modelContainer: ModelContainer?

    private init() {}

    // MARK: - Registration

    /// Call from `application(_:didFinishLaunchingWithOptions:)` to register the background task.
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await self.handleBackgroundRefresh(refreshTask)
            }
        }
    }

    /// Schedule the next background refresh. Call on `.background` scene phase.
    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        // Default 15 min; adaptive scheduling adjusts this in handleBackgroundRefresh
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Cancel any pending background refresh (e.g., on logout).
    func cancelScheduledRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    // MARK: - Background Execution

    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) async {
        // Schedule the next refresh before doing work (in case we get killed)
        let nextInterval = await adaptiveInterval()
        let nextRequest = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        nextRequest.earliestBeginDate = Date(timeIntervalSinceNow: nextInterval)
        try? BGTaskScheduler.shared.submit(nextRequest)

        // Set up expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Detect changes and notify
        guard let container = modelContainer else {
            task.setTaskCompleted(success: false)
            return
        }
        let context = ModelContext(container)
        let detector = SessionChangeDetector(context: context)
        let changes = await detector.detectChanges()

        for change in changes {
            NotificationManager.shared.notifySessionChange(
                sessionId: change.session.sessionId,
                title: change.session.title,
                oldStatus: change.oldStatus,
                newStatus: change.newStatus
            )
        }

        task.setTaskCompleted(success: true)
    }

    // MARK: - Adaptive Scheduling

    /// Returns the interval for the next refresh based on motion + charging state.
    /// Moving = 15 min (minimum, user is on-the-go managing agents)
    /// Stationary + charging = 60 min (likely at desk using web client)
    /// Stationary + battery = 30 min (moderate)
    private func adaptiveInterval() async -> TimeInterval {
        let isCharging = await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let state = UIDevice.current.batteryState
            return state == .charging || state == .full
        }

        let isMoving = await detectMotion()

        if isMoving {
            return 15 * 60  // 15 min — on the go
        } else if isCharging {
            return 60 * 60  // 60 min — at desk
        } else {
            return 30 * 60  // 30 min — stationary on battery
        }
    }

    /// Queries recent motion activity to determine if user is moving.
    private func detectMotion() async -> Bool {
        guard CMMotionActivityManager.isActivityAvailable() else { return false }

        return await withCheckedContinuation { continuation in
            let now = Date()
            let tenMinutesAgo = now.addingTimeInterval(-10 * 60)

            motionActivityManager.queryActivityStarting(
                from: tenMinutesAgo,
                to: now,
                to: .main
            ) { activities, error in
                guard let activities, error == nil, let latest = activities.last else {
                    continuation.resume(returning: false)
                    return
                }
                let moving = latest.walking || latest.running || latest.cycling || latest.automotive
                continuation.resume(returning: moving)
            }
        }
    }
}
