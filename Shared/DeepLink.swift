//
//  DeepLink.swift
//  Shared (compiled into the app and the widget extension)
//

import Foundation

/// Every in-app destination reachable from outside the app
/// (widgets, notifications, URL scheme `testapp://`, universal links).
nonisolated enum DeepLink: String, CaseIterable, Sendable {
    case home
    case settings
    case paywall
    case subscription

    static let scheme = "testapp"

    var url: URL {
        URL(string: "\(Self.scheme)://\(rawValue)")!
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme, let host = url.host() else { return nil }
        self.init(rawValue: host)
    }
}
