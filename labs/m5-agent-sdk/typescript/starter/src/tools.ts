/* Step 3 — custom tool served from an in-process SDK MCP server.
 * TODO(step-3):
 *   1. const createTicket = tool("create_ticket", "<description>",
 *        { title: z.string(), severity: z.string().describe("HIGH | MEDIUM | LOW"), file: z.string(), line: z.number().int() },
 *        async (args) => { ... return { content: [{ type: "text", text: `created ${id} ...` }] } })
 *      — for a bad severity return { content: [...], isError: true } instead of throwing
 *   2. export const trackerServer = createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] })
 *   3. in main.ts: mcpServers: { tracker: trackerServer } and add TICKET_TOOL to allowedTools (until step 4)
 */
import { createSdkMcpServer, tool } from "@anthropic-ai/claude-agent-sdk";   // eslint-disable-line @typescript-eslint/no-unused-vars
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { z } from "zod";                                                       // eslint-disable-line @typescript-eslint/no-unused-vars

const TICKETS = "tickets.json";
export const TICKET_TOOL = "mcp__tracker__create_ticket";   // mcp__<key in mcpServers>__<tool name>

export function appendTicket(title: string, severity: string, file: string, line: number): string {
  const tickets: unknown[] = existsSync(TICKETS) ? JSON.parse(readFileSync(TICKETS, "utf8")) : [];
  const id = `AST-${String(tickets.length + 1).padStart(4, "0")}`;
  tickets.push({ id, title, severity, file, line, created: new Date().toISOString() });
  writeFileSync(TICKETS, JSON.stringify(tickets, null, 2));
  return id;
}

// TODO(step-3): replace with createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] })
export const trackerServer: ReturnType<typeof createSdkMcpServer> | undefined = undefined;
