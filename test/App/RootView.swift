//
//  RootView.swift
//  test
//

import SwiftUI

/// Switches between the top-level flows and handles incoming URLs.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth
    @Environment(AnalyticsService.self) private var analytics

    let bootstrap: () async -> Void

    var body: some View {
        ZStack {
            switch router.phase {
            case .splash:
                SplashView(bootstrap: bootstrap)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .auth:
                AuthView()
                    .transition(.move(edge: .trailing))
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: router.phase)
        .onChange(of: auth.isSignedIn) { _, isSignedIn in
            guard router.phase != .splash else { return }
            router.resolvePhase(isSignedIn: isSignedIn)
        }
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else { return }
            analytics.track(.deepLinkOpened(link))
            router.open(link)
        }
    }
}

#Preview {
    RootView(bootstrap: {})
        .environment(AppContainer.preview)
}
