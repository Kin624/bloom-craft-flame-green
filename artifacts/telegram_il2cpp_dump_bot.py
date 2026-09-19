#!/usr/bin/env python3
"""
IL2CPP Auto Dump Bot v1.1
=========================
Telegram bot matching Rodroid Il2CppDumper options 1:1.

Flow:
  1. Send global-metadata.dat
  2. Send libil2cpp.so / GameAssembly.dll
  3. Bot validates magic + auto-detects version
  4. Runs dump with the same config.json options as Rodroid

Rodroid options mirrored (from rodroid-il2cppdumper config.json / types.ts):
  Output        : methods, fields, properties, attributes, offsets, typedef, assembly
  Generation    : struct, DummyDLL, tokens
  Generics      : RGCTX, MethodSpecs, attributes, strings, usages, vtables, interfaces
  Disassembly   : target, hex, field names, annotations, CFG, max instructions
  C++ Headers   : scaffold, mangling, IDA metadata, Unity headers, topological sort, GCC/MSVC
  Advanced      : force version, force dump, no-redirected-pointer, CODM
  Static fields : thread-static / FieldRVA export

Usage:
  export BOT_TOKEN="..."
  export ALLOWED_IDS="123456789"
  export IL2CPP_DUMPER_BIN="/path/to/il2cpp_dumper"   # optional
  python telegram_il2cpp_dump_bot.py
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import struct
import subprocess
import tempfile
import time
import zipfile
from copy import deepcopy
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from telegram import Update, Document
from telegram.ext import (
    Application, CommandHandler, MessageHandler, filters, ContextTypes,
)
from telegram.error import Forbidden, BadRequest

# ── Bot config ──────────────────────────────────────────────────────────────
BOT_TOKEN = os.environ.get("BOT_TOKEN", "").strip()
ALLOWED_IDS = {
    int(x.strip())
    for x in os.environ.get("ALLOWED_IDS", "").split(",")
    if x.strip().isdigit()
}
MAX_TG_DOWNLOAD = 48 * 1024 * 1024
EXTERNAL_DUMPER = os.environ.get("IL2CPP_DUMPER_BIN", "il2cpp_dumper").strip()

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")
log = logging.getLogger("il2cpp_dump_bot")

# ── Exact Rodroid default config (from source config.json + types.ts) ───────
# Keep keys in camelCase so a config.json written for Rodroid CLI is identical.
RODROID_DEFAULT_CONFIG: Dict[str, Any] = {
    # Output
    "dumpMethod": True,
    "dumpField": True,
    "dumpProperty": True,
    "dumpAttribute": True,
    "dumpMethodOffset": True,
    "dumpFieldOffset": True,
    "dumpTypeDefIndex": True,
    "dumpAssemblyName": True,
    # Generation
    "generateStruct": True,
    "generateDummyDll": True,
    "requireAnyKey": True,
    "dummyDllAddToken": True,
    # Advanced / force
    "forceIl2cppVersion": False,
    "forceVersion": 31.0,
    "forceDump": False,
    "noRedirectedPointer": False,
    "splitDumpPerType": False,
    # Generics
    "generateGenericsDump": True,
    "dumpGenericsRgctx": True,
    "dumpGenericsMethodSpecs": True,
    "dumpGenericsCustomAttributes": True,
    "dumpGenericsStringLiterals": True,
    "dumpGenericsMetadataUsages": True,
    "dumpGenericsVtables": True,
    "dumpGenericsInterfaces": True,
    # Disassembly
    "dumpDisassembly": False,
    "dumpDisassemblyTarget": 0,          # 0=Both, 1=Flat dump.cs, 2=DiffableCs
    "dumpDisassemblyHexBytes": True,
    "dumpDisassemblyFieldNames": True,
    "dumpDisassemblyAnnotations": True,
    "dumpDisassemblyCfg": True,
    "maxDisassemblyInstructions": 512,
    # C++ / headers
    "generateCppScaffold": True,
    "mangleNames": True,
    "enhancedIdaMetadata": True,
    "generateUnityHeaders": True,
    "compilerLayout": "GCC",             # GCC | MSVC
    "useTopologicalSort": True,
    # Game-specific
    "codm": False,
    # Static field metadata (v6+)
    "dumpStaticFieldMetadata": False,
    "dumpFieldRvaData": False,
    "maxFieldRvaDumpBytes": 4096,
}

KNOWN_VERSIONS = {
    16, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    33, 35, 38, 39, 104, 105, 106,
}
VERSION_HINTS = {
    24: "Unity 2018–2019 era",
    27: "Unity 2020–2021",
    29: "Unity 2021–2022",
    31: "Unity 2021.3 / 2022.x (most common)",
    35: "Unity 6 early",
    38: "Unity 6",
    39: "Unity 6",
    104: "Unity 6 (undocumented)",
    106: "Unity 6 (undocumented)",
}
MAGIC = 0xFAB11BAF  # AF 1B B1 FA


# ── Metadata validation (auto version) ──────────────────────────────────────
@dataclass
class MetadataInfo:
    path: Path
    size: int
    magic: int
    version: int
    valid_magic: bool
    known_version: bool
    hint: str
    header_hex: str
    error: str = ""


def analyze_metadata(path: Path) -> MetadataInfo:
    size = path.stat().st_size
    try:
        with open(path, "rb") as f:
            raw = f.read(16)
        if len(raw) < 8:
            return MetadataInfo(
                path=path, size=size, magic=0, version=-1,
                valid_magic=False, known_version=False, hint="",
                header_hex=raw.hex(" ").upper(),
                error="File too small (< 8 bytes)",
            )
        header_hex = raw[:8].hex(" ").upper()
        magic, version = struct.unpack("<Ii", raw[:8])
    except Exception as e:
        return MetadataInfo(
            path=path, size=size, magic=0, version=-1,
            valid_magic=False, known_version=False, hint="",
            header_hex="", error=str(e),
        )

    valid_magic = magic == MAGIC
    known = version in KNOWN_VERSIONS
    hint = VERSION_HINTS.get(version, "")
    error = ""

    if not valid_magic:
        error = (
            f"Invalid magic 0x{magic:08X} (expected AF 1B B1 FA / 0xFAB11BAF). "
            "File is probably still encrypted or truncated. "
            "Dump decrypted metadata from memory (GG: h AF 1B B1 FA 1F 00 00 00)."
        )
    elif version < 16 or version > 200:
        error = (
            f"Suspicious version field ({version}). "
            "Header looks corrupted — often encryption or truncated dump."
        )
    elif not known:
        hint = f"Unknown version {version} — dumper may still try"

    return MetadataInfo(
        path=path, size=size, magic=magic, version=version,
        valid_magic=valid_magic, known_version=known,
        hint=hint, header_hex=header_hex, error=error,
    )


def format_metadata_report(info: MetadataInfo) -> str:
    lines = [
        "METADATA ANALYSIS",
        "=================",
        f"File     : {info.path.name}",
        f"Size     : {info.size / 1e6:.2f} MB ({info.size:,} bytes)",
        f"Header   : {info.header_hex}",
        f"Magic    : 0x{info.magic:08X}  {'✓ valid' if info.valid_magic else '✗ INVALID'}",
        f"Version  : {info.version}  {'✓ known' if info.known_version else '⚠ unknown/out of range'}",
    ]
    if info.hint:
        lines.append(f"Hint     : {info.hint}")
    if info.error:
        lines.append(f"\n⚠ PROBLEM:\n{info.error}")
    else:
        lines.append("\n✓ Header looks good — ready for dumping.")
    return "\n".join(lines)


def analyze_binary(path: Path) -> str:
    size = path.stat().st_size
    with open(path, "rb") as f:
        head = f.read(16)
    kind = "Unknown"
    if head[:4] == b"\x7fELF":
        kind = "ELF (Android/Linux libil2cpp.so)"
    elif head[:2] == b"MZ":
        kind = "PE (Windows GameAssembly.dll)"
    elif head[:4] in (
        b"\xfe\xed\xfa\xce", b"\xce\xfa\xed\xfe",
        b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe",
    ):
        kind = "Mach-O (iOS/macOS)"
    elif head[:4] == b"\x00asm":
        kind = "WASM (WebGL)"
    elif head[:4] == b"NSO0":
        kind = "NSO (Nintendo Switch)"
    return (
        f"BINARY ANALYSIS\n"
        f"===============\n"
        f"File : {path.name}\n"
        f"Size : {size / 1e6:.2f} MB\n"
        f"Type : {kind}\n"
    )


# ── Rodroid-compatible config helpers ───────────────────────────────────────
def build_dump_config(meta_version: int, overrides: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Build config.json identical to Rodroid defaults.
    Auto-fills forceVersion from detected metadata version when not forced.
    """
    cfg = deepcopy(RODROID_DEFAULT_CONFIG)
    # If user did not force a version, seed forceVersion with detected one
    # (Rodroid still prefers auto-detect; this just keeps the field consistent)
    if not cfg.get("forceIl2cppVersion"):
        cfg["forceVersion"] = float(meta_version)
    if overrides:
        cfg.update(overrides)
    return cfg


def write_config_json(cfg: Dict[str, Any], path: Path) -> Path:
    path.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
    return path


def format_config_summary(cfg: Dict[str, Any]) -> str:
    """Short human summary of active Rodroid options."""
    on = [k for k, v in cfg.items() if v is True]
    off = [k for k, v in cfg.items() if v is False]
    lines = [
        "RODROID CONFIG (same options as GUI)",
        "====================================",
        f"forceVersion          : {cfg.get('forceVersion')}",
        f"forceIl2cppVersion    : {cfg.get('forceIl2cppVersion')}",
        f"codm                  : {cfg.get('codm')}",
        f"splitDumpPerType      : {cfg.get('splitDumpPerType')}",
        f"dumpDisassembly       : {cfg.get('dumpDisassembly')}",
        f"generateDummyDll      : {cfg.get('generateDummyDll')}",
        f"generateStruct        : {cfg.get('generateStruct')}",
        f"generateCppScaffold   : {cfg.get('generateCppScaffold')}",
        f"dumpStaticFieldMetadata: {cfg.get('dumpStaticFieldMetadata')}",
        "",
        f"Enabled flags ({len(on)}): " + ", ".join(on[:12]) + (" ..." if len(on) > 12 else ""),
    ]
    return "\n".join(lines)


# ── External dumper ─────────────────────────────────────────────────────────
def try_external_dump(
    binary: Path,
    metadata: Path,
    out_dir: Path,
    config: Dict[str, Any],
) -> Tuple[bool, str]:
    """
    Call Rodroid / il2cpp_dumper CLI with a config.json that matches the GUI options.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    cfg_path = out_dir / "config.json"
    write_config_json(config, cfg_path)

    # Common CLI patterns:
    #   il2cpp_dumper <binary> <metadata> [out]
    #   some builds also accept --config
    cmd_variants = [
        [EXTERNAL_DUMPER, str(binary), str(metadata), str(out_dir)],
        [EXTERNAL_DUMPER, str(binary), str(metadata), str(out_dir), "--config", str(cfg_path)],
        [EXTERNAL_DUMPER, "--config", str(cfg_path), str(binary), str(metadata), str(out_dir)],
    ]

    last_err = ""
    for cmd in cmd_variants:
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=300, cwd=str(out_dir),
            )
            log_text = ((result.stdout or "") + "\n" + (result.stderr or "")).strip()
            if result.returncode == 0:
                return True, log_text or "OK"
            last_err = log_text or f"exit {result.returncode}"
            # if binary not found, no point trying other arg orders
            if "No such file" in last_err or "not found" in last_err.lower():
                break
        except FileNotFoundError:
            return False, (
                f"External dumper '{EXTERNAL_DUMPER}' not found.\n"
                "Install Rodroid CLI or set IL2CPP_DUMPER_BIN.\n"
                "Files were still validated with full Rodroid option set."
            )
        except subprocess.TimeoutExpired:
            return False, "Dumper timed out (>5 min)."
        except Exception as e:
            last_err = str(e)

    return False, last_err or "Dumper failed"


def collect_dump_outputs(out_dir: Path) -> List[Path]:
    wanted_names = {
        "dump.cs", "script.json", "stringliteral.json", "il2cpp.h",
        "static_metadata.json", "config.json",
    }
    found: List[Path] = []
    seen = set()
    for p in out_dir.rglob("*"):
        if not p.is_file():
            continue
        if p.name in wanted_names or p.suffix.lower() in {".cs", ".h", ".json"}:
            if p.stat().st_size > 0 and p.name not in seen:
                # prefer larger dump.cs
                found.append(p)
                seen.add(p.name)
    # put dump.cs first
    found.sort(key=lambda x: (0 if x.name == "dump.cs" else 1, -x.stat().st_size))
    return found[:8]


# ── Telegram helpers ────────────────────────────────────────────────────────
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
        if not path.exists():
            continue
        try:
            if path.is_dir():
                import shutil
                shutil.rmtree(path, ignore_errors=True)
            else:
                path.unlink(missing_ok=True)
        except OSError:
            pass


async def download_file(doc: Document, suffix: str = "") -> Path:
    size = doc.file_size or 0
    name = (doc.file_name or "file").lower()
    if size > MAX_TG_DOWNLOAD:
        raise ValueError(f"File too big ({size/1e6:.1f} MB).")

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix or Path(name).suffix or ".bin")
    tmp_path = Path(tmp.name)
    tmp.close()
    try:
        tg_file = await doc.get_file()
        await tg_file.download_to_drive(custom_path=str(tmp_path))
    except BadRequest as e:
        cleanup(tmp_path)
        if "too big" in str(e).lower():
            raise ValueError("File too big for Telegram download.") from e
        raise

    if name.endswith(".zip") or zipfile.is_zipfile(tmp_path):
        extract_dir = Path(tempfile.mkdtemp(prefix="il2cpp_"))
        try:
            with zipfile.ZipFile(tmp_path, "r") as zf:
                zf.extractall(extract_dir)
            cleanup(tmp_path)
            candidates = (
                list(extract_dir.rglob("global-metadata.dat"))
                + list(extract_dir.rglob("*metadata*"))
                + list(extract_dir.rglob("libil2cpp.so"))
                + list(extract_dir.rglob("GameAssembly.dll"))
                + list(extract_dir.rglob("*.so"))
                + list(extract_dir.rglob("*.dll"))
            )
            if not candidates:
                cleanup(extract_dir)
                raise ValueError("ZIP has no metadata or il2cpp binary.")
            candidates.sort(key=lambda p: p.stat().st_size, reverse=True)
            return candidates[0]
        except zipfile.BadZipFile:
            cleanup(tmp_path, extract_dir)
            raise ValueError("Invalid ZIP")
    return tmp_path


# ── Handlers ────────────────────────────────────────────────────────────────
async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE):
    if isinstance(context.error, Forbidden):
        log.warning("User blocked bot")
    else:
        log.error(f"Error: {context.error}")


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not allowed(update):
        await update.message.reply_text("Not authorized.")
        return
    cleanup(
        context.user_data.get("metadata"),
        context.user_data.get("binary"),
        context.user_data.get("work_dir"),
    )
    context.user_data.clear()
    context.user_data["step"] = "metadata"
    context.user_data["config"] = deepcopy(RODROID_DEFAULT_CONFIG)

    await update.message.reply_text(
        "IL2CPP Auto Dump Bot v1.1\n"
        "========================\n"
        "Rodroid options mirrored 1:1\n\n"
        "Flow:\n"
        "  1. global-metadata.dat\n"
        "  2. libil2cpp.so / GameAssembly.dll\n"
        "  3. Auto version + dump with full config\n\n"
        "Config groups (same as Rodroid GUI):\n"
        "  • Output (methods/fields/props/attrs/offsets)\n"
        "  • DummyDLL + structs\n"
        "  • Generics (RGCTX, MethodSpecs, …)\n"
        "  • Disassembly / CFG\n"
        "  • C++ scaffold + Unity headers\n"
        "  • CODM / static FieldRVA\n\n"
        "Commands:\n"
        "  /start   — begin\n"
        "  /options — show active Rodroid config\n"
        "  /codm    — toggle CODM mode\n"
        "  /cancel  — abort\n\n"
        "Send global-metadata.dat now."
    )


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cleanup(
        context.user_data.get("metadata"),
        context.user_data.get("binary"),
        context.user_data.get("work_dir"),
    )
    context.user_data.clear()
    await update.message.reply_text("Cancelled. /start again.")


async def options_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not allowed(update):
        return
    cfg = context.user_data.get("config") or RODROID_DEFAULT_CONFIG
    text = format_config_summary(cfg)
    if len(text) > 3900:
        text = text[:3900] + "\n..."
    await update.message.reply_text(f"<pre>{text}</pre>", parse_mode="HTML")


async def codm_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not allowed(update):
        return
    cfg = context.user_data.setdefault("config", deepcopy(RODROID_DEFAULT_CONFIG))
    cfg["codm"] = not cfg.get("codm", False)
    await update.message.reply_text(
        f"CODM mode is now {'ON' if cfg['codm'] else 'OFF'}.\n"
        "Same flag as Rodroid Advanced → CODM."
    )


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        if not allowed(update):
            return
        step = context.user_data.get("step")
        if not step:
            await update.message.reply_text("Send /start to begin.")
            return
        if update.message.text and not update.message.document:
            await update.message.reply_text(f"Send a file (step: {step}). Or /cancel")
            return

        doc = update.message.document
        if not doc:
            return

        # ── Step 1: metadata ───────────────────────────────────────────────
        if step == "metadata":
            await update.message.reply_text("Downloading metadata...")
            try:
                path = await download_file(doc, suffix=".dat")
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            except Exception as e:
                await update.message.reply_text(f"Download failed: {e}")
                return

            info = analyze_metadata(path)
            report = format_metadata_report(info)
            context.user_data["metadata"] = str(path)
            context.user_data["meta_info"] = info

            await update.message.reply_text(f"<pre>{report}</pre>", parse_mode="HTML")

            if not info.valid_magic or info.error:
                await update.message.reply_text(
                    "Metadata NOT ready.\n"
                    "Dump decrypted header first (GG search):\n"
                    "  h AF 1B B1 FA 1F 00 00 00\n"
                    "Then /start again."
                )
                cleanup(path)
                context.user_data.clear()
                return

            # seed config forceVersion with detected version
            cfg = context.user_data.setdefault("config", deepcopy(RODROID_DEFAULT_CONFIG))
            if not cfg.get("forceIl2cppVersion"):
                cfg["forceVersion"] = float(info.version)

            context.user_data["step"] = "binary"
            await update.message.reply_text(
                f"Metadata OK — version {info.version}"
                + (f" ({info.hint})" if info.hint else "")
                + "\n\nNow send binary:\n"
                "  • libil2cpp.so\n"
                "  • GameAssembly.dll\n"
                "  • or ZIP"
            )
            return

        # ── Step 2: binary ─────────────────────────────────────────────────
        if step == "binary":
            await update.message.reply_text("Downloading binary...")
            try:
                path = await download_file(doc, suffix=".so")
            except ValueError as e:
                await update.message.reply_text(str(e))
                return
            except Exception as e:
                await update.message.reply_text(f"Download failed: {e}")
                return

            context.user_data["binary"] = str(path)
            bin_report = analyze_binary(path)
            await update.message.reply_text(f"<pre>{bin_report}</pre>", parse_mode="HTML")

            meta_path = Path(context.user_data["metadata"])
            info: MetadataInfo = context.user_data["meta_info"]
            cfg = context.user_data.get("config") or build_dump_config(info.version)

            status = await update.message.reply_text(
                f"Files OK (metadata v{info.version}).\n"
                "Running dump with Rodroid-compatible config..."
            )

            work_dir = Path(tempfile.mkdtemp(prefix="dump_out_"))
            context.user_data["work_dir"] = str(work_dir)

            loop = asyncio.get_event_loop()
            success, dump_log = await loop.run_in_executor(
                None, try_external_dump, path, meta_path, work_dir, cfg
            )

            full_report = (
                format_metadata_report(info)
                + "\n\n"
                + bin_report
                + "\n\n"
                + format_config_summary(cfg)
                + "\n\nDUMP LOG\n========\n"
                + (dump_log or "")
            )
            report_path = work_dir / "il2cpp_dump_report.txt"
            report_path.write_text(full_report, encoding="utf-8")
            # always write the same config.json Rodroid uses
            write_config_json(cfg, work_dir / "config.json")

            if success:
                outputs = collect_dump_outputs(work_dir)
                await status.edit_text(
                    f"Dump finished ✓\n"
                    f"Version: {info.version}\n"
                    f"Outputs: {len(outputs)}\n"
                    "Sending..."
                )
                await update.message.reply_document(
                    document=report_path.open("rb"),
                    filename="il2cpp_dump_report.txt",
                    caption=f"Rodroid-compatible dump (v{info.version})",
                )
                for out in outputs:
                    try:
                        if out.is_file() and out.stat().st_size < 45 * 1024 * 1024:
                            await update.message.reply_document(
                                document=out.open("rb"),
                                filename=out.name,
                            )
                    except Exception as e:
                        log.warning(f"send {out}: {e}")
                await update.message.reply_text(
                    "Done. Options used = Rodroid defaults "
                    "(see config.json in the report folder).\n"
                    "/start for another game."
                )
            else:
                await status.edit_text(
                    "Dumper binary not available or failed.\n"
                    "Validation + full Rodroid config still produced."
                )
                await update.message.reply_document(
                    document=report_path.open("rb"),
                    filename="il2cpp_validation_report.txt",
                    caption=(
                        f"Validated v{info.version}. "
                        "Set IL2CPP_DUMPER_BIN to enable full dump."
                    ),
                )
                # also send the config so user can feed it to Rodroid GUI/CLI
                cfg_path = work_dir / "config.json"
                await update.message.reply_document(
                    document=cfg_path.open("rb"),
                    filename="config.json",
                    caption="Same config.json as Rodroid GUI — use offline if needed.",
                )
                await update.message.reply_text("/start for another run.")

            cleanup(meta_path, path)
            context.user_data.clear()
            return

    except Exception as e:
        log.exception("handle_message")
        try:
            await update.message.reply_text(f"Error: {e}")
        except Exception:
            pass


def main():
    if not BOT_TOKEN:
        raise SystemExit(
            "Set BOT_TOKEN:\n"
            '  export BOT_TOKEN="123:ABC..."\n'
            '  export ALLOWED_IDS="6067014733"\n'
            '  export IL2CPP_DUMPER_BIN="/path/to/il2cpp_dumper"\n'
            "  python telegram_il2cpp_dump_bot.py"
        )
    while True:
        try:
            app = Application.builder().token(BOT_TOKEN).build()
            app.add_handler(CommandHandler("start", start))
            app.add_handler(CommandHandler("cancel", cancel))
            app.add_handler(CommandHandler("options", options_cmd))
            app.add_handler(CommandHandler("codm", codm_cmd))
            app.add_handler(MessageHandler(filters.ALL & ~filters.COMMAND, handle_message))
            app.add_error_handler(error_handler)
            log.info("IL2CPP Auto Dump Bot v1.1 started (Rodroid options 1:1)")
            app.run_polling(drop_pending_updates=True)
        except Exception as e:
            log.error(f"Restart in 5s: {e}")
            time.sleep(5)


if __name__ == "__main__":
    main()
