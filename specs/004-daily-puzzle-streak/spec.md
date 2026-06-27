# Feature Specification: Daily Puzzle Streak

**Feature Branch**: `004-daily-puzzle-streak`

**Created**: 2026-06-27

**Status**: Draft

**Input**: User description: "New feature that will be counting streak of how many days in a row user was resolving puzzles. This should not be about just starting the app, but solving at least one jigsaw puzzle."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Streak Increments on Puzzle Completion (Priority: P1)

A user who completes a puzzle on a new calendar day sees their streak counter go up by one. The streak only grows through finishing a puzzle — merely opening the app has no effect.

**Why this priority**: This is the core mechanic. Without it the feature does not exist. All other stories build on correct streak counting.

**Independent Test**: Can be fully tested by completing a puzzle after simulating consecutive days and verifying the counter increments correctly; delivers the fundamental "daily habit" value to the user.

**Acceptance Scenarios**:

1. **Given** the user has a streak of 3 and completed their last puzzle yesterday, **When** they finish any puzzle today, **Then** the streak becomes 4.
2. **Given** the user has never completed a puzzle, **When** they finish their first puzzle, **Then** a new streak of 1 begins.
3. **Given** the user already completed a puzzle today (streak = 5), **When** they finish another puzzle today, **Then** the streak remains 5 (same-day completion does not double-count).
4. **Given** the user is on a streak of 2, **When** they finish a puzzle on the same day as their last completion, **Then** the last-completion date is updated but the streak count is unchanged.

---

### User Story 2 - Streak Resets After a Missed Day (Priority: P2)

A user who skips a day without completing any puzzle has their streak reset to 1 the next time they finish a puzzle.

**Why this priority**: Without correct reset behaviour the streak counter is meaningless. This story defines the "consequence" half of the habit loop and is essential to the feature's integrity.

**Independent Test**: Can be fully tested by simulating a two-day gap between puzzle completions and verifying the streak resets to 1.

**Acceptance Scenarios**:

1. **Given** the user has a streak of 7 and last completed a puzzle two days ago, **When** they finish a puzzle today, **Then** the streak resets to 1.
2. **Given** the user has a streak of 1 and last completed a puzzle three days ago, **When** they finish a puzzle today, **Then** the streak becomes 1 (no change, already at minimum).
3. **Given** the user has never completed a puzzle, **When** they open the app without finishing a puzzle, **Then** no streak is shown (or streak remains 0).

---

### User Story 3 - Streak Display on Win Screen (Priority: P3)

After completing a puzzle, the user can see their updated current streak displayed on the win overlay so they get immediate positive feedback.

**Why this priority**: Immediate feedback on the win screen closes the habit loop and is the primary motivational touchpoint. It is independently deployable once streak tracking is in place.

**Independent Test**: Can be tested by completing a puzzle and verifying the win overlay shows the correct streak value matching the stored record.

**Acceptance Scenarios**:

1. **Given** the user finishes a puzzle and the streak is now 5, **When** the win overlay appears, **Then** it shows "5 day streak" (or equivalent child-friendly label).
2. **Given** the user finishes a puzzle and the streak has just reset to 1, **When** the win overlay appears, **Then** it shows "1 day streak".
3. **Given** the user finishes a puzzle and today already counted toward the streak, **When** the win overlay appears, **Then** the unchanged streak count is shown correctly.

---

### User Story 4 - Longest Streak Record (Priority: P4)

The system tracks the user's all-time longest streak and displays it alongside the current streak, so the user has a personal best to chase.

**Why this priority**: Adds motivational depth without changing any core mechanic. It is a simple extension once current streak tracking is correct.

**Independent Test**: Can be tested by simulating a long streak followed by a reset and verifying the longest-streak record is preserved.

**Acceptance Scenarios**:

1. **Given** the user's current streak is 10 and longest ever was 8, **When** the win overlay is shown, **Then** the longest streak is updated to 10 and displayed.
2. **Given** the user's streak resets to 1, **When** the win overlay is shown, **Then** the longest streak value is unchanged (still the previous best).
3. **Given** the user has never had a streak longer than their current one, **When** they keep extending their current streak, **Then** the longest streak always mirrors the current streak.

---

### Edge Cases

- What happens when the user changes the device date/time manually? The feature relies on the device calendar day; no additional validation is performed (out of scope).
- What happens if persistent storage is cleared (app data reset)? Streak resets to 0 — no recovery mechanism.
- What happens when a puzzle is completed at exactly midnight? The completion date is determined by the calendar day at the moment the puzzle is won; whichever day the device clock reports at that moment is used.
- What happens if the same puzzle is completed multiple times in one session? Each completion event is checked; only the first completion of a new calendar day advances the streak.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST record the calendar date each time a puzzle is completed (the "won" state is reached).
- **FR-002**: The system MUST increment the current streak by 1 when a puzzle is completed on a calendar day immediately following the day of the previous completion.
- **FR-003**: The system MUST keep the current streak unchanged when a puzzle is completed on the same calendar day as the most recent completion.
- **FR-004**: The system MUST reset the current streak to 1 when a puzzle is completed after one or more calendar days have been skipped since the last completion.
- **FR-005**: The system MUST persist the current streak, the longest streak, and the last-completion date across app sessions (i.e., data survives the app being closed and reopened).
- **FR-006**: The system MUST update the longest streak whenever the current streak exceeds the previously stored longest streak.
- **FR-007**: The system MUST display the current streak count to the user on the win overlay immediately after a puzzle is completed.
- **FR-008**: The system MUST display the longest streak to the user on the win overlay.
- **FR-009**: Streak tracking MUST be global across all puzzle images and all difficulty levels — any completed puzzle counts.

### Key Entities

- **StreakRecord**: Represents the user's streak state. Holds the current streak count (integer ≥ 0), the longest streak ever achieved (integer ≥ 0), and the date of the most recent puzzle completion (nullable date). Immutable; updated via pure transformation.
- **StreakService** (boundary): Encapsulates the rules for reading and updating a StreakRecord given the current date and a completion event. Depends on an abstract persistence interface.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After any puzzle completion, the displayed streak count is always accurate — it matches the number of consecutive calendar days (ending today) on which at least one puzzle was completed.
- **SC-002**: Streak data is fully preserved when the app is closed and reopened; the streak shown after reopening is identical to the one shown at the end of the previous session.
- **SC-003**: Completing multiple puzzles on the same day never inflates the streak beyond 1 increment for that day; this invariant holds in 100% of cases.
- **SC-004**: After a missed day, the first puzzle completion resets the streak to exactly 1; no partially-preserved streak values are shown.
- **SC-005**: The longest streak record is always ≥ the current streak and is never decremented by a streak reset.
- **SC-006**: The streak information is visible to the user within the natural game completion flow, without requiring any additional navigation.

## Assumptions

- **Streak scope**: All puzzle images and difficulty levels count equally toward the streak — there is no per-difficulty or per-image streak.
- **Calendar day definition**: A "day" is defined by the local device calendar date (midnight-to-midnight in the device time zone). No server-side clock is used.
- **No notifications**: Out-of-scope for this feature — no push notifications or reminders to maintain the streak.
- **No cloud sync**: Streak data is stored locally on the device only. Cross-device sync is out of scope.
- **Single user**: The app has no user account system; all streak data belongs to whichever person uses the device.
- **Data loss on clear**: If the user clears app data or reinstalls, the streak is lost. No backup or recovery mechanism is provided.
- **Display location**: Streak is shown on the win overlay (post-puzzle completion screen). Whether it also appears elsewhere (e.g., image selection screen) is deferred to planning.
- **Child-friendly presentation**: The streak display must follow the constitution's children-first UI design principle — large text, bright colours, celebratory feel — consistent with existing win overlay design.
