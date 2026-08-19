# Module 4 — lab assets

```
labs/m4/
  bug-hunt.sh            claude -p + @agent-codebase-toolkit:bug-hunter + --json-schema (labs/shared/findings.schema.json) + dontAsk + budgets
  stream-filter.jq       jq filter for --output-format stream-json --verbose (init / tool calls / result)
  streamjson-driver.py   stretch (a): two user turns over stdin with --input-format stream-json
  github/claude.yml      interactive @claude workflow (anthropics/claude-code-action@v1)
  github/code-review.yml automation-mode PR review via the code-review plugin
  github/toolkit-review.yml  stretch (c): your codebase-toolkit plugin in Actions (replace WORKSHOP_ORG)
  expected-output/       captured/sample outputs for read-along
```
The findings schema lives in `labs/shared/findings.schema.json` (shared with M5 and compared with M7's JSONL).
