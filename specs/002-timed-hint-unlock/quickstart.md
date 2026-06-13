# Quickstart Validation Guide: Timed Hint Unlock

**Feature**: 002-timed-hint-unlock
**Date**: 2026-06-10

This guide describes how to validate the feature end-to-end once implemented. It is not a test
suite — unit and widget tests live in `test/`. Run these scenarios manually on a device or
emulator to confirm the golden paths and edge cases work as specified.

---

## Prerequisites

```bash
# Source the environment (or open a new terminal)
source ~/.bashrc

# Ensure the project builds cleanly
flutter test
flutter analyze
flutter build apk --debug
```

Connect or launch the Android emulator (`Pixel_Tablet_API_35` on Windows host — see memory notes).

---

## Scenario 1: Timed unlock — default 10-second delay

**Setup**: Fresh install or after clearing app data. Immediate mode must be OFF (default).

1. Launch the app → select any puzzle → choose any difficulty → game screen appears.
2. Do NOT place any piece for 10 seconds.
3. **Expected**: The hint button becomes active (full opacity, tappable).
4. Tap the hint button.
5. **Expected**: One piece is highlighted on the board; the hint button disappears.
6. Do NOT place any piece for 10 seconds.
7. **Expected**: The hint button reappears as inactive (grayed out) — timer running for hint 2.

> Wait — per spec FR-008a, hint 2's timer only starts after the hinted piece is correctly placed.
> In step 6, the hint button should NOT re-appear yet because the hinted piece has not been placed.

**Revised step 6**: Drag and snap the highlighted piece to its correct board position.
**Expected after placement**: Hint button reappears as inactive (hint 2 timer starts counting).
After 10 more seconds of no placement: Hint button becomes active again.

---

## Scenario 2: All 3 hints used → button hidden

1. Use Scenario 1's flow to use all 3 hints (each time placing the hinted piece, then waiting 10 s, then using the next hint).
2. **Expected**: After the third hint is used, the hint button area is completely absent from the screen.

---

## Scenario 3: Placement attempt resets the timer

1. Game screen → hint 1 is inactive (timer counting).
2. Drag any piece to a wrong position and release it (piece flies back to tray).
3. **Expected**: The timer resets — wait another 10 seconds and the hint activates.

---

## Scenario 4: Immediate mode — hints always active

1. Open Settings (solve the math gate) → go to the Hints section.
2. Check the "Immediate" checkbox → save / navigate back.
3. Start a new puzzle.
4. **Expected**: All hint slots start as active from the very first second.
5. Tap the hint button three times (placing the hinted piece each time for hints 2 and 3) — wait, in immediate mode all 3 are pre-available.
   Actually: in immediate mode, tapping hint activates one hint. The next hint's button should still be active immediately without any timer.
6. **Expected**: After each hint use and correct placement, the next hint button is immediately active (no waiting period).

---

## Scenario 5: Custom delay via settings

1. Open Settings → Hints section → Immediate checkbox unchecked → change delay to `30` → save.
2. Start a new puzzle.
3. Do NOT place any piece for 29 seconds.
4. **Expected**: Hint button is still inactive.
5. Wait 1 more second (30 s total).
6. **Expected**: Hint button becomes active.

---

## Scenario 6: Settings validation — invalid delay input

1. Open Settings → Hints section → clear the delay input → try to save or navigate away.
2. **Expected**: Input shows an error message; delay reverts to the last valid value (or 10 if never set).
3. Enter `0` → same result as above.
4. Enter `abc` → same result (numeric-only keyboard should prevent this, but paste may allow it).

---

## Scenario 7: Immediate checkbox disables input field

1. Open Settings → Hints section → Immediate checkbox is unchecked.
2. **Expected**: Delay input field is editable.
3. Check the Immediate checkbox.
4. **Expected**: Delay input field is visually disabled and not tappable.
5. Uncheck the Immediate checkbox.
6. **Expected**: Delay input field is editable again, showing the last saved value.

---

## Scenario 8: App backgrounded during countdown

1. Game screen → hint button is inactive (timer counting), delay set to 30 s.
2. After 5 seconds, background the app (home button).
3. Wait 30 seconds in the background.
4. Foreground the app.
5. **Expected**: Hint button is still inactive; only ~25 seconds remain on the timer.
6. Wait 25 seconds without placing a piece.
7. **Expected**: Hint button becomes active.

---

## Scenario 9: Settings persist across restart

1. Open Settings → set delay to `45` and Immediate mode OFF → leave settings.
2. Force-stop the app and relaunch.
3. Open Settings → Hints section.
4. **Expected**: Delay shows `45`, Immediate checkbox is unchecked.

---

## Scenario 10: Mid-session settings change does not affect current session

1. Start a puzzle → note that delay is 10 s (default).
2. Open Settings (leave the puzzle and come back, or open from within if a back button exists on the game screen — if not possible mid-session, skip to step 4).
3. Change delay to `60` → return to the puzzle.
4. **Expected**: The current session still uses the 10 s delay.
5. Start a new puzzle.
6. **Expected**: New session uses the 60 s delay.

---

## Reference

- Data model: [data-model.md](./data-model.md)
- Spec: [spec.md](./spec.md)
- Unit tests: `test/unit/services/hint_settings_service_test.dart`, `test/unit/models/game_state_test.dart`
- Widget tests: `test/widget/settings_screen_test.dart`, `test/widget/game_screen_test.dart`
