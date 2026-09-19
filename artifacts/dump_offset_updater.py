#!/usr/bin/env python3
"""
CPM2 / IL2CPP Dump Offset Updater v3
====================================
Offline offset mapper based on Kinzi Automatic Convertor logic.

Modes:
  update   - old dump + new dump + script → updated script
  kinzi    - .kinzi result file + new dump → new offsets
  diff     - old dump vs new dump method changes
  template - mapping report / kinzi → Lua patch table template

Examples:
  python dump_offset_updater.py update \\
      --old-dump old.cs --new-dump new.cs --script script.lua --out updated.lua

  python dump_offset_updater.py kinzi \\
      --kinzi results.kinzi --new-dump new.cs --out reoffset.txt

  python dump_offset_updater.py diff \\
      --old-dump old.cs --new-dump new.cs --out diff_report.txt

  python dump_offset_updater.py template \\
      --report mapping_report.txt --out patch_table.lua
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# Constants / ignore list (ARM / non-method junk)
# ---------------------------------------------------------------------------

IGNORE_PREFIXES = (
    0x52800000,  # ARM64 MOV wide patterns often appear as literals
    0x52800028,
    0xD65F0000,  # RET-ish
)
IGNORE_EXACT: Set[int] = {
    0x52800000,
    0x52800028,
    0x2A1F03E0,
}

RVA_RE = re.compile(
    r"//\s*RVA:\s*(0x[0-9A-Fa-f]+)\s+Offset:\s*(0x[0-9A-Fa-f]+)",
    re.IGNORECASE,
)
CLASS_RE = re.compile(
    r"^(?:public|private|internal|protected)?\s*"
    r"(?:static\s+|abstract\s+|sealed\s+|virtual\s+|override\s+|readonly\s+)*"
    r"(?:class|struct|interface|enum)\s+(\w+)",
    re.MULTILINE,
)
METHOD_SIMPLE_RE = re.compile(
    r"\b(?:public|private|internal|protected)\s+"
    r"(?:static\s+|virtual\s+|override\s+|abstract\s+|async\s+)*"
    r"(?:[\w.<>,\[\]]+\s+)+(\w+)\s*\(",
)
SKIP_METHODS = {"get", "set", "add", "remove", "op", "ctor", "cctor"}
HEX_RE = re.compile(r"\b(0x[0-9A-Fa-f]{5,10})\b")

OFFSET_TABLE_START = "OFFSET TABLE"
OFFSET_TABLE_MARKERS = (
    "--[[ ══════════════════════════════════════════════════════════",
    "OFFSET TABLE — libil2cpp.so",
)


def should_ignore(rva: int) -> bool:
    if rva in IGNORE_EXACT:
        return True
    for p in IGNORE_PREFIXES:
        if (rva & 0xFFFF0000) == (p & 0xFFFF0000) and rva >= 0x52000000:
            return True
    return False


# ---------------------------------------------------------------------------
# Dump parsing
# ---------------------------------------------------------------------------

def parse_dump(path: Path) -> Dict[int, List[Tuple[str, str]]]:
    print(f"[*] Parsing: {path.name} ({path.stat().st_size / 1e6:.1f} MB)...")
    text = path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()
    rva_map: Dict[int, List[Tuple[str, str]]] = defaultdict(list)
    current_class = "Unknown"
    i, n = 0, len(lines)

    while i < n:
        line = lines[i]
        cm = CLASS_RE.search(line)
        if cm:
            current_class = cm.group(1)

        rm = RVA_RE.search(line)
        if rm:
            try:
                rva = int(rm.group(1), 16)
            except ValueError:
                i += 1
                continue

            method_name = None
            for j in range(i + 1, min(i + 6, n)):
                mline = lines[j].strip()
                if not mline or mline.startswith("//") or mline.startswith("/*") or mline.startswith("["):
                    continue
                mm = METHOD_SIMPLE_RE.search(mline)
                if mm:
                    method_name = mm.group(1)
                    break
                bare = re.match(r"^(\w+)\s*\(", mline)
                if bare and not mline.startswith(("if", "for", "while", "switch")):
                    method_name = bare.group(1)
                    break

            if method_name and method_name not in SKIP_METHODS:
                rva_map[rva].append((current_class, method_name))
        i += 1

    print(f"    → {len(rva_map)} RVAs")
    return dict(rva_map)


def build_cm_index(rva_map: Dict[int, List[Tuple[str, str]]]) -> Dict[Tuple[str, str], List[int]]:
    idx: Dict[Tuple[str, str], List[int]] = defaultdict(list)
    for rva, pairs in rva_map.items():
        for cls, meth in pairs:
            idx[(cls, meth)].append(rva)
    return dict(idx)


def build_method_index(rva_map: Dict[int, List[Tuple[str, str]]]) -> Dict[str, List[Tuple[str, int]]]:
    idx: Dict[str, List[Tuple[str, int]]] = defaultdict(list)
    for rva, pairs in rva_map.items():
        for cls, meth in pairs:
            idx[meth].append((cls, rva))
    return dict(idx)


def lookup_old_pairs(old_rva: int, old_rva_map: Dict[int, List[Tuple[str, str]]]):
    """Kinzi findClassSafe: exact → -4 → +4"""
    if old_rva in old_rva_map:
        return old_rva_map[old_rva], "exact"
    if (old_rva - 4) in old_rva_map:
        return old_rva_map[old_rva - 4], "-4"
    if (old_rva + 4) in old_rva_map:
        return old_rva_map[old_rva + 4], "+4"
    return None, "none"


def find_new_rva(pairs, new_cm, new_meth):
    for cls, meth in pairs:
        cands = new_cm.get((cls, meth))
        if cands:
            return cands[0], (cls, meth), "exact"
    for cls, meth in pairs:
        hits = new_meth.get(meth)
        if hits:
            new_cls, new_rva = hits[0]
            return new_rva, (new_cls, meth), f"name-only ({cls}→{new_cls})"
    return None, None, "not found"


# ---------------------------------------------------------------------------
# Mode: update script
# ---------------------------------------------------------------------------

def build_offset_table_header(mapped_lines: List[str]) -> str:
    """Rebuild a simple OFFSET TABLE comment block from successful mappings."""
    body = "\n".join(f"  {line}" for line in mapped_lines[:80])
    return (
        f"--[[ ══════════════════════════════════════════════════════════\n"
        f"  OFFSET TABLE — auto-updated {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        f"  Generated by dump_offset_updater.py (Kinzi-style Class::Method map)\n"
        f"  ═══════════════════════════════════════════════════════════\n\n"
        f"{body}\n\n"
        f"══════════════════════════════════════════════════════════ --]]\n"
    )


def mode_update(args) -> None:
    old_map = parse_dump(args.old_dump)
    new_map = parse_dump(args.new_dump)
    new_cm = build_cm_index(new_map)
    new_meth = build_method_index(new_map)

    text = args.script.read_text(encoding="utf-8", errors="ignore")
    found = set()
    for m in HEX_RE.finditer(text):
        try:
            val = int(m.group(1), 16)
            if args.min_offset <= val <= args.max_offset and not should_ignore(val):
                found.add(val)
        except ValueError:
            pass

    print(f"[*] Script offsets: {len(found)}")

    replacements = {}
    report = []
    header_lines = []
    stats = {"mapped": 0, "same": 0, "missing": 0, "ignored": 0, "pm4": 0, "name_only": 0}

    for old_rva in sorted(found):
        old_hex = f"0x{old_rva:X}"
        pairs, how_old = lookup_old_pairs(old_rva, old_map)
        if not pairs:
            report.append(f"{old_hex}  →  NO CLASS/METHOD IN OLD DUMP")
            stats["missing"] += 1
            continue
        if how_old in ("-4", "+4"):
            stats["pm4"] += 1

        new_rva, chosen, how_new = find_new_rva(pairs, new_cm, new_meth)
        if new_rva is None:
            report.append(f"{old_hex}  →  NOT FOUND  ({pairs[0][0]}::{pairs[0][1]})  [{how_old}]")
            stats["missing"] += 1
            continue
        if "name-only" in how_new:
            stats["name_only"] += 1

        new_hex = f"0x{new_rva:X}"
        tag = f"{chosen[0]}::{chosen[1]}"
        extra = ""
        if how_old != "exact":
            extra += f"  [old {how_old}]"
        if "name-only" in how_new:
            extra += f"  [{how_new}]"

        if new_hex.upper() == old_hex.upper():
            report.append(f"{old_hex}  = same  ({tag}){extra}")
            header_lines.append(f"{new_hex}  {tag}")
            stats["same"] += 1
            continue

        replacements[old_hex] = new_hex
        report.append(f"{old_hex}  →  {new_hex}  ({tag}){extra}")
        header_lines.append(f"{new_hex}  {tag}")
        stats["mapped"] += 1

    new_text = text
    for old_hex, new_hex in sorted(replacements.items(), key=lambda x: -len(x[0])):
        new_text = re.sub(rf"\b{re.escape(old_hex)}\b", new_hex, new_text, flags=re.IGNORECASE)

    # Optional: inject / replace OFFSET TABLE header block
    if args.rewrite_header and header_lines:
        new_header = build_offset_table_header(header_lines)
        # Try replace existing block between markers
        start = None
        end = None
        lines = new_text.splitlines(keepends=True)
        for i, line in enumerate(lines):
            if start is None and ("OFFSET TABLE" in line or "═══" in line and i < 30):
                if "OFFSET" in line or (i + 1 < len(lines) and "OFFSET" in lines[i + 1]):
                    start = i
            if start is not None and i > start + 3 and "══" in line and "--]]" in line:
                end = i
                break
        if start is not None and end is not None:
            new_text = "".join(lines[:start]) + new_header + "".join(lines[end + 1 :])
            print("[+] OFFSET TABLE header rewritten")
        else:
            # Prepend after first comment block if any
            new_text = new_header + "\n" + new_text
            print("[+] OFFSET TABLE header prepended")

    args.out.write_text(new_text, encoding="utf-8")
    print(f"[+] Script → {args.out}")
    print(f"    Mapped {stats['mapped']} | Same {stats['same']} | Missing {stats['missing']} | ±4 {stats['pm4']} | name-only {stats['name_only']}")

    if args.report:
        args.report.write_text(
            "OFFSET MAPPING REPORT\n=====================\n"
            + "\n".join(f"{k}: {v}" for k, v in stats.items())
            + "\n\n"
            + "\n".join(report)
            + "\n",
            encoding="utf-8",
        )
        print(f"[+] Report → {args.report}")


# ---------------------------------------------------------------------------
# Mode: kinzi re-offset
# ---------------------------------------------------------------------------

def parse_kinzi(path: Path) -> List[Tuple[str, str, str]]:
    """Return list of (class, method, type)"""
    entries = []
    cls = meth = typ = None
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        c = re.match(r"CLASS:\s*(.+)", line)
        m = re.match(r"METHOD:\s*(.+)", line)
        t = re.match(r"TYPE:\s*(.+)", line)
        if c:
            cls = c.group(1).strip()
        if m:
            meth = m.group(1).strip()
        if t:
            typ = t.group(1).strip()
        if line.strip().startswith("---") and cls and meth:
            entries.append((cls, meth, typ or "Unknown"))
            cls = meth = typ = None
        # also accept inline CLASS::METHOD
        inline = re.match(r"(\w+)::(\w+)\s*→", line)
        if inline:
            entries.append((inline.group(1), inline.group(2), "Unknown"))
    # flush last
    if cls and meth:
        entries.append((cls, meth, typ or "Unknown"))
    return entries


def mode_kinzi(args) -> None:
    entries = parse_kinzi(args.kinzi)
    print(f"[*] Kinzi entries: {len(entries)}")
    new_map = parse_dump(args.new_dump)
    new_cm = build_cm_index(new_map)
    new_meth = build_method_index(new_map)

    lines = [
        "KINZI RE-OFFSET RESULT",
        f"Generated: {datetime.now().isoformat(timespec='seconds')}",
        f"Source: {args.kinzi.name}",
        f"Dump:   {args.new_dump.name}",
        "=" * 60,
        "",
    ]
    found = missing = 0
    for cls, meth, typ in entries:
        rva = None
        how = ""
        cands = new_cm.get((cls, meth))
        if cands:
            rva = cands[0]
            how = "exact"
        else:
            hits = new_meth.get(meth)
            if hits:
                ncls, rva = hits[0]
                how = f"name-only ({cls}→{ncls})"
                cls = ncls

        if rva is not None:
            lines.append(f"CLASS:  {cls}")
            lines.append(f"METHOD: {meth}")
            lines.append(f"TYPE:   {typ}")
            lines.append(f"OFFSET: 0x{rva:X}  [{how}]")
            lines.append(f"{cls}::{meth} → 0x{rva:X}")
            lines.append("-" * 40)
            lines.append("")
            found += 1
        else:
            lines.append(f"CLASS:  {cls}")
            lines.append(f"METHOD: {meth}")
            lines.append("OFFSET: NOT FOUND")
            lines.append("-" * 40)
            lines.append("")
            missing += 1

    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[+] Re-offset → {args.out}  (found {found}, missing {missing})")


# ---------------------------------------------------------------------------
# Mode: dump diff
# ---------------------------------------------------------------------------

def mode_diff(args) -> None:
    old_map = parse_dump(args.old_dump)
    new_map = parse_dump(args.new_dump)
    old_cm = {(c, m) for pairs in old_map.values() for c, m in pairs}
    new_cm = {(c, m) for pairs in new_map.values() for c, m in pairs}

    only_old = sorted(old_cm - new_cm)
    only_new = sorted(new_cm - old_cm)
    common = sorted(old_cm & new_cm)

    old_idx = build_cm_index(old_map)
    new_idx = build_cm_index(new_map)

    changed = []
    for key in common:
        o = old_idx.get(key, [None])[0]
        n = new_idx.get(key, [None])[0]
        if o is not None and n is not None and o != n:
            changed.append((key[0], key[1], o, n))

    lines = [
        "DUMP DIFF REPORT",
        f"Old: {args.old_dump.name}",
        f"New: {args.new_dump.name}",
        f"Generated: {datetime.now().isoformat(timespec='seconds')}",
        "=" * 60,
        f"Only in OLD : {len(only_old)}",
        f"Only in NEW : {len(only_new)}",
        f"RVA changed : {len(changed)}",
        f"Unchanged name+RVA common set size: {len(common) - len(changed)}",
        "",
        "--- RVA CHANGED (same Class::Method) ---",
    ]
    for c, m, o, n in changed[:500]:
        lines.append(f"  {c}::{m}  0x{o:X} → 0x{n:X}")

    lines.append("")
    lines.append("--- ONLY IN OLD (removed/renamed) ---")
    for c, m in only_old[:300]:
        lines.append(f"  {c}::{m}")

    lines.append("")
    lines.append("--- ONLY IN NEW (added) ---")
    for c, m in only_new[:300]:
        lines.append(f"  {c}::{m}")

    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[+] Diff → {args.out}")


# ---------------------------------------------------------------------------
# Mode: template from report
# ---------------------------------------------------------------------------

def mode_template(args) -> None:
    text = args.report.read_text(encoding="utf-8", errors="ignore")
    entries = []
    for line in text.splitlines():
        # 0xOLD → 0xNEW  (Class::Method)
        m = re.search(
            r"(0x[0-9A-Fa-f]+)\s*→\s*(0x[0-9A-Fa-f]+)\s*\((\w+)::(\w+)\)",
            line,
        )
        if m:
            entries.append(
                {
                    "old": m.group(1),
                    "new": m.group(2),
                    "class": m.group(3),
                    "method": m.group(4),
                }
            )
            continue
        # Kinzi style OFFSET: 0x...
        m2 = re.search(r"OFFSET:\s*(0x[0-9A-Fa-f]+)", line)
        m3 = re.search(r"(\w+)::(\w+)", line)
        if m2 and m3:
            entries.append(
                {
                    "old": "?",
                    "new": m2.group(1),
                    "class": m3.group(1),
                    "method": m3.group(2),
                }
            )

    out = [
        "-- ==========================================================",
        "-- AUTO-GENERATED PATCH TABLE",
        f"-- Generated: {datetime.now().isoformat(timespec='seconds')}",
        f"-- Entries: {len(entries)}",
        "-- ==========================================================",
        "",
        "local gg = gg",
        "local ranges = gg.getRangesList('libil2cpp.so')",
        "if not ranges or not ranges[2] then gg.alert('libil2cpp.so not found') os.exit() end",
        "local lib_base = ranges[2].start",
        "",
        "local patches = {",
    ]
    for e in entries:
        out.append(f"    -- {e['class']}::{e['method']}  (was {e['old']})")
        out.append(
            f"    {{ offset = {e['new']}, bytes = \"?? ?? ?? ??\", desc = \"{e['method']}\" }},"
        )
        out.append("")
    out += [
        "}",
        "",
        "for _, p in ipairs(patches) do",
        "    if p.bytes ~= \"?? ?? ?? ??\" then",
        "        local addr = lib_base + p.offset",
        "        -- TODO: gg.setValues / your patch method",
        "        gg.toast('Patch: ' .. p.desc)",
        "    end",
        "end",
        "",
        "gg.alert('Template ready — fill in byte values.')",
        "",
    ]
    args.out.write_text("\n".join(out), encoding="utf-8")
    print(f"[+] Template → {args.out} ({len(entries)} entries)")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(description="CPM2 dump offset tools (Kinzi-style)")
    sub = ap.add_subparsers(dest="mode", required=True)

    p_up = sub.add_parser("update", help="Update script offsets old dump → new dump")
    p_up.add_argument("--old-dump", type=Path, required=True)
    p_up.add_argument("--new-dump", type=Path, required=True)
    p_up.add_argument("--script", type=Path, required=True)
    p_up.add_argument("--out", type=Path, required=True)
    p_up.add_argument("--report", type=Path, default=None)
    p_up.add_argument("--rewrite-header", action="store_true", help="Rewrite OFFSET TABLE header in script")
    p_up.add_argument("--min-offset", type=lambda x: int(x, 0), default=0x10000)
    p_up.add_argument("--max-offset", type=lambda x: int(x, 0), default=0x80000000)

    p_k = sub.add_parser("kinzi", help="Re-offset from .kinzi result file using new dump")
    p_k.add_argument("--kinzi", type=Path, required=True)
    p_k.add_argument("--new-dump", type=Path, required=True)
    p_k.add_argument("--out", type=Path, required=True)

    p_d = sub.add_parser("diff", help="Diff methods between two dumps")
    p_d.add_argument("--old-dump", type=Path, required=True)
    p_d.add_argument("--new-dump", type=Path, required=True)
    p_d.add_argument("--out", type=Path, required=True)

    p_t = sub.add_parser("template", help="Build Lua patch table from mapping report")
    p_t.add_argument("--report", type=Path, required=True)
    p_t.add_argument("--out", type=Path, required=True)

    args = ap.parse_args()

    if args.mode == "update":
        mode_update(args)
    elif args.mode == "kinzi":
        mode_kinzi(args)
    elif args.mode == "diff":
        mode_diff(args)
    elif args.mode == "template":
        mode_template(args)
    else:
        ap.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
