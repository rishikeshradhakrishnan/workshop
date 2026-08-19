"""Step 2 success check: uv run python -m bughunter.validate [path-to-findings.json]"""
import json
import os
import sys
from pathlib import Path

from jsonschema import validate

from .schema import FINDINGS_SCHEMA

OTEL = Path(os.environ.get("OTEL", ".")).resolve()
path = Path(sys.argv[1]) if len(sys.argv) > 1 else max((OTEL / "reports").glob("*.findings.json"), key=lambda p: p.stat().st_mtime)
data = json.loads(path.read_text())
validate(instance=data, schema=FINDINGS_SCHEMA)          # raises jsonschema.ValidationError with a precise path on failure
print(f"OK: {len(data['findings'])} findings valid in {path}")
