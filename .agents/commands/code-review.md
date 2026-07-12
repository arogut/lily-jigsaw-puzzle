---
description: Dispatch the project code-reviewer subagent for the current branch changes.
---

# Code review

Dispatch the **`code-reviewer`** subagent to review changes before opening a PR.

## Steps

1. Determine the git range:
   ```bash
   BASE_SHA=$(git merge-base HEAD origin/main)
   HEAD_SHA=$(git rev-parse HEAD)
   git diff --stat "$BASE_SHA".."$HEAD_SHA"
   ```

2. Read `.agents/review/dispatch-template.md` and fill in:
   - `{DESCRIPTION}` — summarise what changed (or use `$ARGUMENTS` if the user provided context)
   - `{PLAN_OR_REQUIREMENTS}` — relevant spec/plan path, or "general maintenance" if none
   - `{BASE_SHA}` / `{HEAD_SHA}`

3. Launch Task tool with `subagent_type: code-reviewer`, `readonly: true`, and the filled prompt.

4. Present the subagent's structured review (Strengths / Issues / Assessment) to the user.

User input (optional):

```text
$ARGUMENTS
```

If `$ARGUMENTS` is non-empty, use it as `{DESCRIPTION}` or `{PLAN_OR_REQUIREMENTS}` as appropriate.
