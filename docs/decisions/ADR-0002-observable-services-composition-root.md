---
tags: [adr, architecture, state]
status: accepted
date: 2026-10-05
---

# ADR-0002: `@Observable` Services from One Composition Root

## Context

Most screens need the same few app-wide services (auth, subscriptions, analytics, router). We want minimal
boilerplate, previews that work, and a single place to swap implementations (real backend, analytics vendors).

## Decision

- Services are `@Observable final class`es with `private(set)` state and injected dependencies.
- `AppContainer` creates them once; `AppDelegate` owns the container so it exists before any delegate callback
  (e.g. a cold-launch notification tap).
- Views get services through `@Environment(Service.self)`; `View.environment(_ container:)` injects them all.
- Navigation state (phase, tab, modals, deep links) is centralized in `AppRouter`.
- No per-screen view models by default; local UI state stays in `@State`.

## Consequences

- ✅ Little ceremony; `AppContainer.preview` makes every `#Preview` work.
- ✅ External seams (`AuthClient`, `AnalyticsProvider`) are swapped in one file.
- ⚠️ A view missing an injected service crashes at runtime — always inject via `.environment(container)`.
- ⚠️ If a screen's logic grows large or needs unit tests, extract an `@Observable` model for that screen rather than
  pushing logic into a global service.
