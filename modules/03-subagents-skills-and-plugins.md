# Module 3 — Extending Claude Code II: subagents, skills, plugins & marketplaces

> **Time box:** 10:50–11:45 (55 min) · **Format:** talk/demo 15 · lab 37 · debrief 3 · **Checkpoint in:** CP2 · **Checkpoint out:** CP3

Conventions: `$WS` = your clone of this workshop repo · `$OTEL` = your clone of `<WORKSHOP_ORG>/opentelemetry-demo` · `<WORKSHOP_ORG>` = the workshop GitHub org set in `labs/.env` (`$WORKSHOP_ORG` when a shell expands it). Everything typed at the Claude Code prompt is shown without a leading `$`; everything typed in your terminal is a `bash` block; Windows users run these from Git Bash or WSL2 (see `labs/SETUP.md` — the lab scripts are bash-only; only the M2 hook has a `.ps1` example).

---

## Why this matters

Module 2 taught Claude Code *rules*: what it may touch (permissions), what happens deterministically around each tool call (hooks), and which outside systems it can reach (MCP). This module teaches it *roles and routines* — and then makes all of it portable.

- A **subagent** is a specialist with its own context window. You hand it a job ("document this service", "hunt bugs in that one"), it burns through as many files as it needs, and only its summary comes back. Your main conversation stays small; several specialists can run at once.
- A **skill** is a routine you would otherwise paste into chat every week: a checklist, a review procedure, a release recipe. It costs almost nothing until it is invoked, takes arguments, can pre-approve exactly the tools it needs, and can pull supporting files in only when they are relevant.
- A **plugin** is the shipping container: agents + skills + hooks + MCP config (and more) in one versioned directory, published through a **marketplace** so a teammate — or a CI job, or the Agent SDK this afternoon — gets the whole toolkit with one install command.

By 11:45 the `service-documenter` and `bug-hunter` agents, the `code-reviewer` skill, your M2 `protect-files` hook and the `astro-catalog` MCP server will all live in one plugin, `codebase-toolkit` v4.0.0, installed from a marketplace. Module 4 runs it headlessly, Module 5 loads it into the Agent SDK with one option, Module 6 lifts the bug-hunter prompt into a Managed Agent, and Module 7 asks the uncomfortable question "should you have trusted that plugin?".

## Learning objectives

By the end of this module you can:

1. Explain what a subagent is — its own context window, its own system prompt (the file body), scoped tools and permissions, returns only a summary — name the built-ins (**Explore**, **Plan**, **general-purpose**), describe background-by-default execution in interactive sessions, and say when parallel subagents pay for themselves and when they do not.
2. Author subagent files in `.claude/agents/` with frontmatter (`name`, `description`, `tools`, `model`, `effort`; awareness of `disallowedTools`, `permissionMode`, `maxTurns`, `isolation`, `memory`, `skills`, `mcpServers`, `hooks`, `background`, `color`) and invoke them three ways: automatic delegation, by name in prose, and by `@agent-<name>` mention.
3. Author a skill (`.claude/skills/<name>/SKILL.md`) with `description`, `argument-hint`, `allowed-tools`, positional `$0`/`$1` (and know `$ARGUMENTS`, named `arguments:`), `` !`command` `` dynamic context, and a supporting file loaded on demand; explain model-invoked vs user-invoked skills (`disable-model-invocation`, `user-invocable`) and why custom slash commands are now simply skills.
4. Package agents + skill + hooks + MCP config as a plugin (`.claude-plugin/plugin.json`, `agents/`, `skills/`, `hooks/hooks.json`, `.mcp.json`), validate it with `claude plugin validate`, smoke-test it with `--plugin-dir`, publish it through a `marketplace.json`, install it with `/plugin install name@marketplace`, and describe team rollout (`extraKnownMarketplaces` + `enabledPlugins`) and enterprise controls (`strictKnownMarketplaces`).
5. Describe how the same components travel onward: to the Agent SDK (`plugins` / `agents` / `setting_sources` options, Module 5) and to Claude Managed Agents (the agent body becomes the `system` prompt; skills attach to the agent, Module 6).

**Prerequisite state:** CP2 — `$OTEL/.claude/settings.json` with the two hooks, `$OTEL/.claude/hooks/protect-files.sh`, and `$OTEL/.mcp.json` pointing at `astro-catalog` all exist. If not: `cd $OTEL && $WS/labs/checkpoint.sh CP2`.

---

## Concepts (instructor talk track)

> [!NOTE]
> **Instructor:** keep this to the 15-minute demo budget by talking *over* the demo (next section). The material below is the script; the reference tables live in `reference/Technical-Reference-v4.md` §G (subagents), §H (skills), §H.2 (plugins & marketplaces). Do not read tables aloud.

### 1. Subagents: specialists with their own context window

When Claude delegates, it calls the **Agent** tool. The subagent starts fresh: its system prompt is the markdown body of its definition file (not the full Claude Code system prompt), it sees the delegation message, the project's `CLAUDE.md` hierarchy and a git-status snapshot — and nothing of your conversation history. It works with only the tools you listed, its tool calls are still checked against your permission rules, and when it finishes, only its final text returns to the parent. That is the whole trick: forty file reads happen *over there*; one paragraph lands *here*.

**Built-ins you already have.** `Explore` (read-only codebase search; Write/Edit denied), `Plan` (read-only research used by plan mode) and `general-purpose` (every tool a subagent may have; the default when Claude does not name a type). You used Explore in Module 1 without noticing. You can deny any of them like a tool: `"deny": ["Agent(Explore)"]`, or deny `Agent` outright to switch delegation off.

**Where definitions live and who wins.** Project agents in `.claude/agents/*.md` (checked in, shared), personal agents in `~/.claude/agents/`, plugin agents in `<plugin>/agents/` (namespaced `plugin-name:agent-name`), plus session-only JSON via `claude --agents '{…}'` and organization-managed agents. On a name clash: managed > `--agents` flag > project > user > plugin. Claude Code watches the agents directories and hot-reloads edits within seconds; a restart is only needed if the directory did not exist when the session started.

**Frontmatter you will type today** — everything else is in Ref §G:

| Field | What it does | Today |
|---|---|---|
| `name` | Identity (lowercase, hyphens). Filename does not have to match. | `bug-hunter` |
| `description` | *When* Claude should delegate. This is the routing signal — write it like an ad: "Use proactively when…". | see files below |
| `tools` | Allowlist. Omit = inherit everything a subagent may have. Accepts `mcp__server__tool` names too. | `Read, Grep, Glob` |
| `model` | `sonnet` \| `opus` \| `haiku` \| a full model ID \| `inherit` (default). We use **aliases** so the file survives model releases. | `sonnet` |
| `effort` | `low`…`max`; **overrides the session's `/effort`** for this agent. | `medium` / `high` |

Worth knowing exist: `disallowedTools` (denylist, applied before `tools`), `permissionMode`, `maxTurns`, `skills` (preload full skill content), `mcpServers` (inline servers that start with the agent), `hooks` (scoped to the agent's lifetime), `memory: user|project|local` (a persistent `MEMORY.md` per agent), `background: true`, `isolation: worktree` (runs in a throw-away git worktree), `color`. Three of these — `hooks`, `mcpServers`, `permissionMode` — are **ignored when the agent ships inside a plugin**, which matters in Part C.

**Three ways to invoke.**
1. *Automatic:* Claude matches the task against every agent's `description`. Vague description → never picked.
2. *By name in prose:* "Use the bug-hunter agent on src/adservice."
3. *Guaranteed:* type `@` and pick `bug-hunter (agent)` from the typeahead, or write `@agent-bug-hunter …` (plugin agents: `@agent-codebase-toolkit:bug-hunter`). A whole session can also *be* an agent: `claude --agent bug-hunter` replaces the default system prompt with the agent's body (Module 4 uses this headlessly).

**Background by default.** In an interactive session, subagents run in the **background**: your prompt stays live, `/tasks` lists them (running and recently finished), a permission prompt raised by a background subagent surfaces in your main session labelled with the agent's name, and each result arrives as a message when it is done. In `claude -p` and the Agent SDK, Claude chooses foreground or background per call; `background: true` in frontmatter pins background. Background subagents get a trimmed tool set (file tools, Bash, web, MCP tools — no nested orchestration tools), and subagents can themselves delegate only to a small, configurable depth (Ref §G). Do not confuse this with **background sessions** and the `claude agents` *agent view* — whole Claude Code sessions running detached — which Module 4 tours.

**When parallel subagents pay off — say this honestly.** Each subagent starts cold: it re-discovers context, has its own prompt cache, and bills its own tokens. Three subagents summarizing three language families of a polyglot repo is a win (independent work, large reads, small outputs). Three subagents editing the same file is a loss. Iterating on one function? Stay in the main conversation. `/usage` breaks spend down per subagent so you can check yourself.

### 2. Skills: routines that load only when used

A skill is a directory with a `SKILL.md` (YAML frontmatter + markdown instructions) and optional supporting files. Claude Code skills follow the open **Agent Skills** standard, with Claude Code extensions on top (invocation control, `context: fork`, `` !`command` `` injection).

**Progressive disclosure, three tiers.** (1) At session start only each skill's *name + description* enters context — a listing capped at roughly 1% of the context window. (2) When you type `/code-reviewer …` or Claude decides the description matches, the rendered `SKILL.md` body is injected once as a message. (3) Files the body *links to* (`checklists/security.md`, `reference.md`, `scripts/validate.sh`) are read or executed only if Claude needs them. Compare `CLAUDE.md`, which is paid for on every request. Rule of thumb from the docs: when a section of `CLAUDE.md` has turned into a *procedure*, it wants to be a skill; keep `SKILL.md` under ~500 lines and push detail into supporting files.

**Custom slash commands are skills now.** `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy` and accept the same frontmatter; existing `commands/` files keep working, skills add the directory for supporting files and invocation control. If both exist with one name, the skill wins.

**Where skills live.** `~/.claude/skills/<name>/` (personal), `.claude/skills/<name>/` (project; also discovered in parent directories up to the repo root, and lazily in nested packages of a monorepo), `<plugin>/skills/<name>/` (namespaced `/plugin:name`), and an organization-managed skills directory. Precedence on a bare-name clash: managed > personal > project; plugin skills cannot collide because of the namespace. The **directory name is the command name**; in project/personal skills `name:` is only a display label.

**Frontmatter you will type today** (full table Ref §H):

| Field | Meaning |
|---|---|
| `description` (+ optional `when_to_use`) | What/when. Front-load the use case; this is what Claude matches on. ~1,500-character cap in the listing. |
| `argument-hint` | Autocomplete hint in the `/` menu, e.g. `<path> [focus]`. |
| `arguments` | Named positional args: `arguments: [path, focus]` → `$path`, `$focus` (missing → empty string). |
| `allowed-tools` | Tools **pre-approved for the turn that runs the skill** (least privilege *and* no prompts). Does not *restrict*; use `disallowed-tools` for that. |
| `disable-model-invocation: true` | Only *you* can run it (`/deploy`, `/commit` — anything with side effects). Description leaves Claude's context entirely. |
| `user-invocable: false` | Only *Claude* can load it (background knowledge, hidden from the `/` menu). |
| `context: fork` + `agent:` | Run the skill as a forked subagent (default `general-purpose`; `Explore` for read-only research). |
| `model`, `effort`, `paths`, `hooks`, `shell` | Override model/effort while active; auto-load only for matching file globs; register hooks; `powershell` for `!` blocks on Windows. |

**Substitutions in the body:** `$ARGUMENTS` (everything typed), `$0` `$1`… (0-based positional, shell-style quoting), `$name` (named), `${CLAUDE_SKILL_DIR}` (this skill's directory — use it to reference bundled files and scripts regardless of cwd), `${CLAUDE_PROJECT_DIR}`, and in plugin skills `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`.

**Dynamic context:** a line containing `` !`git log -3 --oneline` `` is *executed before Claude sees the skill* and replaced by its output. Injected commands never prompt: if no permission rule allows the command, the whole invocation aborts with `Shell command permission check failed…` — which is exactly why `allowed-tools` lists `Bash(git log *)` in our skill. A non-zero exit also aborts (append `|| true` to commands that may legitimately fail). Organizations can switch injection off with `disableSkillShellExecution`.

**Security note you will hear again in Module 7:** a skill checked into a repository can grant itself tool access through `allowed-tools`. Review the `allowed-tools` of skills in repos you clone, exactly as you would review a hook.

**Bundled skills and the skill-creator.** Claude Code ships prompt-based bundled skills (`/code-review`, `/simplify`, `/verify`, `/run`, `/debug`, `/batch`, `/loop`, `/claude-api`, …; table in Ref §H). To *evaluate* a skill you wrote — test prompts, blind A/B against a baseline, description tuning — install Anthropic's `skill-creator` plugin from the official marketplace: `/plugin install skill-creator@claude-plugins-official`, then ask "evaluate my code-reviewer skill with skill-creator". (Stretch goal today.)

### 3. Which extension point? — the decision table

| You want… | Use | Loads / costs | Enforced or advisory? | Example from today |
|---|---|---|---|---|
| A fact or convention Claude should always know | `CLAUDE.md` / `.claude/rules/*.md` | Every request (rules: only for matching paths) | Advisory (the model reads it) | "New endpoints emit an OTel span" (M1) |
| Something that must happen, or must never happen, on every matching event | **Hook** | Zero context; runs outside the model | **Enforced** by Claude Code | `protect-files.sh` blocks generated-code edits (M2) |
| Hard limits on what tools/paths/hosts are usable | **Permission rules / sandbox** | Zero context | **Enforced** | `deny Read(./.env)` (M2) |
| Access to an external system or data source | **MCP server** | Tool names at start; schemas on demand | Enforced by the server's own auth | `astro-catalog` (M2) |
| A repeatable procedure, checklist or reference doc, optionally with arguments | **Skill** | Description at start; body only when invoked; supporting files only when read | Advisory, but `allowed-tools`/`disallowed-tools` shape the turn | `/code-reviewer <path> [focus]` |
| A big side task whose intermediate reads should not pollute your context; parallel independent work; a specialist persona with restricted tools | **Subagent** | Isolated context; own token bill; summary returns | Its `tools` list is enforced; its prompt is advisory | `service-documenter`, `bug-hunter` |
| To share any of the above across repos, teammates, CI and the SDK, versioned | **Plugin** via a **marketplace** | Whatever its components cost | Trust decision at install time | `codebase-toolkit@workshop-marketplace` |

Two heuristics: *guarantees go in hooks and permissions, guidance goes in CLAUDE.md and skills*; *if the output you need is a paragraph but the work is forty files, delegate to a subagent*.

### 4. Plugins and marketplaces: the shipping container

A **plugin** is a directory. Only one thing goes inside `.claude-plugin/`: the manifest `plugin.json` (and even that is optional — components are auto-discovered and the directory name becomes the plugin name). Everything else sits at the plugin root in conventional folders: `agents/`, `skills/`, `commands/` (legacy flat skills), `hooks/hooks.json`, `.mcp.json`, `.lsp.json` (language servers), `workflows/`, `output-styles/`, `bin/` (executables added to the Bash tool's `PATH`), `settings.json` (only `agent` and `subagentStatusLine` keys honored). A `CLAUDE.md` at the plugin root is **not** loaded — ship instructions as a skill.

Inside a plugin, paths are written with `${CLAUDE_PLUGIN_ROOT}` (the install directory, which changes on every update) and persistent state goes in `${CLAUDE_PLUGIN_DATA}`; `${CLAUDE_PROJECT_DIR}` still means the user's project. Plugin skills are always namespaced (`/codebase-toolkit:code-reviewer`; the bare `/code-reviewer` also works if nothing else claims it), agents appear as `codebase-toolkit:bug-hunter`, and tools of a plugin-bundled MCP server are named `mcp__plugin_<plugin>_<server>__<tool>` — remember that when you write permission rules or hook matchers for them.

**Manifest.** Only `name` is required (kebab-case). `version` is semver and it *changes update behavior*: with a version set, users receive an update only when you bump it; without one, every new commit of the marketplace counts as a new version. `description`, `author`, `homepage`, `repository`, `license`, `keywords` are catalog metadata; `userConfig` prompts the user for options at enable time; `dependencies` pulls in other plugins by semver range.

**Lifecycle commands.** Interactive: `/plugin` opens the manager (tabs **Discover · Installed · Marketplaces · Errors**), `/plugin marketplace add <owner/repo | git URL | ./path | URL-to-marketplace.json>`, `/plugin install <plugin>@<marketplace>` (pick **user**, **project** or **local** scope), `/plugin enable|disable|uninstall|update`, `/reload-plugins` to apply changes mid-session. Terminal (scriptable, same verbs): `claude plugin install|uninstall|enable|disable|update|list [--json]|details|validate|marketplace add|list|remove|update`, plus `claude plugin init <name>` which scaffolds a personal "skills-directory plugin" under `~/.claude/skills/<name>/` that loads with no install step. `claude --plugin-dir <dir-or-zip>` loads a plugin for one session only — the developer loop.

**Marketplace.** A git repo (or local directory) whose `.claude-plugin/marketplace.json` lists plugins: `name`, `owner`, `plugins[]` each with a `name` and a `source` — a relative path inside the marketplace (`"./codebase-toolkit"`), or `{ "source": "github", "repo": "owner/repo", "ref": "v4.0.0" }`, a git URL, a git subdirectory, an npm package, or a zip archive. Installing copies the plugin into `~/.claude/plugins/cache/…`; it is not run in place. GitHub is the recommended host: users add it with `/plugin marketplace add owner/repo`.

**The official marketplace.** `claude-plugins-official` (repo `anthropics/claude-plugins-official`) is registered automatically the first time Claude Code starts interactively; browse it in `/plugin` → Discover or at claude.com/plugins. That is where `skill-creator`, the language-server plugins, `security-guidance` and the **Claude Security** plugin you will run in Module 7 come from. Its plugins auto-update by default; third-party and local marketplaces do not unless you turn it on per marketplace. A separate, reviewed community marketplace exists as well (Ref §H.2 — name and submission flow are re-verified before each delivery).

**Team rollout in two keys.** Commit this to the repo's `.claude/settings.json` and every teammate who trusts the folder gets the marketplace registered and the plugin enabled:

```json
{
  "extraKnownMarketplaces": {
    "<WORKSHOP_ORG>-marketplace": {
      "source": { "source": "github", "repo": "<WORKSHOP_ORG>/claude-marketplace" }
    }
  },
  "enabledPlugins": { "codebase-toolkit@<WORKSHOP_ORG>-marketplace": true }
}
```

A teammate can still opt out locally with `false` in `.claude/settings.local.json`. `claude plugin install … --scope project` writes the `enabledPlugins` entry for you; commit `extraKnownMarketplaces` alongside it so teammates' machines can resolve the marketplace name.

**Enterprise controls (one breath; details Ref §H.2 and Module 7).** In managed settings, `strictKnownMarketplaces` is an allowlist of marketplace sources (e.g. only `anthropics/claude-plugins-official` and `your-org/*`), `blockedMarketplaces` a blocklist, managed `enabledPlugins` force-enables or hard-blocks specific plugins, `strictPluginOnlyCustomization` makes plugins + managed config the *only* way skills/hooks/agents load, and Team/Enterprise admins can also distribute a private marketplace from the claude.ai organization settings. The docs' own warning is the policy: *plugins and marketplaces execute arbitrary code with your user privileges — only install from sources you trust.*

### 5. Where these components go this afternoon

| Component | Module 4 (headless/CI) | Module 5 (Agent SDK) | Module 6 (Managed Agents) |
|---|---|---|---|
| `bug-hunter` agent | `claude -p "@agent-codebase-toolkit:bug-hunter …"`, `--agent` | `plugins=[{"type":"local","path":"../codebase-toolkit"}]` or `agents={…}` | body pasted as the agent's `system` prompt |
| `code-reviewer` skill | `claude -p "/codebase-toolkit:code-reviewer src/x"`; Action `prompt:` | discovered via `setting_sources` / `plugins`; `skills=[…]` option | skills attach to the agent definition |
| hooks + MCP in the plugin | load in `-p` (mind the trust caveat) | mirrored as hook callbacks / `mcp_servers` | `permission_policy`, MCP toolsets + vault credentials |

---

## Live demo script (15 min)

> [!NOTE]
> **Instructor setup:** `cd $OTEL`, CP2 state, `mkdir -p .claude/agents .claude/skills` **before** starting `claude` so hot-reload works, `/effort medium`, model `sonnet` unless the room agreed otherwise. Have `$WS/labs/m3/` open in an editor on the second screen. Keep `/tasks` and `/context` muscle memory ready.

**Demo 1 — Built-ins and parallelism (4 min).** In `claude`:

```
/context
```
```
Use 3 parallel subagents to summarize this repo by language family:
1) the Go services, 2) the Python services, 3) the TypeScript/JavaScript services under src/.
Each returns: services covered, entry points, how they talk to other services (gRPC/HTTP/Kafka), and one surprising thing.
Then merge the three summaries into ARCHITECTURE.md at the repo root.
```

Point at the three `Agent(…)` lines starting together, run `/tasks` while they work ("this is background-by-default — I still have my prompt"), then `/context` again when `ARCHITECTURE.md` is written: the main context grew by three summaries, not by ninety file reads. Say the cost line out loud: "three cold starts, three token bills — worth it here because the work was independent and read-heavy; not worth it for a one-file change." Mention `/usage` shows per-subagent spend.

**Demo 2 — Custom agents (3 min).** Open `labs/m3/agents/service-documenter.md` and `bug-hunter.md` side by side; narrate `description` ("the routing signal"), `tools: Read, Grep, Glob` ("read-only specialists — the parent writes files"), `model: sonnet` ("alias, survives releases"), `effort`. Then:

```bash
cp $WS/labs/m3/agents/*.md .claude/agents/
```

Back in the running session (no restart): type `@` and show `bug-hunter (agent)` in the typeahead, then

```
@agent-bug-hunter analyze src/adservice and report using your severity format
```

While it runs: "explicit mention *guarantees* this agent; plain prose lets Claude choose; a good description makes it choose right."

**Demo 3 — The skill (3 min).** Open `labs/m3/skills/code-reviewer/SKILL.md`. Narrate top to bottom: `argument-hint`, `allowed-tools` as least privilege ("read-only tools plus exactly two git commands — and no prompts"), `$0`/`$1`, the `` !`git log …` `` line ("runs *before* Claude reads this"), and the *link* to `checklists/security.md` ("not loaded unless the focus asks for it — progressive disclosure"). Then:

```bash
cp -r $WS/labs/m3/skills/code-reviewer .claude/skills/
```
```
/code-reviewer src/paymentservice security
```

Expand the tool calls (`Ctrl+O`): a `Read` of `checklists/security.md` appears *because* `$1` was `security`. Ask the room: "what would make this skill model-invocable vs. user-only?" (`disable-model-invocation`).

**Demo 4 — Package, validate, serve, install (5 min).** Narrate fast; participants do it themselves in Part C.

```bash
cd $OTEL/..
mkdir -p codebase-toolkit/{.claude-plugin,agents,skills,hooks}
cp $OTEL/.claude/agents/{service-documenter,bug-hunter}.md codebase-toolkit/agents/
cp -r $OTEL/.claude/skills/code-reviewer codebase-toolkit/skills/
cp $OTEL/.claude/hooks/protect-files.sh codebase-toolkit/hooks/
cp $WS/labs/m3/plugin/hooks/hooks.json codebase-toolkit/hooks/
cp $WS/labs/m3/plugin/.mcp.json codebase-toolkit/
cp $WS/labs/m3/plugin/.claude-plugin/plugin.json codebase-toolkit/.claude-plugin/
claude plugin validate ./codebase-toolkit          # ✔ Validation passed
cd $OTEL && claude --plugin-dir ../codebase-toolkit
```

In the session: `/plugin` → **Installed** tab shows `codebase-toolkit` (session-only), then `/codebase-toolkit:code-reviewer src/adservice`. Exit. Show `labs/m3/marketplace/.claude-plugin/marketplace.json` (three fields that matter: `name`, `owner`, `plugins[].source`), then in a fresh `claude`:

```
/plugin marketplace add ../workshop-marketplace
/plugin install codebase-toolkit@workshop-marketplace
```

Finish on the browser: the org-published `github.com/<WORKSHOP_ORG>/claude-marketplace` repo (same two files, tagged `v4.0.0`) and the two-key team-rollout snippet from Concepts §4. Mention `claude plugin init` as the personal-scaffold shortcut and `claude-plugins-official` in the Discover tab. Announce: "Lab, 37 minutes, three parts, checkpoint is CP3."

---

## Hands-on lab (37 min)

Start state: CP2, no `claude` session running in `$OTEL`.

### Part A — Subagents (12 min)

**Step 1 (2 min) — Install the two agents and make them yours.**

```bash
cd $OTEL
mkdir -p .claude/agents .claude/skills docs reports
cp $WS/labs/m3/agents/service-documenter.md $WS/labs/m3/agents/bug-hunter.md .claude/agents/
```

Open both files (contents below). Change one line in each so the agent is recognizably yours — for example add "Kotlin and Rust" awareness to service-documenter's step 1 and add "6. Look for resource leaks (unclosed connections, streams, goroutines)" to bug-hunter.

`.claude/agents/service-documenter.md`:

```markdown
---
name: service-documenter
description: Documents a single microservice — language, entry point, endpoints, dependencies, configuration. Use proactively whenever the user asks to document, summarize, explain, or onboard onto one service directory (for example src/<service>).
tools: Read, Grep, Glob
model: sonnet
effort: medium
color: blue
---

You are a technical documentation specialist. When given a service directory:

1. Identify the primary language and framework
2. Find the main entry point
3. List key functions/endpoints (gRPC methods, HTTP routes, message handlers)
4. Identify dependencies on other services (clients it creates, topics it publishes or consumes)
5. Note any configuration files, environment variables, and feature flags

Output a concise markdown summary with:
- **Service name** and language
- **Purpose** (1-2 sentences)
- **Key endpoints/functions** (bullet list, with file:line)
- **Dependencies** (other services it calls, and how)
- **Configuration** options

Keep the summary under 60 lines. You are read-only: return the markdown as your
final message; the caller decides where to save it. Follow any conventions in the
project's CLAUDE.md.
```

`.claude/agents/bug-hunter.md`:

```markdown
---
name: bug-hunter
description: Investigates one service for bugs, error-handling gaps, concurrency and reliability issues, and reports findings by severity with file:line evidence. Use proactively when the user asks to debug, audit, find bugs in, or assess the code quality of a service or directory.
tools: Read, Grep, Glob
model: sonnet
effort: high
color: orange
---

You are a debugging specialist. When investigating a service:

1. Check all error handling paths
2. Look for unhandled exceptions and ignored return values
3. Identify potential race conditions and shared-state hazards
4. Find timeout/retry issues in calls to other services
5. Check for null/undefined/nil handling and input validation at boundaries

Report findings as a markdown list, most severe first:
- **[HIGH]** <issue> — `file:line` — must fix; explain the failure scenario
- **[MEDIUM]** <issue> — `file:line` — should address
- **[LOW]** <observation> — `file:line` — minor improvement

Rules:
- Always include specific file paths and line numbers you actually read.
- Suggest a concrete fix for every HIGH and MEDIUM finding.
- Do not report style nits, missing comments, or hypothetical issues you cannot
  point to in the code. If you find nothing significant, say so.
- You are read-only: return the report as your final message; the caller saves it.
```

**Step 2 (5 min) — Run both in parallel.**

```bash
claude --permission-mode default
```
```
Use the service-documenter agent on src/emailservice and the bug-hunter agent on src/paymentservice, in parallel.
When both are done, save the documentation to docs/emailservice.md and the bug report to reports/paymentservice-bugs.md.
```

Watch two `Agent(…)` lines start; run `/tasks` while they work; keep typing if you like — the prompt is live. Approve the two `Write` calls when the parent saves the files (the agents themselves are read-only; the *parent* writes).

**Step 3 (3 min) — Explicit mention, and feel `effort`.** In your editor change bug-hunter's `effort: high` to `effort: low` and save — no restart; the file hot-reloads. Then:

```
@agent-bug-hunter investigate src/currencyservice
```

Compare depth and latency with the paymentservice report. Set it back to `effort: high` and save. (Frontmatter `effort` overrides the session's `/effort`; that is why we edited the file rather than the slider.)

**Step 4 (2 min) — Success check.**

```
! ls docs reports
/context
```

Both files exist, and `/context` shows the main conversation well under 30% — the reading happened in the subagents' windows, not yours.

### Part B — Skill (8 min)

**Step 5 (2 min) — Install the skill.**

```bash
# in a second terminal, or prefix with ! inside claude
cp -r $WS/labs/m3/skills/code-reviewer $OTEL/.claude/skills/
```

The skill directory (contents below) is `SKILL.md` plus two supporting checklists:

```
.claude/skills/code-reviewer/
├── SKILL.md
└── checklists/
    ├── security.md
    └── performance.md
```

`.claude/skills/code-reviewer/SKILL.md`:

```markdown
---
name: code-reviewer
description: Review a directory or file for code quality, error handling, performance and basic security, and report findings by severity with file:line references. Use when reviewing a service before a PR, auditing code quality, or when the user asks for a code review of a path. Optional second argument narrows the focus (security | performance).
argument-hint: <path> [security|performance]
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git log *)
  - Bash(git diff *)
---

# Code review: $0

Review the code at `$0`. Requested focus: `$1`

## Recent history (injected before you read this)

Last commits touching this path:

!`git log -3 --oneline -- $0`

Uncommitted changes under this path (may be empty):

!`git diff --stat -- $0`

## How to review

1. Map the target first: language, entry point, size. Read the files that matter;
   use Grep/Glob rather than reading everything.
2. Apply the **general checklist** below to what you read.
3. Focus handling:
   - If the requested focus above is `security`, ALSO read
     `${CLAUDE_SKILL_DIR}/checklists/security.md` and apply every item in it.
   - If it is `performance`, ALSO read
     `${CLAUDE_SKILL_DIR}/checklists/performance.md` and apply every item in it.
   - If it is blank or still shows a `$`-placeholder, no focus was given: apply only
     the general checklist and do not read the checklist files.
4. If recent commits or uncommitted changes exist, weight your attention toward them.

## General checklist

### Code quality
- Clear naming; functions do one thing; no copy-paste duplication
- Dead code, commented-out blocks, TODOs that hide real gaps

### Error handling
- Every error path handled or deliberately propagated; no swallowed exceptions
- Meaningful error messages; cleanup on failure (connections, files, spans)

### Performance (quick pass)
- Work inside loops that belongs outside; N+1 remote calls; unbounded growth

### Security basics (quick pass)
- Input validated at the boundary; no hardcoded secrets; authn/authz where expected

## Output format

Start with a 2-3 sentence summary of what the code does and its overall state. Then:

- **[HIGH]** must fix before merge — `file:line` — why it matters — suggested fix
- **[MEDIUM]** should address — `file:line` — suggested fix
- **[LOW]** suggestion — `file:line`

End with "Reviewed: <n> files, focus: <focus or general>". Cite only lines you read.
Follow the project's CLAUDE.md conventions when judging style.
```

`.claude/skills/code-reviewer/checklists/security.md`:

```markdown
# Security checklist (loaded only when focus = security)

Apply each item to the code under review and cite file:line for every hit.

1. **Injection** — SQL/NoSQL/command/template strings built by concatenation or
   f-strings with request data; shelling out with user input.
2. **Authentication & authorization** — endpoints or RPCs reachable without a check;
   object IDs taken from the request without an ownership check (IDOR).
3. **Secrets** — API keys, passwords, tokens, private keys in source, config samples,
   tests or logs; secrets compared with non-constant-time equality.
4. **Outbound requests** — URLs assembled from user input (SSRF); TLS verification
   disabled; missing timeouts.
5. **Deserialization & parsing** — unsafe YAML/pickle/object deserialization of
   untrusted data; XML external entities.
6. **File system** — paths joined from user input without normalization (traversal);
   world-writable temp files.
7. **Web output** — unescaped user data in HTML/templates (XSS); verbose stack traces
   or debug mode enabled in production paths.
8. **Dependencies** — obviously outdated or unpinned security-relevant libraries
   (note only; do not guess CVEs).

Do NOT report: missing rate limiting, missing security headers, or theoretical issues
without a concrete code location. Severity: exploitable without auth = HIGH.
```

`.claude/skills/code-reviewer/checklists/performance.md`:

```markdown
# Performance checklist (loaded only when focus = performance)

Apply each item to the code under review and cite file:line for every hit.

1. **Remote calls in loops** — per-item gRPC/HTTP/DB calls that could be batched (N+1).
2. **Missing timeouts / retries without backoff** on calls to other services.
3. **Allocation churn** — building large strings/arrays in hot paths; repeated
   (de)serialization of the same payload; regex compiled per call.
4. **Blocking work on request threads / event loop** — sync I/O in async handlers,
   CPU-heavy work without offloading.
5. **Caching** — identical lookups repeated per request (currency rates, product
   catalog, feature flags) with no cache or memoization.
6. **Unbounded growth** — maps/lists/queues that only grow; goroutine/task leaks;
   listeners never removed.
7. **Telemetry cost** — spans or logs emitted inside tight loops; high-cardinality
   attributes.

Severity: user-visible latency or memory growth under normal load = HIGH;
measurable but bounded = MEDIUM; micro-optimizations = LOW (mention at most three).
```

**Step 6 (4 min) — Run it twice with different arguments.** In `claude` (if the session was already running when you copied the skill in, it is picked up live; if `/code-reviewer` does not autocomplete, run `/reload-skills`):

```
/code-reviewer src/shippingservice
```
```
/code-reviewer src/frontend performance
```

Expand the second run's tool calls (`Ctrl+O`): there is a `Read …/checklists/performance.md` that the first run did not have. Open `SKILL.md` and find the three lines that made `$1` do that. Note also the "Recent history" section arrived pre-filled — that was the `` !`git log …` `` line, executed under the `Bash(git log *)` grant without a prompt.

**Step 7 (2 min) — Success check.**

```
/skills
```

`code-reviewer` is listed as a project skill (press `t` to see what its listing costs in tokens). Then ask in plain prose: `What skills can you invoke yourself, and when would you pick code-reviewer?` — Claude describes it from the description, proving it is model-invocable. (If you wanted it user-only you would add `disable-model-invocation: true`.)

### Part C — Plugin + marketplace (17 min)

**Step 8 (4 min) — Assemble `codebase-toolkit` next to the repo.**

```bash
cd $OTEL/..
mkdir -p codebase-toolkit/.claude-plugin codebase-toolkit/agents codebase-toolkit/skills codebase-toolkit/hooks
cp $OTEL/.claude/agents/service-documenter.md $OTEL/.claude/agents/bug-hunter.md codebase-toolkit/agents/
cp -r $OTEL/.claude/skills/code-reviewer codebase-toolkit/skills/
cp $OTEL/.claude/hooks/protect-files.sh codebase-toolkit/hooks/ && chmod +x codebase-toolkit/hooks/protect-files.sh
cp $WS/labs/m3/plugin/hooks/hooks.json codebase-toolkit/hooks/
cp $WS/labs/m3/plugin/.mcp.json codebase-toolkit/
cp $WS/labs/m3/plugin/.claude-plugin/plugin.json codebase-toolkit/.claude-plugin/
```

Then edit `plugin.json` and put **your** name in `author`. Target layout:

```
codebase-toolkit/
├── .claude-plugin/
│   └── plugin.json            <- manifest: the ONLY file in .claude-plugin/
├── agents/
│   ├── service-documenter.md
│   └── bug-hunter.md
├── skills/
│   └── code-reviewer/
│       ├── SKILL.md
│       └── checklists/{security.md,performance.md}
├── hooks/
│   ├── hooks.json             <- was the "hooks" block of settings.json in M2
│   └── protect-files.sh       <- unchanged copy of your M2 script
└── .mcp.json                  <- astro-catalog, path via ${WORKSHOP_REPO}
```

`codebase-toolkit/.claude-plugin/plugin.json`:

```json
{
  "name": "codebase-toolkit",
  "version": "4.0.0",
  "description": "Onboard onto an unfamiliar codebase: parallel service documentation, severity-ranked bug hunting, an argument-driven code-review skill, a generated-code protection hook, and the astro-catalog MCP server.",
  "author": { "name": "<your name>", "url": "https://github.com/<your-github-user>" },
  "repository": "https://github.com/<WORKSHOP_ORG>/claude-marketplace",
  "license": "Apache-2.0",
  "keywords": ["documentation", "debugging", "code-review", "onboarding", "workshop"]
}
```

`codebase-toolkit/hooks/hooks.json` — the M2 hook block moved into a plugin. Note the two different variables: the *script* lives in the plugin (`${CLAUDE_PLUGIN_ROOT}`), the *audit log* belongs to whichever project the plugin runs in (`$CLAUDE_PROJECT_DIR`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/protect-files.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "jq -r '.tool_input.command' >> \"$CLAUDE_PROJECT_DIR\"/.claude/bash-audit.log" }
        ]
      }
    ]
  }
}
```

`codebase-toolkit/.mcp.json` — same server as M2, but the path comes from an environment variable so the plugin works on any machine that has the workshop repo (`WORKSHOP_REPO` is exported by `labs/.env`; `${VAR}` and `${VAR:-default}` expansion work in `command`, `args`, `env`, `url`, `headers`):

```json
{
  "mcpServers": {
    "astro-catalog": {
      "type": "stdio",
      "command": "node",
      "args": ["${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs"]
    }
  }
}
```

> [!NOTE]
> **Instructor:** two design points worth 30 seconds. (1) In a production plugin you would *vendor* the server under the plugin and reference it as `${CLAUDE_PLUGIN_ROOT}/servers/…`; if the plugin root carries a `package.json` + lockfile, Claude Code installs Node dependencies automatically at install time. We point at `$WS` to keep the lab light. (2) Once bundled, the server's tools are called `mcp__plugin_codebase-toolkit_astro-catalog__list_products` etc. — the M2 permission rule `mcp__astro-catalog__*` does not match them.

**Step 9 (2 min) — Validate.**

```bash
claude plugin validate ./codebase-toolkit
```

Expected: `✔ Validation passed`. It checks `plugin.json`, every agent/skill frontmatter and `hooks/hooks.json`. Fix whatever it flags (the usual suspects are in Troubleshooting) and re-run until green. `--strict` turns warnings into errors — good CI hygiene.

**Step 10 (3 min) — Session-only smoke test with `--plugin-dir`.**

```bash
cd $OTEL && source $WS/labs/.env      # makes sure WORKSHOP_REPO is exported
claude --plugin-dir ../codebase-toolkit
```
```
/plugin
```

The **Installed** tab lists `codebase-toolkit` for this session (nothing was written to any settings file); `/mcp` shows a second, plugin-provided `astro-catalog` next to your project one. Then:

```
/codebase-toolkit:code-reviewer src/adservice
@agent-codebase-toolkit:bug-hunter give src/productcatalogservice a quick pass
```

Both resolve through the plugin namespace. Exit `claude` (`/exit`).

**Step 11 (4 min) — Serve it from a local marketplace and install it for real.**

```bash
cd $OTEL/..
mkdir -p workshop-marketplace/.claude-plugin
cp $WS/labs/m3/marketplace/.claude-plugin/marketplace.json workshop-marketplace/.claude-plugin/
cp -r codebase-toolkit workshop-marketplace/
claude plugin validate ./workshop-marketplace       # validates marketplace.json too
```

`workshop-marketplace/.claude-plugin/marketplace.json` (edit `owner`):

```json
{
  "name": "workshop-marketplace",
  "description": "Local marketplace built in Module 3 of the Claude builders workshop",
  "owner": { "name": "<your name>" },
  "plugins": [
    {
      "name": "codebase-toolkit",
      "source": "./codebase-toolkit",
      "description": "Service documentation, bug hunting, code review, generated-code protection hook, astro-catalog MCP server",
      "version": "4.0.0",
      "category": "developer-tools",
      "keywords": ["documentation", "debugging", "code-review", "onboarding"]
    }
  ]
}
```

Resulting sibling layout:

```
<parent>/
├── opentelemetry-demo/        ($OTEL — where you work)
├── codebase-toolkit/          (your plugin source)
└── workshop-marketplace/
    ├── .claude-plugin/marketplace.json     source: "./codebase-toolkit"
    └── codebase-toolkit/                   (copy that the marketplace serves)
```

Now install at **project** scope:

```bash
cd $OTEL && claude
```
```
/plugin marketplace add ../workshop-marketplace
/plugin install codebase-toolkit@workshop-marketplace
```

In the details pane choose **Project** scope. If the summary ends with `Run /reload-plugins to activate.`, do so. Then remove the now-duplicated loose copies — project `.claude/agents/` definitions *override* same-named plugin agents, so the plugin's versions only take effect once the originals are gone (skills do not clash because plugin skills are namespaced, but two `code-reviewer`s in the `/` menu is confusing):

```bash
# second terminal
$WS/labs/m3/dedupe.sh          # removes $OTEL/.claude/agents/{service-documenter,bug-hunter}.md and .claude/skills/code-reviewer/
                               # and offers (y/N) to also drop the astro-catalog entry from .mcp.json and the two
                               # hook entries from .claude/settings.json, since the plugin now provides them
```

**Step 12 (2 min) — Success check.**

```bash
claude plugin list
cat $OTEL/.claude/settings.json | jq '.enabledPlugins, .extraKnownMarketplaces'
```

`codebase-toolkit@workshop-marketplace` is listed as enabled at project scope, and `.claude/settings.json` gained an `enabledPlugins` entry — half of the team-rollout mechanism from Concepts §4 (the other half, `extraKnownMarketplaces`, is what you would commit so a teammate's machine can find a *published* marketplace; a `../` path only resolves on yours). Then in a **fresh** `claude` session:

```
/codebase-toolkit:code-reviewer src/cartservice
```

**Step 13 (2 min) — Install the org-published copy at user scope (your safety net for the afternoon).**

```
/plugin marketplace add <WORKSHOP_ORG>/claude-marketplace
/plugin install codebase-toolkit@<WORKSHOP_ORG>-marketplace
```

Choose **User** scope this time, so `claude -p` in any directory (Module 4) and the SDK's setting sources (Module 5) can see it. You now have two plugins both called `codebase-toolkit` from two marketplaces; there is no documented precedence between same-named plugins, so keep exactly one enabled: `claude plugin disable codebase-toolkit@workshop-marketplace --scope project` (re-enable yours whenever you want to iterate on it; `--plugin-dir ../codebase-toolkit` always wins for a session). Terminal equivalent of this whole step:

```bash
claude plugin marketplace add $WORKSHOP_ORG/claude-marketplace
claude plugin install codebase-toolkit@$WORKSHOP_ORG-marketplace --scope user
claude plugin disable codebase-toolkit@workshop-marketplace --scope project
```

> [!NOTE]
> **Instructor, debrief (3 min):** ask two people what bug-hunter found in paymentservice; ask one person to read their `enabledPlugins` block aloud; restate the ladder — "files in `.claude/` → plugin dir → marketplace → one install line; this afternoon the SDK loads `../codebase-toolkit` by path and Managed Agents reuses the bug-hunter prompt." Announce **CP3**.

---

## If you're behind (fast-forward)

```bash
cd $OTEL && $WS/labs/checkpoint.sh CP3
```

CP3 adds the `<WORKSHOP_ORG>/claude-marketplace` marketplace and installs `codebase-toolkit@<WORKSHOP_ORG>-marketplace` at **user** scope, writes solution copies of `../codebase-toolkit/` and `../workshop-marketplace/` next to `$OTEL` (so Module 5 can load the plugin by path), and removes loose duplicates from `$OTEL/.claude/agents/` and `.claude/skills/`. It never overwrites files you changed unless you pass `--force`, and prints what it did. Minimum viable state for the afternoon is just step 13.

Partial catch-ups: skipped Part A/B only → `cp $WS/labs/m3/agents/*.md $OTEL/.claude/agents/ && cp -r $WS/labs/m3/skills/code-reviewer $OTEL/.claude/skills/`. Skipped Part C only → run step 13, then CP3 for the directories.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Agent file saved but Claude never delegates to it | Weak `description`; or Claude judged the task small enough to do inline | Front-load *when* to use it ("Use proactively when…"); or force it with `@agent-bug-hunter`; check `/doctor` for duplicate agent names |
| New agent/skill not visible in a running session | `.claude/agents` or `.claude/skills` did not exist when the session started | Restart `claude` once (or `/reload-skills` for skills); after that edits hot-reload |
| `claude plugin validate` fails on an agent or skill | YAML frontmatter: tab characters, missing closing `---`, unquoted `:` in `description`, `tools` written as `[Read Grep]` | Spaces not tabs; quote descriptions containing colons; `tools: Read, Grep, Glob` or a YAML list |
| `/code-reviewer` aborts with `Shell command permission check failed for pattern "git log …"` | The injected `!` command is not covered by `allowed-tools` or an allow rule (injected commands never prompt); or a *deny/ask* rule matches `git` | Keep `Bash(git log *)` / `Bash(git diff *)` in `allowed-tools`; remove conflicting ask/deny rules |
| `/code-reviewer` aborts with `Shell command failed …` | Injected command exited non-zero (e.g. not a git repo, bad path) | Run the command by hand; append `\|\| true` to commands allowed to fail |
| Skill directory copied but command is `/code-reviewer` not what `name:` says (or vice versa) | For project/personal skills the **directory name** is the command; `name:` is a label. In plugins `name:` sets the last segment. | Rename the directory, keep `name` equal to it |
| Windows: skill says it requires bash | `!` injection defaults to bash; no Git Bash installed | Add `shell: powershell` to the skill frontmatter (PowerShell tool is default on Windows without Git Bash) or install Git for Windows |
| Plugin loads but hook never fires / `No such file` in Errors tab | `hooks.json` still uses `$CLAUDE_PROJECT_DIR/.claude/hooks/…` for the script path; script not executable; `agents/` etc. placed inside `.claude-plugin/` | Script path must be `${CLAUDE_PLUGIN_ROOT}/hooks/protect-files.sh`; `chmod +x`; only `plugin.json` lives in `.claude-plugin/` |
| Plugin `astro-catalog` shows *failed* in `/mcp` | `WORKSHOP_REPO` not exported in the shell that launched `claude` (unexpanded `${WORKSHOP_REPO}` is used literally); Node < 20; `npm ci` never ran in `labs/mcp/astro-catalog` | `source $WS/labs/.env` then restart; `node $WORKSHOP_REPO/labs/mcp/astro-catalog/server.mjs --selftest`; `claude mcp list` prints the missing-variable warning |
| MCP tools prompt again although M2 allowed `mcp__astro-catalog__*` | Plugin-bundled server tools are named `mcp__plugin_codebase-toolkit_astro-catalog__…` | `/permissions` → allow `mcp__plugin_codebase-toolkit_astro-catalog__*` |
| `/plugin install …@workshop-marketplace` → plugin not found / source error | `source` in `marketplace.json` is relative to the **marketplace root** and must start with `./`; plugin dir not copied into the marketplace; entry `name` ≠ `plugin.json` `name` | `"source": "./codebase-toolkit"` and `workshop-marketplace/codebase-toolkit/` exists; names identical |
| Installed but `/codebase-toolkit:…` unknown in this session | Install summary said `Run /reload-plugins to activate.` | `/reload-plugins` (add `--force` if it warns about the prompt cache) or start a new session |
| Two `bug-hunter`s / plugin agent seems ignored | Loose `.claude/agents/bug-hunter.md` overrides the plugin's same-named agent | Run `labs/m3/dedupe.sh` (or delete the loose files); address the plugin one explicitly as `@agent-codebase-toolkit:bug-hunter` |
| Two plugins named `codebase-toolkit` (yours + org) both enabled, odd behavior | Same plugin name from two marketplaces | Keep one enabled: `claude plugin disable codebase-toolkit@workshop-marketplace --scope project` |
| Edited the plugin source, reinstalled, "already at the latest version" | `version` in `plugin.json` unchanged — with an explicit version, updates ship only on a bump | Bump to `4.0.1` in `plugin.json` (it wins over the marketplace entry), recopy into the marketplace, `/plugin update` or `claude plugin update codebase-toolkit@workshop-marketplace --scope project`; while iterating prefer `--plugin-dir` |
| `/plugin marketplace add <WORKSHOP_ORG>/…` refused on a corporate laptop | Managed `strictKnownMarketplaces` / `blockedMarketplaces` policy | Expected in locked-down orgs; use the instructor's screen or pair. This is the enterprise control working as designed (Module 7). |
| Windows: `cp -r` / `chmod` unfamiliar, symlink errors | Native PowerShell | Run the lab commands from Git Bash or WSL2 (see `labs/SETUP.md`), or translate by hand (`Copy-Item -Recurse`; `chmod` is unnecessary on Windows); no symlinks are needed in this lab |

## Stretch goals

Pick any; all are independent.

1. **Publish your own GitHub marketplace.** `gh repo create <you>/claude-marketplace --public --template <WORKSHOP_ORG>/claude-marketplace-template --clone`, copy `codebase-toolkit/` in, edit `.claude-plugin/marketplace.json` (`name: <you>-marketplace`), commit, push, then `/plugin marketplace add <you>/claude-marketplace` and install from it. Pin consumers to a release with `"source": {"source": "github", "repo": "<you>/claude-marketplace", "ref": "v4.0.0"}` from another marketplace, or tag it.
2. **Named arguments.** Convert the skill to `arguments: [path, focus]` and `$path` / `$focus` in the body; note that a missing named argument becomes an empty string (no more `$`-placeholder check). Add `when_to_use:` with three trigger phrases and watch `/skills` token count change.
3. **Forked skill.** Add `context: fork`, `agent: Explore` and `effort: high` to a copy named `deep-reviewer`; invoke it and observe it run as a background subagent whose result arrives later. Then set `background: false` and compare.
4. **Worktree-isolated bug fixer.** Copy bug-hunter to `bug-fixer.md` with `tools: Read, Grep, Glob, Edit, Write, Bash`, `isolation: worktree`, `background: true`, `maxTurns: 40`, and a body that fixes the top HIGH finding and commits on its worktree branch. Ask Claude to run it on `src/adservice` and inspect the branch it leaves behind. (Remember: `permissionMode`, `hooks`, `mcpServers` would be ignored once this agent ships in a plugin.)
5. **`bin/` and `workflows/` in the plugin.** Add `codebase-toolkit/bin/toolkit-report` (a small shell script that concatenates `reports/*.md` into one file) — it becomes a bare command in the Bash tool while the plugin is enabled — and drop a saved workflow script into `codebase-toolkit/workflows/` so it appears as `/codebase-toolkit:<workflow>` (Module 4 explains workflows). Re-validate, bump `version`.
6. **Token accounting.** `claude plugin details codebase-toolkit` prints the component inventory with *always-on* vs *on-invoke* token cost; compare with pressing `t` in `/skills` and with `/context`.
7. **`userConfig`.** Add to `plugin.json`:
   ```json
   "userConfig": {
     "severity_threshold": {
       "type": "string", "title": "Severity threshold",
       "description": "Lowest severity bug-hunter should report (LOW, MEDIUM or HIGH)",
       "default": "LOW"
     }
   }
   ```
   and reference `${user_config.severity_threshold}` in `agents/bug-hunter.md` ("Report only findings at or above …"). Reinstall: you are prompted for the value at enable time; `claude plugin install … --config severity_threshold=MEDIUM` sets it non-interactively. Values land under `pluginConfigs` in your user settings.
8. **Evaluate the skill with skill-creator.** `/plugin install skill-creator@claude-plugins-official`, then "evaluate my code-reviewer skill with skill-creator": it helps you write test prompts, runs blind comparisons against a no-skill baseline and suggests description tweaks.
9. **Preloaded skills in an agent.** Add `skills: [code-reviewer]` to service-documenter's frontmatter and ask it to end each summary with a "review hotspots" section — the full skill body is injected at the subagent's start instead of being discovered.
10. **Lock it down like an enterprise would.** Read Ref §H.2's managed-settings example that allows only `anthropics/claude-plugins-official` and `<WORKSHOP_ORG>/*` via `strictKnownMarketplaces`, and predict which of today's three marketplaces (`workshop-marketplace`, `<WORKSHOP_ORG>-marketplace`, `claude-plugins-official`) would survive. (Do not apply it to your laptop.)

## Key takeaways

- **Subagent = isolated context + own prompt + scoped tools → summary back.** Great for read-heavy, independent, parallel work; wasteful for small or tightly coupled edits. In interactive sessions they run in the background by default; `/tasks` shows them; `@agent-name` guarantees one runs; the `description` decides whether Claude picks it unprompted.
- **Skill = a procedure that costs (almost) nothing until invoked.** Directory name is the command; `description` routes; `$0`/`$1`/`$name` take arguments; `` !`cmd` `` injects live context; `allowed-tools` is least privilege without prompts; supporting files load only when referenced. Custom slash commands *are* skills.
- **Guarantees live in hooks and permissions; guidance lives in CLAUDE.md and skills; big side quests live in subagents; access lives in MCP.** The decision table is the thing to screenshot.
- **Plugin = the same files in a conventional layout + `plugin.json`; marketplace = a `marketplace.json` that points at plugins.** `claude plugin validate` → `--plugin-dir` → `/plugin marketplace add` → `/plugin install name@marketplace`. `version` controls when users get updates; `${CLAUDE_PLUGIN_ROOT}` replaces project paths; plugin MCP tools and agents are namespaced.
- **Rollout is two settings keys** (`extraKnownMarketplaces`, `enabledPlugins`); **governance is managed settings** (`strictKnownMarketplaces` and friends). Plugins run with your privileges — installing one is a trust decision, which Module 7 revisits.
- Everything you built is now addressable as `codebase-toolkit:…` — by `claude -p` (M4), by the Agent SDK (M5), and, as a prompt and skills, by Managed Agents (M6).

## References

- Reference appendix for this module: `reference/Technical-Reference-v4.md` §G (subagents: file format, full frontmatter table, built-ins, invocation, background/nesting limits), §H (skills: frontmatter table, substitutions, bundled skills, description-writing guidance), §H.2 (plugins & marketplaces: layout, `plugin.json` and `marketplace.json` schemas, CLI table, scopes, `enabledPlugins`, managed restrictions, official/community marketplaces), §O (volatile facts to re-verify).
- Claude Code docs — Subagents: <https://code.claude.com/docs/en/sub-agents>
- Claude Code docs — Run agents in parallel (subagents vs. background sessions vs. workflows vs. teams): <https://code.claude.com/docs/en/agents>
- Claude Code docs — Skills: <https://code.claude.com/docs/en/skills>
- Claude Code docs — Extend Claude Code (features overview and comparison tables): <https://code.claude.com/docs/en/features-overview>
- Claude Code docs — Create plugins: <https://code.claude.com/docs/en/plugins>
- Claude Code docs — Plugins reference (layout, manifest schema, CLI): <https://code.claude.com/docs/en/plugins-reference>
- Claude Code docs — Create and distribute a plugin marketplace: <https://code.claude.com/docs/en/plugin-marketplaces>
- Claude Code docs — Discover and install plugins: <https://code.claude.com/docs/en/discover-plugins>
- Claude Code docs — Settings (`enabledPlugins`, `extraKnownMarketplaces`, `strictKnownMarketplaces`, `skillOverrides`): <https://code.claude.com/docs/en/settings>
- Official plugin catalog: <https://claude.com/plugins> · repo `anthropics/claude-plugins-official`
- Agent Skills open standard: <https://agentskills.io>
- Agent SDK — plugins and skills in the SDK (preview of Module 5): <https://code.claude.com/docs/en/agent-sdk/plugins>, <https://code.claude.com/docs/en/agent-sdk/skills>
- Lab assets: `labs/m3/agents/`, `labs/m3/skills/code-reviewer/`, `labs/m3/plugin/`, `labs/m3/marketplace/`, `labs/m3/dedupe.sh`; solutions in `labs/checkpoints/CP3/` (which copies from `labs/m3/plugin` and `labs/m3/marketplace`).

*Verified against current Claude Code documentation as of August 2026. Marketplace names other than `claude-plugins-official`, and UI strings quoted above, are on the §O re-verify list.*
