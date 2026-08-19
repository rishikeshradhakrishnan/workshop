#!/usr/bin/env bash
# =============================================================================
# labs/cleanup.sh — end-of-day cleanup (Module 8). Archives the Claude Managed Agents resources you created
# today, lists what only the Console can delete, and prints the key/secret reminders. Idempotent; asks before
# each destructive call unless --yes. Never touches ~/.claude/settings.json.
#
#   ./labs/cleanup.sh                     # archive sessions/agents/environments cached in labs/m6-managed-agents/**/.cma-state.json
#   ./labs/cleanup.sh --by-prefix "$GITHUB_USER"   # instead/also: find agents, environments, sessions, vaults, memory
#                                         # stores and deployments whose name/title contains the string; ask per item
#   ./labs/cleanup.sh --dry-run           # show what would be archived, change nothing
#   ./labs/cleanup.sh --yes               # no questions (used by maintainers after regenerating expected-output)
#   ./labs/cleanup.sh --plugins           # also: uninstall codebase-toolkit@workshop-marketplace (project scope in $OTEL),
#                                         #       disable security-guidance, remove the local ../workshop-marketplace registration
#   ./labs/cleanup.sh --delete            # DELETE sessions instead of archiving them (removes transcripts + outputs)
#
# Reads labs/.env (ANTHROPIC_API_KEY must be YOUR key — resources live in the workspace that created them).
# Requires the M6 Python env: labs/m6-managed-agents/python (uv sync) — or any python3 with `anthropic` installed.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi   # shellcheck disable=SC1090

DRY=0; YES=0; PLUGINS=0; DELETE=0; PREFIX=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY=1;;
    --yes|-y) YES=1;;
    --plugins) PLUGINS=1;;
    --delete) DELETE=1;;
    --by-prefix) shift; PREFIX="${1:-}";;
    --by-prefix=*) PREFIX="${1#--by-prefix=}";;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "cleanup: unknown argument '$1' (try --help)" >&2; exit 2;;
  esac
  shift
done

say() { printf '%s\n' "$*"; }
hr() { printf '\n== %s ==\n' "$*"; }

# ----------------------------------------------------------------------------- 1. Managed Agents resources
hr "Claude Managed Agents resources (Module 6)"
STATE_FILES="$(find "$WS/labs/m6-managed-agents" -name .cma-state.json 2>/dev/null | tr '\n' ' ')"
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  say "ANTHROPIC_API_KEY is not set — skipping API cleanup. If you created Managed Agents resources, source labs/.env (your own key) and re-run."
else
  PYRUN=""
  M6PY="$WS/labs/m6-managed-agents/python"
  if command -v uv >/dev/null 2>&1 && [ -f "$M6PY/pyproject.toml" ]; then PYRUN="uv run --quiet --project $M6PY python"
  elif python3 -c 'import anthropic' >/dev/null 2>&1; then PYRUN="python3"
  fi
  if [ -z "$PYRUN" ]; then
    say "No Python with the anthropic SDK found (uv sync --project labs/m6-managed-agents/python). Skipping API cleanup."
  else
    DRY=$DRY YES=$YES DELETE=$DELETE PREFIX="$PREFIX" STATE_FILES="$STATE_FILES" $PYRUN - <<'PY'
import json, os, sys, pathlib
from anthropic import Anthropic, APIStatusError

DRY, YES, DELETE = os.environ["DRY"] == "1", os.environ["YES"] == "1", os.environ["DELETE"] == "1"
PREFIX = os.environ.get("PREFIX", "").strip()
client = Anthropic()

def confirm(q: str) -> bool:
    if DRY:
        print(f"  (dry-run) would: {q}"); return False
    if YES or not sys.stdin.isatty():
        print(f"  {q}"); return True
    return input(f"  {q} [y/N] ").strip().lower() in {"y", "yes"}

def safe(fn, *a, **kw):
    try:
        return fn(*a, **kw)
    except APIStatusError as e:
        print(f"    -> API {e.status_code}: {str(e.message)[:120]}")
    except Exception as e:  # noqa: BLE001
        print(f"    -> {type(e).__name__}: {str(e)[:120]}")

def stop_session(sid: str, label: str = "") -> None:
    s = safe(client.beta.sessions.retrieve, sid)
    if s is None:
        return
    if getattr(s, "archived_at", None):
        print(f"  session {sid} already archived"); return
    if s.status == "running":
        if confirm(f"interrupt running session {sid} {label}"):
            safe(client.beta.sessions.events.send, sid, events=[{"type": "user.interrupt"}])
            import time; time.sleep(3)
    verb = "DELETE" if DELETE else "archive"
    if confirm(f"{verb} session {sid} {label}(status={s.status})"):
        safe(client.beta.sessions.delete if DELETE else client.beta.sessions.archive, sid)

# (a) everything cached in .cma-state.json files
sessions, agents, envs = [], [], []
for f in filter(None, os.environ.get("STATE_FILES", "").split()):
    try:
        st = json.loads(pathlib.Path(f).read_text())
    except Exception:
        continue
    print(f"state file: {f}")
    if st.get("session_id"): sessions.append(st["session_id"])
    if st.get("agent_id"): agents.append(st["agent_id"])
    if st.get("environment_id"): envs.append(st["environment_id"])
if not (sessions or agents or envs):
    print("no .cma-state.json found under labs/m6-managed-agents/ (ran M6 elsewhere? use --by-prefix \"$GITHUB_USER\")")

# (b) --by-prefix: discover by name/title substring
vaults, stores, deployments = [], [], []
if PREFIX:
    print(f"searching the workspace for resources whose name/title contains {PREFIX!r} ...")
    for a in safe(lambda: list(client.beta.agents.list(limit=100))) or []:
        if PREFIX in (a.name or "") and a.id not in agents: agents.append(a.id); print(f"  agent {a.id} {a.name}")
    for e in safe(lambda: list(client.beta.environments.list(limit=100))) or []:
        if PREFIX in (e.name or "") and e.id not in envs: envs.append(e.id); print(f"  environment {e.id} {e.name}")
    for s in safe(lambda: list(client.beta.sessions.list(limit=100))) or []:
        if PREFIX in (getattr(s, "title", "") or "") and s.id not in sessions: sessions.append(s.id); print(f"  session {s.id} {s.title}")
    for aid in list(agents):   # sessions started on your agents by snippets/deployments
        for s in safe(lambda: list(client.beta.sessions.list(agent_id=aid, limit=100))) or []:
            if s.id not in sessions: sessions.append(s.id); print(f"  session {s.id} (on agent {aid})")
    for v in safe(lambda: list(client.beta.vaults.list())) or []:
        if PREFIX in (getattr(v, "display_name", "") or ""): vaults.append(v.id); print(f"  vault {v.id} {v.display_name}")
    for m in safe(lambda: list(client.beta.memory_stores.list())) or []:
        if PREFIX in (getattr(m, "name", "") or ""): stores.append(m.id); print(f"  memory store {m.id} {m.name}")
    for d in safe(lambda: list(client.beta.deployments.list())) or []:
        if PREFIX in (getattr(d, "name", "") or ""): deployments.append(d.id); print(f"  deployment {d.id} {d.name}")

for sid in sessions: stop_session(sid)
for did in deployments:
    if confirm(f"archive scheduled deployment {did}"): safe(client.beta.deployments.archive, did)
for aid in agents:
    if confirm(f"archive agent {aid} (read-only afterwards; existing sessions keep working)"): safe(client.beta.agents.archive, aid)
for eid in envs:
    if confirm(f"archive environment {eid}"): safe(client.beta.environments.archive, eid)
for vid in vaults:
    if confirm(f"archive vault {vid} (credentials become unusable)"): safe(client.beta.vaults.archive, vid)
for mid in stores:
    if confirm(f"archive memory store {mid}"): safe(client.beta.memory_stores.archive, mid)

# (c) things only listed
left = safe(lambda: [d for d in client.beta.deployments.list() if not getattr(d, "archived_at", None)]) or []
if left:
    print("\nActive scheduled deployments still in this workspace (archive in Console -> Deployments if they are yours):")
    for d in left: print(f"  {d.id} {getattr(d, 'name', '')}")
print("\nWebhooks cannot be listed via the API key: open Console -> Manage -> Webhooks and delete the ngrok/cloudflared/smee endpoint you added in M6 step 6 (c).")
PY
  fi
fi

# ----------------------------------------------------------------------------- 2. plugins (optional)
if [ "$PLUGINS" = 1 ]; then
  hr "Lab plugins (--plugins)"
  if command -v claude >/dev/null 2>&1; then
    run() { if [ "$DRY" = 1 ]; then say "  (dry-run) $*"; else say "  \$ $*"; "$@" || true; fi; }
    if [ -n "${OTEL:-}" ] && [ -d "$OTEL" ]; then
      ( cd "$OTEL"
        run claude plugin uninstall codebase-toolkit@workshop-marketplace --scope project
        run claude plugin marketplace remove workshop-marketplace )
    else
      say "  OTEL not set — skip project-scope plugin removal (cd \$OTEL && claude plugin uninstall codebase-toolkit@workshop-marketplace --scope project)"
    fi
    run claude plugin disable security-guidance@claude-plugins-official
    say "  kept: codebase-toolkit@${WORKSHOP_ORG:-<WORKSHOP_ORG>}-marketplace (user scope) and claude-security — remove with 'claude plugin uninstall <name>' if you wish"
  else
    say "  claude not on PATH — nothing to do"
  fi
fi

# ----------------------------------------------------------------------------- 3. reminders (always)
hr "Reminders (manual)"
cat <<EOF
  [ ] Revoke or rotate the API key you used today: Console -> Settings -> API keys.
  [ ] If you used the instructor's shared key: delete it from labs/.env now (it is revoked at end of day anyway).
  [ ] astroshop-reviews on GitHub: delete the ANTHROPIC_API_KEY secret and the CLAUDE_MODEL variable if you will not keep using them
        gh secret delete ANTHROPIC_API_KEY -R ${GITHUB_USER:-<you>}/astroshop-reviews ; gh variable delete CLAUDE_MODEL -R ${GITHUB_USER:-<you>}/astroshop-reviews
  [ ] Console -> Manage -> Webhooks: delete the M6 step-6 endpoint; Console -> Deployments: nothing of yours left active.
  [ ] Cloud sessions / routines you started in M4 (claude.ai/code): stop or delete the ones you do not want to keep.
  [ ] ~/.claude/settings.json: this script never touches it — review any experiments you made there yourself.
  Idle Managed Agents sessions cost nothing, but archived is tidier than idle.
EOF
