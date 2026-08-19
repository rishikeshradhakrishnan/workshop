#!/usr/bin/env bash
# =============================================================================
# labs/m3/dedupe.sh — remove the loose copies that the codebase-toolkit plugin now provides (Module 3, step 11)
#
#   $WS/labs/m3/dedupe.sh                 # from anywhere, with OTEL exported (labs/.env) or run inside $OTEL
#   $WS/labs/m3/dedupe.sh --dry-run       # show what would change
#   $WS/labs/m3/dedupe.sh --yes           # non-interactive: remove loose agents/skill; do NOT touch .mcp.json/settings.json
#   $WS/labs/m3/dedupe.sh --yes --prune-config   # also drop the astro-catalog .mcp.json entry and the two M2 hook entries
#
# What it does (idempotent; prints every action; backs files up to $OTEL/.checkpoint-backup/dedupe-<stamp>/):
#   1. removes $OTEL/.claude/agents/service-documenter.md and bug-hunter.md      (plugin agents are namespaced
#      codebase-toolkit:<name>, but loose project agents with the same name override them)
#   2. removes $OTEL/.claude/skills/code-reviewer/                                (two /code-reviewer entries confuse)
#   3. asks (y/N) whether to also remove the "astro-catalog" server from $OTEL/.mcp.json and the PreToolUse
#      protect-files + PostToolUse bash-audit hook entries from $OTEL/.claude/settings.json, because the plugin
#      ships both (hooks/hooks.json, .mcp.json). Default is No: keeping them is harmless (you just see two servers).
# Requires jq only for step 3.
# =============================================================================
set -euo pipefail

DRY=0; YES=0; PRUNE=0; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY=1;;
    --yes|-y) YES=1;;
    --prune-config) PRUNE=1;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) TARGET="$1";;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
if [ -z "${OTEL:-}" ] && [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi   # shellcheck disable=SC1090
if [ -n "$TARGET" ]; then OTEL="$TARGET"; fi
if [ -z "${OTEL:-}" ]; then
  if git rev-parse --show-toplevel >/dev/null 2>&1; then OTEL="$(git rev-parse --show-toplevel)"; else
    echo "dedupe: OTEL is not set and you are not inside a git checkout. Export OTEL or pass the path." >&2; exit 2; fi
fi
OTEL="$(cd "$OTEL" && pwd)"
STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP="$OTEL/.checkpoint-backup/dedupe-$STAMP"

say() { printf '%s\n' "$*"; }
backup() { # path relative to OTEL
  local rel="$1"
  [ "$DRY" = 1 ] && return 0
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -pR "$OTEL/$rel" "$BACKUP/$(dirname "$rel")/"
}
remove_path() {
  local rel="$1"
  if [ -e "$OTEL/$rel" ]; then
    say "  - remove $rel"
    backup "$rel"
    [ "$DRY" = 1 ] || rm -rf "${OTEL:?}/$rel"
    CHANGED=$((CHANGED+1))
  else
    say "  = $rel already absent"
  fi
}
confirm() { # question -> 0 yes / 1 no
  if [ "$PRUNE" = 1 ]; then return 0; fi
  if [ "$YES" = 1 ] || [ ! -t 0 ]; then return 1; fi
  local ans; read -r -p "$1 [y/N] " ans; case "$ans" in y|Y|yes) return 0;; *) return 1;; esac
}

CHANGED=0
say "dedupe: OTEL=$OTEL$([ "$DRY" = 1 ] && printf '  (dry-run)')"
say "1) loose subagents that the plugin now provides"
remove_path ".claude/agents/service-documenter.md"
remove_path ".claude/agents/bug-hunter.md"
say "2) loose skill that the plugin now provides"
remove_path ".claude/skills/code-reviewer"

say "3) optional: project MCP entry and M2 hook entries duplicated by the plugin"
if ! command -v jq >/dev/null 2>&1; then
  say "  ! jq not found — skipping step 3 (edit .mcp.json / .claude/settings.json by hand if you want)"
else
  MCP="$OTEL/.mcp.json"
  if [ -f "$MCP" ] && jq -e '.mcpServers["astro-catalog"]' "$MCP" >/dev/null 2>&1; then
    if confirm "   Remove the 'astro-catalog' server from .mcp.json (the plugin bundles it as plugin:codebase-toolkit:astro-catalog)?"; then
      say "  - .mcp.json: drop mcpServers.astro-catalog"
      backup ".mcp.json"
      if [ "$DRY" = 0 ]; then tmp="$(mktemp)"; jq 'del(.mcpServers["astro-catalog"])' "$MCP" > "$tmp" && mv "$tmp" "$MCP"; fi
      CHANGED=$((CHANGED+1))
    else say "  = kept .mcp.json as is"; fi
  else
    say "  = .mcp.json has no astro-catalog entry"
  fi
  SETTINGS="$OTEL/.claude/settings.json"
  if [ -f "$SETTINGS" ] && jq -e '[.hooks.PreToolUse[]?.hooks[]?.command, .hooks.PostToolUse[]?.hooks[]?.command] | map(select(. != null)) | map(test("protect-files|bash-audit")) | any' "$SETTINGS" >/dev/null 2>&1; then
    if confirm "   Remove the protect-files (PreToolUse) and bash-audit (PostToolUse) hook entries from .claude/settings.json (the plugin's hooks/hooks.json provides them)?"; then
      say "  - .claude/settings.json: drop the two M2 hook entries (other hooks are kept)"
      backup ".claude/settings.json"
      if [ "$DRY" = 0 ]; then
        tmp="$(mktemp)"
        jq '
          def prune(ev; pat): if .hooks[ev] then
              .hooks[ev] |= (map(.hooks |= map(select((.command // "") | test(pat) | not))) | map(select((.hooks | length) > 0)))
            else . end;
          prune("PreToolUse"; "protect-files") | prune("PostToolUse"; "bash-audit")
          | if (.hooks.PreToolUse // [] | length) == 0 then del(.hooks.PreToolUse) else . end
          | if (.hooks.PostToolUse // [] | length) == 0 then del(.hooks.PostToolUse) else . end
          | if (.hooks // {} | length) == 0 then del(.hooks) else . end
        ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
      fi
      CHANGED=$((CHANGED+1))
    else say "  = kept .claude/settings.json hooks as is"; fi
  else
    say "  = no M2 hook entries found in .claude/settings.json"
  fi
fi

if [ "$CHANGED" -gt 0 ] && [ "$DRY" = 0 ]; then say "done: $CHANGED change(s); backups in ${BACKUP#"$OTEL"/}. Restart 'claude' (or /reload-plugins) to pick up the plugin versions."
elif [ "$DRY" = 1 ]; then say "dry-run: $CHANGED change(s) would be made"
else say "nothing to do — no loose duplicates present"; fi
