# iOS App Scaffold

SwiftUI scaffold (iOS 27, Swift Observation, StoreKit 2, WidgetKit) with the building blocks most subscription apps need.

<!-- cli:start -->
## Create a new app from this scaffold

This repo doubles as the source of the `create-dodox-ios` generator (in [`cli/`](cli/)):

```bash
npx create-dodox-ios@latest            # once published to npm
node cli/index.mjs "My App"            # from a local checkout (run `npm run build-template` in cli/ first)
```

It asks for the app name, bundle ID, Team ID and URL scheme, then renames targets, folders, bundle IDs,
App Group, product IDs and the scheme. Keep developing the scaffold here as a normal Xcode project; the
template is regenerated from it by `npm run build-template` (and automatically on `npm pack` / `npm publish`).
<!-- cli:end -->

## Flow

```
Splash ──bootstrap──▶ Onboarding (first launch) ──▶ Auth (signed out) ──▶ Main (TabView)
                                                                          ├─ Home
                                                                          ├─ Settings ─▶ Notifications / Subscription
                                                                          └─ Paywall (sheet: launch, CTA, deep link)
```

`AppRouter` owns the phase, selected tab and modal presentations. Deep links (`testapp://home|settings|paywall|subscription`) come from widgets, notifications or URLs and are queued until the main UI is ready.

## Layout

| Path | Contents |
|---|---|
| `test/App` | Entry point, `AppDelegate` (APNs + notification delivery), `AppContainer` (composition root / DI), `AppRouter`, `RootView`, `MainTabView` |
| `test/Core/Analytics` | `AnalyticsEvent` taxonomy, `AnalyticsService` fan-out + opt-out, `AnalyticsProvider` protocol, `.trackScreen()` |
| `test/Core/Auth` | `AuthService` (Sign in with Apple, guest, sign out, delete account), `AuthClient` backend seam, `KeychainStore` |
| `test/Core/Subscription` | `SubscriptionService` – StoreKit 2 products, purchase handling, `Transaction.updates`, entitlements, restore |
| `test/Core/Notifications` | `NotificationService` – permission, APNs token, daily reminder, sample notification |
| `test/Core/Localization` | `Localizable.xcstrings` (en / vi / ja) |
| `test/Core/Config`, `DesignSystem`, `Logging` | Constants & storage keys, button/card styles, `os.Logger` categories |
| `test/Features/*` | Splash, Onboarding, Auth, Home, Paywall, Settings, Subscription screens |
| `Shared/` | Compiled into **both** app and widget: App Group, `SharedStore` / `WidgetSnapshot`, `DeepLink` |
| `TestWidget/` | Widget extension (small + medium) reading data from the App Group |
| `Configuration/` | Entitlements and `Products.storekit` (local StoreKit testing, wired into the shared `test` scheme) |
| `docs/` | Architecture, feature docs, ADRs, setup, AI task workflow and templates — start at [`docs/README.md`](docs/README.md) |
| `AGENTS.md` / `CLAUDE.md` | Rules and recipes for AI coding agents (`CLAUDE.md` imports `AGENTS.md`) |

## Adding things

- **Analytics vendor**: implement `AnalyticsProvider`, add it in `AppContainer.init`.
- **Real backend auth**: implement `AuthClient` (send Apple `identityToken` to your server) and pass it to `AuthService`.
- **New product**: add the ID to `AppConfig.Subscription` and to `Products.storekit` / App Store Connect.
- **New screen**: create `test/Features/<Name>/` – files are picked up automatically (synchronized folders).
- **New string**: use a semantic key (`"feature.thing"`) in `Text`/`String(localized:)` and add translations in the String Catalog.

## Before shipping

- Replace placeholders in `AppConfig` (App Store ID, privacy URL, support email) and the `app.name` string.
- Bundle ID `dodoxtech.test`, App Group `group.dodoxtech.test` and capabilities (Sign in with Apple, Push, App Groups) must exist for your team – Xcode's automatic signing registers them on first device build.
- Switch `aps-environment` to `production` via the distribution profile, and add an app icon.
