#!/usr/bin/env python3
"""Data-quality audit for the training log (JSON sessions).

Usage: python3 tools/audit_logs.py <strength_dir>

Reports how consistent the log is: which fields exist, which types they take,
and how many entries have missing or non-numeric values. Useful before using
the log as an evaluation dataset for a model.
"""
import json, sys, pathlib
from collections import Counter, defaultdict

def main(folder):
    files = sorted(pathlib.Path(folder).glob("*.json"))
    types = defaultdict(Counter)
    entries = 0
    broken = []
    for f in files:
        try:
            data = json.loads(f.read_text())
        except Exception as e:
            broken.append((f.name, str(e)))
            continue
        for ex in data.get("esercizi", []):
            entries += 1
            for field in ("sets", "reps", "peso", "rpe"):
                v = ex.get(field, None)
                types[field]["missing" if field not in ex else type(v).__name__] += 1
    print(f"files: {len(files)}   exercise entries: {entries}   unreadable: {len(broken)}")
    for field, c in types.items():
        print(f"  {field:5s}", dict(c))
    non_numeric = types["peso"].get("str", 0)
    print(f"\n'peso' stored as free text in {non_numeric} entries;"
          f" 'rpe' missing in {types['rpe'].get('missing', 0)} entries.")
    for name, err in broken:
        print("  unreadable:", name, err)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
