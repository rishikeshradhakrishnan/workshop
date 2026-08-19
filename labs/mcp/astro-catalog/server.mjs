#!/usr/bin/env node
/**
 * astro-catalog — the workshop's local stdio MCP server (Module 2 onward).
 *
 *   node server.mjs              # run as an MCP server over stdio (what `claude mcp add ... -- node server.mjs` starts)
 *   node server.mjs --selftest   # no client needed: loads the catalog, connects an in-memory client, lists and calls
 *                                # every tool, prints "OK" and the tool names, exits 0 (used by labs/preflight.sh)
 *
 * Tools (three by default):
 *   list_products   filter the Astronomy Shop catalog by minimum price / category
 *   get_product     one product by id (or fuzzy name)
 *   service_owner   which service directory + team owns a topic ("pricing", "currency", a product id, ...)
 * Optional fourth tool for the Module 4 stretch goal (g), only when ASTRO_CATALOG_ENABLE_APPROVE=1:
 *   approve         a toy --permission-prompt-tool target that allows Read/Grep/Glob and denies everything else
 *
 * Environment:
 *   CATALOG_CURRENCY   display currency for prices (USD, EUR, GBP, JPY, CHF, CAD); default USD
 *
 * Deliberately tiny: few tools, tight descriptions, small paginated results — the design advice from Module 2.
 * No network access; the only file it reads is data/products.json next to this script.
 */
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = JSON.parse(readFileSync(path.join(HERE, "data", "products.json"), "utf8"));
const CURRENCY = (process.env.CATALOG_CURRENCY || "USD").toUpperCase();
const RATE = DATA.fx[CURRENCY] ?? 1.0;
const ENABLE_APPROVE = process.env.ASTRO_CATALOG_ENABLE_APPROVE === "1";
const VERSION = "4.0.0";

function money(usd) {
  const value = Math.round(usd * RATE * 100) / 100;
  return { amount: value, currency: DATA.fx[CURRENCY] ? CURRENCY : "USD" };
}

function shapeProduct(p) {
  return {
    id: p.id,
    name: p.name,
    categories: p.categories,
    price: money(p.price_usd),
    price_usd: p.price_usd,
    description: p.description,
    pricing_owner: "productcatalogservice (src/productcatalogservice)",
  };
}

function text(obj) {
  return { content: [{ type: "text", text: typeof obj === "string" ? obj : JSON.stringify(obj, null, 2) }] };
}

export function buildServer() {
  const server = new McpServer(
    { name: "astro-catalog", version: VERSION },
    { instructions: "Astronomy Shop product catalog and service-ownership lookup for the workshop's opentelemetry-demo clone. Prices are list prices; ownership answers name a directory under src/." },
  );

  server.registerTool(
    "list_products",
    {
      title: "List catalog products",
      description:
        "List Astronomy Shop products, optionally filtered by minimum USD price and/or category (telescopes, binoculars, accessories, books, ...). Returns id, name, categories, price and the service that owns pricing. Max 25 per page.",
      inputSchema: {
        min_price_usd: z.number().nonnegative().optional().describe("Only products costing at least this many USD"),
        category: z.string().optional().describe("Category to filter on, e.g. 'telescopes'"),
        limit: z.number().int().min(1).max(25).optional().describe("Page size (default 25)"),
        offset: z.number().int().min(0).optional().describe("Offset for pagination (default 0)"),
      },
      annotations: { readOnlyHint: true },
    },
    async ({ min_price_usd, category, limit = 25, offset = 0 }) => {
      let items = DATA.products;
      if (typeof min_price_usd === "number") items = items.filter((p) => p.price_usd >= min_price_usd);
      if (category) {
        const c = category.toLowerCase().replace(/s$/, "");
        items = items.filter((p) => p.categories.some((x) => x.toLowerCase().replace(/s$/, "") === c));
      }
      const page = items.slice(offset, offset + limit).map(shapeProduct);
      return text({ total: items.length, offset, count: page.length, display_currency: money(0).currency, products: page });
    },
  );

  server.registerTool(
    "get_product",
    {
      title: "Get one product",
      description: "Fetch a single Astronomy Shop product by catalog id (e.g. OLJCESPC7Z) or by a case-insensitive name fragment.",
      inputSchema: { id_or_name: z.string().min(1).describe("Product id or part of its name") },
      annotations: { readOnlyHint: true },
    },
    async ({ id_or_name }) => {
      const q = id_or_name.trim().toLowerCase();
      const hit =
        DATA.products.find((p) => p.id.toLowerCase() === q) ||
        DATA.products.find((p) => p.name.toLowerCase().includes(q));
      if (!hit) return { content: [{ type: "text", text: `No product matches '${id_or_name}'. Try list_products first.` }], isError: true };
      return text(shapeProduct(hit));
    },
  );

  server.registerTool(
    "service_owner",
    {
      title: "Which service owns this?",
      description:
        "Given a topic (pricing, currency, checkout, cart, shipping, ads, recommendations, email, payment, reviews, feature flags) or a product id, return the owning service, its directory under src/ in opentelemetry-demo, its language and the owning team.",
      inputSchema: { topic: z.string().min(1).describe("A capability keyword or a product id") },
      annotations: { readOnlyHint: true },
    },
    async ({ topic }) => {
      const q = topic.trim().toLowerCase();
      if (DATA.products.some((p) => p.id.toLowerCase() === q || p.name.toLowerCase().includes(q))) {
        const o = DATA.owners.find((x) => x.topic === "pricing");
        return text({ query: topic, matched: "product", ...o, note: "Product data and list prices are owned by the catalog service; currency conversion by currencyservice." });
      }
      const scored = DATA.owners
        .map((o) => ({ o, score: (o.topic === q ? 10 : 0) + o.keywords.filter((k) => q.includes(k) || k.includes(q)).length }))
        .filter((s) => s.score > 0)
        .sort((a, b) => b.score - a.score);
      if (!scored.length) {
        return text({ query: topic, matched: null, known_topics: DATA.owners.map((o) => o.topic) });
      }
      return text({ query: topic, matched: "topic", ...scored[0].o, also: scored.slice(1, 3).map((s) => s.o.service) });
    },
  );

  if (ENABLE_APPROVE) {
    // Module 4 stretch (g): a toy target for `claude -p --permission-prompt-tool mcp__astro-catalog__approve`.
    // Contract (see the Agent SDK permissions guide): input {tool_name, input}; reply with a JSON text block
    // {"behavior":"allow","updatedInput":{...}} or {"behavior":"deny","message":"..."}.
    server.registerTool(
      "approve",
      {
        title: "Toy permission prompt handler",
        description: "Workshop-only permission prompt tool: allows Read, Grep and Glob calls unchanged and denies every other tool. Do not use outside the lab.",
        inputSchema: {
          tool_name: z.string().describe("Name of the tool Claude wants to run"),
          input: z.record(z.any()).optional().describe("The tool input Claude proposed"),
          tool_use_id: z.string().optional(),
        },
      },
      async ({ tool_name, input }) => {
        const allowed = ["Read", "Grep", "Glob"].includes(tool_name);
        const decision = allowed
          ? { behavior: "allow", updatedInput: input ?? {} }
          : { behavior: "deny", message: `astro-catalog approve: '${tool_name}' is not on the workshop allowlist (Read, Grep, Glob)` };
        return { content: [{ type: "text", text: JSON.stringify(decision) }] };
      },
    );
  }

  return server;
}

async function selftest() {
  const { Client } = await import("@modelcontextprotocol/sdk/client/index.js");
  const { InMemoryTransport } = await import("@modelcontextprotocol/sdk/inMemory.js");
  const server = buildServer();
  const client = new Client({ name: "astro-catalog-selftest", version: VERSION });
  const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
  await Promise.all([server.connect(serverSide), client.connect(clientSide)]);
  const { tools } = await client.listTools();
  const names = tools.map((t) => t.name);
  for (const expected of ["list_products", "get_product", "service_owner"]) {
    if (!names.includes(expected)) throw new Error(`tool missing: ${expected}`);
  }
  const listed = await client.callTool({ name: "list_products", arguments: { min_price_usd: 100 } });
  const parsed = JSON.parse(listed.content[0].text);
  if (!(parsed.total >= 1)) throw new Error("list_products returned nothing over $100");
  const owner = await client.callTool({ name: "service_owner", arguments: { topic: "pricing" } });
  if (!/productcatalogservice/.test(owner.content[0].text)) throw new Error("service_owner(pricing) did not name productcatalogservice");
  const one = await client.callTool({ name: "get_product", arguments: { id_or_name: "OLJCESPC7Z" } });
  if (one.isError) throw new Error("get_product failed for a known id");
  await client.close();
  await server.close();
  console.log(`OK astro-catalog ${VERSION} — ${DATA.products.length} products, tools: ${names.join(", ")}`);
}

const args = process.argv.slice(2);
if (args.includes("--selftest")) {
  selftest().then(() => process.exit(0)).catch((err) => { console.error(`SELFTEST FAILED: ${err?.stack || err}`); process.exit(1); });
} else if (args.includes("--help") || args.includes("-h")) {
  console.log("usage: node server.mjs [--selftest]\n  stdio MCP server; register with: claude mcp add --transport stdio --scope project astro-catalog -- node <path>/server.mjs");
} else {
  const server = buildServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // stay alive until the client closes stdin
}
