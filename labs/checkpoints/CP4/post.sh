#!/usr/bin/env bash
# CP4 post-apply (cwd = $OTEL): make scripts executable and PRINT (never run) the git/gh commands for Path B.
set -uo pipefail
chmod +x reports/m4/*.sh reports/m4/*.py 2>/dev/null || true
if command -v jq >/dev/null 2>&1 && [ -f reports/adservice.findings.json ]; then
  echo "reports/adservice.findings.json: $(jq -r '"\(.subtype)  findings=\(.structured_output.findings|length)  cost=$\(.total_cost_usd)"' reports/adservice.findings.json)  (captured sample)"
fi
if [ -n "${REV:-}" ] && [ -d "$REV/.github/workflows" ]; then
  cat <<EOF
Path B workflows are in \$REV/.github/workflows/. To activate them YOU push (the checkpoint never pushes or sets secrets):
  cd "$REV"
  gh secret set ANTHROPIC_API_KEY -b "\$ANTHROPIC_API_KEY"
  git add .github/workflows/claude.yml .github/workflows/code-review.yml
  git commit -m "Add Claude Code workflows" && git push origin main
  gh pr create --head demo/add-export-endpoint --base main --title "Add CSV export endpoint" --body "Please review."
EOF
else
  echo "REV not set or missing — skipped the GitHub Action workflows (Path B). Set REV in labs/.env and re-run if you want them."
fi
echo "Path A replay:  cd \$OTEL && \$WS/labs/m4/bug-hunt.sh src/adservice > reports/adservice.findings.json"
