#!/usr/bin/env python3
"""Remove Cursor Co-authored-by trailer from git commit message (stdin -> stdout)."""
import sys

msg = sys.stdin.read()
lines = [
    line
    for line in msg.splitlines(keepends=True)
    if "Co-authored-by: Cursor" not in line
]
# Drop trailing blank lines left after removing trailer
while lines and lines[-1].strip() == "":
    lines.pop()
if lines and not lines[-1].endswith("\n"):
    lines[-1] += "\n"
sys.stdout.write("".join(lines))
