# Module 1 — Claude Code Essentials

> **Time box:** 09:15–09:55 (40 min) · **Format:** talk/demo 15 · lab 20 · debrief 5 · **Checkpoint in:** CP0 · **Checkpoint out:** CP1

> [!NOTE] Instructor
> This module replaces three v3 modules' worth of "essentials". Teach the *workflow* (drive → remember → plan → undo → measure); park the encyclopaedia in `reference/Technical-Reference-v4.md` §B–§D and §I. Everything version- or plan-specific is in the two "Volatile facts" callouts — re-verify those the day before delivery (Ref §O).

## Why this matters

Every later module assumes you can drive an interactive session without thinking about it: mention a file, interrupt a turn, switch model and effort deliberately, know which permission mode you are in, and undo an agent's work in two keystrokes. It also assumes the project has a memory — a `CLAUDE.md` and a path-scoped rule — because the subagents (M3), the SDK (M5, via `setting_sources=["project"]`) and the security discussion (M7, "advisory vs enforced") all build on it. Finally, since mid-August 2026 sessions on Pro/Max/Team plans **start in auto mode**: if the room does not understand permission modes in the first hour, half the laptops will silently edit files while the other half prompt for everything, and every lab instruction will be wrong for someone.

## Learning objectives

By the end of this module participants can:

1. Run an interactive session fluently: prompt, `@file` mentions, `!` shell commands, `Esc` to interrupt, queue a correction mid-turn, and pick a session back up with `--continue` / `--resume`.
2. Choose model and effort deliberately (`/model` and aliases including `opusplan`, `/effort`, the `ultrathink` keyword), know that fast mode and the advisor exist, and read `/context`, `/usage`, `/cost`.
3. Author project memory: generate `CLAUDE.md` with `/init`, add a path-scoped rule in `.claude/rules/`, and explain `CLAUDE.local.md`, `~/.claude/CLAUDE.md`, auto memory, and `/memory`.
4. Use plan mode end-to-end — enter, edit the plan with `Ctrl+G`, approve into a chosen mode — and undo with checkpoints (`Esc Esc` / `/rewind`), knowing what rewind does *not* restore.
5. Name the six permission modes, say which one *their* session starts in (auto on Pro/Max/Team; manual on Enterprise, Console API key, and cloud providers — as of August 2026), set one explicitly, and state what the Bash sandbox adds.
6. Know the other surfaces exist and when to reach for them: VS Code / JetBrains, the Desktop app, Claude Code on the web (`claude.ai/code`, `--cloud`, `--teleport`), mobile and Remote Control.

## Concepts (instructor talk track)

### 1.1 Install and authenticate — two supported paths

Claude Code is a **native binary**; Node.js is not required to run it (we need Node today only for the lab MCP server and the TypeScript SDK track).

| Method | Command | Auto-updates |
|---|---|---|
| Native installer (recommended) — macOS, Linux, WSL | `curl -fsSL https://claude.ai/install.sh \| bash` | yes, in the background |
| Native installer — Windows PowerShell | `irm https://claude.ai/install.ps1 \| iex` | yes |
| Homebrew | `brew install --cask claude-code` | no — `brew upgrade claude-code` |
| WinGet | `winget install Anthropic.ClaudeCode` | no — `winget upgrade Anthropic.ClaudeCode` |
| npm (still supported; wraps the same native binary) | `npm install -g @anthropic-ai/claude-code` | needs Node 22+ for the package itself |

Verify and maintain: `claude --version`, `claude doctor` (read-only diagnostics from the shell), `claude update`, in-session `/doctor` (a bundled skill that can also fix duplicate installs, PATH, unparseable settings). Signed apt/dnf/apk repositories and release channels (`latest` vs `stable`, `autoUpdatesChannel`, `minimumVersion`) exist for managed fleets — Ref §C.1 (install/update table) and §D.5 (settings keys); install troubleshooting is Ref §J.

**Who can log in.** A claude.ai **Pro, Max, Team, or Enterprise** seat, **or** a **Claude Console** account (admin assigns the *Claude Code* or *Developer* role; a "Claude Code" workspace is auto-created for spend tracking), **or** a cloud provider (Amazon Bedrock, Google Vertex AI, Microsoft Foundry, Claude Platform on AWS — set `CLAUDE_CODE_USE_BEDROCK=1` etc. before launch; no browser login). The free claude.ai plan does not include Claude Code.

**Commands you will actually type.**

```bash
claude                      # first run opens the browser login; press `c` to copy the URL if it doesn't open
claude auth status --text   # exit 0 if logged in; shows which method
claude auth login --console # force the Console (API-billing) login flow
claude auth logout
# inside a session: /login  /logout  /status
```

**The precedence gotcha (say it twice today).** If `ANTHROPIC_API_KEY` is exported, it outranks your subscription login: interactive `claude` asks once whether to use it; `claude -p` always uses it. Symptom of a stale key: `400 … "This organization has been disabled"` while your subscription is fine → `unset ANTHROPIC_API_KEY`. Full precedence chain (cloud provider → `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` → `apiKeyHelper` → `CLAUDE_CODE_OAUTH_TOKEN` → subscription OAuth) is in Ref §C.1; `claude setup-token` (a one-year OAuth token for CI) comes back in M4.

Credentials live in the macOS Keychain, or `~/.claude/.credentials.json` (mode 0600) on Linux/Windows. `CLAUDE_CONFIG_DIR=~/.claude-work claude` is the documented way to keep two accounts side by side.

### 1.2 Driving a session

```bash
claude                         # interactive session in the current directory
claude "summarize this repo"   # interactive, with a first prompt
claude -c                      # --continue: most recent session in this directory
claude -r                      # --resume: picker (search, preview with Space, Ctrl+R rename); or: claude -r <name|id>
claude -n currency-validation  # --name the session up front; /rename later
claude -p "question"           # non-interactive (headless) — Module 4
```

Inside the prompt box, four prefixes and six keys carry 90 % of the day:

| Type | Effect |
|---|---|
| `@path/to/file` | Mention a file or directory: its content (or listing) enters context, plus any `CLAUDE.md` on the way down to it. Tab-completes. |
| `! ls src` | Shell mode: runs the command yourself, output enters context, and Claude responds to it. `Esc` on an empty `!` prompt leaves shell mode. |
| `/` | Commands and skills menu (built-ins, bundled skills, your skills, plugin skills, MCP prompts). |
| `?` on an empty prompt | Shortcut cheat-sheet overlay. |
| `Esc` | Interrupt the current turn. Work done so far is kept; anything you queued is sent next. |
| type + `Enter` *while Claude is working* | **Queues** a correction; Claude reads it as soon as the current tool call finishes, inside the same turn. `Up` takes it back. |
| `Esc Esc` (empty prompt) | Open the **rewind** menu (§1.7). With text in the box: clears the draft (saved to history). |
| `Shift+Tab` | Cycle permission modes (§1.6). `Alt+M` on Windows terminals without VT input. |
| `Ctrl+O` | Transcript / verbose view: full tool inputs and outputs, thinking (grey italics), which model answered. |
| `Ctrl+G` | Open the current prompt — or, in plan mode, the proposed **plan** — in your `$EDITOR`. |
| `Ctrl+B` | Send a running Bash command or subagent to the background; `/tasks` lists them. |
| `Ctrl+C` / `Ctrl+D` | Interrupt or clear input / exit (press twice). |

Multiline input: `\`+`Enter` or `Ctrl+J` everywhere; `Shift+Enter` natively in iTerm2, WezTerm, Ghostty, Kitty, Warp, Apple Terminal, Windows Terminal (run `/terminal-setup` once in VS Code's terminal, Alacritty, Zed). Paste an image with `Ctrl+V` (`Cmd+V` in iTerm2, `Alt+V` on Windows). `/btw <question>` asks a side question answered from existing context only — it never enters history and works mid-turn.

Sessions are stored as JSONL under `~/.claude/projects/<project>/` and kept 30 days by default (`cleanupPeriodDays`). A resume restores history, model, and permission mode (except `plan`/`bypassPermissions`); it does not restore `--add-dir`, `--settings`, or `--plugin-dir` flags. `claude --continue --fork-session` (or `/branch`) copies a conversation instead of continuing it.

### 1.3 Models, effort, thinking, fast mode

Use **aliases** everywhere in Claude Code files and prompts; let the alias track the current model.

| Alias | Resolves to |
|---|---|
| `default` | Not a model: clears any override and returns to the recommended model for your account type (or your organization's configured default). |
| `opus` | Latest Opus available on your provider |
| `sonnet` | Latest Sonnet available on your provider |
| `haiku` | The fast, inexpensive tier — good for simple subagents |
| `opusplan` | `opus` while in plan mode, `sonnet` for execution — a strong cost/quality default for feature work |
| `opus[1m]`, `sonnet[1m]` | Force the 1M-token context variant where the plain alias would not already be 1M |
| `best` / `fable` | The most capable tier where your organization has access; may bill usage credits on subscription plans; never the default. See Ref §B before using it in a room. |

> [!IMPORTANT] Volatile facts — re-verify before each delivery (Ref §B, §O). **As of August 2026**, per the public model-configuration docs: on the Anthropic API and Claude Console, `opus` → **Claude Opus 5** and `sonnet` → **Claude Sonnet 5**; `haiku` → Claude Haiku 4.5. What **`default`** resolves to depends on how you log in: Max, Team Premium, Enterprise pay-as-you-go, and Console API → Opus; Pro, Team Standard, and Enterprise subscription seats → Sonnet; Amazon Bedrock, Google Vertex AI and Claude Platform on AWS → Opus (alias resolution for `sonnet` lags on some providers); Microsoft Foundry → an older Sonnet. Newest-generation models run with a **1M-token context window natively** on the Anthropic API. Check live with `/model` and `/status`; never hard-code a model ID in workshop files — SDK code reads the alias `MODEL` and Managed Agents code reads the full ID `CMA_MODEL` from `labs/.env`.

**Choosing the model** (highest priority first): `/model <alias>` or the `/model` picker → `claude --model <alias>` (this launch only) → `ANTHROPIC_MODEL` → `"model"` in settings. Two picker details that bite: pressing **Enter** in `/model` switches *and saves the choice as your user default*; press **`s`** instead for "this session only". `/model default` undoes a saved override. `Option/Alt+P` opens the picker without clearing your half-typed prompt. Organizations can restrict the list (`availableModels`) and set an org default — if your picker looks short, that is why.

**Effort** is the dial you will touch most. Current models reason adaptively; effort tells them how hard to try.

| Level | Use it for | Persists? |
|---|---|---|
| `low` | short, scoped, latency-sensitive questions ("which file defines X?") | yes |
| `medium` | cost-sensitive routine work; recommended for `/init` on a big repo | yes |
| `high` | the default almost everywhere; balanced | yes |
| `xhigh` | deeper reasoning, noticeably more tokens; hard debugging, architecture | yes |
| `max` | demanding tasks; "prone to overthinking" — test before adopting | session only |
| `ultracode` | not a model level: `xhigh` **plus** automatic multi-agent workflow orchestration for every substantive task (M4 tour) | session only |

Set with `/effort` (slider), `/effort low`, `/effort auto` (back to the model default), `claude --effort high`, left/right arrows inside `/model`, `effortLevel` in settings, or `effort:` frontmatter on a skill/subagent (M3). The scale is calibrated per model — `high` on one model is not the same compute as `high` on another. The session header shows the active level ("with medium effort").

**Thinking.** Include the word `ultrathink` anywhere in a prompt for one-off deeper reasoning on that turn ("think hard" and friends are plain text now). `Option/Alt+T` toggles extended thinking for the session; `/config` → thinking sets the default (`alwaysThinkingEnabled`). Thinking is collapsed in the transcript; `Ctrl+O` reveals it. All thinking tokens are billed.

**Fast mode** (research preview, Aug 2026): `/fast` runs Opus up to ~2.5× faster at a premium per-token price; on subscription plans it bills **usage credits** rather than your included allowance, and it is not available on Bedrock/Vertex/Foundry. Great for live debugging; wrong for long unattended runs. **Advisor** (experimental): `/advisor opus` lets a cheaper main model consult a stronger one at decision points. Both: mention, don't demo — Ref §B.

### 1.4 Memory: `CLAUDE.md`, rules, auto memory

`CLAUDE.md` is how a project tells every future session "how we do things here". It is loaded as context at the start of every conversation — **advice, not enforcement** (M2 shows the enforced counterparts: deny rules and hooks).

| Scope | Location | Shared with | Loaded |
|---|---|---|---|
| Managed (org) | OS-specific system path, or `claudeMd` in managed settings | everyone in the org | always; cannot be excluded |
| User | `~/.claude/CLAUDE.md` (+ `~/.claude/rules/*.md`) | you, in every project | at launch |
| Project | `./CLAUDE.md` **or** `./.claude/CLAUDE.md` (+ `.claude/rules/**/*.md`) | the team, via git | at launch (walks *up* from cwd, root-most first) |
| Local | `./CLAUDE.local.md` (gitignore it) | you, this project | at launch, appended after that level's `CLAUDE.md` |
| Nested | `src/payments/CLAUDE.md` etc. | the team | **on demand**, when Claude reads a file in that subtree |
| Auto memory | `~/.claude/projects/<project>/memory/MEMORY.md` + topic files | you (machine-local, shared across worktrees of the repo) | index (first 200 lines / 25 KB) every session; topic files on demand |

Mechanics worth knowing:

- **Imports:** `@docs/git-workflow.md` inside a `CLAUDE.md` pulls that file in (relative to the containing file; up to four hops deep). A repo that standardises on `AGENTS.md` bridges with a one-line `CLAUDE.md` containing `@AGENTS.md`.
- **Path-scoped rules** live in `.claude/rules/*.md` with a `paths:` frontmatter list of globs and load *only* when Claude reads a matching file — perfect for "generated code" or "this legacy package" rules that should not tax every session:

  ```markdown
  ---
  paths:
    - "**/*.proto"
    - "pb/**"
  ---
  # Protobuf rules
  - Never hand-edit generated protobuf code; change the .proto and regenerate.
  ```

- **Auto memory** is Claude's own notebook per repo (build commands it discovered, your stated preferences). On by default; the UI says "Saved N memories" / "Recalled N memories". Say "remember that we use pnpm" → auto memory; say "add to CLAUDE.md: …" → the shared file. Toggle or open the folder from `/memory`; disable per project with `{"autoMemoryEnabled": false}`.
- **`/memory`** lists every memory file that applies here, opens them in your editor, toggles auto memory. **`/context`** shows which ones actually loaded this session.
- **`/init`** analyses the codebase and writes a starter `CLAUDE.md` (build/test commands, conventions); if one exists it proposes improvements. It also reads existing Cursor/Copilot rule files. (`CLAUDE_CODE_NEW_INIT=1` enables a longer interactive flow that can also propose skills and hooks — not today.)
- **Write it like a runbook, not an essay:** under ~200 lines per file, specific and verifiable ("run `make test-go` before committing Go changes"), prune regularly; `/doctor` will suggest trims. Block-level HTML comments are stripped before injection, so you can leave notes for humans.
- **What survives compaction:** project-root `CLAUDE.md`, unscoped rules and auto memory are re-injected from disk; path-scoped rules and nested `CLAUDE.md` come back the next time a matching file is read.

### 1.5 Plan mode

Plan mode lets Claude research and propose an approach **without editing source**. Enter it three ways: `Shift+Tab` until the status bar shows `⏸ plan mode on`; `claude --permission-mode plan`; or `/plan <task>` to enter plan mode *and* start the task in one line. Claude reads files, runs exploratory commands (reviewed by the auto-mode classifier where available, otherwise prompted), and presents a plan.

```
 /plan <task>  ──▶  Claude explores (reads, greps, safe commands)  ──▶  proposed plan
                                                                          │
                                   Ctrl+G: edit the plan in $EDITOR ◀─────┤
                                                                          ▼
                    ┌───────────────────── approve? ─────────────────────────┐
                    │ Yes, and use auto mode      → exits plan → auto        │
                    │ Yes, manually approve edits → exits plan → default     │  ← labs use this
                    │ No, keep planning           → stays in plan            │
                    └────────────────────────────────────────────────────────┘
                                          │
                     implement  ──▶  review `git diff` / `/diff`  ──▶  Esc Esc to rewind, or commit
```

- `Ctrl+G` opens the proposed plan in your editor — delete steps, add constraints, save, and Claude proceeds from *your* version.
- The approval dialog offers **Yes, and use auto mode** (or "Yes, auto-accept edits" where auto mode is unavailable), **Yes, manually approve edits**, and **No, keep planning**. Approving exits plan mode into the mode you picked. Accepting a plan also auto-names the session.
- `Shift+Tab` leaves plan mode without approving anything.
- `/model opusplan` pairs naturally: the stronger model plans, the faster one types.
- Docs' rule of thumb: skip planning when you could describe the diff in one sentence.

### 1.6 Permission modes, auto mode, and the sandbox

Six modes decide what runs without asking. Deny rules (M2) apply in *every* mode.

| Mode (config value) | Runs without asking | Best for | Status bar |
|---|---|---|---|
| `default` — shown as **Manual** (`manual` accepted as alias) | reads only | sensitive work; a uniform classroom | `⏸ manual mode on` |
| `acceptEdits` | reads, file edits, common filesystem commands inside the working dir | iterating while you watch `git diff` | `⏵⏵ accept edits on` |
| `plan` | reads (+ classifier-approved exploration) — no source edits | explore before changing | `⏸ plan mode on` |
| `auto` | everything, with a background **classifier** reviewing each action | long tasks, less prompt fatigue | `⏵⏵ auto mode on` |
| `dontAsk` | only pre-approved tools (`permissions.allow`, read-only Bash); everything else is auto-*denied* | locked-down CI and scripts (M4) | `⏵⏵ don't ask on` |
| `bypassPermissions` | everything, including protected paths | isolated containers/VMs **only** | `⏵⏵ bypass permissions on` |

**Which mode does a session start in?** First match wins: (1) `--permission-mode <mode>` on the command line; (2) `permissions.defaultMode` in a settings file (a project file cannot force `auto` on you); (3) the built-in default:

| How you run Claude Code (Aug 2026) | Built-in start mode |
|---|---|
| Pro, Max, or Team plan — terminal or VS Code | **`auto`** |
| Enterprise plan, or Console API key | `default` (Manual) |
| Amazon Bedrock, Google Vertex AI, Microsoft Foundry, Claude Platform on AWS | `default` |
| `claude -p` and the Agent SDK | `default` |
| any settings scope sets `permissions.disableAutoMode: "disable"` (Team/Enterprise admins) | `default` |

> [!IMPORTANT] Volatile fact. Auto mode became the default start mode for new sessions on Pro, Max, and Team plans in mid-August 2026 (a one-time prompt offers to switch if you had set your own default; org-managed defaults are untouched; classifier calls no longer count toward usage limits on those plans). This is why **Lab step 1 pins `--permission-mode default`** — so every laptop in the room behaves the same regardless of plan.

`Shift+Tab` cycles `default → acceptEdits → plan → default`, with `auto` slotted after `plan` where available (`bypassPermissions` appears in the cycle only if you launched with `--permission-mode bypassPermissions` / `--dangerously-skip-permissions`; `dontAsk` is flag-only). Asking Claude in chat to change mode does nothing — modes are yours.

**Auto mode in three sentences.** A separate classifier model reviews actions before they run and blocks anything that escalates beyond your request, targets unrecognised infrastructure, or looks driven by hostile content Claude read (tool *results* are stripped from what the classifier sees; a server-side probe scans them for injection). Entering auto mode *drops* broad allow rules like `Bash(*)` and wildcarded interpreters while keeping narrow ones like `Bash(npm test)`; things like `curl | bash`, force-pushes, `git reset --hard`, production deploys, and printing live credentials are blocked by default, while local edits, declared dependency installs and read-only HTTP are allowed. After 3 consecutive (or 20 total) blocks it pauses and goes back to prompting; blocked actions show under `/permissions` → *Recently denied* (`r` to retry). Auto mode is a per-action control, **not an isolation boundary**; durable boundaries belong in `permissions.ask` / `deny` (M2) because conversational "don't push yet" instructions can be lost to compaction. Org tuning (`autoMode.environment / allow / soft_deny / hard_deny`) is Ref §D.

**Protected paths** — `.git/`, `.claude/` (except worktrees), `.mcp.json`, `.vscode/`, shell rc files, and similar — are never auto-approved for writes in any mode except bypass. That is why the lab creates `.claude/rules/proto.md` from *your* shell rather than asking Claude to write it.

**The Bash sandbox** (`/sandbox`; lab in M2 Part A) is the OS-level backstop: on macOS (Seatbelt) and Linux/WSL2 (bubblewrap) every Bash command and its children run with filesystem writes confined to the project and a temp dir, and network egress limited to an allowlist you build as you go. It does **not** wrap Claude's own file tools, MCP servers, or hooks, and it is unavailable on native Windows and WSL1. Sandbox + auto mode compose: the classifier decides *whether* to run a command, the sandbox bounds *what it can touch* if it runs. `bypassPermissions` belongs inside a container or VM, never on your laptop's home directory.

### 1.7 Checkpoints and `/rewind`

Every prompt you send creates a checkpoint; before Claude's file-editing tools change a file, its prior content is snapshotted (100 most recent checkpoints per session, kept with the session so rewind works after `--resume`).

`Esc Esc` on an empty prompt (or `/rewind`, aliases `/checkpoint`, `/undo`) opens a list of your prompts. Pick one, then choose: **Restore code and conversation**, **Restore conversation** (keep files), **Restore code** (keep conversation), **Summarize from here** / **Summarize up to here** (partial compaction), or **Never mind**.

Limits to say out loud: Bash side-effects (`rm`, `mv`, package installs, database writes) are **not** tracked; edits made by subagents are generally not restored; files you edited by hand are not tracked; it is not a replacement for git. To branch a conversation rather than rewind it: `/branch`, or `claude --continue --fork-session`.

### 1.8 Context management and the 1M window

What is in the window before you type anything: the system prompt, the auto-memory index, environment info (cwd, git status), MCP tool *names* (schemas load on demand via tool search), skill *descriptions*, `~/.claude/CLAUDE.md`, and the project `CLAUDE.md` chain. As you work, file reads dominate; subagents (M3) run in their own window and hand back only a summary.

- **`/context`** draws the coloured grid with a per-category breakdown, lists loaded memory files, and suggests optimisations. Look at it before and after big operations — it is the single best intuition-builder for cost.
- **Auto-compaction**: as you approach the limit Claude Code first clears old tool outputs, then summarises the conversation. Newest-generation models run a **1M-token** window natively on the Anthropic API, so in practice you compact far less than in 2025; whether 1M is included or draws on usage credits depends on plan and model (Ref §B). Tune the threshold with `/autocompact 500k` (or `claude --autocompact`), pin older models to 200K with `CLAUDE_CODE_DISABLE_1M_CONTEXT=1`.
- **Manual tools**: `/compact focus on the currency validation work` (guided summary; a "Compact Instructions" section in `CLAUDE.md` is honoured); `/clear` between unrelated tasks (`/rename` first if you may want to `/resume` it); `/rewind` → *Summarize up to here* for surgical compaction; `/btw` for questions that should not grow the transcript; delegate big reads to a subagent.
- **What survives a compaction**: system prompt, project-root `CLAUDE.md`, unscoped rules, auto memory (re-read from disk), invoked skill bodies (capped). Lost until re-triggered: path-scoped rules, nested `CLAUDE.md`, and any "don't do X until I say so" you only said in chat.

### 1.9 Usage and cost at a glance

`/usage` is the one screen: session cost at list prices, plan usage bars (5-hour and weekly windows on subscription plans), and — on paid plans — an **attribution** breakdown by skill, subagent, plugin and MCP server. `/cost` and `/stats` are aliases (Stats tab). Totals reset on `/clear`. Cheap habits that matter: `/clear` between tasks, `sonnet` for routine work and `haiku` for simple subagents, lower `/effort` for lookups, keep `CLAUDE.md` lean, and prefer subagents for anything that reads dozens of files.

### 1.10 The twenty commands you need today

| Command | Use | Command | Use |
|---|---|---|---|
| `/init` | generate/improve `CLAUDE.md` | `/permissions` | view/edit allow·ask·deny; recent auto-mode denials |
| `/memory` | open memory files, toggle auto memory | `/sandbox` | enable/configure the Bash sandbox |
| `/model [alias]` | switch model (Enter saves default, `s` session) | `/hooks` | list configured hooks (M2) |
| `/effort [level\|auto]` | reasoning effort | `/mcp` | MCP servers, OAuth, per-server context cost (M2) |
| `/plan [task]` | enter plan mode (+ start task) | `/skills`, `/plugin` | list skills; plugin manager (M3) |
| `/rewind` (`Esc Esc`) | restore code/conversation, summarize | `/tasks` | background shells, subagents, workflows |
| `/context` | what fills the window | `/resume`, `/rename`, `/branch` | session management |
| `/compact [focus]`, `/clear` | shrink or reset context | `/status`, `/config`, `/doctor` | account+model, settings UI, health check |
| `/usage` (`/cost`) | spend, limits, attribution | `/btw <q>` | side question, no history |
| `/diff` | interactive viewer of uncommitted + per-turn diffs | `/help`, `?` | command list; shortcut overlay |

Custom slash commands are skills now (`.claude/skills/<name>/SKILL.md`; legacy `.claude/commands/*.md` still works) — M3.

### 1.11 Same engine, other surfaces (overview only)

| Surface | Get it | Where code runs | Reach for it when |
|---|---|---|---|
| Terminal CLI | `claude` | your machine | everything today; full feature set, all providers |
| VS Code / Cursor extension (`anthropic.claude-code`) | Extensions view → "Claude Code"; running `claude` in the integrated terminal auto-installs it; `/ide` connects an external terminal | your machine | inline side-by-side diffs, `@`-mention with selection, plan as an editable document, multiple tabs; shares history with the CLI (`claude --resume` continues an extension chat) |
| JetBrains plugin ("Claude Code [Beta]") | JetBrains Marketplace + the CLI on PATH | your machine | IDE diff viewer and selection sharing in IntelliJ/PyCharm/GoLand/... |
| Desktop app (Code tab) | Claude Desktop for macOS / Windows (Linux beta); `/desktop` hands a terminal session over | local, SSH/WSL, or cloud per session | visual diffs, parallel sessions in worktrees, scheduled local tasks; requires a claude.ai paid plan |
| Claude Code on the web | `claude.ai/code`; `claude --cloud "task"` from a pushed branch; `claude --teleport` pulls a web session into your terminal | Anthropic-managed VM per session (or a self-hosted environment) | parallel well-defined tasks on their own branches, repos you don't have locally, work that should keep running when you close the lid; subscription plans (Enterprise: seat-dependent) |
| Mobile app / Remote Control | Claude iOS/Android; `claude remote-control` or `/rc` exposes a *local* session to your phone/browser | cloud VM (web sessions) or your machine (Remote Control) | approve a prompt from the coffee line; monitor long runs |
| GitHub Actions / GitLab CI, headless `-p`, Agent SDK | M4, M5 | CI runner / your process | automation — this afternoon |

Local surfaces (CLI, IDE, Desktop) share your `CLAUDE.md`, settings, hooks, skills and MCP config. Cloud surfaces see only what is committed to the repo plus organization-managed settings — one more reason to commit `.claude/` deliberately (M2, M3).

## Live demo script

Fifteen minutes, one terminal in `$OTEL`, font size up, `/config` → verbose off. Have `labs/m1/prompts.md` open in a second pane to paste from. If the room is mostly on Pro seats, run the demo on `sonnet` to model good behaviour.

| Min | Do | Narrate / expected |
|---|---|---|
| 0:00 | `cd $OTEL && claude --permission-mode default` | Point at the status bar: `⏸ manual mode on`. "Yours may say auto — we'll come back to why." |
| 0:30 | `/context` | "Before we've said anything: system prompt, memory, tool names. Remember this picture." |
| 1:00 | Paste: `Give me a one-paragraph tour of this repo and list the services under src/ with their language. Use the Explore agent.` | Point at the `Agent(Explore …)` line as it appears — "a built-in read-only subagent doing the reading in its own window." Press `Ctrl+O` once to show the tool calls streaming inside it, `Ctrl+O` again to collapse. Expected: a table of ~a dozen services (Go, C#, Java, Kotlin, Node, Python, Rust, PHP, C++, TypeScript…). |
| 2:30 | `/context` again | "Main context grew by the *summary*, not by every file Explore read. This is the whole idea behind M3." |
| 3:00 | `/model` | Show the picker: aliases, the Default row and what it resolves to *for this account*, prices column (Anthropic API only). Arrow to `sonnet`, press **`s`** — "session only. Enter would have saved it as my default for every future session." `Esc`. |
| 4:00 | `/effort low` then paste: `Which service converts currencies and where is the conversion table loaded from? One sentence.` | Fast, terse answer. |
| 4:45 | `/effort high` then the same question with ` ultrathink` appended | Slower; watch the thinking indicator; richer answer citing file and line. "Same model, different budget. `ultrathink` is per-turn; `/effort` sticks. `opusplan`, fast mode (`/fast`, usage-credit billed, Opus only) and `/advisor` exist — Ref §B — we won't use them in labs." `/effort auto`. |
| 6:00 | `/init` | While it explores (30–90 s at medium effort on this repo): "It's reading build files, READMEs, existing agent configs." Approve the write when prompted. Open the result: build/test commands per language, repo layout, conventions. "Under 200 lines, specific, verifiable. This file is *advice* — M2 shows walls." |
| 8:00 | In a split shell (or `!` prefix): `mkdir -p .claude/rules && cp $WS/labs/m1/rules/proto.md .claude/rules/ && cat .claude/rules/proto.md` | Show the `paths:` frontmatter. "Loads only when Claude touches a `.proto` or anything under `pb/`. Why from my shell? `.claude/` is a protected path — Claude would have to ask, and I'd rather own this file." |
| 9:00 | `/memory` | Walk the list: project `CLAUDE.md`, (absent) `CLAUDE.local.md`, user `~/.claude/CLAUDE.md`, rules, **auto memory: on** and its folder. "‘Remember that…' goes to auto memory; ‘add to CLAUDE.md' goes to the shared file." `Esc`. |
| 10:00 | `Shift+Tab` slowly through the cycle back to manual | Name each status-bar label. One sentence on the start-mode matrix: "Pro/Max/Team start in auto; Enterprise, API keys and cloud providers start in manual; `--permission-mode` beats all of it." |
| 10:45 | Paste: `/plan add a /healthz endpoint to src/paymentservice (Node) that returns 200 and the service version; follow existing conventions` | Status bar flips to plan. Claude reads `src/paymentservice`, proposes a plan (files to touch, test, maybe a proto/README note). |
| 12:00 | `Ctrl+G` | Plan opens in `$EDITOR`. Delete the test step and any docs step ("keeping the demo short — you'd keep them"). Save, quit. Claude acknowledges the edited plan. |
| 12:45 | Choose **Yes, manually approve edits** | Approve the first one or two edits in the diff prompt (`y`), so files really change. Then `Esc` to stop the turn early. `! git diff --stat` shows the touched files. |
| 13:45 | `Esc Esc` → select the `/plan add a /healthz…` prompt → **Restore code and conversation** | `! git status` — clean apart from `CLAUDE.md` and `.claude/`. "Two keystrokes. But: it would *not* have undone an `npm install` or an `rm` run through Bash — checkpoints track Claude's file edits, not shell side-effects. Git is still your friend." |
| 14:30 | Surfaces slide (§1.11 table) | "Same engine in VS Code, JetBrains, Desktop, web, phone. `/ide`, `/desktop`, `claude --cloud`, `claude --teleport` are the doors between them. Not today's labs — but your `.claude/` folder travels with the repo to all of them." `/exit`. |

Fallback if `/init` drags past 90 s: `Esc`, `/effort medium`, re-run; or `cp $WS/labs/checkpoints/CP1/files/OTEL/CLAUDE.md ./CLAUDE.md` and narrate the file instead.

## Hands-on lab

**Lab 1: Drive, remember, plan, undo** (20 min + 5 min debrief). Start state: **CP0**, `$OTEL` is a clean checkout of the `workshop` branch (`git status` clean), `labs/.env` sourced. All prompts are also in `$WS/labs/m1/prompts.md` for pasting. Work in `$OTEL` unless a step says otherwise.

1. **(3 min) Start uniformly and drive.**

   ```bash
   cd $OTEL
   git status --short            # expect no output
   claude --permission-mode default -n m1-essentials
   ```

   Confirm the status bar reads `⏸ manual mode on`. Ask:

   ```text
   Which services call CartService over gRPC? Cite the files and lines where the client is created.
   ```

   While it answers, try the input affordances: type `@src/checkoutservice/main.go` (Tab-complete works) and ask `what port does this listen on?`; then run a shell command in place with

   ```text
   ! ls src
   ```

   and notice Claude comments on the listing. Press `Esc` once mid-answer on any turn to feel the interrupt; re-ask if you cut it off.

   ✅ Success: you got file citations for the CartService callers (typically checkout and frontend), an answer about the `@`-mentioned file, and Claude reacted to your `! ls src` output.

2. **(5 min) Give the project a memory.**

   ```text
   /init
   ```

   Approve the `CLAUDE.md` write when asked (you are in manual mode, so you *will* be asked). If it is still exploring after ~90 seconds: `Esc`, `/effort medium`, `/init` again. Then extend it:

   ```text
   Add to CLAUDE.md, under a "Conventions" heading: (1) every new HTTP/gRPC endpoint must emit an OpenTelemetry span named <service>.<operation>; (2) Go code uses table-driven tests; (3) never commit directly to the workshop branch — use feature branches.
   ```

   Approve the edit. Now add the path-scoped rule **from your shell** (open a second terminal in `$OTEL`, or use the `!` prefix) — `.claude/` is a protected path, so we own this file rather than asking Claude to write it:

   ```bash
   mkdir -p .claude/rules
   cp $WS/labs/m1/rules/proto.md .claude/rules/proto.md
   cat .claude/rules/proto.md
   ```

   The file you just copied:

   ```markdown
   ---
   paths:
     - "**/*.proto"
     - "pb/**"
   ---
   # Protobuf and generated code

   - `pb/demo.proto` is the single source of truth for service contracts. Propose changes there; never hand-edit generated code (`*_pb2.py`, `*_pb2_grpc.py`, `*.pb.go`, `*_grpc.pb.go`, generated Java/Kotlin/C#/TypeScript stubs under any `genproto/` or `protos/` directory).
   - After changing a message or service, list every consumer service that must regenerate stubs and the command each one uses (see that service's README or Dockerfile).
   - Field numbers are forever: never renumber or reuse a field; mark removed fields `reserved`.
   - Keep backwards compatibility: additive changes only unless the task explicitly says "breaking".
   ```

   ✅ Success check (run in the second terminal, from `$OTEL`):

   ```bash
   claude -p "What rules apply when editing pb/demo.proto?"
   ```

   The answer mentions the protobuf rule (single source of truth / never hand-edit generated code). Path-scoped rules load when a matching file is *read*, so if the answer is generic, force the read: `claude -p "Read pb/demo.proto, then tell me which project rules apply when editing it."` Also peek: `/memory` in your interactive session now lists `CLAUDE.md` and `.claude/rules/proto.md`.

3. **(7 min) Plan → edit the plan → approve → watch edits.** Back in the interactive session:

   ```text
   /plan Add input validation for currency codes in src/currencyservice: reject codes that are not 3 uppercase letters or not in the supported list, with a clear error, following the service's existing error-handling style.
   ```

   Watch the status bar switch to `⏸ plan mode on` and Claude explore before proposing a plan. When the plan appears, press **`Ctrl+G`**: the plan opens in your editor. **Delete any test-writing step and any documentation step** (we are keeping the lab short — in real life you would keep them), optionally add a line "Do not touch generated protobuf code.", save and close. Claude confirms it will follow the edited plan.

   In the approval dialog choose **Yes, manually approve edits**. Approve each proposed edit after reading the diff (`y`); reject anything that touches generated code (it should not — your rule is loaded once it reads the proto). Two or three approved edits are enough; press `Esc` to end the turn early if it keeps going.

   ```text
   ! git diff --stat
   ```

   ✅ Success: `git diff --stat` lists one or more files under `src/currencyservice/`; nothing under `pb/` or any `genproto` directory changed; the status bar is back to `⏸ manual mode on` (approving a plan exits plan mode into the mode you chose).

4. **(2 min) Undo it all with a checkpoint.** On an empty prompt press **`Esc` `Esc`**. In the rewind list select the prompt that starts with `/plan Add input validation…` and choose **Restore code and conversation**.

   ```text
   ! git status --short
   ```

   ✅ Success: the only entries are `CLAUDE.md` and `.claude/` (untracked/new) — the currency-service edits are gone *and* the conversation no longer contains the plan. (Had Claude run a Bash command with side-effects during step 3, those would **not** have been reverted — checkpoints cover Claude's file-tool edits only.)

5. **(3 min) Read the meters; switch model and effort deliberately.**

   ```text
   /context
   /usage
   /cost
   ```

   Note three numbers for the shared sheet (link in the chat channel): context % used, session cost so far, and which model did the work. Then:

   ```text
   /model sonnet
   /model default
   /effort medium
   ```

   Watch the header change each time. On current builds `/model <alias>` switches *and* saves the choice as your user default (inside the picker, `s` is the session-only path); `/model default` clears that override again either way, so you leave the lab exactly as you arrived. `/effort medium` persists into later sessions — that is intentional for today's labs (faster `/init`-style exploration, lower spend); `/effort auto` returns to the model default whenever you want.

   ✅ Success: you can say (a) what filled most of your context, (b) what the session cost, (c) which concrete model `default` means on your plan. Add your row to the sheet. Leave the session running for the debrief or `/exit`.

**Debrief (5 min, instructor-led).** Three questions to the room: *Whose `default` was Opus and whose was Sonnet — and whose session would have started in auto mode without the flag?* · *What did `/context` look like after `/init` versus after the Explore question — where did the tokens go?* · *Name one thing rewind would not have saved you from.* Close with: "You now have artifact #1 — `CLAUDE.md` + `proto.md`. M3's agents inherit it, M5 loads it with one option, M7 asks whether advice was enough."

## If you're behind (fast-forward)

```bash
cd $WS && ./labs/checkpoint.sh CP1
```

CP1 writes `$OTEL/CLAUDE.md` (the reference project memory, including the three conventions from step 2) and `$OTEL/.claude/rules/proto.md`. It does not touch anything else and will not overwrite an existing `CLAUDE.md` unless you add `--force` (it prints a diff hint instead). After running it you are exactly where Module 2 expects you to be; steps 3–5 of this lab produce no lasting artifact, so you can skip them without consequence and try plan mode + rewind during any later lull.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Claude edited files in step 1 or 2 without ever asking | Your session started in **auto** (Pro/Max/Team default since mid-Aug 2026) or `acceptEdits` because the `--permission-mode default` flag was omitted | `Shift+Tab` until `⏸ manual mode on`, or restart with the flag. Nothing is lost; `Esc Esc` rewinds unwanted edits. |
| Status bar shows `⏵⏵ auto mode on` but a neighbour on the same plan sees manual | Neighbour has `permissions.defaultMode` in `~/.claude/settings.json`, is on a Console key, or declined the one-time switch prompt | Expected. The flag in step 1 makes the room uniform; M2 sets a project `defaultMode`. |
| `/init` runs for minutes | Large polyglot repo × high/xhigh effort (Opus defaults) | `Esc`, `/effort medium`, `/init` again. Still slow: `./labs/checkpoint.sh CP1` and move on. |
| `claude -p "What rules apply…"` answers generically, no proto rule | Path-scoped rules load only when a matching file is read; the model answered from `CLAUDE.md` alone | Use the forcing variant in step 2; confirm the file is at `$OTEL/.claude/rules/proto.md` and the frontmatter starts on line 1 with `---` (no BOM, spaces not tabs). `/memory` should list it. |
| `claude -p` in the second terminal fails with an auth error while the interactive session works | That shell exported a stale/empty `ANTHROPIC_API_KEY` (from `labs/.env`) — `-p` always prefers the key | `unset ANTHROPIC_API_KEY` in that shell (subscription users), or put a valid key in `labs/.env`. |
| `Ctrl+G` does nothing / opens the wrong editor | `$EDITOR`/`$VISUAL` unset or pointing at a GUI editor that returns immediately | `export EDITOR=nano` (or `code --wait`, `vim`) before launching `claude`; relaunch with `claude -c`. |
| Approval dialog offers "Yes, and use auto mode" but the lab says "manually approve" | Both are listed; auto is just the first option where available | Arrow down to **Yes, manually approve edits**. |
| After rewind, `git status` still shows a modified file under `src/` | The change was made by a Bash command (formatter, `sed`, package manager), by a subagent, or by you — none are checkpointed | `git checkout -- <file>` (or `git restore <file>`). Teach the limitation; it is the point of the step. |
| Rewind menu doesn't open on `Esc Esc` | Prompt box not empty (first `Esc Esc` clears the draft) or a dialog is open | Clear the input, press `Esc Esc` again, or type `/rewind`. |
| "You've hit your session limit" / Opus limit on a Pro seat mid-lab | Whole room on Opus at high effort | `/model sonnet` (press `s` for session-only if you use the picker), `/effort medium`. Instructor may announce `sonnet` as the room default (FACILITATOR §8, §11). |
| `/model` picker is missing models a neighbour has | Organization `availableModels` allowlist or plan differences | Expected; use what you have. Aliases in all lab files keep working. |
| `@src/checkoutservice/main.go` doesn't autocomplete / "no such file" | Your fork's pinned tag lays out `src/` differently | `! ls src` and adapt the path; tell a TA so the prompts file can be annotated for your tag. |
| Windows: `! ls src` errors | PowerShell tool in use (no Git Bash) | Use `! dir src` or `! Get-ChildItem src`; everything else in this lab is identical. |
| `Shift+Tab` does nothing in Windows Terminal / ConHost | Terminal lacks VT input mode | Use `Alt+M` to cycle modes. |

## Stretch goals

- **Sessions:** `/rename m1-essentials-<yourname>`, `/exit`, then `claude --resume` and explore the picker (`Space` previews, `Ctrl+R` renames, typing searches). Try `claude -c --fork-session` and confirm the original is untouched in `/resume`.
- **`opusplan`:** `/model opusplan`, repeat step 3's `/plan …` and watch the model indicator switch between planning and execution; `/model default` afterwards.
- **Personal memory:** create `~/.claude/CLAUDE.md` with two or three preferences you actually hold ("prefer small, reviewable commits", "explain shell commands before running them"), start a fresh session and ask Claude what it knows about your preferences; then check `/context` to see it listed under memory files.
- **`/btw`:** mid-way through any long answer, `/btw which files has this session read so far?` — note it answers instantly from context and leaves no trace in the transcript.
- **VS Code:** open `$OTEL` in VS Code with the Claude Code extension installed, run the currency-validation `/plan` there, and compare: the plan opens as a Markdown document you can comment on inline, and edits arrive as side-by-side diffs. `claude --resume` in the terminal can continue that same conversation.
- **Auto memory, observed:** tell Claude "remember that in this repo we say 'Astronomy Shop', never 'webstore'", then `/memory` → open the auto-memory folder and read what it wrote in `MEMORY.md`.
- **Read ahead:** `/permissions` — look at the (empty) allow/ask/deny lists you will fill in M2, and the *Recently denied* tab that auto mode populates.

## Key takeaways

- Drive with four prefixes (`@`, `!`, `/`, `?`) and four keys (`Esc`, `Esc Esc`, `Shift+Tab`, `Ctrl+O`); queue corrections instead of waiting.
- Use **aliases** and **effort**, not model IDs: `/model` (Enter saves, `s` doesn't), `/effort`, `ultrathink` for one turn, `opusplan` for plan-heavy work. What `default` means depends on your plan — check, don't assume.
- `CLAUDE.md` + `.claude/rules/` + auto memory are the project's memory. Keep `CLAUDE.md` short and verifiable; scope expensive rules with `paths:`; remember it is *advice* — enforcement is M2's job.
- Plan mode (`/plan`, `Ctrl+G`, approve into a mode) and checkpoints (`Esc Esc`) make ambitious requests cheap to try — but rewind covers Claude's file edits only, not shell side-effects.
- Six permission modes; **your start mode depends on how you log in** (auto on Pro/Max/Team, manual on Enterprise/Console/cloud providers, as of Aug 2026). Pin it explicitly when behaviour must be uniform; add the sandbox when commands must be bounded.
- One engine, many surfaces; your committed `.claude/` folder is what travels with the repo to all of them.

## References

- Quickstart and interactive mode (shortcuts, prefixes, queueing, `/btw`): https://code.claude.com/docs/en/quickstart · https://code.claude.com/docs/en/interactive-mode
- Setup, install methods, updates: https://code.claude.com/docs/en/setup
- Authentication (account types, credential precedence, `claude auth`): https://code.claude.com/docs/en/authentication
- Model configuration (aliases, `default` per account type, effort, `ultrathink`, 1M context, `opusplan`): https://code.claude.com/docs/en/model-config
- Fast mode: https://code.claude.com/docs/en/fast-mode · Advisor: https://code.claude.com/docs/en/advisor
- Memory (`CLAUDE.md`, `.claude/rules/`, imports, auto memory, `/init`, `/memory`): https://code.claude.com/docs/en/memory
- Permission modes and auto mode (start-mode matrix, classifier behaviour): https://code.claude.com/docs/en/permission-modes · https://code.claude.com/docs/en/auto-mode-config
- Sandboxing: https://code.claude.com/docs/en/sandboxing · https://code.claude.com/docs/en/sandbox-environments
- Checkpointing and `/rewind`: https://code.claude.com/docs/en/checkpointing
- Context window and compaction: https://code.claude.com/docs/en/context-window · https://code.claude.com/docs/en/how-claude-code-works
- Sessions (`--continue`, `--resume`, `/branch`, naming): https://code.claude.com/docs/en/sessions
- Costs and `/usage`: https://code.claude.com/docs/en/costs
- Commands reference: https://code.claude.com/docs/en/commands · CLI reference: https://code.claude.com/docs/en/cli-reference
- Best practices (explore → plan → implement → commit): https://code.claude.com/docs/en/best-practices
- Surfaces: https://code.claude.com/docs/en/platforms · https://code.claude.com/docs/en/vs-code · https://code.claude.com/docs/en/jetbrains · https://code.claude.com/docs/en/desktop · https://code.claude.com/docs/en/claude-code-on-the-web · https://code.claude.com/docs/en/remote-control · https://code.claude.com/docs/en/mobile
- What's new digests (for the auto-mode default change and other dated items): https://code.claude.com/docs/en/whats-new
- Models overview: https://platform.claude.com/docs/en/about-claude/models/overview
