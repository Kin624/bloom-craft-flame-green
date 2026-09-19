--[[
================================================================================
  KINZI ENCRYPTOR – STRENGTHENED + UNIQUE (Cleaned & Commented)
================================================================================

  Combined techniques from:
    • Original Kinzi / ManifestDeployment pipeline
    • China-style byte-table + shuffled char tables
    • API-as-bytes hiding
    • Multi-layer outer pack (XOR + Caesar + RevKey + RLE + Base64)
    • Soft anti-debug (network-safe for online panel scripts)

  PIPELINE:
  1. Select script
  2. Inject soft anti-debug block
  3. Encrypt EVERY string with mixed styles (randomly chosen per string):
        Style A – ASCII lookup table + Decode (Kinzi classic)
        Style B – Byte array  string.char(table.unpack({...}))
        Style C – Shuffled unique-char table + index list (China V4 style)
  4. Rename gg/os/io/string/math/table/debug methods to random keys
  5. load() + string.dump() → bytecode
  6. Multi-layer pack the bytecode
  7. Emit polymorphic loader that reverses the pack
  8. Optional non-destructive one-time-use
  9. Write  original.MANIFEST_DEPLOYMENT.lua

  Goal: output looks different from common public encryptors and is harder
  to reverse with a single generic decryptor.
================================================================================
]]

print("\n🔒 Kinzi Encryptor – Strengthened Unique Build\n")

math.randomseed(os.time() + math.floor(os.clock() * 1e6) % 100000)

----------------------------------------------------------------
-- LOCALS
----------------------------------------------------------------
local gg, os, io, debug, math, table, string =
      gg, os, io, debug, math, table, string

local MD = {}   -- ManifestDeployment short name

----------------------------------------------------------------
-- PATH / CONFIG
----------------------------------------------------------------
local SELF_PATH = gg.getFile()
local SELF_DIR  = (SELF_PATH:match("(.*/)") or "")

local cfg = {
  dir  = "/sdcard/",
  name = "ManifestDeployment.Kinzi",
  path = "/sdcard/ManifestDeployment.Kinzi",
}

function cfg.io(tbl, path)
  path = path or cfg.path
  if tbl then
    return gg.saveVariable(tbl, path)
  end
  local fn = loadfile(path)
  if fn then
    return { "📂 SELECT FILE :" }, fn(), { "file" }
  end
  return { "📂 SELECT FILE :" }, { SELF_PATH, SELF_DIR }, { "file" }
end

function MD.io(path, data)
  if data then
    local f, err = io.open(path, "w")
    if not f then return false, err end
    f:write(data)
    f:close()
    return true
  end
  local f, err = io.open(path, "r")
  if not f then return false, err end
  local c = f:read("*a")
  f:close()
  return c
end

----------------------------------------------------------------
-- 1. FILE SELECT
----------------------------------------------------------------
local sel = gg.prompt(cfg.io())
if not sel then return false end
cfg.io(sel)

local inputPath  = sel[1]
local outputPath = inputPath .. ".MANIFEST_DEPLOYMENT.lua"

MD.data = MD.io(inputPath)
if type(MD.data) ~= "string" or #MD.data < 2 then
  gg.alert("❌ Cannot read script")
  return
end

----------------------------------------------------------------
-- 2. SOFT ANTI-DEBUG (network-safe, no infinite loops)
----------------------------------------------------------------
local ANTI = [=[
-- ===== ANTI (soft, network-safe) =====
local _R = {}
for _, fn in ipairs({"loadfile","dofile"}) do
  if _G[fn] then
    _R[fn] = _G[fn]
    _G[fn] = function(p, ...)
      if type(p)=="string" and (p:match("dump") or p:match("syslog") or p:match("payload")) then
        gg.toast("🚫 blocked")
        return nil
      end
      return _R[fn](p, ...)
    end
  end
end
local _RIO = io
_G.io = {
  open = function(f, m)
    if type(f)=="string" and (f:match("dump") or f:match("%.syslog") or f:match("payload")) then
      gg.toast("🚫 dump blocked"); return nil
    end
    return _RIO.open(f, m)
  end,
  write=function(...) return _RIO.write(...) end,
  read=function(...) return _RIO.read(...) end,
  close=function(...) return _RIO.close(...) end,
  input=function(...) return _RIO.input(...) end,
  output=function(...) return _RIO.output(...) end,
  lines=function(...) return _RIO.lines(...) end,
  tmpfile=function(...) return _RIO.tmpfile(...) end,
}
local _RP = print
print = function(...)
  for _,v in ipairs({...}) do
    if type(v)=="string" and (v:match("dump") or v:match("debug")) then
      gg.toast("🚫"); return
    end
  end
  return _RP(...)
end
local _Rpairs = pairs
pairs = function(t)
  local ok, info = pcall(debug.getinfo, 2, "n")
  if ok and t == _G and info and info.name and tostring(info.name):match("pairs") then
    return function() return nil end
  end
  return _Rpairs(t)
end
if gg.prompt then
  local _Rpr = gg.prompt
  gg.prompt = function(...)
    local ok, info = pcall(debug.getinfo, 2, "S")
    if ok and info and info.short_src and info.short_src:match("dump") then
      return nil
    end
    return _Rpr(...)
  end
end
do
  local ok, hit = pcall(function()
    local ti = gg.getTargetInfo and gg.getTargetInfo()
    local pk = gg.getTargetPackage and gg.getTargetPackage()
    if ti and type(ti.label)=="string" and ti.label:match("clone") then return true end
    if type(pk)=="string" and pk:match("parallel|multi|clone") then return true end
    return false
  end)
  if ok and hit then os.exit() end
end
gg.toast("✅ Protected")
-- ===== END ANTI =====
]=]

MD.data = ANTI .. "\n" .. MD.data

----------------------------------------------------------------
-- 3. RANDOM NAME GENERATOR
----------------------------------------------------------------
MD.used = {}
function MD.rnd(n)
  n = n or math.random(6, 10)
  local t = {}
  for i = 1, n do
    local r = math.random(1, 26)
    t[i] = string.char(r + (i % 2 == 1 and 96 or 64))
  end
  local s = table.concat(t)
  if MD.used[s] then return MD.rnd(n + 1) end
  if MD.data:match("[^%w_]" .. s .. "[^%w_]") then return MD.rnd(n + 1) end
  MD.used[s] = true
  return s
end

----------------------------------------------------------------
-- 4. MIXED STRING ENCRYPTION (3 styles – randomly chosen)
--
--  Style A (Kinzi classic):
--    char → random key in ascll table → Decode({keys})
--
--  Style B (byte array – from China tools):
--    string.char(table.unpack({b1,b2,...}))
--
--  Style C (shuffled unique-char table – China V4 idea):
--    build unique sorted chars, shuffle, store as table
--    string becomes concatenation of table[index] lookups
----------------------------------------------------------------
local ASC = { name = MD.rnd(), data = {}, map = {} }
table.insert(ASC.data, ASC.name .. "={}")

local DEC_NAME = MD.rnd()
local DEC_CODE = string.format(
  "%s=function(t)local d=\"\" for _,v in pairs(t)do d=d..%s[v] end return d end",
  DEC_NAME, ASC.name)

local STR = { name = MD.rnd(), data = {}, cache = {} }
table.insert(STR.data, STR.name .. "={}")

-- helper: get or create ascll entry for one byte
local function ascllKey(byte)
  local k = ASC.map[byte]
  if k then return k end
  k = '"' .. MD.rnd() .. '"'
  ASC.map[byte] = k
  table.insert(ASC.data, ASC.name .. "[" .. k .. "]=\"\\" .. byte .. "\"")
  return k
end

-- Style A
local function encA(value)
  local keys = {}
  for _, b in ipairs({ value:byte(1, -1) }) do
    keys[#keys + 1] = ascllKey(b)
  end
  local idx = '"' .. MD.rnd() .. '"'
  table.insert(STR.data,
    STR.name .. "[" .. idx .. "]=" .. DEC_NAME .. "({" .. table.concat(keys, ",") .. "})")
  return "(" .. STR.name .. "[" .. idx .. "])"
end

-- Style B – pure byte array
local function encB(value)
  local bytes = { value:byte(1, -1) }
  if #bytes == 0 then return "\"\"" end
  return "string.char(table.unpack({" .. table.concat(bytes, ",") .. "}))"
end

-- Style C – shuffled unique char table
local function encC(value)
  if value == "" then return "\"\"" end
  -- unique chars
  local seen, uniq = {}, {}
  for i = 1, #value do
    local ch = value:sub(i, i)
    if not seen[ch] then
      seen[ch] = true
      uniq[#uniq + 1] = ch
    end
  end
  -- shuffle
  for i = #uniq, 2, -1 do
    local j = math.random(1, i)
    uniq[i], uniq[j] = uniq[j], uniq[i]
  end
  -- build table literal of string.char(...)
  local parts = {}
  for _, ch in ipairs(uniq) do
    parts[#parts + 1] = "string.char(" .. ch:byte() .. ")"
  end
  local tblName = MD.rnd()
  local tblCode = "local " .. tblName .. "={" .. table.concat(parts, ",") .. "}"
  -- map char → index
  local idxMap = {}
  for i, ch in ipairs(uniq) do idxMap[ch] = i end
  local idxs = {}
  for i = 1, #value do
    idxs[#idxs + 1] = tblName .. "[" .. idxMap[value:sub(i, i)] .. "]"
  end
  local expr = "((function() " .. tblCode .. " return table.concat({" ..
               table.concat(idxs, ",") .. "}) end)())"
  return expr
end

-- Pick a style at random for each string
local function encryptString(rawLiteral)
  local fn = load("return " .. rawLiteral)
  local value
  if fn then
    value = fn()
  else
    value = rawLiteral:sub(2, -2)
  end
  if type(value) ~= "string" then
    return rawLiteral
  end
  if STR.cache[value] then
    return STR.cache[value]
  end

  local style = math.random(1, 3)
  local out
  if style == 1 then
    out = encA(value)
  elseif style == 2 then
    out = encB(value)
  else
    out = encC(value)
  end
  STR.cache[value] = out
  return out
end

----------------------------------------------------------------
-- 5. REPLACE ALL STRING LITERALS
----------------------------------------------------------------
gg.toast("🔄 Encrypting strings (mixed styles)...")

MD.data = MD.data:gsub("\\\\", "\\092\\092")
MD.data = MD.data:gsub("\\\034", "\\034")
MD.data = MD.data:gsub("\\\039", "\\039")

local stash, stashMap = {}, {}
local function put(lit)
  local i = stashMap[lit]
  if not i then
    i = #stash + 1
    stash[i] = lit
    stashMap[lit] = i
  end
  return "_S_(#" .. i .. ")"
end

local changed = true
while changed do
  changed = false
  local kind = MD.data:match("[\034\039]")
  if kind == "\034" then
    MD.data = MD.data:gsub("\034[^\n]-\034", function(s)
      changed = true
      return put(s)
    end, 1)
  elseif kind == "\039" then
    MD.data = MD.data:gsub("\039[^\n]-\039", function(s)
      changed = true
      return put(s)
    end, 1)
  end
end

-- strip comments
MD.data = MD.data:gsub("%-%-%[([=]*)%[.-%]%1%]", "")
MD.data = MD.data:gsub("%-%-[^\n]*", "")
MD.data = MD.data:gsub("%s*\n%s*", "\n")

MD.data = MD.data:gsub("\\092\\092", "\\\\")
MD.data = MD.data:gsub("\\034", "\034")
MD.data = MD.data:gsub("\\039", "\039")

MD.data = MD.data:gsub("_S_%(#(%d+)%)", function(n)
  return encryptString(stash[tonumber(n)])
end)

stash, stashMap = nil, nil

local okLoad, errLoad = load(MD.data)
if not okLoad then
  gg.alert("⚠️ String stage failed:\n" .. tostring(errLoad))
  return false
end

----------------------------------------------------------------
-- 6. API / CLASS RENAMING  (+ byte-style option for gg.*)
----------------------------------------------------------------
local CLASS = { name = MD.rnd(), data = {} }
table.insert(CLASS.data, CLASS.name .. "={}")

local LIBS = { table=1, debug=1, gg=1, os=1, io=1, string=1, math=1, bit32=1, utf8=1 }

for libName, lib in pairs(_ENV) do
  if type(lib) == "table" and LIBS[libName] then
    for methodName, method in pairs(lib) do
      if type(method) == "function" then
        local key = '"' .. MD.rnd() .. '"'
        local hit = false
        MD.data = MD.data:gsub(
          "(.)([^%w_])(%s*)" .. libName .. "%s*%.%s*" .. methodName .. "(%s*)([^%w_])(.)",
          function(a, b, c, d, e, f)
            if (a ~= "." or b == ".") and (e ~= "." or f == ".") then
              hit = true
              return a .. b .. c .. CLASS.name .. "[" .. key .. "]" .. d .. e .. f
            end
          end)
        if hit then
          -- define as _ENV["lib"]["method"] using byte form for the names
          local libBytes  = table.concat({ libName:byte(1, -1) }, ",")
          local methBytes = table.concat({ methodName:byte(1, -1) }, ",")
          table.insert(CLASS.data,
            CLASS.name .. "[" .. key .. "]=_ENV[string.char(" .. libBytes ..
            ")][string.char(" .. methBytes .. ")]")
        end
      end
    end
  end
end

----------------------------------------------------------------
-- 7. ASSEMBLE SOURCE
----------------------------------------------------------------
local header = table.concat({
  table.concat(ASC.data, "\n"),
  DEC_CODE,
  table.concat(STR.data, "\n"),
  table.concat(CLASS.data, "\n"),
}, "\n")

MD.data = header .. "\n" .. MD.data
MD.data = ";(function(...)\n" .. MD.data .. "\n;end)([[Kinzi]])"

local chunk, err2 = load(MD.data)
if not chunk then
  gg.alert("⚠️ Assemble failed:\n" .. tostring(err2))
  return false
end

local bytecode = string.dump(chunk, true)

-- light name scramble inside dump
for name in pairs(MD.used) do
  bytecode = bytecode:gsub(
    "\x04\x07\x00\x00\x00(" .. name .. ")\x00",
    function()
      local r = ""
      for i = 1, 10 do r = r .. string.char(math.random(160, 190)) end
      return "\x04\x0B\x00\x00\x00" .. r .. "\x00"
    end)
end

----------------------------------------------------------------
-- 8. MULTI-LAYER OUTER PACK
--    bytecode → XOR → Caesar → RevKey XOR → RLE → Base64
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
  local k, st = {}, seed % 0x7FFFFFFF
  for i = 1, len do
    st = (1103515245 * st + 12345) % 0x80000000
    k[i] = (st >> 16) & 0xFF
  end
  return k
end

local function xorKey(data, key)
  local o, kl = {}, #key
  for i = 1, #data do
    o[i] = string.char((data:byte(i) ~ key[((i - 1) % kl) + 1]) & 0xFF)
  end
  return table.concat(o)
end

local function caesar(data, sh)
  sh = sh % 256
  local o = {}
  for i = 1, #data do o[i] = string.char((data:byte(i) + sh) % 256) end
  return table.concat(o)
end

local function rle(data)
  local o, i, n = {}, 1, #data
  while i <= n do
    local ch = data:sub(i, i)
    local j = i + 1
    while j <= n and data:sub(j, j) == ch and (j - i) < 255 do j = j + 1 end
    local run = j - i
    if run > 4 then
      o[#o + 1] = string.char(0, run, ch:byte())
      i = j
    else
      o[#o + 1] = data:sub(i, j - 1)
      i = j
    end
  end
  return table.concat(o)
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64(data)
  return ((data:gsub(".", function(x)
    local r, b = "", x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i - 1) > 0 and "1" or "0") end
    return r
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
    if #x < 6 then return "" end
    local c = 0
    for i = 1, 6 do c = c * 2 + (x:sub(i, i) == "1" and 1 or 0) end
    return B64:sub(c + 1, c + 1)
  end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local seed    = (os.time() ~ #bytecode ~ math.floor(os.clock() * 1e6)) & 0x7FFFFFFF
local keyLen  = 128
local mainKey = deriveKey(seed, keyLen)
local revKey  = {}
for i = 1, keyLen do revKey[i] = mainKey[keyLen - ((i - 1) % keyLen)] end

local stage1 = xorKey(bytecode, mainKey)
local stage2 = caesar(stage1, (seed % 251) + 3)
local stage3 = xorKey(stage2, revKey)
local packed = b64(rle(stage3))
local cksum  = adler32(bytecode)

----------------------------------------------------------------
-- 9. POLYMORPHIC LOADER
----------------------------------------------------------------
local V1, V2, V3 = MD.rnd(9), MD.rnd(8), MD.rnd(7)

local loader = string.format([=[
-- Kinzi unique loader
local %s=%d local %s=%d local %s=[[%s]]
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
      o[#o+1]=string.rep(string.char(s:byte(i+2)),s:byte(i+1)); i=i+3
    else o[#o+1]=s:sub(i,i); i=i+1 end
  end
  return table.concat(o)
end
local function der(seed,len)
  local k,st={},seed%%0x7FFFFFFF
  for i=1,len do st=(1103515245*st+12345)%%0x80000000; k[i]=(st>>16)&0xFF end
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
  for i=1,#s do a=(a+s:byte(i))%%65521; b=(b+a)%%65521 end
  return b*65536+a
end
local raw=b64d(%s)
local st=rled(raw)
local key=der(%s,128)
local rkey={} for i=1,#key do rkey[i]=key[#key-((i-1)%%#key)] end
local after=xk(st,rkey)
local s2=crev(after,(%s%%251)+3)
local plain=xk(s2,key)
if adl(plain)~=%s then pcall(function() gg.toast("⚠️") end) return end
local fn=load(plain,"@k")
if type(fn)=="function" then pcall(fn) end
]=], V1, seed, V2, cksum, V3, packed, V3, V1, V1, V2)

----------------------------------------------------------------
-- 10. ONE-TIME USE (non-destructive)
----------------------------------------------------------------
local once = [[
local __f=gg.getFile()..".runonce"
local __h=io.open(__f,"r")
if __h then __h:close() gg.alert("❌ One-time only on this device.") return end
local __w=io.open(__f,"w") if __w then __w:write("1") __w:close() end
]]
loader = once .. "\n" .. loader

----------------------------------------------------------------
-- 11. WRITE
----------------------------------------------------------------
if not MD.io(outputPath, loader) then
  gg.alert("❌ Write failed:\n" .. outputPath)
  return
end

gg.alert("🔐 Done (Unique Strengthened Build)\n\n" ..
         outputPath .. "\n\n" ..
         "• Mixed string styles (A/B/C)\n" ..
         "• API renamed + byte-form defs\n" ..
         "• Multi-layer pack + integrity\n" ..
         "• Soft anti-debug (panel-safe)\n" ..
         "• One-time flag (no delete)")
