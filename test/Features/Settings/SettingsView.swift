//
//  SettingsView.swift
//  test
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth
    @Environment(SubscriptionService.self) private var subscriptions
    @Environment(AnalyticsService.self) private var analytics
    @Environment(\.openURL) private var openURL

    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var router = router
        @Bindable var analytics = analytics

        NavigationStack {
            Form {
                accountSection
                subscriptionSection

                Section("settings.section.preferences") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("settings.notifications", systemImage: "bell")
                    }

                    // iOS manages per-app language in the Settings app (driven by the String Catalog).
                    Button {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        LabeledContent {
                            Text(currentLanguageName)
                        } label: {
                            Label("settings.language", systemImage: "globe")
                        }
                    }
                    .foregroundStyle(.primary)

                    Toggle(isOn: $analytics.isEnabled) {
                        Label("settings.analytics", systemImage: "chart.bar")
                    }
                }

                Section("settings.section.about") {
                    Link(destination: AppConfig.writeReviewURL) {
                        Label("settings.rate", systemImage: "star")
                    }
                    Link(destination: URL(string: "mailto:\(AppConfig.supportEmail)")!) {
                        Label("settings.support", systemImage: "envelope")
                    }
                    Link(destination: AppConfig.privacyPolicyURL) {
                        Label("settings.privacy", systemImage: "hand.raised")
                    }
                    Link(destination: AppConfig.termsOfUseURL) {
                        Label("settings.terms", systemImage: "doc.text")
                    }
                    LabeledContent("settings.version", value: AppConfig.appVersion)
                }

                #if DEBUG
                Section("Debug") {
                    Button("Reset onboarding & paywall") { router.resetForDebug() }
                    Button("Open paywall deep link") { router.open(.paywall) }
                }
                #endif
            }
            .navigationTitle("settings.title")
            .navigationDestination(isPresented: $router.isShowingSubscription) {
                SubscriptionStatusView()
            }
            .confirmationDialog("settings.delete.title", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("settings.delete.confirm", role: .destructive) { deleteAccount() }
            } message: {
                Text("settings.delete.message")
            }
            .errorAlert($errorMessage)
        }
        .trackScreen("settings")
    }

    // MARK: Sections

    private var accountSection: some View {
        Section("settings.section.account") {
            if let user = auth.currentUser {
                LabeledContent("settings.account.name", value: user.displayName ?? String(localized: "settings.account.guest"))
                if let email = user.email {
                    LabeledContent("settings.account.email", value: email)
                }
            }
            Button("settings.signOut") {
                Task {
                    await auth.signOut()
                    analytics.track(.signedOut)
                    analytics.reset()
                }
            }
            Button("settings.delete", role: .destructive) { isConfirmingDelete = true }
        }
    }

    private var subscriptionSection: some View {
        Section("settings.section.subscription") {
            if subscriptions.isPremium {
                NavigationLink {
                    SubscriptionStatusView()
                } label: {
                    Label("settings.subscription.manage", systemImage: "crown.fill")
                }
            } else {
                Button {
                    router.presentPaywall(source: "settings")
                } label: {
                    Label("settings.subscription.upgrade", systemImage: "crown")
                }
            }
            Button("paywall.restore") {
                Task {
                    do { try await subscriptions.restore() } catch { errorMessage = error.localizedDescription }
                }
            }
        }
    }

    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale.current.localizedString(forIdentifier: code) ?? code
    }

    private func deleteAccount() {
        Task {
            do {
                try await auth.deleteAccount()
                analytics.track(.accountDeleted)
                analytics.reset()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppContainer.preview)
}
