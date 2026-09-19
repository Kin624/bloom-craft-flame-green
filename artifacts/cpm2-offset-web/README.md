---
title: CPM2 Offset Updater
emoji: 🔧
colorFrom: blue
colorTo: green
sdk: gradio
sdk_version: 4.44.0
app_file: app.py
pinned: false
---

# CPM2 Offset Updater (Web)

Upload old dump + new dump + Lua script → download updated script.

## Why not Vercel?

Vercel free body limit is ~4.5 MB. CPM2 dumps are ~45–50 MB.
Hugging Face Spaces handles large uploads better and is free.

## Deploy on Hugging Face Spaces (free)

1. Go to https://huggingface.co/new-space
2. Name: `cpm2-offset-updater`
3. SDK: **Gradio**
4. Visibility: Public or Private
5. Upload these files to the Space:
   - `app.py`
   - `offset_core.py`
   - `requirements.txt`
6. Wait for build → open the Space URL

## Local run

```bash
pip install -r requirements.txt
python app.py
```
