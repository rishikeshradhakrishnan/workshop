#!/usr/bin/env bash
# PreToolUse hook (matcher: "Bash") — Module 7 stretch (d): deny the classic "curl … | sh" bootstrap that prompt
# injections love (T1). Emits a JSON permissionDecision instead of exit 2 so the reason is structured.
# Register in .claude/settings.json:
#   "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command",
#      "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-curl-pipe-sh.sh" }]}]
# A denying hook wins over any allow rule; deny/ask RULES still apply regardless of a hook's "allow".
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
  CMD=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -n1)
fi
[ -z "$CMD" ] && exit 0
# curl|wget ... piped (possibly via tee/sudo) into a shell interpreter, or bash <(curl ...), or sh -c "$(curl ...)"
if printf '%s' "$CMD" | grep -Eiq '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da|k)?sh\b|(ba|z)?sh[[:space:]]+<\((curl|wget)|(ba|z)?sh[[:space:]]+-c[[:space:]]+"?\$\((curl|wget)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"curl|sh is blocked by policy: download the script to a file, read it, then run it explicitly if it is safe."}}
JSON
  exit 0
fi
exit 0
