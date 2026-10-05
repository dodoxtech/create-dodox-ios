---
tags: [setup, release]
updated: 2026-10-05
---

# Release Checklist

Everything the scaffold leaves as a placeholder or demo. Tick it all before the first App Store submission.

## Configuration

- [ ] `AppConfig.appStoreID` — real App Store ID (rate link)
- [ ] `AppConfig.privacyPolicyURL`, `termsOfUseURL`, `supportEmail`
- [ ] `app.name` string (en / vi / ja) and display name
- [ ] App icon in `test/Assets.xcassets/AppIcon.appiconset`, `AccentColor`

## Signing & Capabilities

- [ ] Bundle IDs `dodoxtech.test` / `dodoxtech.test.TestWidget` registered for your team
- [ ] App Group `group.dodoxtech.test` on both targets
- [ ] Sign in with Apple, Push Notifications enabled; `aps-environment` = production for distribution

## Subscriptions

- [ ] Products and subscription group created in App Store Connect, IDs match `AppConfig.Subscription`
- [ ] `AppConfig.Subscription.groupID` = real group ID
- [ ] Paywall copy matches the real offers (trial length, prices come from StoreKit)
- [ ] Restore, Terms (EULA) and Privacy visible on the paywall

## Backend & Services

- [ ] Real `AuthClient` (token exchange, account deletion + Apple token revocation)
- [ ] APNs token upload in `NotificationService.didRegisterForRemoteNotifications`
- [ ] Real `AnalyticsProvider`(s) wired in `AppContainer`; privacy label updated

## Content

- [ ] Onboarding pages, paywall features and Home replaced with real content
- [ ] Widget shows real data (replace the demo tap counter)
- [ ] All strings translated (en / vi / ja); no hardcoded copy outside DEBUG

## Store

- [ ] Privacy nutrition label, age rating, screenshots, review notes (guest sign-in path for reviewers)
