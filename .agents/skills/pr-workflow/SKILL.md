---
name: pr-workflow
description: Pre-push verification and pull request creation. Use when committing, pushing, or opening a PR. Use when the user asks to fix failing CI on a branch.
---

# PR workflow

## Before pushing a commit

1. Run the full test suite (`flutter test`) — do NOT raise a PR if tests fail.
2. Run static analysis (`flutter analyze`).
3. Verify test coverage has not dropped.
4. Only open a PR once all of the above pass cleanly.

## After opening a PR

Stop once the PR exists and share the URL. Do **not** poll or watch CI.

A human stays in the loop; if CI fails, they will ask separately to investigate and fix.

When asked to fix CI:

1. Read the failure output (`gh pr checks`, `gh run view --log-failed`)
2. Fix the root cause in the source code
3. Commit and push to the same branch

## CI/CD context

When running in GitHub Actions:

- Always create a new branch for changes, never commit directly to main
- Include test results summary in the PR description
- If tests fail, fix the issues before creating the PR
