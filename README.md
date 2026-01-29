# Claude Code Workshop: Building Plugins from Scratch

A comprehensive 90-minute workshop curriculum that teaches developers how to build production-grade Claude Code plugins. Participants create a "Codebase Toolkit" plugin with subagents, skills, and MCP server integrations.

## Version

| | |
|---|---|
| **Version** | 2.0.0.b |
| **Last Updated** | January 2026 |
| **Claude Code** | Compatible with latest version |
| **Status** | Beta |

### Changelog

- **v2.0.0.b** - Complete workshop restructure with 5-phase curriculum (Beta)
- **v1.0.0** - Initial workshop release

## Workshop Overview

| Phase | Duration | Focus |
|-------|----------|-------|
| 1. Documentation & Analysis | 15 min | Create service-documenter subagent |
| 2. Test Generation | 15 min | Generate language-specific tests |
| 3. Debugging & QA | 15 min | Create bug-hunter subagent |
| 4. Development + MCP | 20 min | Build features, configure MCP servers |
| 5. Skills & Packaging | 20 min | Create code-reviewer skill, package plugin |
| Wrap-up | 5 min | Summary and Q&A |

## What Participants Build

The **Codebase Toolkit** plugin includes three core components:

- **service-documenter** (Subagent) - Documents microservices in parallel with isolated contexts
- **bug-hunter** (Subagent) - Debugs and audits code for issues across multiple services
- **code-reviewer** (Skill) - Reviews code quality with structured output in the main context

## Prerequisites

- Claude Code installed and configured
- Node.js installed
- Terminal access
- Demo repository cloned (OpenTelemetry microservices demo)

## Repository Contents

| File | Description |
|------|-------------|
| `Workshop-Technical-Reference.md` | Complete technical content, code snippets, and configuration examples |

## Key Learning Outcomes

- Create and orchestrate subagents for parallel processing
- Build reusable skills for specialized procedures
- Configure MCP servers (GitHub, Playwright)
- Package plugins for distribution
- Explore the Claude Code marketplace

## Technologies Covered

- **Claude Code Plugin System** - Subagents, Skills, MCP integration
- **Multi-language Support** - Go, Python, TypeScript, C#, Ruby, JavaScript
- **Distribution** - Plugin packaging and GitHub publishing

## Usage

### For Facilitators
> WIP 

### For Participants
> WIP 

### For Self-paced Learning
Use `Workshop-Technical-Reference.md` alongside the participant guide for comprehensive self-study.

## Quick Reference Commands

```bash
# Start Claude Code
claude

# Invoke a skill
/code-reviewer

# Create a skill package
/skill-creator

# Browse marketplace
/plugins
```

## License

Workshop materials for educational use.
