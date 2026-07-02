#!/usr/bin/env bash
set -euo pipefail

# Validates CURSOR_MODEL against the account's live CLI model list.
# "auto" is always accepted. Prints the resolved model to stdout.

REQUESTED="${CURSOR_MODEL:-auto}"

if command -v agent >/dev/null 2>&1; then
  AGENT_BIN=agent
elif command -v cursor-agent >/dev/null 2>&1; then
  AGENT_BIN=cursor-agent
else
  echo "Cursor agent CLI not found. Install it before resolving the model." >&2
  exit 1
fi

list_models() {
  if [ "$AGENT_BIN" = "agent" ]; then
    agent models
  else
    cursor-agent --list-models
  fi
}

if [ "$REQUESTED" = "auto" ]; then
  echo "auto"
  exit 0
fi

RAW_LIST="$(list_models)"
# Strip "(default)" / "(current)" suffixes; keep the first token on each line.
mapfile -t AVAILABLE_MODELS < <(
  printf '%s\n' "$RAW_LIST" \
    | sed -E 's/[[:space:]]*\((default|current)\)[[:space:]]*$//' \
    | awk 'NF { print $1 }' \
    | grep -E '^[A-Za-z0-9][A-Za-z0-9._-]*$' \
    | sort -u
)

for model in "${AVAILABLE_MODELS[@]}"; do
  if [ "$model" = "$REQUESTED" ]; then
    echo "$REQUESTED"
    exit 0
  fi
done

echo "Unknown Cursor model: ${REQUESTED}" >&2
echo "Available models for this account:" >&2
printf '  - %s\n' "${AVAILABLE_MODELS[@]}" >&2
exit 1
