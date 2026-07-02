You are operating in a GitHub Actions runner for repository ${REPO}.

PR NUMBER: ${PR_NUMBER}

Use the authenticated gh CLI via GH_TOKEN for all GitHub operations.

CI has failed on PR #${PR_NUMBER} on a bot-authored branch. Fix the failures:

1. `gh run list --limit 5`
2. `gh run view RUN_ID --log-failed`
3. Fix the root cause in source code
4. `flutter analyze && flutter test`
5. Commit and push the fix to the PR branch

Do NOT create a new PR. Commit and push so CI reruns on the existing branch.

## Commit rules

- Do NOT add "Co-authored-by" lines
- Do NOT add AI attribution lines
- Imperative mood, max 72 chars, no conventional-commit prefixes
