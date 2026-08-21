# FACILITATOR.md — instructor & TA runbook (Workshop v4, August 2026)

Read [Workshop-Guide-v4.md](Workshop-Guide-v4.md) first (audience, agenda, conventions). This file is the
operational layer: what to provision, when, how to run the day to the clock, what to cut when late, how
to recover a room, what you must decide before delivery, and what to do afterwards. It contains no
teaching content — that is in [`modules/`](modules/).

Contents: [1 What you own](#1-what-you-own) · [2 T-14: provisioning](#2-t-14-days-provisioning) · [3 T-7](#3-t-7-days-participants-dry-run-recordings) · [4 T-1](#4-t-1-day) · [5 Day-of run sheet](#5-day-of-run-sheet) · [6 Cut list](#6-timing-risk-and-cut-list) · [7 Checkpoints & pairing](#7-running-checkpoints-pairing-and-tas) · [8 Room-wide failures](#8-room-wide-failures-and-recovery) · [9 Afterwards](#9-post-workshop-follow-up) · [10 Alternative agendas](#10-compressed-and-alternative-agendas) · [11 Decisions before delivery](#11-decisions-to-make-before-delivery) · [12 Record sheet](#12-record-sheet)

> [!WARNING]
> **Volatile (verified Aug 2026).** Plan gating, beta flags, default models, plugin behaviour and scan
> durations drift. The README's ["Before each delivery, re-verify volatile facts"](README.md#before-each-delivery-re-verify-volatile-facts)
> checklist is part of T-7, not optional.

---

## 1. What you own

| Asset | Where | Purpose |
|---|---|---|
| Workshop GitHub org `<WORKSHOP_ORG>` | github.com | hosts the five repos below; no personal accounts anywhere in the material |
| `claude-builders-workshop` | org repo (this) | modules, reference, labs, scripts |
| `opentelemetry-demo` | org **fork** of `open-telemetry/opentelemetry-demo`, default branch `workshop`, pinned to a tagged upstream release | the target codebase (`$OTEL`); additions: `WORKSHOP.md`, `.gitignore` entries for `reports/`, `docs/generated/`, `CLAUDE-SECURITY-*`; **no `.claude/` committed**; optional `solutions` branch with tags `cp1`…`cp4` |
| `astroshop-reviews` | org **template** repo (source of truth: `apps/astroshop-reviews/` here) | deliberately vulnerable Flask service for M4-B and M7; carries `.workshop/` assets and a `demo/add-export-endpoint` branch |
| `claude-marketplace` | org repo, tagged `v4.0.0` | published marketplace with the reference `codebase-toolkit` plugin (CP3 safety net) |
| `claude-marketplace-template` | org template repo | empty marketplace skeleton for the M3 publish stretch |
| Console **workshop workspace** | Claude Console | spend-limited workspace holding pairing-station keys + one emergency shared key; Managed Agents verified; webhook signing secret for the M6 demo |
| claude.ai org (if you provide seats) | claude.ai admin | seats assigned; dynamic workflows not disabled; auto-mode policy known |
| Comms | Slack/Discord channel, shared "numbers" sheet (M1 step 5), registration form with preflight line, feedback form | |

Roles: **Lead** (talks, demos, owns the clock), **TA(s)** (1 per 8–10 participants on site, 1 per 6–8 virtual; own installs, pairing, checkpoints), **Producer** (virtual only: chat, recordings, breakout rooms).

## 2. T-14 days: provisioning

**GitHub org and repos**
- [ ] Create/confirm `<WORKSHOP_ORG>`; you and every TA are owners.
- [ ] Fork `open-telemetry/opentelemetry-demo` into the org. Create branch `workshop` from the **latest stable upstream release tag**; add `WORKSHOP.md` and the `.gitignore` lines; make `workshop` the default branch; protect it. **Record tag + SHA in [§12](#12-record-sheet) and in `labs/env.example` → `OTEL_PINNED_SHA`.**
- [ ] (Optional) push `solutions` branch with tags `cp1`…`cp4` mirroring `labs/checkpoints/CP1..CP4` content for `$OTEL`.
- [ ] Sync `apps/astroshop-reviews/` to the `astroshop-reviews` repo; mark it a **template**; confirm: Actions enabled for repos created from it, `uv run pytest -q` green, `.workshop/` complete (`introduce-ssrf.patch` applies cleanly on `main`, `security-review.yml`, `security-instructions.md`, `security-patterns.yaml`, `claude-security-guidance.md`, `sample-results/CLAUDE-SECURITY-sample/`, `expected-output/`), branch `demo/add-export-endpoint` exists, planted prompt-injection line present in its `CLAUDE.md`, `SOLUTIONS.md` is **not** in the template (it lives in `labs/m7-security/`).
- [ ] Publish `claude-marketplace` with `codebase-toolkit` v4.0.0 (built from `labs/m3/plugin` + agents/skills); `claude plugin validate` passes; tag `v4.0.0`; test `/plugin marketplace add <WORKSHOP_ORG>/claude-marketplace` → install → `/codebase-toolkit:code-reviewer` on a clean machine.
- [ ] Create `claude-marketplace-template` (empty `.claude-plugin/marketplace.json` skeleton) as a template repo.
- [ ] In this repo: `labs/env.example` filled (`OTEL_PINNED_SHA`, minimums, beta header); `./labs/checkpoint.sh --list` shows CP1–CP7 **ready**; `CHANGELOG.md` entry.

**Anthropic Console**
- [ ] Workshop workspace with a **spend limit** sized for headcount × (M5+M6+M7-CI) bursts plus demos; usage tier sufficient for the whole room creating Managed Agents sessions within the same 10 minutes.
- [ ] Keys: one per **pairing station** (planned no-key attendees ÷ 2, rounded up, + 2 spares) and **one emergency shared key**; label them; store in a password manager; prepare `labs/.env.instructor` handout (paper or DM, never in the repo/chat history); calendar reminder to **revoke at 16:00 on the day**.
- [ ] Managed Agents access verified in that workspace (`./labs/preflight.sh` with the key shows `managed-agents=yes`; Console → Agent quickstart opens); create the webhook endpoint + signing secret for the M6 demo; run `labs/m6-managed-agents/*/solution` end to end and note duration/cost in §12.
- [ ] Decide the **default lab model** for the room (`sonnet` recommended when Pro seats are present; see decision Q2) and set `MODEL` (alias) and `CMA_MODEL` (full model ID for Module 6, Ref §B) in `labs/env.example`.

**claude.ai org (if providing seats)**
- [ ] Seats assigned and accepted; Claude Code enabled for those seats; dynamic workflows **not** disabled by policy; note the auto-mode start behaviour for that plan so M1 step 1 lands; Code Review demo repo (optional, decision Q6).

**Plugin marketplace access**
- [ ] From a machine on a typical corporate network: official marketplace reachable (`claude plugin install claude-security@claude-plugins-official`), `security-guidance` installs, `<WORKSHOP_ORG>/claude-marketplace` installs. If attendee orgs enforce `strictKnownMarketplaces`, get the workshop marketplace allow-listed or plan for those attendees to use `--plugin-dir` (M3 step 10) and skip installs.

**Room / AV / virtual**
- [ ] On site: power at every seat; two projectors or one projector + confidence monitor; lapel mic for rooms > 25; table layout that lets TAs walk behind screens; printed one-page agenda + reference §C cheat-sheet per seat; whiteboard for the platform map.
- [ ] Network: venue Wi-Fi tested **from the room** against every host in `labs/preflight.sh` (run it there); captive-portal behaviour known; guest SSID credentials on the printed agenda; a phone hotspot as last resort for the instructor machine.
- [ ] Virtual: platform with breakout rooms; second device for chat; pre-recorded fallbacks (below); a "raise hand = TA DM" convention; attendee cameras optional, instructor camera on.

## 3. T-7 days: participants, dry-run, recordings

**Participant communication (send 5 working days ahead)**
- [ ] Email with: `<WORKSHOP_ORG>` value, link to [labs/SETUP.md](labs/SETUP.md), the three clone commands, the API-key matrix (who needs one, spend cap advice, that nobody is excluded without one), the preflight deadline (**24 h before**), the registration form field for the preflight summary line, and the support channel.
- [ ] Registration form asks: OS, plan type (subscription / Console / Bedrock-Vertex-Foundry / none yet), API key yes/no, Managed Agents yes/no (from preflight), Python or TypeScript preference, corporate laptop yes/no.

**Dry-run (all labs, end to end, on the pinned repos) — on macOS *and* Windows (native + WSL2)**
Record actual durations in §12; adjust effort defaults in lab text if any exceeds its budget by > 30%.
- [ ] M1 `/init` on `$OTEL` at `medium` effort · M1 plan-mode task
- [ ] M2 hook block round-trip · MCP server `--selftest` and first tool call
- [ ] M3 parallel subagents (Part A step 2) · `claude plugin validate` · marketplace install + `/reload-plugins`
- [ ] M4 `bug-hunt.sh` wall time and cost · Action round-trip time on a fresh template copy
- [ ] M5 step 1 and full solution run: time + `total_cost_usd`
- [ ] M6 steps 1–3: time to first event, total, session-hour cost line
- [ ] **M7 medium-effort full-repo scan on `astroshop-reviews`: must finish within Break 2 + talk (≈ 20 min). If not, change step 0 to `--effort low` or scope to `app/` in the module text and regenerate sample results accordingly.**
- [ ] `./labs/checkpoint.sh CP7 --dry-run` on a clean clone and on a fully worked clone: no errors.
- [ ] Sample scan in `.workshop/sample-results/` regenerated with the **current** plugin version if older than 30 days at delivery.

**Recordings / offline fallbacks (asciinema or short screen captures, no audio needed)**
- [ ] M4 scale-out tour: `claude --bg` + agent view, a dynamic workflow in `/workflows`, `/list-agents` + an `@dockerfile-audit` cross-session message, `--cloud` + `--teleport`, `/schedule`.
- [ ] M6 Console tour: agent builder → generated request → Sessions tracing view → Environments → Webhooks → Deployments.
- [ ] M7: a complete `/claude-security` scan at 8× speed and the PR comment from the security-review Action.
- [ ] M4-B: the `@claude` sticky comment updating on a PR.

## 4. T-1 day

- [ ] Triage the registration sheet: list attendees with FAIL/absent preflight → TA contacts them today; list no-key attendees → pairing plan and station keys counted; OS mix → seat Windows-native people near the TA who dry-ran Windows.
- [ ] Re-run `./labs/preflight.sh --full` on the instructor machine **from the venue network** (or the virtual setup); run `claude update`; then **freeze**: set `DISABLE_AUTOUPDATER=1` in the instructor's `~/.claude/settings.json` `env` for the day so behaviour cannot change mid-demo (participants keep auto-update; note your version in §12).
- [ ] Open PRs/branches needed for demos: `demo/add-export-endpoint` PR in *your* `astroshop-reviews` copy (M4-B), a second copy with `feat/avatar-proxy` pushed for the M7 CI demo; confirm Actions secrets present.
- [ ] Pre-create nothing in Managed Agents (participants should see creation), but keep IDs from your dry-run in `.cma-state.json` as a fallback for M6 step 5.
- [ ] Slides (if any) exported to PDF as backup; recordings on local disk; printed agendas; sticky notes in two colours (green = done, red = help) for on-site status at a glance.
- [ ] Charge everything; pack HDMI/USB-C adapters, a travel router or hotspot, extension lead.
- [ ] Post in the channel: start time, Wi-Fi, "run `claude update` and `./labs/preflight.sh` tonight", where to sit if you have no API key.

## 5. Day-of run sheet

Energy notes in italics. "CPn" = announce the checkpoint out loud and in chat. Keep a visible countdown timer per lab.

| Clock | What | Lead does | TAs do | Pace / energy |
|---|---|---|---|---|
| 08:00 | Room open for staff | AV check, fonts ≥ 18pt in terminal, `claude` logged in, `$OTEL` clean, recordings queued, timer app up | Wi-Fi test with preflight; lay out printed agendas and station keys | |
| 08:30 | Doors / install clinic | greet; point FAILs to TAs | fix installs, logins, proxies; pair no-key people **now** and seat pairs together | *calm; no teaching yet* |
| 09:00 | **M0** (15) | agenda + "what you'll have built by 15:40"; platform map; extension points + security rings; housekeeping (checkpoints, channel, pairing rule, cost expectations) | walk the room during the 7-min lab; anyone not green by 09:12 gets paired for M1–M3 | *brisk; set the tone that labs are timed* · **CP0** |
| 09:15 | **M1** (40) | 15-min demo exactly as scripted; pin `--permission-mode default` in step 1 so the room behaves uniformly; start 20-min lab timer at 09:30 | installs finish during the talk; watch for auto-mode surprises and Pro rate limits (suggest `/model sonnet`) | *first lab: over-communicate success checks* · 09:50 debrief · **CP1** |
| 09:55 | **M2** (45) | demo 12; lab 28 in three parts — call the part boundaries at 10:15 (A→B) and 10:25 (B→C) | hooks not firing = not executable / matcher case / session not restarted; MCP "failed" = run `node server.mjs` by hand | *densest config module; keep momentum, park deep questions to break* · **CP2** at 10:38 |
| 10:40 | Break 1 (10) | drink water; do not answer questions for all 10 minutes | help stragglers to CP2 | |
| 10:50 | **M3** (55) | demo 15 incl. org marketplace; lab 37: A (12) → B (8) → C (17); call boundaries at 11:17 and 11:25; **step 13 (org plugin at user scope) is mandatory for everyone** | validate errors (YAML frontmatter), `hooks.json` using `${CLAUDE_PLUGIN_ROOT}`, marketplace `source` paths, `/reload-plugins` | *creative high point of the morning; let fast people do stretches, keep slow people on the main line* · **CP3** at 11:42 — say "CP3 is your safety net for the afternoon; run it if in any doubt" |
| 11:45 | **M4** (30) | demo 15 (headless live; Actions live; scale-out **over the recording** to stay in time); lab 12: Path A default, Path B for people with `$REV`+key | Path B: secret name, `permissions:` block, commenter needs write access | *pre-lunch dip: keep demo punchy; it is fine if only half do Path B* · **CP4** · announce lunch return time twice |
| 12:15 | Lunch (40) | eat first, then reset demo state for M5; export `ANTHROPIC_API_KEY` in the demo shell | hand station keys to pairs; verify `uv sync` done on pairing machines | |
| 12:55 | **M5** (55) | 12-min talk with live-coding from a blank file; lab 38 with visible step clock (6/6/8/7/6/5); walk the TODO map first | most common: key not exported, `dontAsk` silently denying `Agent`/MCP tool (`permission_denials`), tool name mismatch `mcp__tracker__create_ticket`; Python < 3.10 | *post-lunch: start with the live-coding, not slides; first success check by 13:15 or push CP5* · **CP5** at 13:45 |
| 13:50 | **M6** (45) | concept slide 3; Console demo 5; terminal run 4; lab 28 (4/5/9/4/4/2) | 403 "not enabled" → move them to a station key immediately; `limited` networking missing GitHub hosts → recreate env; unanswered `requires_action` → session sits idle | *novelty carries energy; protect step 3 (the stream + confirmation) above all* · **at 14:33 announce M7 step 0** · **CP6** |
| 14:33 | M7 step 0 (2) | everyone: `cd $REV && claude --permission-mode auto` → `/claude-security scan the whole repository at medium effort` → confirm → leave it running; laptops on power, lid open, sleep disabled | check scans actually started; note who could not (workflows unavailable) → they will use sample results | |
| 14:35 | Break 2 (10) | | | *scans run unattended* |
| 14:45 | **M7** (40) | talk 10 while scans finish (threat model → control map lighting up M1–M6 artifacts → tooling layers → `/workflows` on your running scan); lab 27 (6/7/5/4/5); close with the hardened settings commit | anyone whose scan is not done by 14:58 opens the sample results; `git apply` rejects → `git stash`; `/security-review` needs `origin/HEAD` | *last lab: keep it concrete; the CI-gate step is the first thing to demo instead of do* · **CP7** |
| 15:25 | **M8** (15) | artifact ladder with checkmarks; two participants share (pick them during M7); adoption playbook + 30/60/90; `./labs/cleanup.sh`; resources + feedback QR; Q&A | post feedback link in chat; collect station keys | *end on the map, not on logistics* |
| 15:40 | Close | stay for hallway questions | note issues in the known-issues log | |
| 16:00 | | **revoke all workshop keys**; archive remaining Managed Agents resources in the workshop workspace; delete demo webhooks/deployments | | |

**Hard stop 15:30 variant:** 30-min lunch (12:15–12:45, everything after shifts −10), *or* keep lunch and run M4 lab as demo (M4 = 20 min, 11:45–12:05; lunch 12:05–12:45). Decide before the day (Q8), print the right agenda.

## 6. Timing risk and cut list

Rule: **never cut a success check or a checkpoint announcement; cut breadth, then stretch, then debrief, then convert the last lab step to a demo.** Cuts are listed in the order to apply them.

| Module | Main timing risks | Cut list (in order) — minutes recovered | Never cut |
|---|---|---|---|
| M0 | preflight chaos; late arrivals | start M1 talk at 09:15 regardless; TAs absorb installs (0) | pairing of no-key people |
| M1 | `/init` slow at high effort on the big repo; plan-mode task grows | step 5 numbers sheet (−3); trim plan in step 3 harder / skip test step (−3); surfaces slide to one sentence (−1); debrief to 2 (−3) | step 1 uniform permission mode; step 4 rewind |
| M2 | three parts, each with setup; Windows path quoting in hooks | Part A step 3 sandbox → mention only (−2); Part B step 6 read-along → homework (−3); Part C step 10 live permission rule (−2); debrief to 2 (−3) | Part B steps 4–5 (hook must exist for the plugin) — or push CP2 |
| M3 | plugin validate/marketplace fiddling; duplicate names | Part A step 3 explicit mention (−3); Part C step 11 local marketplace → demo, go straight to step 13 org install (−4); Part B step 7 (−2); debrief already 3 | Part C step 13 org install (afternoon depends on it) |
| M4 | demo sprawl; Actions latency | whole lab → demo (−12) **[first cut of the day if ≥ 10 min late at 11:45]**; scale-out tour to the table only (−3) | headless demo with `--json-schema` (M5 builds on the schema) |
| M5 | environment/auth issues eat step 1; step 3 tool wiring | step 6 free-form (−5); step 5 resume → demo (−4); step 4b `can_use_tool` → read solution (−3) | steps 1–3; cost printout (one line) |
| M6 | org gating; slow environment creation when the whole room creates at once | step 6 previews (−2); step 4 steer/interrupt → demo (−4); step 2 `agents.update` versioning (−1) | step 3 stream + confirmation + custom tool; step 5 usage/cost |
| M7 | scan not finished; `git apply` conflicts; Actions latency | step 5 CI gate → demo with recording (−5); step 3 change-scan comparison → demo (−5); SARIF viewer skip (−1) | step 0 kickoff; step 1 triage; step 2 patch; step 4 guidance rules; hardened-settings close |
| M8 | running over | skip participant sharing (−3); resources as a link only (−2) → 8-min M8 | cleanup instructions; feedback link |

If you are **> 15 min late at lunch**, take it out of lunch down to 30 min before touching M5–M7. If you are **> 10 min late at 14:35**, still take Break 2 (scans need it) and apply the M7 cuts.

## 7. Running checkpoints, pairing and TAs

**Checkpoint protocol**
1. At every module boundary the lead says and posts: "We are at **CPn**. If your success check did not pass, run `./labs/checkpoint.sh CPn` now — it will not overwrite your work."
2. Inside long labs (M2, M3, M5, M6) call the **part/step boundary times** from the run sheet; anyone more than one step behind at a boundary runs the checkpoint for the *previous* module and rejoins at the current step using the reference files in `labs/mN/`.
3. `--force` is expected exactly once in the day: **CP7** replaces M2's `settings.json` with the hardened one. Say so.
4. TAs verify with `./labs/checkpoint.sh CPn --dry-run` on a participant machine before forcing anything.
5. If checkpoint content itself is broken on the day, fall back to the `solutions` branch tags (`git -C $OTEL checkout cp3 -- .`) for CP1–CP4 and to `labs/m5…/solution`, `labs/m6…/solution` directly.

**Pairing protocol (no key / broken laptop)**
- Pair at M0, not at M5. Pairs sit together all day; the person without a key drives the keyboard in M5/M6 (they learn more), the key owner navigates.
- Station keys: one per pair, in `labs/.env` only, never in shell history (`set +o history` tip on the handout), revoked at 16:00. Say the spend cap out loud.
- Bedrock/Vertex/Foundry attendees: everything through M5 works on their provider (SDK honours the same env vars); pair only for M6.

**TA protocol**
- One TA owns the channel; questions answered in thread; anything asked three times gets said on mic at the next boundary.
- Red sticky / raised hand older than 3 minutes → TA pushes the checkpoint rather than debugging live; debug at the break.
- TAs log every novel failure in the known-issues log (§9) with the fix.

## 8. Room-wide failures and recovery

| Failure | Detect | Recover |
|---|---|---|
| Venue network blocks or throttles `api.anthropic.com` / captive portal expires | many simultaneous timeouts; preflight `reach` rows fail | re-auth portal; switch room to guest SSID/hotspot for API traffic; instructor continues demos on hotspot; labs pause → resume with checkpoint |
| Whole room rate-limited on subscription seats (everyone on Opus, high effort) | 429s / "usage limit" in many terminals during M1–M3 | announce `/model sonnet` + `/effort medium` for labs; stagger lab starts by table (30 s apart) for M3 parallel agents |
| Workshop Console workspace hits spend limit or tier limit mid-afternoon | 4xx billing/rate errors on station keys simultaneously | raise the limit live (have Console open); move pairs to the emergency key; worst case M6 becomes demo + `expected-output/` walkthrough |
| Claude Code auto-updated overnight and a command/flag moved | demo diverges from module text | you froze your version (T-1); tell participants the new spelling; note in known-issues; do not downgrade participants |
| Anthropic service incident | status page; errors across all auth types | switch to recordings for the current demo; run read-along of `expected-output/`; extend break; resume with checkpoints. Keep teaching concepts — the reference does not need the API |
| GitHub Actions disabled/blocked for many (corporate accounts) | Path B workflows never trigger | Path A for all; show Actions on the projector only; M7 step 5 as demo |
| Managed Agents returns 403 for most attendee orgs | preflight said so; or first `environments.create` fails | everyone onto station keys in the workshop workspace (name resources `ws-<user>` to avoid collisions); if the workspace also fails → recorded Console tour + solution transcript; keep step 5 cost discussion |
| Official plugin marketplace unreachable / plugin install blocked by managed settings | `claude plugin install` errors room-wide | M3: use `--plugin-dir` (no install needed); M7: sample results + `/security-review` (built-in) + recording of the plugin scan |
| Scan did not finish over Break 2 for most | `/workflows` still running at 14:58 | switch everyone to `.workshop/sample-results/`; leave scans running; compare later if time |
| `$OTEL` clone impossible on venue Wi-Fi for late registrants | clone crawling | USB stick / local mirror (`git clone --mirror` prepared at T-1) or pair |
| Projector dies | — | screen-share to the video call everyone joins from their seat; TAs relay |
| Lead's machine dies | — | TA machine is a full mirror (same repos, keys, recordings) — prepare it at T-1 |

## 9. Post-workshop follow-up

**Same day (by 16:00)**
- [ ] Revoke station and emergency keys; confirm in Console.
- [ ] `./labs/cleanup.sh` against the workshop workspace: archive agents/sessions/environments with the `ws-`/`codebase-toolkit-` prefixes; delete demo webhooks and scheduled deployments.
- [ ] Close demo PRs; delete throwaway `astroshop-reviews` copies you created; rotate the webhook signing secret.
- [ ] Export chat Q&A; save the numbers sheet.

**Within 2 days — follow-up email (template)**

> Subject: Workshop follow-up — your Codebase Toolkit, next steps, and links
>
> Thanks for building with us. Everything from the day is in `<WORKSHOP_ORG>/claude-builders-workshop`:
> the module you were in when time ran out still works self-paced, and `./labs/checkpoint.sh CPn` gets you to any state.
> Three things to do this week: (1) commit your `CLAUDE.md`, `.claude/settings.json` and hooks to a real repo and open a PR for your team; (2) publish your `codebase-toolkit` fork to a private marketplace and add it to a project's `enabledPlugins`; (3) run the Claude Security plugin on one service you own and triage the top three findings with a colleague.
> Adoption checklist (30/60/90 days) and all documentation links: `modules/08-wrap-up.md`. Reference for everything we typed: `reference/Technical-Reference-v4.md`.
> If you used a workshop API key, it is revoked; create your own in the Console with a spend limit. If you created Managed Agents resources in your own org, `./labs/cleanup.sh` archives them.
> Feedback form (2 minutes): `<link>` — it directly changes the next delivery.

**Within a week**
- [ ] Read feedback; update the **known-issues log** (`docs/known-issues.md` or the repo wiki): symptom, module/step, root cause, fix, whether module text changed.
- [ ] File PRs for every module text fix discovered live; bump `CHANGELOG.md`.
- [ ] Update §12 with measured durations and costs from the real room (they are better than dry-run numbers).

**Quarterly maintenance (owner: see decision Q5)**
- [ ] Re-pin `opentelemetry-demo` to the latest stable upstream tag if the current one is > 2 quarters old; re-run all labs; update `OTEL_PINNED_SHA`.
- [ ] Regenerate `astroshop-reviews/.workshop/sample-results/` with the current Claude Security plugin; confirm seeded findings still map to the documented CWEs in `labs/m7-security/SOLUTIONS.md`.
- [ ] Re-verify reference §O; bump the "verified <Mon YYYY>" badges you touched.
- [ ] Re-run both SDK solutions and the Managed Agents solution on current package versions; adjust starters.

## 10. Compressed and alternative agendas

Canonical day and variant summary: [Guide §3 and §8](Workshop-Guide-v4.md#8-delivery-variants). Operational detail:

**A. Hard stop 15:30 (6h30 on site).** Option 1: lunch 12:15–12:45; M5 12:45–13:40; M6 13:40–14:25; Break 2 14:25–14:35 (scan kickoff 14:23); M7 14:35–15:15; M8 15:15–15:30. Option 2: keep 40-min lunch, M4 = 20 min demo-only (11:45–12:05), lunch 12:05–12:45, then as Option 1.

**B. Compressed modules (300 min of modules).** Apply all of: M1 lab 20→10 (steps 1, 2, 4 only) · M4 lab → demo (M4 = 18) · M6 drop step 6 · M7 step 5 → demo · debriefs M1/M2/M5/M6 5→2, M3/M4/M7 3→2. Resulting slots: M0 15 · M1 27 · M2 42 · M3 54 · M4 18 · M5 52 · M6 40 · M7 34 · M8 15 = 297 (+3 float). With two 10-min breaks and a 30-min lunch: 09:00–14:50.

**C. Half-day "Claude Code" (no API keys needed).** 09:00 M0 (15) · 09:15 M1 (40) · 09:55 M2 (45) · 10:40 break (10) · 10:50 M3 (55) · 11:45 M4 (30, Path A for all) · 12:15 M7-lite (30: step 0 at 12:15 with `--effort low` scoped to `app/`, threat-model talk while it runs, steps 1–3) · 12:45 wrap (5) → **12:50**. Uses CP0–CP4; skip CP5/CP6; CP7 partial.

**D. Half-day "Platform" (everyone has a key or pairs; assumes Claude Code familiarity).** 09:00 M0 (15, incl. CP3 for all) · 09:15 M3 step 13 + 10-min tour of what the plugin contains (15) · 09:30 M5 (55) · 10:25 break (10) · 10:35 M6 (45) · 11:20 M7 step 0 + Break 2 (10) · 11:30 M7 (40) · 12:10 M8 (15) → **12:25**.

**E. Two half-days (recommended for virtual).** Day 1 = variant C without M7-lite plus a 10-min close (09:00–12:25); homework: `preflight --full` with API key, create `$REV`. Day 2 = 10-min recap + `checkpoint.sh CP4` for all, then M5 (55) · M6 (45) · break + scan kickoff (10) · M7 (40) · M8 (15) → 2h55.

**F. Audience mostly daily Claude Code users (decision Q1).** M1 shrinks to 25 (demo 8: skip `/init` and surfaces; lab 15: steps 3–5 only; debrief 2); give +10 to M5 (stretch a: programmatic subagents becomes a main step) and +5 to M6 (step 6 preview for everyone).

## 11. Decisions to make before delivery

These eight questions from the curriculum design are **owner decisions**. Record the answers in §12; several change handouts, keys and module defaults.

1. **Audience baseline & language track.** Mostly daily Claude Code users (→ variant F: M1 shrinks to 25 min, M5/M6 gain time) or first-timers (canonical)? Python-primary with TypeScript alternates for M5/M6 is the default — acceptable, or must TypeScript be first-class in the room (then a TS-fluent TA narrates the TS track in a breakout/second screen)?
2. **Provisioning model.** Will you provide claude.ai seats, Console API keys (per attendee? what spend cap?), both, or neither? This decides the default lab model (`sonnet` vs `opus`), whether Pro rate limits are a risk, how many station keys to cut, and whether a shared instructor key is allowed by your security policy at all.
3. **Managed Agents access.** Are all attendee Console orgs confirmed to have Managed Agents (beta) enabled, and are webhooks/scheduled deployments acceptable to create in those orgs — or should everyone use a single workshop workspace you own (simpler, but you carry the cost and cleanup)?
4. **Delivery mode & size.** On-site vs virtual, headcount, TA ratio, OS mix. Do you need Windows-native parity dry-run and PowerShell script twins, or can you require WSL2/macOS? Virtual pushes you to pre-recorded fallbacks for M4/M6 demos and a longer M0.
5. **Workshop GitHub org ownership.** Who creates/owns `<WORKSHOP_ORG>` and its five repos, and who does the quarterly refresh (pinned OTel tag, sample-scan regeneration, model constants, volatile facts)? Personal-account repos from earlier versions must not reappear in the material.
6. **Plan-gated features shown live.** Code Review (Team/Enterprise), hosted Claude Security (Enterprise), Claude Code on the web: demonstrate from a real org you control (then prep accounts, screenshots you are allowed to show, and a fallback recording), or position slide-only?
7. **Naming/branding.** Confirm public naming in all handouts and slides: "Claude Managed Agents" (no abbreviations), "Claude Security" for the hosted product and "Claude Security plugin for Claude Code" for the plugin, "Claude Agent SDK"; and the exact workshop title on certificates/invites.
8. **Time box.** Confirm 09:00–15:40 (6h session + 40-min lunch). If the hard stop is 15:30, choose now between the 30-min lunch and the M4-lab-as-demo option (§10-A) and print the matching agenda.

## 12. Record sheet

Fill per delivery; keep in the repo (PR) so the next facilitator inherits real numbers.

| Item | Value |
|---|---|
| Delivery date / venue or platform / headcount / TAs | |
| Decisions Q1–Q8 (one line each) | |
| `<WORKSHOP_ORG>` | |
| `opentelemetry-demo` upstream tag → `workshop` branch SHA (`OTEL_PINNED_SHA`) | |
| `claude-marketplace` tag / `codebase-toolkit` version | v4.0.0 |
| Claude Code version on instructor machine (frozen T-1) | |
| Agent SDK versions used (`claude-agent-sdk` py / `@anthropic-ai/claude-agent-sdk` ts) and `anthropic` SDK version | |
| Managed Agents beta header / toolset id verified on (date) | |
| Claude Security plugin version; sample results regenerated on (date); medium scan duration on `astroshop-reviews` | |
| Default lab `MODEL` alias, `CMA_MODEL` full ID / room plan mix | |
| Measured durations: M1 `/init` · M3 parallel agents · M4 `bug-hunt.sh` · M5 step 1 · M5 full solution (cost) · M6 steps 1–3 (cost) · M7 scan | |
| Workshop workspace spend limit / actual spend | |
| Keys issued / revoked at (time) | |
| Volatile-facts checklist completed on (date) by | |
| Known issues discovered (link) | |
