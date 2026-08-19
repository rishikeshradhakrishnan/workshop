#!/usr/bin/env bash
# ConfigChange hook (matcher: "project_settings|local_settings") — Module 7 stretch (e): settings drift alarm.
# Appends every change to .claude/config-audit.log and BLOCKS (exit 2) a change that removes a permissions.deny rule.
# Register: "ConfigChange": [{ "matcher": "project_settings|local_settings", "hooks": [{ "type": "command",
#             "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/config-change-audit.sh" }]}]
INPUT=$(cat)
LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/config-audit.log"
mkdir -p "$(dirname "$LOG")"
printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$(printf '%s' "$INPUT" | jq -c '{source: .source, file: .file_path}' 2>/dev/null || echo "$INPUT")" >> "$LOG"
command -v jq >/dev/null 2>&1 || exit 0
FILE=$(printf '%s' "$INPUT" | jq -r '.file_path // empty')
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0
# Compare the deny list now on disk with the last snapshot we took of this file.
SNAP="${CLAUDE_PROJECT_DIR:-.}/.claude/.deny-snapshot-$(printf '%s' "$FILE" | tr '/' '_')"
NOW=$(jq -c '.permissions.deny // [] | sort' "$FILE" 2>/dev/null || echo '[]')
if [ -f "$SNAP" ]; then
  BEFORE=$(cat "$SNAP")
  REMOVED=$(jq -cn --argjson b "$BEFORE" --argjson n "$NOW" '$b - $n')
  if [ "$REMOVED" != "[]" ]; then
    printf '%s deny rules removed: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$REMOVED" >> "$LOG"
    echo "Blocked settings change: it removes deny rule(s) $REMOVED from $FILE. Restore them or make this change outside the agent session." >&2
    exit 2
  fi
fi
printf '%s' "$NOW" > "$SNAP"
exit 0
