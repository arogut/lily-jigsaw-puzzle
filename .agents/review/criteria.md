# Code review criteria

Shared checklist for the `code-reviewer` subagent (local/superpowers) and the
`.github/workflows/cursor-code-review.yml` CI agent. Keep this file as the single source of
review standards.

## Review process (two-phase)

Do **not** load the full range diff into context in one shot. That dilutes attention on large
changes. Always use two phases:

1. **Per-file** — list changed paths, then review each file’s own diff in isolation
   (`git diff {BASE}..{HEAD} -- <path>`). Note local bugs, style, missing tests for that file.
2. **Connections** — with per-file notes only (not the full mega-diff), check how changes fit
   together: call sites, imports/APIs, `lib/` ↔ `test/` pairing, shared types, plan/spec
   coverage across files.

## Project standards (always check)

Read before reviewing:

- `AGENTS.md` — always-on rules and architecture
- `.specify/memory/constitution.md` — UI mockup fidelity, TDD, ≥85% coverage gate
- `.agents/skills/flutter-standards/SKILL.md` — Dart/Flutter conventions (when reviewing Dart code)

## Code quality

- Dart style guide and `analysis_options.yaml` (very_good_analysis) — zero warnings
- Meaningful names; no commented-out code
- DRY, SOLID, KISS, YAGNI
- Minimal scope — changes should trace to the stated requirement
- Public APIs have `///` doc comments

## Testing

- New classes/functions have unit tests in `test/` mirroring `lib/`
- New widgets have widget tests
- Tests assert behaviour, not implementation details
- Edge cases covered; coverage must not drop below constitution threshold

## Flutter / UI

- Widgets stay UI-only — no business logic in `build()`
- State kept close to where it is needed; immutable data models
- UI matches mockups in `assets/design/` (constitution)

## Security

- No hardcoded credentials or secrets
- Input validation at boundaries
- No sensitive data in logs

## Severity guide

| Level | Examples |
|---|---|
| **Critical (must fix)** | Hardcoded secrets, broken functionality, missing tests for new logic, coverage gate failure |
| **Important (should fix)** | Architecture violations, missing error handling, spec/plan deviation, test gaps on edge cases |
| **Minor (suggestion)** | Naming, small refactors, documentation polish |

## Verdict

- **Ready to merge** — no Critical or Important issues
- **Ready with fixes** — Important issues that are quick to fix
- **Not ready** — Critical issues or significant Important gaps
