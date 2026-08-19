/**
 * Shared create_ticket handler (TypeScript twin of tickets.py).
 * M5 wraps appendTicket() in an SDK MCP tool; M6 calls createTicket(event.input) for agent.custom_tool_use.
 * Tickets append to ./tickets.json in the current working directory.
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";

export const TICKETS = "tickets.json";
export const SEVERITIES = ["HIGH", "MEDIUM", "LOW"] as const;

/** JSON Schema for the tool input — reused as the Managed Agents custom tool input_schema (M6). */
export const CREATE_TICKET_INPUT_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string", description: "One-line summary of the confirmed finding" },
    severity: { type: "string", enum: ["HIGH", "MEDIUM", "LOW"] },
    file: { type: "string", description: "Path relative to the repository root" },
    line: { type: "integer", minimum: 1 },
  },
  required: ["title", "severity", "file", "line"],
} as const;

export const CREATE_TICKET_DESCRIPTION =
  "File a bug ticket in the team tracker. Call once per HIGH-severity finding, after you have " +
  "confirmed the file and line. Returns the new ticket ID. Do not call for MEDIUM/LOW findings.";

export function appendTicket(title: string, severity: string, file: string, line: number, path: string = TICKETS): string {
  const tickets: unknown[] = existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : [];
  const id = `AST-${String(tickets.length + 1).padStart(4, "0")}`;
  tickets.push({ id, title, severity, file, line, created: new Date().toISOString() });
  writeFileSync(path, JSON.stringify(tickets, null, 2));
  return id;
}

export interface CreateTicketInput { title?: unknown; severity?: unknown; file?: unknown; line?: unknown; [k: string]: unknown }

/** Validate and file a ticket; returns a result string (errors are strings too, so the agent can adapt). */
export async function createTicket(input: CreateTicketInput): Promise<string> {
  const sev = String(input.severity ?? "").toUpperCase();
  if (!(SEVERITIES as readonly string[]).includes(sev)) return `error: severity must be HIGH, MEDIUM or LOW, got ${JSON.stringify(input.severity)}`;
  const line = Number(input.line);
  if (!Number.isInteger(line)) return `error: line must be an integer, got ${JSON.stringify(input.line)}`;
  const id = appendTicket(String(input.title ?? ""), sev, String(input.file ?? ""), line);
  return `created ${id} for ${input.file}:${line}`;
}
