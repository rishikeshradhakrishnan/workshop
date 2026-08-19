import { z } from "zod";

export const Finding = z.object({
  id: z.string(), title: z.string(), severity: z.enum(["HIGH", "MEDIUM", "LOW"]),
  file: z.string(), line: z.number().int().min(1), category: z.string(),
  description: z.string(), recommendation: z.string(), confidence: z.enum(["low", "medium", "high"]),
});
export const Findings = z.object({ service: z.string(), summary: z.string(), findings: z.array(Finding) });
export type Findings = z.infer<typeof Findings>;
// The SDK validates against JSON Schema draft-07; Zod 4 emits 2020-12 unless told otherwise.
export const FINDINGS_JSON_SCHEMA = z.toJSONSchema(Findings, { target: "draft-7" }) as Record<string, unknown>;
