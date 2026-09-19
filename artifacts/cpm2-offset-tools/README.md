# CPM2 Offset Tools (Kinzi-style)

Offline IL2CPP `dump.cs` offset updater for Car Parking Multiplayer 2 scripts.

Maps **old RVA → Class::Method → new RVA** (same idea as Kinzi Automatic Convertor), without needing the game running.

## Features

| Feature | Description |
|--------|-------------|
| **update** | Rewrite all offsets in a Lua script from old dump → new dump |
| **±4 fallback** | If exact RVA missing, try `-4` / `+4` (Kinzi `findClassSafe`) |
| **Name-only fallback** | Match method name if class renamed; copies new class name |
| **Ignore list** | Skips ARM constants / junk values |
| **kinzi mode** | Re-offset a `.kinzi` result file using only the new dump |
| **diff mode** | Methods only-in-old / only-in-new / RVA changed |
| **template mode** | Build a Lua patch-table template from a mapping report |
| **Telegram bot** | Send dumps + script in chat, get updated file back |

## Install

```bash
git clone https://github.com/YOUR_USER/cpm2-offset-tools.git
cd cpm2-offset-tools
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Linux / macOS
source .venv/bin/activate

pip install -r requirements.txt
```

## CLI usage

### 1) Update a script

```bash
python dump_offset_updater.py update \
  --old-dump old_1.3.2.3.cs \
  --new-dump latest.cs \
  --script   CPM2_CLEAN.lua \
  --out      CPM2_UPDATED.lua \
  --report   mapping_report.txt \
  --rewrite-header
```

### 2) Re-offset from Kinzi result file

```bash
python dump_offset_updater.py kinzi \
  --kinzi offset_results.kinzi \
  --new-dump latest.cs \
  --out reoffset.txt
```

### 3) Diff two dumps

```bash
python dump_offset_updater.py diff \
  --old-dump old.cs \
  --new-dump new.cs \
  --out diff_report.txt
```

### 4) Patch table template

```bash
python dump_offset_updater.py template \
  --report mapping_report.txt \
  --out patch_table.lua
```

## Telegram bot

1. Create a bot with [@BotFather](https://t.me/BotFather) → copy token  
2. Get your numeric user id (e.g. via `@userinfobot`)  
3. Run:

**Windows PowerShell**
```powershell
$env:BOT_TOKEN = "123456:AA..."
$env:ALLOWED_IDS = "6067014733"
python telegram_offset_bot.py
```

**Linux / macOS**
```bash
export BOT_TOKEN="123456:AA..."
export ALLOWED_IDS="6067014733"
python telegram_offset_bot.py
```

### Bot flow

```
/start
→ OLD dump.cs  (or .zip if > 20 MB)
→ NEW dump.cs  (or .zip)
→ script.lua
← CPM2_UPDATED.lua
← offset_mapping_report.txt
```

**Important:** Telegram bots can only download files ≤ **20 MB**.  
Zip large `dump.cs` files before sending.

## GitHub setup (first time)

```bash
cd cpm2-offset-tools
git init
git add dump_offset_updater.py telegram_offset_bot.py requirements.txt README.md .gitignore
git commit -m "Initial CPM2 offset tools (Kinzi-style)"
git branch -M main
git remote add origin https://github.com/YOUR_USER/cpm2-offset-tools.git
git push -u origin main
```

Replace `YOUR_USER` with your GitHub username. Create an empty repo on GitHub first (no README).

## Security

- Never commit `BOT_TOKEN` or dumps/scripts with private data  
- Use `ALLOWED_IDS` so only you can use the bot  
- This tool only rewrites offsets from public-style dumps — it does not log into game accounts

## License

Use freely for your own modding workflow. Not affiliated with the game publisher.

## Lua script encryption (clean Kinzi-style)

Protect your own `.lua` scripts without the malware from public "ENC" tools
(no hidden logger, no self-destruct, no anti-tool crash loops).

```bash
# Encrypt → protected loader (runs in GameGuardian)
python lua_script_crypt.py encrypt --in script.lua --out script_protected.lua

# Decrypt back to plain source
python lua_script_crypt.py decrypt --in script_protected.lua --out script_restored.lua

# Verify integrity
python lua_script_crypt.py info --in script_protected.lua
```

Pipeline: `SHA256 → XOR(key) → Caesar → XOR(revkey) → RLE → Base64` + in-memory GG loader.

## Deploy notes (this repo)

Never commit real `BOT_TOKEN`. Use environment variables only.

```powershell
$env:BOT_TOKEN = "YOUR_TOKEN"
$env:ALLOWED_IDS = "6067014733"
python telegram_offset_bot.py
```
