# test — Agent Guide

SwiftUI subscription-app scaffold (iOS 27): Splash → Onboarding → Auth → Main tabs, StoreKit 2 paywall,
analytics, notifications, localization (en / vi / ja) and a WidgetKit extension.

This file is the canonical guide for every AI agent (Claude Code, Codex, Cursor…). `CLAUDE.md` imports it.

<!-- cli:start -->
> **This repo is also the source of the `create-dodox-ios` generator** (`cli/`). The root Xcode project is
> turned into `cli/template/` by `npm run build-template`, which replaces `test`, `TestApp`, `TestWidget`,
> `dodoxtech.test`, `testapp` and the Team ID with placeholders. Rules when editing the scaffold:
>
> - Never hardcode those identifiers in a new form (e.g. `"dodoxtech.test.something"` is fine, `"dodoxtech-test"` is not);
>   derive from `Bundle.main.bundleIdentifier`, `AppGroup.identifier`, `DeepLink.scheme` instead.
> - `CLAUDE.md`, `AGENTS.md` and `docs/` ship with generated apps and have `test` replaced by the app name, so in
>   those files the bare word `test` must only ever mean the project name. Say "verify", "tests" or "check" instead.
> - Anything only about the generator goes inside a `cli:start` … `cli:end` HTML-comment block (like this one);
>   it is stripped from the template.
> - After changing the scaffold, run `cd cli && npm run build-template` — it fails loudly on identifier leaks.
<!-- cli:end -->

## Before You Start a Task

1. Read [docs/README.md](docs/README.md) — the map of everything else.
2. Read the feature doc for the area you touch (`docs/features/<feature>.md`) and
   [docs/architecture/modules.md](docs/architecture/modules.md).
3. If you were handed a task file (`docs/tasks/active/TASK-NNNN-*.md`), its **Acceptance Criteria** are the contract.
4. Prefer the recipes in [Adding Things](#adding-things) over inventing a new pattern.

## Build & Run

```bash
# Build (no signing needed for the simulator)
xcodebuild -project test.xcodeproj -scheme test \
           -destination 'generic/platform=iOS Simulator' build

# Run on a booted simulator
xcrun simctl list devices available          # pick a device
xcodebuild -project test.xcodeproj -scheme test \
           -destination 'platform=iOS Simulator,name=<device>' \
           -derivedDataPath build/DerivedData build
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/test.app
xcrun simctl launch booted dodoxtech.test

# Open a screen via deep link
xcrun simctl openurl booted testapp://paywall      # home | settings | paywall | subscription
```

- **Scheme**: `test` (shared). Builds the app and the embedded `TestWidget` extension, and attaches
  `Configuration/Products.storekit` so purchases work offline in the simulator.
- **No Tuist / SPM packages.** Folders under `test/`, `Shared/`, `TestWidget/` are Xcode *synchronized folders*:
  new files are picked up automatically — never edit `project.pbxproj` to add a file.
- **No unit/UI testing target yet.** When adding one, document it in [docs/setup/getting-started.md](docs/setup/getting-started.md).

## Documentation Rules (REQUIRED)

> Any change to **project structure**, **data/state flow**, or **features** must be reflected in `docs/` in the same change.

| Change | File to update |
|--------|----------------|
| Add / remove / rename a folder, target or service | [docs/architecture/modules.md](docs/architecture/modules.md) |
| Change app phases, routing, deep links, persistence or widget data | [docs/architecture/data-flow.md](docs/architecture/data-flow.md) |
| Add a dependency, framework or capability | [docs/architecture/overview.md](docs/architecture/overview.md) (Tech Stack) |
| Add a new feature | Create `docs/features/<feature>.md` from [docs/templates/feature.md](docs/templates/feature.md), link it in [docs/README.md](docs/README.md) |
| Change an existing feature's behavior | Its `docs/features/<feature>.md` |
| Significant tech / architecture decision | Create `docs/decisions/ADR-NNNN-*.md` from [docs/templates/adr.md](docs/templates/adr.md), add it to [docs/decisions/README.md](docs/decisions/README.md) |
| Add a design token or shared style | [docs/design/design-system.md](docs/design/design-system.md) |
| Add an analytics event | [docs/features/analytics.md](docs/features/analytics.md) (event table) |
| Change build config, signing, tooling | [docs/setup/getting-started.md](docs/setup/getting-started.md) |
| Change something on the pre-release list | [docs/setup/release-checklist.md](docs/setup/release-checklist.md) |

**No doc update needed** for: bug fixes inside existing logic, copy tweaks, refactors that keep a type's public API.

**Frontmatter date** — every docs file has `updated: YYYY-MM-DD`. Bump it whenever you edit the file.

**Write docs for the next agent**: name real types and file paths (`AppRouter.open(_:)`, `test/App/AppRouter.swift`),
explain *why* a non-obvious choice was made, and keep one topic per file.

## Project Structure

```
test/                         → iOS app target
├── App/                      → entry point, AppDelegate, AppContainer (DI), AppRouter, RootView, MainTabView
├── Core/
│   ├── Analytics/            → AnalyticsEvent taxonomy, AnalyticsService + AnalyticsProvider, .trackScreen()
│   ├── Auth/                 → AuthService, AuthClient seam, KeychainStore
│   ├── Subscription/         → SubscriptionService (StoreKit 2)
│   ├── Notifications/        → NotificationService (permission, APNs, local reminders)
│   ├── Config/               → AppConfig (constants, product IDs), StorageKey
│   ├── DesignSystem/         → Spacing, .primary button, .card(), .errorAlert()
│   ├── Localization/         → Localizable.xcstrings (en / vi / ja)
│   └── Logging/              → Log (os.Logger categories)
└── Features/<Name>/          → one folder per screen / flow
Shared/                       → compiled into BOTH app and widget: AppGroup, SharedStore, DeepLink
TestWidget/                   → WidgetKit extension (reads SharedStore)
Configuration/                → entitlements, Products.storekit
docs/                         → documentation (Obsidian-compatible vault)
├── architecture/             → overview, modules, data-flow
├── features/                 → one file per feature
├── decisions/                → Architecture Decision Records
├── design/                   → design system & tokens
├── setup/                    → getting started, release checklist
├── templates/                → task, quick-task, feature, ADR templates
└── tasks/                    → AI task files (active/ → done/)
```

## Architecture Rules

- **Composition root**: every service is created once in `AppContainer` and injected with `.environment(container)`.
  Views read services with `@Environment(Service.self)`. Never instantiate a service inside a view.
- **Services** are `@Observable final class`es; mutable state is `private(set)`; dependencies are injected via `init`
  with defaults, and non-observed stored properties are `@ObservationIgnored`.
- **Navigation lives in `AppRouter`**: phase (`splash/onboarding/auth/main`), selected tab, paywall sheet, and
  `open(DeepLink)`. Views call the router; they don't own cross-screen navigation state.
- **Backend seams are protocols**: `AuthClient`, `AnalyticsProvider`. Add a real implementation and wire it in
  `AppContainer` — don't put network code in views or services directly.
- **Concurrency**: the app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency.
  Code in `Shared/` must stay `nonisolated` (the widget compiles it too).
- **No MVVM boilerplate**: views hold local UI state in `@State`; logic that is shared or testable goes into a service.

## Coding Conventions

- **Strings**: every user-facing string is a semantic key (`"paywall.cta"`) in `Localizable.xcstrings` with en / vi / ja.
  `Text("key")` for views, `String(localized: "key")` elsewhere. No hardcoded copy, except DEBUG-only UI.
- **Styles**: use tokens from `test/Core/DesignSystem/DesignSystem.swift` — `Spacing.m`, `.buttonStyle(.primary)`,
  `.card()`. No magic numbers for spacing; add a token instead. See [docs/design/design-system.md](docs/design/design-system.md).
- **Analytics**: add events as static factories on `AnalyticsEvent` (snake_case names), track via `AnalyticsService`.
  Every screen ends with `.trackScreen("snake_case_name")`.
- **Errors shown to users**: `LocalizedError` with a localized `errorDescription`, surfaced with `.errorAlert($message)`.
- **Logging**: `Log.<category>` (`os.Logger`); mark user data `privacy: .private`.
- **Persistence keys**: `UserDefaults` keys live in `StorageKey`; secrets go in `KeychainStore`; widget data in `SharedStore`.
- **Naming**: English only for code, comments and docs.

## Adding Things

| I want to… | Do this |
|------------|---------|
| Add a screen | Create `test/Features/<Name>/<Name>View.swift`, add `.trackScreen(...)`, localize strings, write `docs/features/<name>.md` |
| Add a service | `@Observable final class` in `test/Core/<Area>/`, add to `AppContainer` (init + `environment(_:)`), update `modules.md` |
| Add a deep link | New case in `Shared/DeepLink.swift`, handle it in `AppRouter.open(_:)`, update `data-flow.md` |
| Add an analytics vendor | Implement `AnalyticsProvider`, append it in `AppContainer.init` |
| Connect a real backend for auth | Implement `AuthClient`, pass it to `AuthService(client:)` in `AppContainer` |
| Add a subscription product | ID in `AppConfig.Subscription` + `Configuration/Products.storekit` + App Store Connect |
| Show new data in the widget | Field on `WidgetSnapshot`, write via `SharedStore.update`, then `WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.main)` |
| Persist a preference | Key in `StorageKey`, read/write in the owning service (or `@AppStorage` for view-only flags) |

## Working with AI Tasks

```
1. Copy   docs/templates/task.md (or quick-task.md)
2. Save   docs/tasks/active/TASK-NNNN-short-name.md   (next free number across active/ and done/)
3. Run    "Read docs/tasks/active/TASK-NNNN-short-name.md and implement it."
4. Done   tick the Definition of Done, set status: done, move the file to docs/tasks/done/
```

Details: [docs/tasks/README.md](docs/tasks/README.md).

## Definition of Done (any change)

- [ ] Builds clean for the `test` scheme (no new warnings)
- [ ] New strings localized in en / vi / ja
- [ ] Docs updated per the table above, `updated:` bumped
- [ ] Task file (if any) moved to `docs/tasks/done/`
