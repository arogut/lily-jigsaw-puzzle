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

## Skills and commands

Both live under `.agents/` and are shared across tools via symlinks. Use **skills** and **commands**
for different jobs — they complement each other; neither replaces the other.

### Skills (`.agents/skills/<name>/SKILL.md`)

The agent can **discover and load automatically** when the task matches the skill's `description`.
Skills can include supporting files in their directory.

| Use a skill when… | Examples in this repo |
|---|---|
| Guidance should apply proactively during matching work | `flutter-standards`, `coding-discipline` |
| The workflow has multiple files or templates | `speckit-*`, `requesting-code-review` |
| You want the agent to decide when expert context is needed | `pr-workflow` |

Optional frontmatter:

- `disable-model-invocation: true` — only run when you invoke it (Claude Code; behaves like a
  manual command while staying in the skills tree)
- `user-invocable: false` — hide from the `/` picker but still allow auto-discovery

### Commands (`.agents/commands/<name>.md`)

You invoke explicitly with **`/<name>`**. The agent does **not** auto-load command content — useful
when you want deliberate, user-triggered workflows.

| Use a command when… | Examples |
|---|---|
| You always want to trigger the workflow yourself | `/code-review` |
| The prompt is a single file with no supporting assets | One markdown file is enough |
| You want a stable, discoverable entry in the `/` menu | Team rituals, routers, one-shot actions |

Subdirectories namespace commands: `.agents/commands/test/integration.md` → `/test:integration`.

### Avoid name collisions

Do not use the same name for a skill directory and a command file — in Claude Code the skill wins.
Pick one home per workflow.

### Subagents (`.agents/agents/<name>.md`)

Subagents run in an isolated context via the Task tool or `/name`. Adapter directories (symlinks):
`.claude/agents`, `.cursor/agents` → `.agents/agents`.

| Subagent | When to use |
|---|---|
| `code-reviewer` | Review a git diff before PR; pairs with `requesting-code-review` skill and `/code-review` command |

Shared review criteria (local subagent + CI workflow): `.agents/review/criteria.md`.

## Agent configuration

This repo shares one agent config across Claude Code, Cursor, and other tools. Edit **canonical**
files only — adapter paths are symlinks and must not be edited directly.

| Canonical (edit these) | Adapter (symlink — do not edit) |
|---|---|
| `AGENTS.md` | `CLAUDE.md` → `AGENTS.md` |
| `.agents/skills/` | `.claude/skills` → `.agents/skills` |
| `.agents/commands/` | `.claude/commands`, `.cursor/commands` → `.agents/commands` |
| `.agents/agents/` | `.claude/agents`, `.cursor/agents` → `.agents/agents` |
| `.mcp.json` | `.cursor/mcp.json` → `.mcp.json` |

Cursor reads `.agents/skills/` natively; Claude Code and Cursor reach commands, agents, and MCP
via the adapter symlinks above.

Spec Kit: both `claude` and `cursor-agent` integrations are installed (`.specify/integration.json`);
default CLI integration is `cursor-agent`. Skills and agent-context target canonical `.agents/` paths.

**Adding config:**

- Instructions → `AGENTS.md` (keep it lean; extract situational guidance into skills)
- Skills → `.agents/skills/<name>/SKILL.md`
- Commands → `.agents/commands/<name>.md`
- Subagents → `.agents/agents/<name>.md`
- MCP servers → `.mcp.json` only (never commit secrets; use env var references)
- Tool-specific settings → vendor directory (e.g. `.claude/settings.json` for Claude permissions)

Environment setup, emulator, and MCP prerequisites: see `README.md`.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/004-daily-puzzle-streak/plan.md
<!-- SPECKIT END -->
