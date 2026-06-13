# Feature Specification: Timed Hint Unlock

**Feature Branch**: `002-timed-hint-unlock`

**Created**: 2026-06-10

**Status**: Draft

---

## Clarifications

### Session 2026-06-10

- Q: When should the idle timer for hints 2 and 3 start counting? → A: Only after the piece highlighted by the previous hint has been correctly placed on the board. Tapping the hint button alone does not start the next timer.
- Q: What happens if the hinted piece is never correctly placed — is there a fallback mechanism? → A: No fallback. The next hint remains permanently locked until the highlighted piece is correctly placed. The child must place the hinted piece before any further hints become available.

---

**Input**: User description: "In our jigsaw puzzle game modify when the hints are available. Currently there are 3 hints available at any time when on main game screen. Hints should become available once gamer is stuck and not able to find a place for puzzle. This means there should be some defined period of time after which hint is available. This should be applied to each hint. Default value should be 10 seconds, but there should be an option in settings to modify this value via input field. Additionally 'immediate' checkbox should be available to keep same behaviour as currently. When immediate option is selected input fields should be inactive. Once hint is available but still waiting to be enabled button should be visible but inactive, when enabled - active, and once all hints are used button should be hidden."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Child Receives a Hint After Being Stuck (Priority: P1)

A child is playing the puzzle and cannot find where to place the current piece. After a short period of inactivity (no successful piece placement), the first hint button becomes active. The child taps it and receives visual guidance. If they are still stuck, another period of inactivity triggers the second hint, and so on. Once all three hints have been used, the hint area disappears.

**Why this priority**: This is the core behaviour change. It ensures hints reward genuine struggle rather than being immediately available as a shortcut, making the game more educational without being frustrating.

**Independent Test**: Can be fully tested by starting a puzzle, waiting for the configured idle period without placing any piece, and verifying that exactly one hint button becomes active. Use a hint, wait again, verify the next hint unlocks. Use all three and verify the hint area is no longer visible.

**Acceptance Scenarios**:

1. **Given** a puzzle is in progress and no piece has been placed for the configured idle period, **When** the timer expires, **Then** the first available hint button transitions from inactive to active.
2. **Given** a hint button is active, **When** the child taps it, **Then** the hinted piece is visually highlighted, the hint button becomes hidden, and the idle timer for the next hint does NOT start yet.
3. **Given** a hint has been used and the hinted piece has been correctly placed on the board, **When** the placement is registered, **Then** the idle timer for the next hint resets to zero and begins counting from that moment.
4. **Given** the idle timer has not yet expired, **When** the child views the hint button, **Then** the button is visible but non-interactive (greyed out or visually disabled).
5. **Given** a child successfully places a piece on the board, **When** the placement is registered, **Then** the idle timer resets and the next hint's countdown restarts from zero.
6. **Given** a child attempts to place a piece in a wrong position and the piece is rejected, **When** the piece returns to the tray, **Then** the idle timer resets as the child is still actively trying.
7. **Given** all three hints have been used, **When** the child views the game screen, **Then** no hint buttons are visible anywhere on the screen.
8. **Given** a hint button is inactive (timer still counting), **When** the child taps it, **Then** nothing happens — the tap is ignored.

---

### User Story 2 — Adult Configures Hint Unlock Behaviour (Priority: P2)

A parent opens the app settings and finds a "Hints" configuration section. They can type in a number of seconds to set how long the child must be idle before a hint unlocks. Alternatively, they tick an "Immediate" checkbox to restore the original behaviour where all hints are available at all times from the start of a puzzle.

**Why this priority**: The timeout value is a matter of parental preference — some parents want to encourage longer independent effort, others prefer less frustration for younger children. The "Immediate" option preserves backward compatibility for parents who prefer the original behaviour.

**Independent Test**: Can be fully tested by opening settings, entering a custom timeout value (e.g., 30 seconds), starting a puzzle, and verifying the hint button unlocks after 30 seconds of idle time rather than the default 10.

**Acceptance Scenarios**:

1. **Given** the settings screen is open, **When** the adult views the Hints section, **Then** they see a numeric input field labelled with the idle timeout duration and an "Immediate" checkbox.
2. **Given** the Immediate checkbox is unchecked, **When** the adult enters a positive integer in the timeout input, **Then** the value is saved and subsequent puzzle sessions use that timeout.
3. **Given** the adult checks the Immediate checkbox, **When** the checkbox state is saved, **Then** the timeout input field becomes visually disabled and non-interactive.
4. **Given** the Immediate checkbox is checked, **When** the child starts a puzzle, **Then** all three hint buttons are immediately active from the first moment the game screen is shown.
5. **Given** the adult unchecks the Immediate checkbox, **When** the change is saved, **Then** the timeout input field becomes editable again and the last-saved timeout value is shown.
6. **Given** the adult clears the timeout input and leaves it blank or enters zero, **When** the settings are saved, **Then** the value reverts to the default of 10 seconds and the input displays 10.
7. **Given** the adult enters a non-numeric value in the timeout input, **When** they attempt to save, **Then** the input shows a validation error and the previous valid value is retained.

---

### Edge Cases

- What happens if the app is backgrounded while the idle timer is counting? The timer should pause while the app is not in the foreground and resume when the app returns to the game screen.
- What happens if the child picks up a piece and holds it without placing it for the entire idle period? Simply holding a piece (without an attempted placement) should not reset the timer — only an actual placement attempt (successful or not) should do so.
- What happens to mid-game hint state if the adult changes the timeout value in settings during an active game session? The change takes effect from the next puzzle session; the current session retains the settings that were active when it started.
- What if the configured timeout value is very large (e.g., 3600 seconds)? The button remains inactive for the full duration; no upper limit is enforced, but the adult is responsible for sensible values.
- What happens if the player restarts the puzzle mid-game? All hint states reset (all three hints return to the "waiting" state) and all idle timers restart.
- What happens if the child uses hint 1 (piece highlighted) but never correctly places that piece? The idle timer for hint 2 never starts and the second hint remains permanently locked until the highlighted piece is correctly placed. There is no fallback mechanism — the only way to unlock the next hint is to correctly place the currently highlighted piece. This is intentional: the hint system rewards completing the guided step before moving on.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game screen MUST display hint buttons in one of three states: inactive (timer running), active (hint available), or hidden (hint used).
- **FR-002**: A hint button MUST start in the inactive state at the beginning of every puzzle session, unless the Immediate mode is enabled in settings.
- **FR-003**: In Immediate mode, all hint buttons MUST start in the active state at the beginning of every puzzle session (preserving current behaviour).
- **FR-004**: In timed mode, a hint button MUST transition from inactive to active after the configured idle period has elapsed with no piece-placement attempt by the player.
- **FR-005**: "Piece-placement attempt" MUST be defined as the player releasing a dragged piece — regardless of whether the placement was correct or rejected.
- **FR-006**: Any piece-placement attempt MUST reset the idle timer for the next available (inactive) hint back to zero. This applies only while the idle timer is actively counting; if the timer has not yet started (because the hinted piece from a previous hint has not yet been correctly placed, per FR-008 and FR-018), piece-placement events have no timer effect.
- **FR-007**: When a hint is used (button tapped while active), that hint button MUST become hidden immediately.
- **FR-008**: After a hint is used (button tapped), the idle timer for the next remaining inactive hint MUST NOT start until the piece highlighted by that hint has been correctly placed on the board.
- **FR-008a**: When the piece highlighted by hint N is correctly placed, the idle timer for hint N+1 MUST reset to zero and begin counting from that moment.
- **FR-009**: When all three hints have been used, the entire hint button area MUST be removed from view.
- **FR-010**: The idle timer MUST pause when the app is not in the foreground and resume when the app returns to the game screen.
- **FR-011**: The settings screen MUST include a Hints section with a numeric timeout input field and an "Immediate" checkbox.
- **FR-012**: The timeout input MUST accept positive integers only; blank or zero values MUST be rejected and the field MUST revert to the last valid value (defaulting to 10 if never set).
- **FR-013**: The default hint unlock timeout MUST be 10 seconds when no value has been saved (new installations or after a full app data clear). A progress reset MUST NOT affect saved hint configuration; hint settings persist independently per FR-016.
- **FR-014**: When the Immediate checkbox is checked, the timeout input field MUST be visually disabled and non-interactive.
- **FR-015**: When the Immediate checkbox is unchecked, the timeout input field MUST be editable.
- **FR-016**: The hint configuration (Immediate mode on/off, timeout value) MUST persist across app restarts.
- **FR-017**: Hint timeout settings MUST apply from the next puzzle session onwards; an in-progress session MUST NOT be affected by mid-game settings changes.
- **FR-018**: If the piece highlighted by hint N has not been correctly placed, the idle timer for hint N+1 MUST NOT start under any circumstances — there is no fallback timer or alternative unlock path. The only way to unlock hint N+1 is to correctly place the piece highlighted by hint N.

### Key Entities

- **HintSettings**: Persistent configuration for hint behaviour. Contains: `immediateMode` (boolean, default false), `unlockDelaySeconds` (positive integer, default 10).
- **HintSlot**: Represents one of the three available hints within a game session. Has a state: `waiting` (timer active), `available` (unlocked, ready to use), or `used` (consumed and hidden).
- **IdleTimer**: A countdown associated with the next `waiting` HintSlot in a game session. Resets to zero on any piece-placement attempt. Triggers a HintSlot state transition from `waiting` to `available` when it reaches the configured `unlockDelaySeconds`. Implemented as a timer field within the game session controller, not a standalone domain object.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In timed mode with the default 10-second setting, a hint button becomes active no earlier than 10 seconds and no later than 11 seconds after the last piece-placement attempt, measured on a mid-range Android device.
- **SC-002**: In Immediate mode, all three hint buttons are active within 1 second of the game screen being fully displayed.
- **SC-003**: Tapping an inactive hint button produces no visible change to game state — 0% false activations from tapping a disabled button.
- **SC-004**: After all three hints are used, 0 hint buttons remain visible on the game screen.
- **SC-005**: An adult can locate the Hints settings, change the timeout value, and save within 30 seconds of opening the settings screen.
- **SC-006**: A settings change (timeout or Immediate mode) persists correctly across 100% of app restarts — the game screen reflects the saved configuration on every subsequent launch.
- **SC-007**: Pausing and resuming the app (backgrounding and foregrounding) causes the idle timer to behave as if the backgrounded time did not pass — no hint unlocks unexpectedly due to background time.

---

## Assumptions

- The existing hint system delivers exactly 3 hints per puzzle session; this count is unchanged by this feature.
- A "piece-placement attempt" is triggered when the player's finger lifts from a dragged piece — the same event that currently determines whether a piece snaps to the board or returns to the tray.
- Simply picking up or holding a piece (without releasing it) does NOT count as a placement attempt and does NOT reset the idle timer.
- All three hint slots begin as `waiting` when a puzzle session starts (in timed mode). Only hint 1's idle timer is active at the start. Hint 2's timer starts only after the piece highlighted by hint 1 is correctly placed; hint 3's timer starts only after the piece highlighted by hint 2 is correctly placed — hints unlock sequentially, not simultaneously.
- The timeout input in settings accepts whole seconds only (no fractional values).
- There is no maximum enforced limit on the timeout value; the adult may enter any positive integer.
- The hint configuration applies globally to all puzzles and difficulty levels — there is no per-puzzle or per-difficulty hint setting.
- Visual and auditory feedback for the hint button state transition (inactive → active) is desirable but the exact design is left to the UI implementation phase.
