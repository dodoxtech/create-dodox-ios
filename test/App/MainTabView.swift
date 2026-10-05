//
//  MainTabView.swift
//  test
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SubscriptionService.self) private var subscriptions
    @AppStorage(StorageKey.hasSeenLaunchPaywall) private var hasSeenLaunchPaywall = false

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("tab.home", systemImage: "house", value: MainTab.home) {
                HomeView()
            }
            Tab("tab.settings", systemImage: "gearshape", value: MainTab.settings) {
                SettingsView()
            }
        }
        .sheet(item: $router.presentedPaywall) { presentation in
            PaywallView(source: presentation.source)
        }
        .task {
            // Soft paywall shown once, right after the user first reaches the main experience.
            guard !hasSeenLaunchPaywall, !subscriptions.isPremium else { return }
            hasSeenLaunchPaywall = true
            try? await Task.sleep(for: .milliseconds(600))
            router.presentPaywall(source: "launch")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppContainer.preview)
}
