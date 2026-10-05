//
//  SubscriptionService.swift
//  test
//

import Foundation
import OSLog
import Observation
import StoreKit
import WidgetKit

/// Snapshot of the user's active auto-renewable subscription.
struct ActiveSubscription: Equatable {
    let productID: String
    let expirationDate: Date?
    let willAutoRenew: Bool
    let isInTrial: Bool
}

enum PurchaseOutcome {
    case success
    case pending
    case cancelled
}

enum SubscriptionError: LocalizedError {
    case failedVerification
    case productsUnavailable

    var errorDescription: String? {
        switch self {
        case .failedVerification: String(localized: "subscription.error.verification")
        case .productsUnavailable: String(localized: "subscription.error.productsUnavailable")
        }
    }
}

/// StoreKit 2 source of truth for products and entitlements.
///
/// - `start()` must be called once at launch so `Transaction.updates` (renewals, refunds,
///   Ask to Buy, purchases made on other devices) are never missed.
/// - Purchases are initiated from SwiftUI with `@Environment(\.purchase)` and the result is
///   handed to `handle(_:)`.
@Observable
final class SubscriptionService {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var activeSubscription: ActiveSubscription?
    private(set) var isLoadingProducts = false

    var isPremium: Bool { !purchasedProductIDs.isEmpty }

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private let productIDs: [String]

    init(productIDs: [String] = AppConfig.Subscription.allProductIDs) {
        self.productIDs = productIDs
    }

    func start() async {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.process(result)
            }
        }
        await refreshEntitlements()
    }

    func loadProducts() async throws {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let loaded = try await Product.products(for: productIDs)
        guard !loaded.isEmpty else { throw SubscriptionError.productsUnavailable }
        // Keep the order declared in `productIDs`.
        products = productIDs.compactMap { id in loaded.first { $0.id == id } }
    }

    @discardableResult
    func handle(_ result: Product.PurchaseResult) async throws -> PurchaseOutcome {
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// "Restore Purchases" – required by App Review. Prompts for the Apple Account password.
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var purchased: Set<String> = []
        var active: ActiveSubscription?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result), transaction.revocationDate == nil else { continue }
            purchased.insert(transaction.productID)

            if transaction.productType == .autoRenewable {
                var willAutoRenew = false
                if let status = await transaction.subscriptionStatus,
                   case .verified(let renewal) = status.renewalInfo {
                    willAutoRenew = renewal.willAutoRenew
                }
                active = ActiveSubscription(
                    productID: transaction.productID,
                    expirationDate: transaction.expirationDate,
                    willAutoRenew: willAutoRenew,
                    isInTrial: transaction.offer?.type == .introductory
                )
            }
        }

        purchasedProductIDs = purchased
        activeSubscription = active
        publishToWidget()
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Private

    private func process(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(result) else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error):
            Log.store.error("Unverified transaction: \(error.localizedDescription, privacy: .public)")
            throw SubscriptionError.failedVerification
        }
    }

    private func publishToWidget() {
        let isPremium = isPremium
        guard SharedStore.load().isPremium != isPremium else { return }
        SharedStore.update { $0.isPremium = isPremium }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.main)
    }
}

extension Product {
    /// Localised "/ month", "/ year"… suffix for subscription prices.
    var periodLabel: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        return switch period.unit {
        case .day: String(localized: "paywall.period.day")
        case .week: String(localized: "paywall.period.week")
        case .month: String(localized: "paywall.period.month")
        case .year: String(localized: "paywall.period.year")
        @unknown default: nil
        }
    }

    /// Price normalised per month, e.g. a yearly plan shown as "$2.49 / month".
    var monthlyEquivalentPrice: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let months: Decimal = switch period.unit {
        case .year: Decimal(12 * period.value)
        case .month: Decimal(period.value)
        default: 0
        }
        guard months > 0 else { return nil }
        return (price / months).formatted(priceFormatStyle)
    }
}
