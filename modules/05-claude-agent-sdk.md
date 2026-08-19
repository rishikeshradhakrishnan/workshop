# Module 5 — Claude Agent SDK deep-dive

> **Time box:** 12:55–13:50 (55 min) · **Format:** talk 12 · lab 38 · debrief 5 · **Checkpoint in:** CP4 (needs the CP3 plugin at `$OTEL/../codebase-toolkit`) · **Checkpoint out:** CP5

> [!IMPORTANT]
> This module **requires a Claude Console API key** (`ANTHROPIC_API_KEY`) or cloud-provider credentials. A claude.ai subscription login is not an accepted auth path for products you build on the SDK. No key? Pair with a neighbour, use the instructor's time-boxed workshop-workspace key from `labs/.env.instructor`, or follow along with `labs/m5-agent-sdk/expected-output/`.

## Why this matters

Everything you built this morning — `CLAUDE.md`, permission rules, hooks, an MCP server, two subagents, a skill, a plugin — ran inside the Claude Code product with a human at the keyboard. The moment you want that same agent inside *your* software (a CLI your team ships, a service behind an API, a nightly job, a support bot), you need the agent loop as a **library**: something you call from Python or TypeScript, configure in code, gate with your own policy functions, and whose output and cost you can read programmatically. That is the Claude Agent SDK. It is the same engine as Claude Code — same tools, same loop, same context management — so nothing you learned is thrown away; it just moves from files and flags into an options object. This module also sets up Module 6: once you have written an SDK agent by hand, you can judge when to host it yourself and when to hand the loop and the sandbox to Claude Managed Agents.

## Learning objectives

By the end of this module you can:

1. **Position the SDK**: Claude Code's agent loop, built-in tools and context management as a Python/TypeScript library that runs in *your* process (it supervises a bundled Claude Code binary); it authenticates with a Console API key or Amazon Bedrock / Google Vertex AI / Microsoft Foundry credentials — not a claude.ai login — for anything you ship.
2. **Drive it**: use `query()` for one-shot runs and `ClaudeSDKClient` (Python) / streaming-input mode (TypeScript) for multi-turn; read the message stream (`system/init`, assistant, user tool results, `result` with `total_cost_usd`, `usage`, `model_usage`/`modelUsage`, `session_id`, `structured_output`, `permission_denials`, `terminal_reason`).
3. **Configure it**: `system_prompt` (preset + append vs custom), `cwd`, `model`, `effort`, `allowed_tools`/`disallowed_tools`/`tools`, `permission_mode`, `max_turns`, `max_budget_usd`, `setting_sources`, `plugins`, `agents`, `mcp_servers`, `hooks`, `can_use_tool`, `output_format`, `resume`/`fork_session`.
4. **Extend it**: add custom tools with `@tool`/`tool()` + `create_sdk_mcp_server`/`createSdkMcpServer` (in-process MCP), name and pre-approve them as `mcp__<server>__<tool>`, return `is_error`, and connect external MCP servers.
5. **Govern and operate it**: enforce policy with hook callbacks and `can_use_tool`; get schema-validated structured output; track cost and usage; resume a session; define programmatic subagents; know the hosting/secure-deployment checklist and that Managed Agents (M6) is the hosted alternative.

## Concepts (instructor talk track)

### 5.1 What the SDK is — and when to reach for something else

The docs' one-liner: *build production AI agents with Claude Code as a library.* Under the hood each `query()` spawns and supervises a Claude Code process (the binary ships inside the SDK package) and talks to it over a structured stdio protocol. Your code never implements a tool loop; it configures one and consumes its event stream.

```
 your app (Py/TS) ── options, prompt ──▶ Agent SDK ──stdio──▶ bundled Claude Code process ──HTTPS──▶ Claude API
        ▲                                   │                    (tools run here: Read/Grep/Bash/MCP,   (or Bedrock /
        └──── messages: init · assistant · user(tool results) · result ◀──┘   in `cwd`, as your OS user)   Vertex / Foundry)
```

| You want to… | Use | Who runs the loop | Where tools execute |
|---|---|---|---|
| Work interactively in a repo, or script a one-off with `claude -p` | **Claude Code** (CLI/IDE/Desktop/Web) | Claude Code | Your machine (or Anthropic cloud for web sessions) |
| Embed the same agent in your own program, with code-level control of tools, permissions, output and cost | **Claude Agent SDK** | The SDK, in your process | Your machine / your container |
| Call the model directly and write your own loop, tool execution and context management | **Messages API** via the client SDKs (`anthropic`, `@anthropic-ai/sdk`) | You | Wherever you implement them |
| Run long/asynchronous agents without operating containers, sandboxes or session storage | **Claude Managed Agents** (Module 6) | Anthropic's hosted harness | Anthropic-managed environment per session |

Rule of thumb for the room: *if you would be happy typing it into `claude`, the SDK can run it unattended; if you don't want to own the box it runs on, look at Managed Agents.* Other languages: run `claude -p --output-format stream-json` as a subprocess — the CLI is "the Agent SDK via the command line" (Module 4).

**Everything from this morning has an SDK equivalent** (full mapping: reference §K.1):

| Claude Code concept (M1–M4) | SDK option |
|---|---|
| `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`, `.mcp.json` | loaded via `setting_sources` / `settingSources` (default: all sources — see 5.13) |
| `permissions.allow/deny`, `--allowedTools`, `--permission-mode` | `allowed_tools`, `disallowed_tools`, `permission_mode` |
| hooks in `settings.json` (shell commands) | `hooks` = in-process callbacks (5.9) — file-based hooks still load too |
| `.mcp.json` / `claude mcp add` | `mcp_servers` (external) + `create_sdk_mcp_server` (in-process, 5.10) |
| `.claude/agents/*.md` | `agents={name: AgentDefinition(...)}` (5.12) |
| `--plugin-dir ../codebase-toolkit` | `plugins=[{"type":"local","path":"../codebase-toolkit"}]` |
| `claude -p --json-schema … --max-turns --max-budget-usd` | `output_format`, `max_turns`, `max_budget_usd` |
| `--resume <id>` / `--continue` | `resume=` / `continue_conversation=True` (`continue: true` in TS) |

### 5.2 Install and authenticate (Python | TypeScript)

```bash
# Python 3.10+ (primary track)
uv init bughunter && cd bughunter && uv add claude-agent-sdk jsonschema
# TypeScript / Node.js (current LTS recommended; docs minimum 18+)
npm init -y && npm pkg set type=module
npm install @anthropic-ai/claude-agent-sdk zod && npm install -D tsx typescript @types/node
# Both: credentials come from the environment
export ANTHROPIC_API_KEY=sk-ant-...        # in this workshop: source $WS/labs/.env
```

- Both packages **bundle the Claude Code binary** for your platform; you do not install Claude Code separately. If the binary is missing (source-only Python install, `npm ci --omit=optional`), install Claude Code natively and point `cli_path` (Py) / `pathToClaudeCodeExecutable` (TS) at it.
- The SDK reads credentials from the **process environment**; it does not load `.env` files for you (`source labs/.env` does that in this workshop).
- Provider switches (same variables as Claude Code): `CLAUDE_CODE_USE_BEDROCK=1` (+ AWS credentials), `CLAUDE_CODE_USE_VERTEX=1` (+ Google Cloud credentials), `CLAUDE_CODE_USE_FOUNDRY=1` (+ Azure credentials). LLM gateways: `ANTHROPIC_BASE_URL` (+ `ANTHROPIC_AUTH_TOKEN` bearer). Rotating credentials: the `apiKeyHelper` setting.
- **Policy, say it out loud:** unless previously approved, third-party products built on the SDK must not offer claude.ai login or consume claude.ai plan limits — use API-key or cloud-provider auth. On a developer laptop the bundled process *can* pick up your own `claude` login for local tinkering, which is exactly why the lab prints `apiKeySource` from the init message: if it does not say the key came from `ANTHROPIC_API_KEY`, fix your environment before you trust the cost numbers.
- Branding for things you ship: "Claude Agent", "{YourProduct} powered by Claude" — not "Claude Code".

> [!NOTE]
> **Volatile facts (re-verify before each delivery; reference §O).** As of August 2026: npm `@anthropic-ai/claude-agent-sdk` is on the 0.3.x line and PyPI `claude-agent-sdk` on 0.2.x, both releasing almost daily and each bundling a matching Claude Code build; Python minimum 3.10, Node.js minimum 18 (we standardise on current LTS); TS peer dependency is Zod 4. Defaults that changed during 2025–26 and that older blog posts get wrong: `settingSources` omitted = **all** filesystem sources load; subagents run in the background by default; MCP servers connect in the background (`pending` is not failure); MCP tool schemas are deferred behind tool search by default; task-tracking tools (`TaskCreate`/`TaskUpdate`) replaced `TodoWrite` and are opt-in on the newest models; the experimental TS "V2 session" API was removed (use `query()` with an async iterable).

### 5.3 The smallest useful program

```python
# Python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions, AssistantMessage, ResultMessage, TextBlock, ToolUseBlock

async def main():
    opts = ClaudeAgentOptions(cwd="../opentelemetry-demo", allowed_tools=["Read", "Grep", "Glob"],
                              permission_mode="dontAsk", max_turns=20)
    async for msg in query(prompt="Which services call CartService over gRPC? Cite files.", options=opts):
        if isinstance(msg, AssistantMessage):
            for b in msg.content:
                if isinstance(b, TextBlock): print(b.text)
                elif isinstance(b, ToolUseBlock): print(f"  -> {b.name}")
        elif isinstance(msg, ResultMessage):
            print(f"Done: {msg.subtype} ${msg.total_cost_usd or 0:.4f}")

asyncio.run(main())
```

```ts
// TypeScript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const msg of query({
  prompt: "Which services call CartService over gRPC? Cite files.",
  options: { cwd: "../opentelemetry-demo", allowedTools: ["Read", "Grep", "Glob"], permissionMode: "dontAsk", maxTurns: 20 },
})) {
  if (msg.type === "assistant") {
    for (const b of msg.message.content) console.log(b.type === "text" ? b.text : b.type === "tool_use" ? `  -> ${b.name}` : "");
  } else if (msg.type === "result") {
    console.log(`Done: ${msg.subtype} $${msg.total_cost_usd.toFixed(4)}`);
  }
}
```

Two shape differences to memorise: Python uses `isinstance()` and content lives at `msg.content`; TypeScript switches on `msg.type` and content lives at `msg.message.content` (it wraps the API message object). Option names are `snake_case` in Python, `camelCase` in TypeScript; the semantics are identical unless flagged below.

### 5.4 The options object — the ones you will actually use

Full tables (every option, both languages, types and defaults) are in **reference §K.3**. These are the ones this workshop touches:

| Python `ClaudeAgentOptions` | TypeScript `Options` | Meaning · default |
|---|---|---|
| `cwd` | `cwd` | Working directory the agent's tools operate in · process cwd |
| `model` | `model` | Alias (`opus`, `sonnet`, `haiku`) or full model ID · CLI default for your account |
| `effort` | `effort` | `low` · `medium` · `high` · `xhigh` · `max` reasoning effort · model default |
| `thinking` | `thinking` | `{"type":"adaptive"}` · `{"type":"enabled","budget_tokens":…}` · `{"type":"disabled"}` (replaces deprecated `max_thinking_tokens`) |
| `system_prompt` | `systemPrompt` | string, or `{"type":"preset","preset":"claude_code","append":…}` · **minimal** tool-use prompt (not the Claude Code prompt) |
| `tools` | `tools` | Which built-in tools *exist* for the model (`[...]` or the `claude_code` preset) · full set |
| `allowed_tools` | `allowedTools` | Auto-approve list — a **permission**, not a restriction · `[]` |
| `disallowed_tools` | `disallowedTools` | Bare name removes a tool; a scoped rule like `Bash(rm *)` denies matching calls even in bypass mode · `[]` |
| `permission_mode` | `permissionMode` | `default` · `acceptEdits` · `plan` · `dontAsk` · `auto` · `bypassPermissions` (TS additionally requires `allowDangerouslySkipPermissions: true`) · `default` |
| `can_use_tool` | `canUseTool` | Async callback deciding calls that fall through rules and mode (5.8) · none → such calls are denied |
| `hooks` | `hooks` | `{event: [HookMatcher(...)]}` in-process callbacks (5.9) · none |
| `mcp_servers` | `mcpServers` | External (`stdio`/`http`/`sse`) and in-process SDK servers keyed by name (5.10–5.11) · `{}` |
| `agents` | `agents` | Programmatic subagents `{name: AgentDefinition}` (5.12) · none (file-based and built-in agents still exist) |
| `setting_sources` | `settingSources` | Which filesystem config loads: `"user"`, `"project"`, `"local"` · **all three**; `[]` isolates |
| `plugins` | `plugins` | `[{"type":"local","path":…}]` plugin directories · `[]` |
| `skills` | `skills` | `"all"`, a list of names, or `[]` to disable model-invoked skills · all discovered skills |
| `max_turns` | `maxTurns` | Cap on tool-use round trips → `error_max_turns` · unlimited |
| `max_budget_usd` | `maxBudgetUsd` | Stop when the client-side cost estimate reaches this → `error_max_budget_usd` · unlimited |
| `output_format` | `outputFormat` | `{"type":"json_schema","schema":{…}}` structured output (5.15) · none |
| `resume` · `fork_session` · `continue_conversation` | `resume` · `forkSession` · `continue` | Session control (5.7) · new session |
| `include_partial_messages` | `includePartialMessages` | Emit raw streaming deltas (`StreamEvent` / `stream_event`) for live UIs · off |
| `env` | `env` | Extra environment for the agent process. **Python merges** onto the inherited env; **TypeScript replaces** it — pass `{...process.env, X: "1"}` · inherited |
| `sandbox` | `sandbox` | OS-level Bash sandbox settings (same keys as `settings.json` `sandbox`) · off |
| `settings` · `stderr` · `cli_path` | `settings` · `stderr` · `pathToClaudeCodeExecutable` | Inline/path settings layer · debug log sink · override the bundled binary |

**Availability vs permission** is the number-one SDK confusion: `tools` decides what Claude can *see*; `allowed_tools` pre-approves; anything else falls through to the permission mode and then to `can_use_tool`. `allowed_tools` never constrains `bypassPermissions`. The locked-down headless recipe you used with `claude -p` this morning is the same here: `allowed_tools=[…]` + `permission_mode="dontAsk"`.

### 5.5 The message stream and the final result

Typical order: `system/init` → (`assistant` with text/`tool_use` → `user` with `tool_result`) × N → final `assistant` → **`result`**. A few informational system messages can trail the result — iterate to the end instead of breaking out (Python's docs specifically warn against `break` inside the `async for`).

| Message | Python | TypeScript | What you use it for |
|---|---|---|---|
| Init | `SystemMessage` with `subtype=="init"`; fields in `msg.data` (`session_id`, `model`, `tools`, `mcp_servers`, `plugins`, `skills`, `slash_commands`, `apiKeySource`, `permissionMode`) | `msg.type==="system" && msg.subtype==="init"`; same fields top-level | Verify what actually loaded (plugins! MCP status!) and how you authenticated |
| Model turn | `AssistantMessage.content` → `TextBlock` / `ToolUseBlock` / `ThinkingBlock`; `.usage`, `.message_id`, `.parent_tool_use_id` | `msg.type==="assistant"`, `msg.message.content[]`, `msg.message.usage`, `msg.parent_tool_use_id` | Stream text to the user; log tool names; `parent_tool_use_id != null` means "inside a subagent" |
| Tool results | `UserMessage` (`ToolResultBlock`) | `msg.type==="user"` | Usually ignore; useful for audit logs |
| Live deltas | `StreamEvent` (only with `include_partial_messages`) | `msg.type==="stream_event"` | Token-by-token UIs |
| **Result** | `ResultMessage` | `msg.type==="result"` | Everything below |

Reading the result (identical field names in both SDKs except `model_usage`↔`modelUsage`):

- `subtype`: `success` · `error_max_turns` · `error_max_budget_usd` · `error_during_execution` · `error_max_structured_output_retries`. `result` (final text) exists **only** on `success`; error subtypes carry `errors: [...]`.
- `terminal_reason` (why the loop stopped: `completed`, `max_turns`, `budget_exhausted`, `aborted_tools`, `prompt_too_long`, `model_error`, …) and `stop_reason` (the last API stop reason: `end_turn`, `max_tokens`, `refusal`, …).
- `total_cost_usd` and `model_usage`/`modelUsage` (per model: `costUSD`, `inputTokens`, `outputTokens`, `cacheReadInputTokens`, `cacheCreationInputTokens`) cover the **whole tree including subagents**; `usage` (`input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`) is the main loop only. All cost figures are **client-side estimates** — fine for budgets and dashboards, not for invoicing (use the Console Usage & Cost API for that).
- `session_id` (persist it to resume), `num_turns`, `duration_ms`, `permission_denials` (authoritative list of what `dontAsk`/rules blocked — first place to look when a run "did nothing"), `structured_output` (5.15).
- **A single-shot `query()` raises/throws after yielding an error result.** Wrap the loop in `try`/`except` (`try`/`catch`) and keep the last `ResultMessage` you saw.

### 5.6 Streaming input, multi-turn clients, interrupts

`prompt="string"` is *single-message mode*: one shot, then the process exits (continue later with `resume`). Passing an **async iterable of user messages** is *streaming-input mode*: one long-lived process, queued messages, image attachments, interrupts, and live `set_model`/`set_permission_mode`. Python wraps this in `ClaudeSDKClient`; TypeScript uses `query()` with an async generator and the returned `Query` handle.

```python
# Python — multi-turn REPL with interrupt (stretch goal b)
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, AssistantMessage, ResultMessage, TextBlock

async def repl(options: ClaudeAgentOptions):
    async with ClaudeSDKClient(options=options) as client:      # one session for the whole loop
        while (q := input("you> ").strip()) not in {"", "exit"}:
            await client.query(q)
            try:
                async for msg in client.receive_response():      # yields until (and including) the ResultMessage
                    if isinstance(msg, AssistantMessage):
                        print("".join(b.text for b in msg.content if isinstance(b, TextBlock)))
            except KeyboardInterrupt:
                await client.interrupt()                         # Ctrl+C stops the turn...
                async for msg in client.receive_response():      # ...then DRAIN it (terminal_reason aborted_*)
                    if isinstance(msg, ResultMessage): print(f"[interrupted: {msg.terminal_reason}]")
```

```ts
// TypeScript — async generator in, Query handle out
import { query, type SDKUserMessage } from "@anthropic-ai/claude-agent-sdk";
async function* turns(): AsyncGenerator<SDKUserMessage> {
  yield { type: "user", parent_tool_use_id: null, message: { role: "user", content: "Analyze src/adservice for bugs" } };
  yield { type: "user", parent_tool_use_id: null, message: { role: "user", content: "Now rank them by severity" } };  // queued
}
const q = query({ prompt: turns(), options: { allowedTools: ["Read", "Grep", "Glob"], permissionMode: "dontAsk" } });
setTimeout(() => void q.interrupt(), 60_000);           // also: q.setModel("haiku"), q.setPermissionMode("plan"), q.streamInput(more)
for await (const m of q) if (m.type === "result") console.log(m.subtype, m.terminal_reason);
```

### 5.7 Sessions: continue, resume, fork, store

| Need | Python | TypeScript |
|---|---|---|
| Multi-turn in one process | `ClaudeSDKClient` | streaming input (above) |
| Pick up the most recent session for this `cwd` after a restart | `continue_conversation=True` | `continue: true` |
| Resume a specific session | save `ResultMessage.session_id` → `resume=sid` | `resume: sid` (also on the init message) |
| Branch without touching the original | `resume=sid, fork_session=True` | `resume: sid, forkSession: true` |
| Keep nothing on disk | env `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` | `persistSession: false` |
| Inspect/manage history | `list_sessions()`, `get_session_messages()`, `rename_session()`, `tag_session()`, `fork_session()`, `delete_session()` | `listSessions()`, `getSessionMessages()`, `renameSession()`, `tagSession()`, `forkSession()`, `deleteSession()` |

Transcripts are JSONL files under `~/.claude/projects/<encoded-cwd>/` on the machine that ran the query — so **resume only works where the transcript is**. For fleets (resume on a different container tomorrow), pass a `session_store`/`sessionStore` adapter: the SDK mirrors transcript batches to your store and hydrates from it on `resume`. An `InMemorySessionStore` ships in both SDKs, reference S3/Redis/Postgres adapters live in the SDK repos' `examples/`, and a conformance test suite lets you validate your own. Forking copies conversation history, not the filesystem.

### 5.8 Permissions in code

Modes are the CLI's: `default` (unmatched calls go to `can_use_tool`; no callback → denied), `acceptEdits`, `plan`, `dontAsk` (never ask; anything not pre-approved is denied), `auto` (classifier), `bypassPermissions` (isolated environments only; deny rules still apply). Evaluation order is fixed and worth drawing on the whiteboard:

**hooks (PreToolUse) → deny rules → ask rules → permission mode → allow rules → `can_use_tool`**

Consequence: an auto-approved call **never reaches** `can_use_tool`. If you want your callback to see `create_ticket`, do *not* also list it in `allowed_tools` (TypeScript even prints a `CLAUDE_SDK_CAN_USE_TOOL_SHADOWED` warning). If you need to see *every* call, use a `PreToolUse` hook instead.

```python
# Python — the lab's policy callback (hooks.py)
from claude_agent_sdk import PermissionResultAllow, PermissionResultDeny

async def ticket_policy(tool_name, input_data, context):          # context: ToolPermissionContext (tool_use_id, agent_id, suggestions…)
    if tool_name == "mcp__tracker__create_ticket":
        if str(input_data.get("severity", "")).upper() == "HIGH":
            return PermissionResultAllow(updated_input=input_data)  # you may also rewrite the input here
        return PermissionResultDeny(message="only HIGH severity gets a ticket")   # Claude reads this and adapts
    return PermissionResultDeny(message=f"{tool_name} is not permitted here")     # everything else stays locked down
```

TypeScript twin: a `CanUseTool` function returning `{ behavior: "allow", updatedInput }` or `{ behavior: "deny", message }` — see `src/hooks.ts` in the lab listing.

The same callback is where a UI product implements "Allow / Deny / Always allow" prompts (return `updated_permissions` built from `context.suggestions`) and where `AskUserQuestion` clarifying questions arrive. It has no timeout — a pending human is a pending agent.

> [!NOTE]
> Python detail: `can_use_tool` needs the SDK's control channel to stay open for the whole run. With `ClaudeSDKClient`, or whenever a hook or an in-process MCP server is registered (both true in our lab from step 3 on), that is already the case. The lab additionally feeds the prompt as a one-item async generator (`as_stream()`), which is the form the docs use for `can_use_tool` with `query()`.

### 5.9 Hooks as callbacks

Same events, same JSON decision schema as the shell hooks from Module 2 — but the handler is an `async` function in your process: no subprocess, no `jq`, no context-window cost, access to your app's state, and (TS) an `AbortSignal`. File-based hooks from `settings.json`/plugins **still run as well** when their setting source or plugin is loaded — in the lab, the M2 `protect-files.sh` inside the plugin fires alongside your Python callback. Hooks fire inside subagents too (`agent_id` is on the input).

```python
# Python — deny reads of secrets (hooks.py); register with HookMatcher(matcher="Read", hooks=[protect_secrets_hook])
import re
PROTECTED = re.compile(r"(^|/)\.env(\.[^/]*)?$|(^|/)secrets/")

async def protect_secrets_hook(input_data, tool_use_id, context):
    path = input_data.get("tool_input", {}).get("file_path", "")
    if PROTECTED.search(path):
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": f"bughunter policy: {path} is protected"}}
    return {}                                                        # empty dict = no opinion, continue
```

TypeScript twin: a `HookCallback` (typed input via `PreToolUseHookInput`) registered as `hooks: { PreToolUse: [{ matcher: "Read", hooks: [protectSecretsHook] }] }` — see `src/hooks.ts` in the lab listing.

What a `PreToolUse` hook may return in `hookSpecificOutput`: `permissionDecision` `allow|deny|ask|defer` (+ `permissionDecisionReason`), `updatedInput` (rewrite arguments — e.g. redirect writes into a sandbox dir), `additionalContext`. `PostToolUse` may add `additionalContext` or `updatedToolOutput` (audit/redact). Top-level `{"decision":"block","reason":…}`, `systemMessage`, and `{"async": true}` fire-and-forget (`async_` in Python) work as in the CLI. Events available as callbacks — Python: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `Stop`, `SubagentStart`, `SubagentStop`, `PreCompact`, `Notification`, `PermissionRequest`; TypeScript adds `SessionStart`/`SessionEnd`, `PostToolBatch`, `PermissionDenied`, `ConfigChange`, `FileChanged`, `CwdChanged` and more (reference §K.6). Matchers match **tool names only**; filter paths inside the function, as above.

### 5.10 Custom tools = an MCP server inside your process

A custom tool is a name, a description, an input schema and an async handler returning MCP `content` blocks. You group tools into an **SDK MCP server**, register it under a key in `mcp_servers`, and the model sees each tool as `mcp__<server-key>__<tool>`. Pre-approve with that exact name (or `mcp__<server-key>__*`) — `acceptEdits` does not cover MCP tools. Return `is_error`/`isError: true` with a helpful message instead of raising; the loop continues and Claude adapts. Read-only tools can declare `readOnlyHint` so they run in parallel.

```python
# Python (tools.py, complete in the lab listing)
from typing import Any
from claude_agent_sdk import tool, create_sdk_mcp_server

@tool("create_ticket", "File a bug ticket in the Astronomy Shop tracker; returns the ticket id.",
      {"title": str, "severity": str, "file": str, "line": int})           # simple type map → JSON Schema (or pass a full JSON Schema dict)
async def create_ticket(args: dict[str, Any]) -> dict[str, Any]:
    if args["severity"].upper() not in {"HIGH", "MEDIUM", "LOW"}:
        return {"content": [{"type": "text", "text": "severity must be HIGH|MEDIUM|LOW"}], "is_error": True}
    tid = append_ticket(args["title"], args["severity"].upper(), args["file"], int(args["line"]))
    return {"content": [{"type": "text", "text": f"created {tid}"}]}

tracker_server = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
options = ClaudeAgentOptions(mcp_servers={"tracker": tracker_server}, allowed_tools=["mcp__tracker__create_ticket"])
```

```ts
// TypeScript (tools.ts) — Zod schema, typed args
import { tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";
const createTicket = tool(
  "create_ticket", "File a bug ticket in the Astronomy Shop tracker; returns the ticket id.",
  { title: z.string(), severity: z.string().describe("HIGH | MEDIUM | LOW"), file: z.string(), line: z.number().int() },
  async (args) => {
    const sev = args.severity.toUpperCase();
    if (!["HIGH", "MEDIUM", "LOW"].includes(sev)) return { content: [{ type: "text", text: "severity must be HIGH|MEDIUM|LOW" }], isError: true };
    return { content: [{ type: "text", text: `created ${appendTicket(args.title, sev, args.file, args.line)}` }] };
  },
);
export const trackerServer = createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] });
// options: { mcpServers: { tracker: trackerServer }, allowedTools: ["mcp__tracker__create_ticket"] }
```

### 5.11 External MCP servers

Exactly the `.mcp.json` shapes from Module 2, inline. A project's `.mcp.json` also loads whenever the `project` setting source is on; `strict_mcp_config=True` says "only the servers I pass here".

```python
ClaudeAgentOptions(
    mcp_servers={
        "astro-catalog": {"command": "node", "args": [f"{WS}/labs/mcp/astro-catalog/server.mjs"]},          # stdio (M2's server)
        "github": {"type": "http", "url": GITHUB_MCP_URL,                                                    # remote HTTP
                   "headers": {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}},                    # SDK runs no OAuth browser flow: bring a token
    },
    allowed_tools=["mcp__astro-catalog__*", "mcp__github__list_issues"],
)
```

Servers connect in the background; check `init.mcp_servers[].status` (`pending|connected|failed|needs-auth|disabled`) rather than assuming. Tool schemas are deferred behind tool search by default, so keyword-rich tool names and descriptions matter.

### 5.12 Subagents from code — the morning's bug-hunter without a file

`agents` takes the same fields as the Markdown frontmatter (note: **camelCase field names even in Python**, e.g. `maxTurns`, `disallowedTools`). Programmatic definitions override same-named file/plugin agents. Claude invokes them through the `Agent` tool, so `"Agent"` must be allowed. Each subagent gets a fresh context and returns only its final message; its spend is inside `total_cost_usd`.

```python
from claude_agent_sdk import AgentDefinition
BUG_HUNTER_PROMPT = (Path(WS) / "labs/shared/prompts/bug_hunter_system.md").read_text()

options = ClaudeAgentOptions(
    allowed_tools=["Read", "Grep", "Glob", "Agent"],
    agents={
        "bug-hunter": AgentDefinition(description="Finds bugs, error-handling gaps and risky patterns in one service. Use proactively for any 'analyze X for bugs' request.",
                                      prompt=BUG_HUNTER_PROMPT, tools=["Read", "Grep", "Glob"], model="sonnet"),
        "lang-scout": AgentDefinition(description="Lists the languages/frameworks used under a path.",     # stretch (a): fan out one per language group
                                      prompt="Report languages, build files and test frameworks under the given path. Be terse.",
                                      tools=["Glob", "Read"], model="haiku", maxTurns=8),
    },
)
```

```ts
agents: { "bug-hunter": { description: "…", prompt: BUG_HUNTER_PROMPT, tools: ["Read", "Grep", "Glob"], model: "sonnet" } }
```

For dozens of parallel workers the docs point past subagents to the `Workflow` tool (dynamic workflows, Module 4) — include `"Workflow"` in `allowed_tools`.

### 5.13 What loads from disk: `setting_sources`, skills, plugins, CLAUDE.md

**Current behaviour (state it precisely, older material has it backwards):** when you *omit* `setting_sources`/`settingSources`, an SDK query loads the same filesystem configuration as the CLI — user, project and local settings, `CLAUDE.md` files and `.claude/rules/`, `.claude/agents`, `.claude/skills`, legacy commands, project hooks and `.mcp.json`. Omitting it equals `["user","project","local"]`. Pass `[]` to load none of them.

| Source | Loads |
|---|---|
| `"project"` | `<cwd>` (and parents) `CLAUDE.md`, `.claude/rules/*.md`, `.claude/settings.json` (rules, hooks, `enabledPlugins`), project skills/agents, `.mcp.json` |
| `"user"` | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, user skills/agents, user-scope plugins |
| `"local"` | `CLAUDE.local.md`, `.claude/settings.local.json` |

Independent of setting sources: organisation **managed settings** always apply; **auto memory** for the project is read (disable with `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`); programmatic options win over files. `CLAUDE.md` is injected as conversation context and is governed by setting sources — **not** by choosing the `claude_code` system-prompt preset. Skills are filesystem artifacts only (project/user/plugin); the `skills` option selects which discovered ones the model may invoke, and a skill's `allowed-tools` frontmatter is *not* honoured in SDK sessions — pre-approve tools yourself. Plugins load by local path only (`{"type":"local","path":…}`); verify in `init.plugins` and look for namespaced entries such as `codebase-toolkit:code-reviewer` in `init.skills`.

Why the lab passes `setting_sources=["project"]`: we *want* `$OTEL/CLAUDE.md`, the M2 deny rules and hooks, and nothing from anyone's `~/.claude` (which differs seat to seat). For a multi-tenant service you would pass `[]` and configure everything in code — the docs are explicit that default `query()` options are not an isolation boundary.

### 5.14 System prompt strategies

Three starting points: **(a)** omit `system_prompt` → a minimal tool-using prompt (this is *not* what `claude -p` uses — CLI-to-SDK ports feel "less like Claude Code" until you fix this); **(b)** `{"type":"preset","preset":"claude_code","append":"…"}` → the full Claude Code prompt plus your rules — lowest-risk choice for coding agents; add `"exclude_dynamic_sections": True` (`excludeDynamicSections`) so per-machine details move out of the system prompt and a fleet shares one prompt-cache entry; **(c)** a custom string → you own tool guidance and safety text (right for non-coding agents or a different persona). Python also accepts `{"type":"file","path":…}` for very large prompts. `CLAUDE.md` and output styles layer on top of any of these.

### 5.15 Structured output

`output_format={"type":"json_schema","schema":{…}}` makes the *final* answer conform to a JSON Schema (draft-07 subset: objects, arrays, enums, `required`, `$ref`; `format` is advisory). The agent still uses tools freely; the validated object arrives as `result.structured_output`. Failure → subtype `error_max_structured_output_retries`; also treat `success` without `structured_output` as failure. TypeScript: derive the schema from Zod with `z.toJSONSchema(Findings, { target: "draft-7" })` and `Findings.parse()` the result; Python: a plain dict (or Pydantic's `model_json_schema()` / `model_validate()`). CLI twin: `claude -p --json-schema` (Module 4) — the lab reuses M4's findings schema on purpose.

### 5.16 Effort and thinking

`effort` (`low`…`max`) is the same dial as `/effort`; set it per query and per `AgentDefinition`. `thinking={"type":"adaptive"}` is the modern default on current models; `{"type":"enabled","budget_tokens":N}` and `{"type":"disabled"}` exist; `display: "summarized"|"omitted"` controls whether thinking blocks are streamed to you. Cheap mechanical stages → `low`; the verifier/judge stage → `high`. Measure with `model_usage`, don't guess.

### 5.17 Cost and usage tracking

Per step: `AssistantMessage.usage` + `message_id` (TS `msg.message.usage` + `msg.message.id`); parallel tool calls emit several assistant messages that **share one id — dedupe by id**. Per run: `total_cost_usd` and `model_usage`/`modelUsage` on the result (whole tree); `usage` undercounts once subagents run. Across runs: sum the results yourself (in streaming-input mode each result is cumulative for the session — read the latest, don't add). Prompt caching is automatic; watch `cache_read_input_tokens` jump on the lab's follow-up query. `max_budget_usd` trips on the same estimate. After a crash the final `error_during_execution` result may carry zeros — keep the previous totals.

### 5.18 Observability

The agent process has OpenTelemetry built in; the SDK just passes environment through (`env` option or process env). Minimum viable config: `CLAUDE_CODE_ENABLE_TELEMETRY=1`, `OTEL_METRICS_EXPORTER=otlp`, `OTEL_LOGS_EXPORTER=otlp`, `OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318`, `OTEL_SERVICE_NAME=bughunter`, `OTEL_RESOURCE_ATTRIBUTES=tenant.id=…`; traces are an opt-in beta (`CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1`, `OTEL_TRACES_EXPORTER=otlp`) with spans `claude_code.interaction → llm_request / tool / hook`, subagents nested under their `Agent` tool span. Prompt and tool *content* are off unless you set the `OTEL_LOG_*` switches. Your app's active W3C trace context propagates into the agent (Python needs the `claude-agent-sdk[otel]` extra). Fitting, given today's target repo is the OpenTelemetry demo. Event/metric catalogue: Claude Code monitoring docs (telemetry variables: reference §C.7 and the observability row of §K.4).

### 5.19 Hosting and production checklist

- **Shape:** one session = one long-lived child process with local state. Patterns: *ephemeral* container per task (our CLI, CI jobs), *long-running* worker (`ClaudeSDKClient` / TS `startup()` pre-warm + `streamInput`), *hybrid* (ephemeral containers hydrating from a `SessionStore`). Budget roughly 1 vCPU / 1 GiB RAM / a few GiB disk per concurrent agent and recycle long sessions.
- **Sandbox the hands:** run in a container/microVM (Docker with `--cap-drop ALL --security-opt no-new-privileges --read-only --network none --user 1000:1000` and code mounted read-only; gVisor/Firecracker or a hosted sandbox provider for stronger isolation); or at minimum enable the `sandbox` option for Bash. `labs/m5-agent-sdk/Dockerfile.hardened` is the worked example (stretch e).
- **Secrets:** `ANTHROPIC_API_KEY` from a secret manager, or no key in the container at all — point `ANTHROPIC_BASE_URL` at a credential-injecting egress proxy; keep third-party tokens in MCP servers/proxies outside the agent boundary; deny reads of `.env`/`secrets/` (you just wrote that hook).
- **Network:** egress allowlist (Claude API or your provider endpoint, package registries you trust, MCP endpoints); `HTTPS_PROXY` is honoured.
- **Multi-tenant isolation:** `setting_sources=[]`, per-tenant `cwd` and `CLAUDE_CONFIG_DIR`, `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`, per-tenant egress rules; never share a process between tenants.
- **Limits:** always set `max_turns` and `max_budget_usd`; cap subagent fan-out; there is no wall-clock session timeout — enforce one in your supervisor; retry/`CLAUDE_CODE_MAX_RETRIES` for unattended runs.
- **Permissions:** `dontAsk` + explicit `allowed_tools`, or `default` + `can_use_tool`; scoped `disallowed_tools` for the never-evers; never rely on `allowed_tools` to tame `bypassPermissions`.
- **Operate:** wrap `query()` in try/except; log `session_id`, `terminal_reason`, `permission_denials`, `model_usage`; export OTel; upgrade the SDK continuously (it carries the Claude Code binary) and read the changelog before minor bumps.
- **Or don't host it:** if this list is longer than your appetite, Module 6 shows the same agent as a Claude Managed Agent.

## Live demo script (12 min)

1. **(3 min) Anatomy slide.** Draw the 5.1 diagram; put the 5.1 mapping table next to it and physically point from each morning artifact to its option name. One sentence on auth policy and on "the SDK bundles the binary".
2. **(6 min) Live-code from an empty file (Python).** In `$WS/labs/m5-agent-sdk/python`: `uv run python demo.py` with the 5.3 program (`cwd=$OTEL`, `allowed_tools=["Read","Grep","Glob"]`, `permission_mode="dontAsk"`), prompt *"Give me a one-paragraph tour of src/paymentservice."* Narrate the stream: init (show `apiKeySource`, `model`), `-> Grep`, `-> Read`, text, `Done: success $0.0…`. Then add **two lines** — `plugins=[{"type":"local","path": f"{OTEL}/../codebase-toolkit"}]` and `"Agent"` in `allowed_tools` — change the prompt to *"Use the codebase-toolkit:bug-hunter agent to analyze src/adservice; give me its top three findings."* Run; point at `plugins: ['codebase-toolkit']` in init and the `-> Agent` call: *the morning's work, reused from code in one line.* Show the TS equivalent on a slide (5.3, plus `plugins: [{ type: "local", path }]`).
3. **(3 min) Lab map.** Open `starter/bughunter/__main__.py`, scroll the `TODO(step-n)` markers, map each to a section above (step 2 → 5.15, step 3 → 5.10, step 4 → 5.8/5.9, step 5 → 5.7/5.17). Remind: `max_budget_usd=1.0` is pre-set; `MODEL` comes from `labs/.env`; Python is the talk-track language, the TypeScript starter has identical step markers.

## Hands-on lab (38 min) — build `bughunter`

**Goal:** a CLI, `bughunter <service-path> [--ticket]` and `bughunter followup "<question>"`, that reuses the `codebase-toolkit` plugin's bug-hunter agent, returns schema-validated findings, files tickets through a custom tool under a code-enforced policy, prints cost/usage, and resumes its session.

**Start state:** CP4 (materially: `$OTEL` with `CLAUDE.md` + `.claude/settings.json` from M1–M2, and the plugin directory `$OTEL/../codebase-toolkit` from M3/CP3). `source $WS/labs/.env` has exported `ANTHROPIC_API_KEY`, `MODEL`, `WS`, `OTEL`. Preflight verified that `claude-agent-sdk` imports (its `--install` flag syncs the shared `labs/m5-agent-sdk/python` env, and `--ts --install` runs `npm ci` for the TypeScript track); the `starter/` directory is its own project, so install its dependencies once now — it takes seconds with a warm cache:

```bash
cd $WS/labs/m5-agent-sdk/python/starter && uv sync       # Python track — run with:  uv run bughunter <args>
cd $WS/labs/m5-agent-sdk/typescript/starter && npm ci    # TS track     — run with:  npx tsx src/main.ts <args>
```

Each step below names the `TODO(step-n)` block to fill and shows the essential lines (Python; the TS block is the camelCase twin). The **complete solution files for both languages follow the steps** — if a step fights you for more than its minute budget, copy that block from `../solution/` and move on.

### Step 1 (6 min) — Run the loop

Fill `base_options()` and the message loop in `__main__.py` / `main.ts`:

```python
ClaudeAgentOptions(cwd=str(OTEL), model=MODEL, setting_sources=["project"],
                   plugins=[{"type": "local", "path": str(PLUGIN)}],
                   allowed_tools=["Read", "Grep", "Glob", "Agent"], permission_mode="dontAsk",
                   max_turns=40, max_budget_usd=1.00)
```

Print `TextBlock.text`, `-> {ToolUseBlock.name}`, and on the `ResultMessage` `Done: {subtype} ${total_cost_usd:.4f}`. From the init message print `plugins` and `apiKeySource`.

**Success check:** `uv run bughunter src/paymentservice` (TS: `npx tsx src/main.ts src/paymentservice`) prints `plugins: ['codebase-toolkit']`, at least one `-> Agent` line, an analysis, and `Done: success $0.0x`.

### Step 2 (6 min) — Structured output

Add `output_format={"type": "json_schema", "schema": FINDINGS_SCHEMA}` (TS: `outputFormat: { type: "json_schema", schema: FINDINGS_JSON_SCHEMA }`). The schema (`schema.py`/`schema.ts`) is deliberately the same shape as the Claude Security findings JSONL you will meet in Module 7, minus the CWE field: `findings[] {id, title, severity HIGH|MEDIUM|LOW, file, line, category, description, recommendation, confidence low|medium|high}`. In `report()`, write `result.structured_output` to `$OTEL/reports/<service>.findings.json`.

**Success check:** `uv run python -m bughunter.validate` (TS: `npx tsx src/validate.ts`) prints `OK: N findings valid`.

### Step 3 (8 min) — Custom tool

In `tools.py`/`tools.ts` implement `create_ticket(title, severity, file, line) -> ticket_id` (appends to `tickets.json` in the lab directory) with `@tool`/`tool()`, wrap it with `create_sdk_mcp_server(name="tracker", …)`, then in the options add `mcp_servers={"tracker": tracker_server}` and append `"mcp__tracker__create_ticket"` to `allowed_tools`. Wire the `--ticket` flag so the prompt gains: *"After producing the findings, call the create_ticket tool once for each HIGH severity finding."*

**Success check:** `uv run bughunter src/paymentservice --ticket` shows `-> mcp__tracker__create_ticket` in the transcript and `cat tickets.json` has entries with `AST-0001`-style ids.

### Step 4 (7 min) — Guardrails in code

(a) Register the `PreToolUse` hook from 5.9: `hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets_hook])]}`.
(b) Add `can_use_tool=ticket_policy` (5.8), switch `permission_mode` to `"default"` so fall-through calls consult the callback, and **remove** `mcp__tracker__create_ticket` from `allowed_tools` (otherwise the allow rule short-circuits your policy — 5.8 evaluation order). Python: pass the prompt as `as_stream(prompt)`. Change the `--ticket` prompt suffix to *"…for each HIGH **or MEDIUM** finding"* so the policy has something to refuse.

**Success check:** `uv run bughunter src/currencyservice --ticket` logs at least one `denied create_ticket (MEDIUM)` line, Claude's text acknowledges that only HIGH items were ticketed, and `tickets.json` gained only HIGH entries. (No MEDIUM findings in that service today? Try `src/adservice`.)

### Step 5 (6 min) — Cost, sessions, resume

In `report()` print `usage` (`input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`) and the per-model breakdown from `model_usage` (`costUSD`, `inputTokens`, `outputTokens`); write `result.session_id` to `.bughunter-session`. Implement `followup`: `query(prompt=question, options=base_options(resume=session_id))` — read-only, `dontAsk`, same `cwd` (transcripts are keyed by it).

**Success check:** `uv run bughunter followup "Which of those findings would you fix first, and why?"` answers about the *earlier* findings without re-running the bug-hunter (few or no `-> Agent`/`-> Read` lines) and the printed `cache_read` count is far larger than in step 1.

### Step 6 (5 min) — Debrief prep

Open `../solution/` in the *other* language and diff mentally: what is identical (option names modulo case, message flow, hook JSON), what differs (`isinstance` vs `type`, `env` merge vs replace, Zod vs dict schema, `ClaudeSDKClient` vs generator). Then list what you would change to run `bughunter` in CI: key from a secret, `setting_sources=[]` plus explicit `system_prompt`/`agents` (the SDK analogue of `claude -p --bare`), a container per run (5.19), `reports/` uploaded as an artifact, exit code from `result.subtype`.

### Complete solution — Python (`labs/m5-agent-sdk/python/solution/`)

`pyproject.toml`
```toml
[project]
name = "bughunter"
version = "4.0.0"
description = "Workshop M5: Claude Agent SDK bug-hunting CLI"
requires-python = ">=3.10"
dependencies = ["claude-agent-sdk", "jsonschema>=4.20"]

[project.scripts]
bughunter = "bughunter.__main__:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["bughunter"]
```

`bughunter/__init__.py` is empty. `bughunter/schema.py`
```python
"""Findings schema — same shape as labs/shared/findings.schema.json (M4) and Claude Security JSONL minus cwe_id (M7)."""
FINDING = {
    "type": "object",
    "properties": {
        "id": {"type": "string", "description": "F1, F2, ..."},
        "title": {"type": "string"},
        "severity": {"type": "string", "enum": ["HIGH", "MEDIUM", "LOW"]},
        "file": {"type": "string", "description": "path relative to the repository root"},
        "line": {"type": "integer", "minimum": 1},
        "category": {"type": "string", "description": "e.g. error-handling, concurrency, input-validation, resource-leak, security"},
        "description": {"type": "string"},
        "recommendation": {"type": "string"},
        "confidence": {"type": "string", "enum": ["low", "medium", "high"]},
    },
    "required": ["id", "title", "severity", "file", "line", "category", "description", "recommendation", "confidence"],
    "additionalProperties": False,
}
FINDINGS_SCHEMA = {
    "type": "object",
    "properties": {
        "service": {"type": "string"},
        "summary": {"type": "string"},
        "findings": {"type": "array", "items": FINDING},
    },
    "required": ["service", "summary", "findings"],
    "additionalProperties": False,
}
```

`bughunter/tools.py`
```python
"""Step 3 — custom tool served from an in-process SDK MCP server. M6 reuses append_ticket() via labs/shared/tickets.py."""
import json
import time
from pathlib import Path
from typing import Any

from claude_agent_sdk import create_sdk_mcp_server, tool

TICKETS = Path("tickets.json")          # lives in the directory you run bughunter from


def append_ticket(title: str, severity: str, file: str, line: int) -> str:
    tickets = json.loads(TICKETS.read_text()) if TICKETS.exists() else []
    ticket_id = f"AST-{len(tickets) + 1:04d}"
    tickets.append({"id": ticket_id, "title": title, "severity": severity, "file": file, "line": line,
                    "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
    TICKETS.write_text(json.dumps(tickets, indent=2))
    return ticket_id


@tool("create_ticket",
      "File a bug ticket in the Astronomy Shop tracker for one confirmed finding. Returns the new ticket id.",
      {"title": str, "severity": str, "file": str, "line": int})
async def create_ticket(args: dict[str, Any]) -> dict[str, Any]:
    severity = str(args.get("severity", "")).upper()
    if severity not in {"HIGH", "MEDIUM", "LOW"}:
        # is_error tells Claude the call failed (and why) without killing the loop
        return {"content": [{"type": "text", "text": f"severity must be HIGH, MEDIUM or LOW, got {args.get('severity')!r}"}],
                "is_error": True}
    ticket_id = append_ticket(args["title"], severity, args["file"], int(args["line"]))
    return {"content": [{"type": "text", "text": f"created {ticket_id} for {args['file']}:{args['line']}"}]}


tracker_server = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
TICKET_TOOL = "mcp__tracker__create_ticket"   # mcp__<key in mcp_servers>__<tool name>
```

`bughunter/hooks.py`
```python
"""Step 4 — guardrails as code: a PreToolUse hook callback and a can_use_tool permission callback."""
import re

from claude_agent_sdk import PermissionResultAllow, PermissionResultDeny

from .tools import TICKET_TOOL

PROTECTED = re.compile(r"(^|/)\.env(\.[^/]*)?$|(^|/)secrets/")


async def protect_secrets_hook(input_data, tool_use_id, context):
    """PreToolUse (matcher='Read'): deny reads of .env* and secrets/ — fires in subagents too."""
    path = input_data.get("tool_input", {}).get("file_path", "")
    if PROTECTED.search(path):
        print(f"  [hook] denied Read {path}")
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": f"bughunter policy: {path} is a protected path"}}
    return {}


async def ticket_policy(tool_name, input_data, context):
    """can_use_tool: reached only by calls that no rule/mode already decided (so NOT by allowed_tools entries)."""
    if tool_name == TICKET_TOOL:
        severity = str(input_data.get("severity", "")).upper()
        if severity == "HIGH":
            print("  [policy] allowed create_ticket (HIGH)")
            return PermissionResultAllow(updated_input=input_data)
        print(f"  [policy] denied create_ticket ({severity})")
        return PermissionResultDeny(message="only HIGH severity gets a ticket; mention lower-severity items in the summary instead")
    return PermissionResultDeny(message=f"{tool_name} is not permitted in bughunter")
```

`bughunter/__main__.py`
```python
"""bughunter — Claude Agent SDK lab (Module 5).

  uv run bughunter <service-path> [--ticket]     analyze one service of $OTEL with the codebase-toolkit bug-hunter agent
  uv run bughunter followup "<question>"         resume the last session and ask a follow-up
"""
import asyncio
import json
import os
import sys
from pathlib import Path

from claude_agent_sdk import (AssistantMessage, ClaudeAgentOptions, HookMatcher, ResultMessage, SystemMessage,
                              TextBlock, ToolUseBlock, query)

from .hooks import protect_secrets_hook, ticket_policy
from .schema import FINDINGS_SCHEMA
from .tools import tracker_server

OTEL = Path(os.environ.get("OTEL", ".")).resolve()                                    # the repo the agent works in
PLUGIN = Path(os.environ.get("TOOLKIT_PLUGIN", str(OTEL.parent / "codebase-toolkit"))).resolve()  # M3 plugin dir
MODEL = os.environ.get("MODEL", "sonnet")                                             # single place to bump: labs/.env
SESSION_FILE = Path(".bughunter-session")

PROMPT = ("Use the codebase-toolkit:bug-hunter agent to analyze the service at `{service}` for bugs "
          "(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). "
          "Then consolidate its report into the required JSON findings object for service `{service}`. "
          "Every finding needs a real file path relative to the repository root and a line number you have verified.")
TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH or MEDIUM severity finding."


def base_options(**overrides) -> ClaudeAgentOptions:
    """Step 1 — the locked-down, read-only baseline (also used by `followup`)."""
    opts = dict(
        cwd=str(OTEL),
        model=MODEL,
        setting_sources=["project"],                       # $OTEL/CLAUDE.md, .claude/settings.json, rules — nothing from ~/.claude
        plugins=[{"type": "local", "path": str(PLUGIN)}],  # agents + skill + hooks + MCP config packaged in M3
        allowed_tools=["Read", "Grep", "Glob", "Agent"],   # step 3 temporarily also listed mcp__tracker__create_ticket here
        permission_mode="dontAsk",
        max_turns=40,
        max_budget_usd=1.00,
    )
    opts.update(overrides)
    return ClaudeAgentOptions(**opts)


async def as_stream(text: str):
    """Streaming-input form of a single prompt (step 4): the documented shape for can_use_tool with query()."""
    yield {"type": "user", "message": {"role": "user", "content": text}}


async def consume(messages) -> ResultMessage | None:
    """Print the stream; return the final ResultMessage (single-shot query() raises AFTER yielding an error result)."""
    result = None
    try:
        async for msg in messages:
            if isinstance(msg, SystemMessage) and msg.subtype == "init":
                print(f"model={msg.data.get('model')} auth={msg.data.get('apiKeySource')} "
                      f"plugins={[p.get('name') for p in msg.data.get('plugins', [])]}")
            elif isinstance(msg, AssistantMessage):
                prefix = "    (subagent) " if msg.parent_tool_use_id else ""
                for block in msg.content:
                    if isinstance(block, TextBlock) and not prefix:
                        print(block.text)
                    elif isinstance(block, ToolUseBlock):
                        print(f"{prefix}-> {block.name}")
            elif isinstance(msg, ResultMessage):
                result = msg
    except Exception as exc:  # noqa: BLE001 — keep the last result we saw, report the error
        print(f"query ended with an error: {exc}", file=sys.stderr)
    return result


def report(result: ResultMessage, service: str | None) -> int:
    """Steps 2 & 5 — findings file, cost/usage, session id."""
    print(f"\nDone: {result.subtype} ${result.total_cost_usd or 0:.4f} "
          f"(turns={result.num_turns}, terminal_reason={result.terminal_reason}, session={result.session_id})")
    for denial in result.permission_denials or []:
        print(f"  permission denial: {denial}")
    u = result.usage or {}
    print(f"usage(main loop): in={u.get('input_tokens', 0)} out={u.get('output_tokens', 0)} "
          f"cache_read={u.get('cache_read_input_tokens', 0)} cache_write={u.get('cache_creation_input_tokens', 0)}")
    for model, mu in (result.model_usage or {}).items():               # whole tree incl. subagents; camelCase keys
        print(f"  {model}: ${mu.get('costUSD', 0):.4f} in={mu.get('inputTokens')} out={mu.get('outputTokens')} "
              f"cache_read={mu.get('cacheReadInputTokens')}")
    SESSION_FILE.write_text(result.session_id)
    if service and result.structured_output:
        out = OTEL / "reports" / f"{Path(service).name}.findings.json"
        out.parent.mkdir(exist_ok=True)
        out.write_text(json.dumps(result.structured_output, indent=2))
        print(f"wrote {out} ({len(result.structured_output.get('findings', []))} findings)")
    elif service:
        print("no structured_output on the result — treat as failure", file=sys.stderr)
        return 1
    return 0 if result.subtype == "success" else 1


async def run(service: str, ticket: bool) -> int:
    prompt = PROMPT.format(service=service) + (TICKET_SUFFIX if ticket else "")
    options = base_options(
        output_format={"type": "json_schema", "schema": FINDINGS_SCHEMA},                        # step 2
        mcp_servers={"tracker": tracker_server},                                                 # step 3
        hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets_hook])]},       # step 4a
        can_use_tool=ticket_policy,                                                              # step 4b
        permission_mode="default",                                                               # step 4b (was dontAsk)
    )
    result = await consume(query(prompt=as_stream(prompt), options=options))
    return report(result, service) if result else 1


async def followup(question: str) -> int:
    if not SESSION_FILE.exists():
        print("no .bughunter-session yet — run an analysis first", file=sys.stderr)
        return 2
    options = base_options(resume=SESSION_FILE.read_text().strip())                             # step 5
    result = await consume(query(prompt=question, options=options))
    return report(result, None) if result else 1


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] in {"-h", "--help"}:
        print(__doc__)
        sys.exit(2)
    if not (os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("CLAUDE_CODE_USE_BEDROCK")
            or os.environ.get("CLAUDE_CODE_USE_VERTEX") or os.environ.get("CLAUDE_CODE_USE_FOUNDRY")):
        print("warning: no ANTHROPIC_API_KEY / provider env set — see module 5.2", file=sys.stderr)
    if args[0] == "followup":
        sys.exit(asyncio.run(followup(" ".join(args[1:]) or "Summarize the findings in three bullets.")))
    sys.exit(asyncio.run(run(args[0], "--ticket" in args[1:])))


if __name__ == "__main__":
    main()
```

`bughunter/validate.py`
```python
"""Step 2 success check: uv run python -m bughunter.validate [path-to-findings.json]"""
import json
import os
import sys
from pathlib import Path

from jsonschema import validate

from .schema import FINDINGS_SCHEMA

OTEL = Path(os.environ.get("OTEL", ".")).resolve()
path = Path(sys.argv[1]) if len(sys.argv) > 1 else max((OTEL / "reports").glob("*.findings.json"), key=lambda p: p.stat().st_mtime)
data = json.loads(path.read_text())
validate(instance=data, schema=FINDINGS_SCHEMA)          # raises jsonschema.ValidationError with a precise path on failure
print(f"OK: {len(data['findings'])} findings valid in {path}")
```

### Complete solution — TypeScript (`labs/m5-agent-sdk/typescript/solution/`)

`package.json` (versions are the "current line" as of August 2026 — see the volatile-facts callout)
```json
{
  "name": "bughunter",
  "version": "4.0.0",
  "private": true,
  "type": "module",
  "scripts": { "bughunter": "tsx src/main.ts", "validate": "tsx src/validate.ts", "typecheck": "tsc --noEmit" },
  "dependencies": { "@anthropic-ai/claude-agent-sdk": "^0.3.0", "zod": "^4.0.0" },
  "devDependencies": { "tsx": "^4.19.0", "typescript": "^5.6.0", "@types/node": "^22.0.0" }
}
```

`src/schema.ts`
```ts
import { z } from "zod";

export const Finding = z.object({
  id: z.string(), title: z.string(), severity: z.enum(["HIGH", "MEDIUM", "LOW"]),
  file: z.string(), line: z.number().int().min(1), category: z.string(),
  description: z.string(), recommendation: z.string(), confidence: z.enum(["low", "medium", "high"]),
});
export const Findings = z.object({ service: z.string(), summary: z.string(), findings: z.array(Finding) });
export type Findings = z.infer<typeof Findings>;
// The SDK validates against JSON Schema draft-07; Zod 4 emits 2020-12 unless told otherwise.
export const FINDINGS_JSON_SCHEMA = z.toJSONSchema(Findings, { target: "draft-7" }) as Record<string, unknown>;
```

`src/tools.ts`
```ts
import { createSdkMcpServer, tool } from "@anthropic-ai/claude-agent-sdk";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { z } from "zod";

const TICKETS = "tickets.json";
export const TICKET_TOOL = "mcp__tracker__create_ticket";

export function appendTicket(title: string, severity: string, file: string, line: number): string {
  const tickets: unknown[] = existsSync(TICKETS) ? JSON.parse(readFileSync(TICKETS, "utf8")) : [];
  const id = `AST-${String(tickets.length + 1).padStart(4, "0")}`;
  tickets.push({ id, title, severity, file, line, created: new Date().toISOString() });
  writeFileSync(TICKETS, JSON.stringify(tickets, null, 2));
  return id;
}

const createTicket = tool(
  "create_ticket",
  "File a bug ticket in the Astronomy Shop tracker for one confirmed finding. Returns the new ticket id.",
  { title: z.string(), severity: z.string().describe("HIGH | MEDIUM | LOW"), file: z.string(), line: z.number().int() },
  async (args) => {
    const severity = args.severity.toUpperCase();
    if (!["HIGH", "MEDIUM", "LOW"].includes(severity)) {
      return { content: [{ type: "text", text: `severity must be HIGH, MEDIUM or LOW, got ${args.severity}` }], isError: true };
    }
    const id = appendTicket(args.title, severity, args.file, args.line);
    return { content: [{ type: "text", text: `created ${id} for ${args.file}:${args.line}` }] };
  },
);

export const trackerServer = createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] });
```

`src/hooks.ts`
```ts
import type { CanUseTool, HookCallback, PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";
import { TICKET_TOOL } from "./tools.js";

const PROTECTED = /(^|\/)\.env(\.[^/]*)?$|(^|\/)secrets\//;

export const protectSecretsHook: HookCallback = async (input) => {
  const filePath = String(((input as PreToolUseHookInput).tool_input as { file_path?: string })?.file_path ?? "");
  if (PROTECTED.test(filePath)) {
    console.log(`  [hook] denied Read ${filePath}`);
    return { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny",
                                   permissionDecisionReason: `bughunter policy: ${filePath} is a protected path` } };
  }
  return {};
};

export const ticketPolicy: CanUseTool = async (toolName, input) => {
  if (toolName === TICKET_TOOL) {
    const severity = String(input.severity ?? "").toUpperCase();
    if (severity === "HIGH") { console.log("  [policy] allowed create_ticket (HIGH)"); return { behavior: "allow", updatedInput: input }; }
    console.log(`  [policy] denied create_ticket (${severity})`);
    return { behavior: "deny", message: "only HIGH severity gets a ticket; mention lower-severity items in the summary instead" };
  }
  return { behavior: "deny", message: `${toolName} is not permitted in bughunter` };
};
```

`src/main.ts`
```ts
/* bughunter — Claude Agent SDK lab (Module 5), TypeScript track.
 *   npx tsx src/main.ts <service-path> [--ticket]
 *   npx tsx src/main.ts followup "<question>"                                  */
import { query, type Options, type SDKResultMessage } from "@anthropic-ai/claude-agent-sdk";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { protectSecretsHook, ticketPolicy } from "./hooks.js";
import { FINDINGS_JSON_SCHEMA, Findings } from "./schema.js";
import { trackerServer } from "./tools.js";

export const OTEL = path.resolve(process.env.OTEL ?? ".");
const PLUGIN = path.resolve(process.env.TOOLKIT_PLUGIN ?? path.join(OTEL, "..", "codebase-toolkit"));
const MODEL = process.env.MODEL ?? "sonnet";
const SESSION_FILE = ".bughunter-session";

const PROMPT = (service: string) =>
  `Use the codebase-toolkit:bug-hunter agent to analyze the service at \`${service}\` for bugs ` +
  `(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). ` +
  `Then consolidate its report into the required JSON findings object for service \`${service}\`. ` +
  `Every finding needs a real file path relative to the repository root and a line number you have verified.`;
const TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH or MEDIUM severity finding.";

function baseOptions(overrides: Partial<Options> = {}): Options {          // step 1
  return {
    cwd: OTEL, model: MODEL,
    settingSources: ["project"],
    plugins: [{ type: "local", path: PLUGIN }],
    allowedTools: ["Read", "Grep", "Glob", "Agent"],                        // step 3 temporarily also listed mcp__tracker__create_ticket
    permissionMode: "dontAsk", maxTurns: 40, maxBudgetUsd: 1.0,
    ...overrides,                                                           // NB: never pass `env` without spreading process.env (TS replaces it)
  };
}

async function consume(messages: AsyncIterable<any>): Promise<SDKResultMessage | undefined> {
  let result: SDKResultMessage | undefined;
  try {
    for await (const msg of messages) {
      if (msg.type === "system" && msg.subtype === "init") {
        console.log(`model=${msg.model} auth=${msg.apiKeySource} plugins=${JSON.stringify(msg.plugins.map((p: any) => p.name))}`);
      } else if (msg.type === "assistant") {
        const prefix = msg.parent_tool_use_id ? "    (subagent) " : "";
        for (const block of msg.message.content) {
          if (block.type === "text" && !prefix) console.log(block.text);
          else if (block.type === "tool_use") console.log(`${prefix}-> ${block.name}`);
        }
      } else if (msg.type === "result") {
        result = msg;
      }
    }
  } catch (err) {                       // single-shot query() throws AFTER yielding an error result
    console.error(`query ended with an error: ${err}`);
  }
  return result;
}

function report(result: SDKResultMessage, service?: string): number {     // steps 2 & 5
  console.log(`\nDone: ${result.subtype} $${result.total_cost_usd.toFixed(4)} ` +
    `(turns=${result.num_turns}, terminal_reason=${result.terminal_reason}, session=${result.session_id})`);
  for (const d of result.permission_denials ?? []) console.log(`  permission denial: ${JSON.stringify(d)}`);
  const u = result.usage;
  console.log(`usage(main loop): in=${u.input_tokens} out=${u.output_tokens} cache_read=${u.cache_read_input_tokens} cache_write=${u.cache_creation_input_tokens}`);
  for (const [model, mu] of Object.entries(result.modelUsage)) {
    console.log(`  ${model}: $${mu.costUSD.toFixed(4)} in=${mu.inputTokens} out=${mu.outputTokens} cache_read=${mu.cacheReadInputTokens}`);
  }
  writeFileSync(SESSION_FILE, result.session_id);
  const structured = result.subtype === "success" ? result.structured_output : undefined;
  if (service && structured) {
    const findings = Findings.parse(structured);                            // belt and braces: Zod-parse what the SDK validated
    const out = path.join(OTEL, "reports", `${path.basename(service)}.findings.json`);
    mkdirSync(path.dirname(out), { recursive: true });
    writeFileSync(out, JSON.stringify(findings, null, 2));
    console.log(`wrote ${out} (${findings.findings.length} findings)`);
  } else if (service) {
    console.error("no structured_output on the result — treat as failure");
    return 1;
  }
  return result.subtype === "success" ? 0 : 1;
}

async function run(service: string, ticket: boolean): Promise<number> {
  const options = baseOptions({
    outputFormat: { type: "json_schema", schema: FINDINGS_JSON_SCHEMA },   // step 2
    mcpServers: { tracker: trackerServer },                                 // step 3
    hooks: { PreToolUse: [{ matcher: "Read", hooks: [protectSecretsHook] }] },  // step 4a
    canUseTool: ticketPolicy,                                               // step 4b
    permissionMode: "default",                                              // step 4b (was dontAsk)
  });
  const result = await consume(query({ prompt: PROMPT(service) + (ticket ? TICKET_SUFFIX : ""), options }));
  return result ? report(result, service) : 1;
}

async function followup(question: string): Promise<number> {
  if (!existsSync(SESSION_FILE)) { console.error("no .bughunter-session yet — run an analysis first"); return 2; }
  const options = baseOptions({ resume: readFileSync(SESSION_FILE, "utf8").trim() });   // step 5
  const result = await consume(query({ prompt: question, options }));
  return result ? report(result) : 1;
}

const args = process.argv.slice(2);
if (args.length === 0) { console.error("usage: bughunter <service-path> [--ticket] | bughunter followup \"<question>\""); process.exit(2); }
if (!process.env.ANTHROPIC_API_KEY && !process.env.CLAUDE_CODE_USE_BEDROCK && !process.env.CLAUDE_CODE_USE_VERTEX && !process.env.CLAUDE_CODE_USE_FOUNDRY) {
  console.error("warning: no ANTHROPIC_API_KEY / provider env set — see module 5.2");
}
const code = args[0] === "followup"
  ? await followup(args.slice(1).join(" ") || "Summarize the findings in three bullets.")
  : await run(args[0], args.slice(1).includes("--ticket"));
process.exit(code);
```

`src/validate.ts`
```ts
import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { Findings } from "./schema.js";

const OTEL = path.resolve(process.env.OTEL ?? ".");
const dir = path.join(OTEL, "reports");
const file = process.argv[2] ?? readdirSync(dir).filter((f) => f.endsWith(".findings.json"))
  .map((f) => path.join(dir, f)).sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];
const parsed = Findings.parse(JSON.parse(readFileSync(file, "utf8")));   // throws ZodError listing every violation
console.log(`OK: ${parsed.findings.length} findings valid in ${file}`);
```

## If you're behind (fast-forward)

- `./labs/checkpoint.sh CP5 --force` copies `solution/` over `starter/` for your chosen language track (the starter files always differ from the solution, so without `--force` they are reported as conflicts and kept; with it your versions are backed up to `.checkpoint-backup/` first), runs the step-1 success check, and leaves you a valid `reports/paymentservice.findings.json`, `tickets.json` and `.bughunter-session` so Module 6 and the M7 stretch have inputs. Add `--dry-run` to preview.
- No API key and no pairing partner: read `labs/m5-agent-sdk/expected-output/` (captured transcripts for steps 1, 3, 4 and 5 plus the findings file) while following the solution code; you can still do step 6.
- Missing the plugin directory (skipped M3): run `./labs/checkpoint.sh CP3` first (it writes `$OTEL/../codebase-toolkit`), or point `TOOLKIT_PLUGIN` at any copy of the plugin (for example `$OTEL/../workshop-marketplace/codebase-toolkit`).

## Troubleshooting

| Symptom | Cause → fix |
|---|---|
| `CLINotFoundError` / `Native CLI binary for <platform> not found` | Source-only Python install (e.g. Windows on ARM) or `npm ci --omit=optional`. Install Claude Code natively and set `cli_path=` / `pathToClaudeCodeExecutable`, or reinstall without omitting optional deps. |
| Init prints `auth=none` or an OAuth source, or a 400 "organization has been disabled" | The agent process fell back to a `claude` login or a stale key. `export ANTHROPIC_API_KEY=…` in *this* shell (`source labs/.env`); `unset` old keys; re-run. Products you ship must use API-key or cloud-provider auth. |
| Run "succeeds" but no analysis / `plugins=[]` / no `-> Agent` | Plugin path wrong (`echo $OTEL`; `ls $OTEL/../codebase-toolkit/.claude-plugin`) or `Agent` missing from `allowed_tools` under `dontAsk`. Read `permission_denials` on the result — it names the tool (may say `Task`, the Agent tool's legacy name). |
| Plugin listed twice in init | It is also enabled at project scope from M3 step 11 (`enabledPlugins` in `.claude/settings.json` loads via `setting_sources=["project"]`). Harmless; or drop the `plugins=[…]` option. |
| `mcp__tracker__create_ticket` never called / denied in step 3 | Name mismatch: it is `mcp__` + the **key** you used in `mcp_servers` (`tracker`) + `__create_ticket`. Under `dontAsk` it must be in `allowed_tools`. |
| Step 4: policy callback never fires, tickets filed for MEDIUM | You left `mcp__tracker__create_ticket` in `allowed_tools` (allow rules win before `can_use_tool`), or `permission_mode` is still `dontAsk` (fall-through = deny, callback skipped). Python on an older SDK: make sure the prompt goes through `as_stream()`. |
| `error_max_structured_output_retries` or `success` without `structured_output` | Schema too strict for what the agent found (e.g. it wants to omit `line`). Loosen (`additionalProperties`, fewer `required`), or tell the prompt exactly what to put in each field. Invalid schemas fail at startup with a clear message. |
| `error_max_budget_usd` / `error_max_turns` | Raise `max_budget_usd`/`max_turns` modestly, or drop `effort`; large services (frontend) cost more — start with `src/paymentservice`. |
| TS: `Cannot find module 'zod'` or type errors mentioning `@anthropic-ai/sdk` / `@modelcontextprotocol/sdk` | Peer dependencies: `npm install zod` (npm 7+ installs the other peers automatically; with yarn classic add them explicitly). |
| Python `RuntimeError: asyncio.run() cannot be called from a running event loop` | You are in a notebook/REPL. Run the script (`uv run bughunter …`) or use `await run(...)` directly. Python < 3.10 fails at install — check `uv run python -V`. |
| `followup` starts a fresh conversation | Different `cwd` than the original run (transcripts are per-cwd), `.bughunter-session` missing, or you ran the other language track (each wrote its own file in its own directory). |
| Windows: `cwd`/plugin path errors | Use absolute paths; in Git Bash `export OTEL=$(cygpath -m "$OTEL")`; avoid `~`. |
| Hook denies nothing / M2 shell hook errors appear | Matchers are tool names (`Read`), case-sensitive; path filtering happens inside the callback. The plugin's `protect-files.sh` also runs — if `jq` is missing it logs an error but does not block reads. |

## Stretch goals

- **(a) Programmatic fan-out.** Add the `lang-scout` `AgentDefinition` from 5.12 plus one `bug-hunter-<lang>` per language group it reports; prompt the main agent to run them in parallel and merge findings (dedupe by `file:line`). Compare `model_usage` per model.
- **(b) Interactive REPL.** Wrap `base_options()` in the `ClaudeSDKClient` loop from 5.6 (`uv run python -m bughunter.repl`); hit Ctrl+C mid-turn and watch `terminal_reason=aborted_tools`. TS: drive `query()` with an async generator fed from `readline` and call `q.interrupt()`.
- **(c) Live UI.** `include_partial_messages=True` and render `text_delta` events with Rich (Py) / Ink (TS); note deltas come from the main session only unless you set `forward_subagent_text`.
- **(d) External MCP.** Add the M2 `astro-catalog` stdio server (5.11) and allow `mcp__astro-catalog__service_owner`; extend the prompt so each finding names the owning team.
- **(e) Hardened container.** `docker build -f ../../Dockerfile.hardened -t bughunter .` then run with `--cap-drop ALL --security-opt no-new-privileges --read-only --tmpfs /tmp --network none --user 1000:1000 -v $OTEL:/workspace:ro` and the API reachable only through the proxy socket described in reference §K.4. What breaks first, and why is that good?
- **(f) Model economics.** `MODEL=haiku uv run bughunter src/paymentservice` vs `sonnet` vs `opus`; fill the cost/latency/finding-count table in the shared sheet. Then try `effort="low"` on the main loop with `model="sonnet"` inside the `AgentDefinition`.
- **(g) Preset prompt.** Switch to `system_prompt={"type":"preset","preset":"claude_code","append":"You are bughunter…","exclude_dynamic_sections":True}` and compare tone, tool strategy and cache-read tokens across two participants' machines.

## Key takeaways

- The Agent SDK **is** Claude Code's loop as a library: same tools, permissions grammar, hooks schema, MCP, subagents, plugins — configured through one options object in Python or TypeScript, authenticated with an API key or cloud-provider credentials.
- Read the **result message**: `subtype`/`terminal_reason` tell you how it ended, `permission_denials` why it did nothing, `model_usage` + `total_cost_usd` what it cost (estimates), `session_id` how to come back, `structured_output` what to hand to the next system.
- **Availability ≠ permission**, and the evaluation order (hooks → deny → ask → mode → allow → `can_use_tool`) decides which of your guardrails actually runs. `dontAsk` + allow-list for unattended jobs; `default` + `can_use_tool` when policy depends on arguments; `PreToolUse` hooks when you must see every call.
- Custom tools are just an in-process MCP server: `mcp__<server>__<tool>`, pre-approve by name, return `is_error` instead of throwing.
- By default the SDK loads the same filesystem config as the CLI; choose `setting_sources` deliberately (`["project"]` today, `[]` + explicit config in production) and verify with the init message.
- Production means a sandboxed box, secrets outside the agent boundary, budgets and turn caps, telemetry, and session storage you control — or Managed Agents, next.

## References

- Agent SDK docs (canonical home is now the Claude Code docs site): overview · quickstart · agent loop · permissions · hooks · custom tools · MCP · subagents · plugins · skills · Claude Code features (`settingSources`) · modifying system prompts · structured outputs · streaming input vs single mode · sessions · session storage · cost tracking · observability · hosting · secure deployment · Python reference · TypeScript reference · migration guide — all under `https://code.claude.com/docs/en/agent-sdk/` (append `.md` to any page for raw Markdown; older `docs.claude.com/.../agent-sdk/...` links redirect).
- SDK repositories and changelogs: `github.com/anthropics/claude-agent-sdk-python`, `github.com/anthropics/claude-agent-sdk-typescript`; demo agents: `github.com/anthropics/claude-agent-sdk-demos`; cookbook series `github.com/anthropics/claude-cookbooks/tree/main/claude_agent_sdk` (research agent, SRE agent with custom MCP tools and safety hooks, session browser, vulnerability-detection agent, hosting on Docker/Modal/Kubernetes, dynamic workflows).
- Engineering post: "Building agents with the Claude Agent SDK" (anthropic.com/engineering) — the gather context → act → verify loop.
- Workshop reference `reference/Technical-Reference-v4.md`: §A platform map · §K.1 CLI↔SDK↔Managed Agents concept mapping · §K.2 install/auth/versions · §K.3 entry points and full options tables (Py/TS) · §K.4 hosting & secure-deployment checklist, hardened Dockerfile · §K.5 message and result types · §K.6 built-in tools, permissions, `can_use_tool` contract, hook events and decision schema · §K.7 custom tools & MCP · §K.8 subagents/skills/plugins/settings in the SDK · §K.9 structured output, sessions/`SessionStore`, streaming input, cost fields · §K.10 migration notes · §O volatile facts.
- Lab assets: `labs/m5-agent-sdk/{python,typescript}/{starter,solution}/`, `labs/m5-agent-sdk/Dockerfile.hardened`, `labs/m5-agent-sdk/expected-output/`, `labs/shared/{findings.schema.json,tickets.py,tickets.ts,prompts/bug_hunter_system.md}`, `labs/checkpoint.sh CP5`.
- Next: Module 6 hosts this same agent — bug-hunter system prompt, `create_ticket` as a custom tool, findings schema — as a Claude Managed Agent.
