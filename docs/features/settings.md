---
tags: [feature, settings]
status: done
updated: 2026-10-05
---

# Feature: Settings

## Overview

`SettingsView` is a `Form` in its own `NavigationStack` (Settings tab). It collects account, subscription,
preferences and about/legal entries, plus a DEBUG-only section.

## Sections

| Section | Rows | Backed by |
|---------|------|-----------|
| Account | Name (or "Guest"), email, Sign out, Delete account (confirmation dialog) | `AuthService`, analytics `reset()` on sign-out |
| Subscription | Manage (premium) → `SubscriptionStatusView` / Upgrade → paywall; Restore | `SubscriptionService`, `AppRouter` |
| Preferences | Notifications → `NotificationSettingsView`; Language → iOS Settings; Analytics toggle | `NotificationService`, `AnalyticsService.isEnabled` |
| About | Rate (`AppConfig.writeReviewURL`), Support mail, Privacy, Terms, Version | `AppConfig` |
| Debug (DEBUG only) | Reset onboarding & paywall, open paywall deep link | `AppRouter.resetForDebug()` |

`router.isShowingSubscription` drives a `navigationDestination` so `testapp://subscription` can push the status screen.

## Notes

- Per-app language is handled by iOS (Settings app → App → Language), not an in-app picker. See [localization](localization.md).
- Account deletion is required by App Review for apps with account creation.

## Related

- [auth](auth.md) · [subscription](subscription.md) · [notifications](notifications.md)
