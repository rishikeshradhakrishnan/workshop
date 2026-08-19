#!/usr/bin/env bash
# SessionStart hook: inject the current branch and last five commits as additional context.
# Register: { "hooks": { "SessionStart": [ { "matcher": "startup|resume", "hooks": [
#   { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/sessionstart-gitlog.sh", "timeout": 10 } ] } ] } }
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
LOG=$(git log -5 --oneline 2>/dev/null) || exit 0
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
jq -n --arg log "$LOG" --arg br "$BRANCH" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:("Current branch: "+$br+"\nRecent commits:\n"+$log)}}'
