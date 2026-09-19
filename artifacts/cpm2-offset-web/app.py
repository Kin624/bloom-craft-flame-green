#!/usr/bin/env python3
"""
CPM2 Offset Updater — Web UI (Gradio)
Host free on Hugging Face Spaces (Vercel cannot accept 50MB dumps).
"""

from __future__ import annotations

import tempfile
import zipfile
from pathlib import Path

import gradio as gr

from offset_core import parse_dump_text, build_cm_index, build_method_index, update_script_text


def _read_upload(file_obj) -> str:
    """Read text from uploaded file path (Gradio) or extract .cs from zip."""
    if file_obj is None:
        raise ValueError("Missing file")
    path = Path(file_obj if isinstance(file_obj, str) else file_obj.name)
    name = path.name.lower()

    if name.endswith(".zip") or zipfile.is_zipfile(path):
        with zipfile.ZipFile(path, "r") as zf:
            candidates = [n for n in zf.namelist() if n.lower().endswith((".cs", ".txt", ".lua"))]
            if not candidates:
                raise ValueError(f"No .cs/.txt/.lua inside {path.name}")
            # largest file usually the dump
            candidates.sort(key=lambda n: zf.getinfo(n).file_size, reverse=True)
            with zf.open(candidates[0]) as f:
                return f.read().decode("utf-8", errors="ignore")
    return path.read_text(encoding="utf-8", errors="ignore")


def run_update(old_dump, new_dump, script_file, progress=gr.Progress()):
    if not old_dump or not new_dump or not script_file:
        return None, None, "Upload OLD dump, NEW dump, and script."

    try:
        progress(0.1, desc="Reading OLD dump...")
        old_text = _read_upload(old_dump)
        progress(0.25, desc="Parsing OLD dump...")
        old_map = parse_dump_text(old_text)

        progress(0.4, desc="Reading NEW dump...")
        new_text = _read_upload(new_dump)
        progress(0.55, desc="Parsing NEW dump...")
        new_map = parse_dump_text(new_text)
        new_cm = build_cm_index(new_map)
        new_meth = build_method_index(new_map)

        progress(0.75, desc="Reading script + mapping...")
        script_text = _read_upload(script_file)
        new_script, report, stats = update_script_text(script_text, old_map, new_cm, new_meth)

        out_dir = Path(tempfile.mkdtemp())
        out_script = out_dir / "CPM2_UPDATED.lua"
        out_report = out_dir / "offset_mapping_report.txt"
        out_script.write_text(new_script, encoding="utf-8")
        out_report.write_text(report, encoding="utf-8")

        summary = (
            f"Done.\n"
            f"Total: {stats['total']} | Mapped: {stats['mapped']} | "
            f"Same: {stats['same']} | Missing: {stats['missing']}\n"
            f"+/-4: {stats['pm4']} | name-only: {stats['name_only']}"
        )
        progress(1.0, desc="Done")
        return str(out_script), str(out_report), summary
    except Exception as e:
        return None, None, f"Error: {e}"


demo = gr.Blocks(title="CPM2 Offset Updater")
with demo:
    gr.Markdown(
        """
        # CPM2 Offset Updater
        Kinzi-style offline mapping: **old dump → new dump → updated Lua script**

        1. Upload **OLD** `dump.cs` (or `.zip`)
        2. Upload **NEW** `dump.cs` (or `.zip`)
        3. Upload your `.lua` script
        4. Click **Update offsets**

        Large dumps: zip them first if upload is slow.
        """
    )
    with gr.Row():
        old_in = gr.File(label="OLD dump (.cs / .zip)")
        new_in = gr.File(label="NEW dump (.cs / .zip)")
        script_in = gr.File(label="Script (.lua)")
    btn = gr.Button("Update offsets", variant="primary")
    status = gr.Textbox(label="Status", lines=4)
    with gr.Row():
        out_script = gr.File(label="Updated script")
        out_report = gr.File(label="Mapping report")
    btn.click(run_update, inputs=[old_in, new_in, script_in], outputs=[out_script, out_report, status])

if __name__ == "__main__":
    demo.queue().launch()
