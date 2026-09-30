"""Reject Fluent parser recovery (Junk) instead of silently skipping invalid text."""

from pathlib import Path
import sys

from fluent.syntax import ast, parse

status = 0
for catalog in sorted(Path(sys.argv[1]).glob("*/main.ftl")):
    source = catalog.read_text(encoding="utf-8")
    for entry in parse(source).body:
        if isinstance(entry, ast.Junk):
            for error in entry.annotations:
                line = source.count("\n", 0, error.span.start) + 1
                print(f"{catalog}:{line}: {error.code}: {error.message}", file=sys.stderr)
            status = 1
sys.exit(status)
