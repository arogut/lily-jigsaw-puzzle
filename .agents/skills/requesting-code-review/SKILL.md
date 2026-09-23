---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements. Dispatches the project code-reviewer subagent with isolated context in two phases (per-file, then connections).
---

# Requesting code review

Review early, review often. Dispatch the project **`code-reviewer`** subagent — it gets a crafted
prompt with the git range and requirements, not your session history.

Large diffs poison attention if reviewed in one blob. Always use **two Task launches**:
per-file scan, then cross-file connections (see `.agents/review/dispatch-template.md`).

Works with the [superpowers](https://github.com/obra/superpowers) plugin: this project skill
overrides the generic flow with Flutter-specific criteria at `.agents/review/criteria.md`.

## When to request

- After each task in subagent-driven development
- After completing a major feature
- Before opening a PR
- When stuck and you want a fresh perspective

## How to dispatch (two-phase)

**1. Get git SHAs and the file list:**

```bash
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)
git diff --name-only "$BASE_SHA".."$HEAD_SHA"
```

**2. Phase — per-file**

Build the prompt from `.agents/review/dispatch-template.md` with:

- `{PHASE}` = `per-file`
- `{DESCRIPTION}` — what you implemented
- `{PLAN_OR_REQUIREMENTS}` — spec, plan path, or acceptance criteria
- `{BASE_SHA}` / `{HEAD_SHA}` / `{CHANGED_FILES}`
- `{PER_FILE_NOTES}` = `n/a`

Launch Task with `subagent_type: code-reviewer` and that prompt.
Save the returned **Per-file notes**.

**3. Phase — connections**

Build the same template with:

- `{PHASE}` = `connections`
- `{PER_FILE_NOTES}` = phase-1 output (do not paste full diffs)

Launch a **second** Task with `subagent_type: code-reviewer`.
The subagent is readonly (frontmatter) — do not ask it to edit files.

Or invoke `/code-review` if you prefer an explicit command entry point.

**4. Act on feedback** (from the connections-phase Assessment):

- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back with reasoning if the reviewer is wrong

## CI parity

Pull requests are also reviewed by `.github/workflows/cursor-code-review.yml`, which uses the same
criteria file (`.agents/review/criteria.md`) for GitHub inline comments and formal review verdicts.
