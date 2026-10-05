//
//  AppContainer.swift
//  test
//

import SwiftUI

/// Composition root: builds every service once and injects them into the SwiftUI environment.
/// Swap implementations here (e.g. a real `AuthClient` or extra `AnalyticsProvider`s).
final class AppContainer {
    let router: AppRouter
    let analytics: AnalyticsService
    let auth: AuthService
    let subscriptions: SubscriptionService
    let notifications: NotificationService

    init(
        router: AppRouter = AppRouter(),
        analytics: AnalyticsService = AnalyticsService(providers: [ConsoleAnalyticsProvider()]),
        auth: AuthService = AuthService(),
        subscriptions: SubscriptionService = SubscriptionService(),
        notifications: NotificationService = NotificationService()
    ) {
        self.router = router
        self.analytics = analytics
        self.auth = auth
        self.subscriptions = subscriptions
        self.notifications = notifications
    }

    /// Work performed while the splash screen is visible. Keep it fast and offline-safe.
    func bootstrap() async {
        await subscriptions.start()
        await auth.restoreSession()
        await notifications.refreshStatus()
        analytics.identify(userID: auth.currentUser?.id)
        analytics.track(.appOpened)

        // Warm the product cache for the paywall without blocking launch.
        Task { try? await subscriptions.loadProducts() }
    }
}

extension View {
    func environment(_ container: AppContainer) -> some View {
        self
            .environment(container.router)
            .environment(container.analytics)
            .environment(container.auth)
            .environment(container.subscriptions)
            .environment(container.notifications)
    }
}

#if DEBUG
extension AppContainer {
    static let preview = AppContainer(analytics: AnalyticsService(providers: []))
}
#endif
