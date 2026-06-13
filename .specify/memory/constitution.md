<!--
SYNC IMPACT REPORT
==================
Version change: N/A (new) → 1.0.0
Added principles: I–VI (all new)
Added sections: Technology & Platform Constraints, Development Workflow & Quality Gates
Removed sections: N/A (initial constitution)
Templates requiring updates:
  ✅ .specify/templates/plan-template.md — Constitution Check gates now derivable from this file
  ⚠ .specify/templates/tasks-template.md — Tests marked OPTIONAL by default; constitution mandates
    TDD strictly. The /speckit-tasks command MUST include test tasks for every feature — treat
    "OPTIONAL - only if explicitly requested" note as overridden by Principle II of this constitution.
  ✅ .specify/templates/spec-template.md — No structural changes required; acceptance scenarios
    align with TDD mandate
Follow-up TODOs: none
-->

# lily-jigsaw-puzzle Constitution

## Core Principles

### I. Children-First UI Design (NON-NEGOTIABLE)
All UI components MUST visually match the mockups stored in `assets/design/`.
- Every screen, widget, and interaction MUST be reviewed against the corresponding mockup before
  a feature is considered done.
- UI MUST be child-friendly: large tap targets, clear visual feedback, no small or dense text.
- No UI change is acceptable that deviates from the approved mockups without explicit sign-off.
- Colours, typography, spacing, and iconography MUST be derived from the design assets — never
  invented ad hoc.

### II. Test-Driven Development (NON-NEGOTIABLE)
TDD is mandatory. Tests are written first, confirmed to fail, then implementation makes them pass.
- Red → Green → Refactor cycle MUST be followed strictly on every change.
- All code changes MUST be covered with unit tests achieving **≥ 85% line coverage** — this is a
  hard gate; PRs below threshold MUST NOT be merged.
- New widgets MUST have widget tests. New logic classes/functions MUST have unit tests in `test/`
  mirroring the `lib/` directory structure.
- Tests MUST assert behaviour and outcomes — never implementation details.
- Test names MUST follow: `given_<context>_when_<action>_then_<expectation>` or equivalent natural
  language.

### III. Functional Programming Preferred
Pure functions and immutable data MUST be preferred over stateful, imperative approaches wherever
practical in Dart/Flutter.
- Functions MUST avoid side effects unless at an explicit boundary (e.g., repository, platform API).
- Data models MUST be immutable; use `final` fields and `copyWith` patterns.
- State transformation MUST be expressed as pure functions mapping old state → new state.
- Avoid mutating shared state; pass data explicitly rather than relying on globals or singletons.

### IV. DRY — Single Source of Truth
Every piece of knowledge MUST have exactly one representation in the codebase.
- Repeated UI fragments MUST be extracted into a widget in `lib/core/widgets/`.
- Repeated logic MUST be extracted to a method or utility in `lib/core/utils/`.
- Repeated values (colours, sizes, durations, strings) MUST be defined as constants — the same
  literal MUST NOT appear in more than one place.
- Before writing new code, search the existing codebase for something that already does (or nearly
  does) what is needed.

### V. KISS & SOLID — Simple, Principled Architecture
The simplest solution that correctly solves the problem MUST be chosen.
- **Single Responsibility**: every class, widget, and function has exactly one reason to change.
  Widgets own UI only; repositories own data access only; state management is a separate layer.
- **Open/Closed**: prefer configuration via constructor parameters or callbacks over subclassing.
- **Liskov Substitution**: subtypes MUST be fully usable wherever their base type is expected.
- **Interface Segregation**: prefer small, focused abstract classes over large ones.
- **Dependency Inversion**: high-level modules depend on abstractions; inject concrete
  implementations via constructors.
- No speculative features, no premature abstractions, no flexibility that was not explicitly
  requested. YAGNI strictly enforced.

### VI. Quality Gates (NON-NEGOTIABLE)
Every change MUST pass all three gates before a PR is raised or merged:
1. `flutter test` — zero test failures; ≥ 85% line coverage (hard stop).
2. `flutter analyze` — zero warnings, zero lint suppressions without an explanatory comment.
3. `flutter build apk --debug` — clean compilation, no build errors.

No PR MUST be opened until all three gates pass. CI enforces the same gates and a failing CI
check MUST be fixed before merge — never bypassed.

## Technology & Platform Constraints

- **Target platform**: Android only (Flutter Android target).
- **Language**: Dart; framework: Flutter (stable channel).
- **Minimum SDK**: Android API defined in `android/app/build.gradle` — do not raise it without
  explicit approval.
- **Dependencies**: favour Flutter/Dart built-ins and framework primitives over third-party
  packages. Any new dependency MUST be justified with a clear rationale.
- **Design assets**: mockups live in `assets/design/`; they are the single source of visual truth.
- **Test tooling**: `flutter_test` (built-in) for unit and widget tests. Additional mocking via
  `mocktail` where needed.
- **Code style**: [Dart style guide](https://dart.dev/effective-dart/style); lints from
  `analysis_options.yaml` (based on `very_good_analysis`).
- **Documentation**: every public API — class, constructor, method, and field — MUST have a
  `///` doc comment. This is a hard requirement enforced by the analysis options and code review.
  Missing doc comments on public symbols are grounds for PR rejection.

## Development Workflow & Quality Gates

- **Branch strategy**: every feature or fix lives on its own branch; PRs target `main`.
- **TDD cycle per task**: write failing test → implement → pass → refactor → commit.
- **Coverage check**: run `flutter test --coverage` locally before pushing; verify ≥ 85%.
- **Pre-PR checklist**:
  - [ ] All tests pass (`flutter test`)
  - [ ] Coverage ≥ 85%
  - [ ] Zero analysis issues (`flutter analyze`)
  - [ ] Debug APK builds cleanly (`flutter build apk --debug`)
  - [ ] UI reviewed against mockups in `assets/design/`
- **CI watch**: after opening a PR, monitor CI with `gh pr checks --watch`; fix failures before
  requesting review.
- **Commit message style**: `type: short description` (e.g., `feat:`, `fix:`, `test:`, `docs:`).

## Governance

This constitution supersedes all other development guidance. When conflicts arise between this
document and any other guide (comments, READMEs, ad-hoc instructions), this constitution wins.

`CLAUDE.md` provides runtime guidance for the AI coding agent and MUST remain consistent with this
constitution — if they diverge, update `CLAUDE.md` to align.

**Amendment procedure**:
- MAJOR bump: removal or redefinition of a principle; requires explicit team approval and a
  migration plan for existing code.
- MINOR bump: new principle or section added; requires rationale in the PR description.
- PATCH bump: wording clarification, typo fix, non-semantic refinement.

All PRs and code reviews MUST verify compliance with this constitution. Complexity that violates
KISS or SOLID MUST be justified in the PR description; unexplained complexity is grounds for
rejection.

**Version**: 1.0.0 | **Ratified**: 2026-06-09 | **Last Amended**: 2026-06-09
