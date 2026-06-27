# Implementation Plan: Daily Puzzle Streak

**Branch**: `004-daily-puzzle-streak` | **Date**: 2026-06-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-daily-puzzle-streak/spec.md`

## Summary

Track and display a consecutive-day puzzle-completion streak. A streak increments by 1 when the player completes any puzzle on a calendar day immediately following the previous completion day; it resets to 1 after a gap; same-day completions are idempotent. Data persists via `shared_preferences` (already a project dependency) — no new packages required. The current streak and personal-best (longest) streak are surfaced on the win overlay immediately after puzzle completion.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK 3.41.3, stable channel)

**Primary Dependencies**: Flutter framework; `shared_preferences 2.5.5` (already in pubspec) — no new dependencies

**Storage**: `SharedPreferences` only — three string/int keys under the `streak_` namespace, following the exact same pattern used by `CompletionService`. No SQLite, no Hive, no external database.

**Testing**: `flutter_test` (built-in); `SharedPreferences.setMockInitialValues({})` in `setUp` — same pattern used by `completion_service_test.dart`

**Target Platform**: Android (Flutter Android target, API 21+)

**Project Type**: Mobile app (Flutter Android)

**Performance Goals**: Streak read/write is a single `SharedPreferences` round-trip on the puzzle-completion event — no performance constraint beyond what `CompletionService` already satisfies

**Constraints**: No network calls; offline-only; must not add any new package dependency

**Scale/Scope**: Single user, single device; three `SharedPreferences` keys total

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| I. Children-First UI | ✅ | Win overlay addition must match existing childish palette; mockups in `assets/design/` to be consulted before implementation |
| II. TDD — ≥85% line coverage | ✅ | `StreakRecord` and `StreakService` must have unit tests written first (red → green → refactor). `WinOverlay` changes need widget tests. |
| III. Functional Programming | ✅ | `StreakRecord` is fully immutable with `copyWith`. State transformation in `StreakService` is a pure function mapping old record + date → new record. |
| IV. DRY | ✅ | Single `StreakService` class owns all streak logic. No constants duplicated. SharedPreferences keys defined as private constants in one place. |
| V. KISS & SOLID | ✅ | `StreakService` has one responsibility: streak state management. `StreakRecord` has one responsibility: value object. No premature abstraction. |
| VI. Quality Gates | ✅ | `flutter test` + `flutter analyze` + `flutter build apk --debug` must pass before PR |

**Complexity Tracking**: No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/004-daily-puzzle-streak/
├── plan.md              ← this file
├── research.md          ← Phase 0 decisions
├── data-model.md        ← Phase 1 data model + service contract
├── quickstart.md        ← Phase 1 validation guide
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (not yet created)
```

### Source Code

```text
lib/
├── models/
│   ├── streak_record.dart        ← NEW: immutable value object
│   └── ...
├── services/
│   ├── streak_service.dart       ← NEW: SharedPreferences-backed streak logic
│   ├── completion_service.dart   ← UNCHANGED
│   └── ...
├── widgets/
│   ├── win_overlay.dart          ← MODIFIED: accept optional StreakRecord, show streak
│   └── ...
└── screens/
    └── game_screen.dart          ← MODIFIED: call StreakService on win, pass record to overlay

test/
└── unit/
    ├── models/
    │   └── streak_record_test.dart     ← NEW
    └── services/
        └── streak_service_test.dart    ← NEW
    unit/widgets/
        └── win_overlay_test.dart       ← MODIFIED: add streak display tests

lib/l10n/
├── app_en.arb   ← MODIFIED: add streak string keys
├── app_pl.arb   ← MODIFIED
├── app_de.arb   ← MODIFIED
└── app_es.arb   ← MODIFIED
```

**Structure Decision**: Flutter Android single-project layout. New files follow the existing `lib/models/` and `lib/services/` conventions exactly. Modified files are `win_overlay.dart`, `game_screen.dart`, and all four ARB localization files.
