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
