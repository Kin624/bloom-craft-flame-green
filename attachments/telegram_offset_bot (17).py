#!/usr/bin/env python3
"""
================================================================================
  CPM Offset Updater Bot  - Beginner-Friendly Version (v5.10 - accuracy upgrade)
================================================================================

WHAT THIS BOT DOES (plain English)
----------------------------------
Game updates change memory addresses (called RVAs / offsets).
Your .lua script still has the OLD addresses. This bot finds the
matching NEW addresses by comparing two dump files:

  1. OLD dump.cs  = dump from the version your script was built for
  2. NEW dump.cs  = dump from the current game version
  3. Your .lua    = the script that still contains the old addresses

Result:
  • YourScript_UPDATED.lua   (addresses rewritten)
  • offset_mapping_report.txt (what changed and why)

HOW MATCHING WORKS (strongest -> weakest)  - v5.10 (IDA + script-aware)
----------------------------------------------------------------------
  1. Exact: Namespace + Class + Method name
  2. Method name in same class
  3. Multi-strategy AGREEMENT (neighbor + signature same RVA)
  4. Strong neighbor (±2, .ctor, size) - ONLY if class size stable
  5. Unique signature + fuzzy name (same class)
  6. IDA-body (mid-function +4/+8 patches via method start)
  7. Proximity-delta (2 anchors, tight dist)
  8. Consensus pass

v5.10 extras for CPM1 obfuscation + CPM2 readable + IDA dumps:
  • Skip pure index-apply when class method count differs by >2
  • Stronger IDA-body for small relative offsets (common MOV/RET patches)
  • Field offsets (0x1B8-style) already ignored by hex length filter
  • Optional: prefer game assemblies when names collide

Only conf >= 70 is written into the script.
Unresolved offsets inject: gg.alert("offset is outdated")

HOW TO USE ON TELEGRAM
----------------------
  /start
  -> send OLD dump   (file OR MediaFire / Google Drive link)
  -> send NEW dump
  -> send your .lua script
  -> receive updated script + report

TIPS FOR BEGINNERS
------------------
  • Prefer environment variables for BOT_TOKEN (never commit secrets).
  • Telegram max file size is 20 MB. For bigger dumps, paste a link.
  • Always read the report: trust [APPLIED], review [SUGGEST].
  • /cancel aborts the current run and cleans temporary files.

The rest of this file is the full implementation with section comments.
"""

# ============================================================================
# IMPORTS
# ============================================================================
from __future__ import annotations

import asyncio
import logging
import os
import re
import json
import tempfile
import time
import zipfile
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

from telegram import Update, Document
from telegram.ext import (
    Application, CommandHandler, MessageHandler, filters, ContextTypes,
)
from telegram.error import Forbidden, BadRequest

# ============================================================================
# CONFIGURATION  (prefer environment variables – do not hard-code secrets)
# ============================================================================
BOT_TOKEN = os.environ.get("BOT_TOKEN", "7541631633:AAEbNlIt0jcYJv8gemnZzYLrnEBjO5IE7ZY").strip()
ALLOWED_IDS = {
    int(x.strip())
    for x in os.environ.get("ALLOWED_IDS", "6067014733").split(",")
    if x.strip().isdigit()
}
MAX_TG_DOWNLOAD = 20 * 1024 * 1024

# Delivery: telegram | link | both  (default link = host URL, not TG file)
SEND_MODE = os.environ.get("SEND_MODE", "link").strip().lower()
LINK_HOST = os.environ.get("LINK_HOST", "auto").strip().lower()  # auto|mediafire|catbox|litterbox
MEDIAFIRE_EMAIL = os.environ.get("MEDIAFIRE_EMAIL", "kinzbatumbakal@gmail.com").strip()
MEDIAFIRE_PASSWORD = os.environ.get("MEDIAFIRE_PASSWORD", "Rhanskkey41@").strip()
MEDIAFIRE_APP_ID = os.environ.get("MEDIAFIRE_APP_ID", "42511").strip()

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")
log = logging.getLogger("offset_bot")

# ============================================================================
# REGULAR EXPRESSIONS – patterns searched inside dump.cs
# ============================================================================
RVA_RE = re.compile(r"//\s*RVA:\s*(0x[0-9A-Fa-f]+)\s+Offset:\s*(0x[0-9A-Fa-f]+)", re.I)
# IDA / GenericInstMethod style: |-RVA: 0x.... Offset: 0x....
IDA_RVA_RE = re.compile(r"\|-RVA:\s*(0x[0-9A-Fa-f]+)\s+Offset:\s*(0x[0-9A-Fa-f]+)", re.I)
# Method name after GenericInst: |-ClassName.MethodName or |-...Type>.Method
IDA_METH_RE = re.compile(r"\|-([\w.<>+,\s]+?)\.(\w+)\s*$")
# IDA instruction line: 0x02CF6D80:  FE0F1DF8  STR ...
INSTR_ADDR_RE = re.compile(r"^\s*0x([0-9A-Fa-f]+):")
# BL / B absolute-ish immediates in comments or operands
BL_IMM_RE = re.compile(r"\b(?:BL|B|B\.\w+)\s+#?-?(0x[0-9A-Fa-f]+)", re.I)
NS_RE = re.compile(r"^//\s*Namespace:\s*(.+?)\s*$", re.I)
CLASS_RE = re.compile(
    r"^(?:public|private|internal|protected)?\s*"
    r"(?:static\s+|abstract\s+|sealed\s+|virtual\s+|override\s+|readonly\s+)*"
    r"(?:class|struct|interface|enum)\s+(\w+)", re.M,
)
METHOD_LINE_RE = re.compile(
    r"\b(?:public|private|internal|protected)\s+"
    r"(?:(static)\s+|virtual\s+|override\s+|abstract\s+|async\s+)*"
    r"([\w.<>,\[\]\s]+?)\s+(\w+)\s*\(([^)]*)\)",
)
# Property/event accessors are noise when ranking methods inside a class.
# We still keep .ctor / .cctor so neighbor order stays stable.
SKIP_METHODS = {"get", "set", "add", "remove", "op"}
HEX_RE = re.compile(r"\b(0x[0-9A-Fa-f]{5,10})\b")

# ---------------------------------------------------------------------------
# ARM opcode filter
# When scanning a .lua for hex numbers, many values are NOT addresses -
# they are ARM64 instructions (MOV, RET, NOP, …). These sets help skip them
# so we only treat real RVAs as mapping candidates.
# ---------------------------------------------------------------------------
_ARM_EXACT = {
    # Common full 32-bit encodings seen in scripts as constants
    0x52800020, 0x52800000, 0x52800028, 0x52800034,
    0xD65F03C0,  # RET
    0xD2800000,  # MOV X0, #0 style
    0x2A0103F4, 0x2A0003E0,
    0xAA1F03E0,  # MOV X0, XZR
    0x2A1F03E0,  # MOV W0, WZR
    0xD503201F,  # NOP
    0x200080D2, 0xC0035FD6,
}
_ARM_TOP16 = {
    # Top 16 bits of common instruction families (MOVZ, MOV, ORR, …)
    0x52800000, 0x52810000, 0x52820000, 0x52830000,
    0xD2800000, 0xD2810000, 0xD65F0000,
    0x2A000000, 0x2A010000, 0xAA1F0000,
    0x32000000, 0xD5030000, 0x20000000, 0xC0030000,
}

# ---------------------------------------------------------------------------
# Weak / common signatures
# Signature key format:  "I|void|0"
#   I or S  = Instance method or Static method
#   void    = return type (normalized)
#   0       = parameter count
#
# These patterns appear on HUNDREDS of methods in every dump, so matching
# by signature alone is unreliable. We refuse to use them as the only signal.
#
#   "I|void|0"   -> instance method, returns void, 0 params   (very common)
#   "I|void|1"   -> instance, void, 1 param
#   "I|void|2"   -> instance, void, 2 params
#   "S|void|0"   -> static void with no params
#   "S|void|1"   -> static void with 1 param
#   "I|bool|0"   -> instance bool getter-style (no params)
#   "I|bool|1"   -> instance bool with 1 param
#   "I|int|0"    -> instance int, no params
#   "I|int32|0"  -> same idea (Int32 normalized to int32)
# ---------------------------------------------------------------------------
_WEAK_SIGS = {
    "I|void|0", "I|void|1", "I|void|2",
    "S|void|0", "S|void|1",
    "I|bool|0", "I|bool|1",
    "I|int|0", "I|int32|0",
}

# ---------------------------------------------------------------------------
# Confidence thresholds
# conf is a score 0..98. Only scores >= APPLY_CONF are written into the .lua.
# Lower scores appear in the report as [SUGGEST] and may trigger gg.alert.
# ---------------------------------------------------------------------------
APPLY_CONF = 70              # minimum conf to actually change the script
NEIGHBOR_STRONG_CONF = 88    # positional match with strong surrounding evidence
NEIGHBOR_IDX_CONF = 78       # same index in class, moderate evidence
MAX_SUGGESTIONS = 6          # max alternative candidates listed per offset

# ---------------------------------------------------------------------------
# v5.10 accuracy knobs (tune these if needed)
# ---------------------------------------------------------------------------
AGREE_BOOST = 14             # +conf when neighbor AND signature agree on same RVA
UNIQUE_SIG_BOOST = 12        # +conf when this signature appears only once in the class
SIZE_MATCH_BONUS = 10        # +conf when old/new method body lengths are similar
SIZE_MISMATCH_PENALTY = 15   # -conf when body lengths differ a lot (stub vs huge fn)
FUZZY_NAME_MIN = 0.55        # min name similarity (0.0–1.0) to count as a fuzzy hit
PROXIMITY_APPLY_DIST = 0x800 # only auto-apply hex-delta if anchors are this close
PROXIMITY_MIN_ANCHORS = 2    # need at least this many nearby mapped anchors
CONSENSUS_MIN_STRATS = 2     # same new RVA from N different strategies -> promote
CLASS_SIZE_DIFF_MAX = 2      # if |old_class_len - new_class_len| > this, pure index is SUGGEST-only
IDA_BODY_TIGHT_REL = 0x40    # rel offset <= this gets high conf (MOV/RET style patches)

# CPM1 obfuscation: class/method names are random + Cyrillic, but these stay readable
STABLE_METHODS = {
    "Update", "Start", "Awake", "OnEnable", "OnDisable",
    "FixedUpdate", "LateUpdate", "OnDestroy", "OnApplicationPause",
    "OnApplicationFocus", "OnTriggerEnter", "OnTriggerExit",
    "OnCollisionEnter", "OnCollisionExit", "Reset",
    ".ctor", ".cctor", "ctor", "cctor",
}
# Min shared stable methods to treat two classes as the same under rename
STRUCT_MATCH_MIN_STABLE = 2
STRUCT_MATCH_MIN_SIGS = 3

# Optional file that remembers successful old->new pairs across bot runs.
# Override with:  export OFFSET_CACHE=/path/to/cache.json


# ============================================================================
# ARM HELPERS – skip values that look like machine code, not addresses
# ============================================================================
def looks_like_arm_instruction(val: int) -> bool:
    """
    True if this hex is almost certainly an ARM64 *instruction word*
    (patch constant), not a code RVA in libil2cpp.

    RVAs for game code are usually in a mid range and do NOT match
    MOV/RET/B encodings.  Filtering stops false candidates like:
      0x2A1F03E0  = MOV W0, WZR
      0x944B2C92  = BL (branch with link)
    """
    if val < 0x10000:
        return True
    if val in _ARM_EXACT or (val & 0xFFFF0000) in _ARM_TOP16:
        return True
    # MOV W0, WZR / MOV X0, XZR family
    if (val & 0xFFFFFC1F) in (0x2A1F03E0, 0xAA1F03E0):
        return True
    # MOVZ/MOVN/MOVK (sf + opc + 100101)
    if (val & 0x1F800000) == 0x12800000:  # MOV* immediate family
        return True
    # Unconditional B / BL (top 6 bits 000101 / 100101)
    top6 = val >> 26
    if top6 in (0x5, 0x25):  # B or BL
        return True
    # RET-like
    if (val & 0xFFFFFC1F) == 0xD65F0000:
        return True
    # GG LE form of common patches mistaken as big numbers
    if val in (0x200080D2, 0x000080D2, 0xC0035FD6, 0x1F2003D5):
        return True
    return False




# ============================================================================
# ARM64 HEX -> INSTRUCTION  (general decoder + known patches)
# ============================================================================
# Works for ANY 32-bit word: exact known patches first, then pattern decode
# (MOVZ/MOVK, RET, NOP, B, BR, BLR, MOV reg, ORR WZR forms, etc.)
# GG "h200080D2" is little-endian bytes of instruction word 0xD2800020.

# Exact high-value patches (fast path)
ARM64_EXACT = {
    0xD503201F: "NOP",
    0xD65F03C0: "RET",
    0xD2800000: "MOV X0, #0",
    0xD2800020: "MOV X0, #1",
    0xD2800040: "MOV X0, #2",
    0xD2800060: "MOV X0, #3",
    0xD2800080: "MOV X0, #4",
    0xD28000A0: "MOV X0, #5",
    0x52800000: "MOV W0, #0",
    0x52800020: "MOV W0, #1",
    0x52800040: "MOV W0, #2",
    0x52800060: "MOV W0, #3",
    0x2A1F03E0: "MOV W0, WZR",
    0xAA1F03E0: "MOV X0, XZR",
    0x14000000: "B #0",
    0x14000001: "B #4",
    0x14000002: "B #8",
}


def _reg_name(sf: int, reg: int) -> str:
    """sf=1 -> Xn / XZR, sf=0 -> Wn / WZR."""
    if reg == 31:
        return "XZR" if sf else "WZR"
    return (f"X{reg}" if sf else f"W{reg}")


def decode_arm64_word(word: int) -> str:
    """
    Decode a 32-bit ARM64 instruction word into a short assembly string.
    Covers the patterns used in GG / CPM patches; unknown -> hex fallback.
    """
    word &= 0xFFFFFFFF

    if word in ARM64_EXACT:
        return ARM64_EXACT[word]

    # ---- NOP family (HINT) ----
    if (word & 0xFFFFF01F) == 0xD503201F:
        return "NOP"

    # ---- RET / BR / BLR ----
    # RET  = 0xD65F03C0
    if word == 0xD65F03C0:
        return "RET"
    # BR Xn  : 1101 0110 0001 1111 0000 00nn nnn0 0000
    if (word & 0xFFFFFC1F) == 0xD61F0000:
        rn = (word >> 5) & 0x1F
        return f"BR X{rn}" if rn != 31 else "BR XZR"
    # BLR Xn
    if (word & 0xFFFFFC1F) == 0xD63F0000:
        rn = (word >> 5) & 0x1F
        return f"BLR X{rn}" if rn != 31 else "BLR XZR"

    # ---- Unconditional B / BL (imm26) ----
    # B  : 0001 01xx xxxx xxxx xxxx xxxx xxxx xxxx
    if (word >> 26) == 0x5:  # 000101
        imm26 = word & 0x3FFFFFF
        if imm26 & 0x2000000:
            imm26 -= 0x4000000
        off = imm26 * 4
        sign = "+" if off >= 0 else ""
        return f"B #{sign}{off}"
    # BL : 1001 01..
    if (word >> 26) == 0x25:  # 100101
        imm26 = word & 0x3FFFFFF
        if imm26 & 0x2000000:
            imm26 -= 0x4000000
        off = imm26 * 4
        sign = "+" if off >= 0 else ""
        return f"BL #{sign}{off}"

    # ---- MOVZ Rd, #imm16, LSL #shift  (includes MOV Xd,#n / MOV Wd,#n) ----
    # sf opc 100101 hw imm16 Rd
    # MOVZ: opc=10 -> bits [30:29]=10, [28:23]=100101
    if (word & 0x7F800000) == 0x52800000:  # MOVZ (sf in bit 31)
        sf = (word >> 31) & 1
        hw = (word >> 21) & 0x3
        imm16 = (word >> 5) & 0xFFFF
        rd = word & 0x1F
        reg = _reg_name(sf, rd)
        shift = hw * 16
        if shift == 0:
            return f"MOV {reg}, #{imm16}"
        return f"MOV {reg}, #{imm16}, LSL #{shift}"

    # ---- MOVN (move inverted) ----
    if (word & 0x7F800000) == 0x12800000:
        sf = (word >> 31) & 1
        hw = (word >> 21) & 0x3
        imm16 = (word >> 5) & 0xFFFF
        rd = word & 0x1F
        reg = _reg_name(sf, rd)
        shift = hw * 16
        # common: MOVN W0, #0 -> MOV W0, #-1 style note
        if shift == 0:
            return f"MOVN {reg}, #{imm16}"
        return f"MOVN {reg}, #{imm16}, LSL #{shift}"

    # ---- MOVK ----
    if (word & 0x7F800000) == 0x72800000:
        sf = (word >> 31) & 1
        hw = (word >> 21) & 0x3
        imm16 = (word >> 5) & 0xFFFF
        rd = word & 0x1F
        reg = _reg_name(sf, rd)
        shift = hw * 16
        return f"MOVK {reg}, #{imm16}, LSL #{shift}"

    # ---- ORR Rd, Rn, Rm  (includes MOV Rd, Rm when Rn=ZR) ----
    # Data-processing register: sf 010 1010 shift 000 Rm 000000 Rn Rd  (ORR shifted)
    if (word & 0x7FE0FC00) == 0x2A000000:
        sf = (word >> 31) & 1
        rm = (word >> 16) & 0x1F
        rn = (word >> 5) & 0x1F
        rd = word & 0x1F
        rd_n = _reg_name(sf, rd)
        rm_n = _reg_name(sf, rm)
        rn_n = _reg_name(sf, rn)
        if rn == 31:  # ORR Rd, ZR, Rm == MOV Rd, Rm
            return f"MOV {rd_n}, {rm_n}"
        return f"ORR {rd_n}, {rn_n}, {rm_n}"

    # ---- ADD/SUB immediate (common in epilogues) ----
    # sf 0010001 sh imm12 Rn Rd  = ADD
    if (word & 0x7F000000) == 0x11000000:
        sf = (word >> 31) & 1
        sh = (word >> 22) & 1
        imm12 = (word >> 10) & 0xFFF
        rn = (word >> 5) & 0x1F
        rd = word & 0x1F
        imm = imm12 << (12 if sh else 0)
        return f"ADD {_reg_name(sf, rd)}, {_reg_name(sf, rn)}, #{imm}"
    if (word & 0x7F000000) == 0x51000000:
        sf = (word >> 31) & 1
        sh = (word >> 22) & 1
        imm12 = (word >> 10) & 0xFFF
        rn = (word >> 5) & 0x1F
        rd = word & 0x1F
        imm = imm12 << (12 if sh else 0)
        return f"SUB {_reg_name(sf, rd)}, {_reg_name(sf, rn)}, #{imm}"

    # ---- CBZ / CBNZ ----
    if (word & 0x7F000000) == 0x34000000:
        sf = (word >> 31) & 1
        imm19 = (word >> 5) & 0x7FFFF
        if imm19 & 0x40000:
            imm19 -= 0x80000
        rt = word & 0x1F
        return f"CBZ {_reg_name(sf, rt)}, #{imm19 * 4}"
    if (word & 0x7F000000) == 0x35000000:
        sf = (word >> 31) & 1
        imm19 = (word >> 5) & 0x7FFFF
        if imm19 & 0x40000:
            imm19 -= 0x80000
        rt = word & 0x1F
        return f"CBNZ {_reg_name(sf, rt)}, #{imm19 * 4}"

    # ---- SVC ----
    if (word & 0xFFE0001F) == 0xD4000001:
        imm16 = (word >> 5) & 0xFFFF
        return f"SVC #{imm16}"

    # ---- BRK ----
    if (word & 0xFFE0001F) == 0xD4200000:
        imm16 = (word >> 5) & 0xFFFF
        return f"BRK #{imm16}"

    return f"??? (0x{word:08X})"


def arm64_meaning_for_word(word: int) -> str:
    """Human comment: instruction + short intent when it's a common patch."""
    word &= 0xFFFFFFFF
    inst = decode_arm64_word(word)
    # intent notes
    intent = ""
    if inst in ("MOV X0, #1", "MOV W0, #1"):
        intent = "  -> force TRUE (IsBought/unlock/bool)"
    elif inst in ("MOV X0, #0", "MOV W0, #0", "MOV X0, XZR", "MOV W0, WZR"):
        intent = "  -> force FALSE / zero return"
    elif inst == "RET":
        intent = "  -> return to caller (pair after MOV)"
    elif inst == "NOP":
        intent = "  -> NOP (neutralize branch/check)"
    elif inst.startswith("B #0"):
        intent = "  -> B #0 hang risk - avoid"
    elif inst.startswith("MOV X0, #") or inst.startswith("MOV W0, #"):
        intent = "  -> force return imm (MOVZ)"
    return inst + intent


# Cache for online disasm results (word_int -> asm string | None)
_ARM64_ONLINE_CACHE: dict = {}
_ARM64_ONLINE_ENABLED = True  # False = offline local decoder only


def arm64_online_disasm(word: int):
    """
    Fallback: https://armconverter.com/api/convert  (same as the website disasm).
    Local decoder first; this runs only for unknown words.

    API wants little-endian hex bytes: 0xD2800020 -> "200080d2"
    """
    word &= 0xFFFFFFFF
    if word in _ARM64_ONLINE_CACHE:
        return _ARM64_ONLINE_CACHE[word]
    if not _ARM64_ONLINE_ENABLED:
        return None
    le = (
        f"{word & 0xFF:02x}"
        f"{(word >> 8) & 0xFF:02x}"
        f"{(word >> 16) & 0xFF:02x}"
        f"{(word >> 24) & 0xFF:02x}"
    )
    try:
        import urllib.request
        payload = json.dumps({"hex": le, "offset": "0x0", "arch": "arm64"}).encode()
        req = urllib.request.Request(
            "https://armconverter.com/api/convert",
            data=payload,
            headers={
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (compatible; OffsetBot/5.2)",
                "Accept": "application/json",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode())
        asm = None
        arm = (data.get("asm") or {}).get("arm64")
        if isinstance(arm, list) and len(arm) >= 2 and arm[0]:
            asm = str(arm[1]).strip()
        _ARM64_ONLINE_CACHE[word] = asm
        return asm
    except Exception as e:
        log.debug("armconverter online failed 0x%08X: %s", word, e)
        _ARM64_ONLINE_CACHE[word] = None
        return None



def _word_from_gg_h_hex(s: str):
    """
    'h200080D2' or '200080D2' -> instruction word 0xD2800020
    GG writes bytes in memory (little-endian) order.
    """
    s = s.strip().upper().replace(" ", "")
    if s.startswith("H"):
        s = s[1:]
    if not re.fullmatch(r"[0-9A-F]{8}", s):
        return None
    b0 = int(s[0:2], 16)
    b1 = int(s[2:4], 16)
    b2 = int(s[4:6], 16)
    b3 = int(s[6:8], 16)
    return (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)) & 0xFFFFFFFF


def token_to_arm64_word(token: str):
    """
    Accept many script forms and return a 32-bit instruction word, or None.
      h200080D2 | 200080D2 | 0xD2800020 | -698416192 | 3596551104
    """
    token = token.strip().replace(",", "")
    # GG h-hex (8 hex digits, optional leading h)
    if re.fullmatch(r"h?[0-9A-Fa-f]{8}", token, re.I):
        # Prefer LE GG decode when it looks like h-form or starts with common LE bytes
        if token.lower().startswith("h") or token.lower()[:2] in {
            "20", "00", "40", "60", "c0", "1f", "e0", "a0",
        }:
            w = _word_from_gg_h_hex(token)
            if w is not None:
                return w
        # else treat as big-endian instruction word
        hx = token[1:] if token.lower().startswith("h") else token
        return int(hx, 16) & 0xFFFFFFFF
    # 0x........ 
    m = re.fullmatch(r"0x([0-9A-Fa-f]{1,8})", token, re.I)
    if m:
        return int(m.group(1), 16) & 0xFFFFFFFF
    # signed / unsigned decimal
    if re.fullmatch(r"-?\d+", token):
        return int(token) & 0xFFFFFFFF
    return None


def arm64_meaning_for_token(token: str):
    """
    token -> word -> assembly comment.
      1) Local pattern decoder (offline)
      2) If ??? -> armconverter.com online (cached)
    """
    word = token_to_arm64_word(token)
    if word is None:
        return None
    meaning = arm64_meaning_for_word(word)
    if meaning.startswith("???"):
        online = arm64_online_disasm(word)
        if online:
            return online
    return meaning





def parse_ida_insn_bytes(dump_text: str) -> dict:
    """
    If the dump is a real IDA listing (not only Il2CppDumper .cs), collect:
      RVA / address -> (byte_hex, disasm_text)

    Supports lines like:
      .text:0000000002F1A554  20 00 80 D2     MOV             X0, #1
      02F1A554  200080D2  MOV X0, #1

    Il2CppDumper-only dumps (// RVA: without bytes) return {}.
    """
    out = {}
    # .text:ADDR  BB BB BB BB  MNEMONIC ...
    pat1 = re.compile(
        r"\.(?:text|code)[:\s]+0*?([0-9A-Fa-f]{5,12})\s+((?:[0-9A-Fa-f]{2}\s+){3,8}[0-9A-Fa-f]{2})\s+(\S+.*)$"
    )
    # ADDR  HEXWORD  MNEMONIC
    pat2 = re.compile(
        r"^\s*0?x?([0-9A-Fa-f]{5,12})\s+([0-9A-Fa-f]{8})\s+([A-Za-z]{2,}.*)$"
    )
    for line in dump_text.splitlines():
        m = pat1.search(line)
        if m:
            try:
                rva = int(m.group(1), 16)
            except ValueError:
                continue
            raw = m.group(2).replace(" ", "")
            out[rva] = (raw, m.group(3).strip())
            continue
        m = pat2.match(line.strip())
        if m:
            try:
                rva = int(m.group(1), 16)
            except ValueError:
                continue
            out[rva] = (m.group(2), m.group(3).strip())
    return out


def build_rva_method_lookup(rva_map: dict) -> dict:
    """rva -> 'Namespace.Class::Method' short label from dump parse."""
    out = {}
    for rva, info in rva_map.items():
        # parse_dump stores List[MethodInfo] per RVA
        if isinstance(info, (list, tuple)):
            info = info[0] if info else None
        if info is None:
            continue
        ns = getattr(info, "ns", "") or ""
        cls = getattr(info, "cls", "") or "?"
        name = getattr(info, "name", "") or "?"
        label = f"{cls}::{name}" if not ns else f"{ns}.{cls}::{name}"
        out[int(rva)] = label
    return out



def _format_method_full(info) -> str:
    """Namespace.Class::Method (ret, N params) for reports."""
    if info is None:
        return ""
    if isinstance(info, (list, tuple)):
        info = info[0] if info else None
    if info is None:
        return ""
    ns = getattr(info, "ns", "") or ""
    cls = getattr(info, "cls", "?")
    name = getattr(info, "name", "?")
    ret = getattr(info, "ret_type", "") or ""
    pc = getattr(info, "param_count", None)
    full = f"{ns}.{cls}::{name}" if ns else f"{cls}::{name}"
    extra = []
    if ret:
        extra.append(ret)
    if pc is not None:
        extra.append(f"{pc}p")
    if extra:
        full += f" ({', '.join(extra)})"
    return full


def _store_offset_meta(offset_meta: dict, old_rva: int, new_rva: int,
                        old_rva_map: dict, strategy: str, detail: str,
                        kind: str = "map", rel: str = ""):
    """Fill offset_meta with namespace/class/method from dump for report + script comments."""
    old_hex = f"0x{old_rva:X}"
    new_hex = f"0x{new_rva:X}"
    infos = (old_rva_map or {}).get(old_rva) or (old_rva_map or {}).get(old_rva & ~3)
    full = _format_method_full(infos) if infos else ""
    if not full:
        full = _short_method_label(detail, strategy) or strategy or "offset"
    info0 = None
    if infos:
        info0 = infos[0] if isinstance(infos, (list, tuple)) else infos
    offset_meta[new_hex.upper()] = {
        "label": full.split(" (")[0] if full else "offset",  # Class::Method short
        "full": full,
        "ns": getattr(info0, "ns", "") if info0 else "",
        "cls": getattr(info0, "cls", "") if info0 else "",
        "name": getattr(info0, "name", "") if info0 else "",
        "ret": getattr(info0, "ret_type", "") if info0 else "",
        "params": getattr(info0, "param_count", "") if info0 else "",
        "old": old_hex,
        "new": new_hex,
        "kind": kind,
        "rel": rel,
        "strategy": strategy,
        "detail": (detail or "")[:160],
    }
    return full


def _short_method_label(detail: str, strategy: str = "") -> str:


    """Pull Class::Method from a mapping detail string when possible."""
    # patterns: Namespace.Class::Method  or Class::Method
    m = re.search(r"([\w.]+)::(\w+)", detail or "")
    if m:
        cls = m.group(1).split(".")[-1]
        return f"{cls}::{m.group(2)}"
    m = re.search(r"->\s*(\w+)\s*\(", detail or "")
    if m:
        return m.group(1)
    # script-hint: script label/comment 'Foo'
    m = re.search(r"script label/comment '([^']+)'", detail or "")
    if m:
        return m.group(1)
    if strategy == "plus4-pair":
        return "+4 pair"
    if strategy == "ida-body":
        m = re.search(r"inside\s+(\S+)", detail or "")
        if m:
            return f"inside {m.group(1)}"
    return ""



def _short_cls_method(label: str) -> str:
    """'_Car_Parking...RallyCar::IsCarOffRoad' -> 'RallyCar::IsCarOffRoad'"""
    if not label:
        return "offset"
    if "::" in label:
        left, right = label.rsplit("::", 1)
        cls = left.split(".")[-1]
        return f"{cls}::{right.split(' (')[0]}"
    return label.split(".")[-1]


def annotate_offset_names(script_text: str, meta: dict) -> str:

    """
    Add comments next to mapped offsets in the updated .lua:

      lib + 0x2F1A554  -- ObscuredPrefs::GetFloat | was 0x2BF59CC
      lib + 0x2F1A554 + 0x4  -- +4 after ObscuredPrefs::GetFloat | was 0x2BF59D0

    meta keys must be UPPER hex like 0x2F1A554.
    """
    if not meta:
        return script_text

    # Normalize keys to "0x" + UPPER hex digits (never "0X...")
    def _nk(s: str) -> str:
        s = str(s).strip()
        if s.lower().startswith("0x"):
            return "0x" + s[2:].upper()
        return "0x" + s.upper()
    meta = {_nk(k): v for k, v in meta.items()}

    keys = sorted(meta.keys(), key=len, reverse=True)
    out_lines = []
    for line in script_text.splitlines():
        stripped = line.strip()
        if stripped.startswith("--") or stripped.startswith("//") or stripped.startswith("#"):
            out_lines.append(line)
            continue
        if " | was " in line or " | unchanged" in line or " | +4" in line:
            out_lines.append(line)
            continue

        # Find ALL 0x offsets on this line (base and +0x4 style)
        found = list(re.finditer(r"\b(0x[0-9A-Fa-f]+)\b", line))
        if not found:
            out_lines.append(line)
            continue

        notes = []
        used = set()
        # Detect "lib + 0xBASE + 0x4" style (BASE may be mapped; +N is relative)
        plus_m = re.search(
            r"\b(0x[0-9A-Fa-f]+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\b",
            line, re.I,
        )
        line_plus = None  # (base_hex_upper, delta_int)
        if plus_m:
            try:
                b = int(plus_m.group(1), 16)
                d_s = plus_m.group(2)
                d = int(d_s, 16) if d_s.lower().startswith("0x") else int(d_s)
                line_plus = (f"0x{b:X}", d)
            except ValueError:
                line_plus = None

        def _norm_hex(s: str) -> str:
            s = s.strip()
            if s.lower().startswith("0x"):
                return "0x" + s[2:].upper()
            return "0x" + s.upper()

        for m in found:
            hx = _norm_hex(m.group(1))
            info = meta.get(hx)
            if hx in used:
                continue
            used.add(hx)

            # Base+delta line: prefer parent method name + "+N"
            if line_plus and hx == line_plus[0] and line_plus[0] in meta:
                parent = meta[line_plus[0]]
                label = _short_cls_method(parent.get("label") or "offset")
                old_h = parent.get("old", "")
                delta = line_plus[1]
                if delta == 0:
                    if old_h and old_h.upper() != hx:
                        notes.append(f"{label} | was {old_h}")
                    else:
                        notes.append(f"{label} | unchanged")
                else:
                    notes.append(
                        f"+{delta:#x} after {label}"
                        + (f" | was {old_h}" if old_h else "")
                    )
                continue

            if info is None:
                continue
            label = _short_cls_method(info.get("label") or "offset")
            kind = info.get("kind", "map")
            old_h = info.get("old", "")
            new_h = info.get("new", hx)
            rel = info.get("rel", "")

            if kind == "same":
                note = f"{label} | unchanged"
            elif kind == "plus4":
                note = f"+4 after {label}" + (f" | was {old_h}" if old_h else "")
            elif kind == "ida-body":
                note = f"{label}" + (f" {rel}" if rel else "") + (f" | was {old_h}" if old_h else "")
            else:
                if old_h and str(old_h).upper() != str(new_h).upper():
                    note = f"{label} | was {old_h}"
                else:
                    note = f"{label} | unchanged"
            notes.append(note)

        # Heuristic: "lib + 0xBASE + 0x4" without separate meta -> inherit +4 from base
        if not notes and len(found) >= 1:
            # look for pattern BASE + 0x4 / +4
            for m in found:
                hx = m.group(1).upper()
                try:
                    base = int(hx, 16)
                except ValueError:
                    continue
                # if this is base+4 of a known mapping
                parent = meta.get(f"0x{base-4:X}")
                if parent and ("+ 0x4" in line or "+0x4" in line or "+ 4" in line):
                    label = parent.get("label") or "offset"
                    notes.append(f"+4 after {label} | was related")
                    break
                parent = meta.get(hx)
                if parent:
                    label = parent.get("label") or "offset"
                    old_h = parent.get("old", "")
                    if old_h and old_h.upper() != hx:
                        notes.append(f"{label} | was {old_h}")
                    else:
                        notes.append(f"{label} | unchanged")
                    break

        if notes:
            # one combined comment
            comment = "  -- " + " ; ".join(notes)
            if comment.strip() not in line:
                out_lines.append(line.rstrip() + comment)
            else:
                out_lines.append(line)
        else:
            out_lines.append(line)

    return "\n".join(out_lines) + ("\n" if script_text.endswith("\n") else "")



def annotate_arm64_patches(script_text: str, rva_methods: dict | None = None,
                           ida_insns: dict | None = None) -> str:
    """
    Add ARM64 comments next to patch values.

    Also, when possible, explain the *connection*:
      - Dump method at this offset (from Il2CppDumper RVA)
      - Original IDA instruction at this RVA (if dump had bytes)
      - Patch instruction meaning (local + armconverter)

    Example:
      value = -763363296
        -- ARM64: MOV X0, #1 -> force TRUE  | dump: Foo::IsLocked  | IDA was: LDR W0, [X0,#0x10]
    """
    rva_methods = rva_methods or {}
    ida_insns = ida_insns or {}
    out_lines = []

    # Collect offsets mentioned on recent lines for context pairing
    recent_offsets = []  # list of int RVAs seen on last few lines

    for line in script_text.splitlines():
        if "ARM64:" in line or re.search(r"--\s*ARM", line, re.I):
            out_lines.append(line)
            # still track offsets
            for m in re.finditer(r"\b0x([0-9A-Fa-f]{5,10})\b", line):
                try:
                    recent_offsets.append(int(m.group(1), 16))
                except ValueError:
                    pass
            recent_offsets = recent_offsets[-6:]
            continue
        stripped = line.strip()
        if stripped.startswith("--") or stripped.startswith("//") or stripped.startswith("#"):
            out_lines.append(line)
            continue

        # track offsets on this line
        line_offs = []
        for m in re.finditer(r"\b0x([0-9A-Fa-f]{5,10})\b", line):
            try:
                line_offs.append(int(m.group(1), 16))
            except ValueError:
                pass
        if line_offs:
            recent_offsets.extend(line_offs)
            recent_offsets = recent_offsets[-6:]

        meaning = None

        # 1) GG h-hex: 'h200080D2' or h200080D2
        for m in re.finditer(r"['\"]h([0-9A-Fa-f]{8})['\"]", line, re.I):
            meaning = arm64_meaning_for_token("h" + m.group(1))
            if meaning and not meaning.startswith("???"):
                break
            meaning = None
        if not meaning:
            for m in re.finditer(r"\bh([0-9A-Fa-f]{8})\b", line, re.I):
                meaning = arm64_meaning_for_token("h" + m.group(1))
                if meaning and not meaning.startswith("???"):
                    break
                meaning = None

        # 2) 0x dword on value=/flags/TYPE_DWORD lines
        if not meaning and re.search(
            r"value\s*=|flags|TYPE_DWORD|TYPE_QWORD|setValues?\s*\(", line, re.I
        ):
            for m in re.finditer(r"\b0x([0-9A-Fa-f]{8})\b", line, re.I):
                meaning = arm64_meaning_for_token("0x" + m.group(1))
                if meaning and not meaning.startswith("???"):
                    break
                meaning = None

        # 3) Signed/unsigned decimal patch values (very common in GG scripts)
        #    value = -763363328
        #    setvalue(lib + Off, gg.TYPE_DWORD, -698416192)
        #    gg.setValues({{..., value = -763363296}})
        if not meaning and re.search(
            r"value\s*=|TYPE_DWORD|TYPE_QWORD|setValues?\s*\(|editAll|setValues",
            line,
            re.I,
        ):
            # Prefer last number on the line (usually the patch value)
            nums = list(re.finditer(r"(?<![\w.])(-?\d{5,12})(?![\w])", line))
            for m in reversed(nums):
                meaning = arm64_meaning_for_token(m.group(1))
                if meaning and not meaning.startswith("???"):
                    break
                meaning = None

        if meaning:
            # Clean single comment. Merge into existing -- name comment if present.
            # Drop dump:/IDA here (noisy / often wrong for +4 lines).
            arm = meaning
            # shorten intent arrows for one-line readability
            arm = arm.replace("  -> force TRUE (IsBought/unlock/bool)", " (TRUE)")
            arm = arm.replace("  -> force FALSE / zero return", " (FALSE)")
            arm = arm.replace("  -> return to caller (pair after MOV)", "")
            arm = arm.replace("  -> NOP (neutralize branch/check)", " (NOP)")
            arm = arm.replace("  -> B #0 hang risk - avoid", " (B#0 BAD)")
            arm = arm.replace("  -> force return imm (MOVZ)", "")
            if " -- " in line:
                # already has method name comment from annotate_offset_names
                out_lines.append(line.rstrip() + " | " + arm)
            else:
                out_lines.append(line.rstrip() + "  -- " + arm)
        else:
            out_lines.append(line)

    return "\n".join(out_lines) + ("\n" if script_text.endswith("\n") else "")



def extract_candidate_rvas(script_text: str, min_off=0x10000, max_off=0x80000000) -> set:
    """
    Collect code RVAs from a .lua script.

    min_off defaults to 0x10000 so short FIELD offsets (0x1B8, 0x50, 0xF4)
    used with valueFromClass() are NOT treated as code addresses.
    ARM instruction constants (MOV/RET/NOP encodings) are also filtered out.
    """
    found = set()
    for m in HEX_RE.finditer(script_text):
        try:
            val = int(m.group(1), 16)
        except ValueError:
            continue
        if min_off <= val <= max_off and not looks_like_arm_instruction(val):
            found.add(val)
    return found


def extract_script_hints(script_text: str) -> dict:
    """
    Parse .lua comments / labels near hex offsets for method-name hints.

    CPM1 scripts often write:
      OnInjectionDetected = 0x2966E1C
      local void1=0x29EA840   -- offset Update
      -- RVA: 0x2AD5DE4
      CarDebugTools_Update   = 0x2D20888

    Returns: { rva_int: ["Update", "OnInjectionDetected", ...] }
    """
    hints = defaultdict(list)
    lines = script_text.splitlines()
    # name = 0xHEX  or  0xHEX -- name
    assign_re = re.compile(
        r"(?:^|\s)([A-Za-z_][\w]*)\s*=\s*(0x[0-9A-Fa-f]{5,10})\b",
        re.I,
    )
    comment_re = re.compile(
        r"(0x[0-9A-Fa-f]{5,10}).{0,40}--\s*(.+)$",
        re.I,
    )
    rva_comment = re.compile(
        r"//\s*RVA:\s*(0x[0-9A-Fa-f]+).*?(?:\n.*?)*?(?:public|private|internal|protected)?\s*"
        r"(?:static\s+)?[\w.<>,\[\]\s]+?\s+(\w+)\s*\(",
        re.I | re.S,
    )
    for line in lines:
        for m in assign_re.finditer(line):
            name, hx = m.group(1), m.group(2)
            try:
                rva = int(hx, 16)
            except ValueError:
                continue
            # skip generic void1/void2/OFFSET1 unless comment has more
            if name.lower() not in {
                "void1", "void2", "offset", "offset1", "offset2", "ofst",
                "addr", "address", "base", "lib", "drag",
            }:
                # strip common prefixes
                clean = re.sub(r"^(CPM1|local)", "", name, flags=re.I)
                clean = clean.replace("_", " ").strip()
                # Keep CamelCase tokens
                if len(name) >= 4:
                    hints[rva].append(name)
        for m in comment_re.finditer(line):
            try:
                rva = int(m.group(1), 16)
            except ValueError:
                continue
            comment = m.group(2).strip()
            # pull Update / Start / method-like words
            for tok in re.findall(r"[A-Za-z_][A-Za-z0-9_]{2,}", comment):
                if tok.lower() not in {"offset", "void", "rva", "va", "local", "the", "and"}:
                    hints[rva].append(tok)
    # dedupe preserve order
    out = {}
    for rva, names in hints.items():
        seen = set()
        uniq = []
        for n in names:
            if n not in seen:
                seen.add(n)
                uniq.append(n)
        out[rva] = uniq
    return out


def pair_plus4_offsets(rvas: set) -> dict:
    """
    CPM1 scripts patch MOV at X and RET at X+4.
    Returns: { start_rva: plus4_rva } for pairs present in the script.
    Mapping the start is enough; +4 follows if both exist.
    """
    pairs = {}
    for r in rvas:
        if (r + 4) in rvas:
            pairs[r] = r + 4
    return pairs


# ============================================================================
# DATA STRUCTURE – one method from a dump.cs
# ============================================================================
@dataclass
class MethodInfo:
    """One method extracted from dump.cs - the unit we match against."""
    ns: str                  # Namespace, e.g. "MyGame.Racing" (may be empty)
    cls: str                 # Class name, e.g. "CarController"
    name: str                # Method name, e.g. "GetSpeed" or obfuscated "gasdhjasdh"
    rva: int                 # Start address (RVA) of this method in the binary
    is_static: bool = False  # True if "static" method
    ret_type: str = ""       # Return type text, e.g. "float" / "void" / "GameObject"
    param_count: int = 0     # Number of parameters (0 = no args)
    params_raw: str = ""     # Original param list, e.g. "int value, GameObject car"
    sig_key: str = ""        # Compact key: "I|void|1|int"  (see _sig_key / _WEAK_SIGS)
    idx: int = 0             # Position of this method inside its class (0, 1, 2, …)
    end_rva: int = 0         # Last address in method body (IDA dumps); 0 = unknown


def _norm_type(t: str) -> str:
    t = re.sub(r"\s+", "", (t or ""))
    return t.split(".")[-1].lower()


def _norm_params(params: str) -> str:
    """Normalize parameter list for comparison: types only, no names.
    'int value, GameObject car' -> 'int,gameobject'
    """
    if not params or not params.strip():
        return ""
    parts = []
    for p in params.split(","):
        p = p.strip()
        if not p:
            continue
        # drop default values
        p = p.split("=")[0].strip()
        tokens = p.split()
        if not tokens:
            continue
        # last token is usually name; types are before it
        if len(tokens) == 1:
            parts.append(_norm_type(tokens[0]))
        else:
            # join type tokens except last (name)
            typ = " ".join(tokens[:-1])
            parts.append(_norm_type(typ))
    return ",".join(parts)


def _sig_key(is_static: bool, ret: str, nparams: int, params_raw: str = "") -> str:
    """
    Build a short signature key used for matching across dumps.

    Format examples:
      "I|void|0"           -> instance, returns void, 0 params
      "S|bool|1|int"       -> static, returns bool, 1 param of type int
      "I|float|2|int,gameobject"

    Prefix:  I = instance method,  S = static method
    See _WEAK_SIGS for patterns that are too common to trust alone.
    """
    base = f"{'S' if is_static else 'I'}|{_norm_type(ret)}|{nparams}"
    pt = _norm_params(params_raw)
    if pt:
        return f"{base}|{pt}"
    return base


def _sigs_match(a: "MethodInfo", b: "MethodInfo") -> Tuple[bool, str]:
    """
    Compare two methods by signature only (ignore name).

    Checks: parameter count, return type, parameter types.
    Returns (matched?, short_detail_for_report).

    Example match: both are instance methods returning float with (int, GameObject).
    """
    if a.param_count != b.param_count:
        return False, f"params {a.param_count}!={b.param_count}"
    ra, rb = _norm_type(a.ret_type), _norm_type(b.ret_type)
    if ra and rb and ra != rb:
        return False, f"ret {ra}!={rb}"
    pa, pb = _norm_params(a.params_raw), _norm_params(b.params_raw)
    if pa and pb and pa != pb:
        return False, f"types {pa}!={pb}"
    # match if param_count equal and (no type info OR types equal)
    detail = f"({a.params_raw or a.param_count})"
    if pa:
        detail = f"({pa})"
    if ra:
        detail = f"{ra}{detail}"
    return True, detail


def _class_key(ns: str, cls: str) -> str:
    ns = (ns or "").strip()
    if ns and ns.lower() not in ("", "-", "global", "none"):
        return f"{ns}.{cls}"
    return cls


def _name_similarity(a: str, b: str) -> float:
    """
    How similar are two method names?  Returns 0.0 … 1.0.

    Examples that score high:
      TryCloseHood  ->  TryCloseHoodAndTrunk   (substring)
      get_TargetHeight -> get_TargetClearance  (shared tokens: get, Target)
      GetSpeed      ->  GetSpd                 (bigrams)

    Pure random obfuscated names score near 0.
    """
    if not a or not b:
        return 0.0
    if a == b:
        return 1.0
    al, bl = a.lower(), b.lower()
    if al == bl:
        return 1.0
    # substring / prefix on lowercase
    if al in bl or bl in al:
        shorter, longer = (al, bl) if len(al) <= len(bl) else (bl, al)
        return max(0.6, len(shorter) / max(len(longer), 1))
    # Split CamelCase + underscores BEFORE lowercasing:
    # get_TargetHeight -> get, Target, Height
    def tokens(s: str) -> set:
        parts = re.findall(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])", s)
        out = set()
        for p in parts:
            p = p.lower()
            if len(p) > 1:
                out.add(p)
        # also underscore pieces
        for p in s.replace("-", "_").split("_"):
            p = p.lower()
            if len(p) > 1:
                out.add(p)
        return out
    ta, tb = tokens(a), tokens(b)
    if ta and tb:
        inter = len(ta & tb)
        union = len(ta | tb)
        token_score = inter / union if union else 0.0
        if inter >= 2:
            token_score = max(token_score, 0.62)
        elif inter == 1 and inter / max(len(ta), len(tb)) >= 0.4:
            token_score = max(token_score, 0.50)
    else:
        token_score = 0.0
    def bigrams(s):
        s = s.lower()
        return {s[i:i+2] for i in range(len(s) - 1)} if len(s) >= 2 else {s}
    ba, bb = bigrams(a), bigrams(b)
    if ba and bb:
        inter_b = len(ba & bb)
        dice = (2.0 * inter_b) / (len(ba) + len(bb))
    else:
        dice = 0.0
    return max(token_score, dice)



def _method_span(m: "MethodInfo") -> int:
    """Estimated body size in bytes (0 if unknown)."""
    if m.end_rva and m.end_rva > m.rva:
        return m.end_rva - m.rva
    return 0


def _size_score(old_info: "MethodInfo", cand: "MethodInfo") -> tuple:
    """
    Compare method body lengths (end_rva - start_rva) from IDA-style dumps.

    If both sizes are known:
      similar (≥75% ratio)  -> +SIZE_MATCH_BONUS   (likely same function)
      very different (<35%) -> -SIZE_MISMATCH_PENALTY  (stub vs large method)

    Returns (delta_conf, detail_str).  (0, "") if size unknown.
    """
    so, sc = _method_span(old_info), _method_span(cand)
    if so <= 0 or sc <= 0:
        return 0, ""
    ratio = min(so, sc) / max(so, sc)
    if ratio >= 0.75:
        return SIZE_MATCH_BONUS, f"sizeok({so:#x}~{sc:#x})"
    if ratio < 0.35:
        return -SIZE_MISMATCH_PENALTY, f"size!=({so:#x}vs{sc:#x})"
    return 0, f"size~({so:#x}/{sc:#x})"


def _is_unique_sig_in_class(
    info: "MethodInfo",
    class_methods: list,
) -> bool:
    """
    True if this signature appears only ONCE in the class.

    Example: only one method is "I|float|1|int" in CarController.
    That makes signature matching much safer than a common "I|void|0".
    Weak signatures (_WEAK_SIGS) are never treated as unique.
    """
    if not info.sig_key or info.sig_key in _WEAK_SIGS:
        return False
    count = sum(1 for m in class_methods if m.sig_key == info.sig_key)
    return count == 1



def is_obfuscated_name(name: str) -> bool:
    """
    True if a class/method name looks CPM1-style obfuscated:
      - contains Cyrillic
      - short random mixed Latin (no dictionary word shape)
    Clear names like Update, CarController, get_Speed return False.
    """
    if not name:
        return True
    if name in STABLE_METHODS or name.startswith(".") and name[1:] in STABLE_METHODS:
        return False
    # compiler-generated
    if name.startswith("<") or "<>" in name or name.startswith("__"):
        return True
    # Cyrillic block
    if re.search(r"[\u0400-\u04FF]", name):
        return True
    # short mixed junk: has digits+letters or weird casing with no vowels pattern
    if len(name) <= 6 and re.search(r"\d", name) and re.search(r"[A-Za-z]", name):
        return True
    if len(name) <= 5 and name.lower() not in {
        "init", "load", "save", "play", "stop", "open", "close", "draw",
        "main", "run", "set", "get", "add", "remove",
    }:
        # all-consonant-ish short tokens often obfuscated
        vowels = sum(1 for c in name.lower() if c in "aeiouy")
        if vowels == 0 and re.match(r"^[A-Za-z]+$", name):
            return True
    return False


def class_fingerprint(methods: list) -> tuple:
    """
    Structural fingerprint of a class for CPM1 when names are junk.

    Uses:
      - ordered signature keys
      - positions of STABLE_METHODS (Update/Start/.ctor/…)
    Two classes with the same fingerprint are likely the same type
    even if both class names were re-obfuscated.
    """
    sigs = tuple(m.sig_key or f"?|{m.param_count}" for m in methods)
    stable_pos = tuple(
        (m.name if m.name in STABLE_METHODS else None)
        for m in methods
    )
    # compact: only keep stable names, blanks as ''
    stable_compact = tuple(x or "" for x in stable_pos)
    return (len(methods), sigs, stable_compact)


def structural_class_match(
    old_methods: list,
    new_class_map: dict,
    claimed: set,
) -> list:
    """
    Find new classes whose fingerprint is close to old_methods.
    Returns list of (score, class_key, new_methods).
    """
    if not old_methods:
        return []
    old_fp = class_fingerprint(old_methods)
    old_stable = {m.name for m in old_methods if m.name in STABLE_METHODS}
    old_sigs = [m.sig_key for m in old_methods if m.sig_key and m.sig_key not in _WEAK_SIGS]
    results = []
    for ck, new_m in new_class_map.items():
        if abs(len(new_m) - len(old_methods)) > CLASS_SIZE_DIFF_MAX + 2:
            continue
        new_stable = {m.name for m in new_m if m.name in STABLE_METHODS}
        shared_stable = old_stable & new_stable
        if len(shared_stable) < 1 and not old_stable:
            # no stable methods either side - fall back to sig sequence only
            pass
        elif len(shared_stable) < 1:
            continue
        # signature overlap
        new_sigs = [m.sig_key for m in new_m if m.sig_key and m.sig_key not in _WEAK_SIGS]
        shared_sigs = set(old_sigs) & set(new_sigs)
        score = 0
        score += 15 * len(shared_stable)
        score += 3 * len(shared_sigs)
        if len(new_m) == len(old_methods):
            score += 10
        # stable positions align?
        for name in shared_stable:
            oi = next((i for i, m in enumerate(old_methods) if m.name == name), None)
            ni = next((i for i, m in enumerate(new_m) if m.name == name), None)
            if oi is not None and ni is not None and abs(oi - ni) <= 2:
                score += 8
        if score >= 20:
            results.append((score, ck, new_m))
    results.sort(key=lambda x: -x[0])
    return results[:5]




# ============================================================================
# PARSE dump.cs -> lookup tables (rva_map, class_map, ranges)
# ============================================================================
def parse_dump(path: Path):
    """
    Stream-parse dump.cs - works for:
      • Normal Il2CppDumper dump (~40–50 MB)
      • IDA-annotated dump (~500 MB+) with disassembly + |-RVA: lines

    For IDA dumps also records method body ranges (start..end) from
    instruction addresses so script offsets inside a function
    (Penalty/Time internals) can be remapped relatively.
    """
    rva_map: Dict[int, List[MethodInfo]] = defaultdict(list)
    class_map: Dict[str, List[MethodInfo]] = defaultdict(list)
    ns_map: Dict[str, Set[str]] = defaultdict(set)
    # rva -> MethodInfo (primary) for range updates
    by_start: Dict[int, MethodInfo] = {}
    ida_insns: Dict[int, tuple] = {}  # rva -> (raw_hex, disasm) from real IDA listings

    current_ns = ""
    current_class = "Unknown"
    size_mb = path.stat().st_size / 1e6
    is_ida = size_mb > 100
    log.info(
        "Parsing %s (%.1f MB)%s streaming...",
        path.name, size_mb, " [IDA-style]" if is_ida else "",
    )

    LOOKAHEAD = 10
    buf: deque = deque()
    in_disasm = False
    current_method: Optional[MethodInfo] = None  # method whose body we are in

    def fill(fh, n=LOOKAHEAD):
        while len(buf) < n:
            line = fh.readline()
            if not line:
                break
            buf.append(line.rstrip("\r\n"))

    def parse_method_from_lookahead():
        method_name = None
        is_static, ret_type, param_count = False, "", 0
        params_raw = ""
        for mline in buf:
            s = mline.strip()
            if not s:
                continue
            if RVA_RE.search(s) or IDA_RVA_RE.search(s):
                break
            if s.startswith("/*") or s.startswith("*/") or s.startswith("// ═") or s.startswith("// ─"):
                break
            if re.match(r"^0x[0-9A-Fa-f]+:", s):
                continue
            if s.startswith(("//", "[")):
                continue
            mm = METHOD_LINE_RE.search(s)
            if mm:
                is_static = bool(mm.group(1))
                ret_type = mm.group(2).strip()
                method_name = mm.group(3)
                params = mm.group(4).strip()
                param_count = 0 if not params else params.count(",") + 1
                params_raw = params
                break
            ctor = re.match(
                r"^(?:public|private|internal|protected)?\s*"
                r"(?:static\s+)?(?:void\s+)?\.(c?ctor)\s*\(",
                s,
            )
            if ctor:
                method_name = ctor.group(1)
                cparams = re.search(r"\(([^)]*)\)", s)
                if cparams:
                    params_raw = cparams.group(1).strip()
                    param_count = 0 if not params_raw else params_raw.count(",") + 1
                break
            bare = re.match(r"^(\w+)\s*\(", s)
            if bare and not s.startswith(("if", "for", "while", "switch", "return")):
                method_name = bare.group(1)
                bparams = re.search(r"\(([^)]*)\)", s)
                if bparams:
                    params_raw = bparams.group(1).strip()
                    param_count = 0 if not params_raw else params_raw.count(",") + 1
                break
        return method_name, is_static, ret_type, param_count, params_raw

    def add_method(rva, method_name, is_static, ret_type, param_count, params_raw):
        nonlocal current_method
        if not method_name or method_name in SKIP_METHODS:
            return None
        if rva <= 0 or rva == 0xFFFFFFFF:
            return None
        ck = _class_key(current_ns, current_class)
        info = MethodInfo(
            ns=current_ns,
            cls=current_class,
            name=method_name,
            rva=rva,
            is_static=is_static,
            ret_type=ret_type,
            param_count=param_count,
            params_raw=params_raw,
            sig_key=_sig_key(is_static, ret_type, param_count, params_raw),
            end_rva=rva,  # grows when we see disasm instructions
        )
        rva_map[rva].append(info)
        class_map[ck].append(info)
        if ck != current_class:
            class_map[current_class].append(info)
        by_start[rva] = info
        current_method = info
        return info

    with open(path, "r", encoding="utf-8", errors="ignore") as fh:
        fill(fh)
        lines_seen = 0
        last_method_name = None

        while buf:
            line = buf.popleft()
            lines_seen += 1
            fill(fh)
            s = line.strip()

            # Enter disassembly / generic-inst block
            if "/* Disassembly" in line or "/* GenericInstMethod" in line:
                in_disasm = True

            if in_disasm:
                # Instruction address -> extend current method body range
                im = INSTR_ADDR_RE.match(line)
                if im:
                    try:
                        addr = int(im.group(1), 16)
                        if current_method is not None and addr > current_method.end_rva:
                            current_method.end_rva = addr + 4
                        # Capture "0xADDR: BB BB BB BB  mnemonic" if present
                        rest = line[im.end():].strip()
                        bm = re.match(
                            r"((?:[0-9A-Fa-f]{2}\s+){3}[0-9A-Fa-f]{2})\s+(\S+.*)$",
                            rest,
                        )
                        if bm:
                            ida_insns[addr] = (bm.group(1).replace(" ", ""), bm.group(2).strip())
                        else:
                            # "0xADDR: MNEMONIC" without bytes
                            if rest and re.match(r"^[A-Za-z]", rest):
                                ida_insns[addr] = ("", rest)
                    except ValueError:
                        pass

                # |-RVA inside GenericInstMethod
                ida = IDA_RVA_RE.search(s)
                if ida:
                    try:
                        rva = int(ida.group(1), 16)
                    except ValueError:
                        rva = 0
                    meth = last_method_name
                    for peek in buf:
                        mm2 = IDA_METH_RE.search(peek.strip())
                        if mm2:
                            meth = mm2.group(2)
                            break
                        if IDA_RVA_RE.search(peek) or peek.strip().startswith("*/"):
                            break
                    if rva > 0x10000:
                        add_method(rva, meth or "generic", False, "", 0, "")

                if "*/" in line:
                    in_disasm = False
                continue

            nm = NS_RE.match(s)
            if nm:
                current_ns = nm.group(1).strip()
                continue

            cm = CLASS_RE.search(line)
            if cm:
                current_class = cm.group(1)
                ns_map[current_ns].add(current_class)

            rm = RVA_RE.search(line)
            if rm:
                try:
                    rva = int(rm.group(1), 16)
                except ValueError:
                    rva = -1
                method_name, is_static, ret_type, param_count, params_raw = parse_method_from_lookahead()
                last_method_name = method_name
                if rva > 0:
                    add_method(rva, method_name, is_static, ret_type, param_count, params_raw)
                continue

            ida = IDA_RVA_RE.search(s)
            if ida:
                try:
                    rva = int(ida.group(1), 16)
                except ValueError:
                    continue
                meth = last_method_name
                for peek in buf:
                    mm2 = IDA_METH_RE.search(peek.strip())
                    if mm2:
                        meth = mm2.group(2)
                        break
                if rva > 0x10000:
                    add_method(rva, meth or "ida_rva", False, "", 0, "")
                continue

            if lines_seen % 3_000_000 == 0:
                log.info("  ... %d lines, %d RVAs so far", lines_seen, len(rva_map))

    # Estimate end_rva for methods without disasm: next method start - 4
    for ck, methods in class_map.items():
        methods.sort(key=lambda m: m.rva)
        seen = set()
        unique = []
        for m in methods:
            if m.rva in seen:
                continue
            seen.add(m.rva)
            unique.append(m)
        for idx, m in enumerate(unique):
            m.idx = idx
            if m.end_rva <= m.rva and idx + 1 < len(unique):
                m.end_rva = max(m.rva + 4, unique[idx + 1].rva - 4)
            elif m.end_rva <= m.rva:
                m.end_rva = m.rva + 0x100  # small stub default
        class_map[ck] = unique

    # Sorted ranges for binary search: (start, end, MethodInfo)
    ranges: List[Tuple[int, int, MethodInfo]] = []
    for m in by_start.values():
        end_a = m.end_rva if m.end_rva > m.rva else m.rva + 0x100
        ranges.append((m.rva, end_a, m))
    ranges.sort(key=lambda x: x[0])

    log.info(
        "Parsed %s: %d RVAs, %d classes, %d body-ranges (%.1f MB)",
        path.name, len(rva_map), len(class_map), len(ranges), size_mb,
    )
    return dict(rva_map), dict(class_map), dict(ns_map), ranges, dict(ida_insns)


def find_enclosing_method(ranges: List[Tuple[int, int, MethodInfo]], addr: int):
    """Binary search: method whose [start, end] contains addr."""
    if not ranges:
        return None
    lo, hi = 0, len(ranges) - 1
    best = None
    while lo <= hi:
        mid = (lo + hi) // 2
        start, end, info = ranges[mid]
        if addr < start:
            hi = mid - 1
        elif addr > end:
            lo = mid + 1
        else:
            return info
    # fallback: nearest start <= addr within 0x8000
    lo2, hi2 = 0, len(ranges) - 1
    cand = None
    while lo2 <= hi2:
        mid = (lo2 + hi2) // 2
        start, end, info = ranges[mid]
        if start <= addr:
            cand = (start, end, info)
            lo2 = mid + 1
        else:
            hi2 = mid - 1
    if cand and addr - cand[0] <= 0x8000:
        return cand[2]
    return None



# ============================================================================
# BUILD FAST INDEXES for matching
# ============================================================================
def build_indexes(rva_map, class_map):
    cm_exact: Dict[Tuple[str, str], List[int]] = defaultdict(list)
    meth_only: Dict[str, List[Tuple[str, int]]] = defaultdict(list)
    sig_index: Dict[str, List[Tuple[str, str, int]]] = defaultdict(list)

    for rva, infos in rva_map.items():
        for info in infos:
            ck = _class_key(info.ns, info.cls)
            cm_exact[(ck, info.name)].append(rva)
            cm_exact[(info.cls, info.name)].append(rva)
            meth_only[info.name].append((ck, rva))
            if info.sig_key:
                sig_index[info.sig_key].append((ck, info.name, rva))

    return dict(cm_exact), dict(meth_only), dict(sig_index)


def resolve_in_old(old_rva, old_rva_map):
    for delta in (0, -4, 4, -8, 8):
        infos = old_rva_map.get(old_rva + delta)
        if infos:
            note = f"aligned {delta:+d} (instr boundary)" if delta else ""
            return infos, delta, note
    return None, 0, ""


def _neighbor_score(old_m: List[MethodInfo], new_m: List[MethodInfo], idx: int,
                    old_info: Optional[MethodInfo] = None) -> Tuple[int, str]:
    """
    Score same-index candidate.
    v5.10: signature, ±1/±2 neighbors, .ctor anchors, size, fuzzy name.
    """
    if idx < 0 or idx >= len(old_m) or idx >= len(new_m):
        return 0, "out of range"

    score = 40
    detail_parts = [f"idx={idx}"]
    cand = new_m[idx]
    src = old_info or old_m[idx]

    # --- signature ---
    sig_ok, sig_detail = _sigs_match(src, cand)
    if sig_ok:
        score += 30
        detail_parts.append(f"sigok{sig_detail}")
        if _is_unique_sig_in_class(src, old_m) and _is_unique_sig_in_class(cand, new_m):
            score += UNIQUE_SIG_BOOST
            detail_parts.append("uniq-sigok")
    else:
        detail_parts.append(f"sig!=({sig_detail})")

    # --- CPM1: both sides are stable Unity methods ---
    if src.name in STABLE_METHODS and cand.name in STABLE_METHODS:
        if src.name == cand.name:
            score += 25
            detail_parts.append(f"stableok{src.name}")
        else:
            score -= 10
            detail_parts.append(f"stable!={src.name}/{cand.name}")

    # --- surrounding methods: ±1 and ±2 ---
    for off, weight_name, weight_sig in (
        (-1, 18, 10),
        (1, 18, 10),
        (-2, 8, 5),
        (2, 8, 5),
    ):
        oi, ni = idx + off, idx + off
        if oi < 0 or oi >= len(old_m) or ni < 0 or ni >= len(new_m):
            continue
        label = f"{'prev' if off < 0 else 'next'}{abs(off)}"
        if old_m[oi].name == new_m[ni].name:
            score += weight_name
            detail_parts.append(f"{label}={old_m[oi].name}ok")
        else:
            pok, _ = _sigs_match(old_m[oi], new_m[ni])
            if pok:
                score += weight_sig
                detail_parts.append(f"{label}-sigok")

    # --- .ctor / .cctor stable anchors in class ---
    for name in (".ctor", ".cctor", "ctor", "cctor"):
        old_ctors = [i for i, m in enumerate(old_m) if m.name in (name, f".{name}" if not name.startswith(".") else name)]
        new_ctors = [i for i, m in enumerate(new_m) if m.name in (name, f".{name}" if not name.startswith(".") else name)]
        # also match exact ".ctor"
        if name.startswith("."):
            old_ctors = [i for i, m in enumerate(old_m) if m.name == name]
            new_ctors = [i for i, m in enumerate(new_m) if m.name == name]
        if old_ctors and new_ctors and abs(old_ctors[0] - new_ctors[0]) <= 1:
            score += 6
            detail_parts.append(f"{name}-anchorok")
            break

    # --- name exact or fuzzy ---
    if src.name == cand.name:
        score += 15
        detail_parts.append("nameok")
    else:
        sim = _name_similarity(src.name, cand.name)
        if sim >= FUZZY_NAME_MIN:
            score += int(10 * sim)
            detail_parts.append(f"fuzzy={sim:.2f} {src.name}->{cand.name}")
        else:
            detail_parts.append(f"renamed {src.name}->{cand.name}")

    # --- method size ---
    sd, sdet = _size_score(src, cand)
    score += sd
    if sdet:
        detail_parts.append(sdet)

    # class size stability
    size_diff = abs(len(old_m) - len(new_m))
    if size_diff == 0:
        score += 8
    elif size_diff <= 2:
        score += 4

    score = max(0, min(score, 98))
    return score, " ".join(detail_parts)



def collect_class_candidates(
    info: MethodInfo,
    old_class_map: Dict[str, List[MethodInfo]],
    new_class_map: Dict[str, List[MethodInfo]],
    claimed_new: Set[int],
    align_delta: int,
) -> List[Tuple[int, int, str, str]]:
    """
    Same-class candidates ranked by:
      1. same index + signature match
      2. nearby index with matching signature (handles inserted methods)
      3. pure positional fallback
    Signature = return type + parameter types inside ().
    """
    results: List[Tuple[int, int, str, str]] = []
    seen_rva: Set[int] = set()
    ck = _class_key(info.ns, info.cls)
    old_m = old_class_map.get(ck) or old_class_map.get(info.cls) or []
    new_m = new_class_map.get(ck) or new_class_map.get(info.cls) or []

    # CPM1: class names re-obfuscated every build - match by structure
    struct_matched = False
    if old_m and (not new_m or is_obfuscated_name(info.cls)):
        hits = structural_class_match(old_m, new_class_map, claimed_new)
        if hits:
            # prefer best structural hit
            best_score, best_ck, best_m = hits[0]
            if not new_m or best_score >= 25:
                new_m = best_m
                ck = best_ck
                struct_matched = True

    if not old_m or not new_m:
        return results

    target_rva = info.rva
    idx = next((i for i, m in enumerate(old_m) if m.rva == target_rva), None)
    if idx is None:
        idx = next((i for i, m in enumerate(old_m) if abs(m.rva - target_rva) <= 8), None)
    if idx is None:
        return results

    def add(conf, rva, strat, detail):
        if rva in claimed_new or rva in seen_rva:
            return
        seen_rva.add(rva)
        results.append((conf, rva, strat, detail))

    # --- same index ---
    # v5.10: if class method count changed a lot, pure positional match is risky
    class_size_diff = abs(len(old_m) - len(new_m))
    if idx < len(new_m):
        conf, detail = _neighbor_score(old_m, new_m, idx, info)
        cand = new_m[idx]
        rva = cand.rva - align_delta if align_delta else cand.rva
        # Require signature or fuzzy when class grew/shrank past threshold
        sig_ok, _ = _sigs_match(info, cand)
        name_sim = _name_similarity(info.name, cand.name)
        if class_size_diff > CLASS_SIZE_DIFF_MAX and not sig_ok and name_sim < FUZZY_NAME_MIN:
            conf = min(conf, APPLY_CONF - 1)  # force SUGGEST only
            detail = f"sized={class_size_diff} {detail}"
            strat = "neighbor-near"
        elif conf >= NEIGHBOR_STRONG_CONF:
            strat = "neighbor-strong"
        else:
            strat = "neighbor-idx"
        add(conf, rva, strat, f"{ck}[{idx}]->{cand.name} ({detail})")

    # --- nearby indices: prefer signature match ---
    for delta in (1, -1, 2, -2, 3, -3, 4, -4):
        j = idx + delta
        if j < 0 or j >= len(new_m):
            continue
        cand = new_m[j]
        rva = cand.rva - align_delta if align_delta else cand.rva
        if rva in claimed_new or rva in seen_rva:
            continue

        conf = max(30, 68 - abs(delta) * 10)
        bits = [f"shift {delta:+d}"]

        sig_ok, sig_detail = _sigs_match(info, cand)
        if sig_ok:
            conf += 28  # big boost: same (int value) etc.
            bits.append(f"sigok{sig_detail}")
            strat = "neighbor-sig"
        else:
            bits.append(f"sig!=")
            strat = "neighbor-near"

        # surrounding name/sig anchors
        if j > 0 and idx > 0:
            if old_m[idx - 1].name == new_m[j - 1].name:
                conf += 10
                bits.append("prevok")
            else:
                pok, _ = _sigs_match(old_m[idx - 1], new_m[j - 1])
                if pok:
                    conf += 6
                    bits.append("prev-sigok")
        if j + 1 < len(new_m) and idx + 1 < len(old_m):
            if old_m[idx + 1].name == new_m[j + 1].name:
                conf += 10
                bits.append("nextok")
            else:
                nok, _ = _sigs_match(old_m[idx + 1], new_m[j + 1])
                if nok:
                    conf += 6
                    bits.append("next-sigok")

        conf = min(conf, 95)
        add(conf, rva, strat, f"{ck}[{idx}->{j}]->{cand.name} ({', '.join(bits)})")
        if len(results) >= MAX_SUGGESTIONS:
            break

    # --- also scan whole class for unique signature match (obfuscated rename + reorder) ---
    if len(results) < MAX_SUGGESTIONS and info.param_count >= 0:
        matches = []
        for j, cand in enumerate(new_m):
            rva = cand.rva - align_delta if align_delta else cand.rva
            if rva in claimed_new or rva in seen_rva:
                continue
            ok, det = _sigs_match(info, cand)
            if not ok:
                continue
            # prefer closer index
            dist = abs(j - idx)
            conf = max(45, 80 - dist * 5)
            matches.append((conf, rva, j, cand, det))
        matches.sort(key=lambda x: -x[0])
        for conf, rva, j, cand, det in matches[:3]:
            if len(results) >= MAX_SUGGESTIONS:
                break
            add(conf, rva, "neighbor-sig",
                f"{ck}[sig-scan {idx}->{j}]->{cand.name} (sigok{det})")

    # --- fuzzy name scan inside same class (rename with similar spelling) ---
    if len(results) < MAX_SUGGESTIONS:
        fuzzy_hits = []
        for j, cand in enumerate(new_m):
            rva = cand.rva - align_delta if align_delta else cand.rva
            if rva in claimed_new or rva in seen_rva:
                continue
            sim = _name_similarity(info.name, cand.name)
            if sim < FUZZY_NAME_MIN or sim >= 0.99:
                continue  # exact handled elsewhere; need real fuzzy
            conf = int(50 + 30 * sim)
            bits = [f"fuzzy={sim:.2f}"]
            sig_ok, sig_detail = _sigs_match(info, cand)
            if sig_ok:
                conf += 20
                bits.append(f"sigok{sig_detail}")
            sd, sdet = _size_score(info, cand)
            conf += sd
            if sdet:
                bits.append(sdet)
            conf = min(conf, 92)
            fuzzy_hits.append((conf, rva, j, cand, " ".join(bits)))
        fuzzy_hits.sort(key=lambda x: -x[0])
        for conf, rva, j, cand, bits in fuzzy_hits[:2]:
            if len(results) >= MAX_SUGGESTIONS:
                break
            add(conf, rva, "neighbor-fuzzy",
                f"{ck}[fuzzy {idx}->{j}]->{cand.name} ({bits})")

    results.sort(key=lambda x: -x[0])
    return results[:MAX_SUGGESTIONS]


# ============================================================================
# MATCH ONE OLD ADDRESS -> NEW ADDRESS (core matching logic)
# ============================================================================
def map_one_rva(
    old_rva,
    old_rva_map,
    new_cm_exact,
    new_meth_only,
    new_sig_index,
    old_class_map,
    new_class_map,
    claimed_new: Set[int],
):
    """
    Find matching new RVA for one old address.
    v5.10: collects multi-strategy votes; agreement boosts confidence.
    Returns: (new_rva, strategy, detail, conf, extras)
    """
    pairs, align_delta, align_note = resolve_in_old(old_rva, old_rva_map)
    if not pairs:
        return None, "none", "no class/method in OLD dump (tried ±0/4/8)", 0, []
    align_suffix = f" | {align_note}" if align_note else ""

    # votes: new_rva -> list of (strategy, conf, detail)
    votes: Dict[int, List[Tuple[str, int, str]]] = defaultdict(list)
    extras: List[Tuple[int, int, str]] = []

    def vote(rva, strat, conf, detail):
        if rva is None or rva <= 0:
            return
        if rva in claimed_new and strat not in ("exact", "method"):
            return
        votes[rva].append((strat, conf, detail))

    # ---- 1 exact ----
    for info in pairs:
        ck = _class_key(info.ns, info.cls)
        for key in ((ck, info.name), (info.cls, info.name)):
            cands = new_cm_exact.get(key)
            if cands:
                rva = cands[0] - align_delta if align_delta else cands[0]
                vote(rva, "exact", 98, f"{ck}::{info.name}{align_suffix}")

    # ---- 2 method name ----
    for info in pairs:
        ck = _class_key(info.ns, info.cls)
        cands = new_meth_only.get(info.name)
        if not cands:
            continue
        same_ck = [(c, r) for c, r in cands if c == ck]
        same_cls = [(c, r) for c, r in cands if c == info.cls or c.endswith("." + info.cls)]
        if same_ck:
            rva = same_ck[0][1] - align_delta if align_delta else same_ck[0][1]
            vote(rva, "method", 92, f"{same_ck[0][0]}::{info.name} (same ns.class){align_suffix}")
        elif same_cls:
            rva = same_cls[0][1] - align_delta if align_delta else same_cls[0][1]
            vote(rva, "method", 90, f"{same_cls[0][0]}::{info.name} (same class){align_suffix}")
        elif len(cands) == 1:
            cls, rva = cands[0]
            rva = rva - align_delta if align_delta else rva
            vote(rva, "method", 85, f"{cls}::{info.name} (unique name){align_suffix}")
        elif len(cands) <= 3:
            cls, rva = cands[0]
            rva = rva - align_delta if align_delta else rva
            vote(rva, "method", 72, f"{cls}::{info.name} (name×{len(cands)}){align_suffix}")

    # ---- 3 same-class neighbor / fuzzy / sig ----
    for info in pairs:
        candidates = collect_class_candidates(
            info, old_class_map, new_class_map, claimed_new, align_delta,
        )
        for conf, rva, strat, detail in candidates:
            vote(rva, strat, conf, f"{detail}{align_suffix}")
            if (rva, conf, detail) not in [(e[0], e[1], e[2]) for e in extras]:
                extras.append((rva, conf, detail))

    # ---- 4 signature (rare / unique preferred) ----
    for info in pairs:
        if not info.sig_key or info.sig_key in _WEAK_SIGS:
            continue
        cands = new_sig_index.get(info.sig_key)
        if not cands or len(cands) > 8:
            continue
        ck = _class_key(info.ns, info.cls)
        old_count = len(old_class_map.get(ck) or old_class_map.get(info.cls) or [])
        scored = []
        for cls, meth, rva in cands:
            if rva in claimed_new:
                continue
            size_score = 100 - abs(len(new_class_map.get(cls, [])) - old_count)
            if info.ns and cls.startswith(info.ns + "."):
                size_score += 15
            # unique in that class?
            cls_methods = new_class_map.get(cls) or []
            uniq = sum(1 for m in cls_methods if m.sig_key == info.sig_key) == 1
            if uniq:
                size_score += 20
            scored.append((size_score, rva, cls, meth, uniq))
        if not scored:
            continue
        scored.sort(reverse=True)
        best_score, rva, cls, meth, uniq = scored[0]
        if best_score < 70:
            continue
        if len(scored) > 1 and scored[0][0] - scored[1][0] < 5:
            continue
        rva = rva - align_delta if align_delta else rva
        conf = 72 if uniq else 60
        vote(rva, "signature", conf, f"{cls}::{meth} sig={info.sig_key}{' uniq' if uniq else ''}{align_suffix}")

    # ---- 5 neighbor-gap (weak) ----
    for info in pairs:
        ck = _class_key(info.ns, info.cls)
        old_m = old_class_map.get(ck) or old_class_map.get(info.cls) or []
        if len(old_m) < 4:
            continue
        target = info.rva
        idx = next((i for i, m in enumerate(old_m) if m.rva == target), None)
        if idx is None or idx == 0:
            continue
        old_gap = old_m[idx].rva - old_m[idx - 1].rva
        for cls_key, methods in new_class_map.items():
            if info.ns and not (cls_key.startswith(info.ns + ".") or cls_key == info.cls):
                if abs(len(methods) - len(old_m)) > 2:
                    continue
            if abs(len(methods) - len(old_m)) > 4 or idx >= len(methods):
                continue
            cand = methods[idx]
            gap = cand.rva - methods[idx - 1].rva
            if abs(gap - old_gap) > 0x30 or cand.rva in claimed_new:
                continue
            rva = cand.rva - align_delta if align_delta else cand.rva
            vote(rva, "neighbor-gap", 40,
                 f"{cls_key}[{idx}]::{cand.name} gap≈{old_gap:#x}{align_suffix}")

    if not votes:
        return None, "missing", f"{pairs[0].cls}::{pairs[0].name}{align_suffix}", 0, []

    # ---- multi-strategy agreement ----
    ranked = []
    for rva, vlist in votes.items():
        strats = {s for s, c, d in vlist}
        best_conf = max(c for s, c, d in vlist)
        best_strat, _, best_detail = max(vlist, key=lambda x: x[1])
        # agreement: neighbor* + signature (or exact/method + something)
        has_neighbor = any(s.startswith("neighbor") for s in strats)
        has_sig = "signature" in strats or any("sig" in s for s in strats)
        has_name = "exact" in strats or "method" in strats
        if len(strats) >= 2 and (has_neighbor and has_sig):
            best_conf = min(98, best_conf + AGREE_BOOST)
            best_strat = "agree"
            best_detail = f"AGREE[{','.join(sorted(strats))}] {best_detail}"
        elif len(strats) >= 2 and has_name:
            best_conf = min(98, best_conf + 6)
            best_detail = f"multi[{','.join(sorted(strats))}] {best_detail}"
        ranked.append((best_conf, rva, best_strat, best_detail, strats))

    ranked.sort(key=lambda x: -x[0])
    best_conf, best_rva, best_strat, best_detail, best_strats = ranked[0]
    for conf, rva, strat, detail, _ in ranked[1:]:
        extras.append((rva, conf, detail))

    return best_rva, best_strat, best_detail, best_conf, extras[:MAX_SUGGESTIONS]



# ============================================================================
# UPDATE THE .LUA SCRIPT with confidently mapped addresses
# ============================================================================
def update_script(
    script_text,
    old_rva_map,
    new_cm_exact,
    new_meth_only,
    new_sig_index,
    old_class_map,
    new_class_map,
    min_off=0x10000,
    max_off=0x80000000,
    old_ranges=None,
    new_ranges=None,
    ida_insns=None,
):
    """
    Rewrite .lua with confidently mapped RVAs.
    v5.10: agreement, safer proximity, consensus, gg.alert for outdated.
    """
    found = extract_candidate_rvas(script_text, min_off, max_off)
    script_hints = extract_script_hints(script_text)
    plus4_pairs = pair_plus4_offsets(found)
    if script_hints:
        log.info("Script method hints for %d offsets", len(script_hints))
    if plus4_pairs:
        log.info("Found %d MOV/+4 RET pairs in script", len(plus4_pairs))
    replacements = {}
    offset_meta = {}  # hex -> {label, old, new, kind, rel} for script comments
    report = []
    stats = {
        "mapped": 0, "same": 0, "missing": 0, "suggested": 0, "total": len(found),
        "by_strategy": defaultdict(int), "high_conf": 0, "low_conf": 0,
        "alerts": 0,
    }
    claimed_new: Set[int] = set()
    pending = sorted(found)
    anchors: List[Tuple[int, int]] = []
    deferred_none: List[int] = []
    # Track all candidates per old_rva for consensus: old -> [(new, conf, strat, detail)]
    all_cands: Dict[int, List[Tuple[int, int, str, str]]] = defaultdict(list)
    suggest_only: Set[int] = set()   # old RVAs only suggested (for alert)
    applied_pairs: List[Tuple[int, int]] = []

    def record_cand(old_rva, new_rva, conf, strat, detail):
        if new_rva is not None:
            all_cands[old_rva].append((new_rva, conf, strat, detail))

    def do_pass(allowed):
        nonlocal pending
        still = []
        for old_rva in pending:
            old_hex = f"0x{old_rva:X}"
            new_rva, strategy, detail, conf, extras = map_one_rva(
                old_rva, old_rva_map, new_cm_exact, new_meth_only, new_sig_index,
                old_class_map, new_class_map, claimed_new,
            )
            # "agree" is accepted in any pass once computed
            if strategy != "agree" and strategy not in allowed:
                still.append(old_rva)
                continue

            stats["by_strategy"][strategy] += 1
            if new_rva is None:
                if strategy == "none":
                    deferred_none.append(old_rva)
                    stats["by_strategy"][strategy] -= 1
                else:
                    report.append(f"{old_hex}  ->  SKIP  [missing]  conf=0  ({detail})")
                    stats["missing"] += 1
                    suggest_only.add(old_rva)
                continue

            record_cand(old_rva, new_rva, conf, strategy, detail)
            for er, ec, ed in extras:
                record_cand(old_rva, er, ec, "alt", ed)

            if strategy in (
                "signature", "neighbor-gap", "neighbor-idx",
                "neighbor-near", "neighbor-strong", "neighbor-sig",
                "neighbor-fuzzy",
            ) and new_rva in claimed_new:
                still.append(old_rva)
                stats["by_strategy"][strategy] -= 1
                continue

            new_hex = f"0x{new_rva:X}"
            how = f"[{strategy}] conf={conf}  how: {detail}"

            # v5.10 apply whitelist - neighbor-near / gap / weak signature = SUGGEST only
            apply = conf >= APPLY_CONF and strategy in (
                "exact", "method", "neighbor-strong", "neighbor-idx",
                "neighbor-sig", "agree", "neighbor-fuzzy", "consensus",
            )
            if strategy == "neighbor-idx" and conf < NEIGHBOR_IDX_CONF:
                apply = False
            if strategy == "neighbor-sig" and conf < 80:
                apply = False
            if strategy == "neighbor-fuzzy" and conf < 82:
                apply = False
            if strategy == "signature" and conf < 75:
                apply = False
            if strategy == "neighbor-near":
                apply = False  # positional only after class size change

            if new_hex.upper() == old_hex.upper():
                full = _store_offset_meta(
                    offset_meta, old_rva, new_rva, old_rva_map, strategy, detail, kind="same"
                )
                report.append(f"{old_hex}  = same  {how}  | {full}")
                stats["same"] += 1
                anchors.append((old_rva, new_rva))
                claimed_new.add(new_rva)
            elif apply:
                replacements[old_hex] = new_hex
                claimed_new.add(new_rva)
                claimed_new.add(new_rva & ~0x3)
                kind = "ida-body" if strategy == "ida-body" else "map"
                rel = ""
                rm = re.search(r"rel=(\+?0x[0-9A-Fa-f]+)", detail or "")
                if rm:
                    rel = rm.group(1)
                full = _store_offset_meta(
                    offset_meta, old_rva, new_rva, old_rva_map, strategy, detail,
                    kind=kind, rel=rel,
                )
                report.append(f"{old_hex}  ->  {new_hex}  [{strategy}] conf={conf}  how: {detail}  | {full}  [APPLIED]")
                stats["mapped"] += 1
                anchors.append((old_rva, new_rva))
                applied_pairs.append((old_rva, new_rva))
            else:
                report.append(f"{old_hex}  ->  {new_hex}  {how}  [SUGGEST only - not applied]")
                stats["suggested"] += 1
                suggest_only.add(old_rva)
                if conf >= 60:
                    anchors.append((old_rva, new_rva))
                for er, ec, ed in extras[:MAX_SUGGESTIONS - 1]:
                    report.append(f"         alt -> 0x{er:X}  conf={ec}  ({ed})")

            if conf >= 80:
                stats["high_conf"] += 1
            elif conf > 0:
                stats["low_conf"] += 1
        pending = still

    do_pass({"exact", "method", "none", "missing", "agree"})
    do_pass({"neighbor-strong", "neighbor-idx", "neighbor-sig", "neighbor-fuzzy", "none", "missing", "agree"})
    do_pass({"neighbor-near", "signature", "none", "missing", "agree"})
    do_pass({"neighbor-gap", "none", "missing", "agree"})

    unresolved = list(pending) + list(deferred_none)

    # ---- IDA body-relative ----
    old_ranges = old_ranges or []
    new_ranges = new_ranges or []
    method_start_map: Dict[int, int] = {}
    for oa, na in anchors:
        method_start_map[oa] = na
    for start_r, end_r, info in old_ranges:
        if start_r in method_start_map:
            continue
        ck = _class_key(info.ns, info.cls)
        for key in ((ck, info.name), (info.cls, info.name)):
            cands = new_cm_exact.get(key)
            if cands:
                method_start_map[start_r] = cands[0]
                break

    still_after_body = []
    for old_rva in unresolved:
        old_hex = f"0x{old_rva:X}"
        encl = find_enclosing_method(old_ranges, old_rva)
        if encl is None:
            still_after_body.append(old_rva)
            continue
        new_start = method_start_map.get(encl.rva)
        if new_start is None:
            ns, st, det, cf, _ = map_one_rva(
                encl.rva, old_rva_map, new_cm_exact, new_meth_only, new_sig_index,
                old_class_map, new_class_map, claimed_new,
            )
            if ns is not None and cf >= 70:
                new_start = ns
                method_start_map[encl.rva] = ns
                anchors.append((encl.rva, ns))
            else:
                still_after_body.append(old_rva)
                continue

        rel = old_rva - encl.rva
        new_rva = new_start + rel
        if new_rva <= 0 or new_rva in claimed_new:
            still_after_body.append(old_rva)
            continue

        # v5.10: CPM scripts often patch +0/+4/+8 (MOV+RET). Reward tight rel.
        if rel == 0:
            conf = 95
        elif rel <= 0x8:
            conf = 93   # +4 / +8 common second instruction
        elif rel <= IDA_BODY_TIGHT_REL:
            conf = 90
        elif rel <= 0x200:
            conf = 84
        elif rel <= 0x1000:
            conf = 78
        else:
            conf = 68

        new_hex = f"0x{new_rva:X}"
        how = (
            f"[ida-body] conf={conf}  how: inside {encl.cls}::{encl.name} "
            f"start 0x{encl.rva:X}->0x{new_start:X}  rel=+{rel:#x}"
        )
        apply = conf >= APPLY_CONF
        stats["by_strategy"]["ida-body"] += 1
        record_cand(old_rva, new_rva, conf, "ida-body", how)
        if apply:
            replacements[old_hex] = new_hex
            claimed_new.add(new_rva)
            claimed_new.add(new_rva & ~0x3)
            report.append(f"{old_hex}  ->  {new_hex}  {how}  [APPLIED]")
            stats["mapped"] += 1
            anchors.append((old_rva, new_rva))
            applied_pairs.append((old_rva, new_rva))
            suggest_only.discard(old_rva)
            kind = "plus4" if rel in (4, 8) else "ida-body"
            _store_offset_meta(
                offset_meta, old_rva, new_rva, {old_rva: [encl]}, "ida-body",
                f"inside {encl.cls}::{encl.name} rel=+{rel:#x}",
                kind=kind, rel=f"+{rel:#x}",
            )
            # keep class/name from enclosing method
            offset_meta[new_hex.upper()]["cls"] = encl.cls
            offset_meta[new_hex.upper()]["name"] = encl.name
            offset_meta[new_hex.upper()]["ns"] = getattr(encl, "ns", "") or ""
            offset_meta[new_hex.upper()]["label"] = f"{encl.cls}::{encl.name}"
            offset_meta[new_hex.upper()]["full"] = _format_method_full(encl)
        else:
            report.append(f"{old_hex}  ->  {new_hex}  {how}  [SUGGEST only - not applied]")
            stats["suggested"] += 1
            suggest_only.add(old_rva)
            anchors.append((old_rva, new_rva))
        if conf >= 80:
            stats["high_conf"] += 1
        else:
            stats["low_conf"] += 1

    unresolved = still_after_body

    # ---- Safer proximity-delta (need 2 anchors, tighter apply dist) ----
    MAX_DELTA_DIST = 0x20000

    def cluster_key(rva: int) -> int:
        return rva >> 12

    by_cluster: Dict[int, List[Tuple[int, int]]] = defaultdict(list)
    for oa, na in anchors:
        by_cluster[cluster_key(oa)].append((oa, na))
    for k in by_cluster:
        by_cluster[k].sort(key=lambda x: x[0])

    unresolved = sorted(set(unresolved))
    changed = True
    rounds = 0
    while unresolved and changed and rounds < 5:
        changed = False
        rounds += 1
        next_unresolved = []
        for old_rva in unresolved:
            old_hex = f"0x{old_rva:X}"
            ck = cluster_key(old_rva)
            candidates = []
            for c in (ck, ck - 1, ck + 1):
                candidates.extend(by_cluster.get(c, []))
            if len(candidates) < PROXIMITY_MIN_ANCHORS:
                next_unresolved.append(old_rva)
                continue

            # nearest + second nearest
            ranked_a = sorted(
                [(abs(oa - old_rva), oa, na) for oa, na in candidates if oa != old_rva]
            )
            if not ranked_a or ranked_a[0][0] > MAX_DELTA_DIST:
                next_unresolved.append(old_rva)
                continue

            best_dist, oa, na = ranked_a[0]
            # require a second supporting anchor reasonably close
            second_ok = len(ranked_a) >= 2 and ranked_a[1][0] <= MAX_DELTA_DIST

            new_rva = na + (old_rva - oa)
            if new_rva <= 0 or new_rva in claimed_new:
                next_unresolved.append(old_rva)
                continue

            delta = old_rva - oa
            delta_s = f"{delta:+#x}" if delta < 0 else f"+{delta:#x}"

            if best_dist <= 0x100:
                conf = 92
            elif best_dist <= 0x800:
                conf = 85
            elif best_dist <= 0x2000:
                conf = 78
            elif best_dist <= 0x8000:
                conf = 68
            else:
                conf = 55

            if not second_ok:
                conf = min(conf, 65)  # demote without 2nd anchor

            new_hex = f"0x{new_rva:X}"
            how = (
                f"[proximity-delta] conf={conf}  how: "
                f"anchor 0x{oa:X}->0x{na:X}  delta={delta_s}  "
                f"(dist={best_dist:#x}, cluster={ck:#x}, anchors={len(candidates)})"
            )
            # Safer: only APPLY if tight distance AND 2 anchors
            apply = (
                conf >= APPLY_CONF
                and second_ok
                and best_dist <= PROXIMITY_APPLY_DIST
            )
            stats["by_strategy"]["proximity-delta"] += 1
            record_cand(old_rva, new_rva, conf, "proximity-delta", how)

            if apply:
                replacements[old_hex] = new_hex
                claimed_new.add(new_rva)
                claimed_new.add(new_rva & ~0x3)
                report.append(f"{old_hex}  ->  {new_hex}  {how}  [APPLIED]")
                stats["mapped"] += 1
                anchors.append((old_rva, new_rva))
                applied_pairs.append((old_rva, new_rva))
                by_cluster[cluster_key(old_rva)].append((old_rva, new_rva))
                by_cluster[cluster_key(old_rva)].sort(key=lambda x: x[0])
                changed = True
                suggest_only.discard(old_rva)
                offset_meta[new_hex.upper()] = {
                    "label": f"near 0x{na:X}", "old": old_hex, "new": new_hex,
                    "kind": "map", "rel": delta_s,
                }
            else:
                report.append(f"{old_hex}  ->  {new_hex}  {how}  [SUGGEST only - not applied]")
                stats["suggested"] += 1
                suggest_only.add(old_rva)
                anchors.append((old_rva, new_rva))
                by_cluster[cluster_key(old_rva)].append((old_rva, new_rva))

            if conf >= 80:
                stats["high_conf"] += 1
            else:
                stats["low_conf"] += 1
        unresolved = next_unresolved

    # ---- Consensus pass: same new RVA from 2+ strategies -> promote ----
    still_consensus = []
    for old_rva in list(unresolved) + list(suggest_only):
        if f"0x{old_rva:X}" in replacements:
            continue
        cands = all_cands.get(old_rva) or []
        if not cands:
            still_consensus.append(old_rva)
            continue
        # count votes per new_rva
        tally: Dict[int, List[Tuple[int, str, str]]] = defaultdict(list)
        for nr, conf, strat, detail in cands:
            tally[nr].append((conf, strat, detail))
        # Only consensus-promote if at least one STRONG strategy is present.
        # neighbor-near / alt alone must stay SUGGEST (avoids CPMEngine.Utils false hits).
        STRONG = {
            "exact", "method", "agree", "neighbor-strong", "neighbor-sig",
            "neighbor-fuzzy", "signature", "ida-body", "script-hint",
        }
        best = None
        for nr, vlist in tally.items():
            strats = {s for _, s, _ in vlist}
            if not (strats & STRONG):
                continue  # only weak (neighbor-near / gap / alt) -> never auto-apply
            if len(strats) >= CONSENSUS_MIN_STRATS or len(vlist) >= CONSENSUS_MIN_STRATS:
                top_conf = max(c for c, s, d in vlist) + AGREE_BOOST
                top_conf = min(top_conf, 96)
                detail = f"CONSENSUS[{','.join(sorted(strats))}] " + vlist[0][2]
                if best is None or top_conf > best[0]:
                    best = (top_conf, nr, detail, strats)
        if best and best[0] >= APPLY_CONF and best[1] not in claimed_new:
            conf, new_rva, detail, strats = best
            old_hex = f"0x{old_rva:X}"
            new_hex = f"0x{new_rva:X}"
            how = f"[consensus] conf={conf}  how: {detail}"
            replacements[old_hex] = new_hex
            claimed_new.add(new_rva)
            report.append(f"{old_hex}  ->  {new_hex}  {how}  [APPLIED]")
            stats["mapped"] += 1
            stats["by_strategy"]["consensus"] += 1
            anchors.append((old_rva, new_rva))
            _store_offset_meta(
                offset_meta, old_rva, new_rva, old_rva_map, "consensus", detail
            )
            applied_pairs.append((old_rva, new_rva))
            suggest_only.discard(old_rva)
            if old_rva in unresolved:
                unresolved.remove(old_rva)
        else:
            still_consensus.append(old_rva)

    for old_rva in unresolved:
        if f"0x{old_rva:X}" in replacements:
            continue
        report.append(
            f"0x{old_rva:X}  ->  SKIP  [unresolved]  "
            f"(no class/method and no nearby mapped anchor within {MAX_DELTA_DIST:#x})"
        )
        stats["missing"] += 1
        stats["by_strategy"]["unresolved"] += 1
        suggest_only.add(old_rva)

    # ---- Propagate +4 RET pairs (CPM1 MOV at X, RET at X+4) ----
    extra_pairs = []
    for start_old, plus_old in plus4_pairs.items():
        start_hex = f"0x{start_old:X}"
        plus_hex = f"0x{plus_old:X}"
        if start_hex in replacements and plus_hex not in replacements:
            new_start = int(replacements[start_hex], 16)
            new_plus = new_start + 4
            if new_plus not in claimed_new:
                replacements[plus_hex] = f"0x{new_plus:X}"
                claimed_new.add(new_plus)
                extra_pairs.append((plus_old, new_plus))
                report.append(
                    f"{plus_hex}  ->  0x{new_plus:X}  [plus4-pair] conf=94  "
                    f"how: RET after mapped MOV 0x{start_old:X}->0x{new_start:X}  [APPLIED]"
                )
                parent = offset_meta.get(f"0x{new_start:X}".upper(), {})
                plabel = parent.get("label") or f"0x{new_start:X}"
                offset_meta[f"0x{new_plus:X}".upper()] = {
                    "label": plabel, "old": plus_hex, "new": f"0x{new_plus:X}",
                    "kind": "plus4", "rel": "+0x4",
                }
                stats["mapped"] += 1
                stats["by_strategy"]["plus4-pair"] += 1
                suggest_only.discard(plus_old)
                applied_pairs.append((plus_old, new_plus))
        elif plus_hex in replacements and start_hex not in replacements:
            new_plus = int(replacements[plus_hex], 16)
            new_start = new_plus - 4
            if new_start > 0 and new_start not in claimed_new:
                replacements[start_hex] = f"0x{new_start:X}"
                claimed_new.add(new_start)
                report.append(
                    f"{start_hex}  ->  0x{new_start:X}  [plus4-pair] conf=94  "
                    f"how: MOV before mapped RET 0x{plus_old:X}->0x{new_plus:X}  [APPLIED]"
                )
                stats["mapped"] += 1
                stats["by_strategy"]["plus4-pair"] += 1
                suggest_only.discard(start_old)
                applied_pairs.append((start_old, new_start))

    # ---- Script comment/name hints boost (already mapped get priority; unmapped try name) ----
    for old_rva, names in script_hints.items():
        old_hex = f"0x{old_rva:X}"
        if old_hex in replacements:
            continue
        # Prefer real method-like tokens (skip Indonesian comments / noise)
        noise = {
            "disable", "check", "patch", "public", "static", "int", "void",
            "offset", "local", "true", "false", "null", "tendangan", "penumpang",
            "kursi", "tambahan", "the", "and", "for", "room",
        }
        ranked = []
        for hint in names:
            if hint.lower() in noise or len(hint) < 3:
                continue
            score = 0
            if hint in STABLE_METHODS:
                score += 50
            if hint[0].isupper() or "_" in hint:
                score += 20
            if not is_obfuscated_name(hint):
                score += 10
            ranked.append((score, hint))
        ranked.sort(reverse=True)
        for _, hint in ranked:
            # stable or readable name
            cands = new_meth_only.get(hint) or []
            if not cands:
                # try case-insensitive / strip prefixes
                for k, v in new_meth_only.items():
                    if k.lower() == hint.lower():
                        cands = v
                        break
            if len(cands) == 1:
                cls, nrva = cands[0]
                if nrva in claimed_new:
                    continue
                conf = 88 if hint in STABLE_METHODS else 80
                replacements[old_hex] = f"0x{nrva:X}"
                claimed_new.add(nrva)
                report.append(
                    f"{old_hex}  ->  0x{nrva:X}  [script-hint] conf={conf}  "
                    f"how: script label/comment '{hint}' -> {cls}::{hint}  [APPLIED]"
                )
                offset_meta[f"0x{nrva:X}".upper()] = {
                    "label": f"{cls}::{hint}" if cls else hint,
                    "full": f"{cls}::{hint}" if cls else hint,
                    "ns": "", "cls": cls, "name": hint,
                    "ret": "", "params": "",
                    "old": old_hex, "new": f"0x{nrva:X}",
                    "kind": "map", "rel": "",
                    "strategy": "script-hint", "detail": f"script label '{hint}'",
                }
                stats["mapped"] += 1
                stats["by_strategy"]["script-hint"] += 1
                suggest_only.discard(old_rva)
                applied_pairs.append((old_rva, nrva))
                anchors.append((old_rva, nrva))
                break
            elif 2 <= len(cands) <= 3:
                cls, nrva = cands[0]
                if nrva in claimed_new:
                    continue
                report.append(
                    f"{old_hex}  ->  0x{nrva:X}  [script-hint] conf=65  "
                    f"how: script '{hint}' ×{len(cands)} candidates  [SUGGEST only - not applied]"
                )
                stats["suggested"] += 1
                record_cand(old_rva, nrva, 65, "script-hint", hint)

    # Apply hex replacements
    new_text = script_text
    for old_hex, new_hex in sorted(replacements.items(), key=lambda x: -len(x[0])):
        new_text = re.sub(rf"\b{re.escape(old_hex)}\b", new_hex, new_text, flags=re.I)

    # Fill missing meta from old dump (cache / proximity / etc. may have skipped names)
    for oh, nh in list(replacements.items()):
        key_u = nh.upper() if isinstance(nh, str) else f"0x{nh:X}".upper()
        if key_u in offset_meta and offset_meta[key_u].get("label") not in ("", "cached", "offset", "consensus", "map"):
            continue
        try:
            old_i = int(oh, 16)
        except ValueError:
            continue
        infos = old_rva_map.get(old_i) or old_rva_map.get(old_i & ~3)
        lbl = ""
        if infos:
            info = infos[0] if isinstance(infos, (list, tuple)) else infos
            lbl = f"{getattr(info,'cls','?')}::{getattr(info,'name','?')}"
        if not lbl:
            # try new dump at new rva
            try:
                new_i = int(nh, 16) if isinstance(nh, str) else int(nh)
            except ValueError:
                new_i = 0
            # old_rva_map only - name from detail in report not available here
            pass
        existing = offset_meta.get(key_u, {})
        offset_meta[key_u] = {
            "label": lbl or existing.get("label") or "offset",
            "old": oh,
            "new": nh if isinstance(nh, str) else f"0x{nh:X}",
            "kind": existing.get("kind") or ("same" if oh.upper() == str(nh).upper() else "map"),
            "rel": existing.get("rel") or "",
        }

    # Name comments next to offsets (Class::Method | was 0xOLD / +4 / unchanged)
    try:
        new_text = annotate_offset_names(new_text, offset_meta)
        log.info("Offset name comments applied: %d", len(offset_meta))
    except Exception as e:
        log.warning("Offset name annotate skipped: %s", e)

    # Annotate known ARM64 patch hex with readable comments (MOV/RET/NOP/…)
    try:
        rva_meth = build_rva_method_lookup(old_rva_map)
        ida_bytes = ida_insns or {}
        if ida_bytes:
            log.info("IDA insn bytes available: %d", len(ida_bytes))
        new_text = annotate_arm64_patches(
            new_text, rva_methods=rva_meth, ida_insns=ida_bytes
        )
        log.info("ARM64 comments: patch meaning + dump method + IDA when available")
    except Exception as e:
        log.warning("ARM64 annotate skipped: %s", e)

    # Inject gg.alert for outdated / unresolved offsets
    outdated = sorted(suggest_only | set(unresolved))
    # only those still present as old hex in script (not replaced)
    still_in_script = []
    for o in outdated:
        hx = f"0x{o:X}"
        if hx in replacements:
            continue
        if re.search(rf"\b{re.escape(hx)}\b", new_text, re.I):
            still_in_script.append(o)

    if still_in_script:
        stats["alerts"] = len(still_in_script)
        preview = ", ".join(f"0x{x:X}" for x in still_in_script[:8])
        if len(still_in_script) > 8:
            preview += f", … (+{len(still_in_script)-8} more)"
        alert_block = (
            "--[[ CPM Offset Bot v5.10: some offsets could not be mapped confidently ]]\n"
            "pcall(function()\n"
            "  gg.alert('offset is outdated\\n"
            f"Unmapped: {preview}')\n"
            "end)\n\n"
        )
        # Insert after shebang / first comment block if present, else at top
        if new_text.lstrip().startswith("--"):
            # after first line
            nl = new_text.find("\n")
            if nl > 0:
                new_text = new_text[:nl+1] + alert_block + new_text[nl+1:]
            else:
                new_text = alert_block + new_text
        else:
            new_text = alert_block + new_text
        report.append(
            f"ALERT injected: gg.alert for {len(still_in_script)} outdated offset(s): {preview}"
        )

    # Save cache

    # ---- Presentable grouped report (ASCII, spaced, dump details) ----
    MATCH_HIERARCHY = """
HOW MATCHING WORKS (strongest -> weakest)
-----------------------------------------
  1. Exact        Namespace + Class + Method name
  2. Method       Same method name in the same class
  3. Agree        Neighbor + signature both point to same new RVA
  4. Neighbor     Strong neighbor (+/-2, .ctor, size) if class size stable
  5. Signature    Unique return+params in class (+ fuzzy name)
  6. IDA-body     Mid-function patch via method start (+0/+4/+8...)
  7. Proximity    Hex math from 2 nearby mapped anchors (tight dist)
  8. Consensus    Same new RVA from 2+ strong strategies
"""

    def _info_from_meta(line: str) -> dict:
        # Normalize meta keys once
        def nk(s):
            s = str(s).strip()
            if s.lower().startswith("0x"):
                return "0x" + s[2:].upper()
            return "0x" + s.upper()
        # Try all hexes on the line against offset_meta
        for m in re.finditer(r"0x([0-9A-Fa-f]+)", line):
            hx = nk(m.group(0))
            if hx in offset_meta:
                return offset_meta[hx]
            # also try as old key stored inside values
            for v in offset_meta.values():
                if isinstance(v, dict) and nk(v.get("old", "")) == hx:
                    return v
                if isinstance(v, dict) and nk(v.get("new", "")) == hx:
                    return v
        return {}

    def _pretty_line(line: str) -> str:
        info = _info_from_meta(line)
        m = re.search(
            r"(0x[0-9A-Fa-f]+)\s*(->|->|=)\s*(0x[0-9A-Fa-f]+|same)?\s*"
            r"(?:\[([^\]]+)\])?\s*"
            r"(?:conf=(\d+))?\s*"
            r"(?:how:\s*(.*?))?\s*"
            r"(?:\|\s*([^\[{]+))?\s*"
            r"(\[APPLIED\]|\[SUGGEST[^\]]*\]|\[unresolved\]|\[missing\])?",
            line,
            re.I,
        )
        if not m:
            return "  " + line.strip()

        old_h = m.group(1)
        arrow = m.group(2)
        new_h = m.group(3) or ""
        strat = m.group(4) or (info.get("strategy") or "")
        conf = m.group(5) or ""
        how = (m.group(6) or "").strip()
        how = re.sub(r"\s*\[(APPLIED|SUGGEST[^\]]*)\]\s*$", "", how).strip()
        full_from_line = (m.group(7) or "").strip()
        flag = m.group(8) or ""

        if how.lower() in ("mapping cache", "cache", ""):
            how = (info.get("detail") or "").strip()
        if len(how) > 100:
            how = how[:97] + "..."

        # Names from meta / line
        ns = info.get("ns") or ""
        cls = info.get("cls") or ""
        name = info.get("name") or ""
        ret = info.get("ret") or ""
        params = info.get("params")
        full = info.get("full") or full_from_line or info.get("label") or ""
        if not full and (cls or name):
            full = f"{ns + '.' if ns else ''}{cls}::{name}" if cls else name

        lines_out = []
        if full:
            lines_out.append(f"  Method   : {full}")
        if ns or cls or name:
            if ns:
                lines_out.append(f"  Namespace: {ns}")
            if cls:
                lines_out.append(f"  Class    : {cls}")
            if name:
                lines_out.append(f"  Name     : {name}")
        if ret or params != "" and params is not None:
            sig_bits = []
            if ret:
                sig_bits.append(f"ret={ret}")
            if params != "" and params is not None:
                sig_bits.append(f"params={params}")
            if sig_bits:
                lines_out.append(f"  Signature: {', '.join(sig_bits)}")

        if new_h and arrow in ("->", "->"):
            lines_out.append(f"  Offset   : {old_h}  -->  {new_h}")
        elif arrow == "=" or (new_h and new_h.lower() == "same"):
            lines_out.append(f"  Offset   : {old_h}  (unchanged)")
        else:
            lines_out.append(f"  Offset   : {old_h}  {arrow}  {new_h}".rstrip())

        if info.get("rel"):
            lines_out.append(f"  Rel      : {info['rel']}  (inside method body / +N patch)")

        meta_bits = []
        if strat:
            meta_bits.append(strat)
        if conf:
            meta_bits.append(f"conf={conf}")
        if flag:
            meta_bits.append(flag.strip("[]"))
        if meta_bits:
            lines_out.append(f"  Match    : {' | '.join(meta_bits)}")
        if how:
            lines_out.append(f"  Why      : {how}")

        return "\n".join(lines_out) if lines_out else ("  " + line.strip())

    applied_lines, suggest_lines, skip_lines, other_lines = [], [], [], []
    for line in report:
        u = line.upper()
        if "[APPLIED]" in u:
            applied_lines.append(line)
        elif "[SUGGEST" in u:
            suggest_lines.append(line)
        elif "SKIP" in u or "UNRESOLVED" in u or "ALERT" in u:
            skip_lines.append(line)
        else:
            other_lines.append(line)

    def _sort_key(s: str):
        m = re.search(r"0x([0-9A-Fa-f]+)", s)
        return int(m.group(1), 16) if m else 0

    applied_lines.sort(key=_sort_key)
    suggest_lines.sort(key=_sort_key)
    skip_lines.sort(key=_sort_key)

    strat_lines = "\n".join(
        f"    {k:16}: {v}" for k, v in sorted(stats["by_strategy"].items())
    )

    def section(title: str, lines: list, pretty: bool = True) -> str:
        bar = "-" * max(len(title), 40)
        if not lines:
            return f"{title}\n{bar}\n  (none)\n"
        body = []
        for i, ln in enumerate(lines):
            if pretty and "0x" in ln and "ALERT" not in ln.upper():
                body.append(_pretty_line(ln))
            else:
                body.append("  " + ln.strip())
            if i < len(lines) - 1:
                body.append("")  # blank line between entries
        return f"{title}\n{bar}\n" + "\n".join(body) + "\n"

    report_text = (
        ("=" * 64) + "\n"
        + "  OFFSET MAPPING REPORT  -  v5.10\n"
        + ("=" * 64) + "\n"
        + "\n"
        + MATCH_HIERARCHY + "\n"
        + "SUMMARY\n"
        + "-------\n"
        + f"  Candidates scanned : {stats['total']}\n"
        + f"  APPLIED to script  : {stats['mapped']}\n"
        + f"  Unchanged (same)   : {stats['same']}\n"
        + f"  SUGGEST only       : {stats['suggested']}  <- review these\n"
        + f"  Skipped / missing  : {stats['missing']}\n"
        + f"  High confidence    : {stats['high_conf']}\n"
        + f"  Low confidence     : {stats['low_conf']}\n"
        + f"  gg.alert injected  : {stats['alerts']} outdated offset(s)\n"
        + "\n"
        + "BY STRATEGY\n"
        + "-----------\n"
        + f"{strat_lines}\n"
        + "\n"
        + f"Rules: apply if conf >= {APPLY_CONF}\n"
        + f"        proximity needs {PROXIMITY_MIN_ANCHORS}+ anchors,"
        + f" dist <= {PROXIMITY_APPLY_DIST:#x}\n"
        + "\n"
        + section("APPLIED (written into script)", applied_lines)
        + "\n"
        + section("SUGGEST (not written - check manually)", suggest_lines)
        + "\n"
        + section("SKIPPED / ALERTS", skip_lines, pretty=False)
        + (("\n" + section("OTHER", other_lines, pretty=False)) if other_lines else "")
        + "\n"
        + ("=" * 64) + "\n"
        + "End of report\n"
    )

    return new_text, report_text, stats



# ============================================================================
def _upload_catbox(path: Path) -> Optional[str]:
    """Anonymous link via catbox.moe."""
    try:
        import urllib.request
        import uuid
        boundary = "----BotBoundary" + uuid.uuid4().hex[:12]
        data = path.read_bytes()
        body = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="reqtype"\r\n\r\n'
            f"fileupload\r\n"
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="fileToUpload"; filename="{path.name}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n"
        ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
        req = urllib.request.Request(
            "https://catbox.moe/user/api.php",
            data=body,
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            url = resp.read().decode("utf-8", errors="replace").strip()
        if url.startswith("http"):
            return url
        log.warning("catbox: %s", url[:200])
    except Exception as e:
        log.warning("catbox failed: %s", e)
    return None


def _upload_litterbox(path: Path, hours: int = 72) -> Optional[str]:
    """Anonymous temp link via litterbox (1/12/24/72h)."""
    try:
        import urllib.request
        import uuid
        boundary = "----BotBoundary" + uuid.uuid4().hex[:12]
        data = path.read_bytes()
        time_val = str(hours) if hours in (1, 12, 24, 72) else "72"
        body = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="reqtype"\r\n\r\n'
            f"fileupload\r\n"
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="time"\r\n\r\n'
            f"{time_val}h\r\n"
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="fileToUpload"; filename="{path.name}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n"
        ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
        req = urllib.request.Request(
            "https://litterbox.catbox.moe/resources/internals/api.php",
            data=body,
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            url = resp.read().decode("utf-8", errors="replace").strip()
        if url.startswith("http"):
            return url
        log.warning("litterbox: %s", url[:200])
    except Exception as e:
        log.warning("litterbox failed: %s", e)
    return None


def _upload_mediafire(path: Path) -> Optional[str]:
    """MediaFire account upload. Requires MEDIAFIRE_EMAIL + MEDIAFIRE_PASSWORD."""
    if not MEDIAFIRE_EMAIL or not MEDIAFIRE_PASSWORD:
        return None
    try:
        from mediafire import MediaFireApi, MediaFireUploader
        api = MediaFireApi()
        session = api.user_get_session_token(
            email=MEDIAFIRE_EMAIL,
            password=MEDIAFIRE_PASSWORD,
            app_id=MEDIAFIRE_APP_ID,
        )
        api.session = session
        uploader = MediaFireUploader(api)
        with open(path, "rb") as fd:
            result = uploader.upload(fd, path.name)
        qk = getattr(result, "quickkey", None) or getattr(result, "quick_key", None)
        if not qk and isinstance(result, dict):
            qk = result.get("quickkey") or result.get("quick_key")
        if qk:
            return f"https://www.mediafire.com/file/{qk}/{path.name}"
        log.warning("mediafire no quickkey: %r", result)
    except ImportError:
        log.warning("Install mediafire: pip install mediafire")
    except Exception as e:
        log.warning("mediafire failed: %s", e)
    return None


def upload_file_get_link(path: Path):
    """Return (url, host). Prefer MediaFire if creds set, else catbox, else litterbox."""
    host = LINK_HOST
    if host == "mediafire":
        order = ["mediafire", "catbox", "litterbox"]
    elif host == "catbox":
        order = ["catbox", "litterbox", "mediafire"]
    elif host == "litterbox":
        order = ["litterbox", "catbox", "mediafire"]
    else:
        order = (
            ["mediafire", "catbox", "litterbox"]
            if (MEDIAFIRE_EMAIL and MEDIAFIRE_PASSWORD)
            else ["catbox", "litterbox", "mediafire"]
        )
    for h in order:
        if h == "mediafire":
            url = _upload_mediafire(path)
        elif h == "catbox":
            url = _upload_catbox(path)
        else:
            url = _upload_litterbox(path)
        if url:
            return url, h
    return None, "none"


def allowed(update: Update) -> bool:
    if not ALLOWED_IDS:
        return True
    uid = update.effective_user.id if update.effective_user else 0
    return uid in ALLOWED_IDS


def cleanup(*paths):
    for p in paths:
        if not p:
            continue
        path = Path(p)
        if path.exists():
            try:
                if path.is_dir():
                    import shutil
                    shutil.rmtree(path, ignore_errors=True)
                else:
                    path.unlink()
            except OSError:
                pass


URL_RE = re.compile(r"https?://[^\s<>\"']+", re.I)

# MediaFire / large-file limits (server-side download, not Telegram)
MAX_URL_DOWNLOAD = int(os.environ.get("MAX_URL_DOWNLOAD_MB", "800")) * 1024 * 1024


def _http_download(url: str, dest: Path, timeout: int = 600) -> Path:
    """Stream download URL to dest. Follows redirects."""
    import urllib.request
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            ),
            "Accept": "*/*",
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        cl = resp.headers.get("Content-Length")
        if cl and int(cl) > MAX_URL_DOWNLOAD:
            raise ValueError(
                f"Remote file too large ({int(cl)/1e6:.0f} MB). "
                f"Max {MAX_URL_DOWNLOAD/1e6:.0f} MB (set MAX_URL_DOWNLOAD_MB)."
            )
        # filename from content-disposition or url
        written = 0
        with open(dest, "wb") as out:
            while True:
                chunk = resp.read(1024 * 1024)
                if not chunk:
                    break
                written += len(chunk)
                if written > MAX_URL_DOWNLOAD:
                    out.close()
                    dest.unlink(missing_ok=True)
                    raise ValueError(
                        f"Download exceeded {MAX_URL_DOWNLOAD/1e6:.0f} MB limit."
                    )
                out.write(chunk)
    if dest.stat().st_size < 100:
        raise ValueError("Downloaded file is empty/too small - bad link?")
    return dest


def resolve_mediafire_url(url: str) -> str:
    """
    Try to turn a MediaFire share page into a direct download URL.
    Direct download*.mediafire.com links are returned as-is.
    """
    if "download" in url and "mediafire.com" in url:
        return url
    if "mediafire.com/file/" not in url and "mediafire.com/download/" not in url:
        return url
    try:
        import urllib.request
        import html as html_mod
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                ),
            },
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            page = resp.read().decode("utf-8", errors="ignore")
        # common patterns for direct link on MF page
        patterns = [
            r'href="(https://download\d*\.mediafire\.com/[^"]+)"',
            r'"(https://download\d*\.mediafire\.com/[^"]+)"',
            r"aria-label=\"Download file\"[^>]*href=\"([^\"]+)\"",
            r'id="downloadButton"[^>]*href="([^"]+)"',
        ]
        for pat in patterns:
            m = re.search(pat, page, re.I)
            if m:
                link = html_mod.unescape(m.group(1))
                if link.startswith("http"):
                    return link
        log.warning("Could not resolve MediaFire direct link from page")
    except Exception as e:
        log.warning("MediaFire resolve failed: %s", e)
    return url


def resolve_gdrive_url(url: str) -> str:
    """Convert Google Drive share/view link to direct download if possible."""
    m = re.search(r"drive\.google\.com/file/d/([^/]+)", url)
    if m:
        return f"https://drive.google.com/uc?export=download&id={m.group(1)}"
    m = re.search(r"[?&]id=([a-zA-Z0-9_-]+)", url)
    if m and "drive.google.com" in url:
        return f"https://drive.google.com/uc?export=download&id={m.group(1)}"
    return url


def extract_dump_from_zip(zip_path: Path) -> Path:
    """
    Extract only dump.cs (or largest .cs) from ZIP - do NOT unpack entire 500MB tree.
    """
    extract_dir = Path(tempfile.mkdtemp(prefix="dump_"))
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            names = zf.namelist()
            # prefer dump.cs
            preferred = [n for n in names if n.lower().endswith("dump.cs") or n.lower().endswith("/dump.cs")]
            if not preferred:
                preferred = [n for n in names if n.lower().endswith(".cs")]
            if not preferred:
                preferred = [n for n in names if n.lower().endswith(".txt")]
            if not preferred:
                cleanup(extract_dir)
                raise ValueError("ZIP has no dump.cs / .cs / .txt")

            # pick largest candidate (real dumps are huge)
            def member_size(n):
                info = zf.getinfo(n)
                return info.file_size

            preferred.sort(key=member_size, reverse=True)
            target = preferred[0]
            # extract only this member
            zf.extract(target, extract_dir)
            out = extract_dir / target
            # zip may use nested folders
            if not out.exists():
                found = list(extract_dir.rglob(Path(target).name))
                if found:
                    out = found[0]
            if not out.exists():
                cleanup(extract_dir)
                raise ValueError(f"Failed to extract {target}")
            log.info(
                "Extracted only %s (%.1f MB) from zip - skipped full unpack",
                out.name, out.stat().st_size / 1e6,
            )
            return out
    except zipfile.BadZipFile:
        cleanup(extract_dir)
        raise ValueError("Invalid ZIP")


# ============================================================================
# DOWNLOAD HELPERS (Telegram file or URL)
# ============================================================================
async def download_from_url(url: str) -> Path:
    """Download large dump from URL (MediaFire / Drive / direct). No 20MB TG limit."""
    url = url.strip().rstrip(".,);]")
    if "mediafire.com" in url:
        url = resolve_mediafire_url(url)
    if "drive.google.com" in url:
        url = resolve_gdrive_url(url)

    # guess extension
    suffix = ".bin"
    lower = url.lower().split("?")[0]
    for ext in (".zip", ".cs", ".txt", ".lua"):
        if lower.endswith(ext):
            suffix = ext
            break
    if "mediafire.com" in lower and suffix == ".bin":
        suffix = ".zip"  # dumps are usually zipped on MF

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    tmp_path = Path(tmp.name)
    tmp.close()
    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, _http_download, url, tmp_path)
    except Exception:
        cleanup(tmp_path)
        raise

    if suffix == ".zip" or zipfile.is_zipfile(tmp_path):
        try:
            extracted = extract_dump_from_zip(tmp_path)
            cleanup(tmp_path)
            return extracted
        except Exception:
            cleanup(tmp_path)
            raise
    return tmp_path


async def download_and_extract(doc: Document) -> Path:
    size = doc.file_size or 0
    name = (doc.file_name or "file").lower()
    if size > MAX_TG_DOWNLOAD:
        raise ValueError(
            f"Telegram limit is 20 MB (yours: {size/1e6:.1f} MB).\n"
            "Upload the ZIP to MediaFire / Drive and send the LINK instead."
        )
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=Path(name).suffix or ".bin")
    tmp_path = Path(tmp.name)
    tmp.close()
    try:
        tg_file = await doc.get_file()
        await tg_file.download_to_drive(custom_path=str(tmp_path))
    except BadRequest as e:
        cleanup(tmp_path)
        if "too big" in str(e).lower():
            raise ValueError(
                "File too big for Telegram (20 MB).\n"
                "Upload to MediaFire and send the URL here."
            ) from e
        raise
    if name.endswith(".zip") or zipfile.is_zipfile(tmp_path):
        try:
            extracted = extract_dump_from_zip(tmp_path)
            cleanup(tmp_path)
            return extracted
        except Exception:
            cleanup(tmp_path)
            raise
    return tmp_path


def make_updated_name(original_name: str) -> str:
    stem = Path(original_name or "script.lua").stem
    if stem.upper().endswith("_UPDATED"):
        stem = stem[: -len("_UPDATED")]
    return f"{stem}_UPDATED.lua"


async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE):
    if isinstance(context.error, Forbidden):
        log.warning("User blocked bot")
    else:
        log.error(f"Error: {context.error}")


# ============================================================================
# TELEGRAM COMMAND HANDLERS
# ============================================================================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not allowed(update):
        await update.message.reply_text("Not authorized.")
        return
    cleanup(
        context.user_data.get("old_dump"), context.user_data.get("new_dump"),
        context.user_data.get("old_dir"), context.user_data.get("new_dir"),
    )
    context.user_data.clear()
    context.user_data["step"] = "old_dump"
    await update.message.reply_text(
        "CPM Offset Updater v5.10\n\n"
        "Match: Namespace -> Class -> Method -> Signature() -> Neighbor\n\n"
        "Telegram max file = 20 MB.\n"
        "Normal dump (~6–50MB) OR IDA dump (~70MB zip / 500MB cs).\n"
        "For big files: MediaFire link (bot downloads server-side).\n"
        "IDA dumps: skips disassembly, keeps // RVA + |-RVA offsets.\n\n"
        "1. OLD dump  2. NEW dump  3. .lua\n"
        f"Delivery: {SEND_MODE} | host: {LINK_HOST}\n\n"
        "Send OLD dump FILE or URL now.\n/cancel"
    )


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cleanup(
        context.user_data.get("old_dump"), context.user_data.get("new_dump"),
        context.user_data.get("old_dir"), context.user_data.get("new_dir"),
    )
    context.user_data.clear()
    await update.message.reply_text("Cancelled. /start again.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        if not allowed(update):
            return
        step = context.user_data.get("step")
        if not step:
            await update.message.reply_text("Send /start to begin.")
            return
        # Accept Telegram file OR a URL (for dumps >20 MB)
        text = (update.message.text or "").strip()
        doc = update.message.document
        url_match = URL_RE.search(text) if text else None
        url = url_match.group(0) if url_match else None

        async def obtain_path(label: str, expect_script: bool = False):
            """Get Path from document or URL."""
            if url:
                await update.message.reply_text(
                    f"Downloading {label} from URL (can be 70MB+)...\n"
                    "This may take a few minutes."
                )
                path = await download_from_url(url)
                return path, Path(url.split("?")[0]).name or label
            if doc:
                name = (doc.file_name or "").lower()
                if expect_script:
                    if not (name.endswith(".lua") or name.endswith(".txt")):
                        raise ValueError("Send the .lua script (file or URL).")
                else:
                    if not (name.endswith((".cs", ".txt", ".zip")) or "dump" in name):
                        raise ValueError(
                            "Send dump as .cs / .zip file, or a MediaFire/Drive URL.\n"
                            "Telegram max = 20 MB - use a link for bigger ZIPs."
                        )
                await update.message.reply_text(f"Downloading {label} from Telegram...")
                path = await download_and_extract(doc)
                return path, doc.file_name or label
            raise ValueError(
                f"Send a file or a URL for {label}.\n"
                "Example: https://www.mediafire.com/file/xxxx/dump.zip"
            )

        if step == "old_dump":
            try:
                path, fname = await obtain_path("OLD dump")
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            except Exception as e:
                await update.message.reply_text(f"Download failed: {e}")
                return
            context.user_data["old_dump"] = str(path)
            if path.parent.name.startswith("dump_"):
                context.user_data["old_dir"] = str(path.parent)
            context.user_data["step"] = "new_dump"
            await update.message.reply_text(
                f"OLD OK ({path.stat().st_size/1e6:.1f} MB) - {path.name}\n\n"
                "Send NEW dump (file or URL)."
            )
            return

        if step == "new_dump":
            try:
                path, fname = await obtain_path("NEW dump")
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            except Exception as e:
                await update.message.reply_text(f"Download failed: {e}")
                return
            context.user_data["new_dump"] = str(path)
            if path.parent.name.startswith("dump_"):
                context.user_data["new_dir"] = str(path.parent)
            context.user_data["step"] = "script"
            await update.message.reply_text(
                f"NEW OK ({path.stat().st_size/1e6:.1f} MB) - {path.name}\n\n"
                "Send .lua script (file or URL)."
            )
            return

        if step == "script":
            script_path = None
            try:
                if doc:
                    out_name = make_updated_name(doc.file_name or "script.lua")
                elif url:
                    out_name = make_updated_name(Path(url.split("?")[0]).name or "script.lua")
                else:
                    out_name = "script_UPDATED.lua"
                status = await update.message.reply_text("Downloading script...")
                script_path, _ = await obtain_path("script", expect_script=True)
            except Exception as e:
                await update.message.reply_text(f"Script download failed: {e}")
                return
            old_path = Path(context.user_data["old_dump"])
            new_path = Path(context.user_data["new_dump"])
            try:
                loop = asyncio.get_event_loop()
                await status.edit_text("Parsing OLD dump (namespace+class)...")
                old_rva_map, old_class_map, _, old_ranges, old_ida = await loop.run_in_executor(
                    None, parse_dump, old_path
                )
                await status.edit_text("Parsing NEW dump (namespace+class)...")
                new_rva_map, new_class_map, _, new_ranges, new_ida = await loop.run_in_executor(
                    None, parse_dump, new_path
                )
                new_cm_exact, new_meth_only, new_sig_index = build_indexes(
                    new_rva_map, new_class_map
                )
                await status.edit_text(
                    "Mapping v5.10 (structural+stable+Agree+IDA)..."
                )
                script_text = script_path.read_text(encoding="utf-8", errors="ignore")
                new_script, report, stats = update_script(
                    script_text, old_rva_map, new_cm_exact, new_meth_only, new_sig_index,
                    old_class_map, new_class_map,
                    old_ranges=old_ranges, new_ranges=new_ranges,
                    ida_insns={**old_ida, **new_ida},
                )
                out_script = Path(tempfile.gettempdir()) / out_name
                out_report = Path(tempfile.gettempdir()) / "offset_mapping_report.txt"
                out_script.write_text(new_script, encoding="utf-8")
                out_report.write_text(report, encoding="utf-8")
                summary = (
                    f"Done (v5.10 CPM1+CPM2)!\n"
                    f"Candidates : {stats['total']}\n"
                    f"APPLIED    : {stats['mapped']}\n"
                    f"Suggest    : {stats['suggested']} (not in script)\n"
                    f"Skipped    : {stats['missing']}\n"
                    f"High conf  : {stats['high_conf']}"
                )
                await status.edit_text(summary + "\n\nPreparing delivery...")

                mode = SEND_MODE  # telegram | link | both
                links_ok = False

                if mode in ("link", "both"):
                    await status.edit_text(summary + "\n\nUploading for download links...")
                    loop2 = asyncio.get_event_loop()
                    script_url, script_host = await loop2.run_in_executor(
                        None, upload_file_get_link, out_script
                    )
                    report_url, report_host = await loop2.run_in_executor(
                        None, upload_file_get_link, out_report
                    )
                    parts = []
                    if script_url:
                        parts.append(
                            f"📜 <b>{out_name}</b>\n<code>{script_url}</code>\n(via {script_host})"
                        )
                        links_ok = True
                    else:
                        parts.append(f"📜 {out_name}: upload failed")
                    if report_url:
                        parts.append(
                            f"📋 <b>offset_mapping_report.txt</b>\n"
                            f"<code>{report_url}</code>\n(via {report_host})"
                        )
                        links_ok = True
                    else:
                        parts.append("📋 report: upload failed")
                    await update.message.reply_text(
                        summary + "\n\n<b>Download links</b>\n\n"
                        + "\n\n".join(parts) + "\n\n"
                        "Trust [APPLIED] lines. Review [SUGGEST].\n"
                        "/start for another run.",
                        parse_mode="HTML",
                        disable_web_page_preview=True,
                    )
                    if mode == "link" and not links_ok:
                        mode = "telegram"  # fallback

                if mode in ("telegram", "both"):
                    await status.edit_text(summary + "\n\nSending files on Telegram...")
                    await update.message.reply_document(
                        document=out_script.open("rb"), filename=out_name,
                        caption=f"Updated -> {out_name}",
                    )
                    await update.message.reply_document(
                        document=out_report.open("rb"), filename="offset_mapping_report.txt",
                        caption="Report: APPLIED vs SUGGEST (+ alternatives)",
                    )
                    if mode == "telegram":
                        await update.message.reply_text(
                            "Trust [APPLIED] lines.\n"
                            "Review [SUGGEST] and alt lines (renamed methods).\n"
                            "/start for another run."
                        )

            except Exception as e:
                log.exception("Update failed")
                await status.edit_text(f"Error: {e}")
            finally:
                cleanup(
                    context.user_data.get("old_dump"), context.user_data.get("new_dump"),
                    context.user_data.get("old_dir"), context.user_data.get("new_dir"),
                    str(script_path) if script_path else None,
                )
                context.user_data.clear()
            return
    except Exception as e:
        log.error(f"handle_message: {e}")


# ============================================================================
# ENTRY POINT – start the bot (auto-restarts on crash)
# ============================================================================
def main():
    if not BOT_TOKEN:
        raise SystemExit(
            "Set env vars:\n"
            '  export BOT_TOKEN="TOKEN"\n'
            '  export ALLOWED_IDS="123456789"\n'
            '  export SEND_MODE="link"   # telegram | link | both\n'
            '  export LINK_HOST="auto"   # auto | mediafire | catbox | litterbox\n'
            "  # Optional MediaFire:\n"
            '  export MEDIAFIRE_EMAIL="you@mail.com"\n'
            '  export MEDIAFIRE_PASSWORD="pass"\n'
            "  python telegram_offset_bot.py"
        )
    while True:
        try:
            app = Application.builder().token(BOT_TOKEN).build()
            app.add_handler(CommandHandler("start", start))
            app.add_handler(CommandHandler("cancel", cancel))
            app.add_handler(MessageHandler(filters.ALL & ~filters.COMMAND, handle_message))
            app.add_error_handler(error_handler)
            log.info("Offset bot v5.10 started (CPM1 obfuscation + IDA + structural)")
            app.run_polling(drop_pending_updates=True)
        except Exception as e:
            log.error(f"Restart in 5s: {e}")
            time.sleep(5)


if __name__ == "__main__":
    main()
