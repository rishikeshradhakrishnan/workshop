# Participant setup — do this before the day

**Time needed:** 30–45 minutes, plus a large `git clone` you should not attempt on venue Wi-Fi.
**Deadline:** run `./labs/preflight.sh` until it prints `READY` **at least 24 hours before** the workshop and paste its summary line into the registration form. If anything is red and you cannot fix it, tell the facilitators *before* the day — installs are not fixable in a 15-minute welcome slot.

> [!WARNING]
> **Volatile facts.** Install commands, minimum versions, plan names and beta flags below were verified against the public Claude Code, Agent SDK and Claude Platform documentation in **August 2026**. If you are reading this months later, trust `code.claude.com/docs` and `platform.claude.com/docs` over this page and tell us what drifted.

Contents: [1 Accounts](#1-accounts) · [2 Which modules need an API key](#2-which-modules-strictly-need-a-console-api-key) · [3 Supported systems](#3-supported-operating-systems) · [4 Install Claude Code](#4-install-claude-code) · [5 Toolchain](#5-toolchain-git-node-python-jq) · [6 GitHub and the three repos](#6-github-account-and-the-three-repositories) · [7 Environment file](#7-environment-variables-labsenv) · [8 Lab dependencies & plugins](#8-lab-dependencies-and-workshop-plugins) · [9 Optional extras](#9-optional-extras) · [10 Verify with preflight](#10-verify-with-preflight) · [11 Proxies, Bedrock, Vertex, locked-down laptops](#11-corporate-proxies-cloud-providers-and-locked-down-laptops) · [12 Troubleshooting](#12-quick-troubleshooting)

---

## 1. Accounts

You need **a way to run Claude Code** and, for the afternoon, ideally **a Console API key**. These are two different things and you may have one, the other, or both.

| You have… | Claude Code (M0–M4, M7) works? | Agent SDK / Managed Agents / CI (M4-B, M5, M6, M7-5) work? |
|---|---|---|
| A **claude.ai Pro, Max, Team or Enterprise** seat that includes Claude Code | Yes — log in with `claude` → browser | No — these call the API directly and need a key (see §2 for your options) |
| A **Claude Console** account (API billing) where you have the *Claude Code* or *Developer* role, and an **API key** | Yes — Claude Code can log in with the Console account, or run on `ANTHROPIC_API_KEY` | Yes |
| Both | Yes (Claude Code uses your subscription interactively; see the note on precedence in §7) | Yes |
| Free claude.ai only | **No.** The free plan does not include Claude Code. Ask your facilitator about a workshop seat or key. | No |
| Claude via **Amazon Bedrock / Google Cloud Vertex AI / Microsoft Foundry** | Yes for Claude Code (see §11) | M5 yes (the SDK supports these providers); **M6 no** — Managed Agents runs on the Claude API only |

**Console API key checklist** (if you can get one):
- Create it in the Claude Console under a workspace with a **spend limit** (we recommend a cap of about USD 10 for the day; typical spend for M5+M6+M7 on the `sonnet` alias is low single-digit USD).
- Confirm **Claude Managed Agents** is available to your Console organization: open the Console and look for *Agent quickstart* / *Managed Agents* in the navigation (beta, Aug 2026; enabled by default for API organizations, but some enterprise orgs restrict betas). `preflight.sh` probes this for you when the key is set.
- Keep the key out of shell history and dotfiles you sync; put it only in `labs/.env` (git-ignored).

## 2. Which modules strictly need a Console API key

| Module / step | Needs `ANTHROPIC_API_KEY`? | If you do not have one |
|---|---|---|
| M0–M3, M4 Path A (headless), M7 steps 0–4, M8 | No — any Claude Code login works | — |
| **M4 Path B** — GitHub Actions `@claude` / PR review | Yes (as a repo secret) | Do Path A; watch the instructor's PR |
| **M5** — Claude Agent SDK lab | **Yes** | Pair with a neighbour, or use the time-boxed instructor workspace key handed out in the room (revoked at end of day), or read along with `labs/m5-agent-sdk/expected-output/` |
| **M6** — Claude Managed Agents lab | **Yes**, in an org with Managed Agents enabled | Same as M5; the Console tour is projected |
| **M7 step 5** — security-review CI gate | Yes (repo secret from M4-B) | Watch the instructor's PR; screenshot in `expected-output/` |

Nobody is sent home for lacking a key. Tell a TA at the M0 welcome and you will be paired.

## 3. Supported operating systems

- **macOS 13+**, **Ubuntu 20.04+ / Debian 10+** (other modern 64-bit Linux is fine), **Windows 10 (1809+) / 11** either natively or under **WSL2**.
- 8 GB RAM recommended (4 GB minimum for Claude Code itself). x64 or ARM64.
- Windows notes: Claude Code runs natively (PowerShell or Git Bash). The Bash **sandbox** step in M2 requires macOS, Linux or **WSL2** (not WSL1, not native Windows) — native Windows users simply skip that one step. The lab shell scripts (`preflight.sh`, `checkpoint.sh`, hook scripts) are bash; run them from **Git Bash** or WSL2. The only PowerShell file shipped is `labs/m2/hooks/protect-files.ps1`, an example of a Windows-native hook for M2.

## 4. Install Claude Code

Use the **native installer** (recommended; auto-updates; no Node.js required):

```bash
# macOS / Linux / WSL
curl -fsSL https://claude.ai/install.sh | bash

# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

Alternatives if your machine policy prefers a package manager (these do **not** auto-update — upgrade the day before):

```bash
brew install --cask claude-code            # macOS Homebrew
winget install Anthropic.ClaudeCode        # Windows
npm install -g @anthropic-ai/claude-code   # npm wrapper around the same native binary; needs a current Node.js; never use sudo
```

Then:

```bash
claude --version        # prints a version; any current release is fine — we do not pin a patch version
claude doctor           # read-only diagnostics; fix anything it flags
claude                  # first run: log in (browser opens; press `c` to copy the URL if it does not)
```

Inside that first session type `/status` (shows login method and model) and `/exit`. If the browser flow is impossible on your machine (locked-down laptop, SSH box), use `claude auth login` and paste the code, or run on `ANTHROPIC_API_KEY` (see §7).

> [!IMPORTANT]
> **Update the day before, not the morning of.** Claude Code ships frequently. Run `claude update` (native) or your package manager's upgrade the evening before, then re-run preflight. If your organization pins versions through managed settings, that is fine — tell us the version in the registration form.

## 5. Toolchain: git, Node, Python, jq

| Tool | Minimum | Why | Install hint |
|---|---|---|---|
| **git** | 2.30+ | everything | Xcode CLT / `apt install git` / Git for Windows |
| **Node.js + npm** | **current LTS (22.x as of Aug 2026)**; 18+ works but is end-of-life | the lab MCP server (M2), `npx`-launched MCP servers, the TypeScript SDK track (M5/M6) | nodejs.org LTS installer, `nvm install --lts`, `brew install node@22` |
| **Python** | **3.10+** as `python3` | Agent SDK minimum is 3.10 (M5/M6); the Claude Security plugin needs ≥ 3.9.6 (M7) | python.org, `brew install python`, `pyenv`; on macOS do **not** rely on the system Python |
| **uv** | current | Python env/deps for M5–M7 (`uv sync`, `uv run`) — pip/venv works but lab text uses uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` or `brew install uv` |
| **jq** | 1.6+ | hook scripts (M2), headless JSON (M4) | `brew install jq`, `apt install jq`, `winget install jqlang.jq` |
| **GitHub CLI `gh`** (optional) | current | convenience in M4-B/M7-5 | cli.github.com; then `gh auth login` |
| A code editor | — | VS Code recommended, with the **Claude Code** extension and (optional) a **SARIF viewer** extension for M7 | |

## 6. GitHub account and the three repositories

You need a **personal github.com account** that can create public repositories and run GitHub Actions. Corporate/EMU-managed accounts often cannot install apps or use Actions on personal repos — use a personal account for the day.

Your facilitator gives you the value of `<WORKSHOP_ORG>`. Then:

```bash
mkdir -p ~/work && cd ~/work

# 1) this repository (labs, scripts, starters)
git clone https://github.com/<WORKSHOP_ORG>/claude-builders-workshop

# 2) the target codebase: the OpenTelemetry "Astronomy Shop" demo, forked and pinned by the workshop org
#    (several hundred MB — clone at home, not at the venue)
git clone https://github.com/<WORKSHOP_ORG>/opentelemetry-demo
git -C opentelemetry-demo switch workshop        # default branch of the fork; preflight checks the pinned commit

# 3) YOUR OWN copy of the deliberately-vulnerable review service used in M4-B and M7:
#    open https://github.com/<WORKSHOP_ORG>/astroshop-reviews -> "Use this template" -> owner: you,
#    name: astroshop-reviews, visibility: public (Actions minutes are free on public repos) -> Create.
git clone https://github.com/<you>/astroshop-reviews
cd astroshop-reviews && uv sync && uv run pytest -q && cd ..   # 6-8 tests, all green
```

You never need to *run* the Astronomy Shop (no Docker, no Kubernetes). Claude reads and edits its source.

> [!CAUTION]
> `astroshop-reviews` contains **intentional security vulnerabilities** for the M7 lab. Do not deploy it, do not reuse its code, and do not point real credentials at it.

## 7. Environment variables (`labs/.env`)

```bash
cd ~/work/claude-builders-workshop
cp labs/env.example labs/.env
$EDITOR labs/.env          # fill WORKSHOP_ORG, GITHUB_USER, WS, OTEL, REV, and ANTHROPIC_API_KEY if you have one
source labs/.env           # do this in every new terminal during the day (or add to your shell profile for the day)
```

What the variables mean:

| Variable | Meaning |
|---|---|
| `WORKSHOP_ORG`, `GITHUB_USER` | GitHub org of the workshop repos; your GitHub username |
| `WS`, `OTEL`, `REV` | Absolute paths to this repo, your `opentelemetry-demo` clone, your `astroshop-reviews` clone. Lab text writes `$WS`, `$OTEL`, `$REV`. |
| `WORKSHOP_REPO` | Same as `WS`; referenced by the plugin's `.mcp.json` through environment expansion (M3) |
| `ANTHROPIC_API_KEY` | Console key; see §2. |
| `MODEL` | Model **alias** for `claude -p` scripts (M4) and the Agent SDK code (M5) — one place to change it. Claude Code and the SDK accept aliases (`sonnet`, `opus`, `haiku`), so no dated ID is needed. |
| `CMA_MODEL` | **Full model ID** for the Managed Agents lab (M6) — that API rejects aliases (`sonnet` → 400). Use a Claude 4.5+ model your Console org can access; see reference §B. Module 7 step 5 reuses this value for the `CLAUDE_MODEL` GitHub repo variable. |
| `TRACK` | `python` (primary, fully narrated) or `typescript` (equivalent starters/solutions) for M5/M6 |
| `OTEL_PINNED_SHA`, `PREFLIGHT_*`, `MANAGED_AGENTS_BETA` | Maintained by facilitators; leave as shipped |

> [!NOTE]
> **Auth precedence matters.** If `ANTHROPIC_API_KEY` is exported, headless `claude -p` uses (and bills) the key; interactive `claude` asks once whether to use it. If you want your **subscription** to cover Claude Code and the key to be used only by M5/M6 code, either keep the key only in `labs/.env` and `source` it just for those modules, or answer "No" when Claude Code asks to use the detected key. A stale or revoked key silently overriding your login is the number-one cause of `401`/`organization disabled` errors — `unset ANTHROPIC_API_KEY` and retry.

## 8. Lab dependencies and workshop plugins

```bash
cd $WS
npm ci --prefix labs/mcp/astro-catalog                 # the tiny MCP server used in M2/M3
uv sync --project labs/m5-agent-sdk/python             # installs claude-agent-sdk, anthropic, jsonschema (M5/M6)
# TypeScript track instead/as well:
npm ci --prefix labs/m5-agent-sdk/typescript

# M7 plugins from the official marketplace (auto-registered in Claude Code):
claude plugin install claude-security@claude-plugins-official -s user
claude plugin install security-guidance@claude-plugins-official -s user
claude plugin disable security-guidance@claude-plugins-official   # keep it quiet until M7 step 4
claude plugin list
```

Then open `claude` once, run `/config`, and make sure **Dynamic workflows** is **on** (Pro plans must opt in; some organizations disable it by policy — if yours does, tell us; you will use the provided sample scan results in M7).

`./labs/preflight.sh --install` performs the `npm ci` / `uv sync` steps for you if you prefer.

## 9. Optional extras

- **Docker Desktop** — only for stretch goals (hardened container for the SDK agent in M5; self-hosted worker in M6).
- **VS Code SARIF Viewer** extension — nicer triage of the M7 `.sarif` output.
- **`smee` client** (`npx smee`) — only for the M6 webhook stretch.
- The Claude **desktop app** or the **VS Code / JetBrains** extension if you want to see the same engine in another surface during M1 (overview only; not required).

## 10. Verify with preflight

```bash
cd $WS && ./labs/preflight.sh            # core checks, changes nothing
./labs/preflight.sh --install            # also installs lab deps inside this repo
./labs/preflight.sh --full               # also: one tiny inference call via `claude -p`, pytest in $REV
./labs/preflight.sh --help
```

It prints a PASS/WARN/FAIL table and ends with a line like:

```
PREFLIGHT v4 | Darwin/arm64 | claude 2.x.y | auth=subscription | node 22.11.0 | python 3.12.4 | managed-agents=yes | READY
```

Paste that line into the registration form. **WARN is acceptable** (it usually means "you will pair for one module" or "optional tool missing"); **FAIL is not** — fix it or contact us. On the morning itself you will run it once more in M0 (takes about 20 seconds).

## 11. Corporate proxies, cloud providers and locked-down laptops

**HTTP proxy / TLS inspection.** Claude Code honours the standard variables. Put them in `~/.claude/settings.json` under `env` (so background processes inherit them) or export them in your shell:

```bash
export HTTPS_PROXY=http://proxy.example.com:8080     # HTTP_PROXY / NO_PROXY also read; SOCKS is not supported
export NODE_EXTRA_CA_CERTS=/path/to/corp-root-ca.pem  # if your proxy re-signs TLS and the CA is not in the OS trust store
```

Then check `/status` inside `claude` (it shows proxy and CA rows) and re-run preflight. Hosts that must be reachable: `api.anthropic.com`, `claude.ai`, `platform.claude.com`, `downloads.claude.ai`, `github.com` / `api.github.com` / `raw.githubusercontent.com`, `registry.npmjs.org`, `pypi.org`.

**Amazon Bedrock, Google Cloud Vertex AI, Microsoft Foundry.** Claude Code and the Agent SDK work through these providers: set `CLAUDE_CODE_USE_BEDROCK=1` (with AWS credentials/region), `CLAUDE_CODE_USE_VERTEX=1` (with `ANTHROPIC_VERTEX_PROJECT_ID`, `CLOUD_ML_REGION` and gcloud ADC), or `CLAUDE_CODE_USE_FOUNDRY=1` (with your Foundry resource and key) before starting `claude`, or pick **3rd-party platform** at the login prompt for the guided Bedrock/Vertex setup. Expect these differences during the day: model aliases resolve to whatever your provider offers (pin with `ANTHROPIC_DEFAULT_SONNET_MODEL` etc. if your admin says so); a few features shown in demos are first-party only (for example web search on Bedrock, some cloud/web surfaces); auto mode may start in manual mode; and **M6 Managed Agents is not available through Bedrock/Vertex/Foundry** — you will pair for M6 or use the instructor workspace key. Everything in M0–M5 and M7 works.

**LLM gateway** (`ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`): fine for Claude Code and the SDK; same M6 caveat; make sure the gateway forwards beta headers unchanged.

**Managed (enterprise) settings on your laptop.** If your organization enforces managed settings (forced login method, restricted models, plugins limited to approved marketplaces, hooks restricted to managed ones), some lab steps may be blocked: installing the workshop marketplace (M3), project hooks (M2), or the M7 plugins. Run `/status` → *Setting sources* to see whether managed settings apply, tell a facilitator at M0, and expect to pair for the blocked steps. Nothing in the workshop asks you to weaken your organization's policy.

**No browser on the box.** `claude auth login` prints a URL to open elsewhere and accepts the pasted code; or use `ANTHROPIC_API_KEY`.

## 12. Quick troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| `claude: command not found` after install | `~/.local/bin` not on `PATH` → open a new terminal or add it; `which -a claude` to find duplicates (old npm global installs) |
| Login loops / `403` right after login | Seat without Claude Code access, or Console user without the *Claude Code*/*Developer* role → ask your admin; meanwhile use a key |
| `400 … organization has been disabled` while you *do* have a subscription | A stale `ANTHROPIC_API_KEY` in your environment wins over the login → `unset ANTHROPIC_API_KEY` |
| Preflight: `API key valid → 401` | Key revoked, copied with whitespace, or from a different Console org → create a fresh key |
| Preflight: `Managed Agents access → 403/404` | Beta not enabled for your Console org/workspace → you will pair in M6; nothing else is affected |
| Preflight: `reach api.anthropic.com → no HTTP response` | Proxy/VPN/captive portal → §11; try off-VPN; hotel Wi-Fi portals need a browser visit first |
| `npm ci` fails in `labs/mcp/astro-catalog` | Node too old → install current LTS; behind a proxy set `npm config set proxy`/`https-proxy` |
| `uv: command not found` | Install uv (§5) or replace `uv run X` with an activated venv + `python -m X` |
| WSL: browser does not open for login | `export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"` (adjust path) or press `c` and paste the URL into Windows |
| Everything is slow / rate-limited on a Pro seat | Use `/model sonnet` and `/effort medium` for labs; heavy Opus use across a whole room exhausts Pro limits quickly |

More, per module, in [`reference/Technical-Reference-v4.md`](../reference/Technical-Reference-v4.md) §J (troubleshooting) and in each module's "Common failures" box.
