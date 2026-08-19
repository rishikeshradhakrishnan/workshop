# Module 6 snippets (step 6 previews and stretch goals)

Run from the directory that holds your `.cma-state.json` (created by `deploy_toolkit_agent.py step1..3`):

```bash
cd labs/m6-managed-agents/python/starter          # or solution
uv run python ../../snippets/budget.py            # (a) budget_reached, then raise the cap
uv run python ../../snippets/deployment.py        # (b) cron deployment + one manual run, then archive
ANTHROPIC_WEBHOOK_SIGNING_KEY=whsec_… uv run python ../../webhook_receiver.py   # (c)
uv run python ../../snippets/memory_store.py      # stretch (b) read_only memory store
uv run python ../../snippets/outcome.py           # stretch (c) outcome grader
GITHUB_TOKEN=… uv run python ../../snippets/vault_mcp.py        # stretch (d)
HAIKU_MODEL=… uv run python ../../snippets/overrides.py         # stretch (e)
uv run python ../../snippets/multiagent.py        # stretch (f)  [verify gating on the day]
GITHUB_TOKEN=… uv run python ../../snippets/github_resource.py  # stretch (a)
```

Every snippet archives the sessions it creates; agents/environments/vaults/memory stores it creates carry your
`$GITHUB_USER` in the name so `labs/cleanup.sh` finds them.
