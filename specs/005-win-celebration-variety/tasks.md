# Tasks: Win Celebration Variety

**Input**: Design documents from `specs/005-win-celebration-variety/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**TDD**: Constitution mandates test-first. Within every phase: write failing tests → implement → pass → refactor.

**Note**: Branch `005-win-celebration-variety` may contain a prior implementation (simultaneous overlay + style-themed win card). Tasks below include **refactor** steps to align with the two-phase flow clarified 2026-07-13.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no competing writes)
- **[Story]**: User story (US1–US5)

---

## Phase 1: Setup

**Purpose**: Register audio assets; no new dependencies.

- [X] T001 Add fanfare asset entries to `pubspec.yaml`: `assets/sounds/win_confetti.wav`, `win_balloons.wav`, `win_fireworks.wav`, `win_milestone.wav`
- [X] T002 [P] Ensure placeholder audio files exist at `assets/sounds/win_confetti.wav`, `win_balloons.wav`, `win_fireworks.wav`, `win_milestone.wav`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, constants, and phase enum. Complete before user story work.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

### Tests (write first — must FAIL before implementation)

- [X] T003 [P] Write unit tests for `CelebrationStyleId` and `CelebrationPhase` in `test/unit/models/celebration_style_test.dart`
- [X] T004 [P] Write unit tests for `CelebrationConstants` (`baseAnimationDuration`, `maxAnimationDuration`, particle counts, intensity cap) in `test/unit/models/celebration_style_test.dart`
- [X] T005 [P] Write unit tests for `CelebrationIntensity.fromStreakWeeks` deriving `animationDuration` and `particleCount` only (no fanfare duration field) in `test/unit/models/celebration_style_test.dart`

### Implementation

- [X] T006 [P] Implement `CelebrationStyleId` with `standardStyles` in `lib/models/celebration_style.dart`
- [X] T007 [P] Add `CelebrationPhase` enum (`animating`, `overlay`) in `lib/models/celebration_style.dart`
- [X] T008 [P] Implement `CelebrationConstants` with `baseAnimationDuration` / `maxAnimationDuration` (replace any `*FanfareDuration` names) in `lib/core/constants/celebration_constants.dart`
- [X] T009 Implement `CelebrationIntensity` with `animationDuration` (not `fanfareDuration`) in `lib/models/celebration_style.dart`

**Checkpoint**: `flutter test test/unit/models/celebration_style_test.dart` passes.

---

## Phase 3: User Story 1 — Varied Celebration on Every Completion (Priority: P1) 🎯 MVP

**Goal**: Every completion resolves a distinct style via `dayOffset + dailyCount` cycling.

**Independent Test**: Complete 3 puzzles in one session → 3 different `CelebrationStyleId` values (debug log or overlay header).

### Tests (write first)

- [X] T010 [P] [US1] Write `CelebrationSelector` unit tests in `test/unit/services/celebration_selector_test.dart`
- [X] T011 [P] [US1] Write `DailyCompletionTracker` unit tests in `test/unit/services/daily_completion_tracker_test.dart`

### Implementation

- [X] T012 [P] [US1] Implement `CelebrationSelector` in `lib/services/celebration_selector.dart`
- [X] T013 [P] [US1] Implement `DailyCompletionTracker` in `lib/services/daily_completion_tracker.dart`
- [X] T014 [US1] Wire style resolution into `GameScreen._onWin()` (store `CelebrationStyleId`; placeholder animation OK) in `lib/screens/game_screen.dart`

**Checkpoint**: `flutter test test/unit/services/celebration_selector_test.dart test/unit/services/daily_completion_tracker_test.dart` passes.

---

## Phase 4: User Story 2 — Distinct Styles + Two-Phase Flow (Priority: P2)

**Goal**: Animation phase (skippable) → fixed 🎉 overlay phase; distinct painters per style; fanfare loops until celebration ends.

**Independent Test**: Win puzzle → animation only → tap skip OR wait → overlay appears (never simultaneous); overlay uses fixed design for all styles.

### Tests (write first)

- [X] T015 [P] [US2] Write `ConfettiPainter` unit tests in `test/unit/painters/confetti_painter_test.dart`
- [X] T016 [P] [US2] Write `BalloonPainter` unit tests in `test/unit/painters/balloon_painter_test.dart`
- [X] T017 [P] [US2] Write `FireworksPainter` unit tests in `test/unit/painters/fireworks_painter_test.dart`
- [X] T018 [P] [US2] Write `CelebrationLayer` widget tests (renders per style; `onSkip` / `onAnimationComplete` fire; controller disposed) in `test/widget/widgets/celebration_layer_test.dart`
- [X] T019 [P] [US2] Write `WinOverlay` tests (fixed 🎉 design; `onDismiss`; no `celebrationStyle` theming param) in `test/unit/widgets/win_overlay_test.dart`
- [X] T020 [P] [US2] Write `SoundService.playWinFanfare(style)` / `stopWinFanfare()` tests (loops until stop; no duration arg) in `test/unit/services/sound_service_test.dart`
- [X] T021 [P] [US2] Write two-phase widget tests in `test/widget/game_screen_loaded_test.dart` (animation without overlay; skip → overlay; never both visible)

### Implementation — painters & layer

- [X] T022 [US2] Implement configurable `ConfettiPainter` in `lib/painters/confetti_painter.dart`
- [X] T023 [P] [US2] Implement `BalloonPainter` in `lib/painters/balloon_painter.dart`
- [X] T024 [P] [US2] Implement `FireworksPainter` in `lib/painters/fireworks_painter.dart`
- [X] T025 [US2] Refactor `CelebrationLayer`: `animationDuration` from intensity; add `onSkip` + `onAnimationComplete`; remove overlay-era assumptions in `lib/widgets/celebration_layer.dart`

### Implementation — audio & overlay

- [X] T026 [US2] Refactor `SoundService.playWinFanfare(CelebrationStyleId style)` to loop until `stopWinFanfare()` (remove duration parameter) in `lib/services/sound_service.dart`
- [X] T027 [US2] Refactor `WinOverlay`: restore fixed 🎉 / pastel design; remove `celebrationStyle` theming; keep `onDismiss` in `lib/widgets/win_overlay.dart`

### Implementation — phase state machine

- [X] T028 [US2] Implement `CelebrationPhase` state machine in `GameScreen._onWin()`: `animating` → `overlay` → dismissed; fanfare starts at win; stops on end in `lib/screens/game_screen.dart`
- [X] T029 [US2] Update `GameBoardView` to show `CelebrationLayer` OR `WinOverlay`, never both, in `lib/screens/game_board_view.dart`
- [X] T030 [US2] Wire backdrop dismiss → puzzle board + **Back** only (no persistent Play Again / New Puzzle) per FR-006a in `lib/screens/game_screen.dart`
- [X] T031 [US2] Ensure **Play Again** / **New Puzzle** call `stopWinFanfare()` before action in `lib/screens/game_screen.dart`

**Checkpoint**: `flutter test test/unit/painters/ test/widget/widgets/celebration_layer_test.dart test/widget/game_screen_loaded_test.dart` passes. Manual: quickstart Scenarios 3–4.

---

## Phase 5: User Story 3 — Streak Milestone Celebration (Priority: P2)

**Goal**: Milestone style defined; never in daily rotation; uses same two-phase flow.

**Independent Test**: Invoke milestone style directly → grander animation; `CelebrationSelector` never returns milestone.

### Tests (write first)

- [X] T032 [P] [US3] Write `MilestonePainter` unit tests in `test/unit/painters/milestone_painter_test.dart`
- [X] T033 [P] [US3] Add milestone scenario to `test/widget/widgets/celebration_layer_test.dart`
- [X] T034 [P] [US3] Assert `CelebrationSelector.styleFor` never returns milestone in `test/unit/services/celebration_selector_test.dart`

### Implementation

- [X] T035 [US3] Implement `MilestonePainter` in `lib/painters/milestone_painter.dart`
- [X] T036 [US3] Add milestone dispatch to `CelebrationLayer` in `lib/widgets/celebration_layer.dart`

**Checkpoint**: Milestone renders in isolation; not in rotation.

---

## Phase 6: User Story 4 — Streak-Scaled Animation Intensity (Priority: P2)

**Goal**: Higher streak → more particles + longer animation; fanfare clip unchanged.

**Independent Test**: Mock streak weeks 0 vs 4 → particle count and `animationDuration` differ; fanfare loop behaviour identical.

### Tests (write first)

- [X] T037 [P] [US4] Extend intensity interpolation tests (level 1 min, level 5 max animation duration) in `test/unit/models/celebration_style_test.dart`
- [X] T038 [P] [US4] Widget test: `CelebrationLayer` uses `intensity.animationDuration` for controller in `test/widget/widgets/celebration_layer_test.dart`

### Implementation

- [X] T039 [US4] Wire `CelebrationIntensity.fromStreakWeeks(streak ~/ 7)` into `GameScreen._onWin()` in `lib/screens/game_screen.dart`
- [X] T040 [US4] Remove any remaining `fanfareDuration` / intensity-scaled audio timer logic from `lib/services/sound_service.dart` and `lib/screens/game_screen.dart`

**Checkpoint**: quickstart Scenario 5 passes.

---

## Phase 7: User Story 5 — Graceful Degradation When Sound Is Off (Priority: P3)

**Goal**: Visual celebration complete when audio unavailable; errors swallowed.

**Independent Test**: Muted device or failing audio → animation + overlay work; no crash.

### Tests (write first)

- [X] T041 [P] [US5] Test `playWinFanfare` completes without rethrow on audio failure in `test/unit/services/sound_service_test.dart`
- [X] T042 [P] [US5] Test `CelebrationLayer` renders without `SoundService` dependency in `test/widget/widgets/celebration_layer_test.dart`

### Implementation

- [X] T043 [US5] Wrap audio calls in `try/on Object` in `lib/services/sound_service.dart`
- [X] T044 [US5] Confirm `CelebrationLayer` has no `SoundService` import; sound triggered only from `GameScreen` in `lib/widgets/celebration_layer.dart`

**Checkpoint**: quickstart Scenario 8 passes.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T045 [P] Call `DailyCompletionTracker.reset()` from `ProgressResetService` in `lib/services/progress_reset_service.dart` (+ test in `test/unit/services/progress_reset_service_test.dart`)
- [X] T046 [P] Run `flutter analyze` — exit 0, "No issues found!"
- [X] T047 [P] Run `flutter test --coverage`; confirm ≥ 85% on new/changed files
- [X] T048 [P] `flutter build apk --debug`
- [ ] T049 Execute `quickstart.md` Scenarios 1–10 on device
- [X] T050 Remove dead code from prior simultaneous-overlay implementation (`celebrationStyle` on overlay, `fanfareDuration` on intensity, unused props on `GameBoardView`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** → **Phase 2** → **US1** → **US2** (blocks visual/two-phase) → **US3 ‖ US4 ‖ US5** (parallel after US2) → **Polish**

### User Story Dependencies

| Story | Depends on | Delivers |
|-------|------------|----------|
| US1 | Phase 2 | Style rotation |
| US2 | US1 | Two-phase flow, painters, fixed overlay, fanfare loop |
| US3 | US2 | Milestone painter |
| US4 | US2 | Intensity → animation only |
| US5 | US2 | Audio resilience |

### Parallel Opportunities

```
Phase 2:  T003 ‖ T004 ‖ T005  →  T006 ‖ T007 ‖ T008  →  T009
US1:      T010 ‖ T011  →  T012 ‖ T013  →  T014
US2:      T015–T021 (tests)  →  T023 ‖ T024  →  T026 ‖ T027  →  T028–T031
US3–US5:  parallel after US2 checkpoint
```

---

## Parallel Example: User Story 2

```text
# Tests in parallel:
T015 confetti_painter_test.dart
T016 balloon_painter_test.dart
T017 fireworks_painter_test.dart
T018 celebration_layer_test.dart
T019 win_overlay_test.dart
T020 sound_service_test.dart

# Painters in parallel (after tests fail):
T023 balloon_painter.dart
T024 fireworks_painter.dart
```

---

## Implementation Strategy

### MVP (User Story 1)

1. Phases 1–2: constants, models, intensity
2. Phase 3: selector + tracker + style wired in `_onWin`
3. **Validate**: 3 wins → 3 different style IDs

### Incremental Delivery

1. MVP (US1) → style rotation proven
2. US2 → two-phase flow + distinct animations + fixed overlay ← **feature complete**
3. US3 + US4 + US5 in parallel
4. Polish + device quickstart

### Refactor note (existing branch)

If code already implements the old design, prioritize **T025–T031** and **T040** before adding new painters. Run tests after each refactor step.

---

## Notes

- Win overlay = `WinOverlay` card, **not** app `SplashScreen`
- Fanfare loops until `stopWinFanfare()`; intensity does **not** scale fanfare
- Animation skip and overlay dismiss are distinct taps (FR-005b, FR-006)
- `[P]` = safe parallelization across different files
