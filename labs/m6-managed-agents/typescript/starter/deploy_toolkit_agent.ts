/* deploy_toolkit_agent.ts — Module 6 TypeScript track (STARTER — fill the TODO(step-n) blocks; solution in ../solution/).
 *   cd labs/m6-managed-agents/typescript && npm ci
 *   cd solution && npx tsx deploy_toolkit_agent.ts step1|step2|step3|step4|step5|all|attach [--yes]
 * Same eight calls as the Python track; IDs cached in ./.cma-state.json. Env: ANTHROPIC_API_KEY, CMA_MODEL (full model ID), WORKSHOP_ORG, GITHUB_USER. */
import Anthropic from "@anthropic-ai/sdk";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import * as readline from "node:readline/promises";
import { CREATE_TICKET_DESCRIPTION, CREATE_TICKET_INPUT_SCHEMA, createTicket } from "../../../shared/tickets.js";   // M5's handler

const BETA = "managed-agents-2026-04-01";
const TOOLSET = "agent_toolset_20260401";
const STATE_FILE = ".cma-state.json";
const client = new Anthropic();                                    // beta header set by the SDK on client.beta.*
const { CMA_MODEL: MODEL = "", WORKSHOP_ORG: ORG = "<WORKSHOP_ORG>" } = process.env as Record<string, string>;   // CMA_MODEL = full model ID
const USER = process.env.GITHUB_USER ?? process.env.USER ?? "anon";
const SYSTEM = readFileSync(new URL("../../../shared/prompts/bug_hunter_system.md", import.meta.url), "utf8");
const EXTRA_LINE = "\nAlways include the exact file:line for every finding.";
const TASK = `Clone https://github.com/${ORG}/opentelemetry-demo (depth 1) into /workspace. Analyze src/paymentservice for bugs ` +
  `and write /mnt/session/outputs/bug-report.md. File a ticket for each HIGH finding with create_ticket. Then fetch ` +
  `https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md and note anything already fixed upstream.`;
const AUTO_YES = process.argv.includes("--yes") || process.argv.includes("-y");

type State = { environment_id?: string; agent_id?: string; agent_version?: number; session_id?: string };
const loadState = (): State => (existsSync(STATE_FILE) ? JSON.parse(readFileSync(STATE_FILE, "utf8")) : {});
const saveState = (s: State) => writeFileSync(STATE_FILE, JSON.stringify(s, null, 2));
const need = (s: State, k: keyof State, step: string) => { if (!s[k]) { console.error(`${k} missing — run ${step} first`); process.exit(2); } return s[k] as string; };
const userMessage = (text: string) => ({ type: "user.message" as const, content: [{ type: "text" as const, text }] });

// (1) environment
async function step1(state: State) {
  if (state.environment_id) return console.log(`reusing ${state.environment_id}`);
  // TODO(step-1): client.beta.environments.create({ name: `ws-${USER}`, config: { type: "cloud", packages: { pip: ["ruff"] },
  //   networking: { type: "limited", allowed_hosts: [github.com, api.github.com, raw.githubusercontent.com], allow_package_managers: true, allow_mcp_servers: false } } })
  const env: { id: string } = await Promise.reject(new Error("TODO(step-1): create the environment"));
  state.environment_id = env.id; saveState(state);
  console.log(`created environment ${env.id}`);
}

// (2) agent, then version 2
async function step2(state: State) {
  let agent;
  if (state.agent_id) { console.log(`reusing ${state.agent_id}`); agent = await client.beta.agents.retrieve(state.agent_id); }
  else {
    // TODO(step-2): client.beta.agents.create({ name: `codebase-toolkit-${USER}`, model: MODEL, system: SYSTEM, tools: [
    //   { type: TOOLSET, default_config: { permission_policy: { type: "always_allow" } },
    //     configs: [{ name: "web_fetch", permission_policy: { type: "always_ask" } }, { name: "web_search", enabled: false }] },
    //   { type: "custom", name: "create_ticket", description: CREATE_TICKET_DESCRIPTION, input_schema: CREATE_TICKET_INPUT_SCHEMA } ] })
    void TOOLSET; void CREATE_TICKET_DESCRIPTION; void CREATE_TICKET_INPUT_SCHEMA; void MODEL;
    agent = await Promise.reject(new Error("TODO(step-2): create the agent")) as Awaited<ReturnType<typeof client.beta.agents.retrieve>>;
    state.agent_id = agent.id; saveState(state);
    console.log(agent.id, "version", agent.version);
  }
  if ((agent.system ?? "").endsWith(EXTRA_LINE.trim())) console.log(`already updated (version ${agent.version})`);
  else { agent = await client.beta.agents.update(agent.id, { version: agent.version, system: (agent.system ?? SYSTEM) + EXTRA_LINE }); console.log("updated -> version", agent.version); }
  state.agent_version = agent.version; saveState(state);
  for await (const v of client.beta.agents.versions.list(agent.id)) console.log("version", v.version);
}

// (4)(5)(6) stream + confirmations + custom tool results
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
async function streamTurn(sessionId: string, opts: { send?: any[]; replayHistory?: boolean; expectIdles?: number; onRunning?: () => void } = {}) {
  const byId = new Map<string, any>();
  const seen = new Set<string>();
  let idles = 0;
  const stream = await client.beta.sessions.events.stream(sessionId);      // open FIRST
  const backlog: any[] = [];
  if (opts.replayHistory) for await (const ev of client.beta.sessions.events.list(sessionId)) backlog.push(ev);
  if (opts.send) await client.beta.sessions.events.send(sessionId, { events: opts.send });   // THEN send
  opts.onRunning?.();
  async function* chain() { yield* backlog; for await (const ev of stream) yield ev; }
  for await (const ev of chain() as AsyncIterable<any>) {
    if (ev.type === "event_start" || ev.type === "event_delta") continue;
    if (ev.id) { if (seen.has(ev.id)) continue; seen.add(ev.id); byId.set(ev.id, ev); }
    if (ev.type === "agent.message") process.stdout.write(ev.content.map((b: any) => (b.type === "text" ? b.text : "")).join(""));
    else if (ev.type === "agent.tool_use" || ev.type === "agent.custom_tool_use" || ev.type === "agent.mcp_tool_use") console.log(`\n[${ev.type}: ${ev.name}] ${JSON.stringify(ev.input).slice(0, 110)}`);
    else if (ev.type === "span.model_request_end") console.log(`\n  · in=${ev.model_usage.input_tokens} cached=${ev.model_usage.cache_read_input_tokens} out=${ev.model_usage.output_tokens}`);
    else if (ev.type === "session.error") console.log(`\n[session.error] ${ev.error?.message ?? "unknown"}`);
    else if (ev.type === "session.status_terminated") { console.log("\n[terminated]"); break; }
    else if (ev.type === "session.status_idle") {
      if (ev.stop_reason.type !== "requires_action") { console.log(`\n[idle: ${ev.stop_reason.type}]`); if (++idles >= (opts.expectIdles ?? 1)) break; continue; }
      for (const id of ev.stop_reason.event_ids as string[]) {                 // answer EVERY pending id
        const pending = byId.get(id); if (!pending) continue;
        // TODO(step-3): agent.custom_tool_use -> const result = await createTicket(pending.input); send
        //   { type: "user.custom_tool_result", custom_tool_use_id: id, content: [{ type: "text", text: String(result) }] }
        // otherwise (always_ask tool) -> ask [a/d] (or AUTO_YES) and send
        //   { type: "user.tool_confirmation", tool_use_id: id, result: "allow" | "deny", deny_message? }
        void createTicket; void AUTO_YES; void rl; void pending;
        throw new Error(`TODO(step-3): answer pending event ${id}`);
      }
    }
  }
  stream.controller.abort();
}

// (3) session
async function step3(state: State) {
  const agentId = need(state, "agent_id", "step2"), envId = need(state, "environment_id", "step1");
  if (state.session_id && !process.argv.includes("--new-session")) {
    console.log(`reusing session ${state.session_id} — attaching (pass --new-session for a fresh one)`);
    return streamTurn(state.session_id, { replayHistory: true });
  }
  // create idle, open the stream, THEN send the first message (the no-race pattern)
  // TODO(step-3): client.beta.sessions.create({ agent: agentId, environment_id: envId, title: `paymentservice bug hunt (${USER})` })
  void agentId; void envId;
  const session: { id: string } = await Promise.reject(new Error("TODO(step-3): create the session"));
  state.session_id = session.id; saveState(state);
  console.log(`created session ${session.id}`);
  await streamTurn(session.id, { send: [userMessage(TASK)] });
}

// (4) steer + follow-up
async function step4(state: State) {
  const sid = need(state, "session_id", "step3");
  const i = process.argv.indexOf("--interrupt-after");
  const after = i > -1 ? Number(process.argv[i + 1]) : 20;
  let timer: NodeJS.Timeout | undefined;
  await streamTurn(sid, {
    send: [userMessage(TASK)], expectIdles: 2,
    onRunning: () => { timer = setTimeout(() => { console.log(`\n>>> ${after}s: interrupt + redirect`);
      void client.beta.sessions.events.send(sid, { events: [{ type: "user.interrupt" }, userMessage("Skip the upstream comparison; finish the report now.")] }); }, after * 1000); },
  });
  if (timer) clearTimeout(timer);
  console.log("\n(b) follow-up on the same session");
  await streamTurn(sid, { send: [userMessage("Summarize the report in 3 bullets.")] });
}

// (7) outputs + usage
async function step5(state: State) {
  const sid = need(state, "session_id", "step3");
  // TODO(step-5): const files = await client.beta.files.list({ scope_id: sid, betas: [BETA] }); print id/filename;
  //   download the one ending in bug-report.md via client.beta.files.download(f.id) and writeFileSync("bug-report.md", ...)
  void BETA; void writeFileSync;
  const sess: any = await client.beta.sessions.retrieve(sid);
  const u = sess.usage;
  if (u) console.log(`status=${sess.status} in=${u.input_tokens} out=${u.output_tokens} cache_read=${u.cache_read_input_tokens} active=${u.active_seconds}s list_cost=$${(Number(u.list_cost?.amount ?? 0) / 100).toFixed(2)}`);
}

async function attach(state: State) { await streamTurn(need(state, "session_id", "step3"), { replayHistory: true }); }

// (8) stop: interrupt if running, then archive
async function cleanup(state: State) {
  const sid = state.session_id; if (!sid) return console.log("no cached session");
  if ((await client.beta.sessions.retrieve(sid)).status === "running") await streamTurn(sid, { send: [{ type: "user.interrupt" }] });
  await client.beta.sessions.archive(sid); console.log(`archived ${sid}`);
}

const STEPS: Record<string, (s: State) => Promise<unknown> | unknown> = { step1, step2, step3, step4, step5, attach, cleanup };
let wanted = process.argv.slice(2).filter((a) => !a.startsWith("-") && !/^\d+$/.test(a));
if (wanted.length === 0 || wanted[0] === "help") { console.log("usage: npx tsx deploy_toolkit_agent.ts step1|step2|step3|step4|step5|all|attach|cleanup [--yes] [--interrupt-after N] [--new-session]"); process.exit(2); }
if (wanted[0] === "all") wanted = ["step1", "step2", "step3", "step5"];
if (!process.env.ANTHROPIC_API_KEY) { console.error("ANTHROPIC_API_KEY is not set — source $WS/labs/.env"); process.exit(2); }
for (const name of wanted) {
  const fn = STEPS[name]; if (!fn) { console.error(`unknown step ${name}`); process.exit(2); }
  console.log(`\n=== ${name} ===`);
  const state = loadState();
  await fn(state);
}
rl.close();
process.exit(0);
