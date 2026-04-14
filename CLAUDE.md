# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

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

---

## Behavioral Guidelines

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- Favour Dart built-ins and Flutter framework primitives over third-party packages for straightforward tasks.
- Each function/method should do exactly one thing and fit comfortably in one screen (~40 lines). If it doesn't, split it.
- Avoid clever one-liners that sacrifice readability.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## Code Quality Principles

These principles are **non-negotiable**. Apply them on every change — new feature, refactor, or bug fix.

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

## Before Pushing a Commit

1. Run the full test suite (`flutter test`) — do NOT raise a PR if tests fail.
2. Run static analysis (`flutter analyze`).
3. Verify test coverage has not dropped.
4. Only open a PR once all of the above pass cleanly.

## After Opening a PR — CI Watch Loop

After creating a PR, poll CI status using `gh` until checks complete:
```bash
# Wait for all checks to finish (polls every 30s)
gh pr checks  --watch

# If any check fails, read the logs:
gh run list --branch  --limit 1
gh run view  --log-failed
```

If checks fail:
1. Read the failure output carefully
2. Fix the root cause in the source code
3. Commit and push the fix to the same branch
4. Repeat until `gh pr checks --watch` exits with all green

## CI/CD Context

When running in GitHub Actions:
- Always create a new branch for changes, never commit directly to main
- Include test results summary in the PR description
- If tests fail, fix the issues before creating the PR

## Notes

- `flutter doctor` shows warnings for Chrome and Linux toolchain — these are not needed for Android development.
- The PATH warning in `flutter doctor` resolves after sourcing `~/.bashrc` in a new terminal.
- To deploy to a physical Android device over USB on WSL2, USB passthrough via `usbipd-win` is required on the Windows host.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
