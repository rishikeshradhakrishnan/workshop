"""deploy_toolkit_agent — Module 6 lab: the Codebase Toolkit's bug-hunter as a Claude Managed Agent (SOLUTION).

  uv run python deploy_toolkit_agent.py step1            # environment  (cloud, pip:ruff, limited networking)
  uv run python deploy_toolkit_agent.py step2            # agent v1, then update -> v2, list versions
  uv run python deploy_toolkit_agent.py step3 [--yes]    # session + stream + tool confirmation + custom tool
  uv run python deploy_toolkit_agent.py step4 [--interrupt-after N]   # steer: interrupt + redirect, then a follow-up
  uv run python deploy_toolkit_agent.py step5            # download /mnt/session/outputs/bug-report.md, print usage
  uv run python deploy_toolkit_agent.py step6            # pointers to the preview snippets (budget/deployment/webhook)
  uv run python deploy_toolkit_agent.py all [--yes]      # step1, step2, step3, step5 in one go (add --with-step4 for the steer demo)
  uv run python deploy_toolkit_agent.py attach [--yes]   # re-open the stream on the cached session, answer what is pending
  uv run python deploy_toolkit_agent.py status | cleanup # show cached IDs / interrupt+archive the cached session

Flags: --yes (auto-allow every tool confirmation; used by labs/checkpoint.sh CP6) · --interrupt-after N (step4, default 20)
       --new-session (step3: ignore the cached session and create a fresh one)
Environment (source labs/.env): ANTHROPIC_API_KEY, CMA_MODEL (a full model ID — Claude Code aliases 400 here),
       WORKSHOP_ORG, GITHUB_USER. IDs are cached in ./.cma-state.json so re-running never re-creates resources.
Beta: managed-agents-2026-04-01 (the SDK sets the header). Verify identifiers in labs/shared/cma_constants.py.
"""
from __future__ import annotations

import itertools
import json
import os
import pathlib
import sys
import threading
import time

SHARED = pathlib.Path(__file__).resolve().parents[3] / "shared"                # -> labs/shared
sys.path.append(str(SHARED))
from cma_constants import BETA, SESSION_HOUR_USD, TOOLSET                       # noqa: E402
from tickets import CREATE_TICKET_DESCRIPTION, CREATE_TICKET_INPUT_SCHEMA, create_ticket   # noqa: E402  M5's handler, reused verbatim

try:
    from anthropic import Anthropic, APIStatusError
except ImportError:                                                             # pragma: no cover
    sys.exit("anthropic SDK missing — run `uv sync` in labs/m6-managed-agents/python (or pip install 'anthropic[webhooks]')")

STATE_FILE = pathlib.Path(".cma-state.json")
MODEL = os.environ.get("CMA_MODEL", "")                                        # full model ID (labs/.env); aliases 400 here
ORG = os.environ.get("WORKSHOP_ORG", "<WORKSHOP_ORG>")
USER = os.environ.get("GITHUB_USER") or os.environ.get("USER") or "anon"
SYSTEM = (SHARED / "prompts" / "bug_hunter_system.md").read_text()
EXTRA_LINE = "\nAlways include the exact file:line for every finding."
TASK = (f"Clone https://github.com/{ORG}/opentelemetry-demo (depth 1) into /workspace. "
        "Analyze src/paymentservice for bugs and write the report to /mnt/session/outputs/bug-report.md. "
        "File a ticket for each HIGH finding with create_ticket. Then fetch "
        "https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md "
        "and note whether any finding is already fixed upstream.")

_client: Anthropic | None = None


def client() -> Anthropic:
    global _client
    if _client is None:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            sys.exit("ANTHROPIC_API_KEY is not set — `source $WS/labs/.env` (Module 6 needs a Console key)")
        _client = Anthropic()                                # SDK adds anthropic-beta: managed-agents-2026-04-01 on client.beta.*
    return _client


# ----------------------------------------------------------------------------- state
def load_state() -> dict:
    return json.loads(STATE_FILE.read_text()) if STATE_FILE.exists() else {}


def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2))


def need(state: dict, key: str, step: str) -> str:
    if key not in state:
        sys.exit(f"{key} missing from {STATE_FILE} — run `{step}` first")
    return state[key]


# ----------------------------------------------------------------------------- step 1: environment
def step1(state: dict, **_) -> None:
    if "environment_id" in state:
        print(f"reusing {state['environment_id']} from {STATE_FILE}")
        return
    env = client().beta.environments.create(
        name=f"ws-{USER}",
        config={
            "type": "cloud",
            "packages": {"pip": ["ruff"]},                                       # pre-installed and cached
            "networking": {"type": "limited",                                     # governs the CONTAINER's egress (bash/git/pip)
                           "allowed_hosts": ["github.com", "api.github.com", "raw.githubusercontent.com"],
                           "allow_package_managers": True, "allow_mcp_servers": False},
        },
    )
    state["environment_id"] = env.id
    save_state(state)
    print(f"created environment {env.id} (ws-{USER}) — see Console -> Environments")


# ----------------------------------------------------------------------------- step 2: agent (+ version 2)
def agent_tools() -> list[dict]:
    return [
        {"type": TOOLSET,
         "default_config": {"permission_policy": {"type": "always_allow"}},
         "configs": [{"name": "web_fetch", "permission_policy": {"type": "always_ask"}},   # the human checkpoint
                     {"name": "web_search", "enabled": False}]},                           # not needed: remove it
        {"type": "custom", "name": "create_ticket",                                        # M5's tool as a contract; WE execute it
         "description": CREATE_TICKET_DESCRIPTION,
         "input_schema": CREATE_TICKET_INPUT_SCHEMA},
    ]


def step2(state: dict, **_) -> None:
    if not MODEL or MODEL.startswith("<") or MODEL in {"sonnet", "opus", "haiku", "default", "opusplan"}:
        print(f"warning: CMA_MODEL={MODEL!r} is empty or looks like a Claude Code alias; Managed Agents needs a full model ID (labs/.env)", file=sys.stderr)
    c = client()
    if "agent_id" in state:
        print(f"reusing {state['agent_id']} from {STATE_FILE}")
        agent = c.beta.agents.retrieve(state["agent_id"])
    else:
        agent = c.beta.agents.create(name=f"codebase-toolkit-{USER}", model=MODEL, system=SYSTEM, tools=agent_tools(),
                                     metadata={"workshop": "claude-builders-v4", "owner": USER})
        state["agent_id"] = agent.id
        save_state(state)
        print(f"created agent {agent.id} version {agent.version}")

    # second half: bump the system prompt -> a new version; re-read first so a re-run is a no-op (no version 3)
    if (agent.system or "").endswith(EXTRA_LINE.strip()):
        print(f"agent already carries the extra line — no update sent (still version {agent.version})")
    else:
        try:
            agent = c.beta.agents.update(agent.id, version=agent.version, system=(agent.system or SYSTEM) + EXTRA_LINE)
            print(f"updated agent -> version {agent.version}")
        except APIStatusError as err:
            if err.status_code == 409:
                print("409: someone updated the agent in between — re-read and retry (optimistic concurrency)")
            raise
    state["agent_version"] = agent.version
    save_state(state)
    for v in c.beta.agents.versions.list(agent.id):
        print("version", v.version, getattr(v, "updated_at", ""))


# ----------------------------------------------------------------------------- streaming helpers (steps 3-4, attach)
def render(ev) -> None:
    t = ev.type
    if t == "agent.message":
        print("".join(b.text for b in ev.content if b.type == "text"), end="", flush=True)
    elif t in ("agent.tool_use", "agent.mcp_tool_use", "agent.custom_tool_use"):
        print(f"\n[{t.split('.')[1]}: {ev.name}] {json.dumps(ev.input)[:110]}")
    elif t == "span.model_request_end":
        u = ev.model_usage
        print(f"\n  · model request: in={u.input_tokens} cached={u.cache_read_input_tokens} out={u.output_tokens}")
    elif t == "session.usage":
        print(f"\n  · session.usage: active={getattr(ev, 'active_seconds', '?')}s")
    elif t == "session.error":
        print(f"\n[session.error] {ev.error.message if getattr(ev, 'error', None) else 'unknown'}")
    elif t == "session.status_running":
        print("\n[running]")


def resolve(session_id: str, pending: list, auto_yes: bool) -> None:
    """Answer EVERY blocking event: custom tools we execute ourselves; always_ask tools a human decides."""
    for ev in pending:
        if ev.type == "agent.custom_tool_use":
            result = create_ticket(**ev.input) if ev.name == "create_ticket" else f"unknown tool {ev.name}"
            print(f"\n  <- custom_tool_result: {result}")
            reply = {"type": "user.custom_tool_result", "custom_tool_use_id": ev.id,
                     "content": [{"type": "text", "text": str(result)}]}
        else:
            if auto_yes:
                ok = True
                print(f"\n  <- auto-allow {ev.name} (--yes)")
            else:
                ans = input(f"\nAllow {ev.name} {json.dumps(ev.input)[:100]} ? [a]llow/[d]eny: ").strip().lower()
                ok = ans.startswith("a") or ans.startswith("y")
            reply = {"type": "user.tool_confirmation", "tool_use_id": ev.id, "result": "allow" if ok else "deny"}
            if not ok:
                reply["deny_message"] = "Operator declined this fetch; finish the report without the upstream check."
        client().beta.sessions.events.send(session_id, events=[reply])


def stream_turn(session_id: str, *, send: list | None = None, replay_history: bool = False,
                auto_yes: bool = False, expect_idles: int = 1, on_running=None) -> str | None:
    """Open the stream FIRST, optionally replay history, then send; render until the Nth non-action idle.

    Returns the last stop_reason type. requires_action idles are resolved and do not count.
    """
    c = client()
    seen: set[str] = set()
    by_id: dict[str, object] = {}
    idles = 0
    last_reason = None
    with c.beta.sessions.events.stream(session_id) as stream:                    # open the stream FIRST ...
        backlog = list(c.beta.sessions.events.list(session_id)) if replay_history else []
        if send:                                                                    # ... THEN send (no race)
            c.beta.sessions.events.send(session_id, events=send)
        if on_running:
            on_running()
        for ev in itertools.chain(backlog, stream):
            if ev.type in ("event_start", "event_delta"):                        # deltas only if you opted in
                continue
            ev_id = getattr(ev, "id", None)
            if ev_id:
                if ev_id in seen:
                    continue
                seen.add(ev_id)
                by_id[ev_id] = ev
            render(ev)
            if ev.type == "session.status_idle":
                last_reason = ev.stop_reason.type
                if last_reason == "requires_action":
                    resolve(session_id, [by_id[i] for i in ev.stop_reason.event_ids if i in by_id], auto_yes)
                    continue                                                        # back to running; keep tailing
                idles += 1
                print(f"\n[idle: {last_reason}]")
                if idles >= expect_idles:
                    break                                                           # end_turn | budget_reached | retries_exhausted
            elif ev.type == "session.status_terminated":
                last_reason = "terminated"
                print("\n[terminated]")
                break
    return last_reason


def user_message(text: str) -> dict:
    return {"type": "user.message", "content": [{"type": "text", "text": text}]}


# ----------------------------------------------------------------------------- step 3: session
def step3(state: dict, *, auto_yes: bool = False, new_session: bool = False, **_) -> None:
    c = client()
    agent_id = need(state, "agent_id", "step2")
    env_id = need(state, "environment_id", "step1")
    if "session_id" in state and not new_session:
        sess = c.beta.sessions.retrieve(state["session_id"])
        print(f"reusing session {sess.id} (status={sess.status}) — attaching; pass --new-session to start a fresh one")
        stream_turn(sess.id, replay_history=True, auto_yes=auto_yes)
        return
    session = c.beta.sessions.create(
        agent=agent_id,                                       # bare ID = latest version; pin with {"type":"agent","id":…,"version":N}
        environment_id=env_id,
        title=f"paymentservice bug hunt ({USER})",
        metadata={"workshop": "claude-builders-v4", "owner": USER},
        initial_events=[user_message(TASK)],                  # starts the turn in the same call: status goes straight to running
    )
    state["session_id"] = session.id
    save_state(state)
    print(f"created session {session.id} — streaming (Ctrl+C detaches; `attach` re-opens)")
    stream_turn(session.id, replay_history=True, auto_yes=auto_yes)             # replay because initial_events already started work


# ----------------------------------------------------------------------------- step 4: steer + follow-up
def step4(state: dict, *, auto_yes: bool = False, interrupt_after: int = 20, **_) -> None:
    c = client()
    sid = need(state, "session_id", "step3")
    status = c.beta.sessions.retrieve(sid).status
    if status == "running":
        print("session is still running — attaching until it idles first")
        stream_turn(sid, auto_yes=auto_yes)

    def fire_interrupt() -> None:
        print(f"\n>>> {interrupt_after}s elapsed: user.interrupt + redirect")
        c.beta.sessions.events.send(sid, events=[
            {"type": "user.interrupt"},
            user_message("Skip the upstream comparison; finish the report now."),
        ])

    timer = threading.Timer(interrupt_after, fire_interrupt)
    print(f"(a) re-sending the analysis task; interrupt fires in {interrupt_after}s")
    # the interrupted turn ends with a normal end_turn idle, then the redirect starts a new turn -> wait for 2 idles
    stream_turn(sid, send=[user_message(TASK)], auto_yes=auto_yes, expect_idles=2, on_running=timer.start)
    timer.cancel()
    print("\n(b) follow-up on the SAME session (history + sandbox persisted; watch cached= grow)")
    stream_turn(sid, send=[user_message("Summarize the report in 3 bullets.")], auto_yes=auto_yes)


# ----------------------------------------------------------------------------- step 5: outputs + usage
def step5(state: dict, **_) -> None:
    c = client()
    sid = need(state, "session_id", "step3")
    found = False
    for f in c.beta.files.list(scope_id=sid, betas=[BETA]):                     # session-scoped outputs need the beta on Files
        print(f.id, f.filename)
        if f.filename.endswith("bug-report.md"):
            c.beta.files.download(f.id).write_to_file("bug-report.md")
            found = True
    print("downloaded bug-report.md" if found else "no bug-report.md yet — ask the agent (same session) to write it to /mnt/session/outputs/")
    sess = c.beta.sessions.retrieve(sid)
    u = sess.usage
    if u is None:
        print(f"status={sess.status}; no usage reported yet")
        return
    runtime_usd = (u.active_seconds or 0) / 3600 * SESSION_HOUR_USD             # rate as of Aug 2026 — check the pricing page
    list_cost = f"${int(u.list_cost.amount) / 100:.2f}" if getattr(u, "list_cost", None) else "n/a"
    print(f"status={sess.status} in={u.input_tokens} out={u.output_tokens} cache_read={u.cache_read_input_tokens} "
          f"active={u.active_seconds or 0:.0f}s  list_cost={list_cost} (runtime part ≈ ${runtime_usd:.3f})")
    print("Now open Console -> Sessions -> this session -> Tracing view (do NOT archive yet; cleanup.sh does that in M8)")


def step6(state: dict, **_) -> None:
    here = pathlib.Path(__file__).resolve().parent
    snippets = here.parent.parent / "snippets"
    print("Pick ONE preview (each snippet reads .cma-state.json from the current directory):")
    print(f"  (a) budget      : uv run python {os.path.relpath(snippets / 'budget.py')}")
    print(f"  (b) deployment  : uv run python {os.path.relpath(snippets / 'deployment.py')}   (or Console -> Deployments -> New)")
    print(f"  (c) webhook     : ANTHROPIC_WEBHOOK_SIGNING_KEY=whsec_... uv run python {os.path.relpath(here.parent.parent / 'webhook_receiver.py')}")
    print("Stretch snippets: memory_store.py, outcome.py, vault_mcp.py, overrides.py, multiagent.py, github_resource.py")


# ----------------------------------------------------------------------------- attach / status / cleanup
def attach(state: dict, *, auto_yes: bool = False, **_) -> None:
    sid = need(state, "session_id", "step3")
    print(f"attaching to {sid}: replaying history, then tailing; pending confirmations will be asked")
    stream_turn(sid, replay_history=True, auto_yes=auto_yes)


def status(state: dict, **_) -> None:
    print(json.dumps(state, indent=2) if state else f"no {STATE_FILE} here yet")
    if "session_id" in state:
        s = client().beta.sessions.retrieve(state["session_id"])
        print(f"session {s.id}: status={s.status} title={s.title!r}")


def cleanup(state: dict, *, auto_yes: bool = False, **_) -> None:
    """Interrupt (if running) and archive the cached session. Agents/environments are archived by labs/cleanup.sh."""
    c = client()
    sid = state.get("session_id")
    if not sid:
        print("no cached session")
        return
    if c.beta.sessions.retrieve(sid).status == "running":
        print("session running -> user.interrupt, waiting for idle")
        stream_turn(sid, send=[{"type": "user.interrupt"}], auto_yes=True)
    c.beta.sessions.archive(sid)                            # keeps history, blocks new events; .delete(sid) removes everything
    print(f"archived {sid}")


STEPS = {"step1": step1, "step2": step2, "step3": step3, "step4": step4, "step5": step5, "step6": step6,
         "attach": attach, "status": status, "cleanup": cleanup}


def main(argv: list[str]) -> int:
    if not argv or argv[0] in {"-h", "--help", "help"}:
        print(__doc__)
        return 0 if argv else 2
    auto_yes = "--yes" in argv or "-y" in argv
    new_session = "--new-session" in argv
    interrupt_after = 20
    if "--interrupt-after" in argv:
        i = argv.index("--interrupt-after")
        try:
            interrupt_after = int(argv[i + 1])
        except (IndexError, ValueError):
            print("--interrupt-after needs a number of seconds", file=sys.stderr)
            return 2
    wanted = [a for a in argv if not a.startswith("-") and not a.isdigit()]
    if wanted == ["all"]:
        wanted = ["step1", "step2", "step3", "step4", "step5"] if "--with-step4" in argv else ["step1", "step2", "step3", "step5"]
    unknown = [w for w in wanted if w not in STEPS]
    if unknown:
        print(f"unknown step(s): {unknown}\n\n{__doc__}", file=sys.stderr)
        return 2
    state = load_state()
    for name in wanted:
        print(f"\n=== {name} ===")
        t0 = time.time()
        try:
            STEPS[name](state, auto_yes=auto_yes, new_session=new_session, interrupt_after=interrupt_after)
        except KeyboardInterrupt:
            print("\n(detached — the session keeps running server-side; `attach` to resume watching)")
            return 130
        except APIStatusError as err:
            print(f"\nAPI error {err.status_code}: {err.message}", file=sys.stderr)
            if err.status_code in (403, 404):
                print("  403/404 usually means Managed Agents (beta) is not enabled for this key's org/workspace, "
                      "or a raw call is missing the beta header. See the module's Troubleshooting table.", file=sys.stderr)
            return 1
        print(f"--- {name} done in {time.time() - t0:.0f}s")
        state = load_state()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
