# Tasks: Timed Hint Unlock

**Input**: Design documents from `specs/002-timed-hint-unlock/`

**Prerequisites**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · quickstart.md ✅

**Tests**: Included — constitution mandates TDD (Red → Green → Refactor on every change).
Write each test task first, confirm it fails, then implement.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story ([US1] or [US2])
- Paths are project-relative from repository root

---

## Phase 1: Setup — Localization Strings

**Purpose**: Add all new UI strings to every supported locale before any screen code is written.
All four files are independent — write them in parallel.

- [X] T001 [P] Add hint settings l10n keys (`hintsSection`, `hintsImmediate`, `hintsDelayLabel`, `hintsDelayError`) to `lib/l10n/app_localizations_en.dart`
- [X] T002 [P] Add hint settings l10n keys with Polish translations to `lib/l10n/app_localizations_pl.dart`
- [X] T003 [P] Add hint settings l10n keys with German translations to `lib/l10n/app_localizations_de.dart`
- [X] T004 [P] Add hint settings l10n keys with Spanish translations to `lib/l10n/app_localizations_es.dart`

**Checkpoint**: Run `flutter analyze` — no missing ARB key errors.

---

## Phase 2: Foundational — New Models, Service & Widget-Tree Wiring

**Purpose**: Core building blocks required by both User Stories. No story work begins until this
phase is complete.

**⚠️ CRITICAL**: US1 and US2 both depend on this phase.

### HintSlotState Enum (TDD)

- [X] T005 Write failing unit test for `HintSlotState` (verify enum has exactly 3 values: `waiting`, `available`, `used`) in `test/unit/models/hint_slot_state_test.dart`
- [X] T006 [P] Create `HintSlotState` enum in `lib/models/hint_slot_state.dart` — three values: `waiting`, `available`, `used` (makes T005 pass)

### HintSettings Service (TDD)

- [X] T007 Write failing unit tests for `HintSettings` covering: default values (`immediateMode=false`, `unlockDelaySeconds=10`), `load()` returns defaults when SharedPreferences is empty, `setImmediateMode()` persists via SharedPreferences, `setUnlockDelay()` rejects values < 1, `setUnlockDelay()` accepts values ≥ 1 and persists — in `test/unit/services/hint_settings_service_test.dart`
- [X] T008 Implement `HintSettings` ChangeNotifier in `lib/services/hint_settings_service.dart` following the `DifficultySettings` pattern: fields `immediateMode`/`unlockDelaySeconds`, `load()` factory, setters with validation, `_save()` via SharedPreferences keys `hint_immediate_mode` / `hint_unlock_delay_seconds` (makes T007 pass)

### Widget-Tree Wiring

- [X] T009 Update `lib/main.dart`: call `HintSettings.load()` alongside `DifficultySettings.load()` in `main()`; add `hintSettings` field to `JigsawApp`; pass it to `SplashScreen`
- [X] T010 Thread `HintSettings hintSettings` constructor parameter through `lib/screens/splash_screen.dart`, `lib/screens/image_selection_screen.dart`, and `lib/screens/difficulty_screen.dart` down to `GameScreen` — constructor stubs only, no behaviour change
- [X] T011 Add `HintSettings hintSettings` constructor parameter stub to `lib/screens/game_screen.dart` (field stored, not yet used)
- [X] T012 Add `HintSettings hintSettings` constructor parameter stub to `lib/screens/settings_screen.dart` (field stored, not yet used) and update the call site in `SplashScreen` to pass it

**Checkpoint**: `flutter test` passes; `flutter analyze` clean. Both screen constructors accept `HintSettings` without crashing.

---

## Phase 3: User Story 1 — Child Receives a Timed Hint (Priority: P1) 🎯 MVP

**Goal**: Hint buttons start inactive and unlock after the configured idle period. Using a hint
highlights a piece; the next hint's timer starts only after the highlighted piece is correctly
placed. Button states: waiting (visible, inactive) → available (active) → used (hidden). All 3
used → entire hint area hidden.

**Independent Test**: Start a puzzle with the default 10-second delay. Verify the hint button is
inactive for 10 seconds, then becomes active. Tap it, place the highlighted piece, wait 10 s,
verify hint 2 becomes active. Use all 3 hints; verify the hint area disappears.

### Tests for GameState Hint Slot Changes (write first — must FAIL before T015)

- [X] T013 [US1] Write failing unit tests for `GameState` hint slot API in `test/unit/models/game_state_test.dart`:
  - `currentHintSlot` returns `HintSlotState.waiting` for all 3 slots on construction (timed mode)
  - `currentHintSlot` returns `HintSlotState.available` on construction when `immediateMode: true`; after using hint 1, returns `available` for slot 2; after using hint 2, returns `available` for slot 3 — verifying all 3 slots are pre-set
  - `markNextSlotAvailable()` transitions first `waiting` slot to `available`; second call transitions the next
  - `markNextSlotAvailable()` is a no-op when no `waiting` slots remain
  - `activateHint()` transitions the first `available` slot to `used` and sets `hintedPieceIndex`
  - `activateHint()` is a no-op when `currentHintSlot` is not `available`
  - `isHintedPiecePlaced` returns `false` when no hint is active
  - `isHintedPiecePlaced` returns `true` after the hinted piece is snapped via `endDrag()`
  - `isHintedPiecePlaced` returns `false` after a *different* (non-hinted) piece is snapped — no false positive
  - `currentHintSlot` returns `null` when all 3 slots are `used`
  - Existing `hasActiveHint` behaviour preserved

### GameState Implementation (makes T013 pass)

- [X] T014 [US1] Modify `lib/models/game_state.dart`:
  - Remove `int _hintsRemaining` field and `int get hintsRemaining` getter
  - Add `bool immediateMode = false` constructor parameter
  - Add `List<HintSlotState> _hintSlots` field — initialized to `[waiting, waiting, waiting]` (timed) or `[available, available, available]` (immediate)
  - Add `int? _hintedPieceIndex` field
  - Add `HintSlotState? get currentHintSlot` — first non-`used` slot state; null if all used
  - Add `int? get hintedPieceIndex`
  - Add `bool get isHintedPiecePlaced`
  - Add `void markNextSlotAvailable()` — transitions first `waiting` → `available`; calls `notifyListeners()`
  - Update `void activateHint()` — guard: first slot must be `available`; mark it `used`; pick random unplaced piece; set `_hintedPieceIndex`

### Tests for GameBoardView Hint Button States (write first — must FAIL before T016)

- [X] T015 [US1] Write failing widget tests for `GameBoardView` hint button rendering in `test/widget/screens/game_board_view_test.dart`:
  - `currentHintSlot: HintSlotState.waiting` → hint button present, `enabled: false`
  - `currentHintSlot: HintSlotState.available` → hint button present, `enabled: true`
  - `currentHintSlot: null` → hint button absent from widget tree

### GameBoardView Implementation (makes T015 pass)

- [X] T016 [US1] Modify `lib/screens/game_board_view.dart`:
  - Replace `VoidCallback? onHint` parameter with `HintSlotState? currentHintSlot` and non-nullable `VoidCallback onHint`
  - Update `_buildRightControls`: if `currentHintSlot == null` → omit hint button; if `waiting` → `enabled: false, opacity: 0.5`; if `available` → `enabled: true, opacity: 1.0`
  - Remove hint count label `(${gs.hintsRemaining})` from button text

### Tests for GameScreen Timer Management (write first — must FAIL before T017/T018)

- [X] T017 [US1] Write failing widget tests for `GameScreen` hint timer behaviour in `test/widget/game_screen_test.dart`:
  - Timer starts when game transitions to `playing` (in timed mode)
  - Hint slot becomes `available` after configured delay with no placement
  - Any piece-placement attempt (correct or wrong) resets the timer
  - App backgrounded → timer pauses; foregrounded → timer resumes remaining duration
  - Immediate mode → all slots start `available` (no timer needed)
  - After all 3 hints used → hint area absent
  - Hint used but hinted piece NOT placed → placing a different piece correctly does NOT start the next hint timer (FR-018)
  - `hintSettings.unlockDelaySeconds` changed mid-session does NOT alter the active timer interval (FR-017)

### GameScreen Timer Management Implementation (makes T017 pass)

- [X] T018 [US1] Add `WidgetsBindingObserver` mixin to `_GameScreenState` in `lib/screens/game_screen.dart`:
  - Register/unregister observer in `initState`/`dispose`
  - Implement `didChangeAppLifecycleState`: on `paused`/`inactive` cancel `_hintTimer` and store `_timerRemainingMs`; on `resumed` restart timer with stored remaining duration
- [X] T019 [US1] Add timer management logic to `lib/screens/game_screen.dart`:
  - Add `Timer? _hintTimer`, `DateTime? _timerStartTime`, `int _timerRemainingMs` fields
  - Implement `_startHintTimer(int delayMs)` — cancels existing, starts one-shot Timer; on fire: calls `gs.markNextSlotAvailable()`, `setState(() {})`
  - Implement `_cancelHintTimer()` and `_resetHintTimer()`
  - Call `_startHintTimer(hintSettings.unlockDelaySeconds * 1000)` inside `_onScatterStatus` when game enters `playing` and `!hintSettings.immediateMode`
  - Reset timer in `_onPanEnd` on any piece-placement attempt (both snapped and rejected paths)
  - After snapped placement: check `gs.isHintedPiecePlaced`; if true, call `_resetHintTimer()` then `_startHintTimer(...)` for next slot — **no fallback**: if hinted piece is NOT the placed piece, do NOT start the timer (FR-018)
- [X] T020 [US1] Update `_initGame()` and `_buildBody()` in `lib/screens/game_screen.dart`:
  - Pass `immediateMode: hintSettings.immediateMode` to `GameState` constructor in `_initGame()`
  - In `_buildBody()`: replace `canUseHint` + `onHint: canUseHint ? ... : null` with `currentHintSlot: gs.currentHintSlot` and `onHint: () { gs.activateHint(); setState(() {}); }`
  - Remove any now-unreachable `canUseHint` / `hasActiveHint` code paths made dead by the above change

**Checkpoint**: `flutter test` passes for all modified test files. Manually run Scenario 1 from `quickstart.md`.

---

## Phase 4: User Story 2 — Adult Configures Hint Unlock Behaviour (Priority: P2)

**Goal**: A new Hints section in the settings screen lets adults toggle Immediate mode (all hints
always active) or set a custom timeout in seconds. The timeout input is disabled when Immediate
mode is on. Invalid input (blank, zero, non-numeric) is rejected with an error.

**Independent Test**: Open Settings, enter `30` in the delay field, save, start a puzzle, verify
the hint unlocks after 30 s. Toggle Immediate on, start a puzzle, verify hints are immediately
active.

### Tests for SettingsScreen Hints Section (write first — must FAIL before T022)

- [X] T021 [US2] Write failing widget tests for the Hints section in `test/widget/settings_screen_test.dart`:
  - Hints section heading is present after math-gate unlock
  - Immediate checkbox starts unchecked when `HintSettings.immediateMode == false`
  - Immediate checkbox starts checked when `HintSettings.immediateMode == true`
  - Delay input is enabled when `immediateMode == false`, disabled when `true`
  - Entering a valid integer and saving calls `hintSettings.setUnlockDelay()`
  - Entering blank or `0` shows error text and does not call `setUnlockDelay()`
  - Toggling Immediate checkbox calls `hintSettings.setImmediateMode()`

### SettingsScreen Hints Section Implementation (makes T021 pass)

- [X] T022 [US2] Add Hints section to `lib/screens/settings_screen.dart` inside `_buildSettingsPanel()`:
  - Section label using `l10n.hintsSection` via `_buildSectionLabel()`
  - `Checkbox` row for Immediate mode: label `l10n.hintsImmediate`; on change → `widget.hintSettings.setImmediateMode(value)`; `setState(() {})`
  - `TextField` for delay: label `l10n.hintsDelayLabel`; `keyboardType: TextInputType.number`; `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`; `enabled: !widget.hintSettings.immediateMode`; on submit/focus-lost → validate: if blank or `int.parse() < 1` show `l10n.hintsDelayError` else call `widget.hintSettings.setUnlockDelay()`
  - Initialize `TextEditingController` with `widget.hintSettings.unlockDelaySeconds.toString()` in `initState`; add to `dispose()`

**Checkpoint**: `flutter test` passes. Manually run Scenarios 4, 5, 6, 7 from `quickstart.md`.

---

## Phase 5: Polish & Quality Gates

**Purpose**: Verify the whole feature against the quality gates mandated by the constitution.

- [X] T023 Run `flutter test --coverage`; verify line coverage ≥ 85% (hard gate per constitution §VI); fix any failures or coverage drops before proceeding
- [X] T024 [P] Run `flutter analyze` — zero warnings; fix any lint issues before proceeding
- [X] T025 [P] Run `flutter build apk --debug` — must compile cleanly; fix any errors
- [ ] T026 Manually validate Scenarios 8, 9, 10 from `quickstart.md` (background/foreground, persistence, mid-session change)
- [X] T027 [P] Update `specs/002-timed-hint-unlock/checklists/requirements.md` — mark any newly resolved checklist items
- [X] T028 [P] Mark `specs/002-timed-hint-unlock/checklists/hint-logic.md` CHK010 and CHK023 as resolved — FR-018 now explicitly prohibits any fallback mechanism, closing both gaps
- [ ] T029 Review hint button visual states (inactive, active, hidden) against `assets/design/` mockups; confirm each state's visual treatment is approved before raising the PR — constitution §I requires every child-facing widget to be reviewed against design mockups

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (l10n)          → no dependencies; start immediately
Phase 2 (Foundational)  → can start in parallel with Phase 1; T005–T012 must complete before Phase 3/4
Phase 3 (US1)           → depends on Phase 2 complete
Phase 4 (US2)           → depends on Phase 2 complete; independent of Phase 3
Phase 5 (Polish)        → depends on Phase 3 + Phase 4 complete
```

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 (T006 for HintSlotState, T008 for HintSettings, T011 for GameScreen stub)
- **US2 (P2)**: Depends on Phase 2 (T008 for HintSettings, T012 for SettingsScreen stub); independent of US1

### Within Each User Story (TDD order)

```
US1: T013 (failing test) → T014 (impl) → T015 (failing test) → T016 (impl) → T017 (failing test) → T018 → T019 → T020 (impl)
US2: T021 (failing test) → T022 (impl)
```

### Parallel Opportunities

```
Phase 1: T001, T002, T003, T004 — fully parallel
Phase 2: T005+T007 can write in parallel (different files); T006 parallel with T007/T008
Phase 3: T015 (write GameBoardView tests) can start as soon as T006 passes (HintSlotState available)
Phase 4: Can start as soon as Phase 2 is complete — fully parallel with Phase 3
Phase 5: T024, T025, T027, T028, T029 are parallel once T023 passes
```

---

## Parallel Execution Examples

### Phase 1 — All l10n files together

```
Task T001: lib/l10n/app_localizations_en.dart
Task T002: lib/l10n/app_localizations_pl.dart
Task T003: lib/l10n/app_localizations_de.dart
Task T004: lib/l10n/app_localizations_es.dart
```

### Phase 2 — Model + Service in parallel

```
Task T005: test/unit/models/hint_slot_state_test.dart  (write failing test)
Task T007: test/unit/services/hint_settings_service_test.dart  (write failing test)
```

### Phase 3 + Phase 4 — Run in parallel after Phase 2

```
Developer A → Phase 3 (US1):  T013 → T014 → T015 → T016 → T017 → T018 → T019 → T020
Developer B → Phase 4 (US2):  T021 → T022
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1 (l10n strings)
2. Complete Phase 2 (foundational model/service/wiring)
3. Complete Phase 3 (US1 — timed hint unlock in gameplay)
4. **STOP and VALIDATE**: run `flutter test`, Scenarios 1–3 from `quickstart.md`
5. Settings configuration (US2) can ship in a follow-up if needed

### Full Feature Delivery

1. Phase 1 + Phase 2 → foundation ready
2. Phase 3 (US1) → timed hint works in gameplay → validate
3. Phase 4 (US2) → adults can configure delay → validate
4. Phase 5 → quality gates → PR

---

## Notes

- `[P]` tasks operate on different files — safe to run concurrently
- `[US1]` / `[US2]` labels trace each task back to its user story in `spec.md`
- TDD is mandatory (constitution §II): every test task must be written and confirmed failing before its implementation task begins
- No-fallback rule (FR-018, spec amended 2026-06-10): the next hint timer MUST NOT start unless the hinted piece is correctly placed — no idle-timeout fallback, no alternative unlock path. CHK010 and CHK023 in `checklists/hint-logic.md` are resolved by FR-018
