# `labs/checkpoints/` — checkpoint content contract (CP0–CP7)

`labs/checkpoint.sh CPn` fast-forwards a participant's working tree to the end state of module *n*
so nobody is blocked by an earlier module. This directory holds the **content** for each checkpoint;
`checkpoint.sh` holds the **mechanics** (copy, never overwrite without `--force`, back up, dry-run,
cumulative apply). Module authors own the files listed in the manifest table below; this README
defines where they must put them.

> [!NOTE]
> Checkpoints are **cumulative**: `checkpoint.sh CP5` applies CP1 → CP5 in order (use `--only` to
> apply a single one). Each `CPn/` therefore contains **only what module *n* adds or changes**, not a
> full snapshot. Files identical to what the participant already has are skipped silently; files that
> differ are reported and left alone unless `--force` is given (originals are then backed up to
> `<root>/.checkpoint-backup/<timestamp>/`).

## Directory contract

```
labs/checkpoints/
  CPn/
    DESCRIPTION          # required. Line 1 = one-line summary shown by --list. Further lines free text.
    files/               # optional. Literal files, copied preserving relative paths, grouped by root:
      OTEL/...           #   -> $OTEL/...          participant's clone of <WORKSHOP_ORG>/opentelemetry-demo
      OTEL_PARENT/...    #   -> $OTEL/../...       sibling dirs: codebase-toolkit/, workshop-marketplace/
      REV/...            #   -> $REV/...           participant's own astroshop-reviews clone (skipped if REV unset)
      WS/...             #   -> this workshop repo (rare; prefer manifest.txt for in-repo copies)
    manifest.txt         # optional. One instruction per line, for content that already lives elsewhere
                         # in this repo (avoids duplicating solution code):
                         #   copy <src-relative-to-repo-root> <ROOT>:<dest-relative-to-root>
                         # <src> may be a file or a directory. {LANG} expands to python|typescript.
                         # Lines starting with # are comments.
    post.sh              # optional. Idempotent bash run *after* copying, with cwd=$OTEL and these
                         # exported: WS OTEL OTEL_PARENT REV LANG_TRACK CHECKPOINT STAMP.
                         # Use for: npm ci, plugin marketplace add/install, git switch -c + git apply,
                         # running a success check. Must be safe to run twice. Must not prompt
                         # (pass -y / --yes). Print what you do. Exit non-zero only on real failure.
```

Rules for authors:

1. **Never put secrets or API keys in checkpoint content.** `labs/.env` is the only place keys live and it is git-ignored.
2. **Paths are relative and portable.** No absolute paths, no `~`. Hooks inside plugin content use `${CLAUDE_PLUGIN_ROOT}`; hooks in project settings use `"$CLAUDE_PROJECT_DIR"`.
3. **Model names are aliases** (`sonnet`, `opus`, `haiku`) in every Claude Code file; SDK code reads the alias `MODEL` and Managed Agents code reads the full model ID `CMA_MODEL` from `labs/.env`.
4. **`post.sh` is optional help, not the checkpoint.** A participant who runs with `--no-post` (or on a locked-down laptop) must still get every file. Put files in `files/` or `manifest.txt`; use `post.sh` only for commands.
5. **Keep CPn minimal and additive.** If module *n* edits a file created earlier (e.g. M7 hardens `.claude/settings.json` from M2), ship the full new version of that file in `CPn/files/…`; `checkpoint.sh` will report it as differing and replace it only with `--force` — say so in the module's "If you're behind" box (`./labs/checkpoint.sh CP7 --force`).
6. **Test with `--dry-run` on a clean clone and on a fully-worked clone** before each delivery; both must end without errors.
7. Keep content shell-agnostic (no symlinks, no bash-isms inside copied files) so a future PowerShell twin of `checkpoint.sh` could read the same directories; v4 ships the bash script only (Windows: Git Bash or WSL2).

## Manifest: what each checkpoint must contain

Owners: the writer of the module in the "Produced by" column. "Root" is the destination root token.

| Checkpoint | Produced by module | Root | Files / actions the checkpoint must provide |
|---|---|---|---|
| **CP0** | M0 `modules/00-welcome-and-platform-map.md` | — | *No content.* Built into `checkpoint.sh`: verifies `$OTEL` is a git clone and `labs/.env` exists, prints `working tree matches CP0`. |
| **CP1** | M1 `modules/01-claude-code-essentials.md` | OTEL | `CLAUDE.md` (the `/init` result plus the two workshop conventions: OTel span on new endpoints, table-driven Go tests) · `.claude/rules/proto.md` (path-scoped rule for `**/*.proto`, `pb/**`). Source of truth: `labs/m1/`. |
| **CP2** | M2 `modules/02-settings-hooks-and-mcp.md` | OTEL | `.claude/settings.json` (= `labs/m2/settings.project.json`: allow/ask/deny, `defaultMode`, `PreToolUse` + `PostToolUse` hooks; no `sandbox` block) · `.claude/hooks/protect-files.sh` (executable) · `.mcp.json` registering `astro-catalog` (stdio, `node ${WORKSHOP_REPO}/labs/mcp/astro-catalog/server.mjs` with env expansion) · `.env` dummy (`FAKE_KEY=123`) for the deny-rule demo. **post.sh:** `npm ci --prefix "$WS/labs/mcp/astro-catalog"`; `chmod +x .claude/hooks/*.sh`; remind to approve the project MCP server on next `claude` start. |
| **CP3** | M3 `modules/03-subagents-skills-and-plugins.md` | OTEL, OTEL_PARENT | OTEL_PARENT: `codebase-toolkit/` (complete plugin: `.claude-plugin/plugin.json` v4.0.0, `agents/service-documenter.md`, `agents/bug-hunter.md`, `skills/code-reviewer/SKILL.md` + `checklists/security.md`, `hooks/hooks.json` + `hooks/protect-files.sh`, `.mcp.json`) · `workshop-marketplace/.claude-plugin/marketplace.json` + `workshop-marketplace/codebase-toolkit/` copy. OTEL: nothing new (loose `.claude/agents|skills` are intentionally *not* re-added — the plugin supplies them). Prefer `manifest.txt` lines copying from `labs/m3/plugin`, `labs/m3/agents`, `labs/m3/skills`, `labs/m3/marketplace`. **post.sh:** `claude plugin marketplace add <WORKSHOP_ORG>/claude-marketplace` (user scope) → `claude plugin install codebase-toolkit@<marketplace-name> -s user -y`; run `labs/m3/dedupe.sh` to remove loose duplicates if present; print `claude plugin list`. |
| **CP4** | M4 `modules/04-automation-and-scale.md` | OTEL, REV | OTEL: `reports/adservice.findings.json` (captured sample output validating against `labs/shared/findings.schema.json`) · optional `README.md` written by the two-step session example. REV: `.github/workflows/claude.yml`, `.github/workflows/code-review.yml` (from `labs/m4/github/`). **post.sh:** none required (do **not** push on the participant's behalf; print the `git add/commit/push` commands instead). |
| **CP5** | M5 `modules/05-claude-agent-sdk.md` | WS | `manifest.txt`: `copy labs/m5-agent-sdk/{LANG}/solution WS:labs/m5-agent-sdk/{LANG}/starter` (solution over starter for the chosen track; participants' edited starter files are reported as conflicts → they re-run with `--force`). **post.sh:** `uv sync` (python) or `npm ci` (typescript) in the starter dir; if `ANTHROPIC_API_KEY` is set, run the step-1 success check (`bughunter src/paymentservice` with `max_budget_usd` cap) and print `Done: … $cost`; otherwise print how to run it. |
| **CP6** | M6 `modules/06-claude-managed-agents.md` | WS | `manifest.txt`: `copy labs/m6-managed-agents/{LANG}/solution WS:labs/m6-managed-agents/{LANG}/starter`. **post.sh:** if `ANTHROPIC_API_KEY` is set, run `deploy_toolkit_agent step1 step2 step3 --yes` (auto-allow confirmations) so the participant sees a full event stream; IDs cached in `.cma-state.json` for step 5. Without a key: print the pairing instructions and the path to `labs/m6-managed-agents/expected-output/`. |
| **CP7** | M7 `modules/07-securing-agentic-development.md` | REV, OTEL | REV: `CLAUDE-SECURITY-sample/` results (copied from the template's `.workshop/sample-results/`, i.e. `CLAUDE-SECURITY-RESULTS.md|.jsonl|.sarif`, `REVISION-<sha>.json`, `patches/F1.patch`, `patches/F2.patch`) · `.claude/security-patterns.yaml` · `.claude/claude-security-guidance.md` · `.github/workflows/security-review.yml` · `.github/security-instructions.md`. OTEL: hardened `.claude/settings.json` (= `labs/m7-security/settings.hardened.json`; differs from CP2's → needs `--force`, say so in the module). **post.sh:** in `$REV`: `git switch -c fix/f1-sqli` (or keep it if it exists) → `git apply --check` then `git apply` `patches/F1.patch` → `uv run pytest -q` → commit; `feat/avatar-proxy` with `.workshop/introduce-ssrf.patch` applied and committed (the branch step 5 pushes); `claude plugin enable security-guidance@claude-plugins-official`; never push. |

## Optional mirror: `solutions` branch tags

Facilitators may also push tags `cp1` … `cp4` on the `<WORKSHOP_ORG>/opentelemetry-demo` fork's
`solutions` branch that mirror CP1–CP4 for `$OTEL`. They are a convenience for people who prefer
`git checkout cp3 -- .claude CLAUDE.md`; `checkpoint.sh` remains the supported path because it also
covers `$OTEL/..`, `$REV` and this repo.

## Quick self-test for maintainers

```bash
export OTEL=/path/to/clean/opentelemetry-demo REV=/path/to/astroshop-reviews
./labs/checkpoint.sh --list                 # every CP1..CP7 row should say "ready" before a delivery
./labs/checkpoint.sh CP7 --dry-run          # full plan, no writes, no post scripts
./labs/checkpoint.sh CP3 && ./labs/checkpoint.sh CP3   # second run must report "working tree matches CP3"
```
