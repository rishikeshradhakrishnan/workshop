#!/usr/bin/env python3
"""labs/m7-security/compare_findings.py — Module 7 stretch (c): LLM-review variance, made visible.

  uv run python $WS/labs/m7-security/compare_findings.py <bughunter findings.json> <CLAUDE-SECURITY-RESULTS.jsonl> [more files…]

Accepts any mix of:
  * M5 bughunter output          ({"service","summary","findings":[…]} — labs/shared/findings.schema.json)
  * M4 `claude -p` result JSON   (the same object under .structured_output)
  * Claude Security plugin JSONL (one finding per line, same fields plus cwe_id/impact/…)
and prints, per pair: findings only in A, only in B, and the overlap — matched by file plus nearby line (±5) or by
similar titles. Use it to discuss why panel-verified findings are fewer and sharper than a single agent's list.
"""
from __future__ import annotations

import json
import re
import sys
from difflib import SequenceMatcher
from itertools import combinations
from pathlib import Path


def load(path: Path) -> list[dict]:
    text = path.read_text().strip()
    if not text:
        return []
    try:
        data = json.loads(text)                                              # a single JSON document (M4/M5 shapes)
    except json.JSONDecodeError:
        return [json.loads(line) for line in text.splitlines() if line.strip()]   # JSONL: one finding per line (plugin)
    if isinstance(data, dict) and "structured_output" in data:          # claude -p result envelope (M4)
        data = data["structured_output"] or {}
    if isinstance(data, dict) and "findings" in data:
        return list(data["findings"])
    if isinstance(data, list):
        return data
    raise SystemExit(f"{path}: unrecognised findings format")


def norm_title(t: str) -> str:
    return re.sub(r"[^a-z0-9 ]+", " ", (t or "").lower())


def same(a: dict, b: dict) -> bool:
    if a.get("file") and a.get("file") == b.get("file"):
        try:
            if abs(int(a.get("line", 0)) - int(b.get("line", 0))) <= 5:
                return True
        except (TypeError, ValueError):
            pass
        if a.get("cwe_id") and a.get("cwe_id") == b.get("cwe_id"):
            return True
    return SequenceMatcher(None, norm_title(a.get("title", "")), norm_title(b.get("title", ""))).ratio() >= 0.72


def label(f: dict) -> str:
    extra = f" {f['cwe_id']}" if f.get("cwe_id") else ""
    return f"[{f.get('severity', '?'):6}] {f.get('file', '?')}:{f.get('line', '?')}{extra} — {f.get('title', '')[:70]} (conf {f.get('confidence', '?')})"


def compare(name_a: str, fa: list[dict], name_b: str, fb: list[dict]) -> None:
    matched_b: set[int] = set()
    both, only_a = [], []
    for a in fa:
        hit = next((j for j, b in enumerate(fb) if j not in matched_b and same(a, b)), None)
        if hit is None:
            only_a.append(a)
        else:
            matched_b.add(hit)
            both.append((a, fb[hit]))
    only_b = [b for j, b in enumerate(fb) if j not in matched_b]
    print(f"\n=== {name_a} ({len(fa)})  vs  {name_b} ({len(fb)}) ===")
    print(f"overlap: {len(both)}   only in {name_a}: {len(only_a)}   only in {name_b}: {len(only_b)}")
    for a, b in both:
        print(f"  = {label(a)}\n    {label(b)}")
    for a in only_a:
        print(f"  A {label(a)}")
    for b in only_b:
        print(f"  B {label(b)}")
    sev = lambda fs: {s: sum(1 for f in fs if f.get('severity') == s) for s in ("HIGH", "MEDIUM", "LOW")}  # noqa: E731
    print(f"severity mix: {name_a} {sev(fa)}  |  {name_b} {sev(fb)}")


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[0] in {"-h", "--help"}:
        print(__doc__)
        return 2
    loaded = [(Path(p).name, load(Path(p))) for p in argv]
    for (na, fa), (nb, fb) in combinations(loaded, 2):
        compare(na, fa, nb, fb)
    print("\nDiscussion: which list would you page someone for? Which findings lack a source->sink path a verifier could confirm?")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
