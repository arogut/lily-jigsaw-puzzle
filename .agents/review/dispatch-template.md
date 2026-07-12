# Code review dispatch template

Fill this template when dispatching the `code-reviewer` subagent (via superpowers
`requesting-code-review` skill, `/code-review` command, or Task tool).

```
Review the following change for production readiness.

## What was implemented

{DESCRIPTION}

## Requirements / plan

{PLAN_OR_REQUIREMENTS}

## Git range

Base: {BASE_SHA}
Head: {HEAD_SHA}

Run:
  git diff --stat {BASE_SHA}..{HEAD_SHA}
  git diff {BASE_SHA}..{HEAD_SHA}

## Instructions

Follow `.agents/review/criteria.md` for project standards.

Structure your response as:

### Strengths
### Issues (Critical / Important / Minor — with file:line)
### Assessment (Ready to merge? Yes / With fixes / No)
```

**Getting SHAs:**

```bash
BASE_SHA=$(git merge-base HEAD origin/main)   # or explicit base
HEAD_SHA=$(git rev-parse HEAD)
```
