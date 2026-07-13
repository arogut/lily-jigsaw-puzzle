# Research: Win Celebration Variety

**Phase**: 0 | **Date**: 2026-07-13 (updated for two-phase flow clarifications)

---

## Decision 1: Fanfare Looping Until Celebration Ends

**Question**: How should fanfare audio behave across animation and overlay phases?

**Decision**: Start fanfare at animation phase begin with `ReleaseMode.loop`. Continue
looping until `stopWinFanfare()` — called when the celebration ends (backdrop dismiss,
**Play Again**, or **New Puzzle**). No intensity-based duration timer.

The looped clip length is fixed per style (the `.wav` file duration). If the animation
phase outlasts one clip cycle, the asset keeps looping (FR-014, clarification Q5-B).

**Approach**:
```
playWinFanfare(style):
  player.setReleaseMode(ReleaseMode.loop)
  player.play(AssetSource(style.audioAsset))

stopWinFanfare():
  cancel any timer (if present)
  player.stop()
```

**Rationale**: Matches clarified spec — fanfare does not scale with intensity; total
play time is bounded only by how long the player keeps the celebration open.

**Alternatives considered**:
- `Future.delayed` stop at intensity-scaled duration: superseded (intensity no longer
  scales fanfare length).
- Stop fanfare when animation ends: rejected (clarification Q1 — fanfare continues
  through overlay).

---

## Decision 2: Day Offset Calculation

**Question**: Deterministic `dayOffset` from calendar date?

**Decision**: Days since fixed epoch `DateTime(2024)` modulo 3:

```dart
int dayOffset(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return local.difference(CelebrationConstants.offsetEpoch).inDays % 3;
}
```

**Rationale**: Pure, no I/O, superseded weekly-shuffle approach.

---

## Decision 3: Intensity Constants (Animation Only)

**Question**: Concrete values for intensity scaling?

**Decision**:

```dart
static const int maxIntensityLevel = 5;
static const int baseParticleCount = 80;
static const int maxParticleCount  = 250;
static const Duration baseAnimationDuration = Duration(seconds: 5);
static const Duration maxAnimationDuration  = Duration(seconds: 12);
```

`CelebrationIntensity.fromStreakWeeks(weeks)` derives `level`, `particleCount`, and
`animationDuration` via linear interpolation. **No `fanfareDuration` field.**

Fanfare clip length is per-style (asset file); not derived from intensity.

**Rationale**: Clarification Q3-D — only animation scales; fanfare clip is fixed.

**Alternatives considered**:
- Scaling fanfare duration with intensity: superseded by 2026-07-13 clarifications.

---

## Decision 4: Within-Day Style Formula

**Decision**: `styleId = standardStyles[(dayOffset(date) + dailyCount) % 3]`

Persisted via `DailyCompletionTracker`. Guarantees SC-001–SC-003.

(Unchanged from prior research; see prior examples in git history.)

---

## Decision 5: Two-Phase Win Flow

**Question**: When do animation and overlay appear?

**Decision**: **Sequential, never simultaneous.**

```
Puzzle won
  → phase = animating
      CelebrationLayer visible (full screen, tap to skip)
      playWinFanfare(style) starts
  → animation completes OR tap skip
      phase = overlay
      CelebrationLayer removed
      WinOverlay shown (fixed 🎉 design)
      fanfare continues looping
  → backdrop dismiss OR Play Again OR New Puzzle
      phase = dismissed
      stopWinFanfare()
      overlay hidden
      if backdrop dismiss: puzzle board visible, Back only
```

`GameScreen` holds `CelebrationPhase? _celebrationPhase` (or equivalent flags).

**Rationale**: FR-005a/b/c; separates style variety (animation) from stable win card.

**Alternatives considered**:
- Simultaneous layer + overlay (prior implementation): rejected by spec update 2026-07-13.

---

## Decision 6: Win Overlay Fixed Design

**Question**: Should overlay theme to active style?

**Decision**: **No.** Restore pre-variety `WinOverlay`: party-popper 🎉, pastel pink
accent, no `celebrationStyle` parameter for theming. Remove style-specific emoji/colours
added in initial implementation.

**Rationale**: FR-005c; variety lives in animation phase only.

---

## Decision 7: Post-Dismiss Navigation

**Question**: What after backdrop dismiss?

**Decision**: Completed puzzle board visible. **Play Again** / **New Puzzle** hidden
(not on screen). Player exits via existing **Back** button.

**Rationale**: Clarification Q4-D. Win actions remain on overlay card while it is visible.
