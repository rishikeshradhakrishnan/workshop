# Module 5 — expected output (read-along for seats without an API key)

Maintainers regenerate these captures before each delivery from `python/solution` (and `typescript/solution`)
against the pinned `opentelemetry-demo` fork; participants without a key read them while following the solution code.

| File | Step | What to look for |
|---|---|---|
| `step1-run.log` | 1 | `model=… auth=ANTHROPIC_API_KEY plugins=['codebase-toolkit']`, at least one `-> Agent`, indented `(subagent) -> Read/Grep/Glob`, `Done: success $0.0x` |
| `paymentservice.findings.json` | 2 | schema-valid `{service, summary, findings[]}`; `uv run python -m bughunter.validate <file>` prints `OK: N findings valid` |
| `step3-ticket.log` + `tickets.json` | 3 | `-> mcp__tracker__create_ticket` calls; `AST-0001`-style ids |
| `step4-policy.log` | 4 | `[policy] denied create_ticket (MEDIUM)` lines; only HIGH tickets filed; `[hook] denied Read …/.env` if the agent tried |
| `step5-followup.log` | 5 | few or no tool calls; `cache_read=` far larger than in step 1; per-model `costUSD` lines |

Until the captures are regenerated for your delivery, `paymentservice.findings.json` below is an **illustrative,
schema-valid sample** (finding text and line numbers are placeholders, clearly marked).

Regenerate:

```bash
source labs/.env && cd labs/m5-agent-sdk/python/solution && uv sync
uv run bughunter src/paymentservice            2>&1 | tee ../../expected-output/step1-run.log
cp $OTEL/reports/paymentservice.findings.json ../../expected-output/
uv run bughunter src/paymentservice --ticket   2>&1 | tee ../../expected-output/step3-ticket.log && cp tickets.json ../../expected-output/
uv run bughunter src/currencyservice --ticket  2>&1 | tee ../../expected-output/step4-policy.log
uv run bughunter followup "Which of those findings would you fix first, and why?" 2>&1 | tee ../../expected-output/step5-followup.log
```
