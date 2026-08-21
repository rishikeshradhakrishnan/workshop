# Claude for Builders — Technical Reference v4 (Appendices A–O)

> **What this document is.** The lookup companion to *Workshop-Guide-v4.md* and `modules/00`–`08`. Module files contain only what is typed, said, or checked in the room; every table of flags, events, settings keys, endpoint maps, schemas and model line-ups lives here and is linked from the modules as "Ref §X". It is meant to be searched (Ctrl-F), not read top to bottom.
>
> **As of 19 August 2026.** Verified against public documentation only: Claude Code docs (`https://code.claude.com/docs`), Claude Platform docs (`https://platform.claude.com/docs`), the official changelogs, and Anthropic's public GitHub repositories. Reference versions at time of writing: Claude Code CLI **v2.1.235**; Claude Agent SDK **TypeScript 0.3.235 / Python 0.2.140**; Claude Managed Agents beta header **`managed-agents-2026-04-01`**; Claude Security plugin **0.10.x**. Claude Code ships roughly daily, so version gates below ("v2.1.2xx+") are minimums, not pins.
>
> **Volatility.** Anything tagged **[volatile]** (model line-up, defaults per plan, prices, beta headers, preview features) is collected again in [§O](#o-volatile-facts-to-re-verify-before-each-delivery) with the page to re-check. Facts that could not be confirmed on a first-party public page are omitted or footnoted as *unverified*.
>
> **Conventions.** `settings.json` keys are JSON paths (`permissions.defaultMode`); environment variables are `UPPER_SNAKE`; slash commands start with `/`; shell subcommands start with `claude`. "1P" = Anthropic API / claude.ai login; "3P" = Amazon Bedrock, Google Cloud's Agent Platform (Vertex AI), Microsoft Foundry, Claude Platform on AWS. "CMA" is table shorthand for **Claude Managed Agents** (always use the full product name in participant-facing text). In tables, `A \| B` inside code means alternatives.

---

## Table of contents

| § | Appendix | Backs modules |
|---|---|---|
| [A](#a-platform-map-and-which-tool-when) | Platform map and "which tool when" | M0, M8 |
| [B](#b-models-aliases-effort-and-fast-mode-as-of-august-2026) | Models, aliases, effort and fast mode (as of Aug 2026) **[volatile]** | M0, M1 |
| [C](#c-cli-slash-commands-keyboard-shortcuts-and-environment-variables) | CLI (install/auth/subcommands/flags/exit codes), slash commands, keyboard shortcuts, environment variables | M0, M1, M4 |
| [D](#d-settings-permissions-memory-and-sandbox) | Settings scopes and keys, CLAUDE.md and memory (D.1), permission modes (D.2), permission-rule grammar (D.3), managed settings (D.4), sandbox, `.claude/` map | M1, M2, M7 |
| [E](#e-hooks-reference) | Hooks: schema, handler types, I/O contract, full event table, examples | M2, M7 |
| [F](#f-mcp-reference) | MCP: `claude mcp` CLI, scopes, transports, `.mcp.json`, OAuth, resources/prompts, `claude mcp serve`, managed MCP | M2 |
| [G](#g-subagents-and-multi-agent-primitives) | Subagents: file format, frontmatter, built-ins, execution model | M3 |
| [H](#h-skills-plugins-and-marketplaces) | Skills (H.1), plugins and marketplaces (H.2), bundled skills (H.3) | M3 |
| [I](#i-headless-ci-github-actions-orchestration-and-surfaces) | Headless `-p` and stream-json (I.1), GitHub Actions / GitLab / Code Review (I.2), orchestration matrix (I.3), surfaces matrix (I.4) | M4 |
| [J](#j-troubleshooting-and-faq) | Troubleshooting and FAQ (install, auth, proxy, plans, Windows/WSL, per-module) | all |
| [K](#k-claude-agent-sdk-reference) | Claude Agent SDK: concept mapping (K.1), install/versions, options tables, hosting (K.4), messages, hooks, custom tools, sessions, migration | M5 |
| [L](#l-claude-managed-agents-reference) | Claude Managed Agents: concepts, endpoint map, events, headers, snippets, limits, pricing | M6 |
| [M](#m-security-and-claude-security-reference) | Security: threat→control matrix (M.1), Claude Security plugin (M.2), security-guidance (M.3), `/security-review` + Action (M.4), hosted Claude Security (M.5), org checklist (M.6) | M2, M7 |
| [N](#n-glossary-resources-and-changelog-highlights) | Glossary, public resource links, changelog highlights mid-2025 → Aug 2026 | M8 |
| [O](#o-volatile-facts-to-re-verify-before-each-delivery) | Volatile facts to re-verify before each delivery (dated) | instructors |

**Quick finder:** install commands → C.1 · CLI flags → C.3 · exit codes / JSON result shape → I.1 · slash commands → C.5 · shortcuts → C.6 · env vars → C.7 · settings precedence → D.0 · CLAUDE.md → D.1 · permission modes → D.2 · rule syntax → D.3 · managed-only keys → D.4 · sandbox keys → D.6 · hook events → E.4 · `.mcp.json` → F.3 · agent frontmatter → G.2 · `SKILL.md` frontmatter → H.1 · `plugin.json` / `marketplace.json` → H.2 · `claude-code-action` inputs → I.2 · SDK options → K.3 · CMA endpoints → L.3 · finding schema → M.2 · model table → B.1.

---

## A. Platform map and which tool when

### A.1 Four ways to build with Claude

| | **Messages API** (Client SDKs) | **Claude Agent SDK** | **Claude Code** | **Claude Managed Agents** (beta) |
|---|---|---|---|---|
| What it is | Direct model access; you implement the loop | Claude Code's agent loop, tools and context management as a Python/TypeScript library | Anthropic's agentic coding product: terminal CLI, IDE extensions, Desktop app, web, mobile | Pre-built, configurable agent harness that runs on Anthropic-managed infrastructure |
| Who runs the agent loop | You | You (the SDK supervises a bundled `claude` subprocess inside *your* process/container) | The Claude Code app on the developer's machine, or Anthropic's cloud VM for Claude Code on the web | Anthropic (tool execution can be moved to your infra with self-hosted sandboxes; the loop stays hosted) |
| Where tools execute | Wherever you run them | Your host / container | Developer machine (or cloud VM for `--cloud` sessions) | Fresh cloud container per session (or your self-hosted worker) |
| State | Stateless requests | Local JSONL transcripts; optional `SessionStore` | Local transcripts, checkpoints, auto memory | Server-side sessions, event history, files, memory stores |
| Auth / billing | API key; per token | API key or 3P cloud creds; per token (claude.ai login not permitted for products you ship) | claude.ai subscription seat **or** Console API key **or** 3P provider | API key; tokens **plus** session runtime ($0.08 per session-hour while `running`) **[volatile]** |
| Interface | REST / `anthropic`, `@anthropic-ai/sdk` | `query()`, `ClaudeSDKClient` (Py) / streaming input (TS) | Terminal, VS Code/JetBrains, Desktop, claude.ai/code, `claude -p` | REST `/v1/agents`, `/v1/environments`, `/v1/sessions`, …, `client.beta.*`, `ant` CLI, Console builder |
| Best for | Custom loops, fine-grained control, non-agentic calls | Embedding a Claude-Code-style agent in your own app, CI job or service | Interactive and headless software engineering by developers | Long-running / asynchronous agents, scheduled runs, per-end-user integrations, minimal infra |
| Docs | platform.claude.com/docs | code.claude.com/docs/en/agent-sdk/overview | code.claude.com/docs | platform.claude.com/docs/en/managed-agents/overview |

Rules of thumb (from the docs' own positioning): prototype an agent with the **Agent SDK** locally; move to **Managed Agents** when you do not want to operate sandboxes/session infrastructure; use **Claude Code** (interactive or `claude -p`) when the "user" is a developer or a CI job working on a repository; drop to the **Messages API** only when you need a bespoke loop. **Claude Code on the web** (subscription feature, no compute charge, developer-facing) is *not* Managed Agents (API product, metered per session-hour, for agents inside *your* product) even though both speak of "environments" and "sessions".

### A.2 Claude Code extension points (where each lives)

| Extension point | What it does | Location(s) | Loaded | Ref |
|---|---|---|---|---|
| `CLAUDE.md` / rules | Persistent instructions, conventions | `./CLAUDE.md`, `./.claude/CLAUDE.md`, `.claude/rules/*.md`, `~/.claude/CLAUDE.md`, `CLAUDE.local.md`, managed `CLAUDE.md` | Every session (path-scoped rules on demand) | D.1 |
| Settings | Permissions, modes, env, hooks, sandbox, plugins | `~/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json`, managed settings, `--settings` | Startup + hot reload | D |
| Hooks | Deterministic scripts/HTTP/prompt/agent handlers on lifecycle events | `hooks` key in any settings file; plugin `hooks/hooks.json`; skill/agent frontmatter | On event | E |
| MCP servers | External tools, resources, prompts | `.mcp.json` (project), `~/.claude.json` (user/local), plugin `.mcp.json`, `managed-mcp.json`, `--mcp-config` | Startup (deferred tool loading) | F |
| Subagents | Isolated workers with own prompt/tools/model | `.claude/agents/*.md`, `~/.claude/agents/`, plugin `agents/`, `--agents` JSON | On delegation | G |
| Skills (and legacy commands) | Reusable instructions/workflows, `/name` or model-invoked | `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/`, plugin `skills/`, `.claude/commands/*.md` | Description at startup; body on invoke | H.1 |
| Plugins + marketplaces | Package and distribute all of the above (+ LSP, workflows, themes, `bin/`) | `<plugin>/.claude-plugin/plugin.json`; `<marketplace>/.claude-plugin/marketplace.json`; `enabledPlugins`, `extraKnownMarketplaces` | Startup / `/reload-plugins` | H.2 |
| Output styles, status line, keybindings, themes | UX customization | `.claude/output-styles/`, `statusLine` setting, `~/.claude/keybindings.json`, `~/.claude/themes/` | Startup | C, D.5 |
| Dynamic workflows | JS scripts orchestrating many subagents | `.claude/workflows/*.js`, `~/.claude/workflows/`, plugin `workflows/` | On `/name` or `Workflow` tool | I.3 |

Layering: CLAUDE.md files are additive; skills and subagents override by name (skills managed > user > project; subagents managed > `--agents` > project > user > plugin); MCP servers override by name (local > project > user > plugin > claude.ai connectors); hooks merge (all matching hooks fire); settings arrays concatenate across scopes, scalars follow precedence (D.0).

### A.3 Security layers you will meet (map for M0/M7)

| Layer | Mechanism | Enforced by | Ref |
|---|---|---|---|
| Permission rules and modes | `permissions.allow/ask/deny`, `defaultMode`, protected paths, critical-path `rm` guard | Claude Code client (not the model) | D.2, D.3 |
| Auto-mode classifier | Separate model reviews each action; `autoMode.*` prose rules | Anthropic server-side classifier + client | D.2 |
| Hooks | `PreToolUse` deny/ask, `PermissionRequest`, `ConfigChange`, audit via `PostToolUse` | Your code, deterministic | E |
| Sandboxed Bash | OS-level filesystem + network isolation for Bash children; credential deny/mask | macOS Seatbelt / Linux bubblewrap + proxy | D.6 |
| Whole-process isolation | sandbox-runtime, devcontainer, container/VM, Claude Code on the web VM | OS / hypervisor | D.6, M.1 |
| Headless/CI trust | `--bare`, `--setting-sources user`, `dontAsk` + `--allowedTools`, minimal workflow permissions | You | I.1, I.2 |
| SDK policy in code | `allowedTools`/`disallowedTools`, `permissionMode`, `canUseTool`, hook callbacks | Your process | K.6 |
| Managed Agents controls | per-tool `permission_policy`, `limited` networking, vaults, `read_only` memory, budgets | Anthropic harness | L |
| Org policy | managed settings (`allowManaged*Only`, `strictKnownMarketplaces`, managed MCP, `disableBypassPermissionsMode`) | Client, fail-closed | D.4 |
| Security tooling | security-guidance plugin → `/security-review` → Claude Security plugin → Code Review / security-review Action → SAST → hosted Claude Security | Various | M |

Sources: https://code.claude.com/docs/en/overview · https://code.claude.com/docs/en/features-overview · https://code.claude.com/docs/en/agent-sdk/overview · https://platform.claude.com/docs/en/managed-agents/overview · https://platform.claude.com/docs/en/managed-agents/migration · https://code.claude.com/docs/en/security

---

## B. Models, aliases, effort and fast mode (as of August 2026)

> **VOLATILE — VERIFY BEFORE EVERY DELIVERY.** Model line-up, per-plan defaults, prices and preview status change frequently. Everything in this appendix was read from https://platform.claude.com/docs/en/about-claude/models/overview , https://code.claude.com/docs/en/model-config and https://claude.com/pricing on 2026-08-19. Workshop files use **aliases** (`opus`, `sonnet`, `haiku`); the SDK lab reads the alias `MODEL` and the CMA lab reads the full model ID `CMA_MODEL` from `labs/.env` precisely so this table is the only place to bump.

### B.1 Current line-up in Claude Code

| Model | Claude API ID | Alias in Claude Code | Context / max output | Effort levels | Notes |
|---|---|---|---|---|---|
| Claude Opus 5 | `claude-opus-5` | `opus`, `opus[1m]` | 1M / 128k | low · medium · high · xhigh · max | Default `opus` on Anthropic API, Claude Platform on AWS, Bedrock, Google Cloud (v2.1.219+). Recommended starting model for agentic coding. Fast mode supported. |
| Claude Sonnet 5 | `claude-sonnet-5` | `sonnet` (`sonnet[1m]` is a no-op; 1M native) | 1M / 128k | low · medium · high · xhigh · max | Default on Pro / Team Standard / Enterprise subscription seats (v2.1.197+). No 200K variant; auto-compacts near ~967K. |
| Claude Fable 5 | `claude-fable-5` | `fable`, `best` (= Fable where the org has access, else latest Opus) | 1M / 128k | low · medium · high · xhigh · max | Never the default; select with `/model fable` (v2.1.170+). May bill **usage credits** on subscription plans (one-time consent prompt). Not available under ZDR. Automatic safety-classifier fallback to Opus documented. |
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` (`claude-haiku-4-5`) | `haiku` | 200k / 64k | — (rejects `effort`) | Fast/cheap; used for background tasks (`ANTHROPIC_DEFAULT_HAIKU_MODEL`); cannot be an advisor; no auto mode. |
| Claude Opus 4.8 | `claude-opus-4-8` | pin by ID (`/model claude-opus-4-8`) | 1M / 128k | low–max | "Legacy" but active; previous default (v2.1.154–218); fast mode supported. |
| Claude Opus 4.7 | `claude-opus-4-7` | pin by ID | 1M / 128k | low–max (default `xhigh`) | Introduced `xhigh`. Fast mode removed 2026-07-24. |
| Claude Opus 4.6 / Sonnet 4.6 | `claude-opus-4-6` / `claude-sonnet-4-6` | pin by ID (`/model claude-sonnet-4-6[1m]` for the 1M variant) | 1M / 128k | low · medium · high · max | Sonnet 4.6 is `sonnet` on Claude Platform on AWS. Sonnet 4.6 1M needs usage credits on subscriptions. |
| Claude Sonnet 4.5 / Opus 4.5 | `claude-sonnet-4-5-20250929` / `claude-opus-4-5-20251101` | pin by ID | 200k / 64k | — | Legacy; `sonnet` still resolves to Sonnet 4.5 on Bedrock, Google Cloud and Microsoft Foundry. Not auto-mode capable. |

Alias resolution by provider (docs, Aug 2026): Anthropic API `opus`→Opus 5, `sonnet`→Sonnet 5 · Claude Platform on AWS Opus 5 / Sonnet 4.6 · Bedrock and Google Cloud's Agent Platform Opus 5 / Sonnet 4.5 · Microsoft Foundry Opus 4.6 / Sonnet 4.5. `default` clears an override and reverts to the recommended model for the account type or the org default. `opusplan` = `opus` while in plan mode, `sonnet` for execution (`opusplan[1m]` forces 1M in both phases).

**What `default` resolves to** **[volatile]**: Max, Team Premium, Enterprise pay-as-you-go, Anthropic API, Claude Platform on AWS, Bedrock, Google Cloud → **Opus 5**; Pro, Team Standard, Enterprise subscription seats → **Sonnet 5**; Microsoft Foundry → **Sonnet 4.5**. Organizations can set an org default model and restrict models (`availableModels`, admin console); check the live value with `/model` or `/status`.

Retired on the Claude API during the last year (do not use in materials): Sonnet 4 and Opus 4 (2026-06-15), Opus 4.1 (2026-08-05), Sonnet 3.7 / Haiku 3.5 (2026-02-19), Haiku 3 (2026-04-20). Deprecation schedule: https://platform.claude.com/docs/en/about-claude/model-deprecations .

### B.2 Choosing and pinning a model

| Mechanism | Scope | Example |
|---|---|---|
| `/model` picker or `/model <alias\|id>` | `Enter` switches **and saves as default** to user settings (v2.1.153+); `s` = this session only; `←/→` adjust effort | `/model sonnet`, `/model opus[1m]`, `/model default` |
| `--model` | Session | `claude --model claude-sonnet-5` |
| `ANTHROPIC_MODEL` | Process env | `ANTHROPIC_MODEL=opus claude` |
| `model` setting | Any settings scope | `{ "model": "opus" }` |
| Alias remap (3P/gateways) | Env | `ANTHROPIC_DEFAULT_OPUS_MODEL`, `_SONNET_MODEL`, `_HAIKU_MODEL`, `_FABLE_MODEL` (each with `_NAME`, `_DESCRIPTION`, `_SUPPORTED_CAPABILITIES`) |
| Subagents / workflows | Env beats frontmatter | `CLAUDE_CODE_SUBAGENT_MODEL=haiku` (`inherit` = unset) |
| Provider ID mapping | Settings | `"modelOverrides": {"claude-opus-4-7": "arn:aws:bedrock:…"}` |
| Restrict | Managed/any scope | `"availableModels": ["sonnet","haiku"]`, `"enforceAvailableModels": true` |
| Fallback chain | Flag/setting | `--fallback-model sonnet,haiku` / `"fallbackModel": ["claude-sonnet-5","claude-haiku-4-5"]` (max 3) |
| Advisor (experimental, 1P only) | `/advisor opus`, `--advisor`, `advisorModel` | Second, stronger model consulted at decision points; must be ≥ main model |

Priority: `/model` (session) > `--model` > `ANTHROPIC_MODEL` > `model` setting > account default. Resumed sessions keep the transcript's model unless overridden.

### B.3 Effort and thinking

| Level | Meaning (docs) | Persists? |
|---|---|---|
| `low` | Short, scoped, latency-sensitive work | yes |
| `medium` | Cost-sensitive work | yes |
| `high` | Balanced default (all current models except Opus 4.7) | yes |
| `xhigh` | Deeper reasoning, higher spend (Opus 4.7 default; Opus 5 / Sonnet 5 / Opus 4.8 / Fable 5 support it) | yes |
| `max` | Demanding tasks; "prone to overthinking" | session only (unless `CLAUDE_CODE_EFFORT_LEVEL=max`) |
| `ultracode` | `xhigh` **plus** Claude plans a dynamic workflow for every substantive task | session only; `/effort ultracode` or `--effort ultracode` (v2.1.203+) |

Set with `/effort [level\|auto]` (slider with no arg), `--effort`, `CLAUDE_CODE_EFFORT_LEVEL` (highest precedence), `"effortLevel"` setting (low/medium/high/xhigh only), or `effort:` frontmatter in skills/subagents. Effort scale is calibrated per model; an unsupported level falls back to the highest supported. `CLAUDE_EFFORT` is exported to Bash and hook subprocesses.

Thinking: adaptive reasoning is always on for Fable 5, Sonnet 5, Opus 4.7+; include the keyword **`ultrathink`** anywhere in a prompt for one-off deeper reasoning ("think hard" etc. are plain text). Toggle thinking display/session with `Option+T`/`Alt+T`; `alwaysThinkingEnabled`, `showThinkingSummaries` settings; `Ctrl+O` shows thinking in the transcript view. All thinking tokens are billed.

### B.4 Fast mode and 1M context

* **Fast mode** (research preview) **[volatile]**: same Opus model up to ~2.5x faster at premium per-token pricing; supported on **Opus 5 and Opus 4.8** only; toggle `/fast [on|off]`, `Alt/Option+O`, `"fastMode": true`, or `claude -p --settings '{"fastMode": true}'`. On subscription plans it bills **usage credits** only (`/usage-credits`); Console orgs need it provisioned; not on Bedrock/Vertex/Foundry/Claude Platform on AWS; not in the VS Code extension. Best for interactive iteration, not CI. Admin: `fastModePerSessionOptIn`, `CLAUDE_CODE_DISABLE_FAST_MODE=1`.
* **1M context**: standard on Opus 5, Sonnet 5, Fable 5, Opus 4.7/4.8 (no premium beyond 200K). `[1m]` suffix selects 1M variants where a 200K variant exists (`/model claude-opus-4-6[1m]`). `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` holds native-1M models to 200K. Auto-compact window: `/autocompact 500k|auto`, `--autocompact`, `autoCompactWindow`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`.
* **Pricing pointers** (do not hard-code prices in slides): https://claude.com/pricing and https://platform.claude.com/docs/en/about-claude/pricing . `/model` shows prices only on the Anthropic API.

Sources: https://code.claude.com/docs/en/model-config · https://code.claude.com/docs/en/fast-mode · https://code.claude.com/docs/en/advisor · https://platform.claude.com/docs/en/about-claude/models/overview · https://platform.claude.com/docs/en/about-claude/model-deprecations · https://claude.com/pricing

---

## C. CLI, slash commands, keyboard shortcuts and environment variables

### C.1 Install, update, uninstall, authenticate

**System requirements:** macOS 13+; Windows 10 1809+ / Server 2019+ (native, WSL2, or WSL1 without sandboxing); Ubuntu 20.04+, Debian 10+, Alpine 3.19+; 4 GB+ RAM; x64 or ARM64. **Node.js is not required** for the native install (the `claude` binary is native). Free claude.ai plans do not include Claude Code.

| Method | Command | Auto-updates |
|---|---|---|
| Native, macOS/Linux/WSL (recommended) | `curl -fsSL https://claude.ai/install.sh \| bash` (append `-s stable` or `-s <version>` to pin) | Yes |
| Native, Windows PowerShell | `irm https://claude.ai/install.ps1 \| iex` | Yes |
| Native, Windows CMD | `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd` | Yes |
| Homebrew | `brew install --cask claude-code` (stable) or `claude-code@latest` | `brew upgrade` (or `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1`) |
| WinGet | `winget install Anthropic.ClaudeCode` | `winget upgrade` |
| apt / dnf / apk | Signed repos under `https://downloads.claude.ai/claude-code/{apt,rpm,apk}/stable`; `sudo apt install claude-code` etc. | Via package manager |
| npm (wraps the same native binary; Node 22+) | `npm install -g @anthropic-ai/claude-code` (upgrade with `@latest`; never `sudo`) | See docs |

| Task | Command |
|---|---|
| Verify | `claude --version`; `claude doctor` (read-only diagnostics); in-session `/doctor` (can fix) |
| Update now | `claude update` |
| Reinstall / pin channel | `claude install [stable\|latest\|2.1.NNN]`; setting `"autoUpdatesChannel": "stable"\|"latest"`, `"minimumVersion"`; managed `requiredMinimumVersion` / `requiredMaximumVersion` |
| Disable updater | `DISABLE_AUTOUPDATER=1` (manual `claude update` still works); `DISABLE_UPDATES=1` blocks all paths |
| Uninstall (native) | `rm -f ~/.local/bin/claude && rm -rf ~/.local/share/claude`; Windows: remove `%USERPROFILE%\.local\bin\claude.exe` and `.local\share\claude` |
| Remove all config/state | `rm -rf ~/.claude ~/.claude.json` (per project: `rm -rf .claude .mcp.json`) |
| Migrate npm → native | run the native installer, then `npm uninstall -g @anthropic-ai/claude-code`; check `which -a claude` |

**Authentication paths** (any one):

| Path | How | Notes |
|---|---|---|
| claude.ai subscription (Pro/Max/Team/Enterprise) | `claude` → browser; `c` copies URL; paste code in WSL/SSH; `claude auth login [--email x] [--sso]` | `/login`, `/logout`; `claude auth status [--text]` exits 0/1 |
| Claude Console (API billing) | `claude auth login --console` or `ANTHROPIC_API_KEY=sk-ant-…` | Console role **Claude Code** or **Developer**; a "Claude Code" workspace is auto-created |
| Long-lived token for CI | `claude setup-token` → `export CLAUDE_CODE_OAUTH_TOKEN=…` | One-year OAuth token, subscription plans, inference only; not read in `--bare` |
| Bearer / gateway | `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `apiKeyHelper` script | See §C.7 |
| Amazon Bedrock | `CLAUDE_CODE_USE_BEDROCK=1` + AWS creds (or login prompt → *3rd-party platform* wizard, `/setup-bedrock`) | Mantle endpoint: `CLAUDE_CODE_USE_MANTLE=1` |
| Google Cloud's Agent Platform (Vertex AI) | `CLAUDE_CODE_USE_VERTEX=1`, `CLOUD_ML_REGION`, `ANTHROPIC_VERTEX_PROJECT_ID` (or `/setup-vertex`) | |
| Microsoft Foundry | `CLAUDE_CODE_USE_FOUNDRY=1`, `ANTHROPIC_FOUNDRY_RESOURCE`, `ANTHROPIC_FOUNDRY_API_KEY` or Entra ID | |
| Claude Platform on AWS | `CLAUDE_CODE_USE_ANTHROPIC_AWS=1`, `ANTHROPIC_AWS_WORKSPACE_ID`, SigV4 or `ANTHROPIC_AWS_API_KEY` | |

Authentication precedence: cloud-provider env → `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` → `apiKeyHelper` → `CLAUDE_CODE_OAUTH_TOKEN` → Anthropic profile / workload identity → subscription OAuth from `/login`. A stale `ANTHROPIC_API_KEY` silently overrides a subscription (`unset` it). Credentials live in the macOS Keychain, or `~/.claude/.credentials.json` (0600) on Linux/Windows; `CLAUDE_CONFIG_DIR` relocates everything (also how to run two accounts side by side). Org restriction (managed): `forceLoginMethod` (`claudeai`\|`console`\|`gateway`), `forceLoginOrgUUID`.

Sources: https://code.claude.com/docs/en/setup · https://code.claude.com/docs/en/authentication · https://code.claude.com/docs/en/troubleshoot-install

### C.2 `claude` subcommands

| Command | Purpose |
|---|---|
| `claude` / `claude "task"` | Interactive session (optionally with an initial prompt) |
| `claude -p "query"` | Non-interactive (print/headless) run; see §I.1 |
| `claude -c` / `claude -r [id\|name]` | Continue most recent session in cwd / resume by ID or name (picker with no arg) |
| `claude update` · `claude install [ver\|stable\|latest]` · `claude doctor` | Update, (re)install, diagnostics |
| `claude auth login\|logout\|status` · `claude setup-token` | Auth management; CI token |
| `claude mcp …` | MCP server management (§F.1); `claude mcp serve` runs Claude Code as an MCP server |
| `claude plugin …` (alias `plugins`) | Plugin/marketplace management (§H.2) |
| `claude agents [--json [--all]]` · `claude attach\|logs\|stop\|respawn\|rm <id>` · `claude daemon status\|stop` | Agent view and background sessions (research preview) |
| `claude --bg "prompt"` (`--background`) [`--exec 'cmd'`] | Start a background session and return |
| `claude auto-mode defaults\|config\|critique\|reset` | Inspect/reset auto-mode classifier rules |
| `claude project purge [path] [--dry-run\|-y\|--all]` | Delete local state for a project |
| `claude import codex\|gemini [--dry-run] [--yes]` | Import other agents' config |
| `claude remote-control [--name]` | Remote Control server mode |
| `claude ultrareview [target] [--json] [--post]` | Cloud multi-agent review, CI-friendly exit codes |
| `claude gateway --config gateway.yaml` | Self-hosted Claude apps gateway (enterprise) |
| `claude self-hosted-runner setup\|doctor` | Register a runner for self-hosted cloud environments (Team/Enterprise) |

### C.3 CLI flags (interactive and `-p`)

| Flag | Purpose |
|---|---|
| **Session selection** | |
| `-c, --continue` · `-r, --resume [id\|name]` · `--fork-session` · `--session-id <uuid>` · `-n, --name <name>` · `--from-pr <n\|url>` | Continue/resume/fork/name sessions; resume by ID searches all projects (v2.1.223+) |
| `-w, --worktree [name\|#n\|PR-URL]` · `--tmux` | Start in an isolated git worktree under `.claude/worktrees/` |
| `--cloud <task\|session>` (`--remote` deprecated) · `--teleport [id]` · `--environment ccpool_…` | Create/attach a Claude Code on the web session; pull a web session local; target a self-hosted environment |
| `--bg "prompt"` · `--exec 'cmd'` | Background session / shell job (not with `-p`) |
| **Model and effort** | |
| `--model <alias\|id>` · `--effort low\|medium\|high\|xhigh\|max\|ultracode` · `--fallback-model a,b` · `--advisor <model>` · `--autocompact <auto\|tokens>` · `--betas <hdrs>` | See §B |
| **Permissions and tools** | |
| `--permission-mode default\|acceptEdits\|plan\|auto\|dontAsk\|bypassPermissions` (`manual` = `default`) | Starting mode; `-p` always starts in `default` unless set |
| `--dangerously-skip-permissions` · `--allow-dangerously-skip-permissions` | = bypassPermissions / add bypass to the Shift+Tab cycle without activating |
| `--allowedTools "Rule" …` · `--disallowedTools "Rule" …` · `--tools "Bash,Edit,Read"\|""\|default` | Pre-approve / deny / restrict built-in tool *availability* (rule syntax §D.3) |
| `--permission-prompt-tool <mcp_tool>` | Delegate permission prompts to an MCP tool (`-p`) |
| **Context and configuration** | |
| `--add-dir <paths…>` | Extra working directories |
| `--settings <file\|json>` · `--setting-sources user,project,local` | Inline/extra settings; choose which filesystem scopes load |
| `--bare` | Minimal mode: skip hooks, skills, plugins, MCP, auto memory, CLAUDE.md; never reads OAuth/keychain (needs `ANTHROPIC_API_KEY` or 3P creds). Recommended for CI; will become the `-p` default |
| `--safe-mode` | Start with all customizations disabled (managed policy still applies) — for troubleshooting |
| `--system-prompt[-file]` · `--append-system-prompt[-file]` · `--append-subagent-system-prompt` (`-p`) · `--exclude-dynamic-system-prompt-sections` | Replace / append system prompt; move per-machine sections into first user message for cache reuse |
| `--agent <name>` · `--agents '<json>'` | Run the session as an agent; define session-only subagents |
| `--mcp-config <files\|json>` · `--strict-mcp-config` | Load MCP servers for this session; ignore all other MCP config |
| `--plugin-dir <path\|zip>` · `--plugin-url <url>` | Session-only plugin loading (repeatable) |
| `--disable-slash-commands` · `--chrome/--no-chrome` · `--ide` · `--channels …` · `--teammate-mode …` · `--remote-control [name]` | Feature toggles |
| **Print-mode I/O** (`-p` only) | |
| `-p, --print` · `--output-format text\|json\|stream-json` · `--input-format text\|stream-json` · `--json-schema '<schema>'` | Formats and validated structured output (§I.1) |
| `--include-partial-messages` · `--include-hook-events` · `--forward-subagent-text` · `--replay-user-messages` · `--prompt-suggestions` · `--verbose` | Extra stream-json events |
| `--max-turns <n>` · `--max-budget-usd <usd>` · `--no-session-persistence` | Caps and persistence |
| `--init` · `--maintenance` · `--init-only` | Fire `Setup` hooks (§E) |
| **Diagnostics** | |
| `--debug[=filter]` · `--debug-file <path>` · `--ax-screen-reader` · `-v, --version` | Debug log at `~/.claude/debug/<session>.txt` |

### C.4 Output formats and exit codes (summary; details §I.1)

| Item | Value |
|---|---|
| `--output-format` | `text` (default) · `json` (single object: `result`, `session_id`, `total_cost_usd`, `usage`, `modelUsage`, `structured_output`, `permission_denials`, …) · `stream-json` (NDJSON events: `system/init`, `assistant`, `user`, `stream_event`, hook events, final `result`) |
| Exit codes | `0` success; non-zero on failure (invalid flags → stderr before run; `--max-turns` reached and invalid `--json-schema` are error exits); `143` on SIGTERM (turn aborted, `SessionEnd` hooks run); `1` when resuming an ended session with `-p`. `claude auth status`: 0 logged in / 1 not. `claude ultrareview`: 0 done / 1 error-or-timeout / 130 Ctrl-C |
| Result subtypes | `success` · `error_max_turns` · `error_during_execution` · `error_max_budget_usd` · `error_max_structured_output_retries` |

Sources: https://code.claude.com/docs/en/cli-reference · https://code.claude.com/docs/en/headless

### C.5 Slash commands (built-in, grouped)

Type `/` to open the menu; a command is recognized only at the start of the message. Bundled *skills* (prompt-based; Claude may auto-invoke most) and the bundled *workflow* are grouped under **Review & quality** and detailed in §H.3. Availability varies by plan/platform.

| Group | Commands |
|---|---|
| **Session & context** | `/clear [name]` (aliases `/reset`, `/new`) · `/compact [focus]` · `/context [all]` · `/rewind` (aliases `/checkpoint`, `/undo`; also `Esc Esc`) · `/branch [name]` · `/fork [prompt]` (copy into a background session) · `/subtask <task>` (forked subagent) · `/resume [session]` (`/continue`) · `/rename [name]` · `/export [file]` · `/copy [N]` · `/cd <path>` · `/add-dir <path>` · `/btw [question]` · `/recap` · `/goal [condition\|clear]` · `/autocompact [auto\|tokens]` · `/exit` |
| **Model & effort** | `/model [model]` (Enter = save default, `s` = session) · `/effort [level\|auto]` · `/fast [on\|off]` · `/advisor [model\|off]` · `/plan [description]` |
| **Memory & project** | `/init` · `/memory` · `/import [codex\|gemini]` |
| **Config & permissions** | `/config [key=value]` (`/settings`) · `/permissions` (`/allowed-tools`) · `/sandbox` · `/hooks` (read-only viewer) · `/status` · `/doctor` (`/checkup`, skill) · `/keybindings` · `/statusline` · `/theme` · `/color` · `/tui [default\|fullscreen]` · `/terminal-setup` · `/focus` · `/voice` · `/privacy-settings` |
| **Extensions** | `/mcp [reconnect <srv>\|enable\|disable …]` · `/plugin [list\|install\|enable\|disable\|marketplace …]` · `/reload-plugins [--force]` · `/skills` · `/reload-skills` · `/agents` (now a pointer to `.claude/agents/`) · `/list-agents` (`/peers`) |
| **Review & quality (skills)** | `/code-review [low..max\|ultra] [--fix] [--comment] [target]` (`/review`) · `/simplify [target]` · `/security-review` · `/verify` · `/run` · `/run-skill-generator` · `/debug [issue]` · `/batch <instruction>` · `/fewer-permission-prompts` · `/deep-research <q>` (workflow) · `/dataviz` · `/claude-api [migrate\|managed-agents-onboard\|prompt-audit]` · `/loop [interval] [prompt]` (`/proactive`) |
| **Background & cloud** | `/background [prompt]` (`/bg`) · `/tasks` (`/bashes`) · `/workflows` · `/stop` · `/schedule [description]` (`/routines`) · `/teleport` (`/tp`) · `/remote-env` · `/remote-control` (`/rc`) · `/autofix-pr [prompt]` · `/ultrareview` (prefer `/code-review ultra`) · `/desktop` (`/app`) · `/mobile` · `/ide` · `/chrome` · `/web-setup` |
| **Account & usage** | `/login` · `/logout` · `/usage` (aliases `/cost`, `/stats`) · `/usage-credits` (was `/extra-usage`) · `/upgrade` · `/passes` · `/insights` · `/team-onboarding` · `/install-github-app` · `/install-slack-app` |
| **Help & feedback** | `/help` · `/powerup` · `/release-notes` · `/feedback` \| `/bug` (`/share`) · `/stickers` · `/radio` |
| **Provider setup** | `/setup-bedrock` · `/setup-vertex` (visible only with the provider env var set) |
| **Removed / renamed** | `/vim` (use `/config` → Editor mode) · `/output-style` (use `outputStyle` setting) · `/pr-comments` · `/ultraplan` (use plan mode) · `/extra-usage` → `/usage-credits` · `/review` merged into `/code-review` · old `/fork` behaviour → `/subtask` · `#` memory shortcut removed (tell Claude "add this to CLAUDE.md") |

Custom entries: your skills (`/name`, plugin skills `/plugin:name`), legacy `.claude/commands/*.md`, and MCP prompts (`/mcp__<server>__<prompt> [args]`). Skills can be stacked: `/skill-a /skill-b args` (up to six).

### C.6 Keyboard shortcuts and input prefixes (terminal defaults)

| Key | Action |
|---|---|
| `Enter` / `\`+`Enter`, `Ctrl+J`, `Option+Enter`, `Shift+Enter` | Submit / newline (run `/terminal-setup` once in VS Code, Cursor, Alacritty, Zed terminals) |
| `Esc` | Interrupt Claude (work so far kept) or close dialog |
| `Esc Esc` (empty prompt) | Open **rewind** menu (restore code / conversation / summarize) |
| `Shift+Tab` (`Alt+M` on Windows without VT) | Cycle permission modes: default → acceptEdits → plan → [bypassPermissions] → [auto] |
| `Ctrl+C` | Interrupt / clear input (twice = exit); `Ctrl+D` exit |
| `Ctrl+O` | Transcript/verbose view (tool details, thinking) |
| `Ctrl+B` | Background the running Bash command or agent (tmux: press twice) |
| `Ctrl+T` | Toggle Claude's task checklist |
| `Ctrl+G` (or `Ctrl+X Ctrl+E`) | Open prompt / proposed plan in your editor |
| `Ctrl+R` | Reverse history search · `Up/Down` history |
| `Ctrl+S` | Stash / restore prompt · `Ctrl+L` redraw |
| `Ctrl+V` (`Cmd+V` iTerm2, `Alt+V` Windows) | Paste image from clipboard |
| `Ctrl+X Ctrl+K` | Stop all background subagents (twice to confirm) |
| `Option/Alt+P` · `Option/Alt+T` · `Option/Alt+O` | Model picker · toggle thinking · toggle fast mode |
| `←` on empty prompt | Background session and open agent view (configurable) |
| `?` on empty prompt | Shortcut help |
| Typing while Claude works + `Enter` | Queue a message (delivered after the current tool call); `Up` takes it back |

| Prefix | Meaning |
|---|---|
| `/` | Command or skill |
| `!` | Shell mode: run command, output enters context, Claude responds (`respondToBashCommands: false` to silence) |
| `@` | File/dir mention (pulls that dir's CLAUDE.md), `@server:resource` MCP resource, `@agent-<name>` force a subagent, `@<session-name>` message another live session |
| `:` | Emoji shortcode |

Custom bindings: `/keybindings` → `~/.claude/keybindings.json` (`{"bindings":[{"context":"Chat","bindings":{"ctrl+e":"chat:externalEditor","ctrl+u":null}}]}`); reserved: Ctrl+C, Ctrl+D, Ctrl+M. macOS Option shortcuts need Option-as-Meta (`/terminal-setup`).

Sources: https://code.claude.com/docs/en/commands · https://code.claude.com/docs/en/interactive-mode · https://code.claude.com/docs/en/keybindings

### C.7 Environment variables (most-used; ~330 are documented)

Set in the shell before `claude`, or persist under `"env"` in any settings file (settings value beats shell; the env var beats the equivalent settings key).

| Group | Variable | Meaning |
|---|---|---|
| Auth | `ANTHROPIC_API_KEY` | Console key (`X-Api-Key`); overrides subscription login |
| Auth | `ANTHROPIC_AUTH_TOKEN` | `Authorization: Bearer` for gateways |
| Auth | `CLAUDE_CODE_OAUTH_TOKEN` | Token from `claude setup-token` (CI) |
| Auth | `ANTHROPIC_BASE_URL` · `ANTHROPIC_CUSTOM_HEADERS` · `ANTHROPIC_BETAS` | LLM gateway URL; extra headers; extra beta flags |
| Auth | `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` | Refresh interval for `apiKeyHelper` |
| Provider | `CLAUDE_CODE_USE_BEDROCK` · `AWS_REGION` · `AWS_PROFILE` · `AWS_BEARER_TOKEN_BEDROCK` · `ANTHROPIC_BEDROCK_BASE_URL` · `ANTHROPIC_BEDROCK_SERVICE_TIER` · `CLAUDE_CODE_SKIP_BEDROCK_AUTH` · `CLAUDE_CODE_USE_MANTLE` | Amazon Bedrock (Invoke API; model IDs like `us.anthropic.claude-opus-5`) |
| Provider | `CLAUDE_CODE_USE_VERTEX` · `CLOUD_ML_REGION` · `ANTHROPIC_VERTEX_PROJECT_ID` · `ANTHROPIC_VERTEX_BASE_URL` · `VERTEX_REGION_CLAUDE_*` · `CLAUDE_CODE_SKIP_VERTEX_AUTH` | Google Cloud's Agent Platform (Vertex AI) |
| Provider | `CLAUDE_CODE_USE_FOUNDRY` · `ANTHROPIC_FOUNDRY_RESOURCE`/`_BASE_URL` · `ANTHROPIC_FOUNDRY_API_KEY` · `ANTHROPIC_FOUNDRY_AUTH_TOKEN` · `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` | Microsoft Foundry |
| Provider | `CLAUDE_CODE_USE_ANTHROPIC_AWS` · `ANTHROPIC_AWS_WORKSPACE_ID` · `ANTHROPIC_AWS_API_KEY` · `ANTHROPIC_AWS_BASE_URL` | Claude Platform on AWS |
| Model | `ANTHROPIC_MODEL` · `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU,FABLE}_MODEL` · `CLAUDE_CODE_SUBAGENT_MODEL` · `CLAUDE_CODE_EFFORT_LEVEL` · `MAX_THINKING_TOKENS` · `CLAUDE_CODE_DISABLE_1M_CONTEXT` · `CLAUDE_CODE_AUTO_COMPACT_WINDOW` · `DISABLE_PROMPT_CACHING[_OPUS\|_SONNET\|_HAIKU\|_FABLE]` · `ENABLE_PROMPT_CACHING_1H` | Model selection, effort, thinking, context, caching |
| Tools | `BASH_DEFAULT_TIMEOUT_MS` (120000) · `BASH_MAX_TIMEOUT_MS` (600000) · `BASH_MAX_OUTPUT_LENGTH` · `CLAUDE_ENV_FILE` · `CLAUDE_CODE_SHELL` · `CLAUDE_CODE_GIT_BASH_PATH` · `CLAUDE_CODE_USE_POWERSHELL_TOOL` · `USE_BUILTIN_RIPGREP` | Bash/shell behaviour |
| MCP | `MCP_TIMEOUT` (30000) · `MCP_TOOL_TIMEOUT` · `MCP_CONNECT_TIMEOUT_MS` · `MCP_CONNECTION_NONBLOCKING` · `MAX_MCP_OUTPUT_TOKENS` (25000) · `ENABLE_TOOL_SEARCH` (`true\|auto\|auto:N\|false`) · `MCP_CLIENT_SECRET` · `ENABLE_CLAUDEAI_MCP_SERVERS` | MCP startup, limits, tool search, connectors |
| Limits | `CLAUDE_CODE_MAX_OUTPUT_TOKENS` · `CLAUDE_CODE_MAX_TURNS` · `API_TIMEOUT_MS` · `CLAUDE_CODE_MAX_RETRIES` · `CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY` (10) · `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (20) · `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (3) | Caps |
| Modes | `CLAUDE_CODE_SIMPLE` (= `--bare`) · `CLAUDE_CODE_SAFE_MODE` · `CLAUDE_CODE_SKIP_PROMPT_HISTORY` · `CLAUDE_CONFIG_DIR` · `CLAUDE_CODE_TMPDIR` | Minimal/clean/relocated sessions |
| Security | `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` · `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` · `CLAUDE_CODE_DISABLE_AUTO_MEMORY` · `CLAUDE_CODE_DISABLE_CLAUDE_MDS` | Strip credentials from subprocess env; memory loading |
| Features | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` · `CLAUDE_CODE_DISABLE_WORKFLOWS` · `CLAUDE_CODE_DISABLE_AGENT_VIEW` · `CLAUDE_CODE_DISABLE_FAST_MODE` · `CLAUDE_CODE_DISABLE_CRON` · `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` · `CLAUDE_CODE_ENABLE_TODO_TOOLS` · `CLAUDE_CODE_NEW_INIT` | Feature gates |
| Network | `HTTPS_PROXY` · `HTTP_PROXY` · `NO_PROXY` · `NODE_EXTRA_CA_CERTS` · `CLAUDE_CODE_CERT_STORE` (`bundled,system`) · `CLAUDE_CODE_CLIENT_CERT/_KEY/_KEY_PASSPHRASE` | Proxy, corporate CA, mTLS |
| Telemetry | `CLAUDE_CODE_ENABLE_TELEMETRY=1` + `OTEL_METRICS_EXPORTER`, `OTEL_LOGS_EXPORTER`, `OTEL_EXPORTER_OTLP_ENDPOINT/PROTOCOL/HEADERS`, `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS` · opt-outs `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` · updates `DISABLE_AUTOUPDATER`, `DISABLE_UPDATES` | Observability and privacy |
| Set *by* Claude Code in subprocesses/hooks | `CLAUDECODE=1` · `CLAUDE_CODE_SESSION_ID` · `CLAUDE_PROJECT_DIR` · `CLAUDE_PLUGIN_ROOT` · `CLAUDE_PLUGIN_DATA` · `CLAUDE_EFFORT` · `CLAUDE_ENV_FILE` · `CLAUDE_CODE_REMOTE` · `CLAUDE_PID` | For scripts, hooks, MCP servers |
| Set *by* Claude Code (cross-session messaging) | `CLAUDE_CODE_MESSAGING_SOCKET` · `CLAUDE_CODE_MESSAGING_TOKEN` | This session's inbox socket path (also shown in `/status` → `Peer address`, there prefixed `uds:`) and a per-session token, exported to hooks and Bash commands so a script can post back into its *own* session; send `{"type":"auth","token":"<token>"}` as the first line where process ancestry can't be verified (macOS after the poster exits, containers with Claude Code as PID 1). Exported before `SessionStart` when messaging is on at launch; each session exports its own, never a parent's. Sandboxed Bash reaches the socket only via `sandbox.network.allowUnixSockets` / `allowAllUnixSockets` |

Removed/no-op since 2025 material: `CLAUDE_CODE_ENABLE_AUTO_MODE` (auto mode is available without an opt-in on all providers since v2.1.207), `ANTHROPIC_SMALL_FAST_MODEL` (deprecated → `ANTHROPIC_DEFAULT_HAIKU_MODEL`). `MAX_THINKING_TOKENS=0` has no effect on adaptive-only models such as Fable 5.

Sources: https://code.claude.com/docs/en/env-vars · https://code.claude.com/docs/en/cross-session-messaging · https://code.claude.com/docs/en/network-config · https://code.claude.com/docs/en/amazon-bedrock · https://code.claude.com/docs/en/google-vertex-ai · https://code.claude.com/docs/en/microsoft-foundry · https://code.claude.com/docs/en/claude-platform-on-aws

---

## D. Settings, permissions, memory and sandbox

### D.0 Settings files, scopes and precedence

| Scope | Location | Affects | Shared? |
|---|---|---|---|
| Managed | Server-managed (claude.ai **Admin Settings → Claude Code → Managed settings**, Team/Enterprise) · macOS MDM domain `com.anthropic.claudecode` · Windows `HKLM\SOFTWARE\Policies\ClaudeCode` (`Settings` value) · file `managed-settings.json` + drop-ins `managed-settings.d/*.json` in `/Library/Application Support/ClaudeCode/` (macOS), `/etc/claude-code/` (Linux/WSL), `C:\Program Files\ClaudeCode\` (Windows) | Everyone in the org / on the machine | Deployed by IT |
| CLI | `--settings <file-or-json>`, `--setting-sources user,project,local` | This session | — |
| Local | `.claude/settings.local.json` (at the git repo root; auto-gitignored) | You, this repo | No |
| Project | `.claude/settings.json` | All collaborators | Commit it |
| User | `~/.claude/settings.json` (`%USERPROFILE%\.claude` on Windows) | You, every project | No |

**Precedence (highest first): Managed → CLI arguments → Local → Project → User.** Scalars: higher scope wins. **Arrays (e.g. `permissions.allow`, `sandbox.network.allowedDomains`) concatenate and de-duplicate across scopes** — lower scopes can add but never remove. A deny at any level cannot be re-allowed elsewhere. Some keys are deliberately *not* read from project/local settings because a cloned repo could plant them (`autoMode`, `pluginConfigs`, `permissions.defaultMode: "auto"`, `skipDangerousModePermissionPrompt`, sandbox `mask`, `spellcheck`, …). Files hot-reload (the `ConfigChange` hook fires); `model`/`outputStyle` apply on next start. Managed settings parse tolerantly but security keys fail closed; user/project/local files are strict (invalid file → **Settings Error** dialog). Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for editor validation. `~/.claude.json` is separate app state (OAuth session, trust decisions, user/local MCP servers) — `permissions`/`hooks`/`env` placed there are ignored.

Inspect: `/status` (shows *Setting sources*), `/config [key=value]`, `/permissions` (each rule with its source file), `/doctor`, `claude --debug`.

Sources: https://code.claude.com/docs/en/settings · https://code.claude.com/docs/en/server-managed-settings

### D.1 CLAUDE.md and memory layers

| Layer | Location | Loaded | Shared with |
|---|---|---|---|
| Managed CLAUDE.md | `/Library/Application Support/ClaudeCode/CLAUDE.md`, `/etc/claude-code/CLAUDE.md`, `C:\Program Files\ClaudeCode\CLAUDE.md`, or managed key `claudeMd` | Always; cannot be excluded | Org |
| User memory | `~/.claude/CLAUDE.md` + `~/.claude/rules/*.md` | Every project | You |
| Project memory | `./CLAUDE.md` or `./.claude/CLAUDE.md` + `.claude/rules/**/*.md` | Launch dir and every parent up to `/` (root-most first); subdirectory CLAUDE.md files load when Claude reads files there | Team (commit) |
| Local project memory | `./CLAUDE.local.md` (gitignore it yourself) | Appended after CLAUDE.md at that level | You |
| Path-scoped rules | `.claude/rules/*.md` with `paths:` frontmatter | Only when a matching file is read; lost on compaction until re-read | Team |
| Auto memory | `~/.claude/projects/<project>/memory/MEMORY.md` (+ topic files); `autoMemoryDirectory` relocates | First 200 lines / 25 KB of `MEMORY.md` every session; Claude writes it ("remember that …") | You (per machine, shared across worktrees of a repo) |
| Subagent memory | `.claude/agent-memory/<agent>/MEMORY.md` etc. via `memory:` frontmatter | When that subagent runs | Depends on scope |

Key facts:
* CLAUDE.md is delivered as context after the system prompt — **advisory, not enforced**. Use `permissions.deny`, hooks or the sandbox for guarantees.
* **Imports:** `@path/to/file` anywhere in CLAUDE.md (relative, absolute or `~`), recursive up to 4 hops; external imports prompt once. `AGENTS.md` is not read natively — write a CLAUDE.md containing `@AGENTS.md`, or `/import codex|gemini`.
* Path-scoped rule example: front matter `paths: ["src/api/**/*.ts"]` then the rule body.
* `/init` generates a starter CLAUDE.md (reads existing Cursor/Copilot rules; `CLAUDE_CODE_NEW_INIT=1` for the interactive multi-artifact flow). `/memory` lists/opens all layers and toggles auto memory (`autoMemoryEnabled`, `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`). `/context` shows what actually loaded. `claudeMdExcludes` skips other teams' files in monorepos.
* Guidance: keep each file under ~200 lines, specific and verifiable; move long reference material into skills; add a "Compact instructions" section to steer `/compact`. `/doctor` proposes trims.
* What survives compaction: project-root CLAUDE.md, unscoped rules and auto memory are re-injected; nested CLAUDE.md and path-scoped rules reload when files are touched again; invoked skill bodies re-injected (5K tokens each / 25K total).

Sources: https://code.claude.com/docs/en/memory · https://code.claude.com/docs/en/context-window

### D.2 Permission modes and start-mode matrix

| Mode (`permissions.defaultMode` / `--permission-mode`) | Runs without asking | Best for | Indicator |
|---|---|---|---|
| `default` (UI label **Manual**; alias `manual`) | Reads only (plus read-only Bash set: `ls`, `cat`, `git status`, …) | Sensitive work, first contact with a repo | `⏸ manual mode on` |
| `acceptEdits` | Reads, file edits, common fs commands (`mkdir touch rm rmdir mv cp sed`) inside working dirs | Iterating while reviewing with `git diff` | `⏵⏵ accept edits on` |
| `plan` | Reads (+ classifier-approved exploration when auto is available, `useAutoModeDuringPlan`) ; no edits | Explore → plan → approve | `⏸ plan mode on` |
| `auto` | Everything, each action reviewed by a background **classifier**; broad allow rules (`Bash(*)`, interpreter wildcards, `Agent`) are dropped on entry; pauses after 3 consecutive / 20 total blocks | Long tasks with fewer prompts | `⏵⏵ auto mode on` |
| `dontAsk` | Only pre-approved tools (`permissions.allow`, read-only Bash, hook allows); everything else auto-**denied** | Locked-down CI / scripts (`-p`) | `⏵⏵ don't ask on` |
| `bypassPermissions` (`--dangerously-skip-permissions`) | Everything incl. protected paths; still honors deny/ask rules, `requiresUserInteraction` tools, critical-path `rm` | Isolated containers/VMs only; refused as root; no prompt-injection protection | `⏵⏵ bypass permissions on` |

Never auto-approved in any mode: explicit `ask` rules; MCP tools marked `requiresUserInteraction`; `rm`/`rmdir` on critical paths (root, home, working dir and parents); writes to **protected paths** (`.git`, `.claude` except worktrees, `.vscode`, `.idea`, shell rc files, `.mcp.json`, `.claude.json`, `.npmrc`, …) except in bypass.

**Which mode a session starts in** (first match wins) **[volatile]**:

| Condition | Start mode |
|---|---|
| `--permission-mode <m>` / `--dangerously-skip-permissions` | that mode |
| `permissions.defaultMode` in a settings file (`"auto"` is ignored in *project*/*local* files) | that mode |
| Any settings file sets `disableAutoMode: "disable"`; feature flags unavailable; first run after install/upgrade | `default` |
| `claude -p` or Agent SDK | `default` |
| Bedrock, Google Cloud's Agent Platform, Foundry, Claude Platform on AWS, Claude apps gateway | `default` |
| **Pro, Max or Team plan** in terminal or VS Code (v2.1.228+ macOS/Linux/WSL, v2.1.233+ Windows; effective 2026-08-14) | **`auto`** |
| Enterprise plan or Console API key | `default` |

Switching: `Shift+Tab` cycles `default → acceptEdits → plan` (+ `bypassPermissions` if launched with it, + `auto` last); `dontAsk` only via flag/setting; asking Claude in chat does not change the mode. Plan approval dialog offers *Yes, and use auto mode* / *Yes, manually approve edits* / *No, keep planning*; `Ctrl+G` edits the plan first. Auto-mode configuration lives in `autoMode.{environment,allow,soft_deny,hard_deny,classifyAllShell}` (user/managed/`--settings` only; keep `"$defaults"`); `claude auto-mode defaults|config|reset`. Admin switches: `permissions.disableBypassPermissionsMode: "disable"`, `permissions.disableAutoMode: "disable"`.

Sources: https://code.claude.com/docs/en/permission-modes · https://code.claude.com/docs/en/auto-mode-config

### D.3 Permission-rule grammar

Evaluation order: **deny → ask → allow; first match wins regardless of specificity** (a broad deny cannot be pierced by a narrow allow). Rules are enforced by Claude Code, not by the model. `PreToolUse` hooks run before rules but cannot override a deny/ask rule; a hook exit 2 blocks even when an allow rule matches.

| Rule form | Matches | Examples |
|---|---|---|
| `Tool` | Every use of the tool (bare deny removes the tool from context) | `Bash`, `WebSearch`, `Agent`, `Skill`, `"mcp__*"`, `"*"` (deny/ask only) |
| `Bash(pattern)` / `PowerShell(pattern)` | Command text; `*` glob anywhere; a space before `*` enforces a word boundary; each subcommand of `&&`, `\|`, `;` must match separately; wrappers like `timeout`, `nice`, `xargs`, `VAR=x` are stripped | `Bash(npm run build)`, `Bash(npm run test *)`, `Bash(git * main)`, `Bash(* --version)`; legacy `Bash(ls:*)` = `Bash(ls *)` |
| `Read(path)` / `Edit(path)` | gitignore-style globs; `Edit` covers all edit tools; a `Read` deny also blocks Edit/Write. `//abs`, `~/home`, `/relative-to-settings-file`, `./` or bare = relative to cwd; `*` one segment, `**` recursive | `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)`, `Edit(/src/**/*.ts)`, `Read(~/.ssh/**)`, `Read(//etc/**)` |
| `WebFetch(domain:host)` | Hostname (`*.example.com` = subdomains only) | `WebFetch(domain:docs.python.org)` |
| `mcp__server`, `mcp__server__tool`, `mcp__server__*` | MCP tools (allow globs only after the literal `mcp__<server>__` prefix) | `mcp__astro-catalog__*`, `mcp__github__get_*` |
| `Agent(name)` | Subagent type | `Agent(Explore)`, `Agent(bug-hunter)` |
| `Skill(name [args])` | Skill invocation | `Skill(commit)`, `Skill(deploy *)` |
| `Cd(path)` | The user-run `/cd` command | `Cd(~/code/**)` |
| `Tool(param:value)` (deny/ask only) | One top-level scalar input parameter | `Agent(model:opus)`, `Bash(dangerouslyDisableSandbox:true)`, `Bash(run_in_background:true)` |

Notes: argument-constraining Bash rules (`Bash(curl http://x/*)`) are fragile — prefer denying `curl`/`wget` and allowing `WebFetch(domain:…)`, hooks, or the sandbox. Read/Edit denies apply to Claude's file tools and recognized file commands, not arbitrary subprocesses — use the sandbox for OS-level enforcement. `Write(...)`, `Glob(...)`, `MultiEdit(...)` path rules are accepted but ignored with a warning. Project `allow` rules and `additionalDirectories` apply only after the workspace trust dialog (never shown in `-p`).

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "defaultMode": "default",
    "allow": ["Bash(go test *)", "Bash(npm test *)", "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)"],
    "ask":   ["Bash(git push *)", "Bash(gh pr create *)"],
    "deny":  ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)", "Bash(curl *)", "Bash(wget *)"],
    "additionalDirectories": ["../docs/"]
  }
}
```

Sources: https://code.claude.com/docs/en/permissions · starter configs https://github.com/anthropics/claude-code/tree/main/examples/settings

### D.4 Managed (enterprise) settings

Delivery channels (same JSON): server-managed from the claude.ai admin console (Team/Enterprise; cached `~/.claude/remote-settings.json`, polled hourly) · MDM plist / Windows registry · `managed-settings.json` + `managed-settings.d/*.json` drop-ins (merged alphabetically; scalars override, arrays concatenate) · `policyHelper` executable · Claude apps gateway policies. Managed values cannot be overridden by users, projects or CLI flags. Starter templates: https://github.com/anthropics/claude-code/tree/main/examples/mdm .

| Org-policy key (most are honored only from managed settings) | Effect |
|---|---|
| `allowManagedPermissionRulesOnly` | Only managed `allow/ask/deny` rules apply |
| `allowManagedHooksOnly` | Only managed hooks, SDK hooks and hooks from managed force-enabled plugins run |
| `allowManagedMcpServersOnly` + `allowedMcpServers` / `deniedMcpServers` | MCP allow/deny lists (`serverUrl`, `serverCommand`, `serverName` entries; deny always wins) |
| `strictKnownMarketplaces` (alias `allowedMarketplaces`) / `blockedMarketplaces` | Marketplace allowlist (`[]` = total lockdown) / blocklist; owner wildcards `acme/*` |
| `strictPluginOnlyCustomization` (`true` or `["skills","hooks","mcp",…]`) | Block skills/agents/hooks/MCP from user & project sources; only plugins + managed |
| `disableSideloadFlags` | Reject `--plugin-dir`, `--plugin-url`, `--agents`, `--mcp-config` |
| `forceLoginMethod` / `forceLoginOrgUUID` / `forceLoginGatewayUrl` | Restrict how/where users log in |
| `availableModels` + `enforceAvailableModels` | Model allowlist |
| `requiredMinimumVersion` / `requiredMaximumVersion` | Refuse to start outside the version range |
| `sandbox.network.allowManagedDomainsOnly` / `sandbox.filesystem.allowManagedReadPathsOnly` | Lock sandbox lists to managed entries |
| `permissions.disableBypassPermissionsMode: "disable"` / `disableAutoMode: "disable"` (any scope, restrictive wins) | Remove modes |
| `channelsEnabled`, `allowedChannelPlugins`, `pluginTrustMessage`, `pluginSuggestionMarketplaces`, `disableCommandPluginSources`, `allowAllClaudeAiMcps`, `forceRemoteSettingsRefresh`, `wslInheritsWindowsSettings`, `claudeMd`, `companyAnnouncements` | Misc org controls |

Related enterprise surfaces: managed `CLAUDE.md`; `managed-mcp.json` (exclusive MCP control, §F.7); org model restrictions / default model / effort limits in the admin console; usage analytics and Analytics API; OpenTelemetry export (`CLAUDE_CODE_ENABLE_TELEMETRY`); Claude apps gateway (`claude gateway`); providers Bedrock / Google Cloud / Foundry / Claude Platform on AWS.

Sources: https://code.claude.com/docs/en/permissions#managed-settings · https://code.claude.com/docs/en/server-managed-settings · https://code.claude.com/docs/en/third-party-integrations

### D.5 Most-used settings keys

| Key | Type / example | Meaning |
|---|---|---|
| `model` | `"opus"` \| `"claude-sonnet-5"` | Default model |
| `effortLevel` | `"low"\|"medium"\|"high"\|"xhigh"` | Persisted effort |
| `availableModels`, `fallbackModel`, `modelOverrides`, `advisorModel` | arrays / map / string | Model policy (§B.2) |
| `alwaysThinkingEnabled`, `showThinkingSummaries`, `fastMode` | booleans | Thinking / fast mode |
| `permissions.allow` / `.ask` / `.deny` | `["Bash(git diff *)"]` | Rule arrays (merge across scopes) |
| `permissions.defaultMode` | `"default"\|"acceptEdits"\|"plan"\|"auto"\|"dontAsk"\|"bypassPermissions"` | Start mode |
| `permissions.additionalDirectories` | `["../docs/"]` | Extra working dirs (file access) |
| `permissions.disableBypassPermissionsMode` | `"disable"` | Block bypass everywhere |
| `autoMode` | `{"environment":["$defaults",…],"allow":[…],"soft_deny":[…],"hard_deny":[…]}` | Prose rules for the classifier (user/managed only) |
| `hooks` | object | §E |
| `disableAllHooks` | `true` | Also disables custom status line |
| `allowedHttpHookUrls`, `httpHookAllowedEnvVars` | arrays | HTTP-hook allowlists |
| `sandbox` | object | §D.6 |
| `env` | `{"FOO":"bar"}` | Env for Claude Code and subprocesses |
| `apiKeyHelper` | `"/bin/get_key.sh"` | Script returning an API key/token |
| `awsAuthRefresh`, `awsCredentialExport`, `gcpAuthRefresh` | commands | Cloud credential refresh |
| `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers` | bool / arrays | Approve `.mcp.json` servers |
| `disableClaudeAiConnectors` | `true` | Opt out of claude.ai connectors |
| `enabledPlugins` | `{"codebase-toolkit@workshop-marketplace": true}` | Enable/disable plugins (§H.2) |
| `extraKnownMarketplaces` (alias `additionalMarketplaces`) | `{"acme":{"source":{"source":"github","repo":"acme/plugins"}}}` | Pre-register marketplaces |
| `pluginConfigs` | `{"x@mkt":{"options":{…}}}` | Plugin `userConfig` values (user/managed only) |
| `autoMemoryEnabled`, `autoMemoryDirectory`, `claudeMdExcludes`, `includeGitInstructions` | | Memory/instructions loading |
| `autoCompactWindow`, `autoCompactEnabled`, `cleanupPeriodDays` (30) | | Compaction / retention |
| `agent` | `"code-reviewer"` | Run main thread as a subagent |
| `outputStyle`, `statusLine` (`{"type":"command","command":"~/.claude/statusline.sh"}`), `theme`, `tui`, `editorMode`, `preferredNotifChannel`, `language`, `spinnerTipsEnabled`, `viewMode` | | UX |
| `attribution` | `{"commit":"…","pr":"","sessionUrl":false}` | Commit trailer / PR text (replaces `includeCoAuthoredBy`) |
| `skillOverrides` | `{"deploy":"off"}` | Per-skill visibility (`on`/`name-only`/`user-invocable-only`/`off`) |
| `disableBundledSkills`, `disableWorkflows`, `disableSkillShellExecution`, `workflowSizeGuideline` | | Skills/workflows controls |
| `worktree.baseRef` / `.symlinkDirectories` / `.sparsePaths` / `.bgIsolation` | | Worktree behaviour |
| `remote.defaultEnvironmentId` | `"env_…"` | Default cloud environment for `--cloud` |
| `crossSessionInbound` | `"accept"\|"hold"\|"refuse"` | What this session does with messages from your other sessions: deliver, hold (notice only; released if an `accept` later applies), or drop. Unset → decided per message from the two sessions' permission-mode classes: a prompting session (incl. auto/`acceptEdits`/`dontAsk`) delivers, holding only messages from bypass-permissions senders; a bypass-permissions session holds each behind an approval dialog unless the sender also bypasses. `refuse` in project/local settings beats every other source; also settable from `/config` → *Messages from your other sessions* (v2.1.232+, writes user settings) |
| `isolatePeerMachines` | `true` | Require your approval before any `SendMessage` leaves this machine (Remote Control / cloud targets), even in `bypassPermissions`; `true` from any scope wins, so a project file can turn it on but not off. Same-machine messages never prompt |
| `dialogExpiry` | default 5 minutes; `"never"` | How long a *default-held* cross-session message waits (approval dialog, or silently in a `-p` session) before it is dropped and reported expired to the sender; a detached background session keeps the dialog open until you attach. Messages held by an explicit `"hold"` never expire |
| `autoUpdatesChannel`, `minimumVersion` | `"stable"`, `"2.1.200"` | Update policy |
| `respondToBashCommands`, `promptSuggestionEnabled`, `awaySummaryEnabled`, `showClearContextOnPlanAccept`, `useAutoModeDuringPlan` | booleans | Interaction toggles |

Global-config keys that belong in `~/.claude.json` (ignored in settings.json): `autoConnectIde`, `autoInstallIdeExtension`, `diffTool`, `permissionExplainerEnabled`.

Source: https://code.claude.com/docs/en/settings · https://code.claude.com/docs/en/cross-session-messaging

### D.6 Sandboxed Bash tool and isolation options

* **What it isolates:** every Bash command and its children — filesystem writes and network egress enforced by the OS (macOS Seatbelt; Linux/WSL2 bubblewrap + socat: `sudo apt-get install bubblewrap socat`). **Not** isolated: Read/Edit/Write tools (governed by rules), MCP servers, hooks, computer use. Native Windows and WSL1 unsupported.
* **Enable:** `/sandbox` (Mode / Overrides / Config / Dependencies tabs; saved to local settings) or `"sandbox": {"enabled": true}`. Defaults: write only to cwd + session temp; read anywhere not denied (deny `~/.ssh`, `~/.aws/credentials` yourself); **no** network hosts pre-allowed (first contact prompts or goes to the classifier). Protected paths (`.claude/*`, `.mcp.json`, rc files, `.git/hooks`, `~/.claude`) stay write-denied.
* **Modes:** *auto-allow* (`autoAllowBashIfSandboxed: true`, default) runs sandboxable commands without prompting even in Manual mode; deny/ask rules and critical-path `rm` still gate. Escape hatch: Claude may retry with `dangerouslyDisableSandbox: true` through the normal permission flow — forbid with `"allowUnsandboxedCommands": false`.

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "autoAllowBashIfSandboxed": true,
    "allowUnsandboxedCommands": false,
    "excludedCommands": ["docker *"],
    "filesystem": { "allowWrite": ["/tmp/build"], "denyWrite": ["/etc"], "denyRead": ["~/.ssh", "~/.aws"], "allowRead": ["."] },
    "network": {
      "allowedDomains": ["proxy.golang.org", "registry.npmjs.org", "api.github.com"],
      "deniedDomains": ["uploads.github.com"],
      "strictAllowlist": false,
      "allowUnixSockets": [], "allowLocalBinding": true,
      "httpProxyPort": 8080, "socksProxyPort": 8081
    },
    "credentials": {
      "files":   [{ "path": "~/.aws/credentials", "mode": "deny" }],
      "envVars": [{ "name": "GITHUB_TOKEN", "mode": "deny" },
                  { "name": "GH_TOKEN", "mode": "mask", "injectHosts": ["api.github.com"] }]
    },
    "enableWeakerNestedSandbox": false
  }
}
```

Managed extras: `network.allowManagedDomainsOnly`, `filesystem.allowManagedReadPathsOnly`, `bwrapPath`, `socatPath`. Recommended fleet enforcement: `{"sandbox":{"enabled":true,"failIfUnavailable":true,"allowUnsandboxedCommands":false}}`. `credentials.mode: "mask"` requires `network.tlsTerminate` and shows a sentinel to the process while the proxy injects the real value only toward `injectHosts`. Independent of the sandbox: `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` strips Anthropic/cloud credentials from all subprocess environments.

| Isolation approach | Isolates | Setup | Use |
|---|---|---|---|
| Sandboxed Bash (`/sandbox`) | Bash + children | Minimal / low | Fewer prompts locally; the only option enforceable via managed settings |
| sandbox-runtime (`npx @anthropic-ai/sandbox-runtime claude`) | Whole Claude Code process incl. file tools, MCP, hooks | Low | Unattended runs; scanning untrusted repos (M7) |
| Dev container (reference `.devcontainer` with default-deny firewall) | Full dev env | Medium (Docker) | Team standard; safe place for `--dangerously-skip-permissions` |
| Custom container / VM / microVM | Full OS | Medium–high | CI fleets, untrusted code, Agent SDK hosting (§K.4) |
| Claude Code on the web (`--cloud`) | Anthropic-managed VM with egress proxy and scoped git creds | None | Full isolation without provisioning |

Sources: https://code.claude.com/docs/en/sandboxing · https://code.claude.com/docs/en/sandbox-environments · https://code.claude.com/docs/en/devcontainer · https://github.com/anthropic-experimental/sandbox-runtime

### D.7 The `.claude/` directory map

```text
your-project/
├── CLAUDE.md                     # project instructions (or .claude/CLAUDE.md); committed
├── CLAUDE.local.md               # your private notes; gitignore it
├── .mcp.json                     # project MCP servers ("mcpServers"); NOT inside .claude/
└── .claude/
    ├── settings.json             # permissions, hooks, env, sandbox, plugins; committed
    ├── settings.local.json       # personal overrides + "don't ask again" rules; auto-gitignored
    ├── rules/*.md                # topic rules; optional `paths:` frontmatter
    ├── skills/<name>/SKILL.md    # skills (+ supporting files)
    ├── commands/*.md             # legacy single-file skills
    ├── agents/*.md               # subagents
    ├── hooks/                    # convention for hook scripts referenced from settings.json
    ├── workflows/*.js            # saved dynamic workflows -> /<name>
    ├── output-styles/*.md
    ├── worktrees/                # worktrees created by --worktree / background sessions
    └── agent-memory/<agent>/MEMORY.md
~/.claude/                        # user scope (relocate with CLAUDE_CONFIG_DIR)
    CLAUDE.md  settings.json  keybindings.json  themes/  rules/  skills/  commands/  agents/  workflows/
    projects/<project>/memory/MEMORY.md          # auto memory
    projects/<project>/<session>.jsonl (+ subagents/, tool-results/)   # transcripts, 30-day sweep
    plugins/ (marketplaces, cache, data)  plans/  debug/  .credentials.json (Linux/Windows)
~/.claude.json                    # app state: OAuth, trust decisions, user+local MCP servers
```

Sources: https://code.claude.com/docs/en/claude-directory · https://code.claude.com/docs/en/debug-your-config

---

## E. Hooks reference

### E.1 Concept, locations, security

Hooks are user-defined handlers — shell commands, HTTP endpoints, MCP tool calls, LLM prompts or agent verifiers — that Claude Code runs deterministically at lifecycle points. Structure: **event → matcher group → handler list**. All matching hooks run in parallel; hooks from every scope **merge** (user + project + local add to managed; identical handlers de-duplicated). They also fire inside subagents (`agent_id`/`agent_type` present).

| Where defined | Scope |
|---|---|
| `~/.claude/settings.json` → `"hooks"` | All your projects (not read by cloud sessions) |
| `.claude/settings.json` / `.claude/settings.local.json` | Project (shared / personal) |
| Managed settings | Organization |
| Plugin `hooks/hooks.json` (or `hooks` in `plugin.json`) | While plugin enabled; use `${CLAUDE_PLUGIN_ROOT}` |
| Skill frontmatter `hooks:` | Rest of session after the skill is invoked (`once: true` supported) |
| Subagent frontmatter `hooks:` | While that subagent runs (`Stop` → `SubagentStop`) |
| Agent SDK `options.hooks` | In-process callbacks (§K.6) |

Security: command hooks run with **your full user permissions**. In interactive sessions hooks are held back until you accept the workspace trust dialog; **`-p`/SDK sessions have no dialog, so hooks in a cloned repo's `.claude/settings.json` run** — use `--bare`, `--setting-sources user`, or `--settings '{"disableAllHooks": true}'` on untrusted checkouts. Quote variables, use `"$CLAUDE_PROJECT_DIR"` absolute paths, block `..`. `/hooks` is a read-only viewer; edits to settings hot-reload.

### E.2 Configuration schema

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
            "statusMessage": "Checking protected paths..." }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "if": "Bash(rm *)",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh", "args": [] }
        ]
      }
    ],
    "PostToolUse": [
      { "matcher": "Bash",
        "hooks": [ { "type": "command",
          "command": "jq -r '.tool_input.command' >> \"$CLAUDE_PROJECT_DIR\"/.claude/bash-audit.log" } ] }
    ]
  }
}
```

**Handler types**

| `type` | Runs | Result via | Extra fields |
|---|---|---|---|
| `command` | Shell command (`sh -c`, Git Bash, or PowerShell per `shell`); with `args` = exec form (no shell) | Exit code + stdout/stderr JSON | `command`, `args`, `async`, `asyncRewake`, `shell: "bash"\|"powershell"` |
| `http` | POST event JSON to `url` | 2xx + JSON body (status code alone never blocks) | `url`, `headers` (`$VAR` interpolation limited to `allowedEnvVars`); global `allowedHttpHookUrls`, `httpHookAllowedEnvVars` |
| `mcp_tool` | Calls a tool on an already-connected MCP server | Tool text output treated like stdout | `server`, `tool`, `input` (with `${tool_input.file_path}`-style substitution) |
| `prompt` | Single-turn LLM check (fast model by default) | Model returns `{"ok": bool, "reason": "..."}` | `prompt` (`$ARGUMENTS` = event JSON), `model`, `continueOnBlock` |
| `agent` (experimental) | Subagent with Read/Grep/Glob… up to 50 turns | `{"ok", "reason"}` | `prompt`, `model`, `timeout` |

Common fields: `type` (required), `if` (one permission-rule expression, tool events only, e.g. `"Bash(git push *)"`, `"Edit(**/pb/**)"`), `timeout` (s; default 600 command/http/mcp_tool, 30 prompt, 60 agent; `UserPromptSubmit` 30; `SessionEnd` shares 1.5 s), `statusMessage`, `once` (skill frontmatter only). Type support: all five types on tool/turn events (`PreToolUse`, `PostToolUse`, `Stop`, `UserPromptSubmit`, …); `command`/`http`/`mcp_tool` only on lifecycle events (`SessionEnd`, `ConfigChange`, `Notification`, `PreCompact`, …); `SessionStart`/`Setup` accept `command` and `mcp_tool` only.

**Matcher syntax:** `"*"`, `""` or omitted = all; only letters/digits/`_`/`-`/spaces/`,`/`|` = exact name or list (`Edit|Write`, `Edit, Write`); anything else = unanchored JavaScript regex (`^Edit$`, `mcp__memory__.*`). Tool matchers use tool names: `Bash`, `PowerShell`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `ExitPlanMode`, `mcp__<server>__<tool>` (plugin servers: `mcp__plugin_<plugin>_<server>__<tool>`).

**Placeholders / env in hooks:** `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` (also exported as env vars); `CLAUDE_ENV_FILE` (append `export …` lines from `SessionStart`/`Setup`/`CwdChanged`/`FileChanged`; sourced before every Bash command); `CLAUDE_EFFORT`; `CLAUDE_CODE_SESSION_ID`; `CLAUDE_CODE_REMOTE=true` in cloud sessions; plugin options as `CLAUDE_PLUGIN_OPTION_<KEY>`.

### E.3 Input / output contract

**stdin (command) or POST body (http)** — common fields: `session_id`, `prompt_id`, `transcript_path`, `cwd`, `permission_mode`, `effort.level`, `hook_event_name`, plus `agent_id`/`agent_type` inside subagents. Tool events add `tool_name`, `tool_input` (Bash `{command, description, timeout, run_in_background}`; Write `{file_path, content}`; Edit `{file_path, old_string, new_string, replace_all}`; Read `{file_path, offset, limit}`; WebFetch `{url, prompt}`; Agent `{prompt, description, subagent_type, model}`; …), `tool_use_id`; `PostToolUse` adds `tool_response`, `duration_ms`.

```json
{ "session_id": "abc123", "cwd": "/home/user/otel", "permission_mode": "default",
  "hook_event_name": "PreToolUse", "tool_name": "Edit",
  "tool_input": { "file_path": "/home/user/otel/pb/demo_pb2.py", "old_string": "…", "new_string": "…" },
  "tool_use_id": "toolu_01ABC…" }
```

**Exit codes (command hooks)**

| Exit | Meaning |
|---|---|
| `0` | Success. stdout starting with `{` is parsed as JSON; plain stdout goes to the debug log **except** `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart` where it is added to context |
| `2` | **Blocking** on events that can block: `PreToolUse` (tool call blocked, stderr fed to Claude), `UserPromptSubmit` (prompt erased), `Stop`/`SubagentStop` (must continue; stderr becomes next instruction), `PostToolBatch`, `PreCompact`, `ConfigChange` (except policy), `TaskCreated/Completed`, `TeammateIdle`, `Elicitation*`, `WorktreeCreate` (any non-zero). On `PostToolUse` exit 2 only shows stderr to Claude (tool already ran) |
| other | Non-blocking error: transcript shows `<hook> hook error`, action proceeds (a mistyped script path = exit 127 = silently non-blocking) |

**JSON output (exit 0, single object on stdout)** — universal: `continue` (false = stop entirely), `stopReason`, `systemMessage` (shown to user), `terminalSequence`. Event-specific via top-level `decision: "block"` + `reason` (`UserPromptSubmit`, `PostToolUse`, `Stop`, `SubagentStop`, `PreCompact`, `ConfigChange`, `PostToolBatch`) or `hookSpecificOutput`:

| Event | `hookSpecificOutput` fields |
|---|---|
| `PreToolUse` | `permissionDecision: "allow"\|"deny"\|"ask"\|"defer"` (deny > defer > ask > allow across hooks; `ask` forces a prompt even in auto mode; `defer` = `-p` only, exits with `stop_reason: "tool_deferred"`), `permissionDecisionReason`, `updatedInput` (replaces whole input), `additionalContext` |
| `PermissionRequest` | `decision: {behavior: "allow"\|"deny", updatedInput, updatedPermissions[{type: addRules\|setMode\|addDirectories, …, destination: session\|localSettings\|projectSettings\|userSettings}], message, interrupt}` |
| `PermissionDenied` (auto mode) | `retry: true` |
| `PostToolUse` | `additionalContext`, `updatedToolOutput` (what Claude sees) |
| `SessionStart` | `additionalContext`, `initialUserMessage`, `sessionTitle`, `watchPaths`, `reloadSkills` |
| `UserPromptSubmit` | `additionalContext`, `sessionTitle` (cannot rewrite the prompt) |
| `Elicitation` / `ElicitationResult` | `action: accept\|decline\|cancel`, `content` |
| `WorktreeCreate` | absolute path as last stdout line (HTTP: `worktreePath`) |

`additionalContext` is wrapped in a system reminder at the point the hook fired (write facts, not commands); strings capped at 10,000 chars.

### E.4 Full event table

| Event | Fires when | Matcher filters on | Can block? | Typical use |
|---|---|---|---|---|
| `SessionStart` | Session begins/resumes (`startup`, `resume`, `clear`, `compact`, `fork`) | source | No | Inject git/branch context, install deps in cloud sessions, export env via `CLAUDE_ENV_FILE` |
| `Setup` | `claude --init-only`, `-p --init`, `-p --maintenance` | `init`\|`maintenance` | No | One-time repo bootstrap in CI images |
| `InstructionsLoaded` | A CLAUDE.md / rule file is loaded | load_reason | No | Debug which memory files load |
| `UserPromptSubmit` | Prompt submitted, before Claude sees it | — | Yes | Add context, block secrets in prompts, set session title |
| `UserPromptExpansion` | A typed `/command` expands | command_name | Yes | Gate/annotate skill invocations |
| `PreToolUse` | Before a tool call executes | tool name | **Yes** | Protect files, block dangerous commands, rewrite inputs, force `ask` |
| `PermissionRequest` | A permission prompt is about to show | tool name | via JSON decision | Auto-approve/deny classes of prompts, persist rules |
| `PermissionDenied` | Auto-mode classifier denied a call | tool name | No | Telemetry; allow retry |
| `PostToolUse` | Tool succeeded | tool name | feedback only | Audit log, auto-format, run tests async, redact output |
| `PostToolUseFailure` | Tool errored | tool name | No | Add hints after failures |
| `PostToolBatch` | All parallel calls in a batch resolved | — | Yes | Aggregate checks before next model call |
| `Notification` | Claude Code notifies (`permission_prompt`, `idle_prompt`, `agent_needs_input`, `agent_completed`, …) | notification_type | No | Desktop/Slack notifications |
| `SubagentStart` / `SubagentStop` | Subagent spawned / finished | agent type | No / Yes | Inject context; enforce subagent completion criteria |
| `TaskCreated` / `TaskCompleted` | Task list item created / marked done | — | Yes | Team workflows, gating |
| `Stop` | Main agent finished a turn (not on interrupt) | — | **Yes** (max 8 consecutive blocks) | "Don't stop until tests ran" (`stop_hook_active` guard) |
| `StopFailure` | Turn ended on API error (`rate_limit`, `authentication_failed`, …) | error type | No | Alerting |
| `TeammateIdle` | Agent-team teammate going idle | — | Yes | Keep teammates working |
| `ConfigChange` | Settings/skills file changed mid-session | source (`user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`) | Yes (not policy) | Detect settings drift (M7) |
| `CwdChanged` / `DirectoryAdded` / `FileChanged` | `/cd`; `/add-dir`; watched file changed | — / source / literal filenames | No | direnv-style env refresh (`watchPaths`) |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle (replaces git) | — | Yes (create) / No | Non-git VCS checkouts |
| `PreCompact` / `PostCompact` | Around compaction | `manual`\|`auto` | Yes / No | Preserve context; log summaries |
| `Elicitation` / `ElicitationResult` | MCP server asks the user for input / user answered | MCP server name | Yes | Auto-answer or veto elicitations |
| `MessageDisplay` | Assistant text renders | — | No | Rewrite on-screen text only |
| `SessionEnd` | Session terminates (`clear`, `resume`, `logout`, `prompt_input_exit`, `other`) | reason | No (1.5 s budget) | Flush logs, cleanup |

### E.5 Examples

Block edits to protected/generated files (`.claude/hooks/protect-files.sh`, `chmod +x`):

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
FILE_PATH="${FILE_PATH//\\//}"          # normalize Windows backslashes
for pattern in ".env" "_pb2.py" ".pb.go" "/pb/" "package-lock.json"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done
exit 0
```

JSON-decision variant (deny, or downgrade to `ask`):

```bash
#!/bin/bash
CMD=$(jq -r '.tool_input.command')
if echo "$CMD" | grep -Eq 'curl[^|]*\|\s*(ba)?sh'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
         permissionDecisionReason:"curl | sh is blocked by policy"}}'
fi
exit 0
```

`SessionStart` context injection (`.claude/hooks/gitlog.sh`, registered under `"SessionStart": [{"matcher": "startup|resume", "hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/gitlog.sh"}]}]`):

```bash
#!/bin/bash
LOG=$(git log -5 --oneline 2>/dev/null | tr '\n' ';')
jq -n --arg ctx "Recent commits: $LOG" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
```

Prompt-type Stop hook and HTTP hook:

```json
{ "hooks": {
  "Stop": [ { "hooks": [ { "type": "prompt", "timeout": 30,
    "prompt": "Here is the turn context: $ARGUMENTS. Return ok=false with a reason if code was changed but no test command was run." } ] } ],
  "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "http", "url": "http://localhost:8080/hooks/pre-tool-use",
    "headers": { "Authorization": "Bearer $AUDIT_TOKEN" }, "allowedEnvVars": ["AUDIT_TOKEN"], "timeout": 10 } ] } ] } }
```

Test a script by hand: `echo '{"tool_name":"Edit","tool_input":{"file_path":"/x/.env"}}' | .claude/hooks/protect-files.sh; echo $?`. Debug with `claude --debug-file /tmp/cc.log` and `/hooks`. Managed controls: `allowManagedHooksOnly`, `strictPluginOnlyCustomization`, `disableAllHooks`. Reference example: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

Sources: https://code.claude.com/docs/en/hooks · https://code.claude.com/docs/en/hooks-guide · https://code.claude.com/docs/en/plugins-reference

---

## F. MCP reference

### F.1 `claude mcp` commands

General shape: `claude mcp add [options] <name> -- <command> [args…]` (stdio) or `claude mcp add --transport http <name> <url>`. Options go **before** the name: `-s/--scope local|project|user`, `-t/--transport stdio|http|sse`, `-e/--env KEY=value` (repeatable), `-H/--header "Name: value"`, `--callback-port`, `--client-id`, `--client-secret`.

| Command | Purpose |
|---|---|
| `claude mcp add --transport stdio --scope project astro-catalog -- node ./labs/mcp/astro-catalog/server.mjs` | Local stdio server, written to `.mcp.json` |
| `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` then `/mcp` → Authenticate | Remote streamable-HTTP server with OAuth **[verify URL on day]** |
| `claude mcp add --transport http secure https://api.example.com/mcp --header "Authorization: Bearer $TOKEN"` | Static header auth |
| `claude mcp add --env AIRTABLE_API_KEY=… --transport stdio airtable -- npx -y airtable-mcp-server` | Env for the server process (put another option between `--env` and the name) |
| `claude mcp add-json <name> '<json>' [--scope user]` | Add from the JSON entry shape (also the only way to add `type: "ws"`) |
| `claude mcp add-from-claude-desktop` | Import from Claude Desktop (macOS/WSL) |
| `claude mcp list` · `claude mcp get <name>` | Health (`✔ Connected`, `! Needs authentication`, `✘ Failed`, `⏸ Pending approval`) and details |
| `claude mcp remove <name> [--scope …]` | Remove |
| `claude mcp reset-project-choices` | Re-prompt for `.mcp.json` server approval |
| `claude mcp login <name> [--no-browser]` · `claude mcp logout <name>` | Run/clear a server's OAuth flow from the shell |
| `claude mcp serve` | Run Claude Code itself as a stdio MCP server (§F.6) |
| `/mcp [reconnect <srv> \| enable\|disable [<srv>\|all]]` | In-session manager: status, tools, authenticate, toggle |

### F.2 Scopes and transports

| Scope (`--scope`) | Stored in | Loads in | Shared |
|---|---|---|---|
| `local` (default) | `~/.claude.json` under `projects["<path>"].mcpServers` | This project | No |
| `project` | `.mcp.json` at repo root | This project (each user approves once) | Yes, via git |
| `user` | `~/.claude.json` top-level `mcpServers` | All projects | No |
| plugin | plugin `.mcp.json` / `mcpServers` in `plugin.json` | While plugin enabled | With plugin |
| managed | `managed-mcp.json` (exclusive) | Org | IT |

Precedence for same-named servers: local > project > user > plugin > claude.ai connectors.

| Transport | Config `type` | Use |
|---|---|---|
| stdio | `"stdio"` (`command`, `args`, `env`) | Local processes (`npx`, `node`, `python`, binaries) |
| Streamable HTTP | `"http"` (`url`, `headers`, `headersHelper`, `oauth`) | Recommended for remote servers |
| SSE | `"sse"` | **Deprecated** — use HTTP where available |
| WebSocket | `"ws"` (JSON only) | Header auth, no OAuth |

Windows note: the docs state `claude mcp add` works the same in PowerShell and CMD. If an `npx`-launched stdio server exits immediately ("Connection closed") on native Windows, wrapping the command as `-- cmd /c npx -y …` is a widely used workaround carried over from earlier workshop versions (not in the current docs — verify on your machines).

### F.3 `.mcp.json` schema and env expansion

```json
{
  "mcpServers": {
    "astro-catalog": {
      "type": "stdio",
      "command": "node",
      "args": ["${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs"],
      "env": { "CATALOG_FILE": "${WORKSHOP_REPO}/labs/mcp/astro-catalog/data/products.json" }
    },
    "claude-code-docs": { "type": "http", "url": "https://code.claude.com/docs/mcp" },
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": { "Authorization": "Bearer ${API_KEY}" },
      "timeout": 120000,
      "alwaysLoad": false
    }
  }
}
```

* `${VAR}` and `${VAR:-default}` expand in `command`, `args`, `env`, `url`, `headers`; unset without default → warning and literal text. `${CLAUDE_PROJECT_DIR}` needs a default in `.mcp.json` (`${CLAUDE_PROJECT_DIR:-.}`); plugins substitute `${CLAUDE_PLUGIN_ROOT}` directly.
* Project servers prompt for approval on first interactive start; **`-p`, the Agent SDK and cloud sessions load them without asking**. Settings: `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers`.
* Per-entry `timeout` (ms per tool call) and `alwaysLoad: true` (exempt from deferred tool loading).

### F.4 Authentication

* **OAuth 2.0** (HTTP/SSE): add server → `/mcp` → *Authenticate* (browser) or `claude mcp login <name>`; tokens stored securely and refreshed; `Re-authenticate` / `Clear authentication` in `/mcp`. Pre-registered clients: `--client-id … --client-secret --callback-port 8080` or `"oauth": {"clientId": "…", "callbackPort": 8080, "scopes": "read write", "authServerMetadataUrl": "https://…"}`. **No OAuth UI in `-p`/SDK** — authorize interactively first (SDK apps pass tokens in `headers`).
* **Static headers:** `--header` / `"headers"`. **Dynamic:** `"headersHelper": "/path/script.sh"` prints a JSON object of headers (10 s timeout; runs on each connect).
* claude.ai **connectors** appear automatically when logged in with a subscription (`mcp__claude_ai_<server>__<tool>`); disable with `disableClaudeAiConnectors: true`.

### F.5 Using MCP inside a session

| Feature | How |
|---|---|
| Tool names / permissions | `mcp__<server>__<tool>`; rules `mcp__astro-catalog`, `mcp__astro-catalog__*`, `mcp__github__get_*`; deny all with `"mcp__*"` |
| Tool search (default on) | Only names load at start; Claude loads schemas on demand via `ToolSearch`. `ENABLE_TOOL_SEARCH=false` loads all upfront; `auto[:N]` threshold; per-server `alwaysLoad` |
| Resources | Type `@` → `@server:protocol://path`, e.g. `@github:issue://123` |
| Prompts | `/mcp__server__prompt [args]` |
| Output limits | Warning at 10K tokens; cap `MAX_MCP_OUTPUT_TOKENS` (25000); servers may declare `_meta["anthropic/maxResultSizeChars"]` up to 500K |
| Timeouts | `MCP_TIMEOUT` startup (30 s), `MCP_TOOL_TIMEOUT`, per-server `timeout`, auto-background after 2 min |
| Elicitation | Supported (form and URL modes); automate with `Elicitation` hooks |
| Server hints honored | `anthropic/requiresUserInteraction` (always prompt), `anthropic/alwaysLoad` |
| Headless flags | `--mcp-config ./mcp.json` (repeatable/JSON), `--strict-mcp-config`, `--permission-prompt-tool mcp__srv__approve`; `system/init` stream event lists `mcp_servers[]` and `mcp_server_errors[]` |

### F.6 Claude Code as an MCP server

`claude mcp serve` exposes Claude Code's tools over stdio to another MCP client (the client handles confirmations). Claude Desktop config:

```json
{ "mcpServers": { "claude-code": { "type": "stdio", "command": "claude", "args": ["mcp", "serve"], "env": {} } } }
```

### F.7 Managed MCP and trust

* `managed-mcp.json` (same OS paths as managed settings) takes **exclusive** control: only its servers load; `claude mcp add` and `--mcp-config` are refused; `{"mcpServers": {}}` disables MCP entirely.
* `allowedMcpServers` / `deniedMcpServers` (any scope; `allowManagedMcpServersOnly` to honor only the managed allowlist): entries `{ "serverUrl": "https://mcp.example.com/*" }`, `{ "serverCommand": ["npx","-y","pkg"] }`, `{ "serverName": "x" }` (name match is not a security control). Deny always wins; `[]` allowlist = none.
* Trust guidance: Anthropic does not audit third-party MCP servers; servers that fetch external content are prompt-injection vectors; only add servers you would run as yourself; prefer OAuth/`headersHelper` over secrets in files. Build your own with the `mcp-server-dev` plugin (`/plugin install mcp-server-dev@claude-plugins-official`). Directory of reviewed servers: https://claude.ai/directory .

Sources: https://code.claude.com/docs/en/mcp · https://code.claude.com/docs/en/mcp-quickstart · https://code.claude.com/docs/en/managed-mcp · https://code.claude.com/docs/en/cli-reference

---

## G. Subagents and multi-agent primitives

### G.1 Concept and built-ins

A subagent runs in its **own context window** with its **own system prompt** (the markdown body), a scoped tool set and independent permissions; only its final message (plus a small metadata trailer) returns to the parent. Claude invokes subagents through the **`Agent` tool** (renamed from `Task` in v2.1.63; `Task(...)` still accepted in rules). Since v2.1.198 subagents run **in the background by default**; the main session stays responsive and permission prompts from background subagents surface in the main session.

| Built-in | Model | Purpose |
|---|---|---|
| `Explore` | inherits (capped at Opus) | Read-only codebase search/summary; thoroughness quick / medium / very thorough; skips CLAUDE.md |
| `Plan` | inherits | Read-only research during plan mode |
| `general-purpose` | inherits | All subagent tools; default when no type is given |
| `claude` | inherits | Default agent for dispatched background sessions |
| `fork` (type) | same as main | Forked subagent inheriting the full conversation and prompt cache (`/subtask`) |
| `statusline-setup`, `claude-code-guide` | Sonnet / Haiku | Used by `/statusline`; answers Claude Code questions |

Invoke: automatic delegation (matched on `description`; write "Use PROACTIVELY when…"), natural language ("use the bug-hunter agent on src/adservice"), guaranteed via **`@agent-<name>`** / `@agent-<plugin>:<name>` mention or the `@` typeahead, headless (`claude -p "@agent-codebase-toolkit:bug-hunter …"`), or run the whole session as an agent (`claude --agent <name>`, `"agent"` setting). Disable: deny `Agent(Explore)` / `Agent(name)` or `Agent` entirely.

### G.2 File format, locations, frontmatter

| Location | Scope | Priority |
|---|---|---|
| Managed settings dir `.claude/agents/` | Org | 1 |
| `--agents '<json>'` | Session | 2 |
| `.claude/agents/*.md` (cwd up to repo root; also `--add-dir` dirs) | Project | 3 |
| `~/.claude/agents/*.md` | User | 4 |
| Plugin `agents/*.md` → `plugin:name` | Where plugin enabled | 5 |

Files hot-reload. Identity comes from `name` (keep unique; `/doctor` reports duplicates). `/agents` no longer opens a wizard — edit files or ask Claude to create one.

| Frontmatter field | Values | Notes |
|---|---|---|
| `name` (required) | lowercase + hyphens | Becomes `agent_type` in hooks |
| `description` (required) | string | Drives automatic delegation |
| `tools` | `Read, Grep, Glob` (comma list or YAML list) | Allowlist; omit = all subagent tools; supports `mcp__srv__*`, `Agent(worker)` |
| `disallowedTools` | list | Applied before `tools`; `mcp__*` removes all MCP tools |
| `model` | `sonnet`\|`opus`\|`haiku`\|`fable`\|full ID\|`inherit` (default) | `CLAUDE_CODE_SUBAGENT_MODEL` env overrides everything |
| `effort` | `low`…`max` | Overrides session effort |
| `permissionMode` | `default`\|`acceptEdits`\|`auto`\|`dontAsk`\|`bypassPermissions`\|`plan` | Parent `bypass`/`acceptEdits`/`auto` take precedence; **ignored for plugin agents** |
| `maxTurns` | int | Turn cap |
| `skills` | list of skill names | Full skill content preloaded |
| `mcpServers` | names or inline `{name: {config}}` | Connect for the subagent's lifetime; ignored for plugin agents |
| `hooks` | hooks object | Scoped to the subagent; `Stop` → `SubagentStop`; ignored for plugin agents; project agents need workspace trust |
| `memory` | `user`\|`project`\|`local` | Persistent `MEMORY.md` for the agent |
| `background` | `true` | Pin to background |
| `isolation` | `worktree` | Run in a temporary git worktree (auto-cleaned if unchanged) |
| `color` | `red blue green yellow purple orange pink cyan` | Display |
| `initialPrompt` | string | Auto-submitted first turn when run via `--agent` |

```markdown
---
name: bug-hunter
description: Hunts for bugs, error-handling gaps and resource leaks in one service directory. Use PROACTIVELY when asked to analyze, audit or find bugs in a service.
tools: Read, Grep, Glob
model: sonnet
effort: high
color: orange
---
You are a meticulous bug hunter. Given a service path:
1. Identify the language and framework; read entry points first.
2. Look for unchecked errors, nil/None dereferences, race conditions, resource leaks, unsafe input handling.
3. Report findings as a table: [HIGH]/[MEDIUM]/[LOW] · file:line · category · description · recommendation.
Do not edit files. Cite exact lines.
```

`--agents` JSON accepts the same fields (`prompt` = body): `claude --agents '{"reviewer":{"description":"…","prompt":"…","tools":["Read","Grep"],"model":"sonnet"}}'`.

### G.3 Execution model

* **Foreground vs background:** interactive sessions run subagents in the background (fork mode default since v2.1.232); `-p`/SDK default to background but go foreground when Claude needs the result first; `background: true` pins. `Ctrl+B` backgrounds a running one; `/tasks` lists them; `Ctrl+X Ctrl+K` stops all.
* **Tool filtering:** subagents never get `AskUserQuestion`, plan-mode tools, `Workflow`; background subagents keep file/search/Bash/web/MCP tools plus `Skill`, `SendMessage`, worktree tools. Zero resolved tools → launch refused.
* **Nesting and concurrency:** up to **3 layers** below main by default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; `1` disables nesting); max **20** concurrent (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`). `--max-budget-usd` includes subagent spend.
* **What loads:** own prompt + delegation message + CLAUDE.md hierarchy (except Explore/Plan) + git status snapshot + preloaded skills. Not inherited: conversation history, output style, auto memory. Forks (`/subtask`, type `fork`) inherit everything.
* **Model resolution:** `CLAUDE_CODE_SUBAGENT_MODEL` → per-call `model` → frontmatter `model` → main model; checked against `availableModels`.
* **Resume/messaging:** named agents are addressable via `SendMessage`; transcripts under `~/.claude/projects/<proj>/<session>/subagents/`. Subagent output that imitates system/user turns is escaped and flagged.
* **Cost/latency trade-off:** each subagent builds its own context and prompt cache; use them for isolation and parallel breadth, not for tiny tasks. `/btw` is the inverse (full context, no tools).

### G.4 Other multi-agent primitives (overview; details §I.3)

| Primitive | Status (Aug 2026) | One-liner |
|---|---|---|
| Subagents (`Agent` tool) | GA | Delegated workers inside one session |
| Forked subagent `/subtask`, `/fork` (background session copy), `/branch` | GA / research preview | Split work without losing context |
| Background sessions + agent view (`claude --bg`, `/background`, `claude agents`) | Research preview | Many local sessions on one screen; each isolates into `.claude/worktrees/` before editing |
| Dynamic workflows (`Workflow` tool, `ultracode`, `/workflows`, `.claude/workflows/*.js`) | Research preview, v2.1.154+, paid plans (Pro: enable in `/config`) | Script fans out up to 16 concurrent / 1,000 agents with deterministic control flow |
| Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) | Experimental, off by default | Named teammates with shared task list and messaging |
| Cross-session messaging (`ListAgents`, `SendMessage`, `/list-agents`) | v2.1.224+, macOS/Linux, 1P only | Your sessions talk to each other |
| `/batch <instruction>` | Bundled skill | 5–30 worktree-isolated background subagents, one PR each |

Sources: https://code.claude.com/docs/en/sub-agents · https://code.claude.com/docs/en/agents · https://code.claude.com/docs/en/agent-view · https://code.claude.com/docs/en/workflows · https://code.claude.com/docs/en/agent-teams

---

## H. Skills, plugins and marketplaces

### H.1 Skills (`SKILL.md`)

A skill is a directory with `SKILL.md` (YAML frontmatter + markdown) and optional supporting files. **Progressive disclosure:** (1) name + description sit in the per-turn skill listing (budget ≈1% of context, `skillListingBudgetFraction`; description+`when_to_use` ≤1,536 chars); (2) the body loads only when invoked; (3) referenced files/scripts are read or executed only when needed. Custom commands (`.claude/commands/*.md`) are the same mechanism; a same-named skill wins. Skills follow the open Agent Skills standard with Claude Code extensions.

| Location | Path | Invoked as |
|---|---|---|
| Enterprise | `<managed dir>/.claude/skills/<name>/SKILL.md` | `/<name>` |
| Personal | `~/.claude/skills/<name>/SKILL.md` | `/<name>` |
| Project | `.claude/skills/<name>/SKILL.md` (cwd and parents to repo root; nested dirs load lazily as `/apps/web:<name>`) | `/<name>` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | `/<plugin>:<name>` |
| Legacy command | `.claude/commands/<name>.md` | `/<name>` |

Precedence enterprise > personal > project; any of them overrides a bundled skill of the same name. Live reload; `/reload-skills`; `/skills` lists (token counts, visibility → `skillOverrides`).

| Frontmatter | Meaning |
|---|---|
| `name` | Display name (directory name is the command; in plugins sets the last segment) |
| `description` · `when_to_use` | What/when — the text Claude matches for auto-invocation. Put the key use case first |
| `argument-hint` | Autocomplete hint, e.g. `<path> [focus]` |
| `arguments` | Named positional args (`arguments: [path, focus]` → `$path`, `$focus`) |
| `disable-model-invocation: true` | Only the user can invoke; description removed from context (use for side-effect workflows) |
| `user-invocable: false` | Hidden from `/`; only Claude can invoke |
| `allowed-tools` | Tools pre-approved for the invoking turn: `Read, Grep, Glob, Bash(git diff *)`; does not restrict; **not** gated by workspace trust — review repo skills |
| `disallowed-tools` | Removed from the pool while active |
| `model` · `effort` | Override for the rest of the turn (`inherit` allowed) |
| `context: fork` · `agent` · `background` | Run in a forked subagent (`agent: Explore\|Plan\|general-purpose\|<custom>`; `background: false` waits inline) |
| `hooks` | Registered on invocation for the rest of the session (`once: true` supported) |
| `paths` | Globs limiting auto-activation (ignored in command files) |
| `shell` | `bash` (default) or `powershell` for `!` blocks |
| `metadata`, `license`, `compatibility` | Agent Skills spec fields (accepted, not acted on) |

Substitutions in the body: `$ARGUMENTS` (all args; appended as `ARGUMENTS: …` if absent), `$ARGUMENTS[N]` / `$N` (**0-based**: `$0` = first arg; shell quoting), `$name` (from `arguments:`), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`. **Dynamic context:** `` !`command` `` (or a fenced block opened with three backticks + `!`) runs *before* Claude sees the content and inlines stdout; non-zero exit aborts the invocation; unmatched permissions abort unless pre-approved in `allowed-tools`; disable org-wide with `disableSkillShellExecution`. `@file` references attach files. The word `ultrathink` in a skill requests deeper reasoning.

```markdown
---
name: code-reviewer
description: Reviews one service or path for quality, security and performance issues and returns a prioritized findings table. Use when asked to review, audit or critique code in a directory.
argument-hint: <path> [security|performance|quality]
arguments: [target, focus]
allowed-tools: Read, Grep, Glob, Bash(git log *), Bash(git diff *)
effort: high
---
## Recent history for $target
!`git log -3 --oneline -- $target`

## Instructions
Review `$target`. If `$focus` is non-empty, load only `checklists/$focus.md` from ${CLAUDE_SKILL_DIR}; otherwise apply all checklists.
Report `[HIGH]/[MEDIUM]/[LOW] · file:line · issue · fix`. Do not modify files.

## Additional resources
- Security checklist: [checklists/security.md](checklists/security.md)
```

Layout: `code-reviewer/SKILL.md`, `code-reviewer/checklists/security.md`, optional `scripts/`. Keep `SKILL.md` under ~500 lines; put reference material in supporting files. Invocation matrix: default = user and Claude; `disable-model-invocation: true` = user only; `user-invocable: false` = Claude only. Permission rules: `Skill`, `Skill(code-reviewer)`, `Skill(deploy *)`. Skills in subagents: `skills:` frontmatter preloads them. In the Agent SDK skills are discovered from `settingSources`; select with the `skills` option (SKILL.md `allowed-tools` is *not* applied there). Portability: claude.ai / Skills API accept only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.

Sources: https://code.claude.com/docs/en/skills · https://agentskills.io

### H.2 Plugins and marketplaces

**Plugin layout** (never put components inside `.claude-plugin/`; a plugin-root `CLAUDE.md` is not loaded):

```text
codebase-toolkit/
├── .claude-plugin/plugin.json      # manifest (only "name" required)
├── agents/service-documenter.md    # -> @agent-codebase-toolkit:service-documenter
├── agents/bug-hunter.md
├── skills/code-reviewer/SKILL.md   # -> /codebase-toolkit:code-reviewer
├── skills/code-reviewer/checklists/security.md
├── hooks/hooks.json                # {"hooks": {...}} using ${CLAUDE_PLUGIN_ROOT}
├── hooks/protect-files.sh
├── .mcp.json                       # plugin MCP servers -> mcp__plugin_codebase-toolkit_<srv>__<tool>
├── workflows/  bin/  commands/  output-styles/  .lsp.json  settings.json  themes/  monitors/   # optional
└── README.md  CHANGELOG.md  LICENSE
```

**`plugin.json`**

```json
{
  "name": "codebase-toolkit",
  "displayName": "Codebase Toolkit",
  "version": "4.0.0",
  "description": "Service documenter and bug hunter agents, code-reviewer skill, protected-file hook, astro-catalog MCP server",
  "author": { "name": "Your Name", "email": "you@example.com", "url": "https://github.com/you" },
  "homepage": "https://github.com/WORKSHOP_ORG/claude-marketplace",
  "repository": "https://github.com/WORKSHOP_ORG/claude-marketplace",
  "license": "MIT",
  "keywords": ["review", "documentation", "opentelemetry"],
  "userConfig": {
    "severity_threshold": { "type": "string", "title": "Severity threshold", "description": "LOW, MEDIUM or HIGH", "default": "LOW" }
  },
  "dependencies": []
}
```

Fields: `name` (kebab-case, required); metadata `displayName`, `version` (semver; if set, users update only when it bumps), `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `metadata`, `defaultEnabled`; component paths (relative, start with `./`): `skills` (adds to default scan), `commands`, `agents`, `workflows`, `outputStyles`, `hooks`, `mcpServers`, `lspServers`, `experimental.themes`, `experimental.monitors`; `userConfig` (options prompted at enable time; `type: string|number|boolean|directory|file`, `sensitive`, `required`, `default`; referenced as `${user_config.KEY}` / env `CLAUDE_PLUGIN_OPTION_<KEY>`; stored in `pluginConfigs`); `channels`; `dependencies` (`"name"` or `{name, version: "~2.1.0", marketplace}` resolved against tags `{plugin}--v{version}`). Plugin agents may **not** declare `hooks`, `mcpServers`, `permissionMode`. Placeholders: `${CLAUDE_PLUGIN_ROOT}` (install dir, changes per version), `${CLAUDE_PLUGIN_DATA}` (persistent), `${CLAUDE_PROJECT_DIR}`. Plugin `hooks/hooks.json` = `{"description": "…", "hooks": { …same schema as settings… }}`.

**`marketplace.json`** (`<marketplace-root>/.claude-plugin/marketplace.json`)

```json
{
  "name": "workshop-marketplace",
  "owner": { "name": "Workshop Org", "email": "devrel@example.com" },
  "metadata": { "pluginRoot": "." },
  "plugins": [
    { "name": "codebase-toolkit", "source": "./codebase-toolkit",
      "description": "Agents + skill + hooks + MCP for the Astronomy Shop", "version": "4.0.0",
      "category": "code-quality", "keywords": ["review"] },
    { "name": "other-plugin", "source": { "source": "github", "repo": "acme/other-plugin", "ref": "v1.2.0" } }
  ]
}
```

Top-level: `name` (kebab; reserved names such as `claude-plugins-official`, `claude-community`, `anthropic-*` are blocked), `owner`, `plugins[]`, optional `description`, `version`, `metadata.pluginRoot`, `renames`, `allowCrossMarketplaceDependenciesOn`. Plugin entry: `name`, `source` (required) + optional `description`, `version`, `author`, `category`, `tags`, `keywords`, `strict`, `relevance`, `defaultEnabled`, component overrides. Source types: relative path `"./dir"` · `{source:"github", repo, ref?, sha?}` · `{source:"url", url}` (git) · `{source:"git-subdir", url, path}` · `{source:"npm", package, version?}` · `{source:"archive", url, sha256?}` · `{source:"command", command}`.

**CLI and slash commands**

| Task | Command |
|---|---|
| Scaffold | `claude plugin init <name> [--with skills agents hooks mcp lsp output-style] [--description …]` |
| Validate | `claude plugin validate <plugin-or-marketplace-dir> [--strict]` → `✔ Validation passed` |
| Session-only load | `claude --plugin-dir ./codebase-toolkit` (dir or `.zip`; repeatable) · `--plugin-url https://…/plugin.zip` |
| Add marketplace | `/plugin marketplace add ./workshop-marketplace` \| `owner/repo[@ref]` \| `https://…/repo.git#ref` \| URL to `marketplace.json`; CLI `claude plugin marketplace add <src> [--scope user\|project\|local]`; `list`, `update [name]`, `remove` |
| Install / manage | `/plugin install codebase-toolkit@workshop-marketplace` (choose scope) · `claude plugin install <p>@<m> [-s user\|project\|local] [--config k=v] [-y]` · `enable` / `disable` / `uninstall [--keep-data]` / `update` / `list [--json]` / `details <name>` (token cost) / `prune` / `tag [--push]` |
| Apply changes mid-session | `/reload-plugins [--force]` (install summary says whether needed) |
| Browse | `/plugin` UI: Discover · Installed · Marketplaces · Errors |

**Scopes and team rollout** — `enabledPlugins` lives in the settings file of the chosen scope (`user` `~/.claude/settings.json`, `project` `.claude/settings.json`, `local`, `managed`):

```json
{
  "extraKnownMarketplaces": { "acme-marketplace": { "source": { "source": "github", "repo": "WORKSHOP_ORG/claude-marketplace" } } },
  "enabledPlugins": { "codebase-toolkit@acme-marketplace": true, "security-guidance@claude-plugins-official": true }
}
```

Committing this to `.claude/settings.json` registers the marketplace for teammates after they accept workspace trust; each user still runs `claude plugin install` for external-source plugins; cloud sessions install repo-declared plugins at start. Managed `enabledPlugins` force-enables or blocks. Enterprise controls: `strictKnownMarketplaces` / `blockedMarketplaces`, `strictPluginOnlyCustomization`, `disableSideloadFlags`, `pluginTrustMessage`, `allowManagedHooksOnly`; Team/Enterprise can also distribute via **Organization settings → Plugins** on claude.ai. Containers/CI: pre-seed with `CLAUDE_CODE_PLUGIN_SEED_DIR`.

**Official marketplaces** **[verify names on day]**: `claude-plugins-official` (repo `anthropics/claude-plugins-official`; auto-registered on first interactive launch; browse at https://claude.com/plugins; includes `security-guidance`, `claude-security`, `code-review`, `mcp-server-dev`, `skill-creator`, `plugin-dev`, `agent-sdk-dev`, LSP plugins `typescript-lsp`, `gopls-lsp`, `pyright-lsp`, …, integrations `github`, `gitlab`, `linear`, `sentry`, …) · `claude-community` (repo `anthropics/claude-plugins-community`; add manually; submissions via claude.ai admin settings or platform.claude.com/plugins/submit) · demo marketplace `claude-code-plugins` (`/plugin marketplace add anthropics/claude-code`).

Security: "Plugins and marketplaces are highly trusted components that can execute arbitrary code on your machine with your user privileges. Only install plugins and add marketplaces from sources you trust." Installed plugins are copied to `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`.

Sources: https://code.claude.com/docs/en/plugins · https://code.claude.com/docs/en/plugins-reference · https://code.claude.com/docs/en/plugin-marketplaces · https://code.claude.com/docs/en/discover-plugins · https://code.claude.com/docs/en/plugin-dependencies

### H.3 Bundled skills and workflows (ship with the CLI)

| Command | What it does |
|---|---|
| `/code-review [low\|medium\|high\|xhigh\|max\|ultra] [--fix] [--comment] [--post] [pr#\|branch\|path]` (alias `/review`) | Multi-lens review of current diff/PR as a background forked subagent; `--comment` posts inline PR comments (via `gh`); `ultra` = cloud ultrareview |
| `/simplify [target]` | Four parallel cleanup reviewers (reuse, simplification, efficiency, abstraction) then applies fixes |
| `/security-review` | Single-pass security review of branch diff vs `origin` default branch (§M.4) |
| `/verify` · `/run` · `/run-skill-generator` | Build/run/observe the app to confirm a change; records a per-project recipe skill |
| `/debug [issue]` | Turn on debug logging and troubleshoot from the log |
| `/batch <instruction>` | Decompose into 5–30 units, one worktree-isolated background subagent + PR each |
| `/loop [interval] [prompt]` (`/proactive`) | Re-run a prompt on an interval or self-paced |
| `/fewer-permission-prompts` | Mine transcripts for safe read-only commands and add allow rules |
| `/claude-api [migrate\|managed-agents-onboard\|prompt-audit]` | Load Claude API + Managed Agents reference; guided CMA onboarding |
| `/doctor` (`/checkup`) | Diagnose and fix install/config issues, unused extensions, slow hooks, CLAUDE.md bloat |
| `/dataviz`, `/design-sync`, `/team-onboarding` | Niche helpers |
| `/deep-research <question>` | Bundled **workflow**: fan-out web research with cited report |

Disable all with `disableBundledSkills: true`; hide one with `skillOverrides: {"<name>": "off"}`.

Source: https://code.claude.com/docs/en/commands · https://code.claude.com/docs/en/skills

---

## I. Headless, CI, GitHub Actions, orchestration and surfaces

### I.1 Headless (`claude -p`) reference

**Essential flags** (full list §C.3): `-p "prompt"` · `--output-format text|json|stream-json` · `--input-format text|stream-json` · `--json-schema '<schema>'` · `--allowedTools` / `--disallowedTools` / `--tools` · `--permission-mode dontAsk|acceptEdits|auto` · `--permission-prompt-tool <mcp tool>` · `--max-turns N` · `--max-budget-usd X` · `--model` / `--effort` / `--fallback-model` · `--continue` / `--resume <id>` (works from any directory) / `--fork-session` / `--session-id` · `--no-session-persistence` · `--bare` · `--settings` / `--setting-sources` · `--mcp-config` / `--strict-mcp-config` · `--agent` / `--agents` · `--plugin-dir` · `--append-system-prompt[-file]` · `--verbose` · `--include-partial-messages` · `--include-hook-events` · `--forward-subagent-text`.

**Facts that bite in CI**
* `-p` starts in **`default` (Manual)** on every plan: anything that would prompt is denied unless allowed. Locked-down recipe: `--permission-mode dontAsk --allowedTools "Read,Grep,Glob"`; check `permission_denials` in the JSON result when something silently didn't happen.
* **No trust dialog in `-p`**: project hooks run and `.mcp.json` servers connect even in never-trusted checkouts. Use `--bare` (skips hooks, skills, plugins, MCP, auto memory, CLAUDE.md; requires `ANTHROPIC_API_KEY`/3P creds; add context back explicitly with `--append-system-prompt-file`, `--settings`, `--mcp-config`, `--agents`, `--plugin-dir`) or `--setting-sources user` / `--settings '{"disableAllHooks":true}'`.
* Auth for CI: `ANTHROPIC_API_KEY` (Console), `CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`, subscription, not in `--bare`), `apiKeyHelper` via `--settings`, or 3P env vars.
* Skills/commands work in the prompt (`claude -p "/codebase-toolkit:code-reviewer src/adservice"`); `/model`, `/effort`, `/mcp` accept text args; interactive-only commands are unavailable. Piped stdin cap 10 MB.
* Background subagents/workflows are awaited at the end (default cap 10 min, `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`).

**Patterns**

```bash
# JSON + schema-validated structured output, locked-down tools, cost cap
claude -p "@agent-codebase-toolkit:bug-hunter analyze src/adservice and return findings" \
  --output-format json --json-schema "$(cat labs/shared/findings.schema.json)" \
  --allowedTools "Read,Grep,Glob,Agent" --permission-mode dontAsk \
  --max-turns 30 --max-budget-usd 1 | jq '{cost: .total_cost_usd, n: (.structured_output.findings|length)}'

# Two-step session
sid=$(claude -p "List services lacking READMEs" --output-format json | jq -r .session_id)
claude -p --resume "$sid" "Write README.md for the first one" --permission-mode acceptEdits --allowedTools "Read,Write,Glob"

# Streaming: print tool names as they happen
claude -p "…" --output-format stream-json --verbose --include-partial-messages \
  | jq -rc 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name'

# Pipe data in
gh pr diff 123 | claude -p --append-system-prompt "You are a security engineer." --output-format json | jq -r .result
```

**`--output-format json` result object** (also the final `result` event in stream-json):

| Field | Meaning |
|---|---|
| `type: "result"`, `subtype` | `success` \| `error_max_turns` \| `error_during_execution` \| `error_max_budget_usd` \| `error_max_structured_output_retries` |
| `result` | Final text (success only) |
| `structured_output` | Validated object when `--json-schema` was given |
| `session_id`, `uuid`, `num_turns`, `duration_ms`, `duration_api_ms`, `is_error`, `stop_reason`, `terminal_reason` | Run metadata (`terminal_reason` e.g. `completed`, `max_turns`, `budget_exhausted`, `tool_deferred`, `prompt_too_long`) |
| `total_cost_usd`, `usage`, `modelUsage` | Client-side cost estimate; `modelUsage` is per model and includes subagents |
| `permission_denials[]` | Tools denied (vital when using `dontAsk`) |
| `deferred_tool_use` | Present when a `PreToolUse` hook returned `defer` |
| `errors[]`, `api_error_status` | On error subtypes |

**stream-json event types:** `system` (`init` — carries `model`, `tools`, `mcp_servers[]`, `mcp_server_errors[]`, `plugins[]`, `plugin_errors[]`, `slash_commands`, `skills`, `permissionMode`, `claude_code_version`, `capabilities`; also `api_retry`, `plugin_install`, `compact_boundary`) · `assistant` (content blocks `text` / `tool_use` / `thinking`; `parent_tool_use_id` non-null inside subagents) · `user` (tool results) · `stream_event` (raw deltas with `--include-partial-messages`) · `hook_started` / `hook_progress` / `hook_response` (with `--include-hook-events`) · `prompt_suggestion` · final `result`. **stream-json input** lines: `{"type":"user","message":{"role":"user","content":[{"type":"text","text":"…"}]},"parent_tool_use_id":null}` (`shouldQuery:false` appends context without a turn).

Sources: https://code.claude.com/docs/en/headless · https://code.claude.com/docs/en/cli-reference · https://code.claude.com/docs/en/agent-sdk/typescript

### I.2 GitHub Actions, GitLab CI, Code Review

**`anthropics/claude-code-action@v1`** — runs Claude Code in a workflow. **Interactive mode** (no `prompt`): responds to `@claude` (whole word) in issue/PR comments and reviews, from users with write access, updating one sticky comment. **Automation mode** (`prompt` set): runs on any event (schedule, `pull_request`, …). Setup: `/install-github-app` (installs the Claude GitHub App, stores `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` secret, opens a PR with workflow files) or manual (install https://github.com/apps/claude, add secret, copy `examples/claude.yml`).

```yaml
name: Claude Code
on:
  issue_comment: { types: [created] }
  pull_request_review_comment: { types: [created] }
jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    permissions: { contents: write, pull-requests: write, issues: write, id-token: write, actions: read }
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 1 }
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          # plugin_marketplaces: "https://github.com/WORKSHOP_ORG/claude-marketplace.git"
          # plugins: "codebase-toolkit@acme-marketplace"
          # prompt: "/codebase-toolkit:code-reviewer src/paymentservice"   # automation mode
          # claude_args: '--max-turns 10 --model claude-sonnet-5 --allowedTools "Read,Grep,Glob"'
```

| Input | Purpose |
|---|---|
| `anthropic_api_key` / `claude_code_oauth_token` | Auth (or OIDC: `anthropic_federation_rule_id`, `anthropic_organization_id`, `anthropic_workspace_id`; or `use_bedrock` / `use_vertex` / `use_foundry: "true"` with cloud OIDC) |
| `prompt` | Automation-mode task; may be `/skill` or `/plugin:skill` |
| `claude_args` | Any CLI flags (`--max-turns`, `--model`, `--allowedTools`, `--mcp-config`, `--json-schema`, …) |
| `trigger_phrase` (default `@claude`), `assignee_trigger`, `label_trigger` | Interactive triggers |
| `plugin_marketplaces`, `plugins` | Install plugins in the runner |
| `settings` | Inline JSON or path (hooks, env, permissions) |
| `github_token` | Omit to act as the Claude GitHub App |
| `track_progress`, `use_sticky_comment`, `classify_inline_comments`, `include_fix_links` | Comment behaviour |
| `base_branch`, `branch_prefix` (`claude/`), `use_commit_signing`, `ssh_signing_key` | Git behaviour |
| `allowed_bots`, `allowed_non_write_users` (risky), `additional_permissions` | Access control |
| `path_to_claude_code_executable`, `path_to_bun_executable` | Custom runners |

Security checklist: least workflow `permissions:`; never commit keys (GitHub Secrets or OIDC); only trusted users trigger; fork PRs on public repos don't receive secrets; cap with `--max-turns` and job `timeout-minutes`; beware hidden markdown in untrusted issues; review Claude's commits like anyone's. Migration from `@beta`: `direct_prompt`→`prompt`, `custom_instructions`→`--append-system-prompt`, `max_turns/model/allowed_tools/mcp_config`→`claude_args`, `claude_env`→`settings`, drop `mode`.

**Code Review** (managed product, Team/Enterprise, research preview): a fleet of agents reviews every GitHub PR with full-codebase context and posts inline comments + a neutral check run; enable at claude.ai/admin-settings/claude-code → Code Review; per-repo behaviour *once / every push / manual*; `@claude review [once|always]` in a PR comment; customize with `CLAUDE.md` + root `REVIEW.md`; billed via usage credits (~$15–25 per review) **[volatile]**. Local sibling: `/code-review`, cloud sibling `/code-review ultra` / `claude ultrareview` (Pro/Max: 3 free runs then usage credits). PR auto-fix: `/autofix-pr` (web session watches CI/review comments).

**GitLab CI/CD** (beta, maintained with GitLab): install the CLI in the job (`curl -fsSL https://claude.ai/install.sh | bash`), masked `ANTHROPIC_API_KEY`, run `claude -p "$AI_FLOW_INPUT" --permission-mode acceptEdits --allowedTools "Bash Read Edit Write mcp__gitlab"`; Bedrock/Vertex via OIDC.

**`anthropics/claude-code-security-review`** Action — see §M.4.

Sources: https://code.claude.com/docs/en/github-actions · https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md · https://github.com/anthropics/claude-code-action/blob/main/docs/security.md · https://code.claude.com/docs/en/code-review · https://code.claude.com/docs/en/ultrareview · https://code.claude.com/docs/en/gitlab-ci-cd

### I.3 Orchestration and scale-out matrix ("when to use what")

| Option | Where it runs | How to start | Isolation | Good for | Status (Aug 2026) |
|---|---|---|---|---|---|
| Single / parallel **subagents** | Inside your session | "use 3 parallel subagents to…", `@agent-name` | Own context; optional `isolation: worktree` | Keep main context small; independent chunks | GA |
| **Forks**: `/subtask`, `/fork`, `/branch` | Session / background session | Slash commands | Inherit full conversation | Side quests without losing context | GA / preview |
| **Background sessions + agent view** | Local, supervised by a daemon | `claude --bg "…" [--agent x] [--exec 'cmd']`, `/background`, `claude agents`, `claude attach\|logs\|stop <id>` | Auto-moves into `.claude/worktrees/` before editing; opens draft PR when done | Several long tasks in parallel on your laptop | Research preview |
| **Dynamic workflows** (`ultracode`) | Inside session, background runtime | Type `ultracode: <task>` or "use a workflow"; `/effort ultracode`; `/workflows` to watch/pause/save; saved scripts in `.claude/workflows/*.js` become `/<name>` | Each agent = subagent in `acceptEdits` with your allowlist; ≤16 concurrent, ≤1,000 per run; size guideline setting | Audits, migrations, sweeps needing deterministic fan-out + verification | Research preview; v2.1.154+; paid plans (Pro: enable in `/config`) |
| **Agent teams** | Local (in-process / tmux panes) | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, then "spawn three teammates…" | Separate sessions + shared task list + messaging | Collaborative exploration with peer messaging | Experimental, off by default; ~7x tokens |
| **Cross-session messaging** | Between your own independent sessions: same machine over a per-session Unix socket (never via Anthropic servers); your other machines and cloud sessions through Anthropic servers while connected to Remote Control | Name sessions (`--name`, `/rename`); `/list-agents` (`/peers`) to see who is reachable; prompt `tell @api-worker …` (mention typeahead) or let Claude call `ListAgents` / `SendMessage` itself; `notify_when_idle` for a one-shot "that session went idle" notice (same machine) | Plain text only, no history/files; receiver is told it's from another session, not you (can't approve prompts or change config; own permission rules apply); `crossSessionInbound` accept/hold/refuse with permission-class defaults, `isolatePeerMachines`, `dialogExpiry` (§D.5); ~1M-char cap per same-machine message, bursts refused at the sender, loops rate-limited (≤50 queued, ≤100 held) | Hand-offs between parallel worktrees; a long run reporting back to the session you're watching; `-p` workers that take messages (`--bare` binds no inbox) | v2.1.224+ (cross-machine initiation 2.1.225+, `@` mention 2.1.232+, idle notice 2.1.236+); macOS/Linux/WSL 2, not native Windows; not Bedrock/Vertex/Foundry/Claude Platform on AWS; on by default |
| **`/goal <condition>`** | Session | `/goal all tests in test/auth pass`; works in `-p` | Evaluator (small model) after each turn | Unattended "keep going until X" | GA |
| **`/loop [interval] [prompt]`** | Session | `/loop 5m check the deploy` | Cron-like, session-scoped, ≤7 days | Polling, babysitting PRs | GA |
| **Claude Code on the web** | Anthropic cloud VM (or self-hosted environment) | claude.ai/code, `claude --cloud "task"`, `--teleport` back, `/autofix-pr`; env setup script + `SessionStart` hooks | Isolated VM, egress allowlist, scoped git proxy; repo config only | Parallel well-defined tasks; repos not on your machine | Pro/Max/Team/Enterprise (docs still label parts research preview) **[verify]** |
| **Routines** | Cloud VM | `/schedule daily PR review at 9am` (`/routines`), claude.ai/code/routines; triggers: schedule (≥1 h), API `POST /v1/claude_code/routines/{id}/fire`, GitHub events | Same as web; runs autonomously; `claude/` branches | Scheduled or event-driven agents on repos | Research preview; needs web enabled |
| **Desktop scheduled tasks** | Your machine (Desktop app open) | Desktop → Routines → New → Local | Per-task permission mode | Local recurring jobs | Ships with Desktop |
| **GitHub Actions / GitLab** | CI runner | `claude-code-action@v1`, `claude -p` | Runner sandbox; workflow permissions | PR/issue automation, gates | GA / beta |
| **Agent SDK service** | Your infra | `query()` (§K) | Whatever you build (container + proxy) | Agents inside your product | GA |
| **Managed Agents** | Anthropic-managed containers | `client.beta.sessions.create` (§L) | Fresh container per session, `limited` networking, vaults | Long-running/async product agents without infra | Public beta |

Workflow script shape (what Claude writes; you can save and re-run it):

```javascript
export const meta = { name: 'dockerfile-audit', description: 'Check every service Dockerfile for unpinned base images' }
const found = await agent('List every Dockerfile under src/. Return JSON.', {
  schema: { type: 'object', required: ['files'], properties: { files: { type: 'array', items: { type: 'string' } } } } })
const audits = await pipeline(found.files, f => agent(`Audit ${f} for unpinned or EOL base images; propose a pinned digest.`, { label: f }))
return audits.filter(Boolean)
```

Sources: https://code.claude.com/docs/en/agents · https://code.claude.com/docs/en/agent-view · https://code.claude.com/docs/en/workflows · https://code.claude.com/docs/en/cross-session-messaging · https://code.claude.com/docs/en/goal · https://code.claude.com/docs/en/scheduled-tasks · https://code.claude.com/docs/en/routines · https://code.claude.com/docs/en/claude-code-on-the-web · https://code.claude.com/docs/en/cloud-environments

### I.4 Surfaces matrix

| Surface | Get it | Code runs on | Config it sees | Plans / status (Aug 2026) **[volatile]** |
|---|---|---|---|---|
| Terminal CLI | §C.1 | Your machine | Everything local | All paid plans, Console, 3P providers |
| VS Code / Cursor extension (`anthropic.claude-code`) | Marketplace / Open VSX; VS Code ≥1.94 | Your machine | Shares `~/.claude` + project config; inline diffs, `@`-mentions, plan review, `/plugins` UI; `Cmd/Ctrl+Esc` focus | Paid plans, Console, 3P |
| JetBrains plugin | JetBrains Marketplace + CLI installed | Your machine | Same as CLI | Beta label |
| Desktop app (Code tab) | Claude Desktop macOS / Windows / Linux beta; `/desktop` hand-off | Local, cloud, SSH or WSL per session | Local config; parallel sessions in worktrees, in-app browser, scheduled tasks | Paid subscription |
| Claude Code on the web | claude.ai/code, `claude --cloud`, `/web-setup` (sync `gh` token) | Anthropic VM (Ubuntu 24.04, ~4 vCPU/16 GB) or self-hosted env | **Repo-committed** CLAUDE.md, `.claude/`, `.mcp.json`, repo `enabledPlugins`, server-managed settings; not `~/.claude` | Pro/Max/Team; Enterprise premium or Chat+Claude Code seat |
| Remote Control | `claude --rc`, `/remote-control`; drive from claude.ai/code or phone | Your machine | Local | All plans (Team/Ent admin toggle); research preview |
| Mobile (iOS/Android) | Claude app; `/mobile` QR | Cloud VM or your machine via Remote Control | — | Follows web/RC |
| Slack / **Claude Tag** | Slack app; Claude Tag for Team/Enterprise | Anthropic cloud | Repo + org environments | Claude Tag replaces per-user Slack app for orgs |
| Chrome | Extension + `claude --chrome` | Your browser | — | GA on 1P plans |
| Routines / scheduled | §I.3 | Cloud / Desktop / session | — | Preview |
| GitHub Actions / GitLab / Code Review | §I.2 | CI runner / Anthropic infra | Repo | GA / beta / Team-Ent preview |
| Agent SDK | §K | Your process | `settingSources` | GA |
| Self-hosted environments | `claude self-hosted-runner setup` | Your runners for cloud sessions | Repo | Public beta, Team/Enterprise |

Sources: https://code.claude.com/docs/en/platforms · https://code.claude.com/docs/en/feature-availability · https://code.claude.com/docs/en/vs-code · https://code.claude.com/docs/en/desktop · https://code.claude.com/docs/en/remote-control

---

## J. Troubleshooting and FAQ

### J.1 First-aid kit

| Tool | Use |
|---|---|
| `claude doctor` / `/doctor` | Install health, duplicate installs, PATH, invalid settings (with file + field), slow hooks, oversized CLAUDE.md |
| `/status` | Version, model, login method / API key row, provider, proxy, setting sources |
| `/context`, `/permissions`, `/hooks`, `/mcp`, `/skills`, `/memory`, `/plugin` (Errors tab) | What actually loaded and from where |
| `claude --debug[=mcp,startup]`, `--debug-file /tmp/cc.log`, `/debug` | Debug log at `~/.claude/debug/<session>.txt` |
| `claude --safe-mode` | Rule out customizations (CLAUDE.md, skills, plugins, hooks, MCP disabled) |
| `CLAUDE_CONFIG_DIR=/tmp/clean claude` | Fully clean profile for comparison |

### J.2 Install, auth, network

| Symptom | Likely cause → fix |
|---|---|
| `claude: command not found` after install | `~/.local/bin` not on PATH → add it, reopen shell; `which -a claude` for duplicates (old npm install) |
| Browser doesn't open on login (WSL2/SSH/locked-down laptop) | Press `c` to copy URL, paste the code back; `claude auth login` reads code from stdin; WSL: `export BROWSER=/mnt/c/…/chrome.exe` |
| `API Error 400 … organization has been disabled` while subscribed | Stale `ANTHROPIC_API_KEY` in env overrides OAuth → `unset ANTHROPIC_API_KEY` (check `/status` "API key" row) |
| 403 after login | No active subscription, or Console user lacks **Claude Code**/**Developer** role |
| macOS keychain errors | `security unlock-keychain ~/Library/Keychains/login.keychain-db` |
| Corporate proxy / TLS inspection | `HTTPS_PROXY`, `NO_PROXY`; put root CA in the OS store (read by default) or `NODE_EXTRA_CA_CERTS=/path/ca.pem`; mTLS via `CLAUDE_CODE_CLIENT_CERT/KEY`; set these in `~/.claude/settings.json` `env` so background agents inherit |
| Firewall allowlist | `api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com` (connectors), `registry.npmjs.org` (npx MCP servers/plugins), `raw.githubusercontent.com`, `github.com`, `pypi.org` for labs |
| Rate-limit / "hit your session limit" | Plan limits are shared with claude.ai chat (5-hour + weekly windows); `/usage`; switch to `sonnet`; lower `/effort`; Console orgs check workspace rate limits; v2.1.234+ auto-continues when the limit resets |
| Fable/fast mode says "requires usage credits" | Enable at `/usage-credits` (subscription) or ask an admin |
| Sandbox unavailable | Native Windows/WSL1 unsupported; Linux needs `bubblewrap socat`; Ubuntu 24.04 AppArmor `bwrap` profile |

### J.3 Windows / WSL notes

* Native Windows works without Git Bash (PowerShell tool is used); set `CLAUDE_CODE_GIT_BASH_PATH` if Git Bash exists but isn't found. Hooks: use `.ps1` handlers with `"shell": "powershell"` and `$env:CLAUDE_PROJECT_DIR`; file paths in hook input use backslashes — normalize before matching.
* WSL2 supports the sandbox; WSL1 does not. IDE detection from WSL2 may need a firewall rule or `networkingMode=mirrored`.
* Paths in permission rules normalize to `/c/Users/...` (`//c/**/.env`).
* `winget install Anthropic.ClaudeCode` or the PowerShell installer; managed settings at `C:\Program Files\ClaudeCode\`.

### J.4 By workshop module

| Module | Symptom | Fix |
|---|---|---|
| M1 | Edits happen without prompts | Auto mode is the default start mode on Pro/Max/Team — start with `--permission-mode default` for the lab |
| M1 | `/init` slow on a huge repo | `/effort medium`; run from a subdirectory |
| M1 | Rewind didn't undo a file | Bash side effects and manual edits aren't checkpointed; use git |
| M2 | Deny rule ignored | Typo in path form (`Read(.env)` matches any depth; `Read(./.env)` cwd only); rule in `~/.claude.json` instead of `settings.json`; check `/permissions` source column |
| M2 | Hook never fires | Not executable; matcher case (`Edit\|Write` exact names); `if` only works on tool events; JSON invalid → whole settings file rejected (startup **Settings Error**); confirm with `/hooks` and `--debug` |
| M2 | Hook "error" but action proceeded | Exit code 1 is non-blocking — use **exit 2** or JSON `permissionDecision` |
| M2 | MCP server `✘ Failed` | Run the command by hand (`node server.mjs`); Node < 20; relative `command` path; missing `type` for URL entries; `MCP_TIMEOUT` |
| M2 | Project MCP server "pending approval" in every run | You declined once → `claude mcp reset-project-choices`; or set `enabledMcpjsonServers` |
| M3 | Agent not picked automatically | Weak `description`; add "Use PROACTIVELY when…"; or force with `@agent-name` |
| M3 | Skill not listed | Must be `.claude/skills/<dir>/SKILL.md`; YAML frontmatter malformed (tabs); skills dir created after session start → restart or `/reload-skills` |
| M3 | `claude plugin validate` fails | Components inside `.claude-plugin/`; paths not starting `./`; hooks file missing top-level `hooks` key; `$CLAUDE_PROJECT_DIR` used where `${CLAUDE_PLUGIN_ROOT}` is needed |
| M3 | Installed plugin not active | Run `/reload-plugins`; check `/plugin` Errors tab; name clash with project skill (plugin skills are namespaced) |
| M4 | `-p` produced nothing / tool skipped | `dontAsk` denied it → read `.permission_denials`; add to `--allowedTools` |
| M4 | Plugin invisible in `-p` | Installed at project scope elsewhere; use user scope or `--plugin-dir` |
| M4 | Action didn't respond to `@claude` | Not a whole word; commenter lacks write access; app not installed; secrets missing on fork PRs; `id-token: write` missing for OIDC |
| M5 | `CLINotFoundError` / native binary not found | Optional deps skipped (`--omit=optional`) or unsupported platform wheel → install CLI natively and set `pathToClaudeCodeExecutable` / `cli_path` |
| M5 | SDK used my subscription instead of the key | Export `ANTHROPIC_API_KEY` explicitly in the process env (SDK doesn't read `.env`) |
| M5 | `canUseTool` never called | Tool already allowed by `allowedTools`/mode — callbacks only see fall-through calls; use a `PreToolUse` hook to see everything |
| M5 | Structured output missing | `error_max_structured_output_retries` → loosen schema; also treat `success` without `structured_output` as failure |
| M6 | 403 / feature not enabled | Managed Agents not enabled for the org/workspace; wrong/missing `anthropic-beta: managed-agents-2026-04-01` on raw HTTP |
| M6 | Session stuck `idle` with `requires_action` | You must answer **every** `event_id` with `user.tool_confirmation` / `user.custom_tool_result` |
| M6 | `git clone` fails in sandbox | `limited` networking missing `github.com`/`api.github.com` hosts; environments aren't versioned — recreate |
| M6 | Missed early events | Open the stream before sending, or use `initial_events` and list past events |
| M7 | Plugin says workflows unavailable | Pro: enable Dynamic workflows in `/config`; org admin may have disabled workflows |
| M7 | `/security-review` fails: no `origin/HEAD` | `git remote set-head origin -a` |
| M7 | Report marked `-dirty` / stale, patch refused | Working tree changed since scan → commit/stash and rescan |
| M7 | Too many prompts during scan | Switch to auto mode (Shift+Tab) as the plugin recommends |

### J.5 FAQ

* **Do I need Node.js?** Not for Claude Code itself (native binary). You need Node for `npx`-launched MCP servers, the TypeScript SDK, and the lab MCP server.
* **Subscription or API key?** Either works for Claude Code. The Agent SDK and Managed Agents labs need a Console API key (products you ship must not use claude.ai login). GitHub Actions accept either an API key or a `claude setup-token` token.
* **Where do "don't ask again" approvals go?** `.claude/settings.local.json` at the repo root.
* **Why did my broad `Bash(*)` allow rule stop working?** Auto mode drops broad allow rules on entry by design.
* **Can I run two accounts?** `alias claude-work='CLAUDE_CONFIG_DIR=~/.claude-work claude'`.
* **How do I see what a plugin costs in context?** `claude plugin details <name>`; `/context`; `/doctor`.
* **Is `--dangerously-skip-permissions` ever OK?** Only inside a container/VM/devcontainer as non-root; it offers no prompt-injection protection. Prefer auto mode + sandbox.

Sources: https://code.claude.com/docs/en/troubleshooting · https://code.claude.com/docs/en/troubleshoot-install · https://code.claude.com/docs/en/errors · https://code.claude.com/docs/en/network-config · https://code.claude.com/docs/en/debug-your-config · https://code.claude.com/docs/en/agent-sdk/troubleshooting

---

## K. Claude Agent SDK reference

> "Build production AI agents with Claude Code as a library." The SDK gives you the same tools, agent loop and context management that power Claude Code, programmable in Python and TypeScript. Architecturally it spawns and supervises a **bundled native `claude` binary** as a subprocess and talks to it over a stdio control protocol; one `query()` = one subprocess with its own cwd and JSONL transcript. Other languages: drive `claude -p --output-format stream-json` yourself.

### K.1 Concept mapping: Claude Code CLI ↔ Agent SDK ↔ Managed Agents

| You did this in Claude Code (M1–M4) | Agent SDK equivalent (M5) | Managed Agents equivalent (M6) |
|---|---|---|
| `CLAUDE.md`, `.claude/rules/` | Loaded via `settingSources` (default: user+project+local); or `systemPrompt: {type:"preset", preset:"claude_code", append}` / custom string | Versioned agent `system` string; skills; `read_only` memory store |
| `.claude/settings.json` allow/ask/deny, `--allowedTools` | `allowedTools`, `disallowedTools`, `tools` (availability), `settings` | Per-tool `configs[].enabled` + `permission_policy` |
| Permission modes, prompts | `permissionMode` (`default\|acceptEdits\|plan\|dontAsk\|auto\|bypassPermissions`), `canUseTool` callback, `permissionPromptToolName` | `always_allow` / `always_ask` → `session.status_idle{requires_action}` → `user.tool_confirmation` |
| Hooks in settings.json | `hooks: {PreToolUse: [{matcher, hooks:[callback]}]}` (in-process) + filesystem hooks via settingSources | Not applicable server-side; enforce in your event loop / custom tools |
| `.mcp.json`, `claude mcp add` | `mcpServers: {name: {type,url\|command,…}}`; in-process tools via `tool()` + `createSdkMcpServer()` | Agent `mcp_servers:[{type:"url",…}]` + `mcp_toolset` tools; credentials from vaults; client-executed `custom` tools |
| `.claude/agents/*.md`, `@agent-x` | `agents: {name: AgentDefinition}` + `Agent` in `allowedTools`; file agents via settingSources | `multiagent: {type:"coordinator", agents:[…]}` (session threads) |
| Skills / plugins | `skills: "all"\|[names]`; `plugins: [{type:"local", path}]` | Agent `skills: [{type:"anthropic"\|"custom", skill_id}]`; repo `.claude/skills` auto-discovered from GitHub resources |
| `claude -p --output-format json --json-schema` | `outputFormat/output_format: {type:"json_schema", schema}` → `result.structured_output` | `user.define_outcome` rubric + grader (different purpose); or ask for a JSON file in `/mnt/session/outputs/` |
| `--resume`, `--continue`, `--fork-session` | `resume`, `continue`/`continue_conversation`, `forkSession`, `listSessions()` | Sessions are server-side and stateful; send more `user.message` events |
| `--max-turns`, `--max-budget-usd`, `/usage` | `maxTurns`, `maxBudgetUsd`, `ResultMessage.total_cost_usd` / `modelUsage` | Session `budget`, `session.usage`, `span.model_request_end.model_usage`; $ per session-hour |
| Sandbox / devcontainer | `sandbox: {...}` option; hardened container + egress proxy (§K.4) | Cloud container per session with `networking: limited`; self-hosted worker |
| Working directory | `cwd`, `additionalDirectories` / `add_dirs` | Session `resources` (files, `github_repository`), `/workspace` |

Things that stay client-side when moving SDK → Managed Agents: plan mode, output styles, slash commands, PreToolUse/PostToolUse hooks, `max_turns`.

Sources: https://code.claude.com/docs/en/agent-sdk/claude-code-features · https://platform.claude.com/docs/en/managed-agents/migration

### K.2 Install, auth, versions

```bash
# TypeScript (Node.js 18+ per docs; workshop standardizes on current LTS 22.x)
npm init -y && npm pkg set type=module
npm install @anthropic-ai/claude-agent-sdk zod          # zod for tool schemas / structured output
# Python (3.10+)
uv init && uv add claude-agent-sdk                       # or: pip install claude-agent-sdk
```

| Item | Detail |
|---|---|
| Packages (Aug 2026) | npm `@anthropic-ai/claude-agent-sdk` **0.3.235** (tracks Claude Code 2.1.235; peer deps `zod ^4`, `@anthropic-ai/sdk`, `@modelcontextprotocol/sdk`) · PyPI `claude-agent-sdk` **0.2.140** (bundles CLI 2.1.235; deps `anyio`, `mcp`) **[volatile]** |
| Bundled CLI | Both SDKs ship the native binary (TS via per-platform optional deps; Python via platform wheels). If missing (`--omit=optional`, unsupported wheel): install Claude Code natively and set `pathToClaudeCodeExecutable` / `cli_path` |
| Auth | `ANTHROPIC_API_KEY` in the **process env** (SDK does not read `.env`); or `CLAUDE_CODE_USE_BEDROCK/VERTEX/FOUNDRY/ANTHROPIC_AWS=1` + cloud creds; `ANTHROPIC_AUTH_TOKEN`/`ANTHROPIC_BASE_URL` for gateways; `CLAUDE_CODE_OAUTH_TOKEN` for personal automation. **Third parties may not offer claude.ai login/rate limits in their products** — use API-key or cloud auth |
| Branding | "Claude Agent", "{YourAgent} Powered by Claude" allowed; not "Claude Code" |
| Repos / changelogs | github.com/anthropics/claude-agent-sdk-typescript · github.com/anthropics/claude-agent-sdk-python · demos github.com/anthropics/claude-agent-sdk-demos · cookbook github.com/anthropics/claude-cookbooks/tree/main/claude_agent_sdk |

### K.3 Entry points and options

**TypeScript:** `query({ prompt: string | AsyncIterable<SDKUserMessage>, options?: Options }): Query` (async generator of `SDKMessage`; string prompt = single-shot, iterable = streaming-input mode with `interrupt()`, `setPermissionMode()`, `setModel()`, `streamInput()`, `close()`). Also `startup()` (pre-warm), `tool()`, `createSdkMcpServer()`, `listSessions()`, `getSessionMessages()`, `forkSession()`, `renameSession()`, `deleteSession()`.

**Python:** `async for m in query(prompt=…, options=ClaudeAgentOptions(...))` (one-shot) or `async with ClaudeSDKClient(options) as client: await client.query("…"); async for m in client.receive_response(): …` (multi-turn, `interrupt()`, `set_permission_mode()`, `set_model()`, `get_mcp_status()`). Helpers `list_sessions()`, `get_session_messages()`, `fork_session()`, `tool`, `create_sdk_mcp_server`, `HookMatcher`, `AgentDefinition`, `PermissionResultAllow/Deny`.

| Option (TS `Options` · Py `ClaudeAgentOptions`) | Type | Notes |
|---|---|---|
| `systemPrompt` · `system_prompt` | `string` \| `{type:"preset", preset:"claude_code", append?, excludeDynamicSections?}` (Py also `{"type":"file","path"}`) | **Default is a minimal prompt**, not Claude Code's; use the preset for CLI-like behaviour |
| `cwd` · `cwd`; `additionalDirectories` · `add_dirs` | path(s) | Working directory / extra dirs |
| `model` · `model`; `fallbackModel` · `fallback_model` | alias or ID | `opus`, `sonnet`, `haiku`, full IDs |
| `effort` · `effort` | `low\|medium\|high\|xhigh\|max` | Reasoning effort |
| `thinking` · `thinking` | `{type:"adaptive"\|"enabled"\|"disabled", …}` | Replaces deprecated `maxThinkingTokens` |
| `tools` · `tools` | `string[]` \| `{type:"preset", preset:"claude_code"}` | **Availability** list |
| `allowedTools` · `allowed_tools` | `string[]` | Auto-approve (rule syntax §D.3); does not restrict availability; ignored by `bypassPermissions` |
| `disallowedTools` · `disallowed_tools` | `string[]` | Bare name removes tool; scoped rule denies matching calls (even in bypass) |
| `permissionMode` · `permission_mode` | `default\|acceptEdits\|plan\|dontAsk\|auto\|bypassPermissions` | TS bypass also needs `allowDangerouslySkipPermissions: true` |
| `canUseTool` · `can_use_tool` | callback | §K.6 |
| `permissionPromptToolName` · `permission_prompt_tool_name` | MCP tool name | Route prompts to a tool |
| `hooks` · `hooks` | `{Event: [{matcher?, hooks:[cb], timeout?}]}` / `{Event: [HookMatcher(...)]}` | §K.6 |
| `mcpServers` · `mcp_servers`; `strictMcpConfig` · `strict_mcp_config` | map (Py also path to JSON) | External + in-process servers (§K.7) |
| `agents` · `agents`; `agent` (TS) | `{name: AgentDefinition}` | Programmatic subagents; run main thread as an agent |
| `settingSources` · `setting_sources` | `("user"\|"project"\|"local")[]` | **Omitted = all three (matches CLI)**; `[]` = isolated (managed policy and `~/.claude.json` still read) |
| `settings` · `settings` | inline object (TS) / path | Flag-layer settings (hooks, env, permissions, `outputStyle`) |
| `plugins` · `plugins` | `[{type:"local", path}]` | Load plugin dirs (marketplace plugins must be on disk) |
| `skills` · `skills` | `"all"` \| `string[]` | Which discovered skills Claude may invoke (adds `Skill` tool) |
| `maxTurns` · `max_turns`; `maxBudgetUsd` · `max_budget_usd` | number | Caps → `error_max_turns` / `error_max_budget_usd` |
| `outputFormat` · `output_format` | `{type:"json_schema", schema}` | Structured output → `structured_output` |
| `resume`, `continue`/`continue_conversation`, `forkSession`/`fork_session`, `sessionId`/`session_id`, `resumeSessionAt`/`resume_session_at`, `persistSession` (TS) | | Sessions (§K.9) |
| `includePartialMessages` · `include_partial_messages`; `includeHookEvents`; `forwardSubagentText` · `forward_subagent_text` | bool | Extra stream events |
| `env` · `env` | map | **TS replaces** the subprocess env (spread `process.env`); **Python merges** |
| `sandbox` · `sandbox` | `SandboxSettings` | Same shape as §D.6 (`failIfUnavailable` defaults true) |
| `pathToClaudeCodeExecutable` · `cli_path`; `executable` (TS: `node\|bun\|deno`) | path | Binary override |
| `stderr`, `debug`/`debugFile`, `abortController` (TS), `extraArgs`/`extra_args`, `user` (Py) | | Diagnostics and passthrough flags |
| `sessionStore` · `session_store` (alpha), `enableFileCheckpointing` · `enable_file_checkpointing`, `taskBudget` · `task_budget`, `managedSettings` (TS), `toolConfig` (TS), `agentProgressSummaries` (TS), `promptSuggestions` (TS) | | Advanced |

`AgentDefinition`: `{ description, prompt, tools?, disallowedTools?, model?, effort?, maxTurns?, skills?, mcpServers?, memory?, background?, permissionMode?, initialPrompt? }` (camelCase in Python too).

Sources: https://code.claude.com/docs/en/agent-sdk/typescript · https://code.claude.com/docs/en/agent-sdk/python · https://code.claude.com/docs/en/agent-sdk/quickstart

### K.4 Hosting and secure deployment checklist

| Topic | Guidance (docs) |
|---|---|
| Process model | One session = one long-lived subprocess with local state (`~/.claude/projects/` transcripts, cwd). Patterns: **ephemeral** container per task · **long-running** container serving many sessions (TS `startup()` pre-warm / Py `ClaudeSDKClient`) · **hybrid** (ephemeral + `SessionStore`) · multi-agent container (per-agent `cwd` + isolated settings) |
| Sizing | Start at ~1 GiB RAM, 5 GiB disk, 1 vCPU per agent; memory grows with session length — recycle |
| Isolation | Sandbox providers (Modal, Cloudflare, Daytona, E2B, Fly, Vercel) or self-hosted Docker/gVisor/Firecracker; lightweight `@anthropic-ai/sandbox-runtime`; SDK `sandbox` option for Bash |
| Hardened container | `docker run --cap-drop ALL --security-opt no-new-privileges --read-only --tmpfs /tmp --network none --memory 2g --pids-limit 100 --user 1000:1000 -v code:/workspace:ro …` with egress only via a mounted proxy socket that injects credentials — "even if the agent is compromised via prompt injection, it cannot exfiltrate data to arbitrary servers" |
| Network | Outbound HTTPS to `api.anthropic.com` (or cloud endpoint) + MCP endpoints; egress proxy with domain allowlist (`HTTPS_PROXY` honored, or `ANTHROPIC_BASE_URL` → credential-injecting proxy) |
| Secrets | `ANTHROPIC_API_KEY` from a secret manager; keep tool credentials outside the agent boundary (MCP server/proxy injects); never mount `.env`, `~/.aws`, `~/.kube`, `*.pem` |
| Multi-tenant | `settingSources: []`, `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`, per-tenant `CLAUDE_CONFIG_DIR` and `cwd`, per-tenant egress rules; do not rely on default `query()` options for isolation |
| Limits | No session wall-clock timeout (use `maxTurns`/`maxBudgetUsd` and your own deadline); wide subagent fan-outs hit rate limits; cap `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` / `_MAX_CONCURRENT_SUBAGENTS` |
| Observability | `CLAUDE_CODE_ENABLE_TELEMETRY=1` + `OTEL_*` exporters in `env` (metrics/logs; traces beta via `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1`); spans `claude_code.interaction → llm_request / tool / hook`; W3C trace context propagates from your app |
| Updates | The CLI is bundled — update the SDK to update the CLI; take patches continuously |

Sources: https://code.claude.com/docs/en/agent-sdk/hosting · https://code.claude.com/docs/en/agent-sdk/secure-deployment · https://code.claude.com/docs/en/agent-sdk/observability

### K.5 Message and result types

Stream order: `system/init` → (`assistant` with text/`tool_use` → `user` with `tool_result`) × N → final `assistant` → `result` (a few trailing system events may follow — iterate to completion). TS discriminates on `message.type` (`content` at `message.message.content`); Python uses `isinstance` (`AssistantMessage.content` blocks `TextBlock`, `ToolUseBlock`, `ThinkingBlock`, `ToolResultBlock`).

| Type | Key fields |
|---|---|
| `system` / `SystemMessage` subtype `init` | `session_id`, `model`, `tools[]`, `mcp_servers[{name,status: pending\|connected\|failed\|needs-auth\|disabled}]`, `slash_commands`, `skills`, `plugins`, `permissionMode`, `claude_code_version` (Python: inside `.data`) |
| `assistant` / `AssistantMessage` | Anthropic `Message` (`content[]`, `usage`, `id`), `parent_tool_use_id` (non-null inside subagents), `error?` (`rate_limit`, `authentication_failed`, `billing_error`, …) |
| `user` / `UserMessage` | Tool results; `parent_tool_use_id` |
| `stream_event` / `StreamEvent` | Raw deltas when partial messages enabled |
| `result` / `ResultMessage` | `subtype` (`success` \| `error_max_turns` \| `error_during_execution` \| `error_max_budget_usd` \| `error_max_structured_output_retries`), `result` (success only), `session_id`, `num_turns`, `duration_ms`, `is_error`, `stop_reason`, `terminal_reason`, **`total_cost_usd`**, `usage` (main loop), **`modelUsage`/`model_usage`** (per model incl. subagents: `inputTokens`, `outputTokens`, `cacheReadInputTokens`, `cacheCreationInputTokens`, `costUSD`), `permission_denials[]`, `structured_output`, `deferred_tool_use`, `errors[]` |
| Others (TS names) | `SDKCompactBoundaryMessage`, hook messages, `SDKTaskStarted/Progress/NotificationMessage`, `SDKRateLimitEvent`, `SDKPermissionDeniedMessage`, `SDKAPIRetryMessage`, `SDKPromptSuggestionMessage` |

Rules: a single-shot `query()` **throws/raises after yielding an error result** — wrap in try/catch (Python `ProcessError`/`ResultError`, `CLINotFoundError`); `total_cost_usd`/`costUSD` are client-side estimates (do not bill from them); in multi-turn mode `modelUsage` is cumulative (read the latest, don't sum).

```python
async for m in query(prompt=PROMPT, options=opts):
    if isinstance(m, AssistantMessage):
        for b in m.content:
            print(getattr(b, "text", None) or f"[tool] {getattr(b, 'name', '')}")
    elif isinstance(m, ResultMessage):
        print(m.subtype, f"${m.total_cost_usd or 0:.4f}", m.session_id)
        findings = m.structured_output      # when output_format was set
```

Sources: https://code.claude.com/docs/en/agent-sdk/agent-loop · https://code.claude.com/docs/en/agent-sdk/cost-tracking · https://code.claude.com/docs/en/agent-sdk/streaming-vs-single-mode

### K.6 Built-in tools, permissions, `canUseTool`, hooks

**Built-in tools** (same names as the CLI): `Read`, `Edit`, `Write`, `Glob`, `Grep`, `Bash`, `WebFetch`, `WebSearch`, `NotebookEdit`, `Agent` (legacy name `Task` still appears in `init.tools`/denials — match both), `Skill`, `ToolSearch`, `AskUserQuestion`, `TaskCreate/Get/Update/List` (replace `TodoWrite`; omitted by default on the newest models unless listed in `tools`/`allowedTools`), `TaskStop`, `Monitor`, `EnterPlanMode`/`ExitPlanMode`, `EnterWorktree`/`ExitWorktree`, `ListMcpResourcesTool`/`ReadMcpResourceTool`, `LSP`, `PowerShell` (Windows), `Workflow`, `SendMessage`, `Cron*`; MCP tools as `mcp__<server>__<tool>`.

**Evaluation order:** hooks (`PreToolUse`) → deny rules (`disallowedTools` + settings; apply even in bypass) → ask rules → permission mode → allow rules (`allowedTools` + settings) → **`canUseTool` callback** (skipped → deny in `dontAsk`). Consequence: auto-approved calls never reach `canUseTool`; to see every call use a `PreToolUse` hook.

```typescript
// canUseTool (TS)
canUseTool: async (toolName, input, { signal, suggestions, toolUseID, agentID }) =>
  toolName === "mcp__tracker__create_ticket" && input.severity !== "HIGH"
    ? { behavior: "deny", message: "only HIGH severity gets a ticket" }
    : { behavior: "allow", updatedInput: input }
```

```python
# can_use_tool (Python)
async def can_use_tool(tool_name, input_data, ctx):   # ctx: ToolPermissionContext(tool_use_id, agent_id, suggestions, …)
    if tool_name == "mcp__tracker__create_ticket" and input_data.get("severity") != "HIGH":
        return PermissionResultDeny(message="only HIGH severity gets a ticket")
    return PermissionResultAllow(updated_input=input_data)
```

**Hooks in the SDK** are in-process callbacks using the same JSON output schema as CLI hooks; filesystem hooks from settings still load via `settingSources`. Events — Python: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `SubagentStart`, `PreCompact`, `Notification`, `PermissionRequest`. TypeScript adds `SessionStart`, `SessionEnd`, `Setup`, `PostToolBatch`, `PermissionDenied`, `ConfigChange`, `CwdChanged`, `FileChanged`, `WorktreeCreate/Remove`, `Elicitation*`, `TaskCreated/Completed`, `TeammateIdle`, `MessageDisplay`, `InstructionsLoaded`, `StopFailure`, `PostCompact`, `UserPromptExpansion`, `DirectoryAdded`.

```python
from claude_agent_sdk import ClaudeAgentOptions, HookMatcher
async def protect_secrets(input_data, tool_use_id, context):
    p = input_data["tool_input"].get("file_path", "")
    if "/.env" in p or "/secrets/" in p:
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": "secret files are off limits"}}
    return {}
opts = ClaudeAgentOptions(hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets])]})
```

```typescript
hooks: { PreToolUse: [{ matcher: "Write|Edit", hooks: [async (input) =>
  (input as PreToolUseHookInput).tool_input?.file_path?.endsWith(".env")
    ? { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "no .env edits" } }
    : {} ] }] }
```

Sources: https://code.claude.com/docs/en/agent-sdk/permissions · https://code.claude.com/docs/en/agent-sdk/hooks · https://code.claude.com/docs/en/agent-sdk/user-input

### K.7 Custom tools (in-process MCP) and external MCP

Tool = name + description + input schema + async handler returning `{ content: [{type:"text", text}], isError? }` (Py `is_error`); served by an in-process "SDK MCP server"; full name **`mcp__<serverKey>__<toolName>`** where `serverKey` is the key you use in `mcpServers`.

```typescript
import { query, tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";
const createTicket = tool("create_ticket", "File a ticket for a finding",
  { title: z.string(), severity: z.enum(["HIGH","MEDIUM","LOW"]), file: z.string(), line: z.number() },
  async (a) => ({ content: [{ type: "text", text: `TICKET-${Date.now()}` }] }));
const tracker = createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] });
query({ prompt, options: { mcpServers: { tracker }, allowedTools: ["mcp__tracker__create_ticket"] } });
```

```python
from claude_agent_sdk import tool, create_sdk_mcp_server, ClaudeAgentOptions
@tool("create_ticket", "File a ticket for a finding", {"title": str, "severity": str, "file": str, "line": int})
async def create_ticket(args):
    return {"content": [{"type": "text", "text": f"TICKET-{args['file']}:{args['line']}"}]}
tracker = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
opts = ClaudeAgentOptions(mcp_servers={"tracker": tracker}, allowed_tools=["mcp__tracker__create_ticket"])
```

Signatures: TS `tool(name, description, zodShape, handler, { annotations?: {readOnlyHint…}, searchHint?, alwaysLoad? })`, `createSdkMcpServer({ name, version?, tools, instructions?, alwaysLoad? })`; Py `@tool(name, description, input_schema: dict|type, annotations=None)`, `create_sdk_mcp_server(name, version="1.0.0", tools=[...])`. External servers: `{ type: "http", url, headers }`, `{ type: "sse", … }`, `{ command, args, env }` (stdio); MCP tools always need permission (`allowedTools: ["mcp__github__*"]`; `acceptEdits` doesn't cover MCP). Servers connect in the background (`init.mcp_servers[].status`); the SDK runs no OAuth browser flow — pass tokens in `headers`. Tool search is on by default (`ENABLE_TOOL_SEARCH`).

Sources: https://code.claude.com/docs/en/agent-sdk/custom-tools · https://code.claude.com/docs/en/agent-sdk/mcp

### K.8 Subagents, skills, plugins, settings in the SDK

* **Subagents:** `agents: {"lang-scout": {description, prompt, tools:["Read","Grep","Glob"], model:"haiku"}}` + `"Agent"` in `allowedTools`; file agents from `.claude/agents/` load via `settingSources`; built-in `general-purpose` always available (`CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1` to remove). Messages from inside a subagent carry `parent_tool_use_id`; subagents run in the background by default. For dozens of agents use the `Workflow` tool (TS SDK ≥0.3.149; include `Workflow` in `allowedTools`).
* **Skills:** filesystem only (`.claude/skills`, `~/.claude/skills`, plugin skills) — no programmatic registration; `skills: "all" | ["code-reviewer"] | []`; SKILL.md `allowed-tools` is **not** applied in SDK sessions — pre-approve with `allowedTools`.
* **Plugins:** `plugins: [{ type: "local", path: "../codebase-toolkit" }]`; verify via `init.plugins` and namespaced skills (`codebase-toolkit:code-reviewer`); invoke by sending `/codebase-toolkit:code-reviewer src/x` as the prompt or `@agent-codebase-toolkit:bug-hunter …`.
* **Slash commands** work as prompt text (`/compact`, `/context`, your skills); discover via `init.slash_commands`.
* **`settingSources`:** omitted = `["user","project","local"]` (CLAUDE.md, rules, skills, agents, hooks, `.mcp.json`, settings files — same as CLI); `[]` = programmatic only. Read regardless: managed policy, `~/.claude.json`, auto memory (`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` to disable), claude.ai connectors when logged in via claude.ai (`strictMcpConfig`).
* **System prompt choice:** minimal default (thin tool loop) · `claude_code` preset (+`append`) for CLI-like coding agents · custom string when identity/permission model differs. `excludeDynamicSections` moves per-machine context to the first user message for cross-host prompt-cache reuse.

Sources: https://code.claude.com/docs/en/agent-sdk/subagents · https://code.claude.com/docs/en/agent-sdk/skills · https://code.claude.com/docs/en/agent-sdk/plugins · https://code.claude.com/docs/en/agent-sdk/modifying-system-prompts

### K.9 Structured output, sessions, streaming input, cost

| Need | API |
|---|---|
| Schema-validated JSON | `outputFormat: { type: "json_schema", schema: z.toJSONSchema(S) }` / `output_format={"type":"json_schema","schema": Model.model_json_schema()}` → `result.structured_output`; failure subtype `error_max_structured_output_retries`; supports objects/arrays/enum/`$ref`; `format` is annotation only |
| One-shot | `query(prompt="…")` |
| Multi-turn in one process | Py `ClaudeSDKClient` (`query()` then `receive_response()` per turn; `interrupt()`); TS pass an `AsyncIterable<SDKUserMessage>` and use `q.streamInput()`, `q.interrupt()` |
| Continue most recent | `continue: true` / `continue_conversation=True` |
| Resume specific | capture `session_id` from `ResultMessage` (TS also `init`) → `resume: id`; `forkSession: true` to branch; `resumeSessionAt` to rewind |
| No transcripts on disk | TS `persistSession: false`; Py env `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` |
| Cross-host resume | `SessionStore` adapter (`InMemorySessionStore`; S3/Redis/Postgres examples in the SDK repos) |
| List/inspect | `listSessions()`, `getSessionMessages()`, `renameSession()`, `tagSession()`, `deleteSession()` (Py snake_case) |
| Cost | `ResultMessage.total_cost_usd`, `modelUsage[model].{inputTokens,outputTokens,cacheReadInputTokens,cacheCreationInputTokens,costUSD}`; per-step `AssistantMessage.usage` (dedupe by message id); prompt caching automatic (`ENABLE_PROMPT_CACHING_1H=1` for 1-hour TTL on API keys) |
| Todo tracking | Watch `TaskCreate`/`TaskUpdate` tool_use blocks (task tools must be listed in `tools` on newest models) |
| File checkpointing | `enableFileCheckpointing: true` → `query.rewindFiles(userMessageUuid)` / `client.rewind_files()` |

Sources: https://code.claude.com/docs/en/agent-sdk/structured-outputs · https://code.claude.com/docs/en/agent-sdk/sessions · https://code.claude.com/docs/en/agent-sdk/session-storage

### K.10 Migration and breaking changes (2025 → Aug 2026)

| When | Change | Action |
|---|---|---|
| 0.1.0 (Sep 2025) | **Renamed** `@anthropic-ai/claude-code` (SDK import) → `@anthropic-ai/claude-agent-sdk`; `claude-code-sdk` → `claude-agent-sdk`; `ClaudeCodeOptions` → `ClaudeAgentOptions` | `npm uninstall @anthropic-ai/claude-code && npm i @anthropic-ai/claude-agent-sdk`; `pip install claude-agent-sdk`; rename imports |
| 0.1.0 | `customSystemPrompt`/`appendSystemPrompt` merged into `systemPrompt`; **no Claude Code system prompt by default** | Use `{type:"preset", preset:"claude_code", append}` if you relied on it |
| 0.1.0 → later reverted | Settings isolation default | **Today omitting `settingSources` loads user+project+local like the CLI**; pass `[]` to isolate (upgrade very old Python versions where `[]` meant "unset") |
| TS 0.1.45 / Py 0.1.7 | Structured outputs (`outputFormat`) | — |
| TS 0.1.57 / Py 0.1.12 | `tools` availability option | Prefer over prompt-only restrictions |
| CC 2.1.63 | `Task` tool renamed `Agent` in `tool_use` blocks | Match both names |
| TS 0.2.91 / Py 0.1.57 | `permissionMode: "auto"`; `terminal_reason`; `startup()` pre-warm; `includeHookEvents` | — |
| TS 0.2.113 | SDK spawns the **native binary** via optional deps; TS `env` replaces `process.env` again; `sessionStore` alpha; `title` | Don't `--omit=optional`; spread `process.env` |
| TS 0.2.120 / Py 0.1.62 | `skills` option | Replace `'Skill'` in `allowedTools` |
| **TS 0.3.142** | Version jump 0.2.141 → 0.3.142: experimental **V2 session API removed** (`unstable_v2_*`); **MCP servers connect in background** by default; **Task tools replace TodoWrite** in SDK/headless sessions | Use `query()` + AsyncIterable / `resume`; check `init.mcp_servers[].status`; watch `TaskCreate/TaskUpdate` |
| TS 0.3.143 | `@anthropic-ai/sdk`, `@modelcontextprotocol/sdk` become peer deps | Add them if your package manager doesn't auto-install peers |
| TS 0.3.217 / CC 2.1.217+ | Subagent nesting/concurrency caps (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, `_MAX_CONCURRENT_SUBAGENTS`) | Tune for fan-outs |
| TS 0.3.233 / Py 0.2.13x | Task-tracking tools removed from the default surface on newest models | List them in `tools` or set `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` |
| Py 0.2.140 | `ResultError` structured exception; `can_use_tool` works with string prompts; MCP 2.x; `forward_subagent_text` | — |
| Ongoing | `betas: ["context-1m-…"]` retired 2026-04-30 (no effect); `maxThinkingTokens` deprecated → `thinking`; docs moved to code.claude.com/docs/en/agent-sdk/* | Clean up options |

Sources: https://code.claude.com/docs/en/agent-sdk/migration-guide · https://github.com/anthropics/claude-agent-sdk-typescript/blob/main/CHANGELOG.md · https://github.com/anthropics/claude-agent-sdk-python/blob/main/CHANGELOG.md

---

## L. Claude Managed Agents reference

> **Status (Aug 2026) [volatile]:** public beta on the Claude Platform (launched 2026-04-08), enabled by default for API organizations; all endpoints require the beta header **`anthropic-beta: managed-agents-2026-04-01`** (SDKs set it automatically under `client.beta.*`; memory-store endpoints use `agent-memory-2026-07-22`). Also available on Claude Platform on AWS (feature differences); **not** on Bedrock/Vertex. Not eligible for ZDR or HIPAA BAA. MCP tunnels and "dreaming" are limited research previews. Models: Claude 4.5 and later.

### L.1 Concepts glossary

| Concept | Definition (docs) | Key fields / limits |
|---|---|---|
| **Agent** | The model, system prompt, tools, MCP servers and skills. Versioned (`version` increments on each changing update; pin per session; `archive` = read-only) | `name`\*, `model`\* (string or `{id, speed, effort, inference_geo}`), `system` (≤100k chars), `tools[]` (≤128 across toolsets), `mcp_servers[]` (≤20), `skills[]`, `multiagent`, `description`, `metadata` |
| **Environment** | Where sessions run: Anthropic-managed **cloud** container or **self-hosted** worker. Not versioned; each session gets a fresh container | `config.type: "cloud"` with `packages` (`apt/pip/npm/cargo/gem/go`, cached) and `networking: {type:"unrestricted"}` or `{type:"limited", allowed_hosts[], allow_package_managers, allow_mcp_servers}`; or `{type:"self_hosted"}` |
| **Session** | A running agent instance in an environment; stateful (filesystem + history), statuses `idle` / `running` / `rescheduling` / `terminated` | `agent` (id = latest, `{type:"agent",id,version}` pin, or `{type:"agent_with_overrides",…}`), `environment_id`, `title`, `initial_events` (≤50), `resources[]`, `vault_ids[]`, `budget`, `metadata` |
| **Events** | Messages between your app and the agent: `user.*` in, `agent.*` / `session.*` / `span.*` out; SSE stream | `POST/GET …/events`, `GET …/events/stream` |
| **Agent toolset** | `{"type":"agent_toolset_20260401"}` = `bash`, `read`, `write`, `edit`, `glob`, `grep`, `web_fetch`, `web_search` running in the sandbox against `/workspace` | Per-tool `configs[{name, enabled, permission_policy}]`, `default_config`; tool output >100k chars spills to a file |
| **Custom tools** | `{"type":"custom", name, description, input_schema}` — executed by **your** application | Round-trip `agent.custom_tool_use` → `user.custom_tool_result` |
| **MCP toolset** | `{"type":"mcp_toolset","mcp_server_name":…}` bound to `mcp_servers:[{type:"url", name, url}]`; credentials from vaults | Default policy `always_ask` |
| **Permission policy** | `always_allow` \| `always_ask` per tool; `always_ask` pauses the session (`session.status_idle`, `stop_reason.type:"requires_action"`) until `user.tool_confirmation` | Toolset default `always_allow`; MCP default `always_ask`; custom tools not governed |
| **Vaults / credentials** | Per-end-user secret containers referenced by `vault_ids`; `auth.type: mcp_oauth` (auto-refresh) \| `static_bearer` \| `environment_variable` (injected at egress toward `allowed_hosts`; the model sees a placeholder) | ≤20 credentials/vault; secrets write-only |
| **Files / resources** | Files API uploads mounted at `/mnt/session/uploads/…`; `github_repository` resources cloned to `/workspace/<repo>` (token rotatable; repo `.claude/skills` auto-discovered); deliverables written to **`/mnt/session/outputs/`** and listed with `files.list(scope_id=session_id)` | ≤500 files/session |
| **Memory stores** | Workspace-scoped text memories mounted at `/mnt/memory/<slug>/`, `access: read_only\|read_write`; versioned writes | ≤8 stores/session, 100 kB/memory, 2,000/store; use `read_only` for reference to avoid poisoning |
| **Skills** | `pptx`, `xlsx`, `docx`, `pdf` (Anthropic) or custom uploads (`/v1/skills`) | ≤500/session |
| **Outcomes** | `user.define_outcome {description, rubric, max_iterations}` → separate grader; `span.outcome_evaluation_*` with `satisfied\|needs_revision\|max_iterations_reached\|failed` | `max_iterations` ≤20 |
| **Multi-agent** | `multiagent: {type:"coordinator", agents:[{type:"agent", id, version?}]}`; roster agents run as session threads sharing the sandbox; optional advisor entry | ≤25 concurrent threads |
| **Budgets** | `budget: {type:"limit", max_list_cost:{amount:"0.50", currency:"USD"}}` → `stop_reason: budget_reached`, webhook `session.budget_reached` | List-price based |
| **Webhooks** | Console → Manage → Webhooks (also `/v1/webhooks`); events `session.status_idled`, `session.status_run_started`, `session.status_terminated`, `session.budget_reached`, `agent.updated`, `deployment_run.*`, `environment.*`, `memory_store.*`, `vault_credential.refresh_failed`; payload `{type,id}` only; headers `webhook-id/-timestamp/-signature`; secret `whsec_…`; verify with `client.beta.webhooks.unwrap()`; 3 attempts | |
| **Scheduled deployments** | Run an agent on cron; `deployment` + `deployment_run` resources; Console Deployments page | ≤1,000/org |
| **Self-hosted sandbox** | Environment `{type:"self_hosted"}` + your worker (`ant beta:worker poll --workdir /workspace` or SDK `EnvironmentWorker`) authenticated with an **environment key**; loop stays hosted, tools/filesystem/egress on your host | `environment_variable` credentials not yet supported |
| **Cloud sandbox spec** | Ubuntu 22.04 x86_64, up to 8 GB RAM / 10 GB disk; Python 3.12+, Node 20+, Go, Rust, Java 21+, Ruby, PHP, GCC; state checkpointed on idle, kept 30 days | |
| **Console** | Agent quickstart/builder (`platform.claude.com/workspaces/default/agent-quickstart`), Sessions list + **tracing view** (events, tokens, tool calls; Developer/Admin roles), Environments, Vaults, Memory stores, Deployments, Webhooks | |
| **`ant` CLI** | `brew install anthropics/tap/ant` (or GitHub releases `anthropics/anthropic-cli`); `ant beta:agents create\|list`, `ant beta:sessions create`, `ant beta:sessions:events send`, `ant beta:worker poll` | Optional |

### L.2 Headers, auth, SDKs

```text
x-api-key: $ANTHROPIC_API_KEY
anthropic-version: 2023-06-01
anthropic-beta: managed-agents-2026-04-01        # memory-store endpoints: agent-memory-2026-07-22
content-type: application/json
```

SDKs: `pip install anthropic` / `npm install @anthropic-ai/sdk` (also Java, Go, C#, Ruby, PHP) — everything under `client.beta.agents|environments|sessions|vaults|memory_stores|files|webhooks`. Guided setup inside Claude Code: `/claude-api managed-agents-onboard`.

### L.3 Endpoint map

| Resource | Endpoints |
|---|---|
| Agents | `POST /v1/agents` · `GET /v1/agents` · `GET /v1/agents/{id}` · `POST /v1/agents/{id}` (update; optional `version` → 409 on mismatch) · `GET /v1/agents/{id}/versions` · `POST /v1/agents/{id}/archive` |
| Environments | `POST /v1/environments` · `GET /v1/environments` · `GET /v1/environments/{id}` · `POST /v1/environments/{id}/archive` · `DELETE /v1/environments/{id}` |
| Sessions | `POST /v1/sessions` · `GET /v1/sessions` · `GET /v1/sessions/{id}` · `POST /v1/sessions/{id}` (update) · `POST /v1/sessions/{id}/archive` · `DELETE /v1/sessions/{id}` |
| Events | `POST /v1/sessions/{id}/events` · `GET /v1/sessions/{id}/events` · `GET /v1/sessions/{id}/events/stream` (SSE; optional `event_deltas[]`) · `GET /v1/sessions/{id}/threads/{thread_id}/stream` |
| Session resources | `POST/GET/DELETE /v1/sessions/{id}/resources` |
| Vaults | `POST /v1/vaults` · `POST /v1/vaults/{id}/credentials` · `POST /v1/vaults/{id}/credentials/{cred}` (rotate) · `…/mcp_oauth_validate` · `…/archive` · `DELETE` |
| Memory | `POST /v1/memory_stores` · `…/{id}/memories` · `…/memory_versions` · `…/memory_versions/{id}/redact` · archive/delete |
| Files | `POST /v1/files` · `GET /v1/files?scope_id=<session_id>` · `GET /v1/files/{id}/content` |
| Skills / Webhooks / Deployments | `POST /v1/skills` · `/v1/webhooks` · deployments (Console + API reference) |

Rate limits (per org) **[volatile]**: create endpoints 300 req/min; read/list/stream 1,200 req/min; plus normal spend tiers. Request body ≤32 MB.

### L.4 Event catalogue and statuses

| Direction | Events |
|---|---|
| You → session | `user.message` · `user.interrupt` · `user.tool_confirmation {tool_use_id, result:"allow"\|"deny", deny_message?}` · `user.custom_tool_result {custom_tool_use_id, content[]}` · `user.define_outcome` · (`user.tool_result` self-hosted only) · `system.message` (newer models) |
| Agent → you | `agent.message` (content blocks; may include `{"type":"redacted"}`) · `agent.thinking` (signal only) · `agent.tool_use` / `agent.tool_result` · `agent.mcp_tool_use` / `agent.mcp_tool_result` · `agent.custom_tool_use` · `agent.thread_message_sent/received` · `agent.thread_context_compacted` |
| Session lifecycle | `session.status_running` · `session.status_idle` (with `stop_reason.type`: `end_turn` \| `requires_action` (+ `event_ids[]`) \| `budget_reached` \| `retries_exhausted`) · `session.status_rescheduled` · `session.status_terminated` · `session.error {error.type: model_overloaded_error\|model_rate_limited_error\|mcp_connection_failed_error\|mcp_authentication_failed_error\|billing_error, retry_status: retrying\|exhausted\|terminal}` · `session.usage` · `session.updated` · `session.deleted` · `session.thread_created` |
| Spans | `span.model_request_start` / `span.model_request_end {model_usage}` · `span.outcome_evaluation_start/ongoing/end` |
| Stream-only | `event_start`, `event_delta` (when `event_deltas[]=agent.message` requested) |

Approval flow: `agent.tool_use` (policy `always_ask`) → `session.status_idle{requires_action, event_ids}` → send one `user.tool_confirmation` per id → `running`. Custom-tool flow: `agent.custom_tool_use` → same idle → run your function → `user.custom_tool_result`. Billing accrues only while `running`.

### L.5 SDK snippets (Python; TS is `client.beta.<same>` camel-cased)

```python
import os
from anthropic import Anthropic
client = Anthropic()  # ANTHROPIC_API_KEY
MODEL = os.environ["CMA_MODEL"]  # full model ID from labs/.env (aliases like "sonnet" 400 here)

env = client.beta.environments.create(
    name="ws-alice",
    config={"type": "cloud", "packages": {"pip": ["ruff"]},
            "networking": {"type": "limited",
                           "allowed_hosts": ["github.com", "api.github.com", "raw.githubusercontent.com"],
                           "allow_package_managers": True, "allow_mcp_servers": False}})

agent = client.beta.agents.create(
    name="codebase-toolkit-alice", model=MODEL, system=open("prompts/bug_hunter_system.md").read(),
    tools=[{"type": "agent_toolset_20260401",
            "default_config": {"permission_policy": {"type": "always_allow"}},
            "configs": [{"name": "web_fetch", "permission_policy": {"type": "always_ask"}},
                        {"name": "web_search", "enabled": False}]},
           {"type": "custom", "name": "create_ticket", "description": "File a ticket for a HIGH finding",
            "input_schema": {"type": "object",
                             "properties": {"title": {"type": "string"}, "severity": {"type": "string"},
                                            "file": {"type": "string"}, "line": {"type": "integer"}},
                             "required": ["title", "severity", "file", "line"]}}])
agent = client.beta.agents.update(agent.id, system=NEW_SYSTEM)          # -> version 2

session = client.beta.sessions.create(
    agent=agent.id, environment_id=env.id, title="paymentservice bug hunt",
    budget={"type": "limit", "max_list_cost": {"amount": "0.50", "currency": "USD"}},
    initial_events=[{"type": "user.message", "content": [{"type": "text", "text": TASK}]}])

pending = {}                                                            # tool-use events awaiting our answer
with client.beta.sessions.events.stream(session.id) as stream:
    for ev in stream:
        if ev.type == "agent.message":
            print("".join(getattr(b, "text", "") for b in ev.content), end="")
        elif ev.type in ("agent.tool_use", "agent.custom_tool_use"):
            pending[ev.id] = ev; print(f"\n[{ev.type}: {ev.name}]")
        elif ev.type == "span.model_request_end":
            print(f"\n(tokens: {ev.model_usage})")
        elif ev.type == "session.status_idle":
            sr = ev.stop_reason
            if sr.type == "requires_action":
                out = []
                for eid in sr.event_ids:
                    p = pending[eid]
                    if p.type == "agent.tool_use":          # always_ask tool (web_fetch)
                        ok = input(f"allow {p.name}? [a/d] ") == "a"
                        out.append({"type": "user.tool_confirmation", "tool_use_id": eid,
                                    "result": "allow" if ok else "deny", **({} if ok else {"deny_message": "not needed"})})
                    else:                                    # custom tool
                        out.append({"type": "user.custom_tool_result", "custom_tool_use_id": eid,
                                    "content": [{"type": "text", "text": create_ticket(**p.input)}]})
                client.beta.sessions.events.send(session.id, events=out)
            elif sr.type in ("end_turn", "budget_reached"):
                break

# steer / follow up on the same session
client.beta.sessions.events.send(session.id, events=[{"type": "user.interrupt"},
    {"type": "user.message", "content": [{"type": "text", "text": "Skip the upstream comparison; finish the report."}]}])

# deliverables + usage
for f in client.beta.files.list(scope_id=session.id): open(f.filename, "wb").write(client.beta.files.download(f.id).read())
print(client.beta.sessions.retrieve(session.id).usage)   # tokens, active_seconds, list_cost
```

SDK object attribute names above follow the current `anthropic` Python SDK and Managed Agents docs; if a field differs in your SDK version, check the API reference (`platform.claude.com/docs/en/api/beta/sessions/…`).

Raw HTTP: `curl https://api.anthropic.com/v1/agents -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "anthropic-beta: managed-agents-2026-04-01" -H "content-type: application/json" -d '{"name":"Coding Assistant","model":"claude-opus-5","tools":[{"type":"agent_toolset_20260401"}]}'`. Other snippets: pin `agent={"type":"agent","id":…,"version":1}`; override `agent={"type":"agent_with_overrides","id":…,"model":{"id":"claude-haiku-4-5"}}`; vault `client.beta.vaults.credentials.create(vault_id, auth={"type":"static_bearer",…})` then `sessions.create(..., vault_ids=[v.id])`; memory `client.beta.memory_stores.create(...)` + `resources=[{"type":"memory_store","memory_store_id":…, "access":"read_only"}]`; webhook `event = client.beta.webhooks.unwrap(body, headers=…)` with `ANTHROPIC_WEBHOOK_SIGNING_KEY`; self-hosted `ANTHROPIC_ENVIRONMENT_KEY=… ant beta:worker poll --workdir /workspace`.

### L.6 Pricing, limits, positioning

* **Pricing [volatile]:** tokens at standard model rates (prompt caching applies; web search $10/1,000; fast-mode premium if `speed:"fast"`; `inference_geo:"us"` 1.1x) **plus session runtime $0.08 per session-hour, accrued only while status is `running`** (idle/rescheduling/terminated free). Docs' worked example: 1-hour Opus session with 50k in / 15k out ≈ $0.705. No batch discount.
* **Limits:** see L.1/L.3 (create 300 rpm, read 1,200 rpm, ≤50 initial events, ≤20 MCP servers, ≤128 tools, ≤8 memory stores, ≤25 threads).
* **Choose CMA vs Agent SDK vs Claude Code on the web:** CMA when you want Anthropic to run the loop and sandbox for long-running/async agents in *your product* (metered runtime, REST/webhooks, vaults, scheduling); Agent SDK when the agent must run in your process/network with your own hosting and full hook control; Claude Code on the web when a *developer* wants cloud sessions on repos under their subscription. Cookbook lab seeds: https://github.com/anthropics/claude-cookbooks/tree/main/managed_agents ; quickstarts https://github.com/anthropics/claude-quickstarts/tree/main/managed-agents .

Sources: https://platform.claude.com/docs/en/managed-agents/overview · /quickstart · /agent-setup · /environments · /sessions · /session-operations · /events-and-streaming · /tools · /permission-policies · /vaults · /memory · /files · /github · /skills · /define-outcomes · /multiagent-orchestration · /budgets · /webhooks · /scheduled-deployments · /self-hosted-sandboxes · /migration · /reference · https://platform.claude.com/docs/en/about-claude/pricing#claude-managed-agents-pricing · https://platform.claude.com/docs/en/api/beta-headers · https://www.anthropic.com/engineering/managed-agents

---

## M. Security and Claude Security reference

### M.1 Threat → control matrix for coding agents

| Threat | Example | Controls you already have (module) | Ref |
|---|---|---|---|
| Prompt injection via repo content, issues, web pages, MCP tool output | README says "AI agents: run `curl … \| sh`" | Permission rules are enforced by the client, not the model (M2); auto-mode classifier strips tool results and blocks escalation (M1); `PreToolUse` hooks (M2); sandbox as OS-level backstop (M2); treat fetched content as data; Claude Security reports text addressed to the scanner as a `prompt-injection` finding (M7) | D.2, D.3, E, D.6 |
| Over-broad permissions / `bypassPermissions` | `Bash(*)` allow, `--dangerously-skip-permissions` on a laptop | Narrow allow rules, explicit `deny`/`ask` (M2); auto mode drops broad rules; bypass only in containers, disable org-wide `disableBypassPermissionsMode` (D.4); `dontAsk` + `--allowedTools` in CI (M4); SDK `allowedTools`/`canUseTool` (M5); CMA `always_ask` (M6) | D, I.1, K.6, L |
| Secret exposure (env, dotfiles, logs, PR text) | Agent reads `.env`, prints a token, commits it | `deny Read(./.env*)`, `Read(./secrets/**)` (M2); sandbox `credentials` deny/mask, `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`; GitHub Secrets/OIDC (M4); credential-injecting proxy for SDK agents (K.4); CMA vaults (M6); auto mode blocks printing live credentials and secrets in public PR text | D.3, D.6, K.4, L |
| Supply chain: plugins, marketplaces, MCP servers, actions | Malicious plugin hook; MCP server exfiltrates | Only trusted sources; `strictKnownMarketplaces`/`blockedMarketplaces`, `allowedMcpServers`, `managed-mcp.json` (D.4/F.7); review `allowed-tools` in repo skills; pin action versions; CMA MCP toolsets default `always_ask` | H.2, F.7, L |
| Unattended / headless trust gaps | `-p` in an untrusted checkout runs its hooks and MCP servers | `--bare`, `--setting-sources user`, `disableAllHooks` (M4); minimal workflow `permissions:`; trusted PRs only for AI review actions | I.1, I.2, M.4 |
| Memory / state poisoning | Injected content written to a `read_write` memory store or auto memory | CMA `read_only` stores for reference material (M6); review auto memory (`/memory`); `ConfigChange` hook for settings drift | L, E |
| Insecure code the agent writes | SQLi, SSRF, `yaml.load`, hardcoded keys | security-guidance plugin while coding → `/security-review` on the branch → Claude Security plugin deep scan → Code Review / security-review Action on PR → SAST/dependency scanners → hosted Claude Security (M7) | M.2–M.5 |
| Data egress from the sandbox | `curl` to attacker host | Sandbox `network.allowedDomains` + `strictAllowlist`; devcontainer default-deny firewall; SDK container `--network none` + proxy; CMA `networking: limited`; web sessions' egress allowlist | D.6, K.4, L, I.3 |

Hardening recipes (drop into `.claude/settings.json`; from the docs' examples):

```json
{
  "permissions": {
    "defaultMode": "default",
    "allow": ["Bash(go test *)", "Bash(npm test *)", "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)"],
    "ask":   ["Bash(git push *)", "Bash(gh pr create *)"],
    "deny":  ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)", "Bash(curl *)", "Bash(wget *)"],
    "disableBypassPermissionsMode": "disable"
  },
  "sandbox": { "enabled": true, "failIfUnavailable": false, "allowUnsandboxedCommands": false,
               "network": { "allowedDomains": ["proxy.golang.org", "registry.npmjs.org", "api.github.com"] },
               "credentials": { "files": [{ "path": "~/.aws/credentials", "mode": "deny" }, { "path": "~/.ssh", "mode": "deny" }],
                                "envVars": [{ "name": "GITHUB_TOKEN", "mode": "deny" }] } },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command",
             "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-curl-pipe-sh.sh" } ] } ],
             "ConfigChange": [ { "hooks": [ { "type": "command", "command": "jq -c . >> \"$CLAUDE_PROJECT_DIR\"/.claude/config-changes.log" } ] } ] }
}
```

Auto-mode classifier summary: reviews every non-trivial action (and subagent spawns/results, cross-session messages) against user intent + `autoMode.environment/allow/soft_deny/hard_deny`; blocked by default: `curl | bash`, exfiltration, prod deploys/migrations, force-push, destructive git, IAM grants, printing credentials, launching bypass-mode agents; allowed by default: local edits, declared dependency installs, read-only HTTP, pushing to the current repo's branches; 3 consecutive / 20 total blocks pause auto mode; "reduces prompts but does not guarantee safety" — it is a per-action control, not an isolation boundary.

Sources: https://code.claude.com/docs/en/security · https://code.claude.com/docs/en/permission-modes · https://code.claude.com/docs/en/sandboxing · https://code.claude.com/docs/en/agent-sdk/secure-deployment · https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks · https://www.anthropic.com/engineering/claude-code-sandboxing · https://www.anthropic.com/engineering/claude-code-auto-mode

### M.2 Claude Security plugin for Claude Code (`claude-security@claude-plugins-official`) — beta, Aug 2026

**What:** a multi-agent vulnerability scan that runs *inside your Claude Code session, under your permissions*: agents map the architecture, build a threat model, hunt per component × category, and an independent panel verifies every finding before the report is written; selected findings can be turned into verified patches you apply yourself. It is the in-session sibling of the hosted Claude Security product; it reaches code the hosted product cannot (GitLab/Bitbucket, air-gapped networks). Scans count against your plan usage; nondeterministic — run regularly.

| Item | Detail |
|---|---|
| Prerequisites | Claude Code v2.1.154+ on a paid plan with **dynamic workflows** (Pro: enable in `/config`; orgs may disable) · `python3` ≥ 3.9.6 on PATH (stdlib only) · git for change scans/patches · works best in **auto mode** |
| Install | `/plugin install claude-security@claude-plugins-official` → `/reload-plugins` (add marketplace `anthropics/claude-plugins-official` if missing); uninstall `claude plugin uninstall claude-security` |
| Entry point | `/claude-security` (user-invoked skill; accepts plain language/args) → three jobs: **Scan codebase** (whole repo or a scoped area) · **Scan changes** (`scan my branch`, `--base <ref>`, `--commit <sha>`, open PR via `gh`) · **Suggest patches** (`fix finding F3`, `all`, `high`, `F1,F3`) |
| Effort tiers | `--effort low` (one researcher + panel) · `medium` (default: inventory, threat model, researcher per component×category, one sweep, 2-of-3 panel) · `high` (wider inventory, two researchers per cell, two sweeps) · `max` (+ adversarial refuter phase). Panel fixed at three voters |
| Phases (watch in `/workflows`) | Inventory → Threat model → Research (`injection-and-input`, `auth-and-access`, `memory-and-unsafe`, `crypto-and-secrets`) → Sweep → Panel (lenses Reachability / Impact / Defenses; keep if ≥2 of 3 vote real) → [Adversarial at max] |
| Components it ships | Skill `claude-security`; agents `claude-security` (lead), `scan-inventory`, `scan-researcher`, `scan-verifier`, `patch-generator`, `patch-verifier`, `explore`; workflow `scan.js`; stdlib Python report/SARIF/CWE helpers; one display-only `UserPromptExpansion` hook; **no MCP server, no network calls** (except optional `gh` PR lookup) |
| Output directory | `CLAUDE-SECURITY-<timestamp>/` (own `.gitignore`): `CLAUDE-SECURITY-RESULTS.md` (findings + **Coverage** section) · `CLAUDE-SECURITY-RESULTS.jsonl` · `CLAUDE-SECURITY-RESULTS.sarif` (SARIF 2.1.0) · `CLAUDE-SECURITY-REVISION-<sha12>[-dirty].json` (commit, effort, severity counts, verified/unverified) · `patches/F<n>.patch` + notes |
| Patch flow | Draft in a scratch copy → independent reviewer runs tests (if any) and re-reads the bare diff → patch written only if it fixes that finding, adds no new vuln, changes nothing else; **never auto-applied**: `git apply CLAUDE-SECURITY-<ts>/patches/F1.patch`, one PR per patch; stale (`-dirty`/changed) reports are refused with an offer to rescan |
| Trust model | Adds no isolation: the repo's `.git/config`, `.claude/` settings/hooks and `CLAUDE.md` apply; built for code you trust — for untrusted repos run the session inside **sandbox-runtime** (`npx @anthropic-ai/sandbox-runtime claude`). Never commits/pushes/opens PRs itself. Repo text is treated as data; instructions aimed at the scanner become a `prompt-injection` finding |
| Configuration | Scope, effort, natural-language arguments. No documented repo-level rules/excludes file for the plugin as of 0.10.x (use security-guidance custom rules while coding; hosted product supports targeted scans/dismissals) |
| Troubleshooting | "Dynamic workflows unavailable" → plan/org toggle; Python too old; scan slow → `--effort low` or scan one directory; not in auto mode → many prompts; newest frontier model may be auto-downgraded to Opus by cyber safeguards (scan still completes) |

**Finding schema** (`CLAUDE-SECURITY-RESULTS.jsonl`, one object per line):

| Field | Type / values |
|---|---|
| `id` | `F1`, `F2`, … |
| `title`, `impact`, `description`, `exploit_scenario`, `recommendation` | strings |
| `file`, `line`, `symbol`, `snippet` | location (snippet omitted for hardcoded-credential findings) |
| `preconditions` | array of strings |
| `category` | research category |
| `severity` | `HIGH` \| `MEDIUM` \| `LOW` |
| `confidence` | `low` \| `medium` \| `high` (`high` only if the panel was unanimous) |
| `cwe_id` | `CWE-<n>` (e.g. `CWE-89`) |

Handy: `jq -c '{id,severity,cwe_id,file,line}' CLAUDE-SECURITY-*/CLAUDE-SECURITY-RESULTS.jsonl`. SARIF: open in an IDE SARIF viewer or upload to GitHub code scanning (`github/codeql-action/upload-sarif`, `sarif_file: CLAUDE-SECURITY-…/CLAUDE-SECURITY-RESULTS.sarif`). Verifier policy: verifiers are instructed to call a candidate a false positive unless they can confirm a real path to exploitation, so hardening gaps without an exploit path (e.g. "no rate limiting") generally do not appear as findings.

Sources: https://code.claude.com/docs/en/claude-security · https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-security · https://claude.com/plugins/claude-security · https://github.com/anthropic-experimental/sandbox-runtime

### M.3 security-guidance plugin (`security-guidance@claude-plugins-official`) — free, all plans

| Item | Detail |
|---|---|
| What | Makes Claude review its own changes for common vulnerabilities while it works and fix them in the same session. Nothing blocks; findings are fed back to Claude |
| Prereqs / install | Claude Code 2.1.144+; Python 3.7+ (3.10+ for the agentic layer / 3P providers); `/plugin install security-guidance@claude-plugins-official` + `/reload-plugins`; team-wide: `{"enabledPlugins": {"security-guidance@claude-plugins-official": true}}` in `.claude/settings.json`; org-wide via managed `enabledPlugins` |
| Layer 1 — per edit | Pattern match on `Edit`/`Write`/`NotebookEdit` (no model call): `eval(`, `new Function`, `os.system`, `child_process.exec`, `pickle`, `dangerouslySetInnerHTML`, `.innerHTML =`, `document.write`, edits under `.github/workflows/`; one warning per pattern per file per session |
| Layer 2 — end of turn | `Stop` hook sends the turn's git diff to a separate security-focused Claude review in the background; findings re-prompt Claude (≤30 files/turn, ≤3 consecutive re-prompts) |
| Layer 3 — on `git commit`/`git push` Claude runs | Agentic review reading callers/sanitizers (≤20/hour); uses `asyncRewake` to wake Claude with findings |
| Hooks registered | `SessionStart` (bootstrap venv in `~/.claude/security/`), `UserPromptSubmit` (baseline), `PostToolUse` Edit/Write (patterns), `Stop` (diff review), `PostToolUse` Bash `if: Bash(git commit *)` (commit review) — a worked example of "hooks that call a model" |
| Custom rules | `.claude/claude-security-guidance.md` (+ `~/.claude/…`, `.local.md`; 8 KB combined) for the model-backed reviews; `.claude/security-patterns.yaml\|yml\|json` for per-edit rules: `patterns: [{rule_name, reminder (≤1 KB), regex \| substrings, paths?, exclude_paths?}]` (≤50 rules) |
| Switches | `ENABLE_PATTERN_RULES=0`, `ENABLE_STOP_REVIEW=0`, `ENABLE_COMMIT_REVIEW=0`, `ENABLE_CODE_SECURITY_REVIEW=0`, `SECURITY_GUIDANCE_DISABLE=1`; models `SECURITY_REVIEW_MODEL`, `SG_AGENTIC_MODEL`; logs `~/.claude/security/log.txt`; disable with `/plugin disable security-guidance@claude-plugins-official` |

```yaml
# .claude/security-patterns.yaml
patterns:
  - rule_name: subprocess_shell
    regex: "shell\\s*=\\s*True"
    paths: ["**/*.py"]
    reminder: "shell=True with request data enables command injection. Use an argv list and shlex, never a shell."
  - rule_name: internal_api_key
    substrings: ["sk_live_", "AKIA"]
    reminder: "Hardcoded credential prefix. Load secrets from the secret manager."
```

Sources: https://code.claude.com/docs/en/security-guidance · https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance

### M.4 `/security-review` and the `claude-code-security-review` GitHub Action

* **`/security-review`** (built-in): single-pass review of the diff between your branch and `origin`'s default branch (needs an `origin` remote and `origin/HEAD` → `git remote set-head origin -a`). Customize by copying `security-review.md` from the Action repo into `.claude/commands/`. Contrast with the plugin: one pass, no verifier panel, no patches, minutes not tens of minutes.
* **Action** `anthropics/claude-code-security-review` (MIT): diff-aware PR scan with inline comments and false-positive filtering.

```yaml
name: Security Review
permissions: { pull-requests: write, contents: read }
on: { pull_request: {} }
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { ref: "${{ github.event.pull_request.head.sha || github.sha }}", fetch-depth: 2 }
      - uses: anthropics/claude-code-security-review@main
        with:
          claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
          comment-pr: true
          exclude-directories: tests
          custom-security-scan-instructions: .github/security-instructions.md
          claude-model: <current model id>        # README default is old — pin explicitly [verify-on-day]
```

| Input | Default | Meaning |
|---|---|---|
| `claude-api-key` | required | Console key secret |
| `comment-pr` | `true` | Post inline PR comments |
| `upload-results` | `true` | Upload results artifact |
| `exclude-directories` | — | Comma-separated |
| `claude-model` | (old default) | Set a current model |
| `claudecode-timeout` | 20 (min) | |
| `run-every-commit` | `false` | |
| `false-positive-filtering-instructions` / `custom-security-scan-instructions` | paths | Tune FP filter / add org checks |
| Outputs | `findings-count`, `results-file` | Findings JSON: `file, line, severity, category, description, exploit_scenario, recommendation, confidence` |

Caveats: **not hardened against prompt injection — trusted PRs only** (enable "Require approval for all external contributors"); fork PRs don't receive secrets; excludes DoS/rate-limiting/open-redirect classes by default. To surface plugin results in code scanning, upload the SARIF with `github/codeql-action/upload-sarif@v3`.

Sources: https://code.claude.com/docs/en/commands · https://github.com/anthropics/claude-code-security-review

### M.5 Hosted Claude Security (positioning) **[verify-on-day; partly snippet-sourced]**

Claude Security is a capability in Claude (claude.ai/security) that scans **GitHub-connected** repositories and proposes patches for human review; public beta for **Enterprise** plans (announced 2026-04-30; Team/Max "coming soon" at that time). Org Owner enables it under Organization settings; the Claude GitHub App must be installed; scanning users need the appropriate seat and usage credits enabled; scans billed at token cost. Features described publicly: scheduled and directory-targeted scans, dedup + severity/confidence/CWE per finding, dismiss with reason, export CSV/Markdown, per-project webhooks (Slack/Jira), "Open in Claude Code on the web" to remediate. Use the plugin (M.2) when code is not on GitHub, networks disallow inbound access, or you want scans in the developer loop; use the hosted product for continuous org-wide coverage.

Sources: https://claude.com/product/claude-security · https://claude.com/blog/claude-security-public-beta · https://support.claude.com/en/articles/14661296-use-claude-security · https://www.anthropic.com/news/claude-code-security

### M.6 Organization hardening checklist

1. Start restrictive (`default`/`plan`), escalate deliberately; auto mode with a tuned `autoMode` block for daily work; `bypassPermissions` only inside containers/VMs and disabled org-wide via managed `permissions.disableBypassPermissionsMode`.
2. Narrow `allow`, explicit `deny` (`curl`, `wget`, `.env*`, `secrets/**`), `ask` for human checkpoints (`git push`, `gh pr create`); remember **deny → ask → allow**.
3. Ship policy through managed settings: `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`, `allowManagedMcpServersOnly` + allow/deny lists, `strictKnownMarketplaces`, `strictPluginOnlyCustomization`, `disableSideloadFlags`, `forceLoginMethod`/`forceLoginOrgUUID`, `requiredMinimumVersion`. To switch cross-session messaging off org-wide, combine `"permissions": {"deny": ["SendMessage", "ListAgents"]}` (bare tool names; this also removes messaging to subagents/agent-team teammates) with `"crossSessionInbound": "refuse"` in managed settings — a refusing session shows no visible change in `/status`, so verify via the settings files; if you only want a human gate on messages leaving the machine, `"isolatePeerMachines": true`.
4. Turn on the Bash sandbox fleet-wide (`enabled`, `failIfUnavailable`, `allowUnsandboxedCommands:false`, domain allowlist, credential deny/mask); `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`.
5. Unattended agents live inside a boundary: devcontainer firewall, hardened container + egress proxy (K.4), VM, sandbox-runtime, or Managed Agents `limited` networking / self-hosted sandbox.
6. Hooks for hard guardrails (`PreToolUse` exit 2 / `deny`), `PostToolUse` + OpenTelemetry (`CLAUDE_CODE_ENABLE_TELEMETRY=1`, `claude_code.tool_decision` events) for audit, `ConfigChange` for drift.
7. Treat repo/web/MCP/tool content as untrusted; only trusted MCP servers and plugins; CMA MCP toolsets `always_ask`; memory stores `read_only` unless needed.
8. Secrets never in context: deny reads, env scrub, vaults/proxy injection, GitHub Secrets/OIDC, short-lived tokens (`apiKeyHelper`).
9. CI: `--bare`, `dontAsk` + explicit `--allowedTools`, minimal workflow permissions, trusted PRs only for AI review actions, review before merge.
10. Layer the tooling: security-guidance → `/security-review` → Claude Security plugin → Code Review / security-review Action → SAST & dependency scanners → hosted Claude Security scheduled scans.

Sources: https://code.claude.com/docs/en/security · https://code.claude.com/docs/en/permissions · https://code.claude.com/docs/en/monitoring-usage · https://github.com/anthropics/claude-code-action/blob/main/docs/security.md

---

## N. Glossary, resources and changelog highlights

### N.1 Glossary

| Term | Meaning |
|---|---|
| Agent loop | The cycle model → tool call → tool result → model … until the model stops; run by Claude Code, the Agent SDK subprocess, or the Managed Agents harness |
| Agent SDK | `@anthropic-ai/claude-agent-sdk` / `claude-agent-sdk`: Claude Code as a library (formerly "Claude Code SDK") |
| Agent view | `claude agents`: one screen listing background sessions (research preview) |
| Alias (model) | `opus`, `sonnet`, `haiku`, `fable`, `best`, `opusplan`, `default`, `[1m]` suffix — resolve per provider |
| Artifact | A private, shareable page on claude.ai published from a session (`Artifact` tool) |
| Auto memory | Notes Claude writes for itself per project (`~/.claude/projects/<p>/memory/MEMORY.md`) |
| Auto mode | Permission mode where a classifier model reviews each action instead of prompting; default start mode on Pro/Max/Team since 2026-08-14 |
| `--bare` | Minimal `-p` mode with no auto-discovered hooks/skills/plugins/MCP/CLAUDE.md |
| Bundled skill | Prompt-based capability shipped in the CLI (`/code-review`, `/simplify`, `/loop`, …) |
| Checkpoint / rewind | Per-prompt snapshot of files edited by Claude's tools; `Esc Esc` or `/rewind` |
| CLAUDE.md | Markdown instructions loaded into every session at user/project/managed scope |
| Claude Code on the web | Cloud sessions at claude.ai/code (`claude --cloud`); subscription feature |
| Claude Managed Agents (CMA in tables) | Anthropic-hosted agent harness and sandboxes driven over the API (`/v1/agents`, `/v1/sessions`); public beta |
| Claude Security | Anthropic's hosted repo-scanning product (Enterprise); the **Claude Security plugin** is its in-session version for Claude Code |
| Code Review | Managed multi-agent GitHub PR review (Team/Enterprise) |
| Compaction | Summarizing older conversation to free context (`/compact`, automatic near the window) |
| Connector | claude.ai-hosted MCP integration that appears automatically in `/mcp` |
| Console | platform.claude.com — API keys, workspaces, Managed Agents builder/tracing |
| Custom tool (CMA) | Tool declared on an agent but executed by *your* application (`agent.custom_tool_use` → `user.custom_tool_result`) |
| Deferred tools / tool search | MCP tool schemas load on demand via `ToolSearch` instead of upfront |
| Dynamic workflow | JavaScript script Claude writes to orchestrate many subagents (`ultracode`, `/workflows`) |
| Effort | Adaptive-reasoning depth: `low`…`max` (+ `ultracode`) |
| Environment (CMA) | Cloud or self-hosted sandbox configuration sessions run in; (web) a cloud VM profile with setup script + network policy |
| Event (CMA) | Typed message on a session stream (`user.*`, `agent.*`, `session.*`, `span.*`) |
| Fast mode | Same Opus model, ~2.5x faster, premium price, research preview |
| Fork | Copy of a conversation: `/branch` (switch into it), `/fork` (background session), `/subtask` (forked subagent), `--fork-session` |
| Hook | Deterministic handler (command/http/mcp_tool/prompt/agent) on a lifecycle event |
| Managed settings | Org policy delivered via admin console, MDM, registry or `managed-settings.json`; wins over everything |
| Marketplace | Catalog (`marketplace.json`) from which plugins install as `plugin@marketplace` |
| MCP | Model Context Protocol — servers exposing tools/resources/prompts to Claude |
| Memory store (CMA) | Versioned text memories mounted into sessions at `/mnt/memory/` |
| Outcome (CMA) | Rubric-graded goal with automatic revise loop |
| Permission policy (CMA) | `always_allow` / `always_ask` per tool |
| Plan mode | Read-only exploration that ends in an approvable plan |
| Plugin | Directory bundling skills, agents, hooks, MCP/LSP servers, workflows, etc., with `.claude-plugin/plugin.json` |
| Protected paths | Files/dirs never auto-editable except in bypass (`.git`, `.claude`, rc files, `.mcp.json`, …) |
| Remote Control | Drive a local session from claude.ai/mobile |
| Routine | Cloud agent run on a schedule, API call or GitHub event (`/schedule`) |
| Sandbox (Bash) | OS-enforced filesystem/network limits for Bash children (`/sandbox`) |
| Session | A conversation with transcript and state; resumable by ID/name; in CMA a running agent instance |
| Skill | `SKILL.md` directory: instructions Claude loads on demand or via `/name` |
| Subagent | Isolated worker with own context/prompt/tools invoked via the `Agent` tool |
| Usage credits | Prepaid credits for usage beyond plan limits and for premium features (fast mode, Fable on some plans, ultrareview, Code Review) |
| Vault (CMA) | Per-user credential container referenced by sessions; secrets injected at egress |
| Workspace trust | One-time dialog before project settings/hooks/MCP apply interactively; absent in `-p` |

### N.2 Public resources

| Area | Links |
|---|---|
| Claude Code docs (index / llms.txt) | https://code.claude.com/docs · https://code.claude.com/docs/llms.txt · What's new https://code.claude.com/docs/en/whats-new · Changelog https://code.claude.com/docs/en/changelog (mirrors https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) |
| Core pages | overview · quickstart · setup · authentication · cli-reference · commands · interactive-mode · settings · permissions · permission-modes · auto-mode-config · sandboxing · memory · hooks · hooks-guide · mcp · sub-agents · skills · plugins · plugins-reference · plugin-marketplaces · headless · github-actions · code-review · claude-code-on-the-web · workflows · agent-view · cross-session-messaging · security · claude-security · security-guidance · troubleshooting (all under `https://code.claude.com/docs/en/<page>`) |
| Agent SDK | https://code.claude.com/docs/en/agent-sdk/overview · /quickstart · /typescript · /python · /permissions · /hooks · /custom-tools · /mcp · /subagents · /skills · /plugins · /sessions · /structured-outputs · /hosting · /secure-deployment · /migration-guide · repos https://github.com/anthropics/claude-agent-sdk-typescript · https://github.com/anthropics/claude-agent-sdk-python · demos https://github.com/anthropics/claude-agent-sdk-demos |
| Managed Agents | https://platform.claude.com/docs/en/managed-agents/overview · /quickstart · /agent-setup · /environments · /sessions · /events-and-streaming · /tools · /permission-policies · /vaults · /memory · /webhooks · /scheduled-deployments · /self-hosted-sandboxes · /migration · /reference · cookbook https://github.com/anthropics/claude-cookbooks/tree/main/managed_agents · quickstarts https://github.com/anthropics/claude-quickstarts/tree/main/managed-agents · CLI https://github.com/anthropics/anthropic-cli |
| Models & pricing | https://platform.claude.com/docs/en/about-claude/models/overview · https://platform.claude.com/docs/en/about-claude/model-deprecations · https://claude.com/pricing · release notes https://platform.claude.com/docs/en/release-notes/overview |
| Plugins & security repos | https://github.com/anthropics/claude-plugins-official (incl. `plugins/claude-security`, `plugins/security-guidance`) · https://github.com/anthropics/claude-plugins-community · https://claude.com/plugins · https://github.com/anthropics/claude-code-action · https://github.com/anthropics/claude-code-security-review · https://github.com/anthropic-experimental/sandbox-runtime · examples https://github.com/anthropics/claude-code/tree/main/examples |
| Cookbooks | https://github.com/anthropics/claude-cookbooks/tree/main/claude_agent_sdk · https://platform.claude.com/cookbook |
| Engineering / blog | https://www.anthropic.com/engineering/claude-code-sandboxing · https://www.anthropic.com/engineering/claude-code-auto-mode · https://www.anthropic.com/engineering/managed-agents · https://claude.com/blog/building-agents-with-the-claude-agent-sdk · https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills · https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code · https://claude.com/blog/claude-managed-agents · https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more |
| Help center (plans/limits) | https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan · https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work · https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans |
| Standards | https://modelcontextprotocol.io · https://agentskills.io · settings schema https://json.schemastore.org/claude-code-settings.json |

### N.3 Changelog highlights, mid-2025 → August 2026 (condensed)

| When | Claude Code / platform | Why it matters for this workshop |
|---|---|---|
| 2025-05 | Claude Code 1.0 GA with Claude 4; SDK and GitHub Actions (beta) | Baseline most older material assumes |
| 2025-06/07 | Hooks; custom subagents (`/agents`) | M2/M3 foundations |
| 2025-09-29 | **Claude Code 2.0**: native VS Code extension, checkpoints `/rewind`, `/usage`; **Claude Code SDK renamed Claude Agent SDK** (`claude-agent-sdk` 0.1.0); Sonnet 4.5 | Package names, `/rewind` in M1 |
| 2025-10 | **Plugins & marketplaces** public beta; **Agent Skills** (`SKILL.md`); Claude Code on the web + iOS; sandboxed Bash tool; Haiku 4.5 | M3 core; D.6 |
| 2025-11 | Opus 4.5; docs move to platform.claude.com | |
| 2025-12 | `#` memory shortcut removed; Slack integration | Say "add this to CLAUDE.md" instead |
| 2026-01 (2.1.0) | Skills/commands convergence, hooks in skill/agent frontmatter, wildcard Bash rules, `/plan`, `context: fork` | H.1, E |
| 2026-02 | Opus 4.6 / Sonnet 4.6 (1M context); fast mode preview | |
| 2026-03 (2.1.83+) | **Auto mode** research preview; conditional hooks `if`; `managed-settings.d/`; PowerShell tool; computer use in CLI; `PermissionDenied` hook, `defer` | D.2, E |
| 2026-04-08 | **Claude Managed Agents public beta** (`managed-agents-2026-04-01`), `ant` CLI | M6 |
| 2026-04 (2.1.105+) | Opus 4.7 + `xhigh` effort + `/effort` slider; **Routines**; native binaries in npm; `/ultrareview`; custom themes; `/cost`+`/stats` → `/usage`; `mcp_tool` hooks; Claude Security hosted product public beta (Enterprise, 04-30) | B.3, I.3 |
| 2026-05 (2.1.139–157) | **Agent view** `claude agents` + `--bg`; `/goal`; auto mode on Pro; usage credits rename; `/code-review` bundled skill; **Opus 4.8**; **dynamic workflows** (`ultracode`); **security-guidance plugin**; `claude plugin init`; `MessageDisplay` hook | I.3, M.3 |
| 2026-06 (2.1.158–193) | Auto mode on Bedrock/Vertex/Foundry; `requiredMinimumVersion`; `/cd`; subagents can nest; `--safe-mode`; `fallbackModel`; **Fable 5** (2.1.170); Artifacts; `Tool(param:value)` rules; `/config key=value`; `claude mcp login/logout`; `sandbox.credentials`; **Sonnet 5** (2.1.197, default on Pro/Team Standard); subagents run in **background by default**; "default" mode relabelled **Manual** | B, D.2, G |
| 2026-07 (2.1.202–219) | `/doctor` full checkup; `/fork` = background session copy (old behaviour → `/subtask`); auto mode no longer needs an env var on 3P; **Opus 5** default `opus` (2.1.219); **Claude Security plugin** (`/claude-security`); `context: fork` skills background; 20-concurrent-subagent cap; `--max-budget-usd` includes subagents | B, M.2 |
| 2026-08 (2.1.220–235) | **Cross-session messaging**; **self-hosted environments** beta; **auto mode becomes the default on Pro/Max/Team (Aug 14)**; sandbox credential masking; `archive` plugin source; `/review` = alias of `/code-review`; Ultraplan removed; subagent forking default-on; `additionalMarketplaces`/`allowedMarketplaces` aliases; task tools off by default on newest models; auto-continue at limit reset; `spellcheck` | D.2, H.2 |
| Agent SDK | 0.1.0 rename (2025-09) → structured outputs, `tools`, plugins, skills options → 0.2.113 native binary + SessionStore → **0.3.142** V2 session API removed, background MCP connect, Task tools → 0.3.235 (parity with CLI 2.1.235) | K.10 |
| Managed Agents | 04-08 beta → 04-23 memory → 05-06 multiagent, outcomes, webhooks → 05-19 self-hosted sandboxes, MCP tunnels preview → 06-09 scheduled deployments, env-var credentials → 06-30 event deltas, `agent_with_overrides` → 07-22 `effort` on model, `initial_events` → 08-07 budgets, advisor, skills from GitHub repos | L |

Sources: https://code.claude.com/docs/en/whats-new · https://code.claude.com/docs/en/changelog · https://platform.claude.com/docs/en/release-notes/overview

---

## O. Volatile facts to re-verify before each delivery

Dated 2026-08-19. Re-check each row on the listed page the week of delivery; update `labs/env.example` (`MODEL`, `CMA_MODEL`), `labs/shared/cma_constants.py`, and this appendix together.

| # | Fact as stated in this reference | Where used | Re-verify at |
|---|---|---|---|
| 1 | Current line-up: Opus 5 (`claude-opus-5`), Sonnet 5 (`claude-sonnet-5`), Fable 5 (`claude-fable-5`), Haiku 4.5; aliases `opus`/`sonnet` resolution per provider | §B.1, `MODEL` / `CMA_MODEL` defaults | platform.claude.com/docs/en/about-claude/models/overview · code.claude.com/docs/en/model-config |
| 2 | `default` model per plan (Opus 5 on Max/Team Premium/Ent PAYG/API/3P; Sonnet 5 on Pro/Team Standard/Ent seats; Sonnet 4.5 on Foundry) | §B.1, M1 lab step 5 | code.claude.com/docs/en/model-config |
| 3 | Auto mode is the built-in start mode on Pro/Max/Team (since 2026-08-14); Manual on Enterprise/Console/3P/`-p` | §D.2, M1 step 1 | code.claude.com/docs/en/permission-modes |
| 4 | Fast mode: Opus 5 / 4.8 only, research preview, usage-credits billing on subscriptions | §B.4 | code.claude.com/docs/en/fast-mode |
| 5 | Sonnet 5 price ($2/$10 made permanent 2026-08-10) and all per-token prices | never in slides; §B pointer | claude.com/pricing |
| 6 | Managed Agents: public beta, header `managed-agents-2026-04-01`, toolset `agent_toolset_20260401`, memory header `agent-memory-2026-07-22`, enabled by default for API orgs | §L, M6, preflight step 7 | platform.claude.com/docs/en/managed-agents/overview · /api/beta-headers |
| 7 | CMA pricing $0.08 per session-hour while `running` + tokens; example $0.705 | §L.6, M6 step 5 | platform.claude.com/docs/en/about-claude/pricing#claude-managed-agents-pricing |
| 8 | CMA rate limits 300 create / 1,200 read rpm; multiagent + outcomes gating | §L.3 | platform.claude.com/docs/en/managed-agents/reference |
| 9 | Claude Security plugin: beta, needs v2.1.154+ and dynamic workflows, `python3` ≥3.9.6, outputs incl. `.sarif`, plugin version 0.10.x, medium scan duration on `astroshop-reviews` | §M.2, M7 step 0 | code.claude.com/docs/en/claude-security · plugin README |
| 10 | Hosted Claude Security: Enterprise-only, GitHub-only, features list (snippet-sourced) | §M.5, M7 talk | claude.com/product/claude-security · support article |
| 11 | `claude-code-security-review` Action default `claude-model` is outdated → pin explicitly; inputs list; `@main` ref | §M.4, M7 step 5 | github.com/anthropics/claude-code-security-review |
| 12 | `claude-code-action@v1` inputs and `actions/checkout@v6` in examples | §I.2, M4 Path B | github.com/anthropics/claude-code-action/blob/main/docs/usage.md |
| 13 | GitHub remote MCP URL `https://api.githubcopilot.com/mcp/` and OAuth via `/mcp` | §F.1, M2 stretch | code.claude.com/docs/en/mcp · GitHub MCP server docs |
| 14 | Official marketplace names `claude-plugins-official` (auto-registered) and `claude-community`; plugin names `security-guidance`, `claude-security`, `code-review`, `mcp-server-dev` | §H.2, M3, M7 | code.claude.com/docs/en/discover-plugins |
| 15 | Dynamic workflows research preview: v2.1.154+, Pro opt-in in `/config`, 16 concurrent / 1,000 per run, `workflowSizeGuideline` default `medium` | §I.3, M4, M7 | code.claude.com/docs/en/workflows |
| 16 | Agent view / `--bg` research preview; Claude Code on the web / Routines / Remote Control preview labels and plan availability | §I.3, §I.4, M4 tour | code.claude.com/docs/en/agent-view · /claude-code-on-the-web · /feature-availability |
| 17 | Subagents: background by default, nesting depth default 3, concurrency 20 | §G.3 | code.claude.com/docs/en/sub-agents |
| 18 | Hook handler types (`command`, `http`, `mcp_tool`, `prompt`, `agent`) and event list (31 events) | §E | code.claude.com/docs/en/hooks |
| 19 | Agent SDK versions (TS 0.3.235 / Py 0.2.140), Node 18+ / Python 3.10+ minimums, `settingSources` default = all | §K.2, preflight | npm / PyPI · code.claude.com/docs/en/agent-sdk/overview |
| 20 | Claude Code current version line (2.1.23x), native installer URLs, Node 22 for npm wrapper | §C.1, preflight | code.claude.com/docs/en/setup · /changelog |
| 21 | Removed commands still absent (`/vim`, `/output-style`, `/ultraplan`, `/pr-comments`) and `/autofix-pr` still present | §C.5 | code.claude.com/docs/en/commands |
| 22 | Usage-limit wording (5-hour + weekly windows, shared with claude.ai) and any numeric limits | §J.2, FACILITATOR | support.claude.com usage-limits article |
| 23 | Team plan seat price / Enterprise availability statements | never in slides | claude.com/pricing |
| 24 | URLs in §N.2 still resolve (docs pages get renamed) | §N.2 | code.claude.com/docs/llms.txt |
| 25 | Cross-session messaging: v2.1.224+ (initiating to another machine 2.1.225+; `@session` mention and `/config` row 2.1.232+; `notify_when_idle` 2.1.236+); macOS/Linux/WSL 2 only, not native Windows; not on Bedrock / Vertex / Foundry / Claude Platform on AWS; stays off when `DISABLE_TELEMETRY`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `DO_NOT_TRACK` or `DISABLE_GROWTHBOOK` disable feature-flag evaluation; `crossSessionInbound` permission-class defaults; `dialogExpiry` default 5 min; ~1M-character same-machine cap | §G.4, §I.3, §D.5, §C.7, M4 §4.5 + demo beat 3 | code.claude.com/docs/en/cross-session-messaging · /settings · /env-vars |

*Verified against current Claude Code, Claude Agent SDK, and Claude Platform documentation as of 19 August 2026. See §O before each delivery.*
