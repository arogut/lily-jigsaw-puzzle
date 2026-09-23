#!/usr/bin/env bash
# Format Dart files after Agent edits. Fail-open: never block the agent.
set -u

input=$(cat)

file_path=$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
path = data.get("file_path") or ""
print(path)
' <<<"$input" 2>/dev/null || true)

if [[ -z "${file_path}" || "${file_path}" != *.dart ]]; then
  exit 0
fi

if [[ ! -f "${file_path}" ]]; then
  exit 0
fi

if ! command -v dart >/dev/null 2>&1; then
  exit 0
fi

dart format "${file_path}" >/dev/null 2>&1 || true
exit 0
