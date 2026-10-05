//
//  NotificationService.swift
//  test
//

import Foundation
import OSLog
import Observation
import UIKit
import UserNotifications

/// Permission, remote registration and local scheduling for notifications.
/// Delivery callbacks are handled in `AppDelegate`.
@Observable
final class NotificationService {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var deviceToken: String?

    var isDailyReminderEnabled: Bool {
        didSet {
            defaults.set(isDailyReminderEnabled, forKey: StorageKey.dailyReminderEnabled)
            Task { await syncDailyReminder() }
        }
    }

    var reminderTime: DateComponents {
        didSet {
            defaults.set(reminderTime.hour, forKey: StorageKey.dailyReminderHour)
            defaults.set(reminderTime.minute, forKey: StorageKey.dailyReminderMinute)
            Task { await syncDailyReminder() }
        }
    }

    var isAuthorized: Bool {
        [.authorized, .provisional, .ephemeral].contains(authorizationStatus)
    }

    @ObservationIgnored private let center: UNUserNotificationCenter
    @ObservationIgnored private let defaults: UserDefaults

    private enum Identifier {
        static let dailyReminder = "daily-reminder"
        static let test = "test-notification"
    }

    init(center: UNUserNotificationCenter = .current(), defaults: UserDefaults = .standard) {
        self.center = center
        self.defaults = defaults
        self.isDailyReminderEnabled = defaults.bool(forKey: StorageKey.dailyReminderEnabled)
        self.reminderTime = DateComponents(
            hour: defaults.object(forKey: StorageKey.dailyReminderHour) as? Int ?? 20,
            minute: defaults.object(forKey: StorageKey.dailyReminderMinute) as? Int ?? 0
        )
    }

    func refreshStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
        if isAuthorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Shows the system prompt. Call it in context (after explaining the value), not on first launch.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshStatus()
        return granted
    }

    // MARK: Remote (APNs)

    func didRegisterForRemoteNotifications(deviceToken data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        Log.notifications.info("APNs token: \(token, privacy: .private)")
        // TODO: Upload the token to your push provider / backend.
    }

    func didFailToRegisterForRemoteNotifications(_ error: any Error) {
        Log.notifications.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    // MARK: Local

    func scheduleTestNotification(after seconds: TimeInterval = 5) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.test.title")
        content.body = String(localized: "notification.test.body")
        content.sound = .default
        content.userInfo = ["deepLink": DeepLink.paywall.url.absoluteString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try await center.add(UNNotificationRequest(identifier: Identifier.test, content: content, trigger: trigger))
    }

    private func syncDailyReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])
        guard isDailyReminderEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.reminder.title")
        content.body = String(localized: "notification.reminder.body")
        content.sound = .default
        content.userInfo = ["deepLink": DeepLink.home.url.absoluteString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderTime, repeats: true)
        do {
            try await center.add(UNNotificationRequest(identifier: Identifier.dailyReminder, content: content, trigger: trigger))
        } catch {
            Log.notifications.error("Failed to schedule reminder: \(error.localizedDescription, privacy: .public)")
        }
    }
}
