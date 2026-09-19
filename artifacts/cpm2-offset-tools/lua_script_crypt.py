#!/usr/bin/env python3
"""
Lua Script Crypt (clean Kinzi-style pipeline)
=============================================
Encrypt / decrypt GameGuardian Lua scripts offline.

Pipeline (same idea as ENC KINGDOM KINZI, without malware):
  plain → XOR(key) → Caesar(+seed) → XOR(revkey) → RLE → Base64
  + SHA256 integrity + polymorphic-ish loader output

Usage:
  # Encrypt a script → protected .lua loader
  python lua_script_crypt.py encrypt --in script.lua --out script_protected.lua

  # Decrypt (recover original from intermediate, or from protected if payload extractable)
  python lua_script_crypt.py decrypt --in script_protected.lua --out script_restored.lua

  # Just show info / verify integrity of a protected file
  python lua_script_crypt.py info --in script_protected.lua

This tool does NOT:
  - log/steal your script to hidden paths
  - self-destruct or overwrite source with garbage
  - kill anti-debug packages or crash the device
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import random
import re
import struct
import sys
import time
from pathlib import Path
from typing import List, Tuple


# ---------------------------------------------------------------------------
# Crypto helpers
# ---------------------------------------------------------------------------

def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def derive_key(seed: int, sighex: str, length: int) -> List[int]:
    """PRNG key derivation matching the Kinzi-style loop."""
    state = 0
    for ch in sighex.encode("utf-8", errors="ignore"):
        state = (state * 131 + ch) & 0x7FFFFFFF
    state = (state + (seed & 0x7FFFFFFF)) & 0x7FFFFFFF
    key = []
    for _ in range(length):
        state = (1103515245 * state + 12345) % 0x80000000
        key.append((state >> 16) & 0xFF)
    return key


def xor_with_key(data: bytes, key: List[int]) -> bytes:
    klen = len(key)
    return bytes(data[i] ^ key[i % klen] for i in range(len(data)))


def caesar_shift(data: bytes, shift: int) -> bytes:
    shift %= 256
    return bytes((b + shift) % 256 for b in data)


def caesar_unshift(data: bytes, shift: int) -> bytes:
    shift %= 256
    return bytes((b - shift) % 256 for b in data)


def rle_compress(data: bytes) -> bytes:
    """
    Simple RLE:
      - runs of length >= 3 encoded as 0x00, run_len, byte
      - literal 0x00 encoded as 0x00, 0x01, 0x00
      - other bytes as themselves
    """
    out = bytearray()
    i, n = 0, len(data)
    while i < n:
        b = data[i]
        run = 1
        while i + run < n and data[i + run] == b and run < 255:
            run += 1
        if run >= 3:
            out += bytes([0, run, b])
            i += run
        else:
            for _ in range(run):
                if b == 0:
                    out += bytes([0, 1, 0])
                else:
                    out.append(b)
            i += run
    return bytes(out)


def rle_decompress(data: bytes) -> bytes:
    out = bytearray()
    i, n = 0, len(data)
    while i < n:
        c = data[i]
        if c == 0 and i + 2 < n:
            run, b = data[i + 1], data[i + 2]
            out += bytes([b]) * run
            i += 3
        else:
            out.append(c)
            i += 1
    return bytes(out)


def rev_key(key: List[int]) -> List[int]:
    return [key[len(key) - 1 - ((i) % len(key))] for i in range(len(key))]


# ---------------------------------------------------------------------------
# Encrypt / Decrypt pipeline
# ---------------------------------------------------------------------------

def encrypt_payload(plain: bytes, seed: int | None = None, keylen: int = 256) -> Tuple[str, str, dict]:
    """
    Returns (b64_payload, b64_header, meta)
    """
    if seed is None:
        seed = (int(time.time()) ^ len(plain)) & 0x7FFFFFFF

    signature = sha256_hex(plain)
    key = derive_key(seed, signature[:16], keylen)  # match loader (16-char sig)
    rkey = rev_key(key)

    stage1 = xor_with_key(plain, key)
    stage2 = caesar_shift(stage1, seed % 256)
    stage3 = xor_with_key(stage2, rkey)
    compressed = rle_compress(stage3)
    encoded = base64.b64encode(compressed).decode("ascii")

    meta = {
        "build": f"{int(time.time())}-{random.randint(1000, 9999)}",
        "seed": seed,
        "sig": signature[:16],
        "sig_full": signature,
        "klen": keylen,
        "plain_len": len(plain),
        "encoded_len": len(encoded),
    }
    header_plain = json.dumps(
        {"build": meta["build"], "seed": seed, "sig": signature[:16], "klen": keylen},
        separators=(",", ":"),
    ).encode("utf-8")
    header_key = derive_key(seed ^ 0xABCDEF, signature[:16], 64)
    header_enc = base64.b64encode(xor_with_key(header_plain, header_key)).decode("ascii")

    return encoded, header_enc, meta


def decrypt_payload(encoded_b64: str, header_b64: str) -> Tuple[bytes, dict]:
    header_raw = base64.b64decode(header_b64)
    # We need seed from header — try decrypt with candidate: we embedded seed in plaintext header
    # Recover by brute is unnecessary: header xor key depends on seed in header itself.
    # Kinzi loader parses seed from decrypted header; chicken-egg is solved because
    # header key uses seed from a first-pass parse of *unencrypted* seed field after
    # a weak scheme. Our clean version stores seed in a clear prefix for recovery.

    # Clean approach: try decode header with seed extracted via regex on xor-failure fallback
    # Better: embed clear JSON line in our Python format for decrypt tool.
    raise RuntimeError("Use decrypt_blob() with meta, or decrypt from protected file format below.")


def decrypt_with_meta(encoded_b64: str, seed: int, sig16: str, klen: int) -> bytes:
    key = derive_key(seed, sig16, klen)
    rkey = rev_key(key)
    compressed = base64.b64decode(encoded_b64)
    stage3 = rle_decompress(compressed)
    after = xor_with_key(stage3, rkey)
    s2 = caesar_unshift(after, seed % 256)
    plain = xor_with_key(s2, key)
    return plain


# ---------------------------------------------------------------------------
# Protected Lua file format (readable by GG + recoverable by this tool)
# ---------------------------------------------------------------------------

BANNER = "-- CPM2 Script Crypt | clean Kinzi-style pipeline (no logger / no self-destruct)\n"

LOADER_TEMPLATE = r'''-- Auto-generated protected loader
-- Build: __BUILD__
local _PAY = [[__PAYLOAD__]]
local _META = [[__META__]]

local function b64d(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(string.find(b,x)-1)
    for i=6,1,-1 do r=r..(f%2^i - f%2^(i-1) > 0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c*2 + (string.sub(x,i,i)=='1' and 1 or 0) end
    return string.char(c)
  end))
end

local function rle_decomp(s)
  local out, i, n = {{}}, 1, #s
  out = {}
  while i <= n do
    local c = s:byte(i)
    if c == 0 and i + 2 <= n then
      local run, b = s:byte(i+1), s:byte(i+2)
      out[#out+1] = string.rep(string.char(b), run)
      i = i + 3
    else
      out[#out+1] = s:sub(i,i)
      i = i + 1
    end
  end
  return table.concat(out)
end

local function derive(seed, sig, len)
  local key, state = {}, 0
  for i = 1, #sig do state = (state * 131 + sig:byte(i)) % 0x80000000 end
  state = (state + seed) % 0x80000000
  for i = 1, len do
    state = (1103515245 * state + 12345) % 0x80000000
    key[i] = math.floor(state / 65536) % 256
  end
  return key
end

local function xor_s(d, k)
  local out, kl = {}, #k
  for i = 1, #d do out[i] = string.char(d:byte(i) ~ k[((i-1) % kl) + 1]) end
  return table.concat(out)
end

local function caesar_rev(d, sh)
  sh = sh % 256
  local t = {}
  for i = 1, #d do t[i] = string.char((d:byte(i) - sh) % 256) end
  return table.concat(t)
end

local ok, meta = pcall(function()
  return (load("return " .. _META:gsub("null", "nil")))()
end)
if not ok or type(meta) ~= "table" then
  if gg and gg.alert then gg.alert("Protected script: bad meta") end
  return
end

local seed = tonumber(meta.seed) or 0
local sig = tostring(meta.sig or "")
local klen = tonumber(meta.klen) or 256
local key = derive(seed, sig, klen)
local revk = {}
for i = 1, #key do revk[i] = key[#key - ((i-1) % #key)] end

local stage3 = rle_decomp(b64d(_PAY))
local after = xor_s(stage3, revk)
local s2 = caesar_rev(after, seed % 256)
local plain = xor_s(s2, key)

local fn, err = load(plain, "@protected")
if not fn then
  if gg and gg.alert then gg.alert("Decrypt/load failed: " .. tostring(err)) end
  return
end
fn()
'''


def build_protected_lua(plain_text: str, seed: int | None = None) -> str:
    plain = plain_text.encode("utf-8")
    encoded, header_enc, meta = encrypt_payload(plain, seed=seed)
    # meta for loader (Lua table-ish JSON subset)
    meta_public = {
        "build": meta["build"],
        "seed": meta["seed"],
        "sig": meta["sig"],
        "klen": meta["klen"],
    }
    # JSON is fine if we convert true/false/null; we only have numbers/strings
    meta_json = json.dumps(meta_public)
    # Lua load("return {...}") needs Lua table — convert JSON object to Lua
    meta_lua = meta_json
    meta_lua = meta_lua.replace("{", "{").replace("}", "}")
    # simpler: emit Lua table literal
    meta_lua = (
        "{"
        f"build={json.dumps(meta_public['build'])},"
        f"seed={meta_public['seed']},"
        f"sig={json.dumps(meta_public['sig'])},"
        f"klen={meta_public['klen']}"
        "}"
    )
    body = (LOADER_TEMPLATE
        .replace("__BUILD__", meta["build"])
        .replace("__PAYLOAD__", encoded)
        .replace("__META__", meta_lua)
    )
    # Also embed machine-readable trailer for Python decrypt
    trailer = (
        "\n--CRYPT_META:"
        + json.dumps(
            {
                "seed": meta["seed"],
                "sig": meta["sig"],
                "klen": meta["klen"],
                "payload_b64": encoded,
                "sig_full": meta["sig_full"],
            }
        )
        + "\n"
    )
    return BANNER + body + trailer


def extract_and_decrypt_protected(text: str) -> bytes:
    m = re.search(r"--CRYPT_META:(\{.*\})", text)
    if not m:
        # try extract _PAY and _META from loader
        pay = re.search(r"local _PAY = \[\[(.*?)\]\]", text, re.S)
        meta = re.search(r"local _META = \[\[(.*?)\]\]", text, re.S)
        if not pay or not meta:
            raise ValueError("No CRYPT_META trailer and could not parse loader payload")
        # meta is Lua table — parse seed/sig/klen
        mt = meta.group(1)
        seed = int(re.search(r"seed=(%d+)", mt).group(1))
        sig = re.search(r'sig="([0-9a-fA-F]+)"', mt).group(1)
        klen = int(re.search(r"klen=(%d+)", mt).group(1))
        return decrypt_with_meta(pay.group(1), seed, sig, klen)

    meta = json.loads(m.group(1))
    plain = decrypt_with_meta(meta["payload_b64"], meta["seed"], meta["sig"], meta["klen"])
    # optional full integrity
    if meta.get("sig_full"):
        if sha256_hex(plain) != meta["sig_full"]:
            raise ValueError("Integrity check failed (SHA256 mismatch)")
    return plain


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def cmd_encrypt(args: argparse.Namespace) -> None:
    src = args.infile.read_text(encoding="utf-8", errors="ignore")
    out = build_protected_lua(src, seed=args.seed)
    args.outfile.write_text(out, encoding="utf-8")
    print(f"[+] Encrypted → {args.outfile} ({len(out)} bytes)")
    print("    Run the output in GameGuardian; it decrypts in memory then executes.")


def cmd_decrypt(args: argparse.Namespace) -> None:
    text = args.infile.read_text(encoding="utf-8", errors="ignore")
    plain = extract_and_decrypt_protected(text)
    args.outfile.write_bytes(plain)
    print(f"[+] Decrypted → {args.outfile} ({len(plain)} bytes)")


def cmd_info(args: argparse.Namespace) -> None:
    text = args.infile.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"--CRYPT_META:(\{.*\})", text)
    if m:
        meta = json.loads(m.group(1))
        print("Protected file meta:")
        for k in ("seed", "sig", "klen"):
            print(f"  {k}: {meta.get(k)}")
        try:
            plain = extract_and_decrypt_protected(text)
            print(f"  integrity: OK ({len(plain)} bytes plaintext)")
        except Exception as e:
            print(f"  integrity: FAIL ({e})")
    else:
        print("No CRYPT_META trailer found (may still be a loader).")


def main() -> None:
    ap = argparse.ArgumentParser(description="Clean Lua script encrypt/decrypt (Kinzi-style pipeline)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("encrypt", help="Encrypt .lua → protected loader")
    p.add_argument("--in", dest="infile", type=Path, required=True)
    p.add_argument("--out", dest="outfile", type=Path, required=True)
    p.add_argument("--seed", type=int, default=None, help="Optional fixed seed")
    p.set_defaults(func=cmd_encrypt)

    p = sub.add_parser("decrypt", help="Decrypt protected → plain .lua")
    p.add_argument("--in", dest="infile", type=Path, required=True)
    p.add_argument("--out", dest="outfile", type=Path, required=True)
    p.set_defaults(func=cmd_decrypt)

    p = sub.add_parser("info", help="Show meta / verify integrity")
    p.add_argument("--in", dest="infile", type=Path, required=True)
    p.set_defaults(func=cmd_info)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
