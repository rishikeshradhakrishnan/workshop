#!/usr/bin/env bash
# =============================================================================
# preflight.sh — Workshop v4 environment check (macOS / Linux / WSL2)
#
# Run this from anywhere:   ./labs/preflight.sh [options]
#
# It checks, without changing anything on your machine:
#   1. OS / architecture / RAM
#   2. Claude Code CLI present, version, `claude doctor`, and how you are authenticated
#   3. git, gh (optional), jq, node/npm, python3, uv or pip
#   4. ANTHROPIC_API_KEY present (masked) and, if present, that it works (read-only GET)
#      plus whether Claude Managed Agents is reachable for that key
#   5. Network reachability to the hosts the labs need
#   6. Your repo clones ($OTEL fork, $REV template copy) and labs/.env
#   7. Lab dependencies (MCP server node_modules, Python SDK imports, workshop plugins)
# and prints a PASS / WARN / FAIL table plus a one-line summary you can paste into
# the registration form.
#
# Options:
#   --full        also run the (cheap) inference ping via `claude -p`, and `pytest` in $REV
#   --ping        only add the inference ping (costs a fraction of a cent / one prompt of quota)
#   --install     allowed to run `npm ci` / `uv sync` for lab dependencies inside this repo
#   --ts          also check the TypeScript track dependencies (labs/m5-agent-sdk/typescript)
#   --no-network  skip all network checks (air-gapped rehearsal)
#   --no-color    plain output
#   -h, --help    this text
#
# Exit code: 0 when there is no FAIL row, 1 otherwise. WARN rows never fail the run.
# Nothing here deletes, overwrites, installs (unless --install), logs in, or logs out.
# =============================================================================
set -euo pipefail

# ----------------------------------------------------------------------------- args
OPT_FULL=0; OPT_PING=0; OPT_INSTALL=0; OPT_TS=0; OPT_NET=1; OPT_COLOR=1
for arg in "$@"; do
  case "$arg" in
    --full) OPT_FULL=1; OPT_PING=1 ;;
    --ping) OPT_PING=1 ;;
    --install) OPT_INSTALL=1 ;;
    --ts) OPT_TS=1 ;;
    --no-network) OPT_NET=0 ;;
    --no-color) OPT_COLOR=0 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "preflight: unknown option '$arg' (try --help)" >&2; exit 2 ;;
  esac
done

# ----------------------------------------------------------------------------- paths & env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a; . "$ENV_FILE"; set +a
fi
WS="$(cd "$SCRIPT_DIR/.." && pwd)"                  # this workshop repo (authoritative: where this script lives)
OTEL="${OTEL:-}"                                    # participant's clone of <WORKSHOP_ORG>/opentelemetry-demo
REV="${REV:-}"                                      # participant's own copy of astroshop-reviews
WORKSHOP_ORG="${WORKSHOP_ORG:-}"
GITHUB_USER="${GITHUB_USER:-}"
OTEL_PINNED_SHA="${OTEL_PINNED_SHA:-}"              # set by facilitators in env.example
MIN_NODE_MAJOR="${PREFLIGHT_MIN_NODE_MAJOR:-22}"    # WARN 18–21, FAIL <18
MIN_PY="${PREFLIGHT_MIN_PYTHON:-3.10}"              # FAIL <3.9.6, WARN 3.9.x
MIN_CLAUDE="${PREFLIGHT_MIN_CLAUDE_VERSION:-}"      # optional floor, e.g. "2.1.0"; empty = just report
API_HOST="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
MA_BETA="${MANAGED_AGENTS_BETA:-managed-agents-2026-04-01}"   # volatile: re-verify before each delivery

# ----------------------------------------------------------------------------- output helpers
if [ "$OPT_COLOR" = 1 ] && [ -t 1 ]; then
  C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_D=$'\033[2m'; C_B=$'\033[1m'; C_0=$'\033[0m'
else
  C_G=""; C_Y=""; C_R=""; C_D=""; C_B=""; C_0=""
fi
ROWS=""; N_PASS=0; N_WARN=0; N_FAIL=0
row() { # status, check, detail
  local st="$1" name="$2" detail="${3:-}"
  case "$st" in
    PASS) N_PASS=$((N_PASS+1));;
    WARN) N_WARN=$((N_WARN+1));;
    FAIL) N_FAIL=$((N_FAIL+1));;
  esac
  ROWS="${ROWS}${st}|${name}|${detail}
"
}
say()  { printf '%s\n' "$*"; }
step() { printf '%s.. %s%s\n' "$C_D" "$*" "$C_0"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Run a command with a timeout if `timeout`/`gtimeout` exists (macOS lacks it by default).
with_timeout() { # seconds cmd...
  local secs="$1"; shift
  if have timeout; then timeout "$secs" "$@"
  elif have gtimeout; then gtimeout "$secs" "$@"
  else "$@"
  fi
}

# ver_ge A B  -> true when dotted version A >= B (compares first three numeric fields)
ver_ge() {
  local IFS=.
  # shellcheck disable=SC2206
  local a=($1) b=($2)
  local i x y
  for i in 0 1 2; do
    x="${a[$i]:-0}"; y="${b[$i]:-0}"
    x="${x%%[!0-9]*}"; y="${y%%[!0-9]*}"
    x="${x:-0}"; y="${y:-0}"
    if [ "$x" -gt "$y" ]; then return 0; fi
    if [ "$x" -lt "$y" ]; then return 1; fi
  done
  return 0
}
first_version() { # extract first x.y[.z] from stdin (never fails)
  { grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' || true; } | head -n1
}
mask_key() {
  local k="$1"; local n=${#k}
  if [ "$n" -le 12 ]; then printf '****'; else printf '%s...%s (%d chars)' "${k:0:7}" "${k:$((n-4))}" "$n"; fi
}
http_code() { # url [extra curl args...] -> prints HTTP status or 000
  local url="$1"; shift
  local c
  c="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 12 "$@" "$url" 2>/dev/null)" || true
  printf '%s' "${c:-000}"
}

say "${C_B}Workshop v4 preflight${C_0}  ($(date '+%Y-%m-%d %H:%M'))"
say "${C_D}workshop repo: $WS${C_0}"
[ -f "$ENV_FILE" ] && say "${C_D}loaded: $ENV_FILE${C_0}" || say "${C_D}note: $ENV_FILE not found (copy labs/env.example to labs/.env)${C_0}"
say ""

# ============================================================================= 1. OS / RAM
step "System"
OS="$(uname -s 2>/dev/null || echo unknown)"; ARCH="$(uname -m 2>/dev/null || echo unknown)"
OS_LABEL="$OS/$ARCH"
RAM_GB=""
case "$OS" in
  Darwin) bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"; RAM_GB=$(( bytes / 1024 / 1024 / 1024 )) ;;
  Linux)  kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"; RAM_GB=$(( kb / 1024 / 1024 ))
          if grep -qi microsoft /proc/version 2>/dev/null; then OS_LABEL="WSL/$ARCH"; fi ;;
  *)      RAM_GB=0 ;;
esac
if [ "$OS" = Darwin ] || [ "$OS" = Linux ]; then
  row PASS "Operating system" "$OS_LABEL"
else
  row WARN "Operating system" "$OS_LABEL — this script targets macOS/Linux/WSL2; on native Windows run it from Git Bash or WSL2"
fi
if [ "${RAM_GB:-0}" -ge 8 ]; then row PASS "Memory" "${RAM_GB} GB"
elif [ "${RAM_GB:-0}" -gt 0 ]; then row WARN "Memory" "${RAM_GB} GB (8 GB recommended; close other apps during M3/M7)"
else row WARN "Memory" "could not determine"; fi

# ============================================================================= 2. Claude Code
step "Claude Code CLI"
CLAUDE_VER="missing"; AUTH_MODE="none"
if have claude; then
  CLAUDE_VER="$(claude --version 2>/dev/null | first_version || true)"; CLAUDE_VER="${CLAUDE_VER:-unknown}"
  if [ -n "$MIN_CLAUDE" ] && [ "$CLAUDE_VER" != unknown ]; then
    if ver_ge "$CLAUDE_VER" "$MIN_CLAUDE"; then row PASS "claude --version" "$CLAUDE_VER (>= $MIN_CLAUDE)"
    else row FAIL "claude --version" "$CLAUDE_VER is older than the workshop floor $MIN_CLAUDE — run: claude update"; fi
  else
    row PASS "claude --version" "$CLAUDE_VER ($(command -v claude)) — keep auto-update on, or run 'claude update' the day before"
  fi
  # claude doctor is read-only diagnostics; tolerate versions where it is interactive/slow.
  if with_timeout 45 claude doctor </dev/null >/dev/null 2>&1; then row PASS "claude doctor" "no blocking issues reported"
  else row WARN "claude doctor" "non-zero exit or timed out — run 'claude doctor' yourself and read the output"; fi
  # Auth: subscription login and/or API key. `claude auth status` exits 0 when logged in.
  LOGGED_IN=0
  if with_timeout 20 claude auth status </dev/null >/dev/null 2>&1; then LOGGED_IN=1; fi
  if [ "$LOGGED_IN" = 1 ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    AUTH_MODE="both"
    row WARN "Claude Code auth" "logged in AND ANTHROPIC_API_KEY is set — in 'claude -p' the API key wins and is billed; interactive sessions ask once. Unset the key if you want subscription billing in Claude Code."
  elif [ "$LOGGED_IN" = 1 ]; then AUTH_MODE="subscription"; row PASS "Claude Code auth" "logged in (claude.ai or Console login)"
  elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then AUTH_MODE="apikey"; row PASS "Claude Code auth" "ANTHROPIC_API_KEY (Console billing)"
  else row FAIL "Claude Code auth" "not logged in and no ANTHROPIC_API_KEY — run 'claude' once and complete login (or 'claude auth login')"; fi
else
  row FAIL "claude CLI" "not found on PATH — install: curl -fsSL https://claude.ai/install.sh | bash   (see labs/SETUP.md)"
fi

# ============================================================================= 3. Toolchain
step "Toolchain"
if have git; then
  GV="$(git --version | first_version)"; GV="${GV:-0}"
  if ver_ge "$GV" "2.30"; then row PASS "git" "$GV"; else row WARN "git" "$GV (2.30+ recommended)"; fi
else row FAIL "git" "not found"; fi

if have gh; then
  if gh auth status >/dev/null 2>&1; then row PASS "gh (optional)" "authenticated"
  else row WARN "gh (optional)" "installed but not authenticated — 'gh auth login' (only needed for M4 Path B / M7 step 5 convenience)"; fi
else row WARN "gh (optional)" "not installed — fine; you can use the GitHub web UI instead"; fi

if have jq; then row PASS "jq" "$(jq --version 2>/dev/null)"
else row FAIL "jq" "not found — brew install jq | sudo apt install jq (used by hooks in M2 and scripts in M4)"; fi

NODE_VER="missing"
if have node; then
  NODE_VER="$(node --version 2>/dev/null | first_version)"; NODE_VER="${NODE_VER:-0.0.0}"; NODE_MAJOR="${NODE_VER%%.*}"
  if [ "$NODE_MAJOR" -ge "$MIN_NODE_MAJOR" ]; then row PASS "node" "v$NODE_VER"
  elif [ "$NODE_MAJOR" -ge 18 ]; then row WARN "node" "v$NODE_VER works but is past/near end-of-life; workshop standard is current LTS (${MIN_NODE_MAJOR}.x)"
  else row FAIL "node" "v$NODE_VER is too old (need >= 18, want ${MIN_NODE_MAJOR}.x LTS)"; fi
  if have npm; then row PASS "npm" "$(npm --version 2>/dev/null)"; else row FAIL "npm" "not found"; fi
else row FAIL "node" "not found — install Node.js LTS (needed for the lab MCP server and the TypeScript track)"; fi

PY_VER="missing"; PY=""
for cand in python3 python; do if have "$cand"; then PY="$cand"; break; fi; done
if [ -n "$PY" ]; then
  PY_VER="$($PY --version 2>&1 | first_version)"; PY_VER="${PY_VER:-0}"
  if ver_ge "$PY_VER" "$MIN_PY"; then row PASS "python" "$PY_VER ($PY)"
  elif ver_ge "$PY_VER" "3.9.6"; then row WARN "python" "$PY_VER — Claude Security plugin OK (>= 3.9.6) but the Agent SDK lab (M5) needs >= $MIN_PY"
  else row FAIL "python" "$PY_VER — need >= $MIN_PY (M5/M6) and >= 3.9.6 (M7)"; fi
else row FAIL "python3" "not found"; fi

if have uv; then row PASS "uv" "$(uv --version 2>/dev/null | first_version)"
elif [ -n "$PY" ] && $PY -m pip --version >/dev/null 2>&1; then row WARN "uv" "not installed — pip/venv works, but lab commands are written for uv (https://docs.astral.sh/uv/)"
else row FAIL "uv or pip" "neither found"; fi

if have docker; then row PASS "docker (optional)" "present (only used by M5/M6 stretch goals)"; fi

# ============================================================================= 4. API key & Managed Agents
step "Anthropic API key (needed for M4-B, M5, M6, M7 step 5)"
MA_STATUS="unknown"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  row PASS "ANTHROPIC_API_KEY set" "$(mask_key "$ANTHROPIC_API_KEY")"
  if [ "$OPT_NET" = 1 ] && have curl; then
    code="$(http_code "$API_HOST/v1/models?limit=1" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01")"
    case "$code" in
      200) row PASS "API key valid" "GET /v1/models -> 200" ;;
      401|403) row FAIL "API key valid" "GET /v1/models -> $code (revoked/typo/wrong workspace?) — create a new key in the Console" ;;
      000) row WARN "API key valid" "could not reach $API_HOST (see network section)" ;;
      *)   row WARN "API key valid" "unexpected HTTP $code — check Console billing/credits" ;;
    esac
    code="$(http_code "$API_HOST/v1/agents?limit=1" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "anthropic-beta: $MA_BETA")"
    case "$code" in
      200) MA_STATUS="yes"; row PASS "Managed Agents access (M6)" "GET /v1/agents -> 200 (beta header $MA_BETA)" ;;
      401|403|404) MA_STATUS="no"; row WARN "Managed Agents access (M6)" "HTTP $code — your Console org/workspace may not have Managed Agents enabled; open Console -> Agent quickstart to confirm, or plan to pair / use the instructor workspace key in M6" ;;
      000) row WARN "Managed Agents access (M6)" "network unreachable" ;;
      *)   row WARN "Managed Agents access (M6)" "unexpected HTTP $code — ask a facilitator" ;;
    esac
  fi
  case "${CMA_MODEL:-}" in
    ""|"<"*|sonnet|opus|haiku|default|opusplan)
      row WARN "CMA_MODEL (M6)" "labs/.env CMA_MODEL='${CMA_MODEL:-}' — Managed Agents needs a full model ID (Claude Code aliases 400); see reference §B" ;;
    *) row PASS "CMA_MODEL (M6)" "$CMA_MODEL" ;;
  esac
else
  row WARN "ANTHROPIC_API_KEY" "not set — fine for M0–M4 Path A and M7 steps 0–4; for M4-B/M5/M6/M7-5 you will pair or use an instructor key (see labs/SETUP.md 'Which modules need an API key')"
fi

# ============================================================================= 5. Network
if [ "$OPT_NET" = 1 ]; then
  step "Network reachability"
  if have curl; then
    # critical hosts FAIL when unreachable; supporting hosts only WARN (some CDNs do not answer HEAD on /)
    for entry in "FAIL $API_HOST" "FAIL https://github.com" "FAIL https://registry.npmjs.org" "FAIL https://pypi.org" \
                 "WARN https://claude.ai" "WARN https://platform.claude.com" "WARN https://api.github.com" \
                 "WARN https://downloads.claude.ai/claude-code-releases/stable" "WARN https://raw.githubusercontent.com"; do
      sev="${entry%% *}"; host="${entry#* }"
      code="$(http_code "$host" -I)"
      name="${host#https://}"; name="${name#http://}"; name="${name%%/*}"
      if [ "$code" = "000" ]; then row "$sev" "reach $name" "no HTTP response (proxy/firewall/VPN/captive portal?) — see labs/SETUP.md 'Corporate proxies'"
      else row PASS "reach $name" "HTTP $code"; fi
    done
    if [ -n "${HTTPS_PROXY:-${https_proxy:-}}" ]; then row WARN "proxy" "HTTPS_PROXY is set (${HTTPS_PROXY:-$https_proxy}); if TLS is inspected also set NODE_EXTRA_CA_CERTS / trust the CA in the OS store"; fi
  else
    row WARN "network" "curl not found; skipped"
  fi
fi

# ============================================================================= 6. Repos & labs/.env
step "Repositories and labs/.env"
if [ -f "$ENV_FILE" ]; then
  miss=""
  [ -n "$WORKSHOP_ORG" ] || miss="$miss WORKSHOP_ORG"
  [ -n "$GITHUB_USER" ] || miss="$miss GITHUB_USER"
  [ -n "$OTEL" ] || miss="$miss OTEL"
  [ -n "$REV" ] || miss="$miss REV"
  if [ -z "$miss" ]; then row PASS "labs/.env" "WORKSHOP_ORG=$WORKSHOP_ORG GITHUB_USER=$GITHUB_USER"
  else row WARN "labs/.env" "missing values:$miss"; fi
else
  row WARN "labs/.env" "not found — cp labs/env.example labs/.env and fill it in"
fi

if [ -n "$OTEL" ] && [ -d "$OTEL/.git" ]; then
  origin="$(git -C "$OTEL" remote get-url origin 2>/dev/null || echo '?')"
  head="$(git -C "$OTEL" rev-parse --short=12 HEAD 2>/dev/null || echo '?')"
  detail="$OTEL @ $head (origin $origin)"
  if [ -n "$OTEL_PINNED_SHA" ]; then
    case "$(git -C "$OTEL" rev-parse HEAD 2>/dev/null)" in
      "$OTEL_PINNED_SHA"*) row PASS "\$OTEL clone" "$detail — matches pinned SHA" ;;
      *) row WARN "\$OTEL clone" "$detail — HEAD differs from pinned ${OTEL_PINNED_SHA:0:12}; 'git -C \$OTEL checkout workshop && git pull' unless you changed it on purpose" ;;
    esac
  else row PASS "\$OTEL clone" "$detail"; fi
  [ -d "$OTEL/src" ] || row WARN "\$OTEL layout" "no src/ directory — is this really the opentelemetry-demo fork?"
else
  row FAIL "\$OTEL clone" "not found (OTEL='${OTEL:-unset}') — git clone https://github.com/${WORKSHOP_ORG:-<WORKSHOP_ORG>}/opentelemetry-demo and set OTEL in labs/.env"
fi

if [ -n "$REV" ] && [ -d "$REV/.git" ]; then
  origin="$(git -C "$REV" remote get-url origin 2>/dev/null || echo '?')"
  if [ -n "$GITHUB_USER" ] && printf '%s' "$origin" | grep -qi "[/:]$GITHUB_USER/"; then
    row PASS "\$REV clone" "$REV (origin $origin)"
  else
    row WARN "\$REV clone" "$REV origin is $origin — expected your own copy github.com/${GITHUB_USER:-<you>}/astroshop-reviews (Use this template -> clone). Needed for M4-B and M7."
  fi
  if [ "$OPT_FULL" = 1 ]; then
    if have uv && (cd "$REV" && with_timeout 180 uv run pytest -q >/dev/null 2>&1); then row PASS "\$REV tests" "pytest green"
    else row WARN "\$REV tests" "pytest did not pass (or uv missing) — cd \$REV && uv run pytest -q"; fi
  fi
else
  row WARN "\$REV clone" "not found (REV='${REV:-unset}') — needed from M4 Path B / M7; create github.com/<you>/astroshop-reviews from the ${WORKSHOP_ORG:-<WORKSHOP_ORG>} template and clone it"
fi

# ============================================================================= 7. Lab dependencies
step "Lab dependencies"
MCP_DIR="$WS/labs/mcp/astro-catalog"
if [ -f "$MCP_DIR/package.json" ]; then
  if [ -d "$MCP_DIR/node_modules" ]; then
    if have node && [ -f "$MCP_DIR/server.mjs" ] && (cd "$MCP_DIR" && with_timeout 30 node server.mjs --selftest >/dev/null 2>&1); then
      row PASS "MCP lab server" "astro-catalog selftest ok"
    else
      row PASS "MCP lab server" "dependencies installed (selftest skipped/unsupported)"
    fi
  elif [ "$OPT_INSTALL" = 1 ] && have npm; then
    if (cd "$MCP_DIR" && npm ci --silent >/dev/null 2>&1); then row PASS "MCP lab server" "npm ci done"
    else row WARN "MCP lab server" "npm ci failed — cd labs/mcp/astro-catalog && npm ci"; fi
  else
    row WARN "MCP lab server" "dependencies not installed — run: npm ci --prefix labs/mcp/astro-catalog   (or re-run preflight with --install)"
  fi
else
  row WARN "MCP lab server" "labs/mcp/astro-catalog not present in this checkout (pull latest workshop repo before the day)"
fi

PY_PROJ="$WS/labs/m5-agent-sdk/python"
if [ -n "$PY" ]; then
  if [ -f "$PY_PROJ/pyproject.toml" ] || [ -f "$PY_PROJ/starter/pyproject.toml" ]; then
    proj="$PY_PROJ"; [ -f "$proj/pyproject.toml" ] || proj="$PY_PROJ/starter"
    if [ "$OPT_INSTALL" = 1 ] && have uv; then (cd "$proj" && uv sync >/dev/null 2>&1) || true; fi
    if have uv && (cd "$proj" && with_timeout 60 uv run python -c 'import claude_agent_sdk, anthropic' >/dev/null 2>&1); then
      row PASS "Python SDKs (M5/M6)" "claude-agent-sdk + anthropic import ok (uv, $proj)"
    elif $PY -c 'import claude_agent_sdk, anthropic' >/dev/null 2>&1; then
      row PASS "Python SDKs (M5/M6)" "claude-agent-sdk + anthropic import ok ($PY)"
    else
      row WARN "Python SDKs (M5/M6)" "not importable yet — run: uv sync --project ${proj#"$WS"/}   (or: pip install claude-agent-sdk anthropic jsonschema)"
    fi
  else
    if $PY -c 'import claude_agent_sdk, anthropic' >/dev/null 2>&1; then row PASS "Python SDKs (M5/M6)" "importable ($PY)"
    else row WARN "Python SDKs (M5/M6)" "pip install claude-agent-sdk anthropic jsonschema  (lab project folder not present yet)"; fi
  fi
fi

if [ "$OPT_TS" = 1 ]; then
  TS_PROJ="$WS/labs/m5-agent-sdk/typescript"
  tsdir="$TS_PROJ"; [ -f "$tsdir/package.json" ] || tsdir="$TS_PROJ/starter"
  if [ -f "$tsdir/package.json" ]; then
    if [ -d "$tsdir/node_modules/@anthropic-ai/claude-agent-sdk" ]; then row PASS "TypeScript SDK track" "installed in ${tsdir#"$WS"/}"
    elif [ "$OPT_INSTALL" = 1 ] && (cd "$tsdir" && npm ci --silent >/dev/null 2>&1); then row PASS "TypeScript SDK track" "npm ci done"
    else row WARN "TypeScript SDK track" "run: npm ci --prefix ${tsdir#"$WS"/}"; fi
  else row WARN "TypeScript SDK track" "labs/m5-agent-sdk/typescript not present in this checkout"; fi
fi

if have claude; then
  PLUG_OUT="$(with_timeout 30 claude plugin list </dev/null 2>/dev/null || true)"
  if [ -z "$PLUG_OUT" ]; then
    row WARN "workshop plugins (M7)" "could not list plugins non-interactively — inside claude run /plugin and confirm claude-security + security-guidance are installed"
  else
    if printf '%s' "$PLUG_OUT" | grep -q 'claude-security@claude-plugins-official'; then row PASS "plugin claude-security" "installed"
    else row WARN "plugin claude-security" "not installed — run: claude plugin install claude-security@claude-plugins-official -s user"; fi
    if printf '%s' "$PLUG_OUT" | grep -q 'security-guidance@claude-plugins-official'; then
      row PASS "plugin security-guidance" "installed (keep it DISABLED until M7 step 4: claude plugin disable security-guidance@claude-plugins-official)"
    else row WARN "plugin security-guidance" "not installed — run: claude plugin install security-guidance@claude-plugins-official -s user && claude plugin disable security-guidance@claude-plugins-official"; fi
  fi
  row WARN "dynamic workflows (M7)" "manual check: open 'claude', run /config and confirm 'Dynamic workflows' is ON (Pro plans must opt in; some orgs disable it)"
fi

# ============================================================================= 8. Optional inference ping
PING_MODEL=""; PING_COST=""
if [ "$OPT_PING" = 1 ] && have claude; then
  step "Inference ping (one tiny prompt)"
  out="$(cd "${OTEL:-$WS}" 2>/dev/null || cd "$WS"; with_timeout 120 claude -p --max-turns 1 --output-format json "Reply with the single word: pong" 2>/dev/null || true)"
  if [ -n "$out" ] && have jq && printf '%s' "$out" | jq -e '.result' >/dev/null 2>&1; then
    res="$(printf '%s' "$out" | jq -r '.result' | tr -d '\r\n' | cut -c1-40)"
    PING_COST="$(printf '%s' "$out" | jq -r '.total_cost_usd // empty')"
    PING_MODEL="$(printf '%s' "$out" | jq -r '(.modelUsage // {}) | keys | join(",")' 2>/dev/null || true)"
    if printf '%s' "$res" | grep -qi pong; then row PASS "inference ping" "result='$res' model=${PING_MODEL:-?} cost=\$${PING_COST:-?}"
    else row WARN "inference ping" "got a reply but not 'pong': '$res'"; fi
  elif [ -n "$out" ]; then row WARN "inference ping" "reply was not JSON (install jq?) — first 80 chars: $(printf '%s' "$out" | head -c 80)"
  else row FAIL "inference ping" "no reply from 'claude -p' — auth, network, or org policy problem; run: claude -p \"say pong\""; fi
fi

# ============================================================================= report
say ""
say "${C_B}Results${C_0}"
printf '%s\n' "------+--------------------------------+-----------------------------------------------"
printf '%s' "$ROWS" | while IFS='|' read -r st name detail; do
  [ -n "$st" ] || continue
  case "$st" in PASS) col="$C_G";; WARN) col="$C_Y";; *) col="$C_R";; esac
  printf '%s%-5s%s | %-30s | %s\n' "$col" "$st" "$C_0" "$name" "$detail"
done
printf '%s\n' "------+--------------------------------+-----------------------------------------------"
say "PASS $N_PASS   WARN $N_WARN   FAIL $N_FAIL"
READY="READY"; [ "$N_FAIL" -eq 0 ] || READY="NOT READY"
say ""
say "${C_B}PREFLIGHT v4 | $OS_LABEL | claude $CLAUDE_VER | auth=$AUTH_MODE | node $NODE_VER | python $PY_VER | managed-agents=$MA_STATUS | $READY${C_0}"
say "${C_D}(paste the line above into the registration form; WARN rows are fine to bring to the room, FAIL rows are not)${C_0}"
[ "$N_FAIL" -eq 0 ]
