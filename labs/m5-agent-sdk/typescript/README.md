# Module 5 — TypeScript track

```
labs/m5-agent-sdk/typescript/
  starter/    YOUR lab:  cd starter && npm ci && npx tsx src/main.ts src/paymentservice   (TODO(step-n) markers)
  solution/   reference; `labs/checkpoint.sh CP5 --lang typescript` copies it over starter/
```

Each directory is its own npm project (`@anthropic-ai/claude-agent-sdk`, `zod`, `tsx`). Node.js current LTS.
`package-lock.json` is generated on first `npm install`; commit it in your fork if you want reproducible `npm ci`.
Environment: `source $WS/labs/.env` first (`ANTHROPIC_API_KEY`, `OTEL`, `MODEL`; optional `TOOLKIT_PLUGIN`).
