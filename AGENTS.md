# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project

Flutter jigsaw puzzle game for Android (tablets, primarily Samsung Galaxy Tab S8+).

## Environment

Flutter 3.41.3 at `~/development/flutter`. PATH and ANDROID_HOME are in `~/.bashrc` / `~/.zshrc` — run `source ~/.bashrc` in a new shell.

- Flutter SDK: `~/development/flutter`
- Android SDK: `~/Android/Sdk` (API 36, build-tools 35.0.0)

## Commands

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
- `specs/` — feature specifications and plans (Spec Kit)
- `.specify/memory/constitution.md` — project constitution (UI, TDD, coverage gates)

## Always apply

These rules apply to every task. For full detail, use the skills listed below.

- **Clarify first:** State assumptions; ask when requirements are ambiguous or multiple interpretations exist.
- **Minimal scope:** Solve only what was asked. Don't refactor, "improve", or expand adjacent code.
- **Match the codebase:** Follow existing style and patterns. Search before duplicating logic or widgets.
- **Verify:** `flutter analyze` and `flutter test` must pass before opening a PR.
- **Test new code:** New classes, functions, and widgets need tests in `test/` mirroring `lib/`.
- **Lints:** Zero warnings from `analysis_options.yaml` — never suppress without a comment explaining why.

## Skills

Skills live in `.agents/skills/`. They load on demand — read the relevant skill when the task matches its description.

| Skill | When to use |
|---|---|
| `coding-discipline` | Planning, scope control, goal-driven execution |
| `flutter-standards` | Writing or reviewing Dart/Flutter code, widgets, tests |
| `pr-workflow` | Committing, pushing, opening PRs, fixing CI |
| `speckit-*` | Spec-driven feature workflow (specify, plan, implement, …) |

## Agent configuration

This repo shares one agent config across Claude Code, Cursor, and other tools. Edit **canonical**
files only — adapter paths are symlinks and must not be edited directly.

| Canonical (edit these) | Adapter (symlink — do not edit) |
|---|---|
| `AGENTS.md` | `CLAUDE.md` → `AGENTS.md` |
| `.agents/skills/` | `.claude/skills` → `.agents/skills` |
| `.mcp.json` | `.cursor/mcp.json` → `.mcp.json` |

**Adding config:**

- Instructions → `AGENTS.md` (keep it lean; extract situational guidance into skills)
- Skills → `.agents/skills/<name>/SKILL.md` (prefer skills over slash commands; use
  `disable-model-invocation: true` in frontmatter if a skill should only run when invoked)
- MCP servers → `.mcp.json` only (never commit secrets; use env var references)
- Tool-specific settings → vendor directory (e.g. `.claude/settings.json` for Claude permissions)

Environment setup, emulator, and MCP prerequisites: see `README.md`.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/004-daily-puzzle-streak/plan.md
<!-- SPECKIT END -->
