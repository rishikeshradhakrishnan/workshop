#!/usr/bin/env bash
# CP3 post-apply (cwd = $OTEL): executable plugin hooks, org marketplace + plugin at USER scope (the afternoon's safety net),
# remove loose duplicates. Never fails the checkpoint if the claude CLI or network is unavailable.
set -uo pipefail
chmod +x "$OTEL_PARENT/codebase-toolkit/hooks/"*.sh "$OTEL_PARENT/workshop-marketplace/codebase-toolkit/hooks/"*.sh 2>/dev/null || true
ORG="${WORKSHOP_ORG:-}"
if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not on PATH — skipping marketplace/plugin install. Files are in place; run modules/03 step 13 by hand later."
else
  echo "\$ claude plugin validate $OTEL_PARENT/codebase-toolkit"; claude plugin validate "$OTEL_PARENT/codebase-toolkit" || true
  if [ -z "$ORG" ] || [ "$ORG" = "<WORKSHOP_ORG>" ]; then
    echo "WORKSHOP_ORG not set in labs/.env — cannot add the org marketplace. Set it and run:"
    echo "  claude plugin marketplace add <WORKSHOP_ORG>/claude-marketplace && claude plugin install codebase-toolkit@<WORKSHOP_ORG>-marketplace --scope user"
  else
    echo "\$ claude plugin marketplace add $ORG/claude-marketplace"
    claude plugin marketplace add "$ORG/claude-marketplace" </dev/null || echo "  (already added, offline, or blocked by policy — continuing)"
    echo "\$ claude plugin install codebase-toolkit@$ORG-marketplace --scope user"
    claude plugin install "codebase-toolkit@$ORG-marketplace" --scope user </dev/null || echo "  (install failed — pair, or use: claude --plugin-dir $OTEL_PARENT/codebase-toolkit)"
  fi
fi
if [ -x "$WS/labs/m3/dedupe.sh" ]; then OTEL="$OTEL" "$WS/labs/m3/dedupe.sh" --yes || true; fi
if command -v claude >/dev/null 2>&1; then echo "\$ claude plugin list"; claude plugin list </dev/null 2>/dev/null | sed 's/^/  /' || true; fi
cat <<EOF
CP3 ready:
  plugin source      $OTEL_PARENT/codebase-toolkit          (try: cd \$OTEL && claude --plugin-dir ../codebase-toolkit)
  local marketplace  $OTEL_PARENT/workshop-marketplace     (/plugin marketplace add ../workshop-marketplace)
  Remember: source \$WS/labs/.env so WORKSHOP_REPO is exported for the plugin's .mcp.json.
EOF
