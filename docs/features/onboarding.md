---
tags: [feature, onboarding, launch]
status: done
updated: 2026-10-05
---

# Feature: Splash & Onboarding

## Overview

`SplashView` shows the brand mark while `AppContainer.bootstrap()` runs (at least 1.2 s so the animation is
not cut off), then asks the router for the next phase. First-launch users see a 3-page `OnboardingView`;
finishing or skipping it sets `hasCompletedOnboarding` and moves on to Auth (or Main if already signed in).

## User Stories

- [x] See a branded screen while the app restores the session and entitlements
- [x] Swipe through 3 intro pages, or skip at any time
- [x] Never see onboarding again after completing or skipping it once

## Flow

```
SplashView.task ─ bootstrap() ─ wait remaining of 1.2 s ─ router.resolvePhase(isSignedIn:)
OnboardingView: page 1 → 2 → 3 ("Get started")  |  "Skip" (hidden on last page)
   └─ finish(skipped:) → analytics .onboardingCompleted → router.completeOnboarding(isSignedIn:)
```

## Implementation

| File | Role |
|------|------|
| `test/Features/Splash/SplashView.swift` | Animation, runs injected `bootstrap`, minimum duration |
| `test/Features/Onboarding/OnboardingView.swift` | `OnboardingPage.all` (SF Symbol + localized title/message), paging `TabView` |
| `test/App/AppRouter.swift` | `completeOnboarding`, `hasCompletedOnboarding` |

**Customize pages**: edit `OnboardingPage.all` and the `onboarding.pageN.*` strings. Keep the permission
prompts out of onboarding — ask in context (see [notifications](notifications.md)).

## Analytics

`screen_viewed(onboarding)`, `onboarding_started`, `onboarding_completed(skipped)`.

## Debug

Settings → Debug → "Reset onboarding & paywall" (`AppRouter.resetForDebug()`) returns to splash with both flags cleared.

## Related

- [data-flow](../architecture/data-flow.md#app-phases-approuter) · [auth](auth.md)
