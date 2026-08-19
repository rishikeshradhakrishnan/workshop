# Module 7 — lab assets in the workshop repo

```
labs/m7-security/
  SOLUTIONS.md              instructor answer key: seeded weakness → file:line/CWE, worksheet answers, debrief   (never in the template)
  worksheet.md              the triage/compare worksheet participants fill in (copy it somewhere outside $REV)
  settings.hardened.json    the Close step: keys to merge into $OTEL/.claude/settings.json (CP7 ships it; needs --force over CP2's file)
  compare_findings.py       stretch (c): overlap between bughunter/`claude -p` findings and Claude Security JSONL
  hooks/block-curl-pipe-sh.sh   stretch (d): PreToolUse Bash hook that denies curl|sh with a JSON permissionDecision
  hooks/config-change-audit.sh  stretch (e): ConfigChange hook that logs settings changes and blocks removal of deny rules
  expected-output/          instructor-side captures (see its README)
```

Everything the lab copies *inside* `$REV` comes from the template's `.workshop/` folder (source: `apps/astroshop-reviews/.workshop/`).
