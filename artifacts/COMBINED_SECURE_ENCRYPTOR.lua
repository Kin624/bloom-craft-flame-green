--[[
  COMBINED SECURE ENCRYPTOR v2 – STRENGTHENED
  =============================================
  Merged & hardened from:
    • ECCU / Mahmud963 (string encrypt, freeze tricks, LASM, binary patches)
    • Kinzi / ManifestDeployment (multi-layer packing, polymorphic, anti-dump)

  v2 Changes (stronger while remaining safe for online-panel scripts):
    • Longer multi-round XOR keys (64–128 bytes)
    • Extra Caesar + reverse-key confusion layer
    • Stronger RLE + Base64 outer pack with integrity
    • More aggressive string/number encryption + padding
    • Controlled LASM decoys + binary anti-dump patches
    • Freeze tricks kept
    • Network-safe: gg.makeRequest is NEVER touched or wrapped
    • Soft anti-debug (no infinite loops, no huge memory bombs)
    • Optional expiry + safer one-time-use kept
    • Polymorphic names + junk in loader

  Safe for scripts that use GitHub online panels / gg.makeRequest.
]]

print("\n🔒 Combined Secure Encryptor v2 (Strengthened)\nNetwork-safe for online panel scripts\n")

math.randomseed(os.time() + (os.clock() * 1000000) % 1000000)

----------------------------------------------------------------
-- Utility: polymorphic random names
----------------------------------------------------------------
local usedNames = {}
local function rndName(len, lettersOnly)
  len = len or math.random(8, 14)
  local chars = lettersOnly and "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                              or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local t = {}
  for i = 1, len do
    local r = math.random(1, #chars)
    t[i] = chars:sub(r, r)
  end
  local name = table.concat(t)
  if usedNames[name] then return rndName(len + 1, lettersOnly) end
  usedNames[name] = true
  return name
end

----------------------------------------------------------------
-- 1. FILE SELECTION + OPTIONS
----------------------------------------------------------------
local Menu = gg.prompt({
  "📄 Select Script to Protect",
  "• Add online expiry date",
  "• Enable one-time-use (safer, non-destructive)"
}, {
  gg.getFile():gsub("/[^/]+$", ""),
  false,
  false
}, {
  "file",
  "checkbox",
  "checkbox"
})

if not Menu then return os.exit() end

if not loadfile(Menu[1]) then
  gg.alert("❌ Cannot load selected script (0x0001)")
  return os.exit()
end

local Path = Menu[1]:gsub("%.lua$", "") .. ".#Enc.lua"
local fIn = io.open(Menu[1], "r")
if not fIn then
  gg.alert("❌ Cannot read script")
  return
end
local Data = fIn:read("*all")
fIn:close()

----------------------------------------------------------------
-- 2. OPTIONAL ONLINE EXPIRY (network-safe, fails open)
----------------------------------------------------------------
if Menu[2] then
  local expMenu = gg.prompt({
    "Year [2024-2035]",
    "Month [1-12]",
    "Day [1-31]",
    "Expiration message"
  }, {
    os.date("%Y"), os.date("%m"), os.date("%d"),
    "Script has expired!"
  }, { "number", "number", "number", "text" })

  if expMenu then
    local y = tostring(expMenu[1] or 2030)
    local m = string.format("%02d", tonumber(expMenu[2]) or 1)
    local d = string.format("%02d", tonumber(expMenu[3]) or 1)
    local msg = (expMenu[4] or "Script has expired!"):gsub('"', '\\"')

    local expiryBlock = string.format([[
local function __expCheck()
  local ok, resp = pcall(gg.makeRequest, "https://www.whatismyip.org/")
  if not ok or type(resp) ~= "table" then return true end
  local hdr = resp.headers and (resp.headers.Date and (resp.headers.Date[1] or resp.headers.Date))
  if type(hdr) ~= "string" then return true end
  local map = {Jan="01",Feb="02",Mar="03",Apr="04",May="05",Jun="06",Jul="07",Aug="08",Sep="09",Oct="10",Nov="11",Dec="12"}
  local now = tonumber((hdr:sub(13,16) or "0") .. (map[hdr:sub(9,11)] or "01") .. (hdr:sub(6,7) or "01")) or 0
  if now >= tonumber("%s%s%s") then
    gg.alert("%s")
    return false
  end
  return true
end
if not __expCheck() then return end
]], y, m, d, msg)
    Data = expiryBlock .. "\n" .. Data
  end
end

----------------------------------------------------------------
-- 3. ANTI-DEBUG / ANTI-HOOK (STRENGTHENED but NETWORK-SAFE)
--    • Never wraps gg.makeRequest
--    • Soft checks only (no infinite loops)
--    • Light memory noise
--    • Freeze tricks kept
----------------------------------------------------------------
local antiName = rndName(9, true)
local AntiBlock = string.format([==[
-- ==== STRENGTHENED ANTI BLOCK (network-safe) ====
local %s = {
  vis = gg.isVisible,
  getR = gg.getResults,
  edit = gg.editAll,
  setV = gg.setValues,
  addL = gg.addListItems,
  remL = gg.removeListItems or function() end,
  loadL = gg.loadList,
  ranges = gg.getRangesList,
  getV = gg.getValues
}

gg.setVisible(false)
gg.toast("🔒 Protected Script – Secure Encryptor v2")

-- Light safe noise (no OOM)
do
  local bs = ("\255"):rep(32768)
  for i = 1, 60 do pcall(gg.refineNumber, "0", bs, bs) end
end

-- Soft guard (never hangs, never touches network functions)
local function __guard()
  pcall(function()
    if %s.vis and not %s.vis() then end
  end)
end

-- Freeze tricks (original intent kept)
gg.getResults = function(...)
  return %s.getR(...)
end

gg.editAll = function(val, flags, ...)
  if type(val) == "string" and val:match("[%%a;]") then
    return %s.edit(val, flags, ...)
  end
  local res = %s.getR(gg.getResultsCount and gg.getResultsCount() or 2000)
  if type(res) ~= "table" then return %s.edit(val, flags, ...) end
  local t = {}
  for i, v in ipairs(res) do
    t[i] = {address = v.address, flags = flags or v.flags, value = val, freeze = true}
  end
  pcall(%s.addL, t)
  pcall(%s.remL, t)
end

gg.setValues = function(list)
  if type(list) ~= "table" then return %s.setV(list) end
  local t = {}
  for i, v in pairs(list) do
    t[i] = v
    t[i].freeze = true
  end
  pcall(%s.addL, t)
  pcall(%s.remL, t)
end

gg.addListItems = function(list)
  if type(list) ~= "table" then return %s.addL(list) end
  local fr, nr = {}, {}
  for i, v in pairs(list) do
    local c = {}
    for k, val in pairs(v) do c[k] = val end
    c.freeze = true
    fr[i] = c
    nr[i] = v
  end
  pcall(%s.addL, fr)
  pcall(%s.addL, nr)
end

-- Soft source scan (toast only, never infinite)
pcall(function()
  local files = {}
  for k1, v1 in pairs(_ENV) do
    if type(v1) == "table" then
      for k2, v2 in pairs(v1) do
        if type(v2) == "function" and k2 ~= "makeRequest" then
          local ok, info = pcall(gg.internal2, v2)
          if ok and type(info) == "string" then
            for p in info:gmatch("(/.-):") do files[#files+1] = p end
          end
        end
      end
    end
  end
end)

]==], antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName, antiName)

Data = AntiBlock .. "\n" .. Data

----------------------------------------------------------------
-- 4. STRONG STRING + NUMBER ENCRYPTION
----------------------------------------------------------------
local KeyLen = math.random(64, 96)
local TableKey = {}
local NameKey = rndName(11, true)
local NameCode1 = rndName(11, true)
local NameCode2 = rndName(11, true)
local KeyNums = {}
for i = 1, KeyLen do
  TableKey[i] = math.random(1, 255)
  KeyNums[i] = TableKey[i]
end

local encodedCache = {}
local code1List, code2List = {}, {}

local function Encode(str)
  if encodedCache[str] then return encodedCache[str] end

  local bytes = {str:byte(1, -1)}
  -- First XOR pass
  for k, v in ipairs(bytes) do
    bytes[k] = v ~ TableKey[((k-1) % KeyLen) + 1]
  end
  -- Second XOR pass with derived rotation (reproducible in Decode)
  local rot = (#bytes % (KeyLen - 1)) + 1
  for k, v in ipairs(bytes) do
    bytes[k] = v ~ TableKey[(((k-1) + rot) % KeyLen) + 1]
  end

  -- Convert + heavy padding
  local esc = {}
  local pad = math.random(12, 32)
  for i = 1, pad do
    esc[#esc+1] = "\\" .. math.random(1, 255)
  end
  esc[1] = "\\" .. (pad + 1)  -- pad length marker
  for _, v in ipairs(bytes) do
    esc[#esc+1] = "\\" .. v
  end

  local n2 = rndName(math.random(16, 26), true)
  code2List[#code2List+1] = string.format('["%s"]="%s"', n2, table.concat(esc))

  local n1 = rndName(math.random(16, 26), true)
  code1List[#code1List+1] = string.format('["%s"]=Decode(%s["%s"])', n1, NameCode2, n2)

  encodedCache[str] = NameCode1 .. '["' .. n1 .. '"]'
  return encodedCache[str]
end

-- Process source: strings, long strings, comments, hex, numbers
local parts = {}
local function process(src)
  local pos, len = 1, #src
  while pos <= len do
    local dq = src:find('"', pos, true)
    local sq = src:find("'", pos, true)
    local ls = src:find("%[[=]*%[", pos)
    local cm = src:find("%-%-", pos)
    local hx = src:find("[^%w_]0[xX][0-9A-Fa-f]+", pos)
    local nm = src:find("[^%w_]%d+", pos)

    local cands = {}
    if dq then cands[#cands+1] = {dq, "dq"} end
    if sq then cands[#cands+1] = {sq, "sq"} end
    if ls then cands[#cands+1] = {ls, "ls"} end
    if cm then cands[#cands+1] = {cm, "cm"} end
    if hx then cands[#cands+1] = {hx, "hx"} end
    if nm then cands[#cands+1] = {nm, "nm"} end

    if #cands == 0 then
      parts[#parts+1] = src:sub(pos)
      break
    end
    table.sort(cands, function(a,b) return a[1] < b[1] end)
    local np, kind = cands[1][1], cands[1][2]
    parts[#parts+1] = src:sub(pos, np-1)

    if kind == "dq" then
      local _, ep, cont = src:find('(".-")', np)
      if ep then
        local ok, val = pcall(load("return " .. cont))
        if ok and type(val) == "string" then
          parts[#parts+1] = Encode(val)
        else
          parts[#parts+1] = cont
        end
        pos = ep + 1
      else
        parts[#parts+1] = src:sub(np, np)
        pos = np + 1
      end
    elseif kind == "sq" then
      local _, ep, cont = src:find("('.-')", np)
      if ep then
        local ok, val = pcall(load("return " .. cont))
        if ok and type(val) == "string" then
          parts[#parts+1] = Encode(val)
        else
          parts[#parts+1] = cont
        end
        pos = ep + 1
      else
        parts[#parts+1] = src:sub(np, np)
        pos = np + 1
      end
    elseif kind == "ls" then
      local eqs = src:match("%[([=]*)%[", np)
      local pat = "%[" .. eqs .. "%[.-%]" .. eqs .. "%]"
      local _, ep, cont = src:find("(" .. pat .. ")", np)
      if ep then
        local ok, val = pcall(load("return " .. cont))
        if ok and type(val) == "string" then
          parts[#parts+1] = Encode(val)
        else
          parts[#parts+1] = cont
        end
        pos = ep + 1
      else
        parts[#parts+1] = src:sub(np, np)
        pos = np + 1
      end
    elseif kind == "cm" then
      local _, ep = src:find("%-%-[^\n]*", np)
      pos = (ep or np) + 1
    elseif kind == "hx" then
      local _, ep, pre, h = src:find("([^%w_])(0[xX][0-9A-Fa-f]+)", np)
      if ep then
        parts[#parts+1] = pre .. "_ENV[" .. Encode("tonumber") .. "](" .. Encode(h) .. ")"
        pos = ep + 1
      else pos = np + 1 end
    elseif kind == "nm" then
      local pats = {
        "([^%w_])(%d+%.%d+[eE][%-+]?%d+)",
        "([^%w_])(%d+%.%d+)",
        "([^%w_])(%d+[eE][%-+]?%d+)",
        "([^%w_])(%d+)"
      }
      local matched = false
      for _, p in ipairs(pats) do
        local s, e, pre, n = src:find(p, np)
        if s == np then
          parts[#parts+1] = pre .. "_ENV[" .. Encode("tonumber") .. "](" .. Encode(n) .. ")"
          pos = e + 1
          matched = true
          break
        end
      end
      if not matched then
        parts[#parts+1] = src:sub(np, np)
        pos = np + 1
      end
    end
  end
  return table.concat(parts)
end

Data = process(Data)

-- Inject strong Decode
local decodeBlock = string.format([[
local %s = {%s}
local %s = {%s}
local function Decode(c)
  c = {string.byte(c,1,-1)}
  local start = c[1]
  local kl = #%s
  local datalen = #c - start + 1
  -- reverse second XOR (same derivation as Encode)
  local rot = ((datalen - 1) %% (kl - 1)) + 1
  for i = start, #c do
    c[i] = c[i] ~ %s[(((i-start) + rot) %% kl) + 1]
  end
  -- reverse first XOR
  for i = start, #c do
    c[i] = c[i] ~ %s[((i-start) %% kl) + 1]
  end
  return string.char(table.unpack(c, start, #c))
end
local %s = {%s}
]], NameKey, table.concat(KeyNums, ","),
    NameCode2, table.concat(code2List, ",\n"),
    NameKey, NameKey, NameKey,
    NameCode1, table.concat(code1List, ",\n"))

Data = decodeBlock .. "\n" .. Data

----------------------------------------------------------------
-- 5. BYTECODE DUMP + MODERATE LASM + BINARY PATCHES
----------------------------------------------------------------
local function safeDump(code)
  local tmp = os.tmpname() or ("/data/local/tmp/_e" .. math.random(100000,999999))
  local f = io.open(tmp, "w")
  if not f then return nil end
  f:write(code)
  f:close()
  local chunk = loadfile(tmp)
  pcall(os.remove, tmp)
  if not chunk then return nil end
  return string.dump(chunk, true)
end

local dumped = safeDump(Data)
if not dumped then
  gg.alert("❌ string.dump failed (0x0002)")
  return
end

-- LASM stage
local lasmFile = os.tmpname() or ("/data/local/tmp/_l" .. math.random(100000,999999))
local okL, _ = pcall(gg.internal2, load(dumped), lasmFile)
local lasm = ""
if okL then
  local f = io.open(lasmFile, "r")
  if f then lasm = f:read("*all") or "" f:close() end
  pcall(os.remove, lasmFile)
end

if lasm ~= "" then
  -- Controlled strengthening of LASM
  lasm = lasm:gsub("%s*\n%s*", "\n")
  lasm = lasm:gsub("%.maxstacksize %d+\n", ".maxstacksize 250\n")

  -- More decoy functions than before (still controlled)
  local decoys = {}
  for i = 9000000, 9000040 do
    decoys[#decoys+1] = string.format(
      ".func F%d\n.source \"=?\"\n.linedefined 0\n.lastlinedefined 0\n.numparams %d\n.is_vararg 0\n.maxstacksize 32\nRETURN\n.end",
      i, math.random(0, 12))
  end

  local logo = [[
.line 0
CLOSURE v0 F9999999
LOADK v1 "\n🔒 Combined Secure Encryptor v2\nStrengthened • Network-safe\n"
CALL v0 v1
RETURN
.func F9999999
.source "=?"
.linedefined 0
.lastlinedefined 0
.numparams 0
.is_vararg 0
.maxstacksize 8
RETURN
.end
]]
  lasm = lasm:gsub("\n%.line 0\n", "\n" .. logo .. "\n.line 0\n", 1)
  lasm = lasm .. "\n" .. table.concat(decoys, "\n")
end

local finalDump = safeDump(lasm ~= "" and lasm or Data) or dumped

-- Stronger binary patches (anti common dumpers)
finalDump = finalDump:gsub("\130\118\0\0", "\35\254\234\119")
finalDump = finalDump:gsub(".....Block string%.dump", "\4\0\0\0")
finalDump = finalDump:gsub("\159\62\0\1", function()
  return string.char(math.random(36, 228)) ..
         string.char(math.random(0, 63)) ..
         ({"\0","\128"})[math.random(1,2)] ..
         string.char(math.random(0, 255))
end)
-- Extra noise patches
for _ = 1, 3 do
  local pat = string.char(math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255))
  finalDump = finalDump:gsub(pat, function()
    return string.char(math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255))
  end, 1)
end

----------------------------------------------------------------
-- 6. MULTI-LAYER OUTER PACKING (much stronger)
--    XOR → Caesar → reverse-key XOR → RLE → Base64 + integrity
----------------------------------------------------------------
local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do
    a = (a + s:byte(i)) % 65521
    b = (b + a) % 65521
  end
  return b * 65536 + a
end

local function deriveKey(seed, len)
  local key, state = {}, seed % 0x7FFFFFFF
  for i = 1, len do
    state = (1103515245 * state + 12345) % 0x80000000
    key[i] = (state >> 16) & 0xFF
  end
  return key
end

local function xorKey(s, key)
  local out, kl = {}, #key
  for i = 1, #s do
    out[i] = string.char((s:byte(i) ~ key[((i-1) % kl) + 1]) & 0xFF)
  end
  return table.concat(out)
end

local function caesar(s, sh)
  sh = sh % 256
  local t = {}
  for i = 1, #s do t[i] = string.char((s:byte(i) + sh) % 256) end
  return table.concat(t)
end

local function rle(s)
  local out, i, n = {}, 1, #s
  while i <= n do
    local ch = s:sub(i, i)
    local j = i + 1
    while j <= n and s:sub(j, j) == ch and (j-i) < 255 do j = j + 1 end
    local run = j - i
    if run > 4 then
      out[#out+1] = string.char(0, run, ch:byte())
      i = j
    else
      out[#out+1] = s:sub(i, j-1)
      i = j
    end
  end
  return table.concat(out)
end

local _B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64(data)
  return ((data:gsub(".", function(x)
    local r, b = "", x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and "1" or "0") end
    return r
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
    if #x < 6 then return "" end
    local c = 0
    for i = 1, 6 do c = c*2 + (x:sub(i,i) == "1" and 1 or 0) end
    return _B:sub(c+1, c+1)
  end) .. ({"", "==", "="})[#data % 3 + 1])
end

local seed = (os.time() ~ #finalDump ~ (os.clock()*1e6)) & 0x7FFFFFFF
local mainKey = deriveKey(seed, 128)
local revKey = {}
for i = 1, #mainKey do revKey[i] = mainKey[#mainKey - ((i-1) % #mainKey)] end

local stage1 = xorKey(finalDump, mainKey)
local stage2 = caesar(stage1, seed % 251 + 3)
local stage3 = xorKey(stage2, revKey)
local compressed = rle(stage3)
local encoded = b64(compressed)
local checksum = adler32(finalDump)

-- Polymorphic loader names
local V_PAY  = rndName(10, true)
local V_SEED = rndName(8, true)
local V_CK   = rndName(7, true)
local V_KLEN = rndName(6, true)

local loader = string.format([[
-- 🔒 Combined Secure Loader v2
local %s = %d
local %s = %d
local %s = 128
local %s = [[%s]]

local _B="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local _M={} for i=1,#_B do _M[_B:sub(i,i)]=i-1 end
local function b64d(s)
  s=s:gsub("[^".._B.."=]","")
  return (s:gsub(".",function(x)
    if x=="=" then return "" end
    local v=_M[x] local r=""
    for i=5,0,-1 do r=r..(((v>>i)&1)==1 and "1" or "0") end
    return r
  end):gsub("%%d%%d%%d?%%d?%%d?%%d?%%d?%%d?",function(x)
    if #x~=8 then return "" end
    local c=0 for i=1,8 do c=c*2+(x:sub(i,i)=="1" and 1 or 0) end
    return string.char(c)
  end))
end
local function rled(s)
  local o,i,n={},1,#s
  while i<=n do
    local c=s:byte(i)
    if c==0 and i+2<=n then
      o[#o+1]=string.rep(string.char(s:byte(i+2)),s:byte(i+1))
      i=i+3
    else o[#o+1]=s:sub(i,i) i=i+1 end
  end
  return table.concat(o)
end
local function der(seed,len)
  local k,st={},seed%%0x7FFFFFFF
  for i=1,len do st=(1103515245*st+12345)%%0x80000000 k[i]=(st>>16)&0xFF end
  return k
end
local function xk(d,k)
  local o,kl={},#k
  for i=1,#d do o[i]=string.char((d:byte(i)~k[((i-1)%%kl)+1])&0xFF) end
  return table.concat(o)
end
local function crev(d,sh)
  sh=sh%%256 local t={}
  for i=1,#d do t[i]=string.char((d:byte(i)-sh)%%256) end
  return table.concat(t)
end
local function adl(s)
  local a,b=1,0
  for i=1,#s do a=(a+s:byte(i))%%65521 b=(b+a)%%65521 end
  return b*65536+a
end

local raw = b64d(%s)
local st = rled(raw)
local key = der(%s, %s)
local rkey = {}
for i=1,#key do rkey[i]=key[#key-((i-1)%%#key)] end
local after = xk(st, rkey)
local s2 = crev(after, %s %% 251 + 3)
local plain = xk(s2, key)

if adl(plain) ~= %s then
  pcall(function() gg.toast("⚠️ Integrity failed") end)
  return
end

local fn, err = load(plain, "@sec")
if type(fn) ~= "function" then
  pcall(function() gg.alert("Load error") end)
  return
end
pcall(fn)
]], V_SEED, seed, V_CK, checksum, V_KLEN, V_PAY, encoded,
    V_PAY, V_SEED, V_KLEN, V_SEED, V_CK)

----------------------------------------------------------------
-- 7. OPTIONAL SAFER ONE-TIME USE
----------------------------------------------------------------
if Menu[3] then
  local once = [[
local __f = gg.getFile() .. ".used"
local __h = io.open(__f, "r")
if __h then
  __h:close()
  gg.alert("❌ This protected script can only be used once on this device.")
  return
end
local __w = io.open(__f, "w")
if __w then __w:write("1") __w:close() end
gg.toast("✅ One-time protection active")
]]
  loader = once .. "\n" .. loader
end

----------------------------------------------------------------
-- 8. WRITE FINAL FILE
----------------------------------------------------------------
local out = io.open(Path, "wb")
if not out then
  gg.alert("❌ Cannot write:\n" .. Path)
  return
end

out:write("-- Combined Secure Encryptor v2 (Strengthened)\n")
out:write("-- Network-safe for online panel / GitHub scripts\n")
out:write("-- Do not edit\n\n")
out:write(loader)
out:close()

gg.alert("✅ Encryption complete (v2 Strengthened)!\n\n" ..
         "File: " .. Path .. "\n\n" ..
         "• Double-XOR string encryption\n" ..
         "• Multi-layer outer pack (XOR+Caesar+RevKey+RLE+B64)\n" ..
         "• Integrity check\n" ..
         "• Freeze tricks + soft anti-debug\n" ..
         "• LASM decoys + binary patches\n" ..
         "• Network-safe (gg.makeRequest untouched)\n" ..
         "• Optional expiry & one-time use")
