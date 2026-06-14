# Research: Hint Feedback Effects

## Summary of Findings

All technical questions resolved by reading the live codebase. No external research required.

---

## Decision 1: Where to Trigger the Hint-Available Sound and Animation

**Decision**: Trigger inside `GameScreen._startHintTimer` callback, immediately after calling `_gameState!.markNextSlotAvailable()`.

**Rationale**: This is the single code point where the `waiting → available` transition occurs in timed mode. Placing the trigger here keeps cause and effect together and avoids adding observer callbacks to `GameState`. In `immediateMode` this code path is never entered (the callback is never scheduled), satisfying FR-005 automatically.

**Alternatives considered**:
- Override `markNextSlotAvailable()` to emit a notification — rejected because it couples sound/animation logic to the model layer, violating SRP.
- Add a `ValueNotifier<bool>` in `GameState` to signal the transition — rejected as over-engineering; the existing call site in `_startHintTimer` is the only place the transition is initiated.

---

## Decision 2: Animation Type for Hint Button — Available Feedback

**Decision**: `TweenSequence<double>` on a `ScaleTransition` wrapping the hint button — scales 1.0 → 1.25 → 0.9 → 1.05 → 1.0 over ~500 ms. Driven by a dedicated `AnimationController _hintAvailableController` in `GameScreen`.

**Rationale**: The springy "pop" is immediately recognisable as a positive event (the same pattern used by most mobile game UIs when an item becomes available). It does not require a new package and fits cleanly into the existing AnimationController pattern already used by `_scatterController`, `_returnController`, `_confettiController`, and `_hintController`.

**Alternatives considered**:
- `ShakeTransition` (horizontal oscillation) — conveys "error" more than "ready", rejected for child UX reasons.
- `FadeTransition` (opacity 0 → 1) — already implied by the opacity change from 0.5 to 1.0; adding a fade on top is redundant.
- `AnimatedContainer` with a color flash — harder to test and produces more widget rebuilds than a `ScaleTransition`.

---

## Decision 3: Animation Type for Hint Area Exit — All Hints Exhausted

**Decision**: Combined `ScaleTransition` (1.0 → 0.0) + `FadeTransition` (1.0 → 0.0) on the hint area widget, driven by a dedicated `AnimationController _hintsExhaustedController` in `GameScreen`, with duration 400 ms. After the animation completes, the widget is removed from the tree by setting a `_hintsExhaustedDone` flag in `setState`.

**Rationale**: Scale-out + fade is the standard "close/pop" idiom in mobile UIs and reads unambiguously as "this item is gone". The 400 ms duration satisfies SC-004 (≤ 600 ms). The two-stage approach (animate, then remove) avoids a layout jump while keeping the tree clean after completion.

**Alternatives considered**:
- `SlideTransition` (slide up off-screen) — requires knowing the widget height, adds complexity; not materially better for children.
- `AnimatedSize` collapsing to zero — introduces layout reflow on every frame; heavier than a transform.
- Setting `currentHintSlot = null` immediately to trigger conditional removal — what the current code does; produces an abrupt disappearance (the bug this feature fixes).

---

## Decision 4: How to Pass Animation State to `GameBoardView`

**Decision**: Add two new parameters to `GameBoardView`:
- `Animation<double>? hintAvailableAnimation` — drives the `ScaleTransition` on the hint button.
- `Animation<double>? hintsExhaustedAnimation` — drives the exit animation on the hint area.

Both are nullable; when null the corresponding animation is inactive (no wrapping widget overhead). `GameBoardView` remains stateless.

**Rationale**: Consistent with how `hintController` and `confettiController` are already passed in. Keeps all `AnimationController` ownership in `GameScreen` (the `TickerProviderStateMixin` owner) and rendering logic in `GameBoardView`.

**Alternatives considered**:
- Making `GameBoardView` stateful and owning the controllers — rejected; violates existing architecture where `GameBoardView` is purposely stateless.
- Using `InheritedWidget` or provider to pass animations down — massively over-engineered for two parameters in a direct parent-child pair.

---

## Decision 5: Detecting "Last Hint Used" in `onHint` Callback

**Decision**: In `GameScreen`, after calling `gs.activateHint()`, check `gs.currentHintSlot == null`. If true, all hints are exhausted; play the sound and start the exit animation.

**Rationale**: `GameState.activateHint()` is synchronous. After it returns, `currentHintSlot` immediately reflects the new state (null if all 3 slots are now `used`). This is a single-line check with no race conditions.

**Alternatives considered**:
- Counting used slots directly — less idiomatic; `currentHintSlot` already encapsulates this.
- Adding a `bool allHintsExhausted` getter to `GameState` — reasonable but unnecessary given the existing `currentHintSlot` accessor covers it.

---

## Decision 6: Sound Assets

**Decision**: Add two new WAV files:
- `assets/sounds/hint_available.wav` — short upward chime (~0.5 s), child-friendly and positive.
- `assets/sounds/hints_exhausted.wav` — short descending two-tone sound (~0.8 s), gently communicating "no more".

The `assets/sounds/` directory is already declared as a glob in `pubspec.yaml` (`- assets/sounds/`), so no `pubspec.yaml` change is needed — new files in that directory are picked up automatically.

**Rationale**: Consistent with existing asset organisation. The WAV format matches existing sounds. The glob declaration means zero config overhead.

**Alternatives considered**:
- MP3 format — smaller files but more decode latency on Android; WAV is used throughout, consistency wins.
- Reusing an existing sound — `playClick` or `playSnap` both exist but carry established meanings; adding new semantically distinct sounds is clearer.

---

## Decision 7: Immediate Mode Suppression

**Decision**: No code changes needed for Immediate mode suppression (FR-005). In `GameScreen._onScatterStatus`, when `immediateMode` is true, `_startHintTimer` is never called, so the hint-available animation/sound callback is never registered. The transition from `waiting → available` never happens in Immediate mode — hints start as `available` directly.

**Rationale**: The existing architecture already gates all timed-hint behaviour behind `!widget.hintSettings.immediateMode`. This feature inherits that gate for free.

---

## Decision 8: Exit Animation and `currentHintSlot` Interaction

**Decision**: Introduce a `bool _showingHintArea` flag in `GameScreen` (initially `true`). The hint area widget is shown when `_showingHintArea` is true. When the exit animation completes, `setState(() => _showingHintArea = false)`. `currentHintSlot` is passed as-is; `GameBoardView` renders the button based on `currentHintSlot` while `_showingHintArea` controls whether the whole area is visible at all.

**Rationale**: Decouples visibility (showing/hiding the area) from enabled state (waiting/available). The button can be in "used" state during the exit animation and still render correctly.

**Alternatives considered**:
- Delaying `currentHintSlot = null` until after animation — not possible since `currentHintSlot` is derived from `GameState`, not owned by the view.
- Using `AnimatedSwitcher` — adds unnecessary widget wrapping; `ScaleTransition` + `FadeTransition` on the existing widget is simpler.
