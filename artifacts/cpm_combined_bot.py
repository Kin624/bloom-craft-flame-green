#!/usr/bin/env python3
"""CPM Combined Bot v5: Offset + Kinzi Encrypt multi-line + Custom."""
from __future__ import annotations
import asyncio, logging, os, random, re, string, tempfile, time, zipfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Set
from telegram import Update, Document, ReplyKeyboardMarkup, ReplyKeyboardRemove, KeyboardButton
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from telegram.error import Forbidden, BadRequest

_RAW = os.environ.get("BOT_TOKEN", "").strip()
BOT_TOKEN = "" if _RAW.lower() in {"", "put your bot token here", "token"} else _RAW
ALLOWED_IDS = {int(x.strip()) for x in os.environ.get("ALLOWED_IDS", "").split(",") if x.strip().isdigit()}
APPLY_MIN_CONF = int(os.environ.get("APPLY_MIN_CONF", "70"))
MAX_TG_DOWNLOAD = 20 * 1024 * 1024
SESSION_TIMEOUT_SEC = 30 * 60
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")
log = logging.getLogger("cpm_combined")

ANTI_LUA = '\npcall(function() if gg and gg.setVisible then gg.setVisible(false) end end)\npcall(function() if gg and gg.toast then gg.toast("KINZI DOM") end end)\npcall(function()\n  local bad = {"com.reqable.android","com.guoshi.httpcanary","sstool.only.com.sstool","com.minhui.networkcapture","app.greyshirts.sslcapture"}\n  for _, pkg in ipairs(bad) do\n    if gg and gg.isPackageInstalled and gg.isPackageInstalled(pkg) then\n      if gg.alert then gg.alert("Blocked tool") end\n      os.exit()\n    end\n  end\nend)\npcall(function()\n  local ti = gg.getTargetInfo and gg.getTargetInfo()\n  local pkg = gg.getTargetPackage and gg.getTargetPackage()\n  if ti and type(ti.label) == "string" then\n    local lb = ti.label:lower()\n    if lb:match("clone") or lb:match("parallel") or lb:match("multi") then os.exit() end\n  end\n  if type(pkg) == "string" then\n    local p = pkg:lower()\n    if p:match("parallel") or p:match("multi") or p:match("clone") then os.exit() end\n  end\nend)\ndo\n  local R = {}\n  for _, fn in ipairs({"loadfile", "dofile"}) do\n    if _G[fn] then\n      R[fn] = _G[fn]\n      _G[fn] = function(path, ...)\n        if type(path) == "string" then\n          local p = path:lower()\n          if p:match("dump") or p:match("syslog") or p:match("payload")\n             or p:match("unlua") or p:match("decrypt") or p:match("%.lasm") then\n            return nil\n          end\n        end\n        return R[fn](path, ...)\n      end\n    end\n  end\nend\npcall(function()\n  for _, p in ipairs({"/sdcard/RL.LOG","/sdcard/.syslog_payload.txt","/sdcard/lokinzer.log","/sdcard/GG_DUMP.txt"}) do\n    local f = io.open(p, "r")\n    if f then f:close(); pcall(os.remove, p) end\n  end\nend)\n'

RUNTIME_POLY = '\n-- Runtime obscure: changes every open/run\ndo\n  local t = (os.time and os.time() or 1) + math.floor(((os.clock and os.clock()) or 0) * 1e6) % 1000000\n  if math.randomseed then math.randomseed(t) end\n  local function _R(n)\n    n = n or 6\n    local s = ""\n    for i = 1, n do\n      local r = math.random(1, 26)\n      if i == 1 then s = s .. string.char(96 + r)\n      elseif math.random(1, 10) <= 7 then s = s .. string.char(96 + r)\n      else s = s .. tostring(math.random(0, 9)) end\n    end\n    return s\n  end\n  local _d = {"防御","校验","拦截","锁钥","暗层","核芯","禁制","影盾"}\n  for i = 1, math.random(5, 12) do\n    local n = _R(math.random(5, 8))\n    local v = _d[((i - 1) % #_d) + 1] .. tostring(math.random(1000, 9999))\n    if false then gg.toast(n .. v) end\n    local _ = n\n  end\n  -- shuffle soft side-file wipe order each open\n  pcall(function()\n    local paths = {"/sdcard/RL.LOG","/sdcard/.syslog_payload.txt","/sdcard/lokinzer.log","/sdcard/GG_DUMP.txt"}\n    for i = #paths, 2, -1 do\n      local j = math.random(1, i)\n      paths[i], paths[j] = paths[j], paths[i]\n    end\n    for _, p in ipairs(paths) do\n      local f = io.open(p, "r")\n      if f then f:close(); pcall(os.remove, p) end\n    end\n  end)\nend\n'

DECOYS = ["防御系统", "反编译拦截", "日志封锁", "核心校验", "多层保护", "禁止破解", "加密有效", "安全模块"]


def rnd_ascii(n=7):
    chars = []
    for i in range(n):
        if i == 0:
            chars.append(random.choice(string.ascii_lowercase))
        else:
            chars.append(random.choice(string.ascii_lowercase) if random.randint(1, 10) <= 7 else str(random.randint(0, 9)))
    return "".join(chars)

def is_url_string(quoted):
    body = quoted[1:-1].lower()
    return "http://" in body or "https://" in body

def unescape_lua_str(body):
    out, i = [], 0
    while i < len(body):
        if body[i] == "\\" and i + 1 < len(body):
            n = body[i + 1]
            m = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\"}
            if n in m:
                out.append(m[n])
                i += 2
                continue
        out.append(body[i])
        i += 1
    return "".join(out)

def layer_runtime(src):
    return RUNTIME_POLY + "\n" + src

def layer_anti(src):
    return ANTI_LUA + "\n" + src


def layer_manifest_strings(src):
    """Encrypt all single-line '...' and "..." strings except URLs."""
    an, sn, dn = rnd_ascii(7), rnd_ascii(7), rnd_ascii(7)
    ascll_used, str_used = {}, {}
    ascll_data, str_data = [an + "={}"], [sn + "={}"]
    dec = (
        dn
        + '=function(T)local d="" for _,v in pairs(T)do d=d..'
        + an
        + "[v] end return d end"
    )

    def enc_plain(plain):
        if not plain:
            return None
        low = plain.lower()
        if "http://" in low or "https://" in low:
            return None  # keep original
        if any(ord(c) > 255 for c in plain):
            # still encrypt latin; skip pure non-latin1 only if ALL high
            pass
        if plain in str_used:
            return "(" + sn + "[" + str_used[plain] + "])"
        keys = []
        for ch in plain:
            b = ord(ch)
            if b > 255:
                return None  # leave unicode-heavy strings; avoid byte loss
            key = ascll_used.get(b)
            if key is None:
                key = '"' + rnd_ascii(6) + '"'
                ascll_used[b] = key
                ascll_data.append(an + "[" + key + "]=string.char(" + str(b) + ")")
            keys.append(key)
        idx = '"' + rnd_ascii(6) + '"'
        str_used[plain] = idx
        str_data.append(sn + "[" + idx + "]=" + dn + "({" + ",".join(keys) + "})")
        return "(" + sn + "[" + idx + "])"

    def process_quote(src, i, qchar):
        """Return (replacement_or_None, end_index_exclusive)."""
        j, esc = i + 1, False
        n = len(src)
        while j < n:
            ch = src[j]
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == qchar:
                break
            elif ch == "\n":
                return None, i + 1  # multi-line: skip
            j += 1
        if j >= n:
            return None, i + 1
        quoted = src[i : j + 1]
        body = quoted[1:-1]
        plain = unescape_lua_str(body)
        rep = enc_plain(plain)
        if rep is None:
            return quoted, j + 1  # keep as-is (URL or unicode)
        return rep, j + 1

    res, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        # skip long comments
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            if i + 3 < n and src[i + 2] == "[" and src[i + 3] == "[":
                end = src.find("]]", i + 4)
                if end < 0:
                    res.append(src[i:])
                    break
                res.append(src[i : end + 2])
                i = end + 2
                continue
            # line comment
            end = src.find("\n", i)
            if end < 0:
                res.append(src[i:])
                break
            res.append(src[i:end])
            i = end
            continue
        if c in ('"', "'"):
            rep, ni = process_quote(src, i, c)
            if rep is None:
                res.append(c)
                i += 1
            else:
                res.append(rep)
                i = ni
        else:
            res.append(c)
            i += 1
    header = "\n".join(ascll_data) + "\n" + dec + "\n" + "\n".join(str_data) + "\n"
    return header + "".join(res)


def layer_cjk_decoys(src):
    lines = []
    for i in range(random.randint(6, 12)):
        n = rnd_ascii(6)
        d = DECOYS[i % len(DECOYS)]
        lines.append("local " + n + "=[[" + d + "]] if false then gg.toast(" + n + ") end")
    for _ in range(random.randint(4, 8)):
        n, f = rnd_ascii(5), rnd_ascii(5)
        lines.append(
            "local " + n + "=" + str(random.randint(1, 90000000))
            + " local function " + f + "() return " + n + "%" + str(random.randint(3, 97))
            + " end if false then " + f + "() end"
        )
    lines.append(
        'local function _nzf(c) local r="" for i=1,#c do r=r..string.char(c[i]) end return r end\n'
        "if false then gg.toast(_nzf({75,73,78,90,73})) end"
    )
    for _ in range(random.randint(3, 6)):
        lab = rnd_ascii(5)
        lines.append(
            "if nil then goto " + lab + " end ::" + lab + ":: if false then local _="
            + str(random.randint(1, 99999)) + " end"
        )
    return "\n".join(lines) + "\n" + src

def layer_hidegg(src):
    found = sorted(set(re.findall(r"\b(gg\.[A-Za-z_][A-Za-z0-9_]*)\b", src)))
    if not found:
        return src
    decls = []
    out = src
    for full in found:
        name = rnd_ascii(8)
        decls.append(name + "=" + full)
        out = re.sub(r"\b" + re.escape(full) + r"\b", name, out)
    return " ".join(decls) + "\n" + out

def layer_wrap(src):
    return 'gg.toast("KINZI DOM")\n;(function(...)\n' + src + "\nend)()\n"

def layer_oneline(src):
    esc = ["\\" + format(b, "03d") for b in src.encode("utf-8", errors="surrogateescape")]
    return 'load("' + "".join(esc) + '")()'

@dataclass
class EncOptions:
    runtime: bool = True
    anti: bool = True
    strings: bool = True
    cjk: bool = True
    hidegg: bool = True
    wrap: bool = True
    oneline: bool = False

def encrypt_lua(src, opt=None):
    random.seed(time.time_ns() % (2**32))
    opt = opt or EncOptions()
    stage = src
    if getattr(opt, "runtime", True):
        stage = layer_runtime(stage)
    if opt.anti:
        stage = layer_anti(stage)
    if opt.strings:
        try:
            stage = layer_manifest_strings(stage)
        except Exception as e:
            log.warning("strings: %s", e)
    if opt.cjk:
        stage = layer_cjk_decoys(stage)
    if opt.hidegg:
        try:
            stage = layer_hidegg(stage)
        except Exception as e:
            log.warning("hidegg: %s", e)
    if opt.wrap:
        stage = layer_wrap(stage)
    if opt.oneline:
        stage = layer_oneline(stage)
    return stage

RVA_RE = re.compile(r"//\s*RVA:\s*(0x[0-9A-Fa-f]+)\s+Offset:\s*(0x[0-9A-Fa-f]+)", re.I)
CLASS_RE = re.compile(
    r"^(?:public|private|internal|protected)?\s*"
    r"(?:static\s+|abstract\s+|sealed\s+|virtual\s+|override\s+|readonly\s+)*"
    r"(?:class|struct|interface|enum)\s+(\w+)",
    re.M,
)
METHOD_LINE_RE = re.compile(
    r"\b(?:public|private|internal|protected)\s+"
    r"(?:(static)\s+|virtual\s+|override\s+|abstract\s+|async\s+)*"
    r"([\w.<>,\[\]\s]+?)\s+(\w+)\s*\(([^)]*)\)",
)
SKIP_METHODS = {"get", "set", "add", "remove", "op", "ctor", "cctor"}
HEX_RE = re.compile(r"\b(0x[0-9A-Fa-f]{5,10})\b")

_ARM_EXACT = {
    0x52800020, 0x52800000, 0x52800028, 0x52800034,
    0xD65F03C0, 0xD2800000, 0x2A0103F4, 0x2A0003E0,
    0xAA1F03E0, 0xD503201F, 0x200080D2, 0xC0035FD6,
}
_ARM_TOP16 = {
    0x52800000, 0x52810000, 0x52820000, 0x52830000,
    0xD2800000, 0xD2810000, 0xD65F0000,
    0x2A000000, 0x2A010000, 0xAA1F0000,
    0x32000000, 0xD5030000, 0x20000000, 0xC0030000,
}
_WEAK_SIGS = {
    "I|void|0", "I|void|1", "I|void|2", "S|void|0", "S|void|1",
    "I|bool|0", "I|bool|1", "I|int|0", "I|int32|0",
}


def looks_like_arm_instruction(val: int) -> bool:
    if val in _ARM_EXACT or (val & 0xFFFF0000) in _ARM_TOP16 or val < 0x10000:
        return True
    return False


def extract_candidate_rvas(script_text: str, min_off=0x10000, max_off=0x80000000) -> set:
    found = set()
    for m in HEX_RE.finditer(script_text):
        try:
            val = int(m.group(1), 16)
        except ValueError:
            continue
        if min_off <= val <= max_off and not looks_like_arm_instruction(val):
            found.add(val)
    return found


@dataclass
class MethodInfo:
    cls: str
    name: str
    rva: int
    is_static: bool = False
    ret_type: str = ""
    param_count: int = 0
    sig_key: str = ""


def _norm_type(t: str) -> str:
    t = re.sub(r"\s+", "", (t or ""))
    return t.split(".")[-1].lower()


def _sig_key(is_static: bool, ret: str, nparams: int) -> str:
    return f"{'S' if is_static else 'I'}|{_norm_type(ret)}|{nparams}"


def parse_dump(path: Path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()
    rva_map: Dict[int, List[MethodInfo]] = defaultdict(list)
    class_map: Dict[str, List[MethodInfo]] = defaultdict(list)
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
            is_static, ret_type, param_count = False, "", 0
            for j in range(i + 1, min(i + 8, n)):
                mline = lines[j].strip()
                if not mline or mline.startswith(("//", "/*", "[")):
                    continue
                mm = METHOD_LINE_RE.search(mline)
                if mm:
                    is_static = bool(mm.group(1))
                    ret_type = mm.group(2).strip()
                    method_name = mm.group(3)
                    params = mm.group(4).strip()
                    param_count = 0 if not params else params.count(",") + 1
                    break
                bare = re.match(r"^(\w+)\s*\(", mline)
                if bare and not mline.startswith(("if", "for", "while", "switch", "return")):
                    method_name = bare.group(1)
                    break
            if method_name and method_name not in SKIP_METHODS:
                info = MethodInfo(
                    cls=current_class,
                    name=method_name,
                    rva=rva,
                    is_static=is_static,
                    ret_type=ret_type,
                    param_count=param_count,
                    sig_key=_sig_key(is_static, ret_type, param_count),
                )
                rva_map[rva].append(info)
                class_map[current_class].append(info)
        i += 1
    for cls in class_map:
        class_map[cls].sort(key=lambda m: m.rva)
    return dict(rva_map), dict(class_map)


def build_indexes(rva_map, class_map):
    cm_exact, meth_only, sig_index = defaultdict(list), defaultdict(list), defaultdict(list)
    for rva, infos in rva_map.items():
        for info in infos:
            cm_exact[(info.cls, info.name)].append(rva)
            meth_only[info.name].append((info.cls, rva))
            if info.sig_key:
                sig_index[info.sig_key].append((info.cls, info.name, rva))
    return dict(cm_exact), dict(meth_only), dict(sig_index)


def resolve_in_old(old_rva, old_rva_map):
    for delta in (0, -4, 4, -8, 8):
        infos = old_rva_map.get(old_rva + delta)
        if infos:
            note = f"aligned {delta:+d} (instr boundary)" if delta else ""
            return infos, delta, note
    return None, 0, ""


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
    pairs, align_delta, align_note = resolve_in_old(old_rva, old_rva_map)
    if not pairs:
        return None, "none", "no class/method in OLD dump (tried ±0/4/8)", 0
    align_suffix = f" | {align_note}" if align_note else ""

    for info in pairs:
        cands = new_cm_exact.get((info.cls, info.name))
        if cands:
            rva = cands[0] - align_delta if align_delta else cands[0]
            return rva, "exact", f"{info.cls}::{info.name}{align_suffix}", 98

    for info in pairs:
        cands = new_meth_only.get(info.name)
        if not cands:
            continue
        same = [(c, r) for c, r in cands if c == info.cls]
        if same:
            rva = same[0][1] - align_delta if align_delta else same[0][1]
            return rva, "method", f"{same[0][0]}::{info.name} (same class){align_suffix}", 90
        if len(cands) == 1:
            cls, rva = cands[0]
            rva = rva - align_delta if align_delta else rva
            return rva, "method", f"{cls}::{info.name} (unique name){align_suffix}", 85
        if len(cands) <= 3:
            cls, rva = cands[0]
            rva = rva - align_delta if align_delta else rva
            return rva, "method", f"{cls}::{info.name} (name×{len(cands)}){align_suffix}", 70
        break

    for info in pairs:
        if not info.sig_key or info.sig_key in _WEAK_SIGS:
            continue
        cands = new_sig_index.get(info.sig_key)
        if not cands or len(cands) > 8:
            continue
        old_count = len(old_class_map.get(info.cls, []))
        scored = []
        for cls, meth, rva in cands:
            if rva in claimed_new:
                continue
            size_score = 100 - abs(len(new_class_map.get(cls, [])) - old_count)
            scored.append((size_score, rva, cls, meth))
        if not scored:
            continue
        scored.sort(reverse=True)
        best_score, rva, cls, meth = scored[0]
        if best_score < 75:
            continue
        if len(scored) > 1 and scored[0][0] - scored[1][0] < 5:
            continue
        rva = rva - align_delta if align_delta else rva
        return rva, "signature", f"{cls}::{meth} sig={info.sig_key}{align_suffix}", 60

    for info in pairs:
        old_m = old_class_map.get(info.cls)
        new_m = new_class_map.get(info.cls)
        if not old_m or not new_m:
            continue
        target = old_rva + align_delta
        idx = next((i for i, m in enumerate(old_m) if m.rva == target), None)
        if idx is None or idx >= len(new_m):
            continue
        cand = new_m[idx]
        rva = cand.rva - align_delta if align_delta else cand.rva
        return rva, "neighbor-idx", f"{info.cls}[{idx}]→{cand.name}{align_suffix}", 65

    for info in pairs:
        old_m = old_class_map.get(info.cls, [])
        if len(old_m) < 4:
            continue
        target = old_rva + align_delta
        idx = next((i for i, m in enumerate(old_m) if m.rva == target), None)
        if idx is None or idx == 0:
            continue
        old_gap = old_m[idx].rva - old_m[idx - 1].rva
        for cls, methods in new_class_map.items():
            if abs(len(methods) - len(old_m)) > 4 or idx >= len(methods):
                continue
            cand = methods[idx]
            gap = cand.rva - methods[idx - 1].rva
            if abs(gap - old_gap) > 0x30 or cand.rva in claimed_new:
                continue
            rva = cand.rva - align_delta if align_delta else cand.rva
            return rva, "neighbor-gap", f"{cls}[{idx}]::{cand.name} gap≈{old_gap:#x}{align_suffix}", 40

    return None, "missing", f"{pairs[0].cls}::{pairs[0].name}{align_suffix}", 0


def apply_hex_replacements(script_text: str, replacements: Dict[str, str]) -> str:
    """Replace 0xHEX tokens case-insensitively, longest first."""
    new_text = script_text
    for old_hex, new_hex in sorted(replacements.items(), key=lambda x: -len(x[0])):
        # Match any case form of the old hex as a whole token
        pattern = re.compile(rf"\b{re.escape(old_hex)}\b", re.I)
        new_text = pattern.sub(new_hex, new_text)
    return new_text


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
    min_conf: int = APPLY_MIN_CONF,
):
    found = extract_candidate_rvas(script_text, min_off, max_off)
    replacements = {}
    report = []
    stats = {
        "mapped": 0,
        "same": 0,
        "missing": 0,
        "suggested": 0,
        "total": len(found),
        "by_strategy": defaultdict(int),
        "high_conf": 0,
        "low_conf": 0,
    }
    claimed_new: Set[int] = set()
    pending = sorted(found)

    def do_pass(allowed):
        nonlocal pending
        still = []
        for old_rva in pending:
            old_hex = f"0x{old_rva:X}"
            new_rva, strategy, detail, conf = map_one_rva(
                old_rva,
                old_rva_map,
                new_cm_exact,
                new_meth_only,
                new_sig_index,
                old_class_map,
                new_class_map,
                claimed_new,
            )
            if strategy not in allowed:
                still.append(old_rva)
                continue
            stats["by_strategy"][strategy] += 1
            if new_rva is None:
                tag = "none" if strategy == "none" else "missing"
                report.append(f"{old_hex}  →  SKIP  [{tag}]  conf=0  ({detail})")
                stats["missing"] += 1
                continue
            if strategy in ("signature", "neighbor-gap", "neighbor-idx") and new_rva in claimed_new:
                still.append(old_rva)
                stats["by_strategy"][strategy] -= 1
                continue
            new_hex = f"0x{new_rva:X}"
            claimed_new.add(new_rva)
            claimed_new.add(new_rva & ~0x3)
            how = f"[{strategy}] conf={conf}  how: {detail}"
            apply = conf >= min_conf
            if new_hex.upper() == old_hex.upper():
                report.append(f"{old_hex}  = same  {how}")
                stats["same"] += 1
            elif apply:
                replacements[old_hex] = new_hex
                report.append(f"{old_hex}  →  {new_hex}  {how}  [APPLIED]")
                stats["mapped"] += 1
            else:
                report.append(f"{old_hex}  →  {new_hex}  {how}  [SUGGEST only — not applied]")
                stats["suggested"] += 1
            if conf >= 80:
                stats["high_conf"] += 1
            elif conf > 0:
                stats["low_conf"] += 1
        pending = still

    do_pass({"exact", "method", "none", "missing"})
    do_pass({"neighbor-idx", "signature", "none", "missing"})
    do_pass({"neighbor-gap", "none", "missing"})
    for old_rva in pending:
        report.append(f"0x{old_rva:X}  →  SKIP  [unresolved]")
        stats["missing"] += 1
        stats["by_strategy"]["unresolved"] += 1

    new_text = apply_hex_replacements(script_text, replacements)

    report_sorted = sorted(report, key=lambda s: s.split()[0])
    strat_lines = "\n".join(f"  {k:14}: {v}" for k, v in sorted(stats["by_strategy"].items()))
    report_text = (
        f"OFFSET MAPPING REPORT (v4.2)\n"
        f"============================\n"
        f"Apply threshold  : conf >= {min_conf}\n"
        f"Total candidates : {stats['total']}\n"
        f"APPLIED to script: {stats['mapped']}\n"
        f"Unchanged        : {stats['same']}\n"
        f"SUGGEST only     : {stats['suggested']}  (NOT written into script)\n"
        f"Skipped/Missing  : {stats['missing']}\n"
        f"High confidence  : {stats['high_conf']}\n"
        f"Low confidence   : {stats['low_conf']}\n\n"
        f"By strategy:\n{strat_lines}\n\n"
        f"APPLY rule: only conf >= {min_conf} is written into the .lua\n"
        f"  (exact / method typically). Everything else is SUGGEST only.\n\n"
        "Alignment: ARM64 instr = 4 bytes. Script often stores +4;\n"
        "bot resolves via ±4/±8 and re-applies the delta.\n"
        "ARM opcodes filtered. Weak void|0 signatures rejected.\n\n"
        + "\n".join(report_sorted)
        + "\n"
    )
    return new_text, report_text, stats



# --- Telegram ---
MENU_KB = ReplyKeyboardMarkup(
    [
        [KeyboardButton("1) Offset Update"), KeyboardButton("2) Encrypt Script")],
        [KeyboardButton("3) Custom Encrypt"), KeyboardButton("Help")],
        [KeyboardButton("Cancel")],
    ],
    resize_keyboard=True,
)
YES_NO = ReplyKeyboardMarkup([["ON", "OFF"], ["Done / Encrypt now"]], resize_keyboard=True)

HELP_TEXT = '📖 HELP — CPM Combined Bot\n\n━━━━━━━━━━━━━━━━━━━━━━\n① OFFSET UPDATE\n━━━━━━━━━━━━━━━━━━━━━━\nWhen the game updates, map old offsets → new.\n\nSteps:\n  1. Send OLD dump.cs (or zip)\n  2. Send NEW dump.cs (or zip)\n  3. Send your .lua script\n\nYou get:\n  • script_UPDATED.lua\n  • offset_mapping_report.txt\n\nOnly high-confidence (conf≥70) offsets are written.\nReview the report for [SUGGEST] lines.\n\n━━━━━━━━━━━━━━━━━━━━━━\n② ENCRYPT SCRIPT\n━━━━━━━━━━━━━━━━━━━━━━\nProtect a .lua with Kinzi layers (multi-line).\n\nAfter you tap 2, just send the .lua file.\n\nIncludes: anti, string obscure, CJK decoys, gg rename.\nURLs are NOT encrypted (makeRequest still works).\n\n⚠️ Full Orvex LASM/bytecode encrypt only works inside\nGameGuardian (file: KINZI_ORVEX_STRONG.lua).\nTelegram cannot do LASM.\n\n━━━━━━━━━━━━━━━━━━━━━━\n③ CUSTOM ENCRYPT\n━━━━━━━━━━━━━━━━━━━━━━\nTurn each layer ON or OFF, then send .lua.\n\nRecommended for panels:\n  Runtime ON · Anti ON · Strings ON\n  CJK ON · hidegg ON · Wrap ON\n  One-line OFF\n\n━━━━━━━━━━━━━━━━━━━━━━\nCOMMANDS\n━━━━━━━━━━━━━━━━━━━━━━\n/start   main menu\n/help    this guide\n/cancel  stop current step\n'
CUSTOM_STEPS = [
    ("runtime", "Runtime poly (changes every open)"),
    ("anti", "Soft anti-log / anti-dump"),
    ("strings", "Manifest string encrypt (keep URLs)"),
    ("cjk", "CJK / Chinese decoy junk"),
    ("hidegg", "Rename gg.xxx APIs"),
    ("wrap", "Wrap in function(...)"),
    ("oneline", "One-line load() — leave OFF"),
]

def allowed(update):
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

def touch(context):
    context.user_data["last_active"] = time.time()

def expired(context):
    last = context.user_data.get("last_active")
    return bool(last and (time.time() - last) > SESSION_TIMEOUT_SEC)

async def download_and_extract(doc):
    size = doc.file_size or 0
    name = (doc.file_name or "file").lower()
    if size > MAX_TG_DOWNLOAD:
        raise ValueError("File too big. ZIP under 20 MB.")
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=Path(name).suffix or ".bin")
    tmp_path = Path(tmp.name)
    tmp.close()
    try:
        tg_file = await doc.get_file()
        await tg_file.download_to_drive(custom_path=str(tmp_path))
    except BadRequest as e:
        cleanup(tmp_path)
        raise ValueError(str(e)) from e
    if name.endswith(".zip") or zipfile.is_zipfile(tmp_path):
        extract_dir = Path(tempfile.mkdtemp(prefix="dump_"))
        try:
            with zipfile.ZipFile(tmp_path, "r") as zf:
                zf.extractall(extract_dir)
            cleanup(tmp_path)
            candidates = list(extract_dir.rglob("dump.cs")) or list(extract_dir.rglob("*.cs")) or list(extract_dir.rglob("*.txt"))
            if not candidates:
                cleanup(extract_dir)
                raise ValueError("ZIP has no dump")
            candidates.sort(key=lambda p: p.stat().st_size, reverse=True)
            return candidates[0]
        except zipfile.BadZipFile:
            cleanup(tmp_path, extract_dir)
            raise ValueError("Invalid ZIP")
    return tmp_path

def make_updated_name(original_name):
    stem = Path(original_name or "script.lua").stem
    if stem.upper().endswith("_UPDATED"):
        stem = stem[: -len("_UPDATED")]
    return stem + "_UPDATED.lua"

async def error_handler(update, context):
    if isinstance(context.error, Forbidden):
        log.warning("blocked")
    else:
        log.error("%s", context.error)

async def cmd_start(update, context):
    if not allowed(update):
        await update.message.reply_text("Not authorized.")
        return
    cleanup(context.user_data.get("old_dump"), context.user_data.get("new_dump"),
            context.user_data.get("old_dir"), context.user_data.get("new_dir"))
    context.user_data.clear()
    touch(context)
    context.user_data["step"] = "menu"
    await update.message.reply_text(
        "╔══════════════════════╗\n"
        "   CPM Combined Bot\n"
        "╚══════════════════════╝\n\n"
        "What do you want to do?\n\n"
        "① Offset Update\n"
        "   Fix script offsets after a game update\n"
        "   → send OLD dump, NEW dump, then .lua\n\n"
        "② Encrypt Script\n"
        "   Protect a .lua (Kinzi multi-line)\n"
        "   → then send your .lua file\n\n"
        "③ Custom Encrypt\n"
        "   Choose layers ON/OFF, then send .lua\n\n"
        "Tap a button below, or Help for details.\n\n"
        "Note: Max LASM encrypt = GG app only\n"
        "(KINZI_ORVEX_STRONG.lua on phone).",
        reply_markup=MENU_KB,
    )

async def cmd_help(update, context):
    if not allowed(update):
        return
    await update.message.reply_text(HELP_TEXT, reply_markup=MENU_KB)

async def cmd_cancel(update, context):
    cleanup(context.user_data.get("old_dump"), context.user_data.get("new_dump"),
            context.user_data.get("old_dir"), context.user_data.get("new_dir"))
    context.user_data.clear()
    touch(context)
    context.user_data["step"] = "menu"
    await update.message.reply_text("Cancelled.", reply_markup=MENU_KB)

async def handle_message(update, context):
    if not allowed(update) or not update.message:
        return
    if expired(context) and context.user_data.get("step") not in (None, "menu"):
        context.user_data.clear()
        await update.message.reply_text("Timeout. /start", reply_markup=MENU_KB)
        return
    touch(context)
    text = (update.message.text or "").strip()
    doc = update.message.document
    if text in ("Cancel", "cancel", "/cancel"):
        await cmd_cancel(update, context)
        return
    step = context.user_data.get("step") or "menu"

    if step == "menu" or text in ("Help", "help", "HELP", "/help"):
        low = text.lower()
        if text.startswith("1") or "offset" in low:
            context.user_data.clear()
            touch(context)
            context.user_data["step"] = "old_dump"
            await update.message.reply_text(
                "① OFFSET UPDATE\n\n"
                "Step 1/3 — Send the OLD dump\n"
                "Accepts: .cs  .txt  .zip (max 20 MB)\n\n"
                "Tip: zip large dumps first.",
                reply_markup=ReplyKeyboardRemove(),
            )
            return
        if text.startswith("2") or "encrypt script" in low or low == "2":
            context.user_data.clear()
            touch(context)
            context.user_data["step"] = "encrypt_lua"
            context.user_data["enc_opt"] = EncOptions().__dict__.copy()
            await update.message.reply_text(
                "② ENCRYPT SCRIPT\n\n"
                "Default layers (multi-line output):\n"
                "  • Runtime poly\n"
                "  • Soft anti\n"
                "  • String encrypt (URLs kept)\n"
                "  • CJK decoys\n"
                "  • gg API rename\n"
                "  • Function wrap\n"
                "  • One-line: OFF\n\n"
                "Now send your .lua file.",
                reply_markup=ReplyKeyboardRemove(),
            )
            return
        if text.startswith("3") or "custom" in low:
            context.user_data.clear()
            touch(context)
            context.user_data["step"] = "custom_0"
            context.user_data["enc_opt"] = EncOptions().__dict__.copy()
            k, lab = CUSTOM_STEPS[0]
            await update.message.reply_text(
                f"③ CUSTOM ENCRYPT — layer 1/{len(CUSTOM_STEPS)}\n\n"
                f"{lab}\n\n"
                f"Tap ON or OFF.\n"
                f"Or tap Done / Encrypt now to skip the rest.",
                reply_markup=YES_NO,
            )
            return
        if "help" in low:
            await update.message.reply_text(HELP_TEXT, reply_markup=MENU_KB)
            return
        await update.message.reply_text(
            "Use the buttons:\n"
            "① Offset Update\n"
            "② Encrypt Script\n"
            "③ Custom Encrypt\n"
            "Help — full guide",
            reply_markup=MENU_KB,
        )
        return

    if step.startswith("custom_"):
        idx = int(step.split("_")[1])
        if text == "Done / Encrypt now":
            context.user_data["step"] = "encrypt_lua"
            await update.message.reply_text("Send .lua file.", reply_markup=ReplyKeyboardRemove())
            return
        if text in ("ON", "OFF") and idx < len(CUSTOM_STEPS):
            key, lab = CUSTOM_STEPS[idx]
            context.user_data.setdefault("enc_opt", EncOptions().__dict__.copy())
            context.user_data["enc_opt"][key] = (text == "ON")
            idx += 1
            if idx >= len(CUSTOM_STEPS):
                opt = context.user_data["enc_opt"]
                summary = "\n".join(f"  {k}: {'ON' if opt.get(k) else 'OFF'}" for k, _ in CUSTOM_STEPS)
                context.user_data["step"] = "encrypt_lua"
                await update.message.reply_text(
                    f"Layers:\n{summary}\n\nSend .lua file.", reply_markup=ReplyKeyboardRemove())
            else:
                context.user_data["step"] = f"custom_{idx}"
                k, lab = CUSTOM_STEPS[idx]
                await update.message.reply_text(
                    f"Step {idx+1}/{len(CUSTOM_STEPS)}\n{lab}\nON or OFF?", reply_markup=YES_NO)
            return
        await update.message.reply_text("ON / OFF / Done", reply_markup=YES_NO)
        return

    if step == "encrypt_lua":
        if not doc:
            await update.message.reply_text("Send .lua document")
            return
        name = (doc.file_name or "").lower()
        if not name.endswith((".lua", ".txt")):
            await update.message.reply_text("Need .lua")
            return
        status = await update.message.reply_text("Encrypting…")
        try:
            path = await download_and_extract(doc)
            raw = path.read_text(encoding="utf-8", errors="replace")
            od = context.user_data.get("enc_opt") or EncOptions().__dict__
            defaults = EncOptions()
            opt = EncOptions(**{
                k: bool(od[k]) if k in od else getattr(defaults, k)
                for k in EncOptions.__dataclass_fields__
            })
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, lambda: encrypt_lua(raw, opt))
            out_name = Path(doc.file_name or "script.lua").stem + ".MANIFEST_DEPLOYMENT.lua"
            out_path = Path(tempfile.gettempdir()) / out_name
            out_path.write_text(result, encoding="utf-8", newline="\n")
            await status.edit_text(f"Done {out_name} ({out_path.stat().st_size/1024:.1f} KB)")
            await update.message.reply_document(document=out_path.open("rb"), filename=out_name,
                caption="✅ Kinzi encrypt done (source layers).\nFor full LASM use KINZI_ORVEX_STRONG.lua in GG.")
            await update.message.reply_text("Menu:", reply_markup=MENU_KB)
        except Exception as e:
            log.exception("enc")
            await status.edit_text(f"Fail: {e}")
        finally:
            context.user_data.clear()
            context.user_data["step"] = "menu"
            touch(context)
        return

    if step == "old_dump":
        if not doc:
            await update.message.reply_text("Send OLD dump")
            return
        name = (doc.file_name or "").lower()
        if not (name.endswith((".cs", ".txt", ".zip")) or "dump" in name):
            await update.message.reply_text("OLD: .cs/.zip")
            return
        await update.message.reply_text("Downloading OLD…")
        try:
            path = await download_and_extract(doc)
        except Exception as e:
            await update.message.reply_text(str(e)); return
        context.user_data["old_dump"] = str(path)
        if path.parent.name.startswith("dump_"):
            context.user_data["old_dir"] = str(path.parent)
        context.user_data["step"] = "new_dump"
        await update.message.reply_text(
            f"✅ OLD dump OK ({path.stat().st_size/1e6:.1f} MB)\n"
            f"File: {path.name}\n\n"
            f"Step 2/3 — Send the NEW dump.")
        return

    if step == "new_dump":
        if not doc:
            await update.message.reply_text("Send NEW dump"); return
        name = (doc.file_name or "").lower()
        if not (name.endswith((".cs", ".txt", ".zip")) or "dump" in name):
            await update.message.reply_text("NEW: .cs/.zip"); return
        await update.message.reply_text("Downloading NEW…")
        try:
            path = await download_and_extract(doc)
        except Exception as e:
            await update.message.reply_text(str(e)); return
        context.user_data["new_dump"] = str(path)
        if path.parent.name.startswith("dump_"):
            context.user_data["new_dir"] = str(path.parent)
        context.user_data["step"] = "script"
        await update.message.reply_text(
            f"✅ NEW dump OK ({path.stat().st_size/1e6:.1f} MB)\n"
            f"File: {path.name}\n\n"
            f"Step 3/3 — Send the .lua script to update.")
        return

    if step == "script":
        if not doc:
            await update.message.reply_text("Send .lua"); return
        name = (doc.file_name or "").lower()
        if not name.endswith((".lua", ".txt")):
            await update.message.reply_text("Need .lua"); return
        out_name = make_updated_name(doc.file_name or "script.lua")
        status = await update.message.reply_text("Working…")
        try:
            script_path = await download_and_extract(doc)
        except Exception as e:
            await status.edit_text(str(e)); return
        old_path = Path(context.user_data["old_dump"])
        new_path = Path(context.user_data["new_dump"])
        try:
            loop = asyncio.get_event_loop()
            await status.edit_text("Parse OLD…")
            old_rva_map, old_class_map = await loop.run_in_executor(None, parse_dump, old_path)
            await status.edit_text("Parse NEW…")
            new_rva_map, new_class_map = await loop.run_in_executor(None, parse_dump, new_path)
            new_cm_exact, new_meth_only, new_sig_index = build_indexes(new_rva_map, new_class_map)
            await status.edit_text("Map…")
            script_text = script_path.read_text(encoding="utf-8", errors="ignore")
            new_script, report, stats = await loop.run_in_executor(
                None, lambda: update_script(
                    script_text, old_rva_map, new_cm_exact, new_meth_only, new_sig_index,
                    old_class_map, new_class_map, APPLY_MIN_CONF))
            out_script = Path(tempfile.gettempdir()) / out_name
            out_report = Path(tempfile.gettempdir()) / "offset_mapping_report.txt"
            out_script.write_text(new_script, encoding="utf-8")
            out_report.write_text(report, encoding="utf-8")
            await status.edit_text(f"Applied={stats.get('mapped')} Suggest={stats.get('suggested')}")
            await update.message.reply_document(document=out_script.open("rb"), filename=out_name)
            await update.message.reply_document(document=out_report.open("rb"), filename="offset_mapping_report.txt")
            await update.message.reply_text("Menu:", reply_markup=MENU_KB)
        except Exception as e:
            log.exception("offset")
            await status.edit_text(f"Error: {e}")
        finally:
            cleanup(context.user_data.get("old_dump"), context.user_data.get("new_dump"),
                    context.user_data.get("old_dir"), context.user_data.get("new_dir"),
                    str(script_path) if script_path else None)
            context.user_data.clear()
            context.user_data["step"] = "menu"
            touch(context)
        return

    await update.message.reply_text("Use menu /start", reply_markup=MENU_KB)

def main():
    if not BOT_TOKEN:
        raise SystemExit('export BOT_TOKEN="..." && python telegram_offset_bot.py')
    while True:
        try:
            app = Application.builder().token(BOT_TOKEN).build()
            app.add_handler(CommandHandler("start", cmd_start))
            app.add_handler(CommandHandler("cancel", cmd_cancel))
            app.add_handler(CommandHandler("help", cmd_help))
            app.add_handler(MessageHandler(filters.ALL & ~filters.COMMAND, handle_message))
            app.add_error_handler(error_handler)
            log.info("CPM Combined Bot v5 started")
            app.run_polling(drop_pending_updates=True)
        except Exception as e:
            log.error("restart %s", e)
            time.sleep(5)

if __name__ == "__main__":
    main()
