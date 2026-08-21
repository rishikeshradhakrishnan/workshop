# Changelog

All notable changes to the workshop materials. Dates are the month the content was verified against public documentation; volatile facts (model line-up, beta headers, prices, preview features) are listed in `reference/Technical-Reference-v4.md` §O and must be re-verified before every delivery.

## v4 (2026-08-19) — "Claude for Builders", a clocked 6-hour hands-on day

- Restructured the workshop from a modular reference into a **6-hour curriculum** (09:00–15:40 with two 10-minute breaks and a 40-minute lunch): `Workshop-Guide-v4.md` is the spine, with nine clocked modules under `modules/` — M0 welcome & platform map, M1 Claude Code essentials, M2 settings/permissions, hooks and MCP, M3 subagents, skills, plugins & marketplaces, M4 automation & scale (headless, GitHub Actions, cloud/background sessions, orchestration), M5 Claude Agent SDK deep-dive, M6 Claude Managed Agents, M7 securing agentic development with Claude Security, M8 wrap-up.
- New `reference/Technical-Reference-v4.md` (appendices A–O): look-up tables for CLI, settings, hooks, MCP, subagents, skills/plugins, headless/CI, troubleshooting, Agent SDK, Managed Agents, security, glossary/resources, and a dated volatile-facts list.
- New `labs/` tree: participant `SETUP.md`, `env.example`, `preflight.sh` (environment check), `checkpoint.sh` with cumulative checkpoints CP0–CP7 (`labs/checkpoints/`), `cleanup.sh`, per-module assets (`m1`–`m4`, `m5-agent-sdk`, `m6-managed-agents`, `m7-security`), the `astro-catalog` MCP lab server, and shared schema/prompt/tool code reused across M4–M7.
- New `apps/astroshop-reviews/`: the intentionally vulnerable Flask sample service (source of truth for the workshop-org template repo) used by the M4 GitHub Action path and the M7 security module, including sample scan results and patches for offline fallback.
- New `FACILITATOR.md`: provisioning timeline, day-of run sheet, cut list, room-wide failure playbook, compressed/half-day agendas, decisions record.
- Conventions: model **aliases** everywhere in Claude Code files; SDK code reads `MODEL` (alias) and Managed Agents code reads `CMA_MODEL` (full model ID) from `labs/.env`; workshop-org placeholder `<WORKSHOP_ORG>`; every version- or plan-specific statement carries a "verify before delivery" badge.
- `Workshop-Technical-Reference-v3.md` (v3 draft) and `Workshop-Technical-Reference.md` (v2) are **retained unchanged** for history. Do not deliver from them.
- 2026-08-21: added **cross-session messaging** (`--name`/`/rename`, `/list-agents`, `@session-name` mentions, `ListAgents`/`SendMessage`, `crossSessionInbound`) — M4 §4.5 talk track, §4.7 decision row, demo beat 3, troubleshooting and a stretch goal; reference §C.7 (`CLAUDE_CODE_MESSAGING_SOCKET`/`_TOKEN`), §D.5 (`crossSessionInbound`, `isolatePeerMachines`, `dialogExpiry`), §I.3 matrix row, §M.6 org switch-off, §O row 25. Verified against `code.claude.com/docs/en/cross-session-messaging`.

## v3 (2026-07) — modular reference draft, never released

- `Workshop-Technical-Reference-v3.md`: ~3.5 hours of pick-and-mix modules covering Claude Code 2.1.2xx, newer model capabilities, agent orchestration (teams/workflows), and first Claude Managed Agents + Agent SDK material. Marked work-in-progress; superseded by v4 before release.

## v2.0.0.b — 5-phase 90-minute plugin workshop (released)

- `Workshop-Technical-Reference.md`: instructor-led live-coding workshop in which participants build the "Codebase Toolkit" plugin (service-documenter and bug-hunter subagents, code-reviewer skill, MCP integration) against the OpenTelemetry demo in five phases.

## v1.0.0 — initial workshop release
