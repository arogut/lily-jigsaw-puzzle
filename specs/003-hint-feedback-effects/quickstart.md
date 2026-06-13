# Quickstart Validation Guide: Hint Feedback Effects

## Prerequisites

- Feature branch checked out and all changes implemented
- Physical Android device or AVD connected (Windows host for emulator per project setup)
- `flutter test` passes with zero failures
- `flutter analyze` passes with zero warnings

## Build & Run

```bash
flutter run
```

Or for a debug APK on device:

```bash
flutter build apk --debug && adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## Validation Scenario 1 — Hint Available Sound + Animation (Timed Mode)

**Setup:**
1. Open the app → Settings → set hint delay to **5 seconds** → uncheck "Immediate" → save.
2. Start a new puzzle (any image, any difficulty).

**Steps:**
1. Wait for the scatter animation to finish.
2. Do **not** drag any piece — wait 5 seconds idle.

**Expected:**
- At the 5-second mark, a short upward chime plays.
- The hint button visibly "pops" — briefly scales up then springs back to normal size.
- The button becomes fully opaque (was 50% opaque while waiting).

**Pass criteria:**
- Sound plays ✓
- Pop animation visible (scale up → spring back) ✓
- Button is now tappable ✓

---

## Validation Scenario 2 — Hint Available Animation Does NOT Play in Immediate Mode

**Setup:**
1. Settings → check "Immediate" → save.
2. Start a new puzzle.

**Steps:**
1. Observe the game screen immediately after scatter animation.

**Expected:**
- All hint buttons appear fully active (full opacity) with **no** chime sound and **no** pop animation.

**Pass criteria:**
- No sound at game start ✓
- No pop animation at game start ✓
- Buttons are immediately tappable ✓

---

## Validation Scenario 3 — All Hints Exhausted Sound + Exit Animation

**Setup:**
- Use Immediate mode so all 3 hints are available immediately (quicker to exhaust).

**Steps:**
1. Start a puzzle in Immediate mode.
2. Tap the hint button → place the highlighted piece → wait for hint 2 to appear (or skip if immediate).
3. Repeat until you have used all 3 hints (tap hint button 3 times, placing the hinted piece each time to unlock the next).

   _Shortcut_: In Immediate mode all 3 hints are active at game start; tap hint, place hinted piece, tap hint again, place hinted piece, tap hint a third time.

4. On the **third tap** (the last hint):

**Expected:**
- A distinct, gentle "no more hints" sound plays immediately after the third tap.
- The hint button area begins an animated exit — simultaneously shrinking and fading.
- Within ~400 ms the hint area is completely gone — no blank space, no invisible widget, no residual tap area.

**Pass criteria:**
- Distinct sound plays (different from the hint-available chime) ✓
- Animated exit visible (scale + fade out) ✓
- Hint area fully removed from layout after animation ✓
- Tapping where the button was registers no interaction ✓

---

## Validation Scenario 4 — Device Muted / Silent

**Steps:**
1. Mute the device (volume to 0 or silent mode).
2. Repeat Scenario 1 (timed mode, wait for hint to unlock).
3. Repeat Scenario 3 (use all 3 hints).

**Expected:**
- No sounds play (correct — device is muted).
- Pop animation still plays when hint unlocks ✓
- Exit animation still plays when all hints are exhausted ✓

---

## Validation Scenario 5 — Puzzle Restart Resets Animation State

**Steps:**
1. Use all 3 hints (exit animation plays, hint area removed).
2. Tap "Play Again" from the win screen, or press Back and start a new puzzle.

**Expected:**
- The hint area re-appears on the new puzzle session.
- In timed mode: hint button shows as waiting (50% opacity) until timer expires.
- In Immediate mode: hint button shows as active immediately.

**Pass criteria:**
- `_showingHintArea` reset — hint area visible again ✓
- No stale animation state from previous session ✓

---

## Automated Test Coverage

Run the full suite to confirm coverage gates:

```bash
flutter test --coverage
# Check lcov.info: coverage must be ≥ 85% overall

flutter test test/unit/services/sound_service_test.dart
flutter test test/widget/screens/game_board_view_test.dart
flutter test test/widget/game_screen_loaded_test.dart
```

Key test cases to verify exist:
- `SoundService.playHintAvailable()` returns a `Future` (mirrors existing pattern)
- `SoundService.playHintsExhausted()` returns a `Future`
- `GameBoardView` renders hint button with `ScaleTransition` when `hintAvailableAnimation` provided
- `GameBoardView` renders exit animation widgets when `hintsExhaustedAnimation` provided
- `GameBoardView` removes hint area from tree when `showHintArea` is `false`
