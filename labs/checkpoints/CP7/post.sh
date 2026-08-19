#!/usr/bin/env bash
# CP7 post-apply (cwd = $OTEL; works in $REV): F1 patch on fix/f1-sqli, SSRF branch feat/avatar-proxy, security-guidance on.
# Idempotent: existing branches are reused; a dirty tree skips the git steps with a message. NEVER pushes or opens PRs.
set -uo pipefail
if [ -z "${REV:-}" ] || [ ! -d "$REV/.git" ]; then
  echo "REV not set / not a git clone — skipped the astroshop-reviews steps. Set REV in labs/.env (or --rev DIR) and re-run: ./labs/checkpoint.sh CP7 --only"
else
  cd "$REV"
  SAMPLE="$REV/CLAUDE-SECURITY-sample"
  SSRF="$REV/.workshop/introduce-ssrf.patch"
  BASE=main; git rev-parse --verify -q main >/dev/null || BASE="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; BASE="${BASE:-main}"
  START="$(git rev-parse --abbrev-ref HEAD)"
  run_tests() { if command -v uv >/dev/null 2>&1; then uv run pytest -q; else python3 -m pytest -q; fi; }
  # only tracked-file changes block branch work; the untracked .claude/.github/CLAUDE-SECURITY-sample files we just copied are fine
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "! \$REV has uncommitted changes to tracked files — commit or 'git stash' them, then re-run CP7 (--only). Skipping git steps."
  else
    # --- fix/f1-sqli: apply the sample F1 patch, prove tests, commit
    if git rev-parse --verify -q fix/f1-sqli >/dev/null; then echo "= branch fix/f1-sqli exists (kept)"
    elif git apply --check "$SAMPLE/patches/F1.patch" 2>/dev/null; then
      git switch -q -c fix/f1-sqli "$BASE" && git apply "$SAMPLE/patches/F1.patch" && echo "+ fix/f1-sqli: applied F1.patch"
      if run_tests; then git commit -qam "Fix SQL injection in review search" && echo "+ committed (tests green)"; else echo "! tests failed — left uncommitted for you to inspect"; fi
    else
      echo "! F1.patch does not apply cleanly to $BASE (did you already fix it, or edit app/reviews.py?) — skipping fix/f1-sqli"
    fi
    git switch -q "$BASE" 2>/dev/null || true
    # --- feat/avatar-proxy: introduce the SSRF the lab scans and gates
    if git rev-parse --verify -q feat/avatar-proxy >/dev/null; then echo "= branch feat/avatar-proxy exists (kept)"; git switch -q feat/avatar-proxy
    elif [ -f "$SSRF" ] && git apply --check "$SSRF" 2>/dev/null; then
      git switch -q -c feat/avatar-proxy "$BASE" && git apply "$SSRF" && git add app && git commit -qm "Add avatar proxy endpoint" && echo "+ feat/avatar-proxy: SSRF endpoint committed (this is the branch step 5 pushes)"
    else
      echo "! .workshop/introduce-ssrf.patch missing or does not apply — skipping feat/avatar-proxy"; git switch -q "$START" 2>/dev/null || true
    fi
    echo "  now on branch: $(git rev-parse --abbrev-ref HEAD)   (started on: $START)"
  fi
  echo "  sample report: ${SAMPLE#"$REV"/}/CLAUDE-SECURITY-RESULTS.md   (R=CLAUDE-SECURITY-sample/ for the step-1 commands)"
  echo "  step 5 by hand: git add .github .claude && git commit -m 'Add Claude security review gate and security-guidance rules' && git push -u origin feat/avatar-proxy && gh pr create ..."
fi
if command -v claude >/dev/null 2>&1; then
  echo "\$ claude plugin enable security-guidance@claude-plugins-official"
  claude plugin enable security-guidance@claude-plugins-official </dev/null 2>/dev/null || echo "  (not installed? claude plugin install security-guidance@claude-plugins-official -s user)"
fi
cd "$OTEL" && if ! cmp -s "$WS/labs/checkpoints/CP7/files/OTEL/.claude/settings.json" .claude/settings.json 2>/dev/null; then
  echo "NOTE: \$OTEL/.claude/settings.json differs from the hardened CP7 version (expected if you came from CP2). Re-run with --force to take it, or merge labs/m7-security/settings.hardened.json by hand."
fi
