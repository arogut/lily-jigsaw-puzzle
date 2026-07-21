---
description: Dispatch the project code-reviewer subagent for the current branch changes (per-file, then connections).
---

# Code review

Dispatch the **`code-reviewer`** subagent in **two phases** before opening a PR.
Do not review the full-range diff in one shot.

## Steps

1. Determine the git range and file list:
   ```bash
   BASE_SHA=$(git merge-base HEAD origin/main)
   HEAD_SHA=$(git rev-parse HEAD)
   git diff --name-only "$BASE_SHA".."$HEAD_SHA"
   git diff --stat "$BASE_SHA".."$HEAD_SHA"
   ```

2. Read `.agents/review/dispatch-template.md` and fill placeholders:
   - `{DESCRIPTION}` — summarise what changed (or use `$ARGUMENTS` if the user provided context)
   - `{PLAN_OR_REQUIREMENTS}` — relevant spec/plan path, or "general maintenance" if none
   - `{BASE_SHA}` / `{HEAD_SHA}` / `{CHANGED_FILES}`

3. **Phase per-file:** Launch Task with `subagent_type: code-reviewer`,
   `{PHASE}` = `per-file`, `{PER_FILE_NOTES}` = `n/a`. Keep the Per-file notes.

4. **Phase connections:** Launch a second Task with `subagent_type: code-reviewer`,
   `{PHASE}` = `connections`, `{PER_FILE_NOTES}` = phase-1 output.
   The subagent is readonly (frontmatter) — do not ask it to edit files.

5. Present the connections-phase review (Strengths / Issues / Assessment) to the user.
   Optionally attach a short summary of per-file notes if useful.

User input (optional):

```text
$ARGUMENTS
```

If `$ARGUMENTS` is non-empty, use it as `{DESCRIPTION}` or `{PLAN_OR_REQUIREMENTS}` as appropriate.
