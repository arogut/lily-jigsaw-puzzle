# Tasks: Daily Puzzle Streak

**Input**: Design documents from `specs/004-daily-puzzle-streak/`

**Prerequisites**: [plan.md](plan.md) · [spec.md](spec.md) · [data-model.md](data-model.md) · [research.md](research.md) · [quickstart.md](quickstart.md)

**TDD mandate**: Constitution Principle II requires tests to be written and confirmed FAILING before implementation. Every implementation task is preceded by its corresponding test task.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this belongs to ([US1]–[US4])

---

## Phase 1: Setup

**Purpose**: Branch setup — no new packages, no schema migrations required.

- [x] T001 Create git branch `004-daily-puzzle-streak` from `main` and confirm working tree is clean

---

## Phase 2: Foundational — StreakRecord + StreakService (TDD)

**Purpose**: Core data model and service that ALL user stories depend on. Must be 100% complete before any UI or integration work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

> **TDD**: Write T002 and T003 first, confirm they FAIL, then implement T004 and T005.

- [x] T002 [P] Write failing unit tests for `StreakRecord` in `test/unit/models/streak_record_test.dart`: cover `initial()` factory (zeros + null date), `copyWith` preserving unchanged fields, and `assert` violations (negative counts, longestStreak < currentStreak)
- [x] T003 [P] Write failing unit tests for `StreakService` in `test/unit/services/streak_service_test.dart`: cover all four transition paths (first-ever completion → streak 1; same-day → idempotent; consecutive day → increments; gap of 2+ days → resets to 1); `getStreak()` on empty prefs returns `StreakRecord.initial()`; `resetAll()` removes all three keys; clock injection controls the "current date"
- [x] T004 Implement `StreakRecord` immutable value object with `initial()` factory and `copyWith` in `lib/models/streak_record.dart` (makes T002 green; doc-comment every public member)
- [x] T005 Implement `StreakService` with `getStreak()`, `recordPuzzleCompletion()`, and `resetAll()` using `shared_preferences` and optional `clock` injection in `lib/services/streak_service.dart` (makes T003 green; doc-comment every public member)

**Checkpoint**: `flutter test test/unit/models/streak_record_test.dart test/unit/services/streak_service_test.dart` passes with zero failures.

---

## Phase 3: User Stories 1 & 2 — Streak Counting in GameScreen (Priority: P1 + P2) 🎯 MVP

**Goal**: When any puzzle is won, the app records the completion via `StreakService` and stores the resulting `StreakRecord` in `_GameScreenState`, ready to pass to the win overlay. US1 (increment) and US2 (reset) are both exercised through this single integration point.

**Independent Test**: After triggering a puzzle win in a widget test (with `SharedPreferences` mocked to empty initial values), the `WinOverlay` in the widget tree is found to receive a `streakRecord` with `currentStreak == 1`.

> **TDD**: Write T006 first, confirm it FAILS, then implement T007–T009.

- [x] T006 [US1] Write failing widget test in `test/widget/game_screen_loaded_test.dart`: set up `SharedPreferences.setMockInitialValues({})`, trigger `GamePhase.won`, and assert the rendered `WinOverlay` receives a `streakRecord` argument with `currentStreak >= 1`
- [x] T007 [US1] Add `StreakRecord? _streakRecord` field to `_GameScreenState` in `lib/screens/game_screen.dart`
- [x] T008 [US1] Extend `_recordCompletion()` in `lib/screens/game_screen.dart` to call `await StreakService().recordPuzzleCompletion()` and store the result in `_streakRecord` via `setState()`
- [x] T009 [US1] Pass `streakRecord: _streakRecord` to the `WinOverlay(...)` constructor call in `lib/screens/game_screen.dart` (makes T006 green)

**Checkpoint**: `flutter test test/widget/game_screen_loaded_test.dart` passes; `flutter analyze` clean.

---

## Phase 4: User Stories 3 & 4 — Win Overlay Streak Display (Priority: P3 + P4)

**Goal**: The win overlay shows the updated current streak (US3) and the all-time longest streak (US4) immediately after puzzle completion. Both are read from `StreakRecord` already stored in `_GameScreenState`.

**Independent Test**: Construct `WinOverlay` with a `StreakRecord(currentStreak: 5, longestStreak: 12, lastCompletionDate: '2026-06-27')` in a widget test and assert "5 Day Streak" and "Best: 12" appear in the rendered tree.

> **TDD**: Write T011 first, confirm it FAILS, then implement T012–T013.

- [x] T010 [P] [US3] Add localization keys `streakDays` (with `count` int placeholder) and `streakBest` (with `count` int placeholder) to all four ARB files: `lib/l10n/app_en.arb`, `lib/l10n/app_pl.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_es.arb` (EN: `"🔥 {count} Day Streak"` / `"Best: {count} days"`)
- [x] T011 [US3] Write failing widget tests in `test/unit/widgets/win_overlay_test.dart`: (a) null `streakRecord` renders correctly with no streak section; (b) `streakRecord` with `currentStreak > 0` shows streak text and longest streak; (c) `streakRecord` with `currentStreak == 0` hides streak section
- [x] T012 [US3] Add `final StreakRecord? streakRecord` named parameter (default `null`) to `WinOverlay` constructor in `lib/widgets/win_overlay.dart` (doc-comment the new field)
- [x] T013 [US3] Add streak display section to `WinOverlay.build()` in `lib/widgets/win_overlay.dart`: render between subtitle and buttons when `streakRecord != null && streakRecord!.currentStreak > 0`; use `l10n.streakDays(count: streakRecord!.currentStreak)` and `l10n.streakBest(count: streakRecord!.longestStreak)`; match existing childish palette (makes T011 green)

**Checkpoint**: `flutter test test/unit/widgets/win_overlay_test.dart` passes; `WinOverlay` renders correctly for null and non-null `streakRecord` cases.

---

## Phase 5: Settings Integration & Polish

**Purpose**: Wire `StreakService.resetAll()` into the existing "Reset Progress" flow so a settings reset also clears the streak. Then run all quality gates.

- [x] T014 Write failing widget test in `test/widget/settings_screen_test.dart` asserting that after tapping "Reset Progress", subsequent `StreakService().getStreak()` returns `StreakRecord.initial()` (use `SharedPreferences.setMockInitialValues({'streak_current': 5, 'streak_longest': 10, 'streak_last_date': '2026-06-01'})`)
- [x] T015 Extend the "Reset Progress" action in `lib/screens/settings_screen.dart` to call `await StreakService().resetAll()` alongside the existing `CompletionService().resetAll()` call (makes T014 green)
- [x] T016 [P] Run all quality gates in order: `flutter test`, `flutter analyze`, `flutter build apk --debug`; resolve any failures before raising a PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all user story work**
- **Phase 3 (US1/US2)**: Depends on Phase 2 (needs `StreakRecord` + `StreakService`)
- **Phase 4 (US3/US4)**: Depends on Phase 2 (needs `StreakRecord`); depends on T010 (localization) before T011 can compile
- **Phase 5 (Polish)**: Depends on Phases 3 and 4

### User Story Dependencies

| Story | Phase | Depends on | Can start after |
|-------|-------|------------|-----------------|
| US1 + US2 | Phase 3 | Phase 2 complete | T005 merged |
| US3 + US4 | Phase 4 | T004 (StreakRecord) + T010 (l10n) | T004 + T010 done |
| Settings (T014-T015) | Phase 5 | Phase 2 + Phase 3 | T009 merged |

### Within Phase 2

- T002 and T003 are parallel (different test files, no shared code)
- T004 must precede T005 (`StreakService` imports `StreakRecord`)

### Within Phase 4

- T010 must precede T011 (localization keys must exist for test to compile)
- T012 must precede T013 (`WinOverlay` constructor change before body change)
- T011 can be written against the stub constructor from T012 before T013 fills the implementation

---

## Parallel Opportunities

### Phase 2 (run together)

```
T002  Write StreakRecord tests    (test/unit/models/streak_record_test.dart)
T003  Write StreakService tests   (test/unit/services/streak_service_test.dart)
```

### Phases 3 and 4 (after Phase 2)

Phases 3 and 4 can be worked in parallel by different developers once `StreakRecord` (T004) is done.

```
Developer A → Phase 3: T006 → T007 → T008 → T009  (GameScreen integration)
Developer B → Phase 4: T010 → T011 → T012 → T013  (WinOverlay display)
```

---

## Parallel Example: Phase 2

```
# These two test-writing tasks run in parallel:
Task T002: "Write failing StreakRecord tests in test/unit/models/streak_record_test.dart"
Task T003: "Write failing StreakService tests in test/unit/services/streak_service_test.dart"

# After both fail as expected, implement in order:
Task T004: "Implement StreakRecord in lib/models/streak_record.dart"   ← makes T002 green
Task T005: "Implement StreakService in lib/services/streak_service.dart"  ← makes T003 green
```

---

## Implementation Strategy

### MVP (Phase 1 + Phase 2 + Phase 3 only)

1. Phase 1: Create branch
2. Phase 2: Implement `StreakRecord` + `StreakService` with full TDD
3. Phase 3: Wire into `GameScreen`
4. **STOP and VALIDATE**: The streak is tracked and `_streakRecord` is populated on win — verifiable via `flutter test` and debug output
5. The win overlay will not show the streak yet (Phase 4 not done) — this is the deliberate MVP boundary

### Incremental Delivery

1. After Phase 2: Streak logic is complete and unit-tested
2. After Phase 3: Streak is tracked in the live app on puzzle completion (no UI yet)
3. After Phase 4: Full feature — streak displayed to player after every win
4. After Phase 5: Reset flow complete; all quality gates pass; ready for PR

---

## Notes

- `[P]` tasks touch different files and have no mutual dependencies — safe to run concurrently
- `[Story]` labels map each task to a user story for spec traceability
- All new public Dart symbols (classes, constructors, methods, fields) MUST have `///` doc comments — this is a hard constitution requirement
- `SharedPreferences.setMockInitialValues({})` must appear in `setUp()` for every test file that touches `StreakService`
- The `clock` parameter on `StreakService` is the only mechanism for date control in tests — do not use `mockito`/`mocktail` for `DateTime`
- Run `flutter test --coverage` locally before raising a PR to confirm ≥ 85% line coverage
