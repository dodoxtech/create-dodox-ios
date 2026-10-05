---
tags: [architecture, modules]
updated: 2026-10-05
---

# Modules

There are no frameworks or packages — "modules" are folders inside two targets. The dependency rules below are
conventions, so keep them when adding code.

## Dependency Graph

```
test (app target)
├── App/         → depends on Core, Features, Shared
├── Features/    → depends on Core, Shared   (never on another feature; cross-screen = AppRouter)
├── Core/        → depends on Shared         (never on Features)
└── Shared/      → Foundation only

TestWidget (extension target)
└── depends on Shared only  (+ SwiftUI / WidgetKit)
```

## App — `test/App/`

| File | Responsibility |
|------|----------------|
| `TestApp.swift` | `@main`; mounts `RootView` with the container from `AppDelegate` |
| `AppDelegate.swift` | Owns `AppContainer` (exists before any delegate callback); APNs token callbacks; `UNUserNotificationCenterDelegate` (foreground banners, tap → deep link) |
| `AppContainer.swift` | Composition root: builds every service, `bootstrap()` launch work, `View.environment(_ container:)`, `AppContainer.preview` for `#Preview` |
| `AppRouter.swift` | `AppPhase`, `MainTab`, paywall presentation, `open(DeepLink)` with pending-link queue |
| `RootView.swift` | Switches on `router.phase`; reacts to sign-in changes; `.onOpenURL` |
| `MainTabView.swift` | `TabView` (Home, Settings), paywall sheet, one-time launch paywall |

## Core — `test/Core/`

| Folder | Main types | Notes |
|--------|-----------|-------|
| `Analytics/` | `AnalyticsEvent`, `AnalyticsService`, `AnalyticsProvider`, `ConsoleAnalyticsProvider`, `.trackScreen()` | Opt-out stored in `StorageKey.analyticsEnabled` |
| `Auth/` | `AuthService`, `AppUser`, `AuthClient`, `LocalAuthClient`, `KeychainStore` | `LocalAuthClient` is on-device only — replace for production |
| `Subscription/` | `SubscriptionService`, `ActiveSubscription`, `PurchaseOutcome`, `Product.periodLabel` / `.monthlyEquivalentPrice` | Must `start()` at launch to observe `Transaction.updates` |
| `Notifications/` | `NotificationService` | Permission, APNs token, daily reminder, sample notification |
| `Config/` | `AppConfig`, `AppConfig.Subscription`, `StorageKey` | Placeholders to replace before shipping |
| `DesignSystem/` | `Spacing`, `PrimaryButtonStyle` (`.primary`), `.card()`, `.errorAlert(_:)` | See [design-system](../design/design-system.md) |
| `Localization/` | `Localizable.xcstrings` | en / vi / ja |
| `Logging/` | `Log.app`, `.auth`, `.analytics`, `.store`, `.notifications` | Subsystem = bundle ID |

## Services in `AppContainer`

| Service | Injected deps (defaults) | Read by |
|---------|--------------------------|---------|
| `AppRouter` | `UserDefaults.standard` | almost every view |
| `AnalyticsService` | `[ConsoleAnalyticsProvider()]` | every screen (`.trackScreen`) |
| `AuthService` | `LocalAuthClient()`, `KeychainStore()` | Splash, Onboarding, Auth, Home, Settings, `RootView` |
| `SubscriptionService` | `AppConfig.Subscription.allProductIDs` | Home, Paywall, Settings, SubscriptionStatus, `MainTabView` |
| `NotificationService` | `UNUserNotificationCenter.current()`, `UserDefaults.standard` | Home, NotificationSettings, `AppDelegate` |

## Features — `test/Features/`

| Folder | Views | Doc |
|--------|-------|-----|
| `Splash/` | `SplashView` | [onboarding](../features/onboarding.md) |
| `Onboarding/` | `OnboardingView`, `OnboardingPage` | [onboarding](../features/onboarding.md) |
| `Auth/` | `AuthView` | [auth](../features/auth.md) |
| `Home/` | `HomeView` (demo content: premium card, tap counter → widget, notification prompt) | — |
| `Paywall/` | `PaywallView`, `ProductRow` | [subscription](../features/subscription.md) |
| `Subscription/` | `SubscriptionStatusView` | [subscription](../features/subscription.md) |
| `Settings/` | `SettingsView`, `NotificationSettingsView` | [settings](../features/settings.md), [notifications](../features/notifications.md) |

## Shared — `Shared/` (app + widget)

| File | Types |
|------|-------|
| `AppGroup.swift` | `AppGroup.identifier` / `.defaults`, `WidgetKind.main` |
| `SharedStore.swift` | `WidgetSnapshot`, `SharedStore.load/save/update` |
| `DeepLink.swift` | `DeepLink` (+ `scheme`, `url`, `init?(url:)`) |

Everything here is `nonisolated` and `Sendable`-friendly because the widget process compiles it without the app's
`MainActor` default.

## Widget — `TestWidget/`

`TestWidgetBundle` → `TestWidget` (`StaticConfiguration`, small + medium) with `SnapshotProvider`. See [widget](../features/widget.md).

## Related

- [overview](overview.md) · [data-flow](data-flow.md)
