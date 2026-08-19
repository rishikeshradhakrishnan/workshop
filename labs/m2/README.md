# Module 2 — lab assets

```
labs/m2/
  settings.project.json        -> $OTEL/.claude/settings.json  (allow/ask/deny, defaultMode, PreToolUse + PostToolUse hooks)
  hooks/protect-files.sh|.ps1  -> $OTEL/.claude/hooks/          (PreToolUse guardrail; exit 2 blocks generated/sensitive paths)
  hooks/examples/              read-only examples for Concepts Part B and the stretch goals (see its README)
../mcp/astro-catalog/          the stdio MCP server added at project scope in Part C
```
`labs/checkpoint.sh CP2` installs all of the above into `$OTEL` (plus `.mcp.json` with `${WORKSHOP_REPO}` expansion).
