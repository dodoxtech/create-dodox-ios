---
tags: [design, design-system, tokens]
updated: 2026-10-05
---

# Design System

All shared styles live in `test/Core/DesignSystem/DesignSystem.swift`. The scaffold is intentionally minimal and
leans on system styles — grow the token set here as the app gets its own visual identity, and record every
addition in this file.

## Tokens

### Spacing

| Token | Value | Typical use |
|-------|-------|-------------|
| `Spacing.xs` | 4 | icon ↔ label |
| `Spacing.s` | 8 | inside a group |
| `Spacing.m` | 16 | card padding, between rows |
| `Spacing.l` | 24 | screen padding, between sections |
| `Spacing.xl` | 32 | hero spacing |

```swift
// ✅
VStack(spacing: Spacing.l) { … }.padding(Spacing.l)
// ❌
VStack(spacing: 24) { … }.padding(22)
```

### Color

- Brand color = `AccentColor` in `test/Assets.xcassets` → use `.tint` / `Color.accentColor`.
- Everything else uses semantic system styles (`.primary`, `.secondary`, `.background`, `.background.secondary`)
  so Dark Mode works for free. Add named colors to the asset catalog (Any + Dark), never `Color(red:…)` literals.

### Typography

System text styles only (`.largeTitle.bold()`, `.headline`, `.footnote`) so Dynamic Type works. Fixed sizes are
reserved for decorative SF Symbols (splash, paywall header).

## Components

| API | What | Where used |
|-----|------|-----------|
| `.buttonStyle(.primary)` | Full-width capsule CTA, min height 52, press scale, dimmed when disabled | Onboarding, Paywall |
| `.card()` | Padding `Spacing.m`, secondary background, 20 pt corners | Paywall feature list, Home |
| `.errorAlert($message)` | Alert shown while `String?` is non-nil (`common.error` / `common.ok`) | Auth, Paywall, Settings |
| `.trackScreen("name")` | Analytics screen view (lives in `Core/Analytics`) | every screen |

## UI Rules

- One primary CTA per screen; secondary actions are plain buttons or links.
- Use `ContentUnavailableView` for empty states (see `SubscriptionStatusView`).
- Every view ships a `#Preview` using `.environment(AppContainer.preview)`.
- Respect Dynamic Type and Dark Mode; check both before marking a task done.

## Related

- [localization](../features/localization.md)
