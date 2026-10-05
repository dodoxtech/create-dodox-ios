# test — Claude Code Guide

@AGENTS.md

---

## Claude Code Specifics

Everything above (project rules, docs rules, conventions) applies. This section only adds Claude Code tooling.

### Plugins

`.claude/settings.json` registers the shared plugins; Claude Code offers to install them when the folder is trusted.
Manual install:

```bash
claude plugin install apple-platform-build-tools@apple-platform-build-tools
claude plugin install ios-app-design-skills@ios-app-design-skills
```

Personal overrides go in `.claude/settings.local.json` (git-ignored).

### Builds

Delegate builds, simulator work and log reading to the `apple-platform-build-tools` **builder** subagent — it keeps
long `xcodebuild` output out of the main context and returns only the result or the relevant error.

### Skills (use `/skill-name` when installed)

| Area | Skills |
|------|--------|
| Start here | `/ios-dev` — any iOS / SwiftUI task |
| Code | `/swiftui`, `/swift-concurrency`, `/guide-swift-concurrency`, `/swiftdata` |
| UI / UX | `/ios-ui-craft`, `/ios-design-consultant` (advice, no code), `/hig`, `/ios-liquid-glass`, `/guide-swiftui-ui-patterns`, `/guide-swiftui-animations`, `/guide-swiftui-view-refactor` |
| Frameworks used here | `/storekit` (paywall), `/widgetkit` (widget), `/usernotifications` (reminders, APNs) |
| Testing & performance | `/swift-testing`, `/xcuitest`, `/guide-swiftui-performance-audit`, `/simulator-utils` |
| App Store | `/apple-aso` |

### Docs & tasks

- Plan a larger change → write a task file first (`docs/templates/task.md`), then implement it.
- Architecture decisions → ADR from `docs/templates/adr.md`.
- Don't save to auto-memory what belongs in `docs/` — project knowledge lives in the repo so every agent sees it.
