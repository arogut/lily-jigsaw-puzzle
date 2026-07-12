# Lily Jigsaw Puzzle

> Built with [Claude Code](https://claude.ai/code)

A jigsaw puzzle game for children, built with Flutter for Android. Designed to run on tablets, primarily targeting the Samsung Galaxy Tab S8+.

> Images generated with [DeepAI](https://deepai.org/)

## Requirements

- Flutter 3.41.3
- Android SDK (API 35+, build-tools 35.0.0)
- Java 17+

## Environment Setup

Flutter is installed at `~/development/flutter`. Add it to your PATH by sourcing your shell config:

```bash
source ~/.bashrc
```

Or use the full path directly: `~/development/flutter/bin/flutter`.

### Android SDK

The Android SDK is located at `~/Android/Sdk`. Set the environment variable when needed:

```bash
export ANDROID_HOME=~/Android/Sdk
```

### Install dependencies

```bash
flutter pub get
```

## Emulated Device Setup

The emulator runs on the **Windows host** to avoid WSL2 QEMU memory crashes caused by
`lavapipe` software rendering at the Pixel Tablet's 2560×1600 resolution. Flutter in WSL2
connects to it via the Windows ADB server.

### Windows: install SDK command-line tools

Download the command-line tools zip from https://developer.android.com/studio#command-line-tools-only
and extract to `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\`. Then install the required
components from PowerShell:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$sdkmanager = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
& $sdkmanager --sdk_root=$sdk --licenses
& $sdkmanager --sdk_root=$sdk "emulator" "platform-tools" "system-images;android-35;google_apis;x86_64"
```

### Windows: create the Pixel Tablet AVD

```powershell
$avdmanager = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat"
echo "no" | & $avdmanager --sdk_root="$env:LOCALAPPDATA\Android\Sdk" create avd `
  --name "Pixel_Tablet_API_35" `
  --package "system-images;android-35;google_apis;x86_64" `
  --device "pixel_tablet"
```

### Windows: start the emulator and ADB server

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"

# Start the emulator
& "$sdk\emulator\emulator.exe" -avd Pixel_Tablet_API_35 -no-metrics

# In a separate PowerShell window, start the ADB server listening on all interfaces
# so WSL2 can reach it (ensure port 5037 is allowed in Windows Firewall)
$adb = "$sdk\platform-tools\adb.exe"
& $adb kill-server
Start-Process -FilePath $adb -ArgumentList "-a -P 5037 nodaemon server" -WindowStyle Hidden
```

> **Note:** Windows Firewall must allow inbound TCP on port 5037. The ADB server and the
> WSL2 ADB client must be the same version — if they differ, update platform-tools via
> `sdkmanager "platform-tools"` on both sides.

### WSL2: connect to the Windows ADB server

`~/.bashrc` is already configured to point ADB at the Windows host:

```bash
export ANDROID_ADB_SERVER_ADDRESS=$(ip route | grep default | awk '{print $3}')
export ANDROID_ADB_SERVER_PORT=5037
```

The Windows host IP is read from the default gateway at shell startup (it changes on WSL restart).
After sourcing, verify the emulator is visible:

```bash
source ~/.bashrc
adb devices   # should list the Windows emulator
flutter devices
```

## AI agent setup

This repository uses an agent-agnostic layout so Claude Code, Cursor, and other tools share one
configuration without duplication.

### Layout

Edit **canonical** files only. Adapter paths are symlinks — do not edit them directly.

| Canonical (edit these) | Adapter (symlink) |
|---|---|
| `AGENTS.md` | `CLAUDE.md` → `AGENTS.md` |
| `.agents/skills/` | `.claude/skills` → `.agents/skills` (Cursor reads `.agents/skills/` natively) |
| `.agents/commands/` | `.claude/commands`, `.cursor/commands` → `.agents/commands` |
| `.agents/agents/` | `.claude/agents`, `.cursor/agents` → `.agents/agents` |
| `.mcp.json` | `.cursor/mcp.json` → `.mcp.json` |
| `tool/agents/` | Tool-neutral helper scripts (e.g. MCP wrappers) |

Tool-specific config that has no shared format stays in the vendor directory — for example
`.claude/settings.json` (Claude permission allowlists) and `.github/cursor/` (CI runners).

Cursor reads `.agents/skills/` natively. Commands, subagents, and MCP use adapter symlinks under
`.cursor/` and `.claude/`. Spec Kit lists both `claude` and `cursor-agent` integrations
(`.specify/integration.json`); default CLI integration is `claude`.

### Skills vs commands

Both are first-class. They live under `.agents/` and reach Claude Code and Cursor through symlinks.

| | Skills (`.agents/skills/<name>/`) | Commands (`.agents/commands/<name>.md`) |
|---|---|---|
| **Triggered by** | Agent auto-loads when task matches `description`; also invokable via `/name` | You invoke explicitly via `/name` |
| **Best for** | Context the agent should apply proactively; multi-file playbooks | Deliberate one-shot workflows; stable `/` menu entries |
| **Supporting files** | Yes — keep templates/scripts alongside `SKILL.md` | Single markdown file (use subdirs for namespacing) |
| **Examples here** | `flutter-standards`, `requesting-code-review`, `speckit-*` | `/code-review` |

### Code review (local + CI)

- **Subagent:** `.agents/agents/code-reviewer.md` — readonly reviewer for git diffs (works with
  [superpowers](https://github.com/obra/superpowers) `requesting-code-review` skill)
- **Command:** `/code-review` — explicit trigger that dispatches the subagent
- **Criteria:** `.agents/review/criteria.md` — shared checklist used by the subagent and by
  `.github/workflows/cursor-code-review.yml` on every PR

Do not reuse the same name for a skill directory and a command file (Claude Code gives the skill
precedence). For manual-only workflows you can use either a command or a skill with
`disable-model-invocation: true` in frontmatter — pick one per workflow.

### Extending the setup

- **New skill** → `.agents/skills/<name>/SKILL.md`
- **New command** → `.agents/commands/<name>.md` (subdirs for namespaced commands, e.g.
  `test/integration.md` → `/test:integration`)
- **New subagent** → `.agents/agents/<name>.md`
- **New MCP server** → add to `.mcp.json` only. Never commit API keys; use `${env:VAR}` references
  or local override files.
- **New always-on instruction** → add to `AGENTS.md` if it applies to every task; otherwise
  create a skill (auto-discovery) or a command (manual trigger).
- **New agent tool** → if it reads `AGENTS.md`, `.agents/skills/`, or `.agents/commands/` natively,
  nothing to do; otherwise add a symlink from the tool's expected path to the canonical directory.

> **Windows note:** symlinks require Developer Mode or `git config core.symlinks true`. On WSL2/Linux
> this works out of the box. If a Windows-native checkout cannot use symlinks, replace the
> `CLAUDE.md` symlink with a real file containing `@AGENTS.md` on its own line.

## Claude Code / Android MCP Setup

The project ships with an Android MCP server (`.mcp.json`) that lets AI agents take
screenshots, interact with the emulator, and run ADB commands via
[`@mobilenext/mobile-mcp`](https://github.com/mobile-next/mobile-mcp).

### Prerequisites

- **Node.js** with `npx` on your PATH (install via [nvm](https://github.com/nvm-sh/nvm) or your system package manager)
- **ANDROID_HOME** pointing to your Android SDK (e.g. `export ANDROID_HOME=~/Android/Sdk`)
- An Android emulator or device visible to ADB

The script at `tool/agents/android-mcp.sh` resolves `ANDROID_HOME` from your environment
(defaulting to `~/Android/Sdk` if unset) and loads nvm automatically if `npx` is not on
your PATH. No hardcoded paths — it works on any machine.

> **WSL2 note:** If the emulator runs on the Windows host (the setup described in the
> [Emulated Device Setup](#emulated-device-setup) section above), the script reads the
> Windows host IP from the default gateway at runtime and points ADB at the Windows ADB
> server on port 5037. No extra configuration is needed beyond what that section describes.

## Running the App

```bash
flutter run -d emulator-5554
```

## Other Useful Commands

```bash
flutter build apk          # Build release APK
flutter build apk --debug  # Build debug APK
flutter test               # Run all tests
flutter analyze            # Run static analysis
```
