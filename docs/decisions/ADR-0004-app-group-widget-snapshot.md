---
tags: [adr, widget]
status: accepted
date: 2026-10-05
---

# ADR-0004: Widget Reads a Snapshot from the App Group

## Context

The widget extension runs in a separate process with tight memory/time limits. It cannot use the app's services
(Keychain session, StoreKit listener, `MainActor` state).

## Decision

- The app publishes a small `Codable` `WidgetSnapshot` to the App Group `UserDefaults` via `SharedStore`.
- The widget only reads it (`SnapshotProvider`) and links back with `DeepLink` URLs; it never mutates app data.
- Writers reload timelines with `WidgetCenter.reloadTimelines(ofKind: WidgetKind.main)` after meaningful changes.

## Consequences

- ✅ The widget is simple, fast and has no dependency on app internals.
- ⚠️ Data is only as fresh as the last app write; the provider also refreshes hourly.
- ⚠️ `UserDefaults` suits small data only. For larger/shared data, move to a file or SwiftData store in the App Group
  container (new ADR).
