//
//  HomeView.swift
//  test
//

import SwiftUI
import WidgetKit

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth
    @Environment(SubscriptionService.self) private var subscriptions
    @Environment(NotificationService.self) private var notifications
    @Environment(AnalyticsService.self) private var analytics

    @State private var tapCount = SharedStore.load().tapCount
    @State private var notificationScheduled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    if !subscriptions.isPremium {
                        upgradeCard
                    }
                    counterCard
                    notificationCard
                }
                .padding()
            }
            .navigationTitle(greeting)
            .toolbar {
                if subscriptions.isPremium {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("common.premium", systemImage: "crown.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .trackScreen("home")
    }

    private var greeting: String {
        if let name = auth.currentUser?.displayName {
            String(localized: "home.greeting.name \(name)")
        } else {
            String(localized: "home.greeting")
        }
    }

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label("home.upgrade.title", systemImage: "crown.fill")
                .font(.headline)
                .foregroundStyle(.yellow)
            Text("home.upgrade.message")
                .foregroundStyle(.secondary)
            Button("home.upgrade.cta") { router.presentPaywall(source: "home_card") }
                .buttonStyle(.primary)
                .padding(.top, Spacing.s)
        }
        .card()
    }

    /// Demo of app → widget data flow through the App Group.
    private var counterCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("home.counter.title").font(.headline)
            Text("home.counter.message").foregroundStyle(.secondary)
            HStack {
                Text(tapCount, format: .number)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Spacer()
                Button("home.counter.increment", systemImage: "plus") {
                    withAnimation { tapCount += 1 }
                    SharedStore.update { $0.tapCount = tapCount }
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.main)
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
            }
        }
        .card()
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("home.notification.title").font(.headline)
            Text("home.notification.message").foregroundStyle(.secondary)
            Button(notificationScheduled ? "home.notification.scheduled" : "home.notification.cta") {
                Task {
                    if !notifications.isAuthorized {
                        let granted = await notifications.requestAuthorization()
                        analytics.track(.notificationPermission(granted: granted))
                        guard granted else { return }
                    }
                    try? await notifications.scheduleTestNotification()
                    notificationScheduled = true
                }
            }
            .buttonStyle(.bordered)
            .disabled(notificationScheduled)
        }
        .card()
    }
}

#Preview {
    HomeView()
        .environment(AppContainer.preview)
}
