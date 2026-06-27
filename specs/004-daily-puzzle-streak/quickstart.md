# Quickstart Validation Guide: Daily Puzzle Streak

**Feature**: 004-daily-puzzle-streak | **Date**: 2026-06-27

This guide describes how to validate the feature works end-to-end, both via automated tests and manual verification on a device/emulator.

---

## Prerequisites

- Flutter 3.41.3 available (`/home/arogut/development/flutter/bin/flutter`)
- `ANDROID_HOME=/home/arogut/Android/Sdk`
- Feature branch `004-daily-puzzle-streak` checked out
- All source files from [data-model.md](data-model.md) implemented

---

## Automated Test Validation

### 1. Run the full test suite

```bash
/home/arogut/development/flutter/bin/flutter test
```

**Expected**: zero failures, ≥ 85% line coverage

### 2. Key test files to verify exist and pass

| Test file | What it covers |
|-----------|----------------|
| `test/unit/models/streak_record_test.dart` | `StreakRecord` immutability, `copyWith`, `initial()`, invariant asserts |
| `test/unit/services/streak_service_test.dart` | All four streak transition paths (first ever, same-day, consecutive, gap); `getStreak()` on empty prefs; `resetAll()`; clock injection |
| `test/unit/widgets/win_overlay_test.dart` | Overlay renders correctly without streakRecord; renders streak section when streakRecord provided; hides streak section when currentStreak == 0 |

### 3. Static analysis

```bash
/home/arogut/development/flutter/bin/flutter analyze
```

**Expected**: zero issues, zero warnings

### 4. Debug APK build

```bash
/home/arogut/development/flutter/bin/flutter build apk --debug
```

**Expected**: clean compilation, no errors

---

## Manual Validation Scenarios

Connect to the Windows-hosted emulator (Pixel_Tablet_API_35) via ADB as described in the project memory before running these scenarios.

### Scenario A — First puzzle completion starts streak at 1

1. Fresh install (or clear app data in Android Settings)
2. Complete any puzzle on any difficulty
3. **Verify**: Win overlay shows "🔥 1 Day Streak" and "Best: 1 days"

### Scenario B — Same-day completion does not inflate streak

1. Complete a second puzzle on the same day (do not change device date)
2. **Verify**: Win overlay still shows "🔥 1 Day Streak" (unchanged)

### Scenario C — Consecutive day increments streak

1. Advance the device date by exactly one day (Developer Options → System clock, or `adb shell date`)
2. Complete any puzzle
3. **Verify**: Win overlay shows "🔥 2 Day Streak"

### Scenario D — Missed day resets streak to 1

1. Advance the device date by two or more days
2. Complete any puzzle
3. **Verify**: Win overlay shows "🔥 1 Day Streak"; "Best:" retains the previous highest value

### Scenario E — Longest streak is preserved after reset

1. Build a streak of 3 across three consecutive days
2. Skip one day and complete a puzzle (streak resets to 1)
3. **Verify**: Win overlay shows "Best: 3 days"

### Scenario F — Streak persists across app restarts

1. Complete a puzzle (streak becomes N)
2. Force-stop the app and reopen it
3. Complete another puzzle on the same day
4. **Verify**: Win overlay still shows streak = N (not reset)

### Scenario G — Reset Progress clears streak

1. Complete a puzzle to establish a streak
2. Navigate to Settings → Reset Progress → confirm
3. Complete a new puzzle
4. **Verify**: Win overlay shows "🔥 1 Day Streak" (streak restarted from zero)

---

## Acceptance Criteria Cross-reference

| Scenario | Spec acceptance scenario covered |
|----------|----------------------------------|
| A | US1-AC2, US3-AC1 |
| B | US1-AC3, US1-AC4 |
| C | US1-AC1 |
| D | US2-AC1 |
| E | US4-AC2 |
| F | SC-002 |
| G | SC-004 |
