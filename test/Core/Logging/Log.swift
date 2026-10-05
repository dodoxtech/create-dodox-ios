//
//  Log.swift
//  test
//

import OSLog

/// Categorised loggers. Filter in Console.app by subsystem.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dodoxtech.test"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let analytics = Logger(subsystem: subsystem, category: "Analytics")
    static let store = Logger(subsystem: subsystem, category: "StoreKit")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
