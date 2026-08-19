# `.workshop/` — assets used verbatim in Module 7 (and M4 Path B)

| File | Used in | Purpose |
|---|---|---|
| `introduce-ssrf.patch` | M7 step 3 | `git apply` on a branch from `main`: adds `GET /users/<id>/avatar?url=` → `fetch_avatar(url)` (SSRF, CWE-918) |
| `security-review.yml` | M7 step 5 | copy to `.github/workflows/`; `anthropics/claude-code-security-review@main`, `claude-model: ${{ vars.CLAUDE_MODEL }}` |
| `security-instructions.md` | M7 step 5 | copy to `.github/security-instructions.md`; custom scan categories for the Action |
| `security-patterns.yaml` / `.json` | M7 step 4 | copy to `.claude/`; per-edit rules for the security-guidance plugin (JSON twin needs no PyYAML) |
| `claude-security-guidance.md` | M7 step 4 | copy to `.claude/`; plain-language checklist for security-guidance's model-backed reviews |
| `sample-results/CLAUDE-SECURITY-sample/` | M7 steps 1–2 fallback, CP7 | a prior medium-effort Claude Security scan of `main`: `…RESULTS.md|.jsonl|.sarif`, revision stamp, `patches/` |
| `expected-output/` | M7 step 5 fallback | PR comment screenshot, Action run log, transcripts (maintainers regenerate) |
| `maintainers/` | repo setup | `demo-add-export-endpoint.patch` → create branch `demo/add-export-endpoint` for the M4 Path B PR |

Maintainers: regenerate `sample-results/` with the current plugin version each quarter (delete the scan directory's own
`.gitignore` before committing it here) and confirm the findings still map to `labs/m7-security/SOLUTIONS.md` in the workshop repo.
