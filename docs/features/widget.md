---
tags: [feature, widget, widgetkit]
status: done
updated: 2026-10-05
---

# Feature: Home-Screen Widget

## Overview

`TestWidget` (small + medium) renders a `WidgetSnapshot` the app writes to the App Group. The widget never runs
app services; it only reads `SharedStore`. Taps deep-link back into the app.

## What It Shows

| Family | Content | Tap |
|--------|---------|-----|
| Small | Tap counter (from Home), premium crown | `testapp://home` |
| Medium | Small content + greeting with user name + premium badge or "Upgrade" link | Upgrade → `testapp://paywall` |

## Data Contract — `WidgetSnapshot`

| Field | Written by |
|-------|-----------|
| `userName` | `AuthService.persist` / `clearSession` |
| `isPremium` | `SubscriptionService.publishToWidget` (reloads timelines on change) |
| `tapCount` | `HomeView` demo counter |
| `updatedAt` | `SharedStore.update` (automatic) |

## Implementation

| File | Role |
|------|------|
| `TestWidget/TestWidget.swift` | `SnapshotProvider` (hourly refresh policy), `TestWidgetEntryView`, `TestWidget` config, previews |
| `TestWidget/TestWidgetBundle.swift` | `@main` bundle |
| `TestWidget/Localizable.xcstrings` | Widget strings (`widget.*`) |
| `Shared/SharedStore.swift`, `Shared/AppGroup.swift` | Snapshot storage, `AppGroup.identifier`, `WidgetKind.main` |

## Adding Widget Data

1. Add a field to `WidgetSnapshot` (and to `.empty` / `.placeholder`). Keep it `Codable` — old data that fails to
   decode falls back to `.empty`.
2. Write it from the app with `SharedStore.update { $0.field = … }`.
3. Call `WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.main)`.

## Gotchas

- App Group `group.dodoxtech.test` must be in **both** entitlements files and match `AppGroup.identifier`.
- `Shared/` code must stay `nonisolated` — the extension has no `MainActor` default.
- Replace the demo tap counter with real app data before shipping.

## Related

- [data-flow](../architecture/data-flow.md#widget-data-flow) · [deep-links](deep-links.md)
