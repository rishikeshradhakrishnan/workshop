# Module 0 — Welcome, Preflight, and the Claude Developer Platform Map

> **Time box:** 09:00–09:15 (15 min) · **Format:** talk 8 · lab 7 · **Checkpoint in:** — (homework preflight) · **Checkpoint out:** CP0

> [!NOTE] Instructor
> This is the only module with no demo. Resist the urge to "just show one thing" — every minute you overrun here is stolen from the Module 1 lab. The goal is a shared mental model, a green preflight on every laptop, and everyone knowing how checkpoints work. TAs circulate during the talk and fix red preflights silently.

## Why this matters

By 15:40 today every participant will have built the same product — the **Codebase Toolkit** for the OpenTelemetry Astronomy Shop — at nine different altitudes: a prompt, a `CLAUDE.md`, project settings with hooks and an MCP server, subagents, a skill, a plugin served from a marketplace, a headless CI script, an Agent SDK service, a Claude Managed Agent, and finally a security-gated pipeline. Nothing gets built twice; every module consumes the previous module's artifact.

That only works if two things are true at 09:15: everyone can place the four ways of building with Claude on one map (so the afternoon does not feel like a different product), and everyone's machine is verifiably ready (so nobody spends Module 1 reinstalling Node). This module does exactly those two things and nothing else.

## Learning objectives

By the end of this module participants can:

1. Draw the four ways to build with Claude — **Messages API → Claude Agent SDK → Claude Code → Claude Managed Agents** — and say, for each, who runs the agent loop and where the tools execute.
2. Name Claude Code's seven extension points and where each lives on disk: `CLAUDE.md`, `.claude/settings*.json`, `.claude/hooks/` (wired from settings), `.mcp.json`, `.claude/agents/`, `.claude/skills/`, and plugins/marketplaces.
3. Locate the security layers they will meet today: permission rules and modes, hooks, the Bash sandbox, the auto-mode classifier, Managed Agents permission policies / limited networking / vaults, the security-guidance plugin, `/security-review`, the Claude Security plugin, the CI security-review action, and hosted Claude Security.
4. Confirm their environment is green, know the three shell variables used all day (`$WS`, `$OTEL`, `$REV`), and know how `labs/checkpoint.sh` rescues them if they fall behind.

## Concepts (instructor talk track)

### 1. The day in one sentence

"We are going to teach Claude one codebase, then progressively move that knowledge from *your head* into *files*, from files into a *distributable package*, from the package into *automation*, from automation into *your own product*, and finally put a *security gate* in front of all of it."

### 2. The platform map — four ways to build with Claude

Everything Anthropic ships for developers sits on one ladder. Each rung takes something off your plate and, in exchange, makes some decisions for you.

```
                        more control  <───────────────────────────────>  less infrastructure
 ┌──────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌───────────────────────┐
 │  Messages API    │   │  Claude Agent SDK  │   │    Claude Code     │   │ Claude Managed Agents │
 │  (client SDKs)   │──▶│  (Python / TS lib) │──▶│ (CLI, IDE, Desktop,│──▶│  (hosted harness,     │
 │                  │   │                    │   │  web, mobile, CI)  │   │   REST API, beta)     │
 └──────────────────┘   └────────────────────┘   └────────────────────┘   └───────────────────────┘
  you write the loop      Claude Code's loop,      Anthropic's product      Anthropic runs the loop
  you run the tools       tools & context mgmt     for developers; same     AND the sandbox; you send
  you hold the state      as a library in YOUR     engine on every surface  events, receive events
                          process; you host it
```

| | Messages API | Claude Agent SDK | Claude Code | Claude Managed Agents |
|---|---|---|---|---|
| **What it is** | Direct model access (`anthropic` / `@anthropic-ai/sdk`). You implement the tool loop. | "Claude Code as a library": the same agent loop, built-in tools and context management, programmable in Python and TypeScript. Bundles the Claude Code binary and drives it as a subprocess. | Anthropic's agentic coding product. Reads your codebase, edits files, runs commands. Terminal, VS Code/JetBrains, Desktop app, web (`claude.ai/code`), mobile, Slack, GitHub Actions, and headless `claude -p`. | Pre-built, configurable agent harness that runs on Anthropic-managed infrastructure. You define an Agent, an Environment (cloud container), start Sessions, and exchange Events. |
| **Who runs the agent loop** | You | You (your process, your servers/containers) | The Claude Code app — on the developer's machine, or in an Anthropic cloud VM for web sessions | Anthropic |
| **Where tools execute** | Wherever you execute them | Your machine / container (`cwd`) | Your working directory (or the cloud VM) | A managed sandbox per session (or a self-hosted sandbox you run) |
| **Auth & billing** | Console API key; per-token | Console API key or Bedrock / Vertex AI / Foundry credentials; per-token. *Not* claude.ai login for products you ship. | claude.ai subscription seat (Pro/Max/Team/Enterprise) **or** Console API key **or** cloud provider | Console API key; per-token **plus** session runtime while `running` (beta, Aug 2026 — pricing in Ref §L) |
| **Best for** | Custom loops, fine-grained control, non-agentic calls | Embedding a Claude-Code-style agent inside your own app, CLI, or backend | Interactive and headless software engineering by developers | Long-running / asynchronous agents in production without operating sandbox or session infrastructure |
| **You will use it in** | (background knowledge) | **M5** | **M1–M4, M7** | **M6** |

Two sentences to say out loud, because they prevent the most common afternoon confusion:

- **Claude Code on the web** (`claude.ai/code`, `claude --cloud`) is a *subscription* feature for *developers*: Anthropic hosts a VM so *you* can keep coding from a browser or phone. **Claude Managed Agents** is an *API product* for *your product*: metered per session-hour, driven by your code, no human in a chat box. Both talk about "environments" and "sessions"; they are different products.
- The **Agent SDK** and **Managed Agents** run the *same kind* of agent. The difference is operational: "the SDK runs in a process you operate, while Managed Agents runs in Anthropic's infrastructure." M6 ends with the migration mapping between the two.

### 3. Claude Code's extension points (what we build in the morning)

Claude Code is one agent loop surrounded by seven places you can plug things in. Every one of them is *just a file* in a known location, which is why they can be versioned, reviewed, packaged, and shipped.

| # | Extension point | What it does | Lives at (project scope) | User scope | Built in |
|---|---|---|---|---|---|
| 1 | **CLAUDE.md** (+ rules) | Persistent instructions loaded every session; advisory, not enforced | `./CLAUDE.md` or `./.claude/CLAUDE.md`; `./CLAUDE.local.md` (personal, gitignored); `.claude/rules/*.md` (optionally path-scoped) | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | M1 |
| 2 | **Settings & permissions** | allow / ask / deny rules, default permission mode, sandbox, env, model defaults | `.claude/settings.json` (committed), `.claude/settings.local.json` (gitignored) | `~/.claude/settings.json`; org-wide managed settings | M2-A |
| 3 | **Hooks** | Deterministic scripts / prompts / HTTP calls fired on lifecycle events (e.g. block an edit *before* it happens) | `"hooks"` block inside `.claude/settings.json`; scripts conventionally in `.claude/hooks/` | same keys in `~/.claude/settings.json` | M2-B |
| 4 | **MCP servers** | Connect external tools and data (stdio or HTTP) | `.mcp.json` at the repo root (project scope) | `~/.claude.json` (user/local scope) via `claude mcp add` | M2-C |
| 5 | **Subagents** | Isolated workers with their own context window, system prompt, tools, model; run in the background and return a summary | `.claude/agents/*.md` | `~/.claude/agents/` | M3-A |
| 6 | **Skills** | Reusable instructions/workflows; invoked as `/name` or auto-loaded when relevant; can take arguments and carry supporting files | `.claude/skills/<name>/SKILL.md` | `~/.claude/skills/` | M3-B |
| 7 | **Plugins & marketplaces** | Packaging + distribution layer bundling agents, skills, hooks, MCP config (and more); installed as `name@marketplace`, namespaced `/plugin:skill` | `../codebase-toolkit/.claude-plugin/plugin.json`; marketplace `…/.claude-plugin/marketplace.json`; team rollout via `enabledPlugins` in settings | `~/.claude/plugins/` (installed cache) | M3-C |

Layering rules worth stating once: CLAUDE.md files are *additive* (all levels concatenate); skills and subagents *override by name* across scopes; MCP servers override by name (local > project > user); hooks *merge* (all matching hooks fire). Settings precedence is its own topic in M2.

In the afternoon the same seven ideas reappear under different names: the SDK takes `system_prompt`, `allowed_tools`, hook *callbacks*, `mcp_servers`, `agents`, and `plugins` as options (M5); a Managed Agent takes a versioned `system` prompt, toolsets with permission policies, MCP servers, and skills (M6).

### 4. Security is a thread, not only a module

Draw this as concentric rings around the agent loop. Every ring is something participants will *touch* before M7 names it.

```
            ┌───────────────────────────── org & CI ──────────────────────────────┐
            │  managed settings · strictKnownMarketplaces · managed MCP allowlist  │
            │  claude-code-security-review Action (PR gate) · hosted Claude        │
            │  Security (Enterprise, scheduled repo scans)                     M7  │
            │   ┌──────────────────────── on demand ─────────────────────────┐    │
            │   │  /security-review (single pass on branch diff)              │    │
            │   │  Claude Security plugin: multi-agent scan, verified         │    │
            │   │  findings, patches (beta, Aug 2026)                     M7  │    │
            │   │   ┌──────────────── while the agent works ──────────────┐   │    │
            │   │   │  security-guidance plugin (hooks) · auto-mode        │   │    │
            │   │   │  classifier · Bash sandbox (OS-level fs + network)   │   │    │
            │   │   │  PreToolUse hooks (exit 2 blocks) · CMA permission   │   │    │
            │   │   │  policies, limited networking, vaults   M1 M2 M5 M6  │   │    │
            │   │   │   ┌──────────── before anything runs ────────────┐   │   │    │
            │   │   │   │ permission rules deny → ask → allow ·        │   │   │    │
            │   │   │   │ permission mode · --allowedTools/dontAsk ·   │   │   │    │
            │   │   │   │ SDK can_use_tool                 M1 M2 M4 M5 │   │   │    │
            │   │   │   │            ┌──────────────┐                  │   │   │    │
            │   │   │   │            │  agent loop  │                  │   │   │    │
            │   │   │   │            └──────────────┘                  │   │   │    │
            │   │   │   └──────────────────────────────────────────────┘   │   │    │
            │   │   └──────────────────────────────────────────────────────┘   │    │
            │   └──────────────────────────────────────────────────────────────┘    │
            └───────────────────────────────────────────────────────────────────────┘
```

One line to land: *permission rules and the sandbox are enforced by Claude Code and the operating system, not by the model — they hold even if a prompt injection succeeds. `CLAUDE.md` is advice; a deny rule is a wall.*

### 5. The artifact ladder — what you will have built by 15:40

| # | Artifact | Built in | Reused in |
|---|---|---|---|
| 1 | `CLAUDE.md` + `.claude/rules/proto.md` | M1 | inherited by M3 agents/skill; loaded by the SDK via `setting_sources=["project"]` (M5); contrasted with enforced rules (M7) |
| 2 | `.claude/settings.json` (allow/ask/deny, `defaultMode`, sandbox) | M2 | `dontAsk` headless runs rely on the allow list (M4); hardened in M7 |
| 3 | `.claude/hooks/protect-files.sh` + hook config; `bash-audit.log` | M2 | bundled into the plugin (M3); mirrored as an SDK hook callback (M5) |
| 4 | `.mcp.json` + `astro-catalog` stdio MCP server | M2 | bundled into the plugin (M3); MCP trust discussion (M7) |
| 5 | `service-documenter` and `bug-hunter` subagents | M3 | headless `-p @agent-…` (M4); SDK `plugins`/`agents` (M5); bug-hunter prompt becomes the Managed Agent's `system` (M6) |
| 6 | `code-reviewer` skill (arguments, `allowed-tools`, checklist file) | M3 | headless and GitHub Action invocation (M4) |
| 7 | `codebase-toolkit` plugin v4.0.0 + `workshop-marketplace` (+ org marketplace install) | M3 | `-p` and Actions (M4); SDK `plugins=[…]` (M5); plugin trust (M7) |
| 8 | `bug-hunt.sh` + `findings.schema.json`; `.github/workflows/claude.yml` | M4 | schema reused as SDK structured output (M5) and compared to Claude Security JSONL (M7) |
| 9 | `bughunter` Agent SDK CLI (custom tool, hooks, `can_use_tool`, structured output, sessions, cost) | M5 | `create_ticket` handler reused verbatim as a Managed Agents custom tool (M6) |
| 10 | Managed Agent `codebase-toolkit-<user>` + environment + session + `bug-report.md` | M6 | referenced as security controls (M7); cleaned up in M8 |
| 11 | `CLAUDE-SECURITY-<ts>/` report, applied `F1.patch`, `security-patterns.yaml`, `security-review.yml` gate, hardened settings | M7 | M8 adoption playbook |

### 6. Housekeeping: conventions, checkpoints, auth paths, cost

**Three directories, three variables** (set by `labs/.env`, used verbatim in every module):

| Variable | What | Where it comes from |
|---|---|---|
| `$WS` | This workshop repo (`<WORKSHOP_ORG>/claude-builders-workshop`) — labs, scripts, starters, solutions | cloned as homework |
| `$OTEL` | Your clone of `<WORKSHOP_ORG>/opentelemetry-demo` (the Astronomy Shop, default branch `workshop`) — the codebase Claude works on all morning | cloned as homework |
| `$REV` | Your own copy of the `<WORKSHOP_ORG>/astroshop-reviews` template repo (small Flask service, deliberately vulnerable) — used in M4 Path B and M7 | "Use this template" into your GitHub account, then clone |

**Checkpoints are code, not prose.** `labs/checkpoint.sh CPn` (bash; on Windows run it from Git Bash or WSL2) idempotently materialises the end-state of module *n* into your working tree — it copies solution files, never overwrites your work without `--force`, and prints exactly what it changed. The instructor announces the checkpoint ID at every module boundary. Falling behind is normal; staying behind is optional.

**Two auth paths, both fine for the morning.** Claude Code accepts *either* a claude.ai **Pro/Max/Team/Enterprise** seat *or* a **Claude Console** account/API key (roles *Claude Code* or *Developer*). The free claude.ai plan does not include Claude Code. Modules that strictly need a **Console API key** are flagged now so nobody hits a wall at 13:00:

| Needs `ANTHROPIC_API_KEY` | Why | No-key path |
|---|---|---|
| M4 Path B (GitHub Actions) | the Action authenticates with a repo secret | do Path A (headless, uses your Claude Code login) |
| M5 (Agent SDK) | products you ship authenticate with an API key or cloud-provider credentials, not a claude.ai login | pair with a neighbour, or use the instructor's time-boxed workshop-workspace key from `labs/.env.instructor` |
| M6 (Managed Agents) | API product (beta) | same as M5; or watch and read `labs/m6-managed-agents/expected-output/` |
| M7 step 5 (CI gate) | Action secret again | watch the instructor's PR; read `expected-output/pr-comment.png` |

**Cost expectations.** The morning runs on your Claude Code login (subscription usage or Console tokens). M5 + M6 + the M7 CI step together cost roughly low single-digit USD per person on the `sonnet` alias; instructors have set a spend limit on the workshop Console workspace. Recommendation for the labs: leave `/model` on `default` unless the instructor says otherwise for your room.

**Where to ask.** The workshop chat channel (URL on the slide) for questions and pasted errors; raise a hand for anything that blocks you for more than two minutes.

### 7. What `labs/preflight.sh` checks (so you can read its output)

Preflight is the same script you ran as homework; it exits non-zero on any `FAIL` and prints one row per check. Knowing *why* each row exists tells you which failures matter *now* and which only matter after lunch.

| # | Check | PASS means | Needed from |
|---|---|---|---|
| 1 | OS / arch / RAM | supported OS (macOS 13+, Windows 10 1809+/11 or WSL2, Ubuntu 20.04+/Debian 10+); ≥ 8 GB RAM (WARN below) | M0 |
| 2 | Claude Code install + auth | `claude --version` prints; `claude doctor` clean; `claude auth status` OK **or** `ANTHROPIC_API_KEY` set — prints which path; WARN if both are present (precedence!) | M0 |
| 3 | Live inference | `claude -p --max-turns 1 --output-format json "Reply with the single word: pong"` returns `pong`; prints the model used and `total_cost_usd` — proves the venue network/proxy lets you reach the API | M1 |
| 4 | Toolchain | `git` ≥ 2.30, `gh auth status`, `jq`, `node` ≥ 22 (WARN 18–21, FAIL < 18), `npm`, `python3` ≥ 3.10 (WARN 3.9.x, FAIL < 3.9.6), `uv` or `pip` | M2 (jq, node), M4-B (gh), M5 (python/uv) |
| 5 | Lab MCP server | `npm ci --prefix labs/mcp/astro-catalog` succeeded and `node labs/mcp/astro-catalog/server.mjs --selftest` passes | M2-C |
| 6 | SDK environments | `uv sync --project labs/m5-agent-sdk/python` installed `claude-agent-sdk`, `anthropic`, `jsonschema`; (`--ts` flag) `npm ci` for the TypeScript track | M5, M6 |
| 7 | API key + Managed Agents | with a key: a tiny `anthropic` models call succeeds; `client.beta.agents.list(limit=1)` succeeds → `cma=yes` | M5, M6 |
| 8 | Repos | `$OTEL` exists and HEAD matches the pinned SHA (WARN if not); `$REV` exists, `origin` is *your* namespace, `uv run pytest -q` passes | M1 (`$OTEL`), M4-B/M7 (`$REV`) |
| 9 | Plugins | `claude-plugins-official` marketplace present; `claude-security` installed at user scope; `security-guidance` installed **and disabled** (until M7 step 4) | M7 |
| 10 | Manual reminder | prints: "open `claude`, run `/config`, confirm **Dynamic workflows** is on" (not scriptable) | M4 tour, M7 |

The summary line is what you paste into the chat if asked: `PREFLIGHT v4 | <OS> | claude <version> | auth=subscription|apikey | node <v> | python <v> | cma=yes/no | READY|NOT READY`.

### 8. Sixty-second glossary

These words are used precisely all day; align on them now.

| Term | Meaning today |
|---|---|
| **Agent loop** | The cycle *model proposes a tool call → client executes it → result goes back to the model*, repeated until the model answers without a tool call. Claude Code, the Agent SDK and Managed Agents are three hosts for the same loop. |
| **Tool** | A capability the model can call: built-ins (`Read`, `Edit`, `Write`, `Bash`, `Glob`, `Grep`, `WebFetch`, `Agent`…), MCP tools (`mcp__server__tool`), SDK custom tools, Managed Agents toolsets/custom tools. Permission rules are written *per tool*. |
| **Context window** | Everything the model sees on a turn: system prompt, memory files, conversation, tool results. Finite; `/context` shows it; compaction summarises it. |
| **Permission mode** | The session-wide policy for what runs without asking (manual, acceptEdits, plan, auto, dontAsk, bypass). Distinct from permission *rules* (allow/ask/deny per tool pattern). |
| **Checkpoint** | (1) Claude Code's automatic per-prompt snapshot used by `/rewind` (M1). (2) *Workshop* checkpoint `CPn` = the scripted end-state of module *n*. Context makes it obvious which is meant. |
| **Alias** | A moving model name (`opus`, `sonnet`, `haiku`, `opusplan`) that resolves to the current generation for your provider. We use aliases everywhere so the material survives model launches. |
| **Subagent** | A helper agent with its own context window and tool scope that returns a summary to the main session (M3). Not a separate product. |
| **Skill / plugin / marketplace** | Skill = a folder with `SKILL.md` (instructions + optional files) invocable as `/name`. Plugin = a package of skills/agents/hooks/MCP config. Marketplace = a catalogue (`marketplace.json`) plugins install from. |
| **Headless** | `claude -p`: one prompt in, result out, no TUI — the CI/scripting form of Claude Code (M4). |
| **Seat vs key** | *Seat* = a claude.ai subscription login (Pro/Max/Team/Enterprise). *Key* = a Claude Console API key (usage-billed). Both run Claude Code; only a key runs the SDK/Managed Agents labs. |

## Live demo script

There is no product demo in M0. The instructor's screen shows slides for 6 minutes and a terminal for 2. Budget:

| Min | Screen | Say / do |
|---|---|---|
| 0:00–1:00 | Slide 1 — agenda + artifact ladder (§5 table) | "Here is 15:40. Eleven artifacts, one product. Every module hands its output to the next." Point at rows 5→9→10: "the bug-hunter you write at 11:00 becomes a library call at 13:00 and a hosted agent at 14:00." |
| 1:00–4:00 | Slide 2 — platform map (§2 diagram + table) | Walk left to right. For each column ask the room "who runs the loop? where do tools execute?" and answer. Say the two disambiguation sentences (web ≠ Managed Agents; SDK vs Managed Agents is *where it runs*). |
| 4:00–6:00 | Slide 3 — extension points table (§3) overlaid on the security rings (§4) | "Seven files. You will create every one of them before lunch. The rings are the security story; notice you meet the inner rings in M1 and M2, long before the security module." Land the "advice vs wall" line. |
| 6:00–8:00 | Terminal, font size up | Type exactly: |

```bash
cd $WS && ./labs/preflight.sh            # show an all-green table and the summary line
./labs/checkpoint.sh --list              # show CP0…CP7 with one-line descriptions
./labs/checkpoint.sh CP0                 # prints: working tree matches CP0
```

Expected on screen: the preflight table with every row `PASS` (a `WARN` on RAM or Node 18–21 is acceptable), ending in a line shaped like

```text
PREFLIGHT v4 | macOS 14 arm64 | claude <version> | auth=subscription | node 22.x | python 3.12 | cma=yes | READY
```

Then say: "Your turn — seven minutes. If your summary line does not say READY, hand up now; a TA will come to you while I start Module 1."

## Hands-on lab

**Lab 0: Green lights** (7 min). Start state: you did the homework in `README.md` → *Participants: before the day* (repos cloned, Claude Code installed and logged in once, preflight run at least once). End state: CP0.

1. **(2 min) Re-run preflight.**

   ```bash
   cd $WS            # if $WS is not set yet, cd into your clone of claude-builders-workshop
   git pull --ff-only
   ./labs/preflight.sh          # Windows: run from Git Bash or WSL2 (the lab scripts are bash)
   ```

   ✅ Success: the last line ends in `READY`. `WARN` rows are fine; any `FAIL` row → raise your hand now and keep going with the next steps while a TA comes over.

2. **(2 min) Confirm login method and default model.**

   ```bash
   cd $OTEL && claude
   ```

   Inside the session type:

   ```text
   /status
   ```

   Read the **Login method** row (claude.ai subscription) or **API key** row (Console key) and the **Model** row. Then:

   ```text
   /model
   ```

   Leave the selection on **Default** and press `Esc` to close the picker without changing anything. Note which concrete model "Default" resolves to for your plan (you will compare with neighbours in M1). Exit with `/exit` (or `Ctrl+D` twice).

   ✅ Success: you saw a login method and a model name; no error banner.

3. **(2 min) Fill in your lab environment file.**

   ```bash
   cd $WS
   cp -n labs/env.example labs/.env      # -n: don't clobber if you already did this at home
   ${EDITOR:-nano} labs/.env
   ```

   The file has this shape — fill the first three (and `CMA_MODEL` before Module 6), leave the rest unless told otherwise:

   ```bash
   # labs/.env — sourced by every lab script. Never commit this file (it is gitignored).
   export WORKSHOP_ORG="<WORKSHOP_ORG>"          # GitHub org announced by the instructor
   export GITHUB_USER="<your-github-username>"
   export ANTHROPIC_API_KEY=""                    # Console key if you have one; leave empty if using a claude.ai seat only
   export MODEL="sonnet"                          # alias used by `claude -p` scripts (M4) and the Agent SDK lab (M5)
   export CMA_MODEL="<full-model-id>"             # Managed Agents (M6) needs a full model ID, not an alias — see reference §B
   export WS="$HOME/src/claude-builders-workshop" # adjust the three paths to where you cloned
   export OTEL="$HOME/src/opentelemetry-demo"
   export REV="$HOME/src/astroshop-reviews"
   ```

   Then load it (add this line to your shell profile if you want it in every new terminal today):

   ```bash
   source labs/.env && echo "WS=$WS OTEL=$OTEL REV=$REV ORG=$WORKSHOP_ORG"
   ```

   ✅ Success: the echo prints three real paths and the org name; `ls $OTEL/src | head` lists Astronomy Shop services.

   > If you use a claude.ai seat **and** also have an API key, keep `ANTHROPIC_API_KEY` in `labs/.env` but be aware that an exported `ANTHROPIC_API_KEY` takes precedence over your subscription login inside `claude` (interactive mode asks once whether to use it; `claude -p` always uses it). The M5/M6 scripts read it from this file; if you want the morning to run on your subscription, answer **No** when `claude` asks, or `unset ANTHROPIC_API_KEY` in the terminal you use for interactive work.

4. **(1 min) Meet the checkpoint tool.**

   ```bash
   ./labs/checkpoint.sh --list
   ./labs/checkpoint.sh CP0
   ```

   ✅ Success: `--list` prints `CP0` … `CP7` with a one-line description each; `CP0` prints `working tree matches CP0` and changes nothing.

You are done when: preflight says `READY`, `labs/.env` is sourced, and `checkpoint.sh CP0` is happy. Post your preflight summary line in the chat channel so the TAs can see the room's status at a glance.

## If you're behind (fast-forward)

```bash
cd $WS && ./labs/checkpoint.sh CP0
```

CP0 restores nothing — it is a no-op sanity check that verifies your three repos exist at the paths in `labs/.env`, that `labs/.env` itself is present, and that `$OTEL` is a clean checkout, then prints `working tree matches CP0`. If CP0 itself complains, the problem is an install or a missing clone, not lab work:

- **Raise your hand now.** A TA fixes installs during the Module 1 talk track (15 minutes of cover).
- **Worst case:** pair with a neighbour for M1–M3 (no API key needed for those), and pick up the instructor's workshop-workspace key at M4. You lose nothing permanent — every later checkpoint rebuilds the full state.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `claude` tries to open a browser and nothing happens (locked-down laptop, SSH, WSL) | No default browser reachable from the shell | Press `c` at the login prompt to copy the URL, open it on any device, then paste the code back at `Paste code here if prompted`. `claude auth login` also accepts the pasted code on stdin. Or use the Console API-key path: `export ANTHROPIC_API_KEY=…` and restart `claude`. |
| `API Error: 400 … "This organization has been disabled"` although your subscription is active | A stale `ANTHROPIC_API_KEY` in your environment is overriding the subscription login | `unset ANTHROPIC_API_KEY` (and remove it from your shell profile), then `claude` again; `/status` should show *Login method: Claude … subscription*. |
| 403 right after a successful login | Subscription inactive, or Console user lacks the *Claude Code* / *Developer* role | Check plan at claude.ai → Settings; Console admins assign the role under Settings → Members. |
| Preflight: `claude -p … pong` step fails with TLS / certificate errors on the venue or corporate network | TLS-inspecting proxy whose root CA is not trusted, or proxy not configured | `export HTTPS_PROXY=http://proxy.corp.example:8080` and `export NODE_EXTRA_CA_CERTS=/path/to/corp-root-ca.pem` (Claude Code also reads the OS trust store by default). Put both under `"env"` in `~/.claude/settings.json` so subprocesses inherit them. Verify with `/status` (Proxy / Additional CA cert rows). Details: Ref §J. |
| Preflight: `node` FAIL (< 18) or WARN (18–21) | Old Node; Claude Code itself does not need Node, but the lab MCP server and the TypeScript SDK track do | Install current LTS (22.x as of August 2026) via your version manager (`nvm install --lts`, `fnm`, `volta`) and re-run preflight. |
| Preflight: `python3` FAIL (< 3.9.6) or WARN (3.9.x) | macOS system Python or old distro Python | `brew install python` / `pyenv install 3.12` / distro package; ensure `python3 --version` ≥ 3.10 (Agent SDK minimum), then `uv sync --project labs/m5-agent-sdk/python`. |
| Preflight: `cma=no` | Your Console org/key does not have Managed Agents (beta) enabled, or no API key set | Not blocking until M6. Tell a TA; you will pair or use the workshop-workspace key for M6. |
| Windows: `claude` works but says it is using the PowerShell tool, hooks lab worries you | Git for Windows (Git Bash) not installed — expected and supported | Nothing to fix for Claude Code itself — it uses the PowerShell tool natively, and the M2 hook ships a `.ps1` example (`labs/m2/hooks/protect-files.ps1`). The lab *scripts* (`preflight.sh`, `checkpoint.sh`, `cleanup.sh`) are bash-only: run them from Git Bash or WSL2 (see `labs/SETUP.md`). If you want Bash inside Claude Code too: install Git for Windows and set `CLAUDE_CODE_GIT_BASH_PATH` if it is not auto-detected. |
| `checkpoint.sh: OTEL not found at …` | `labs/.env` paths don't match where you cloned | Edit the three path lines in `labs/.env`, `source labs/.env`, re-run. |
| `ls $OTEL/src` shows names that differ from the ones in the lab text (e.g. `payment` vs `paymentservice`) | Your fork is not on the pinned `workshop` branch/tag | `cd $OTEL && git fetch && git switch workshop`; preflight step 8 warns when HEAD is off the pinned SHA. |
| Two Claude Code installs (`which -a claude` shows npm and native) | Old npm global install left behind | Keep the native one: `npm uninstall -g @anthropic-ai/claude-code`; `claude doctor` confirms a single healthy install. |

## Stretch goals

- Run `claude doctor` from your shell and read what it checks (install health, settings validation, last update result) — it never starts a session. Compare with the in-session `/doctor` skill later today, which can also *fix* things.
- Skim Ref §A (platform map; glossary in §N.1) and try to place three things you already use (an IDE extension? a CI bot? a chat app?) on the four-column map.
- `claude --version`, then `claude update` — note whether you are on the `latest` or `stable` release channel (`/config` → Auto-update channel). Do **not** change channels today.
- Open `labs/checkpoint.sh` in your editor and read how CP1 is defined in `labs/checkpoints/CP1/` — it is a manifest of paths, nothing magic.

## Key takeaways

- One ladder: **Messages API → Agent SDK → Claude Code → Managed Agents.** Moving right trades control for infrastructure you no longer operate. Ask "who runs the loop, where do tools execute, how is it billed" and you can place any product announcement on it.
- Claude Code on the web is a *developer subscription surface*; Claude Managed Agents is an *API product for your software*. Same words, different products.
- Claude Code has seven file-based extension points. Because they are files, they can be reviewed, versioned, packaged as a plugin, and reused by the SDK and (in spirit) by Managed Agents.
- Security controls come in rings; the inner rings (rules, modes, hooks, sandbox) are enforced by the client and the OS, not by the model.
- `labs/checkpoint.sh CPn` is your parachute. Use it without shame.

## References

- Claude Code overview and surfaces: https://code.claude.com/docs/en/overview · https://code.claude.com/docs/en/platforms
- Extend Claude Code (features overview, layering rules): https://code.claude.com/docs/en/features-overview
- The `.claude` directory explained: https://code.claude.com/docs/en/claude-directory
- Setup, install, `claude doctor`: https://code.claude.com/docs/en/setup · https://code.claude.com/docs/en/troubleshoot-install
- Authentication and credential precedence: https://code.claude.com/docs/en/authentication
- Network configuration (proxies, custom CAs): https://code.claude.com/docs/en/network-config
- Security model: https://code.claude.com/docs/en/security
- Claude Agent SDK overview: https://code.claude.com/docs/en/agent-sdk/overview
- Claude Managed Agents overview and migration guide: https://platform.claude.com/docs/en/managed-agents/overview · https://platform.claude.com/docs/en/managed-agents/migration
- Claude Security plugin and how it fits with other security tools: https://code.claude.com/docs/en/claude-security
- Models overview (check what `default` resolves to today): https://platform.claude.com/docs/en/about-claude/models/overview
- OpenTelemetry demo (upstream of the workshop fork): https://github.com/open-telemetry/opentelemetry-demo
