---
tags: [feature, localization, i18n]
status: done
updated: 2026-10-05
---

# Feature: Localization

## Overview

String Catalogs with English as the source language plus Vietnamese and Japanese. The app follows the iOS
per-app language setting; there is no in-app language switcher.

| Catalog | Target |
|---------|--------|
| `test/Core/Localization/Localizable.xcstrings` | App |
| `TestWidget/Localizable.xcstrings` | Widget |

## Rules

- **Semantic keys**, dot-separated by feature: `paywall.cta.trial`, `settings.section.account`. Never use English
  text as the key.
- Views: `Text("key")`, `Button("key")`, `Label("key", systemImage:)` — `LocalizedStringKey` is implicit.
  Non-view code: `String(localized: "key")`; stored model values: `LocalizedStringResource`.
- Interpolation: `Text("widget.hello \(name)")` → key `widget.hello %@`.
- Every new key gets **en, vi and ja** in the same change. Mark plural/device variants in the catalog, not in code.
- `app.name` is the display name used on the splash screen.
- DEBUG-only UI may use plain strings.

## Key Prefixes in Use

`app`, `common`, `tab`, `onboarding`, `auth`, `home`, `paywall`, `subscription`, `settings`, `notification`,
`notifications`, `widget`.

## Related

- [settings](settings.md)
