# astro-catalog — the workshop's local MCP server

A deliberately small **stdio** MCP server (Node.js, `@modelcontextprotocol/sdk`) used from Module 2 onward:
project-scoped in `$OTEL/.mcp.json` (M2), bundled into the `codebase-toolkit` plugin via `${WORKSHOP_REPO}` (M3),
optionally connected from the Agent SDK (M5 stretch). It makes **no network calls** and reads only `data/products.json`.

```bash
npm ci --prefix labs/mcp/astro-catalog            # once (preflight --install does this)
node labs/mcp/astro-catalog/server.mjs --selftest # prints: OK astro-catalog 4.0.0 — 10 products, tools: list_products, get_product, service_owner
claude mcp add --transport stdio --scope project astro-catalog -- node $WS/labs/mcp/astro-catalog/server.mjs
```

| Tool | Input | Returns |
|---|---|---|
| `list_products` | `min_price_usd?`, `category?`, `limit?`, `offset?` | products (id, name, categories, price, pricing owner), paginated |
| `get_product` | `id_or_name` | one product |
| `service_owner` | `topic` (pricing, currency, checkout, cart, shipping, ads, …) or a product id | owning service, `src/<dir>`, language, team |
| `approve` *(only with `ASTRO_CATALOG_ENABLE_APPROVE=1`)* | `tool_name`, `input` | toy `--permission-prompt-tool` target for the M4 stretch goal: allows Read/Grep/Glob, denies the rest |

Environment: `CATALOG_CURRENCY` (USD, EUR, GBP, JPY, CHF, CAD) changes the display currency — used in M2 to show
`${VAR:-default}` expansion in `.mcp.json`. Requires Node.js 20+ (workshop standard: current LTS).
