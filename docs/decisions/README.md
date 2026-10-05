---
tags: [adr, decisions]
updated: 2026-10-05
---

# Architecture Decision Records

Every significant architecture, tech-stack or approach decision is recorded here so future humans and agents know
**why** the code looks the way it does — and don't "fix" a deliberate choice.

## When to Write One

- Choosing or replacing a framework, service or vendor
- Changing a cross-cutting pattern (DI, navigation, persistence, concurrency)
- Reversing a previous ADR (mark the old one `superseded`)

## How

1. Copy [templates/adr](../templates/adr.md) to `decisions/ADR-NNNN-short-title.md` (next free number).
2. Fill in Context → Decision → Consequences. Status starts as `proposed`, becomes `accepted` once implemented.
3. Add a row below.

## Records

| ID | Title | Status |
|----|-------|--------|
| [ADR-0001](ADR-0001-plain-xcode-project.md) | Plain Xcode project with synchronized folders (no Tuist / SPM modules) | accepted |
| [ADR-0002](ADR-0002-observable-services-composition-root.md) | `@Observable` services injected from one composition root | accepted |
| [ADR-0003](ADR-0003-storekit2-native.md) | Native StoreKit 2 for subscriptions (no third-party SDK) | accepted |
| [ADR-0004](ADR-0004-app-group-widget-snapshot.md) | Widget reads a snapshot from the App Group | accepted |
