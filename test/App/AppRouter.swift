//
//  AppRouter.swift
//  test
//

import Foundation
import Observation

/// Top-level phase of the app. Each phase is a full-screen flow rendered by `RootView`.
enum AppPhase: Equatable {
    case splash
    case onboarding
    case auth
    case main
}

struct PaywallPresentation: Identifiable {
    let id = UUID()
    /// Analytics label for where the paywall was opened from.
    let source: String
}

enum MainTab: Hashable {
    case home
    case settings
}

/// Single source of truth for navigation: the current phase, the selected tab
/// and modal presentations triggered from outside the view hierarchy (deep links).
@Observable
final class AppRouter {
    private(set) var phase: AppPhase = .splash
    var selectedTab: MainTab = .home
    var presentedPaywall: PaywallPresentation?
    var isShowingSubscription = false

    /// Deep link received before the main UI is ready (e.g. cold launch from a widget).
    @ObservationIgnored private var pendingDeepLink: DeepLink?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: StorageKey.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: StorageKey.hasCompletedOnboarding) }
    }

    /// Computes the phase that follows splash/onboarding/auth for the current state.
    func resolvePhase(isSignedIn: Bool) {
        let next: AppPhase = if !hasCompletedOnboarding {
            .onboarding
        } else if !isSignedIn {
            .auth
        } else {
            .main
        }
        guard next != phase else { return }
        phase = next
        if next == .main, let link = pendingDeepLink {
            pendingDeepLink = nil
            open(link)
        }
    }

    func completeOnboarding(isSignedIn: Bool) {
        hasCompletedOnboarding = true
        resolvePhase(isSignedIn: isSignedIn)
    }

    func presentPaywall(source: String) {
        presentedPaywall = PaywallPresentation(source: source)
    }

    func open(_ link: DeepLink) {
        guard phase == .main else {
            pendingDeepLink = link
            return
        }
        switch link {
        case .home: selectedTab = .home
        case .settings: selectedTab = .settings
        case .paywall: presentPaywall(source: "deep_link")
        case .subscription:
            selectedTab = .settings
            isShowingSubscription = true
        }
    }

    #if DEBUG
    func resetForDebug() {
        defaults.removeObject(forKey: StorageKey.hasCompletedOnboarding)
        defaults.removeObject(forKey: StorageKey.hasSeenLaunchPaywall)
        phase = .splash
    }
    #endif
}
