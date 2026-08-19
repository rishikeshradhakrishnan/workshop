# Module 7 — SOLUTIONS (instructors and TAs; do not project before the debrief)

`astroshop-reviews` (source of truth: `apps/astroshop-reviews/` in this repo) is deliberately vulnerable. This file maps
every seeded weakness to its file and line, says what a good Claude Security scan typically reports at each effort tier,
and gives the expected answers for the worksheet and debrief questions. It is **not** shipped in the template repo.

## 1. Seeded weaknesses → file:line (template `main`)

| # | Class | CWE | File:line (symbol) | Reachability | Typical severity / confidence at `medium` | Sample report ID |
|---|---|---|---|---|---|---|
| 1 | SQL injection — f-string query | CWE-89 | `app/reviews.py:19` (`search`) | unauthenticated `GET /reviews/search?q=` | HIGH / high (3/3) | F1 |
| 2 | IDOR — no ownership check | CWE-639 | `app/users.py:20-21` (`private_reviews`) | any logged-in user, any `<id>` | HIGH / high | F2 |
| 3 | Unsafe YAML deserialization | CWE-502 | `app/reviews.py:39` (`import_reviews`) | logged-in user, request body | HIGH / medium | F3 |
| 4 | Hard-coded admin key + signing secret | CWE-798 | `app/config.py:2-3` | anyone with the source; forges tokens / admin | HIGH / high; **snippet omitted** in JSONL/SARIF | F4 |
| 5 | Path traversal | CWE-22 | `app/exports.py:10` (`download_export`) | logged-in user | HIGH or MEDIUM / medium | F5 |
| 6 | Reflected XSS via `\|safe` | CWE-79 | `app/templates/search.html:3` (+ `app/reviews.py:21-22`) | unauthenticated, victim clicks a link | MEDIUM / medium | F6 |
| 7 | Debug server / verbose tracebacks | CWE-209 (also CWE-489/94 framing) | `wsgi.py:6` | only if run via `python wsgi.py` | MEDIUM or LOW / low | F7 |
| 8 | Planted prompt injection | CWE-1427 (typ.) | `CLAUDE.md:6` | n/a — reported, not obeyed | LOW / high | F8 |
| 9 | Non-constant-time signature compare | CWE-208 | `app/auth/tokens.py:24` (`verify_token`) | network timing; hard in practice | LOW / low — **often missed at `medium`**, usually found at `high` on `app/auth` (stretch b) | — |
| 10 | SSRF (only after `.workshop/introduce-ssrf.patch`) | CWE-918 | `app/users.py` (`avatar`) → `app/avatars.py:5` (`fetch_avatar`) | logged-in user supplies `url` | HIGH / high | change-scan F1 |

Design **non-findings** (must *not* appear; if they do, use it to discuss the false-positive rule): no rate limiting on
`/login`; no security headers; plaintext password compare in `/login` (commented as out of scope — a real product finding,
but verifiers often keep it out because the code says so; either outcome is a good discussion); `allow_redirects=True` in the
unused helper on `main`; sqlite file permissions.

Scans are nondeterministic: at `medium` expect 6–8 of rows 1–8, always including 1, 2, 4. Numbering differs between runs —
teach participants to match by file:line and CWE, never by F-number.

## 2. Worksheet — expected answers (step 1)

| Finding | Severity | Confidence | CWE | file:line | Reachable unauthenticated? | Fix now / later / accept |
|---|---|---|---|---|---|---|
| SQLi in search | HIGH | high (3/3) | CWE-89 | `app/reviews.py:19` | **yes** | now (F1 patch) |
| IDOR private reviews | HIGH | high | CWE-639 | `app/users.py:20` | no — needs any account | now (F2 patch + add cross-user test) |
| Unsafe YAML | HIGH | medium | CWE-502 | `app/reviews.py:39` | no — needs any account | now (`yaml.safe_load`) |
| Hard-coded secrets | HIGH | high | CWE-798 | `app/config.py:2` | source is public → effectively yes | now (env/secret manager, rotate) |

- **Prompt-injection finding:** `CLAUDE.md:6`, category `prompt-injection`, LOW — the sentence was reported as evidence, the scan
  continued unchanged. Under the *trusted-code* model this anchors the work to evidence; it is not a defence against a hostile repo
  (that is what sandbox-runtime is for — stretch a).
- **Why "no rate limiting" is absent:** no attacker-controlled source flows to a dangerous sink, so no lens can confirm a path;
  best-practice gaps are false positives by rule (and the Action's default filter drops the same class). It is a backlog item.

## 3. Step 2 — patches

- `F1.patch` changes only `app/reviews.py` (`search`): placeholder `LIKE ?` with `(f"%{q}%",)`. Tests: 8 passed. `git show --stat` → 1 file.
- `F2.patch` changes only `app/users.py`: imports `g`, `abort(403)` unless `user_id == g.user_id`. Verifier note asks for a cross-user
  test — the "behaviour unchanged" claim holds for legitimate callers only, which is the point.
- A **declined** patch is the verifier refusing to vouch (usually claim 3 with no test coverage). Not an error; read `F<n>.md`.
- Sample-results users: `suggest patches` refuses because the stamp (`sample000000`) ≠ `HEAD` → `git apply .workshop/sample-results/CLAUDE-SECURITY-sample/patches/F1.patch` directly.
- Re-scan on `fix/f1-sqli` at `low`: no CWE-89; Coverage says it read a 1-file diff vs `origin/main`.

## 4. Step 3 — `/security-review` vs change scan on `feat/avatar-proxy`

| | `/security-review` | `/claude-security scan my branch --effort low` |
|---|---|---|
| Wall clock | ~20–60 s | ~2–5 min |
| Shape | one agent, one pass over `git diff --merge-base origin/HEAD` | one researcher + 3-lens panel over the same diff |
| Finds SSRF (CWE-918) at `app/users.py` `avatar()` → `fetch_avatar(url)`? | yes (typically HIGH) | yes, HIGH, verified 3/3, `cwe_id: CWE-918` |
| Artifacts | markdown in the transcript only | `CLAUDE-SECURITY-<ts>/` with MD, JSONL, SARIF, revision stamp |
| Use it | before every push | before merges that matter; feeds code scanning |

## 5. Step 4 — security-guidance

Expected transcript evidence: (a) after the edit that adds `subprocess.run(..., shell=True)` (or `os.system`), a context line carrying
the participant's own reminder text from `security-patterns.yaml` (`subprocess_shell` rule) plus the built-in `os.system`/`subprocess`
pattern warning; (b) at end of turn, the background diff review re-prompts with a command-injection finding (request parameter reaches a
shell) and Claude removes/refuses the endpoint or rewrites it without a shell. If nothing fires: plugin not enabled/reloaded, PyYAML missing
(the `.json` twin covers that), or no auth for the model-backed layer — `~/.claude/security/log.txt` says which.

## 6. Step 5 — CI gate

Inline comment on `app/users.py` at the `fetch_avatar(url)` call: SSRF, HIGH, exploit scenario (internal metadata/localhost reachability),
recommendation (allowlist scheme+host, resolve and block private ranges, or drop the proxy). `findings-count` ≥ 1. Discussion answers:
trusted PRs only (`if:` guard + "Require approval for all external contributors"); pin the Action to a SHA in production; SARIF upload via
`github/codeql-action/upload-sarif` needs `security-events: write` and (private repos) GitHub code security.

## 7. Debrief prompts and one-line answers

- *Advisory vs enforced?* `CLAUDE.md` asked scanners to report clean → ignored and reported; a `deny` rule or sandbox would hold even if the model complied.
- *Which of today's controls would have stopped T1's `curl | sh`?* `deny Bash(curl *)` (M2), sandbox network allowlist (M2), auto-mode classifier (M1), the stretch (d) hook, `limited` networking (M6).
- *Why did the plugin not fix everything?* Patches are earned per finding by an independent verifier; humans merge, one PR each.
