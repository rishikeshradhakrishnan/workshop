#!/usr/bin/env bash
# labs/m4/bug-hunt.sh <service-path>  — run the toolkit's bug-hunter headlessly, emit schema-validated JSON
set -euo pipefail
TARGET="${1:?usage: bug-hunt.sh <service-path>}"
SCHEMA="$(cat "${WS:?export WS}/labs/shared/findings.schema.json")"
exec claude -p "@agent-codebase-toolkit:bug-hunter Analyze ${TARGET} for bugs. Report every finding with \
id, title, severity (HIGH|MEDIUM|LOW), file, line, category, description, recommendation, confidence (low|medium|high); \
set service to ${TARGET} and add a two-sentence summary." \
  --model "${MODEL:-sonnet}" \
  --output-format json \
  --json-schema "$SCHEMA" \
  --allowedTools "Read,Grep,Glob,Agent" \
  --permission-mode dontAsk \
  --max-turns 30 \
  --max-budget-usd 1.00
