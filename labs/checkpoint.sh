#!/usr/bin/env bash
# =============================================================================
# checkpoint.sh — fast-forward your working tree to a workshop checkpoint (CP0–CP7)
#
#   ./labs/checkpoint.sh --list                 # what each checkpoint contains
#   ./labs/checkpoint.sh CP3                    # apply CP1..CP3 (cumulative), never overwriting your edits
#   ./labs/checkpoint.sh CP3 --dry-run          # show what would be copied, change nothing
#   ./labs/checkpoint.sh CP3 --force            # overwrite differing files (originals are backed up first)
#   ./labs/checkpoint.sh CP5 --only --lang typescript
#
# Where files go is decided by four roots (read from the environment, labs/.env, or flags):
#   OTEL         your clone of <WORKSHOP_ORG>/opentelemetry-demo   (--target DIR)      [required]
#   OTEL_PARENT  the directory that contains $OTEL (codebase-toolkit/ and workshop-marketplace/ live here)
#   REV          your clone of <you>/astroshop-reviews             (--rev DIR)         [CP4, CP7]
#   WS           this workshop repository (auto-detected)
#
# Options:
#   --list            list checkpoints, the module that produces them, and whether content is present
#   --dry-run, -n     print the plan; copy nothing; run no post-apply script
#   --force, -f       overwrite files that differ from the checkpoint (backup to <root>/.checkpoint-backup/<stamp>/)
#   --only            apply only the named checkpoint instead of CP1..CPn
#   --no-post         skip the checkpoint's post-apply script (labs/checkpoints/CPn/post.sh)
#   --target DIR      set $OTEL      --rev DIR   set $REV      --lang python|typescript   set track for CP5/CP6
#   -h, --help        this text
#
# The content of each checkpoint lives in labs/checkpoints/CPn/ — see labs/checkpoints/README.md
# for the directory contract. This script only copies files and (optionally) runs CPn/post.sh;
# it never deletes anything and never overwrites without --force.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CP_ROOT="$SCRIPT_DIR/checkpoints"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi   # shellcheck disable=SC1090
WS="$(cd "$SCRIPT_DIR/.." && pwd)"                               # authoritative: the repo this script lives in

# ----------------------------------------------------------------------------- built-in catalogue
# (used by --list and messages; the files themselves come from labs/checkpoints/CPn/)
cp_module() {
  case "$1" in
    CP0) echo "M0  Welcome & preflight";;
    CP1) echo "M1  Claude Code essentials";;
    CP2) echo "M2  Settings, hooks & MCP";;
    CP3) echo "M3  Subagents, skills, plugins";;
    CP4) echo "M4  Automation & scale";;
    CP5) echo "M5  Claude Agent SDK";;
    CP6) echo "M6  Claude Managed Agents";;
    CP7) echo "M7  Securing agentic development";;
    *)   echo "?";;
  esac
}
cp_default_desc() {
  case "$1" in
    CP0) echo "Sanity check only: \$OTEL is a git clone, labs/.env exists. Copies nothing.";;
    CP1) echo "CLAUDE.md and .claude/rules/proto.md in \$OTEL.";;
    CP2) echo ".claude/settings.json, .claude/hooks/protect-files.sh, .mcp.json in \$OTEL; MCP lab server dependencies.";;
    CP3) echo ".claude/agents + skills (reference copies), ../codebase-toolkit plugin, ../workshop-marketplace; org plugin installed at user scope.";;
    CP4) echo "labs/m4 outputs (reports/*.findings.json) in \$OTEL; .github/workflows/{claude,code-review}.yml in \$REV.";;
    CP5) echo "Agent SDK 'bughunter' solution copied over the starter for your language track.";;
    CP6) echo "Managed Agents 'deploy_toolkit_agent' solution copied over the starter; runs steps 1-3 with --yes.";;
    CP7) echo "Sample Claude Security results, F1 patch branch, security-guidance config, security-review workflow, hardened settings.";;
  esac
}
ALL_CPS="CP0 CP1 CP2 CP3 CP4 CP5 CP6 CP7"

# ----------------------------------------------------------------------------- args
MODE="apply"; DRY=0; FORCE=0; ONLY=0; POST=1; TARGET_CP=""
LANG_TRACK="${TRACK:-${LANG_TRACK:-python}}"
while [ $# -gt 0 ]; do
  case "$1" in
    --list|-l) MODE="list";;
    --dry-run|-n) DRY=1;;
    --force|-f) FORCE=1;;
    --only) ONLY=1;;
    --no-post) POST=0;;
    --target) shift; OTEL="${1:-}";;
    --target=*) OTEL="${1#--target=}";;
    --rev) shift; REV="${1:-}";;
    --rev=*) REV="${1#--rev=}";;
    --lang) shift; LANG_TRACK="${1:-python}";;
    --lang=*) LANG_TRACK="${1#--lang=}";;
    -h|--help) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    CP[0-7]|cp[0-7]) TARGET_CP="$(printf '%s' "$1" | tr 'cp' 'CP')";;
    [0-7]) TARGET_CP="CP$1";;
    *) echo "checkpoint: unknown argument '$1' (try --help)" >&2; exit 2;;
  esac
  shift
done
case "$LANG_TRACK" in python|typescript) ;; py) LANG_TRACK=python;; ts) LANG_TRACK=typescript;;
  *) echo "checkpoint: --lang must be python or typescript" >&2; exit 2;; esac

if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; Z=$'\033[0m'; else B=""; D=""; G=""; Y=""; R=""; Z=""; fi
info() { printf '%s\n' "$*"; }
warn() { printf '%s!%s %s\n' "$Y" "$Z" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$R" "$Z" "$*" >&2; exit 1; }

has_content() { # CPn -> 0 if the checkpoint directory carries files or a manifest
  local d="$CP_ROOT/$1"
  [ -d "$d/files" ] || [ -f "$d/manifest.txt" ] || [ -f "$d/post.sh" ]
}
desc_of() {
  local d="$CP_ROOT/$1/DESCRIPTION"
  if [ -f "$d" ]; then head -n1 "$d"; else cp_default_desc "$1"; fi
}

# ----------------------------------------------------------------------------- --list
if [ "$MODE" = list ]; then
  info "${B}Workshop v4 checkpoints${Z}  (content directory: labs/checkpoints/)"
  info ""
  printf '%-4s  %-34s  %-8s  %s\n' "ID" "Produced by" "Content" "What you get"
  printf '%-4s  %-34s  %-8s  %s\n' "----" "----------------------------------" "--------" "------------"
  for cp in $ALL_CPS; do
    if [ "$cp" = CP0 ]; then st="builtin"; elif has_content "$cp"; then st="ready"; else st="pending"; fi
    printf '%-4s  %-34s  %-8s  %s\n' "$cp" "$(cp_module "$cp")" "$st" "$(desc_of "$cp")"
  done
  info ""
  info "Apply with: ./labs/checkpoint.sh CPn   (cumulative CP1..CPn; add --dry-run to preview, --force to overwrite)"
  exit 0
fi

[ -n "$TARGET_CP" ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

# ----------------------------------------------------------------------------- resolve roots
OTEL="${OTEL:-}"; REV="${REV:-}"
if [ -z "$OTEL" ]; then
  # convenience: `cd $OTEL && $WS/labs/checkpoint.sh CPn` works even without labs/.env
  here="$(pwd)"
  if [ "$here" != "$WS" ] && git -C "$here" rev-parse --show-toplevel >/dev/null 2>&1; then
    OTEL="$(git -C "$here" rev-parse --show-toplevel)"
    info "note: OTEL not set; using the git repository you are in: $OTEL"
  fi
fi
[ -n "$OTEL" ] || die "OTEL is not set. Run this from inside your opentelemetry-demo clone, pass --target <path>, or set OTEL in labs/.env"
case "$OTEL" in "$WS"|"$WS"/*) die "OTEL points inside the workshop repo ($OTEL); it must be your opentelemetry-demo clone";; esac
[ -d "$OTEL" ] || die "OTEL='$OTEL' is not a directory"
OTEL="$(cd "$OTEL" && pwd)"
OTEL_PARENT="$(dirname "$OTEL")"
if [ -n "$REV" ] && [ -d "$REV" ]; then REV="$(cd "$REV" && pwd)"; fi
STAMP="$(date '+%Y%m%d-%H%M%S')"
export WS OTEL OTEL_PARENT REV LANG_TRACK STAMP

root_path() { # ROOT token -> absolute path (or empty if unavailable)
  case "$1" in
    OTEL) printf '%s' "$OTEL";;
    OTEL_PARENT) printf '%s' "$OTEL_PARENT";;
    WS) printf '%s' "$WS";;
    REV) [ -n "$REV" ] && [ -d "$REV" ] && printf '%s' "$REV" || printf '';;
    *) printf '';;
  esac
}

# ----------------------------------------------------------------------------- copy engine
N_NEW=0; N_SAME=0; N_CONFLICT=0; N_OVER=0; N_SKIPROOT=0; N_PENDING=0
copy_one() { # abs-src abs-dest root-abs
  local src="$1" dst="$2" root="$3" rel bdir
  rel="${dst#"$root"/}"
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then N_SAME=$((N_SAME+1)); [ "$DRY" = 1 ] && printf '  %s= %s%s\n' "$D" "$rel" "$Z"; return 0; fi
    if [ "$FORCE" = 1 ]; then
      N_OVER=$((N_OVER+1))
      printf '  %s~ %s%s (overwrite; backup kept)\n' "$Y" "$rel" "$Z"
      if [ "$DRY" = 0 ]; then
        bdir="$root/.checkpoint-backup/$STAMP/$(dirname "$rel")"
        mkdir -p "$bdir" && cp -p "$dst" "$bdir/"
        cp -p "$src" "$dst"
      fi
    else
      N_CONFLICT=$((N_CONFLICT+1))
      printf '  %s! %s%s differs from the checkpoint — kept yours (re-run with --force to replace)\n' "$R" "$rel" "$Z"
    fi
  else
    N_NEW=$((N_NEW+1))
    printf '  %s+ %s%s\n' "$G" "$rel" "$Z"
    if [ "$DRY" = 0 ]; then mkdir -p "$(dirname "$dst")" && cp -p "$src" "$dst"; fi
  fi
}
copy_tree() { # abs-src(file|dir) abs-dest root-abs
  local src="$1" dst="$2" root="$3" f
  if [ -d "$src" ]; then
    while IFS= read -r -d '' f; do
      copy_one "$f" "$dst/${f#"$src"/}" "$root"
    done < <(find "$src" \( -name node_modules -o -name .venv -o -name __pycache__ -o -name .pytest_cache \) -prune -o \
                  -type f ! -name '.DS_Store' ! -name '.gitkeep' ! -name '*.pyc' -print0)   # never copy local build artefacts
  elif [ -f "$src" ]; then
    copy_one "$src" "$dst" "$root"
  else
    warn "source missing in workshop repo: ${src#"$WS"/} (checkpoint content not yet authored?)"
  fi
}

apply_cp() { # CPn
  local cp="$1" dir="$CP_ROOT/$1" tok rootp line src spec dst
  info ""
  info "${B}== $cp — $(cp_module "$cp")${Z}"
  info "   $(desc_of "$cp")"
  if [ "$cp" = CP0 ]; then
    if [ -d "$OTEL/.git" ] || git -C "$OTEL" rev-parse --git-dir >/dev/null 2>&1; then info "   \$OTEL is a git checkout: $OTEL"; else die "\$OTEL ($OTEL) is not a git clone"; fi
    if [ -f "$ENV_FILE" ]; then info "   labs/.env present"; else warn "labs/.env missing — cp labs/env.example labs/.env"; fi
    info "   ${G}working tree matches CP0${Z}"
    return 0
  fi
  if ! has_content "$cp"; then
    N_PENDING=$((N_PENDING+1))
    warn "$cp has no content in labs/checkpoints/$cp yet (see labs/checkpoints/README.md). Nothing to do."
    return 0
  fi
  # 1) files/<ROOT>/... trees
  if [ -d "$dir/files" ]; then
    for tok in OTEL OTEL_PARENT REV WS; do
      [ -d "$dir/files/$tok" ] || continue
      rootp="$(root_path "$tok")"
      if [ -z "$rootp" ]; then N_SKIPROOT=$((N_SKIPROOT+1)); warn "$cp: files for \$$tok skipped — $tok is not set/does not exist (pass --rev DIR for REV)"; continue; fi
      info "   -> \$$tok ($rootp)"
      copy_tree "$dir/files/$tok" "$rootp" "$rootp"
    done
  fi
  # 2) manifest.txt lines:  copy <src-relative-to-WS> <ROOT>:<dest-relative-to-root>   ({LANG} expands to the track)
  if [ -f "$dir/manifest.txt" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%%#*}"; line="$(printf '%s' "$line" | sed 's/[[:space:]]*$//')"
      [ -n "$line" ] || continue
      # shellcheck disable=SC2086
      set -- $line
      [ "${1:-}" = copy ] && [ $# -eq 3 ] || { warn "$cp manifest: ignoring malformed line: $line"; continue; }
      src="${2//\{LANG\}/$LANG_TRACK}"; spec="${3//\{LANG\}/$LANG_TRACK}"
      tok="${spec%%:*}"; dst="${spec#*:}"
      rootp="$(root_path "$tok")"
      if [ -z "$rootp" ]; then N_SKIPROOT=$((N_SKIPROOT+1)); warn "$cp: '$line' skipped — \$$tok not available"; continue; fi
      info "   -> \$$tok/$dst  (from $src)"
      copy_tree "$WS/$src" "$rootp/$dst" "$rootp"
    done < "$dir/manifest.txt"
  fi
  # 3) post.sh
  if [ -f "$dir/post.sh" ]; then
    if [ "$DRY" = 1 ]; then info "   (dry-run) would run labs/checkpoints/$cp/post.sh"
    elif [ "$POST" = 0 ]; then info "   skipped post.sh (--no-post)"
    else
      info "   running labs/checkpoints/$cp/post.sh ..."
      if ( cd "$OTEL" && CHECKPOINT="$cp" bash "$dir/post.sh" ); then info "   post.sh ok"; else warn "$cp post.sh exited non-zero — read its output above; files were still copied"; fi
    fi
  fi
}

# ----------------------------------------------------------------------------- run
n="${TARGET_CP#CP}"
info "${B}checkpoint $TARGET_CP${Z}  ${D}(OTEL=$OTEL  REV=${REV:-unset}  track=$LANG_TRACK  dry-run=$DRY force=$FORCE only=$ONLY)${Z}"
if [ "$ONLY" = 1 ] || [ "$n" = 0 ]; then
  apply_cp "$TARGET_CP"
else
  apply_cp CP0
  i=1
  while [ "$i" -le "$n" ]; do apply_cp "CP$i"; i=$((i+1)); done
fi

info ""
info "${B}Summary${Z}: added $N_NEW, already identical $N_SAME, overwritten $N_OVER, kept-yours (conflicts) $N_CONFLICT, skipped-roots $N_SKIPROOT$([ "$DRY" = 1 ] && printf '  [dry-run: nothing was written]')"
if [ "$N_OVER" -gt 0 ] && [ "$DRY" = 0 ]; then info "Backups of overwritten files: <root>/.checkpoint-backup/$STAMP/"; fi
if [ "$N_CONFLICT" -gt 0 ]; then
  info "${Y}Some files differ from $TARGET_CP and were left untouched.${Z} If your version works, carry on. If you want the reference version: re-run with --force."
  exit 3
fi
if [ "$N_PENDING" -gt 0 ]; then info "${Y}$N_PENDING checkpoint(s) had no content in this checkout — pull the latest workshop repo or ask a TA.${Z}"
elif [ "$N_NEW" -eq 0 ] && [ "$N_OVER" -eq 0 ]; then info "${G}working tree matches $TARGET_CP${Z}"; else info "${G}now at $TARGET_CP${Z} — restart any running 'claude' session so it reloads settings, hooks and plugins."; fi
