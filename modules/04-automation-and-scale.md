# Module 4 — Automation & scale: headless, GitHub Actions, cloud sessions, orchestration

> **Time box:** 11:45–12:15 (30 min) · **Format:** talk/demo 15 · lab 12 · debrief 3 · **Checkpoint in:** CP3 · **Checkpoint out:** CP4

Conventions: `$WS` = your clone of `<WORKSHOP_ORG>/claude-builders-workshop`, `$OTEL` = your clone of `<WORKSHOP_ORG>/opentelemetry-demo`, `$REV` = your own copy of the `<WORKSHOP_ORG>/astroshop-reviews` template. Model names use aliases (`sonnet`, `opus`, `haiku`); scripts read `MODEL` from `labs/.env`. Anything badged **(research preview, Aug 2026)**, **(experimental)** or **(beta)** is listed in reference §O "Volatile facts" and must be re-verified before each delivery.

## Why this matters

Everything you built this morning — `CLAUDE.md`, project settings, hooks, the `astro-catalog` MCP server, two subagents, a skill, and the `codebase-toolkit` plugin — has so far needed a human at a prompt. Real teams need the same capability to run **without a terminal open**: as a step in a shell script, as a PR reviewer in CI, as a scheduled job that runs while laptops are closed, or as twenty parallel workers chewing through a migration. Claude Code ships all of those shapes with the *same* engine and the *same* on-disk configuration, so the question is never "can it?" but "which shape fits this job, and how do I keep it on a leash when nobody is watching?" This module gives you the shapes, the leash (`--allowedTools`, `dontAsk`, budgets, `--bare`), and a decision table you will extend in Modules 5 and 6 when the agent moves into your own process (Agent SDK) and onto managed infrastructure (Claude Managed Agents).

## Learning objectives

By 12:15 a participant can:

1. Run Claude Code non-interactively with `claude -p`: choose `--output-format text|json|stream-json`, get schema-validated output with `--json-schema`, drive multi-turn runs with `--continue` / `--resume <session-id>` (and `--input-format stream-json`), cap work with `--max-turns` / `--max-budget-usd`, lock permissions with `--allowedTools` / `--disallowedTools` / `--permission-mode dontAsk`, and know `--bare`, `--agent`, `--append-system-prompt`, exit codes and CI auth (`ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`).
2. State the headless trust caveat — `-p` has no workspace-trust dialog, so project hooks and `.mcp.json` servers load — and mitigate it with `--bare` or `--setting-sources user` on untrusted checkouts.
3. Set up `anthropics/claude-code-action@v1` in both modes (interactive `@claude` mentions; automation with `prompt:`), via `/install-github-app` or manually, with least-privilege `permissions:` and secrets; know that managed **Code Review** (Team/Enterprise) and a GitLab CI/CD integration exist, and that the security-review Action is Module 7's PR gate.
4. Choose between local scale-out options — background sessions (`claude --bg`, `/background`, agent view `claude agents`), parallel subagents, dynamic workflows / `ultracode` (`/workflows`), agent teams, cross-session messaging (`--name`, `/list-agents`, `@session-name`), `/loop`, `/goal` — and cloud options — Claude Code on the web (`--cloud`, `--teleport`, setup scripts / `SessionStart` hooks), Routines (`/schedule`: schedule, API and GitHub triggers), Remote Control, Desktop parallel sessions — with honest maturity labels.
5. Reuse the morning's toolkit headlessly: a namespaced plugin skill inside a `-p` prompt, `@agent-codebase-toolkit:bug-hunter`, and `claude --agent codebase-toolkit:bug-hunter -p …`.

**Prerequisite state:** CP3 — `codebase-toolkit` installed at **user** scope (so `-p` runs in any directory see it). Path B additionally needs `$REV` created from the template and an `ANTHROPIC_API_KEY` (Console). No key? Do Path A, pair for Path B, or watch the instructor's PR and read `labs/m4/expected-output/`.

## Concepts (instructor talk track)

### 4.1 One engine, many triggers

Draw this once; every later section fills in a row.

| Shape | Who starts it | Where the loop runs | Auth it uses | Config it sees | Human in the loop? |
|---|---|---|---|---|---|
| Interactive `claude` (M1–M3) | you, at a prompt | your machine | subscription login or API key | user + project + local + plugins | every turn |
| Background session `claude --bg` / agent view **(research preview, Aug 2026)** | you, then walk away | your machine (own git worktree) | same as interactive | same as interactive | when it needs input |
| Print mode `claude -p` | a script / cron / CI step | wherever the script runs | `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, or cloud-provider env | user + project + local + plugins (**no trust dialog**) — or nothing with `--bare` | none unless you wire one |
| GitHub Action `claude-code-action@v1` | a GitHub event or `@claude` comment | a GitHub runner | repo/org secret or OIDC workload identity | the checked-out repo (`CLAUDE.md`, `.claude/`), plus `plugins:` input | via PR/issue comments |
| Cloud session (Claude Code on the web, `claude --cloud`) | you (web, mobile, Desktop, CLI) | Anthropic-managed VM (or a self-hosted environment) | claude.ai subscription | **repo-committed** config only + cloud environment | steer from browser/phone; `--teleport` home |
| Routine **(research preview, Aug 2026)** | schedule / API call / GitHub event | cloud VM | claude.ai subscription | repo-committed config + routine prompt + connectors | none (autonomous run) |
| Agent SDK (M5) | your program | your process / container | API key or cloud provider | whatever `setting_sources` / `plugins` you pass | your code decides (`can_use_tool`) |
| Claude Managed Agents (M6) **(beta)** | your API call | Anthropic-managed session container | API key | the Agent definition (system prompt, tools, skills, MCP) | `permission_policy` + confirmations |

Say out loud: the first six rows are **Claude Code** (developer tooling, subscription or key); the last two are **platform products** you build *your* software on. Same ideas, different owner of the loop and the sandbox.

### 4.2 Print mode (`claude -p`) — the ten flags that matter

`-p` / `--print` runs one task and exits. Stdin is accepted (cap 10 MB), so `cat log.txt | claude -p "explain"` works. The flags below are the ones we type today; the full table is reference §I.1.

| Concern | Flags | Notes |
|---|---|---|
| Output | `--output-format text` (default) · `json` · `stream-json` | `json` = one result object; `stream-json` = newline-delimited events, needs `--verbose`; add `--include-partial-messages` for token deltas, `--include-hook-events` for hook lifecycle |
| Structured output | `--json-schema '<JSON Schema>'` | validated object lands in `.structured_output`; an invalid *schema* is an error exit before the run |
| Input | `--input-format stream-json` | stdin takes newline-delimited user messages (Agent SDK user-message shape); pair with `--output-format stream-json`, optionally `--replay-user-messages` |
| Multi-turn | `--continue` / `-c` · `--resume <id-or-name>` / `-r` · `--session-id <uuid>` · `--fork-session` · `--name` | `session_id` is in every JSON result; `--resume` by ID works from any directory; `--no-session-persistence` for throwaway CI runs |
| Permissions | `--allowedTools "Read,Grep,Bash(git diff *)"` · `--disallowedTools "Edit"` · `--tools "Bash,Read"` · `--permission-mode default|acceptEdits|auto|dontAsk|plan|bypassPermissions` · `--permission-prompt-tool <mcp tool>` | `-p` starts in `default` on every plan: **anything that would prompt is denied**. `dontAsk` = deny everything not explicitly allowed (locked-down CI). `--tools` removes tools from the menu; `--allowedTools` pre-approves them |
| Limits | `--max-turns N` · `--max-budget-usd 1.00` · `--model` · `--effort` · `--fallback-model sonnet,haiku` | hitting turns/budget ends the run with an error subtype (below); subagent spend counts toward the budget |
| Prompting | `--append-system-prompt "…"` / `--append-system-prompt-file` · `--system-prompt` (replace) · `--agent <name>` · `--agents '<json>'` | append keeps Claude Code's tool guidance; replace means you own it. `--agent codebase-toolkit:bug-hunter` runs the whole session as your plugin agent |
| Context loading | `--bare` · `--setting-sources user,project,local` · `--settings <file-or-json>` · `--mcp-config` / `--strict-mcp-config` · `--plugin-dir <path>` | `--bare` skips hooks, skills, plugins, MCP, auto memory and `CLAUDE.md`, and reads only `ANTHROPIC_API_KEY` (never the keychain) — then add back exactly what you need |
| Observability | `--verbose` · `--debug-file <path>` | in stream-json, `system/init` lists `model`, `tools`, `plugins[]`, `plugin_errors[]`, `mcp_servers[]` — fail CI if your plugin didn't load |
| Auth (env, not flags) | `ANTHROPIC_API_KEY` · `CLAUDE_CODE_OAUTH_TOKEN` · `CLAUDE_CODE_USE_BEDROCK=1` / `CLAUDE_CODE_USE_VERTEX=1` / Foundry equivalents | `claude setup-token` prints a one-year subscription token for CI (Pro/Max/Team/Enterprise; inference only; not read in `--bare`) |

**The result object** (`--output-format json`, and the last line of `stream-json`). Fields you will script against:

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "session_id": "3f6b1c1e-…",
  "num_turns": 7,
  "duration_ms": 41210,
  "result": "…final assistant text (success only)…",
  "structured_output": { "findings": [ … ] },
  "total_cost_usd": 0.0412,
  "usage": { "input_tokens": …, "output_tokens": …, "cache_read_input_tokens": … },
  "modelUsage": { "<model-id>": { "costUSD": …, … } },
  "permission_denials": [],
  "terminal_reason": "completed"
}
```

`subtype` is one of `success`, `error_max_turns`, `error_max_budget_usd`, `error_during_execution`, `error_max_structured_output_retries`. `total_cost_usd` and `modelUsage` are client-side estimates and include subagents. `permission_denials` is the first place to look when a `dontAsk` run "did nothing".

**Stream events** (`--output-format stream-json --verbose`): `system` (`init`, `api_retry`, `plugin_install`), `user`, `assistant` (content blocks incl. `tool_use`), `stream_event` (deltas, with `--include-partial-messages`), hook events (with `--include-hook-events`), and one final `result`. Subagent traffic carries a non-null `parent_tool_use_id`; add `--forward-subagent-text` to also see subagent prose.

**Exit codes:** `0` success; non-zero on failure (bad flags are reported on stderr before the run; in-run failures such as missing auth, max-turns, invalid schema come back as the result with `is_error: true` and a non-zero exit). SIGTERM aborts the turn, runs `SessionEnd` hooks and exits `143`. In CI, test **both** the exit code and `.is_error`/`.subtype`.

**Skills and agents in `-p`:** a `/skill-name` inside the prompt expands exactly as it does interactively, so `claude -p "/codebase-toolkit:code-reviewer src/adservice security"` works; `@agent-codebase-toolkit:bug-hunter …` guarantees delegation to your plugin subagent; `claude --agent codebase-toolkit:bug-hunter -p "analyze src/adservice"` makes the agent's system prompt *the* system prompt for the run. Terminal-only built-ins (`/login`, pickers) are unavailable; `/model sonnet`, `/effort high`, `/mcp` accept arguments or print text.

> [!WARNING] **Headless trust caveat (security thread).** Interactive Claude Code asks you to trust a folder before it will run that folder's hooks or connect its `.mcp.json` servers. `claude -p` has no dialog: a run inside a freshly cloned, never-trusted repo **will execute that repo's project hooks and start its project MCP servers**. On checkouts you don't control (CI on fork PRs, triage bots, bulk repo sweeps) use `claude --bare -p …` and add back only what you need (`--append-system-prompt-file`, `--settings`, `--mcp-config`, `--plugin-dir`), or at minimum `--setting-sources user` / `--settings '{"disableAllHooks": true}'`. The docs note `--bare` is intended to become the default for `-p` in a future release — write scripts that opt in explicitly today.

### 4.3 CI usage patterns

Four shapes cover most pipelines (all from the public headless docs; adapt the prompt):

```bash
# 1. Pipe in, text out — explain a failing build step
cat build-error.txt | claude -p 'concisely explain the root cause of this build error' > explanation.txt

# 2. Diff in, JSON out — gate on a field
gh pr diff "$PR" | claude -p \
  --append-system-prompt "You are a security engineer. Review for vulnerabilities." \
  --output-format json --max-turns 3 | tee review.json
jq -e '.is_error == false' review.json >/dev/null || exit 1

# 3. Locked-down write access — exactly these git commands, nothing else
claude -p "Look at my staged changes and create an appropriate commit" \
  --allowedTools "Bash(git diff *),Bash(git log *),Bash(git status *),Bash(git commit *)"

# 4. Two-step job sharing one session (cache-warm follow-up)
sid=$(claude -p "Review this codebase for performance issues" --output-format json | jq -r .session_id)
claude -p --resume "$sid" "Now focus on the database queries" --output-format json | jq -r .result
```

`package.json` one-liner from the docs: `"lint:claude": "git diff main | claude -p \"you are a typo linter. for each typo in this diff, report filename:line on one line and the issue on the next. return nothing else.\""`.

Rules of thumb for unattended runs: (1) always set `--max-turns` **and** `--max-budget-usd`; (2) prefer `--permission-mode dontAsk` + an explicit `--allowedTools` list over `acceptEdits`, and never `bypassPermissions` on a shared runner; (3) mind the space in Bash rules — `Bash(git diff *)` matches `git diff …` only, `Bash(git diff*)` would also match `git diff-index`; (4) emit `json`, archive it as a build artifact, and grep `permission_denials`/`plugin_errors` when behaviour surprises you; (5) `--exclude-dynamic-system-prompt-sections` improves prompt-cache reuse across ephemeral runners.

### 4.4 GitHub: `anthropics/claude-code-action@v1`

**What it is.** A GitHub Action (built on the Agent SDK) that runs Claude Code inside your workflow. Two modes, auto-detected: **interactive** — no `prompt:` input; the job waits for the `trigger_phrase` (default `@claude`) in an issue/PR comment, review, or issue body, then works and keeps one sticky comment updated; **automation** — `prompt:` set; runs immediately on any event (`pull_request`, `schedule`, `workflow_dispatch` …) and writes to the run log unless the prompt/tools post to the PR. `CLAUDE.md` and the repo's `.claude/` are honoured because the repo is checked out.

**Setup, two ways.**
- *Quick:* `gh auth login`, open `claude` in the repo, run **`/install-github-app`**. It installs the Claude GitHub App, stores `ANTHROPIC_API_KEY` (or `CLAUDE_CODE_OAUTH_TOKEN` for subscription auth) as a repo secret, and opens a PR adding `claude.yml` (and optionally a review workflow). github.com only. Re-run it later to update the workflow to the latest template.
- *Manual (what the lab does, so you see every line):* install the app from `https://github.com/apps/claude` (or skip the app and pass your own `github_token`), add the secret, commit the workflow file.
- *Org rollout:* org-level secret, or **OIDC workload identity federation** to a Console service account (`anthropic_federation_rule_id`, `anthropic_organization_id`, optional `anthropic_workspace_id`; requires `id-token: write`) so no static key lives in GitHub. Bedrock / Google Cloud / Microsoft Foundry via `use_bedrock` / `use_vertex` / `use_foundry: "true"` plus that cloud's OIDC login step.

**Interactive workflow** — `labs/m4/github/claude.yml` (docs example, verbatim):

```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
      id-token: write
      actions: read
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 1
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

**Automation workflow** — `labs/m4/github/code-review.yml`: automated PR review through the `code-review` plugin skill (docs example, verbatim; the `claude_args` line must stay so the inline-comment MCP server starts):

```yaml
name: Code Review
on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 1
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          plugin_marketplaces: "https://github.com/anthropics/claude-code.git"
          plugins: "code-review@claude-code-plugins"
          prompt: "/code-review:code-review --comment ${{ github.repository }}/pull/${{ github.event.pull_request.number }}"
          claude_args: '--allowedTools "mcp__github_inline_comment__create_inline_comment"'
```

**Your toolkit in CI.** `prompt:` may be any skill: `/skill` from the repo's `.claude/skills/`, or `/plugin:skill` when you pass `plugin_marketplaces` + `plugins`. So the morning's work runs in Actions with two inputs — `plugin_marketplaces: "https://github.com/<WORKSHOP_ORG>/claude-marketplace.git"`, `plugins: "codebase-toolkit@<WORKSHOP_ORG>-marketplace"`, `prompt: "/codebase-toolkit:code-reviewer app/ security"` (stretch goal c).

**Inputs you will actually touch** (full table reference §I.2): `prompt`, `claude_args` (any CLI flags: `--max-turns 5 --model sonnet --allowedTools …`), `anthropic_api_key` | `claude_code_oauth_token`, `github_token` (omit to act as the Claude app; using `secrets.GITHUB_TOKEN` means Claude's own commits won't re-trigger CI), `plugin_marketplaces`, `plugins`, `settings` (JSON or path — this is where hooks/permissions go), `trigger_phrase`, `use_sticky_comment`, `track_progress`, `allowed_bots`, `allowed_non_write_users`, `use_commit_signing`. Migrating from `@beta`: `direct_prompt`→`prompt`, `mode` removed, `max_turns`/`model`/`allowed_tools`/`mcp_config`→`claude_args`, `custom_instructions`→`--append-system-prompt`, `claude_env`→`settings`.

**Security checklist for the Action** (say it, it's short): least `permissions:` per job; secrets never in YAML; the commenter must have write access (that is the default gate — don't loosen `allowed_non_write_users` casually); fork PRs on public repos don't receive secrets, by design; cap `--max-turns` and set a job `timeout-minutes`; review Claude's commits like anyone else's; prefer OIDC over long-lived keys at org scale.

**Neighbours you should know exist (no lab today):**
- **Code Review** — managed PR reviews for **Team and Enterprise** **(research preview, Aug 2026)**: enabled by an Owner at `claude.ai/admin-settings/claude-code`, runs a fleet of agents on Anthropic infrastructure with full-repo context, posts inline comments plus a summary and a neutral **Claude Code Review** check; per-repo behaviour *once / after every push / manual*; manual trigger `@claude review` in a PR comment; tuned by `CLAUDE.md` and a root `REVIEW.md`; billed in usage credits per review. Local sibling: the bundled `/code-review` skill (alias `/review`), which also runs in `-p`.
- **GitLab CI/CD** **(beta, maintained by GitLab)** — same idea with `claude -p` in a job image; masked `ANTHROPIC_API_KEY`, Bedrock/Google Cloud via OIDC; snippet in reference §I.2.
- **`anthropics/claude-code-security-review`** — the security-focused PR gate. We wire it in **Module 7 step 5**; park it until then.
- **GitHub Enterprise Server** — Team/Enterprise Owners connect a GHES instance once in admin settings; Actions there are manual-setup only.

### 4.5 Scaling out on your machine

You already ran parallel subagents in M3. Above that sit four more local layers. Be honest about maturity when you present them.

**Background sessions and agent view** — **(research preview, Aug 2026)**.
```bash
claude --bg "Generate a dependency report for every service in src/ and open a draft PR"   # returns immediately
#  backgrounded · 7c5dcf5d · dependency-report
claude agents            # full-screen agent view: Working / Needs input / Ready for review / Completed, across all projects
claude attach 7c5dcf5d   # open it here;  claude logs <id> · claude stop <id> · claude respawn <id> · claude rm <id>
```
Inside a session, `/background` (alias `/bg`) frees the terminal; `←` on an empty prompt backgrounds and opens agent view. Before a background session edits files it moves into its own git worktree under `.claude/worktrees/`, and on finish it commits, pushes a branch (never `main`) and opens a **draft PR** unless told otherwise. A per-user supervisor keeps sessions alive across sleep (`claude daemon status`). Options ride along: `claude --bg --agent codebase-toolkit:bug-hunter --permission-mode plan "…"`. Costs and rate limits multiply per session; sessions are local, not cloud. Turn off org-wide with `disableAgentView`.

**Parallel subagents (recap) and `/batch`.** Subagents run in the background by default, up to 20 concurrently per session, nested up to 3 layers; results return as summaries so the main context stays small. `/batch <instruction>` is a bundled skill that splits a large mechanical change into 5–30 units, one worktree-isolated background subagent per unit, each opening its own PR.

**Dynamic workflows / `ultracode`** — **(research preview, Aug 2026; all paid plans, Pro must enable "Dynamic workflows" in `/config`; admins can disable)**. Instead of Claude juggling agents turn by turn, Claude *writes a small JavaScript orchestration script* and a runtime executes it in the background: fan-out, pipelines, verification passes, loops — deterministic control flow with only the final result entering your context. Trigger it by typing the keyword **`ultracode`** in a prompt (`ultracode: audit every Dockerfile under src/ for unpinned base images`) or by asking for "a workflow"; `/effort ultracode` (or `claude --effort ultracode`) makes it the default for every substantive task in the session. You approve the script (`View raw script`, `Ctrl+G`), then watch `/workflows` (drill in, `p` pause, `x` stop, `r` restart an agent, `s` save). Saved workflows live in `.claude/workflows/` (project) or `~/.claude/workflows/` (personal), ship in plugins under `workflows/`, and become slash commands that take `args`. Limits: up to 16 concurrent agents, 1,000 agents per run, no mid-run user input, no filesystem/shell from the script itself (agents do the work), workflow subagents run in `acceptEdits` with your allow-list. `/deep-research` is the bundled example. This is the machinery the Claude Security plugin uses in Module 7. Canonical script shape (docs):

```javascript
export const meta = {
  name: 'audit-routes',
  description: 'Audit every route handler for missing auth checks',
}

const found = await agent('List every .ts file under src/routes/.', {
  schema: { type: 'object', required: ['files'], properties: { files: { type: 'array', items: { type: 'string' } } } },
})

const audits = await pipeline(found.files, file =>
  agent(`Audit ${file} for missing authentication checks.`, { label: file }),
)

return audits.filter(Boolean)
```

**Agent teams** — **(experimental, disabled by default)**. `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`; then in natural language "spawn three teammates …". Teammates are separate Claude Code instances with their own context that share a task list and message each other and the lead; permission prompts bubble to your terminal. Interactive only (not `-p`/SDK), 3–5 teammates is the guidance, token use is significantly higher. One row in the matrix; no demo today.

**Cross-session messaging** — **(v2.1.224+; macOS/Linux incl. WSL 2; Anthropic API only — not Bedrock, Vertex, Foundry or Claude Platform on AWS; on by default)**. Your *own* independent sessions can list and message each other: on the same machine over a per-session socket restricted to your OS user (never via Anthropic servers), and — while connected to Remote Control — your sessions on other machines and on the web too. Name sessions so they are worth addressing (`claude --name api-worker`, `/rename`), check who is reachable with `/list-agents` (alias `/peers`; `/status` gains a `Peer address` row), then just say it: `Let @api-worker know the schema migration finished` (`@`-mention typeahead, v2.1.232+) or "ask the session in my other terminal whether the migration finished". Claude makes the `ListAgents` / `SendMessage` calls itself, may send unprompted when a change here breaks what another session is building on, and can ask a local session for a one-shot "tell me when you next go idle" notice (`notify_when_idle`, v2.1.236+). The trust model is the part to teach: a message is plain text one Claude wrote — never history or files — and the receiver is told it came from *another session, not from you*, so it cannot approve a permission prompt or change settings/`CLAUDE.md` on a peer's say-so, slash commands in it stay inert text, and the receiver's own permission rules still apply. `crossSessionInbound` (`accept` / `hold` / `refuse`, also a `/config` row) sets inbound policy; unset, a session that prompts for permissions delivers peer messages (holding only those from a bypass-permissions sender) while a bypass-permissions session holds each one behind an approval dialog unless the sender bypasses too. `claude -p` workers have an inbox too (`--bare` does not). Reach for it when two sessions *you* started and steer — two worktrees, or a long migration reporting back to the terminal you're watching — need to hand off a finding; fanning one job out is still subagents / `/batch` / workflows, and a team Claude spawns and supervises is agent teams.

**`/loop` and `/goal`** (both work with everything above).
- `/loop 10m check whether the canary deploy is healthy` re-runs a prompt or skill on an interval inside the open session (`/loop` with no interval lets Claude self-pace; bare `/loop` runs a maintenance prompt or your `.claude/loop.md`); tasks expire after 7 days; alias `/proactive`.
- `/goal all tests in src/currencyservice pass and go vet is clean — or stop after 20 turns` sets a completion condition that a small evaluator model checks after every turn; Claude keeps taking turns until *Met* / *Impossible* / `/goal clear`. It does not change the permission mode (pair with auto mode for unattended runs) and it works in `-p`: `claude -p "/goal CHANGELOG.md has an entry for every PR merged this week" --output-format stream-json --verbose`.

**Desktop app parallel sessions.** In Claude Desktop's **Code** tab every new session in a git repo (`Cmd/Ctrl+N`) automatically gets its own worktree, sessions can be Local / Cloud / SSH / WSL, and a *Continue in → Claude Code on the web* menu pushes a local session to the cloud. Same engine, GUI affordances; not scriptable (`-p`, `dontAsk` and agent teams are CLI-only).

### 4.6 Scaling out in the cloud

**Claude Code on the web / cloud sessions** — available to Pro, Max, Team and Enterprise seats with Claude Code (docs still carry research-preview wording in places — **[verify-on-day]**); requires claude.ai login (not Console key / Bedrock / Vertex / Foundry) and, on Team/Enterprise, that the org allows remote sessions. Each session is an isolated Anthropic-managed Ubuntu VM (≈4 vCPU/16 GB, common toolchains preinstalled) that clones your GitHub repo, works on a branch, and lets you review the diff and **Create PR** from `claude.ai/code`, the mobile app, Desktop, or the CLI. No compute charge; usage counts against your plan like any session.

```bash
claude --cloud "Add table-driven tests for src/currencyservice"     # new cloud session from the current repo/branch (push first)
claude --cloud "Fix flaky test"; claude --cloud "Update docs"       # each call = its own parallel session
claude -p "also update the README" --cloud <session-id-or-url>      # queue a follow-up into an existing cloud session, exit
claude --teleport            # picker: pull a cloud session into this terminal (clean tree, same repo, branch pushed)
/teleport   (alias /tp)      # same, from inside a session;  /tasks lists your cloud sessions too
/web-setup                   # one-time: sync your gh token and create the Default cloud environment
/remote-env                  # choose the default cloud environment for --cloud
```
`--remote` is a deprecated alias of `--cloud`. What a cloud session sees: **only what is committed** — repo `CLAUDE.md`, `.claude/rules|settings.json|agents|skills`, `.mcp.json`, and plugins declared in the repo's `enabledPlugins` — plus organization server-managed settings. Your `~/.claude/*`, user-scope MCP servers and user-installed plugins do **not** travel; that is the practical reason M3 taught `enabledPlugins` + `extraKnownMarketplaces` in project settings. Cloud environments (picker above the prompt box) hold network level (*None / Trusted* default allow-list */ Full / Custom*), `.env`-style variables (not a secrets store), and a **setup script** (root, cached ~7 days) for VM provisioning; per-session project setup belongs in a `SessionStart` hook that checks `CLAUDE_CODE_REMOTE=true` (stretch goal e). Cloud sessions offer Accept-edits / Plan / Auto modes, never Bypass. `/autofix-pr` spawns a cloud session that watches the current branch's PR and pushes fixes when CI fails or reviewers comment (needs the Claude GitHub App on the repo).

**Routines** — **(research preview, Aug 2026; Pro/Max/Team/Enterprise with web enabled; Owners can disable)**. A routine = saved prompt + repos + cloud environment + connectors + one or more **triggers**, running autonomously in a cloud session under *your* account and pushing to `claude/`-prefixed branches.
- **Schedule** — hourly/daily/weekdays/weekly presets, custom cron via `/schedule update` (minimum interval 1 h), or a one-off timestamp.
- **API** — per-routine URL + bearer token generated on the web; fire it from anywhere:
  ```bash
  curl -X POST https://api.anthropic.com/v1/claude_code/routines/<trigger-id>/fire \
    -H "Authorization: Bearer <routine-token>" \
    -H "anthropic-beta: experimental-cc-routine-2026-04-01" \
    -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -d '{"text": "Sentry alert SEN-4521 fired in prod. Stack trace attached."}'
  # -> {"type":"routine_fire","claude_code_session_id":"session_…","claude_code_session_url":"https://claude.ai/code/session_…"}
  ```
  The `text` arrives wrapped as untrusted payload; the routine prompt must say what to do with it. (Beta header value is volatile — reference §O.)
- **GitHub event** — pull-request and release events with field filters (author, base branch, labels, draft, regex…); needs the Claude GitHub App on the repo.
Create from `claude.ai/code/routines`, Desktop → Routines → Cloud, or the CLI: `/schedule daily dependency-audit at 07:00 on weekdays` (alias `/routines`; `/schedule list | update | run`). `/schedule` is **hidden** when you are authenticated with a Console API key or a cloud provider — expect that in a mixed room. Daily run caps apply per account. Desktop also offers **local** scheduled tasks (machine must be awake) — same Routines page, "Local".

**Remote Control** — **(research preview, Aug 2026; claude.ai login only; Team/Enterprise Owner must enable)**. The inverse of the web: the session keeps running **on your machine** with your files, MCP servers and tools, and you drive it from `claude.ai/code` or the Claude mobile app. `claude --remote-control` (alias `--rc`) or `/remote-control` in a session; `claude remote-control` runs a headless server that can spawn sessions per worktree. Outbound HTTPS only; the transcript is relayed and stored via Anthropic servers while connected; remote clients can pick Manual / Accept edits / Plan (not Auto/Bypass) and answer permission prompts from the phone.

**Self-hosted environments** — **(public beta; Team/Enterprise)**: route cloud sessions, `--cloud` and routines onto your own runners (`claude self-hosted-runner setup`, then `claude --cloud "…" --environment ccpool_…`). Reference §I.3 and Module 6's "self-hosted" contrast.

### 4.7 When to use what

| You want… | Reach for | Why / watch out |
|---|---|---|
| To iterate with judgement calls every few minutes | interactive `claude` (plan mode, `/rewind`) | cheapest feedback loop |
| A long task off your terminal but on your machine and config | `claude --bg` + `claude agents` **(research preview)** | own worktree, draft PR; local rate limits multiply |
| Independent chunks of one job, results merged | parallel subagents (M3) or `/batch` for mechanical N-way edits | context isolation; summaries only |
| Dozens–hundreds of units with verify/dedupe stages | dynamic workflow / `ultracode` **(research preview)** | deterministic script, 16 concurrent, resumable, saved as a command |
| Agents that must negotiate with each other | agent teams **(experimental)** | high token cost; interactive only |
| Two of your own sessions / worktrees need to hand off a finding or ask each other something | cross-session messaging (`--name`, `/list-agents`, `@session-name`) | plain text only; the receiver treats it as untrusted (`crossSessionInbound` accept/hold/refuse); other machines need Remote Control on both ends; macOS/Linux, Anthropic API only |
| "Keep going until X is true" | `/goal` (+ auto mode) | evaluator has no tools — state a checkable end state and a turn cap |
| Poll/re-run something while you work | `/loop 5m …` | session-scoped, 7-day expiry |
| A step in a script or pipeline you own | `claude -p` + `--output-format json` + `dontAsk` + budgets (`--bare` on untrusted checkouts) | you own auth, runners, secrets |
| React to GitHub events / `@claude` in PRs | `claude-code-action@v1`; managed **Code Review** on Team/Enterprise | least-privilege `permissions:`; fork PRs get no secrets |
| Work that continues with the laptop shut, from a phone, on repos you haven't cloned | Claude Code on the web / `--cloud`, `--teleport` back | repo-committed config only; subscription auth |
| The same, on a timer / webhook / PR event, no human | Routine **(research preview)** | autonomous; prompt-injection hygiene for API `text` |
| Drive a *local* session from the phone | Remote Control **(research preview)** | machine must stay on |
| Claude's agent loop **inside your product or service** | **Agent SDK → Module 5** | API-key auth, your process, `can_use_tool` in code |
| A hosted, versioned agent your backend calls, with managed containers, vaults, schedules | **Claude Managed Agents → Module 6** **(beta)** | metered per session-hour + tokens; not a dev tool |
| Direct model calls, you write the loop | Messages API | full control, most work |

## Live demo script

Total 15 min. Keep a terminal in `$OTEL`, a browser tab on the instructor's `astroshop-reviews` fork with PR #1 (`demo/add-export-endpoint`) already open, and the pre-recorded scale-out asciinema ready (FACILITATOR §3, recordings) in case the network stalls.

**Beat 1 — Headless toolkit (5 min).**
1. `cat $WS/labs/m4/bug-hunt.sh` — read it aloud; it is eight flags you just explained:
   ```bash
   #!/usr/bin/env bash
   # labs/m4/bug-hunt.sh <service-path>  — run the toolkit's bug-hunter headlessly, emit schema-validated JSON
   set -euo pipefail
   TARGET="${1:?usage: bug-hunt.sh <service-path>}"
   SCHEMA="$(cat "${WS:?export WS}/labs/shared/findings.schema.json")"
   exec claude -p "@agent-codebase-toolkit:bug-hunter Analyze ${TARGET} for bugs. Report every finding with \
   id, title, severity (HIGH|MEDIUM|LOW), file, line, category, description, recommendation, confidence (low|medium|high); \
   set service to ${TARGET} and add a two-sentence summary." \
     --model "${MODEL:-sonnet}" \
     --output-format json \
     --json-schema "$SCHEMA" \
     --allowedTools "Read,Grep,Glob,Agent" \
     --permission-mode dontAsk \
     --max-turns 30 \
     --max-budget-usd 1.00
   ```
2. `mkdir -p reports && $WS/labs/m4/bug-hunt.sh src/paymentservice | tee reports/paymentservice.findings.json | jq '.structured_output.findings[] | {severity,title,file,line}'` then `jq '{subtype, num_turns, total_cost_usd, permission_denials}' reports/paymentservice.findings.json` — point at `structured_output` (schema-shaped, no prose to parse), the cost, and the empty `permission_denials`.
3. Stream variant: `claude -p "@agent-codebase-toolkit:bug-hunter quick pass over src/adservice" --allowedTools "Read,Grep,Glob,Agent" --permission-mode dontAsk --max-turns 12 --output-format stream-json --verbose | jq -r --unbuffered -f $WS/labs/m4/stream-filter.jq` — narrate the `init` line (model, plugins loaded), tool calls scrolling by (indented ones come from the subagent), and the final `done` line.
4. `sid=$(jq -r .session_id reports/paymentservice.findings.json); claude -p --resume "$sid" "Which single finding would you fix first and why? Two sentences."` — same session, warm cache, no re-reading.
5. One slide: `--bare` and the trust caveat (4.2 warning box). Thirty seconds, but say it.

**Beat 2 — GitHub (5 min).**
1. In the browser: `astroshop-reviews` → `.github/workflows/claude.yml` and `code-review.yml` (the two files above). Point at `permissions:` and at `plugins:`/`prompt:` in the review workflow.
2. On PR #1 comment: `@claude explain the export flow added here and suggest one missing test`. Switch to the **Actions** tab — job picked up — back to the PR: the sticky comment appears and updates with a checklist as Claude works. While it runs: mention `/install-github-app` as the 60-second path, OIDC workload identity for orgs, `settings:` input for hooks/permissions in CI, and that the same runner minutes + tokens economics apply.
3. Name-check managed **Code Review** (Team/Enterprise, `@claude review`, `REVIEW.md`), GitLab CI/CD (beta), and "the security-review Action is Module 7".

**Beat 3 — Scale-out tour (5 min, talk over the recording if needed).**
1. `claude --bg --name dockerfile-audit "List every Dockerfile under src/ whose base image is not pinned to a digest; write reports/dockerfiles.md"` → show the four-line receipt → `claude agents` → peek with `Space`, attach with `Enter`, detach with `←`. Label: research preview.
2. In an interactive session: `ultracode: for every service under src/, check its Dockerfile for an unpinned base image and its README for a missing 'How to run tests' section; verify each finding with a second agent; return a table` → approve the script (`View raw script` briefly) → `/workflows` view: phases, agent tree, `s` to save as `/dockerfile-audit`. Label: research preview; 16-concurrent cap; this is what M7's scanner is built on.
3. `claude --cloud "Add a CONTRIBUTING.md section on running the Go services' tests"` → open the printed `claude.ai/code/session_…` URL → show the diff view and **Create PR** button → back in terminal `claude --teleport` picker (don't complete it). Then `/schedule weekdays at 07:00: run /codebase-toolkit:code-reviewer on files changed in the last day and open an issue with HIGH findings` → show the routine page with **Schedule / API / GitHub event** triggers. Labels: web = subscription feature; Routines = research preview; `/schedule` hidden under API-key auth.
4. Twenty seconds on cross-session messaging, still in the interactive session: `/list-agents` — the `dockerfile-audit` background session from step 1 is listed with its working directory (and `/status` now has a `Peer address` row) → type `tell @dockerfile-audit to also record the current digest for each unpinned base image so the fix is copy-paste — and let me know when it goes idle` (pick the session from the `@d…` typeahead) → `claude agents`, peek at `dockerfile-audit`: the message sits in its transcript under *this* session's name. Say: "plain text between my own sessions; the receiver knows it is not me, so it cannot approve anything on my behalf." Label: v2.1.224+, macOS/Linux, Anthropic API only. If the audit already finished, the message simply starts a new turn there — that is the idle case.
5. Ten seconds each: `/goal …` indicator, `/loop 10m …`, agent-teams env flag exists (experimental), Remote Control QR (`/rc`).
6. Close on the §4.7 table: "pick the row, not the shiny thing." Announce: **Path A needs nothing new; Path B needs `$REV` + an API key. Twelve minutes. Go.**

> [!NOTE] Instructor: if Beat 2's Action hasn't finished by the time you reach Beat 3, keep going and flip back when the comment lands — the asynchrony is the point.

## Hands-on lab (12 min)

Pick **Path A** (no GitHub setup, no API key beyond your Claude Code login) or **Path B** (GitHub Action; needs `$REV` and `ANTHROPIC_API_KEY`). Fast finishers do both; both end-states are in CP4.

Start state: CP3. Verify once: `claude plugin list | grep codebase-toolkit` shows it **enabled at user scope**; `echo $WS $OTEL` both set (`source $WS/labs/.env`).

### Path A — Headless toolkit (12 min)

1. **(4 min) Run the script, read the JSON.**
   ```bash
   cd $OTEL && mkdir -p reports
   $WS/labs/m4/bug-hunt.sh src/adservice > reports/adservice.findings.json
   jq '.subtype, .total_cost_usd, (.structured_output.findings | length)' reports/adservice.findings.json
   jq -r '.structured_output.findings[] | "\(.severity)\t\(.file):\(.line)\t\(.title)"' reports/adservice.findings.json
   ```
   Expect `"success"`, a cost well under the $1 cap, and a non-zero finding count. If `subtype` is `error_max_turns`, open the script and raise `--max-turns` (or narrow the path to one sub-package) — tuning the caps *is* the lesson.

2. **(4 min) Watch it work: stream-json.** Copy the script to `reports/bug-hunt-stream.sh` and change three things: `--output-format stream-json`, add `--verbose --include-partial-messages`, drop `--json-schema "$SCHEMA"`. Pipe through the provided filter:
   ```bash
   bash reports/bug-hunt-stream.sh src/adservice | jq -r --unbuffered -f $WS/labs/m4/stream-filter.jq
   ```
   `labs/m4/stream-filter.jq` is five lines — read it so you can write your own:
   ```jq
   ( select(.type=="system" and .subtype=="init")
       | "init  model=\(.model)  plugins=\([.plugins[]?.name] | join(","))" ),
   ( select(.type=="assistant") | (if .parent_tool_use_id then "  sub " else "tool  " end) as $p
       | .message.content[]? | select(.type=="tool_use") | "\($p)\(.name)  \(.input | tostring | .[0:70])" ),
   ( select(.type=="result") | "done  \(.subtype)  turns=\(.num_turns)  cost=$\(.total_cost_usd)" )
   ```
   You should see `init … plugins=codebase-toolkit`, an `Agent` call, indented `Read`/`Grep`/`Glob` calls from the bug-hunter subagent, then `done success …`.

3. **(4 min) Two turns, one session.**
   ```bash
   sid=$(claude -p "List the services under src/ that have no README.md. Names only, one per line." \
           --allowedTools "Read,Glob,Grep" --permission-mode dontAsk --output-format json | tee reports/readmes.json | jq -r .session_id)
   jq -r .result reports/readmes.json
   claude -p --resume "$sid" "Write a concise README.md for the first service in that list, based on its source. Create the file." \
     --permission-mode acceptEdits --allowedTools "Read,Write,Glob,Grep" --max-turns 15 --output-format json \
     | jq '{subtype, total_cost_usd, cache_read: .usage.cache_read_input_tokens}'
   ```
   Note the `cache_read` tokens on the second call — that is the resumed context being reused, not re-read.

**Success check (Path A):**
```bash
git -C $OTEL status --porcelain | grep -E '^\?\? src/[^/]+/README.md'        # a new README exists
jq .structured_output reports/adservice.findings.json > reports/adservice.structured.json
npx -y ajv-cli validate -s $WS/labs/shared/findings.schema.json -d reports/adservice.structured.json   # -> "... valid"
```

### Path B — GitHub Action (12 min)

1. **(3 min) Secret.** In `$REV` (your copy of the template, `origin` = your account):
   ```bash
   cd $REV && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY" && gh secret list
   ```
   (UI route: repo → Settings → Secrets and variables → Actions → New repository secret.) If the instructor says your org allows the GitHub App, `claude` → `/install-github-app` does this step *and* the next; choose "API key", select only `claude.yml`, merge its PR, then still copy `code-review.yml` by hand.

2. **(4 min) Workflows.**
   ```bash
   mkdir -p .github/workflows
   cp $WS/labs/m4/github/claude.yml $WS/labs/m4/github/code-review.yml .github/workflows/
   git add .github/workflows/claude.yml .github/workflows/code-review.yml
   git commit -m "Add Claude Code workflows" && git push origin main
   gh workflow list        # both listed
   ```

3. **(5 min) Trigger both modes.** The template ships a branch `demo/add-export-endpoint`.
   ```bash
   gh pr create --head demo/add-export-endpoint --base main \
     --title "Add CSV export endpoint" --body "Adds admin-only POST /exports: writes one product's public reviews to <EXPORT_DIR>/<product_id>.csv and returns its /exports/<name> download path. Please review."
   # automation mode: code-review.yml starts on 'opened' — watch it
   gh run watch $(gh run list --workflow code-review.yml --limit 1 --json databaseId -q '.[0].databaseId')
   # interactive mode: mention @claude (whole word!) in a PR comment
   gh pr comment demo/add-export-endpoint --body "@claude review this for correctness and missing tests; keep it to five bullets"
   gh run list --workflow claude.yml --limit 1
   ```
   Open the PR in the browser (`gh pr view demo/add-export-endpoint --web`): inline review comments from the automation job, and a sticky comment from the `@claude` job that fills in as it works.

**Success check (Path B):** `gh pr view demo/add-export-endpoint --comments | grep -ic claude` is non-zero; `gh run view --log $(gh run list --workflow claude.yml -L1 --json databaseId -q '.[0].databaseId') | grep -i total_cost_usd` shows what the run cost (the Action prints the final result object). Leave the PR **open** — Module 7 reuses this repo and its secret.

**Optional (2 min, subscription login only): kick off something in the cloud** so it is waiting for you after lunch: `cd $OTEL && claude --cloud "Write docs/testing.md explaining how each language's services run their unit tests"` and copy the session URL; or `/schedule in 1 hour, run /codebase-toolkit:code-reviewer src/shippingservice and summarize` (one-off routine). Check it at 12:55.

> [!NOTE] Instructor debrief (3 min): ask one Path A person for their finding count + cost and one Path B person to show the PR. Land two sentences: "`-p` + JSON schema turned your plugin into a Unix tool; the Action turned it into a teammate on every PR. After lunch the same agent moves into your own Python/TypeScript process." Announce **CP4** and lunch; remind Path B people not to delete `$REV`'s secret.

## If you're behind (fast-forward)

```bash
cd $OTEL && $WS/labs/checkpoint.sh CP4
```
CP4 copies `labs/m4/bug-hunt.sh`, `stream-filter.jq`, `streamjson-driver.py` into `$OTEL/reports/m4/`, drops a captured `adservice.findings.json` there, and — if `$REV` exists — copies both workflow files into `$REV/.github/workflows/` (you still need to `git push` and set the secret yourself; the script prints the two commands). Nothing in Modules 5–8 depends on M4 output except that Module 7 step 5 assumes `$REV` has an `ANTHROPIC_API_KEY` secret; if you skipped Path B, you will add it then or watch the instructor's PR. Captured transcripts of every step are in `$WS/labs/m4/expected-output/`.

## Troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| Result `subtype: "success"` but findings are empty / `result` says it couldn't read files | `dontAsk` silently denied a tool. `jq .permission_denials reports/*.json` names it → add to `--allowedTools` (this is why the script lists `Agent` explicitly). |
| `Error: --json-schema is not a valid JSON Schema`, exit ≠ 0 | Shell quoting mangled the schema. Use `--json-schema "$(cat file.json)"` exactly; validate the file with `jq . file.json`. |
| `subtype: "error_max_structured_output_retries"` | The model couldn't satisfy the schema (too strict / contradictory). Loosen (`additionalProperties`, optional fields) or simplify the prompt. |
| `subtype: "error_max_turns"` / `"error_max_budget_usd"` | Caps hit — by design. Raise `--max-turns` / `--max-budget-usd`, or narrow the target path. |
| stream shows `plugins=` empty; `@agent-codebase-toolkit:bug-hunter` treated as plain text | Plugin not visible to this run: installed at *project* scope in another directory, or disabled. `claude plugin list`; reinstall at user scope (`claude plugin install codebase-toolkit@<WORKSHOP_ORG>-marketplace -s user`) or add `--plugin-dir $OTEL/../codebase-toolkit` to the command. `--bare` also drops plugins unless you pass `--plugin-dir`. |
| `-p` hangs ~30 s at start | Waiting for a slow/failing MCP server from `.mcp.json`. Fix the server, or `--strict-mcp-config --mcp-config '{}'` for runs that don't need it. |
| `claude -p` in CI: "Invalid API key" / falls back to nothing | `ANTHROPIC_API_KEY` not exported in that step's env; with `--bare` the keychain/OAuth login is never read — key or `apiKeyHelper` only. |
| `--resume "$sid"`: "No conversation found" | `$sid` empty (first call failed → `jq` printed `null`) or first call used `--no-session-persistence`. `echo $sid`; re-run step. |
| Action never starts on `@claude` comment | Workflow not on the default branch yet; Actions disabled on the repo (Settings → Actions → allow); `@claude` not a whole word (`@claude,` is fine, `/claude` and `@claude-bot` are not); commenter lacks write access; comment was on a fork PR (no secrets by design). |
| Action fails at auth: `id-token` / OIDC error | Job `permissions:` block missing `id-token: write` (needed even with an API key in the v1 examples). Copy the block verbatim. |
| Action fails: secret not found | Name mismatch — workflow expects `ANTHROPIC_API_KEY` exactly; org-level secret not shared with this repo. `gh secret list`. |
| Corporate GitHub org blocks third-party apps / Actions | Use your personal namespace for `$REV` (prereq mail said so); or skip the App and rely on `secrets.GITHUB_TOKEN` via `github_token:` (Claude's commits then won't retrigger CI). |
| `--cloud`: "requires a claude.ai account" / `/schedule` is "Unknown command" | You're authenticated with a Console API key or cloud provider; cloud sessions, Routines and Remote Control need subscription login (`unset ANTHROPIC_API_KEY; claude auth status`). Team/Enterprise: Owner may have web/Routines/Remote Control toggled off. |
| `--teleport` refuses | Needs clean git state, same repo (not a fork), branch pushed, same claude.ai account. `git stash`, `git push`, retry. |
| `ultracode` does nothing special | Dynamic workflows off: Pro must enable in `/config`; org admin may have disabled; keyword only counts when *typed by you* (not in `-p`, not pasted by a script). Ask "use a workflow to …" explicitly. |
| `claude agents`: command opens but sessions show failed after reboot | Background sessions survive sleep, not shutdown; select and interact to restart, or `claude respawn --all`. |
| `/list-agents` is an unknown command; or it works but the other session is missing; or your message is "held" on the other side | *Unknown command* → this session has no cross-session messaging: check `claude --version` (v2.1.224+), OS (macOS/Linux/WSL 2, not native Windows), provider (not Bedrock/Vertex/Foundry/Claude Platform on AWS), and that `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` / `DO_NOT_TRACK` / `DISABLE_GROWTHBOOK` aren't switching off feature-flag evaluation. *Missing peer* → the other session was started with `--bare` (no inbox), runs in a container (separate filesystem), or is on another machine / the web without Remote Control connected on this side (and running on that side); a deny rule on `ListAgents`/`SendMessage` also removes the tools. *Held* → the receiver bypasses permissions (default: hold behind an approval dialog that expires after `dialogExpiry`, 5 min) or has `"crossSessionInbound": "hold"`; approve there, or set `"accept"` (the `/config` row *Messages from your other sessions*). |

## Stretch goals

a. **Drive `-p` over stdin.** `python3 $WS/labs/m4/streamjson-driver.py src/cartservice` feeds two user turns through one process using `--input-format stream-json --output-format stream-json --verbose --replay-user-messages`. Each stdin line is
   `{"type":"user","message":{"role":"user","content":[{"type":"text","text":"…"}]},"parent_tool_use_id":null}`; the script waits for a `result` event before sending turn 2. This is the wire protocol the Agent SDK speaks for you in Module 5.
b. **Whole-session agent.** `claude --agent codebase-toolkit:bug-hunter -p "src/quoteservice" --allowedTools "Read,Grep,Glob" --permission-mode dontAsk --output-format json | jq -r .result` — compare turns/cost with the `@agent-` delegation form (no outer orchestrator turn).
c. **Your plugin in Actions.** Add a third workflow `toolkit-review.yml` on `pull_request` with `plugin_marketplaces: "https://github.com/<WORKSHOP_ORG>/claude-marketplace.git"`, `plugins: "codebase-toolkit@<WORKSHOP_ORG>-marketplace"`, `prompt: "/codebase-toolkit:code-reviewer app/ security — post a single summary comment"`, `claude_args: '--max-turns 12 --allowedTools "Bash(gh pr comment *)"'`. Push, then re-trigger with `gh pr close demo/add-export-endpoint && gh pr reopen demo/add-export-endpoint`.
d. **Save the workflow.** In the `/workflows` view of the Dockerfile audit press `s`, save to project scope, then run it as `/dockerfile-audit src/frontend src/adservice` and open `.claude/workflows/dockerfile-audit.*` to read the script Claude wrote.
e. **Cloud-ready repo.** Add to `$OTEL/.claude/settings.json` a `SessionStart` hook (`matcher: "startup|resume"`) running `scripts/cloud-setup.sh` that exits 0 unless `CLAUDE_CODE_REMOTE=true`, then runs `npm ci --prefix src/frontend`; add `"enabledPlugins": {"codebase-toolkit@<WORKSHOP_ORG>-marketplace": true}` and the matching `extraKnownMarketplaces` entry; commit on a branch, push, `claude --cloud "run /codebase-toolkit:code-reviewer src/frontend"` and confirm in the web transcript that the plugin loaded. Then `claude --teleport` it home.
f. **Fire a routine from curl.** Create a routine on the web with an **API** trigger whose prompt says "Treat the fire payload as an alert description; find the likely service in this repo and open an issue with a triage note." Generate the token, fire it with the `curl` from §4.6, open the returned session URL.
g. **Delegated approvals (exploratory).** `--permission-prompt-tool mcp__astro-catalog__approve` routes would-be permission prompts in `-p` to an MCP tool instead of denying them. The lab server ships a toy `approve` tool that allows `Read`/`Grep`/`Glob` and denies everything else — it is **off by default** (so `/mcp` in Module 2 shows 3 tools); enable it by adding `"env": {"ASTRO_CATALOG_ENABLE_APPROVE": "1"}` to the `astro-catalog` entry in `.mcp.json` (or exporting it before `claude`), then try a prompt that wants `Bash`. (The tool's request/response contract is documented with the Agent SDK permissions guide rather than the CLI page — check reference §I.1 notes before relying on it.)
h. **Goal-driven headless run.** `claude -p "/goal reports/services.csv lists every directory under src/ with columns name,language,has_readme,has_dockerfile and the row count equals the directory count — or stop after 12 turns" --allowedTools "Read,Glob,Grep,Write" --permission-mode acceptEdits --output-format stream-json --verbose | jq -r -f $WS/labs/m4/stream-filter.jq`.
i. **Two named sessions, one hand-off.** Terminal 1: `cd $OTEL && claude --name readme-writer`. Terminal 2: `git -C $OTEL worktree add ../otel-audit && cd $OTEL/../otel-audit && claude --name dockerfile-audit`. In each, run `/list-agents` (the other session appears with its directory) and `/status` (note the `uds:` `Peer address`; hooks and Bash commands see it as `$CLAUDE_CODE_MESSAGING_SOCKET`). In `dockerfile-audit`: `Find the service with the least reproducible Dockerfile, then tell @readme-writer which one and why so it can mention that in the README it writes; let me know when it goes idle.` Watch the message land in terminal 1 under `dockerfile-audit`'s name and read how the receiving Claude frames it (from another session, not from you). Then add `"crossSessionInbound": "hold"` to `.claude/settings.local.json` on the `readme-writer` side, have `dockerfile-audit` send a follow-up, see the *held* notice, switch the value to `"accept"` (or use `/config` → *Messages from your other sessions*) and watch the held message release. Clean up with `git -C $OTEL worktree remove ../otel-audit`.

## Key takeaways

- `claude -p` is Claude Code as a Unix filter: text/JSON/stream-JSON out, `--json-schema` for typed results, `session_id` + `--resume` for multi-step jobs, and `total_cost_usd`/`usage` in every result so cost is observable by default.
- Unattended means **locked down by you**: `--permission-mode dontAsk` + explicit `--allowedTools`, `--max-turns` + `--max-budget-usd`, and `--bare` (or `--setting-sources user`) whenever the checkout isn't yours — `-p` has no trust dialog.
- `anthropics/claude-code-action@v1` gives you `@claude` in PRs (interactive) and event-driven jobs (`prompt:`), authenticates with a secret or OIDC, honours the repo's `CLAUDE.md`/`.claude/`, and can load your plugin via `plugin_marketplaces` + `plugins`. Managed Code Review (Team/Enterprise) and the security-review Action (M7) sit beside it.
- Local scale-out ladder: subagents → `/batch` → background sessions + agent view (research preview) → dynamic workflows/`ultracode` (research preview) → agent teams (experimental); `/loop` and `/goal` add time- and condition-driven persistence to any of them, and cross-session messaging (`--name`, `/list-agents`, `@session-name`) lets sessions you run side by side hand each other findings — as plain, untrusted text gated by `crossSessionInbound`.
- Cloud scale-out: Claude Code on the web (`--cloud`, `--teleport`) runs repo-committed config in an isolated VM under your subscription; Routines add schedule/API/GitHub triggers; Remote Control is the opposite direction (local session, remote screen). None of these are the API products — that bridge is Modules 5 (Agent SDK) and 6 (Managed Agents).
- Choose by *who triggers it, where it runs, whose credentials it uses, and what config it can see* — the §4.7 table — not by novelty.

## References

- Reference §I.1 — CLI commands & flags table, print-mode result schema, stream event catalogue, exit codes, CI auth precedence, `--bare` details: `../reference/Technical-Reference-v4.md`
- Reference §I.2 — `claude-code-action@v1` inputs, example workflows (incl. Bedrock/Google Cloud/Foundry OIDC), security checklist, `@beta`→`v1` migration, GitLab CI/CD snippet, Code Review & `REVIEW.md`, GitHub Enterprise Server notes
- Reference §I.3 — background sessions & agent view keys, dynamic-workflow limits/script API/size guideline, agent teams, cross-session messaging (settings in §D.5, env vars in §C.7), `/loop`·`/goal`·Routines·Desktop-tasks comparison, web/cloud-environment matrix (what carries over, network levels, setup script vs `SessionStart`), Remote Control, self-hosted environments, "when to use what"
- Reference §M.1 — threat → control matrix (the "unattended / headless trust gaps" row: `--bare`, `--setting-sources user`, `disableAllHooks`); §I.2 — Actions security checklist (least `permissions:`, secrets/OIDC, fork PRs); §O — volatile facts (routine API beta header, preview/beta labels, plan gating) to re-verify before delivery
- Public docs (as of Aug 2026): `code.claude.com/docs/en/headless`, `/cli-reference`, `/github-actions`, `/code-review`, `/gitlab-ci-cd`, `/agent-view`, `/workflows`, `/agent-teams`, `/cross-session-messaging`, `/scheduled-tasks`, `/goal`, `/claude-code-on-the-web`, `/cloud-environments`, `/routines`, `/remote-control`, `/desktop`; Action repo `github.com/anthropics/claude-code-action` (`docs/usage.md`, `docs/security.md`, `examples/`)
- Lab assets: `labs/m4/bug-hunt.sh`, `labs/m4/stream-filter.jq`, `labs/m4/streamjson-driver.py`, `labs/m4/github/{claude.yml,code-review.yml}`, `labs/shared/findings.schema.json`, `labs/m4/expected-output/`; next: [Module 5 — Claude Agent SDK deep-dive](05-claude-agent-sdk.md)
