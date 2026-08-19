# Module 5 — Python track

```
labs/m5-agent-sdk/python/
  pyproject.toml   shared env: `uv sync --project labs/m5-agent-sdk/python` (preflight) — claude-agent-sdk, anthropic, jsonschema
  demo.py          instructor live-code demo (5.3 program, then --plugin)
  starter/         YOUR lab: `cd starter && uv sync && uv run bughunter src/paymentservice`  (TODO(step-n) markers)
  solution/        complete reference; `labs/checkpoint.sh CP5` copies it over starter/
```

Both `starter/` and `solution/` are standalone uv projects named `bughunter` (console script `bughunter`).
Environment: `source $WS/labs/.env` first — the SDK reads `ANTHROPIC_API_KEY`, and the code reads `OTEL`, `MODEL`
and optionally `TOOLKIT_PLUGIN` (defaults to `$OTEL/../codebase-toolkit`).
