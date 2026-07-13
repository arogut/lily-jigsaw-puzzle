# Data Model: Win Celebration Variety

**Phase**: 1 | **Date**: 2026-07-13 (updated for two-phase flow)

---

## Entities

### CelebrationStyleId

**Type**: `enum` | **Location**: `lib/models/celebration_style.dart`

| Value | Description | In rotation? |
|---|---|---|
| `confetti` | Paper shapes raining down | Yes |
| `balloons` | Balloons floating upward | Yes |
| `fireworks` | Radial bursts | Yes |
| `milestone` | Elaborate combined effect; streak feature only | No |

---

### CelebrationPhase

**Type**: `enum` | **Location**: `lib/models/celebration_style.dart`

| Value | UI visible | Audio | Transitions |
|---|---|---|---|
| `animating` | `CelebrationLayer` full screen | Fanfare looping | → `overlay` on animation complete or tap skip |
| `overlay` | `WinOverlay` (fixed 🎉 design) | Fanfare looping | → dismissed on backdrop / Play Again / New Puzzle |
| *(none)* | Completed puzzle board | Stopped | After dismiss |

`GameScreen` owns the current phase. Animation and overlay **never** overlap.

---

### CelebrationIntensity

**Type**: immutable value object | **Location**: `lib/models/celebration_style.dart`

| Field | Type | Description |
|---|---|---|
| `level` | `int` | `1 … maxIntensityLevel` |
| `particleCount` | `int` | Linear lerp from `baseParticleCount` to `maxParticleCount` |
| `animationDuration` | `Duration` | Linear lerp from `baseAnimationDuration` to `maxAnimationDuration` |

**Factory**: `CelebrationIntensity.fromStreakWeeks(int completedStreakWeeks)`

Does **not** include fanfare duration — fanfare is per-style fixed clip, looped until stop.

---

### DailyCompletionState

| Field | Type | Description |
|---|---|---|
| `date` | `String` | ISO local date `YYYY-MM-DD` |
| `count` | `int` | Completions on `date` |

**Keys**: `celebration_daily_date`, `celebration_daily_count`

---

## Services

### DailyCompletionTracker

| Method | Description |
|---|---|
| `consumeNext(DateTime date)` | Return current count, increment, persist; reset on new day |
| `peek(DateTime date)` | Read count without increment |
| `reset()` | Clear keys (progress reset + tests) |

### CelebrationSelector

| Method | Description |
|---|---|
| `styleFor(date, dailyCount)` | `standardStyles[(dayOffset(date) + dailyCount) % 3]` |
| `dayOffset(date)` | Days since epoch mod 3 |

---

## Constants (`CelebrationConstants`)

| Constant | Value |
|---|---|
| `maxIntensityLevel` | `5` |
| `baseParticleCount` | `80` |
| `maxParticleCount` | `250` |
| `baseAnimationDuration` | `5 s` |
| `maxAnimationDuration` | `12 s` |
| `dailyDateKey` / `dailyCountKey` | persistence keys |
| `offsetEpoch` | `DateTime(2024)` |

---

## Modified Entities

### SoundService

| Method | Description |
|---|---|
| `playWinFanfare(CelebrationStyleId style)` | Loop style asset until `stopWinFanfare()` |
| `stopWinFanfare()` | Stop player immediately |

No duration parameter. Intensity does not affect fanfare.

### WinOverlay

| Parameter | Description |
|---|---|
| `onDismiss` | Backdrop tap → end celebration |
| `onPlayAgain` / `onNewPuzzle` | End celebration + action |

**Removed**: `celebrationStyle` theming parameter. Fixed 🎉 / pastel design for all styles.

### CelebrationLayer

| Parameter | Description |
|---|---|
| `style` | Particle painter dispatch |
| `intensity` | `particleCount` + `animationDuration` |
| `onSkip` | Full-screen tap during animation phase |
| `onAnimationComplete` | Natural end of animation controller |

Does not depend on `SoundService` (sound is `GameScreen` responsibility).

---

## Data Flow

```
Puzzle win → GameScreen._onWin()
  ├── record completion / streak
  ├── dailyCount = DailyCompletionTracker.consumeNext(today)
  ├── style = CelebrationSelector.styleFor(today, dailyCount)
  ├── intensity = CelebrationIntensity.fromStreakWeeks(weeks)
  ├── phase = animating
  ├── SoundService.playWinFanfare(style)
  └── CelebrationLayer(style, intensity)

Animation complete OR onSkip
  ├── phase = overlay
  ├── remove CelebrationLayer
  └── show WinOverlay (fixed design); fanfare continues

Backdrop dismiss / Play Again / New Puzzle
  ├── SoundService.stopWinFanfare()
  ├── phase = dismissed, hide overlay
  └── if backdrop only: puzzle board + Back button
```
