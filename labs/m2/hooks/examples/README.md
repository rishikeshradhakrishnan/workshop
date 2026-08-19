# Hook examples (Module 2, Concepts Part B and stretch goals)

| File | Event / type | Used in |
|---|---|---|
| `../protect-files.sh` (`.ps1`) | `PreToolUse` command, exit 2 blocks edits to generated/sensitive paths | Lab Part B (installed to `$OTEL/.claude/hooks/`) |
| `postformat.json` | `PostToolUse` command with `if` filters — gofmt / prettier after edits | Concepts example 2 |
| `scan-prompt.sh` + `scan-prompt.settings.json` | `UserPromptSubmit` command, rejects prompts containing credentials | Concepts example 3 |
| `http.json` | `PostToolUse` http handler → audit endpoint (`allowedHttpHookUrls`, `allowedEnvVars`) | Concepts example 4, lab step 6 |
| `stop-prompt.json` | `Stop` prompt handler — "don't stop until the tests ran" | Concepts example 5, lab step 6 |
| `sessionstart-gitlog.sh` + `.settings.json` | `SessionStart` context injection (branch + last commits) | Stretch (d) |
| `protect-files-ask.sh` | `PreToolUse` JSON `permissionDecision: "ask"` variant | Stretch (c) |

All `.settings.json` snippets are meant to be **merged** into the `"hooks"` block of `.claude/settings.json`
(hooks merge across scopes; they are never standalone files). Scripts must be executable (`chmod +x`).
