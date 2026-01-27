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
| 5. Skills + Packaging | 20 min | `code-reviewer` skill + packaged plugin | ✅ Component 3 + Package |
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

> "A plugin needs a manifest that describes what it contains. This is the PLUGIN.md file."

Create the file from [5B: Plugin Manifest](Workshop-Technical-Reference.md#5b-plugin-manifest)

> "This documents your plugin — what's included, how to use it, and how to install it. Think of it as the README for your plugin."

**Have participants create the same file.**

---

### 5C: Package the Plugin

**⏱️ Time: 72:00 - 77:00 (5 min)**

#### 🎤 Transition

> "Now let's package everything into a distributable `.skill` file."

📎 **Reference:** [5C: Package Plugin](Workshop-Technical-Reference.md#5c-package-plugin)

Run the skill-creator packaging prompt.

> "The skill-creator validates our files, bundles them together, and creates a single `.skill` file we can share."

**Show the package contents:**

```bash
unzip -l codebase-toolkit.skill
```

> "Four files: our manifest, two subagents, and one skill. This is your complete plugin!"

**Have participants package their plugins.**

👀 **Watch for:**
- Missing files → Check file paths match exactly
- YAML errors → Common cause of validation failures
- Permission errors → May need to check directory permissions

---

### 5D: Test Plugin Installation

**⏱️ Time: 77:00 - 80:00 (3 min)**

#### 🎤 Transition

> "Let's verify the plugin works by doing a clean install. We'll remove the local components and install from the package."

📎 **Reference:** [5D: Test Plugin Installation](Workshop-Technical-Reference.md#5d-test-plugin-installation)

Run the uninstall, extract, and install commands.

> "And now let's verify:"

```
/code-reviewer

Briefly review src/cartservice.
```

> "It works! You've just installed your plugin from a package."

---

### 5E: GitHub Publishing

**⏱️ Time: 80:00 - 82:00 (2 min)**

#### 🎤 Transition

> "To share your plugin, you can push it to GitHub. Let me show you quickly."

📎 **Reference:** [5E: GitHub Publishing](Workshop-Technical-Reference.md#5e-github-publishing)

Show the git commands (demo only, don't wait for participants):

> "Others can then clone your repo and install the plugin. This is how you share plugins with your team."

---

### 5F: Marketplace Demo

**⏱️ Time: 82:00 - 85:00 (3 min)**

#### 🎤 Transition

> "Finally, let me show you some plugins already available in the marketplace."

📎 **Reference:** [5F: Marketplace Demo](Workshop-Technical-Reference.md#5f-marketplace-demo)

```bash
claude /plugins
```

**Highlight key plugins:**

> "**document-skills** creates Word docs, PowerPoints, spreadsheets, PDFs — all from Claude Code.
> **claude-md-management** helps maintain CLAUDE.md files.
> **code-review** provides professional code review workflows."

**Demo document-skills if available:**

> "Watch — I'll create a Word document for our wishlist feature."

> "These follow the same structure as what we just built. You could publish your plugin to the marketplace someday!"

---

## Wrap-up

**⏱️ Time: 85:00 - 90:00 (5 min)**

### 🎤 Summary Talk Track

> "Let's recap what we built today."

| Component | Type | What It Does |
|-----------|------|--------------|
| `service-documenter` | Subagent | Documents services in parallel |
| `bug-hunter` | Subagent | Debugs services in parallel |
| `code-reviewer` | Skill | Reviews code quality |
| MCP config | Infrastructure | Extends Claude's reach |
| `codebase-toolkit.skill` | Plugin | Packages everything for distribution |

> "Remember: each component works independently. The plugin is just a packaging mechanism. You can use `service-documenter` without the others, or add new components later."

### 🎤 Key Takeaways

> "Three things to remember:
> 
> 1. **Subagents** run in parallel with isolated context — use them for speed
> 2. **Skills** add knowledge to Claude — use them for specialized procedures
> 3. **Plugins** package components for sharing — use them for distribution"

### 🎤 Hackathon Prep

> "For the hackathon, you now have:
> - A complete toolkit for any codebase you encounter
> - The ability to create more subagents and skills
> - Understanding of how to package and share your work"

### 🎤 Closing

> "Any questions before we wrap up?"

**Pause for questions.**

> "Thank you all! The technical reference document has all the prompts, file contents, and troubleshooting tips if you need them later. Good luck at the hackathon!"

---

## Facilitator Troubleshooting Quick Reference

| Issue | Phase | Quick Fix |
|-------|-------|-----------|
| Setup incomplete | Pre | Pair with neighbor who's ready |
| Subagent not found | 1, 3 | Check `~/.claude/agents/` path and `.md` extension |
| Tasks run sequentially | 1, 3 | Add "run in parallel" to prompt |
| Rate limiting | 1, 3 | Reduce parallel count to 2 |
| MCP not connecting | 4 | Verify Node.js, check JSON syntax, restart Claude |
| Skill not found | 5 | Check `~/.claude/skills/[name]/SKILL.md` path |
| Packaging fails | 5 | Validate YAML frontmatter, check all files exist |
| Running behind | Any | See timing adjustments below |

### Timing Adjustments

| If behind by... | Skip or shorten... |
|-----------------|-------------------|
| 5 min | Skip Python test alternative in Phase 2 |
| 10 min | Demo MCP only in Phase 4, skip participant setup |
| 15 min | Skip parallel debugging demo in Phase 3, show bug-hunter only |
| 20+ min | Skip GitHub publishing and marketplace demo in Phase 5 |
