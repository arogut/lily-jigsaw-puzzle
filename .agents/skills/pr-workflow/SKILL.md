---
name: pr-workflow
description: Pre-push verification, pull request creation, and CI watch loop. Use when committing, pushing, opening a PR, or fixing failing CI checks on a branch.
---

# PR workflow

## Before pushing a commit

1. Run the full test suite (`flutter test`) — do NOT raise a PR if tests fail.
2. Run static analysis (`flutter analyze`).
3. Verify test coverage has not dropped.
4. Only open a PR once all of the above pass cleanly.

## After opening a PR — CI watch loop

After creating a PR, poll CI status using `gh` until checks complete:

```bash
# Wait for all checks to finish (polls every 30s)
gh pr checks --watch

# If any check fails, read the logs:
gh run list --branch <branch> --limit 1
gh run view <run-id> --log-failed
```

If checks fail:

1. Read the failure output carefully
2. Fix the root cause in the source code
3. Commit and push the fix to the same branch
4. Repeat until `gh pr checks --watch` exits with all green

## CI/CD context

When running in GitHub Actions:

- Always create a new branch for changes, never commit directly to main
- Include test results summary in the PR description
- If tests fail, fix the issues before creating the PR
