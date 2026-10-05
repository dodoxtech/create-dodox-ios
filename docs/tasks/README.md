---
tags: [tasks, ai, workflow]
updated: 2026-10-05
---

# AI Tasks

Task files are the hand-off format between people and AI agents: a self-contained brief with context,
scope and acceptance criteria, kept in the repo so any agent (or human) can pick it up.

## Workflow

```
1. Copy      docs/templates/task.md   (or quick-task.md for < 1–2 h of work)
2. Save as   docs/tasks/active/TASK-NNNN-short-name.md
3. Hand off  "Read docs/tasks/active/TASK-NNNN-short-name.md and implement it."
4. Finish    tick Definition of Done, set status: done + completed: date, move to docs/tasks/done/
```

## Naming

- `TASK-NNNN-kebab-case-title.md`, 4-digit number, never reused.
- Next number = highest number across `active/` **and** `done/` + 1:

```bash
ls docs/tasks/active docs/tasks/done | grep -o 'TASK-[0-9]*' | sort | tail -1
```

## Status Values

`active` (ready / in progress) · `blocked` (say why in the file) · `done`

## For Agents Implementing a Task

1. Read the whole task file and every doc it links before writing code.
2. Stay inside **In scope**; note anything discovered out of scope under a `## Follow-ups` heading instead of doing it.
3. Treat **Acceptance Criteria** as the contract — tick each one only when verified.
4. Update docs per the rules in `AGENTS.md`, then move the file to `done/`.

## Tips for Writing Good Tasks

- **Context before instructions** — the agent needs the *why* to make good calls.
- **Name files and types** — `test/Features/Paywall/PaywallView.swift`, `SubscriptionService.isPremium`.
- **Concrete acceptance criteria** — not "nice UI" but "card uses `.card()`, CTA uses `.buttonStyle(.primary)`".
- **State constraints** — offline? premium-only? widget surface? new strings in 3 languages?
- **Link related docs** — feature docs, ADRs.

## Active Tasks

```dataview
TABLE status, priority, estimate
FROM "tasks/active"
SORT priority DESC
```

## Completed Tasks

```dataview
TABLE completed
FROM "tasks/done"
SORT completed DESC
```

(Dataview blocks render in Obsidian; elsewhere just list the folders.)
