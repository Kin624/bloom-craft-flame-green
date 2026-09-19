#!/usr/bin/env python3
"""
Telegram bot: unlock CPM police lights + sirens (IDs 1,2,3)
Send email:password after /start
"""

import asyncio
import base64
import json
import struct
from copy import deepcopy
from typing import Any, Dict, List, Optional

import aiohttp
import brotli
import telebot

# ============================================================
#  CONFIG
# ============================================================

API_TOKEN = "7541631633:AAEbNlIt0jcYJv8gemnZzYLrnEBjO5IE7ZY"
ADMIN_ID = 6067014733

FIREBASE_KEY = "AIzaSyAe_aOVT1gSfmHKBrorFvX4fRwN5nODXVA"
FB_VERIFY = (
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/"
    f"verifyPassword?key={FIREBASE_KEY}"
)
SAVE_URL = "https://europe-west1-cp-multiplayer.cloudfunctions.net/SavePlayerRecordsPartially8"
LOAD_URL = "https://europe-west1-cp-multiplayer.cloudfunctions.net/GetPlayerRecords8"

GAME_HEADERS = {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Content-Type": "application/json",
    "User-Agent": "UnityPlayer/2022.3.62f2 (UnityWebRequest/1.0, libcurl/8.10.1-DEV)",
    "X-Unity-Version": "2022.3.62f2",
}

POLICE_UNLOCK_IDS = [1, 2, 3]

FIELD_MAPPING = [
    (1, "localID"),
    (2, "money"),
    (3, "Name"),
    (4, "coin"),
    (5, "allData"),
    (6, "boughtFsos"),
    (7, "boughtPoliceLights"),
    (8, "boughtPoliceSirens"),
    (9, "FriendsID"),
    (10, "LevelsDoneTime"),
    (11, "floats"),
    (12, "integers"),
    (13, "fcar"),
    (14, "favouriteWheels"),
    (15, "favouriteVinyls"),
    (16, "favouriteEmojis"),
    (17, "premiumA"),
    (18, "emojiPacks"),
    (21, "premium21"),
    (24, "premium24"),
    (26, "premium26"),
    (27, "premium27"),
    (28, "premium28"),
    (29, "premium29"),
    (30, "premiumB"),
    (41, "personEquipmentsMale"),
    (42, "personEquipmentsFemale"),
    (43, "platesData"),
    (44, "carIDnStatus"),
    (45, "flags"),
    (46, "animations"),
    (48, "wheels"),
]
INT_LIST_FIELDS = {6, 7, 8, 12, 13, 14, 15, 16, 18, 21, 24, 26, 27, 28, 29, 46, 48}
FLOAT_LIST_FIELDS = {10, 11}
ALWAYS_SEND = {"allData"}


# ============================================================
#  CRYPTO / SERIALIZE
# ============================================================

def make_xor_key(uid: str) -> bytes:
    chars = list(str(uid or ""))
    if len(chars) >= 9:
        chars[1], chars[8] = chars[8], chars[1]
    if len(chars) >= 3:
        chars.pop(2)
    if len(chars) >= 5:
        chars.append(chars[4])
    key = "".join(chars).encode("utf-8")
    return key or b"0"


def xor_bytes(data: bytes, key: bytes) -> bytes:
    return bytes(data[i] ^ key[i % len(key)] for i in range(len(data)))


class Writer:
    def __init__(self):
        self._p: List[bytes] = []

    def write_byte(self, v):
        self._p.append(bytes([int(v or 0) & 0xFF]))

    def write_int(self, v):
        self._p.append(struct.pack("<i", int(v or 0)))

    def write_float(self, v):
        self._p.append(struct.pack("<f", float(v or 0.0)))

    def write_string(self, s):
        if s is None:
            self._p.append(struct.pack("<i", -1))
            return
        s = str(s)
        if s == "":
            self._p.append(struct.pack("<i", 0))
            return
        enc = s.encode("utf-8")
        self._p.append(struct.pack("<ii", -(len(enc)) - 1, len(s)) + enc)

    def write_list(self, lst, fn):
        if lst is None:
            self._p.append(struct.pack("<i", -1))
            return
        self._p.append(struct.pack("<i", len(lst)))
        for item in lst:
            fn(item)

    def to_bytes(self):
        return b"".join(self._p)


class Reader:
    def __init__(self, data: bytes):
        self.buf = data
        self.pos = 0

    def has(self, n: int) -> bool:
        return self.pos + n <= len(self.buf)

    def read_byte(self) -> int:
        if not self.has(1):
            return 0
        v = self.buf[self.pos]
        self.pos += 1
        return v

    def read_int(self) -> int:
        if not self.has(4):
            return 0
        v = struct.unpack("<i", self.buf[self.pos : self.pos + 4])[0]
        self.pos += 4
        return v

    def read_float(self) -> float:
        if not self.has(4):
            return 0.0
        v = struct.unpack("<f", self.buf[self.pos : self.pos + 4])[0]
        self.pos += 4
        return v

    def read_string(self) -> Optional[str]:
        if not self.has(4):
            return None
        n = struct.unpack("<i", self.buf[self.pos : self.pos + 4])[0]
        self.pos += 4
        if n == -1:
            return None
        if n == 0:
            return ""
        if n < 0:
            if not self.has(4):
                return None
            char_count = struct.unpack("<i", self.buf[self.pos : self.pos + 4])[0]
            self.pos += 4
            byte_len = -n - 1
            if not self.has(byte_len):
                return None
            raw = self.buf[self.pos : self.pos + byte_len]
            self.pos += byte_len
            try:
                return raw.decode("utf-8")
            except Exception:
                return raw.decode("utf-8", errors="replace")
        if not self.has(n):
            return None
        raw = self.buf[self.pos : self.pos + n]
        self.pos += n
        try:
            return raw.decode("utf-8")
        except Exception:
            return raw.decode("utf-8", errors="replace")

    def read_list(self, fn):
        if not self.has(4):
            return []
        n = struct.unpack("<i", self.buf[self.pos : self.pos + 4])[0]
        self.pos += 4
        if n < 0:
            return []
        out = []
        for _ in range(n):
            out.append(fn())
        return out


def serialize_field(fid: int, value: Any) -> Optional[bytes]:
    w = Writer()
    if fid in (1, 3, 5):
        w.write_string(value)
        return w.to_bytes()
    if fid in (2, 4, 17, 30):
        w.write_int(value or 0)
        return w.to_bytes()
    if fid in INT_LIST_FIELDS:
        w.write_list(value or [], w.write_int)
        return w.to_bytes()
    if fid in FLOAT_LIST_FIELDS:
        w.write_list(value or [], w.write_float)
        return w.to_bytes()
    return None


def parse_field(fid: int, raw: bytes) -> Any:
    r = Reader(raw)
    if fid in (1, 3, 5):
        return r.read_string()
    if fid in (2, 4, 17, 30):
        return r.read_int()
    if fid in INT_LIST_FIELDS:
        return r.read_list(r.read_int)
    if fid in FLOAT_LIST_FIELDS:
        return r.read_list(r.read_float)
    return None


def build_payload(
    record: Dict[str, Any],
    firebase_uid: str,
    original: Optional[Dict[str, Any]] = None,
    force_fields: Optional[set] = None,
) -> str:
    force_fields = set(force_fields or [])
    fields = []
    for fid, key in FIELD_MAPPING:
        value = record.get(key)
        if value is None:
            continue
        if key in ALWAYS_SEND:
            should_send = isinstance(value, str) and len(value) > 0
        elif key in force_fields:
            should_send = True
        elif original is not None:
            should_send = original.get(key) != value
        else:
            should_send = True
        if not should_send:
            continue
        raw = serialize_field(fid, value)
        if raw is not None:
            fields.append((fid, raw))
    parts = [struct.pack("<i", len(fields))]
    for fid, raw in fields:
        parts.append(struct.pack("<hi", fid, len(raw)))
        parts.append(raw)
    combined = b"".join(parts)
    compressed = brotli.compress(combined)
    encrypted = xor_bytes(compressed, make_xor_key(firebase_uid))
    return base64.b64encode(encrypted).decode("ascii")


def parse_payload(b64: str, firebase_uid: str) -> Optional[Dict[str, Any]]:
    try:
        encrypted = base64.b64decode(b64)
    except Exception:
        return None
    key = make_xor_key(firebase_uid)
    try:
        compressed = xor_bytes(encrypted, key)
        combined = brotli.decompress(compressed)
    except Exception:
        return None

    r = Reader(combined)
    n_fields = r.read_int()
    if n_fields < 0 or n_fields > 200:
        return None

    fid_to_key = {fid: key for fid, key in FIELD_MAPPING}
    record: Dict[str, Any] = {}
    for _ in range(n_fields):
        if not r.has(6):
            break
        fid = struct.unpack("<h", r.buf[r.pos : r.pos + 2])[0]
        r.pos += 2
        length = r.read_int()
        if length < 0 or not r.has(length):
            break
        raw = r.buf[r.pos : r.pos + length]
        r.pos += length
        key = fid_to_key.get(fid)
        if key is None:
            continue
        val = parse_field(fid, raw)
        if val is not None:
            record[key] = val
    return record if record else None


def _ok(value: Any) -> bool:
    if value in (1, True):
        return True
    if value in (0, False, None):
        return False
    if isinstance(value, str):
        text = value.strip()
        if text == "1":
            return True
        if text == "0":
            return False
        try:
            return _ok(json.loads(text))
        except Exception:
            return False
    if isinstance(value, dict):
        for key in ("result", "ok", "success"):
            if key in value:
                return _ok(value[key])
    return False


async def _post(
    url: str, payload: Dict[str, Any], headers: Dict[str, str]
) -> Optional[Dict[str, Any]]:
    timeout = aiohttp.ClientTimeout(total=30.0, connect=10.0, sock_read=30.0)
    clean = {k: v for k, v in headers.items() if k.lower() != "host"}
    async with aiohttp.ClientSession(timeout=timeout) as session:
        async with session.post(url, json=payload, headers=clean) as resp:
            text = await resp.text()
            try:
                parsed = json.loads(text)
                if resp.status >= 400 and isinstance(parsed, dict):
                    parsed["_http_status"] = resp.status
                return parsed
            except Exception:
                return {"raw": text, "status": resp.status}


# ============================================================
#  LOGIN + LOAD + UNLOCK
# ============================================================

async def firebase_login(email: str, password: str) -> Dict[str, Any]:
    timeout = aiohttp.ClientTimeout(total=30)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        async with session.post(
            FB_VERIFY,
            json={
                "email": email,
                "password": password,
                "returnSecureToken": True,
            },
        ) as resp:
            data = await resp.json()
    if "idToken" not in data or "localId" not in data:
        msg = data.get("error", {}).get("message", "login failed")
        raise ValueError(msg)
    return {"token": data["idToken"], "uid": data["localId"]}


def _extract_b64(obj: Any) -> Optional[str]:
    """Walk common CPM response shapes and pull out a base64 blob."""
    if isinstance(obj, str) and len(obj) > 40:
        return obj
    if not isinstance(obj, dict):
        return None
    for k in ("base64", "record", "data", "result", "payload"):
        v = obj.get(k)
        if isinstance(v, str) and len(v) > 40:
            return v
        if isinstance(v, dict):
            found = _extract_b64(v)
            if found:
                return found
    return None


async def load_record(auth: str, firebase_uid: str):
    """
    Returns (record_dict | None, debug_str).
    Tries multiple payload / header combinations used by different CPM clients.
    """
    debug_lines = []
    headers_list = [
        {
            **GAME_HEADERS,
            "Authorization": f"Bearer {auth}",
            "Connection": "Keep-Alive",
        },
        {
            **GAME_HEADERS,
            "Authorization": f"Bearer {auth}",
            "Connection": "Keep-Alive",
            "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 12; Pixel 6 Build/SD1A.210817.036)",
        },
    ]
    device_short = firebase_uid[:8] if len(firebase_uid) >= 8 else firebase_uid
    candidates = [
        {"data": {"deviceId": device_short}},
        {"data": {"deviceId": firebase_uid}},
        {"data": {"uid": firebase_uid, "deviceId": device_short}},
        {"data": firebase_uid},
        {"uid": firebase_uid, "deviceId": device_short},
        {"uid": firebase_uid},
        {"data": {"uid": firebase_uid}},
        {"localId": firebase_uid},
        {"data": {"localId": firebase_uid}},
    ]

    for headers in headers_list:
        for payload in candidates:
            result = await _post(LOAD_URL, payload, headers)
            if not result:
                debug_lines.append(f"empty resp for {payload}")
                continue
            keys = list(result.keys()) if isinstance(result, dict) else type(result).__name__
            debug_lines.append(f"payload={payload} → keys={keys}")
            b64 = _extract_b64(result)
            if not b64:
                snippet = str(result)[:180]
                debug_lines.append(f"  no b64, snippet: {snippet}")
                continue
            parsed = parse_payload(b64, firebase_uid)
            if parsed and parsed.get("Name") is not None:
                return parsed, "ok"
            if parsed:
                debug_lines.append(f"  parsed keys={list(parsed.keys())} but no Name")
            else:
                debug_lines.append("  b64 present but parse_payload failed")

    return None, "\n".join(debug_lines[-12:])


async def unlock_sirens(
    auth: str, firebase_uid: str, record: Dict[str, Any]
) -> Dict[str, Any]:
    if not record or record.get("Name") is None:
        return {"ok": False, "message": "Could not load account data."}
    if not firebase_uid:
        return {"ok": False, "message": "Missing firebase uid."}

    data = deepcopy(record)
    ids = list(POLICE_UNLOCK_IDS)
    data["boughtPoliceLights"] = list(ids)
    data["boughtPoliceSirens"] = list(ids)

    payload = build_payload(
        data,
        firebase_uid,
        original=record,
        force_fields={"boughtPoliceLights", "boughtPoliceSirens"},
    )
    result = await _post(
        SAVE_URL,
        {"data": {"data": payload, "deviceId": firebase_uid[:8]}},
        {
            **GAME_HEADERS,
            "Authorization": f"Bearer {auth}",
            "Connection": "Keep-Alive",
            "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 12; Pixel 6 Build/SD1A.210817.036)",
        },
    )
    if result and _ok(result):
        return {
            "ok": True,
            "message": (
                "Police lights and sirens set to 1, 2, 3.\n"
                "Stay out of CPM, then full relog."
            ),
            "record": data,
        }
    return {
        "ok": False,
        "message": f"CPM rejected police lights/sirens: {str(result)[:160]}",
    }


async def inject(email: str, password: str) -> str:
    try:
        creds = await firebase_login(email, password)
    except Exception as e:
        return f"Login failed: {e}"

    auth = creds["token"]
    uid = creds["uid"]

    record, debug = await load_record(auth, uid)
    if not record:
        return (
            "Logged in (uid ok), but could not load player records.\n"
            "Possible causes: never saved in-game, wrong endpoint, or empty cloud save.\n\n"
            f"uid: {uid}\n"
            f"debug:\n{debug}"
        )

    name = record.get("Name") or "?"
    before_l = record.get("boughtPoliceLights") or []
    before_s = record.get("boughtPoliceSirens") or []

    result = await unlock_sirens(auth, uid, record)
    if result.get("ok"):
        return (
            f"OK — {name}\n"
            f"Lights before: {before_l}\n"
            f"Sirens before: {before_s}\n"
            f"{result['message']}"
        )
    return f"Failed for {name}: {result.get('message', 'unknown')}"


# ============================================================
#  TELEGRAM BOT
# ============================================================

bot = telebot.TeleBot(API_TOKEN)
sessions: Dict[int, bool] = {}


@bot.message_handler(commands=["start"])
def cmd_start(message):
    if message.from_user.id != ADMIN_ID:
        bot.reply_to(message, "Not allowed.")
        return
    sessions[message.from_user.id] = True
    bot.reply_to(
        message,
        "CPM Police Lights / Sirens unlock\n\n"
        "Send the account as:\n`email:password`",
        parse_mode="Markdown",
    )


@bot.message_handler(
    func=lambda m: m.from_user.id == ADMIN_ID and sessions.get(m.from_user.id)
)
def handle(message):
    sessions.pop(message.from_user.id, None)
    text = (message.text or "").strip()
    if ":" not in text:
        bot.reply_to(message, "Wrong format. Send:\n`email:password`", parse_mode="Markdown")
        return
    email, _, password = text.partition(":")
    bot.reply_to(message, "Unlocking police lights & sirens...")
    try:
        result = asyncio.run(inject(email.strip(), password.strip()))
    except Exception as exc:
        result = f"Failed: {exc}"
    bot.reply_to(message, result)


if __name__ == "__main__":
    print("Bot is running...")
    bot.infinity_polling()
