# Quickstart Validation Guide: Win Celebration Variety

**Phase**: 1 | **Date**: 2026-07-13

See [data-model.md](data-model.md) and [contracts/celebration-api.md](contracts/celebration-api.md).

---

## Prerequisites

- Flutter 3.41.3 at `~/development/flutter`; `source ~/.bashrc`
- Android device or emulator API 36
- `flutter pub get`

---

## Scenario 1 — Three Styles in One Session

**Validates**: FR-001–003, SC-001, SC-002

1. Clear app data. Complete 3 puzzles in one session.
2. Confirm 3 **animation** styles differ (confetti, balloons, fireworks each appear once).

---

## Scenario 2 — Daily Counter Persists

**Validates**: FR-003a, SC-003

1. Complete 2 puzzles; note animation styles.
2. Force-quit; complete 3rd puzzle — style continues sequence (not style #1 again).
3. 4th completion cycles back to first style of the day.

---

## Scenario 3 — Two-Phase Flow (Animation Then Overlay)

**Validates**: FR-005a/b, US2 scenarios 4–6

1. Win a puzzle. Confirm **only** particle animation shows first — **no** win card yet.
2. Wait for animation to finish. Confirm win overlay (🎉 fixed card) appears.
3. Win again; during animation, tap screen. Confirm animation stops and overlay appears immediately (≤ 200 ms).
4. Confirm animation and overlay were **never** visible at the same time.

---

## Scenario 4 — Fanfare Continues Through Overlay

**Validates**: FR-005, clarification fanfare behaviour

1. Win puzzle; let animation finish (or skip).
2. While overlay is visible, confirm fanfare still audible.
3. Tap backdrop dismiss. Confirm audio stops within 200 ms.

---

## Scenario 5 — Intensity Scales Animation Only

**Validates**: FR-012–014, SC-006, SC-007

1. Set `currentStreak` to 0 → level 1: shorter animation, fewer particles.
2. Set streak for level 5 → longer animation (≤ 12 s), more particles.
3. Confirm fanfare **clip** sounds the same length per loop at all levels (looping continues as needed).

---

## Scenario 6 — Overlay Dismiss and Back

**Validates**: FR-006a, Q4-D

1. Win; reach overlay phase.
2. Tap backdrop. Overlay closes; completed puzzle visible.
3. Confirm **Play Again** / **New Puzzle** are **not** on screen.
4. Tap **Back** to leave.

---

## Scenario 7 — Play Again Stops Fanfare

**Validates**: FR-007

1. Win; reach overlay.
2. Tap **Play Again**. Fanfare stops; game restarts.

---

## Scenario 8 — Sound-Off

**Validates**: FR-008

1. Mute device; complete puzzle.
2. Full animation plays; overlay appears; no crash.

---

## Scenario 9 — Milestone Style

**Validates**: FR-010, FR-011

1. Invoke milestone style via debug harness.
2. Confirm distinct animation; never in daily rotation.

---

## Scenario 10 — Corrupt Daily Tracker

**Validates**: Edge case recovery

1. Corrupt `celebration_daily_count` in preferences.
2. Complete puzzle — valid style plays; no crash.

---

## Test Suite

```bash
flutter test
flutter test --coverage
flutter analyze    # must exit 0: "No issues found!"
flutter build apk --debug
```

---

## Key Test Files

| Area | Path |
|---|---|
| Phase transitions | `test/widget/game_screen_loaded_test.dart` |
| CelebrationLayer skip/complete | `test/widget/widgets/celebration_layer_test.dart` |
| Fixed WinOverlay | `test/unit/widgets/win_overlay_test.dart` |
| Selector / tracker | `test/unit/services/` |
