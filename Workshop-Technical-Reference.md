# Claude Code Workshop - Technical Reference

**Duration:** 90 minutes | **Format:** Instructor-led, live coding  
**Repo:** [opentelemetry-demo](https://github.com/rishikeshradhakrishnan/opentelemery-demo)

> 📘 **Note:** This document contains all technical content, prompts, and code snippets. Use alongside the [Facilitator Guide](Workshop-Facilitator-Guide.md) for talk tracks and transitions.

---

## Table of Contents

- [Pre-Workshop Setup](#pre-workshop-setup)
- [Phase 1: Documentation & Analysis](#phase-1-documentation--analysis)
  - [1A: Basic Documentation Demo](#1a-basic-documentation-demo)
  - [1B: Plugin Directory Setup](#1b-plugin-directory-setup)
  - [1C: Service-Documenter Subagent](#1c-service-documenter-subagent)
  - [1D: Parallel Subagents Demo](#1d-parallel-subagents-demo)
  - [1E: Participant Parallel Exercise](#1e-participant-parallel-exercise)
- [Phase 2: Test Generation](#phase-2-test-generation)
  - [2A: Go Test Demo](#2a-go-test-demo)
  - [2B: Python Test Alternative](#2b-python-test-alternative)
  - [2C: Participant Test Exercises](#2c-participant-test-exercises)
- [Phase 3: Debugging & QA](#phase-3-debugging--qa)
  - [3A: Single-Service Debug Demo](#3a-single-service-debug-demo)
  - [3B: Bug-Hunter Subagent](#3b-bug-hunter-subagent)
  - [3C: Parallel Debugging Demo](#3c-parallel-debugging-demo)
  - [3D: Participant Debug Exercise](#3d-participant-debug-exercise)
- [Phase 4: Development & MCP](#phase-4-development--mcp)
  - [4A: Feature Development Demo](#4a-feature-development-demo)
  - [4B: MCP Configuration](#4b-mcp-configuration)
  - [4C: MCP Demo Prompts](#4c-mcp-demo-prompts)
  - [4D: Participant MCP Setup](#4d-participant-mcp-setup)
  - [4E: Participant Development Exercises](#4e-participant-development-exercises)
- [Phase 5: Skills, Packaging & Marketplace](#phase-5-skills-packaging--marketplace)
  - [5A: Code-Reviewer Skill](#5a-code-reviewer-skill)
  - [5B: Plugin Manifest](#5b-plugin-manifest)
  - [5C: Package Plugin](#5c-package-plugin)
  - [5D: Test Plugin Installation](#5d-test-plugin-installation)
  - [5E: GitHub Publishing](#5e-github-publishing)
  - [5F: Marketplace Demo](#5f-marketplace-demo)
- [Reference Materials](#reference-materials)

---

<a id="pre-workshop-setup"></a>
## Pre-Workshop Setup

### Participant Requirements

```bash
# Check Claude Code is installed
claude --version

# Clone the repository
git clone https://github.com/rishikeshradhakrishnan/opentelemery-demo.git
cd opentelemetry-demo

# Verify Node.js (needed for MCP in Phase 4)
node --version

# Start Claude Code
claude
```

### Instructor Pre-Check

```bash
# Verify all services are present
ls src/

# Expected output:
# accountingservice  cartservice       currencyservice  frontend      paymentservice         recommendationservice
# adservice          checkoutservice   emailservice     loadgenerator productcatalogservice  shippingservice
```

---

<a id="phase-1-documentation--analysis"></a>
## Phase 1: Documentation & Analysis

<a id="1a-basic-documentation-demo"></a>
### 1A: Basic Documentation Demo

**Prompt:**

```
Analyze the architecture of this application.
Create a README.md that includes:
- High-level architecture diagram (mermaid)
- List of all services with their primary language
- How services communicate with each other
- Quick start instructions for local development
```

**Expected Output:**
- Mermaid diagram showing service relationships
- Table of services with languages (Go, Python, TypeScript, etc.)
- Communication patterns (gRPC, HTTP)
- Docker compose instructions

---

<a id="1b-plugin-directory-setup"></a>
### 1B: Plugin Directory Setup

**Commands:**

```bash
# Create the plugin directory structure
mkdir -p .claude/plugins/codebase-toolkit/agents
mkdir -p .claude/plugins/codebase-toolkit/skills

# Also create local agents directory for immediate use
mkdir -p .claude/agents
```

**Resulting Structure:**

```
.claude/
├── agents/                              # Local active agents
└── plugins/
    └── codebase-toolkit/               # Our plugin project
        ├── agents/                      # Plugin agents
        └── skills/                      # Plugin skills
```

---

<a id="1c-service-documenter-subagent"></a>
### 1C: Service-Documenter Subagent

**File:** `.claude/plugins/codebase-toolkit/agents/service-documenter.md`

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

**Installation Command:**

```bash
cp .claude/plugins/codebase-toolkit/agents/service-documenter.md .claude/agents/
```

---

<a id="1d-parallel-subagents-demo"></a>
### 1D: Parallel Subagents Demo

**Prompt:**

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

**Expected Behavior:**
- 4 parallel `Task(...)` indicators appear
- Each completes independently
- Results synthesized into single document

---

<a id="1e-participant-parallel-exercise"></a>
### 1E: Participant Parallel Exercise

**Prompt:**

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

**Success Criteria:**
- Participant sees parallel `Task(...)` execution
- Receives combined summary
- Has `service-documenter.md` in plugin folder

---

<a id="phase-2-test-generation"></a>
## Phase 2: Test Generation

<a id="2a-go-test-demo"></a>
### 2A: Go Test Demo

**Prompt:**

```
Look at src/checkoutservice (Go) and generate a test suite:
- Unit tests for the main order placement logic
- Mock any external service calls
- Use table-driven tests following Go conventions
- Cover both success and error scenarios
```

**Expected Output:**
- File named `*_test.go`
- Table-driven test structure
- Mocked external services
- Error case coverage

---

<a id="2b-python-test-alternative"></a>
### 2B: Python Test Alternative

**Prompt:**

```
Generate pytest tests for src/recommendationservice/recommendation_server.py
Include fixtures for the product catalog dependency
```

**Expected Output:**
- pytest file with fixtures
- Mocked gRPC calls
- Multiple test cases

---

<a id="2c-participant-test-exercises"></a>
### 2C: Participant Test Exercises

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

---

<a id="phase-3-debugging--qa"></a>
## Phase 3: Debugging & QA

<a id="3a-single-service-debug-demo"></a>
### 3A: Single-Service Debug Demo

**Option A - Hypothetical:**

```
Users are reporting random payment failures.
Analyze src/paymentservice to find potential issues.
Check for error handling gaps, race conditions, and edge cases.
```

**Option B - Injected Bug:**

Before workshop, add to `src/paymentservice/charge.js`:

```javascript
// Add inside the charge function
if (Math.random() < 0.3) throw new Error("Connection timeout");
```

**Prompt for injected bug:**

```
Users are reporting random payment failures in production.
Analyze src/paymentservice to find the root cause.
Show me the problematic code and propose a fix.
```

---

<a id="3b-bug-hunter-subagent"></a>
### 3B: Bug-Hunter Subagent

**File:** `.claude/plugins/codebase-toolkit/agents/bug-hunter.md`

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

**Installation Command:**

```bash
cp .claude/plugins/codebase-toolkit/agents/bug-hunter.md .claude/agents/
```

---

<a id="3c-parallel-debugging-demo"></a>
### 3C: Parallel Debugging Demo

**Prompt:**

```
Debug the checkout flow using 4 parallel subagents:

Subagent 1: Investigate src/frontend for client-side error handling
Subagent 2: Investigate src/checkoutservice for orchestration issues
Subagent 3: Investigate src/paymentservice for payment processing bugs
Subagent 4: Investigate src/cartservice for data consistency issues

Use the bug-hunter approach for each.
Compile all findings into a prioritized bug report.
```

**Expected Output:**
- 4 parallel investigations
- Findings categorized by severity
- Cross-service issue identification

---

<a id="3d-participant-debug-exercise"></a>
### 3D: Participant Debug Exercise

**Prompt:**

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

**Success Criteria:**
- Parallel debugging executed
- Issues identified with file:line references
- Has `bug-hunter.md` in plugin folder

---

<a id="phase-4-development--mcp"></a>
## Phase 4: Development & MCP

<a id="4a-feature-development-demo"></a>
### 4A: Feature Development Demo

**Prompt:**

```
Add a "wishlist" feature to this application:
1. Users can save products for later
2. Store wishlist data using the existing cart service patterns
3. Add API endpoints to the frontend service
4. Follow the existing code patterns in this repo

First show me your implementation plan, then build it.
```

**Expected Output:**
- Implementation plan first
- Multi-file changes
- Consistent with existing patterns

---

<a id="4b-mcp-configuration"></a>
### 4B: MCP Configuration

**File:** `~/.claude/settings.json`

**Full Configuration:**

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
        "GITHUB_TOKEN": "your-github-token-here"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-playwright"]
    }
  }
}
```

**Minimal Configuration (Filesystem only):**

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

**MCP Server Reference:**

| Server | Purpose | Requirements |
|--------|---------|--------------|
| Filesystem | Safe file operations outside repo | Node.js |
| GitHub | Repo operations, PRs, issues | GitHub token |
| Playwright | Browser automation, screenshots | Node.js |

---

<a id="4c-mcp-demo-prompts"></a>
### 4C: MCP Demo Prompts

**Filesystem MCP:**

```
List all markdown files in the current directory using the filesystem MCP
```

**Playwright MCP:**

```
Use Playwright to:
1. Open the demo application at http://localhost:8080
2. Take a screenshot of the homepage
3. Click on a product and capture that page too
4. Report what UI elements are visible
```

**GitHub MCP:**

```
Use the GitHub MCP to:
1. List the open issues in this repository
2. Summarize what bugs or features are requested
3. Suggest which our bug-hunter subagent could help investigate
```

---

<a id="4d-participant-mcp-setup"></a>
### 4D: Participant MCP Setup

**Step 1: Create/Edit settings.json**

```bash
# Check if file exists
cat ~/.claude/settings.json

# Create directory if needed
mkdir -p ~/.claude

# Create minimal config
cat > ~/.claude/settings.json << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "."]
    }
  }
}
EOF
```

**Step 2: Restart Claude Code**

```bash
# Exit current session
exit

# Start fresh
claude
```

**Step 3: Verify**

```
List all files in the current directory using the filesystem MCP
```

---

<a id="4e-participant-development-exercises"></a>
### 4E: Participant Development Exercises

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

<a id="phase-5-skills-packaging--marketplace"></a>
## Phase 5: Skills, Packaging & Marketplace

<a id="5a-code-reviewer-skill"></a>
### 5A: Code-Reviewer Skill

**Directory Setup:**

```bash
mkdir -p .claude/plugins/codebase-toolkit/skills/code-reviewer
```

**File:** `.claude/plugins/codebase-toolkit/skills/code-reviewer/SKILL.md`

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

**Installation Commands:**

```bash
mkdir -p ~/.claude/skills/code-reviewer
cp .claude/plugins/codebase-toolkit/skills/code-reviewer/SKILL.md ~/.claude/skills/code-reviewer/
```

**Test Prompt:**

```
/code-reviewer

Review src/paymentservice for code quality issues.
```

---

<a id="5b-plugin-manifest"></a>
### 5B: Plugin Manifest

**File:** `.claude/plugins/codebase-toolkit/PLUGIN.md`

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
- **service-documenter** - Analyzes and documents microservices in parallel
- **bug-hunter** - Investigates services for bugs and code quality issues

### Skills
- **code-reviewer** - Comprehensive code review following best practices

## Usage

### Document a codebase
```
Document this repo using 4 parallel service-documenter subagents
```

### Hunt for bugs
```
Debug these services using bug-hunter subagents in parallel
```

### Review code
```
/code-reviewer
Review src/myservice for issues
```

## Installation

1. Extract to `~/.claude/plugins/codebase-toolkit/`
2. Copy agents to `~/.claude/agents/`
3. Copy skills to `~/.claude/skills/`
```

**Final Plugin Structure:**

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

---

<a id="5c-package-plugin"></a>
### 5C: Package Plugin

**Using skill-creator:**

```
/skill-creator

Package the codebase-toolkit plugin located at .claude/plugins/codebase-toolkit/
Include:
- The PLUGIN.md manifest
- Both subagents (service-documenter, bug-hunter)
- The code-reviewer skill

Create a distributable .skill file with validation.
```

**Manual Packaging (Alternative):**

```bash
cd .claude/plugins/codebase-toolkit
zip -r ../../../codebase-toolkit.skill .
cd ../../..
```

**Validate Package:**

```bash
# Check file exists
ls -la codebase-toolkit.skill

# View contents
unzip -l codebase-toolkit.skill
```

**Expected Contents:**

```
Archive:  codebase-toolkit.skill
  Length      Date    Time    Name
---------  ---------- -----   ----
      892  01-27-2026 10:00   PLUGIN.md
      687  01-27-2026 10:00   agents/service-documenter.md
      724  01-27-2026 10:00   agents/bug-hunter.md
      983  01-27-2026 10:00   skills/code-reviewer/SKILL.md
---------                     -------
     3286                     4 files
```

---

<a id="5d-test-plugin-installation"></a>
### 5D: Test Plugin Installation

**Step 1: Uninstall Local Components**

```bash
rm ~/.claude/agents/service-documenter.md
rm ~/.claude/agents/bug-hunter.md
rm -rf ~/.claude/skills/code-reviewer
```

**Step 2: Install from Package**

```bash
# Create test directory
mkdir -p ~/.claude/plugins/codebase-toolkit-test

# Extract
unzip codebase-toolkit.skill -d ~/.claude/plugins/codebase-toolkit-test/

# Copy to active locations
cp ~/.claude/plugins/codebase-toolkit-test/agents/* ~/.claude/agents/
cp -r ~/.claude/plugins/codebase-toolkit-test/skills/* ~/.claude/skills/
```

**Step 3: Verify**

```
/code-reviewer

Briefly review src/cartservice for any obvious issues.
```

---

<a id="5e-github-publishing"></a>
### 5E: GitHub Publishing

**Initialize and Push:**

```bash
cd .claude/plugins/codebase-toolkit

# Initialize git
git init
git add .
git commit -m "Initial release of codebase-toolkit plugin v1.0.0"

# Create GitHub repo and push
gh repo create codebase-toolkit-plugin --public --source=. --push
```

**Installation Instructions for Others:**

```bash
# Clone the plugin
git clone https://github.com/USERNAME/codebase-toolkit-plugin ~/.claude/plugins/codebase-toolkit

# Install components
cp ~/.claude/plugins/codebase-toolkit/agents/* ~/.claude/agents/
cp -r ~/.claude/plugins/codebase-toolkit/skills/* ~/.claude/skills/
```

---

<a id="5f-marketplace-demo"></a>
### 5F: Marketplace Demo

**List Available Plugins:**

```bash
claude /plugins
```

**Key Marketplace Plugins:**

| Plugin | Purpose | Demo Command |
|--------|---------|--------------|
| document-skills | Create DOCX, PPTX, XLSX, PDF | `Create a DOCX spec for a new feature` |
| claude-md-management | Manage CLAUDE.md files | `Update CLAUDE.md with project conventions` |
| claude-code-setup | Bootstrap new projects | `Set up a new Python project` |
| code-review | Professional code review | `Review this PR for issues` |

**Document Skills Demo:**

```
Use the document skills to create a DOCX specification 
for the wishlist feature we built earlier.
Include requirements, API design, and implementation notes.
```

---

<a id="reference-materials"></a>
## Reference Materials

### Complete Directory Structure

```
Project Directory:
.claude/
├── agents/                              # Active agents (copied here)
│   ├── service-documenter.md
│   └── bug-hunter.md
├── plugins/
│   └── codebase-toolkit/               # Plugin source
│       ├── PLUGIN.md
│       ├── agents/
│       │   ├── service-documenter.md
│       │   └── bug-hunter.md
│       └── skills/
│           └── code-reviewer/
│               └── SKILL.md
└── settings.json                        # MCP configuration (if local)

User Directory (~/.claude/):
├── agents/                              # Active agents
│   ├── service-documenter.md
│   └── bug-hunter.md
├── skills/                              # Active skills
│   └── code-reviewer/
│       └── SKILL.md
├── plugins/                             # Installed plugins
│   └── codebase-toolkit/
└── settings.json                        # MCP configuration
```

### Command Quick Reference

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `claude --version` | Check version |
| `/skills` | List available skills |
| `/plugins` | List installed plugins |
| `/code-reviewer` | Invoke code-reviewer skill |
| `/skill-creator` | Create/package skills |
| `/context` | Show current context |
| `/clear` | Reset conversation |

### Subagent File Template

```markdown
---
name: agent-name
description: What this agent does. When Claude should use it.
tools: Read, Grep, Glob
model: sonnet
---

Instructions for the agent...
```

### Skill File Template

```markdown
---
name: skill-name
description: What this skill does. When Claude should use it.
---

# Skill Title

Instructions for using the skill...
```

### MCP Settings Template

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-name", "arg1"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Subagent not found | Verify file in `~/.claude/agents/` with `.md` extension |
| Skill not found | Verify `SKILL.md` in `~/.claude/skills/[name]/` |
| MCP not connecting | Check Node.js installed, verify settings.json syntax |
| Parallel tasks sequential | Be explicit: "run in parallel" or "use N parallel tasks" |
| Rate limiting | Reduce parallel count from 4 to 2 |
| Package validation fails | Check YAML frontmatter syntax, ensure all files exist |
