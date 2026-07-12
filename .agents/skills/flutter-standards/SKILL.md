---
name: flutter-standards
description: Dart and Flutter code quality standards for this project — DRY, SOLID, linting, widgets, state management, and testing conventions. Use when writing or reviewing Dart/Flutter code, widgets, repositories, or tests.
---

# Flutter standards

Apply on every Dart/Flutter change. The project constitution (`.specify/memory/constitution.md`) adds feature-level gates (mockup fidelity, ≥85% coverage) — follow both.

## DRY

- Every piece of knowledge must have a single, unambiguous representation in the codebase.
- Extract repeated UI fragments into a widget in `lib/core/widgets/`.
- Extract repeated logic into a method, utility function in `lib/core/utils/`, or an extension.
- Extract repeated values (colours, sizes, durations, strings) into constants — never hard-code the same literal in more than one place.
- Before writing new code, search the existing codebase for something that already does (or nearly does) what you need.

## SOLID

### Single responsibility

- Every class, widget, and function has exactly one reason to change.
- Widgets are responsible for UI only — no business logic, no direct data fetching.
- Repositories handle data access only — no UI, no state management logic.
- Separate state management (e.g., `ChangeNotifier`, `Bloc`, `Riverpod`) from both UI and data layers.

### Open / closed

- Prefer composing behaviours via constructor parameters, callbacks, or interfaces over subclassing.
- Design core/shared widgets to be configurable (via parameters) rather than requiring modification when new use-cases arise.

### Liskov substitution

- Subtypes must be fully usable wherever their base type is expected.
- If an override needs to throw `UnimplementedError` or silently no-op, reconsider the inheritance hierarchy.

### Interface segregation

- Prefer small, focused abstract classes/interfaces over large ones.
- A class should depend only on the methods it actually uses; split fat interfaces into role-specific ones.

### Dependency inversion

- High-level modules (features, UI) must not depend on low-level modules (data sources, platform APIs) directly.
- Depend on abstractions (abstract classes or interfaces); inject concrete implementations.
- Use constructor injection as the default; avoid service locators unless the whole team has agreed on one pattern.

## Dart & Flutter conventions

- Follow the [official Dart style guide](https://dart.dev/effective-dart/style).
- All lints in `analysis_options.yaml` (based on `very_good_analysis`) must pass with zero warnings. Never suppress a lint without a comment explaining why.
- Use `const` constructors wherever possible — it reduces widget rebuilds.
- Prefer `final` fields; use `late` sparingly and only when initialisation truly cannot happen in the constructor.
- Avoid `dynamic`; use explicit types or generics.
- Name things for what they *are*, not what they *do*: `PuzzlePiece`, not `PuzzlePieceWidget`; `PuzzleRepository`, not `PuzzleDataFetcher`.
- Write doc comments (`///`) on every public API — class, constructor, method, and field.

## Widget guidelines

- Split large widget `build` methods into focused private methods or separate `StatelessWidget` classes — not both for the same thing.
- Keep widget files under ~200 lines; split into multiple files if they grow larger.
- Never put business logic inside `build()`. Extract it to a method, a `StatefulWidget`'s state, or a dedicated notifier/bloc.
- Prefer `StatelessWidget` + external state management over `StatefulWidget` unless local ephemeral state (e.g., animation controller) is genuinely required.

## State management

- Keep state as close to where it is needed as possible (`setState` for truly local, ephemeral state; a shared provider/bloc for anything consumed by more than one widget).
- Never pass raw mutable state objects through the widget tree — use immutable data models.

## Testing

- Every new class or function must have a corresponding unit test in `test/` mirroring the `lib/` structure.
- New widgets must have widget tests.
- Do not write tests that rely on implementation details — test behaviour and outcomes.
- Use descriptive test names: `given_<context>_when_<action>_then_<expectation>` or a natural-language equivalent.
