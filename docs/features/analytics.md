---
tags: [feature, analytics]
status: done
updated: 2026-10-05
---

# Feature: Analytics

## Overview

Vendor-agnostic analytics. Events are defined once on `AnalyticsEvent`; `AnalyticsService` fans them out to every
registered `AnalyticsProvider` and drops everything when the user opts out (Settings toggle). The scaffold ships
only `ConsoleAnalyticsProvider` (logs to `Log.analytics`).

## Adding a Vendor

```swift
struct MyVendorProvider: AnalyticsProvider {
    func track(_ event: AnalyticsEvent) { /* vendor.log(event.name, event.parameters) */ }
    func identify(userID: String?) { /* … */ }
    func reset() { /* … */ }
}
// AppContainer.init
analytics: AnalyticsService = AnalyticsService(providers: [ConsoleAnalyticsProvider(), MyVendorProvider()])
```

## Adding an Event

1. Add a static factory in `test/Core/Analytics/AnalyticsEvent.swift` under the right `// MARK` group.
2. Name: `snake_case`, `object_action` past tense (`purchase_completed`); parameters are `[String: String]`.
3. Add a row to the table below.

## Event Catalog

| Event | Parameters | Fired from |
|-------|-----------|------------|
| `app_opened` | — | `AppContainer.bootstrap` |
| `screen_viewed` | `screen` | `.trackScreen(_:)` on every screen |
| `deep_link_opened` | `destination` | `RootView.onOpenURL` |
| `onboarding_started` | — | `OnboardingView.onAppear` |
| `onboarding_completed` | `skipped` | `OnboardingView.finish` |
| `sign_in_completed` | `method` (`apple` / `guest`) | `AuthView` |
| `sign_in_failed` | `method`, `reason` | `AuthView` |
| `signed_out` | — | `SettingsView` |
| `account_deleted` | — | `SettingsView` |
| `paywall_viewed` | `source` | `PaywallView.task` |
| `paywall_dismissed` | `source` | `PaywallView.close` |
| `purchase_started` / `purchase_completed` | `product_id` | `PaywallView.buy` |
| `purchase_failed` | `product_id`, `reason` | `PaywallView.buy` |
| `restore_completed` | — | `PaywallView.restore` |
| `notification_permission` | `granted` | `HomeView`, `NotificationSettingsView` |
| `notification_opened` | `id` | `AppDelegate` |

**Screen names** in use: `onboarding`, `auth`, `home`, `paywall`, `settings`, `notification_settings`, `subscription_status`.

**Paywall sources** in use: `launch`, `home_card`, `settings`, `subscription_status`, `deep_link`.

## Privacy

Opt-out is stored in `StorageKey.analyticsEnabled` (default on). Sign-out calls `analytics.reset()`.
Update the App Store privacy label when adding a vendor.

## Related

- [modules](../architecture/modules.md)
