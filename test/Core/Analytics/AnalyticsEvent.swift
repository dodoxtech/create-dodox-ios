//
//  AnalyticsEvent.swift
//  test
//

import Foundation

/// A single analytics event. Add new events as static factories below so the
/// event taxonomy lives in one place and stays consistent across providers.
struct AnalyticsEvent: Equatable, Sendable {
    let name: String
    let parameters: [String: String]

    init(_ name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

extension AnalyticsEvent {
    // Lifecycle
    static let appOpened = AnalyticsEvent("app_opened")
    static func screenViewed(_ screen: String) -> Self { .init("screen_viewed", parameters: ["screen": screen]) }
    static func deepLinkOpened(_ link: DeepLink) -> Self { .init("deep_link_opened", parameters: ["destination": link.rawValue]) }

    // Onboarding
    static let onboardingStarted = AnalyticsEvent("onboarding_started")
    static func onboardingCompleted(skipped: Bool) -> Self {
        .init("onboarding_completed", parameters: ["skipped": String(skipped)])
    }

    // Auth
    static func signInCompleted(method: String) -> Self { .init("sign_in_completed", parameters: ["method": method]) }
    static func signInFailed(method: String, reason: String) -> Self {
        .init("sign_in_failed", parameters: ["method": method, "reason": reason])
    }
    static let signedOut = AnalyticsEvent("signed_out")
    static let accountDeleted = AnalyticsEvent("account_deleted")

    // Monetisation
    static func paywallViewed(source: String) -> Self { .init("paywall_viewed", parameters: ["source": source]) }
    static func paywallDismissed(source: String) -> Self { .init("paywall_dismissed", parameters: ["source": source]) }
    static func purchaseStarted(productID: String) -> Self { .init("purchase_started", parameters: ["product_id": productID]) }
    static func purchaseCompleted(productID: String) -> Self { .init("purchase_completed", parameters: ["product_id": productID]) }
    static func purchaseFailed(productID: String, reason: String) -> Self {
        .init("purchase_failed", parameters: ["product_id": productID, "reason": reason])
    }
    static let restoreCompleted = AnalyticsEvent("restore_completed")

    // Notifications
    static func notificationPermission(granted: Bool) -> Self {
        .init("notification_permission", parameters: ["granted": String(granted)])
    }
    static func notificationOpened(_ identifier: String) -> Self {
        .init("notification_opened", parameters: ["id": identifier])
    }
}
