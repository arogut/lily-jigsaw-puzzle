# Implementation Plan: Hint Feedback Effects

**Branch**: `003-hint-feedback-effects` | **Date**: 2026-06-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-hint-feedback-effects/spec.md`

## Summary

Add auditory and visual feedback to the two key hint lifecycle events:
(1) when a hint unlocks (waiting → available), play a short chime and animate a "pop" bounce on the hint button;
(2) when the last hint is consumed, play a closing sound and animate the hint area out of view before removing it from the widget tree.

The implementation is confined to `SoundService`, `GameScreen`, and `GameBoardView`. No model changes are required.

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.41.3, stable channel)

**Primary Dependencies**: `flutter/material.dart` (AnimationController, Tween, ScaleTransition, FadeTransition), `audioplayers 6.7.0`

**Storage**: N/A

**Testing**: `flutter_test` (built-in); `mocktail` for mocking `SoundService` in widget tests

**Target Platform**: Android only (API defined in `android/app/build.gradle`)

**Project Type**: Mobile app (Flutter Android)

**Performance Goals**: Animations must run at 60 fps; sound must play within 200 ms of the triggering event

**Constraints**: No new packages; two new WAV sound asset files; no changes to `GameState` or `HintSlotState` — purely UI/service layer changes

**Scale/Scope**: 2 new service methods, 2 new AnimationControllers, 2 new parameters on `GameBoardView`, 2 new sound assets

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| I. Children-First UI | ✅ PASS | Animations are short, positive, and child-appropriate. No mockups exist for this sub-feature; design must match app palette (sky blue/lavender/pink) and existing button style. |
| II. TDD (≥ 85% line coverage) | ✅ PASS (mandatory) | All changed methods and new animation logic must have tests written first. `SoundService` and `GameBoardView` widget tests updated before implementation. |
| III. Functional Programming | ✅ PASS | `TweenSequence` and `Animation<double>` are pure value-mapping constructs. No mutable global state added. |
| IV. DRY | ✅ PASS | `SoundService._play()` helper is reused for new methods. Animation pattern from `_hintController` is replicated, not duplicated (different lifecycle/purpose). |
| V. KISS & SOLID | ✅ PASS | Two controllers, two parameters, two sound methods. All responsibility stays in existing layers. |
| VI. Quality Gates | ✅ MANDATORY | `flutter test`, `flutter analyze`, `flutter build apk --debug` must all pass before PR. |

**Complexity Tracking**: No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-hint-feedback-effects/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code Changes

```text
assets/sounds/
├── hint_available.wav        # NEW — short upward chime (~0.5 s)
└── hints_exhausted.wav       # NEW — short descending two-tone (~0.8 s)

lib/services/
└── sound_service.dart        # MODIFY — add playHintAvailable(), playHintsExhausted()

lib/screens/
├── game_screen.dart          # MODIFY — 2 new AnimationControllers, trigger logic, _showingHintArea flag
└── game_board_view.dart      # MODIFY — 2 new Animation<double>? params, animated hint area

test/unit/services/
└── sound_service_test.dart   # MODIFY — add tests for 2 new methods

test/widget/
├── game_screen_loaded_test.dart    # MODIFY — hint-available sound + animation trigger tests
└── screens/game_board_view_test.dart  # MODIFY — hint area animation parameter tests
```

**Structure Decision**: Single project — Flutter Android app. All changes are in `lib/` and `test/`, mirroring existing file organisation.

## Implementation Design

### SoundService Changes

Add two new public methods following the existing pattern:

```
playHintAvailable()  →  _play('sounds/hint_available.wav')
playHintsExhausted() →  _play('sounds/hints_exhausted.wav')
```

No structural changes to `SoundService` — `_play()` already handles fire-and-forget audio.

### GameScreen Changes

Three additions to `_GameScreenState`:

**1. `AnimationController _hintAvailableController`**
- Duration: 500 ms
- Curve via `TweenSequence`: 1.0 → 1.25 → 0.9 → 1.05 → 1.0 (springy pop)
- Initialised in `initState()`, disposed in `dispose()`
- Driven by `_onHintBecameAvailable()` helper

**2. `AnimationController _hintsExhaustedController`**  
- Duration: 400 ms
- Drives combined `ScaleTransition` + `FadeTransition` on hint area
- On completion: `setState(() => _showingHintArea = false)`
- Initialised in `initState()`, disposed in `dispose()`
- Reset in `_restartGame()`

**3. `bool _showingHintArea = true`**
- Set to `false` only after `_hintsExhaustedController` animation completes
- Reset to `true` in `_restartGame()`

**Trigger points:**

| Event | Code Location | Action |
|-------|--------------|--------|
| Hint becomes available | `_startHintTimer` callback (after `markNextSlotAvailable`) | `_onHintBecameAvailable()` → play sound + forward `_hintAvailableController` |
| Last hint used | `onHint` callback (after `activateHint`, when `currentHintSlot == null`) | play sound + forward `_hintsExhaustedController` |

### GameBoardView Changes

Two new optional parameters:

```dart
final Animation<double>? hintAvailableAnimation;
final Animation<double>? hintsExhaustedAnimation;
```

In `_buildRightControls`:

- Wrap hint button with `ScaleTransition(scale: hintAvailableAnimation ?? const AlwaysStoppedAnimation(1.0), child: ...)` to produce the pop effect.
- Wrap the entire hint area (the `Padding` + `GameButton` block) with a combined `ScaleTransition` + `FadeTransition` driven by `hintsExhaustedAnimation`.
- The outer `if (currentHintSlot != null || _showingHintArea)` guard controls when the hint area is present in the tree; currently `currentHintSlot != null` alone does this.

**Note**: `_showingHintArea` is in `GameScreen` (stateful). Pass it as a bool parameter `showHintArea` to `GameBoardView`, replacing the current implicit `currentHintSlot != null` guard.

### Animation Curves

| Animation | Tween | Duration | Curve |
|-----------|-------|----------|-------|
| Hint available (pop) | `TweenSequence`: 1.0→1.25→0.9→1.05→1.0 | 500 ms | `Curves.easeOut` per segment |
| Hints exhausted (exit scale) | `Tween<double>(begin: 1.0, end: 0.0)` | 400 ms | `Curves.easeIn` |
| Hints exhausted (exit fade) | `Tween<double>(begin: 1.0, end: 0.0)` | 400 ms | `Curves.easeIn` |
