#!/usr/bin/env bash
# CP5 post-apply: install deps in the starter for the chosen track; with an API key, run the step-1/3 success check once
# (bughunter src/paymentservice --ticket, capped by max_budget_usd=1.00) so reports/, tickets.json and .bughunter-session exist.
set -uo pipefail
DIR="$WS/labs/m5-agent-sdk/$LANG_TRACK/starter"
cd "$DIR" || { echo "missing $DIR"; exit 1; }
echo "track=$LANG_TRACK dir=${DIR#"$WS"/}"
if [ "$LANG_TRACK" = python ]; then
  if command -v uv >/dev/null 2>&1; then uv sync --quiet && echo "uv sync ok"; else echo "uv missing — pip install claude-agent-sdk jsonschema"; fi
  RUN="uv run bughunter"
else
  if command -v npm >/dev/null 2>&1; then (npm ci --silent 2>/dev/null || npm install --silent) && echo "npm deps ok"; else echo "npm missing"; fi
  RUN="npx tsx src/main.ts"
fi
if [ ! -d "$OTEL_PARENT/codebase-toolkit/.claude-plugin" ]; then
  echo "NOTE: $OTEL_PARENT/codebase-toolkit is missing — run ./labs/checkpoint.sh CP3 (or set TOOLKIT_PLUGIN) before bughunter."
fi
KEYFILE="bughunter/__main__.py"; [ "$LANG_TRACK" = typescript ] && KEYFILE="src/main.ts"
if ! cmp -s "$DIR/$KEYFILE" "$WS/labs/m5-agent-sdk/$LANG_TRACK/solution/$KEYFILE"; then
  echo "starter/$KEYFILE still differs from the solution (your own edits, or the untouched TODO version)."
  echo "  -> keep working on yours, or take the reference version with: ./labs/checkpoint.sh CP5 --only --force   (skipping the run)"
elif [ -n "${ANTHROPIC_API_KEY:-}" ] && [ "${CP_SKIP_RUN:-0}" != 1 ]; then
  echo "\$ (cd ${DIR#"$WS"/} && $RUN src/paymentservice --ticket)   # one real run, budget-capped at \$1.00; CP_SKIP_RUN=1 to skip"
  OTEL="$OTEL" $RUN src/paymentservice --ticket || echo "run did not complete — read the error above and modules/05 troubleshooting"
else
  mkdir -p "$OTEL/reports"
  [ -f "$OTEL/reports/paymentservice.findings.json" ] || cp "$WS/labs/m5-agent-sdk/expected-output/paymentservice.findings.json" "$OTEL/reports/paymentservice.findings.json"
  echo "No ANTHROPIC_API_KEY (or CP_SKIP_RUN=1): copied the sample findings to \$OTEL/reports/paymentservice.findings.json instead of running."
  echo "When you have a key:  cd ${DIR#"$WS"/} && $RUN src/paymentservice --ticket"
fi
echo "Then: $RUN followup \"Which of those findings would you fix first, and why?\""
