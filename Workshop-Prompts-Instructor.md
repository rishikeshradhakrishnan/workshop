# Claude Code Workshop - Instructor Guide

**Duration:** 90 minutes | **Format:** Instructor-led, live coding  
**Repo:** [opentelemetry-demo](https://github.com/rishikeshradhakrishnan/opentelemery-demo)

---

## Workshop Goal

By the end of this workshop, participants will have built a complete **"Codebase Toolkit" plugin** containing:
- 2 custom subagents (service-documenter, bug-hunter)
- 1 custom skill (code-reviewer)
- MCP server integration experience

Each component works independently, but together they form a distributable plugin that accelerates onboarding to any new codebase.

---

## Pre-Workshop Checklist

Ensure participants have:
- Claude Code installed and authenticated (`claude --version`)
- Repository cloned: `git clone https://github.com/rishikeshradhakrishnan/opentelemery-demo.git`
- Terminal/IDE ready with repo open
- Node.js installed (for Playwright MCP in Phase 4)

---

## Phase 1: Documentation & Analysis (15 min)

**Objective:** Create the `service-documenter` subagent — the first component of our plugin

---

### 👨‍🏫 Instructor Demo Part A: Basic Documentation (3 min)

Navigate to the repo and start Claude Code:

```bash
cd opentelemetry-demo
claude
```

**Demo Prompt:**

```
Analyze the architecture of this application.
Create a README.md that includes:
- High-level architecture diagram (mermaid)
- List of all services with their primary language
- How services communicate with each other
- Quick start instructions for local development
```

**Talking Points:**

- Claude Code scans the entire directory structure automatically
- It identifies the polyglot nature without being told
- Point out how long this takes for a single-threaded approach
- *"What if we could make this faster and reusable?"*

---

### 👨‍🏫 Instructor Demo Part B: Creating the `service-documenter` Subagent (5 min)

**Frame the plugin goal:**
> "We're going to build a 'Codebase Toolkit' plugin throughout this workshop. Our first component is a subagent that documents services. We'll package everything together in Phase 5."

**Step 1: Create a project plugin directory**

```bash
mkdir -p .claude/plugins/codebase-toolkit/agents
mkdir -p .claude/plugins/codebase-toolkit/skills
```

> "We're organizing everything in a plugin folder structure from the start. Agents and skills can exist independently in `~/.claude/`, but we're putting them here so we can package them together later."

**Step 2: Create the `service-documenter` subagent**

Create `.claude/plugins/codebase-toolkit/agents/service-documenter.md`:

```markdown
---
name: service-documenter
description: Documents a single microservice. Use when analyzing individual services for documentation purposes.
tools: Read, Grep, Glob
model: sonnet
---

You are a technical documentation specialist. When given a service directory:

1. Identify the primary language and framework
2. Find the main entry point
3. List key functions/endpoints
4. Identify dependencies on other services
5. Note any configuration files

Output a concise markdown summary with:
- **Service name** and language
- **Purpose** (1-2 sentences)
- **Key endpoints/functions** (bullet list)
- **Dependencies** (other services it calls)
- **Configuration** options
```

**Step 3: Also install it locally for immediate use**

```bash
mkdir -p .claude/agents
cp .claude/plugins/codebase-toolkit/agents/service-documenter.md .claude/agents/
```

**Step 4: Use parallel subagents**

```
Document this codebase using 4 parallel subagents.
Assign each subagent to a different group:

Subagent 1: Go services (checkoutservice, productcatalogservice)
Subagent 2: Python services (recommendationservice, loadgenerator)  
Subagent 3: Frontend services (frontend in TypeScript, paymentservice in JS)
Subagent 4: .NET services (cartservice, accountingservice)

Each subagent should use the service-documenter approach.
Then combine all findings into a comprehensive ARCHITECTURE.md
```

**Talking Points:**

- Show the `Task(...)` indicators appearing in parallel
- Each subagent has isolated context
- Point out speed difference vs sequential
- *"This subagent is now saved for our plugin. Let's move on and add more components."*

---

### 👨‍🏫 Guided Follow-Along (7 min)

Have participants:

1. Create the plugin directory structure
2. Create their own `service-documenter.md`
3. Run the parallel documentation prompt

**Prompt for participants:**

```
Explore this codebase using 3 parallel tasks:

Task 1: Analyze the frontend layer (src/frontend)
Task 2: Analyze the backend services (src/checkoutservice, src/cartservice)
Task 3: Analyze the data/infrastructure layer (docker-compose.yml, kubernetes/)

Each task should report:
- What components exist
- Key technologies used
- How they connect to other parts

Synthesize findings into a summary.
```

**Checkpoint:** *"Everyone should now have a `service-documenter.md` in their plugin folder. This is component 1 of 3."*

---

## Phase 2: Test Generation (15 min)

**Objective:** Generate tests (standalone phase — demonstrates Claude Code's testing capabilities)

---

### 👨‍🏫 Instructor Demo (5 min)

**Transition:**
> "Now let's see Claude Code's test generation. This phase is standalone — we won't add it to our plugin, but it shows another key capability."

**Demo Prompt:**

```
Look at src/checkoutservice (Go) and generate a test suite:
- Unit tests for the main order placement logic
- Mock any external service calls
- Use table-driven tests following Go conventions
- Cover both success and error scenarios
```

**Talking Points:**

- Claude recognizes Go conventions (table-driven tests, `_test.go` naming)
- It identifies which dependencies need mocking
- Tests are idiomatic — not generic templates
- Show the generated test file structure

**Alternative Demo (Python):**

```
Generate pytest tests for src/recommendationservice/recommendation_server.py
Include fixtures for the product catalog dependency
```

---

### 👨‍🏫 Participant Exercise (10 min)

Participants choose a service and generate tests in their preferred language.

---

## Phase 3: Debugging & QA (15 min)

**Objective:** Create the `bug-hunter` subagent — the second component of our plugin

---

### 👨‍🏫 Instructor Demo Part A: Single-Service Debugging (3 min)

**Demo Prompt:**

```
Users are reporting random payment failures.
Analyze src/paymentservice to find potential issues.
Check for error handling gaps, race conditions, and edge cases.
```

---

### 👨‍🏫 Instructor Demo Part B: Creating the `bug-hunter` Subagent (5 min)

**Frame the plugin addition:**
> "Let's add our second subagent to the plugin — a debugging specialist that can investigate services in parallel."

**Create the `bug-hunter` subagent:**

Create `.claude/plugins/codebase-toolkit/agents/bug-hunter.md`:

```markdown
---
name: bug-hunter
description: Investigates a service for bugs, error handling gaps, and potential issues. Use when debugging or auditing code quality.
tools: Read, Grep, Glob
model: sonnet
---

You are a debugging specialist. When investigating a service:

1. Check all error handling paths
2. Look for unhandled exceptions
3. Identify potential race conditions
4. Find timeout/retry issues
5. Check for null/undefined handling

Report findings as:
- 🔴 **Critical:** [issue + file:line] - must fix immediately
- 🟡 **Warning:** [issue + file:line] - should address
- 🟢 **Info:** [observation] - minor improvement

Always include specific file paths and line numbers.
Suggest a fix for each critical and warning issue.
```

**Install locally:**

```bash
cp .claude/plugins/codebase-toolkit/agents/bug-hunter.md .claude/agents/
```

**Run parallel debugging:**

```
Debug the checkout flow using 4 parallel subagents:

Subagent 1: Investigate src/frontend for client-side error handling
Subagent 2: Investigate src/checkoutservice for orchestration issues
Subagent 3: Investigate src/paymentservice for payment processing bugs
Subagent 4: Investigate src/cartservice for data consistency issues

Use the bug-hunter approach for each.
Compile all findings into a prioritized bug report.
```

**Talking Points:**

- This mimics real incident response
- Each subagent focuses deeply on one service
- Results are synthesized across services
- *"That's component 2 of 3 for our plugin!"*

---

### 👨‍🏫 Guided Follow-Along (7 min)

Have participants:

1. Create their `bug-hunter.md` in the plugin folder
2. Copy to `.claude/agents/` for immediate use
3. Run the parallel debugging prompt

**Prompt for participants:**

```
Analyze 3 services in parallel for potential issues:

Task 1: Check src/productcatalogservice for performance issues
Task 2: Check src/recommendationservice for error handling gaps
Task 3: Check src/cartservice for data validation issues

For each, report:
- Specific code locations with issues
- Severity (critical/warning/info)
- Suggested fix

Combine into a single report ordered by severity.
```

**Checkpoint:** *"You now have 2 subagents in your plugin folder: `service-documenter` and `bug-hunter`. One more component to go!"*

---

## Phase 4: Core Development + MCP Integration (20 min)

**Objective:** Build features and introduce MCP servers for extended capabilities

---

### 👨‍🏫 Instructor Demo Part A: Feature Development (8 min)

**Feature Addition Prompt:**

```
Add a "wishlist" feature to this application:
1. Users can save products for later
2. Store wishlist data using the existing cart service patterns
3. Add API endpoints to the frontend service
4. Follow the existing code patterns in this repo

First show me your implementation plan, then build it.
```

**Talking Points:**

- Claude maintains consistency with existing patterns
- Demonstrates coordinated changes across multiple files
- Point out how it reuses existing infrastructure

---

### 👨‍🏫 Instructor Demo Part B: MCP Server Introduction (7 min)

**Transition:**
> "Claude Code can connect to external tools via MCP (Model Context Protocol) servers. Let's add some to extend our capabilities."

**Show MCP configuration:**

Create/edit `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "/path/to/allowed/directory"]
    },
    "github": {
      "command": "npx", 
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-playwright"]
    }
  }
}
```

**Explain each MCP server:**

| MCP Server | Purpose | Use Case |
|------------|---------|----------|
| **Filesystem** | Safe file operations | Read/write outside repo |
| **GitHub** | Repo operations | Create PRs, issues, read repos |
| **Playwright** | Browser automation | Test UIs, scrape docs |

**Demo with Playwright MCP:**

```
Use Playwright to:
1. Open the demo application at http://localhost:8080
2. Take a screenshot of the homepage
3. Click on a product and capture that page too
4. Report what UI elements are visible
```

**Demo with GitHub MCP:**

```
Use the GitHub MCP to:
1. List the open issues in this repository
2. Summarize what bugs or features are requested
3. Suggest which our bug-hunter subagent could help investigate
```

**Talking Points:**

- MCP servers extend Claude's reach beyond the local filesystem
- They're configured once and available to all sessions
- Subagents and skills can leverage MCP tools
- *"MCP servers are separate from plugins but complement them well"*

---

### 👨‍🏫 Guided Follow-Along: Participants Configure MCP (5 min)

Have participants add at least the Filesystem MCP:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "."]
    }
  }
}
```

**Verify it works:**

```
List all files in the current directory using the filesystem MCP
```

**Checkpoint:** *"MCP servers are now available. These work alongside your plugin components."*

---

## Phase 5: Skill Building, Plugin Packaging & Marketplace (20 min)

**Objective:** Create the `code-reviewer` skill, package the complete plugin, and explore marketplace

---

### Part A: Create the `code-reviewer` Skill (5 min)

**Frame the final component:**
> "Let's add our third and final component — a skill that reviews code quality. Then we'll package everything together."

**Create the skill:**

Create `.claude/plugins/codebase-toolkit/skills/code-reviewer/SKILL.md`:

```markdown
---
name: code-reviewer
description: Review code for quality, patterns, and potential issues. Use when reviewing PRs, auditing code quality, or preparing for code review.
---

# Code Review Skill

When reviewing code, analyze for:

## Code Quality
- Clear naming conventions
- Appropriate function/method length
- Single responsibility principle
- DRY (Don't Repeat Yourself) violations

## Error Handling
- All error paths handled
- Meaningful error messages
- No swallowed exceptions
- Proper cleanup in error cases

## Performance
- Unnecessary allocations
- N+1 query patterns
- Missing caching opportunities
- Inefficient algorithms

## Security Basics
- Input validation present
- No hardcoded secrets
- Proper authentication checks

## Output Format
Provide findings as:
- 🔴 **Critical** - Must fix before merge
- 🟡 **Warning** - Should address
- 🟢 **Suggestion** - Nice to have

Include file paths and line numbers for each finding.
```

**Install locally and test:**

```bash
mkdir -p ~/.claude/skills/code-reviewer
cp .claude/plugins/codebase-toolkit/skills/code-reviewer/SKILL.md ~/.claude/skills/code-reviewer/
```

```
/code-reviewer

Review src/cartservice for code quality issues.
```

**Checkpoint:** *"All three components are ready! Let's package them into a plugin."*

---

### Part B: Package the Plugin (8 min)

**Show the complete plugin structure:**

```
.claude/plugins/codebase-toolkit/
├── PLUGIN.md                          # Plugin metadata
├── agents/
│   ├── service-documenter.md          # Component 1
│   └── bug-hunter.md                  # Component 2
└── skills/
    └── code-reviewer/
        └── SKILL.md                   # Component 3
```

**Create the plugin manifest:**

Create `.claude/plugins/codebase-toolkit/PLUGIN.md`:

```markdown
---
name: codebase-toolkit
version: 1.0.0
description: A toolkit for onboarding to new codebases. Includes parallel documentation generation, automated bug hunting, and code review capabilities.
author: Workshop Participant
---

# Codebase Toolkit Plugin

This plugin helps developers quickly understand and improve unfamiliar codebases.

## Components

### Subagents

1. **service-documenter** - Analyzes and documents microservices in parallel
2. **bug-hunter** - Investigates services for bugs and code quality issues

### Skills

1. **code-reviewer** - Comprehensive code review following best practices

## Usage

After installing, use these components:

```
# Document a codebase with parallel subagents
Document this repo using 4 parallel service-documenter subagents

# Hunt for bugs across services
Debug these services using bug-hunter subagents in parallel

# Review code quality
/code-reviewer
Review src/myservice for issues
```

## Installation

1. Extract to `~/.claude/plugins/codebase-toolkit/`
2. Copy agents to `~/.claude/agents/`
3. Copy skills to `~/.claude/skills/`
```

**Package using skill-creator:**

```
/skill-creator

Package the codebase-toolkit plugin located at .claude/plugins/codebase-toolkit/
Include:
- The PLUGIN.md manifest
- Both subagents (service-documenter, bug-hunter)
- The code-reviewer skill

Create a distributable .skill file with validation.
```

**Validate the package:**

```bash
# Check the generated file
ls -la codebase-toolkit.skill

# View contents
unzip -l codebase-toolkit.skill
```

---

### Part C: Test the Plugin (3 min)

**Uninstall local components:**

```bash
rm -rf ~/.claude/agents/service-documenter.md
rm -rf ~/.claude/agents/bug-hunter.md
rm -rf ~/.claude/skills/code-reviewer
```

**Install from packaged plugin:**

```bash
# Extract plugin
unzip codebase-toolkit.skill -d ~/.claude/plugins/codebase-toolkit-installed/

# Copy components to active locations
cp ~/.claude/plugins/codebase-toolkit-installed/agents/* ~/.claude/agents/
cp -r ~/.claude/plugins/codebase-toolkit-installed/skills/* ~/.claude/skills/
```

**Verify everything works:**

```
/code-reviewer
Review src/paymentservice briefly.
```

---

### Part D: Share via GitHub (2 min)

**Show the GitHub publishing flow:**

```bash
# Create a repo for your plugin
cd .claude/plugins/codebase-toolkit
git init
git add .
git commit -m "Initial release of codebase-toolkit plugin"

# Push to GitHub
gh repo create my-codebase-toolkit --public --source=. --push
```

**Share the install command:**

```bash
# Others can install via:
git clone https://github.com/yourusername/my-codebase-toolkit ~/.claude/plugins/codebase-toolkit
```

---

### Part E: Marketplace Plugins Demo (2 min)

**Show available marketplace plugins:**

```bash
claude /plugins
```

**Highlight key plugins:**

| Plugin | Purpose |
|--------|---------|
| **document-skills** | Create DOCX, PPTX, XLSX, PDF files |
| **claude-md-management** | Manage CLAUDE.md files |
| **claude-code-setup** | Bootstrap new projects |
| **code-review** | Professional code review workflows |

**Demo one plugin:**

```
Use the document skills to create a DOCX specification 
for the wishlist feature we built earlier.
Include requirements, API design, and implementation notes.
```

**Talking Points:**

- Marketplace plugins extend capabilities significantly
- They follow the same structure as what we just built
- Participants can publish their plugins to share with teams

---

## Wrap-up (5 min)

### What We Built

| Phase | Component | Location |
|-------|-----------|----------|
| Phase 1 | `service-documenter` subagent | `agents/` |
| Phase 3 | `bug-hunter` subagent | `agents/` |
| Phase 4 | MCP configuration | `settings.json` |
| Phase 5 | `code-reviewer` skill | `skills/` |
| Phase 5 | `codebase-toolkit` plugin | `.skill` file |

### Quick Reference Card

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `/skills` | List available skills |
| `/plugins` | List installed plugins |
| `/code-reviewer` | Invoke our skill |
| `claude --mcp` | Show MCP status |

### Component Independence

> "Remember: subagents, skills, and MCP servers all work independently. The plugin is just a packaging mechanism that bundles them for easy distribution. You can use any component on its own."

### Hackathon Prep

Participants leave with:
- ✅ Complete `codebase-toolkit` plugin
- ✅ Experience with parallel subagents
- ✅ MCP server configuration
- ✅ Understanding of plugin packaging and distribution

---

## Facilitator Notes

### Timing Adjustments

| If running behind... | Do this |
|---------------------|---------|
| Phase 1 slow | Skip parallel demo, just show subagent creation |
| Phase 3 slow | Skip parallel debugging, show bug-hunter only |
| Phase 4 slow | Demo MCP only, skip participant config |
| Phase 5 slow | Skip GitHub publishing, just show packaging |

### Common Issues

| Issue | Solution |
|-------|----------|
| MCP not connecting | Check Node.js installed, verify paths |
| Plugin packaging fails | Ensure all files exist, check YAML frontmatter |
| Subagents not found | Verify copied to `~/.claude/agents/` |
| Rate limiting | Reduce parallel tasks from 4 to 2 |

### Plugin Directory Cheat Sheet

```
Final structure participants should have:

.claude/plugins/codebase-toolkit/
├── PLUGIN.md
├── agents/
│   ├── service-documenter.md
│   └── bug-hunter.md
└── skills/
    └── code-reviewer/
        └── SKILL.md

~/.claude/
├── agents/
│   ├── service-documenter.md  (copied)
│   └── bug-hunter.md          (copied)
├── skills/
│   └── code-reviewer/
│       └── SKILL.md           (copied)
└── settings.json              (MCP config)
```
