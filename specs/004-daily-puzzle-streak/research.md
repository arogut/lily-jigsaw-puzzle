# Research: Daily Puzzle Streak

**Phase**: 0 | **Date**: 2026-06-27 | **Feature**: [spec.md](spec.md)

No external research required — all decisions resolved from existing project context.

---

## Decision 1: Storage Mechanism

**Decision**: Use `shared_preferences` (already in `pubspec.yaml`) to persist streak state as three primitive keys.

**Rationale**: The user explicitly requested no internal databases and to reuse existing dependencies. `SharedPreferences` is already used by `CompletionService` for the same kind of lightweight persistent state (a handful of typed key-value pairs). Adding a new package (e.g., Hive, SQLite) would violate both the user constraint and the constitution's YAGNI principle.

**Alternatives considered**:
- `sqflite` / `drift` — overkill for three values; adds a dependency; explicitly ruled out by the user
- In-memory only — streak would be lost on app restart; violates FR-005
- File I/O — more complexity than `SharedPreferences`; no benefit

**SharedPreferences keys chosen**:
| Key | Type | Meaning |
|-----|------|---------|
| `streak_current` | `int` | Current consecutive-day streak count (≥ 0) |
| `streak_longest` | `int` | All-time longest streak (≥ 0) |
| `streak_last_date` | `String?` | ISO date of last completion (`YYYY-MM-DD`), null if never |

---

## Decision 2: Date Representation

**Decision**: Store the date as a plain `YYYY-MM-DD` string (ISO 8601 date-only format). Compare strings directly; use `DateTime.now()` to extract the local date.

**Rationale**: No time zone conversion complexity. The spec says a "day" is the device's local calendar day. `DateTime.now()` gives local time; formatting it as `YYYY-MM-DD` captures the calendar day in the device time zone.

**Alternatives considered**:
- UTC epoch timestamp — would require timezone-aware day comparison; unnecessary complexity
- Full `DateTime.toIso8601String()` — includes time component, making same-day comparison harder

---

## Decision 3: Testability Without External Packages

**Decision**: `StreakService` accepts an optional `DateTime Function()` parameter named `clock`, defaulting to `() => DateTime.now()`. Tests inject a fake clock by passing a closure that returns a fixed date.

**Rationale**: Streak logic is date-sensitive — tests must control the "current date" to verify increment, same-day, and reset scenarios deterministically. Injecting a clock closure costs nothing (no extra package, no interface) and follows the existing project style of keeping things simple. No `clock` package or `mocktail` mock of `DateTime` is needed.

**Alternatives considered**:
- `mocktail` / `mockito` mock of a `Clock` interface — more boilerplate than a simple closure
- `clock` pub package — an unnecessary new dependency

---

## Decision 4: Integration Point

**Decision**: Call `StreakService.recordPuzzleCompletion()` inside `GameScreen._recordCompletion()`, immediately after the existing `CompletionService.recordCompletion()` call. Store the returned `StreakRecord` in `_GameScreenState` and pass it to `WinOverlay`.

**Rationale**: `_recordCompletion()` is already the single place where puzzle completion is actioned. Keeping the streak call adjacent to the existing completion call avoids scattering the win logic. `WinOverlay` receives the record as a constructor parameter (nullable) — backward-compatible and testable.

**Alternatives considered**:
- Calling `StreakService` inside `GameState.endDrag()` — violates SRP (state management shouldn't know about persistence)
- Loading streak separately in `WinOverlay` itself — mixes data-fetching into a UI widget; violates constitution principle V

---

## Decision 5: Win Overlay Display

**Decision**: Add a `StreakRecord? streakRecord` parameter to `WinOverlay`. When non-null and `currentStreak > 0`, display the current streak (e.g. "🔥 5 Day Streak") and longest streak ("Best: 12 days") using existing text styles and the childish palette. Localization strings go through the existing ARB pipeline.

**Rationale**: The `WinOverlay` already uses localized strings. Extending its constructor is the surgical, minimal change — no new widget file needed. The nullable parameter means existing tests that construct `WinOverlay` without a streak record continue to work.

**Alternatives considered**:
- New `StreakBadge` widget composed into `WinOverlay` — adds a file and an abstraction layer for what is a small UI addition; YAGNI
- Separate streak screen/page — not requested; over-scope
