# Module 2 — Extending Claude Code I: settings & permissions, hooks, MCP

> **Time box:** 09:55–10:40 (45 min) · **Format:** talk/demo 12 · lab 28 · debrief 5 · **Checkpoint in:** CP1 · **Checkpoint out:** CP2

Conventions: `$WS` = your clone of the workshop repo, `$OTEL` = your clone of `<WORKSHOP_ORG>/opentelemetry-demo` (both exported by `labs/.env`). "Ref §X" points at an appendix in `reference/Technical-Reference-v4.md`. Everything version-specific here was verified against current Claude Code documentation as of August 2026; volatile items carry **[verify-on-day]**.

## Why this matters

In Module 1 you *told* Claude how to behave with `CLAUDE.md` and rules. That is advice: the model reads it and usually complies. This module is about the three mechanisms that Claude Code itself **enforces or executes**, regardless of what the model decides:

- **Settings & permission rules** decide what a tool call is *allowed* to do (and the Bash sandbox makes the OS enforce part of it).
- **Hooks** run *your* code at fixed lifecycle points — deterministically, every time — so "always format after an edit" or "never touch generated code" stops depending on the model remembering.
- **MCP servers** give Claude new tools and data sources, at the scope you choose, under the same permission system.

These three files — `.claude/settings.json`, `.claude/hooks/*`, `.mcp.json` — are also exactly what you will bundle into a plugin in Module 3, mirror in code with the Agent SDK in Module 5, and harden in Module 7. Build them carefully now; you reuse them all day.

## Learning objectives

By 10:40 you can:

1. Explain settings scopes and precedence (managed > CLI flags > local > project > user), the difference between `settings.json` and `settings.local.json`, and the **deny → ask → allow** evaluation order.
2. Write permission rules with correct syntax — `Bash(npm run test *)`, `Read(./.env*)`, `WebFetch(domain:…)`, `mcp__server__tool`, `Agent(name)` — and set `permissions.defaultMode`.
3. Turn on the Bash sandbox and state what it does and does not isolate (Bash and its child processes: yes; Claude's file tools, MCP servers, hooks: no).
4. Author hooks: the config schema, matchers, the `command` handler type, the stdin JSON contract, exit-code-2-blocks semantics and the JSON `permissionDecision` output; recognise the other handler types (`http`, `mcp_tool`, `prompt`, `agent`) and the size of the event catalogue (about 30 events; Ref §E).
5. Add MCP servers at the right scope with `claude mcp add` (stdio vs HTTP; `--scope project` → `.mcp.json`; env-var expansion; OAuth via `/mcp`), understand tool search / deferred loading and its context cost, and apply the trust rule "only servers you would run as yourself".

## Concepts (instructor talk track)

### Part A — Settings and permissions (4 min)

**Where settings live.** One JSON format, five places. Location decides scope:

| Scope | File / source | Affects | Shared? |
|---|---|---|---|
| Managed | Server-managed settings from the Claude admin console, MDM/registry policy, or `managed-settings.json` (macOS `/Library/Application Support/ClaudeCode/`, Linux/WSL `/etc/claude-code/`, Windows `C:\Program Files\ClaudeCode\`) | Everyone in the org / on the machine | Deployed by IT; cannot be overridden |
| CLI | `--settings <file-or-json>`, `--setting-sources`, `--permission-mode`, `--allowedTools` … | This launch only | n/a |
| Local | `.claude/settings.local.json` (at the repo root; auto-added to your global git excludes) | You, in this repo | No |
| Project | `.claude/settings.json` | Every collaborator | Yes — commit it |
| User | `~/.claude/settings.json` | You, in every project | No |

**Precedence** (highest first): managed > command-line arguments > local > project > user. Scalars: the higher scope wins. **Arrays such as `permissions.allow/ask/deny` concatenate across scopes** — a lower scope can add rules but never remove one, and a `deny` at *any* level blocks. Files are watched and hot-reloaded (a `ConfigChange` hook event fires per change). Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for editor validation. `~/.claude.json` is *not* a settings file (it holds login state, per-project trust, and user/local-scope MCP servers) — `permissions`, `hooks`, and `env` placed there are silently ignored.

**What prompts by default** (Manual / `default` mode): reads inside the working directory are free; Bash (except a small read-only set such as `ls`, `cat`, `git status`), file edits, WebFetch and WebSearch prompt. "Yes, and don't ask again" for a Bash command is saved as an allow rule in `.claude/settings.local.json`.

**Evaluation order: deny → ask → allow; the first match wins regardless of specificity.** A broad `deny` (`Bash(aws *)`) cannot be pierced by a narrow `allow` (`Bash(aws s3 ls)`), and an `ask` beats a more specific `allow`. Say this sentence out loud — it is the single most useful fact in the module: *permission rules are enforced by Claude Code, not by the model. `CLAUDE.md` shapes what Claude tries; rules decide what is allowed.*

**Rule grammar** — `Tool` or `Tool(specifier)`:

| Rule | Matches | Notes |
|---|---|---|
| `Bash` or `Bash(*)` | every Bash command | a bare-name **deny** removes the tool from Claude's context entirely |
| `Bash(npm run build)` | exactly that command | |
| `Bash(npm run test *)` | `npm run test`, `npm run test -- -u` … | space before `*` = word boundary (`Bash(ls *)` matches `ls -la`, not `lsof`). Legacy `Bash(npm test:*)` means the same as `Bash(npm test *)`; `:*` is only recognised at the end |
| `Bash(git * main)`, `Bash(* --version)` | `*` anywhere, spans arguments | compound commands (`&&`, `\|`, `;`, pipes) are split and **each part must match** — `Bash(safe-cmd *)` never authorises `safe-cmd && other-cmd` |
| `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)` | gitignore-style paths; `./` or bare = relative to cwd, `/path` = relative to the settings file's root, `~/` = home, `//abs` = filesystem root | a `Read` deny also blocks `Edit`/`Write` on that path. Only `Read(...)` and `Edit(...)` take path specifiers (`Edit` covers all built-in editing tools) |
| `Edit(/src/**/*.ts)` | edits under `<project>/src` | `*` one segment, `**` recursive |
| `WebFetch(domain:example.com)`, `WebFetch(domain:*.example.com)` | that host / its subdomains only | prefer this over fragile `Bash(curl https://… *)` argument rules — deny `curl`/`wget` instead |
| `mcp__github`, `mcp__github__*`, `mcp__github__get_issue` | all tools of a server / one tool | deny/ask accept globs like `"mcp__*"`; allow globs only after a literal `mcp__<server>__` prefix |
| `Agent(Explore)`, `Agent(bug-hunter)` | a subagent type | deny to disable a subagent (Module 3) |
| `Skill(deploy)`, `Skill(review-pr *)` | a skill, optionally with args | |

Path rules apply to Claude's built-in file tools (and recognised file commands like `cat`), **not** to arbitrary subprocesses — `python -c 'open(".env")'` is a Bash call. That gap is what the sandbox closes.

**Permission modes recap** (taught in M1; full matrix Ref §D.2). Set with `permissions.defaultMode`, `--permission-mode`, or `Shift+Tab`:

| Mode | Runs without asking | How rules interact |
|---|---|---|
| `default` ("Manual") | reads | allow rules skip prompts; ask forces one; deny blocks |
| `acceptEdits` | reads + edits + common file commands in the working dir | same |
| `plan` | reads (plus classifier-approved exploration where auto mode is available) | no source edits until you approve the plan |
| `auto` | everything a background classifier judges in-scope | rules resolve **first**; on entering auto mode broad allow rules (`Bash(*)`, wildcarded interpreters, package-manager `run *`, `Agent`) are **dropped**, narrow ones like `Bash(go test *)` carry over; an `ask` rule is your durable human checkpoint (conversation-stated boundaries can be lost to compaction). `"defaultMode": "auto"` is ignored in project/local settings — a repo cannot opt you into it |
| `dontAsk` | only what allow rules, the read-only set, or a hook explicitly allow; everything else is auto-denied | the CI/headless mode (Module 4) — your allow list *is* the policy |
| `bypassPermissions` | everything, including protected paths | deny rules and ask rules still apply; containers/VMs only; block org-wide with `permissions.disableBypassPermissionsMode: "disable"` |

As of August 2026, new sessions on Pro/Max/Team plans start in `auto`; Console API-key and Enterprise sessions start in `default`. That is why the lab file pins `"defaultMode": "default"` — the room behaves uniformly.

**Sandbox in one breath.** `/sandbox` (or `"sandbox": {"enabled": true}`) makes the **operating system** confine every Bash command and its children: writes only inside the working directory and a session temp dir, reads everywhere except paths you `denyRead`, and **no network host is pre-allowed** (a proxy outside the sandbox enforces `network.allowedDomains` plus your `WebFetch(domain:…)` rules). macOS uses Seatbelt (nothing to install); Linux and WSL2 need `bubblewrap` and `socat`; native Windows and WSL1 are not supported. In the default *auto-allow* sandbox mode, sandboxable Bash commands run **without a prompt** even in Manual mode — deny rules, content-scoped ask rules like `Bash(git push *)`, and dangerous `rm` still gate. If a command fails on a sandbox violation Claude may retry it unsandboxed via `dangerouslyDisableSandbox`, which goes through the normal prompt/classifier; forbid that with `"allowUnsandboxedCommands": false`. What the sandbox does **not** cover: Claude's own Read/Edit/Write tools (permission rules cover those), MCP servers, and hooks — they run as you. Full key list: Ref §D.5.

**Environment variables worth knowing today** (about 330 exist; Ref §C.7). Set them in the shell, or persist them for every session under `"env"` in any settings file:

| Variable | Why you would touch it in this workshop |
|---|---|
| `ANTHROPIC_API_KEY` | API-key auth; silently overrides a subscription login in `-p` — `unset` it if `/status` shows the wrong account |
| `ANTHROPIC_MODEL`, `CLAUDE_CODE_EFFORT_LEVEL`, `CLAUDE_CODE_SUBAGENT_MODEL` | pin model / effort / subagent model for a session or CI job |
| `CLAUDE_CONFIG_DIR` | relocate `~/.claude` (clean-room debugging, two accounts side by side) |
| `BASH_DEFAULT_TIMEOUT_MS`, `BASH_MAX_OUTPUT_LENGTH` | long test suites, chatty builds |
| `MCP_TIMEOUT`, `MAX_MCP_OUTPUT_TOKENS`, `ENABLE_TOOL_SEARCH` | MCP startup timeout (default 30 s), per-result cap (default 25 000 tokens), deferred tool loading on/off |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` | strip Anthropic/cloud credentials from Bash, hook, and stdio-MCP subprocess environments |
| `CLAUDE_CODE_ENABLE_TELEMETRY=1` + `OTEL_*` | OpenTelemetry export incl. `tool_decision` events (Module 7 stretch) |
| `HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS` | corporate proxies (Ref §J) |
| `CLAUDE_PROJECT_DIR`, `CLAUDE_CODE_SESSION_ID`, `CLAUDECODE=1` | *set by* Claude Code inside hook and Bash subprocesses — use them in scripts |

**Enterprise sentence.** Everything above can be imposed centrally: managed settings win over all scopes, and managed-only keys such as `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`, `allowManagedMcpServersOnly` and `strictKnownMarketplaces` turn "team convention" into "policy" (Ref §D.4; revisited in M7/M8).

### Part B — Hooks (4 min)

**Concept.** A hook is *your* handler that Claude Code runs at a lifecycle **event**, filtered by a **matcher**, implemented by a **handler** of one of five types. Hooks are deterministic: a `CLAUDE.md` line "run gofmt after editing Go" is a request; a `PostToolUse` hook is a guarantee. Hooks live inside the `"hooks"` key of any settings file (user/project/local/managed), in a plugin's `hooks/hooks.json` (Module 3), or in skill/subagent frontmatter. They **merge** across scopes (all matching hooks fire, in parallel), hot-reload when the file changes, also fire inside subagents, and run with **your full user permissions** — review them like code. `/hooks` is a read-only viewer; you edit JSON (or ask Claude to).

**Shape** — event → matcher group → handler list:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh",
            "timeout": 30,
            "statusMessage": "Checking protected paths…" }
        ]
      }
    ]
  }
}
```

**The event catalogue** (31 events as of August 2026 — full I/O per event in Ref §E.3–§E.4):

| Cadence | Events |
|---|---|
| Once per session | `SessionStart` (matcher: `startup\|resume\|clear\|compact\|fork`), `SessionEnd`, `Setup` (only with `--init`/`--maintenance`) |
| Once per turn | `UserPromptSubmit`, `UserPromptExpansion` (a typed `/skill` expands), `Stop`, `StopFailure` (turn ended on an API error) |
| Every tool call | `PreToolUse`, `PermissionRequest` (a prompt is about to show), `PermissionDenied` (auto-mode classifier said no), `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` (all parallel calls in a batch resolved) |
| Agents & tasks | `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle` |
| Context & config | `PreCompact`, `PostCompact`, `InstructionsLoaded` (a CLAUDE.md/rule file loaded), `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged` |
| Environment & UI | `Notification`, `MessageDisplay`, `WorktreeCreate`, `WorktreeRemove`, `Elicitation`, `ElicitationResult` (MCP user-input requests) |

The ones you will actually write this year:

| Event | Fires | Matcher filters on | Can block? | Typical use |
|---|---|---|---|---|
| `PreToolUse` | before a tool executes | tool name (`Bash`, `Edit`, `Write`, `Read`, `WebFetch`, `Agent`, `mcp__…`) | **Yes** — exit 2 or `permissionDecision` | guardrails, input rewriting |
| `PostToolUse` | after a tool succeeded | tool name | feedback only (tool already ran) | format, lint, audit, inject context |
| `UserPromptSubmit` | you press Enter, before Claude sees it | — | Yes (blocks and erases the prompt) | secret scanning, context injection |
| `Stop` / `SubagentStop` | main agent / a subagent is about to finish | — / agent type | Yes (forces it to keep working) | "don't stop until tests ran" |
| `SessionStart` | session begins or resumes | source | No | inject branch/tickets/recent commits; export env via `$CLAUDE_ENV_FILE` |
| `Notification` | Claude needs you (permission prompt, idle) | notification type | No | desktop/Slack ping |
| `PreCompact` | before context compaction | `manual\|auto` | Yes | save state, veto auto-compact |

**Five handler types:**

| `type` | Runs | Decides via | Default timeout |
|---|---|---|---|
| `command` | a shell command (`sh -c`, Git Bash, or `"shell": "powershell"`); JSON on **stdin**; `"args": [...]` switches to exec form (no shell) ; `"async": true` for fire-and-forget | exit code + stdout JSON | 600 s (30 s on `UserPromptSubmit`) |
| `http` | POSTs the same JSON to `url`; `headers` may interpolate only vars listed in `allowedEnvVars` | 2xx + JSON body (a non-2xx status **never** blocks) | 600 s |
| `mcp_tool` | calls `tool` on an already-connected MCP `server` with `input` (supports `${tool_input.file_path}` substitution) | tool text output, parsed like command stdout | 600 s |
| `prompt` | one fast-model LLM call; `$ARGUMENTS` = the hook input JSON | model returns `{"ok": true\|false, "reason": "…"}` | 30 s |
| `agent` | (experimental) a subagent with Read/Grep/Glob/Bash for up to 50 turns | `{ok, reason}` | 60 s |

Common handler fields: `if` — **one** permission-rule expression (`"Bash(rm *)"`, `"Edit(**/*.go)"`) evaluated only on tool events, so cheap filtering happens before your script spawns; `timeout` (seconds); `statusMessage` (spinner text). **Matcher syntax:** `"Edit|Write"` or `"Edit, Write"` is an exact list; any other character makes it an *unanchored* JavaScript regex (`Edit.*` also matches `NotebookEdit`; anchor with `^Edit$`); `"*"`, `""` or omitted = everything; a whole MCP server is `mcp__astro-catalog__.*` (the `.*` is required). Tool names are case-sensitive.

**stdin contract** (what your script receives — `PreToolUse` on Bash shown; file tools carry an absolute `tool_input.file_path`, `PostToolUse` adds `tool_response` and `duration_ms`, `Stop` adds `stop_hook_active` and `last_assistant_message`, `UserPromptSubmit` adds `prompt`):

```json
{
  "session_id": "abc123",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/home/user/opentelemetry-demo",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "go test ./...", "description": "Run Go tests", "timeout": 120000, "run_in_background": false },
  "tool_use_id": "toolu_01ABC123..."
}
```

**Exit codes** — memorise three rows:

| Exit | Meaning |
|---|---|
| `0` | success. If stdout is a single JSON object it is parsed for decisions; plain stdout is ignored **except** on `SessionStart`/`UserPromptSubmit`, where it is added to Claude's context |
| `2` | **block** (on events that can): `PreToolUse` → call cancelled, stderr fed to Claude; `UserPromptSubmit` → prompt rejected, stderr shown to you; `Stop` → Claude must continue, stderr becomes its next instruction; `PostToolUse` → stderr shown to Claude (nothing to undo). Exit 2 wins even over a matching allow rule and even in `bypassPermissions` |
| anything else (incl. `1`, and `127` "script not found / not executable") | **non-blocking error** — a one-line `hook error` notice, and the action proceeds. A typo in a guardrail's path therefore *silently disables it*: test your hooks |

**JSON output** (exit 0, one object on stdout) is the richer channel. Universal fields: `continue` (false = stop everything), `stopReason`, `systemMessage` (warning shown to you). Event-specific fields sit under `hookSpecificOutput`; for `PreToolUse`:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "package-lock.json is generated; run npm install instead",
    "updatedInput": { "command": "npm install --package-lock-only" },
    "additionalContext": "Lockfiles in this repo are regenerated by CI."
  }
}
```

`permissionDecision` values: `allow` (skip the prompt — but deny/ask **rules** still apply, so a hook cannot launder a denied action), `deny` (reason goes to Claude), `ask` (force a prompt, even in auto mode), `defer` (headless only: the `-p` run exits with `stop_reason: "tool_deferred"` so an external system can decide and `--resume`). Several hooks on one call: **deny > defer > ask > allow**. Other events use a top-level `{"decision": "block", "reason": "…"}` (`PostToolUse`, `Stop`, `UserPromptSubmit`, `PreCompact`, `ConfigChange`) and/or `hookSpecificOutput.additionalContext` (text injected next to the tool result / prompt / session start — write it as facts, not commands).

**When a hook beats a `CLAUDE.md` line:** whenever "usually" is not good enough — generated files, secrets, formatting, audit, compliance evidence. When `CLAUDE.md` beats a hook: taste, style, priorities, anything that needs judgement. Enforce hard allow/deny with **permission rules** first (they are cheaper and cannot fail open); use hooks for logic rules cannot express.

#### Worked guardrail examples

All five live in `$WS/labs/m2/hooks/`; the first two are what you install in the lab.

**1 — Block writes to protected paths** (`PreToolUse`, `command`, exit 2). `labs/m2/hooks/protect-files.sh`:

```bash
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
```

Registered under `PreToolUse` with matcher `Edit|Write|MultiEdit` (config block in the lab). Test it without Claude:

```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/x/demo_pb2.py"}}' | .claude/hooks/protect-files.sh; echo "exit=$?"   # expect exit=2
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/checkoutservice/main.go"}}' | .claude/hooks/protect-files.sh; echo "exit=$?"   # expect exit=0
```

Windows-native participants use `labs/m2/hooks/protect-files.ps1` with `{"type": "command", "shell": "powershell", "command": "& \"$env:CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.ps1\""}` (in PowerShell hooks write `$env:CLAUDE_PROJECT_DIR`, never bare `$CLAUDE_PROJECT_DIR`).

**2 — Auto-format on edit** (`PostToolUse`, `command`, uses `if` so only matching files spawn a process):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "if": "Edit(**/*.go)",
            "command": "jq -r '.tool_input.file_path' | xargs gofmt -w", "statusMessage": "gofmt" },
          { "type": "command", "if": "Edit(**/*.ts)",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write", "timeout": 60 }
        ]
      }
    ]
  }
}
```

The tool already ran, so this cannot block; if the formatter fails, exit 2 with a message and Claude sees it next to the tool result. For slow work (a test suite) add `"async": true` — the result arrives on Claude's next turn instead of stalling this one.

**3 — Secret scan on every prompt** (`UserPromptSubmit`, `command`, exit 2 rejects and erases the prompt before the model or the transcript ever sees it). `labs/m2/hooks/examples/scan-prompt.sh`:

```bash
#!/usr/bin/env bash
PROMPT=$(jq -r '.prompt // empty')
if printf '%s' "$PROMPT" | grep -Eq 'sk-ant-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  echo "Prompt rejected by project hook: it appears to contain a credential. Reference the secret by name (env var / vault path) instead of pasting it." >&2
  exit 2
fi
exit 0
```

```json
{ "hooks": { "UserPromptSubmit": [ { "hooks": [ { "type": "command",
  "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/scan-prompt.sh", "timeout": 5 } ] } ] } }
```

(`UserPromptSubmit` has no matcher. The same regex as a `PreToolUse` hook on `Write|Edit` inspecting `.tool_input.content` / `.tool_input.new_string` stops Claude *writing* a secret into a file — that is what the security-guidance plugin in Module 7 does, with hooks exactly like these.)

**4 — Audit log to an HTTP endpoint** (`PostToolUse`, `http`). `labs/m2/hooks/examples/http.json`:

```json
{
  "allowedHttpHookUrls": ["https://hooks.example.com/*", "http://localhost:8080/*"],
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Edit|Write|mcp__.*",
        "hooks": [
          { "type": "http",
            "url": "http://localhost:8080/hooks/audit",
            "headers": { "Authorization": "Bearer $AUDIT_TOKEN" },
            "allowedEnvVars": ["AUDIT_TOKEN"],
            "timeout": 10 }
        ]
      }
    ]
  }
}
```

The endpoint receives the full event JSON (`session_id`, `tool_name`, `tool_input`, `tool_response`, `cwd`) — a ready-made audit trail for a SIEM. Rules of the `http` type: header interpolation works only for names in `allowedEnvVars` (further restricted org-wide by `httpHookAllowedEnvVars`); `allowedHttpHookUrls` is an allowlist (`[]` disables HTTP hooks entirely); to *decide* something the endpoint must answer 2xx with the same JSON a command hook would print — an HTTP 403 is just a logged error. To watch it locally: `nc -l 8080` (traditional netcat: `nc -l -p 8080`) in another terminal.

**5 — "Don't stop until the tests ran"** (`Stop`, `prompt` type; lab step 6 reads this). `labs/m2/hooks/examples/stop-prompt.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "prompt",
            "prompt": "You gate whether a coding agent may end its turn. Hook input follows: $ARGUMENTS. Read last_assistant_message. If it describes source-code changes but does not report running the matching tests (go test / npm test / pytest) after the last change, answer ok=false with a reason that tells the agent exactly which test command to run and to report the result. If stop_hook_active is true, or no code was changed, answer ok=true.",
            "timeout": 30 }
        ]
      }
    ]
  }
}
```

The fast model must return `{"ok": false, "reason": "…"}` to block; on `Stop` the reason becomes Claude's next instruction and the turn continues (a built-in cap stops endless loops, and your prompt should honour `stop_hook_active`). Swap `"type": "prompt"` for `"type": "agent"` and the verifier gets tools — it can actually run `go test ./...` before letting Claude stop (experimental, slower, costs tokens). The `command`-type equivalent prints `{"decision": "block", "reason": "Test suite must pass before finishing"}` after checking `stop_hook_active`.

> [!NOTE]
> **Instructor:** if someone asks "why not just put *run the tests* in CLAUDE.md?" — that is the debrief question for step 6. Answer: CLAUDE.md gets it right most of the time and costs nothing; the hook gets it right every time and costs a fast-model call per turn. Pick per rule, not per project.

### Part C — MCP (4 min)

**What it is.** The Model Context Protocol is the open standard for plugging tools, data sources and prompts into an AI application. Claude Code is an MCP **client** (and can be a server — below). Every MCP tool becomes a Claude tool named `mcp__<server>__<tool>`, subject to the same permission rules, hooks (`matcher: "mcp__astro-catalog__.*"`), and auto-mode classifier as built-ins.

**Adding servers** — options go **before** the name; `--` separates Claude's flags from a stdio server's own command line:

```bash
# local process over stdio (default transport) — what we use today
claude mcp add --transport stdio --scope project astro-catalog -- node $WS/labs/mcp/astro-catalog/server.mjs
# stdio with env vars for the server process (-e may repeat; keep another option between -e and the name)
claude mcp add -e AIRTABLE_API_KEY=YOUR_KEY --transport stdio airtable -- npx -y airtable-mcp-server
# remote server over streamable HTTP (recommended for remote); OAuth handled later via /mcp
claude mcp add --transport http github https://api.githubcopilot.com/mcp/        # [verify-on-day URL]
# remote with a static token header
claude mcp add --transport http secure-api https://api.example.com/mcp --header "Authorization: Bearer $TOKEN"
# SSE transport still works but is deprecated in favour of http
claude mcp add --transport sse legacy https://mcp.example.com/sse
# from a JSON blob; plus list / get / remove / reset approvals
claude mcp add-json weather '{"type":"http","url":"https://api.weather.example/mcp"}'
claude mcp list        # health: Connected / Needs authentication / Failed to connect / Pending approval
claude mcp get astro-catalog
claude mcp remove astro-catalog --scope project
claude mcp reset-project-choices
```

`claude mcp add` only writes config; it does not test the connection — `claude mcp list` or `/mcp` does.

**Scopes** (not the same files as settings scopes — note where "local" lives):

| `--scope` | Loads in | Stored in | Shared |
|---|---|---|---|
| `local` (default) | this project, only you | `~/.claude.json` under `projects["<path>"].mcpServers` | No |
| `project` | this project, whole team | **`.mcp.json` at the repo root** (not inside `.claude/`) | Yes — commit it; bundles into a plugin in M3 |
| `user` | all your projects | `~/.claude.json` top-level `mcpServers` | No |

Same name in several places: local > project > user > plugin-provided > claude.ai connectors (whole entry wins, no field merging). If you are signed in with a claude.ai plan, connectors you enabled at claude.ai also appear in `/mcp` automatically as `mcp__claude_ai_<name>__*` tools.

**`.mcp.json` shape** with environment expansion (`${VAR}` and `${VAR:-default}` work in `command`, `args`, `env`, `url`, `headers` — share config, not secrets):

```json
{
  "mcpServers": {
    "astro-catalog": {
      "type": "stdio",
      "command": "node",
      "args": ["${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs"],
      "env": { "CATALOG_CURRENCY": "${CATALOG_CURRENCY:-USD}" }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_PAT}" }
    }
  }
}
```

Per-entry extras: `timeout` (ms per tool call), `alwaysLoad`, and for HTTP an `oauth` object (`clientId`, `callbackPort`, `scopes`). A `url` entry without `"type"` is an error — always write `"type": "http"`.

**Trust gate for project servers.** Because `.mcp.json` arrives with a `git clone`, an interactive session **asks you to approve** each new project-scoped server before starting it. Pre-approve in settings with `enabledMcpjsonServers: ["astro-catalog"]` (or `enableAllProjectMcpServers: true`), block with `disabledMcpjsonServers`. Careful: `claude -p`, the Agent SDK and cloud sessions cannot prompt and **load project servers without asking** — Module 4 shows `--strict-mcp-config`, `--mcp-config`, and `--bare` for untrusted checkouts.

**OAuth.** Add the HTTP server, then inside Claude run `/mcp` → select it → **Authenticate** (browser flow; tokens are stored in the OS keychain/credentials file and refreshed automatically; `/mcp` also offers Re-authenticate / Clear authentication). From a shell: `claude mcp login <name>` (prints a URL on headless machines) and `claude mcp logout <name>`. Pre-registered apps: `--client-id … --client-secret --callback-port 8080`; pin scopes with `"oauth": {"scopes": "…"}` in the JSON. Headless runs have no OAuth UI — authenticate once interactively first.

**Using MCP inside a session.**
- `/mcp` — status, tool counts, enable/disable, reconnect, authenticate.
- Tools — just ask; approve `mcp__astro-catalog__list_products` like any tool, or allow `mcp__astro-catalog__*` in settings.
- **Resources** — type `@` and pick from the list, or write `@server:protocol://path`, e.g. "Analyze @github:issue://123 and suggest a fix"; the resource is fetched and attached.
- **Prompts** — server-published prompts become commands: `/mcp__github__pr_review 456`.
- Servers can also request input from you mid-call (elicitation dialogs) — no config needed.

**Context cost and tool search.** MCP used to be expensive: every tool schema sat in the context window whether used or not. Current Claude Code **defers** MCP tool definitions by default — only names load at startup and Claude pulls full schemas on demand through a built-in tool-search step — so twenty servers no longer cost you 30 % of the window. Knobs: `ENABLE_TOOL_SEARCH=false` loads everything up front (also the automatic fallback on some third-party providers/gateways), `"alwaysLoad": true` on a server you use every turn, `MAX_MCP_OUTPUT_TOKENS` (default 25 000; a warning appears above 10 000 tokens per result; oversized results spill to a file reference), `MCP_TIMEOUT` for slow-starting servers. Check the real numbers with `/context`. Design advice for your own servers: few tools, tight descriptions (they are truncated at 2 KB), paginated results.

**Claude Code *as* an MCP server.** `claude mcp serve` exposes Claude Code's own tools (read, edit, search, Bash …) over stdio to any MCP client — e.g. Claude Desktop:

```json
{ "mcpServers": { "claude-code": { "type": "stdio", "command": "claude", "args": ["mcp", "serve"], "env": {} } } }
```

The *client* is then responsible for confirming tool calls. Use the full path from `which claude` if the client cannot find it.

**Org control.** A `managed-mcp.json` next to `managed-settings.json` takes **exclusive** control (only its servers load; `{"mcpServers": {}}` disables MCP entirely). Softer: `allowedMcpServers` / `deniedMcpServers` entries matching `serverUrl` (wildcards) or exact `serverCommand` arrays, with `allowManagedMcpServersOnly: true`; the denylist always wins (Ref §F.7).

**Trust guidance — say it plainly.** An MCP server is a program you run with your own privileges (stdio) or a remote party you hand data to (HTTP). Anthropic does not audit third-party servers. So: prefer first-party servers from the vendor whose API it wraps, or ones you wrote; read the command line you are about to approve (`npx -y some-package` downloads and executes code); scope tokens minimally and keep them in env vars/OAuth, never in committed JSON; remember that anything a server returns — issue text, web pages, database rows — is **untrusted input** that can carry prompt injection, which is why permission rules, `ask` on write-capable MCP tools, and the sandbox still matter after you connect one. In `-p`/CI, load only the servers you name (`--strict-mcp-config`).

## Live demo script

Total 12 minutes. Run everything in `$OTEL` at CP1. Keep `Ctrl+O` (verbose transcript) handy so the room sees hook messages and MCP tool names.

**Demo 1 — Settings deny in action (4 min)**
1. Show the scope/precedence table (Ref §D.0 diagram) for 30 seconds.
2. `mkdir -p .claude && cp $WS/labs/m2/settings.project.json .claude/settings.json`; open it; read the three lists aloud; point at `"defaultMode": "default"`.
3. `[ -f .env ] || echo 'FAKE_KEY=123' > .env` (the upstream demo already ships a harmless `.env`; this only creates one if it is missing), then `claude` → "print the contents of .env". Expected: Claude reports the Read was denied by a permission rule from project settings; it may try `cat .env` via Bash — also refused (Read deny covers recognised file commands). Then "run `curl -s https://example.com`" → denied; "run git status" → runs with no prompt.
4. `/permissions` — show the rules with their source file (Project settings), add a session-only allow rule live, point out **Recently denied**.
5. One sentence: "In an enterprise, this same JSON arrives as managed settings; `allowManagedPermissionRulesOnly` means only IT's lists count."

**Demo 2 — A blocking hook (4 min)**
1. Open `labs/m2/hooks/protect-files.sh`; narrate stdin → `jq` → pattern loop → `exit 2` + stderr.
2. `mkdir -p .claude/hooks && cp $WS/labs/m2/hooks/protect-files.sh .claude/hooks/ && chmod +x .claude/hooks/protect-files.sh` — the `hooks` block is already in the settings file you copied.
3. In `claude`: "Add a one-line comment header to pb/demo_pb2.py" (any `_pb2.py` path works). Expected: the transcript shows the edit blocked by the `PreToolUse` hook with the stderr text `Blocked: … matches protected pattern '_pb2.py'`, and Claude explaining it cannot edit generated code. Then `/hooks` → 2 hooks from Project Settings.
4. `tail .claude/bash-audit.log` — the PostToolUse audit line from `git status` earlier.
5. 20-second scroll through the Ref §E event table; name the five handler types; "the security-guidance plugin you meet in M7 is *just hooks* like these."

**Demo 3 — MCP at project scope (4 min)**
1. `claude mcp add --transport stdio --scope project astro-catalog -- node $WS/labs/mcp/astro-catalog/server.mjs` → `cat .mcp.json`.
2. `claude` → approve the new project server when asked → `/mcp` shows `astro-catalog · connected · 3 tools`.
3. Prompt: "Using astro-catalog, which products cost more than $100, and which service owns pricing?" — point at `mcp__astro-catalog__list_products` and `…__service_owner` calls and the permission prompt for the first call.
4. Mention, don't do: `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` then `/mcp` → Authenticate **[verify-on-day URL]**; tool search and `/context`; `MAX_MCP_OUTPUT_TOKENS`; managed allow/deny lists; `claude mcp serve`.

> [!NOTE]
> **Instructor:** if the venue network is flaky, skip the GitHub mention entirely — the lab is 100 % local by design. If Demo 2's hook does not fire, run the `echo … | protect-files.sh` self-test live; it is a better teaching moment than a working demo.

## Hands-on lab

**Goal:** leave `$OTEL` with a committed-quality `.claude/settings.json` (rules + two hooks), an executable `.claude/hooks/protect-files.sh`, a `.mcp.json` pointing at the workshop's `astro-catalog` server, and proof that each one fired. **Start state:** CP1 (`CLAUDE.md`, `.claude/rules/proto.md`). **End state:** CP2. Three parts; each ends with a success check. Minute budgets in parentheses.

### Part A — Settings & permissions (8 min)

**Step 1 (3 min) — install the project settings.**

```bash
cd $OTEL
mkdir -p .claude
cp $WS/labs/m2/settings.project.json .claude/settings.json
[ -f .env ] || echo 'FAKE_KEY=123' > .env   # the demo repo normally ships a harmless .env; create a dummy only if missing
cat .claude/settings.json
```

The file you just copied (identical to the demo):

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "defaultMode": "default",
    "allow": ["Bash(go test *)", "Bash(npm test *)", "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)"],
    "ask":   ["Bash(git push *)", "Bash(gh pr create *)"],
    "deny":  ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)", "Bash(curl *)", "Bash(wget *)"]
  },
  "hooks": {
    "PreToolUse":  [{ "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh" }]}],
    "PostToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "jq -r '.tool_input.command' >> \"$CLAUDE_PROJECT_DIR\"/.claude/bash-audit.log" }]}]
  }
}
```

(The `PreToolUse` hook points at a script you install in Part B. Until then every Edit shows a harmless non-blocking `hook error` — a live illustration of "missing script does not block".)

**Step 2 (3 min) — watch the rules work.** Start `claude` (it starts in Manual mode because of `defaultMode`) and send, one at a time:

1. `print the contents of .env` → expect a refusal that cites a permission rule; if Claude falls back to `cat .env`, that is denied too.
2. `run: curl -s https://example.com | head` → denied by `Bash(curl *)`.
3. `run git status and summarize` → runs **without** a prompt (allow rule).
4. Type `/permissions` → **Success check:** the Allow, Ask and Deny tabs each list the rules above with source *Project settings*.

**Step 3 (2 min, macOS / Linux / WSL2 only — native Windows skip to Part B) — sandbox.** In the same session run `/sandbox`, choose **Enable** with auto-allow mode (Linux/WSL2: if it reports missing dependencies, `sudo apt-get install bubblewrap socat` or skip). Then ask: `create an empty file at ~/claude-sandbox-probe.txt using bash`. Expected: the write is refused by the operating system (outside the working directory) and Claude reports the sandbox violation — possibly offering to retry unsandboxed, which you decline. Notice that `git status`-style commands now run with no prompt at all. Optional, to make it permanent for this repo, merge into `.claude/settings.json`:

```json
{
  "sandbox": {
    "enabled": true,
    "allowUnsandboxedCommands": false,
    "filesystem": { "denyRead": ["~/.ssh", "~/.aws/credentials"] },
    "network": { "allowedDomains": ["proxy.golang.org", "registry.npmjs.org"] }
  }
}
```

With `denyRead` in place, `ls ~/.ssh` via Bash is refused as well (by default the sandbox restricts *writes* and *network*, not reads — you opt paths out of reading explicitly).

### Part B — Hooks (10 min)

**Step 4 (3 min) — install the guardrail script.**

```bash
cd $OTEL
mkdir -p .claude/hooks
cp $WS/labs/m2/hooks/protect-files.sh .claude/hooks/
chmod +x .claude/hooks/protect-files.sh
# self-test: 2 = blocked, 0 = allowed
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/checkoutservice/genproto/oteldemo/demo.pb.go"}}' | .claude/hooks/protect-files.sh; echo "exit=$?"
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/checkoutservice/main.go"}}' | .claude/hooks/protect-files.sh; echo "exit=$?"
```

Windows PowerShell: `Copy-Item $env:WS\labs\m2\hooks\protect-files.ps1 .claude\hooks\` and replace the `PreToolUse` handler in `.claude/settings.json` with the `"shell": "powershell"` variant shown in Concepts Part B example 1. Read the script (30 seconds): it blocks any path containing `.env`, `_pb2.py`, `.pb.go`, `pb/`, or `package-lock.json`.

**Step 5 (4 min) — trigger both hooks.** In `claude` (a running session picks up the new script automatically; if in doubt, `/hooks`):

1. `Add a comment header "// Code generated from pb/demo.proto. DO NOT EDIT." to src/checkoutservice/genproto/oteldemo/demo.pb.go` → expect the edit to be **blocked**, the `Blocked: … protected pattern '.pb.go'` message to appear in the transcript (`Ctrl+O` to expand), and Claude to explain it cannot modify generated code (it may offer to edit `pb/demo.proto` instead — also blocked, by design).
2. `Add a one-line comment at the top of src/checkoutservice/main.go saying it is the checkout entrypoint` → allowed (normal edit prompt; approve).
3. `run git diff --stat` → runs unprompted and is audited.

**Success check:**

```bash
tail -5 .claude/bash-audit.log        # shows git status / git diff --stat lines written by the PostToolUse hook
```

and `/hooks` inside the session lists **2** hooks (PreToolUse `Edit|Write|MultiEdit`, PostToolUse `Bash`) sourced from *Project Settings*. Revert the demo edit when done: `git checkout -- src/checkoutservice/main.go`.

**Step 6 (3 min) — read, don't type.** Open `$WS/labs/m2/hooks/examples/stop-prompt.json` (Concepts Part B example 5) and `http.json` (example 4). With your neighbour, answer: (a) for "always run tests before finishing", would you use CLAUDE.md, a `prompt` Stop hook, or an `agent` Stop hook — and what does each cost? (b) What would you have to add to `http.json` before your security team accepts it as an audit control? (Hint: `allowedHttpHookUrls` in *managed* settings, and `allowManagedHooksOnly`.) We take two answers in the debrief.

### Part C — MCP (10 min)

**Step 7 (2 min) — make sure the server runs.** Preflight already installed it; this is a re-check.

```bash
cd $WS/labs/mcp/astro-catalog && npm ci --silent && node server.mjs --selftest   # prints OK and the 3 tool names
cd $OTEL
```

**Step 8 (3 min) — add it at project scope.**

```bash
claude mcp add --transport stdio --scope project astro-catalog -- node $WS/labs/mcp/astro-catalog/server.mjs
cat .mcp.json            # note: type stdio, command node, args = absolute path to server.mjs
claude mcp list          # astro-catalog shows "Pending approval" until you approve it in a session
claude
```

On start, Claude Code asks whether to enable the new project MCP server `astro-catalog` — choose the option that approves it for this project. Then `/mcp` → **Success check (part 1):** `astro-catalog` is *connected* with **3 tools**: `list_products`, `get_product`, `service_owner`. (Note for M3: the absolute path in `args` is fine on your laptop but not portable; the plugin version replaces it with `${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs`.)

**Step 9 (3 min) — use the tools.** Prompt:

> Using the astro-catalog tools, list telescopes that cost over $100, then tell me which service and which source file in this repo implement pricing for them.

Approve the first `mcp__astro-catalog__list_products` call when prompted. Expected: Claude combines catalog data from the MCP server with a `Grep`/`Read` of the repo (pricing lives in the product catalog / currency services). **Success check (part 2):** `Ctrl+O` shows at least one `mcp__astro-catalog__list_products` (or `get_product` / `service_owner`) tool call in the transcript.

**Step 10 (2 min) — pre-approve the server's tools.** `/permissions` → **Allow** → *Add a new rule* → `mcp__astro-catalog__*` → save to **Project settings**. Re-ask "which service owns pricing for the cheapest telescope?" → the MCP call now runs with no prompt. `cat .claude/settings.json` shows the new entry appended to `permissions.allow` — this is the file state CP2 expects.

You are at **CP2** when: `.claude/settings.json` has the three rule lists + two hooks (+ `mcp__astro-catalog__*` allow), `.claude/hooks/protect-files.sh` is executable and self-tests 2/0, `.claude/bash-audit.log` has entries, `.mcp.json` defines `astro-catalog`, and `/mcp` shows it connected.

## If you're behind (fast-forward)

```bash
cd $OTEL && $WS/labs/checkpoint.sh CP2
```

CP2 writes `.claude/settings.json` (rules, hooks, `mcp__astro-catalog__*` allow, `enabledMcpjsonServers: ["astro-catalog"]` so no approval prompt), `.claude/hooks/protect-files.sh` (+ `.ps1`), and `.mcp.json`; runs `npm ci` for the MCP server; and prints what it changed. It never overwrites files you edited unless you pass `--force`. Afterwards run the two self-test `echo … | protect-files.sh` lines from Step 4 and `claude mcp list` to confirm, then rejoin at Part C Step 9 or wait for Module 3. Windows: `labs\checkpoint.ps1 CP2`.

## Troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| Deny rule doesn't bite; Claude reads `.env` anyway | Rule typo or wrong anchor: `Read(.env)` matches `.env` at any depth, `Read(./.env)` is anchored to the working directory, `Read(/.env)` is relative to the *settings file's* project root. Check `/permissions` for the rule and its source; check you edited `.claude/settings.json`, not `~/.claude.json` |
| Allow rule ignored, still prompted | An `ask` or `deny` matched first (deny → ask → allow, first match wins); or the command is compound (`cd x && npm test`) and one part isn't allowed; or you're in auto mode and it was a broad rule that auto mode drops |
| "Settings Error" dialog at startup | Invalid JSON / unknown key type in a user/project/local file — the whole file is rejected. Fix the line it names; `$schema` in your editor catches this before you save |
| Edits happen with no prompts at all | Session started in `auto` (plan default) or `acceptEdits` — look at the status line; `Shift+Tab` to Manual, or rely on `defaultMode` in the lab file |
| Hook never fires | Script not executable (`chmod +x`) → exit 127 is *non-blocking*, look for a grey `hook error` line; matcher case (`edit` ≠ `Edit`); matcher written as `Edit.*`-style regex matching more/less than intended; hooks placed in `~/.claude.json` or a standalone file instead of under `"hooks"` in a settings file; workspace trust not accepted (interactive sessions hold hooks until you trust the folder). Confirm with `/hooks`; debug with `claude --debug-file /tmp/cc.log` and search for `Hook PreToolUse` |
| Hook fires but doesn't block | Script exits 1 instead of 2; or prints JSON *and* your shell profile echoed text first (stdout must be only the JSON object); or the message went to stdout instead of stderr with exit 2 |
| `jq: command not found` inside the hook | Install jq (preflight flags it) — the workshop script falls back to `sed`, your own scripts may not |
| Windows: hook path/quoting errors | Use the `.ps1` variant with `"shell": "powershell"` and `$env:CLAUDE_PROJECT_DIR`; forward slashes are fine |
| `/sandbox` says unavailable | Native Windows/WSL1 unsupported (skip); Linux/WSL2 missing `bubblewrap`/`socat`; some Docker-in-Docker setups need `enableWeakerNestedSandbox` (weaker — don't for real work) |
| Sandboxed `go`/`gh` fails TLS or module download | No domains are pre-allowed: approve the host when prompted or add it to `sandbox.network.allowedDomains` (`proxy.golang.org`, `sum.golang.org`, `registry.npmjs.org`) |
| `claude mcp list` → `✘ Failed to connect` for astro-catalog | Run `node $WS/labs/mcp/astro-catalog/server.mjs --selftest` by hand to see the stack trace; usual culprits: Node older than 20, `npm ci` not run, path typo after `--` (paths are resolved from where you launched `claude`) |
| Server never offered for approval / shows "Pending approval" forever | You dismissed the prompt once → `claude mcp reset-project-choices`, restart `claude`; or pre-approve with `"enabledMcpjsonServers": ["astro-catalog"]` in `.claude/settings.local.json` |
| `.mcp.json` not created | You ran `claude mcp add` outside `$OTEL`, or without `--scope project` (then it went to `~/.claude.json` local scope — `claude mcp get astro-catalog` tells you the scope; `claude mcp remove astro-catalog --scope local` and redo) |
| Options parsed as the server command | Everything after `--` is passed to the server verbatim; put `--scope/--transport/--env` **before** the server name |
| Windows native: stdio server "Connection closed" immediately | Wrap npx-based servers: `claude mcp add --scope project playwright -- cmd /c npx -y @playwright/mcp@latest`; `node …server.mjs` works unwrapped |
| Remote server stuck on "Needs authentication" | `/mcp` → Authenticate (browser) or `claude mcp login <name>`; behind SSH use the printed URL and paste the callback URL back; corporate proxy → `HTTPS_PROXY`/`NODE_EXTRA_CA_CERTS` |
| MCP answers are truncated / "result too large" | Raise `MAX_MCP_OUTPUT_TOKENS` for the session, or (better) ask for filtered/paginated results; check `/context` |

## Stretch goals

Pick any; all are independent. Hook scripts referenced here live in `$WS/labs/m2/hooks/examples/`.

**(a) Remote MCP with OAuth.** `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` **[verify-on-day URL]** → in `claude`, `/mcp` → *github* → **Authenticate** → browser → back in the session ask "list my 3 most recently updated repositories". Then try a resource mention: type `@github:` and browse. Remove afterwards with `claude mcp remove github` if you don't want it at local scope.

**(b) Browser automation MCP.** `claude mcp add --transport stdio playwright -- npx -y @playwright/mcp@latest` (Windows native: prefix `cmd /c`). Prompt: "Use Playwright to open https://opentelemetry.io/docs/demo/, take a screenshot, and list the services the architecture page names." Watch `/context` before and after — tool search keeps the ~20 Playwright tool schemas out of the window until used.

**(c) Ask instead of block.** Copy `protect-files.sh` to `protect-files-ask.sh` and replace the `echo … >&2; exit 2` branch with a JSON decision so a human can override case by case:

```bash
jq -n --arg f "$FILE_PATH" --arg p "$pattern" '{hookSpecificOutput:{hookEventName:"PreToolUse",
  permissionDecision:"ask",
  permissionDecisionReason:("\($f) matches protected pattern \($p) - confirm you really intend to hand-edit it")}}'
exit 0
```

Point the `PreToolUse` handler at the new script, retry Step 5.1, and note the prompt is labelled with the hook's source. Then switch to auto mode (`Shift+Tab`) and confirm the hook still forces a prompt — `ask` from a hook is honoured even there.

**(d) SessionStart context injection.** Install `labs/m2/hooks/examples/sessionstart-gitlog.sh`:

```bash
#!/usr/bin/env bash
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
LOG=$(git log -5 --oneline 2>/dev/null) || exit 0
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
jq -n --arg log "$LOG" --arg br "$BRANCH" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:("Current branch: "+$br+"\nRecent commits:\n"+$log)}}'
```

```json
{ "hooks": { "SessionStart": [ { "matcher": "startup|resume", "hooks": [
  { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/sessionstart-gitlog.sh", "timeout": 10 } ] } ] } }
```

Restart `claude` and ask "what did the last few commits change?" without letting it run git — it already knows. (Same trick with `"matcher": "compact"` re-injects must-know facts after compaction.)

**(e) Claude Code as an MCP server.** In a second terminal: `claude mcp serve` (it prints nothing — it is waiting for a client). If you have Claude Desktop, add the `claude-code` entry from Concepts Part C to its MCP config and ask Desktop to "use claude-code to grep for CartService in $OTEL". Otherwise inspect it with `npx -y @modelcontextprotocol/inspector claude mcp serve` and browse the exposed tools.

**(f) One more rule form.** Add `"ask": ["Bash(dangerouslyDisableSandbox:true)", "Agent(model:opus)"]` — parameter-matching rules (deny/ask only) that force a prompt whenever Claude tries to leave the sandbox or spawn an Opus subagent. Verify with `/permissions`.

## Key takeaways

- **Rules are enforcement, CLAUDE.md is advice.** deny → ask → allow, first match wins; arrays merge across managed > CLI > local > project > user and a deny anywhere is final.
- Write rules at the right grain: `Bash(go test *)` not `Bash(*)`; deny `curl`/`wget` and secrets paths; use `ask` for irreversible actions (`git push`, `gh pr create`) — it survives auto mode and compaction.
- The **sandbox** makes the OS enforce filesystem/network limits for Bash and its children and removes most Bash prompts; it does not cover file tools, MCP servers or hooks. `allowUnsandboxedCommands: false` closes the escape hatch.
- **Hooks** = event → matcher → handler. `command` hooks read JSON on stdin; **exit 2 blocks**, exit 1 does not, a missing script silently doesn't. Prefer JSON `hookSpecificOutput.permissionDecision` (`allow`/`deny`/`ask`/`defer`) when you need nuance; `http`, `mcp_tool`, `prompt`, `agent` handlers exist for audit sinks and judgement calls.
- **MCP**: `claude mcp add [options] <name> -- <cmd>` or `<url>`; `--scope project` → committed `.mcp.json` with `${VAR}` expansion; OAuth via `/mcp`; tools are `mcp__server__tool` and obey the same rules and hooks; tool search keeps context cost low; only connect servers you would run as yourself, and treat what they return as untrusted.
- You now own `.claude/settings.json`, `.claude/hooks/protect-files.sh`, and `.mcp.json` — Module 3 packages all three into the `codebase-toolkit` plugin.

## References

Workshop reference (`reference/Technical-Reference-v4.md`): **§D** settings scopes & precedence diagram, full settings-key table, permission-rule grammar, modes & start-mode matrix, sandbox keys, managed-only keys · **§E** hooks: config schema, handler fields, matcher table, stdin/stdout contract per event, full 31-event table, exit-code matrix, examples · **§F** MCP: transports, scopes, `.mcp.json` schema, env expansion, OAuth options, tool search, output limits, managed MCP, `claude mcp serve` · **§J** troubleshooting by module · **§M** threat → control matrix (how today's rules/hooks/sandbox map to Module 7) · **§O** volatile facts to re-verify (GitHub MCP URL, auto-mode default matrix, handler-type list).

Official documentation (as of August 2026):
- Settings — https://code.claude.com/docs/en/settings
- Permissions & rule syntax — https://code.claude.com/docs/en/permissions
- Permission modes & auto mode — https://code.claude.com/docs/en/permission-modes , https://code.claude.com/docs/en/auto-mode-config
- Sandboxing — https://code.claude.com/docs/en/sandboxing , https://code.claude.com/docs/en/sandbox-environments
- Hooks reference & guide — https://code.claude.com/docs/en/hooks , https://code.claude.com/docs/en/hooks-guide
- MCP in Claude Code — https://code.claude.com/docs/en/mcp , https://code.claude.com/docs/en/managed-mcp
- Environment variables — https://code.claude.com/docs/en/env-vars
- Security overview — https://code.claude.com/docs/en/security
- Example hooks and settings — https://github.com/anthropics/claude-code/tree/main/examples
- Model Context Protocol — https://modelcontextprotocol.io

Lab assets: `labs/m2/settings.project.json`, `labs/m2/hooks/protect-files.sh|.ps1`, `labs/m2/hooks/examples/{stop-prompt.json,http.json,scan-prompt.sh,sessionstart-gitlog.sh}`, `labs/mcp/astro-catalog/`, `labs/checkpoint.sh CP2`.
