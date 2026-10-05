---
tags: [adr, monetization]
status: accepted
date: 2026-10-05
---

# ADR-0003: Native StoreKit 2 for Subscriptions

## Context

Subscription apps need products, purchases, entitlement checks, restore, manage and refund flows. Options:
StoreKit 2 directly, or a third-party SDK (RevenueCat, Adapty…) that adds server-side receipts, cross-platform
entitlements and paywall experiments.

## Decision

Use StoreKit 2 directly in `SubscriptionService`:

- Entitlements come from `Transaction.currentEntitlements` (verified, not revoked) — the app never caches them.
- `Transaction.updates` is observed from launch (`start()` in `bootstrap`).
- Purchases use SwiftUI's `@Environment(\.purchase)`; manage/refund use the system sheets.
- `Configuration/Products.storekit` mirrors App Store Connect for offline simulator testing.

## Consequences

- ✅ No SDK, no extra account or fees; works offline in the simulator.
- ⚠️ No server-side validation, cross-platform entitlements or remote paywall config. If those become needed,
  write a new ADR and wrap the SDK behind `SubscriptionService` so views don't change.
