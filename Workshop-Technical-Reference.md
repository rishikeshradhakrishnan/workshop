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
  - [5B: Plugin Manifest (plugin.json)](#5b-plugin-manifest-pluginjson)
  - [5C: Complete Plugin Structure](#5c-complete-plugin-structure)
  - [5D: Create Local Test Marketplace](#5d-create-local-test-marketplace)
  - [5E: Install and Test Plugin Locally](#5e-install-and-test-plugin-locally)
  - [5F: Publish to GitHub Marketplace](#5f-publish-to-github-marketplace)
  - [5G: Browse Existing Marketplaces](#5g-browse-existing-marketplaces)
- [Phase 6: Reusability Demo](#phase-6-reusability-demo)
  - [6A: Clone Fresh Repository](#6a-clone-fresh-repository)
  - [6B: Install Plugin from Marketplace](#6b-install-plugin-from-marketplace)
  - [6C: Use Plugin on New Codebase](#6c-use-plugin-on-new-codebase)
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
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-playwright"]
    }
  }
}
```

**MCP Server Reference:**

| Server | Purpose | Requirements |
|--------|---------|--------------|
| GitHub | Repo operations, PRs, issues | GitHub token |
| Playwright | Browser automation, screenshots | Node.js |

---

<a id="4c-mcp-demo-prompts"></a>
### 4C: MCP Demo Prompts

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
        "playwright": {
        "command": "npx",
        "args": ["-y", "@anthropic/mcp-server-playwright"]
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
Open the application to verify if its launched successfully. Use the address http://localhost:8080
```

---

<a id="4e-participant-development-exercises"></a>
### 4E: Participant Development Exercises

**Task A — New Feature:**

```
Add a "wishlist" feature to this application:
1. Users can save products for later
2. Store wishlist data using the existing cart service patterns
3. Add API endpoints to the frontend service
4. Follow the existing code patterns in this repo

First show me your implementation plan, then build it.
```

**Task B — Refactoring:**

```
Refactor src/cartservice to improve code quality:
- Extract repeated logic into helper functions
- Improve error messages to be more descriptive
- Add input validation where missing

Keep all existing functionality working.
```

**Task C — New API Endpoint:**

```
Add a "search products" endpoint to productcatalogservice:
- Accept a search query string
- Filter products by name or description
- Return matching products sorted by relevance
- Include proper error handling

Show me your plan first, then implement it.
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

<a id="5b-plugin-manifest-pluginjson"></a>
### 5B: Plugin Manifest (plugin.json)

**File:** `.claude/plugins/codebase-toolkit/.claude-plugin/plugin.json`

First, create the `.claude-plugin` directory inside your plugin folder:

```bash
mkdir -p .claude/plugins/codebase-toolkit/.claude-plugin
```

Then create the manifest:

```json
{
  "name": "codebase-toolkit",
  "description": "A toolkit for onboarding to new codebases. Includes parallel documentation generation, automated bug hunting, and code review capabilities.",
  "version": "1.0.0",
  "author": {
    "name": "Workshop Participant"
  },
  "keywords": ["documentation", "debugging", "code-review", "onboarding"]
}
```

---

<a id="5c-complete-plugin-structure"></a>
### 5C: Complete Plugin Structure

**Verify your plugin has this structure:**

```
.claude/plugins/codebase-toolkit/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (required)
├── agents/
│   ├── service-documenter.md    # Documentation subagent
│   └── bug-hunter.md            # Debugging subagent
└── skills/
    └── code-reviewer/
        └── SKILL.md             # Code review skill
```

**Verify all files exist:**

```bash
ls -la .claude/plugins/codebase-toolkit/.claude-plugin/
ls -la .claude/plugins/codebase-toolkit/agents/
ls -la .claude/plugins/codebase-toolkit/skills/code-reviewer/
```

---

<a id="5d-create-local-test-marketplace"></a>
### 5D: Create Local Test Marketplace

A marketplace is a directory containing a manifest that lists available plugins. We'll create a local one to test before publishing to GitHub.

**Step 1: Create marketplace directory (sibling to the repo)**

```bash
# From inside opentelemetry-demo, go up one level
cd ..

# Create the marketplace structure
mkdir -p test-marketplace/.claude-plugin
```

**Step 2: Create marketplace manifest**

**File:** `test-marketplace/.claude-plugin/marketplace.json`

```json
{
  "name": "test-marketplace",
  "owner": {
    "name": "Workshop Participant"
  },
  "plugins": [
    {
      "name": "codebase-toolkit",
      "source": "../opentelemetry-demo/.claude/plugins/codebase-toolkit",
      "description": "A toolkit for onboarding to new codebases"
    }
  ]
}
```

**Directory structure after this step:**

```
~/workshop/                              # Or wherever you're working
├── opentelemetry-demo/                  # The demo repo
│   ├── src/
│   └── .claude/
│       └── plugins/
│           └── codebase-toolkit/        # Your plugin
│               ├── .claude-plugin/
│               │   └── plugin.json
│               ├── agents/
│               └── skills/
└── test-marketplace/                    # Local test marketplace
    └── .claude-plugin/
        └── marketplace.json
```

---

<a id="5e-install-and-test-plugin-locally"></a>
### 5E: Install and Test Plugin Locally

**Step 1: Remove manually installed components (clean slate)**

```bash
rm -f ~/.claude/agents/service-documenter.md
rm -f ~/.claude/agents/bug-hunter.md
rm -rf ~/.claude/skills/code-reviewer
```

**Step 2: Go back to the demo repo and add the marketplace**

```bash
cd opentelemetry-demo
claude
```

```
/plugin marketplace add ../test-marketplace
```

**Step 3: Install the plugin**

```
/plugin install codebase-toolkit@test-marketplace
```

Select "Install now" when prompted.

**Step 4: Restart Claude Code**

```bash
# Exit and restart
exit
claude
```

**Step 5: Verify installation**

```
/help
```

You should see your plugin's components available.

**Step 6: Test the plugin**

```
/code-reviewer

Briefly review src/cartservice for code quality.
```

---

<a id="5f-publish-to-github-marketplace"></a>
### 5F: Publish to GitHub Marketplace

**GitHub Marketplace Repository:** `rishikeshradhakrishnan/marketplace`

The marketplace repository structure:

```
marketplace/                              # GitHub repo
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace manifest
└── plugins/
    └── codebase-toolkit/                 # Plugin copied here
        ├── .claude-plugin/
        │   └── plugin.json
        ├── agents/
        │   ├── service-documenter.md
        │   └── bug-hunter.md
        └── skills/
            └── code-reviewer/
                └── SKILL.md
```

**Step 1: Clone the marketplace repo**

```bash
cd ~
git clone https://github.com/rishikeshradhakrishnan/marketplace.git
cd marketplace
```

**Step 2: Create the directory structure**

```bash
mkdir -p .claude-plugin
mkdir -p plugins
```

**Step 3: Copy your plugin**

```bash
cp -r ~/workshop/opentelemetry-demo/.claude/plugins/codebase-toolkit plugins/
```

**Step 4: Create the marketplace manifest**

**File:** `.claude-plugin/marketplace.json`

```json
{
  "name": "rishikesh-marketplace",
  "owner": {
    "name": "Rishikesh Radhakrishnan"
  },
  "metadata": {
    "description": "Claude Code plugins for developer productivity",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "codebase-toolkit",
      "source": "./plugins/codebase-toolkit",
      "description": "A toolkit for onboarding to new codebases. Includes parallel documentation, debugging, and code review.",
      "version": "1.0.0",
      "author": {
        "name": "Workshop Participant"
      },
      "keywords": ["documentation", "debugging", "code-review", "onboarding"]
    }
  ]
}
```

**Step 5: Commit and push**

```bash
git add .
git commit -m "Add codebase-toolkit plugin v1.0.0"
git push origin main
```

**Step 6: Add the GitHub marketplace to Claude Code**

```bash
cd ~/workshop/opentelemetry-demo
claude
```

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

---

<a id="5g-browse-existing-marketplaces"></a>
### 5G: Browse Existing Marketplaces

**Add Anthropic's official demo marketplace:**

```
/plugin marketplace add anthropics/claude-code
```

**Browse available plugins:**

```
/plugin
```

Select "Browse Plugins" to see available options.

**List all known marketplaces:**

```
/plugin marketplace list
```

**Available Marketplaces:**

| Marketplace | Source | Description |
|-------------|--------|-------------|
| anthropics/claude-code | GitHub | Official Anthropic demo plugins |
| rishikeshradhakrishnan/marketplace | GitHub | Workshop plugins |
| test-marketplace | Local | Local testing |

---

<a id="phase-6-reusability-demo"></a>
## Phase 6: Reusability Demo

<a id="6a-clone-fresh-repository"></a>
### 6A: Clone Fresh Repository

**Step 1: Navigate to a new directory**

```bash
cd ~
mkdir plugin-demo
cd plugin-demo
```

**Step 2: Clone the OpenTelemetry demo fresh (main branch, no modifications)**

```bash
git clone https://github.com/open-telemetry/opentelemetry-demo.git
cd opentelemetry-demo
```

---

<a id="6b-install-plugin-from-marketplace"></a>
### 6B: Install Plugin from Marketplace

**Step 1: Start Claude Code**

```bash
claude
```

**Step 2: Add the GitHub marketplace**

```
/plugin marketplace add rishikeshradhakrishnan/marketplace
```

**Step 3: Install the plugin**

```
/plugin install codebase-toolkit@rishikesh-marketplace
```

**Step 4: Restart Claude Code**

```bash
exit
claude
```

---

<a id="6c-use-plugin-on-new-codebase"></a>
### 6C: Use Plugin on New Codebase

**Option 1: Use the code-reviewer skill**

```
/code-reviewer

Review the src/frontend directory for code quality issues.
Focus on error handling and TypeScript best practices.
```

**Option 2: Use the service-documenter subagent**

```
Use the service-documenter subagent to document 
src/checkoutservice and src/paymentservice in parallel.
Create a combined services documentation file.
```

**Option 3: Use bug-hunter for parallel debugging**

```
Use 3 bug-hunter subagents in parallel to investigate:
- src/cartservice
- src/productcatalogservice  
- src/recommendationservice

Compile findings into a prioritized report.
```

---

## Updates to Reference Materials Section

### Replace "Complete Directory Structure" with:

```
### Plugin Directory Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json              # Required: Plugin manifest
├── agents/                       # Optional: Subagent definitions
│   └── my-agent.md
├── skills/                       # Optional: Skill definitions
│   └── my-skill/
│       └── SKILL.md
├── commands/                     # Optional: Custom slash commands
│   └── my-command.md
└── hooks/                        # Optional: Event handlers
    └── hooks.json
```

### Marketplace Directory Structure

```
marketplace-repo/
├── .claude-plugin/
│   └── marketplace.json         # Required: Marketplace manifest
└── plugins/                      # Plugin directories
    ├── plugin-one/
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── ...
    └── plugin-two/
        └── ...
```
```

### Replace "Command Quick Reference" with:

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `claude --version` | Check version |
| `/plugin` | Open plugin management menu |
| `/plugin marketplace add <source>` | Add a marketplace |
| `/plugin marketplace list` | List known marketplaces |
| `/plugin install <name>@<marketplace>` | Install a plugin |
| `/plugin uninstall <name>@<marketplace>` | Remove a plugin |
| `/help` | List available commands |
| `/code-reviewer` | Invoke code-reviewer skill |

### Add new reference template:

### Plugin Manifest Template (plugin.json)

```json
{
  "name": "plugin-name",
  "description": "What the plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Author Name"
  },
  "keywords": ["tag1", "tag2"]
}
```

### Marketplace Manifest Template (marketplace.json)

```json
{
  "name": "marketplace-name",
  "owner": {
    "name": "Owner Name"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugins/plugin-name",
      "description": "Plugin description"
    }
  ]
}
```

### Update Troubleshooting table:

| Issue | Solution |
|-------|----------|
| Subagent not found | Verify file in `agents/` with `.md` extension, restart Claude |
| Skill not found | Verify `SKILL.md` in `skills/[name]/` directory |
| MCP not connecting | Check Node.js installed, verify settings.json syntax |
| Parallel tasks sequential | Be explicit: "run in parallel" or "use N parallel tasks" |
| Rate limiting | Reduce parallel count from 4 to 2 |
| Plugin install fails | Check `.claude-plugin/plugin.json` exists |
| Marketplace not found | Verify `.claude-plugin/marketplace.json` path and JSON syntax |
| "Invalid schema" error | Check `source` path is correct relative to marketplace.json |