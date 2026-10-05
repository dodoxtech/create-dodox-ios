---
tags: [index, home]
updated: 2026-10-05
---

# test Docs

> SwiftUI subscription app (iOS 27) — onboarding, Sign in with Apple, StoreKit 2 paywall, analytics,
> notifications, localization and a home-screen widget.

**For AI agents:** start here, then open only the files relevant to your task. Rules for keeping these docs
current are in [`AGENTS.md`](../AGENTS.md#documentation-rules-required).

## Architecture

- [overview](architecture/overview.md) — tech stack, targets, capabilities
- [modules](architecture/modules.md) — folders, services, what depends on what
- [data-flow](architecture/data-flow.md) — app phases, routing, deep links, persistence, widget data

## Features

| Feature | Doc | Code |
|---------|-----|------|
| Launch & onboarding | [onboarding](features/onboarding.md) | `Features/Splash`, `Features/Onboarding` |
| Sign in | [auth](features/auth.md) | `Core/Auth`, `Features/Auth` |
| Paywall & subscription | [subscription](features/subscription.md) | `Core/Subscription`, `Features/Paywall`, `Features/Subscription` |
| Notifications | [notifications](features/notifications.md) | `Core/Notifications`, `Features/Settings/NotificationSettingsView.swift` |
| Analytics | [analytics](features/analytics.md) | `Core/Analytics` |
| Deep links | [deep-links](features/deep-links.md) | `Shared/DeepLink.swift`, `App/AppRouter.swift` |
| Home-screen widget | [widget](features/widget.md) | `TestWidget/`, `Shared/` |
| Settings | [settings](features/settings.md) | `Features/Settings` |
| Localization | [localization](features/localization.md) | `Core/Localization` |

## Design

- [design-system](design/design-system.md) — tokens, shared styles, UI rules

## Decisions

- [decisions/README](decisions/README.md) — Architecture Decision Records (ADRs)

## Setup

- [getting-started](setup/getting-started.md) — requirements, build, run, StoreKit testing
- [release-checklist](setup/release-checklist.md) — everything to replace before shipping

## Tasks & Templates

- [tasks/README](tasks/README.md) — how to hand work to an AI agent
- [templates/task](templates/task.md) · [templates/quick-task](templates/quick-task.md) ·
  [templates/feature](templates/feature.md) · [templates/adr](templates/adr.md)

## Conventions for This Folder

- One topic per file, kebab-case file names, frontmatter with `tags` and `updated: YYYY-MM-DD`.
- Link with relative markdown links (`[modules](architecture/modules.md)`) — they work on GitHub, in Obsidian and for AI agents.
- Name real types and paths so readers can jump to code.

## Obsidian

Open `docs/` as a vault (Obsidian → Open folder as vault). Recommended plugins: **Dataview** (task tables in
[tasks/README](tasks/README.md)) and **Templater** (set the template folder to `templates/`).
