# Module 6 — Claude Managed Agents lab

```
labs/m6-managed-agents/
  python/            uv project (anthropic[webhooks], flask):  cd python && uv sync
    starter/         deploy_toolkit_agent.py with TODO(step-n) markers  ->  uv run python deploy_toolkit_agent.py --help
    solution/        complete reference; labs/checkpoint.sh CP6 copies it over starter/
  typescript/        npm project (@anthropic-ai/sdk, tsx):  cd typescript && npm ci; cd starter && npx tsx deploy_toolkit_agent.ts step1
  curl/steps.sh      the same eight calls with raw HTTP + jq (three headers on every call)
  snippets/          step-6 previews (budget, deployment) and stretch goals (memory_store, outcome, vault_mcp, overrides, multiagent, github_resource)
  webhook_receiver.py   step 6 (c): Flask endpoint that verifies with client.beta.webhooks.unwrap()
  expected-output/   captured run for seats without a key
```

Environment: `source $WS/labs/.env` first — every track reads `ANTHROPIC_API_KEY`, `CMA_MODEL` (a **full model ID**; the
Managed Agents API rejects Claude Code aliases such as `sonnet`), `WORKSHOP_ORG` and `GITHUB_USER`.

State: every script caches IDs in `./.cma-state.json` (git-ignored) in the directory you run it from; `labs/cleanup.sh`
reads those files and archives what you created. Identifiers to re-verify before each delivery: `labs/shared/cma_constants.py`.
