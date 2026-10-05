---
tags: [setup, onboarding]
updated: 2026-10-05
---

# Getting Started

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 27+ (iOS 27 SDK) |
| Apple Developer account | for device builds, Sign in with Apple, push, App Groups |
| Claude Code (optional) | latest — see `CLAUDE.md` for plugins |

## First Run

```bash
sudo xcode-select -s /Applications/Xcode.app   # once
open test.xcodeproj
```

1. Select the **`test`** scheme and an iOS simulator, then Run.
2. For a device: Signing & Capabilities → pick your team for **both** targets. Automatic signing registers the
   bundle IDs, App Group and capabilities on the first device build.

## Command Line

```bash
# Build
xcodebuild -project test.xcodeproj -scheme test -destination 'generic/platform=iOS Simulator' build

# Build + install + launch on a booted simulator
xcodebuild -project test.xcodeproj -scheme test \
           -destination 'platform=iOS Simulator,name=<device>' -derivedDataPath build/DerivedData build
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/test.app
xcrun simctl launch booted dodoxtech.test

# Deep link into a screen
xcrun simctl openurl booted testapp://paywall
```

## StoreKit Testing

The shared scheme attaches `Configuration/Products.storekit` (Run → Options → StoreKit Configuration), so the
paywall loads products and purchases succeed in the simulator without App Store Connect. Use
Xcode → Debug → StoreKit → Manage Transactions to refund, expire or clear purchases.

Keep the `.storekit` product IDs identical to `AppConfig.Subscription` and App Store Connect.

## Debugging Helpers

- Settings → **Debug** section (DEBUG builds): reset onboarding & launch paywall, open paywall deep link.
- Home → send a sample notification (arrives after 5 s).
- Logs: Console.app, filter subsystem = bundle ID; categories `App`, `Auth`, `Analytics`, `StoreKit`, `Notifications`.

## Docs

```bash
open -a Obsidian docs/   # optional — docs are plain markdown
```

## Related

- [release-checklist](release-checklist.md) · [overview](../architecture/overview.md) · [tasks](../tasks/README.md)
