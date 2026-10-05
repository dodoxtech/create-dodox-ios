//
//  AppDelegate.swift
//  test
//

import UIKit
import UserNotifications

/// UIKit hooks SwiftUI has no equivalent for: APNs registration and notification delivery.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Owned here (not by `TestApp`) so it exists before any delegate callback,
    /// e.g. a notification tap that cold-launches the app.
    let container = AppContainer()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        container.notifications.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        container.notifications.didFailToRegisterForRemoteNotifications(error)
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Show banners while the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// The user tapped a notification: route to its `deepLink` payload.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        let link = (response.notification.request.content.userInfo["deepLink"] as? String)
            .flatMap(URL.init(string:))
            .flatMap(DeepLink.init(url:))

        await MainActor.run {
            container.analytics.track(.notificationOpened(identifier))
            if let link { container.router.open(link) }
        }
    }
}
