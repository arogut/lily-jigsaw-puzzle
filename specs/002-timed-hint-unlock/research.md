# Research: Timed Hint Unlock

**Feature**: 002-timed-hint-unlock
**Date**: 2026-06-10

---

## Decision 1: Timer Implementation Strategy

**Decision**: Use `dart:async Timer` managed in `GameScreen`, not the physics ticker or a separate
isolate.

**Rationale**: A one-shot `Timer` is the idiomatic Dart approach for a single countdown. The
physics ticker runs every frame (≈16 ms) and is optimised for position updates — piggybacking
timer logic onto it adds coupling. A `Timer` fires on the platform event loop at the configured
interval, providing sufficient ±1 s accuracy for a children's game. No additional package is
needed.

**Alternatives considered**:
- Physics ticker accumulation — rejected; adds coupling between rendering and game logic.
- `Timer.periodic` — rejected; one-shot Timer is simpler for a count-down that resets on events.
- `Stopwatch` + periodic check — rejected; more complex without accuracy benefit.

---

## Decision 2: Timer Pause on Backgrounding

**Decision**: Implement `WidgetsBindingObserver` in `_GameScreenState`. On
`AppLifecycleState.paused` / `inactive`, record `_remainingHintDelay` (= start time + delay −
now) and cancel the active `Timer`. On `AppLifecycleState.resumed`, restart a new `Timer` with
`_remainingHintDelay` if it was non-zero and a hint slot is still `waiting`.

**Rationale**: The spec (SC-007, edge case) requires that background time does not count toward
the idle period. `WidgetsBindingObserver` is the Flutter-standard way to observe app lifecycle.
`GameScreen` already has a `Ticker`-based infrastructure (physics simulation), so adding an
observer is a minimal addition.

**Alternatives considered**:
- Ignoring background state — rejected; violates FR-010 and SC-007.
- `AppLifecycleListener` (Flutter 3.13+) — viable but `WidgetsBindingObserver` has broader
  compat and is already in wider use across the codebase pattern.

---

## Decision 3: SharedPreferences Keys for HintSettings

**Decision**: Use `hint_immediate_mode` (bool) and `hint_unlock_delay_seconds` (int).

**Rationale**: Consistent with existing DifficultySettings key naming convention
(`difficulty_easy`, `difficulty_medium`, `difficulty_hard`). Prefixed with `hint_` to avoid
future collisions.

**Defaults**: `immediateMode = false`, `unlockDelaySeconds = 10`.

---

## Decision 4: HintSlotState Representation in GameState

**Decision**: `GameState` holds `List<HintSlotState> _hintSlots` (fixed length 3) and
`int? _hintedPieceIndex` (index into `_pieces` of the currently highlighted piece).

`HintSlotState` is a plain enum:
```
waiting   → timer counting; button visible but inactive
available → timer expired; button active
used      → hint consumed; button hidden
```

`GameState` exposes:
- `HintSlotState? get currentHintSlot` — state of the first non-`used` slot; null if all used
- `void markNextSlotAvailable()` — `waiting → available` for the first waiting slot; called by `GameScreen` when the timer fires
- `void activateHint()` — `available → used`; picks a random unplaced piece; sets `_hintedPieceIndex`
- `int? get hintedPieceIndex` — null when no hint is active
- `bool get isHintedPiecePlaced` — true when `_hintedPieceIndex != null` and the piece at that index has `isPlaced == true`

`GameScreen` inspects `gs.isHintedPiecePlaced` after each `endDrag()` call to detect when to
start the next slot's timer.

**Rationale**: SRP — `GameState` tracks slot state; `GameScreen` owns timer lifecycle. This keeps
pure state mutations in the model and side-effectful timer management in the screen.

**Fallback logic location**: `GameScreen` applies the fallback rule (start next timer even if
hinted piece is still unplaced) — a single placement-attempt resets the timer regardless, so the
fallback fires naturally after an idle period with no activity.

---

## Decision 5: Settings Screen Integration

**Decision**: Add a `HintSettings hintSettings` parameter to `SettingsScreen` (same pattern as
`DifficultySettings difficultySettings`). The Hints section renders:
- A `Checkbox` row: "Immediate (always available)"
- A `TextField` (numeric, `FilteringTextInputFormatter.digitsOnly`) for the delay in seconds;
  disabled when `immediateMode == true`
- Validation: empty or zero → reject, revert to last valid value (default 10 if never set)

**Rationale**: Matches the existing settings architecture. `HintSettings` is a `ChangeNotifier`,
so the settings section rebuilds reactively when values change. The `TextField` is disabled via
`enabled: !hintSettings.immediateMode`.

---

## Decision 6: Localization Strings Required

New keys needed in all four ARB files (en, pl, de, es):

| Key | English value |
|-----|--------------|
| `hintsSection` | `Hints` |
| `hintsImmediate` | `Immediate (always available)` |
| `hintsDelayLabel` | `Unlock after (seconds)` |
| `hintsDelayError` | `Enter a number greater than 0` |

---

## Decision 7: GameBoardView Hint Button Rendering

**Decision**: Replace the current single `onHint: VoidCallback?` parameter with
`hintSlot: HintSlotState?` (null = all hints used). `GameBoardView` derives enabled/visible state:
- `null` → hide button completely
- `HintSlotState.waiting` → show button, `enabled: false`, opacity 0.5
- `HintSlotState.available` → show button, `enabled: true`, opacity 1.0
- `HintSlotState.used` → impossible value once slot is consumed; slot advances before next render

The hint count label (`(${gs.hintsRemaining})`) is removed; replaced by a state-driven button.

**Rationale**: Passing the slot state (not a callback) gives the view enough information to render
all three visual states without needing a callback for the inactive state.
