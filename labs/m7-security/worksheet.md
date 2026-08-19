# Module 7 worksheet (fill in a scratch copy OUTSIDE `$REV` — keep the tree clean for patches)

## Step 1 — triage (top three findings from `CLAUDE-SECURITY-RESULTS.md`)

| Finding | Title | Severity | Confidence (votes) | CWE | `file:line` | Reachable unauthenticated? | Fix now / later / accept |
|---|---|---|---|---|---|---|---|
| F__ | | | | | | | |
| F__ | | | | | | | |
| F__ | | | | | | | |

- Prompt-injection finding: file ______ line ___ — what did the scan do with the instruction? ______________________
- One "finding" that is *not* in the report and why (one sentence): _____________________________________________
- Coverage: which directories were skipped, with what reason? _____________________________________________________

## Step 2 — patch

- Patch applied: F__ → branch `fix/________` · tests: ___ passed · `git show --stat`: ___ file(s)
- The three claims in `F__.md`: targeted ☐ · no new vulnerability ☐ · behaviour unchanged ☐ — any caveat? __________
- Declined patch (if any) and the verifier's reason: ______________________________________________________________

## Step 3 — single pass vs change scan on `feat/avatar-proxy`

| Tool | Seconds | Found SSRF (CWE-918) in `app/users.py`? | Verified by panel? | Artifact produced |
|---|---|---|---|---|
| `/security-review` | | | | |
| `/claude-security scan my branch --effort low` | | | | |

When would you use each? ________________________________________________________________________________

## Step 4 — security-guidance

- Reminder text you saw from *your* `security-patterns` rule: "______________________________________________"
- End-of-turn review finding and what Claude did about it: ______________________________________________________

## Step 5 — CI gate

- PR URL: __________________ · `Security Review` check: ☐ passed ☐ commented · `findings-count`: ___
- One thing you must configure in a real repo before trusting this gate: ________________________________________

## Close — hardening `$OTEL/.claude/settings.json`

Keys you merged from `labs/m7-security/settings.hardened.json`: ☐ `disableBypassPermissionsMode` ☐ `sandbox.enabled` + `allowUnsandboxedCommands:false`
☐ `sandbox.credentials` deny ☐ `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` ☐ `enabledPlugins` security-guidance · kept your M2 `hooks` block? ☐
