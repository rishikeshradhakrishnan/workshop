# Module 6 — Claude Managed Agents

> **Time box:** 13:50–14:35 (45 min) · **Format:** talk/demo 12 · lab 28 · debrief 5 · **Checkpoint in:** CP5 · **Checkpoint out:** CP6

> [!NOTE] Instructor
> This module needs a **Console API key** in a workspace where Claude Managed Agents is enabled (beta; on by default for API accounts as of August 2026 — **verify on the day** by opening Console → *Agent quickstart*). Attendees without a key pair up, use the time-boxed instructor workspace key from `labs/.env.instructor`, or follow along with the captured run in `labs/m6-managed-agents/expected-output/`. Announce at 14:33: "before the break, start your Module 7 scan" (see Module 7, step 0).

## Why this matters

In Module 5 you embedded the Codebase Toolkit's bug-hunter in *your own* process with the Agent SDK. That works, but you now own a process that must stay up for as long as the agent runs, a sandbox for whatever code it executes, the conversation state, the retry logic, and the bill for all of it. **Claude Managed Agents** is the same *kind* of agent — model + system prompt + tools + MCP servers + skills — run by Anthropic: you create an **Agent**, describe an **Environment**, start a **Session**, and exchange **Events**. Anthropic provisions a fresh container per session, runs the loop, executes the built-in tools inside the sandbox, checkpoints state when the session goes idle, and streams everything back over SSE.

For a builder this is the shortest path from "the bug-hunter prompt in a markdown file" (M3) to "a hosted agent your product can call, schedule, budget, and observe" — with the guardrails you already know re-appearing under new names: `allowed_tools` becomes a **toolset config**, `can_use_tool` becomes a **permission policy** plus a `user.tool_confirmation` event, your `@tool` function becomes a **custom tool** answered with `user.custom_tool_result`, and `.env` secrets move into **vaults**.

## Learning objectives

By the end of this module participants can:

1. Define the Managed Agents resources and their lifecycle — **Agent** (versioned), **Environment** (cloud container config or self-hosted), **Session** (statuses `idle` / `running` / `rescheduling` / `terminated`, `stop_reason`), **Events** (`user.*` in; `agent.*` / `session.*` / `span.*` out over SSE) — plus the satellites: the `agent_toolset_20260401` toolset, custom tools, MCP toolsets, permission policies and tool confirmations, vaults/credentials, memory stores, files and GitHub repository resources, skills, outcomes, multi-agent, budgets, webhooks, and scheduled deployments. *(beta, Aug 2026 — `anthropic-beta: managed-agents-2026-04-01`; the SDKs set it for you.)*
2. Create environment → agent → session with the `anthropic` SDK (Python primary; TypeScript and curl shown), stream and render events, send messages and interrupts, answer a `requires_action` pause for both an `always_ask` tool and a custom tool, and download the deliverable from `/mnt/session/outputs/`.
3. Use the Console: Agent quickstart/builder, Sessions list and tracing view, Environments, Webhooks, Deployments (cron).
4. Explain pricing (tokens + session runtime while `running`; idle is free — *as of August 2026, check the pricing page*), rate limits, the data-retention caveat (not ZDR/HIPAA-eligible), the branding rule, and availability (Claude API and Claude Platform on AWS; not Bedrock/Vertex).
5. Decide between Managed Agents, self-hosting the Agent SDK, and Claude Code Routines using the migration mapping (`ClaudeAgentOptions` → agent, `query()` → session + events, `@tool` → custom tool, hooks/`can_use_tool` → `permission_policy` + confirmations, `cwd` → resources).

## Concepts (instructor talk track)

### 1. What it is, in one breath

"A pre-built, configurable agent harness that runs in managed infrastructure — best for long-running tasks and asynchronous work." You stop writing the loop, the tool executor, the sandbox provisioning and the "are we done yet?" logic; you keep the parts that are yours: the system prompt, which tools exist and who may run them, your custom tools, and what to do with the results. The harness brings prompt caching, context compaction and retries with it. The docs' one-liner for how it is built: the *brain* (model + harness, Anthropic-side) is decoupled from the *hands* (a sandboxed container per session — Anthropic's cloud, or a self-hosted worker you run).

Status badge to say out loud: **public beta since April 2026**; every endpoint needs `anthropic-beta: managed-agents-2026-04-01` (memory-store endpoints use `agent-memory-2026-07-22` instead); MCP tunnels and "dreaming" are a narrower research preview behind a request form. Behaviours are refined between releases — Ref §O lists what to re-verify before each delivery.

### 2. When to choose it — Managed Agents vs self-hosted Agent SDK vs Claude Code Routines

All three can "run the bug-hunter every night". They differ in *who operates what* and *who the user is*.

| | **Claude Managed Agents** (this module) | **Agent SDK, self-hosted** (Module 5) | **Claude Code Routines** (Module 4 tour) |
|---|---|---|---|
| What it is | Hosted agent harness + per-session sandbox, driven by a REST API / SDKs / `ant` CLI | Claude Code's agent loop as a Python/TS library inside *your* process | A saved Claude Code cloud session (prompt + repos + cloud environment + connectors) fired by a schedule, an API trigger, or a GitHub event *(research preview, Aug 2026)* |
| Who runs the loop / the sandbox | Anthropic / Anthropic (or your self-hosted worker for tools) | You / you (container, VM, laptop) | Anthropic / Anthropic cloud VM (or your org's self-hosted environment) |
| Auth & billing | Console API key; tokens **+** session runtime while `running` | Console API key or Bedrock / Vertex / Foundry; tokens only, plus your infra | A **claude.ai subscription seat** (Pro/Max/Team/Enterprise with Claude Code on the web enabled); draws your plan's usage; belongs to *your individual account* |
| State & duration | Server-side history, sandbox checkpointed on idle, resume days later; minutes-to-hours per turn | Whatever you persist (`resume=session_id` + your own storage) | One cloud session per run; minimum schedule interval 1 h |
| Human-in-the-loop | `always_ask` policies → `user.tool_confirmation`; custom tools; interrupts | `can_use_tool`, hooks, your UI | None at run time (runs autonomously; review the transcript / PR after) |
| Extension surface | system prompt, toolset configs, custom tools, MCP servers + vaults, skills, memory stores, outcomes, multi-agent, webhooks, deployments, budgets | Everything Claude Code has: CLAUDE.md/`settingSources`, plugins, hooks, subagents, MCP, structured output | Whatever is committed to the repo (`CLAUDE.md`, `.claude/`, plugins) + claude.ai connectors |
| Choose it when… | you are shipping an agent **inside your product** or ops pipeline and don't want to operate sandboxes, session state, or scaling; you need scheduled/async runs with an API contract | you need full control (custom loop policy, on-prem data, your own container hardening, non-Anthropic model hosting), or the agent must touch a filesystem/network only you can reach and self-hosted sandboxes don't fit | **a developer** wants their *own* recurring/dev-loop automation (nightly PR triage, post-release checks) with zero code and no API key |
| Not for… | ZDR/HIPAA workloads (see §8); Bedrock/Vertex-only shops | teams without capacity to run and secure long-lived agent infrastructure | anything customer-facing or team-owned; anything needing an API-key/service identity |

Two lines that prevent confusion: **Claude Code on the web / Routines are subscription features for developers; Managed Agents is an API product for your software.** And the SDK ↔ Managed Agents difference is operational, not conceptual: "the SDK runs in a process you operate, while Managed Agents runs in Anthropic's infrastructure" — §9 has the field-by-field mapping.

### 3. Core concepts — one diagram

```
                 ┌──────────────────── your application / script ─────────────────────┐
                 │  POST /v1/sessions/{id}/events          GET /v1/sessions/{id}/      │
                 │   user.message  user.interrupt            events/stream  (SSE)      │
                 │   user.tool_confirmation                 ← agent.*  session.*       │
                 │   user.custom_tool_result                   span.*  (event deltas)  │
                 │   user.define_outcome                                               │
                 └──────────────┬──────────────────────────────────▲──────────────────┘
                     events in  │                                  │ events out (persisted; list any time)
┌─────────────────────┐   ┌─────▼──────────────────────────────────┴─────┐   ┌───────────────────────┐
│ AGENT  (versioned)  │   │ SESSION = agent × environment                │   │ ENVIRONMENT           │
│ POST /v1/agents     │──▶│ POST /v1/sessions                            │◀──│ POST /v1/environments │
│ model (+effort,     │   │ status: idle → running → idle …              │   │ config.type: cloud    │
│   speed, geo)       │   │         rescheduling | terminated            │   │   packages{apt,cargo, │
│ system              │   │ stop_reason: end_turn | requires_action |    │   │    gem,go,npm,pip}    │
│ tools[]  ───────────┼─┐ │              budget_reached | retries_exhaus.│   │   networking:         │
│ mcp_servers[]       │ │ │ resources[]: file · github_repository ·      │   │    unrestricted |     │
│ skills[] multiagent │ │ │              memory_store   vault_ids[]      │   │    limited{allowed_   │
└─────────────────────┘ │ │ budget{max_list_cost}   usage{tokens,        │   │    hosts,…}           │
                        │ │   active_seconds, list_cost}                 │   │  or type: self_hosted │
  tools[] kinds:        │ └─────────────────────┬────────────────────────┘   └───────────────────────┘
  ┌─────────────────────▼───────────────────┐   │ built-in + MCP tools execute in
  │ agent_toolset_20260401  → runs IN the   │   ▼
  │   sandbox: bash read write edit glob    │  ┌────────────────────────────────────────────┐
  │   grep web_fetch web_search             │  │ SANDBOX (fresh container per session)      │
  │   configs[]: enabled, permission_policy │  │ /workspace/<repo>       (github_repository)│
  │ mcp_toolset → remote MCP server; creds  │  │ /mnt/session/uploads/…  (file resources)   │
  │   from a VAULT; default always_ask      │  │ /mnt/session/outputs/…  (deliverables →    │
  │ custom → runs in YOUR process:          │  │                          Files API)        │
  │   agent.custom_tool_use ⇄               │  │ /mnt/memory/<store>/    (memory stores)    │
  │   user.custom_tool_result               │  │ checkpointed on idle; state kept 30 days   │
  └─────────────────────────────────────────┘  └────────────────────────────────────────────┘
  around it: WEBHOOKS (Console) · SCHEDULED DEPLOYMENTS (/v1/deployments, cron) · BUDGETS ·
             OUTCOMES (grader) · MULTI-AGENT threads · CONSOLE sessions list + tracing view
```

| Concept | What it is (docs wording) | You will touch it in |
|---|---|---|
| **Agent** | "The model, system prompt, tools, MCP servers, and skills." Versioned: `version` starts at 1 and increments on every changing update; sessions use the latest version unless you pin `{type:"agent", id, version}` or override per session with `{type:"agent_with_overrides", …}`. Archive = read-only. | Lab step 2 |
| **Environment** | "Configuration for where sessions run": `cloud` (packages pre-installed and cached; networking `unrestricted` or `limited` with `allowed_hosts`, `allow_package_managers`, `allow_mcp_servers`) or `self_hosted` (you run an environment worker). Not versioned; every session gets its own fresh container. Cloud sandbox: Ubuntu 22.04 x86_64, up to 8 GB RAM / 10 GB disk, common runtimes preinstalled (Ref §L). | Lab step 1 |
| **Session** | "A running agent instance within an environment." Holds history server-side; `initial_events` (≤ 50, `user.message` / `user.define_outcome`) can start work in the create call; `resources`, `vault_ids`, `budget`, `metadata`, `title`. | Lab steps 3–5 |
| **Events** | "Messages exchanged between your application and the agent." Send `POST /v1/sessions/{id}/events`; stream `GET …/events/stream` (SSE); list `GET …/events` (full history, filter with `types[]`). Names follow `{domain}.{action}` — full catalogue in Ref §L. | Lab step 3 |

The events you will actually render today: `agent.message` (text blocks), `agent.tool_use` / `agent.tool_result`, `agent.custom_tool_use`, `span.model_request_end` (per-request `model_usage` token counts), `session.status_running`, `session.status_idle` (with `stop_reason`), `session.usage` (cumulative snapshot right before every idle), `session.error` (typed error with `retry_status`).

### 4. Tools, permission policies, and the two "your turn" pauses

Three kinds of entries live in an agent's `tools[]`:

- **`{"type": "agent_toolset_20260401"}`** — the built-in tools (`bash`, `read`, `write`, `edit`, `glob`, `grep`, `web_fetch`, `web_search`), executed *inside the sandbox*. All on by default. Shape them with `default_config` and per-tool `configs[]`: `{"name": "web_search", "enabled": false}` removes a tool; `{"name": "web_fetch", "permission_policy": {"type": "always_ask"}}` keeps it but pauses for approval. Start-from-nothing form: `"default_config": {"enabled": false}` then enable individual tools. Tool output over 100,000 characters is spilled to a sandbox file automatically.
- **`{"type": "mcp_toolset", "mcp_server_name": "github"}`** — tools from a remote MCP server declared in `mcp_servers: [{"type": "url", "name": "github", "url": "https://api.githubcopilot.com/mcp/"}]`. Credentials never go on the agent: they come from a **vault** referenced by the session. Default policy is `always_ask` so a server that grows a new tool cannot act without you.
- **`{"type": "custom", "name": "create_ticket", "description": …, "input_schema": {…}}`** — a contract only. The model emits a structured request; **your process** executes it and returns the result. Not governed by permission policies (you are the executor).

Two policies exist: `always_allow` and `always_ask` (agent toolset defaults to allow, MCP toolsets to ask). Both "asks" and custom-tool calls surface the same way — the session **goes idle with `stop_reason.type == "requires_action"`** and lists the blocking event IDs:

```
always_ask tool                                        custom tool
──────────────                                         ───────────
→ agent.tool_use {id:"sevt_A", name:"web_fetch",       → agent.custom_tool_use {id:"sevt_B",
     input:{url:…}, evaluated_permission:"ask"}             name:"create_ticket", input:{…}}
→ session.status_idle                                  → session.status_idle
     {stop_reason:{type:"requires_action",                  {stop_reason:{type:"requires_action",
                   event_ids:["sevt_A"]}}                                 event_ids:["sevt_B"]}}
← user.tool_confirmation {tool_use_id:"sevt_A",        ← user.custom_tool_result {custom_tool_use_id:"sevt_B",
     result:"allow" | "deny", deny_message?}                content:[{type:"text", text:"TICKET-7"}]}
→ session.status_running → agent.tool_result …         → session.status_running → agent continues
```

Rules worth memorising: answer **every** ID in `event_ids` (the session waits indefinitely — and idle time is free); a denied call returns a rejection tool result that includes your `deny_message`, so Claude adapts rather than crashes; several confirmations may go in one `events` request. This is the hosted equivalent of M5's `can_use_tool` callback — the decision now travels as an event, so the human can be in a different process, or a different day.

### 5. The satellites (one sentence each; details in Ref §L)

- **Vaults & credentials** — `POST /v1/vaults` (typically one per end-user) holding up to 20 credentials: `mcp_oauth` (Anthropic refreshes tokens), `static_bearer`, or `environment_variable` (secret injected at egress for listed hosts; the agent only ever sees an opaque placeholder). Reference with `vault_ids=[…]` on the session. Secrets are write-only.
- **Memory stores** *(beta header `agent-memory-2026-07-22`)* — workspace-scoped collections of small text memories mounted at `/mnt/memory/<store>/`; attach as a session resource with `access: "read_only" | "read_write"` (≤ 8 per session). Docs' own warning: prompt-injected content can poison a `read_write` store — mount reference material `read_only` (we reuse this in M7).
- **Files & GitHub repositories** — upload with the Files API and mount via `resources: [{type:"file", file_id, mount_path}]` (lands under `/mnt/session/uploads/`); mount repos with `{type:"github_repository", url, authorization_token, mount_path?, checkout?}` (cached across sessions; token never echoed; a repo's root `.claude/skills/` is auto-discovered). Deliverables written to `/mnt/session/outputs/` are listed with `GET /v1/files?scope_id=<session_id>`.
- **Skills** — `skills: [{type:"anthropic"|"custom", skill_id, version}]` on the agent (pre-built `pptx`/`xlsx`/`docx`/`pdf`, or your own uploaded via `/v1/skills`); the M3 `code-reviewer` skill can ride along either uploaded or via the repo's `.claude/skills/`.
- **Outcomes** — send `user.define_outcome {description, rubric, max_iterations}`; a separate-context grader evaluates deliverables and the agent revises until `satisfied` (events `span.outcome_evaluation_start/ongoing/end`).
- **Multi-agent** — a coordinator agent with `multiagent: {type:"coordinator", agents:[…]}` delegates to roster agents in context-isolated **session threads** sharing one sandbox *(verify current gating on the day)*.
- **Budgets** — `budget: {type:"limit", max_list_cost:{amount:"<cents>", currency:"USD"}}` on session (or deployment) create; the session pauses with `stop_reason: budget_reached` instead of overspending; raise or remove the cap to resume.
- **Webhooks** — registered in Console (*Manage → Webhooks*); thin payloads (`data.type`, `data.id`) for `session.status_idled`, `session.status_run_started`, `session.budget_reached`, `session.status_terminated`, `agent.updated`, `deployment_run.*`, `environment.*`, `memory_store.*`, `vault_credential.refresh_failed`, …; verify with `client.beta.webhooks.unwrap()`; up to three delivery attempts.
- **Scheduled deployments** — `POST /v1/deployments` with agent + environment + `initial_events` + `schedule: {type:"cron", expression, timezone}`; each fire creates a session and a `deployment_run` record; `run` (manual), `pause`, `unpause`, `archive`.
- **Self-hosted sandboxes** — `config: {"type": "self_hosted"}` + an environment key + `ant beta:worker poll --workdir /workspace` (or the SDK `EnvironmentWorker`) on your host: the loop stays on Anthropic's side, tool execution/filesystem/egress stay on yours.
- **Observability** — `span.model_request_*` and `session.usage` events on the stream; `session.usage` / `stats` on the session object; Console **Sessions list**, **Tracing view** (chronological events with content, timestamps, token usage — Developers and Admins only) and per-tool execution details.

### 6. Auth, SDKs, and the beta headers

- **Auth** is a normal Console API key (`x-api-key`). Resources are **workspace-scoped** — any key in the workspace sees the same agents, environments, sessions and vaults. Self-hosted workers use a separate **environment key**, never your API key.
- **Raw HTTP** needs three headers: `x-api-key`, `anthropic-version: 2023-06-01`, `anthropic-beta: managed-agents-2026-04-01` (use `agent-memory-2026-07-22` — and *only* that one — on `/v1/memory_stores/*`). A missing beta header typically surfaces as a **404** rather than a 400 — beta-gated endpoints simply don't exist without it.
- **SDKs** (`pip install anthropic`, `npm install @anthropic-ai/sdk`, plus Java/Go/C#/Ruby/PHP) set the header automatically and expose everything under `client.beta.*` (`agents`, `environments`, `sessions`, `sessions.events`, `sessions.resources`, `vaults`, `memory_stores`, `files`, `deployments`, `deployment_runs`, `webhooks`). The one place you still pass a beta explicitly is the Files API when listing session outputs: `client.beta.files.list(scope_id=…, betas=["managed-agents-2026-04-01"])`.
- **Models**: Claude 4.5 and later. The API takes **model IDs**, not Claude Code aliases — `sonnet` will 400. Lab code reads `CMA_MODEL` (a full model ID) from `labs/.env` so there is exactly one place to bump it (Ref §B); the alias-valued `MODEL` used by Claude Code and the SDK in M4/M5 is a separate variable for exactly this reason.
- **CLI**: `ant` (`brew install anthropics/tap/ant`, or the release binary — Ref §L) mirrors the API: `ant beta:agents create …`, `ant beta:sessions list …`, `ant beta:sessions:events list --session-id …`, `ant beta:worker poll`. In Claude Code, `/claude-api managed-agents-onboard` walks you through the same setup interactively. Neither is required today.

### 7. Pricing & limits *(as of August 2026 — check the pricing page before quoting numbers)*

> **Two meters.** (1) **Tokens** at the model's standard API rates — prompt-caching multipliers apply, web search is billed per search, fast-mode and US-only-inference multipliers apply if you set `model.speed` / `model.inference_geo`. (2) **Session runtime**, quoted on the pricing page as **$0.08 per session-hour**, measured to the millisecond and accruing **only while the session status is `running`**. `idle` (waiting for your message or a tool confirmation), `rescheduling` and `terminated` cost nothing — a session parked on an approval overnight is free. The Batch API discount does not apply; Managed Agents is not sold through Bedrock/Vertex (it *is* available on Claude Platform on AWS with some feature differences). The docs' worked example — a one-hour coding session on the current Opus model with 50k input / 15k output tokens — comes to well under a dollar, and less again with cache hits; the session's own `usage.list_cost` gives you the exact list-price figure (tokens + searches + runtime) without arithmetic.
>
> **Limits you may meet today:** create endpoints 300 req/min and read/list/stream endpoints 1,200 req/min *per organization* (a 30-person room on one instructor org is fine for creates, but mind the org's spend tier); `initial_events` ≤ 50; ≤ 8 memory stores per session; ≤ 20 credentials per vault; ≤ 500 files per session; ≤ 20 MCP servers and ≤ 128 tools per agent; system prompt ≤ 100,000 chars; ≤ 1,000 scheduled deployments per org. Full table: Ref §L.

### 8. Production considerations

- **Idempotency and re-runs.** `POST /v1/agents|environments|sessions` create a new resource every time. Persist IDs (the lab caches them in `.cma-state.json`), name resources deterministically and tag them with `metadata` so a restart can *list-then-reuse* instead of re-creating; create the agent once (CI "apply" job) and only create sessions at request time. Agent updates take an optional `version` for optimistic concurrency (mismatch → **409**, re-read and retry); omit it only in a declarative sync loop that owns the agent. Pin production sessions to `{type:"agent", id, version}` so a prompt tweak rolls out when *you* decide. Webhook deliveries repeat the same top-level `event.id` — dedupe on it.
- **Streaming vs webhooks.** SSE is for a UI that is watching *now*: open the stream **before** you send, and on reconnect open a new stream, list history, and skip seen IDs (deltas are never replayed). Webhooks are for everything asynchronous — deployments, hour-long sessions, approvals that arrive tomorrow: subscribe to `session.status_idled`, re-fetch the session (payloads carry only type + id), and act on `stop_reason`. Webhooks are not a durable log (three attempts, then dropped; ordering not guaranteed) — reconcile by listing sessions/events on a timer if you must observe every transition. Endpoints must be public HTTPS on 443; a `3xx` auto-disables the endpoint.
- **Secrets belong in vaults, not prompts.** Never paste tokens into `system` or a `user.message` — both are stored in session history. Use `mcp_oauth`/`static_bearer` credentials for MCP servers and `environment_variable` credentials (host-scoped, injected at egress, placeholder-only inside the sandbox) for CLIs the agent runs; GitHub `authorization_token` on a repo resource is write-only and rotatable. Pair with `limited` networking and an explicit `allowed_hosts` list — the docs' recommendation for every production environment.
- **Data retention (say this plainly to regulated customers).** Because sessions persist history, sandbox state and outputs server-side, Managed Agents is **not currently eligible for Zero Data Retention or HIPAA BAA** coverage. You control deletion: `DELETE /v1/sessions/{id}` removes the record, events, container and session-scoped output files; uploaded files are deleted separately. Sandbox *state* is only kept 30 days from creation regardless — have agents write anything that matters to `/mnt/session/outputs/`.
- **Cost control.** Put a `budget` on every autonomous session and every deployment (per-run cap); disable `web_search` unless needed; choose model and `effort` on the agent (a per-session `model` override resets effort to default); interrupt-then-archive runaway sessions; watch `session.usage` events instead of polling; set a workspace spend limit in Console. Idle is free, so *do* leave sessions open for follow-ups rather than re-creating context.
- **Guardrails recap for M7.** `permission_policy: always_ask` on anything with side effects, `enabled: false` for tools you don't need, `limited` networking, vault-scoped secrets, `read_only` memory for reference material, agent version pinning, and the branding rule: your product may say "*YourAgent* Powered by Claude", never "Claude Code".

### 9. From the Agent SDK to Managed Agents — the mapping

| Agent SDK (M5) | Managed Agents (M6) | Stays client-side |
|---|---|---|
| `ClaudeAgentOptions(model, system_prompt, allowed_tools, mcp_servers, …)` | `client.beta.agents.create(model, system, tools, mcp_servers, skills)` — versioned, reusable | — |
| `query()` / `ClaudeSDKClient` loop, message iterator | `client.beta.sessions.create(...)` + `sessions.events.send/stream` | rendering, your UI |
| Built-in tools against `cwd` | `agent_toolset_20260401` in the sandbox against `/workspace`; `cwd`/`add_dirs` → file & `github_repository` resources | — |
| `@tool` + `create_sdk_mcp_server` (in-process) | `{"type":"custom"}` tool → `agent.custom_tool_use` → you run it → `user.custom_tool_result` | the tool implementation (`labs/shared/tickets.py`) |
| `permission_mode`, `can_use_tool`, `PreToolUse` deny | per-tool `permission_policy` + `user.tool_confirmation`; `enabled:false`; `limited` networking | PreToolUse/PostToolUse hooks, plan mode, `max_turns` (interrupt instead) |
| `mcp_servers` with tokens in env | `mcp_servers` on the agent, credentials in a **vault** on the session | — |
| CLAUDE.md via `setting_sources` | the versioned `system` string; or a `read_only` memory store; or skills in the mounted repo | — |
| `max_budget_usd` | session `budget` (`budget_reached`) | — |
| `resume=session_id` | just send another `user.message` to the same session (state is server-side) | — |

### 10. API walkthrough — the eight calls, three ways

The lab script wraps exactly these calls. Python is the primary track; the TypeScript and curl versions are complete equivalents you can run from `labs/m6-managed-agents/typescript/` and `labs/m6-managed-agents/curl/steps.sh`. All three read `ANTHROPIC_API_KEY`, `CMA_MODEL`, `WORKSHOP_ORG` and `GITHUB_USER` from `labs/.env`.

#### 10.1 Python (`anthropic` SDK)

```python
# labs/m6-managed-agents/python — the essential calls (the starter adds arg parsing + .cma-state.json caching)
import itertools, json, os, pathlib, sys
from anthropic import Anthropic

SHARED = pathlib.Path(__file__).resolve().parents[3] / "shared"                # -> labs/shared
sys.path.append(str(SHARED))
from tickets import create_ticket                                               # M5's handler, reused verbatim

client = Anthropic()                                   # ANTHROPIC_API_KEY from env; SDK adds the beta header
MODEL, ORG = os.environ["CMA_MODEL"], os.environ["WORKSHOP_ORG"]   # CMA_MODEL is a full model ID, not a Claude Code alias
USER = os.environ.get("GITHUB_USER", "anon")
SYSTEM = (SHARED / "prompts/bug_hunter_system.md").read_text()

# (1) Environment — container recipe: packages are pre-installed and cached; limited egress for bash/pip.
env = client.beta.environments.create(
    name=f"ws-{USER}",
    config={
        "type": "cloud",
        "packages": {"pip": ["ruff"]},
        "networking": {"type": "limited",
                       "allowed_hosts": ["github.com", "api.github.com", "raw.githubusercontent.com"],
                       "allow_package_managers": True, "allow_mcp_servers": False},
    },
)

# (2) Agent — bug-hunter prompt from M3, toolset with one always_ask tool and one disabled tool, plus M5's custom tool.
agent = client.beta.agents.create(
    name=f"codebase-toolkit-{USER}",
    model=MODEL,
    system=SYSTEM,
    tools=[
        {"type": "agent_toolset_20260401",
         "default_config": {"permission_policy": {"type": "always_allow"}},
         "configs": [{"name": "web_fetch", "permission_policy": {"type": "always_ask"}},
                     {"name": "web_search", "enabled": False}]},
        {"type": "custom", "name": "create_ticket",
         "description": "File a bug ticket in the team tracker. Call once per HIGH-severity finding, after you have "
                        "confirmed the file and line. Returns the new ticket ID. Do not call for MEDIUM/LOW findings.",
         "input_schema": {"type": "object",
                          "properties": {"title": {"type": "string"},
                                         "severity": {"type": "string", "enum": ["HIGH", "MEDIUM", "LOW"]},
                                         "file": {"type": "string"}, "line": {"type": "integer"}},
                          "required": ["title", "severity", "file", "line"]}},
    ],
)
print(agent.id, "version", agent.version)

# (3) Session with a prompt. initial_events starts the turn in the same call: status goes straight to `running`.
TASK = (f"Clone https://github.com/{ORG}/opentelemetry-demo (depth 1) into /workspace. "
        "Analyze src/paymentservice for bugs and write the report to /mnt/session/outputs/bug-report.md. "
        "File a ticket for each HIGH finding with create_ticket. Then fetch "
        "https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md "
        "and note whether any finding is already fixed upstream.")
session = client.beta.sessions.create(
    agent=agent.id,                                    # bare ID = latest version; pin with {"type":"agent","id":…,"version":2}
    environment_id=env.id,
    title=f"paymentservice bug hunt ({USER})",
    initial_events=[{"type": "user.message", "content": [{"type": "text", "text": TASK}]}],
)
# Alternative to cloning in bash (stretch a): mount the repo as a session resource. Needs a GitHub token even for a
# public repo (fine-grained, read-only); cached across sessions; default mount /workspace/<repo>; token never echoed.
#   resources=[{"type": "github_repository", "url": f"https://github.com/{ORG}/opentelemetry-demo",
#               "authorization_token": os.environ["GITHUB_TOKEN"], "checkout": {"type": "branch", "name": "workshop"}}]

# (4)+(5)+(6) Stream, render, and answer both kinds of requires_action pause.
def render(ev) -> None:
    match ev.type:
        case "agent.message":
            print("".join(b.text for b in ev.content if b.type == "text"), end="", flush=True)
        case "agent.tool_use" | "agent.mcp_tool_use" | "agent.custom_tool_use":
            print(f"\n[{ev.type.split('.')[1]}: {ev.name}] {json.dumps(ev.input)[:110]}")
        case "span.model_request_end":
            u = ev.model_usage
            print(f"\n  · model request: in={u.input_tokens} cached={u.cache_read_input_tokens} out={u.output_tokens}")
        case "session.error":
            print(f"\n[session.error] {ev.error.message if ev.error else 'unknown'}")

def resolve(session_id: str, pending: list, auto_yes: bool) -> None:
    for ev in pending:                                   # answer EVERY blocking event id
        if ev.type == "agent.custom_tool_use":           # (6) custom tool: we execute, we reply
            result = create_ticket(**ev.input) if ev.name == "create_ticket" else f"unknown tool {ev.name}"
            reply = {"type": "user.custom_tool_result", "custom_tool_use_id": ev.id,
                     "content": [{"type": "text", "text": str(result)}]}
        else:                                            # (5) always_ask tool: a human decides
            ok = auto_yes or input(f"\nAllow {ev.name} {json.dumps(ev.input)[:100]} ? [a]llow/[d]eny: ").strip().lower().startswith("a")
            reply = {"type": "user.tool_confirmation", "tool_use_id": ev.id, "result": "allow" if ok else "deny"}
            if not ok:
                reply["deny_message"] = "Operator declined this fetch; finish the report without the upstream check."
        client.beta.sessions.events.send(session_id, events=[reply])

def stream_turn(session_id: str, *, send: list | None = None, replay_history: bool = False, auto_yes: bool = False) -> None:
    seen, by_id = set(), {}
    with client.beta.sessions.events.stream(session_id) as stream:          # open the stream FIRST …
        backlog = list(client.beta.sessions.events.list(session_id)) if replay_history else []
        if send:                                                              # … THEN send (no race)
            client.beta.sessions.events.send(session_id, events=send)
        for ev in itertools.chain(backlog, stream):
            if ev.type in ("event_start", "event_delta") or ev.id in seen:   # deltas only if you opted in
                continue
            seen.add(ev.id); by_id[ev.id] = ev
            render(ev)
            if ev.type == "session.status_idle":
                if ev.stop_reason.type == "requires_action":
                    resolve(session_id, [by_id[i] for i in ev.stop_reason.event_ids if i in by_id], auto_yes)
                    continue                                                  # back to running; keep tailing
                print(f"\n[idle: {ev.stop_reason.type}]"); break            # end_turn | budget_reached | retries_exhausted
            if ev.type == "session.status_terminated":
                break

stream_turn(session.id, replay_history=True)          # initial_events already started the turn → replay what we missed

# Follow-up on the SAME session (stateful): open stream, then send.
stream_turn(session.id, send=[{"type": "user.message",
                               "content": [{"type": "text", "text": "Summarize the report in 3 bullets."}]}])

# (7) Outputs and usage
for f in client.beta.files.list(scope_id=session.id, betas=["managed-agents-2026-04-01"]):
    print(f.id, f.filename)
    if f.filename.endswith("bug-report.md"):
        client.beta.files.download(f.id).write_to_file("bug-report.md")
u = client.beta.sessions.retrieve(session.id).usage
print(f"tokens in={u.input_tokens} out={u.output_tokens} cache_read={u.cache_read_input_tokens} "
      f"active={u.active_seconds:.0f}s list_cost=${int(u.list_cost.amount) / 100:.2f}")

# (8) Stop. A `running` session can't be archived or deleted: interrupt it, let it reach idle, then archive.
if client.beta.sessions.retrieve(session.id).status == "running":
    stream_turn(session.id, send=[{"type": "user.interrupt"}])      # interrupted turn ends with a normal end_turn idle
client.beta.sessions.archive(session.id)               # keeps history, blocks new events; .delete(id) removes everything
```

#### 10.2 TypeScript (`@anthropic-ai/sdk`)

<details>
<summary><code>labs/m6-managed-agents/typescript/solution/deploy_toolkit_agent.ts</code> — same eight calls (click to expand)</summary>

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "node:fs";
import * as readline from "node:readline/promises";
import { createTicket } from "../../../shared/tickets.js";        // M5's handler (labs/shared/tickets.ts)

const client = new Anthropic();                                    // beta header set by the SDK
const { CMA_MODEL: MODEL, WORKSHOP_ORG: ORG, GITHUB_USER: USER = "anon" } = process.env as Record<string, string>;   // full model ID
const SYSTEM = readFileSync(new URL("../../../shared/prompts/bug_hunter_system.md", import.meta.url), "utf8");

// (1) environment
const env = await client.beta.environments.create({
  name: `ws-${USER}`,
  config: {
    type: "cloud",
    packages: { pip: ["ruff"] },
    networking: { type: "limited", allowed_hosts: ["github.com", "api.github.com", "raw.githubusercontent.com"],
                  allow_package_managers: true, allow_mcp_servers: false },
  },
});

// (2) agent
const agent = await client.beta.agents.create({
  name: `codebase-toolkit-${USER}`,
  model: MODEL,
  system: SYSTEM,
  tools: [
    { type: "agent_toolset_20260401",
      default_config: { permission_policy: { type: "always_allow" } },
      configs: [{ name: "web_fetch", permission_policy: { type: "always_ask" } }, { name: "web_search", enabled: false }] },
    { type: "custom", name: "create_ticket",
      description: "File a bug ticket for one HIGH-severity finding (after confirming file and line). Returns the ticket ID.",
      input_schema: { type: "object",
        properties: { title: { type: "string" }, severity: { type: "string", enum: ["HIGH", "MEDIUM", "LOW"] },
                      file: { type: "string" }, line: { type: "integer" } },
        required: ["title", "severity", "file", "line"] } },
  ],
});
console.log(agent.id, "version", agent.version);

// (3) session — create idle, open the stream, THEN send the first message (the no-race pattern)
const TASK = `Clone https://github.com/${ORG}/opentelemetry-demo (depth 1) into /workspace. Analyze src/paymentservice for bugs ` +
  `and write /mnt/session/outputs/bug-report.md. File a ticket for each HIGH finding with create_ticket. Then fetch ` +
  `https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md and note anything already fixed upstream.`;
const session = await client.beta.sessions.create({ agent: agent.id, environment_id: env.id, title: `paymentservice bug hunt (${USER})` });

// (4)(5)(6) stream + confirmations + custom tool results
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
async function streamTurn(sessionId: string, send?: any[]) {                // send = user.* events to post once the stream is open
  const byId = new Map<string, any>();
  const stream = await client.beta.sessions.events.stream(sessionId);      // open first
  if (send) await client.beta.sessions.events.send(sessionId, { events: send });
  for await (const ev of stream) {
    if (ev.type === "event_start" || ev.type === "event_delta") continue;
    byId.set(ev.id, ev);
    if (ev.type === "agent.message") process.stdout.write(ev.content.map((b: any) => b.type === "text" ? b.text : "").join(""));
    else if (ev.type === "agent.tool_use" || ev.type === "agent.custom_tool_use") console.log(`\n[${ev.type}: ${ev.name}]`);
    else if (ev.type === "span.model_request_end") console.log(`\n  · in=${ev.model_usage.input_tokens} out=${ev.model_usage.output_tokens}`);
    else if (ev.type === "session.error") console.log(`\n[session.error] ${ev.error?.message ?? "unknown"}`);
    else if (ev.type === "session.status_idle") {
      if (ev.stop_reason.type !== "requires_action") { console.log(`\n[idle: ${ev.stop_reason.type}]`); break; }
      for (const id of ev.stop_reason.event_ids) {
        const pending = byId.get(id); if (!pending) continue;
        if (pending.type === "agent.custom_tool_use") {
          const result = await createTicket(pending.input);
          await client.beta.sessions.events.send(sessionId, { events: [
            { type: "user.custom_tool_result", custom_tool_use_id: id, content: [{ type: "text", text: String(result) }] }] });
        } else {
          const ok = (await rl.question(`\nAllow ${pending.name} ${JSON.stringify(pending.input).slice(0, 100)}? [a/d] `)).startsWith("a");
          await client.beta.sessions.events.send(sessionId, { events: [ ok
            ? { type: "user.tool_confirmation", tool_use_id: id, result: "allow" }
            : { type: "user.tool_confirmation", tool_use_id: id, result: "deny", deny_message: "Operator declined; skip the upstream check." }] });
        }
      }
    }
  }
  stream.controller.abort();
}
await streamTurn(session.id, [{ type: "user.message", content: [{ type: "text", text: TASK }] }]);
await streamTurn(session.id, [{ type: "user.message", content: [{ type: "text", text: "Summarize the report in 3 bullets." }] }]);
rl.close();

// (7) outputs + usage
const files = await client.beta.files.list({ scope_id: session.id, betas: ["managed-agents-2026-04-01"] });
for (const f of files.data) {
  console.log(f.id, f.filename);
  if (f.filename.endsWith("bug-report.md")) await (await client.beta.files.download(f.id)).writeToFile("bug-report.md");
}
const { usage } = await client.beta.sessions.retrieve(session.id);
console.log(usage);

// (8) stop: interrupt only if still running → archive (keeps history) or delete (removes everything)
if ((await client.beta.sessions.retrieve(session.id)).status === "running") {
  await streamTurn(session.id, [{ type: "user.interrupt" }]);
}
await client.beta.sessions.archive(session.id);
```

</details>

#### 10.3 curl (raw HTTP — note the three headers on every call)

<details>
<summary><code>labs/m6-managed-agents/curl/steps.sh</code> — same eight calls with <code>jq</code> (click to expand)</summary>

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$WS/labs/.env"                       # ANTHROPIC_API_KEY, CMA_MODEL, WORKSHOP_ORG, GITHUB_USER
API=https://api.anthropic.com/v1
H=(-H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01"
   -H "anthropic-beta: managed-agents-2026-04-01" -H "content-type: application/json")

# (1) environment
ENV_ID=$(curl -sS --fail-with-body "$API/environments" "${H[@]}" -d @- <<'EOF' | jq -er .id
{"name": "ws-curl", "config": {"type": "cloud", "packages": {"pip": ["ruff"]},
  "networking": {"type": "limited", "allowed_hosts": ["github.com","api.github.com","raw.githubusercontent.com"],
                 "allow_package_managers": true, "allow_mcp_servers": false}}}
EOF
)
# (2) agent  (system prompt inlined from the shared file with jq to keep JSON escaping correct)
AGENT=$(jq -n --arg model "$CMA_MODEL" --arg name "codebase-toolkit-$GITHUB_USER-curl" \
        --rawfile system "$WS/labs/shared/prompts/bug_hunter_system.md" '{
  name: $name, model: $model, system: $system,
  tools: [
    {type: "agent_toolset_20260401", default_config: {permission_policy: {type: "always_allow"}},
     configs: [{name: "web_fetch", permission_policy: {type: "always_ask"}}, {name: "web_search", enabled: false}]},
    {type: "custom", name: "create_ticket", description: "File a bug ticket for one HIGH finding. Returns the ticket ID.",
     input_schema: {type: "object", properties: {title: {type: "string"}, severity: {type: "string"},
                    file: {type: "string"}, line: {type: "integer"}}, required: ["title","severity","file","line"]}}]}' \
  | curl -sS --fail-with-body "$API/agents" "${H[@]}" -d @-)
AGENT_ID=$(jq -er .id <<<"$AGENT"); echo "agent $AGENT_ID v$(jq -r .version <<<"$AGENT")"

# (3) session (idle) → (4) open the SSE stream FIRST → then send the prompt
SESSION_ID=$(jq -n --arg a "$AGENT_ID" --arg e "$ENV_ID" '{agent: $a, environment_id: $e, title: "curl bug hunt"}' \
  | curl -sS --fail-with-body "$API/sessions" "${H[@]}" -d @- | jq -er .id)
exec {stream}< <(curl -sS --fail-with-body -N "$API/sessions/$SESSION_ID/events/stream" "${H[@]}" -H "accept: text/event-stream")
jq -n --arg org "$WORKSHOP_ORG" '{events: [{type: "user.message", content: [{type: "text", text:
  ("Clone https://github.com/" + $org + "/opentelemetry-demo (depth 1) into /workspace, analyze src/paymentservice for bugs, write /mnt/session/outputs/bug-report.md, file a ticket per HIGH finding with create_ticket, then fetch https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md and note anything already fixed upstream.")}]}]}' \
  | curl -sS --fail-with-body "$API/sessions/$SESSION_ID/events" "${H[@]}" -d @- >/dev/null

declare -A KIND NAME                                     # remember pending tool events by id
send() { curl -sS --fail-with-body "$API/sessions/$SESSION_ID/events" "${H[@]}" -d "$1" >/dev/null; }
while IFS= read -r -u "$stream" line; do
  [[ $line == data:* ]] || continue; ev=${line#data: }
  type=$(jq -r .type <<<"$ev")
  case $type in
    agent.message)          jq -j '.content[] | select(.type=="text") | .text' <<<"$ev" ;;
    agent.tool_use|agent.mcp_tool_use|agent.custom_tool_use)
                            id=$(jq -r .id <<<"$ev"); KIND[$id]=$type; NAME[$id]=$(jq -r .name <<<"$ev")
                            printf '\n[%s: %s]\n' "$type" "${NAME[$id]}" ;;
    span.model_request_end) jq -r '"  · in=\(.model_usage.input_tokens) out=\(.model_usage.output_tokens)"' <<<"$ev" ;;
    session.error)          jq -r '"[session.error] " + (.error.message // "unknown")' <<<"$ev" ;;
    session.status_idle)
      reason=$(jq -r .stop_reason.type <<<"$ev")
      if [[ $reason != requires_action ]]; then printf '\n[idle: %s]\n' "$reason"; break; fi
      for id in $(jq -r '.stop_reason.event_ids[]' <<<"$ev"); do
        if [[ ${KIND[$id]} == agent.custom_tool_use ]]; then          # (6) custom tool → our result
          send "$(jq -n --arg id "$id" --arg t "TICKET-$RANDOM" \
            '{events: [{type: "user.custom_tool_result", custom_tool_use_id: $id, content: [{type: "text", text: $t}]}]}')"
        else                                                           # (5) always_ask → human decides
          read -r -p "Allow ${NAME[$id]}? [a/d] " ans </dev/tty
          if [[ $ans == a* ]]; then
            send "$(jq -n --arg id "$id" '{events: [{type: "user.tool_confirmation", tool_use_id: $id, result: "allow"}]}')"
          else
            send "$(jq -n --arg id "$id" '{events: [{type: "user.tool_confirmation", tool_use_id: $id, result: "deny",
                     deny_message: "Operator declined; skip the upstream check."}]}')"
          fi
        fi
      done ;;
  esac
done
exec {stream}<&-

# (7) outputs + usage
FILE_ID=$(curl -fsSL "$API/files?scope_id=$SESSION_ID" "${H[@]}" | jq -r '.data[] | select(.filename|endswith("bug-report.md")) | .id' | head -1)
curl -fsSL "$API/files/$FILE_ID/content" "${H[@]}" -o bug-report.md
curl -fsSL "$API/sessions/$SESSION_ID" "${H[@]}" | jq '.usage'

# (8) stop: interrupt if still running, then archive (POST …/archive) or delete (DELETE …)
send '{"events": [{"type": "user.interrupt"}]}' || true
curl -fsSL -X POST "$API/sessions/$SESSION_ID/archive" "${H[@]}" | jq -r .status
```

</details>

## Live demo script

**T/D 12 min. Have `labs/.env` sourced, Console open in a browser tab, and the recorded fallback (`labs/m6-managed-agents/expected-output/demo.cast`) ready in case venue Wi-Fi misbehaves.**

1. **(3 min) Concept slide.** Draw §3's four boxes and the sandbox; say the "brain vs hands" line; point at the three tool kinds and the two `requires_action` pauses; one pricing sentence ("tokens plus runtime while running; idle is free"); one beta sentence (header, SDK sets it). Land the M5 bridge: "`can_use_tool` becomes an event; `@tool` becomes a custom tool; `.env` becomes a vault."
2. **(5 min) Console.** Open **platform.claude.com → workspace → Agent quickstart** (`/workspaces/default/agent-quickstart`). Build "Codebase Toolkit Agent" visually: pick the model, paste `labs/shared/prompts/bug_hunter_system.md` into the system-prompt editor, add the agent toolset, set **web_fetch → always ask**, toggle **web_search off**. Point at the **generated API request** panel — "this is the JSON your lab script sends". Run one message in the **inline session runner** ("List the tools you have and what you'd do first on a Node.js payments service"). Then open **Sessions → (that session) → Tracing view**: chronological events, content, timestamps, per-request token usage, tool execution details. Mention: tracing is visible to Developers and Admins only; **Environments** page (cloud/self-hosted, environment keys); **Deployments** (cron builder that validates expressions); **Manage → Webhooks** (signing secret shown once). Copy the agent ID — "Console and API are the same resources; you could `sessions.create(agent="agent_…")` against this right now."
3. **(4 min) Terminal.** `cd $WS/labs/m6-managed-agents/python/solution && uv run python deploy_toolkit_agent.py all` — narrate the stream as it scrolls: `[tool_use: bash] git clone…`, model-request token lines, then the **pause**: `Allow web_fetch {"url": "https://raw.githubusercontent…"}? [a]llow/[d]eny` — answer `a` (or, if you are ahead of time, `d` to show the `deny_message` flowing back and Claude finishing without the upstream check). Show a `[custom_tool_use: create_ticket]` round-trip and `cat tickets.json`. Finish on `bug-report.md` downloaded and the `usage` line. If time: `ant beta:sessions list --agent-id "$AGENT_ID"` and `ant beta:sessions:events list --session-id "$SESSION_ID"` to show the CLI sees the same objects (instructor machine only).

> [!NOTE] Instructor
> Keep the demo session **open** (idle is free) — you will point at it again in M7 when mapping `always_ask`, `limited` networking and vaults onto the threat model, and `labs/cleanup.sh` archives it in M8.

## Hands-on lab

**L 28 min · Build `deploy_toolkit_agent` — the Codebase Toolkit's bug-hunter as a hosted agent.**

**Start state:** CP5 or later (strictly, only `labs/shared/` and `labs/m6-managed-agents/` are needed). `source $WS/labs/.env` has exported `ANTHROPIC_API_KEY`, `CMA_MODEL` (a full model ID, not an alias), `WORKSHOP_ORG`, `GITHUB_USER`, `WS`. Preflight already installed `anthropic` into the lab's Python env (`uv sync`); TypeScript track: `npm ci` in `labs/m6-managed-agents/typescript/`. Work in `labs/m6-managed-agents/python/starter/` (or `typescript/starter/`). The starter `deploy_toolkit_agent.py` has `TODO(step-n)` markers; every step runs alone (`uv run python deploy_toolkit_agent.py step3`) and caches IDs in `.cma-state.json`, so re-running never re-creates resources. Solution next door in `solution/`. Constants (`BETA = "managed-agents-2026-04-01"`, `TOOLSET = "agent_toolset_20260401"`) live in `labs/shared/cma_constants.py` — one place to bump.

```bash
cd $WS/labs/m6-managed-agents/python/starter      # TS: cd ../../typescript/starter && npx tsx deploy_toolkit_agent.ts stepN
uv run python deploy_toolkit_agent.py --help       # lists step1 … step6, all, attach, --yes, --interrupt-after N
```

### Step 1 — Environment (4 min)

Fill `TODO(step-1)`: `client.beta.environments.create(name=f"ws-{USER}", config={...})` exactly as in §10.1 (1): `type: "cloud"`, `packages.pip: ["ruff"]`, `networking.type: "limited"` with `allowed_hosts` `github.com`, `api.github.com`, `raw.githubusercontent.com`, `allow_package_managers: True`, `allow_mcp_servers: False`. Save `env.id` to state.

```bash
uv run python deploy_toolkit_agent.py step1
```

**Success check:** prints `env_…`; the environment appears in Console → **Environments** with your name on it. (`limited` governs the *container's* egress — bash, git, pip. It does not restrict `web_fetch`/`web_search`, which is why we gate `web_fetch` with a policy in step 2.)

### Step 2 — Agent, then a new version (5 min)

Fill `TODO(step-2)`: `client.beta.agents.create(...)` as in §10.1 (2) — `name=f"codebase-toolkit-{USER}"`, `model=MODEL` (read from `CMA_MODEL`), `system=` the bug-hunter prompt, the toolset with `web_fetch: always_ask` and `web_search: enabled False`, and the `create_ticket` custom tool (schema imported from `labs/shared`). Print `agent.id` and `agent.version` (expect `1`). Then the second half of the TODO: `client.beta.agents.update(agent.id, version=agent.version, system=SYSTEM + "\nAlways include the exact file:line for every finding.")` and print the returned `version` (expect `2`); finally list versions:

```python
for v in client.beta.agents.versions.list(agent.id):
    print("version", v.version, v.updated_at)
```

```bash
uv run python deploy_toolkit_agent.py step2
```

**Success check:** output shows `version 1` then `version 2`, and the versions list has two rows. Re-running step 2 prints "reusing agent_… from .cma-state.json"; the starter re-reads the agent before updating, so the repeat update is a no-op and **no version 3** appears (no-op detection). Passing a stale `version=` instead would return **409** — optimistic concurrency doing its job.

### Step 3 — Session, stream, confirmation, custom tool (9 min)

Fill `TODO(step-3)`: create the session with `agent=state["agent_id"]` (a bare ID string = latest version), `environment_id`, a `title`, and `initial_events=[user.message TASK]` where `TASK` is the §10.1 prompt (clone `https://github.com/$WORKSHOP_ORG/opentelemetry-demo` depth 1 into `/workspace` → analyze `src/paymentservice` → write `/mnt/session/outputs/bug-report.md` → `create_ticket` per HIGH finding → fetch the upstream `CHANGELOG.md` and compare). Then complete `stream_turn()`:

- open `client.beta.sessions.events.stream(session_id)` **first**, list history once (`replay_history=True`, because `initial_events` already put the session in `running`), then tail, skipping seen IDs;
- render `agent.message` text, `agent.tool_use` / `agent.custom_tool_use` names, `span.model_request_end` token counts, `session.error`;
- on `session.status_idle`: if `stop_reason.type == "requires_action"`, for each ID in `stop_reason.event_ids` look up the pending event → `agent.tool_use` (it will be `web_fetch`) → ask the human `[a]llow/[d]eny` and send `user.tool_confirmation` (`tool_use_id`, `result`, optional `deny_message`); `agent.custom_tool_use` → call `create_ticket(**ev.input)` from `labs/shared/tickets.py` and send `user.custom_tool_result` (`custom_tool_use_id`, text `content`). Any other stop reason (`end_turn`, `budget_reached`, `retries_exhausted`) → print it and break.

```bash
uv run python deploy_toolkit_agent.py step3            # add --yes to auto-allow (used by the checkpoint script)
```

Watch it: `git clone`, a burst of `read`/`grep`, the report being written, one or more `[custom_tool_use: create_ticket]` round-trips, then the pause on `web_fetch`. Answer it. Typical wall-clock 3–6 min.

**Success check:** the terminal showed **≥ 1 confirmation prompt** and **≥ 1 ticket**; `cat tickets.json` (in the starter dir) has new entries with `file`/`line` under `src/paymentservice`; the run ends with `[idle: end_turn]`. In Console → **Sessions**, your titled session is `idle`.

### Step 4 — Steer and follow up (4 min)

(a) Re-run the task with the provided flag: `uv run python deploy_toolkit_agent.py step4 --interrupt-after 20`. It sends the analysis prompt to the **same** session and, 20 s in, fires:

```python
client.beta.sessions.events.send(sid, events=[
    {"type": "user.interrupt"},
    {"type": "user.message", "content": [{"type": "text", "text": "Skip the upstream comparison; finish the report now."}]},
])
```

The interrupted turn ends with a normal `session.status_idle` / `end_turn` (there is no interrupt-specific stop reason) and the redirect immediately starts a new turn — the starter's loop keeps tailing until the second idle for you.

(b) After idle, the script sends one more `user.message` on the same session — "Summarize the report in 3 bullets" — via `stream_turn(sid, send=[...])` (open stream, *then* send). No files are re-read from scratch: history and the sandbox filesystem persisted across turns.

**Success check:** transcript shows `[idle: end_turn]` twice in (a) and a three-bullet summary in (b) that references findings from step 3; the `span.model_request_end` lines in (b) show large `cached=` numbers.

### Step 5 — Deliverables and observability (4 min)

Fill `TODO(step-5)`:

```python
for f in client.beta.files.list(scope_id=sid, betas=["managed-agents-2026-04-01"]):   # session-scoped outputs
    print(f.id, f.filename)
    if f.filename.endswith("bug-report.md"):
        client.beta.files.download(f.id).write_to_file("bug-report.md")
sess = client.beta.sessions.retrieve(sid)
u = sess.usage
runtime_usd = u.active_seconds / 3600 * 0.08                      # rate as of Aug 2026 — check the pricing page
print(f"in={u.input_tokens} out={u.output_tokens} cache_read={u.cache_read_input_tokens} "
      f"active={u.active_seconds:.0f}s  list_cost=${int(u.list_cost.amount)/100:.2f} (runtime part ≈ ${runtime_usd:.3f})")
```

```bash
uv run python deploy_toolkit_agent.py step5 && head -40 bug-report.md
```

Then open the session in Console → **Sessions → Tracing view** and find (i) the `web_fetch` tool call you approved, (ii) the `create_ticket` custom tool use with your returned text, (iii) the token usage on one model request. Do **not** archive anything yet — M7 refers back to this agent and `labs/cleanup.sh` (M8) archives by name prefix.

**Success check:** `bug-report.md` exists locally with `file:line` findings; the printed `list_cost` is cents-to-dimes; `active_seconds` is a few minutes even though the session has existed far longer (idle was free). Post your `list_cost` in the shared sheet.

### Step 6 — Pick ONE preview (2 min; read + run the provided snippet)

- **(a) Budget.** `uv run python ../../snippets/budget.py` creates a *new* session on your agent with `budget={"type": "limit", "max_list_cost": {"amount": "50", "currency": "USD"}}` (amount is **whole US cents as a string** — `"50"` is $0.50; decimals are rejected) and the same task; watch the stream end with `session.usage` then `[idle: budget_reached]`. The snippet then resumes it with `client.beta.sessions.update(sid, budget={"type": "limit", "max_list_cost": {"amount": "150", "currency": "USD"}})` — no event is needed; raising (or removing, `budget=None`) the cap restarts the paused work.
- **(b) Schedule.** Console → **Deployments → New**: pick your `codebase-toolkit-<user>` agent and `ws-<user>` environment, initial message = the step-3 task, cron `0 7 * * 1-5` ("weekdays 07:00") in your timezone; save and read `upcoming_runs_at`. Or from code: `uv run python ../../snippets/deployment.py`, which calls `client.beta.deployments.create(name=…, agent=…, environment_id=…, initial_events=[…], schedule={"type": "cron", "expression": "0 7 * * 1-5", "timezone": "<Area/City>"})`, triggers one manual `client.beta.deployments.run(deployment.id)`, lists `client.beta.deployment_runs.list(deployment_id=…)`, and finally `client.beta.deployments.archive(...)` so nothing fires tomorrow. (Deployments accept a per-run `budget` too.)
- **(c) Webhook.** Start the receiver: `ANTHROPIC_WEBHOOK_SIGNING_KEY=whsec_… uv run python ../../webhook_receiver.py` (Flask on `:8787`, route `/hook`, verifies with `client.beta.webhooks.unwrap(request.get_data(as_text=True), headers=dict(request.headers))` and re-fetches the session on `session.status_idled`). Expose it with a tunnel that passes the **raw body** through unchanged — `ngrok http 8787` or `cloudflared tunnel --url http://localhost:8787` — and register `https://<tunnel-host>/hook` in Console → **Manage → Webhooks** for `session.status_idled` (copy the `whsec_…` secret; it is shown once). Send your step-3 session any short `user.message`; when it idles, the receiver prints `session idled: sesn_… status=idle`. Delete the endpoint afterwards. (Payload-replaying relays such as smee.io may re-serialise the JSON body, which breaks signature verification — fine for eyeballing deliveries, not for `unwrap()`.)

**Success check (any one):** (a) printed `budget_reached` then resumed to `end_turn`; (b) a deployment with three `upcoming_runs_at` timestamps and one manual run that produced a `session_id`, then archived; (c) one verified delivery logged by the receiver.

**Checkpoint out: CP6** — you have an agent ID + version 2, an environment ID, a session with a full transcript in Console, `tickets.json` entries, and `bug-report.md` on disk.

## If you're behind (fast-forward)

```bash
cd $WS && ./labs/checkpoint.sh CP6 --force      # --force: your modified starter file is backed up, then replaced
```

Copies `solution/` over `starter/` for your language (without `--force` a starter file you already edited is reported as a conflict and kept — `--dry-run` previews), then runs steps 1–3 non-interactively with `--yes` (auto-allow confirmations) so you see a complete stream at least once, and caches the IDs in `.cma-state.json` so you can still do step 5 (download + Console tracing) by hand. No API key at your seat? Pair with a neighbour for steps 3–5, or read `labs/m6-managed-agents/expected-output/` (`stream.log`, `bug-report.md`, `usage.json`, Console screenshots) and rejoin at the debrief. Managed Agents not enabled on your org (403)? Switch `ANTHROPIC_API_KEY` to the instructor workspace key in `labs/.env.instructor` for this module only.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `403` / "managed agents not enabled" on `environments.create` | Org/workspace gating (beta) | Confirm in Console → Agent quickstart; use the instructor workspace key for M6; ask your admin later |
| `404` on `/v1/agents` or `/v1/sessions/…/events/stream` with raw curl | Missing or misspelled `anthropic-beta: managed-agents-2026-04-01` (without it the endpoints don't exist); or memory-store call sent with the wrong header | Add the header; memory endpoints take `agent-memory-2026-07-22` *instead* |
| `400 … model` on `agents.create` | `CMA_MODEL` is empty, still the placeholder, a Claude Code alias (`sonnet`) or a model not enabled for your org | Set `CMA_MODEL` in `labs/.env` to a full model ID your org can use (Ref §B); Claude 4.5+ only |
| Agent runs but `git clone` fails / hangs; pip works | `limited` networking without the GitHub hosts | Environments aren't versioned: fix `allowed_hosts` and **create a new environment** (update `.cma-state.json`), new session |
| Stream connects but you never see the first tool calls | Stream opened after work started (`initial_events`) without replaying history | Use the starter's `replay_history=True` path (stream → list → dedupe), or create the session idle and send after the stream opens |
| Session sits `idle` forever after the `web_fetch` prompt | Not every ID in `stop_reason.event_ids` was answered, or you answered with the wrong field (`custom_tool_use_id` vs `tool_use_id`) | Send one `user.tool_confirmation` per pending `agent.tool_use` and one `user.custom_tool_result` per `agent.custom_tool_use`; run `deploy_toolkit_agent.py attach` to re-open the stream on the cached session, replay history, and answer what is pending |
| `400` sending `user.message` | Session is `running` (send `user.interrupt` first or wait), paused at a budget (raise/remove the budget instead), or waiting on `requires_action` | Check `sessions.retrieve(id).status` and the last `session.status_idle.stop_reason` |
| `409` on `agents.update` | Stale `version=` (someone/you updated in between) | `agents.retrieve` → retry with the current version, or omit `version` for last-write-wins |
| `archive`/`delete` rejected | Session still `running` | `user.interrupt`, wait for `session.status_idle`, then archive |
| `files.list` returns nothing | Report written somewhere other than `/mnt/session/outputs/`; or missing `betas=[…]` on the Files call | Ask the agent (same session) to copy it into `/mnt/session/outputs/`; pass `betas=["managed-agents-2026-04-01"]` |
| `429` when the whole room creates at once | 300 create req/min per org, or the shared org's spend tier | Stagger by table; instructor pre-raises the workspace limit; retries are safe for reads |
| Webhook endpoint flips to `disabled` | Tunnel URL returned a `3xx` or resolved to a private IP | Fix the URL in Console and re-enable; events emitted meanwhile are not replayed |
| Garbled box-drawing / unicode in the Windows console | Code page | `chcp 65001` or run in Windows Terminal / VS Code terminal; `PYTHONIOENCODING=utf-8` |

## Stretch goals

Each has a runnable snippet in `labs/m6-managed-agents/snippets/` (Python; TS ports for a, b, e).

- **(a) Repo as a resource.** Re-create the session with `resources=[{"type": "github_repository", "url": "https://github.com/<WORKSHOP_ORG>/opentelemetry-demo", "authorization_token": GITHUB_TOKEN, "checkout": {"type": "branch", "name": "workshop"}}]` (fine-grained PAT, read-only; the token is never echoed) instead of cloning in bash; note the default mount `/workspace/opentelemetry-demo`, the faster start on the second session (repos are cached), and that a committed `.claude/skills/code-reviewer/SKILL.md` would be **auto-discovered** as a skill.
- **(b) Team conventions as read-only memory** (`snippets/memory_store.py`): `client.beta.memory_stores.create(name=f"team-conventions-{USER}", description=…)`, write your M1 `CLAUDE.md` as a memory (`memory_stores.memories.create(store.id, path="/CLAUDE.md", content=…)`), attach with `resources=[{"type": "memory_store", "memory_store_id": store.id, "access": "read_only"}]`, and ask the agent which conventions apply to `src/currencyservice`. Discuss why `read_only` (M7: memory poisoning).
- **(c) Outcome-graded report** (`snippets/outcome.py`): start a session whose `initial_events` include `{"type": "user.define_outcome", "description": "A bug report for src/paymentservice", "rubric": {"type": "text", "content": "≥3 findings; each has file:line, severity, and a concrete fix"}, "max_iterations": 3}`; watch `span.outcome_evaluation_start/ongoing/end` and the `result` (`needs_revision` → another cycle; `satisfied` terminal).
- **(d) Vault + MCP with approval** (`snippets/vault_mcp.py`): create a vault, add a `static_bearer` credential for the GitHub MCP server (`https://api.githubcopilot.com/mcp/`), add `mcp_servers=[…]` + `{"type": "mcp_toolset", "mcp_server_name": "github"}` (default `always_ask`) to a new agent version, start a session with `vault_ids=[vault.id]` and an environment that allows MCP egress, ask it to open an issue in **your** `astroshop-reviews` repo, and approve the `agent.mcp_tool_use`.
- **(e) Same agent, cheaper model** (`snippets/overrides.py`): `agent={"type": "agent_with_overrides", "id": agent_id, "model": {"id": "<haiku model id>"}}` for one session; compare `list_cost` and report quality with your step-5 numbers (note: a `model` override runs at the model's default effort).
- **(f) Coordinator + roster** (`snippets/multiagent.py`): create a `service-documenter` agent from the M3 prompt, then a coordinator with `multiagent={"type": "coordinator", "agents": [{"type": "agent", "id": documenter_id}, {"type": "agent", "id": bug_hunter_id}]}`; watch `session.thread_created` and `agent.thread_message_sent/received`, and tail one thread with `client.beta.sessions.threads.events.stream(thread_id, session_id=…)`.
- **(g) Self-hosted hands** (Docker): `client.beta.environments.create(name="laptop", config={"type": "self_hosted"})`, generate an environment key in Console → Environments, run `docker run -e ANTHROPIC_ENVIRONMENT_KEY -e ANTHROPIC_ENVIRONMENT_ID … ant beta:worker poll --workdir /workspace`, and start a session against it — the loop runs in the cloud, `bash` runs on your laptop.
- **(h) Other tracks:** redo steps 1–3 with `typescript/starter` or `curl/steps.sh` (§10.2 / §10.3) and diff the event handling.

## Key takeaways

- **Four nouns:** Agent (versioned config) × Environment (container recipe) → Session (stateful run) ⇄ Events (SSE out, POST in). Everything else — vaults, memory, files/repos, skills, outcomes, budgets, webhooks, deployments — hangs off those four.
- **Two pauses, one mechanism:** `always_ask` tools and custom tools both surface as `session.status_idle` + `requires_action`; you answer with `user.tool_confirmation` or `user.custom_tool_result` for **every** listed event ID. That is M5's `can_use_tool` and `@tool`, moved across a network boundary.
- **Open the stream before you send; on reconnect, list history and dedupe.** Webhooks (thin, retried three times, unordered) are for the asynchronous cases.
- **Beta, metered, retained:** `managed-agents-2026-04-01` on every raw call; tokens + runtime only while `running` (idle is free); not ZDR/HIPAA-eligible; you can delete sessions and files. Re-verify the numbers in Ref §O before quoting them.
- **Choosing:** Managed Agents when the agent lives in *your product* and you don't want to run sandboxes or state; the Agent SDK when you must own the process; Routines when a *developer* wants their own scheduled Claude Code run. The morning's toolkit travelled to all three without being rewritten.

## References

- Overview, quickstart, Console builder: https://platform.claude.com/docs/en/managed-agents/overview · https://platform.claude.com/docs/en/managed-agents/quickstart · https://platform.claude.com/docs/en/managed-agents/onboarding
- Agents (fields, versioning, update semantics): https://platform.claude.com/docs/en/managed-agents/agent-setup
- Environments and the cloud sandbox spec: https://platform.claude.com/docs/en/managed-agents/environments · https://platform.claude.com/docs/en/managed-agents/cloud-sandboxes-reference
- Sessions (create, `initial_events`, overrides, budgets) and session operations (statuses, update, archive, delete): https://platform.claude.com/docs/en/managed-agents/sessions · https://platform.claude.com/docs/en/managed-agents/session-operations
- Event stream (send/stream/list, deltas, custom tools, confirmations, usage, Console observability): https://platform.claude.com/docs/en/managed-agents/events-and-streaming
- Tools and permission policies: https://platform.claude.com/docs/en/managed-agents/tools · https://platform.claude.com/docs/en/managed-agents/permission-policies
- MCP connector, vaults: https://platform.claude.com/docs/en/managed-agents/mcp-connector · https://platform.claude.com/docs/en/managed-agents/vaults
- Files, GitHub repositories, skills, memory: https://platform.claude.com/docs/en/managed-agents/files · https://platform.claude.com/docs/en/managed-agents/github · https://platform.claude.com/docs/en/managed-agents/skills · https://platform.claude.com/docs/en/managed-agents/memory
- Outcomes, multi-agent, budgets: https://platform.claude.com/docs/en/managed-agents/define-outcomes · https://platform.claude.com/docs/en/managed-agents/multiagent-orchestration · https://platform.claude.com/docs/en/managed-agents/budgets
- Webhooks, scheduled deployments: https://platform.claude.com/docs/en/managed-agents/webhooks · https://platform.claude.com/docs/en/managed-agents/scheduled-deployments
- Self-hosted sandboxes (+ security model): https://platform.claude.com/docs/en/managed-agents/self-hosted-sandboxes · https://platform.claude.com/docs/en/managed-agents/self-hosted-sandboxes-security
- Migration from the Messages API / Agent SDK: https://platform.claude.com/docs/en/managed-agents/migration
- Reference (event catalogue, rate limits, branding), beta headers, pricing: https://platform.claude.com/docs/en/managed-agents/reference · https://platform.claude.com/docs/en/api/beta-headers · https://platform.claude.com/docs/en/about-claude/pricing#claude-managed-agents-pricing
- Claude Platform on AWS differences: https://platform.claude.com/docs/en/build-with-claude/claude-platform-on-aws#claude-managed-agents
- Data retention / ZDR eligibility: https://platform.claude.com/docs/en/manage-claude/api-and-data-retention#feature-eligibility
- `ant` CLI releases; cookbooks and quickstarts (lab seeds: human-in-the-loop gate, cap session spend, operate in production): https://github.com/anthropics/anthropic-cli/releases · https://github.com/anthropics/claude-cookbooks/tree/main/managed_agents · https://github.com/anthropics/claude-quickstarts/tree/main/managed-agents
- Claude Code Routines (for the §2 comparison): https://code.claude.com/docs/en/routines
- Launch and engineering posts: https://claude.com/blog/claude-managed-agents · https://www.anthropic.com/engineering/managed-agents
- Workshop reference: Ref §L (endpoint map, full event/status tables, schemas, pricing worked example, Console tour, `ant` cheatsheet), Ref §K (CLI ↔ SDK ↔ Managed Agents mapping), Ref §O (volatile facts to re-verify).
