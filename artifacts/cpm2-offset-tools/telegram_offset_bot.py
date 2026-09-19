#!/usr/bin/env python3
"""
CPM2 Telegram Offset Updater Bot
================================
Send OLD dump → NEW dump → script (.lua)
Receives updated script + mapping report.

Dumps > 20 MB must be ZIP'd (Telegram bot download limit).

Windows PowerShell:
  $env:BOT_TOKEN = "TOKEN"
  $env:ALLOWED_IDS = "6067014733"
  python telegram_offset_bot.py
"""

from __future__ import annotations

import asyncio
import logging
import os
import re
import tempfile
import time
import zipfile
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

from telegram import Update, Document
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from telegram.error import Forbidden, BadRequest

BOT_TOKEN = os.environ.get("BOT_TOKEN", "").strip()
ALLOWED_IDS = {
    int(x.strip())
    for x in os.environ.get("ALLOWED_IDS", "").split(",")
    if x.strip().isdigit()
}
MAX_TG_DOWNLOAD = 20 * 1024 * 1024

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")
log = logging.getLogger("offset_bot")

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


def parse_dump(path: Path) -> Dict[int, List[Tuple[str, str]]]:
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
            return nrva, (ncls, meth), f"name-only ({cls}→{ncls})"
    return None, None, "not found"


def update_script(script_text, old_map, new_cm, new_meth):
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
        report.append(f"{old_hex}  →  {new_hex}  {tag}{extra}")
        stats["mapped"] += 1

    new_text = script_text
    for oh, nh in sorted(replacements.items(), key=lambda x: -len(x[0])):
        new_text = re.sub(rf"\b{re.escape(oh)}\b", nh, new_text, flags=re.I)

    report_text = (
        "OFFSET MAPPING REPORT (Kinzi-style)\n"
        "====================================\n"
        f"Total : {stats['total']}\nMapped: {stats['mapped']}\nSame  : {stats['same']}\n"
        f"Missing: {stats['missing']}\n±4    : {stats['pm4']}\nName-only: {stats['name_only']}\n\n"
        + "\n".join(report) + "\n"
    )
    return new_text, report_text, stats


def allowed(update: Update) -> bool:
    if not ALLOWED_IDS:
        return True
    uid = update.effective_user.id if update.effective_user else 0
    return uid in ALLOWED_IDS


def cleanup(*paths):
    import shutil
    for p in paths:
        if not p:
            continue
        path = Path(p)
        try:
            if path.is_dir():
                shutil.rmtree(path, ignore_errors=True)
            elif path.exists():
                path.unlink()
        except OSError:
            pass


async def download_and_extract(doc: Document) -> Path:
    size = doc.file_size or 0
    name = (doc.file_name or "file").lower()
    if size > MAX_TG_DOWNLOAD:
        raise ValueError(
            f"File too big ({size/1e6:.1f} MB). Telegram limit 20 MB.\n"
            "Zip the dump.cs first, then send the .zip"
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
            raise ValueError("File too big (20 MB limit). Zip the dump first.") from e
        raise

    if name.endswith(".zip") or zipfile.is_zipfile(tmp_path):
        extract_dir = Path(tempfile.mkdtemp(prefix="dump_"))
        try:
            with zipfile.ZipFile(tmp_path, "r") as zf:
                zf.extractall(extract_dir)
            cleanup(tmp_path)
            candidates = list(extract_dir.rglob("*.cs")) + list(extract_dir.rglob("*.txt"))
            if not candidates:
                cleanup(extract_dir)
                raise ValueError("ZIP has no .cs/.txt inside.")
            candidates.sort(key=lambda p: p.stat().st_size, reverse=True)
            return candidates[0]
        except zipfile.BadZipFile:
            cleanup(tmp_path, extract_dir)
            raise ValueError("Invalid ZIP.")
    return tmp_path


async def error_handler(update, context):
    if isinstance(context.error, Forbidden):
        log.warning("User blocked bot")
    else:
        log.error(f"Error: {context.error}")


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not allowed(update):
        await update.message.reply_text("Not authorized.")
        return
    cleanup(
        context.user_data.get("old_dump"),
        context.user_data.get("new_dump"),
        context.user_data.get("old_dir"),
        context.user_data.get("new_dir"),
    )
    context.user_data.clear()
    context.user_data["step"] = "old_dump"
    await update.message.reply_text(
        "CPM2 Offset Updater (Kinzi-style)\n\n"
        "Telegram limit 20 MB — ZIP big dumps.\n\n"
        "1. OLD dump (.cs / .zip)\n"
        "2. NEW dump (.cs / .zip)\n"
        "3. Script (.lua)\n\n"
        "Send OLD dump now.\n/cancel to abort"
    )


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cleanup(
        context.user_data.get("old_dump"),
        context.user_data.get("new_dump"),
        context.user_data.get("old_dir"),
        context.user_data.get("new_dir"),
    )
    context.user_data.clear()
    await update.message.reply_text("Cancelled. /start to begin.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        if not allowed(update):
            return
        step = context.user_data.get("step")
        if not step:
            await update.message.reply_text("Send /start")
            return
        if update.message.text and not update.message.document:
            await update.message.reply_text(f"Send a file. Step: {step}")
            return
        doc = update.message.document
        if not doc:
            return
        name = (doc.file_name or "").lower()

        if step == "old_dump":
            if not any(name.endswith(x) for x in (".cs", ".txt", ".zip")) and "dump" not in name:
                await update.message.reply_text("Send OLD dump (.cs or .zip)")
                return
            await update.message.reply_text("Downloading OLD dump...")
            try:
                path = await download_and_extract(doc)
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            context.user_data["old_dump"] = str(path)
            if path.parent.name.startswith("dump_"):
                context.user_data["old_dir"] = str(path.parent)
            context.user_data["step"] = "new_dump"
            await update.message.reply_text(
                f"OLD OK ({path.stat().st_size/1e6:.1f} MB)\nSend NEW dump (.cs or .zip)"
            )
            return

        if step == "new_dump":
            if not any(name.endswith(x) for x in (".cs", ".txt", ".zip")) and "dump" not in name:
                await update.message.reply_text("Send NEW dump (.cs or .zip)")
                return
            await update.message.reply_text("Downloading NEW dump...")
            try:
                path = await download_and_extract(doc)
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            context.user_data["new_dump"] = str(path)
            if path.parent.name.startswith("dump_"):
                context.user_data["new_dir"] = str(path.parent)
            context.user_data["step"] = "script"
            await update.message.reply_text(
                f"NEW OK ({path.stat().st_size/1e6:.1f} MB)\nSend .lua script"
            )
            return

        if step == "script":
            if not (name.endswith(".lua") or name.endswith(".txt")):
                await update.message.reply_text("Send .lua script")
                return
            status = await update.message.reply_text("Working... (1–3 min for big dumps)")
            try:
                script_path = await download_and_extract(doc)
            except Exception as e:
                await status.edit_text(f"Script fail: {e}")
                return
            old_path = Path(context.user_data["old_dump"])
            new_path = Path(context.user_data["new_dump"])
            try:
                loop = asyncio.get_event_loop()
                await status.edit_text("Parsing OLD dump...")
                old_map = await loop.run_in_executor(None, parse_dump, old_path)
                await status.edit_text("Parsing NEW dump...")
                new_map = await loop.run_in_executor(None, parse_dump, new_path)
                new_cm = build_cm_index(new_map)
                new_meth = build_method_index(new_map)
                await status.edit_text("Mapping offsets...")
                script_text = script_path.read_text(encoding="utf-8", errors="ignore")
                new_script, report, stats = update_script(script_text, old_map, new_cm, new_meth)
                out_s = Path(tempfile.gettempdir()) / "CPM2_UPDATED.lua"
                out_r = Path(tempfile.gettempdir()) / "offset_mapping_report.txt"
                out_s.write_text(new_script, encoding="utf-8")
                out_r.write_text(report, encoding="utf-8")
                await status.edit_text(
                    f"Done!\n"
                    f"Total {stats['total']} | Mapped {stats['mapped']} | "
                    f"Same {stats['same']} | Missing {stats['missing']}\n"
                    f"±4 {stats['pm4']} | name-only {stats['name_only']}\n"
                    f"Sending..."
                )
                await update.message.reply_document(document=out_s.open("rb"), filename="CPM2_UPDATED.lua")
                await update.message.reply_document(document=out_r.open("rb"), filename="offset_mapping_report.txt")
                await update.message.reply_text("Test race + free buy. /start for next.")
            except Exception as e:
                log.exception("fail")
                await status.edit_text(f"Error: {e}")
            finally:
                cleanup(
                    context.user_data.get("old_dump"),
                    context.user_data.get("new_dump"),
                    context.user_data.get("old_dir"),
                    context.user_data.get("new_dir"),
                    str(script_path),
                )
                context.user_data.clear()
    except Exception as e:
        log.error(f"handle_message: {e}")


def main():
    if not BOT_TOKEN:
        raise SystemExit(
            "Set BOT_TOKEN\n"
            'Windows:  $env:BOT_TOKEN="TOKEN"; $env:ALLOWED_IDS="6067014733"; python telegram_offset_bot.py'
        )
    while True:
        try:
            app = Application.builder().token(BOT_TOKEN).build()
            app.add_handler(CommandHandler("start", start))
            app.add_handler(CommandHandler("cancel", cancel))
            app.add_handler(MessageHandler(filters.ALL & ~filters.COMMAND, handle_message))
            app.add_error_handler(error_handler)
            log.info("Bot started")
            app.run_polling(drop_pending_updates=True)
        except Exception as e:
            log.error(f"Restart in 5s: {e}")
            time.sleep(5)


if __name__ == "__main__":
    main()
