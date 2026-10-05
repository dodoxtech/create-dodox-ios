---
tags: [adr, build]
status: accepted
date: 2026-10-05
---

# ADR-0001: Plain Xcode Project with Synchronized Folders

## Context

The project must be easy to open and run with nothing but Xcode. Module generators like Tuist add a tool
dependency and a generate step.
<!-- cli:start -->
It is also the source of the `create-dodox-ios` generator, which renames identifiers with plain text replacement.
<!-- cli:end -->

## Decision

- One `test.xcodeproj` with two targets (`test`, `TestWidget`), using Xcode **synchronized folders** — files added
  to `test/`, `Shared/`, `TestWidget/` are compiled automatically.
- Code shared with the widget lives in `Shared/`, which is a member of both targets.
- Layering (App / Core / Features / Shared) is a folder convention, documented in
  [modules](../architecture/modules.md), not enforced by frameworks.

## Consequences

- ✅ Zero setup: clone, open, run. No `project.pbxproj` merge conflicts when adding files.
<!-- cli:start -->
- ✅ The generator only needs text replacement.
<!-- cli:end -->
- ⚠️ Dependency rules aren't compiler-enforced; reviewers and agents must respect them.
- ⚠️ Revisit (new ADR) if build times grow or a second app/extension needs Core — extract a local Swift package then.
