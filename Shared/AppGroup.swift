//
//  AppGroup.swift
//  Shared (compiled into the app and the widget extension)
//

import Foundation

/// App Group container shared between the app and its extensions.
/// Must match the `com.apple.security.application-groups` entitlement of every target.
nonisolated enum AppGroup {
    static let identifier = "group.dodoxtech.test"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

/// Widget kinds, so the app can reload a specific timeline.
nonisolated enum WidgetKind {
    static let main = "TestWidget"
}
