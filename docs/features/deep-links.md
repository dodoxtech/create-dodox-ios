---
tags: [feature, navigation, deep-links]
status: done
updated: 2026-10-05
---

# Feature: Deep Links

## Overview

`DeepLink` (in `Shared/`, so the widget can build URLs) enumerates every destination reachable from outside the
app. All entry points funnel into `AppRouter.open(_:)`; links arriving before the main UI exists are queued and
replayed when the phase becomes `.main`.

## Destinations

| URL | Case | Result |
|-----|------|--------|
| `testapp://home` | `.home` | Home tab |
| `testapp://settings` | `.settings` | Settings tab |
| `testapp://paywall` | `.paywall` | Paywall sheet (`source: "deep_link"`) |
| `testapp://subscription` | `.subscription` | Settings tab → `SubscriptionStatusView` |

## Entry Points

| Source | Code |
|--------|------|
| URL scheme (Safari, other apps, `simctl openurl`) | `RootView.onOpenURL` (+ `deep_link_opened` event) |
| Widget | `.widgetURL(DeepLink.home.url)`, `Link(destination: DeepLink.paywall.url)` |
| Notification tap | `AppDelegate.userNotificationCenter(_:didReceive:)` reads `userInfo["deepLink"]` |

## Adding a Destination

1. Add a case to `Shared/DeepLink.swift` (raw value = URL host).
2. Handle it in the `switch` in `AppRouter.open(_:)` (the compiler forces this).
3. Add a row above.

Universal links need an Associated Domains entitlement + `apple-app-site-association`; then map the path to a
`DeepLink` in `.onOpenURL`.

## Verify

```bash
xcrun simctl openurl booted testapp://subscription
```

## Related

- [data-flow](../architecture/data-flow.md#deep-links) · [widget](widget.md) · [notifications](notifications.md)
