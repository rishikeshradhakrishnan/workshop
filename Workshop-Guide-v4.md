# Building with Claude Code, the Agent SDK, Managed Agents & Claude Security — 6-Hour Workshop (v4, August 2026)

**Format:** instructor-led, hands-on · **Session time:** 6h00 (340 min of modules + two 10-min breaks; lunch is outside session time) · **Wall clock:** 09:00–15:40
**Status:** v4.0 — verified against the public Claude Code, Claude Agent SDK and Claude Platform documentation as of **August 2026**. See [Version and history](#version-history-and-license).

This file is the **spine** of the workshop: who it is for, what gets built, the clocked agenda, how the
repository is meant to be used, and the conventions every module follows. The teaching content itself is
in [`modules/`](modules/), the look-up material in
[`reference/Technical-Reference-v4.md`](reference/Technical-Reference-v4.md), the participant setup in
[`labs/SETUP.md`](labs/SETUP.md), and the instructor runbook in [`FACILITATOR.md`](FACILITATOR.md).

---

## Contents

1. [Who this is for](#1-who-this-is-for)
2. [What you will build](#2-what-you-will-build)
3. [Agenda](#agenda)
4. [How to use this repository](#4-how-to-use-this-repository)
5. [Prerequisites at a glance](#5-prerequisites-at-a-glance)
6. [Module index](#6-module-index)
7. [The checkpoint system](#7-the-checkpoint-system)
8. [Delivery variants](#8-delivery-variants)
9. [Conventions used in the modules](#9-conventions-used-in-the-modules)
10. [Design principles (short)](#10-design-principles-short)
11. [Version, history and license](#version-history-and-license)

---

## 1. Who this is for

Developers, solutions engineers, platform/DevEx engineers and technical customers who **can use a
terminal and git** and want to go from "I have used Claude Code a bit" to "I can extend it, automate it,
embed the same agent in my own service, run it hosted, and put security controls around all of that".

- **Assumed:** comfortable in a shell; can read Python *or* TypeScript; has a GitHub account.
- **Helpful, not required:** prior Claude Code use. Module 1 levels the room.
- **Not assumed:** running Docker/Kubernetes, knowing the Anthropic API, any specific language of the target repo (it is polyglot on purpose).
- **Two personas, one day:** the morning (M0–M4) is *Claude Code as a tool you extend*; the afternoon (M5–M7) is *Claude as a platform you build on and secure*. Each half also runs as a standalone half-day (see [§8](#8-delivery-variants)).

## 2. What you will build

One running project climbs one rung per module — nothing is built twice, and every module consumes the
previous module's artifact. The target codebase is the OpenTelemetry **"Astronomy Shop"** demo (forked
and pinned under the workshop GitHub org); the thing you build is the **Codebase Toolkit**: conventions,
guardrails, subagents and a skill, packaged as a plugin, then driven headlessly, embedded through the
Agent SDK, hosted as a Managed Agent, and finally wrapped in security tooling.

```
                                                            M7  security-gated pipeline
                                                        ┌── Claude Security scan + verified patch,
                                                        │   security-guidance rules, PR gate, hardened settings
                                                   M6  Managed Agent  "codebase-toolkit-<you>"
                                               ┌── environment + agent + session, tool confirmations,
                                               │   custom tool round-trip, bug-report.md
                                          M5  Agent SDK service  "bughunter"
                                      ┌── query(), plugin reuse, @tool create_ticket, hooks,
                                      │   can_use_tool, structured findings, sessions, cost
                                 M4  headless & CI
                             ┌── claude -p --json-schema -> findings.json; @claude GitHub Action
                        M3  plugin + marketplace  "codebase-toolkit@workshop-marketplace" v4.0.0
                    ┌── service-documenter + bug-hunter subagents, code-reviewer skill,
                    │   hooks + MCP bundled, validated, installed (local and org marketplace)
               M2  guardrails & tools
           ┌── .claude/settings.json (allow/ask/deny, mode, sandbox), protect-files hook, astro-catalog MCP
      M1  memory & workflow
  ┌── CLAUDE.md + path-scoped rule, plan -> approve -> rewind
M0  platform map + green preflight
```

**Artifact ladder — built once, reused all day**

| # | Artifact | Built in | Reused in |
|---|---|---|---|
| 1 | `CLAUDE.md` + `.claude/rules/proto.md` | M1 | inherited by M3 agents/skill; loaded by the SDK via `setting_sources=["project"]` (M5); optional read-only memory store (M6 stretch); "advisory vs enforced" contrast (M7) |
| 2 | `.claude/settings.json` (allow/ask/deny, default mode, sandbox) | M2 | `dontAsk` headless runs rely on the allow list (M4); hardened in M7 |
| 3 | `protect-files.sh` hook + `bash-audit.log` | M2 | bundled into the plugin's `hooks/hooks.json` (M3); mirrored as an SDK hook callback (M5); pattern reused for security hooks (M7 stretch) |
| 4 | `.mcp.json` + `astro-catalog` stdio server | M2 | bundled in the plugin (M3); external MCP from the SDK (M5 stretch); MCP toolset + vault (M6 stretch); MCP trust discussion (M7) |
| 5 | `service-documenter` and `bug-hunter` subagents | M3 | `claude -p "@agent-…"` (M4); `plugins`/`agents` options (M5); bug-hunter prompt becomes the Managed Agent's system prompt (M6); compared with Claude Security's researcher agents (M7) |
| 6 | `code-reviewer` skill (arguments, `allowed-tools`, checklist file) | M3 | headless skill invocation and Action `prompt:` (M4); least-privilege pattern echoed in M7 |
| 7 | `codebase-toolkit` plugin v4.0.0 + `workshop-marketplace` (+ org marketplace install) | M3 | `-p` and Actions `plugins:` (M4); SDK `plugins=[{"type":"local",…}]` (M5); "same components, hosted" (M6); plugin trust and `strictKnownMarketplaces` (M7) |
| 8 | `bug-hunt.sh` + `findings.schema.json`; `.github/workflows/claude.yml`, `code-review.yml` | M4 | schema reused as SDK structured output (M5) and compared to Claude Security JSONL (M7); Actions repo reused for the security gate (M7) |
| 9 | `bughunter` SDK CLI (`create_ticket` tool, hooks, `can_use_tool`, structured output, sessions, cost) | M5 | `create_ticket` handler and findings schema reused verbatim as the Managed Agent's custom tool (M6); findings compared with plugin output (M7 stretch) |
| 10 | Managed Agent + environment + session transcript + `bug-report.md` (+ optional deployment/webhook) | M6 | permission policy, limited networking, vaults, read-only memory cited as controls (M7); cleaned up in M8 |
| 11 | `CLAUDE-SECURITY-<ts>/` report, applied `F1.patch` branch, `security-patterns.yaml`, `claude-security-guidance.md`, `security-review.yml`, hardened settings | M7 | M8 adoption playbook |

<a id="agenda"></a>
## 3. Agenda

**Time model (stated once, used everywhere):** 6h00 of session time = **340 min of modules + two 10-min
breaks**. Lunch (40 min) is not session time. Wall clock **09:00 → 15:40** (6h40 on site).

Arithmetic: 15 + 40 + 45 + 55 + 30 + 55 + 45 + 40 + 15 = **340** module minutes; + 10 + 10 breaks = **360 = 6h00**; + 40 lunch = 400 min = 09:00 → 15:40.

| Time | Module | Title | Format (min) | Dur | You leave with… | Checkpoint |
|---|---|---|---|---|---|---|
| 09:00–09:15 | **M0** | Welcome, preflight, the Claude developer platform map | talk 8 · lab 7 | 15 | green preflight; `labs/.env`; the four-ways-to-build map and the seven extension points in your head | CP0 |
| 09:15–09:55 | **M1** | Claude Code essentials | talk/demo 15 · lab 20 · debrief 5 | 40 | `CLAUDE.md`, `.claude/rules/proto.md`, a planned-approved-then-rewound feature; model/effort/permission-mode fluency | CP1 |
| 09:55–10:40 | **M2** | Extending Claude Code I: settings & permissions, hooks, MCP | talk/demo 12 · lab 28 · debrief 5 | 45 | `.claude/settings.json` (allow/ask/deny, default mode, optional sandbox), a blocking `PreToolUse` + audit `PostToolUse` hook, `.mcp.json` with a running stdio server | CP2 |
| 10:40–10:50 | — | **Break 1** | | 10 | | |
| 10:50–11:45 | **M3** | Extending Claude Code II: subagents, skills, plugins & marketplaces | talk/demo 15 · lab 37 · debrief 3 | 55 | two subagents run in parallel, an argument-taking skill, the `codebase-toolkit` plugin validated and installed from a local *and* the org marketplace | CP3 |
| 11:45–12:15 | **M4** | Automation & scale: headless, GitHub Actions, cloud/background sessions, orchestration | talk/demo 15 · lab 12 · debrief 3 | 30 | `findings.json` from `claude -p --json-schema` with locked-down permissions (Path A) or a working `@claude` PR workflow (Path B); a "when to use what" map for background/cloud/workflows | CP4 |
| 12:15–12:55 | — | **Lunch** (not session time) | | 40 | | |
| 12:55–13:50 | **M5** | Claude Agent SDK deep-dive | talk 12 · lab 38 · debrief 5 | 55 | `bughunter`, a CLI agent that reuses the plugin, adds a custom in-process tool, a hook and `can_use_tool`, returns schema-validated findings, prints cost, resumes a session | CP5 |
| 13:50–14:35 | **M6** | Claude Managed Agents | talk/demo 12 · lab 28 · debrief 5 | 45 | environment + agent + session created via SDK, streamed events, an answered tool confirmation and custom-tool call, `bug-report.md` downloaded, the session found in Console tracing | CP6 |
| 14:35–14:45 | — | **Break 2** — *M7 step 0: start your Claude Security scan before you stand up* | | 10 | scan running in `$REV` | |
| 14:45–15:25 | **M7** | Securing agentic development with Claude Security | talk 10 · lab 27 · debrief 3 | 40 | triaged scan results (MD/JSONL/SARIF), a verified patch applied on a branch, custom security-guidance rules, a security-review PR gate, hardened project settings; the threat model mapped to controls you built all day | CP7 |
| 15:25–15:40 | **M8** | Wrap-up: the whole picture, adoption playbook, resources, Q&A | talk 10 · Q&A 5 | 15 | your artifacts placed on the platform map; a 30/60/90-day adoption checklist; cleanup done | — |

Debrief minutes are the shock absorbers. If a module overruns, the cut list in
[FACILITATOR.md §6](FACILITATOR.md#6-timing-risk-and-cut-list) says what to drop, in order.

## 4. How to use this repository

**If you are a participant**
1. A week before: [`labs/SETUP.md`](labs/SETUP.md) → run `./labs/preflight.sh` until `READY`.
2. On the day: keep the current module file from [`modules/`](modules/) open next to your terminal; type only what is in its **Hands-on lab** section; use the **Success check** lines to know you are done; use `./labs/checkpoint.sh CPn` the moment you fall behind.
3. When you want to know *why* or *what else exists*: follow the "Ref §X" links into [`reference/Technical-Reference-v4.md`](reference/Technical-Reference-v4.md). You are not expected to read the reference during the day.
4. Afterwards: the modules double as a self-paced course ([§8](#8-delivery-variants)); [modules/08-wrap-up.md](modules/08-wrap-up.md) has the adoption checklist and links.

**If you are an instructor or TA**
1. Read this file, then [`FACILITATOR.md`](FACILITATOR.md) end to end (prep checklists at T-14/T-7/T-1, run sheet, cut list, room-wide failure playbook, decisions you must make before delivery).
2. Read every module's `> [!NOTE] Instructor` callouts and the **Instructor demo** script; rehearse the demos on the pinned repo and record real durations.
3. Verify [`labs/checkpoints/`](labs/checkpoints/README.md) content is `ready` for CP1–CP7 (`./labs/checkpoint.sh --list`) and re-verify the volatile facts ([§9](#9-conventions-used-in-the-modules), reference §O) within a week of delivery.
4. Slides are optional and not shipped in this repository; if you make them, keep speaker-note bullets in a `slides/` folder per module — the module files remain the source of truth.

**Reading paths by time available**

| You have… | Read |
|---|---|
| 5 minutes | [README.md](README.md) and the agenda table above |
| 30 minutes (participant) | this file + [labs/SETUP.md](labs/SETUP.md) |
| 2 hours (instructor, first time) | this file → FACILITATOR.md → modules 00–08 skim → reference §O |
| Self-paced learner | modules in order; skip "Instructor demo" blocks or treat them as worked examples |

## 5. Prerequisites at a glance

Full detail, install commands and proxy/cloud-provider notes: **[labs/SETUP.md](labs/SETUP.md)**. Summary:

- **Claude Code access** through *either* a claude.ai Pro/Max/Team/Enterprise seat *or* a Claude Console account (API billing). Free claude.ai does not include Claude Code.
- **Claude Code**, current release, native installer; logged in once. We never pin a patch version; preflight reports yours.
- **git**, **Node.js current LTS**, **Python 3.10+** with **uv**, **jq**; optional `gh`, Docker.
- **GitHub personal account**; three clones: this repo (`$WS`), the org's `opentelemetry-demo` fork (`$OTEL`), and **your own** copy of the `astroshop-reviews` template (`$REV`).
- **A Console API key** — see the matrix below — with a small spend cap.

**Which modules strictly need a Console API key** (everything else runs on any Claude Code login):

| Needs `ANTHROPIC_API_KEY` | No-key path provided |
|---|---|
| **M4 Path B** (GitHub Actions) | do Path A; watch the instructor's PR |
| **M5** (Agent SDK) | pair; instructor workshop-workspace key (time-boxed, revoked end of day); or read `expected-output/` transcripts |
| **M6** (Managed Agents; org must have the beta enabled) | same as M5; Console tour is projected |
| **M7 step 5** (CI gate) | watch the instructor's PR; screenshot in `expected-output/` |

Cost expectation for a participant with their own key: low single-digit USD for M5+M6+M7 on the `sonnet` alias. Instructors set a workspace spend limit regardless.

## 6. Module index

Each module file has the same skeleton: **Learning objectives · Timing bar · Prerequisite state (checkpoint) · Instructor demo · Hands-on lab (numbered, minute budgets, success checks) · If you're behind · Common failures · Stretch · Reference pointers · Instructor notes.**

| # | Module | Abstract |
|---|---|---|
| M0 | [Welcome, preflight, the Claude developer platform map](modules/00-welcome-and-platform-map.md) | Places the four ways to build with Claude (Messages API → Agent SDK → Claude Code → Managed Agents) on one map, names Claude Code's seven extension points and where each lives on disk, previews the security layers you will meet, and gets every laptop to a green preflight and CP0. 15 min. |
| M1 | [Claude Code essentials](modules/01-claude-code-essentials.md) | A first agentic session done properly: `@file` mentions and `!` shell, model and effort chosen deliberately, `/context` `/usage`, project memory with `CLAUDE.md` and a path-scoped rule, plan mode end-to-end and undo with checkpoints/rewind, the six permission modes and which one you start in, and where the IDE/Desktop/Web surfaces fit. 40 min. |
| M2 | [Extending Claude Code I: settings & permissions, hooks, MCP](modules/02-settings-hooks-and-mcp.md) | Settings scopes and precedence; permission-rule grammar with allow/ask/deny and a default mode; the Bash sandbox and what it does not isolate; hooks as deterministic guardrails (config schema, stdin contract, exit-2 blocks, JSON decisions, other handler types); adding a stdio MCP server at project scope, calling its tools, and the trust rule for servers. Three-part lab. 45 min. |
| M3 | [Extending Claude Code II: subagents, skills, plugins & marketplaces](modules/03-subagents-skills-and-plugins.md) | Author two subagents and run them in parallel; write an argument-taking skill with `allowed-tools` and a supporting checklist; package agents + skill + hooks + MCP as the `codebase-toolkit` plugin, validate it, serve it from a local marketplace, install the org-published copy, and see how teams roll plugins out through settings. Sets up the afternoon: the same components travel to the SDK and to Managed Agents. 55 min. |
| M4 | [Automation & scale](modules/04-automation-and-scale.md) | Claude Code without a human at the keyboard: `claude -p` with JSON/stream-JSON output, `--json-schema`, locked-down permissions and budgets, session resume, the headless trust caveat; `claude-code-action` for `@claude` mentions and PR review; a guided tour of background sessions, dynamic workflows, cross-session messaging, Claude Code on the web and Routines with a "when to use what" table. Two lab paths. 30 min. |
| M5 | [Claude Agent SDK deep-dive](modules/05-claude-agent-sdk.md) | The Claude Code agent loop as a Python/TypeScript library in *your* process: `query()` vs client, options that mirror the morning's CLI concepts, loading the plugin by path, custom in-process MCP tools, hook callbacks and `can_use_tool` as policy in code, schema-validated structured output, cost/usage, sessions and resume, and how you would host it. Six-step build of `bughunter`. 55 min. |
| M6 | [Claude Managed Agents](modules/06-claude-managed-agents.md) | The hosted alternative: Agents, Environments, Sessions and Events; toolsets and permission policies; custom tools; files, vaults, memory, webhooks, schedules and budgets (beta, Aug 2026). Create environment → agent → session with the SDK, stream events, answer a `requires_action` confirmation and a custom-tool call, fetch the deliverable, read usage and find the session in Console tracing; decide Managed Agents vs Agent SDK vs Claude Code on the web. 45 min. |
| M7 | [Securing agentic development with Claude Security](modules/07-securing-agentic-development.md) | The coding-agent threat model (prompt injection, over-broad permissions, secrets, supply chain, headless trust gaps, memory poisoning, insecure generated code) mapped to controls you already built in M1–M6; then the tooling layers: security-guidance while coding, `/security-review` on a diff, the Claude Security plugin's deep scan with verified findings and patches, a security-review GitHub Action as a PR gate, and where hosted Claude Security (Enterprise) fits. Scan starts before Break 2. 40 min. |
| M8 | [Wrap-up](modules/08-wrap-up.md) | Your artifacts redrawn on the M0 platform map; an individual → team → CI → product → org adoption playbook with a 30/60/90-day checklist; where to stay current; cloud-resource cleanup; feedback and Q&A. 15 min. |
| Ref | [Technical Reference v4](reference/Technical-Reference-v4.md) | Appendices §A–§O: platform map & glossary; models/aliases/effort (as of Aug 2026); slash commands, shortcuts, CLI flags, env vars; settings & permission grammar & sandbox & managed settings; hooks reference; MCP; subagents; skills, plugins & marketplaces; headless/CI/GitHub/cloud & orchestration matrices; troubleshooting by module; Agent SDK; Managed Agents; security; resources; **§O volatile facts to re-verify before each delivery**. |

## 7. The checkpoint system

Nobody gets left behind: **checkpoints are code, not prose.**

- Every module ends at a named state **CP0 … CP7**. The instructor announces the checkpoint ID at each module boundary ("we are now at CP3").
- `./labs/checkpoint.sh CPn` materialises that state into your working tree: it applies CP1 → CPn **cumulatively**, copies only what is missing, **never overwrites your own edits** unless you pass `--force` (and then backs the originals up), can `--dry-run`, and runs an optional idempotent post-step (dependency install, plugin install, patch apply). `--list` shows all checkpoints and whether their content is present in your checkout.
- Checkpoint content lives in [`labs/checkpoints/CPn/`](labs/checkpoints/README.md) and is owned by the module that produces it; the directory contract and the per-checkpoint file manifest are in that README.
- **CP3 is everyone's safety net for the afternoon** — it installs the reference `codebase-toolkit` plugin from the org marketplace at user scope, so M4/M5 work even if your own plugin is half-finished.
- Modules that need an API key state their no-key path in the same "If you're behind" box.
- Optional mirror for git-native people: tags `cp1`…`cp4` on the fork's `solutions` branch.

```bash
./labs/checkpoint.sh --list
./labs/checkpoint.sh CP3            # catch up to the end of M3
./labs/checkpoint.sh CP7 --force    # M7 replaces M2's settings.json with the hardened one — force is expected here
```

## 8. Delivery variants

The canonical day is the agenda in [§3](#agenda). These variants are pre-cut so instructors do not improvise under time pressure; minute-level cut lists are in [FACILITATOR.md §6 and §10](FACILITATOR.md#10-compressed-and-alternative-agendas).

| Variant | Modules | Session time | Notes |
|---|---|---|---|
| **Full day (canonical)** | M0–M8 | 6h00 + 40 min lunch (09:00–15:40) | as above |
| **Full day, hard stop 15:30** | M0–M8 | 6h00 + 30 min lunch | shortest lunch that survives a real venue; or keep 40 min lunch and turn the M4 lab into a demo (−10) |
| **Compressed (5h of modules)** | M0–M8, trimmed | 300 module min + breaks | M4 lab → demo (−12), M1 lab shortened (−10), M7 CI-gate step → demo (−5), M6 step 6 dropped (−2), debriefs trimmed (−11) |
| **Half-day "Claude Code"** | M0, M1, M2, break, M3, M4, M7 steps 0–3, 5-min wrap | ≈ 3h50 | no API key needed by anyone; security via plugin scan + patch only; ends with the plugin installed and a scan triaged |
| **Half-day "Platform"** | M0, M3 step 13 only (install the org plugin), M5, break, M6, M7, M8 | ≈ 3h25 | everyone needs a Console key (or pairs); assumes Claude Code familiarity; start with CP3 |
| **Two half-days** | Day 1: M0–M4 + 10-min close (≈ 3h25 incl. break) · Day 2: 10-min recap at CP4 → M5, M6, break, M7, M8 (≈ 2h55) | 2 × ~3h | best for virtual delivery; assign preflight `--full` as Day-1 homework check for Day 2 keys |
| **Self-paced** | modules 00–08 in order | 8–10 h | treat "Instructor demo" blocks as worked examples; do every lab; use checkpoints to verify (`--dry-run` shows what you are missing); M4-B/M5/M6/M7-5 need your own key; expected outputs are in each `labs/m*/expected-output/` |

Virtual delivery: add 5 min to M0 for audio/screen checks, pre-record the M4 scale-out tour and the M6 Console tour as fallbacks, run checkpoints more aggressively (announce at every part boundary, not just module boundary), and staff one TA per 8 participants in a help channel.

## 9. Conventions used in the modules

**Variables and placeholders**

| Token | Meaning |
|---|---|
| `<WORKSHOP_ORG>` | the GitHub organization hosting the five workshop repos (set once in `labs/.env` as `WORKSHOP_ORG`) |
| `<you>` | your GitHub username (`GITHUB_USER`) |
| `$WS`, `$OTEL`, `$REV` | this repo; your clone of `<WORKSHOP_ORG>/opentelemetry-demo`; your own `astroshop-reviews` copy |
| `MODEL` / `CMA_MODEL` | read from `labs/.env`: `MODEL` is the alias (`sonnet` / `opus` / `haiku`) used by `claude -p` scripts and the Agent SDK; `CMA_MODEL` is the full model ID the Managed Agents API requires (M6, reused as the `CLAUDE_MODEL` repo variable in M7). Claude Code files never carry a dated model ID |
| `T · D · L · Q` | minutes of instructor **T**alk, live **D**emo, participant **L**ab, debrief/**Q**&A buffer in a module's timing bar |
| `(3)` before a lab step | minute budget for that step |
| `Ref §X` | appendix X of `reference/Technical-Reference-v4.md` |

**Callouts** (GitHub alert syntax; no emoji)

| Callout | Used for |
|---|---|
| `> [!NOTE] Instructor` | what to say/show, pacing hints, answers to expected questions — participants may skip |
| `> [!IMPORTANT] Requires Console API key` | a step or module on the API-key matrix, always followed by the no-key path |
| `> [!WARNING] Volatile (verified Aug 2026)` | a fact likely to drift: beta headers and flags, plan/feature gating, default models, pricing, preview features, marketplace names. Every such banner is also listed in reference **§O** with the date last verified. Re-verify before each delivery. |
| `> [!CAUTION]` | a security-relevant instruction (running untrusted code, secrets, permissions you should not widen) |
| `> [!TIP] Stretch` | optional depth for fast finishers; never required by a later module |
| **Success check:** | a copy-pasteable command or observable result that proves the step worked |
| **If you're behind:** | the checkpoint command (and no-key path) that gets you to the module's end state |
| **Common failures:** | symptom → cause → fix, room-tested |

**Badges in prose:** "(beta, Aug 2026)", "(research preview, Aug 2026)", "(Team/Enterprise)", "(Enterprise)" mark availability as of the verification date. Product names are written in full: **Claude Code**, **Claude Agent SDK**, **Claude Managed Agents**, **Claude Security** (the plugin for Claude Code and the hosted Enterprise product are distinguished explicitly where it matters).

**Version-agnostic phrasing:** modules say "current Claude Code (as of August 2026)" and never pin a patch version; minimums live only in `labs/SETUP.md` / `labs/env.example` and are enforced by `preflight.sh`.

## 10. Design principles (short)

1. **One product, nine altitudes.** A single running project climbs prompt → `CLAUDE.md` → settings/hooks/MCP → subagents → skill → plugin → marketplace → headless/CI → Agent SDK service → Managed Agent → security-gated pipeline.
2. **Every module has a participant lab with a success check.** Demos are capped at about a third of each module.
3. **Checkpoints are code.** `labs/checkpoint.sh CPn`; announced at every boundary.
4. **Clocked agenda, honest arithmetic.** Talk/demo/lab/debrief minutes sum to the slot; debriefs absorb shocks; cuts are pre-decided.
5. **Teach the workflow, park the encyclopaedia.** Tables of flags, events, keys, endpoints and schemas live in the reference and are linked, not inlined.
6. **No plan/API-key dead-ends.** Two auth paths for Claude Code; API-key modules flagged up front with a no-key path each.
7. **Version-agnostic phrasing; volatile facts badged and listed.**
8. **Facilitator-portable.** All infra under `<WORKSHOP_ORG>` template repos; no personal accounts.
9. **Security is a thread, not only a module.** M2 guardrails → M4 headless trust → M5 `can_use_tool` → M6 permission policies, networking, vaults → M7 ties them together.

<a id="version-history-and-license"></a>
## 11. Version, history and license

| | |
|---|---|
| **Version** | 4.0 (August 2026) |
| **Verified against** | public Claude Code docs (`code.claude.com/docs`), Claude Agent SDK docs, and Claude Platform docs incl. Managed Agents (`platform.claude.com/docs`) as of **2026-08**. Items to re-check before each delivery: reference §O and the checklist in [README.md](README.md#before-each-delivery-re-verify-volatile-facts). |
| **Supersedes** | `Workshop-Technical-Reference-v3.md` (July 2026, never released) and `Workshop-Technical-Reference.md` (v2, the released 90-minute plugin workshop). Both are **retained unchanged for history**: [Workshop-Technical-Reference-v3.md](Workshop-Technical-Reference-v3.md), [Workshop-Technical-Reference.md](Workshop-Technical-Reference.md). Do not deliver from them. |
| **What changed from v3** | restructured from a 3.5-hour modular reference into a clocked 6-hour hands-on day; new modules for settings/hooks/MCP as guardrails, automation & CI, a full Agent SDK lab, an expanded Managed Agents lab, and a Claude Security module; real `labs/` tree with preflight and checkpoints; facilitator runbook; workshop-org template repos instead of personal accounts; model history and per-release trivia removed in favour of aliases and a dated volatile-facts list. Details: `CHANGELOG.md`. |
| **License** | Workshop materials for educational use. The OpenTelemetry demo is Apache-2.0 and used unmodified apart from a `WORKSHOP.md` pointer; `astroshop-reviews` is deliberately vulnerable teaching code — do not deploy. |
