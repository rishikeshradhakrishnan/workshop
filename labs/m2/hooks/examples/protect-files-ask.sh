#!/usr/bin/env bash
# Stretch (c): variant of protect-files.sh that ASKS instead of blocking, via a JSON permissionDecision.
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
FILE_PATH="${FILE_PATH//\\//}"
[ -z "$FILE_PATH" ] && exit 0
PROTECTED_PATTERNS=(".env" "_pb2.py" ".pb.go" "pb/" "package-lock.json")
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    jq -n --arg f "$FILE_PATH" --arg p "$pattern" '{hookSpecificOutput:{hookEventName:"PreToolUse",
      permissionDecision:"ask",
      permissionDecisionReason:("\($f) matches protected pattern \($p) - confirm you really intend to hand-edit it")}}'
    exit 0
  fi
done
exit 0
