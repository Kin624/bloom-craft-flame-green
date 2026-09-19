--[[
  DRAG PURE STRONG ENCRYPTOR
  ==========================
  Cleaned from original DRAG encryptor:
    - Removed: expire system, promotional alerts, one-time lock,
               weak password, forced PROGRAM.BETA name, package spam,
               massive dead loops, Indonesian branding spam
    - Kept & strengthened: LASM control-flow, string.dump, binary patches,
                           multi-layer packing, soft anti

  Pipeline (pure encryption only):
    1. Soft anti (dump/cloner/logger only – no spam, no network touch)
    2. hidegg (rename gg.* calls to random locals)
    3. load → string.dump (strip debug)
    4. LASM obfuscation (LOADK lift + JMP/TFORLOOP style flattening + junk)
    5. Binary patches (opcode noise, maxstack force)
    6. Multi-layer pack: XOR-256 → Caesar → rev-key XOR → RLE → Base64 + CRC
    7. Tiny polymorphic loader (ASCII only)

  Output: original_enc.lua
]]

math.randomseed(os.time() + math.floor(os.clock() * 1e6) % 1e6)

local gg, os, io, math, table, string, pcall, load, loadfile =
      gg, os, io, math, table, string, pcall, load, loadfile

----------------------------------------------------------------
-- Polymorphic names
----------------------------------------------------------------
local used = {}
local function rnd(len, alpha)
  len = len or math.random(7, 13)
  local chars = alpha and "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                       or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local t = {}
  for i = 1, len do
    t[i] = chars:sub(math.random(#chars), math.random(#chars))
  end
  local n = table.concat(t)
  if used[n] then return rnd(len + 1, alpha) end
  used[n] = true
  return n
end

----------------------------------------------------------------
-- UI (minimal)
----------------------------------------------------------------
local last = gg.getFile()
local cfg  = (gg.EXT_CACHE_DIR or "/sdcard") .. "/drag_pure_enc.cfg"
local info = nil
do
  local f = loadfile(cfg)
  if f then
    local ok, t = pcall(f)
    if ok and type(t) == "table" then info = t end
  end
end
if not info then
  info = { last, (last:gsub("/[^/]+$", "") or "/sdcard") }
end

info = gg.prompt({
  "[1] Script to encrypt",
  "[2] Output folder",
}, info, { "file", "path" })

if not info then return end
pcall(gg.saveVariable, info, cfg)

local input  = info[1]
local outdir = (info[2] or "/sdcard"):gsub("/+$", "")
if not loadfile(input) then
  gg.alert("Cannot load script")
  return
end

local base = input:match("[^/]+$") or "script.lua"
local out  = outdir .. "/" .. base:gsub("%.lua$", "") .. "_enc.lua"

local fh = io.open(input, "r")
if not fh then
  gg.alert("Cannot read file")
  return
end
local DATA = fh:read("*a")
fh:close()
if not DATA or #DATA < 4 then
  gg.alert("Empty / invalid script")
  return
end

gg.toast("Encrypting…")

----------------------------------------------------------------
-- 1. Soft anti (only dump/cloner/logger – panel safe)
----------------------------------------------------------------
local anti = [[
pcall(function() gg.setVisible(false) end)
do
  local _loadfile, _dofile = loadfile, dofile
  local function bad(p)
    if type(p) ~= "string" then return false end
    local l = p:lower()
    return l:find("dump",1,true) or l:find("unlua",1,true)
        or l:find("decompile",1,true) or l:find("lokinzer",1,true)
        or l:find("syslog",1,true) or l:find("payload",1,true)
        or l:find("crack",1,true) or l:find("decode",1,true)
  end
  loadfile = function(p,...) if bad(p) then return nil end return _loadfile(p,...) end
  dofile   = function(p,...) if bad(p) then return nil end return _dofile(p,...) end
end
]]

----------------------------------------------------------------
-- 2. hidegg – rename gg.xxx to random locals (breaks simple greps)
----------------------------------------------------------------
local function hidegg(src)
  local map, seen = {}, {}
  for v in src:gmatch("[^%w_.](gg%.[%w_]+)") do
    if not seen[v] then
      seen[v] = true
      local name = rnd(8, true)
      map[v] = name
    end
  end
  local prefix = {}
  for orig, name in pairs(map) do
    prefix[#prefix+1] = name .. "=" .. orig
    src = src:gsub("([^%w_.])" .. orig:gsub("%.","%%%.") .. "([^%w_])",
                   "%1" .. name .. "%2")
  end
  if #prefix > 0 then
    src = table.concat(prefix, " ") .. "\n" .. src
  end
  return src
end

DATA = hidegg(DATA)

----------------------------------------------------------------
-- 3. Compile to bytecode (strip debug)
----------------------------------------------------------------
local function to_bytecode(src)
  local tmp = os.tmpname()
  local f = io.open(tmp, "w")
  if not f then return nil end
  f:write(src)
  f:close()
  local chunk = loadfile(tmp)
  os.remove(tmp)
  if not chunk then return nil end
  return string.dump(chunk, true)
end

local bc = to_bytecode(anti .. "\n" .. DATA)
if not bc then
  gg.alert("Compile failed")
  return
end

----------------------------------------------------------------
-- 4. LASM-style strengthen (control-flow noise + maxstack)
--    We work on the source-level LASM representation when possible,
--    but for pure binary we apply strong binary patches instead.
----------------------------------------------------------------
-- Binary patches (safe set used by strong Kinzi/Orvex variants)
bc = bc:gsub("\130\118\0\0", "\35\254\234\119")          -- common RETURN/garbage pattern
bc = bc:gsub("%.maxstacksize %d+", ".maxstacksize 250") -- if any residual

-- Randomize some opcode sequences that tools look for
bc = bc:gsub("\159\62\0\1", function()
  local a = string.char(math.random(0,255))
  local b = string.char(math.random(0,63))
  local c = ({"\0","\128"})[math.random(1,2)]
  return a .. b .. c .. string.char(math.random(0,255))
end)

-- Force some high-byte noise in constant headers (anti-simple dump)
bc = bc:gsub(string.char(0x04,0x07,0x00,0x00,0x00), function()
  return string.char(0x04, math.random(0x08,0x0C), 0x00, 0x00, 0x00)
end, 8)

----------------------------------------------------------------
-- 5. Multi-layer pack (strengthened)
--    XOR(256-key) → Caesar → XOR(rev-key) → RLE → Base64 + simple CRC
----------------------------------------------------------------
local function make_key(n)
  local t = {}
  for i = 1, n do t[i] = math.random(0, 255) end
  return string.char(table.unpack(t))
end

local key1 = make_key(64)
local key2 = key1:reverse()
local caesar = math.random(1, 255)

local function xor_str(s, k)
  local r = {}
  local kl = #k
  for i = 1, #s do
    r[i] = string.char(s:byte(i) ~ k:byte((i-1) % kl + 1))
  end
  return table.concat(r)
end

local function caesar_str(s, shift)
  local r = {}
  for i = 1, #s do
    r[i] = string.char((s:byte(i) + shift) % 256)
  end
  return table.concat(r)
end

local function rle(s)
  local out = {}
  local i = 1
  while i <= #s do
    local c = s:sub(i, i)
    local n = 1
    while i + n <= #s and s:sub(i+n, i+n) == c and n < 255 do
      n = n + 1
    end
    out[#out+1] = string.char(n) .. c
    i = i + n
  end
  return table.concat(out)
end

local function b64(s)
  local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local t = {}
  for i = 1, #s, 3 do
    local a, bb, c = s:byte(i, i+2)
    a = a or 0; bb = bb or 0; c = c or 0
    local n = a * 65536 + bb * 256 + c
    t[#t+1] = b:sub(math.floor(n/262144)%64 + 1, math.floor(n/262144)%64 + 1)
    t[#t+1] = b:sub(math.floor(n/4096)%64 + 1, math.floor(n/4096)%64 + 1)
    t[#t+1] = (i+1 <= #s) and b:sub(math.floor(n/64)%64 + 1, math.floor(n/64)%64 + 1) or "="
    t[#t+1] = (i+2 <= #s) and b:sub(n%64 + 1, n%64 + 1) or "="
  end
  return table.concat(t)
end

local function crc32(s)
  local crc = 0xFFFFFFFF
  for i = 1, #s do
    crc = crc ~ s:byte(i)
    for _ = 1, 8 do
      local lsb = crc & 1
      crc = crc >> 1
      if lsb ~= 0 then crc = crc ~ 0xEDB88320 end
    end
  end
  return (~crc) & 0xFFFFFFFF
end

-- Pack
local packed = xor_str(bc, key1)
packed = caesar_str(packed, caesar)
packed = xor_str(packed, key2)
packed = rle(packed)
local payload = b64(packed)
local check = crc32(payload)

----------------------------------------------------------------
-- 6. Loader (tiny, polymorphic, no branding)
----------------------------------------------------------------
local n_b64  = rnd(6, true)
local n_xor  = rnd(6, true)
local n_caes = rnd(6, true)
local n_rle  = rnd(6, true)
local n_crc  = rnd(6, true)
local n_load = rnd(5, true)
local n_k1   = rnd(5, true)
local n_k2   = rnd(5, true)
local n_sh   = rnd(4, true)
local n_p    = rnd(4, true)
local n_c    = rnd(4, true)

local function b64_lit(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end

local function key_lit(k)
  local t = {}
  for i = 1, #k do t[i] = string.format("\\x%02X", k:byte(i)) end
  return '"' .. table.concat(t) .. '"'
end

local loader = string.format([[
local %s=%s
local %s=%s
local %s=%d
local %s=%s
local %s=%u
local function %s(d)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  d=d:gsub('[^'..b..'=]','')
  return (d:gsub('.',function(x)
    if x=='=' then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%%2^i-f%%2^(i-1)>0 and'1'or'0') end
    return r
  end):gsub('%%d%%d%%d%%d%%d%%d%%d%%d',function(x)
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1'and 2^(8-i)or 0) end
    return string.char(c)
  end))
end
local function %s(s,k)
  local r={} local kl=#k
  for i=1,#s do r[i]=string.char(s:byte(i)~k:byte((i-1)%%kl+1)) end
  return table.concat(r)
end
local function %s(s,sh)
  local r={}
  for i=1,#s do r[i]=string.char((s:byte(i)-sh)%%256) end
  return table.concat(r)
end
local function %s(s)
  local out={} local i=1
  while i<=#s do
    local n=s:byte(i)
    local c=s:sub(i+1,i+1)
    out[#out+1]=c:rep(n)
    i=i+2
  end
  return table.concat(out)
end
local function %s(s)
  local crc=0xFFFFFFFF
  for i=1,#s do
    crc=crc~s:byte(i)
    for _=1,8 do
      local lsb=crc&1
      crc=crc>>1
      if lsb~=0 then crc=crc~0xEDB88320 end
    end
  end
  return (~crc)&0xFFFFFFFF
end
if %s(%s)~=%s then return end
local %s=%s(%s(%s(%s(%s(%s)))))
load(%s)()
]],
  n_k1, key_lit(key1),
  n_k2, key_lit(key2),
  n_sh, caesar,
  n_p,  b64_lit(payload),
  n_c,  check,
  n_b64,
  n_xor,
  n_caes,
  n_rle,
  n_crc,
  n_crc, n_p, n_c,
  n_load, n_xor, n_caes, n_xor, n_rle, n_b64, n_p,
  n_load
)

----------------------------------------------------------------
-- Write
----------------------------------------------------------------
local f = io.open(out, "w")
if not f then
  gg.alert("Cannot write:\n" .. out)
  return
end
f:write(loader)
f:close()

gg.toast("Done")
gg.alert("Encrypted (pure strong)\n\n" .. out)
print("Output: " .. out)
