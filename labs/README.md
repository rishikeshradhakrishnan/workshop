# `labs/` — hands-on labs, scripts, starters and solutions

Everything a participant types during the day lives under this folder or is copied from it. The
teaching narrative (objectives, instructor demo, numbered lab steps with minute budgets, success
checks, troubleshooting, stretch goals) lives in [`../modules/`](../modules/); each module has a
**"Hands-on lab"** section that these folders back. Look things *up* in
[`../reference/Technical-Reference-v4.md`](../reference/Technical-Reference-v4.md).

Before the day: **[SETUP.md](SETUP.md)** → `./labs/preflight.sh` until it says `READY`.

## Conventions

- `$WS` = this repository · `$OTEL` = your clone of `<WORKSHOP_ORG>/opentelemetry-demo` · `$REV` = your own `astroshop-reviews` copy. All three come from `labs/.env` (`cp labs/env.example labs/.env; source labs/.env`).
- Every lab lists a **start state** (a checkpoint), numbered steps with **(minutes)**, a copy-pasteable **Success check**, **Stretch** goals, and an **If you're behind** box naming the checkpoint that fast-forwards you.
- Model names in Claude Code files are aliases (`sonnet`, `opus`, `haiku`); SDK code reads the alias `MODEL` and Managed Agents code reads the full model ID `CMA_MODEL` from `labs/.env`.

## Lab index

Times are the *lab* portion of each module (talk/demo/debrief excluded); wall-clock slots are in the [Workshop Guide](../Workshop-Guide-v4.md#agenda).

| Module | Lab | Time box | Start state | You leave with | Lab folder | Instructions |
|---|---|---|---|---|---|---|
| M0 | Preflight, `/status`, `labs/.env`, `checkpoint.sh --list` | 7 min | fresh clones | green preflight, `labs/.env`, CP0 | `labs/` (scripts) | [modules/00 → Hands-on lab](../modules/00-welcome-and-platform-map.md#hands-on-lab) |
| M1 | Drive, remember, plan, undo | 20 min | CP0 | `CLAUDE.md`, `.claude/rules/proto.md`, a reverted feature diff | `labs/m1/` | [modules/01 → Hands-on lab](../modules/01-claude-code-essentials.md#hands-on-lab) |
| M2 | A: settings & permissions (8) · B: hooks (10) · C: MCP (10) | 28 min | CP1 | `.claude/settings.json`, `protect-files.sh` hook, `.mcp.json` + astro-catalog server | `labs/m2/`, `labs/mcp/astro-catalog/` | [modules/02 → Hands-on lab](../modules/02-settings-hooks-and-mcp.md#hands-on-lab) |
| M3 | A: subagents (12) · B: skill (8) · C: plugin + marketplace (17) | 37 min | CP2 | two subagents, `code-reviewer` skill, `codebase-toolkit` plugin v4.0.0, local + org marketplace install | `labs/m3/` | [modules/03 → Hands-on lab](../modules/03-subagents-skills-and-plugins.md#hands-on-lab-37-min) |
| M4 | Path A: headless toolkit **or** Path B: GitHub Action | 12 min | CP3 (+ `$REV`, API key for Path B) | `findings.json` from `claude -p --json-schema`; or a working `@claude` PR workflow | `labs/m4/` | [modules/04 → Hands-on lab](../modules/04-automation-and-scale.md#hands-on-lab-12-min) |
| M5 | Build `bughunter` with the Claude Agent SDK (6 steps) | 38 min | CP3 plugin dir + API key | SDK CLI with plugin reuse, custom tool, hooks, `can_use_tool`, structured output, sessions, cost | `labs/m5-agent-sdk/{python,typescript}/` | [modules/05 → Hands-on lab](../modules/05-claude-agent-sdk.md#hands-on-lab-38-min--build-bughunter) |
| M6 | Deploy the toolkit as a Managed Agent (6 steps) | 28 min | API key in an org with Managed Agents | environment + agent + session, streamed events, tool confirmation, custom tool round-trip, `bug-report.md` | `labs/m6-managed-agents/{python,typescript,curl}/` | [modules/06 → Hands-on lab](../modules/06-claude-managed-agents.md#hands-on-lab) |
| M7 | Step 0 (before Break 2) + triage, patch, change-scan, security-guidance, CI gate | 2 + 27 min | `$REV`, plugins pre-installed | Claude Security report, applied verified patch, custom guidance rules, security-review PR gate, hardened settings | `labs/m7-security/` (+ `$REV/.workshop/`) | [modules/07 → Hands-on lab](../modules/07-securing-agentic-development.md#hands-on-lab-27-min--step-0-before-the-break) |
| M8 | (no lab) cleanup + feedback | — | — | `./labs/cleanup.sh` run, feedback sent | `labs/` | [modules/08](../modules/08-wrap-up.md#hands-on-lab-take-home) |

## Checkpoints

`./labs/checkpoint.sh CPn` materialises the end state of module *n* (cumulatively, CP1→CPn) without
overwriting your own work unless you add `--force`. Content contract and per-checkpoint file lists:
[`checkpoints/README.md`](checkpoints/README.md).

| Checkpoint | After module | Gives you | Typical use |
|---|---|---|---|
| CP0 | M0 | sanity check only (`$OTEL` is a clone, `labs/.env` exists) | M0 step 4 |
| CP1 | M1 | `CLAUDE.md`, `.claude/rules/proto.md` | late arrival |
| CP2 | M2 | project settings + hook + `.mcp.json`; MCP server deps | hook would not fire, MCP would not connect |
| CP3 | M3 | `codebase-toolkit` plugin + marketplaces; org plugin at user scope | **everyone's safety net for the afternoon** |
| CP4 | M4 | headless outputs; Action workflows in `$REV` | skipped Path B |
| CP5 | M5 | SDK solution over starter (`--lang python\|typescript`) | stuck past step 2 |
| CP6 | M6 | Managed Agents solution over starter; runs steps 1–3 with `--yes` | no time to type; org gating |
| CP7 | M7 | sample scan results, F1 patch branch, guidance config, CI workflow, hardened settings (`--force`) | scan did not finish over the break |

```bash
./labs/checkpoint.sh --list            # see status ("ready"/"pending") of each checkpoint's content
./labs/checkpoint.sh CP3 --dry-run     # preview
./labs/checkpoint.sh CP3               # apply CP1..CP3
./labs/checkpoint.sh CP5 --only --lang typescript
```

## Folder map

```
labs/
  README.md            this file
  SETUP.md             participant prerequisites (accounts, installs, repos, proxy notes)
  env.example          copy to labs/.env (git-ignored) and fill in
  preflight.sh         environment check; PASS/WARN/FAIL table + one-line summary  (--help)
  checkpoint.sh        CP0–CP7 fast-forward  (--list, --dry-run, --force, --only, --lang)
  cleanup.sh           end-of-day: archive Managed Agents resources, list Console items to delete   [M8]
  checkpoints/         content for each checkpoint + README with the directory contract
  shared/              findings.schema.json, tickets.py|ts (create_ticket handler), prompts/bug_hunter_system.md
  mcp/astro-catalog/   local stdio MCP server used from M2 onward (node, --selftest)
  m1/                  rules/proto.md, prompts.md
  m2/                  settings.project.json, hooks/protect-files.sh|.ps1, hooks/examples/
  m3/                  agents/, skills/code-reviewer/, plugin/, marketplace/, dedupe.sh
  m4/                  bug-hunt.sh (reads shared/findings.schema.json), stream-filter.jq, streamjson-driver.py, github/*.yml, expected-output/
  m5-agent-sdk/        python/{starter,solution}, typescript/{starter,solution}, Dockerfile.hardened, expected-output/
  m6-managed-agents/   python/{starter,solution}, typescript/, curl/steps.sh, webhook_receiver.py, snippets/, expected-output/
  m7-security/         SOLUTIONS.md, settings.hardened.json, compare_findings.py, hooks/, expected-output/
```

Folders other than `checkpoints/`, the two scripts, `env.example`, `SETUP.md` and this README are
authored alongside their modules; if one is missing in your checkout, pull the latest workshop repo.
