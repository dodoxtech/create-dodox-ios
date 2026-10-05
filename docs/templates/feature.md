---
tags: [feature]
status: planned           # planned | in-progress | done
updated: YYYY-MM-DD
---

# Feature: [Name]

## Overview

[2–4 sentences: what it does for the user and how it fits the app. Mention the task that introduced it (TASK-NNNN).]

## User Stories

- [ ] [As a user I can …]
- [ ] […]

## Flow

```
[Entry point] → [Screen / step] → [Result]
```

## Implementation

| File | Role |
|------|------|
| `test/Features/<Name>/<Name>View.swift` | [UI] |
| `test/Core/<Area>/<Service>.swift` | [Logic / state] |

[Key decisions and *why* — the things a future agent would otherwise "fix".]

## Data & Persistence

[What is stored where (`StorageKey`, Keychain, `SharedStore`, server). "None" is a valid answer.]

## Analytics

[Events fired, or "none". Add new events to [analytics](../features/analytics.md).]

## Edge Cases & Known Limitations

- [Offline, signed-out, non-premium, permission denied, …]

## Related

- [data-flow](../architecture/data-flow.md)
