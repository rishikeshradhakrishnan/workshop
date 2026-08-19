# Building with Claude Code, the Agent SDK, Managed Agents & Claude Security

A **6-hour, instructor-led, hands-on workshop** (v4, August 2026) for developers and technical customers.
Participants take one running project — the *Codebase Toolkit* for the OpenTelemetry "Astronomy Shop"
demo — from a first Claude Code session all the way to a plugin, a headless/CI pipeline, an Agent SDK
service, a hosted Managed Agent, and a security-gated workflow. Every module has a timed lab with a
success check, and scripted checkpoints so nobody is left behind.

**Start here:** [Workshop-Guide-v4.md](Workshop-Guide-v4.md) (the spine: audience, agenda, conventions) ·
participants → [labs/SETUP.md](labs/SETUP.md) · instructors → [FACILITATOR.md](FACILITATOR.md)

## Agenda at a glance (09:00–15:40; 6h00 session + 40 min lunch)

| Time | Module | You leave with |
|---|---|---|
| 09:00 | **M0** Welcome, preflight, platform map | green preflight; the four-ways-to-build map |
| 09:15 | **M1** Claude Code essentials | `CLAUDE.md` + path rule; plan → approve → rewind; model/effort/mode fluency |
| 09:55 | **M2** Settings & permissions, hooks, MCP | project `settings.json`, a blocking hook, a working MCP server |
| 10:40 | Break | |
| 10:50 | **M3** Subagents, skills, plugins & marketplaces | `codebase-toolkit` plugin v4.0.0 installed from a marketplace |
| 11:45 | **M4** Automation & scale | `claude -p --json-schema` findings, or an `@claude` GitHub Action |
| 12:15 | Lunch | |
| 12:55 | **M5** Claude Agent SDK | `bughunter` CLI: plugin reuse, custom tool, hooks, `can_use_tool`, structured output, sessions, cost |
| 13:50 | **M6** Claude Managed Agents | environment + agent + session, streamed events, confirmations, deliverable |
| 14:35 | Break (security scan kicked off first) | |
| 14:45 | **M7** Securing agentic development with Claude Security | triaged scan, verified patch, guidance rules, PR gate, hardened settings |
| 15:25 | **M8** Wrap-up | adoption playbook, cleanup, resources |

Full clocked table with formats, durations and checkpoints: [Workshop-Guide-v4.md → Agenda](Workshop-Guide-v4.md#agenda). Half-day, two-half-day, compressed and self-paced variants: [Guide §8](Workshop-Guide-v4.md#8-delivery-variants).

## Quick start

**Participants**
```bash
git clone https://github.com/<WORKSHOP_ORG>/claude-builders-workshop && cd claude-builders-workshop
less labs/SETUP.md                       # read first: accounts, installs, the two other repos, labs/.env
cp labs/env.example labs/.env && $EDITOR labs/.env
./labs/preflight.sh                      # until it prints READY; paste the summary line into the registration form
```
On the day, open `modules/00-welcome-and-platform-map.md` and follow the **Hands-on lab** sections module by module. Behind? `./labs/checkpoint.sh CPn`.

**Instructors / TAs**
1. [Workshop-Guide-v4.md](Workshop-Guide-v4.md) → [FACILITATOR.md](FACILITATOR.md) (T-14/T-7/T-1 checklists, run sheet, cut list, decisions to make).
2. Provision the workshop GitHub org and Console workspace (FACILITATOR §2), dry-run every lab on the pinned repo, fill in `labs/env.example` (`OTEL_PINNED_SHA` etc.).
3. `./labs/checkpoint.sh --list` must show CP1–CP7 `ready`; re-verify volatile facts (below) within a week of delivery.

## Repository map

```
README.md                          you are here
Workshop-Guide-v4.md               spine: audience, artifact ladder, clocked agenda, conventions, variants, version
FACILITATOR.md                     instructor runbook: prep checklists, run sheet, cut list, failures, decisions, follow-up
modules/
  00-welcome-and-platform-map.md   each module: objectives · timing · prerequisite checkpoint · instructor demo ·
  01-claude-code-essentials.md       Hands-on lab (numbered, minute budgets, success checks) · if you're behind ·
  02-settings-hooks-and-mcp.md       common failures · stretch · reference pointers
  03-subagents-skills-and-plugins.md
  04-automation-and-scale.md
  05-claude-agent-sdk.md
  06-claude-managed-agents.md
  07-securing-agentic-development.md
  08-wrap-up.md
reference/
  Technical-Reference-v4.md        appendices §A–§O (commands, settings, hooks, MCP, subagents, skills/plugins,
                                   headless/CI, Agent SDK, Managed Agents, security, resources, volatile facts)
labs/
  README.md  SETUP.md  env.example preflight.sh  checkpoint.sh  cleanup.sh
  checkpoints/CP0..CP7/            checkpoint content + README (directory contract, manifest)
  shared/  mcp/astro-catalog/  m1/ … m7-security/  m5-agent-sdk/  m6-managed-agents/
apps/astroshop-reviews/            source of truth for the deliberately-vulnerable template repo (M4-B, M7)
CHANGELOG.md
Workshop-Technical-Reference-v3.md archived v3 (July 2026, never released) — history only
Workshop-Technical-Reference.md    archived v2 (released 90-minute plugin workshop) — history only
```

External infrastructure lives under one GitHub org (`<WORKSHOP_ORG>`): `claude-builders-workshop` (this repo), `opentelemetry-demo` (pinned fork), `astroshop-reviews` (template), `claude-marketplace` (published reference plugin), `claude-marketplace-template`.

## Status and versions

| | |
|---|---|
| **Current** | **v4.0 — August 2026.** Verified against public Claude Code, Claude Agent SDK and Claude Platform (incl. Managed Agents) documentation as of 2026-08. Model references use aliases (`sonnet`/`opus`/`haiku`); no Claude Code patch version is pinned. |
| **Superseded** | `Workshop-Technical-Reference-v3.md` (v3, WIP July 2026, never released) and `Workshop-Technical-Reference.md` (v2). Both are kept unchanged for history; **deliver from v4 only**. |
| **History** | v4.0.0 — 6-hour hands-on redesign (this) · v3.0.0 — modular reference draft, unreleased · v2.0.0.b — 5-phase 90-minute plugin workshop · v1.0.0 — initial release. See `CHANGELOG.md`. |

## Contributing and keeping it current

- **One module per PR.** Module files map 1:1 to `labs/mN*/` folders and to checkpoints; keep the skeleton (objectives → … → reference pointers) intact and the minute budgets summing to the slot.
- **Facts go in the reference, steps go in modules.** If you add a table of flags/events/keys to a module, move it to `reference/Technical-Reference-v4.md` and link it.
- **Never pin a Claude Code patch version in prose;** use aliases for models; put minimums only in `labs/SETUP.md`/`labs/env.example`.
- **Badge anything beta/preview/plan-gated** with `> [!WARNING] Volatile (verified <Mon YYYY>)` and add it to reference §O.
- **Scripts:** `bash -n labs/*.sh`; keep them bash-3.2-compatible (macOS) and non-destructive; Windows participants run them from Git Bash or WSL2 (only `labs/m2/hooks/protect-files.ps1` ships as a PowerShell example).
- **Checkpoint content** changes together with the lab that produces it; run the self-test in `labs/checkpoints/README.md`.

### Before each delivery, re-verify volatile facts

Do this within 7 days of the event and record the date in FACILITATOR.md's record sheet.

- [ ] `claude --version` current release installs cleanly via the native installer on macOS, Windows and Linux; `claude doctor` clean; note the version.
- [ ] What the `default`, `sonnet`, `opus`, `haiku` aliases resolve to for the plans in the room (`/model`); update reference §B if changed, and set `CMA_MODEL` in `labs/env.example` to a current full model ID for Module 6.
- [ ] Permission modes and the **start mode per plan** (auto vs manual) still as described in M1; `--permission-mode default` still pins the room.
- [ ] Hook event names/handler types used in M2 and the `PreToolUse` JSON decision contract unchanged (reference §E).
- [ ] `claude plugin init|validate|install|list`, `/plugin marketplace add`, `marketplace.json` schema, and the official marketplace name (`claude-plugins-official`) unchanged; `claude-security` and `security-guidance` plugins install and run; note plugin versions.
- [ ] `claude -p` JSON result fields (`result`, `session_id`, `total_cost_usd`, `structured_output`, `permission_denials`) and `--json-schema` behaviour unchanged (M4, preflight `--ping`).
- [ ] `anthropics/claude-code-action@v1` and `anthropics/claude-code-security-review` inputs used in `labs/m4/github/*.yml` and `.workshop/security-review.yml` still valid; pinned `claude-model` input current.
- [ ] Agent SDK: `pip install claude-agent-sdk` / `npm i @anthropic-ai/claude-agent-sdk` current majors still expose the options used in M5 (`setting_sources`, `plugins`, `output_format`, `can_use_tool`, hooks, `max_budget_usd`); run both solutions end to end.
- [ ] Managed Agents: beta header (`managed-agents-2026-04-01`), toolset id (`agent_toolset_20260401`), event names, `requires_action` flow, pricing line (session-hour rate) and default org availability; run the M6 solution end to end; update `labs/env.example` `MANAGED_AGENTS_BETA` and reference §L/§O.
- [ ] Claude Security plugin: `/claude-security` job names, effort tiers, output folder layout (`CLAUDE-SECURITY-<ts>/…RESULTS.md|.jsonl|.sarif`), medium-effort scan duration on `astroshop-reviews` (must fit Break 2 + talk ≈ 20 min); regenerate `.workshop/sample-results/` if older than a quarter.
- [ ] Dynamic workflows availability/opt-in per plan (needed by the Claude Security plugin).
- [ ] Hosted Claude Security, Code Review, Claude Code on the web: plan gating and naming as positioned in M4/M7 slides.
- [ ] `<WORKSHOP_ORG>/opentelemetry-demo` still pinned to the recorded tag/SHA; `astroshop-reviews` tests green on current Python; marketplace repo tagged `v4.0.0`.
- [ ] Venue network reaches every host in `labs/preflight.sh`'s list.

## License

Workshop materials for educational use. Third-party components keep their own licenses (OpenTelemetry demo: Apache-2.0). `astroshop-reviews` is intentionally vulnerable teaching code — never deploy it.
