#!/usr/bin/env bash
# UserPromptSubmit hook: reject (exit 2) prompts that appear to contain a credential.
# Register: { "hooks": { "UserPromptSubmit": [ { "hooks": [ { "type": "command",
#   "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/scan-prompt.sh", "timeout": 5 } ] } ] } }
PROMPT=$(jq -r '.prompt // empty')
if printf '%s' "$PROMPT" | grep -Eq 'sk-ant-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  echo "Prompt rejected by project hook: it appears to contain a credential. Reference the secret by name (env var / vault path) instead of pasting it." >&2
  exit 2
fi
exit 0
