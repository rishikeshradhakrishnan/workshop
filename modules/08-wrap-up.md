# Module 8 — Wrap-up: The Whole Picture, Adoption Playbook, Resources, Q&A

> **Time box:** 15:25–15:40 (15 min) · **Format:** talk 10 · Q&A 5 · **Checkpoint in:** CP7 · **Checkpoint out:** — (nothing new is built; `labs/cleanup.sh` is the only command)

Conventions: `$WS` = your clone of `<WORKSHOP_ORG>/claude-builders-workshop`, `$OTEL` = your clone of `<WORKSHOP_ORG>/opentelemetry-demo`, `$REV` = your copy of `<WORKSHOP_ORG>/astroshop-reviews`. "Ref §X" points at `reference/Technical-Reference-v4.md`. Product status words ("beta", "research preview") are as of August 2026; Ref §O lists what to re-verify before each delivery.

## Why this matters

Six hours ago the platform map was four boxes on a slide. Now every box has something *you* built sitting in it, and each artifact was consumed by the next: a `CLAUDE.md` became context for subagents, subagents and a skill became a plugin, the plugin ran headless in CI, loaded into an SDK process, and its prompt became a Managed Agent — and then you turned the same machinery on your own code to find and fix vulnerabilities and gate the PR. The risk after a day like this is that it stays a day. This module turns it into a plan: what to do Monday, what to do this quarter, which tool to reach for when, where to keep current, and how to clean up what you spun up in the cloud.

## Learning objectives

By 15:40 you can:

1. Re-tell the day as **one architecture**: place your own artifacts on the M0 platform map (Messages API → Agent SDK → Claude Code → Managed Agents, ringed by the extension points and the security layers).
2. Leave with an **adoption playbook**: individual (CLAUDE.md, plan mode, skills) → team (project settings, hooks, plugin + private marketplace, `enabledPlugins`) → CI (headless, Actions, Code Review, security gate) → products (Agent SDK vs Managed Agents decision) → organization (managed settings, model/effort policies, telemetry, hosted Claude Security).
3. Know **where to keep current** — `code.claude.com/docs`, `platform.claude.com/docs`, the What's-new digests and changelogs for Claude Code and both SDKs, the cookbooks, the plugin marketplaces — and how to **clean up** today's cloud resources.

## Concepts (instructor talk track)

### 8.0 The M0 map, redrawn with your artifacts on it (shown, not narrated)

The opening slide of the day returns with the boxes filled in. Left to right is "who runs the agent loop"; the rings are the extension points and guardrails that travelled with you.

```
                         ┌──────────────── security layers you configured ─────────────────┐
                         │ deny/ask/allow · modes+auto classifier · sandbox · hooks ·       │
                         │ dontAsk/--bare · can_use_tool · permission_policy/limited net/    │
                         │ vaults · managed settings · security-guidance · /security-review │
                         │ · Claude Security plugin · PR gate · (hosted Claude Security)     │
  ┌──────────────┐   ┌───┴────────────┐   ┌──────────────────────┐   ┌───────────────────┴──┐
  │ Messages API │   │ Agent SDK      │   │ Claude Code          │   │ Managed Agents (beta)│
  │ you run loop │   │ SDK runs loop  │   │ CLI/IDE/web/CI       │   │ Anthropic runs loop  │
  │ + tools      │   │ in YOUR process│   │ on your machine/VM   │   │ + container          │
  │              │   │                │   │                      │   │                      │
  │ (background  │   │ M5 bughunter:  │   │ M1 CLAUDE.md, rules  │   │ M6 agent+env+session │
  │  for today)  │   │ custom tool,   │   │ M2 settings/hooks/MCP│   │ custom tool, confirm,│
  │              │   │ hooks, schema, │   │ M3 agents/skill →    │   │ bug-report.md,       │
  │              │   │ sessions, cost │   │    plugin+marketplace│   │ webhook/schedule     │
  │              │   │                │   │ M4 -p, Actions       │   │                      │
  │              │   │                │   │ M7 scan/patch/gate   │   │                      │
  └──────────────┘   └────────────────┘   └──────────────────────┘   └──────────────────────┘
        same models · same tool-use protocol · same plugin components (agents, skills, hooks, MCP)
```

One sentence to say over it: *"Claude Code on the web is a developer surface on a subscription; Managed Agents is an API you meter into your product — same engine, different customer."*

### 8.1 What you built — the artifact ladder, checked off (3 min)

| # | Artifact | Built in | Reused in | Yours? |
|---|---|---|---|---|
| 1 | `CLAUDE.md` + `.claude/rules/proto.md` | M1 | M3 agents/skill inherit it · M5 `setting_sources=["project"]` · M6 memory-store stretch · M7 "advisory vs enforced" | ☐ |
| 2 | `.claude/settings.json` (allow/ask/deny, `defaultMode`, sandbox) | M2 | M4 `dontAsk` relied on it · M7 hardened it | ☐ |
| 3 | `.claude/hooks/protect-files.sh` + `bash-audit.log` | M2 | plugin `hooks/hooks.json` (M3) · SDK hook callback (M5) · security hooks (M7) | ☐ |
| 4 | `.mcp.json` + `astro-catalog` stdio server | M2 | bundled in plugin (M3) · SDK external MCP (M5) · Managed Agents `mcp_toolset` + vault (M6) · MCP trust (M7) | ☐ |
| 5 | `service-documenter` + `bug-hunter` subagents | M3 | `-p @agent-…` (M4) · SDK `plugins`/`agents` (M5) · Managed Agents `system` prompt (M6) · vs. Claude Security researchers (M7) | ☐ |
| 6 | `code-reviewer` skill (args, `allowed-tools`, checklist file) | M3 | headless + Action prompt (M4) · least-privilege echoed by `/claude-security` (M7) | ☐ |
| 7 | `codebase-toolkit` plugin v4.0.0 + `workshop-marketplace` (+ org marketplace install) | M3 | `-p`/Actions `plugins:` (M4) · SDK `plugins=[…]` (M5) · "same components, hosted" (M6) · `strictKnownMarketplaces` (M7) | ☐ |
| 8 | `bug-hunt.sh` + `findings.schema.json`; `claude.yml`, `code-review.yml` | M4 | schema → SDK structured output (M5) → compared to Claude Security JSONL (M7); Actions repo reused for the gate (M7) | ☐ |
| 9 | `bughunter` SDK CLI (custom tool, hooks, `can_use_tool`, structured output, sessions, cost) | M5 | `create_ticket` + schema reused as Managed Agents custom tool (M6) · variance vs plugin (M7 stretch) | ☐ |
| 10 | Managed Agent `codebase-toolkit-<you>` + environment + session + `bug-report.md` | M6 | security controls recap (M7) · cleaned up **now** | ☐ |
| 11 | `CLAUDE-SECURITY-<ts>/` report, `fix/f1-sqli`, `security-patterns.yaml`, `claude-security-guidance.md`, `security-review.yml`, hardened settings | M7 | this playbook | ☐ |

> [!NOTE] Instructor
> Put this table on screen with live checkmarks (ask for hands per row — it doubles as feedback on pacing). Invite two volunteers: one to show their favourite `bug-hunter` or Claude Security finding, one to show their `tickets.json` or Managed Agents session trace. 60 seconds each, hard stop.

**Party trick (optional, 40 s):** in `$OTEL`, run
`claude -p "Read .claude/, ../codebase-toolkit, and git log since this morning. Write WHAT-YOU-BUILT.md: a one-page inventory of every Claude Code artifact in this repo, what it does, and which workshop module produced it." --permission-mode acceptEdits --allowedTools "Read,Glob,Grep,Write,Bash(git log *)"` — participants leave with a personalized summary written by the thing they configured.

### 8.2 "Which tool when" — the master decision table (3 min)

Read it row by row as *"reach for this when…"*. Everything here is documented in Ref §A/§I.3/§K/§L/§M; plan and status notes are as of Aug 2026.

| Tool | Reach for it when… | Not the right tool when… | Lives in / invoked by | Notes (plan · status) |
|---|---|---|---|---|
| **`CLAUDE.md` + `.claude/rules/`** | Every session in this repo should know conventions, commands, architecture; path-scoped rules for special dirs | You need a *guarantee* (use rules/hooks) or on-demand know-how (use a skill); keep it < ~200 lines | repo root, `.claude/rules/*.md`, `~/.claude/CLAUDE.md` | Advisory context, loaded every session |
| **Skills** (`SKILL.md`) | A repeatable procedure or checklist Claude should load *on demand* or you invoke as `/name args`; progressive disclosure via supporting files | It must run deterministically every time (hook) or needs live data/tools (MCP) | `.claude/skills/<name>/`, plugin `skills/` | Model- or user-invocable; `allowed-tools` for least privilege |
| **Subagents** | Work that benefits from its own context window, scoped tools/model/effort, or parallel fan-out; keep the main context small | A two-line task (overhead > benefit); you need shared scratch state between workers (use one agent or a workflow) | `.claude/agents/*.md`, plugin `agents/`, SDK `agents=` | Run in background by default; cost scales with fan-out |
| **Hooks** | "Always/never" policies: block edits to protected paths, audit Bash, inject context at `SessionStart`, refuse to stop before tests, alert on `ConfigChange` | The behaviour needs judgement (skill/CLAUDE.md) — hooks are code, not prose | `settings.json` `hooks`, plugin `hooks/hooks.json`, SDK callbacks | Deterministic; exit 2 blocks; run with *your* privileges |
| **MCP servers** | Claude needs tools or data outside the repo (catalog, tickets, browser, DB) under the permission system | A skill documenting *how* to use existing tools would do; you would not run the server as yourself (trust) | `claude mcp add`, `.mcp.json`, plugin `.mcp.json`, SDK `mcp_servers`, Managed Agents `mcp_toolset` | Only servers you trust; managed allow/deny lists for orgs |
| **Plugins + marketplaces** | You want to *ship* agents+skills+hooks+MCP as one versioned unit to a team; roll out with `enabledPlugins` + `extraKnownMarketplaces` | One-person, one-repo tweaks (project files are simpler) | `.claude-plugin/plugin.json`, `marketplace.json`, `/plugin install x@mkt` | Executes code as you — `strictKnownMarketplaces` for orgs |
| **`claude -p` (headless)** | Scripts, cron, CI steps: JSON/stream-JSON, `--json-schema`, `--allowedTools` + `--permission-mode dontAsk`, `--max-turns`, `--max-budget-usd` | Long-lived services with custom tools and callbacks (SDK) or fully hosted runs (Managed Agents) | any shell/CI runner | No trust dialog: `--bare`/`--setting-sources user` on untrusted checkouts |
| **GitHub Actions** (`anthropics/claude-code-action@v1`, `claude-code-security-review`) | `@claude` in PRs/issues, automated review, scheduled repo chores, PR security gate | Interactive exploration; untrusted fork PRs for AI reviewers | `.github/workflows/*.yml` + secret/OIDC | API key or cloud-provider auth; minimal `permissions:` |
| **Code Review** (managed) | You want every PR reviewed with full-codebase context without maintaining workflows | You are not on Team/Enterprise, or need custom pipeline logic (use the Action) | Claude admin settings + GitHub App | Team/Enterprise |
| **Background sessions / dynamic workflows** (`claude --bg`, `claude agents`, `ultracode`, `/workflows`) | Big local jobs: many parallel subagents with verification, saved as `/name` workflows; keep working while it runs | CI (use `-p`/Actions) or anything that must survive your laptop closing (web/Routines/Managed Agents) | terminal | Research preview / paid plans; Pro enables workflows in `/config` |
| **Claude Code on the web** (`claude.ai/code`, `--cloud`, `--teleport`) | Developer-facing cloud sessions on your repos that continue after you disconnect; hand-off between laptop and cloud | Building a product for *your* users (that is Managed Agents); air-gapped code | subscription seat + GitHub | Subscription plans; isolated VM, limited network |
| **Routines** (`/schedule`) | "Every weekday at 07:00 run this prompt against this repo in the cloud" for *developers* | Product workloads metered to your customers (Managed Agents scheduled deployments) | Claude Code + subscription | Subscription feature |
| **Claude Agent SDK** (Python/TS) | You are building an agentic feature *inside your own service/process*: custom tools in-process, hook and `can_use_tool` callbacks, structured output, your infra, your container hardening | You do not want to run/secure the loop and sandbox yourself (Managed Agents), or a shell one-liner would do (`-p`) | `claude-agent-sdk` / `@anthropic-ai/claude-agent-sdk` | Console API key or Bedrock/Vertex/Foundry; you host it |
| **Claude Managed Agents** | You want Anthropic to run the loop *and* the sandboxed container: versioned agents, environments, sessions/events, permission policies, vaults, memory, webhooks, schedules; per-session isolation for your product's users | You need on-prem execution only (consider self-hosted sandboxes) or sub-second in-process tools (SDK) | `client.beta.agents/…`, Console | Beta (Aug 2026); tokens + session-hour runtime; Claude API / Claude Platform on AWS |
| **security-guidance plugin** | Every coding session: catch risky patterns per edit, review each turn's diff, review commits Claude makes | You need blocking enforcement (pair with hooks/CI) | `security-guidance@claude-plugins-official`, `.claude/security-patterns.yaml`, `.claude/claude-security-guidance.md` | All plans; model-backed layers use normal usage |
| **`/security-review`** | Quick single-pass check of your branch diff before pushing | You need verified, machine-readable findings or a whole-repo view | built-in command | Needs `origin/HEAD` |
| **Claude Security plugin** | On-demand deep scan of a repo/area/diff with panel-verified findings, JSONL/SARIF, and verified patches; any git host, offline networks | Continuous org-wide monitoring with dashboards (hosted product); untrusted code without sandbox-runtime | `claude-security@claude-plugins-official`, `/claude-security` | Beta (Aug 2026); paid plan + dynamic workflows; plan usage |
| **Claude Security** (hosted) | Enterprise wants scheduled/targeted scans of connected GitHub repos, triage/dismissal workflow, exports and webhooks | Repos not on GitHub, or no Enterprise plan (use the plugin) | `claude.ai/security` | Enterprise **[verify-on-day]** |

**The three-question shortcut** for "SDK vs Managed Agents vs Claude Code on the web vs `-p`":
1. *Who is the user?* Your developers → Claude Code (terminal/IDE/web/Routines/`-p`/Actions). Your customers or internal systems → SDK or Managed Agents.
2. *Who runs the loop and the sandbox?* You want both in your process/infra → **Agent SDK** (+ your container: `--network none`, proxy, read-only mounts). You want Anthropic to run both → **Managed Agents** (environment `networking: limited`, `permission_policy`, vaults).
3. *How long and how stateful?* One-shot in a pipeline → `-p`. Minutes-to-hours, resumable, event-streamed, many concurrent tenants → Managed Agents sessions. Embedded multi-turn inside an app you already operate → SDK with `resume`/sessions.

The mapping you saw in M6 makes migration mechanical: SDK options → Agent; `query()` → Session; `@tool` → custom tool; hooks/`can_use_tool` → `permission_policy` + confirmations; `cwd`/files → resources.

### 8.3 The 30 / 60 / 90-day adoption playbook (3 min)

Print this; it is also the follow-up email.

**Days 1–30 — individuals and one pilot repo ("make Monday better")**
- [ ] Every active repo gets a reviewed `CLAUDE.md` (< 200 lines: build/test commands, architecture, conventions) and 1–3 path-scoped rules. Measure: fewer "how do I run tests" turns.
- [ ] Default working style: plan mode for anything multi-file → approve into `acceptEdits`/auto; `/rewind` instead of arguing; `/context` and `/usage` awareness; `sonnet` for routine work, `opus`/higher effort deliberately.
- [ ] Personal `~/.claude/settings.json`: deny `Read(./.env*)`, `Read(./secrets/**)`, `Bash(curl *)`, `Bash(wget *)`; ask on `git push`; sandbox on where supported. Install `security-guidance` at user scope.
- [ ] Port two team rituals into skills (`/code-reviewer`-style with `allowed-tools`) and one specialist into a subagent. Keep them in the pilot repo's `.claude/`.
- [ ] Run `/security-review` before every push for a month; run one Claude Security plugin scan of the pilot repo at `medium`, triage as a team, apply ≥ 1 verified patch via PR.
- [ ] Nominate an owner for "Claude tooling" in the team (rotating is fine).

**Days 31–60 — team standardization ("make it the same for everyone")**
- [ ] Promote the pilot's agents/skills/hooks/MCP config into a **team plugin** (`plugin.json` semver, CHANGELOG) in a **private marketplace repo**; roll out with `extraKnownMarketplaces` + `enabledPlugins` in each repo's committed `.claude/settings.json`.
- [ ] Commit project `settings.json` per repo: allow/ask/deny lists, `defaultMode`, sandbox block (+ `allowUnsandboxedCommands: false`), the protect-files hook, a Bash audit hook. Review it like code.
- [ ] CI: add `anthropics/claude-code-action@v1` (`@claude` + automation prompts using your plugin's skills) with minimal `permissions:` and secrets/OIDC; add the `claude-code-security-review` gate (pinned SHA, explicit `claude-model`, `custom-security-scan-instructions`, external-contributor approval on). Team/Enterprise: evaluate managed Code Review instead of/alongside.
- [ ] Headless helpers: 2–3 `claude -p` scripts with `--json-schema`, `--allowedTools`, `--permission-mode dontAsk`, `--max-budget-usd` (release notes, findings triage, README drift).
- [ ] Decide your MCP trust list (which servers, which scopes) and write it down; prefer HTTP servers with OAuth for SaaS, stdio you own for local.
- [ ] Schedule: weekly `/claude-security scan my branch` habit for release branches; monthly `medium` whole-repo scan; findings go to the tracker via JSONL, SARIF to code scanning where available.

**Days 61–90 — products and organization ("make it policy, make it product")**
- [ ] Pick one agentic feature and build it properly: **Agent SDK** if it lives in your service (container per Ref §K.4: `--cap-drop ALL`, `--network none` + egress proxy, read-only code mount, API-key/cloud auth — never a developer's subscription login), or **Managed Agents** if you want hosted sessions (environment `limited` networking + `allowed_hosts`, `always_ask` on risky tools, vault credentials, `read_only` memory stores, budgets, webhooks into your systems). Use the M5→M6 mapping to keep the option to move.
- [ ] Organization controls via **managed settings** (server-managed from the admin console or `managed-settings.json` via MDM): `permissions.disableBypassPermissionsMode`, org deny rules, `allowManagedPermissionRulesOnly` / `allowManagedHooksOnly` / `allowManagedMcpServersOnly` as your risk appetite dictates, `strictKnownMarketplaces` (your marketplace + `claude-plugins-official`), managed MCP allow/deny lists, model and effort policies, `enabledPlugins` for security-guidance.
- [ ] Observability and cost: `CLAUDE_CODE_ENABLE_TELEMETRY=1` → your OTel collector (`tool_decision`, token/cost metrics); Console workspace spend limits and per-key budgets; usage analytics (Team/Enterprise); a monthly "cost per merged PR" glance.
- [ ] Security program: Enterprise → evaluate hosted **Claude Security** for connected GitHub repos (scheduled scans, dismissal workflow, exports/webhooks) with the plugin covering everything else; everyone → quarterly `high`-effort scoped scans of auth/payment code; keep SAST/dependency scanning — the layers complement, not replace.
- [ ] Write the one-page internal "How we use Claude for code" doc: approved surfaces, auth paths, what needs an API key, data-handling rules, who owns the plugin, how to report weird agent behaviour (`/feedback` + your channel).
- [ ] Re-run this workshop's preflight quarterly against current versions; re-verify Ref §O volatile facts (model line-up, beta headers, pricing, plan gating) before you present any of it internally.

### 8.4 Keeping current, and cleaning up (1 min)

**Where truth lives** (bookmark these; everything in today's material was verified against them in August 2026):
- Claude Code docs home and index: <https://code.claude.com/docs> · What's new (weekly digests): <https://code.claude.com/docs/en/whats-new> · Changelog: <https://code.claude.com/docs/en/changelog>
- Claude Platform docs (Messages API, models, pricing, Managed Agents): <https://platform.claude.com/docs> · Release notes: <https://platform.claude.com/docs/en/release-notes/overview> · Models overview: <https://platform.claude.com/docs/en/about-claude/models/overview>
- Agent SDK: <https://code.claude.com/docs/en/agent-sdk/overview> · repos/changelogs: <https://github.com/anthropics/claude-agent-sdk-python>, <https://github.com/anthropics/claude-agent-sdk-typescript>
- Managed Agents: <https://platform.claude.com/docs/en/managed-agents/overview> · cookbook: <https://github.com/anthropics/claude-cookbooks/tree/main/managed_agents> · quickstarts: <https://github.com/anthropics/claude-quickstarts>
- Plugins: official marketplace <https://github.com/anthropics/claude-plugins-official> · docs <https://code.claude.com/docs/en/discover-plugins>
- Security: <https://code.claude.com/docs/en/security>, <https://code.claude.com/docs/en/claude-security>, <https://code.claude.com/docs/en/security-guidance>, <https://github.com/anthropics/claude-code-security-review>, <https://github.com/anthropic-experimental/sandbox-runtime>

**Cleanup — do it before you close the laptop:**

```bash
cd $WS && ./labs/cleanup.sh            # Windows: run from Git Bash or WSL2
```

It archives the Managed Agents **agents, sessions and environments** you created today (matched by the IDs cached in `labs/m6-managed-agents/**/.cma-state.json`; the resources are named `ws-$GITHUB_USER` / `codebase-toolkit-$GITHUB_USER` as in Module 6), lists any Console **webhooks** and **scheduled deployments** you made in M6 step 6 with the exact Console page to delete them, and prints reminders to: revoke or rotate the workshop API key (Console → API keys), remove the instructor's shared key from `labs/.env`, delete the `CLAUDE_MODEL` repo variable / `ANTHROPIC_API_KEY` secret from `astroshop-reviews` if you will not keep using it, and (optionally, `--plugins`) uninstall `codebase-toolkit@workshop-marketplace` and disable lab plugins. It never touches `~/.claude/settings.json`; if you experimented there, review it yourself. Idle Managed Agents sessions do not accrue runtime charges, but archived is tidier than idle.

## Live demo script (10 min talk · 5 min Q&A)

1. **(3 min) "What you built."** Table 8.1 on screen; hands per row; two volunteers × 60 s. Optionally run the `WHAT-YOU-BUILT.md` one-liner on the side screen and open the result at the end.
2. **(3 min) "Which tool when" + playbook.** Show table 8.2 collapsed to its first two columns; walk only the five rows people mix up most: skills vs subagents vs hooks; `-p` vs SDK vs Managed Agents; plugin scan vs hosted Claude Security. Then the 30/60/90 slide — say explicitly which three checkboxes you would do first in *their* shoes (usually: `CLAUDE.md` + project settings, one team plugin, the PR security gate).
3. **(2 min) Cleanup.** Run `./labs/cleanup.sh` live; show the archived agent disappearing from Console → Agents (filter: active). Say the API-key sentence out loud.
4. **(2 min) Resources + feedback.** Resources slide (8.4 list) and the feedback-form QR. Ask for the form *now*, before Q&A — completion rates halve after people stand up.
5. **(5 min) Q&A.** Script below.

**Feedback form (5 questions, 90 seconds; template in FACILITATOR §9).** (1) Which checkpoint did you finish on your own — CP0…CP7? (2) Rate each module 1–5 for *usefulness* and for *pace*. (3) Which one artifact will you use at work first? (4) What blocked you today (install, auth/plan, network, time, concepts)? (5) What should the next edition add or cut? Optional: email for the follow-up pack. The CP question is the single best pacing metric across deliveries — keep it first.

**Q&A script (facilitator notes).**
- Open with a seeded question if the room is quiet: *"What is the first thing that will break when you try this at work?"* — it surfaces proxy/SSO/plan-gating issues you can answer from Ref §J, the proxy / managed-settings notes in `labs/SETUP.md`, and FACILITATOR §8.
- Expect and prepare one-line answers for: "Which of this is beta?" (Managed Agents, Claude Security plugin, background sessions/workflows are research preview or beta as of Aug 2026 — Ref §O); "Does the plugin send my code anywhere new?" (it runs in your session under your existing Claude Code data flow; scans make no additional network calls); "Subscription or API key for CI/products?" (products and CI use API-key or cloud-provider auth; subscriptions are for humans at keyboards); "Can I run all this on Bedrock/Vertex/Foundry?" (Claude Code, SDK: yes with provider env vars; Managed Agents: Claude API and Claude Platform on AWS — Ref §L); "How much did today cost?" (show your Console usage page for the workshop workspace).
- Park anything roadmap-shaped: "I can only speak to what is documented today; the What's-new digest is where that will show up."
- Close at 15:39 with the one-sentence summary: *"Same engine everywhere — terminal, CI, your code, Anthropic's cloud — and the guardrails are files you now know how to write."*

## Hands-on lab (take-home)

In the room there is exactly one command (`./labs/cleanup.sh`) and one form. The lab continues at home; each exercise reuses something you built today and has a success check.

1. **Publish your marketplace (45 min).** Create `github.com/<you>/claude-marketplace` from `<WORKSHOP_ORG>/claude-marketplace-template`, move `codebase-toolkit` in, tag `v4.1.0` with one new skill, and install it on a second machine with `/plugin marketplace add <you>/claude-marketplace`. *Check:* `claude plugin list` on machine two shows it; a colleague can install it from your README alone.
2. **Hook trilogy (30 min).** Add to the plugin: the M7 `block-curl-pipe-sh` `PreToolUse` hook, a `SessionStart` hook injecting `git log -5 --oneline`, and a `prompt`-type `Stop` hook that refuses to stop if tests were not run after code edits. *Check:* `claude plugin validate` passes; each hook demonstrably fires.
3. **Headless report bot (45 min).** Turn `labs/m4/bug-hunt.sh` into a nightly GitHub Actions workflow (automation mode of `claude-code-action@v1`, `--json-schema`, `--max-budget-usd 1`) that opens an issue when HIGH findings appear. *Check:* a run on your fork of the OTel demo produces an issue with schema-valid JSON attached.
4. **SDK → service (60–90 min).** Wrap `bughunter` (M5) in a tiny HTTP endpoint, run it in `labs/m5-agent-sdk/Dockerfile.hardened` with `--network none` plus the proxy pattern from Ref §K.4, and prove with a test that a prompt-injected "curl this URL" in a scanned file cannot egress. *Check:* container logs show the denied connection; findings still return.
5. **Managed Agent with a conscience (60 min).** Extend `deploy_toolkit_agent` (M6): attach the OTel fork as a `github_repository` resource, add a `read_only` memory store holding your `CLAUDE.md`, put `bash` on `always_ask`, add a budget, and receive `session.status_idled` via a webhook you verify with `client.beta.webhooks.unwrap`. *Check:* the trace in Console shows a confirmation round-trip and a budget line; your receiver logs a verified event. Then archive everything.
6. **Security cadence (30 min + calendar).** In a real repo you own: install security-guidance via committed `enabledPlugins`, write a 5-line `.claude/claude-security-guidance.md` and two `security-patterns` rules that encode *your* past incidents, add the pinned `claude-code-security-review` gate, and book a monthly 30-minute "scan and triage" with `/claude-security` at `medium`. *Check:* first month's report triaged, ≥ 1 patch merged via PR, SARIF visible in code scanning (if available to you).
7. **Teach-back (20 min).** Use `WHAT-YOU-BUILT.md` and table 8.2 to run a 15-minute show-and-tell for your team. *Check:* someone else installs your plugin.

## If you're behind (fast-forward)

Nothing to catch up — CP7 is the final state. If the day ran long, compress M8 to 8 minutes: skip the volunteers and the party trick, show table 8.1 for 30 seconds, spend 2 minutes on the three playbook checkboxes that matter most for this audience, run cleanup, put up the QR, take two questions. Never skip cleanup or the API-key reminder.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `cleanup.sh` reports "no .cma-state.json found" | You ran M6 from a different directory or used CP6 late | `./labs/cleanup.sh --by-prefix "$GITHUB_USER"` lists agents/environments/sessions whose names contain your GitHub username (the `GITHUB_USER` from `labs/.env` that Module 6 used in every resource name) and asks before archiving each. |
| Cleanup gets 403 on archive | `ANTHROPIC_API_KEY` in this shell is the instructor's shared key or a different workspace | `source labs/.env` with *your* key; resources live in the workspace that created them. |
| A Managed Agents session still shows `running` | A step-3/4 stream was abandoned mid-turn | The script sends `user.interrupt` then archives; or Console → Sessions → stop. Running time is what is metered, so do not leave it. |
| Webhook endpoint keeps receiving events after the workshop | Console webhook not deleted (the script can only list them) | Console → Webhooks → delete the `smee.io` endpoint you added. |
| `WHAT-YOU-BUILT.md` one-liner is denied a tool | `acceptEdits` still asks for Bash beyond the allow list | It only needs `Read,Glob,Grep,Write,Bash(git log *)`; if your project settings deny more, run it with `--setting-sources user`. |
| Participants ask for slides/recording | — | FACILITATOR §9 has the follow-up email template with links to this repo, Ref §N, and the feedback summary timeline. |

## Stretch goals

None in the room. If a group finishes cleanup early, have them open Ref §O ("volatile facts") and guess which three entries will have changed by the next delivery — it is the most honest summary of how fast this platform moves, and a good habit to leave with.

## Key takeaways

1. **One engine, many altitudes.** The same agent loop runs in your terminal, your IDE, your CI, your own process (SDK) and Anthropic's cloud (Managed Agents); the artifacts you wrote today — `CLAUDE.md`, settings, hooks, MCP config, agents, skills, a plugin — travel across all of them.
2. **Files are the interface.** Almost everything that made Claude more useful or safer today was a small, reviewable file in git. Treat them like code: owners, review, versions, a marketplace.
3. **Choose the tool by who the user is and who runs the loop.** Developers → Claude Code surfaces; your product → SDK (you run it) or Managed Agents (Anthropic runs it); one-shot automation → `-p`/Actions.
4. **Guardrails before autonomy.** Deny rules, sandbox, hooks, `dontAsk`/`can_use_tool`, `always_ask`/limited networking/vaults, managed settings — then turn up auto mode, background work and unattended runs.
5. **Security is a cadence, not an event.** security-guidance while typing, `/security-review` before pushing, change scans before merging, a PR gate, periodic deep scans (plugin or hosted), and humans on the merge button.
6. **Re-verify before you repeat.** Model line-ups, beta headers, plan gating and prices move monthly; the docs, What's-new digests and changelogs are the source of truth, and Ref §O tells you exactly what to check.

## References

- Ref §A (platform map) · §N.1 (glossary) · §I.3 (orchestration & surfaces "when to use what") · §K (Agent SDK incl. §K.4 secure deployment and the CLI↔SDK↔CMA mapping) · §L (Managed Agents incl. pricing example and cleanup API calls) · §M (security layers) · §N (resources & links, kept current) · §O (volatile facts to re-verify) · FACILITATOR §9 (feedback form, follow-up email template, known-issues log).
- Claude Code: <https://code.claude.com/docs> · <https://code.claude.com/docs/en/whats-new> · <https://code.claude.com/docs/en/changelog> · best practices <https://code.claude.com/docs/en/best-practices> · settings <https://code.claude.com/docs/en/settings> · hooks <https://code.claude.com/docs/en/hooks> · MCP <https://code.claude.com/docs/en/mcp> · subagents <https://code.claude.com/docs/en/sub-agents> · skills <https://code.claude.com/docs/en/skills> · plugins <https://code.claude.com/docs/en/discover-plugins>, <https://code.claude.com/docs/en/plugins-reference> · headless <https://code.claude.com/docs/en/headless> · GitHub Actions <https://code.claude.com/docs/en/github-actions> · Code Review <https://code.claude.com/docs/en/code-review> · Claude Code on the web <https://code.claude.com/docs/en/claude-code-on-the-web> · Routines <https://code.claude.com/docs/en/routines> · workflows <https://code.claude.com/docs/en/workflows> · sandboxing <https://code.claude.com/docs/en/sandboxing> · security <https://code.claude.com/docs/en/security> · monitoring <https://code.claude.com/docs/en/monitoring-usage> · admin setup <https://code.claude.com/docs/en/admin-setup>
- Agent SDK: <https://code.claude.com/docs/en/agent-sdk/overview> · <https://code.claude.com/docs/en/agent-sdk/permissions> · <https://code.claude.com/docs/en/agent-sdk/hosting> · <https://code.claude.com/docs/en/agent-sdk/secure-deployment> · <https://github.com/anthropics/claude-agent-sdk-python> · <https://github.com/anthropics/claude-agent-sdk-typescript>
- Managed Agents (beta): <https://platform.claude.com/docs/en/managed-agents/overview> · quickstart <https://platform.claude.com/docs/en/managed-agents/quickstart> · permission policies <https://platform.claude.com/docs/en/managed-agents/permission-policies> · environments <https://platform.claude.com/docs/en/managed-agents/environments> · vaults <https://platform.claude.com/docs/en/managed-agents/vaults> · memory <https://platform.claude.com/docs/en/managed-agents/memory> · webhooks <https://platform.claude.com/docs/en/managed-agents/webhooks> · migration from the SDK <https://platform.claude.com/docs/en/managed-agents/migration> · pricing <https://platform.claude.com/docs/en/about-claude/pricing> · cookbook <https://github.com/anthropics/claude-cookbooks/tree/main/managed_agents>
- Security tooling: <https://code.claude.com/docs/en/claude-security> · <https://code.claude.com/docs/en/security-guidance> · <https://github.com/anthropics/claude-plugins-official> · <https://github.com/anthropics/claude-code-security-review> · <https://github.com/anthropics/claude-code-action/blob/main/docs/security.md> · <https://github.com/anthropic-experimental/sandbox-runtime> · hosted Claude Security <https://claude.com/product/claude-security> **[verify-on-day]**
- Building safer agents on the API: <https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks>
- Engineering background reading (re-read before quoting numbers): Claude Code sandboxing and auto mode posts on <https://www.anthropic.com/engineering>
