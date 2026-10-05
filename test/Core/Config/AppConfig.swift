//
//  AppConfig.swift
//  test
//

import Foundation

/// Static, app-wide configuration. Replace placeholder values before shipping.
enum AppConfig {
    static let appStoreID = "0000000000"

    static let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportEmail = "support@example.com"

    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    enum Subscription {
        static let groupID = "21000001"
        static let monthly = "dodoxtech.test.premium.monthly"
        static let yearly = "dodoxtech.test.premium.yearly"
        static let allProductIDs = [yearly, monthly]
    }
}

/// Keys for values persisted in `UserDefaults.standard`.
enum StorageKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let hasSeenLaunchPaywall = "hasSeenLaunchPaywall"
    static let analyticsEnabled = "analyticsEnabled"
    static let dailyReminderEnabled = "notifications.dailyReminderEnabled"
    static let dailyReminderHour = "notifications.dailyReminderHour"
    static let dailyReminderMinute = "notifications.dailyReminderMinute"
}
