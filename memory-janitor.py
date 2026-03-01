#!/usr/bin/env python3
"""memory-janitor.py

Daily maintenance for OpenClaw memory files.

Policy implemented:
- MEMORY.md is "hot memory" and should stay ≤ 200 lines.
- Items tagged [P1] expire after 90 days; [P2] expire after 30 days.
- Expired items are moved into memory/archive/ as "cold memory" (still searchable).
- Daily logs (memory/YYYY-MM-DD.md) are left untouched.

Expected bullet format (single line preferred):
- [P1][ts:YYYY-MM-DD] ...
- [P2][ts:YYYY-MM-DD] ...

Usage:
  py memory-janitor.py
  py memory-janitor.py --dry-run
  py memory-janitor.py --now 2026-02-14

Exit codes:
  0 success (including "nothing to do")
  2 parse/format warnings (no changes applied)
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import List, Optional, Tuple

TS_RE = re.compile(r"\[ts:(\d{4}-\d{2}-\d{2})\]")
PRIO_RE = re.compile(r"\[(P0|P1|P2)\]")


@dataclass
class MemoryItem:
    idx: int
    line: str
    prio: str
    ts: Optional[date]


def parse_iso_date(s: str) -> date:
    return datetime.strptime(s, "%Y-%m-%d").date()


def find_prio(line: str) -> Optional[str]:
    m = PRIO_RE.search(line)
    return m.group(1) if m else None


def find_ts(line: str) -> Optional[date]:
    m = TS_RE.search(line)
    if not m:
        return None
    try:
        return parse_iso_date(m.group(1))
    except ValueError:
        return None


def get_expiry_days(prio: str) -> Optional[int]:
    if prio == "P1":
        return 90
    if prio == "P2":
        return 30
    return None


def load_items(lines: List[str]) -> Tuple[List[MemoryItem], List[str]]:
    items: List[MemoryItem] = []
    warnings: List[str] = []

    for i, raw in enumerate(lines):
        line = raw.rstrip("\n")
        # Only consider bullet lines.
        if not line.lstrip().startswith("-"):
            continue
        prio = find_prio(line)
        if prio not in ("P0", "P1", "P2"):
            continue
        ts = find_ts(line)
        if prio in ("P1", "P2") and ts is None:
            warnings.append(
                f"Line {i+1}: {prio} item missing [ts:YYYY-MM-DD]; will NOT be auto-archived: {line}"
            )
        items.append(MemoryItem(idx=i, line=line, prio=prio, ts=ts))

    return items, warnings


def archive_path(root: Path, today: date) -> Path:
    arch_dir = root / "memory" / "archive"
    arch_dir.mkdir(parents=True, exist_ok=True)
    return arch_dir / f"MEMORY-archive-{today.isoformat()}.md"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="Show what would change; write nothing")
    ap.add_argument("--now", type=str, default=None, help="Override today's date (YYYY-MM-DD)")
    args = ap.parse_args()

    root = Path(__file__).resolve().parent
    mem_path = root / "MEMORY.md"

    if not mem_path.exists():
        print(f"ERROR: {mem_path} not found")
        return 2

    today = parse_iso_date(args.now) if args.now else date.today()

    lines = mem_path.read_text(encoding="utf-8").splitlines(True)
    items, warnings = load_items(lines)

    if warnings:
        print("WARN: format issues found (fix these to enable auto-archiving):")
        for w in warnings:
            print("- " + w)

    had_format_warnings = bool(warnings)

    # Determine expired items.
    expired: List[MemoryItem] = []
    for it in items:
        expiry = get_expiry_days(it.prio)
        if expiry is None or it.ts is None:
            continue
        age = (today - it.ts).days
        if age > expiry:
            expired.append(it)

    # Enforce the 200-line limit by archiving oldest P2 items if needed.
    overflow: List[MemoryItem] = []
    remove_idx = {it.idx for it in expired}
    projected_lines = len(lines) - len(remove_idx)

    if projected_lines > 200:
        candidates = [
            it
            for it in items
            if it.prio == "P2" and it.ts is not None and it.idx not in remove_idx
        ]
        candidates.sort(key=lambda x: x.ts)  # oldest first

        while projected_lines > 200 and candidates:
            it = candidates.pop(0)
            overflow.append(it)
            remove_idx.add(it.idx)
            projected_lines -= 1

    to_archive = expired + overflow

    if not to_archive:
        print("OK: nothing to archive")
        total_lines = len(lines)
        if total_lines > 200:
            print(
                f"WARN: MEMORY.md is {total_lines} lines (>200) and no archivable P2 items were found."
            )
            return 2
        return 2 if had_format_warnings else 0

    # Apply changes.
    arch_file = archive_path(root, today)

    if args.dry_run:
        print("DRY RUN: would archive:")
        if expired:
            print("- Expired items:")
            for it in sorted(expired, key=lambda x: x.idx):
                print(f"  - Line {it.idx+1}: {it.line}")
        if overflow:
            print("- Line-limit pruning (overflow; oldest P2 first):")
            for it in sorted(overflow, key=lambda x: x.ts or date.min):
                print(f"  - Line {it.idx+1}: {it.line}")
        return 0

    archived_block_lines: List[str] = []
    archived_block_lines.append(f"# MEMORY Archive — {today.isoformat()}\n")
    archived_block_lines.append("\n")
    archived_block_lines.append("Archived from `MEMORY.md` by `memory-janitor.py`.\n")
    archived_block_lines.append("\n")

    if expired:
        archived_block_lines.append("## Expired items\n\n")
        for it in sorted(expired, key=lambda x: x.idx):
            archived_block_lines.append(f"- [{it.prio}] {it.line.lstrip('-').strip()}\n")
        archived_block_lines.append("\n")

    if overflow:
        archived_block_lines.append("## Line-limit pruning (overflow)\n\n")
        archived_block_lines.append("Archived to keep `MEMORY.md` ≤ 200 lines (oldest P2 first).\n\n")
        for it in sorted(overflow, key=lambda x: x.ts or date.min):
            archived_block_lines.append(f"- [{it.prio}] {it.line.lstrip('-').strip()}\n")
        archived_block_lines.append("\n")

    # Remove from bottom to top to keep indices stable.
    remove_sorted = sorted({it.idx for it in to_archive}, reverse=True)
    for idx in remove_sorted:
        del lines[idx]

    # Write archive append.
    with arch_file.open("a", encoding="utf-8") as f:
        f.writelines(archived_block_lines)
        f.write("\n")

    # Write updated hot memory.
    mem_path.write_text("".join(lines), encoding="utf-8")

    print(
        f"OK: archived {len(to_archive)} item(s) (expired={len(expired)}, overflow={len(overflow)}) -> {arch_file}"
    )

    total_lines = len(lines)
    if total_lines > 200:
        print(f"WARN: MEMORY.md is still {total_lines} lines (>200). Consider pruning.")
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
