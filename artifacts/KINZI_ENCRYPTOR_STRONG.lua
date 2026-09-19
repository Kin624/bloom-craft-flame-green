--[[
================================================================================
  KINZI ENCRYPTOR – FINAL STRONG
  ================================
  Strong pack + reliable run (CPM1 / panel / login safe)

  Pipeline:
    1. Soft anti (dump/cloner only – prompts & makeRequest OK)
    2. load(your script) → string.dump  (logic unchanged)
    3. Strong pack: XOR(256-key) → Caesar → XOR(rev) → RLE → Base64
    4. Tiny ASCII-only loader (no CJK, no format bugs)

  NOT used (broke your scripts before):
    • String rewrite / API rename
    • One-time lock / stealer
    • CJK identifiers in code (Telegram corrupts them)

  Output: yourscript.MANIFEST_DEPLOYMENT.lua
================================================================================
]]

print("\nKINZI ENCRYPTOR – FINAL STRONG\n")

math.randomseed(os.time() + math.floor(os.clock() * 1e6) % 1e6)

local gg, os, io, math, table, string =
      gg, os, io, math, table, string

local MD = {}

----------------------------------------------------------------
-- IO
----------------------------------------------------------------
local SELF_PATH = gg.getFile()
local SELF_DIR  = (SELF_PATH:match("(.*/)") or "")

local cfg = {
  path = "/sdcard/igaenc.ini",
}

function cfg.io(tbl, path)
  path = path or cfg.path
  if tbl then return gg.saveVariable(tbl, path) end
  local fn = loadfile(path)
  if fn then return { "SELECT FILE :" }, fn(), { "file" } end
  return { "SELECT FILE :" }, { SELF_PATH, SELF_DIR }, { "file" }
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
-- SELECT
----------------------------------------------------------------
local sel = gg.prompt(cfg.io())
if not sel then return false end
cfg.io(sel)

local inputPath  = sel[1]
local outputPath = inputPath .. ".MANIFEST_DEPLOYMENT.lua"

MD.data = MD.io(inputPath)
if type(MD.data) ~= "string" or #MD.data < 2 then
  gg.alert("Cannot read script")
  return
end

----------------------------------------------------------------
-- SOFT ANTI (panel safe)
----------------------------------------------------------------
local ANTI = [=[
pcall(function() gg.setVisible(false) end)
pcall(function() gg.toast("KINZI PROTECTED") end)
do
  local R = {}
  for _, fn in ipairs({"loadfile","dofile"}) do
    if _G[fn] then
      R[fn] = _G[fn]
      _G[fn] = function(p, ...)
        if type(p)=="string" then
          local pl = p:lower()
          if pl:match("dump") or pl:match("syslog") or pl:match("payload")
             or pl:match("lokinzer") or pl:match("unlua") or pl:match("decompile") then
            pcall(function() gg.toast("LOAD BLOCKED") end)
            return nil
          end
        end
        return R[fn](p, ...)
      end
    end
  end
end
do
  local RIO = io
  if RIO then
    _G.io = {
      open = function(f, m)
        if type(f)=="string" then
          local fl = f:lower()
          if fl:match("%.syslog") or fl:match("payload") or fl:match("rl%.log")
             or fl:match("lokinzer") or fl:match("gg_dump") then
            pcall(function() gg.toast("IO DUMP BLOCKED") end)
            return nil
          end
        end
        return RIO.open(f, m)
      end,
      write=function(...) return RIO.write(...) end,
      read=function(...) return RIO.read(...) end,
      close=function(...) return RIO.close(...) end,
      input=function(...) return RIO.input(...) end,
      output=function(...) return RIO.output(...) end,
      lines=function(...) return RIO.lines(...) end,
      tmpfile=function(...) return RIO.tmpfile(...) end,
    }
  end
end
pcall(function()
  local ti = gg.getTargetInfo and gg.getTargetInfo()
  local pkg = gg.getTargetPackage and gg.getTargetPackage()
  if ti and type(ti.label)=="string" then
    local lb = ti.label:lower()
    if lb:match("clone") or lb:match("parallel") or lb:match("multi") then
      gg.toast("CLONER"); os.exit()
    end
  end
  if type(pkg)=="string" then
    local p = pkg:lower()
    if p:match("parallel") or p:match("multi") or p:match("clone") then
      gg.toast("CLONER"); os.exit()
    end
  end
end)
pcall(function()
  for _, p in ipairs({"/sdcard/RL.LOG","/sdcard/.syslog_payload.txt","/sdcard/lokinzer.log","/sdcard/GG_DUMP.txt"}) do
    local f = io.open(p, "r")
    if f then f:close(); pcall(os.remove, p) end
  end
end)
pcall(function()
  local base = gg.getFile()
  if type(base)~="string" then return end
  for _, s in ipairs({".dump.txt",".luac.dump.txt",".log.txt",".load_0.lua",".load_1.lua"}) do
    pcall(os.remove, base..s)
  end
end)
pcall(function() gg.toast("KINZI OK") end)
]=]

MD.data = ANTI .. "\n" .. MD.data

----------------------------------------------------------------
-- DUMP
----------------------------------------------------------------
gg.toast("Building bytecode...")
local chunk, err = load(MD.data)
if not chunk then
  gg.alert("Load failed:\n" .. tostring(err))
  return false
end
local bytecode = string.dump(chunk, true)

----------------------------------------------------------------
-- PACK (strong, simple, proven reverse order)
----------------------------------------------------------------
local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do a = (a + s:byte(i)) % 65521; b = (b + a) % 65521 end
  return b * 65536 + a
end

local function der(seed, len)
  local k, st = {}, seed % 0x7FFFFFFF
  for i = 1, len do
    st = (1103515245 * st + 12345) % 0x80000000
    k[i] = (st >> 16) & 0xFF
  end
  return k
end

local function xk(data, key)
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
    if (j - i) > 4 then
      o[#o + 1] = string.char(0, j - i, ch:byte())
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

local seed = (os.time() ~ #bytecode ~ math.floor(os.clock() * 1e6)) & 0x7FFFFFFF
if seed == 0 then seed = 1 end
local keyLen = 256
local mainKey = der(seed, keyLen)

-- reverse key built safely with number length
local revKey = {}
local kn = #mainKey
for i = 1, kn do
  revKey[i] = mainKey[kn - ((i - 1) % kn)]
end

local midKey = der(seed ~ 0xA5A5A5, keyLen)
local shift = (seed % 251) + 3

local s1 = xk(bytecode, mainKey)
local s2 = caesar(s1, shift)
local s3 = xk(s2, revKey)
local s4 = xk(s3, midKey)
local packed = b64(rle(s4))
local ck = adler32(bytecode)

-- split seed (3 parts)
local sa = math.random(1, 0x3FFFFFFF)
local sb = math.random(1, 0x3FFFFFFF)
local sc = (seed ~ sa ~ sb) & 0x7FFFFFFF

-- decoy blobs (ASCII only content)
local function fake(n)
  local t = {}
  for i = 1, n do t[i] = B64:sub(math.random(1, 64), math.random(1, 64)) end
  return table.concat(t)
end
local d1 = fake(math.random(300, 500))
local d2 = fake(math.random(400, 600))

----------------------------------------------------------------
-- LOADER (hand-built, ASCII names only, no string.format % bugs)
----------------------------------------------------------------
-- variable names: pure a-z
local function rn()
  local t = {}
  for i = 1, 8 do t[i] = string.char(97 + math.random(0, 25)) end
  return table.concat(t)
end

local n_sa, n_sb, n_sc = rn(), rn(), rn()
local n_d1, n_hdr, n_d2, n_pay = rn(), rn(), rn(), rn()
local n_seed = rn()
local n_alph, n_map = rn(), rn()
local n_b64, n_rle, n_der, n_xor, n_crev, n_adl = rn(), rn(), rn(), rn(), rn(), rn()
local n_raw, n_st, n_key, n_kn, n_rk, n_mid = rn(), rn(), rn(), rn(), rn(), rn()
local n_t1, n_t2, n_t3, n_pl, n_fn, n_ck = rn(), rn(), rn(), rn(), rn(), rn()

-- header is plain numbers (not encrypted JSON) to avoid extra failure points
-- strength is in the payload pack; seed split still hides the real seed

local L = {}
local function A(s) L[#L + 1] = s end

A("-- KINZI STRONG | DECRYPTOR(NOOB) | 禁止反编译")
A(string.format("local %s,%s,%s=%d,%d,%d", n_sa, n_sb, n_sc, sa, sb, sc))
A(string.format("local %s=[[%s]]", n_d1, d1))
A(string.format("local %s=[[%s]]", n_pay, packed))
A(string.format("local %s=[[%s]]", n_d2, d2))
A(string.format("local %s=(%s~%s~%s)&0x7FFFFFFF", n_seed, n_sa, n_sb, n_sc))
A(string.format("local %s=%d", n_ck, ck))
A(string.format('local %s="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"', n_alph))
A(string.format("local %s={} for i=1,#%s do %s[%s:sub(i,i)]=i-1 end", n_map, n_alph, n_map, n_alph))

-- b64 decode
A(string.format([[
local function %s(s)
  s=s:gsub("[^"..%s.."=]","")
  return (s:gsub(".",function(x)
    if x=="=" then return "" end
    local v=%s[x] local r=""
    for i=5,0,-1 do r=r..(((v>>i)&1)==1 and "1" or "0") end
    return r
  end):gsub("%%d%%d%%d?%%d?%%d?%%d?%%d?%%d?",function(x)
    if #x~=8 then return "" end
    local c=0 for i=1,8 do c=c*2+(x:sub(i,i)=="1" and 1 or 0) end
    return string.char(c)
  end))
end]], n_b64, n_alph, n_map))

-- rle
A(string.format([[
local function %s(s)
  local o,i,n={},1,#s
  while i<=n do
    local c=s:byte(i)
    if c==0 and i+2<=n then
      o[#o+1]=string.rep(string.char(s:byte(i+2)),s:byte(i+1)); i=i+3
    else
      o[#o+1]=s:sub(i,i); i=i+1
    end
  end
  return table.concat(o)
end]], n_rle))

-- derive
A(string.format([[
local function %s(seed,len)
  local k,st={},seed%%0x7FFFFFFF
  for i=1,len do
    st=(1103515245*st+12345)%%0x80000000
    k[i]=(st>>16)&0xFF
  end
  return k
end]], n_der))

-- xor
A(string.format([[
local function %s(d,k)
  local o,kl={},#k
  for i=1,#d do
    o[i]=string.char((d:byte(i)~k[((i-1)%%kl)+1])&0xFF)
  end
  return table.concat(o)
end]], n_xor))

-- caesar reverse
A(string.format([[
local function %s(d,sh)
  sh=sh%%256
  local t={}
  for i=1,#d do t[i]=string.char((d:byte(i)-sh)%%256) end
  return table.concat(t)
end]], n_crev))

-- adler
A(string.format([[
local function %s(s)
  local a,b=1,0
  for i=1,#s do a=(a+s:byte(i))%%65521; b=(b+a)%%65521 end
  return b*65536+a
end]], n_adl))

-- unpack payload (correct reverse order)
A(string.format("local %s=%s(%s)", n_raw, n_b64, n_pay))
A(string.format("local %s=%s(%s)", n_st, n_rle, n_raw))
A(string.format("local %s=%s(%s,%d)", n_key, n_der, n_seed, keyLen))
A(string.format("local %s=#%s", n_kn, n_key))
A(string.format("local %s={} for i=1,%s do %s[i]=%s[%s-((i-1)%%%s)] end", n_rk, n_kn, n_rk, n_key, n_kn, n_kn))
A(string.format("local %s=%s((%s~0xA5A5A5)&0x7FFFFFFF,%d)", n_mid, n_der, n_seed, keyLen))
A(string.format("local %s=%s(%s,%s)", n_t1, n_xor, n_st, n_mid))
A(string.format("local %s=%s(%s,%s)", n_t2, n_xor, n_t1, n_rk))
A(string.format("local %s=%s(%s,(%s%%251)+3)", n_t3, n_crev, n_t2, n_seed))
A(string.format("local %s=%s(%s,%s)", n_pl, n_xor, n_t3, n_key))
A(string.format("if %s(%s)~=%s then pcall(function() gg.toast('KINZI integrity') end) return end", n_adl, n_pl, n_ck))
A(string.format("local %s=load(%s,'@k') if type(%s)=='function' then pcall(%s) end", n_fn, n_pl, n_fn, n_fn))
A(string.format("if false then %s(%s) %s(%s) end", n_b64, n_d1, n_b64, n_d2))

local loader = table.concat(L, "\n")

local banner = [=[
--[[
  KINZI STRONG PROTECTED
  禁止反编译 / NO DECRYPT / DECRYPTOR(NOOB)
  Si kinzi ay isang chill na tao
--]]
]=]

loader = banner .. "\n" .. loader

----------------------------------------------------------------
-- WRITE
----------------------------------------------------------------
if not MD.io(outputPath, loader) then
  gg.alert("Cannot write:\n" .. outputPath)
  return
end

gg.alert("KINZI FINAL STRONG – Done\n\n" ..
         "File:\n" .. outputPath .. "\n\n" ..
         "• Soft anti (panel/login safe)\n" ..
         "• Bytecode + 4-layer pack\n" ..
         "• Split seed + decoys\n" ..
         "• ASCII loader (Telegram safe)\n" ..
         "• Logic unchanged\n" ..
         "• No one-time lock")
