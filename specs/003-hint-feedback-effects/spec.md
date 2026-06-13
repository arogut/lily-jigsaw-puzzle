# Feature Specification: Hint Feedback Effects

**Feature Branch**: `003-hint-feedback-effects`

**Created**: 2026-06-13

**Status**: Draft

**Input**: User description: "Make sure to display some visual effect when hint becomes available with a sound. Also, when last hint is used make sure to play sound that will inform player that all hints are exhausted, add some visual effect of hint button disappearing."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Child Notices a Hint Has Become Available (Priority: P1)

A child is playing the puzzle and has been struggling for a while. Behind the scenes, the idle timer (from the timed hint unlock feature) expires and a hint becomes available. The child is alerted to this by a short, cheerful sound and a noticeable visual effect on the hint button — drawing their attention to the fact that help is now available without requiring them to check the button constantly.

**Why this priority**: The timed hint unlock system is only useful if the child knows a hint is ready. Without feedback, children may not notice the button has become active and continue struggling unnecessarily. This story delivers the core value of the broader hint system.

**Independent Test**: Can be fully tested by starting a puzzle in timed mode, waiting for the idle period to expire, and confirming that a sound plays and a visual effect appears on the hint button at the moment it transitions from inactive to active.

**Acceptance Scenarios**:

1. **Given** a puzzle is in progress and a hint's idle timer has been counting, **When** the timer expires and the hint transitions to available, **Then** a short sound plays immediately and a visual effect plays on the hint button.
2. **Given** the hint-available effect is playing, **When** the child taps the hint button during or after the effect, **Then** the button responds normally — the effect does not block interaction.
3. **Given** a puzzle is started in Immediate mode (all hints available from the start), **When** the game screen appears, **Then** no sound or visual effect plays — the effects are suppressed because no timed unlock occurred.
4. **Given** hint 1 is used and the hinted piece is placed, **When** hint 2's timer subsequently expires, **Then** the sound and visual effect play on hint 2's button, not hint 1's.
5. **Given** the hint-available sound is playing, **When** another game sound is triggered at the same time, **Then** both sounds play without either being suppressed (or the hint-available sound takes priority based on existing sound mixing rules).

---

### User Story 2 — Child Is Informed When All Hints Are Exhausted (Priority: P2)

A child uses the third and final hint. Since no further hints will ever become available in this puzzle session, the game plays a distinct sound to clearly communicate "no more hints" and the hint button area gracefully animates out of view rather than abruptly disappearing.

**Why this priority**: An abrupt disappearance of the hint area can be confusing. A sound and smooth exit animation give the child clear, age-appropriate feedback that the hint system is fully consumed — preventing repeated tapping on where the button used to be.

**Independent Test**: Can be fully tested by using all three hints in a single puzzle session and confirming that on the third use a distinct sound plays and the hint area animates out of view over a short duration before being fully removed.

**Acceptance Scenarios**:

1. **Given** the player has used hints 1 and 2 and hint 3 is active, **When** the player taps hint 3, **Then** a distinct "all hints exhausted" sound plays immediately.
2. **Given** the last hint has just been tapped, **When** the all-hints-exhausted sound plays, **Then** the hint button area begins a visible exit animation.
3. **Given** the exit animation is in progress, **When** the animation completes, **Then** the hint button area is fully removed from the layout (no leftover space or invisible elements).
4. **Given** the exit animation is in progress, **When** the child taps where the hint area was, **Then** no interaction is registered — the area is non-interactive during and after the animation.
5. **Given** all hints are exhausted and the animation has completed, **When** the child views the game screen, **Then** the hint button area is absent from the screen with no visual artifact.

---

### Edge Cases

- What if the child places a piece successfully at the exact moment the hint-available sound begins playing? Both events should proceed normally — piece placement and the hint sound are independent.
- What if the device is muted or silent? The visual effect must still play; audio feedback is supplementary, not the sole signal.
- What if the app is backgrounded while the hint-available visual effect is playing? The effect should stop and not replay when the app returns to the foreground; the hint simply remains in its available state.
- What if the app is backgrounded while the all-hints-exhausted exit animation is playing? On return to the foreground the hint area should already be in its final hidden state — no partial animation should resume.
- What happens if the puzzle is restarted mid-session? All hint states reset; the exit animation and sounds do not replay from the previous session.
- What if hints 1 and 2 are used but hint 3 is still waiting (timer not yet expired)? The "all hints exhausted" feedback must NOT play until hint 3 is also used — the state that triggers it is all three hints being in the `used` state.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a hint transitions from `waiting` to `available`, the system MUST play a short, distinct sound to notify the player.
- **FR-002**: When a hint transitions from `waiting` to `available`, the hint button MUST display a brief visual effect (such as a glow, pulse, or bounce) to draw the player's attention.
- **FR-003**: The hint-available sound and visual effect MUST play within 200 ms of the hint state transition.
- **FR-004**: The hint-available visual effect MUST NOT block or delay interaction with the hint button — the button MUST remain tappable during the animation.
- **FR-005**: In Immediate mode (all hints active from game start), the hint-available sound and visual effect MUST NOT play at the beginning of a puzzle session.
- **FR-006**: When the player uses the last remaining hint (all three hints are now in the `used` state), the system MUST play a distinct sound that is audibly different from the hint-available sound.
- **FR-007**: The all-hints-exhausted sound MUST play within 200 ms of the last hint being tapped.
- **FR-008**: After the last hint is used, the hint button area MUST exit the screen via a visible animation rather than disappearing instantly.
- **FR-009**: The exit animation for the hint area MUST complete within 600 ms of starting.
- **FR-010**: During and after the exit animation, the hint button area MUST be non-interactive.
- **FR-011**: After the exit animation completes, the hint button area MUST be fully removed from the layout — no placeholder space, invisible widget, or visual artifact MUST remain.
- **FR-012**: If audio playback fails (e.g., device is muted or audio system unavailable), the visual effects MUST still play — audio failure MUST NOT prevent visual feedback.
- **FR-013**: Both new sounds (hint-available and all-hints-exhausted) MUST be child-appropriate in character — short, positive, and non-alarming in tone.

### Key Entities

- **HintSlot** (extended from 002-timed-hint-unlock): The existing hint slot entity. This feature adds observable state-transition events that trigger feedback; no new data fields are required.
- **HintFeedback**: A conceptual grouping of the two feedback events — `hintAvailable` (sound + visual effect on button) and `allHintsExhausted` (sound + exit animation on hint area). Not a stored entity; represents runtime behaviour triggered by HintSlot state changes.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The hint-available sound and visual effect play on 100% of hint state transitions from `waiting` to `available` during a timed-mode session, with no missed transitions.
- **SC-002**: In Immediate mode, the hint-available sound plays 0 times when the game screen first appears.
- **SC-003**: The all-hints-exhausted sound plays on 100% of occasions when the third hint is consumed, with no false triggers when only hints 1 or 2 are used.
- **SC-004**: The hint area exit animation completes within 600 ms of the last hint being tapped, measured on a mid-range Android device.
- **SC-005**: After the exit animation completes, 0 interactive elements from the hint area remain present on the game screen.
- **SC-006**: Children aged 4–8 can correctly identify that a hint is available after the visual and audio cue, without requiring any instruction — measured informally through parent observation.

---

## Assumptions

- The 002-timed-hint-unlock feature is fully implemented and merged; this feature extends its behaviour without altering core hint-slot state logic.
- The game already has an audio playback system capable of playing short sound effects; this feature adds two new sound assets but does not require a new audio framework.
- Existing sound assets and the audio mixing behaviour are already defined; the new sounds will follow the same rules for volume and simultaneous playback.
- The visual effect for hint availability is applied to the individual hint button (not the entire screen); the exact animation style is defined during the design/planning phase.
- The exit animation for the hint area is a single unified animation covering the whole hint button area (not each button separately), consistent with the 002 spec which removes the entire area at once.
- In Immediate mode, since hints start as `available` (never pass through `waiting`), no hint-available feedback is ever triggered — this is the intended behaviour.
- There is no setting to disable the feedback effects; they are always active and are considered a non-optional part of the user experience.
- The two new sounds are bundled as app assets; no network fetch or external service is required for audio.
