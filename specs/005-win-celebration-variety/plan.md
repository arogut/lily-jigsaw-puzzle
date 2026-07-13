# Implementation Plan: Win Celebration Variety

**Branch**: `005-win-celebration-variety` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-win-celebration-variety/spec.md`

## Summary

Replace the single confetti win celebration with 4 distinct celebration styles
(confetti, balloons, fireworks, milestone) cycled via
`styleId = standardStyles[(dayOffset(date) + dailyCount) % 3]`. Each calendar
day starts at a deterministic offset; each completion within a day advances
`dailyCount` (persisted, resets at day boundaries).

**Two-phase win flow** (FR-005a):
1. **Animation phase** — full-screen `CelebrationLayer` + looping fanfare; tap anywhere to skip.
2. **Overlay phase** — fixed `WinOverlay` (party-popper 🎉, original pastel palette — no style theming); fanfare continues until celebration ends.

Celebration ends on backdrop dismiss (**Back** only afterward) or **Play Again** / **New Puzzle**.

**Intensity** scales animation duration and particle count only (`level = clamp(weeks + 1, 1, 5)`). Fanfare uses one looped asset per style; clip length does not scale with intensity; loops until `stopWinFanfare()`.

No new packages required.

## Technical Context

**Language/Version**: Dart 3.12, Flutter 3.41.3 (stable channel)

**Primary Dependencies** (no new packages):
- `audioplayers: 6.8.1` — `SoundService` fanfare loop + stop
- `shared_preferences: 2.5.5` — `DailyCompletionTracker` via `PreferencesStore`

**Storage**: `celebration_daily_date` + `celebration_daily_count` keys only (no weekly sequence).

**Testing**: `flutter_test`; hand-rolled fakes for `PreferencesStore` / `SoundService` in widget tests.

**Target Platform**: Android (Samsung Galaxy Tab S8+ primary, API 36)

**Performance Goals**:
- 60 fps for up to 250 particles on Tab S8+
- Animation skip → overlay: ≤ 200 ms (SC-005)
- Overlay dismiss → stopped state: ≤ 200 ms (SC-005a)
- Max animation duration at intensity cap: ≤ 12 s (SC-006); skippable anytime

**Constraints**:
- Flutter `CustomPainter` + `AnimationController` only
- One fanfare asset per style; `ReleaseMode.loop` until celebration ends
- `CelebrationPhase` state machine in `GameScreen` (`animating` → `overlay` → dismissed)
- Fixed win overlay design — remove per-style theming from `WinOverlay`

**Scale/Scope**: 4 styles, 5 intensity levels, 2-phase celebration flow

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

### I. Children-First UI (NON-NEGOTIABLE)
- [ ] Visual designs for animation styles in `assets/design/` before merge.
- [ ] Win overlay matches pre-variety design (🎉, pastel palette) — not style-themed.
- [ ] **BLOCKER**: Missing mockups → placeholder + sign-off before UI PR.

### II. Test-Driven Development (NON-NEGOTIABLE)
- [ ] Failing tests before implementation; ≥ 85% line coverage.

### III. Functional Programming Preferred
- [ ] `CelebrationSelector` and `CelebrationIntensity.fromStreakWeeks` are pure.

### IV. DRY
- [ ] Constants in `celebration_constants.dart` only.

### V. KISS & SOLID
- [ ] `CelebrationSelector` — selection only; `DailyCompletionTracker` — persistence only.
- [ ] `GameScreen` owns phase transitions; `CelebrationLayer` — visuals only.

### VI. Quality Gates (NON-NEGOTIABLE)
- [ ] `flutter test`, `flutter analyze` (exit 0, no issues), `flutter build apk --debug`.

## Project Structure

### Documentation

```text
specs/005-win-celebration-variety/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/celebration-api.md
└── tasks.md          ← regenerate via /speckit-tasks after plan sync
```

### Source Code Changes

```text
lib/
  core/constants/celebration_constants.dart   NEW/MODIFY
  models/celebration_style.dart                 NEW/MODIFY — CelebrationStyleId,
                                                CelebrationIntensity (animation only),
                                                CelebrationPhase enum
  services/
    celebration_selector.dart                 NEW
    daily_completion_tracker.dart             NEW
    sound_service.dart                        MODIFY — playWinFanfare(style) loops
                                                until stopWinFanfare()
  painters/                                   NEW/REPLACE painters per style
  widgets/
    celebration_layer.dart                    NEW — animation phase only; onComplete,
                                                onSkip tap target
    win_overlay.dart                          MODIFY — onDismiss; remove celebrationStyle
                                                theming; restore fixed 🎉 design
  screens/
    game_screen.dart                          MODIFY — CelebrationPhase state machine:
                                                animating → overlay → dismissed
    game_board_view.dart                      MODIFY — show layer OR overlay, not both

test/                                           mirrors lib/ + phase transition tests
```

### Structure Decision

Flutter mobile app. `GameScreen` coordinates phases; widgets stay single-purpose.

## Complexity Tracking

No constitution violations. `CelebrationPhase` in `GameScreen` is justified by
sequential UX requirements (FR-005a); painters remain stateless aside from local
`AnimationController` in `CelebrationLayer`.
