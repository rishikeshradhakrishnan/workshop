import { createSdkMcpServer, tool } from "@anthropic-ai/claude-agent-sdk";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { z } from "zod";

const TICKETS = "tickets.json";
export const TICKET_TOOL = "mcp__tracker__create_ticket";

export function appendTicket(title: string, severity: string, file: string, line: number): string {
  const tickets: unknown[] = existsSync(TICKETS) ? JSON.parse(readFileSync(TICKETS, "utf8")) : [];
  const id = `AST-${String(tickets.length + 1).padStart(4, "0")}`;
  tickets.push({ id, title, severity, file, line, created: new Date().toISOString() });
  writeFileSync(TICKETS, JSON.stringify(tickets, null, 2));
  return id;
}

const createTicket = tool(
  "create_ticket",
  "File a bug ticket in the Astronomy Shop tracker for one confirmed finding. Returns the new ticket id.",
  { title: z.string(), severity: z.string().describe("HIGH | MEDIUM | LOW"), file: z.string(), line: z.number().int() },
  async (args) => {
    const severity = args.severity.toUpperCase();
    if (!["HIGH", "MEDIUM", "LOW"].includes(severity)) {
      return { content: [{ type: "text", text: `severity must be HIGH, MEDIUM or LOW, got ${args.severity}` }], isError: true };
    }
    const id = appendTicket(args.title, severity, args.file, args.line);
    return { content: [{ type: "text", text: `created ${id} for ${args.file}:${args.line}` }] };
  },
);

export const trackerServer = createSdkMcpServer({ name: "tracker", version: "1.0.0", tools: [createTicket] });
