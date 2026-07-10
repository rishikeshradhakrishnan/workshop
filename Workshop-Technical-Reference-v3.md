# Claude Code Workshop - Technical Reference (v3)

**Format:** Modular, instructor-led or self-paced | **Total content:** ~3.5 hours (pick modules to fit your slot)
**Repo:** [opentelemetry-demo](https://github.com/rishikeshradhakrishnan/opentelemery-demo)
**Updated:** July 2026 — covers Claude Code 2.1.2xx, Claude Fable 5 / Sonnet 5 / Opus 4.8, Claude Managed Agents & the Agent SDK

> ⚠️ **WORK IN PROGRESS — NOT YET RELEASED**
> This v3 content is under active development and has **not** been released for workshop delivery.
> Commands, module structure, and feature coverage may change before release.
> For current workshop deliveries, use [Workshop-Technical-Reference.md](Workshop-Technical-Reference.md) (v2).

---

## What's New in v3

This version extends the original 6-phase workshop (v2) with the platform capabilities released between **Claude Opus 4.5 (Nov 2025)** and **Claude Fable 5 / Sonnet 5 (June 2026)**:

| Area | What's new |
|------|-----------|
| **Models** | Claude Fable 5 (new flagship, `/model fable`), Sonnet 5 (native 1M context), Opus 4.8; adaptive thinking, effort levels (`low` → `max`, plus `ultracode`), fast mode |
| **Claude Code core UX** | Plan mode, checkpoints & rewind, auto memory, permission modes (incl. Auto mode on all plans), `/usage`, `/context`, `/compact`, output styles, status line |
| **Built-in skills** | `/code-review`, `/security-review`, `/verify`, `/run`, `/simplify`, `/debug`, `/deep-research` |
| **Hooks** | Event-driven automation (`PreToolUse`, `PostToolUse`, `SessionStart`, … — ~30 events) |
| **Orchestration** | Dynamic workflows (`ultracode`), agent teams, agent view (`claude agents`), background agents, `/goal`, `/loop` |
| **Cloud** | Claude Code on the web, routines, remote control, PR auto-fix |
| **Subagents & skills format** | Richer frontmatter: `effort`, `permissionMode`, `context: fork`, named arguments, dynamic context injection |
| **Plugins** | `claude plugin init/validate`, `.zip` & URL loading, `/reload-plugins`, community marketplace |
| **Managed Agents** | Claude Managed Agents (public beta) — hosted agent harness via API; `ant` CLI; Agent SDK |

> The previous version of this document is preserved as `Workshop-Technical-Reference.md`.

---

## Module Index

Modules are self-contained. Times are approximate; each module lists its prerequisites.

| Module | Time | Focus | Builds on |
|--------|------|-------|-----------|
| [0. Pre-Workshop Setup](#module-0-pre-workshop-setup) | 10 min | Install, model & effort defaults | — |
| [1. Documentation & Analysis](#module-1-documentation--analysis) | 20 min | Subagents, parallel exploration | 0 |
| [2. Claude Code Essentials](#module-2-claude-code-essentials) | 20 min | Plan mode, checkpoints, memory, permissions | 0 |
| [3. Test Generation](#module-3-test-generation) | 15 min | Language-specific tests, `/verify`, hooks | 0 |
| [4. Debugging & QA](#module-4-debugging--qa) | 20 min | bug-hunter subagent, `/code-review`, `/security-review` | 1 |
| [5. Development & MCP](#module-5-development--mcp) | 25 min | Feature development, MCP servers | 2 |
| [6. Multi-Agent Orchestration](#module-6-multi-agent-orchestration) | 25 min | Agent teams, workflows, agent view, cloud sessions | 1 |
| [7. Skills, Packaging & Marketplace](#module-7-skills-packaging--marketplace) | 25 min | Skills, plugins, marketplaces | 1, 4 |
| [8. Reusability Demo](#module-8-reusability-demo) | 10 min | Install your plugin on a fresh repo | 7 |
| [9. Claude Managed Agents & Agent SDK](#module-9-claude-managed-agents--the-agent-sdk) | 30 min | Hosted agents via API, `ant` CLI, Agent SDK | 0 |
| [Appendix A: Claude Models — Opus 4.5 → Fable 5](#appendix-a-claude-models--opus-45--48) | ref | Model timeline & API capabilities | — |
| [Appendix B: Command & Configuration Quick Reference](#appendix-b-command--configuration-quick-reference) | ref | Slash commands, CLI flags, env vars | — |
| [Appendix C: Changelog from v2](#appendix-c-changelog-from-v2) | ref | What changed in this document | — |

**Suggested tracks:**

| Track | Duration | Modules |
|-------|----------|---------|
| Classic (matches v2 workshop) | 90 min | 0, 1, 3, 4, 5 (compressed), 7, 8 |
| Claude Code Deep Dive | 2 hours | 0, 1, 2, 4, 6 |
| Platform / API Builders | 2 hours | 0, 2, 5, 9 + Appendix A |
| Full Workshop | Half day | All modules |

---

<a id="module-0-pre-workshop-setup"></a>
## Module 0: Pre-Workshop Setup

**Time:** 10 min | **Prerequisites:** none

### Participant Requirements

```bash
# Check Claude Code is installed and current
claude --version
claude update

# Run health check (verifies install, auth, environment)
claude doctor

# Clone the repository
git clone https://github.com/rishikeshradhakrishnan/opentelemetry-demo
cd opentelemetry-demo

# Verify Node.js (needed for MCP in Module 5)
node --version

# Start Claude Code
claude
```

### Verify Model & Effort Defaults

Inside Claude Code, check what model and effort level you are running:

```
/model
```

```
/effort
```

**Expected:**
- **Max / Team Premium / Enterprise / API accounts:** Claude Opus 4.8 (`claude-opus-4-8`) as the default model
- **Pro / Team Standard accounts:** Claude Sonnet 5 (`claude-sonnet-5`, native 1M context)
- **Claude Fable 5** (`claude-fable-5`) — the most capable model — is available but not the default; switch with `/model fable`
- Effort defaults to `high` (adaptive thinking decides how much reasoning each turn needs)

**Useful model aliases:**

| Alias | Meaning |
|-------|---------|
| `default` | Account default (Opus 4.8 or Sonnet 5, depending on plan) |
| `fable` / `best` | Claude Fable 5 — most capable model |
| `opus` | Latest Opus (4.8) |
| `sonnet` | Latest Sonnet (5 — native 1M context) |
| `haiku` | Fast & efficient (4.5) |
| `opusplan` | Opus for plan mode, Sonnet for execution |
| `opus[1m]` | 1M-token context variant of Opus |

### Instructor Pre-Check

```bash
# Verify all services are present
ls src/

# Expected output:
# accountingservice  cartservice       currencyservice  frontend      paymentservice         recommendationservice
# adservice          checkoutservice   emailservice     loadgenerator productcatalogservice  shippingservice
```

---

<a id="module-1-documentation--analysis"></a>
## Module 1: Documentation & Analysis

**Time:** 20 min | **Prerequisites:** Module 0

### 1A: Basic Documentation Demo

**Prompt:**

```
Analyze the architecture of this application.
Create a README.md that includes:
- High-level architecture diagram (mermaid)
- List of all services with their primary language
- How services communicate with each other
- Quick start instructions for local development
```

**Expected Output:**
- Mermaid diagram showing service relationships
- Table of services with languages (Go, Python, TypeScript, etc.)
- Communication patterns (gRPC, HTTP)
- Docker compose instructions

---

### 1B: Built-In Subagents Demo (NEW)

Claude Code ships with built-in subagents — you can use them before writing any custom ones:

| Built-in agent | Model | Purpose |
|----------------|-------|---------|
| **Explore** | Haiku | Fast, read-only codebase search |
| **Plan** | (inherits) | Research for plan mode |
| **general-purpose** | (inherits) | All tools, multi-step tasks |

**Prompt:**

```
Use the Explore agent to find every place in this codebase where
a service makes a gRPC call to another service. Just give me the
list of caller -> callee pairs with file references.
```

**Expected Behavior:**
- An `Agent(Explore: ...)` indicator appears (the tool was renamed from `Task` to `Agent`)
- Exploration happens in an isolated context (your main conversation stays small)
- Check `/context` before and after to show the difference

> **Also new:** subagents now run in the **background by default** — you can keep talking to Claude while they work — and subagents can spawn their own subagents (up to 5 levels deep).

---

### 1C: Service-Documenter Subagent

Subagents are just markdown files in `.claude/agents/` — one file per agent. Create the directory and your first agent:

```bash
mkdir -p .claude/agents
```

**File:** `.claude/agents/service-documenter.md`

```markdown
---
name: service-documenter
description: Documents a single microservice. Use when analyzing individual services for documentation purposes.
tools: Read, Grep, Glob
model: sonnet
effort: medium
---

You are a technical documentation specialist. When given a service directory:

1. Identify the primary language and framework
2. Find the main entry point
3. List key functions/endpoints
4. Identify dependencies on other services
5. Note any configuration files

Output a concise markdown summary with:
- **Service name** and language
- **Purpose** (1-2 sentences)
- **Key endpoints/functions** (bullet list)
- **Dependencies** (other services it calls)
- **Configuration** options
```

**What's new in subagent frontmatter (2026):**

| Field | Purpose | Example |
|-------|---------|---------|
| `effort` | Reasoning depth for this agent | `low`, `medium`, `high`, `xhigh`, `max` |
| `permissionMode` | Permission behavior when this agent runs | `default`, `acceptEdits`, `plan` |
| `maxTurns` | Cap the number of agent turns | `15` |
| `background` | Run as a background agent | `true` |
| `isolation` | Run in an isolated git worktree | `worktree` |
| `color` | Display color in the UI | `cyan` |
| `skills` | Pre-load specific skills | `[code-reviewer]` |
| `memory` | Persist agent memory | `user`, `project`, `local` |
| `disallowedTools` | Deny specific tools | `Bash` |
| `mcpServers` | MCP servers available to this agent | inline or by reference |

> Only `name` and `description` are required. Start simple; add fields as you need them.

The agent is active as soon as the file is saved — no installation step needed.

> **Looking ahead:** in Module 7 you'll package this agent (and everything else you build today) into a distributable plugin — in one step, at the end. For now, just build and use it.

> **Changed:** the `/agents` interactive creation wizard was **removed** (v2.1.198). To create a subagent, either write the file yourself (as above) or just ask: *"Create a subagent that reviews SQL migrations"* — Claude writes the file for you. Claude Code watches `.claude/agents/`, so edits take effect immediately, no restart.

---

### 1D: Parallel Subagents Demo

**Check Context Usage**

```
/context
```

**Prompt:**

```
Document this codebase using 4 parallel subagents.
Assign each subagent to a different group:

Subagent 1: Go services (checkoutservice, productcatalogservice)
Subagent 2: Python services (recommendationservice, loadgenerator)
Subagent 3: Frontend services (frontend in TypeScript, paymentservice in JS)
Subagent 4: .NET services (cartservice, accountingservice)

Each subagent should use the service-documenter approach.
Then combine all findings into a comprehensive ARCHITECTURE.md
```

**Expected Behavior:**
- 4 parallel `Agent(...)` indicators appear
- Each completes independently in its own context window
- Results synthesized into single document

**Check Context Usage Again**

```
/context
```

**Then check per-component token usage (NEW):**

```
/usage
```

`/usage` breaks down token consumption by skill, subagent, plugin, and MCP server — useful to show participants the cost profile of parallel subagents.

---

### 1E: Participant Parallel Exercise

**Prompt:**

```
Explore this codebase using 3 parallel tasks:

Task 1: Analyze the frontend layer (src/frontend)
Task 2: Analyze the backend services (src/checkoutservice, src/cartservice)
Task 3: Analyze the data/infrastructure layer (docker-compose.yml, kubernetes/)

Each task should report:
- What components exist
- Key technologies used
- How they connect to other parts

Synthesize findings into a summary.
```

**Success Criteria:**
- Participant sees parallel `Agent(...)` execution
- Receives combined summary
- Has `service-documenter.md` in `.claude/agents/`

---

<a id="module-2-claude-code-essentials"></a>
## Module 2: Claude Code Essentials (NEW)

**Time:** 20 min | **Prerequisites:** Module 0

This module covers the core Claude Code UX features added since the original workshop. These apply to *every* phase of work, so teach them early.

### 2A: Plan Mode

Plan mode lets Claude research and propose an approach **without making any changes**. Ideal for non-trivial features and refactors.

**Enter plan mode:** press `Shift+Tab` to cycle permission modes until you see `plan`, or start with:

```bash
claude --permission-mode plan
```

**Prompt (in plan mode):**

```
I want to add a promotional discount code feature to the checkout flow.
Research the codebase and propose an implementation plan.
```

**Expected Behavior:**
- Claude reads code and asks clarifying questions but does NOT edit files
- Presents a structured plan for approval
- On approval, you choose how to proceed (auto-accept edits, manual review, or **"Approve and start in auto mode"**)
- Press `Ctrl+G` to open and edit the plan in your editor before approving
- One-off variant: prefix a single prompt with `/plan` without switching modes

**Related:** the `opusplan` model alias uses Opus for planning and Sonnet for execution — a good cost/quality tradeoff:

```
/model opusplan
```

---

### 2B: Effort & Adaptive Thinking

Modern Claude models (Opus 4.6+) use **adaptive thinking** — the model decides how much reasoning each turn needs. The **effort level** tunes that tradeoff.

```
/effort
```

| Level | When to use |
|-------|-------------|
| `low` | Quick lookups, simple edits |
| `medium` | Routine coding tasks |
| `high` | Default — most work |
| `xhigh` | Complex agentic coding, hard debugging (Opus 4.7+, Fable 5, Sonnet 5) |
| `max` | Maximum exploration |
| `ultracode` | **New** — a Claude Code setting (not a model level): `xhigh` reasoning **plus** automatic multi-agent workflow orchestration for every substantive task (see Module 6C) |

**Demo — same prompt at two effort levels:**

```
/effort low
```

```
Why does the checkout flow call the currency service twice per order?
```

```
/effort xhigh
```

```
Why does the checkout flow call the currency service twice per order?
Trace the full call path and verify your answer against the code.
```

**One-off deep reasoning:** include the keyword `ultrathink` anywhere in a prompt to request deeper reasoning for just that turn — no settings change.

**View thinking:** press `Ctrl+O` to expand/collapse Claude's reasoning.

---

### 2C: Checkpoints & Rewind

Claude Code automatically snapshots your session so you can undo agent work safely.

**Open the rewind menu:** press `Esc` `Esc` (or run `/rewind`)

**Demo flow:**
1. Ask Claude to make a change you don't actually want:
   ```
   Rename all variables in src/paymentservice/charge.js to single letters.
   ```
2. Press `Esc` `Esc` and select the checkpoint from before the change
3. Both the conversation and the file changes are rewound

**Also in the rewind menu:** "Summarize up to here" compresses earlier context — useful in long sessions instead of a full `/compact`. Rewind can even restore a conversation from before a `/clear`.

---

### 2D: Memory — CLAUDE.md, Rules & Auto Memory

| Mechanism | Location | Purpose |
|-----------|----------|---------|
| Project memory | `CLAUDE.md` / `.claude/CLAUDE.md` | Conventions, architecture notes, commands — loaded every session |
| Local memory | `CLAUDE.local.md` | Personal notes, not checked into git |
| Path-specific rules | `.claude/rules/*.md` | Rules that apply only to matching paths |
| User memory | `~/.claude/CLAUDE.md` | Your preferences across all projects |
| Auto memory | `~/.claude/projects/<project>/memory/` | Claude's own notes per repo (a `MEMORY.md` index + topic files), captured automatically; **on by default** — toggle via `/memory` |

**Generate a starting CLAUDE.md for the demo repo:**

```
/init
```

**View and edit all memory:**

```
/memory
```

**Demo prompt after /init:**

```
Add a rule to CLAUDE.md: all new code must include OpenTelemetry spans
for any cross-service call.
```

Then start a new session and verify Claude follows the rule without being told.

---

### 2E: Permission Modes

Cycle with `Shift+Tab` or set at startup with `--permission-mode <mode>`.

| Mode | Behavior | Use case |
|------|----------|----------|
| `default` (shown as **"Manual"** in the UI) | Reads are free; writes/commands prompt | Sensitive codebases |
| `acceptEdits` | Auto-approves file edits & common file commands | Normal development |
| `plan` | Read-only research; proposes a plan | Design before build |
| `auto` | Background safety classifier reviews actions, blocks risky ones | Hands-off sessions — now on **all paid plans** |
| `dontAsk` | Auto-denies anything not pre-approved | CI / scripts |
| `bypassPermissions` | No prompts at all | **Isolated containers/VMs only** |

**Notes for instructors:**
- **Auto mode** is the newest addition — a safety classifier reviews each action in the background and only interrupts when something looks risky. Conversational boundaries work too: saying "don't push to remote" blocks matching actions. Works with Sonnet 4.6/5 and Opus 4.7/4.8; on Bedrock/Vertex/Foundry set `CLAUDE_CODE_ENABLE_AUTO_MODE=1`.
- Protected paths (`.git`, `.mcp.json`, settings files, etc.) always prompt regardless of mode.
- Set a project default in `.claude/settings.json`:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

---

### 2F: Context & Cost Management

| Command | Purpose |
|---------|---------|
| `/context` | Visualize what's occupying the context window |
| `/compact` | Summarize the conversation to free up context |
| `/usage` | Token usage breakdown by skill, subagent, plugin, MCP server |
| `/cost` | Estimated cost of the session |
| `/status` | Account, model, and settings overview |

**Demo:** run `/context` after the parallel subagent demo (Module 1D) — show how subagent work does *not* bloat the main context.

---

### 2G: Output Styles & Status Line (Optional)

Output styles change how Claude communicates. Built-ins: **Default**, **Proactive** (stronger autonomous execution), **Explanatory**, **Learning**.

Switch via `/config` → "Output style", or set `"outputStyle"` in `.claude/settings.json`. (The old `/output-style` command was removed in v2.1.91.)

```
/statusline            # configure the terminal status line (model, effort, tokens, git branch)
/theme                 # terminal colors
```

Custom output styles live in `.claude/output-styles/` and can be distributed via plugins (Module 7).

---
<a id="module-3-test-generation"></a>
## Module 3: Test Generation

**Time:** 15 min | **Prerequisites:** Module 0

### 3A: Go Test Demo

**Prompt:**

```
Look at src/checkoutservice (Go) and generate a test suite:
- Unit tests for the main order placement logic
- Mock any external service calls
- Use table-driven tests following Go conventions
- Cover both success and error scenarios
```

**Expected Output:**
- File named `*_test.go`
- Table-driven test structure
- Mocked external services
- Error case coverage

---

### 3B: Python Test Alternative

**Prompt:**

```
Generate pytest tests for src/recommendationservice/recommendation_server.py
Include fixtures for the product catalog dependency
```

**Expected Output:**
- pytest file with fixtures
- Mocked gRPC calls
- Multiple test cases

---

### 3C: Verify the Tests Actually Work (NEW)

Don't stop at generation — make Claude prove the tests run. Two bundled skills help:

```
/verify
```

> Confirms a change works by running the relevant code/tests and observing behavior.

```
/run
```

> Launches the project's app or test suite to validate changes in the real application.

**Demo prompt (after 3A):**

```
Run the tests you just generated for checkoutservice. If any fail,
fix either the test or the code until the suite passes. Show me the
final test output.
```

**Teaching point:** generation + verification in the same session is the workflow shift from "AI writes code" to "AI ships code."

---

### 3D: Automate with Hooks (NEW)

Hooks run scripts automatically around Claude's actions. Example: auto-run the linter after every file edit.

**File:** `.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File modified - remember to run tests' >&2"
          }
        ]
      }
    ]
  }
}
```

**Hook events available:**

| Event | Fires |
|-------|-------|
| `SessionStart` | When a session begins |
| `PreToolUse` | Before any tool call (can block it) |
| `PostToolUse` | After a tool call completes |
| `SubagentStart` / `SubagentStop` | Around subagent execution |
| `Stop` | When Claude finishes a turn |
| `PermissionRequest` | When a permission prompt would appear |

…plus ~20 more (`PostToolUseFailure`, `PreCompact`/`PostCompact`, `TaskCreated`/`TaskCompleted`, `FileChanged`, `SessionEnd`, …) — about 30 events in total; see the hooks reference.

**Hook handler types:** `command` (shell), `prompt` (ask Claude), `agent` (spawn a subagent), `http` (POST to an endpoint), `mcp_tool` (call an MCP tool).

**Inspect configured hooks:**

```
/hooks
```

**Realistic workshop example** — block edits to generated protobuf files:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 -c \"import json,sys; d=json.load(sys.stdin); p=d.get('tool_input',{}).get('file_path',''); sys.exit(2 if '_pb2' in p or '.pb.go' in p else 0)\""
          }
        ]
      }
    ]
  }
}
```

> Exit code `2` from a hook blocks the action and tells Claude why.

---

### 3E: Participant Test Exercises

**Python (pytest):**

```
Generate pytest tests for src/recommendationservice/recommendation_server.py
Include:
- Test for the ListRecommendations function
- Mock the product catalog dependency
- Test empty input handling
- Use pytest fixtures appropriately
Then run the tests and fix any failures.
```

**Go (testing):**

```
Generate tests for src/productcatalogservice/main.go
Include:
- Table-driven tests for GetProduct
- Tests for ListProducts with various filters
- Mock any database or external calls
- Test error conditions
Then run the tests and fix any failures.
```

**TypeScript (Jest):**

```
Generate Jest tests for the frontend cart functionality
Include:
- Test adding items to cart
- Test removing items
- Test quantity updates
- Mock API calls to the cart service
Then run the tests and fix any failures.
```

**C# (xUnit):**

```
Generate xUnit tests for src/cartservice
Include:
- Test AddItem functionality
- Test GetCart returns correct items
- Mock the Redis dependency
- Test concurrent access scenarios
Then run the tests and fix any failures.
```

---

<a id="module-4-debugging--qa"></a>
## Module 4: Debugging & QA

**Time:** 20 min | **Prerequisites:** Module 1

### 4A: Single-Service Debug Demo

**Option A - Hypothetical:**

```
Users are reporting random payment failures.
Analyze src/paymentservice to find potential issues.
Check for error handling gaps, race conditions, and edge cases.
```

**Option B - Prompt for injected bug:**

```
Users are reporting random payment failures in production.
Analyze src/paymentservice to find the root cause.
Show me the problematic code and propose a fix.
```

> **Instructor note:** see [Pre-Workshop Notes](#pre-workshop-notes) for the bug to inject before the session.

---

### 4B: Bug-Hunter Subagent

**File:** `.claude/agents/bug-hunter.md`

```markdown
---
name: bug-hunter
description: Investigates a service for bugs, error handling gaps, and potential issues. Use when debugging or auditing code quality.
tools: Read, Grep, Glob
model: sonnet
effort: high
---

You are a debugging specialist. When investigating a service:

1. Check all error handling paths
2. Look for unhandled exceptions
3. Identify potential race conditions
4. Find timeout/retry issues
5. Check for null/undefined handling

Report findings as:
- 🔴 **Critical:** [issue + file:line] - must fix immediately
- 🟡 **Warning:** [issue + file:line] - should address
- 🟢 **Info:** [observation] - minor improvement

Always include specific file paths and line numbers.
Suggest a fix for each critical and warning issue.
```

The agent is active as soon as the file is saved — no installation step needed.

---

### 4C: Parallel Debugging Demo

**Prompt:**

```
Debug the checkout flow using 4 parallel subagents:

Subagent 1: Investigate src/frontend for client-side error handling
Subagent 2: Investigate src/checkoutservice for orchestration issues
Subagent 3: Investigate src/paymentservice for payment processing bugs
Subagent 4: Investigate src/cartservice for data consistency issues

Use the bug-hunter approach for each.
Compile all findings into a prioritized bug report.
```

**Expected Output:**
- 4 parallel investigations
- Findings categorized by severity
- Cross-service issue identification

---

### 4D: Built-In Review Skills (NEW)

Claude Code now bundles review skills — compare them with your custom bug-hunter.

**Code review (correctness bugs):**

```
/code-review
```

> Reviews the current diff / recent changes for correctness bugs. Run it after Claude (or you) make changes — e.g. after the Module 5 feature build. Takes an effort level (`/code-review high`), and supports `--fix` (apply the findings) and `--comment` (post them as inline PR comments). For a quick single-pass PR review there is also `/review <pr-number>`.

**Security review:**

```
/security-review
```

> Reviews pending changes for security vulnerabilities (injection, auth gaps, secrets, unsafe deserialization, etc.)

**Cleanup review:**

```
/simplify
```

> Looks for duplication, dead code, and unnecessary complexity in changed code — quality only, no bug hunting.

**Demo flow:**
1. Make a change (e.g., the discount feature from Module 5)
2. Run `/code-review` — triage the findings together
3. Run `/security-review` — discuss what classes of issues it looks for

**Optional — security guidance plugin** (checks every edit in real time):

```
/plugin install security-guidance
```

---

### 4E: Participant Debug Exercise

**Prompt:**

```
Analyze 3 services in parallel for potential issues:

Task 1: Check src/productcatalogservice for performance issues
Task 2: Check src/recommendationservice for error handling gaps
Task 3: Check src/cartservice for data validation issues

For each, report:
- Specific code locations with issues
- Severity (critical/warning/info)
- Suggested fix

Combine into a single report ordered by severity.
```

**Success Criteria:**
- Parallel debugging executed
- Issues identified with file:line references
- Has `bug-hunter.md` in `.claude/agents/`
- Has run `/code-review` at least once

---

<a id="module-5-development--mcp"></a>
## Module 5: Development & MCP

**Time:** 25 min | **Prerequisites:** Module 2 (plan mode)

### 5A: Feature Development Demo

This demo now uses **plan mode** explicitly (Module 2A) instead of asking for a plan in the prompt.

**Step 1:** Enter plan mode (`Shift+Tab` until `plan`)

**Step 2 — Prompt:**

```
Add a promotional discount code feature to the checkout flow:

1. Create a discount code input field on the cart/checkout page
2. Support these discount codes:
   - SAVE10 - 10% off entire order
   - FREESHIP - Free shipping (set shipping to $0)
   - ASTRO20 - 20% off orders over $100
3. Validate discount codes against a simple in-memory store
4. Display the discount amount and updated total
5. Ensure the discount is applied in the order confirmation
6. Add appropriate OpenTelemetry spans for discount validation
```

**Step 3:** Review the plan, edit it if needed (`Ctrl+G`), then approve with "auto-accept edits"

**Step 4:** After the build completes, run `/code-review` (Module 4D)

**Expected Output:**
- Implementation plan first (enforced by plan mode, not by prompt phrasing)
- Multi-file changes consistent with existing patterns
- Review findings triaged

---

### 5B: MCP Configuration

MCP (Model Context Protocol) servers extend Claude Code's capabilities by connecting to external tools. Claude Code uses the `claude mcp add` CLI command to configure servers.

**Adding MCP Servers:**

| Transport | Use Case | Example |
|-----------|----------|---------|
| `http` | Remote cloud services (recommended) | GitHub, Sentry, Notion |
| `sse` | Server-Sent Events (**deprecated** — use `http`) | Legacy services |
| `stdio` | Local processes | Playwright, Filesystem |

**Scope Options:**

| Scope | Storage Location | Use Case |
|-------|------------------|----------|
| `local` | `~/.claude.json` (per project) | Personal, single project (default) |
| `project` | `.mcp.json` in project root | **Team sharing, plugin bundling** |
| `user` | `~/.claude.json` (global) | Personal, all projects |

> **For this workshop**, we use `--scope project` so the configuration is stored in `.mcp.json` and can later be bundled with a plugin.

**Workshop MCP Servers:**

```bash
# 1. Add Playwright MCP (browser automation)
claude mcp add --transport stdio --scope project playwright -- npx -y @playwright/mcp@latest

# 2. Add GitHub MCP (repository operations)
claude mcp add --transport http --scope project github https://api.githubcopilot.com/mcp/

# 3. Add Filesystem MCP (file operations outside repo)
claude mcp add --transport stdio --scope project filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/allowed/directory
```

> **Syntax notes:**
> - Options (`--transport`, `--scope`, `--env`, `--header`) go **before** the server name
> - `--` separates the server name from the command that launches a stdio server

**Resulting `.mcp.json` file (created automatically):**

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/directory"]
    }
  }
}
```

**Environment variable expansion (NEW):** `.mcp.json` supports `${VAR}` and `${VAR:-default}` syntax, so teams can share configs without sharing secrets:

```json
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

**Managing MCP Servers:**

```bash
# List all configured servers
claude mcp list

# Get details for a specific server
claude mcp get playwright

# Remove a server
claude mcp remove playwright

# Authenticate an OAuth server from the CLI (NEW)
claude mcp login github

# Check server status (within Claude Code)
/mcp
```

**Tool Search / Deferred Loading (NEW):**

When you connect many MCP servers, Claude Code no longer loads every tool definition into context up front. Tools are *deferred* and loaded on demand via tool search. This keeps large MCP setups cheap.

```bash
# Default: tool search enabled (tools loaded on demand)
# Force all tools to load upfront:
ENABLE_TOOL_SEARCH=false claude

# Always load a specific server's tools (in .mcp.json):
# "alwaysLoad": true
```

**Authentication:**

Some MCP servers (like GitHub) require OAuth authentication:

1. Add the server using `claude mcp add`
2. Start Claude Code: `claude`
3. Run `/mcp` command
4. Select the server and click "Authenticate"
5. Complete OAuth flow in browser

Or do it entirely from the terminal: `claude mcp login <server-name>` / `claude mcp logout <server-name>`.

**Windows Users Note:**

On native Windows (not WSL), use the `cmd /c` wrapper for stdio servers:

```bash
claude mcp add --transport stdio --scope project playwright -- cmd /c npx -y @playwright/mcp@latest
```

---

### 5C: MCP Demo Prompts

**Playwright MCP (Browser Automation):**

```
Use Playwright to:
1. Open the demo application at http://localhost:8080
2. Take a screenshot of the homepage
3. Click on a product and capture that page too
4. Report what UI elements are visible
```

**GitHub MCP (Repository Operations):**

> **Note:** GitHub MCP requires OAuth authentication. Run `/mcp` first, select "github", and click "Authenticate" to complete the OAuth flow in your browser.

```
Use the GitHub MCP to:
1. List the open issues in this repository
2. Summarize what bugs or features are requested
3. Suggest which our bug-hunter subagent could help investigate
```

**Filesystem MCP (External File Access):**

```
Use the Filesystem MCP to:
1. List files in the allowed directory
2. Read the contents of a specific file
3. Create a summary of what files are available
```

---

### 5D: Participant MCP Setup

**Step 1: Verify Node.js is installed**

```bash
node --version
# Should output v18.x or higher
```

**Step 2: Add MCP servers using CLI**

```bash
# Navigate to the project directory
cd opentelemetry-demo

# Add Playwright MCP (simplest to test)
claude mcp add --transport stdio --scope project playwright -- npx -y @playwright/mcp@latest
```

**Step 3: Verify the configuration was created**

```bash
cat .mcp.json
```

**Step 4: Start Claude Code and verify**

```bash
claude
```

Then run:

```
/mcp
```

You should see `playwright` listed as an available server.

**Step 5: Test the MCP server**

```
Use Playwright to take a screenshot of http://localhost:8080
```

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "Command not found: claude" | Ensure Claude Code is installed and in PATH |
| "npx: command not found" | Install Node.js (v18+) |
| Server not appearing in `/mcp` | Restart Claude Code after adding servers, or run `/mcp` to reconnect |
| "Connection closed" on Windows | Use `cmd /c` wrapper (see 5B) |
| GitHub authentication fails | Ensure you have a GitHub account and try `/mcp` again |
| `.mcp.json` not created | Check you're in the correct directory |
| Too many tools / context bloat | Tool search is on by default; check `/context` |

---

### 5E: Participant Development Exercises

**Task A — New Feature (use plan mode):**

```
Add a "wishlist" feature to this application:
1. Users can save products for later
2. Store wishlist data using the existing cart service patterns
3. Add API endpoints to the frontend service
4. Follow the existing code patterns in this repo
```

**Task B — Refactoring:**

```
Refactor src/cartservice to improve code quality:
- Extract repeated logic into helper functions
- Improve error messages to be more descriptive
- Add input validation where missing

Keep all existing functionality working.
Run /simplify when you're done and apply its suggestions.
```

**Task C — New API Endpoint (use plan mode):**

```
Add a "search products" endpoint to productcatalogservice:
- Accept a search query string
- Filter products by name or description
- Return matching products sorted by relevance
- Include proper error handling
```

---
<a id="module-6-multi-agent-orchestration"></a>
## Module 6: Multi-Agent Orchestration (NEW)

**Time:** 25 min | **Prerequisites:** Module 1 (subagents)

In v2 of this workshop, "parallel subagents" was the most advanced orchestration pattern. Claude Code now has several layers above that.

### 6A: Background Tasks & Agent View

Long-running work no longer has to block your session.

**Run an agent in the background:**

```
In the background, generate a full dependency report for every service
in src/ — language, framework, direct dependencies, and license.
Tell me when it's done.
```

**Expected Behavior:**
- The task runs as a background agent; you keep working in the same session
- Claude notifies you when it completes

**Launch a background agent straight from the terminal:**

```bash
claude --bg "Generate a dependency report for every service in src/"
```

Background agents run in an isolated git worktree (`.claude/worktrees/<id>`), and can auto-commit, push, and open a **draft PR** when they finish.

**Monitor everything from one place:**

```bash
# From a new terminal — opens the agent dashboard (research preview)
claude agents
```

The agent view shows all running, blocked, and completed sessions; you can attach, reply, or dispatch new agents from there. Companion commands: `claude attach`, `claude logs`, `claude stop`.

---

### 6B: Agent Teams (Experimental)

Agent teams let multiple specialized agents collaborate on one task — each with its own context window, coordinated by a lead agent.

**Enable (opt-in via environment variable):**

```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude
```

**Demo prompt:**

```
Create an agent team to add health-check endpoints to every service in src/:

- One teammate handles the Go services
- One teammate handles the Python services
- One teammate handles the JS/TS services
- One teammate handles the .NET services

Each teammate should follow the existing patterns in its services.
The lead should verify consistency across all implementations at the end.
```

**Expected Behavior:**
- A lead agent decomposes the work and spawns teammates
- Teammates claim tasks, work independently, and report back
- The lead synthesizes and cross-checks the results

**Teaching points:**
- Agent teams vs. parallel subagents: subagents are fire-and-forget workers; teammates can communicate, claim tasks, and be steered mid-flight
- Every session now has one implicit team — there is no setup step; the lead simply spawns named teammates
- You can talk to an individual teammate directly while the team runs
- Quality gates can be enforced with hooks (e.g., a teammate can't mark a task done until tests pass)
- Cost warning: a full team can burn ~7x the tokens of a single session

---

### 6C: Dynamic Workflows & `ultracode`

Workflows are scripted, deterministic orchestration: Claude writes a small orchestration script that fans out dozens (or hundreds) of subagents, with loops, barriers, and verification stages. They are now available on **all paid plans** (Pro: opt-in via `/config`).

**Trigger:** include the keyword **`ultracode`** in your prompt — or run `/effort ultracode` once to make Claude orchestrate a workflow automatically for every substantive task.

**Demo prompt:**

```
ultracode — review this codebase for error-handling gaps:

1. Fan out one reviewer agent per service in src/
2. For every finding, spawn a verifier agent that tries to refute it
3. Only report findings that survive verification
4. Produce a final report grouped by severity
```

**Expected Behavior:**
- Claude authors a workflow script (phases, number of agents) and runs it
- A progress tree shows each phase and agent; manage runs with `/workflows` (pause / resume / save)
- The result is a verified, deduplicated report

**Good to know:**
- Limits: 16 concurrent agents, up to 1,000 agents per run; workflow subagents run in `acceptEdits`
- Saved workflows live in `.claude/workflows/` and become reusable slash commands
- `/deep-research` is a bundled workflow — a ready-made example of the pattern

**When to use what:**

| Pattern | Best for |
|---------|----------|
| Single subagent | Isolated research/task, keep main context clean |
| Parallel subagents | Independent chunks of the same job |
| Agent team | Collaborative work needing coordination & communication |
| Workflow | Large-scale fan-out with deterministic control flow (audits, migrations, sweeps) |

---

### 6D: Goal-Driven & Recurring Sessions

```
/goal All tests in src/cartservice pass and coverage is above 80%
```

> Claude keeps working — iterating, running tests, fixing failures — until the goal condition is met.

```
/loop 10m Check whether any new TODO comments were added to src/ and list them
```

> Runs a prompt on a recurring interval.

```
/schedule
```

> Creates **Routines** — recurring cloud runs (cron-style) that fire in Claude Code on the web even when your machine is off.

---

### 6E: Claude Code on the Web

Claude Code also runs as a managed cloud service (research preview for Pro, Max, Team, and Enterprise) — useful when you want agents working while your laptop is closed. There is no separate compute charge; cloud sessions share your plan's usage limits.

**Access:** [https://claude.ai/code](https://claude.ai/code), or straight from your terminal:

```bash
claude --cloud "Add unit tests for the currency service"   # run in the cloud
claude --teleport                                          # pull a cloud session into your terminal
```

| Capability | Description |
|------------|-------------|
| GitHub repos | Connect a repo; sessions run in an isolated cloud container |
| Parallel sessions | Kick off multiple independent sessions on the same or different repos |
| PR auto-fix | `/autofix-pr` — sessions watch a PR, respond to review comments, and fix CI failures |
| Mobile | Start/steer sessions from the Claude mobile app; push notifications |
| Teleport | Move a session between web and your local CLI |
| Setup scripts | Pre-install dependencies for the cloud environment |

**Demo (instructor, requires eligible plan):**
1. Open claude.ai/code, connect the workshop repo fork
2. Start a session: "Add unit tests for the currency service"
3. Show the same session from the mobile app
4. Show the PR it creates when done

**Workshop relevance:** everything built in this workshop (subagents, skills, plugins, MCP project config) is filesystem-based — committed to the repo, it works identically in cloud sessions.

---

<a id="module-7-skills-packaging--marketplace"></a>
## Module 7: Skills, Packaging & Marketplace

**Time:** 25 min | **Prerequisites:** Modules 1, 4 (the agents you'll package)

So far, everything you've built — `service-documenter` (Module 1) and `bug-hunter` (Module 4) — lives directly in this project's `.claude/` directory and just works. In this module you'll add one more component (a skill), then **package all of it into a distributable plugin in a single step (7B)**. Build first, package once at the end.

### 7A: Code-Reviewer Skill

Skills are reusable procedures, structured the same way as agents: one directory per skill in `.claude/skills/`, with a `SKILL.md` inside.

**Directory Setup:**

```bash
mkdir -p .claude/skills/code-reviewer
```

**File:** `.claude/skills/code-reviewer/SKILL.md`

```markdown
---
name: code-reviewer
description: Review code for quality, patterns, and potential issues. Use when reviewing PRs, auditing code quality, or preparing for code review.
argument-hint: "[directory or file to review]"
---

# Code Review Skill

Review the code at: $ARGUMENTS

When reviewing code, analyze for:

## Code Quality
- Clear naming conventions
- Appropriate function/method length
- Single responsibility principle
- DRY (Don't Repeat Yourself) violations

## Error Handling
- All error paths handled
- Meaningful error messages
- No swallowed exceptions
- Proper cleanup in error cases

## Performance
- Unnecessary allocations
- N+1 query patterns
- Missing caching opportunities
- Inefficient algorithms

## Security Basics
- Input validation present
- No hardcoded secrets
- Proper authentication checks

## Output Format
Provide findings as:
- 🔴 **Critical** - Must fix before merge
- 🟡 **Warning** - Should address
- 🟢 **Suggestion** - Nice to have

Include file paths and line numbers for each finding.
```

**What's new in skill frontmatter (2026):**

| Field | Purpose |
|-------|---------|
| `argument-hint` | Hint shown in the `/` menu for what arguments to pass |
| `arguments` | Named arguments → `$name` substitution in the body |
| `disable-model-invocation: true` | Only you can invoke it (Claude won't trigger it automatically) |
| `user-invocable: false` | Only Claude can use it (hidden from the `/` menu) |
| `allowed-tools` | Pre-approve tools the skill may use |
| `context: fork` | Run the skill in an isolated subagent context |
| `model` / `effort` | Override model or effort while the skill runs |
| `paths` | Only activate the skill when working on matching file paths |

> **Naming rule:** the **directory name** determines the `/command` name — the `name` field is now just an optional display label. In fact *all* frontmatter fields are optional; `description` is just strongly recommended so Claude knows when to use the skill.

**String substitutions available in skill bodies:**

| Token | Value |
|-------|-------|
| `$ARGUMENTS` | Everything typed after the skill name |
| `$0`, `$1`, … | Positional arguments |
| `$name` | Named argument (when `arguments:` is declared) |
| `` !`command` `` | Output of a shell command, injected before Claude sees the prompt |

**Test Prompt:**

```
/code-reviewer src/paymentservice
```

The skill is active as soon as the file is saved — no installation step needed.

> **Note:** `/commands/` (the old custom slash-command directory) has merged into skills. If you used custom commands in v2, move them to `.claude/skills/<name>/SKILL.md`.

---

### 7B: Assemble the Plugin (One Step)

You now have three working components, all living in this project's `.claude/` directory:

| Component | Type | Location | Built in |
|-----------|------|----------|----------|
| `service-documenter` | Subagent | `.claude/agents/service-documenter.md` | Module 1 |
| `bug-hunter` | Subagent | `.claude/agents/bug-hunter.md` | Module 4 |
| `code-reviewer` | Skill | `.claude/skills/code-reviewer/SKILL.md` | Module 7A |

A **plugin** is nothing more than these same files arranged in a standard, distributable layout with a manifest. A plugin directory can live **anywhere** — we'll build ours as a sibling of the repo so it's clearly a standalone, distributable thing. Assemble it now — this is the only plugin-structure step in the whole workshop:

**Step 1: Create the plugin layout** (from inside `opentelemetry-demo`)

```bash
mkdir -p ../codebase-toolkit/.claude-plugin
mkdir -p ../codebase-toolkit/agents
mkdir -p ../codebase-toolkit/skills
```

**Step 2: Copy your components into it**

```bash
cp .claude/agents/service-documenter.md ../codebase-toolkit/agents/
cp .claude/agents/bug-hunter.md ../codebase-toolkit/agents/
cp -r .claude/skills/code-reviewer ../codebase-toolkit/skills/
```

**Step 3: Create the plugin manifest**

**File:** `../codebase-toolkit/.claude-plugin/plugin.json`

```json
{
  "name": "codebase-toolkit",
  "description": "A toolkit for onboarding to new codebases. Includes parallel documentation generation, automated bug hunting, and code review capabilities.",
  "version": "2.0.0",
  "author": {
    "name": "Workshop Participant"
  },
  "keywords": ["documentation", "debugging", "code-review", "onboarding"]
}
```

> **Common mistake:** only `plugin.json` goes inside `.claude-plugin/` — the `agents/`, `skills/`, `hooks/` directories sit at the plugin **root**.

> **How minimal can it get?** `name` is the only required manifest field — and the manifest itself is now optional (components are auto-discovered, the directory name becomes the plugin name, and without a `version` each git commit counts as a new version). We write a real one because a distributable plugin should describe itself.

> **Shortcut:** `claude plugin init codebase-toolkit` scaffolds a plugin skeleton for you — by default into `~/.claude/skills/codebase-toolkit/`, a "skills-directory plugin" that auto-loads in every session without any install step. We assemble ours by hand in a plain directory so the layout is explicit.

---

### 7C: Verify and Validate the Plugin

**Verify your plugin has this structure:**

```
codebase-toolkit/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/
│   ├── service-documenter.md    # Documentation subagent
│   └── bug-hunter.md            # Debugging subagent
├── skills/
│   └── code-reviewer/
│       └── SKILL.md             # Code review skill
├── hooks/
│   └── hooks.json               # (optional) hooks bundled with the plugin
└── .mcp.json                    # (optional) MCP servers bundled with the plugin
```

> **Plugins can bundle much more than agents and skills:** hooks, MCP servers, LSP servers (`.lsp.json`), output styles, default settings, and even executables (`bin/`, added to PATH while the plugin is enabled) all travel with the plugin.

**Validate the plugin:**

```bash
claude plugin validate ../codebase-toolkit
```

**Test it locally without installing:**

```bash
claude --plugin-dir ../codebase-toolkit
```

> `--plugin-dir` also accepts a `.zip`; `--plugin-url` loads a hosted zip.

---

### 7D: Create Local Test Marketplace

A marketplace is a directory containing a manifest that lists available plugins. We'll create a local one to test before publishing to GitHub.

**Step 1: Create marketplace directory (sibling to the repo)**

```bash
# From inside opentelemetry-demo, go up one level
cd ..

# Create the marketplace structure and copy the plugin in
mkdir -p test-marketplace/.claude-plugin
cp -r codebase-toolkit test-marketplace/
```

**Step 2: Create marketplace manifest**

**File:** `test-marketplace/.claude-plugin/marketplace.json`

```json
{
  "name": "test-marketplace",
  "owner": {
    "name": "Workshop Participant"
  },
  "plugins": [
    {
      "name": "codebase-toolkit",
      "source": "./codebase-toolkit",
      "description": "A toolkit for onboarding to new codebases"
    }
  ]
}
```

**Directory structure after this step:**

```
~/workshop/
├── opentelemetry-demo/              # Cloned demo repo (work happens here)
├── codebase-toolkit/                # Plugin assembled in 7B
└── test-marketplace/                # This becomes your GitHub marketplace
    ├── .claude-plugin/
    │   └── marketplace.json         # source: "./codebase-toolkit"
    └── codebase-toolkit/            # Copy of the plugin
        ├── .claude-plugin/
        │   └── plugin.json
        ├── agents/
        └── skills/
```

---

### 7E: Install and Test Plugin Locally

**Step 1: Remove the working copies (clean slate)**

Your components now exist in two places: the working copies you built in Modules 1, 4, and 7A, and the copies inside the plugin (7B). Remove the working copies so you can prove the plugin alone provides them:

```bash
cd opentelemetry-demo
rm -f .claude/agents/service-documenter.md
rm -f .claude/agents/bug-hunter.md
rm -rf .claude/skills/code-reviewer
```

**Step 2: Add the marketplace and install**

```bash
claude
```

```
/plugin marketplace add ../test-marketplace
```

```
/plugin install codebase-toolkit@test-marketplace
```

Select "Install now" when prompted.

**Step 3: Reload plugins (no restart needed) (NEW)**

```
/reload-plugins
```

**Step 4: Test the plugin**

```
/codebase-toolkit:code-reviewer src/cartservice
```

> Plugin skills are namespaced as `/plugin-name:skill-name` to avoid collisions. If there's no conflict, the short form `/code-reviewer` also works.

---

### 7F: Publish to GitHub Marketplace

**GitHub Marketplace Repository:** `rishikeshradhakrishnan/marketplace`

The marketplace repository structure:

```
marketplace/                              # GitHub repo
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace manifest
└── plugins/
    └── codebase-toolkit/                 # Plugin copied here
        ├── .claude-plugin/
        │   └── plugin.json
        ├── agents/
        │   ├── service-documenter.md
        │   └── bug-hunter.md
        └── skills/
            └── code-reviewer/
                └── SKILL.md
```

**Step 1: Clone the marketplace repo**

```bash
cd ~
git clone https://github.com/rishikeshradhakrishnan/marketplace.git
cd marketplace
```

**Step 2: Create the directory structure**

```bash
mkdir -p .claude-plugin
mkdir -p plugins
```

**Step 3: Copy your plugin**

```bash
cp -r ~/workshop/codebase-toolkit plugins/
```

**Step 4: Create the marketplace manifest**

**File:** `.claude-plugin/marketplace.json`

```json
{
  "name": "rishikesh-marketplace",
  "owner": {
    "name": "Rishikesh Radhakrishnan"
  },
  "metadata": {
    "description": "Claude Code plugins for developer productivity",
    "version": "2.0.0"
  },
  "plugins": [
    {
      "name": "codebase-toolkit",
      "source": "./plugins/codebase-toolkit",
      "description": "A toolkit for onboarding to new codebases. Includes parallel documentation, debugging, and code review.",
      "version": "2.0.0",
      "author": {
        "name": "Workshop Participant"
      },
      "keywords": ["documentation", "debugging", "code-review", "onboarding"]
    }
  ]
}
```

**Step 5: Commit and push**

```bash
git add .
git commit -m "Add codebase-toolkit plugin v2.0.0"
git push origin main
```

**Step 6: Add the GitHub marketplace to Claude Code**

```bash
cd ~/workshop/opentelemetry-demo
claude
```

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

---

### 7G: Browse Existing Marketplaces

Anthropic's **official marketplace** (`claude-plugins-official`) registers automatically the first time you start Claude Code — the `security-guidance` plugin from Module 4D comes from there.

**Add the community marketplace:**

```
/plugin marketplace add anthropics/claude-plugins-community
```

**Browse available plugins:**

```
/plugin
```

Select "Browse Plugins" to see available options.

**List all known marketplaces:**

```
/plugin marketplace list
```

**Available Marketplaces:**

| Marketplace | Source | Description |
|-------------|--------|-------------|
| claude-plugins-official | Auto-registered | Official Anthropic plugins (e.g. `security-guidance`) |
| anthropics/claude-plugins-community | GitHub | Community-contributed plugins (submission + review pipeline) |
| rishikeshradhakrishnan/marketplace | GitHub | Workshop plugins |
| test-marketplace | Local | Local testing |

> You can submit your plugin to the community marketplace for review — run `claude plugin validate` first, then follow the submission process in the `anthropics/claude-plugins-community` repo.

---

<a id="module-8-reusability-demo"></a>
## Module 8: Reusability Demo

**Time:** 10 min | **Prerequisites:** Module 7

### 8A: Clone Fresh Repository

**Step 1: Navigate to a new directory**

```bash
cd ~
mkdir plugin-demo
cd plugin-demo
```

**Step 2: Clone the OpenTelemetry demo fresh (main branch, no modifications)**

```bash
git clone https://github.com/open-telemetry/opentelemetry-demo.git
cd opentelemetry-demo
```

---

### 8B: Install Plugin from Marketplace

**Step 1: Start Claude Code**

```bash
claude
```

**Step 2: Add the GitHub marketplace**

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

**Step 3: Install the plugin**

```
/plugin install codebase-toolkit@rishikesh-marketplace
```

**Step 4: Reload plugins**

```
/reload-plugins
```

---

### 8C: Use Plugin on New Codebase

**Option 1: Use the code-reviewer skill**

```
/code-reviewer src/frontend
Focus on error handling and TypeScript best practices.
```

**Option 2: Use the service-documenter subagent**

```
Use the service-documenter subagent to document
src/checkoutservice and src/paymentservice in parallel.
Create a combined services documentation file.
```

**Option 3: Use bug-hunter for parallel debugging**

```
Use 3 bug-hunter subagents in parallel to investigate:
- src/cartservice
- src/productcatalogservice
- src/recommendationservice

Compile findings into a prioritized report.
```

**Closing teaching point:** the entire toolkit — agents, skills, hooks, MCP config — moved to a brand-new codebase with two commands. That's the payoff of packaging as a plugin.

---
<a id="module-9-claude-managed-agents--the-agent-sdk"></a>
## Module 9: Claude Managed Agents & the Agent SDK (NEW)

**Time:** 30 min | **Prerequisites:** Module 0, an Anthropic API key (Console account)

Everything so far ran Claude Code *interactively*. This module covers running Claude as an agent **programmatically** — first in your own process (Agent SDK), then on Anthropic's managed infrastructure (Claude Managed Agents).

### 9A: The Landscape — Which Tool When?

| | **Claude Code** | **Claude Agent SDK** | **Claude Managed Agents** | **Messages API** |
|---|---|---|---|---|
| What it is | Interactive coding product (CLI + web) | Python/TS library that runs the agent loop in *your* process | Hosted agent harness run by Anthropic (public beta) | Direct model access |
| Runs on | Your machine / Anthropic cloud | Your infrastructure | Anthropic-managed sandbox | Stateless API calls |
| Agent works on | Your working directory | Files on your infrastructure | A managed sandbox per session | N/A — you build the loop |
| Best for | Day-to-day development | Local prototyping, agents over your filesystem/services | Production agents without operating infra; long-running & async work | Full control, custom agent loops |
| Interface | Terminal / browser | `query()` in Python/TypeScript | REST API / SDKs / `ant` CLI | REST API / SDKs |

**Anthropic's recommended path:** prototype with the **Agent SDK** locally → move to **Managed Agents** for production.

> Don't confuse **Claude Code on the web** (Module 6E — subscription product, no per-hour compute charge) with **Managed Agents** (API product: token costs + $0.08/session-hour). Both use "environments" and "sessions" as concepts, but they are different products.

---

### 9B: The Agent SDK in 5 Minutes

The Agent SDK (formerly "Claude Code SDK") gives you the same agent harness Claude Code uses, as a library.

**Install:**

```bash
# TypeScript
npm install @anthropic-ai/claude-agent-sdk

# Python (3.10+)
pip install claude-agent-sdk
```

**Minimal Python example:**

```python
import asyncio
from claude_agent_sdk import query

async def main():
    async for message in query(
        prompt="Analyze src/paymentservice and list its error handling gaps"
    ):
        print(message)

asyncio.run(main())
```

**Minimal TypeScript example:**

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Analyze src/paymentservice and list its error handling gaps",
  options: { allowedTools: ["Read", "Grep", "Glob"] },
})) {
  console.log(message);
}
```

**What the SDK gives you for free:**
- The full tool suite (Read, Write, Edit, Bash, Grep, Glob, WebSearch, …)
- Subagents, hooks, permission modes, MCP servers
- Session management (resume, fork)
- It reads the same `.claude/` filesystem config you built in this workshop — your skills, agents, and CLAUDE.md work here too

**Headless one-liner (no code at all):**

```bash
claude -p "List all services in src/ with their primary language" --output-format json
```

> `-p` (print mode) runs a single non-interactive prompt — the simplest way to put Claude Code in a script or CI pipeline.

---

### 9C: Claude Managed Agents — Concepts

Claude Managed Agents (public beta since April 2026) is the hosted version: Anthropic runs the agent loop *and* the sandbox.

**Four core concepts:**

| Concept | What it is |
|---------|-----------|
| **Agent** | The configuration: model, system prompt, tools, MCP servers, skills. Created once, versioned, referenced by ID. |
| **Environment** | Where sessions run: an Anthropic-managed cloud sandbox, or a self-hosted sandbox on your infra. |
| **Session** | A running instance of an agent in an environment, working on a task. Stateful, resumable, long-running. |
| **Events** | The message stream between your app and the agent (user messages, agent output, tool use, status changes). |

**What the managed sandbox provides:**
- Bash, file operations, web search, web fetch (the built-in `agent_toolset`)
- MCP server connections (configurable mid-session)
- Persistent filesystem per session
- Server-sent event streaming
- Memory (beta), multiagent orchestration (beta), webhooks

**Added since the April launch:** scheduled deployments (cron-triggered sessions), multi-agent sessions (threaded events), outcomes (`user.define_outcome`), a memory store (beta), and **self-hosted sandboxes** (run the sandbox on your own infra via `ant beta:worker`).

**Pricing model (beta):**
- Standard token rates (e.g. Opus 4.8: $5/M input, $25/M output)
- **Plus** $0.08 per session-hour, metered only while the session is actively `running` (idle time is free)
- Example from the docs: a 1-hour Opus 4.8 session using 50K input / 15K output tokens ≈ **$0.71 total**

---

### 9D: Managed Agents Quickstart (Python)

**Prerequisites:**

```bash
pip install anthropic
export ANTHROPIC_API_KEY=sk-ant-...
```

> All Managed Agents endpoints are in public beta and require the `managed-agents-2026-04-01` beta header — the official SDKs set it automatically.

**Step 1 — Create an agent (once; reuse the ID):**

```python
from anthropic import Anthropic

client = Anthropic()

agent = client.beta.agents.create(
    name="Codebase Analyst",
    model="claude-opus-4-8",
    system="You are a code analysis specialist. Be precise and always cite file paths.",
    tools=[{"type": "agent_toolset_20260401"}],
)
print(f"Agent created: {agent.id}")
```

**Step 2 — Create an environment:**

```python
environment = client.beta.environments.create(
    name="workshop-env",
    config={"type": "cloud", "networking": {"type": "unrestricted"}},
)
print(f"Environment created: {environment.id}")
```

**Step 3 — Start a session and stream events:**

```python
session = client.beta.sessions.create(
    agent=agent.id,
    environment_id=environment.id,
    title="Analyze the OpenTelemetry demo",
)

with client.beta.sessions.events.stream(session.id) as stream:
    client.beta.sessions.events.send(session.id, events=[{
        "type": "user.message",
        "content": [{
            "type": "text",
            "text": (
                "Clone https://github.com/open-telemetry/opentelemetry-demo, "
                "then produce a markdown report listing every service, its language, "
                "and its direct service dependencies. Save it as report.md."
            ),
        }],
    }])

    for event in stream:
        if event.type == "agent.message":
            for block in event.content:
                print(block.text, end="")
        elif event.type == "agent.tool_use":
            print(f"\n[Using tool: {event.name}]")
        elif event.type == "session.status_idle":
            print("\nAgent finished.")
            break
```

**Key teaching points:**
- The **agent** is configuration (like a subagent `.md` file, but server-side and versioned)
- The **session** is execution — you can have many sessions per agent
- The sandbox is real: the agent actually clones the repo, runs commands, and writes files on Anthropic's infrastructure
- Sessions survive disconnects — reconnect to the stream and pick up where you left off

---

### 9E: The `ant` CLI

Alongside Managed Agents, Anthropic shipped a CLI for the Claude API itself:

```bash
# Install (macOS/Linux via Homebrew)
brew install anthropics/tap/ant
```

```bash
# Create an agent from the command line
ant beta:agents create \
  --name "Codebase Analyst" \
  --model '{id: claude-opus-4-8}' \
  --tool '{type: agent_toolset_20260401}'

# List agents
ant beta:agents list

# Resources can be versioned as YAML files and applied like infrastructure-as-code
```

> There is also a guided onboarding inside Claude Code itself: `/claude-api managed-agents-onboard`

---

### 9F: Participant Exercise — Your First Managed Agent

**Goal:** turn the bug-hunter from Module 4 into a hosted agent.

```python
bug_hunter = client.beta.agents.create(
    name="Bug Hunter",
    model="claude-opus-4-8",
    system="""You are a debugging specialist. When investigating a service:
1. Check all error handling paths
2. Look for unhandled exceptions
3. Identify potential race conditions
4. Find timeout/retry issues
5. Check for null/undefined handling

Report findings as:
- CRITICAL: [issue + file:line] - must fix immediately
- WARNING: [issue + file:line] - should address
- INFO: [observation] - minor improvement""",
    tools=[{"type": "agent_toolset_20260401"}],
)
```

Then start a session that:
1. Clones the demo repo
2. Investigates `src/paymentservice`
3. Writes findings to `bug-report.md`

**Success criteria:**
- Agent created and reusable by ID
- Session completed and report produced
- Participant can explain when they'd use this vs. running Claude Code locally

**Discussion prompts:**
- What would you build if an agent could run for hours without your laptop being open?
- How does the same "bug-hunter" idea exist at three altitudes: subagent (Module 4) → plugin (Module 7) → managed agent (here)?

---

<a id="appendix-a-claude-models--opus-45--48"></a>
## Appendix A: Claude Models — Opus 4.5 → Fable 5

Reference for instructors. All dates and capabilities verified against Anthropic release notes as of July 2026.

### Release Timeline

| Released | Model | API Model ID | Context | Max Output | Pricing (in/out per MTok) | Headline |
|----------|-------|--------------|---------|------------|---------------------------|----------|
| Oct 2025 | Haiku 4.5 | `claude-haiku-4-5` | 200K | 64K | $0.80 / $4 | Near-Sonnet performance at Haiku speed/cost |
| Nov 2025 | **Opus 4.5** | `claude-opus-4-5` | 200K | 128K | $5 / $25 | 67% price cut vs Opus 4; effort parameter (beta) |
| Feb 2026 | **Opus 4.6** | `claude-opus-4-6` | **1M** | 128K | $5 / $25 | Adaptive thinking; 1M context; compaction API |
| Feb 2026 | Sonnet 4.6 | `claude-sonnet-4-6` | 1M | 128K | $3 / $15 | Opus-4.5-level coding at Sonnet price |
| Apr 2026 | **Opus 4.7** | `claude-opus-4-7` | 1M | 128K | $5 / $25 | `xhigh` effort; 3x vision resolution |
| May 2026 | **Opus 4.8** | `claude-opus-4-8` | 1M | 128K | $5 / $25 | Refined adaptive thinking; 4x better at catching code flaws; cheaper fast mode |
| Jun 2026 | **Claude Fable 5** | `claude-fable-5` | 1M | 128K | $10 / $50 | New flagship family above Opus; adaptive-thinking-only; built-in safety classifiers |
| Jun 2026 | **Sonnet 5** | `claude-sonnet-5` | 1M | 128K | $3 / $15 (intro $2/$10 until Aug 31) | Native 1M context; new default for Pro plans |

> There is no Sonnet 4.7/4.8 or Haiku 4.6+ — Sonnet jumped from 4.6 straight to 5. The full 1M window is standard-priced (no long-context surcharge) on Opus 4.6+, Sonnet 4.6/5, and Fable 5.

### What Each Release Added for Coding/Agent Workflows

**Opus 4.5 (Nov 2025)**
- Effort parameter (beta): `low` / `medium` / `high`
- Tool search tool + programmatic tool calling (beta)
- 50–75% fewer tokens for equivalent output quality vs Opus 4

**Opus 4.6 (Feb 2026)**
- **Adaptive thinking** — replaces manual thinking budgets; the model decides reasoning depth per turn
- **1M-token context window** (GA March 2026)
- **Compaction API** — server-side conversation summarization for effectively unbounded sessions
- Effort `max` level; automatic prompt caching
- Agent teams support in Claude Code

**Sonnet 4.6 (Feb 2026)**
- First Sonnet preferred over the previous Opus (4.5) in coding evals
- 1M context; full agentic toolkit (memory, tool search, programmatic tool calling) at GA

**Opus 4.7 (Apr 2026)**
- **`xhigh` effort level** — recommended for complex agentic coding
- Vision resolution up 3x (to ~2,576px long edge)
- Advisor tool (beta): pair a fast executor model with a high-intelligence advisor
- Launched alongside Claude Managed Agents (public beta) and the `ant` CLI

**Opus 4.8 (May 2026)**
- Refined adaptive thinking — reasons only when the turn needs it
- **4x less likely than Opus 4.7 to miss code flaws** (better code review/verification)
- Fast mode price cut to $10/$50 (research preview)
- Mid-conversation system messages; refusal categories in `stop_details`
- Default model in Claude Code for Max/Team Premium/Enterprise/API accounts

**Claude Fable 5 (Jun 9, 2026)**
- New flagship model family positioned above Opus ($10/$50); 1M context, 128K output
- Adaptive thinking is the *only* thinking mode; raw chain-of-thought is never returned (summarized or omitted)
- Ships with safety classifiers that can decline requests (`stop_reason: "refusal"`), with a server-side `fallbacks` retry parameter (beta) and fallback billing credit
- Released alongside **Claude Mythos 5** — invitation-only, for defensive-cybersecurity work (Project Glasswing)
- Briefly unavailable June 12–30, 2026 under US export controls; access restored July 1
- In Claude Code: `/model fable` (alias `best`) — available on paid plans but not the default
- Uses the newer tokenizer (shared with Opus 4.7+/Sonnet 5): ~30% more tokens for the same text — budget accordingly

**Sonnet 5 (Jun 30, 2026)**
- Native 1M-token context at standard pricing; introductory rate $2/$10 through Aug 31, 2026 (then $3/$15)
- First Sonnet with `xhigh` effort support
- Default model for Free/Pro on claude.ai, and for Pro/Team Standard seats in Claude Code

### Key API Features (and when they became usable)

| Feature | Status (Jul 2026) | What it does |
|---------|-------------------|--------------|
| Effort parameter | GA | Tune reasoning depth: `low` → `xhigh`/`max` |
| Adaptive thinking | GA (Opus 4.6+) | Model self-regulates thinking; no manual budgets |
| 1M context window | GA | Whole-codebase context for Opus 4.6+/Sonnet 4.6 |
| Context compaction | Beta | Server-side summarization; "infinite" conversations |
| Tool search tool | GA | Discover/load tools on demand from large catalogs |
| Programmatic tool calling | GA | Claude calls tools from inside code execution |
| Memory tool | GA | Persist knowledge across conversations |
| Agent Skills API | GA | Server-side skills (incl. Office docs: xlsx, docx, pptx, pdf) |
| Code execution tool | GA | Sandboxed Python execution |
| Web search / web fetch tools | GA | Live web access from the API |
| Structured outputs | GA | Schema-enforced JSON responses |
| Fast mode | Research preview | ~2.5x faster output; Opus 4.8 at $10/$50 (Opus 4.6/4.7 fast modes retired) |
| Automatic prompt caching | GA | Caching without manual breakpoints |
| Cache diagnostics | Beta | `cache_miss_reason` for debugging cache hits |
| Claude Managed Agents | Public beta | Hosted agent harness (Module 9) |

### Models Retired/Deprecated in This Window

| Model | Status | Replacement |
|-------|--------|-------------|
| Claude Opus 3 | Retired (Jan 2026) | Opus 4.5+ |
| Claude Sonnet 3.5 / 3.7 | Retired / deprecated | Sonnet 4.6 |
| Claude Haiku 3 / 3.5 | Deprecated/retired | Haiku 4.5 |
| Claude Opus 4 / Sonnet 4 | Retired (June 2026) | Opus 4.7+ / Sonnet 5 |
| Claude Opus 4.1 | Deprecated (retires Aug 5, 2026) | Opus 4.5+ |

---

<a id="appendix-b-command--configuration-quick-reference"></a>
## Appendix B: Command & Configuration Quick Reference

### Slash Commands

| Command | Purpose | Module |
|---------|---------|--------|
| `/model` | Switch models / open model picker | 0 |
| `/effort` | Adjust reasoning effort | 2B |
| `/context` | Visualize context window usage | 1E, 2F |
| `/compact` | Summarize conversation to free context | 2F |
| `/usage` | Token breakdown by component | 1E, 2F |
| `/cost` | Session cost estimate | 2F |
| `/init` | Generate CLAUDE.md for the project | 2D |
| `/memory` | View/edit memory files (incl. auto memory) | 2D |
| `/rewind` | Open the checkpoint/rewind menu | 2C |
| `/hooks` | List configured hooks | 3D |
| `/mcp` | MCP server status & authentication | 5B |
| `/plugin` | Install/manage plugins & marketplaces | 7E |
| `/reload-plugins` | Reload plugins without restart | 7E |
| `/code-review` | Built-in correctness review (`--fix`, `--comment`) | 4D |
| `/security-review` | Built-in security review | 4D |
| `/simplify` | Built-in cleanup review | 4D |
| `/review` | Quick single-pass PR review | 4D |
| `/verify` | Verify a change actually works | 3C |
| `/run` | Launch the project's app | 3C |
| `/goal` | Work until a condition is met | 6D |
| `/loop` | Run a prompt on an interval | 6D |
| `/schedule` | Recurring cloud Routines | 6D |
| `/workflows` | Manage dynamic workflow runs | 6C |
| `/fast` | Toggle fast mode (Opus 4.8) | — |
| `/statusline` | Configure status line | 2G |
| `/status` | Account/model/settings overview | 2F |
| `/config` | Global settings (incl. output style) | 2G |
| `/help` | List all commands | — |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Shift+Tab` | Cycle permission modes (default → acceptEdits → plan → …) |
| `Esc` `Esc` | Open rewind/checkpoint menu (same as `/rewind`) |
| `Ctrl+O` | Expand/collapse Claude's thinking |
| `Ctrl+G` | Edit the current plan/prompt in your editor |
| `Ctrl+R` | Search conversation history across projects |

### CLI Flags & Commands

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `claude -p "<prompt>"` | Headless one-shot prompt (print mode) |
| `claude --model opus` | Start with a specific model |
| `claude --effort xhigh` | Start with a specific effort level |
| `claude --permission-mode plan` | Start in a specific permission mode |
| `claude --agent <name>` | Run an entire session as a specific subagent |
| `claude --bg "<task>"` | Launch a background agent |
| `claude --cloud "<task>"` | Run the task on Claude Code on the web |
| `claude --teleport` | Pull a cloud session into your terminal |
| `claude agents` | Open the agent view dashboard |
| `claude attach/logs/stop` | Manage background agents |
| `claude doctor` | Health check / full setup checkup |
| `claude update` | Update Claude Code |
| `claude mcp add/list/get/remove` | Manage MCP servers |
| `claude mcp login/logout <name>` | MCP OAuth from the CLI |
| `claude plugin init/validate/install/list` | Manage plugins |
| `claude --plugin-dir <path>` | Load a plugin for testing (dir or .zip) |

### Useful Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_MODEL` | Default model |
| `CLAUDE_CODE_EFFORT_LEVEL` | Default effort level |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Enable agent teams |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` | Disable auto memory |
| `CLAUDE_CODE_ENABLE_AUTO_MODE=1` | Enable Auto mode on Bedrock/Vertex/Foundry |
| `CLAUDE_CODE_DISABLE_WORKFLOWS=1` | Disable dynamic workflows |
| `ENABLE_TOOL_SEARCH` | Control MCP tool deferred loading |
| `MAX_MCP_OUTPUT_TOKENS` | Cap MCP tool output size |
| `MAX_THINKING_TOKENS=0` | Disable extended thinking |

---

<a id="appendix-c-changelog-from-v2"></a>
## Appendix C: Changelog from v2

| Section | Change |
|---------|--------|
| Overall structure | "Phases" → self-contained "Modules" with timings and suggested tracks; no fixed 90-minute constraint |
| Module 0 | Added `claude doctor`, `claude update`, model/effort verification, model alias table |
| Module 1 | Added built-in subagents (Explore) demo (1B); subagent frontmatter updated with 2026 fields; added `/usage`; agents now built directly in `.claude/agents/` — plugin packaging deferred to Module 7 |
| Module 2 | **New module** — plan mode, effort/adaptive thinking, checkpoints & rewind, memory & rules, permission modes (incl. Auto mode), context/cost commands, output styles |
| Module 3 | Was Phase 2. Added `/verify` & `/run` (3C) and hooks (3D); exercises now require running the tests |
| Module 4 | Was Phase 3. Added built-in `/code-review`, `/security-review`, `/simplify` and security-guidance plugin (4D) |
| Module 5 | Was Phase 4. Feature demo now uses plan mode; MCP section updated: current Playwright MCP package, env-var expansion, tool search/deferred loading |
| Module 6 | **New module** — background tasks, agent view, agent teams, workflows, `/goal`, `/loop`, Claude Code on the web |
| Module 7 | Was Phase 5. Plugin assembly consolidated into a single step (7B) at the end — components are built in their native `.claude/` locations first, then packaged once. Skill frontmatter updated (arguments, `context: fork`, substitutions); `claude plugin init/validate`, `--plugin-dir`, `/reload-plugins`, namespaced skill invocation, community marketplace submission |
| Module 8 | Was Phase 6. Updated install flow (`/reload-plugins` instead of restart) |
| Module 9 | **New module** — Claude Managed Agents (concepts, quickstart, pricing), Agent SDK, `ant` CLI, headless mode |
| Appendix A | **New** — model timeline Opus 4.5 → Fable 5 with API capabilities |
| Appendix B | **New** — consolidated command/shortcut/flag/env-var reference |
| **July 2026 revision** | Refreshed against Claude Code 2.1.2xx and July 2026 models: added Claude Fable 5 & Sonnet 5; workflows now triggered with `ultracode` (all paid plans); subagents background-by-default & nestable; `/agents` wizard and `/output-style` removed; auto-memory location corrected; Auto mode on all plans; plugin assembled in a plain directory (not `.claude/plugins/`); official & community marketplaces updated |

---

<a id="pre-workshop-notes"></a>
## Pre-Workshop Notes

Before the workshop, add to `src/paymentservice/charge.js` for bug simulation (used in Module 4A Option B):

```javascript
// Add inside the charge function
if (Math.random() < 0.3) throw new Error("Connection timeout");
```

**Feature availability checklist for instructors:**

| Feature | Requirement |
|---------|-------------|
| Opus 4.8 as default | Max/Team Premium/Enterprise/API account (Pro & Team Standard default to Sonnet 5) |
| Claude Fable 5 | Available via `/model fable` on paid plans; not the default |
| Auto permission mode | All paid plans; Sonnet 4.6/5, Opus 4.7/4.8 (Bedrock/Vertex/Foundry need `CLAUDE_CODE_ENABLE_AUTO_MODE=1`) |
| Agent teams | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` env var (still experimental) |
| Dynamic workflows / `ultracode` | All paid plans (Pro: opt-in via `/config`); Claude Code 2.1.154+ (`/effort ultracode` needs 2.1.203+) |
| Claude Code on the web | Research preview; Pro/Max/Team/Enterprise; GitHub repo access |
| Managed Agents (Module 9) | Console account + API key; public beta; usage-based billing |
| Fast mode | Research preview; Opus 4.8 only ($10/$50) |

> **Versions change quickly.** This document was verified against Claude Code 2.1.206 and the Claude API as of July 2026. Before delivering the workshop, re-check anything marked beta/experimental/research-preview against [code.claude.com/docs](https://code.claude.com/docs) and [platform.claude.com/docs](https://platform.claude.com/docs).
