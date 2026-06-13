# Data Model: Hint Feedback Effects

## Overview

This feature adds no new persistent data entities and no changes to `GameState` or `HintSlotState`. All additions are ephemeral UI-layer state (animation controllers and a visibility flag) owned by `_GameScreenState`.

---

## Existing Entities (unchanged)

### HintSlotState *(lib/models/hint_slot_state.dart)*

```
waiting  →  available  →  used
```

- `waiting`: timer running, button visible but non-interactive
- `available`: timer expired, button active and tappable
- `used`: hint consumed, button hidden

This feature hooks into two transitions:
- `waiting → available` (timed only): triggers hint-available sound + bounce animation
- `used` (when it is the third/last slot): triggers all-hints-exhausted sound + exit animation

### GameState *(lib/models/game_state.dart)*

Relevant accessors (read-only from the feature's perspective):

| Accessor | Type | Used for |
|----------|------|---------|
| `currentHintSlot` | `HintSlotState?` | Null when all 3 slots are `used` — signals "all exhausted" |
| `markNextSlotAvailable()` | `void` | Existing trigger point for hint-available feedback |
| `activateHint()` | `void` | Existing trigger point for checking "last hint used" |

---

## New Ephemeral UI State (in `_GameScreenState`)

These are not persisted, not serialised, and reset on puzzle restart.

| Field | Type | Initial Value | Description |
|-------|------|---------------|-------------|
| `_hintAvailableController` | `AnimationController` | Stopped at 0.0 | Drives the "pop" bounce animation on the hint button. Forward-only; resets between each hint unlock. |
| `_hintsExhaustedController` | `AnimationController` | Stopped at 0.0 | Drives the combined scale+fade exit animation on the hint area. Forward-only; fires once per puzzle session at most. |
| `_showingHintArea` | `bool` | `true` | Controls whether the hint area widget is present in the tree. Set to `false` only after `_hintsExhaustedController` completes. Reset to `true` in `_restartGame()`. |

---

## Animation Value Mappings

### Hint Available — Pop Bounce (`_hintAvailableController`, 500 ms)

| t | Scale |
|---|-------|
| 0.0 | 1.0 |
| 0.25 | 1.25 |
| 0.55 | 0.9 |
| 0.75 | 1.05 |
| 1.0 | 1.0 |

Implemented as a `TweenSequence<double>` passed to `ScaleTransition`. Triggers once per `waiting → available` transition.

### Hints Exhausted — Scale+Fade Exit (`_hintsExhaustedController`, 400 ms)

| t | Scale | Opacity |
|---|-------|---------|
| 0.0 | 1.0 | 1.0 |
| 1.0 | 0.0 | 0.0 |

Both driven by the same controller via `CurvedAnimation(curve: Curves.easeIn)`. After `t = 1.0`, `_showingHintArea` is set to `false` to remove the widget from the tree.

---

## State Transition Table

| Trigger | Pre-state | Post-state | Side effects added by this feature |
|---------|-----------|------------|-------------------------------------|
| Idle timer expires (timed mode) | `currentHintSlot == HintSlotState.waiting` | `currentHintSlot == HintSlotState.available` | Play `hint_available.wav`; forward `_hintAvailableController` |
| Player taps hint (not last) | `currentHintSlot == HintSlotState.available`, ≥1 remaining | Next slot is `waiting` or `available` | (no new side effects) |
| Player taps last hint | `currentHintSlot == HintSlotState.available`, 0 remaining after | `currentHintSlot == null` | Play `hints_exhausted.wav`; forward `_hintsExhaustedController`; on animation complete: `_showingHintArea = false` |
