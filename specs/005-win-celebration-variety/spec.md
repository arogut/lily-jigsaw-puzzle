# Feature Specification: Win Celebration Variety

**Feature Branch**: `005-win-celebration-variety`

**Created**: 2026-07-12

**Status**: Draft

**Input**: User description: "Win celebration variety. Every win plays the same confetting + sound + overlay. For a game meant to be played daily, rotating between few celebration styles (confetti colors/shapes, balloons, fireworks, different fanfares) would keep completions feeling fresh."

## Clarifications

### Session 2026-07-12

- Q: Should a streak milestone trigger a special celebration style distinct from the normal daily rotation, or are streak and celebration features fully independent? → A: Streak milestones trigger a special 4th celebration style; this feature reserves and defines it, but triggering is owned by the streak feature (004).
- Q: Should the existing confetti animation become style #1 (reused and extended), or should all 3 standard styles be built from scratch? → A: All 3 standard styles are implemented from scratch under the new CelebrationStyle abstraction; the confetti style must visually match the existing celebration's look and feel.
- Q: How should the daily rotation algorithm work — round-robin, hash-based, or shuffled sequence? → A: Shuffled sequence: a randomised order of all standard styles is generated per week and stored; all styles appear before any repeats within that week.
- Q: Does the codebase already have audio playback utilities, or does this feature need to build them from scratch? → A: Existing audio utilities are already in place; this feature only requires new audio asset files for each fanfare variant.
- Additional scope (user-provided): Celebration intensity (animation duration and particle density) scales with streak length — incremented once per completed week of streak, capped at a predefined maximum so no celebration ever exceeds a fixed upper bound on duration.

### Session 2026-07-12 (continued)

- Q: When the animation finishes, does the overlay auto-dismiss or require a player tap? → A: Tap-to-dismiss on the **win overlay only** — the overlay stays on screen until the player taps; it never auto-closes. The animation phase is skippable with a tap (see Session 2026-07-13 continued).
- Q: How should the fanfare be extended at higher intensity levels — separate long/short asset files, or one file extended programmatically? → A: One audio file per style; looped for a **fixed** duration per style — fanfare length does **not** scale with intensity (see Session 2026-07-13 continued, animation-vs-fanfare question).
- Q: Who computes the intensity level from streak data — the caller, or the celebration system? → A: The caller passes `completedStreakWeeks`; the celebration system internally maps weeks → intensity level and clamps to the maximum.
- Q: Does the milestone celebration style participate in intensity scaling or always play at a fixed intensity? → A: The milestone style scales with streak length exactly like standard styles — a longer streak produces a grander milestone celebration.

### Session 2026-07-13

- Additional scope (user-provided): Style rotation must also vary within a single day. Completing multiple puzzles in one session should cycle through different styles, not repeat the same one. The mechanism is a single sequence that is cycled indefinitely; each day starts at a deterministically different position in that sequence, and each successive completion within the day advances to the next position.
- Q: How should the weekly rotation algorithm work — round-robin, hash-based, or shuffled sequence? → A: **Superseded** by within-day cycling (see above): `styleId = standardStyles[(dayOffset(date) + dailyCount) % 3]` with persisted `dailyCount`.

### Session 2026-07-13 (continued)

- Q: When does the win overlay ("splash") appear relative to the celebration animation? → A: **Two-phase flow**: the celebration animation plays first (full-screen particles + fanfare). The win overlay appears only after the animation finishes naturally **or** the player taps to skip the animation. The animation and overlay are never shown simultaneously.
- Q: What happens when the player taps during the animation phase? → A: Tap skips the animation immediately and transitions to the win overlay. This is separate from overlay dismissal — tapping the overlay backdrop still dismisses the overlay per FR-006.
- Q: Should the win overlay visually match the active celebration style? → A: **No.** The win overlay uses a **fixed, uniform design** for every celebration style (the original win card with the party-popper emoji 🎉 — not style-themed emoji, colours, or imagery). Style variety is expressed only in the animation phase, not on the overlay card.
- Q: When the animation phase ends (naturally or skipped), what happens to the fanfare? → A: Fanfare **continues through the overlay phase** until the player dismisses the overlay (backdrop tap) or taps **Play Again** / **New Puzzle**.
- Q: After the player dismisses the win overlay by tapping the backdrop, what should they see? → A: The **completed puzzle board** with overlay and celebration fully gone. *(Button access after dismiss clarified below.)*
- Q: How should animation phase length relate to fanfare length at higher intensity levels? → A: **Fanfare duration is fixed** (does not scale with streak/intensity); **only animation length** (and particle density) scales with intensity.
- Q: After the overlay is dismissed, where should **Play Again** / **New Puzzle** live? → A: **No persistent win buttons** after dismiss — player uses the existing **Back** button to leave; **Play Again** / **New Puzzle** are available only while the overlay card is visible.
- Q: If the fixed fanfare ends before the celebration ends (long animation or overlay still open), what happens? → A: Fanfare **loops** until the celebration ends; the fixed duration is the looped clip length, not a hard cap on total play time.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Varied Celebration on Every Completion (Priority: P1)

Every puzzle completion — whether the player's first today or their fifth — shows a celebration that feels different from the one just before it. The system cycles through celebration styles using a single endless sequence; each calendar day starts at a deterministically different position in that sequence, and each successive completion within a session advances to the next position. Playing across multiple days and multiple sessions per day means rarely seeing the same style twice in a row.

**Why this priority**: This is the core request. Variety must be felt both across days and within a single play session.

**Independent Test**: Can be fully tested by completing 3 puzzles in one session and confirming all 3 completions show different celebration styles.

**Acceptance Scenarios**:

1. **Given** a player completes their first puzzle today, **When** the celebration plays, **Then** the style is determined by today's date (deterministic) and is potentially different from yesterday's first completion.
2. **Given** a player completes a second puzzle in the same session, **When** the celebration plays, **Then** it uses the next style in the sequence — different from the first completion in that session.
3. **Given** a player completes 3 puzzles in one session, **When** reviewing all 3 celebrations, **Then** all 3 standard styles have appeared (the sequence advances through all 3 before repeating).
4. **Given** the player restarts the app mid-day and completes another puzzle, **When** the celebration plays, **Then** the style continues from where the day's sequence left off — the within-day position is persisted.

---

### User Story 2 - Visually and Audibly Distinct Styles (Priority: P2)

Each celebration style is immediately recognisable as different from the others during the **animation phase**. A player who sees "balloons" knows they haven't seen "fireworks" yet today. Sound matches the visual: a fanfare that fits balloons sounds different from a dramatic fireworks boom. After the animation, a **fixed win overlay** (same look for every style) presents the congratulatory message and action buttons.

**Why this priority**: Variety only works if the styles are perceptibly different. Without this, rotation exists but isn't felt. Separating animation variety from a stable overlay keeps the win moment familiar while the lead-in stays fresh.

**Independent Test**: Can be tested by forcing each style in isolation and confirming a child tester names the animation differently from every other style without prompting; then confirming the win overlay looks identical regardless of which style played.

**Acceptance Scenarios**:

1. **Given** style A (confetti) plays, **When** a child observes the animation phase, **Then** they see coloured paper-like shapes raining down and hear an upbeat fanfare.
2. **Given** style B (balloons) plays, **When** a child observes the animation phase, **Then** they see balloon-shaped particles floating upward and hear a cheerful pop-and-bounce sound.
3. **Given** style C (fireworks) plays, **When** a child observes the animation phase, **Then** they see burst-shaped explosions of colour and hear a dramatic bang-and-sparkle fanfare.
4. **Given** any style's animation has finished or been skipped, **When** the win overlay appears, **Then** it covers the completed puzzle with the fixed win card design (party-popper 🎉, original pastel palette) — **not** themed to the active celebration style.
5. **Given** the animation phase is playing, **When** the player taps anywhere on screen, **Then** the animation stops immediately and the win overlay appears.
6. **Given** the animation phase is playing, **When** the animation runs to its natural end, **Then** the win overlay appears without requiring a tap.
7. **Given** the player dismisses the overlay backdrop, **When** the celebration ends, **Then** the completed puzzle is visible with no overlay card; **Play Again** / **New Puzzle** are not shown — the player may leave via **Back**.

---

### User Story 3 - Streak Milestone Celebration (Priority: P2)

When a player reaches a meaningful streak milestone (e.g., 7-day or 30-day streak), a special celebration plays that is visually more impressive than any daily rotation style — making milestone moments feel earned and memorable. The celebration style is defined in this feature; the streak feature (004) is responsible for detecting the milestone and triggering it.

**Why this priority**: Milestone moments are the highest-engagement touchpoints in a daily game. Defining the style here keeps the celebration system as the single source of all style definitions, while the streak feature stays focused on streak logic.

**Independent Test**: Can be tested by directly invoking the milestone celebration style in isolation and confirming it is visually distinct from all 3 standard styles.

**Acceptance Scenarios**:

1. **Given** the milestone celebration style is invoked with a low streak value, **When** a child observes the screen, **Then** the visual effect is clearly more elaborate than the standard daily styles at the same intensity level.
2. **Given** the milestone style is invoked with a high streak value, **When** the animation phase plays, **Then** the animation is noticeably grander than the same milestone style at a lower streak value.
3. **Given** device sound is muted, **When** the milestone style plays, **Then** the visual effect still conveys a sense of special occasion without audio.

---

### User Story 4 - Streak-Scaled Celebration Intensity (Priority: P2)

The longer a player's active streak, the more elaborate the **animation** feels. A player on their first week sees a standard-length animation; a player who has maintained a 4-week streak sees noticeably more particles and a longer animation sequence. Fanfare length stays the same at every intensity level. The animation grows week by week but stops escalating once it reaches a predefined maximum.

**Why this priority**: This directly rewards habit and makes long-streak players feel seen. It ties into the same daily engagement loop as the style variety.

**Independent Test**: Can be tested by invoking the celebration with mock streak values (week 1, week 2, week N≥max) and confirming intensity increases between weeks 1 and 2, and stays constant from max week onward.

**Acceptance Scenarios**:

1. **Given** a player has a streak of less than 1 completed week, **When** the celebration animation plays, **Then** the animation runs at the baseline (minimum) intensity level.
2. **Given** a player's streak crosses each additional completed week, **When** the celebration plays, **Then** the intensity is one level higher than the previous week's — more particles and a longer animation; fanfare length stays the same.
3. **Given** a player's streak reaches or exceeds the maximum intensity level, **When** the celebration plays, **Then** intensity stays at the cap — it does not keep growing indefinitely.
4. **Given** a player's streak resets to zero, **When** the next celebration plays, **Then** intensity returns to baseline.

---

### User Story 5 - Graceful Degradation When Sound Is Off (Priority: P3)

A player with device sound muted or app sound disabled still gets the full visual celebration. The fanfare variation is reflected visually (e.g., particle density, colour intensity) so the experience is not flat.

**Why this priority**: Accessibility and silent-mode use are common on tablets used by children in shared spaces.

**Independent Test**: Can be tested by disabling sound and completing a puzzle — visual style remains distinctive and identifiable.

**Acceptance Scenarios**:

1. **Given** device sound is muted, **When** puzzle completion triggers a celebration, **Then** the full visual effect plays without any errors or empty states.
2. **Given** two different styles play with sound off, **When** a child observes both in sequence, **Then** the visual experience of each is clearly distinct without needing the audio.

---

### Edge Cases

- What happens when only one celebration style is defined? The single style plays every time — no rotation, no crash.
- What happens if the puzzle date/ID cannot be determined at celebration time? Fall back to a default style (e.g., style index 0); log a warning internally.
- What if a new style is added mid-release? The cycle length changes (modulo increases), which shifts future style assignments. This is acceptable; only a deliberate breaking change requires migration.
- What if the player taps to skip the animation before it finishes? The animation and its particles stop immediately; the win overlay appears; fanfare **continues** into the overlay phase until the celebration ends.
- What if the player taps the win overlay backdrop to dismiss? All remaining audio stops; the overlay closes; the completed puzzle board is visible; only **Back** is available to leave (no **Play Again** / **New Puzzle** until the next win overlay).
- What if the player taps **Play Again** or **New Puzzle**? Fanfare stops immediately; the chosen action proceeds.
- What if the animation phase outlasts one fanfare loop cycle? The fanfare asset continues looping until the celebration ends; animation and overlay proceed without forcing audio to stop.
- What if the player taps to skip the animation and then immediately taps the overlay backdrop? Both transitions complete cleanly with no stacked overlays or duplicate audio.
- What if the streak feature (004) is not yet implemented? The milestone style and intensity scaling are defined and testable in isolation using a mock streak value; absence of a live streak trigger does not block this feature's delivery.
- What if the streak length is unavailable at celebration time? Fall back to baseline intensity (level 1) — no crash, no empty state.
- What if the persisted daily tracker is missing or corrupted (e.g., first launch)? Treat as day 0, count 0 — generates a valid style with no crash; no recovery needed beyond default values.
- What if the device clock is wrong or changes mid-day? The date used at the moment the puzzle is won is the one recorded; subsequent resets or advances do not retroactively alter completed celebrations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define exactly 4 celebration styles: 3 standard styles used in the daily rotation and 1 milestone style reserved for streak milestone events.
- **FR-002**: Style selection MUST use a single cyclic sequence of the 3 standard styles indexed by a per-completion position counter: `styleId = standardStyles[(dayOffset + dailyCount) % 3]`, where `dayOffset` is a deterministic integer derived from the calendar date and `dailyCount` is the number of completions already recorded today.
- **FR-003**: `dayOffset` MUST be derived solely from the calendar date (e.g., days elapsed since a fixed epoch, modulo 3), ensuring each calendar day starts at a potentially different position in the cycle and that consecutive days very rarely produce the same starting style.
- **FR-003a**: The `dailyCount` and the date it belongs to MUST be persisted on-device; `dailyCount` resets to 0 at the start of each new calendar day, ensuring the within-day sequence position survives app restarts.
- **FR-004**: Each celebration style MUST include a distinct particle effect (type, shape, and colour palette) played during the **animation phase** over the completed puzzle board (full-screen layer behind any UI chrome, but before the win overlay).
- **FR-005**: Each celebration style MUST include a distinct fanfare sound that starts when the **animation phase** begins, loops its audio asset, and continues through the **overlay phase** until the celebration ends (overlay dismissed or action button tapped). Total fanfare play time is NOT capped by intensity; the asset loops as needed.
- **FR-005a**: The win flow MUST have two sequential phases: (1) **animation phase** — full-screen celebration animation with fanfare; (2) **overlay phase** — fixed win overlay card with congratulatory message and action buttons. The phases MUST NOT overlap.
- **FR-005b**: The animation phase MUST end when either (a) the animation reaches its natural completion (duration derived from intensity), or (b) the player taps anywhere to skip. In both cases, the overlay phase MUST begin immediately after.
- **FR-005c**: The win overlay MUST use a **fixed visual design** shared by all celebration styles (the original win card with party-popper 🎉 emoji and established pastel palette). It MUST NOT change emoji, accent colour, or card styling based on the active `CelebrationStyleId`.
- **FR-006**: The win overlay MUST be dismissible by the player tapping anywhere on its backdrop; it MUST NOT auto-dismiss — it stays on screen until the player taps the backdrop, presses **Play Again**, or presses **New Puzzle**.
- **FR-006a**: When the overlay backdrop is dismissed, the overlay card and celebration MUST fully close; the completed puzzle board MUST remain visible. **Play Again** and **New Puzzle** are NOT shown after dismiss — the player exits via the existing **Back** button.
- **FR-007**: When the celebration ends — overlay backdrop tapped, or **Play Again** / **New Puzzle** pressed — all animations and audio associated with that celebration MUST stop immediately and cleanly.
- **FR-008**: If device or app sound is disabled, the visual celebration MUST still play in full with no errors.
- **FR-009**: Adding a new celebration style in a future release MUST NOT alter the style assigned to past dates.
- **FR-010**: The milestone celebration style MUST be exposed as a named, addressable style so the streak feature (004) can invoke it directly by identifier without coupling to the daily rotation logic.
- **FR-011**: The milestone celebration style MUST NOT appear in the daily rotation — it is exclusively triggered by the streak feature.
- **FR-012**: Every celebration — including the milestone style — MUST accept `completedStreakWeeks` as an input; the celebration system MUST internally derive the intensity level (baseline = 0 completed weeks → level 1; each additional completed week increments the level by 1, clamped to the predefined maximum).
- **FR-013**: A predefined maximum intensity level MUST be defined; celebrations MUST NOT exceed it regardless of streak length.
- **FR-014**: At higher intensity levels, the celebration MUST display a proportionally greater number of particles and run a proportionally longer **animation phase** than at baseline. Fanfare MUST use one looped audio asset per style at a **fixed clip duration** (no per-intensity fanfare length); the clip loops until the celebration ends, even if the animation phase outlasts one loop cycle.
- **FR-015**: When a player's streak resets, the celebration intensity MUST return to the baseline level on the next completion.

### Key Entities

- **CelebrationStyle**: Represents one complete celebration experience — a named identifier, a particle configuration (shape, colours, behaviour), an audio identifier, and a flag indicating whether it belongs to the daily rotation or is milestone-only. All styles, including the milestone style, support intensity scaling. Style identity is expressed in the animation phase only.
- **CelebrationIntensity**: An integer level (1 to a predefined maximum) representing how elaborate the celebration animation should be; computed internally by the celebration system from `completedStreakWeeks` (level = clamp(completedStreakWeeks + 1, 1, max)). Callers supply streak weeks, not the level directly. Controls **animation duration** and particle count only; fanfare duration is fixed separately.
- **CelebrationPhase**: The active stage of a win celebration — `animating` (particles + fanfare, skippable) or `overlay` (fixed win card visible, fanfare still playing). Transitions: `animating` → `overlay` on animation complete or skip (fanfare continues); celebration ends on backdrop tap or action button press (fanfare stops).
- **CelebrationSelector**: Pure-function logic that derives a `CelebrationStyleId` from a calendar date and a within-day completion count: `standardStyles[(dayOffset(date) + dailyCount) % 3]`. No I/O, no state.
- **DailyCompletionTracker**: Persisted state containing the last-recorded date (ISO string) and the number of completions recorded on that date (`dailyCount`). On access: if the stored date differs from today, `dailyCount` resets to 0. On each completion: returns the current `dailyCount` then increments and persists it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Completing 3 puzzles in a single session always produces 3 distinct celebration styles (all 3 standard styles appear once before any repeats within that session).
- **SC-002**: All 3 standard celebration styles are encountered within any 3-consecutive-completion window — guaranteed by the cyclic sequence length of 3.
- **SC-003**: The N-th completion on a given calendar date always produces the same style, regardless of how many app restarts occur that day — 100% stable per (date, completionCount) pair.
- **SC-004**: Children aged 4–8 in usability observation can identify at least 2 celebration styles as "different" without prompting, within a 5-minute session.
- **SC-005**: Skipping the animation phase (tap) transitions to the win overlay in no longer than 200 ms, with no lingering particles from the animation layer.
- **SC-005a**: Win overlay dismissal takes no longer than 200 ms from tap to fully stopped state (no lingering particles or audio).
- **SC-006**: The maximum-intensity **animation** (at the cap) lasts no longer than a predefined upper bound duration; players can skip it at any time with a tap to reach the overlay sooner. Fanfare clip length does not scale with intensity (looping covers longer celebrations).
- **SC-007**: A player who increases their streak by one week observes a perceptible difference in **animation length** or particle density compared to the previous week's intensity level.

## Assumptions

- The existing celebration trigger point (puzzle completion event) will not change; this feature replaces only the content and sequencing of the celebration, not when it fires.
- The win overlay ("splash") is the existing `WinOverlay` card — congratulatory message, streak display, and action buttons. It is **not** the app launch splash screen (`SplashScreen`).
- The win overlay reverts to its pre-variety fixed design (party-popper 🎉, original pastel accent colours) for all celebration styles; per-style theming applies only to the animation phase.
- Calendar date (device local time zone, `YYYY-MM-DD`) is the stable identifier for day-boundary detection; `dayOffset` is computed from the number of days since a fixed epoch (e.g. 2024-01-01), modulo the number of standard styles.
- The system does not restrict how many puzzles a player can complete in one day; all completions in a day contribute to advancing the within-day counter.
- The initial release defines exactly 4 celebration styles: confetti, balloons, fireworks (standard rotation), and a milestone style (streak-triggered). The design allows additional styles to be added later without structural changes.
- The codebase already contains audio playback utilities; this feature reuses them and only requires new audio asset files (one fanfare per celebration style, including the milestone style).
- The maximum intensity level and the corresponding maximum celebration duration are defined as named constants; their exact values are a design/UX decision to be confirmed during planning.
- Intensity scales with completed streak weeks (not days); a player on day 6 of week 1 is still at intensity level 1.
- Each celebration style requires exactly one fanfare audio file, looped until the celebration ends. The clip length is fixed per style and does not scale with intensity; looping covers celebrations where the animation phase is longer than one clip cycle.
- Particle effects are implemented using Flutter's animation primitives (no third-party particle engine required for 3 simple styles).
- All 3 standard celebration styles are implemented from scratch under the `CelebrationStyle` abstraction; the existing confetti implementation is replaced, not reused as code.
- The confetti style MUST visually match the appearance of the current celebration (same particle shapes, motion, and colour mood) so existing players do not notice a regression.
- Visual designs for each style will be reviewed against mockups in `assets/design/` before implementation is considered done (per constitution Principle I).
