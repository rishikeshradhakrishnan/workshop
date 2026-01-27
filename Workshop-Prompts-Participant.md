# Claude Code Workshop - Participant Guide

**Duration:** 90 minutes  
**Repo:** [opentelemetry-demo](https://github.com/rishikeshradhakrishnan/opentelemery-demo)

---

## Workshop Goal

By the end of this workshop, you'll build a complete **"Codebase Toolkit" plugin** containing:

| Component | Type | Purpose |
|-----------|------|---------|
| `service-documenter` | Subagent | Document services in parallel |
| `bug-hunter` | Subagent | Debug services in parallel |
| `code-reviewer` | Skill | Review code quality |

Each component works independently, but together they form a distributable plugin.

---

## Setup Verification

```bash
# Check Claude Code is installed
claude --version

# Navigate to the repo
cd opentelemetry-demo

# Create the plugin directory structure
mkdir -p .claude/plugins/codebase-toolkit/agents
mkdir -p .claude/plugins/codebase-toolkit/skills

# Start Claude Code
claude
```

---

## Phase 1: Documentation & Analysis (15 min)

**Objective:** Create the `service-documenter` subagent — Component 1 of 3

---

### 🧑‍💻 Exercise 1A: Create the Plugin Structure (2 min)

Create your plugin directory:

```bash
mkdir -p .claude/plugins/codebase-toolkit/agents
mkdir -p .claude/plugins/codebase-toolkit/skills
```

---

### 🧑‍💻 Exercise 1B: Create the `service-documenter` Subagent (5 min)

Create the file `.claude/plugins/codebase-toolkit/agents/service-documenter.md`:

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

**Install it for immediate use:**

```bash
mkdir -p .claude/agents
cp .claude/plugins/codebase-toolkit/agents/service-documenter.md .claude/agents/
```

---

### 🧑‍💻 Exercise 1C: Use Parallel Subagents (8 min)

Run this prompt to document the codebase using parallel subagents:

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

**What to observe:**
- `Task(...)` indicators show parallel execution
- Each task has its own context window
- Results are combined at the end

**✅ Checkpoint:** You have `service-documenter.md` in your plugin folder — Component 1 complete!

---

## Phase 2: Test Generation (15 min)

**Objective:** Generate tests (standalone capability demonstration)

> Note: This phase demonstrates test generation but doesn't add to our plugin.

---

### 🧑‍💻 Your Exercise (10 min)

**Choose a service and generate tests:**

**Python (pytest):**
```
Generate pytest tests for src/recommendationservice/recommendation_server.py
Include:
- Test for the ListRecommendations function
- Mock the product catalog dependency
- Test empty input handling
- Use pytest fixtures appropriately
```

**Go (testing):**
```
Generate tests for src/productcatalogservice/main.go
Include:
- Table-driven tests for GetProduct
- Tests for ListProducts with various filters
- Mock any database or external calls
- Test error conditions
```

**TypeScript (Jest):**
```
Generate Jest tests for the frontend cart functionality
Include:
- Test adding items to cart
- Test removing items
- Test quantity updates
- Mock API calls to the cart service
```

**C# (xUnit):**
```
Generate xUnit tests for src/cartservice
Include:
- Test AddItem functionality
- Test GetCart returns correct items
- Mock the Redis dependency
- Test concurrent access scenarios
```

**✅ Success:** You have a runnable test file

---

## Phase 3: Debugging & QA (15 min)

**Objective:** Create the `bug-hunter` subagent — Component 2 of 3

---

### 🧑‍💻 Exercise 3A: Create the `bug-hunter` Subagent (5 min)

Create the file `.claude/plugins/codebase-toolkit/agents/bug-hunter.md`:

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

**Install for immediate use:**

```bash
cp .claude/plugins/codebase-toolkit/agents/bug-hunter.md .claude/agents/
```

---

### 🧑‍💻 Exercise 3B: Parallel Debugging (10 min)

Run parallel debugging across multiple services:

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

**✅ Checkpoint:** You have `bug-hunter.md` in your plugin folder — Component 2 complete!

---

## Phase 4: Core Development + MCP Integration (20 min)

**Objective:** Build features and configure MCP servers

---

### 🧑‍💻 Exercise 4A: Feature Development (10 min)

**Choose one task:**

**Task A — New API Endpoint:**
```
Add a "search products" endpoint to productcatalogservice:
- Accept a search query string
- Filter products by name or description
- Return matching products sorted by relevance
- Include proper error handling

Show me your plan first, then implement it.
```

**Task B — Refactoring:**
```
Refactor src/cartservice to improve code quality:
- Extract repeated logic into helper functions
- Improve error messages to be more descriptive
- Add input validation where missing

Keep all existing functionality working.
```

**Task C — New Feature:**
```
Add a "recently viewed products" feature:
- Track the last 10 products a user viewed
- Store in memory
- Add an API endpoint to retrieve the list

Follow the patterns used in the cart service.
```

---

### 🧑‍💻 Exercise 4B: Configure MCP Servers (10 min)

**What is MCP?**
Model Context Protocol (MCP) servers extend Claude's capabilities to interact with external tools — filesystems, browsers, APIs, and more.

**Configure the Filesystem MCP:**

Edit or create `~/.claude/settings.json`:

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

**Restart Claude Code and verify:**

```bash
claude
```

```
List all markdown files in the current directory using the filesystem MCP
```

**Optional — Add more MCP servers:**

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "."]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "your-token-here"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-playwright"]
    }
  }
}
```

| MCP Server | Purpose | Requires |
|------------|---------|----------|
| **Filesystem** | Safe file operations | Node.js |
| **GitHub** | Repo operations, PRs, issues | GitHub token |
| **Playwright** | Browser automation | Node.js |

**✅ Checkpoint:** MCP is configured and working

---

## Phase 5: Skill Building, Plugin Packaging & Marketplace (20 min)

**Objective:** Create `code-reviewer` skill, package the complete plugin, explore marketplace

---

### 🧑‍💻 Exercise 5A: Create the `code-reviewer` Skill (5 min)

Create the directory and file:

```bash
mkdir -p .claude/plugins/codebase-toolkit/skills/code-reviewer
```

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

**Install and test:**

```bash
mkdir -p ~/.claude/skills/code-reviewer
cp .claude/plugins/codebase-toolkit/skills/code-reviewer/SKILL.md ~/.claude/skills/code-reviewer/
```

```
/code-reviewer

Review src/paymentservice for code quality issues.
```

**✅ Checkpoint:** You have `code-reviewer` skill — Component 3 complete!

---

### 🧑‍💻 Exercise 5B: Create the Plugin Manifest (3 min)

Create `.claude/plugins/codebase-toolkit/PLUGIN.md`:

```markdown
---
name: codebase-toolkit
version: 1.0.0
description: A toolkit for onboarding to new codebases. Includes parallel documentation generation, automated bug hunting, and code review capabilities.
author: Your Name
---

# Codebase Toolkit Plugin

This plugin helps developers quickly understand and improve unfamiliar codebases.

## Components

### Subagents
- **service-documenter** - Analyzes and documents microservices in parallel
- **bug-hunter** - Investigates services for bugs and code quality issues

### Skills
- **code-reviewer** - Comprehensive code review following best practices

## Usage

# Document a codebase with parallel subagents
Document this repo using 4 parallel service-documenter subagents

# Hunt for bugs across services
Debug these services using bug-hunter subagents in parallel

# Review code quality
/code-reviewer
Review src/myservice for issues
```

---

### 🧑‍💻 Exercise 5C: Package the Plugin (5 min)

**Your final plugin structure should be:**

```
.claude/plugins/codebase-toolkit/
├── PLUGIN.md
├── agents/
│   ├── service-documenter.md
│   └── bug-hunter.md
└── skills/
    └── code-reviewer/
        └── SKILL.md
```

**Package using skill-creator:**

```
/skill-creator

Package the codebase-toolkit plugin located at .claude/plugins/codebase-toolkit/
Include all agents and skills.
Create a distributable .skill file.
```

**Validate:**

```bash
ls -la codebase-toolkit.skill
unzip -l codebase-toolkit.skill
```

---

### 🧑‍💻 Exercise 5D: Test Your Plugin (3 min)

**Uninstall local components:**

```bash
rm ~/.claude/agents/service-documenter.md
rm ~/.claude/agents/bug-hunter.md
rm -rf ~/.claude/skills/code-reviewer
```

**Install from packaged plugin:**

```bash
unzip codebase-toolkit.skill -d ~/.claude/plugins/codebase-toolkit-test/
cp ~/.claude/plugins/codebase-toolkit-test/agents/* ~/.claude/agents/
cp -r ~/.claude/plugins/codebase-toolkit-test/skills/* ~/.claude/skills/
```

**Verify:**

```
/code-reviewer
Briefly review src/cartservice
```

---

### 🧑‍💻 Exercise 5E: Share via GitHub (Optional - 2 min)

```bash
cd .claude/plugins/codebase-toolkit
git init
git add .
git commit -m "Initial release of codebase-toolkit plugin"
gh repo create my-codebase-toolkit --public --source=. --push
```

**Others can install via:**

```bash
git clone https://github.com/yourusername/my-codebase-toolkit ~/.claude/plugins/codebase-toolkit
```

---

### 📺 Marketplace Demo (Watch Instructor)

The instructor will demonstrate these marketplace plugins:

| Plugin | Purpose |
|--------|---------|
| **document-skills** | Create DOCX, PPTX, XLSX, PDF |
| **claude-md-management** | Manage CLAUDE.md files |
| **claude-code-setup** | Bootstrap new projects |
| **code-review** | Professional code review |

**Post-Workshop: Installing Marketplace Plugins**

```bash
# List available plugins
claude /plugins

# Install a plugin (example)
claude /plugins install document-skills

# Use the plugin
Create a DOCX specification for a new feature
```

---

## Quick Reference

### Commands

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `/skills` | List available skills |
| `/plugins` | List installed plugins |
| `/code-reviewer` | Invoke our skill |
| `/context` | Show current context |
| `/clear` | Reset conversation |

### What You Built

| Phase | Component | File Location |
|-------|-----------|---------------|
| 1 | `service-documenter` | `agents/service-documenter.md` |
| 3 | `bug-hunter` | `agents/bug-hunter.md` |
| 4 | MCP config | `~/.claude/settings.json` |
| 5 | `code-reviewer` | `skills/code-reviewer/SKILL.md` |
| 5 | Plugin package | `codebase-toolkit.skill` |

### Component Independence

> **Important:** Subagents, skills, and MCP servers all work independently. The plugin is just a packaging mechanism for easy distribution. You can use any component on its own!

### Final Directory Structure

```
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
│   ├── service-documenter.md
│   └── bug-hunter.md
├── skills/
│   └── code-reviewer/
│       └── SKILL.md
└── settings.json (MCP config)
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Subagent not found | Check file is in `~/.claude/agents/` |
| Skill not found | Check file is in `~/.claude/skills/[name]/SKILL.md` |
| MCP not working | Verify Node.js installed, restart Claude Code |
| Packaging fails | Ensure all files exist, check YAML syntax |
| Rate limiting | Reduce parallel tasks from 4 to 2 |

---

## What to Bring to the Hackathon

After this workshop, you have:

1. ✅ `service-documenter` subagent for parallel documentation
2. ✅ `bug-hunter` subagent for parallel debugging
3. ✅ `code-reviewer` skill for quality audits
4. ✅ MCP configuration for extended capabilities
5. ✅ Packaged `codebase-toolkit.skill` plugin
6. ✅ Knowledge to create more components and plugins
