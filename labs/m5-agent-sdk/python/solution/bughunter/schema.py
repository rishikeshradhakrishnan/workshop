"""Findings schema — same shape as labs/shared/findings.schema.json (M4) and Claude Security JSONL minus cwe_id (M7)."""
FINDING = {
    "type": "object",
    "properties": {
        "id": {"type": "string", "description": "F1, F2, ..."},
        "title": {"type": "string"},
        "severity": {"type": "string", "enum": ["HIGH", "MEDIUM", "LOW"]},
        "file": {"type": "string", "description": "path relative to the repository root"},
        "line": {"type": "integer", "minimum": 1},
        "category": {"type": "string", "description": "e.g. error-handling, concurrency, input-validation, resource-leak, security"},
        "description": {"type": "string"},
        "recommendation": {"type": "string"},
        "confidence": {"type": "string", "enum": ["low", "medium", "high"]},
    },
    "required": ["id", "title", "severity", "file", "line", "category", "description", "recommendation", "confidence"],
    "additionalProperties": False,
}
FINDINGS_SCHEMA = {
    "type": "object",
    "properties": {
        "service": {"type": "string"},
        "summary": {"type": "string"},
        "findings": {"type": "array", "items": FINDING},
    },
    "required": ["service", "summary", "findings"],
    "additionalProperties": False,
}
