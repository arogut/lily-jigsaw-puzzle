# Agent-Agnostic Setup Plan

Goal: one canonical set of AI-agent configuration (instructions, skills, MCP servers) that works
identically for Claude Code, Cursor, and any future tool — with zero content duplication.
Tool-specific files are reduced to thin *adapters* (symlinks or one-line imports) that point at
the canonical files.

## Guiding principles

1. **Single source of truth.** Every piece of agent configuration lives in exactly one
   vendor-neutral file/directory. Nothing is ever copy-pasted into a tool-specific location.
2. **Standards first.** Use the emerging cross-tool conventions: `AGENTS.md` for instructions,
   `.agents/skills/` for skills (the Agent Skills open standard), `mcpServers`-keyed JSON for MCP.
3. **Thin adapters for laggards.** Where a tool doesn't read the standard location (today: Claude
   Code), bridge with a symlink or a one-line import — never a copy.
4. **Genuinely tool-specific config stays tool-specific.** Permission allowlists, hooks, CI
   runners etc. have no shared format; keep them small and in their native locations.

## Current state (inventory)

| Item | Location | Problem |
|---|---|---|
| Agent instructions | `CLAUDE.md` (root) | Claude-branded filename; Cursor/others prefer `AGENTS.md` |
| Skills (10× speckit) | `.claude/skills/` | Vendor directory; works in Cursor only via compatibility fallback |
| MCP servers | `.mcp.json` (root) | Claude Code's location; Cursor expects `.cursor/mcp.json` |
| MCP helper script | `.claude/android-mcp.sh` | Vendor directory for a tool-neutral script |
| Claude permissions | `.claude/settings.json` | Fine — genuinely Claude-specific |
| Local overrides | `.claude/settings.local.json` (gitignored) | Fine |
| Spec Kit context target | `.specify/extensions/agent-context/agent-context-config.yml` → `context_file: CLAUDE.md` | Writes the managed block into the vendor file |
| `.gitignore` | ignores all of `.cursor/` | Prevents committing any shared project-level Cursor config |
| CI agents | `.github/cursor/`, `.github/workflows/` | Fine — CI is inherently per-runner |

## Compatibility facts this plan relies on (verified Jul 2026)

- **Instructions:** Cursor, Codex, Copilot, Windsurf, Cline read root `AGENTS.md` natively.
  Claude Code reads only `CLAUDE.md`; the supported bridge is a symlink or a `@AGENTS.md` import.
- **Skills:** Cursor loads skills from `.agents/skills/`, `.cursor/skills/`, and (for
  compatibility) `.claude/skills/` — project and user level. Claude Code loads only
  `.claude/skills/` (`.agents/skills/` support is a long-open feature request), so a symlink
  bridge is needed.
- **MCP:** Claude Code reads root `.mcp.json`; Cursor reads `.cursor/mcp.json`. Both use the same
  JSON shape with the `mcpServers` root key, so a symlink shares one file.
- **Commands vs skills:** both tools now treat skills as a superset of slash commands. New
  reusable prompts should be skills, not `.claude/commands/` / `.cursor/commands/` entries.

## Target layout

```
AGENTS.md                          # canonical instructions (content moved from CLAUDE.md)
CLAUDE.md                          # adapter: symlink → AGENTS.md
.agents/
  skills/                          # canonical skills (speckit-* moved here; all future skills here)
    speckit-plan/SKILL.md
    ...
.claude/
  skills                           # adapter: symlink → ../.agents/skills
  settings.json                    # Claude-only: permissions (stays)
  settings.local.json              # Claude-only, gitignored (stays)
.mcp.json                          # canonical MCP config (mcpServers key)
.cursor/
  mcp.json                         # adapter: symlink → ../.mcp.json
tool/agents/
  android-mcp.sh                   # moved out of .claude/ (tool-neutral helper script)
```

Everything under "adapter" is a committed symlink (fine on WSL2/Linux and in git; see risks for
Windows note).

## Migration steps

Each step is independently verifiable; do them in order.

### Phase 1 — Instructions

1. `git mv CLAUDE.md AGENTS.md`, then edit the intro: remove "guidance to Claude Code" phrasing,
   make it tool-neutral ("instructions for AI coding agents working in this repository").
2. `ln -s AGENTS.md CLAUDE.md` and commit the symlink.
   - Alternative if Claude-specific instructions are ever needed: make `CLAUDE.md` a real file
     containing only `@AGENTS.md` plus the Claude-only notes. Start with the symlink; switch to
     the import only when a real need appears.
3. Update Spec Kit: set `context_file: AGENTS.md` in
   `.specify/extensions/agent-context/agent-context-config.yml` so the managed
   `<!-- SPECKIT START/END -->` block is written to the canonical file.
4. **Verify:** run `.specify/extensions/agent-context/scripts/bash/update-agent-context.sh` and
   confirm the block lands in `AGENTS.md`; open the repo in Cursor and in Claude Code and confirm
   both pick up the instructions (Claude Code: `/memory` shows the file; Cursor: rules panel
   lists `AGENTS.md`).

Note: Cursor reads both `AGENTS.md` and `CLAUDE.md` if present. With the symlink they are the
same content, so the worst case is a harmless duplicate load.

### Phase 2 — Skills

1. `mkdir -p .agents && git mv .claude/skills .agents/skills`.
2. `ln -s ../.agents/skills .claude/skills` and commit the symlink.
3. **Verify:** in Cursor, the `speckit-*` skills appear in the skills list; in Claude Code,
   `/skills` (or invoking `speckit-plan`) still works via the symlinked directory.

### Phase 3 — MCP

1. Keep `.mcp.json` at the root as the canonical file (both tools use the `mcpServers` root key,
   so no content change is needed).
2. Move the helper script: `git mv .claude/android-mcp.sh tool/agents/android-mcp.sh` and update
   the `args` path in `.mcp.json`. This keeps `.claude/` free of anything that isn't genuinely
   Claude-specific.
3. In `.gitignore`, replace the blanket `.cursor/` ignore with granular entries so shared config
   can be committed while local state stays out:

   ```gitignore
   # Cursor: ignore local state, keep shared project config
   .cursor/*
   !.cursor/mcp.json
   ```

4. `mkdir -p .cursor && ln -s ../.mcp.json .cursor/mcp.json` and commit the symlink.
5. **Verify:** Cursor Settings → MCP shows the `android` server; Claude Code `/mcp` shows it too.
   Secrets rule going forward: never put keys in `.mcp.json`; use `${env:VAR}`-style references
   or local override files.

### Phase 4 — Documentation & guardrails

1. Add a short "AI agent setup" section to `README.md` (or the top of `AGENTS.md`) stating the
   convention: canonical files are `AGENTS.md`, `.agents/skills/`, `.mcp.json`; everything
   tool-specific is an adapter; never edit `CLAUDE.md`/`.claude/skills`/`.cursor/mcp.json`
   directly (they are symlinks).
2. Update the repo inventory in `AGENTS.md` architecture notes if it references old paths.

## Conventions when extending the setup later

- **New skill** → create `.agents/skills/<name>/SKILL.md`. It is instantly available to Cursor
  (native) and Claude Code (via the symlink). Same for supporting files inside the skill folder.
- **New slash command** → prefer a skill (add `disable-model-invocation: true` in the frontmatter
  if it should only run when explicitly invoked). Avoid `.claude/commands/` / `.cursor/commands/`.
- **New MCP server** → add to `.mcp.json` only.
- **New instruction/rule** → add to `AGENTS.md`. Only create `.cursor/rules/` or Claude-specific
  content for behavior that genuinely differs per tool (rare).
- **Personal (user-level) setup, optional:** apply the same pattern in `$HOME` — keep personal
  skills in `~/.agents/skills/` (Cursor reads it natively) and symlink
  `~/.claude/skills → ~/.agents/skills` for Claude Code. Do this only if/when you start keeping
  personal cross-project skills.

## Onboarding a future agent tool

Checklist, in order of likelihood:

1. Does it read `AGENTS.md`? (Most 2026 tools do.) → nothing to do.
2. Does it read `.agents/skills/` or `.claude/skills/`? → nothing to do.
3. Otherwise, add one adapter: a symlink or a one-line import from the tool's expected location
   to the canonical file. Never copy content.
4. Tool-specific extras (permissions, hooks, sandbox settings) go in the tool's own directory and
   stay minimal.

## What deliberately stays tool-specific

- `.claude/settings.json` / `settings.local.json` — permission allow/deny lists have no shared
  format across tools.
- `.github/cursor/` + `.github/workflows/cursor*.yml` — CI runner wiring.
- Any future hooks (`.claude/hooks`, `.cursor/hooks.json`) — incompatible event models.

## Risks & mitigations

- **Symlinks on Windows checkouts:** require Developer Mode or `core.symlinks=true`. You develop
  in WSL2 so this is a non-issue today; if a Windows-native contributor ever appears, switch the
  `CLAUDE.md` symlink to the `@AGENTS.md` import file (the skills symlink has no import
  equivalent — that contributor would enable symlinks).
- **Claude Code adds native `.agents/skills/`/`AGENTS.md` support later:** the adapters simply
  become removable; nothing else changes. This is the payoff of making the standard locations
  canonical now.
- **Cursor drops `.claude/` compatibility fallback:** irrelevant after Phase 2, since the
  canonical location is already `.agents/skills/`.
- **Spec Kit regeneration:** if Spec Kit is ever re-initialized it may recreate
  `.claude/skills/speckit-*` as real directories. The symlink makes writes land in
  `.agents/skills/` anyway; if a tool replaces the symlink with a directory, re-run Phase 2
  steps 1–2.

## Definition of done

- [ ] `AGENTS.md` is the only instruction file with content; `CLAUDE.md` is a symlink.
- [ ] `.agents/skills/` is the only skills directory with content; `.claude/skills` is a symlink.
- [ ] `.mcp.json` is the only MCP config with content; `.cursor/mcp.json` is a symlink.
- [ ] Spec Kit `context_file` points at `AGENTS.md` and its update script works.
- [ ] Both Claude Code and Cursor load instructions, all 10 speckit skills, and the `android`
      MCP server — confirmed by opening each tool once.
- [ ] `grep -r "CLAUDE.md" --include="*.sh" --include="*.yml" .specify/ .github/` shows no script
      still hard-coded to the old file (or the hits are intentional).
