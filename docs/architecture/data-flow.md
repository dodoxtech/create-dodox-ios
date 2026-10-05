---
tags: [architecture, data-flow, navigation]
updated: 2026-10-05
---

# Data Flow

## Launch Sequence

```
TestApp
 └─ AppDelegate.container (AppContainer, created before didFinishLaunching)
     └─ RootView(bootstrap: container.bootstrap)      phase = .splash
         └─ SplashView.task
             ├─ container.bootstrap()
             │    1. subscriptions.start()        → listen to Transaction.updates, refresh entitlements
             │    2. auth.restoreSession()        → Keychain session; Apple credential revoked → cleared
             │    3. notifications.refreshStatus() → authorized → registerForRemoteNotifications
             │    4. analytics.identify + .appOpened
             │    5. Task { loadProducts() }      → warms the paywall, never blocks launch
             └─ router.resolvePhase(isSignedIn:)
```

Keep `bootstrap()` fast and offline-safe — the user is staring at the splash screen.

## App Phases (`AppRouter`)

```
.splash ──▶ hasCompletedOnboarding? ──no──▶ .onboarding ──completeOnboarding──┐
                 │yes                                                            │
                 ▼                                                               ▼
            isSignedIn? ──no──▶ .auth ──sign in──▶ (RootView.onChange) ──▶ resolvePhase
                 │yes
                 ▼
               .main  (MainTabView: Home | Settings, paywall sheet)
```

- `resolvePhase(isSignedIn:)` is the only place that decides the phase. Call it — don't set phases ad hoc.
- `RootView` re-resolves whenever `auth.isSignedIn` changes (outside splash), so sign-out or account deletion
  automatically returns to `.auth`.
- `hasCompletedOnboarding` is in `UserDefaults` (`StorageKey.hasCompletedOnboarding`).

## Deep Links

Sources: URL scheme `testapp://<host>` (`.onOpenURL`), widget `widgetURL`/`Link`, notification `userInfo["deepLink"]`.

```
URL ─▶ DeepLink(url:) ─▶ router.open(link)
                           phase != .main → stored in pendingDeepLink, replayed when phase becomes .main
                           .home / .settings → selectedTab
                           .paywall          → presentPaywall(source: "deep_link")
                           .subscription     → Settings tab + isShowingSubscription
```

Details: [deep-links](../features/deep-links.md).

## Persistence Map

| Data | Store | Owner |
|------|-------|-------|
| Session (`AppUser`) | Keychain, key `auth.session`, `AfterFirstUnlockThisDeviceOnly` | `AuthService` |
| Onboarding done, launch paywall seen | `UserDefaults.standard` (`StorageKey`) | `AppRouter`, `MainTabView` (`@AppStorage`) |
| Analytics opt-in | `UserDefaults.standard` | `AnalyticsService` |
| Daily reminder on/off + time | `UserDefaults.standard` | `NotificationService` |
| Entitlements | StoreKit (`Transaction.currentEntitlements`) — never cached by the app | `SubscriptionService` |
| Widget snapshot | App Group `UserDefaults`, key `shared.widgetSnapshot` | `SharedStore` |

## Widget Data Flow

```
AuthService.persist / clearSession ─┐
SubscriptionService.refreshEntitlements ─┼─▶ SharedStore.update { … } ─▶ App Group defaults
HomeView tap counter ───────────────┘                                     │
                                         WidgetCenter.reloadTimelines ─▶ SnapshotProvider ─▶ SharedStore.load()
```

`SubscriptionService` reloads timelines only when `isPremium` actually changes. When adding new widget data,
reload explicitly after writing.

## Purchases

```
PaywallView ─ @Environment(\.purchase)(product) ─▶ subscriptions.handle(result)
                                                     verified → transaction.finish() → refreshEntitlements()
Transaction.updates (renewals, refunds, Ask to Buy, other devices) ─▶ process → finish → refreshEntitlements()
```

`isPremium` = any verified, non-revoked entitlement. Details: [subscription](../features/subscription.md).

## Related

- [modules](modules.md) · [overview](overview.md)
