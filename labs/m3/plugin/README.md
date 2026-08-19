# codebase-toolkit (reference plugin, v4.0.0)

The complete plugin participants assemble in Module 3 Part C, kept here as the source of truth for
`labs/checkpoint.sh CP3` and for the org-published `<WORKSHOP_ORG>/claude-marketplace` repo.

```
codebase-toolkit/
├── .claude-plugin/plugin.json      manifest (the ONLY file in .claude-plugin/)
├── agents/{service-documenter,bug-hunter}.md
├── skills/code-reviewer/{SKILL.md,checklists/security.md,checklists/performance.md}
├── hooks/{hooks.json,protect-files.sh}      M2 hook block, script path via ${CLAUDE_PLUGIN_ROOT}
└── .mcp.json                       astro-catalog via ${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs
```

Validate and try it: `claude plugin validate labs/m3/plugin` · `cd $OTEL && claude --plugin-dir $WS/labs/m3/plugin`.
Edit `author` in `plugin.json` before publishing your own copy.
