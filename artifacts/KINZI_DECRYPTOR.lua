--[[
  KINZI DOM — BEST-EFFORT DECRYPT / RECOVER
  ========================================
  Truth:
    Orvex LASM + binary patches are NOT password encryption.
    GG runs the bytecode directly. There is no AES key to invert.

  This tool can:
    A) SOURCE with Manifest tables → rebuild some plain strings
    B) BYTECODE → detect + write a note (need Unluac on PC for source)

  Cannot guarantee original source from full JMPhx + binary output.
]]

local g = {}
g.last = gg.getFile()
g.info = nil
g.config = (gg.EXT_CACHE_DIR or "/sdcard") .. "/" .. (gg.getFile():match("[^/]+$") or "kinzi") .. ".dec.cfg"
do
  local f = loadfile(g.config)
  if f then
    local ok, t = pcall(f)
    if ok and type(t) == "table" then g.info = t end
  end
end
if not g.info then
  g.info = { g.last, (g.last:gsub("/[^/]+$", "") or "/sdcard") }
end

local function is_mostly_binary(s)
  if type(s) ~= "string" or #s < 4 then return false end
  if s:byte(1) == 0x1B then return true end
  local bad, n = 0, math.min(#s, 4000)
  for i = 1, n do
    local b = s:byte(i)
    if b == 0 or b > 127 then bad = bad + 1 end
  end
  return (bad / n) > 0.15
end

local function try_manifest_recover(src)
  local out = src
  local recovered = 0
  local char_maps = {}

  for tname, key, num in src:gmatch('([%w_]+)%s*%[%s*["\']([%w_]+)["\']%s*%]%s*=%s*string%.char%s*%((%d+)%)') do
    char_maps[tname] = char_maps[tname] or {}
    char_maps[tname][key] = string.char(tonumber(num))
  end

  for tname, idx, body in src:gmatch('([%w_]+)%s*%[%s*["\']([^"\']+)["\']%s*%]%s*=%s*[%w_]+%s*%(%s*{([^}]+)}%s*%)') do
    local keys = {}
    for k in body:gmatch('["\']([%w_]+)["\']') do
      keys[#keys + 1] = k
    end
    local cmap = nil
    for name, map in pairs(char_maps) do
      local ok = true
      for _, k in ipairs(keys) do
        if not map[k] then ok = false break end
      end
      if ok and #keys > 0 then cmap = map break end
    end
    if cmap and #keys > 0 then
      local plain = {}
      for _, k in ipairs(keys) do plain[#plain + 1] = cmap[k] end
      local s = table.concat(plain)
      local esc = idx:gsub("(%W)", "%%%1")
      local pat = "%(%s*" .. tname .. "%s*%[%s*[\"']" .. esc .. "[\"']%s*%]%s*%)"
      local safe = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
      local n
      out, n = out:gsub(pat, '"' .. safe .. '"')
      recovered = recovered + (n or 0)
    end
  end
  return out, recovered, char_maps
end

local function strip_junk(src)
  local lines = {}
  for line in (src .. "\n"):gmatch("(.-)\n") do
    local keep = true
    if line:find("if false then", 1, true) and line:find("gg.toast", 1, true) then keep = false end
    if line:find("if nil then goto", 1, true) then keep = false end
    if line:find("local function _nzf", 1, true) then keep = false end
    if keep then lines[#lines + 1] = line end
  end
  return table.concat(lines, "\n")
end

while true do
  g.info = gg.prompt({
    "[FOLDER] Script to analyze / recover :",
    "[FOLDER] Output folder :",
  }, g.info, { "file", "path" })
  if not g.info then return end
  pcall(gg.saveVariable, g.info, g.config)

  local path = g.info[1]
  local outdir = g.info[2] or "/sdcard"
  local f = io.open(path, "rb")
  if not f then
    gg.alert("Cannot open file")
  else
    local data = f:read("*a")
    f:close()
    local base = path:match("[^/]+$") or "out.lua"
    local outpath = outdir .. "/" .. base:gsub("%.lua$", "") .. ".RECOVERED.lua"

    if is_mostly_binary(data) then
      local note = table.concat({
        "BYTECODE DETECTED",
        "-----------------",
        "This is Orvex-style output (string.dump / LASM).",
        "GG can RUN it. There is no password key to invert.",
        "",
        "To try recovering SOURCE on PC:",
        "  1) Copy the .lua to computer",
        "  2) Use Unluac / unluac52 (or similar)",
        "  3) Clean JMPhx noise by hand if needed",
        "",
        "Auto full decrypt to original is not reliable",
        "after JMPhx + binary patches.",
      }, "\n")
      local okload, err = load(data)
      if not okload then
        note = note .. "\n\nload() error: " .. tostring(err)
      else
        note = note .. "\n\nload() OK — file is valid runnable chunk."
      end
      local rf = io.open(outdir .. "/" .. base .. ".BYTECODE_NOTE.txt", "w")
      if rf then rf:write(note) rf:close() end
      gg.alert(note)
      gg.toast("Bytecode — note saved")
    else
      local rec, n, maps = try_manifest_recover(data)
      rec = strip_junk(rec)
      local mapcount = 0
      for _ in pairs(maps) do mapcount = mapcount + 1 end
      local header = string.format(
        "-- RECOVERED (best effort) replacements=%d char_tables=%d\n-- Original: %s\n\n",
        n, mapcount, path
      )
      local wf = io.open(outpath, "w")
      if not wf then
        gg.alert("Cannot write:\n" .. outpath)
      else
        wf:write(header)
        wf:write(rec)
        wf:close()
        gg.alert(string.format(
          "SOURCE recover (best effort)\n\nReplacements: %d\nChar tables: %d\n\n%s\n\nFull Orvex LASM bytecode needs Unluac on PC.",
          n, mapcount, outpath
        ))
        gg.toast("Saved recovered file")
      end
    end
  end
end
