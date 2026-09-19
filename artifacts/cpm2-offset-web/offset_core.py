"""Shared dump offset mapping core (Kinzi-style)."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

IGNORE_EXACT = {0x52800000, 0x52800028, 0x2A1F03E0}
RVA_RE = re.compile(r"//\s*RVA:\s*(0x[0-9A-Fa-f]+)\s+Offset:\s*(0x[0-9A-Fa-f]+)", re.I)
CLASS_RE = re.compile(
    r"^(?:public|private|internal|protected)?\s*"
    r"(?:static\s+|abstract\s+|sealed\s+|virtual\s+|override\s+|readonly\s+)*"
    r"(?:class|struct|interface|enum)\s+(\w+)",
    re.M,
)
METHOD_SIMPLE_RE = re.compile(
    r"\b(?:public|private|internal|protected)\s+"
    r"(?:static\s+|virtual\s+|override\s+|abstract\s+|async\s+)*"
    r"(?:[\w.<>,\[\]]+\s+)+(\w+)\s*\(",
)
SKIP_METHODS = {"get", "set", "add", "remove", "op", "ctor", "cctor"}
HEX_RE = re.compile(r"\b(0x[0-9A-Fa-f]{5,10})\b")


def should_ignore(rva: int) -> bool:
    if rva in IGNORE_EXACT:
        return True
    if rva >= 0x52000000 and (rva & 0xFF000000) == 0x52000000:
        return True
    return False


def parse_dump_text(text: str) -> Dict[int, List[Tuple[str, str]]]:
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
    return dict(rva_map)


def build_cm_index(rva_map):
    idx = defaultdict(list)
    for rva, pairs in rva_map.items():
        for cls, meth in pairs:
            idx[(cls, meth)].append(rva)
    return dict(idx)


def build_method_index(rva_map):
    idx = defaultdict(list)
    for rva, pairs in rva_map.items():
        for cls, meth in pairs:
            idx[meth].append((cls, rva))
    return dict(idx)


def lookup_old_pairs(old_rva, old_rva_map):
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
            ncls, nrva = hits[0]
            return nrva, (ncls, meth), f"name-only ({cls}->{ncls})"
    return None, None, "not found"


def update_script_text(script_text: str, old_map, new_cm, new_meth):
    found = set()
    for m in HEX_RE.finditer(script_text):
        try:
            val = int(m.group(1), 16)
            if 0x10000 <= val <= 0x80000000 and not should_ignore(val):
                found.add(val)
        except ValueError:
            pass

    replacements = {}
    report = []
    stats = {"mapped": 0, "same": 0, "missing": 0, "total": len(found), "pm4": 0, "name_only": 0}

    for old_rva in sorted(found):
        old_hex = f"0x{old_rva:X}"
        pairs, how_old = lookup_old_pairs(old_rva, old_map)
        if not pairs:
            report.append(f"{old_hex}  ->  NO CLASS/METHOD IN OLD DUMP")
            stats["missing"] += 1
            continue
        if how_old in ("-4", "+4"):
            stats["pm4"] += 1
        new_rva, chosen, how_new = find_new_rva(pairs, new_cm, new_meth)
        if new_rva is None:
            report.append(f"{old_hex}  ->  NOT FOUND  ({pairs[0][0]}::{pairs[0][1]})  [{how_old}]")
            stats["missing"] += 1
            continue
        if "name-only" in how_new:
            stats["name_only"] += 1
        new_hex = f"0x{new_rva:X}"
        tag = f"({chosen[0]}::{chosen[1]})"
        extra = ""
        if how_old != "exact":
            extra += f"  [old {how_old}]"
        if "name-only" in how_new:
            extra += f"  [{how_new}]"
        if new_hex.upper() == old_hex.upper():
            report.append(f"{old_hex}  = same  {tag}{extra}")
            stats["same"] += 1
            continue
        replacements[old_hex] = new_hex
        report.append(f"{old_hex}  ->  {new_hex}  {tag}{extra}")
        stats["mapped"] += 1

    new_text = script_text
    for oh, nh in sorted(replacements.items(), key=lambda x: -len(x[0])):
        new_text = re.sub(rf"\b{re.escape(oh)}\b", nh, new_text, flags=re.I)

    report_text = (
        "OFFSET MAPPING REPORT\n"
        "=====================\n"
        f"Total: {stats['total']} | Mapped: {stats['mapped']} | Same: {stats['same']} | "
        f"Missing: {stats['missing']} | +/-4: {stats['pm4']} | name-only: {stats['name_only']}\n\n"
        + "\n".join(report) + "\n"
    )
    return new_text, report_text, stats
