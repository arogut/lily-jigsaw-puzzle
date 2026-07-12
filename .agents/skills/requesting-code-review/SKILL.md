---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements. Dispatches the project code-reviewer subagent with isolated context.
---

# Requesting code review

Review early, review often. Dispatch the project **`code-reviewer`** subagent — it gets a crafted
prompt with the git range and requirements, not your session history.

Works with the [superpowers](https://github.com/obra/superpowers) plugin: this project skill
overrides the generic flow with Flutter-specific criteria at `.agents/review/criteria.md`.

## When to request

- After each task in subagent-driven development
- After completing a major feature
- Before opening a PR
- When stuck and you want a fresh perspective

## How to dispatch

**1. Get git SHAs:**

```bash
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Build the prompt** from `.agents/review/dispatch-template.md` with:

- `{DESCRIPTION}` — what you implemented
- `{PLAN_OR_REQUIREMENTS}` — spec, plan path, or acceptance criteria
- `{BASE_SHA}` / `{HEAD_SHA}`

**3. Launch the subagent:**

Use the Task tool with:

- `subagent_type`: `code-reviewer`
- `readonly`: `true`
- `prompt`: filled template from step 2

Or invoke `/code-review` if you prefer an explicit command entry point.

**4. Act on feedback:**

- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back with reasoning if the reviewer is wrong

## CI parity

Pull requests are also reviewed by `.github/workflows/cursor-code-review.yml`, which uses the same
criteria file (`.agents/review/criteria.md`) for GitHub inline comments and formal review verdicts.
