#!/usr/bin/env bash
# CP2 post-apply: MCP lab server deps, executable hooks, dummy .env for the deny-rule demo. cwd = $OTEL.
set -euo pipefail
chmod +x .claude/hooks/*.sh 2>/dev/null || true
echo "hooks: $(ls .claude/hooks 2>/dev/null | tr '\n' ' ')"
if [ ! -f .env ]; then echo 'FAKE_KEY=123' > .env && echo "created dummy .env (FAKE_KEY=123) for the Read(./.env) deny demo"; fi
if command -v npm >/dev/null 2>&1; then
  if [ -d "$WS/labs/mcp/astro-catalog/node_modules" ]; then echo "astro-catalog deps already installed"
  else echo "npm ci --prefix $WS/labs/mcp/astro-catalog"; npm ci --silent --prefix "$WS/labs/mcp/astro-catalog"; fi
  node "$WS/labs/mcp/astro-catalog/server.mjs" --selftest || echo "selftest failed — see modules/02 troubleshooting"
else
  echo "npm not found — install Node.js LTS, then: npm ci --prefix \$WS/labs/mcp/astro-catalog"
fi
# self-test the guardrail exactly like lab step 4
printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"src/x/demo_pb2.py"}}' | .claude/hooks/protect-files.sh >/dev/null 2>&1 && rc=$? || rc=$?
echo "protect-files.sh self-test on a _pb2.py path -> exit=$rc (2 = blocks, as intended)"
if [ -z "${WORKSHOP_REPO:-}" ]; then echo "NOTE: .mcp.json uses \${WORKSHOP_REPO}; 'source \$WS/labs/.env' before starting claude so it expands."; fi
echo "Next 'claude' start in \$OTEL: astro-catalog is pre-approved via enabledMcpjsonServers; check with /mcp (3 tools)."
