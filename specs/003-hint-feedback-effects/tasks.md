# Tasks: Hint Feedback Effects

**Input**: Design documents from `specs/003-hint-feedback-effects/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅ constitution.md ✅

**Tests**: Included per the project constitution (TDD is NON-NEGOTIABLE — see constitution.md Principle II). All tests are written and confirmed to fail before implementation.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies)
- **[Story]**: Which user story this belongs to (US1, US2)
- Exact file paths in every description

---

## Phase 1: Setup (Sound Assets)

**Purpose**: Place required sound asset files before any implementation can be tested end-to-end. These are binary files and cannot be auto-generated — a suitable short WAV must be obtained or recorded for each.

- [X] T001 Add hint_available.wav (short upward chime, ≤1 s) to assets/sounds/hint_available.wav
- [X] T002 Add hints_exhausted.wav (short descending two-tone, ≤1 s) to assets/sounds/hints_exhausted.wav

> **Note**: `assets/sounds/` is already declared as a glob in `pubspec.yaml` — no config change needed. If final audio is not yet available, use any valid WAV file as a placeholder and replace before shipping.

---

## Phase 2: Foundational (SoundService — shared by both user stories)

**Purpose**: Extend `SoundService` with the two new sound methods used by both US1 and US2. Must complete before either user story's implementation can be wired up.

**⚠️ CRITICAL**: Write tests first (TDD). Confirm they FAIL before adding implementation.

- [X] T003 Write failing unit tests for `SoundService.playHintAvailable()` and `SoundService.playHintsExhausted()` in test/unit/services/sound_service_test.dart
- [X] T004 Implement `SoundService.playHintAvailable()` and `SoundService.playHintsExhausted()` delegating to `_play('sounds/hint_available.wav')` and `_play('sounds/hints_exhausted.wav')` in lib/services/sound_service.dart

**Checkpoint**: `flutter test test/unit/services/sound_service_test.dart` passes — both methods exist and return `Future`s.

---

## Phase 3: User Story 1 — Hint Becomes Available (Priority: P1) 🎯 MVP

**Goal**: When the idle timer expires in timed mode, a short chime plays and the hint button displays a springy "pop" bounce animation, alerting the child that a hint is ready.

**Independent Test**: Start a puzzle in timed mode (5-second delay in settings); wait 5 seconds without placing a piece; confirm a sound plays and the hint button visibly pops (see quickstart.md Scenario 1).

### Tests for User Story 1

> **Write these tests first — confirm they FAIL before implementation**

- [X] T005 [P] [US1] Write failing widget test: `GameBoardView` wraps hint button in `ScaleTransition` when `hintAvailableAnimation` is a non-null animation — find `ScaleTransition` in test/widget/screens/game_board_view_test.dart
- [X] T006 [P] [US1] Write failing widget test: `GameScreen` (timed mode, 1-second delay) advances `_hintAvailableController` after the hint timer fires — pump past the delay and verify hint slot is `available` and animation controller has run in test/widget/game_screen_loaded_test.dart

### Implementation for User Story 1

- [X] T007 [P] [US1] Add `hintAvailableAnimation` parameter (`Animation<double>?`) to `GameBoardView` and wrap the hint `GameButton` in `ScaleTransition(scale: hintAvailableAnimation ?? const AlwaysStoppedAnimation(1.0), ...)` in lib/screens/game_board_view.dart
- [X] T008 [P] [US1] Add `_hintAvailableController` (`AnimationController`, 500 ms) to `_GameScreenState`; define a `TweenSequence<double>` (1.0 → 1.25 → 0.9 → 1.05 → 1.0) animated against it; initialise in `initState()` and dispose in `dispose()` in lib/screens/game_screen.dart
- [X] T009 [US1] In `_startHintTimer` callback (after `markNextSlotAvailable()`): call `SoundService().playHintAvailable()` and `_hintAvailableController.forward(then: (_) => _hintAvailableController.reset())`; pass the `TweenSequence` animation as `hintAvailableAnimation` to `GameBoardView` in `_buildBody()` in lib/screens/game_screen.dart

**Checkpoint**: `flutter test test/widget/screens/game_board_view_test.dart` and `flutter test test/widget/game_screen_loaded_test.dart` pass. US1 manually verifiable per quickstart.md Scenario 1.

---

## Phase 4: User Story 2 — All Hints Exhausted (Priority: P2)

**Goal**: When the child taps the last available hint, a distinct "no more hints" sound plays and the hint button area smoothly scales and fades out of view (400 ms), then is fully removed from the widget tree.

**Independent Test**: In Immediate mode, use all 3 hints; on the third tap confirm a distinct sound plays and the hint area animates away within 400 ms, leaving no interactive residue (see quickstart.md Scenario 3).

### Tests for User Story 2

> **Write these tests first — confirm they FAIL before implementation**

- [X] T010 [P] [US2] Write failing widget tests for `GameBoardView`: (a) hint area is wrapped in `ScaleTransition` + `FadeTransition` when `hintsExhaustedAnimation` is non-null; (b) hint area is absent from the tree when `showHintArea` is `false` in test/widget/screens/game_board_view_test.dart
- [X] T011 [P] [US2] Write failing widget test: `GameScreen` (Immediate mode) — after tapping hint button 3 times (placing the hinted piece each time), the hint area begins its exit animation (verify `_showingHintArea` driven state via widget presence) in test/widget/game_screen_loaded_test.dart

### Implementation for User Story 2

- [X] T012 [P] [US2] Add `hintsExhaustedAnimation` (`Animation<double>?`) and `showHintArea` (`bool`, default `true`) parameters to `GameBoardView`; change the `if (currentHintSlot != null)` guard to `if (showHintArea)`; wrap the hint area `Padding` in `ScaleTransition` + `FadeTransition` (both driven by `hintsExhaustedAnimation ?? const AlwaysStoppedAnimation(1.0)`) in lib/screens/game_board_view.dart
- [X] T013 [P] [US2] Add `_hintsExhaustedController` (`AnimationController`, 400 ms, `Curves.easeIn`) and `bool _showingHintArea = true` to `_GameScreenState`; initialise in `initState()`, dispose in `dispose()`, reset both in `_restartGame()` in lib/screens/game_screen.dart
- [X] T014 [US2] In the `onHint` callback in `_buildBody()`: after `gs.activateHint()`, if `gs.currentHintSlot == null`, call `SoundService().playHintsExhausted()` and `_hintsExhaustedController.forward().then((_) { if (mounted) setState(() => _showingHintArea = false); })`; pass `showHintArea: _showingHintArea` and `hintsExhaustedAnimation: Tween(begin: 1.0, end: 0.0).animate(_hintsExhaustedController)` to `GameBoardView` in lib/screens/game_screen.dart

**Checkpoint**: All widget tests pass. US2 manually verifiable per quickstart.md Scenario 3. Both Scenarios 4 and 5 (muted device; restart) also pass.

---

## Phase 5: Polish & Quality Gates

**Purpose**: Verify all quality gates defined in the project constitution before raising a PR.

- [X] T015 Run `flutter test --coverage` and confirm zero test failures and ≥ 85% line coverage; fix any gaps in lib/services/sound_service.dart, lib/screens/game_board_view.dart, lib/screens/game_screen.dart
- [X] T016 Run `flutter analyze` and fix any warnings or lint violations introduced by the feature changes
- [X] T017 Run `flutter build apk --debug` and confirm clean compilation with no build errors
- [ ] T018 Manually execute all 5 quickstart.md validation scenarios on device or AVD and confirm all pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (Sound Assets): No dependencies — start immediately
- **Phase 2** (SoundService): Depends on Phase 1 assets existing; tests can be written before assets land but integration requires WAV files
- **Phase 3** (US1): Depends on Phase 2 completion — both new sound methods must exist before wiring triggers
- **Phase 4** (US2): Depends on Phase 2 completion; independent of Phase 3 (no shared code paths)
- **Phase 5** (Polish): Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependency on US2. Can be shipped independently.
- **US2 (P2)**: No dependency on US1. Can be developed in parallel with US1 after Phase 2 completes.

### Within Each User Story

1. Tests MUST be written and confirmed to FAIL first (TDD mandate)
2. `GameBoardView` parameter changes (T007 / T012) before `GameScreen` wiring (T009 / T014)
3. `AnimationController` additions (T008 / T013) in parallel with view changes
4. Wiring task (T009 / T014) requires both view and controller additions to be done

---

## Parallel Opportunities

### Phase 1
```
T001 (hint_available.wav)   ← parallel
T002 (hints_exhausted.wav)  ← parallel
```

### Phase 3 Tests + Implementation (after Phase 2 complete)
```
T005 (game_board_view_test.dart)  ← parallel tests
T006 (game_screen_loaded_test.dart)
```
```
T007 (game_board_view.dart)  ← parallel implementation
T008 (game_screen.dart)
↓
T009 (game_screen.dart wiring)  ← sequential
```

### Phase 4 Tests + Implementation (after Phase 2 complete, in parallel with Phase 3)
```
T010 (game_board_view_test.dart)  ← parallel tests
T011 (game_screen_loaded_test.dart)
```
```
T012 (game_board_view.dart)  ← parallel implementation
T013 (game_screen.dart)
↓
T014 (game_screen.dart wiring)  ← sequential
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001, T002 — sound assets)
2. Complete Phase 2 (T003, T004 — SoundService)
3. Complete Phase 3 (T005–T009 — hint available feedback)
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 + Scenario 2
5. Confirm all quality gates pass (`flutter test`, `flutter analyze`, `flutter build apk --debug`)

### Incremental Delivery

1. Phase 1 + Phase 2 → audio foundation ready
2. Phase 3 → US1 complete (hint-available pop + chime) → test independently
3. Phase 4 → US2 complete (exhausted exit animation + sound) → test independently
4. Phase 5 → all quality gates confirmed → PR ready

---

## Notes

- `[P]` tasks in the same phase can be launched in parallel (they edit different files)
- `[Story]` label maps each task to the user story it delivers
- Each user story phase is independently completable and testable
- TDD cycle per task: write failing test → confirm red → implement → confirm green → refactor → commit
- The `_BoardViewHarness` in `game_board_view_test.dart` will need to be extended to accept the two new animation parameters (T005 / T010)
- `SoundService` cannot be easily mocked in widget tests (singleton); test the sound methods in unit tests (T003) and test the animation/UI state transitions in widget tests (T005–T006, T010–T011)
- Commit after each completed phase as a logical milestone
