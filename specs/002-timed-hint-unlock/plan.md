# Implementation Plan: Timed Hint Unlock

**Branch**: `002-timed-hint-unlock` | **Date**: 2026-06-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-timed-hint-unlock/spec.md`

## Summary

Replace the always-available hint system (3 active hints at all times) with a timer-based unlock
system. Each of the 3 hints unlocks after an idle period with no piece-placement attempt. The
second and third hints only begin their countdown once the piece highlighted by the previous hint
has been correctly placed. Adults configure the timeout (default 10 s) or opt for the existing
immediate-unlock behaviour via a new settings section protected behind the existing math gate.

Hint configuration is persisted locally via SharedPreferences, following the same pattern as
`DifficultySettings`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.41.3

**Primary Dependencies**: `shared_preferences` (already in pubspec — no new package required)

**Storage**: SharedPreferences — local on-device, matching `DifficultySettings` pattern

**Testing**: `flutter_test` (unit + widget); `mocktail` for SharedPreferences mocking (already used)

**Target Platform**: Android phones and tablets (landscape orientation)

**Project Type**: Mobile app (Flutter)

**Performance Goals**: Timer resolution ±1 second; hint glow animation maintains 60 fps

**Constraints**:
- No new third-party packages
- Settings survive app restarts
- Timer pauses while app is backgrounded (WidgetsBindingObserver)
- Mid-session settings changes take effect from the next session only

**Scale/Scope**: Single-device, single-user; 3 hint slots per session; 1 settings screen section

## Constitution Check

*GATE: Must pass before proceeding.*

| Gate | Status | Notes |
|------|--------|-------|
| I — Children-First UI | PASS | Hint button states (inactive/active/hidden) are child-facing; exact visual design deferred to implementation — must be reviewed against `assets/design/` before PR |
| II — TDD (Red→Green→Refactor) | PASS | Plan requires tests written first for every new class and modified method |
| III — Functional/Immutable | PASS | `HintSlotState` is an enum; `HintSettings` uses `final` fields with `copyWith` not needed (ChangeNotifier mutation via setters matches existing `DifficultySettings` pattern) |
| IV — DRY | PASS | Reuses SharedPreferences pattern; new `HintSettings` does not duplicate `DifficultySettings` logic |
| V — KISS / SOLID | PASS | `HintSettings` single responsibility: persist config. Timer management stays in `GameScreen`. `GameState` tracks slot states only |
| VI — Quality Gates | REQUIRED | `flutter test` + `flutter analyze` + `flutter build apk --debug` must pass before PR |

**Post-design re-check**: Required after Phase 1 — confirm no SOLID violations in `GameState` changes.

## Resolved: No Fallback for Unplaced Hinted Piece

The previously unresolved gap is now closed. Per FR-018 (spec amended 2026-06-10):

**Decision**: If the child uses hint N but never correctly places the highlighted piece, hint N+1
remains permanently locked. There is **no fallback timer** and no alternative unlock path. The
only way to unlock hint N+1 is to correctly place the piece highlighted by hint N.

**Implication for implementation**: `GameScreen` timer logic MUST NOT start the next hint's timer
for any reason other than correct placement of the hinted piece. No idle-timeout fallback path.

## Project Structure

### Documentation (this feature)

```text
specs/002-timed-hint-unlock/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code Changes

```text
lib/
├── models/
│   ├── game_state.dart          # MODIFY — replace _hintsRemaining with _hintSlots
│   └── hint_slot_state.dart     # NEW — HintSlotState enum
├── services/
│   ├── difficulty_settings_service.dart  # unchanged
│   └── hint_settings_service.dart        # NEW — HintSettings ChangeNotifier
├── screens/
│   ├── game_screen.dart         # MODIFY — timer management, lifecycle observer
│   ├── game_board_view.dart     # MODIFY — new hint button rendering
│   └── settings_screen.dart     # MODIFY — add Hints section
├── l10n/
│   ├── app_localizations_en.dart  # MODIFY — add hint settings strings
│   ├── app_localizations_pl.dart  # MODIFY
│   ├── app_localizations_de.dart  # MODIFY
│   └── app_localizations_es.dart  # MODIFY
└── main.dart                    # MODIFY — load HintSettings, pass to widget tree

test/
├── unit/
│   ├── models/
│   │   └── game_state_test.dart           # MODIFY — update hint-related tests
│   └── services/
│       └── hint_settings_service_test.dart # NEW
└── widget/
    ├── screens/
    │   └── game_board_view_test.dart       # MODIFY — hint button state rendering tests
    ├── settings_screen_test.dart           # MODIFY — add Hints section tests
    └── game_screen_test.dart               # MODIFY — timer/slot tests
```

## Complexity Tracking

No constitution violations. No complexity justification required.
