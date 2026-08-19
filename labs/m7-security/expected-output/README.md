# Module 7 — expected output kept in the workshop repo

Participant-facing captures for M7 live in the **template** repo under `$REV/.workshop/`:
`sample-results/CLAUDE-SECURITY-sample/` (scan report, JSONL, SARIF, stamp, patches) and `expected-output/`
(PR comment screenshot, Action run log, `/security-review` and change-scan transcripts). Source of truth for both:
`apps/astroshop-reviews/.workshop/` in this repository.

This folder holds instructor-side captures that should **not** ship in the template:

| File (maintainers add) | What |
|---|---|
| `workflows-view.png` | `/workflows` drill-in during a medium scan: Inventory → Threat model → Research → Sweep → Panel, one verifier open on its lens |
| `security-guidance-transcript.md` | step 4: the pattern warning with the custom reminder text and the end-of-turn re-prompt |
| `hardened-settings-merge.md` | the Close step: Claude merging `settings.hardened.json` into `$OTEL/.claude/settings.json` without dropping the M2 hooks |
| `timings.md` | measured durations from the last dry run (medium whole-repo scan, low change scan, `/security-review`, Action run) — copy into FACILITATOR.md |
