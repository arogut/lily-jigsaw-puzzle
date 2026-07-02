#!/usr/bin/env bash
set -euo pipefail

CONFIG_SOURCE="${1:?config source path required}"
PROMPT_TEMPLATE="${2:?prompt template path required}"

test -n "${CURSOR_API_KEY:-}" || {
  echo "CURSOR_API_KEY is missing. Add it in repository secrets before running Cursor workflows."
  exit 1
}

mkdir -p .cursor
cp "$CONFIG_SOURCE" .cursor/cli.json

if command -v agent >/dev/null 2>&1; then
  AGENT_BIN=agent
elif command -v cursor-agent >/dev/null 2>&1; then
  AGENT_BIN=cursor-agent
else
  echo "Cursor agent CLI not found after installation."
  exit 1
fi

export REPO EVENT_NAME ACTOR ISSUE_NUMBER PR_NUMBER PR_HEAD_SHA PR_BASE_SHA
PROMPT="$(envsubst < "$PROMPT_TEMPLATE")"

if [ -f .github/cursor/.event-context.txt ]; then
  PROMPT="${PROMPT}

## Event context

$(cat .github/cursor/.event-context.txt)"
fi

if [ "$AGENT_BIN" = "agent" ]; then
  agent -p "$PROMPT" --model auto --force
else
  cursor-agent --force --model auto --output-format=text --print "$PROMPT"
fi
