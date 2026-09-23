# Code review dispatch templates

Fill these when dispatching the `code-reviewer` subagent (via `requesting-code-review` skill,
`/code-review` command, or Task tool).

Always run **two Task launches** (fresh context each time):

1. **per-file** — template below with `{PHASE}` = `per-file`
2. **connections** — template below with `{PHASE}` = `connections` and `{PER_FILE_NOTES}` =
   the phase-1 output

Do **not** paste a full-range `git diff` into the prompt.

**Getting SHAs:**

```bash
BASE_SHA=$(git merge-base HEAD origin/main)   # or explicit base
HEAD_SHA=$(git rev-parse HEAD)
git diff --name-only "$BASE_SHA".."$HEAD_SHA"
```

---

## Shared prompt body

```
Review the following change for production readiness.

## Phase

{PHASE}

## What was implemented

{DESCRIPTION}

## Requirements / plan

{PLAN_OR_REQUIREMENTS}

## Git range

Base: {BASE_SHA}
Head: {HEAD_SHA}

## Changed files (name-only)

{CHANGED_FILES}

## Per-file notes (connections phase only)

{PER_FILE_NOTES}

## Instructions

Follow `.agents/review/criteria.md`.

- If phase is `per-file`: review each path with
  `git diff {BASE_SHA}..{HEAD_SHA} -- <path>` only. Never dump the full-range diff.
  Return ## Per-file notes only (no Assessment).
- If phase is `connections`: use {PER_FILE_NOTES} and the file list. Fetch individual file
  diffs only when needed to verify a cross-file claim. Return Strengths / Issues / Assessment.
```

Placeholders:

| Placeholder | Fill with |
|---|---|
| `{PHASE}` | `per-file` or `connections` |
| `{DESCRIPTION}` | What changed |
| `{PLAN_OR_REQUIREMENTS}` | Spec/plan path, or `general maintenance` |
| `{BASE_SHA}` / `{HEAD_SHA}` | Git range |
| `{CHANGED_FILES}` | Output of `git diff --name-only …` |
| `{PER_FILE_NOTES}` | Phase-1 output, or `n/a` for per-file phase |
