# Data Model: Timed Hint Unlock

**Feature**: 002-timed-hint-unlock
**Date**: 2026-06-10

---

## New: HintSlotState (enum)

**File**: `lib/models/hint_slot_state.dart`

| Value | Meaning | Button visible? | Button interactive? |
|-------|---------|----------------|-------------------|
| `waiting` | Idle timer is counting; hint not yet earned | Yes | No |
| `available` | Timer expired; hint ready to use | Yes | Yes |
| `used` | Hint consumed; hidden | No | — |

**Lifecycle**:
```
[game start, timed mode]  → waiting
waiting + timer expires   → available
available + player taps   → used

[game start, immediate mode] → available (skip waiting)
```

**Constraints**:
- Enum with exactly 3 values.
- All 3 hint slots start in `waiting` (timed mode) or `available` (immediate mode).
- Transition `waiting → available` is triggered externally (by `GameScreen` timer).
- Transition `available → used` is triggered by `activateHint()` in `GameState`.
- No backward transitions.

---

## New: HintSettings (ChangeNotifier)

**File**: `lib/services/hint_settings_service.dart`

| Field | Type | Default | Validation | SharedPreferences key |
|-------|------|---------|------------|----------------------|
| `immediateMode` | `bool` | `false` | — | `hint_immediate_mode` |
| `unlockDelaySeconds` | `int` | `10` | ≥ 1 | `hint_unlock_delay_seconds` |

**Constructors / factory**:
- `HintSettings({required bool immediateMode, required int unlockDelaySeconds})`
- `static Future<HintSettings> load()` — reads SharedPreferences, applies defaults on missing/invalid values

**Mutators**:
- `void setImmediateMode(bool value)` — sets `immediateMode`, calls `notifyListeners()`, fires async `_save()`
- `void setUnlockDelay(int value)` — guards: `if (value < 1) return;`; sets `unlockDelaySeconds`, calls `notifyListeners()`, fires async `_save()`

**Validation rule**: Any value < 1 for `unlockDelaySeconds` is silently rejected; the field retains its previous valid value. The UI layer is responsible for showing an error to the adult.

---

## Modified: GameState

**File**: `lib/models/game_state.dart`

### Removed fields

| Removed | Replacement |
|---------|-------------|
| `int _hintsRemaining` | `List<HintSlotState> _hintSlots` |

### Added fields

| Field | Type | Initial value (timed) | Initial value (immediate) |
|-------|------|----------------------|--------------------------|
| `_hintSlots` | `List<HintSlotState>` | `[waiting, waiting, waiting]` | `[available, available, available]` |
| `_hintedPieceIndex` | `int?` | `null` | `null` |

### Constructor change

```
GameState({
  ...,
  bool immediateMode = false,   // new parameter
})
```

`_hintSlots` initialized based on `immediateMode`.

### New / changed getters and methods

| Member | Signature | Behaviour |
|--------|-----------|-----------|
| `currentHintSlot` | `HintSlotState? get` | First non-`used` slot state; null when all 3 are `used` |
| `hintedPieceIndex` | `int? get` | Index of currently hinted piece; null if none |
| `isHintedPiecePlaced` | `bool get` | True when `_hintedPieceIndex != null` and `_pieces[_hintedPieceIndex!].isPlaced` |
| `markNextSlotAvailable()` | `void` | Transitions first `waiting` slot to `available`; no-op if none; calls `notifyListeners()` |
| `activateHint()` | `void` | Guards: first slot must be `available`; marks it `used`; picks random unplaced piece; sets `_hintedPieceIndex`; calls `notifyListeners()` |

### Removed getters

| Removed | Notes |
|---------|-------|
| `int get hintsRemaining` | Replaced by `currentHintSlot` |

### endDrag() change

When a piece snaps (placed correctly): existing logic already sets `isHinted = false`. No change
needed here; `GameScreen` checks `isHintedPiecePlaced` after `endDrag()` returns.

---

## Modified: GameScreen (_GameScreenState)

**File**: `lib/screens/game_screen.dart`

### New widget parameter

```
HintSettings hintSettings  // injected from main.dart
```

### New state fields

| Field | Type | Purpose |
|-------|------|---------|
| `_hintTimer` | `Timer?` | Active countdown timer; null when not running |
| `_timerStartTime` | `DateTime?` | Wall-clock time when current timer was started |
| `_timerRemainingMs` | `int` | Milliseconds remaining when backgrounded |

### Lifecycle additions

- `mixin WidgetsBindingObserver` added to `_GameScreenState`
- `didChangeAppLifecycleState()`:
  - `paused` / `inactive` → cancel `_hintTimer`, compute and store `_timerRemainingMs`
  - `resumed` → restart timer with `_timerRemainingMs` (if > 0 and a `waiting` slot exists)

### Timer management rules

| Event | Timer action |
|-------|-------------|
| Game transitions to `playing` | Start timer (full `unlockDelaySeconds`) if NOT immediate mode |
| Any piece-placement attempt (endDrag fires) | Cancel + restart timer at full delay, IF a `waiting` slot exists |
| Hinted piece placed correctly | Cancel existing timer; start timer at full delay for next slot (if one exists) |
| Hinted piece still unplaced + idle timeout | Same as "any placement attempt" — fallback: start next slot's timer anyway |
| Timer fires | Call `gs.markNextSlotAvailable()`; setState |
| `immediateMode == true` | Never start timer; all slots pre-set to `available` by GameState |
| Puzzle won / disposed | Cancel timer |

---

## Modified: GameBoardView

**File**: `lib/screens/game_board_view.dart`

### Parameter change

| Old | New |
|-----|-----|
| `VoidCallback? onHint` | `HintSlotState? currentHintSlot` |

`onHint` callback removed. `GameScreen` provides `currentHintSlot` and a separate `onHint` is
replaced by direct `GameState.activateHint()` call inside the button's `onPressed`.

Wait — to keep the view stateless and not couple it to `GameState`, the `onHint` callback is kept
but the enabled/visible state is now driven by `currentHintSlot`:

| Parameter | Type | Notes |
|-----------|------|-------|
| `currentHintSlot` | `HintSlotState?` | New — replaces count-based rendering |
| `onHint` | `VoidCallback` | Changed: no longer nullable; always provided; button's `enabled` parameter gates interaction |

### Rendering logic

```
if currentHintSlot == null → hide hint button entirely
if currentHintSlot == waiting → show, enabled: false, opacity: 0.5
if currentHintSlot == available → show, enabled: true, opacity: 1.0
```

---

## SharedPreferences Key Registry (full, post-feature)

| Key | Type | Owner | Default |
|-----|------|-------|---------|
| `difficulty_easy` | int | DifficultySettings | 3 |
| `difficulty_medium` | int | DifficultySettings | 4 |
| `difficulty_hard` | int | DifficultySettings | 5 |
| `locale` | String | LocaleNotifier | 'pl' |
| `hint_immediate_mode` | bool | HintSettings | false |
| `hint_unlock_delay_seconds` | int | HintSettings | 10 |
