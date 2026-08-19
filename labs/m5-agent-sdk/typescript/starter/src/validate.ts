import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { Findings } from "./schema.js";

const OTEL = path.resolve(process.env.OTEL ?? ".");
const dir = path.join(OTEL, "reports");
const file = process.argv[2] ?? readdirSync(dir).filter((f) => f.endsWith(".findings.json"))
  .map((f) => path.join(dir, f)).sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];
const parsed = Findings.parse(JSON.parse(readFileSync(file, "utf8")));   // throws ZodError listing every violation
console.log(`OK: ${parsed.findings.length} findings valid in ${file}`);
