/* bughunter — Claude Agent SDK lab (Module 5), TypeScript track — STARTER.
 *   npx tsx src/main.ts <service-path> [--ticket]
 *   npx tsx src/main.ts followup "<question>"
 * Fill the TODO(step-n) blocks in order; success checks are in modules/05-claude-agent-sdk.md.
 * Stuck past a step's minute budget? Copy the block from ../solution/ and move on.            */
import { query, type Options, type SDKResultMessage } from "@anthropic-ai/claude-agent-sdk";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";   // eslint-disable-line @typescript-eslint/no-unused-vars
import path from "node:path";
import { protectSecretsHook, ticketPolicy } from "./hooks.js";                 // eslint-disable-line @typescript-eslint/no-unused-vars  (step 4)
import { FINDINGS_JSON_SCHEMA, Findings } from "./schema.js";                  // eslint-disable-line @typescript-eslint/no-unused-vars  (step 2)
import { TICKET_TOOL, trackerServer } from "./tools.js";                       // eslint-disable-line @typescript-eslint/no-unused-vars  (step 3)

export const OTEL = path.resolve(process.env.OTEL ?? ".");
const PLUGIN = path.resolve(process.env.TOOLKIT_PLUGIN ?? path.join(OTEL, "..", "codebase-toolkit"));
const MODEL = process.env.MODEL ?? "sonnet";
const SESSION_FILE = ".bughunter-session";

const PROMPT = (service: string) =>
  `Use the codebase-toolkit:bug-hunter agent to analyze the service at \`${service}\` for bugs ` +
  `(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). ` +
  `Then consolidate its report into the required JSON findings object for service \`${service}\`. ` +
  `Every finding needs a real file path relative to the repository root and a line number you have verified.`;
const TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH severity finding.";
// step 4 changes the suffix to "...for each HIGH or MEDIUM severity finding" so the policy has something to refuse.

function baseOptions(overrides: Partial<Options> = {}): Options {          // step 1
  // TODO(step-1): cwd: OTEL, model: MODEL, settingSources: ["project"], plugins: [{ type: "local", path: PLUGIN }],
  //               allowedTools: ["Read", "Grep", "Glob", "Agent"], permissionMode: "dontAsk", maxTurns: 40, maxBudgetUsd: 1.0
  void PLUGIN; void MODEL;
  return {
    cwd: OTEL,
    maxBudgetUsd: 1.0,          // pre-set: never remove the budget cap in a workshop room
    ...overrides,               // NB: never pass `env` without spreading process.env (TS replaces it)
  };
}

async function consume(messages: AsyncIterable<any>): Promise<SDKResultMessage | undefined> {
  let result: SDKResultMessage | undefined;
  try {
    for await (const msg of messages) {
      // TODO(step-1): system/init -> log msg.model, msg.apiKeySource, msg.plugins.map(p => p.name)
      //               assistant   -> log text blocks and `-> ${block.name}` for tool_use (prefix "(subagent)" if msg.parent_tool_use_id)
      //               result      -> keep it (do not break)
      if (msg.type === "result") result = msg;
    }
  } catch (err) {                       // single-shot query() throws AFTER yielding an error result
    console.error(`query ended with an error: ${err}`);
  }
  return result;
}

function report(result: SDKResultMessage, service?: string): number {     // steps 2 & 5
  console.log(`\nDone: ${result.subtype} $${result.total_cost_usd.toFixed(4)} ` +
    `(turns=${result.num_turns}, terminal_reason=${result.terminal_reason}, session=${result.session_id})`);
  for (const d of result.permission_denials ?? []) console.log(`  permission denial: ${JSON.stringify(d)}`);
  // TODO(step-5): log result.usage and result.modelUsage; writeFileSync(SESSION_FILE, result.session_id)
  // TODO(step-2): if service && result.structured_output: Findings.parse it and write OTEL/reports/<basename>.findings.json;
  //               if service but no structured_output: console.error(...) and return 1
  void service; void SESSION_FILE;
  return result.subtype === "success" ? 0 : 1;
}

async function run(service: string, ticket: boolean): Promise<number> {
  const options = baseOptions({
    // TODO(step-2): outputFormat: { type: "json_schema", schema: FINDINGS_JSON_SCHEMA },
    // TODO(step-3): mcpServers: { tracker: trackerServer! },   (+ TICKET_TOOL in allowedTools)
    // TODO(step-4): hooks: { PreToolUse: [{ matcher: "Read", hooks: [protectSecretsHook] }] }, canUseTool: ticketPolicy, permissionMode: "default"
  });
  const result = await consume(query({ prompt: PROMPT(service) + (ticket ? TICKET_SUFFIX : ""), options }));
  return result ? report(result, service) : 1;
}

async function followup(question: string): Promise<number> {
  if (!existsSync(SESSION_FILE)) { console.error("no .bughunter-session yet — run an analysis first (and finish step 5)"); return 2; }
  // TODO(step-5): const options = baseOptions({ resume: readFileSync(SESSION_FILE, "utf8").trim() }); consume(query({ prompt: question, options }))
  void question;
  console.error("TODO(step-5): followup not implemented yet");
  return 2;
}

const args = process.argv.slice(2);
if (args.length === 0) { console.error("usage: bughunter <service-path> [--ticket] | bughunter followup \"<question>\""); process.exit(2); }
if (!process.env.ANTHROPIC_API_KEY && !process.env.CLAUDE_CODE_USE_BEDROCK && !process.env.CLAUDE_CODE_USE_VERTEX && !process.env.CLAUDE_CODE_USE_FOUNDRY) {
  console.error("warning: no ANTHROPIC_API_KEY / provider env set — see module 5.2");
}
const code = args[0] === "followup"
  ? await followup(args.slice(1).join(" ") || "Summarize the findings in three bullets.")
  : await run(args[0], args.slice(1).includes("--ticket"));
process.exit(code);
