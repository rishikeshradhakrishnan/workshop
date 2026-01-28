# Claude Code Workshop - Facilitator Guide

**Duration:** 90 minutes | **Format:** Instructor-led, live coding  
**Companion Document:** [Technical Reference](Workshop-Technical-Reference.md)

---

## How to Use This Guide

This guide contains:
- ⏱️ **Timing cues** for each section
- 🎤 **Talk tracks** (scripted key moments + bullet points)
- 🔗 **Links** to technical content in the [Technical Reference](Workshop-Technical-Reference.md)
- ✅ **Checkpoints** to verify participant progress
- 👀 **Watch for** cues for audience engagement

---

## Workshop Overview

| Phase | Duration | Key Outcome | Plugin Component |
|-------|----------|-------------|------------------|
| 1. Documentation | 15 min | `service-documenter` subagent | ✅ Component 1 |
| 2. Test Generation | 15 min | Test generation experience | (standalone) |
| 3. Debugging | 15 min | `bug-hunter` subagent | ✅ Component 2 |
| 4. Development + MCP | 20 min | MCP configuration | (infrastructure) |
| 5. Skills + Packaging | 25 min | `code-reviewer` skill + marketplace plugin | ✅ Component 3 + Plugin |
| 6. Reusability Demo | 10 min | Use plugin on fresh codebase | Validation |
| Wrap-up | 5 min | Summary + Q&A | |

---

## Pre-Workshop (5 min before start)

### 🎤 Opening Talk Track

> "Welcome everyone! Today we're going to build a complete Claude Code plugin from scratch. By the end of these 90 minutes, you'll have a 'Codebase Toolkit' that helps you quickly understand and improve any new codebase you encounter."

> "This plugin will contain three components that we'll build throughout the workshop — two subagents for parallel processing and one skill for code review. Each component works independently, but together they form a powerful toolkit."

### ✅ Pre-Flight Check

Ask participants to confirm:
- [ ] Claude Code installed (`claude --version`)
- [ ] Repository cloned
- [ ] Terminal open in repo directory

👀 **Watch for:** Anyone struggling with setup — pair them with a neighbor

📎 **Reference:** [Pre-Workshop Setup](Workshop-Technical-Reference.md#pre-workshop-setup)

---

## Phase 1: Documentation & Analysis

**⏱️ Total Time: 15 minutes**

---

### 1A: Basic Documentation Demo

**⏱️ Time: 0:00 - 3:00 (3 min)**

#### 🎤 Transition Into Phase

> "Let's start by seeing how Claude Code can analyze an unfamiliar codebase. This OpenTelemetry demo has 14+ microservices written in different languages — Go, Python, TypeScript, C#, Ruby, and more. Let's see how quickly we can understand it."

#### 🎤 During Demo

Run the prompt from [1A: Basic Documentation Demo](Workshop-Technical-Reference.md#1a-basic-documentation-demo)

**While Claude works, explain:**

> "Notice how Claude is scanning the entire directory structure. It's identifying languages, finding configuration files, and understanding how services connect — all without us telling it anything about this codebase."

**When output appears:**

> "Look at that Mermaid diagram — it shows service relationships that would take us hours to map manually. And this is just sequential processing. What if we could make this even faster?"

---

### 1B: Plugin Directory Setup

**⏱️ Time: 3:00 - 4:00 (1 min)**

#### 🎤 Transition

> "Now, before we speed things up with parallel processing, let's set up our plugin structure. We're going to organize our components from the start so we can package them later."

Run the commands from [1B: Plugin Directory Setup](Workshop-Technical-Reference.md#1b-plugin-directory-setup)

> "This creates our plugin folder with separate directories for agents and skills. Think of this as scaffolding for what we'll build throughout the workshop."

**Ask participants to run the same commands.**

👀 **Watch for:** Participants in wrong directory — they should be in the repo root

---

### 1C: Service-Documenter Subagent

**⏱️ Time: 4:00 - 7:00 (3 min)**

#### 🎤 Transition

> "Now let's create our first plugin component — a subagent that specializes in documenting services. Subagents are separate Claude instances with their own context window. They can run in parallel, which dramatically speeds up tasks."

#### 🎤 Explaining Subagent Structure

Open/create the file from [1C: Service-Documenter Subagent](Workshop-Technical-Reference.md#1c-service-documenter-subagent)

> "Let me walk through this file:
> - The YAML frontmatter at the top defines metadata — name, description, and which tools it can use
> - The description is crucial — it tells Claude when to use this subagent
> - The markdown body contains the instructions the subagent follows"

> "We're saving this in our plugin folder, but we also need to copy it to the active agents directory for immediate use."

Run the installation command.

**Have participants create the same file.**

👀 **Watch for:** YAML syntax errors (missing `---` delimiters)

---

### 1D: Parallel Subagents Demo

**⏱️ Time: 7:00 - 10:00 (3 min)**

#### 🎤 Transition

> "Now for the magic — let's run multiple subagents in parallel. Instead of documenting services one by one, we'll have four subagents working simultaneously."

Run the prompt from [1D: Parallel Subagents Demo](Workshop-Technical-Reference.md#1d-parallel-subagents-demo)

#### 🎤 Key Moment — When Tasks Appear

> "Look! You can see `Task(Documenting Go services)`, `Task(Documenting Python services)` — they're all running at the same time. Each has its own context window, so they don't interfere with each other."

**Pause and let participants observe the parallel execution.**

> "This is what makes subagents powerful for large codebases. What would take 10 minutes sequentially now takes 2-3 minutes."

**When results combine:**

> "And now Claude is synthesizing all the findings into a single document. The subagents did the heavy lifting in parallel, and the main agent combines it."

---

### 1E: Participant Parallel Exercise

**⏱️ Time: 10:00 - 15:00 (5 min)**

#### 🎤 Transition

> "Your turn! Run the simpler version with 3 parallel tasks. Make sure you see the parallel `Task(...)` indicators."

📎 **Reference:** [1E: Participant Parallel Exercise](Workshop-Technical-Reference.md#1e-participant-parallel-exercise)

**Walk around the room while participants work.**

👀 **Watch for:**
- Tasks not starting → Check if subagent file was created correctly
- Rate limiting → Suggest reducing to 2 tasks
- Sequential execution → Participant may need to be more explicit ("run in parallel")

#### ✅ Checkpoint

> "Quick check: Raise your hand if you saw multiple `Task(...)` running at the same time."

> "Great! You now have your first plugin component — `service-documenter`. That's 1 of 3. Let's move on."

---

## Phase 2: Test Generation

**⏱️ Total Time: 15 minutes**

---

### 2A: Test Generation Demo

**⏱️ Time: 15:00 - 20:00 (5 min)**

#### 🎤 Transition Into Phase

> "Phase 2 is about test generation. This is a standalone demonstration — we won't add it to our plugin, but it shows another powerful Claude Code capability."

> "Claude doesn't just generate generic tests — it understands language-specific conventions. Let me show you with Go."

Run the prompt from [2A: Go Test Demo](Workshop-Technical-Reference.md#2a-go-test-demo)

#### 🎤 During Demo

> "Notice it's using table-driven tests — that's the Go idiom. It's naming the file with `_test.go`. It's identifying which services need to be mocked. These aren't template tests; they're idiomatic to the language."

**Optional:** Show Python alternative from [2B: Python Test Alternative](Workshop-Technical-Reference.md#2b-python-test-alternative)

> "Same thing works for pytest — it uses fixtures, follows Python conventions."

---

### 2B: Participant Test Exercise

**⏱️ Time: 20:00 - 30:00 (10 min)**

#### 🎤 Transition

> "Your turn. Pick a service in your preferred language and generate tests. The reference has prompts for Python, Go, TypeScript, and C#."

📎 **Reference:** [2C: Participant Test Exercises](Workshop-Technical-Reference.md#2c-participant-test-exercises)

👀 **Watch for:**
- Participants unsure which service → Suggest `recommendationservice` (Python) or `productcatalogservice` (Go)
- Tests don't run → That's OK, focus is on generation quality

#### ✅ Checkpoint

> "Did everyone get a test file generated? Notice how the tests match the language conventions — that's Claude understanding context, not just templating."

---

## Phase 3: Debugging & QA

**⏱️ Total Time: 15 minutes**

---

### 3A: Single-Service Debug Demo

**⏱️ Time: 30:00 - 33:00 (3 min)**

#### 🎤 Transition Into Phase

> "Now let's talk about debugging. In production, you often need to investigate issues quickly. Claude Code can trace through code paths and identify problems."

> "First, let me show single-service debugging."

Run prompt from [3A: Single-Service Debug Demo](Workshop-Technical-Reference.md#3a-single-service-debug-demo)

> "Claude is checking error handling paths, looking for unhandled exceptions, identifying edge cases. This is like having a senior developer review the code."

---

### 3B: Bug-Hunter Subagent Creation

**⏱️ Time: 33:00 - 36:00 (3 min)**

#### 🎤 Transition

> "Now let's add our second plugin component — a debugging specialist subagent. This follows the same pattern as service-documenter."

Create the file from [3B: Bug-Hunter Subagent](Workshop-Technical-Reference.md#3b-bug-hunter-subagent)

> "Notice the output format with severity levels — 🔴 Critical, 🟡 Warning, 🟢 Info. This standardizes how we report findings across any service."

Run the installation command.

**Have participants create the same file.**

---

### 3C: Parallel Debugging Demo

**⏱️ Time: 36:00 - 40:00 (4 min)**

#### 🎤 Transition

> "Here's where it gets powerful. In a real incident, you often don't know which service is the problem. Let's investigate the entire checkout flow in parallel."

Run the prompt from [3C: Parallel Debugging Demo](Workshop-Technical-Reference.md#3c-parallel-debugging-demo)

#### 🎤 Key Moment

> "This mimics real incident response. Instead of checking services one by one, we have four investigators working simultaneously. The main agent then prioritizes findings across all services."

> "Imagine doing this at 3 AM during an outage — you'd have comprehensive analysis in minutes instead of hours."

---

### 3D: Participant Debug Exercise

**⏱️ Time: 40:00 - 45:00 (5 min)**

#### 🎤 Transition

> "Your turn. Run the parallel debugging exercise and see what issues you find."

📎 **Reference:** [3D: Participant Debug Exercise](Workshop-Technical-Reference.md#3d-participant-debug-exercise)

👀 **Watch for:**
- No issues found → That's actually fine; code quality may be good
- Too many findings → Point out severity prioritization

#### ✅ Checkpoint

> "You now have both subagents — `service-documenter` and `bug-hunter`. That's 2 of 3 components for our plugin. One more to go!"

---

## Phase 4: Development + MCP

**⏱️ Total Time: 20 minutes**

---

### 4A: Feature Development Demo

**⏱️ Time: 45:00 - 53:00 (8 min)**

#### 🎤 Transition Into Phase

> "Phase 4 covers feature development and introduces MCP servers. Let's start with building a feature."

Run the prompt from [4A: Feature Development Demo](Workshop-Technical-Reference.md#4a-feature-development-demo)

#### 🎤 During Demo

> "Notice Claude asks clarifying questions or presents a plan first. It then maintains consistency with existing patterns — same naming conventions, same error handling style, same file structure."

**Highlight multi-file coordination:**

> "It's updating proto files, service code, and frontend — all coordinated. This is where Claude Code really shines for development work."

---

### 4B: MCP Introduction

**⏱️ Time: 53:00 - 56:00 (3 min)**

#### 🎤 Transition

> "Now let's extend Claude's capabilities with MCP — Model Context Protocol. MCP servers let Claude interact with external tools: filesystems, browsers, APIs, and more."

> "This isn't part of our plugin, but it's infrastructure that complements what we're building."

📎 **Reference:** [4B: MCP Configuration](Workshop-Technical-Reference.md#4b-mcp-configuration)

**Show the settings.json file:**

> "MCP servers are configured in settings.json. Let me explain the three we'll set up:
> - **Filesystem** — Safe file operations, even outside the repo
> - **GitHub** — Create PRs, read issues, interact with repos
> - **Playwright** — Browser automation, screenshots, UI testing"

---

### 4C: MCP Demo

**⏱️ Time: 56:00 - 60:00 (4 min)**

#### 🎤 Demo MCP in Action

Run prompts from [4C: MCP Demo Prompts](Workshop-Technical-Reference.md#4c-mcp-demo-prompts)

**For Playwright (if demo app is running):**

> "Watch — Claude is actually controlling a browser. It's taking screenshots, clicking elements, reporting what it sees. This is powerful for UI testing."

**For GitHub:**

> "It's reading real issues from the repo. You could combine this with our bug-hunter subagent to investigate reported issues automatically."

---

### 4D: Participant MCP Setup

**⏱️ Time: 60:00 - 65:00 (5 min)**

#### 🎤 Transition

> "Let's get everyone set up with at least the Filesystem MCP. This is the simplest one — just requires Node.js."

📎 **Reference:** [4D: Participant MCP Setup](Workshop-Technical-Reference.md#4d-participant-mcp-setup)

Walk participants through:
1. Creating/editing settings.json
2. Restarting Claude Code
3. Testing with a filesystem command

👀 **Watch for:**
- JSON syntax errors → Common issue, help validate
- Node.js not installed → They can skip MCP, continue with workshop
- "MCP not found" → Check file path, restart Claude Code

#### ✅ Checkpoint

> "Quick check: Who got the filesystem MCP working? Great!"

> "MCP servers are optional but powerful. You can add more later from the technical reference."

---

## Phase 5: Skills, Packaging & Marketplace

**⏱️ Total Time: 20 minutes**

---

### 5A: Code-Reviewer Skill Creation

**⏱️ Time: 65:00 - 70:00 (5 min)**

#### 🎤 Transition Into Phase

> "Final phase! We're going to add our third component — a skill — and then package everything into a distributable plugin."

> "Skills are different from subagents. Subagents are parallel workers with their own context. Skills add knowledge and procedures to the main Claude instance."

Create the file from [5A: Code-Reviewer Skill](Workshop-Technical-Reference.md#5a-code-reviewer-skill)

> "The structure is similar — YAML frontmatter with name and description, then markdown instructions. But skills go in the `skills/` directory, not `agents/`."

Run the installation and test:

```
/code-reviewer

Review src/paymentservice for code quality issues.
```

> "See? We invoke skills with `/skill-name`. They run in the main context, not as separate agents."

**Have participants create the same skill.**

#### ✅ Checkpoint

> "You now have all three components! Let's package them into a plugin."

---

### 5B: Plugin Manifest

**⏱️ Time: 70:00 - 72:00 (2 min)**

#### 🎤 Transition

> "Now let's make this an official plugin. Every plugin needs a manifest — a `plugin.json` file inside a `.claude-plugin` folder."

📎 **Reference:** [5B: Plugin Manifest (plugin.json)](Workshop-Technical-Reference.md#5b-plugin-manifest-pluginjson)

Create the directory and file.

> "This tells Claude Code what your plugin is called, what it does, and who made it. It's the metadata that makes your plugin installable."

**Have participants create the same manifest.**

---

### 5C: Verify Plugin Structure

**⏱️ Time: 72:00 - 73:00 (1 min)**

#### 🎤 Transition

> "Let's verify our plugin structure is complete before we create a marketplace."

📎 **Reference:** [5C: Complete Plugin Structure](Workshop-Technical-Reference.md#5c-complete-plugin-structure)

Show the expected structure:

```
.claude/plugins/codebase-toolkit/
├── .claude-plugin/
│   └── plugin.json              # ← We just created this
├── agents/
│   ├── service-documenter.md    # ← Created in Phase 1
│   └── bug-hunter.md            # ← Created in Phase 3
└── skills/
    └── code-reviewer/
        └── SKILL.md             # ← Created in Phase 5A
```

> "Everyone should have these four files. Quick check — raise your hand if anything is missing."

👀 **Watch for:** Missing `.claude-plugin/plugin.json` — most common issue

---

### 5D: Create Local Test Marketplace

**⏱️ Time: 73:00 - 76:00 (3 min)**

#### 🎤 Transition

> "To install a plugin, you need a marketplace. A marketplace is just a folder with a JSON file that lists available plugins. Let's create one locally to test."

📎 **Reference:** [5D: Create Local Test Marketplace](Workshop-Technical-Reference.md#5d-create-local-test-marketplace)

> "We'll create this as a sibling folder to the demo repo — not inside it."

Run the commands to create the marketplace structure and manifest.

> "The key is the `source` field — it points to where our plugin lives. Right now it's a relative path to our local plugin folder."

**Have participants create the same marketplace.**

👀 **Watch for:** 
- JSON syntax errors in marketplace.json
- Incorrect relative path in `source` field

---

### 5E: Install and Test Plugin

**⏱️ Time: 76:00 - 80:00 (4 min)**

#### 🎤 Transition

> "Now the moment of truth — let's install our plugin from the marketplace using the official plugin commands."

📎 **Reference:** [5E: Install and Test Plugin Locally](Workshop-Technical-Reference.md#5e-install-and-test-plugin-locally)

**Step 1: Clean up manually installed files**

> "First, let's remove the files we copied manually earlier. The plugin should provide everything."

Run the rm commands.

**Step 2: Add marketplace**

```
/plugin marketplace add ../test-marketplace
```

> "This tells Claude Code where to find plugins."

**Step 3: Install plugin**

```
/plugin install codebase-toolkit@test-marketplace
```

> "Select 'Install now' when prompted, then restart Claude Code."

**Step 4: Restart and verify**

```
/code-reviewer

Briefly review src/cartservice
```

> "It works! We just installed our plugin through the official plugin system."

👀 **Watch for:**
- "Invalid schema" error → Check the `source` path in marketplace.json
- Plugin not found after install → Restart Claude Code

---

### 5F: Publish to GitHub Marketplace

**⏱️ Time: 80:00 - 85:00 (5 min)**

#### 🎤 Transition

> "Local testing works. Now let's publish this so anyone can use it. I've set up a GitHub repository that will serve as our marketplace."

📎 **Reference:** [5F: Publish to GitHub Marketplace](Workshop-Technical-Reference.md#5f-publish-to-github-marketplace)

**Demo the process (instructor only):**

1. Show the marketplace repo structure
2. Copy the plugin into `plugins/` directory
3. Create the marketplace.json with the proper source path
4. Commit and push

> "The structure is the same as our local marketplace, but now it's on GitHub where anyone can access it."

**Add the GitHub marketplace:**

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

> "Now anyone in the world can install our plugin with that one command."

---

### 5G: Browse Existing Marketplaces

**⏱️ Time: 85:00 - 88:00 (3 min)**

#### 🎤 Transition

> "Let me show you what other marketplaces look like. Anthropic maintains an official demo marketplace."

📎 **Reference:** [5G: Browse Existing Marketplaces](Workshop-Technical-Reference.md#5g-browse-existing-marketplaces)

```
/plugin marketplace add anthropics/claude-code
```

```
/plugin
```

> "Select 'Browse Plugins' to see what's available. These are example plugins that demonstrate different capabilities."

```
/plugin marketplace list
```

> "You can see all marketplaces now — Anthropic's demos, our workshop marketplace, and the local test one. The plugin ecosystem is designed to be distributed like this."

#### ✅ Checkpoint

> "Congratulations! You've built a complete plugin, tested it locally, and we've published it to a GitHub marketplace. Let's prove it works on a completely fresh codebase."

---

## Add Phase 6:

## Phase 6: Reusability Demo

**⏱️ Total Time: 10 minutes**

---

### 6A: Clone Fresh Repository

**⏱️ Time: 88:00 - 90:00 (2 min)**

#### 🎤 Transition Into Phase

> "The whole point of packaging this as a plugin is reusability. Let's prove it works by using it on a completely fresh codebase — one we haven't touched at all."

📎 **Reference:** [6A: Clone Fresh Repository](Workshop-Technical-Reference.md#6a-clone-fresh-repository)

```bash
cd ~
mkdir plugin-demo
cd plugin-demo
git clone https://github.com/open-telemetry/opentelemetry-demo.git
cd opentelemetry-demo
```

> "This is the original OpenTelemetry demo from the official repo — no modifications, completely fresh."

---

### 6B: Install Plugin from Marketplace

**⏱️ Time: 90:00 - 93:00 (3 min)**

#### 🎤 Transition

> "Now watch how easy it is to add our plugin to this new project."

📎 **Reference:** [6B: Install Plugin from Marketplace](Workshop-Technical-Reference.md#6b-install-plugin-from-marketplace)

```bash
claude
```

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

```
/plugin install codebase-toolkit@rishikesh-marketplace
```

> "One marketplace add, one install command. That's it. Restart Claude Code and we're ready."

---

### 6C: Use Plugin on New Codebase

**⏱️ Time: 93:00 - 98:00 (5 min)**

#### 🎤 Transition

> "Let's use our plugin on this fresh codebase. Pick whichever component you want to try."

📎 **Reference:** [6C: Use Plugin on New Codebase](Workshop-Technical-Reference.md#6c-use-plugin-on-new-codebase)

**Demo one or more:**

```
/code-reviewer

Review the src/frontend directory for code quality issues.
```

Or:

```
Use 3 bug-hunter subagents in parallel to investigate:
- src/cartservice
- src/productcatalogservice  
- src/recommendationservice

Compile findings into a prioritized report.
```

#### 🎤 Key Point

> "This is the power of plugins:
> - You built it once
> - Published it to a marketplace
> - Now it works on any codebase
> - Your team can install it with a single command
> - Updates are as simple as pulling from the marketplace"

👀 **Watch for:** Participants who want to try their own prompts — encourage this!

---

## Replace Wrap-up section with:

## Wrap-up

**⏱️ Time: 98:00 - 105:00 (5-7 min)**

### 🎤 Summary Talk Track

> "Let's recap what we built today."

| Component | Type | Where It Lives |
|-----------|------|----------------|
| `service-documenter` | Subagent | `agents/` |
| `bug-hunter` | Subagent | `agents/` |
| `code-reviewer` | Skill | `skills/` |
| `plugin.json` | Manifest | `.claude-plugin/` |

> "We packaged these into a plugin, created a marketplace, published to GitHub, and proved it works on a fresh codebase."

### 🎤 Key Takeaways

> "Four things to remember:
> 
> 1. **Subagents** run in parallel with isolated context — use them for speed
> 2. **Skills** add knowledge to Claude — use them for specialized procedures
> 3. **Plugins** package your components — defined by `.claude-plugin/plugin.json`
> 4. **Marketplaces** make sharing trivial — one command to install"

### 🎤 Hackathon Prep

> "For the hackathon, you now have:
> - A working plugin you can extend
> - A marketplace you can add more plugins to
> - Understanding of how to create and share components
> - The ability to install your plugin on any project instantly"

### 🎤 Closing

> "Any questions before we wrap up?"

**Pause for questions.**

> "Thank you all! The technical reference document has all the file contents, commands, and troubleshooting tips. Good luck at the hackathon!"

---

## Replace Troubleshooting Quick Reference with:

## Facilitator Troubleshooting Quick Reference

| Issue | Phase | Quick Fix |
|-------|-------|-----------|
| Setup incomplete | Pre | Pair with neighbor who's ready |
| Subagent not found | 1, 3 | Verify file in `agents/` with `.md` extension |
| Tasks run sequentially | 1, 3 | Add "run in parallel" to prompt |
| Rate limiting | 1, 3 | Reduce parallel count to 2 |
| MCP not connecting | 4 | Verify Node.js, check JSON syntax, restart Claude |
| Skill not found | 5 | Verify `SKILL.md` in `skills/[name]/` directory |
| Plugin manifest missing | 5 | Check `.claude-plugin/plugin.json` exists |
| "Invalid schema" error | 5 | Check `source` path in marketplace.json |
| Marketplace not found | 5 | Verify path, check JSON syntax |
| Plugin not available after install | 5, 6 | Restart Claude Code |
| Running behind | Any | See timing adjustments below |

### Timing Adjustments

| If behind by... | Skip or shorten... |
|-----------------|-------------------|
| 5 min | Skip Python test alternative in Phase 2 |
| 10 min | Demo MCP only in Phase 4, skip participant setup |
| 15 min | Skip parallel debugging demo in Phase 3 |
| 20+ min | Skip Phase 6, just describe what it would show |
| 25+ min | Skip 5G (browse marketplaces), demo GitHub publish only |
