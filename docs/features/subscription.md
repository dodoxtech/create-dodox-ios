---
tags: [feature, monetization, storekit]
status: done
updated: 2026-10-05
---

# Feature: Paywall & Subscription

## Overview

StoreKit 2 auto-renewable subscriptions (monthly + yearly with a 1-week free trial in the local catalog).
`SubscriptionService` is the single source of truth for products and entitlements; `PaywallView` sells,
`SubscriptionStatusView` shows the active plan with manage/refund actions.

## Products

| Constant | Product ID | Local catalog |
|----------|-----------|---------------|
| `AppConfig.Subscription.yearly` | `dodoxtech.test.premium.yearly` | 29.99 / year, 1-week free trial |
| `AppConfig.Subscription.monthly` | `dodoxtech.test.premium.monthly` | 4.99 / month |
| `AppConfig.Subscription.groupID` | `21000001` | subscription group (manage sheet) |

Order on the paywall follows `allProductIDs` (yearly first, preselected).

## User Stories

- [x] See the paywall once after first reaching Main (soft paywall, skipped if already premium)
- [x] Open it from Home card, Settings, Subscription screen or `testapp://paywall`
- [x] Buy with trial-aware CTA, restore purchases, read Terms & Privacy
- [x] See plan, trial/active state and renewal/expiry date; manage or request a refund in-app

## Flow

```
router.presentPaywall(source:) ─▶ MainTabView .sheet ─▶ PaywallView(source:)
   .task → paywall_viewed + loadProducts()
   CTA   → purchase(product) → subscriptions.handle(result) → finish + refreshEntitlements
   isPremium becomes true → dismiss automatically
```

## Implementation

| File | Role |
|------|------|
| `test/Core/Subscription/SubscriptionService.swift` | `start()` (must run at launch), `loadProducts`, `handle`, `restore`, `refreshEntitlements`, widget publish, `Product.periodLabel` / `monthlyEquivalentPrice` |
| `test/Features/Paywall/PaywallView.swift` | Header, feature list, `ProductRow`s, footer with CTA / Restore / legal links |
| `test/Features/Subscription/SubscriptionStatusView.swift` | Plan details, `.manageSubscriptionsSheet`, `.refundRequestSheet` |
| `test/App/MainTabView.swift` | Launch paywall (`StorageKey.hasSeenLaunchPaywall`) and paywall sheet |
| `Configuration/Products.storekit` | Local StoreKit config, attached to the shared scheme |

**Rules**: gate premium features on `subscriptions.isPremium` only; never cache entitlement state yourself.
Always pass a meaningful `source` (snake_case) to `presentPaywall` — it feeds analytics.

## Analytics

`paywall_viewed(source)`, `paywall_dismissed(source)`, `purchase_started|completed|failed(product_id)`, `restore_completed`.

## App Review Checklist

Restore button, Terms (EULA) + Privacy links on the paywall, price + period visible, trial wording via
`paywall.cta.trial`. See [release-checklist](../setup/release-checklist.md).

## Related

- [data-flow](../architecture/data-flow.md#purchases) · [widget](widget.md)
