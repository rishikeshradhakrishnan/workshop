/* bughunter — Claude Agent SDK lab (Module 5), TypeScript track.
 *   npx tsx src/main.ts <service-path> [--ticket]
 *   npx tsx src/main.ts followup "<question>"                                  */
import { query, type Options, type SDKResultMessage } from "@anthropic-ai/claude-agent-sdk";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { protectSecretsHook, ticketPolicy } from "./hooks.js";
import { FINDINGS_JSON_SCHEMA, Findings } from "./schema.js";
import { trackerServer } from "./tools.js";

export const OTEL = path.resolve(process.env.OTEL ?? ".");
const PLUGIN = path.resolve(process.env.TOOLKIT_PLUGIN ?? path.join(OTEL, "..", "codebase-toolkit"));
const MODEL = process.env.MODEL ?? "sonnet";
const SESSION_FILE = ".bughunter-session";

const PROMPT = (service: string) =>
  `Use the codebase-toolkit:bug-hunter agent to analyze the service at \`${service}\` for bugs ` +
  `(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). ` +
  `Then consolidate its report into the required JSON findings object for service \`${service}\`. ` +
  `Every finding needs a real file path relative to the repository root and a line number you have verified.`;
const TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH or MEDIUM severity finding.";

function baseOptions(overrides: Partial<Options> = {}): Options {          // step 1
  return {
    cwd: OTEL, model: MODEL,
    settingSources: ["project"],
    plugins: [{ type: "local", path: PLUGIN }],
    allowedTools: ["Read", "Grep", "Glob", "Agent"],                        // step 3 temporarily also listed mcp__tracker__create_ticket
    permissionMode: "dontAsk", maxTurns: 40, maxBudgetUsd: 1.0,
    ...overrides,                                                           // NB: never pass `env` without spreading process.env (TS replaces it)
  };
}

async function consume(messages: AsyncIterable<any>): Promise<SDKResultMessage | undefined> {
  let result: SDKResultMessage | undefined;
  try {
    for await (const msg of messages) {
      if (msg.type === "system" && msg.subtype === "init") {
        console.log(`model=${msg.model} auth=${msg.apiKeySource} plugins=${JSON.stringify(msg.plugins.map((p: any) => p.name))}`);
      } else if (msg.type === "assistant") {
        const prefix = msg.parent_tool_use_id ? "    (subagent) " : "";
        for (const block of msg.message.content) {
          if (block.type === "text" && !prefix) console.log(block.text);
          else if (block.type === "tool_use") console.log(`${prefix}-> ${block.name}`);
        }
      } else if (msg.type === "result") {
        result = msg;
      }
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
  const u = result.usage;
  console.log(`usage(main loop): in=${u.input_tokens} out=${u.output_tokens} cache_read=${u.cache_read_input_tokens} cache_write=${u.cache_creation_input_tokens}`);
  for (const [model, mu] of Object.entries(result.modelUsage)) {
    console.log(`  ${model}: $${mu.costUSD.toFixed(4)} in=${mu.inputTokens} out=${mu.outputTokens} cache_read=${mu.cacheReadInputTokens}`);
  }
  writeFileSync(SESSION_FILE, result.session_id);
  const structured = result.subtype === "success" ? result.structured_output : undefined;
  if (service && structured) {
    const findings = Findings.parse(structured);                            // belt and braces: Zod-parse what the SDK validated
    const out = path.join(OTEL, "reports", `${path.basename(service)}.findings.json`);
    mkdirSync(path.dirname(out), { recursive: true });
    writeFileSync(out, JSON.stringify(findings, null, 2));
    console.log(`wrote ${out} (${findings.findings.length} findings)`);
  } else if (service) {
    console.error("no structured_output on the result — treat as failure");
    return 1;
  }
  return result.subtype === "success" ? 0 : 1;
}

async function run(service: string, ticket: boolean): Promise<number> {
  const options = baseOptions({
    outputFormat: { type: "json_schema", schema: FINDINGS_JSON_SCHEMA },   // step 2
    mcpServers: { tracker: trackerServer },                                 // step 3
    hooks: { PreToolUse: [{ matcher: "Read", hooks: [protectSecretsHook] }] },  // step 4a
    canUseTool: ticketPolicy,                                               // step 4b
    permissionMode: "default",                                              // step 4b (was dontAsk)
  });
  const result = await consume(query({ prompt: PROMPT(service) + (ticket ? TICKET_SUFFIX : ""), options }));
  return result ? report(result, service) : 1;
}

async function followup(question: string): Promise<number> {
  if (!existsSync(SESSION_FILE)) { console.error("no .bughunter-session yet — run an analysis first"); return 2; }
  const options = baseOptions({ resume: readFileSync(SESSION_FILE, "utf8").trim() });   // step 5
  const result = await consume(query({ prompt: question, options }));
  return result ? report(result) : 1;
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
