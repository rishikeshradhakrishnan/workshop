#!/usr/bin/env bash
# CP6 post-apply: with an API key in an org that has Managed Agents, run steps 1-3 non-interactively (--yes auto-allows the
# web_fetch confirmation) so you see one complete event stream; IDs are cached in .cma-state.json for step 5 by hand.
set -uo pipefail
BASE="$WS/labs/m6-managed-agents"
if [ "$LANG_TRACK" = python ]; then
  DIR="$BASE/python/starter"; cd "$DIR" || exit 1
  command -v uv >/dev/null 2>&1 && (cd "$BASE/python" && uv sync --quiet) && echo "uv sync ok (labs/m6-managed-agents/python)"
  RUN="uv run python deploy_toolkit_agent.py"
else
  DIR="$BASE/typescript/starter"; cd "$DIR" || exit 1
  command -v npm >/dev/null 2>&1 && (cd "$BASE/typescript" && (npm ci --silent 2>/dev/null || npm install --silent)) && echo "npm deps ok"
  RUN="npx tsx deploy_toolkit_agent.ts"
fi
echo "track=$LANG_TRACK dir=${DIR#"$WS"/}"
case "${CMA_MODEL:-}" in ""|"<"*|sonnet|opus|haiku|default) echo "NOTE: CMA_MODEL='${CMA_MODEL:-}' — Managed Agents needs a full model ID in labs/.env (Claude Code aliases 400).";; esac
KEYFILE="deploy_toolkit_agent.py"; [ "$LANG_TRACK" = typescript ] && KEYFILE="deploy_toolkit_agent.ts"
if ! cmp -s "$DIR/$KEYFILE" "$BASE/$LANG_TRACK/solution/$KEYFILE"; then
  echo "starter/$KEYFILE still differs from the solution (your own edits, or the untouched TODO version)."
  echo "  -> keep working on yours, or take the reference version with: ./labs/checkpoint.sh CP6 --only --force   (skipping the run)"
elif [ -n "${ANTHROPIC_API_KEY:-}" ] && [ "${CP_SKIP_RUN:-0}" != 1 ]; then
  echo "\$ (cd ${DIR#"$WS"/} && $RUN step1 step2 step3 --yes)"
  $RUN step1 step2 step3 --yes || echo "run stopped — 403/404 usually means Managed Agents is not enabled for this key's org; see modules/06 troubleshooting"
  echo "Next by hand: $RUN step5   (download bug-report.md, print usage; then Console -> Sessions -> Tracing view)"
else
  cat <<EOF
No ANTHROPIC_API_KEY in this shell (or CP_SKIP_RUN=1) — nothing was created.
  * Pair with a neighbour for steps 3-5, or use the instructor workspace key (labs/.env.instructor) for this module only.
  * Read-along: $BASE/expected-output/  (stream.log, bug-report.md, usage.json once regenerated for this delivery)
  * When you have a key: cd ${DIR#"$WS"/} && $RUN step1 step2 step3
EOF
fi
