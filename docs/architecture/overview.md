---
tags: [architecture]
updated: 2026-10-05
---

# Architecture Overview

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift, language mode 5 (`SWIFT_VERSION = 5.0`) + `MemberImportVisibility` upcoming feature |
| UI | SwiftUI, iOS 27.0+ |
| State | Observation (`@Observable`), injected through the SwiftUI environment |
| Concurrency | Default actor isolation `MainActor`, approachable concurrency; `Shared/` is `nonisolated` |
| Purchases | StoreKit 2 (`Product`, `Transaction`, `@Environment(\.purchase)`) |
| Auth | Sign in with Apple (`AuthenticationServices`) + guest mode, session in Keychain |
| Notifications | `UserNotifications` (local reminders) + APNs registration |
| Widget | WidgetKit `StaticConfiguration`, data via App Group `UserDefaults` |
| Logging | `os.Logger` (`Log`) |
| Localization | String Catalog (`Localizable.xcstrings`): en (source), vi, ja |
| Build | Plain Xcode project with synchronized folders — no Tuist, no SPM dependencies |

## Targets

| Target | Type | Bundle ID | Sources |
|--------|------|-----------|---------|
| `test` | iOS app | `dodoxtech.test` | `test/`, `Shared/` |
| `TestWidget` | Widget extension (embedded in the app) | `dodoxtech.test.TestWidget` | `TestWidget/`, `Shared/` |

## Capabilities & Entitlements

| Capability | Where | Notes |
|------------|-------|-------|
| Sign in with Apple | `Configuration/test.entitlements` | |
| Push Notifications | `Configuration/test.entitlements` | `aps-environment = development`; distribution signing switches to production |
| App Groups | both entitlements files | `group.dodoxtech.test` — must match `AppGroup.identifier` |
| Background mode: remote notifications | `test/Info.plist` | `UIBackgroundModes` |
| In-App Purchase | App Store Connect | local catalog: `Configuration/Products.storekit` |

## Layering

```
Features (SwiftUI views)  ──reads──▶  Services via @Environment  ──uses──▶  Seams (AuthClient, AnalyticsProvider)
        │                                   │                                 Apple frameworks (StoreKit, UN, Keychain)
        └──── navigation ────▶  AppRouter   └──── widget data ────▶  SharedStore (App Group) ◀── TestWidget
```

- **App layer** (`test/App/`) wires everything: `AppDelegate` owns the `AppContainer`, `RootView` switches phases.
- **Core** (`test/Core/`) holds services and cross-cutting helpers; it never imports a feature.
- **Features** (`test/Features/`) are leaf screens; they talk to each other only through `AppRouter`.
- **Shared** (`Shared/`) is the only code the widget sees.

## Related

- [modules](modules.md) · [data-flow](data-flow.md) · [decisions](../decisions/README.md)
