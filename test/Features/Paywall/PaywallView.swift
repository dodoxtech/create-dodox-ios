//
//  PaywallView.swift
//  test
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    /// Analytics label for where the paywall was opened from (e.g. "launch", "home_card", "settings").
    let source: String

    @Environment(SubscriptionService.self) private var subscriptions
    @Environment(AnalyticsService.self) private var analytics
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID = AppConfig.Subscription.yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let features: [(icon: String, title: LocalizedStringKey)] = [
        ("infinity", "paywall.feature.unlimited"),
        ("rectangle.stack.badge.plus", "paywall.feature.widgets"),
        ("bell.badge", "paywall.feature.reminders"),
        ("nosign", "paywall.feature.noAds"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    header
                    featureList
                    productList
                }
                .padding(Spacing.l)
            }
            .safeAreaInset(edge: .bottom) { footer }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close", systemImage: "xmark") { close() }
                }
            }
        }
        .interactiveDismissDisabled(isPurchasing)
        .task {
            analytics.track(.paywallViewed(source: source))
            do {
                try await subscriptions.loadProducts()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .onChange(of: subscriptions.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
        .errorAlert($errorMessage)
        .trackScreen("paywall")
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow.gradient)
            Text("paywall.title")
                .font(.largeTitle.bold())
            Text("paywall.subtitle")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(features, id: \.icon) { feature in
                Label(feature.title, systemImage: feature.icon)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private var productList: some View {
        if subscriptions.products.isEmpty {
            ProgressView().frame(height: 140)
        } else {
            VStack(spacing: Spacing.s) {
                ForEach(subscriptions.products) { product in
                    ProductRow(product: product, isSelected: product.id == selectedProductID)
                        .onTapGesture { selectedProductID = product.id }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.s) {
            Button {
                Task { await buy() }
            } label: {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(.primary)
            .disabled(isPurchasing || subscriptions.product(for: selectedProductID) == nil)

            HStack(spacing: Spacing.m) {
                Button("paywall.restore") { Task { await restore() } }
                Link("settings.terms", destination: AppConfig.termsOfUseURL)
                Link("settings.privacy", destination: AppConfig.privacyPolicyURL)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.s)
        .background(.bar)
    }

    private var ctaTitle: LocalizedStringKey {
        let hasTrial = subscriptions.product(for: selectedProductID)?.subscription?.introductoryOffer != nil
        return hasTrial ? "paywall.cta.trial" : "paywall.cta.subscribe"
    }

    // MARK: Actions

    private func buy() async {
        guard let product = subscriptions.product(for: selectedProductID) else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        analytics.track(.purchaseStarted(productID: product.id))
        do {
            let outcome = try await subscriptions.handle(purchase(product))
            if outcome == .success {
                analytics.track(.purchaseCompleted(productID: product.id))
            }
        } catch {
            analytics.track(.purchaseFailed(productID: product.id, reason: error.localizedDescription))
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await subscriptions.restore()
            analytics.track(.restoreCompleted)
            if !subscriptions.isPremium {
                errorMessage = String(localized: "paywall.restore.nothing")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func close() {
        analytics.track(.paywallDismissed(source: source))
        dismiss()
    }
}

private struct ProductRow: View {
    let product: Product
    let isSelected: Bool

    private var isYearly: Bool { product.subscription?.subscriptionPeriod.unit == .year }

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(product.displayName).font(.headline)
                    if isYearly {
                        Text("paywall.badge.bestValue")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.yellow, in: .capsule)
                            .foregroundStyle(.black)
                    }
                }
                if isYearly, let monthly = product.monthlyEquivalentPrice {
                    Text("paywall.perMonth \(monthly)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(verbatim: product.displayPrice + (product.periodLabel ?? ""))
                .font(.headline)
        }
        .padding(Spacing.m)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PaywallView(source: "preview")
        .environment(AppContainer.preview)
}
