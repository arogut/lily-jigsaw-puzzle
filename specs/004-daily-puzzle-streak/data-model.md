# Data Model: Daily Puzzle Streak

**Feature**: 004-daily-puzzle-streak | **Date**: 2026-06-27

---

## StreakRecord (immutable value object)

**File**: `lib/models/streak_record.dart`

**Purpose**: Carries the complete streak state as a single, immutable snapshot. All fields are final. No business logic lives here — pure data.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `currentStreak` | `int` | ≥ 0 | Number of consecutive calendar days on which at least one puzzle was completed, ending on `lastCompletionDate`. Zero only before the user has ever completed a puzzle. |
| `longestStreak` | `int` | ≥ `currentStreak` | All-time highest value of `currentStreak`. Never decremented. |
| `lastCompletionDate` | `String?` | `YYYY-MM-DD` or `null` | ISO 8601 date of the most recent puzzle completion in the device local time zone. `null` when the user has never completed a puzzle. |

**Validation invariants** (enforced by constructor assert):
- `currentStreak >= 0`
- `longestStreak >= 0`
- `longestStreak >= currentStreak`

**Key methods**:
- `StreakRecord.initial()` — factory returning `StreakRecord(currentStreak: 0, longestStreak: 0, lastCompletionDate: null)`, i.e. the state before any puzzle is ever completed
- `copyWith({int? currentStreak, int? longestStreak, String? lastCompletionDate})` — returns a new record with overridden fields

---

## StreakService

**File**: `lib/services/streak_service.dart`

**Purpose**: Sole owner of streak persistence and transition logic. Reads/writes three `SharedPreferences` keys. Follows the exact same structural pattern as `CompletionService`.

### SharedPreferences keys (private constants)

| Constant | Key string | Type |
|----------|------------|------|
| `_kCurrentKey` | `'streak_current'` | `int` |
| `_kLongestKey` | `'streak_longest'` | `int` |
| `_kLastDateKey` | `'streak_last_date'` | `String` |

### Constructor

```
StreakService({ DateTime Function()? clock })
```

`clock` defaults to `() => DateTime.now()`. Injected in tests to control the current date without any mocking framework.

### Public API

```
Future<StreakRecord> getStreak() async
```
Reads all three keys from `SharedPreferences` and returns the current `StreakRecord`. Returns `StreakRecord.initial()` if no keys exist yet.

```
Future<StreakRecord> recordPuzzleCompletion() async
```
Computes the new `StreakRecord` by applying streak transition logic (see below) against `clock()`, persists all three keys, and returns the updated record.

```
Future<void> resetAll() async
```
Removes all three keys. Used by the settings "Reset Progress" flow and tests.

### Streak transition logic (pure, inside `recordPuzzleCompletion`)

```
today = toDateString(clock())          // YYYY-MM-DD
existing = await getStreak()

if existing.lastCompletionDate == null:
  next = StreakRecord(currentStreak: 1,
                     longestStreak: max(1, existing.longestStreak),
                     lastCompletionDate: today)

elif existing.lastCompletionDate == today:
  next = existing (no change, idempotent)

elif existing.lastCompletionDate == yesterday(today):
  newCurrent = existing.currentStreak + 1
  next = StreakRecord(currentStreak: newCurrent,
                     longestStreak: max(newCurrent, existing.longestStreak),
                     lastCompletionDate: today)

else:  // gap of 2+ days
  next = StreakRecord(currentStreak: 1,
                     longestStreak: existing.longestStreak,
                     lastCompletionDate: today)

persist(next)
return next
```

**Helper**: `String _toDateString(DateTime dt)` formats as `'${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}'`.

**Helper**: `String _yesterday(String isoDate)` subtracts one day using `DateTime.parse(isoDate).subtract(const Duration(days: 1))` and re-formats.

---

## Modified: WinOverlay

**File**: `lib/widgets/win_overlay.dart`

**Change**: Add `final StreakRecord? streakRecord;` as an optional named constructor parameter (defaults to `null`). When non-null and `streakRecord.currentStreak > 0`, render a streak section between the subtitle text and the action buttons. Existing constructor callers that omit `streakRecord` continue to work unchanged.

**Streak section layout** (when streak is shown):
- Fire emoji + current streak count + localised "Day Streak" label — prominent, child-friendly
- Localised "Best:" label + longest streak count — smaller, secondary

**New localisation keys** (added to all four ARB files):

| Key | EN value | Notes |
|-----|----------|-------|
| `streakDays` | `"🔥 {count} Day Streak"` | `count` placeholder (int) |
| `streakBest` | `"Best: {count} days"` | `count` placeholder (int) |

---

## Modified: GameScreen

**File**: `lib/screens/game_screen.dart`

**Change**: Add `StreakRecord? _streakRecord` field. In `_recordCompletion()`, call `StreakService().recordPuzzleCompletion()` and store the result in `_streakRecord` (via `setState`). Pass `_streakRecord` to the `WinOverlay` constructor.

No change to `GameState`, `CompletionService`, or any other existing file.

---

## State Transitions Diagram

```
[Never played]
  lastCompletionDate = null, currentStreak = 0

  → complete puzzle on Day 1
  lastCompletionDate = "2026-06-27", currentStreak = 1, longestStreak = 1

  → complete puzzle again on Day 1 (same day)
  ← no change (idempotent)

  → complete puzzle on Day 2 (consecutive)
  lastCompletionDate = "2026-06-28", currentStreak = 2, longestStreak = 2

  → skip Day 3, complete puzzle on Day 4 (gap)
  lastCompletionDate = "2026-06-30", currentStreak = 1, longestStreak = 2
```
