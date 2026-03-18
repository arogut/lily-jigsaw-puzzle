# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter jigsaw puzzle game targeting Android.

## Environment

Flutter 3.41.3 is installed at `~/development/flutter`. PATH and ANDROID_HOME are configured in `~/.bashrc` and `~/.zshrc`. Open a new terminal (or `source ~/.bashrc`) to have `flutter` available directly.

- Flutter SDK: `~/development/flutter`
- Android SDK: `~/Android/Sdk` (API 36, build-tools 35.0.0)

## Common Commands

```bash
flutter run                        # Run on connected device
flutter build apk                  # Build release APK
flutter build apk --debug          # Build debug APK
flutter test                       # Run all tests
flutter test test/widget_test.dart # Run a single test file
flutter pub get                    # Install dependencies
flutter pub add <package>          # Add a dependency
flutter analyze                    # Run static analysis
```

## Architecture

- `lib/main.dart` — entry point
- `android/` — Android-specific configuration (Kotlin, Gradle)
- `test/` — widget and unit tests
- `pubspec.yaml` — dependencies and project metadata

## Code Quality Principles
 
These principles are **non-negotiable**. Apply them on every change — new feature, refactor, or bug fix.
 
### KISS — Keep It Simple, Stupid
 
- Prefer the simplest solution that correctly solves the problem.
- Avoid premature abstractions: do not create a base class, mixin, or interface until the same pattern appears in at least two concrete places.
- Favour Dart built-ins and Flutter framework primitives over third-party packages for straightforward tasks.
- Each function/method should do exactly one thing and fit comfortably in one screen (~40 lines). If it doesn't, split it.
- Avoid clever one-liners that sacrifice readability.
 
### DRY — Don't Repeat Yourself
 
- Every piece of knowledge must have a single, unambiguous representation in the codebase.
- Extract repeated UI fragments into a widget in `lib/core/widgets/`.
- Extract repeated logic into a method, utility function in `lib/core/utils/`, or an extension.
- Extract repeated values (colours, sizes, durations, strings) into constants — never hard-code the same literal in more than one place.
- Before writing new code, search the existing codebase for something that already does (or nearly does) what you need.
 
### SOLID Principles
 
#### Single Responsibility
- Every class, widget, and function has exactly one reason to change.
- Widgets are responsible for UI only — no business logic, no direct data fetching.
- Repositories handle data access only — no UI, no state management logic.
- Separate state management (e.g., `ChangeNotifier`, `Bloc`, `Riverpod`) from both UI and data layers.
 
#### Open / Closed
- Prefer composing behaviours via constructor parameters, callbacks, or interfaces over subclassing.
- Design core/shared widgets to be configurable (via parameters) rather than requiring modification when new use-cases arise.
 
#### Liskov Substitution
- Subtypes must be fully usable wherever their base type is expected.
- If an override needs to throw `UnimplementedError` or silently no-op, reconsider the inheritance hierarchy.
 
#### Interface Segregation
- Prefer small, focused abstract classes/interfaces over large ones.
- A class should depend only on the methods it actually uses; split fat interfaces into role-specific ones.
 
#### Dependency Inversion
- High-level modules (features, UI) must not depend on low-level modules (data sources, platform APIs) directly.
- Depend on abstractions (abstract classes or interfaces); inject concrete implementations.
- Use constructor injection as the default; avoid service locators unless the whole team has agreed on one pattern.
 
## Dart & Flutter Conventions
 
- Follow the [official Dart style guide](https://dart.dev/effective-dart/style).
- All lints in `analysis_options.yaml` (based on `very_good_analysis`) must pass with zero warnings. Never suppress a lint without a comment explaining why.
- Use `const` constructors wherever possible — it reduces widget rebuilds.
- Prefer `final` fields; use `late` sparingly and only when initialisation truly cannot happen in the constructor.
- Avoid `dynamic`; use explicit types or generics.
- Name things for what they *are*, not what they *do*: `PuzzlePiece`, not `PuzzlePieceWidget`; `PuzzleRepository`, not `PuzzleDataFetcher`.
- Write doc comments (`///`) on every public API — class, constructor, method, and field.
 
## Widget Guidelines
 
- Split large widget `build` methods into focused private methods or separate `StatelessWidget` classes — not both for the same thing.
- Keep widget files under ~200 lines; split into multiple files if they grow larger.
- Never put business logic inside `build()`. Extract it to a method, a `StatefulWidget`'s state, or a dedicated notifier/bloc.
- Prefer `StatelessWidget` + external state management over `StatefulWidget` unless local ephemeral state (e.g., animation controller) is genuinely required.
 
## State Management
 
- Keep state as close to where it is needed as possible (`setState` for truly local, ephemeral state; a shared provider/bloc for anything consumed by more than one widget).
- Never pass raw mutable state objects through the widget tree — use immutable data models.
 
## Testing
 
- Every new class or function must have a corresponding unit test in `test/` mirroring the `lib/` structure.
- New widgets must have widget tests.
- Do not write tests that rely on implementation details — test behaviour and outcomes.
- Use descriptive test names: `given_<context>_when_<action>_then_<expectation>` or a natural-language equivalent.

## Before Pushing a commit — Required Steps

1. Run the full test suite (e.g., `flutter test`) — do NOT raise a PR if tests fail
2. Run static analysis (e.g., `flutter analyze`)
3. Verify test coverage has not dropped
4. Only open a PR once all of the above pass cleanly

## CI/CD Context
When running in GitHub Actions:
- Always create a new branch for changes, never commit directly to main
- Include test results summary in the PR description
- If tests fail, fix the issues before creating the PR

## Notes

- `flutter doctor` shows warnings for Chrome and Linux toolchain — these are not needed for Android development.
- The PATH warning in `flutter doctor` resolves after sourcing `~/.bashrc` in a new terminal.
- To deploy to a physical Android device over USB on WSL2, USB passthrough via `usbipd-win` is required on the Windows host.
