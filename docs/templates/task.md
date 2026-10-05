---
tags: [task]
status: active            # active | blocked | done
priority: medium          # low | medium | high | critical
estimate: 2h
created: YYYY-MM-DD
completed:
assigned: ai              # ai | human | tbd
---

# TASK-NNNN: [Short task title]

## Context

> Why does this need doing? Background, user problem, motivation.

[Describe the feature, bug or refactor.]

**Related docs:**
- [feature doc](../../features/xxx.md)
- [modules](../../architecture/modules.md)

## Goal

[One sentence describing the end result.]

## Scope

### In scope
- [ ] [Thing to do 1]
- [ ] [Thing to do 2]

### Out of scope
- [Not doing X — separate task]

## Relevant Files

```
test/Features/<Name>/            ← screens
test/Core/<Area>/                ← services, models
Shared/                          ← anything the widget needs
test/Core/Localization/Localizable.xcstrings
```

## Acceptance Criteria

- [ ] AC1: [Specific, observable behavior]
- [ ] AC2: [Specific UI element / interaction]
- [ ] AC3: New strings localized in en / vi / ja
- [ ] AC4: Analytics: [events to fire, or "none"]
- [ ] AC5: Builds clean for the `test` scheme

## Technical Notes

> Suggested approach, constraints, gotchas.

- Inject services via `AppContainer`; navigation via `AppRouter`
- Use design tokens (`Spacing`, `.primary`, `.card()`)
- [Other constraints]

## Design Reference

> Screenshot, Figma link, or a description of the UI.

## Definition of Done

- [ ] Acceptance criteria verified
- [ ] Build clean, no new warnings
- [ ] Verified in the simulator (light + dark, large Dynamic Type)
- [ ] Docs updated (see `AGENTS.md` → Documentation Rules)
- [ ] `status: done`, `completed:` set, file moved to `docs/tasks/done/`
