//
//  AnalyticsService.swift
//  test
//

import Foundation
import OSLog
import Observation
import SwiftUI

/// A backend that receives analytics (Firebase, Amplitude, Mixpanel, TelemetryDeck…).
/// Implement this protocol and register it in `AppContainer` to add a vendor.
protocol AnalyticsProvider {
    func track(_ event: AnalyticsEvent)
    func identify(userID: String?)
    func reset()
}

/// Fans events out to every registered provider and honours the user's opt-out.
@Observable
final class AnalyticsService {
    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: StorageKey.analyticsEnabled) }
    }

    @ObservationIgnored private let providers: [any AnalyticsProvider]
    @ObservationIgnored private let defaults: UserDefaults

    init(providers: [any AnalyticsProvider], defaults: UserDefaults = .standard) {
        self.providers = providers
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: StorageKey.analyticsEnabled) as? Bool ?? true
    }

    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        providers.forEach { $0.track(event) }
    }

    func identify(userID: String?) {
        guard isEnabled else { return }
        providers.forEach { $0.identify(userID: userID) }
    }

    func reset() {
        providers.forEach { $0.reset() }
    }
}

/// Logs events to the unified log. Useful in DEBUG and as a template for real providers.
struct ConsoleAnalyticsProvider: AnalyticsProvider {
    func track(_ event: AnalyticsEvent) {
        let params = event.parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        Log.analytics.debug("📊 \(event.name, privacy: .public) \(params, privacy: .public)")
    }

    func identify(userID: String?) {
        Log.analytics.debug("📊 identify \(userID ?? "nil", privacy: .private)")
    }

    func reset() {
        Log.analytics.debug("📊 reset")
    }
}

// MARK: - Screen tracking

private struct TrackScreenModifier: ViewModifier {
    let name: String
    @Environment(AnalyticsService.self) private var analytics

    func body(content: Content) -> some View {
        content.onAppear { analytics.track(.screenViewed(name)) }
    }
}

extension View {
    /// Emits `screen_viewed` each time the view appears.
    func trackScreen(_ name: String) -> some View {
        modifier(TrackScreenModifier(name: name))
    }
}
