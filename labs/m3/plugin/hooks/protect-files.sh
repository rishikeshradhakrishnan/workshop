#!/usr/bin/env bash
# PreToolUse guardrail for Edit|Write|MultiEdit: refuse edits to generated or sensitive files.
# Input: hook JSON on stdin. Output: exit 2 + stderr message (fed back to Claude) to block.
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
else  # pure-bash fallback when jq is missing
  FILE_PATH=$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
fi
FILE_PATH="${FILE_PATH//\\//}"          # normalise Windows backslashes
[ -z "$FILE_PATH" ] && exit 0            # not a file tool call: allow

PROTECTED_PATTERNS=(".env" "_pb2.py" ".pb.go" "pb/" "package-lock.json")
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'. Generated protobuf code, lockfiles and .env files are never hand-edited in this repo; change the source (.proto / package.json) or ask the user." >&2
    exit 2
  fi
done
exit 0
