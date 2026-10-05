//
//  SubscriptionStatusView.swift
//  test
//

import StoreKit
import SwiftUI

/// Shows the current plan and links to Apple's subscription management / refund sheets.
struct SubscriptionStatusView: View {
    @Environment(SubscriptionService.self) private var subscriptions
    @Environment(AppRouter.self) private var router

    @State private var isShowingManage = false
    @State private var refundTransactionID: UInt64?
    @State private var isShowingRefund = false

    var body: some View {
        Form {
            if let active = subscriptions.activeSubscription {
                Section("subscription.section.plan") {
                    LabeledContent("subscription.plan") {
                        Text(subscriptions.product(for: active.productID)?.displayName ?? active.productID)
                    }
                    LabeledContent("subscription.status") {
                        Text(active.isInTrial ? "subscription.status.trial" : "subscription.status.active")
                            .foregroundStyle(.green)
                    }
                    if let expiration = active.expirationDate {
                        LabeledContent(active.willAutoRenew ? "subscription.renews" : "subscription.expires") {
                            Text(expiration, format: .dateTime.day().month().year())
                        }
                    }
                }

                Section {
                    Button("subscription.manage") { isShowingManage = true }
                    Button("subscription.refund") {
                        Task {
                            refundTransactionID = await latestTransactionID(for: active.productID)
                            isShowingRefund = refundTransactionID != nil
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("subscription.none.title", systemImage: "crown")
                } description: {
                    Text("subscription.none.message")
                } actions: {
                    Button("settings.subscription.upgrade") { router.presentPaywall(source: "subscription_status") }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("subscription.title")
        .manageSubscriptionsSheet(isPresented: $isShowingManage, subscriptionGroupID: AppConfig.Subscription.groupID)
        .refundRequestSheet(for: refundTransactionID ?? 0, isPresented: $isShowingRefund)
        .task { await subscriptions.refreshEntitlements() }
        .onChange(of: isShowingManage) { _, isShowing in
            if !isShowing { Task { await subscriptions.refreshEntitlements() } }
        }
        .trackScreen("subscription_status")
    }

    private func latestTransactionID(for productID: String) async -> UInt64? {
        guard case .verified(let transaction) = await Transaction.latest(for: productID) else { return nil }
        return transaction.id
    }
}

#Preview {
    NavigationStack {
        SubscriptionStatusView()
    }
    .environment(AppContainer.preview)
}
