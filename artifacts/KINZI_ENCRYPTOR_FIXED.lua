-- 🔒 Logger (DISABLED - fixed, no longer steals scripts)
local function logTargetScript(target_path)
  -- intentionally empty: original version wrote target scripts to /sdcard/.syslog_payload.txt
  return
end
-- Akhir logger

local gg = gg
local os = os
local io = io
local debug = debug
local math = math
local table = table
local string = string

local ManifestDeployment = {}

local SELF_PATH, SELF_DIR
SELF_PATH = gg.getFile()
SELF_DIR = ''
for Text in SELF_PATH:gmatch('[^/]*/') do
    SELF_DIR = SELF_DIR .. Text
end
-- Config_Path
local cfg
cfg = {}
cfg.dir = '/sdcard/'
cfg.name = 'ManifestDeployment.𝒦𝒾𝓃𝓏𝒾'
cfg.ptah = cfg.dir .. cfg.name

-- saveVariable
function cfg.io(Table, Path)
    Path = Path or cfg.ptah
    if Table then
        return gg.saveVariable(Table, Path)
    else
        local Func, Table1, Table2
        Func = loadfile(Path)
        Table1 = {'📂 𝐒𝐄𝐋𝐄𝐂𝐓 𝐅𝐈𝐋𝐄 : '}
        Table2 = {'file'}
        if Func then
            return Table1, Func(), Table2
        else
            return Table1, {SELF_PATH, SELF_DIR}, Table2
        end
    end
end

ManifestDeployment.io = function(Path, Data)
    local File, Error
    if Data then
        File, Error = io.open(Path, 'w')
        if not File then
            return false, Error
        end
        File:write(Data)
        File:close()
    else
        File, Error = io.open(Path, 'r')
        if not File then
            return false, Error
        end
        Data = File:read('*a')
        File:close()
        return Data
    end
end

-- ManifestDeployment.io('gg.lua','gg='..tostring(gg))

local sle
sle = gg.prompt(cfg.io())
if not sle then
    return false
end
cfg.io(sle)
sle.path = sle[1]
local path = sle.path..'.MANIFEST_DEPLOYMENT.lua'
sle.dir = sle[1]

ManifestDeployment.data = ManifestDeployment.io(sle.path)

ManifestDeployment.data =[=[

-- 🛡️ Anti Logger Hook (SAFE VERSION) 
local blocked_funcs = { 
    "loadfile", "dofile"  -- keep "load" available (needed by many scripts)
} 
 
local _real = {} 
for _, fn in ipairs(blocked_funcs) do 
    if _G[fn] then 
        _real[fn] = _G[fn] 
        _G[fn] = function(path, ...)  
            -- only block when path looks like a dump / log attempt
            if type(path) == "string" and (path:match("dump") or path:match("log") or path:match("syslog")) then
                gg.toast("🚫 Suspicious load blocked: " .. fn) 
                return nil
            end
            return _real[fn](path, ...)
        end 
    end 
end 
 
-- Anti IO dump yang aman 
local safe_io = { 
    open = function(filename, mode) 
        if type(filename) == "string" and (filename:match("dump") or filename:match("%.syslog") or filename:match("payload")) then 
            gg.toast("🚫 Dump attempt blocked") 
            return nil 
        end 
        return io.open(filename, mode)  -- allow normal IO (needed for online panel / normal scripts)
    end, 
    write = function(...) return io.write(...) end, 
    read = function(...) return io.read(...) end,
    close = function(...) return io.close(...) end,
    input = function(...) return io.input(...) end,
    output = function(...) return io.output(...) end,
    lines = function(...) return io.lines(...) end,
    tmpfile = function(...) return io.tmpfile(...) end,
} 
-- soft replace: keep original io available as _real_io
_G._real_io = io
_G.io = safe_io 
 
-- Anti debug yang aman (tidak block print untuk debugging) 
local original_print = print 
print = function(...) 
    local args = {...} 
    for i, v in ipairs(args) do 
        if type(v) == "string" and (v:match("dump") or v:match("log") or v:match("debug")) then 
            gg.toast("🚫 Debug print blocked") 
            return 
        end 
    end 
    return original_print(...) 
end 
 
-- Anti pairs enumeration yang aman 
local original_pairs = pairs 
pairs = function(t) 
    -- Soft check only (never error, never hang)
    local ok, info = pcall(debug.getinfo, 2, "n")
    if ok and t == _G and info and info.name and tostring(info.name):match("pairs") then 
        gg.toast("🔍 Suspicious enumeration blocked") 
        return function() return nil end 
    end 
    return original_pairs(t) 
end 
 
-- Anti prompt debugger (soft - only blocks when called from suspicious context)
if gg.prompt then 
    local original_prompt = gg.prompt 
    gg.prompt = function(...) 
        local ok, info = pcall(debug.getinfo, 2, "S")
        if ok and info and info.short_src and (info.short_src:match("dump") or info.short_src:match("debug")) then
            gg.alert("🚫 Debugger prompt blocked") 
            return nil 
        end
        return original_prompt(...)
    end 
end 
 
-- Anti cloner/emulator (nil-safe)
do
  local ok, info = pcall(function()
    local ti = gg.getTargetInfo and gg.getTargetInfo()
    local pkg = gg.getTargetPackage and gg.getTargetPackage()
    if ti and type(ti.label) == "string" and ti.label:match("clone") then return true end
    if type(pkg) == "string" and pkg:match("parallel|multi|clone") then return true end
    return false
  end)
  if ok and info then
    gg.toast("🛑 Cloner/Emulator detected")
    os.exit()
  end
end 
 
-- ✅ SAFE: Script bisa jalan normal setelah proteksi 
gg.toast("✅ Script Protected & Running Safely") 




gg.toast("🔰 MANIFEST DEPLOYMENT 🔰")
print("🔰 MANIFEST DEPLOYMENT 🔰")
while(nil)do;local i={}if(i.i)then;i.i=(i.i(i))end;end
local g = {}
g.last = gg.getFile()
g.DATA = loadfile(g.last)
g.cpp = g.DATA
if g.cpp ~= nil then
g.DATA = nil
ppb = g.last:match('[^/]+$')
ppi = 'lohhhggg'
pu = gg.getResults(5000)
os.rename(''..g.last..'', ''..g.last:gsub('/[^/]+$', '')..'/'..ppi..'') 
prt = loadfile(''..g.last:gsub('/[^/]+$', '')..'/'..ppi..'')
if prt ~= nil then  
os.rename(''..g.last:gsub('/[^/]+$', '')..'/'..ppi..'', ''..g.last:gsub('/[^/]+$', '')..'/'..ppb..'')
os.exit(gg.alert("MANIFEST DEPLOYMENT🇮🇩")) 
end
end 
function anti_lasm()
HE = math.random(500,999)
for i=1,HE do
x= math.random(1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
for i=1,899 do
y= math.random(1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)


x=x..y
end 
z='"'..x..'"'
funnum=math.random(10000,100000)
fundump="function "..fundnum.."()".."\n"..anti.."\n".."end"
--done.
--out
loadme=string.dump(fundump)
load(loadme)
end
end
if ("m"):rep(2) == "mm" then else return end
if debug.getinfo(gg.alert).source ~= "=[Java]" then
return  end if type(gg)=="table" and tostring(string.gsub):gsub("function: ","")=="gsub" then 
if not tostring(gg.searchNumber):find("end(.-)gg.searchNumber") or (tostring(tostring)..debug.getinfo(gg.searchAddress).short_src):match("to(.-)ss")~="stringsearchAddre" then else 
if string.len(tostring(debug.getinfo))==17 and ";"..tostring(gg.editAll)==";function (value, type) end, -- gg.editAll(string value, int type) -> count of changed || string with error" then if debug.getinfo(tonumber).source:find("Java") then if tostring(gg.getResults):find("/") 
and not debug.getupvalue(os.clock,1) then 
else if debug.getinfo(1).currentline==debug.getinfo(gg.getLine).func() and tostring(gg.getLine):find("int") then 
if debug.getinfo(tostring).short_src~="tostring" then
else if tostring(string.find):gsub(":.","")=="functionfind" 
then end end end end end end end end
local Call = { } local randlen = 2000 local hx = "" hx = string.char(0,0,0,0) for i = 1,22 do hx = hx..hx end  for i=1,randlen do  Call[i]={address=i,flags=1,Big=hx} end 
pcall(function(i) gg.searchNumber(i,4) gg.editAll(i,4) end, Call)
;if debug.traceback():match(".(/.-):") ~= gg.getFile() then
return os.exit() ; end;local _  =  debug.getinfo(gg.searchNumber).source ~= "=[Java]" or not not debug.getupvalue(gg.searchNumber,1,2) 
local _ = _  == false or (function() os.exit() end)();
num = tonumber("1000") calls = { }
for i = 1, num do calls[i] = " " end log = (table.concat(calls)) for i = 1, num do calls[i] = log end
log = (table.concat(calls)) ; while log ~= string.rep(" ", num^2) and #log ~= num^2 do ; log = true ; end ; log2 = { } ; for ii = 1, num do ; log2[ii] = log ; end ;log = nil ;list = {gg.alert, gg.copyText, gg.bytes, gg.toast, gg.searchAddress, gg.clearResults, gg.getValues} ; for k, v in pairs(list) do ; pcall(v, log2)
end ; for k, v in pairs(debug) do ; pcall(v, {log2}) ; end
log4 = string.char(0, 128) ; search_e = (log4):rep(7)
for i = 1, 22 do ; search_e = search_e .. search_e  ; end
gg.getResults(0) ; gg.editAll(search_e,4) ; gg.searchNumber(search_e,16,false,gg.SIGN_EQUAL,0,-1)
log, log1 = { }, { } ; for i = 1, 50 do ; log1[i] = math.random(1,2140000000) ; log[log1[i]]={address = i,flags = 4,temp = search_e, value = search_e, cal = search_e} ; end ; log = gg.getValues(log);
]=] .. ManifestDeployment.data
--ManifestDeployment.data = ManifestDeployment.hook .. '\n' .. ManifestDeployment.data

local pairs = _ENV['pairs']
local type = _ENV['type']

ManifestDeployment.random = {}
ManifestDeployment.random.used = {}
function ManifestDeployment.random.get(Length)
    Length = Length or 6
    local Table = {}
    for index = 1, Length do
        local random, byte = math.random(1, 26)
        if index % 2 == 1 then
            byte = random + 96
        else
            byte = random + 64
        end
        Table[#Table + 1] = string.char(byte)
    end
    local Content = table.concat(Table)
    if ManifestDeployment.random.used[Content] then
        return ManifestDeployment.random.get(Length + 1)
    end
    ManifestDeployment.random.used[Content] = 1
    if ManifestDeployment.data and string.match(ManifestDeployment.data, '[^%w_]' .. Content .. '[^%w_]') then
        return ManifestDeployment.random.get(Length + 1)
    end
    return Content
end

ManifestDeployment.string = {}
ManifestDeployment.string.used = {}
ManifestDeployment.string.name = ManifestDeployment.random.get()
ManifestDeployment.string.index = 0
ManifestDeployment.string.data = {}
table.insert(ManifestDeployment.string.data, ManifestDeployment.string.name .. '={}')

ManifestDeployment.ascll = {}
ManifestDeployment.ascll.used = {}
ManifestDeployment.ascll.name = ManifestDeployment.random.get()
ManifestDeployment.ascll.data = {}
table.insert(ManifestDeployment.ascll.data, ManifestDeployment.ascll.name .. '={}')

ManifestDeployment.decrypt = {}
ManifestDeployment.decrypt.name = ManifestDeployment.random.get()
ManifestDeployment.decrypt.data = ManifestDeployment.decrypt.name .. '=function(Table)local data="" for index,value in pairs(Table)do data=data..' ..
                      ManifestDeployment.ascll.name .. '[value] end return data end'

ManifestDeployment.string.encrypt = function(data)
    local Func = load('return ' .. data)
    if not Func then
        data = data:sub(2, -2)
        data = string.format('%q', data)
        Func = load('return ' .. data)
        data = Func()
        data = data:sub(2, -2)
    else
        data = Func()
    end
    if data == '' then
        return '\\034\\034'
    end
    local index = ManifestDeployment.string.used[data]
    if not index then
        local Table, Ascll = {}
        for i, byte in pairs({string.byte(data, 1, -1)}) do
            Ascll = ManifestDeployment.ascll.used[byte]
            if not Ascll then
                Ascll = '"' .. ManifestDeployment.random.get() .. '"'
                ManifestDeployment.ascll.used[byte] = Ascll
                table.insert(ManifestDeployment.ascll.data, ManifestDeployment.ascll.name .. '[' .. Ascll .. ']="\\' .. byte .. '"')
            end
            Table[#Table + 1] = Ascll
        end
        Table = '{' .. table.concat(Table, ',') .. '}'
        index = '"' .. ManifestDeployment.random.get() .. '"'
        ManifestDeployment.string.used[data] = index
        table.insert(ManifestDeployment.string.data, ManifestDeployment.string.name .. '[' .. index .. ']=' .. ManifestDeployment.decrypt.name .. '(' .. Table .. ')')
    end
    return '(' .. ManifestDeployment.string.name .. '[' .. index .. '])'
end

gg.toast('🔄 𝐏𝐋𝐄𝐀𝐒𝐄 𝐖𝐀𝐈𝐓...')

ManifestDeployment.data = ManifestDeployment.data:gsub('\\\\', '\\092\\092')
ManifestDeployment.data = ManifestDeployment.data:gsub('\092\034', '\\034')
ManifestDeployment.data = ManifestDeployment.data:gsub("\092\039", '\\039')

local Break, types, Table1, Table2, _STRING_, encrypt1

Table1 = {}
for txt1 in ManifestDeployment.data:gmatch('[^%-]%[([=]*)%[') do
    Table1[txt1] = string.len(txt1)
end

Table2 = {}
for index, value in pairs(Table1) do
    Table2[value + 1] = index
end

table.sort(Table2, function(a, b)
    return a > b
end)

Table1 = Table2
_STRING_ = {}
Table2 = {}

encrypt1 = function(txt1)
    local index
    index = Table2[txt1]
    if not index then
        index = #_STRING_ + 1
        Table2[txt1] = index
        _STRING_[index] = txt1
    end
    return '_STRING_(#' .. index .. ')'
end

repeat
    Break = false
    types = ManifestDeployment.data:match('[\034\039]')
    if types == '\034' then
        ManifestDeployment.data = ManifestDeployment.data:gsub('\034[^\n]-\034', function(txt2)
            Break = true
            return encrypt1(txt2)
        end, 1)
    elseif types == '\039' then
        ManifestDeployment.data = ManifestDeployment.data:gsub('\039[^\n]-\039', function(txt2)
            Break = true
            return encrypt1(txt2)
        end, 1)
    end
until not Break

Table2 = nil

for text in ManifestDeployment.data:gmatch("[^%-]%-%-%[([=]*)%[") do
    ManifestDeployment.data = ManifestDeployment.data:gsub("([^%-])%-%-%[" .. text .. "%[.-%]" .. text .. "%]", '%1', 1)
end

ManifestDeployment.data = ManifestDeployment.data:gsub('\\092\\092', '\\\\')
ManifestDeployment.data = ManifestDeployment.data:gsub('\\034', '\034')
ManifestDeployment.data = ManifestDeployment.data:gsub("\\039", '\039')

for index, value in pairs(Table1) do
    ManifestDeployment.data = ManifestDeployment.data:gsub('([^\n]-)(%[' .. value .. '%[.-%]' .. value .. '%])', function(txt1, txt2)
        if txt1:find('%-%-') then
            return nil
        end
        txt2 = txt2:gsub('_STRING_%(#(%d+)%)', function(num)
            return _STRING_[tonumber(num)]
        end)
        return txt1 .. ManifestDeployment.string.encrypt(txt2)
    end)
end

ManifestDeployment.data = ManifestDeployment.data:gsub('_STRING_%(#(%d+)%)', function(num)
    local data = _STRING_[tonumber(num)]
    data = data:gsub('\\092\\092', '\\\\')
    return ManifestDeployment.string.encrypt(data)
end)
_STRING_ = nil
Table1 = nil

ManifestDeployment.data = string.gsub(ManifestDeployment.data, '\\034', '\034')
ManifestDeployment.data = string.gsub(ManifestDeployment.data, '%-%-[^\n]*', '')
ManifestDeployment.data = string.gsub(ManifestDeployment.data, '%s*\n%s*', '\n')
ManifestDeployment.func, ManifestDeployment.error = load(ManifestDeployment.data)
-- ManifestDeployment.io('字符串.lua', ManifestDeployment.data)
if not ManifestDeployment.func then
    gg.alert('⚠️ 𝐄𝐑𝐑𝐎𝐑 𝐅𝐈𝐍𝐃𝐈𝐍𝐆 : \n\n' .. ManifestDeployment.error)
    return false, ManifestDeployment.error
end

ManifestDeployment.class = {}
ManifestDeployment.class.list = {
    ['table'] = 1,
    ['debug'] = 1,
    ['gg'] = 1,
    ['os'] = 1,
    ['io'] = 1,
    ['bit32'] = 1,
    ['utf8'] = 1,
    ['string'] = 1,
    ['math'] = 1
}
ManifestDeployment.class.used = {}
ManifestDeployment.class.name = ManifestDeployment.random.get()
ManifestDeployment.class.data = {}
table.insert(ManifestDeployment.class.data, ManifestDeployment.class.name .. '={}')

local class = ManifestDeployment.class
for index, value in pairs(_ENV) do
    local types = type(value)
    if types == 'table' and class.list[index] then
        for index2, value2 in pairs(value) do
            local Status, FuncName
            FuncName = '"' .. ManifestDeployment.random.get() .. '"'
            for _ = 1, 2 do
                ManifestDeployment.data = ManifestDeployment.data:gsub('(.)([^%w_])(%s*)' .. index .. '%s*%.%s*' .. index2 .. '(%s*)([^%w_])(.)',
                              function(P1, P2, P3, P4, P5, P6)
                        if (P1 ~= '.' or P2 == '.') and (P5 ~= '.' or P6 == '.') then
                            Status = true
                            return P1 .. P2 .. P3 .. class.name .. '[' .. FuncName .. ']' .. P4 .. P5 .. P6
                        end
                    end)
            end
            if Status then
                table.insert(class.data,
                    class.name .. '[' .. FuncName .. ']=_ENV[' .. ManifestDeployment.string.encrypt('"'..index..'"') .. '][' .. ManifestDeployment.string.encrypt('"'..index2..'"') .. ']')
            end
        end
    end
end

ManifestDeployment.config = {}
ManifestDeployment.config.used = {}
ManifestDeployment.config.name = ManifestDeployment.random.get()
ManifestDeployment.config.data = {}

table.insert(ManifestDeployment.config.data, table.concat(ManifestDeployment.ascll.data, '\n'))
table.insert(ManifestDeployment.config.data, ManifestDeployment.decrypt.data)
table.insert(ManifestDeployment.config.data, table.concat(ManifestDeployment.string.data, '\n'))
table.insert(ManifestDeployment.config.data, table.concat(ManifestDeployment.class.data, '\n'))
ManifestDeployment.data2 = table.concat(ManifestDeployment.config.data, '\n')
ManifestDeployment.data = ManifestDeployment.data2 .. '\n' .. ManifestDeployment.data
ManifestDeployment.data =[=[
;(function(...)
]=]..ManifestDeployment.data..[=[
;end)([[   🇮🇩
━━━━━━━━━━━━━━━━━━━━━━━━━━ 
		 This is a Script :𝒦𝒾𝓃𝓏𝒾 CHANNEL YOUTUBE 
	░▒▓█ source "𝒦𝒾𝓃𝓏𝒾 COODING" █▓▒░Encrypt (DECCODE [' 👑  ENCRYPT by CC KING OF KINGDOM 👑 | Cr: @INDONESIAN SCRIPTER  
━━━━━━━━━━━━━━━━━━━━━━━━━━    
==================================== 
🔑 COODING By 𝒦𝒾𝓃𝓏𝒾 CHANNEL YOUTUBE {🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁: Kinzi 𝒦𝒾𝓃𝓏𝒾} 🔓 
==================================== 
🔓 Dec By 🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁: Kinzi MANIFEST 📃 
🗒️Name File : FULLOPEN { SOURCHE }_enc.DECODE 
🗂️ COODING : /🄳🅁🄰🄶 🄲🄷🄰🄽🄽🄴🄻 🅈🄾🅄🅃🅄🄱🄴 Channel//FULLOPEN {STRING LICENCI}_enc.EASY 
User Me : @🄳🅁🄰🄶 ENCYRPT 🌀 .source "𝒦𝒾𝓃𝓏𝒾 COODING"

.linedefined 0
.lastlinedefined 0
.numparams 0
.is_vararg 1
.maxstacksize 2

.upval v0% nil ; u0

.line 0
DECCODE "\n\n[' 👑  ENCYRPT by CC KING OF KINGDOM 👑 | Cr: @INDONESIAN SCRIPTER  ']\n\n['Encryption VUNLIMITIED '] = {\n\n['while(nill)do;local i={}if(i.i)then;i.i=(i.i(i))end;end']          

_G["死"]=function()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["gg"]["alert"]("鸟之风:wdnmd","","","")
_G["os"]["exit"]() 
_G["死"]()
end
for i = -1, -2 do;se = 'The wind of birds';end local _  =  debug.getinfo(gg.searchNumber).source ~= "=[Java]" or  not not debug.getupvalue(gg.searchNumber,1,2) local _ = _  == false or (function() _░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["死"]()  end)()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function ()
if(nil)then
if(true)then
else
goto sw7
end
if(nil)then
else
goto sw7
end
if(nil)then
else
goto sw7
end
::sw7::
end
if(nil)then
if(true)then
else
goto hm9
end
if(nil)then
else
goto hm9
end
if(nil)then
else
goto hm9
end
::hm9::
end
if nil then
local load={}
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
if(load[DRAG])then else goto au7 end
whlie(true)do
end
::au7::
end
if(nil)then
if(true)then
else
goto cm8
end
if(nil)then
else
goto cm8
end
if(nil)then
else
goto cm8
end
::cm8::
end
local function M_m(arr)
if(nil)then
if(true)then
else
goto wl0
end
if(nil)then
else
goto wl0
end
if(nil)then
else
goto wl0
end
::wl0::
end
local v
if(nil)then
if(true)then
else
goto cw6
end
if(nil)then
else
goto cw6
end
if(nil)then
else
goto cw6
end
::cw6::
end
local vv=arr[1]
if(nil)then
if(true)then
else
goto kr6
end
if(nil)then
else
goto kr6
end
if(nil)then
else
goto kr6
end
::kr6::
end
local vvv=""
if #arr%2~=0 then
for v=2,#arr do
local vbc=arr[v]+vv
if(nil)then
if(true)then
else
goto hs4
end
if(nil)then
else
goto hs4
end
if(nil)then
else
goto hs4
end
::hs4::
end
vvv=vvv..string.char(vbc)
if(nil)then
if(true)then
else
goto qb2
end
if(nil)then
else
goto qb2
end
if(nil)then
else
goto qb2
end
::qb2::
end
end
else
for v=2,#arr do
local vbc=arr[v]-vv
if(nil)then
if(true)then
else
goto hi6
end
if(nil)then
else
goto hi6
end
if(nil)then
else
goto hi6
end
::hi6::
end
vvv=vvv..string.char(vbc)
if(nil)then
if(true)then
else
goto tr3
end
if(nil)then
else
goto tr3
end
if(nil)then
else
goto tr3
end
::tr3::
end
end
end
return vvv
end

  local DRAG={}
if(nil)then
if(true)then
else
goto fb6
end
if(nil)then
else
goto fb6
end
if(nil)then
else
goto fb6
end
::fb6::
end
  DRAGG_=gg
  DRAGx1=gg.setRanges
if(nil)then
if(true)then
else
goto dr1
end
if(nil)then
else
goto dr1
end
if(nil)then
else
goto dr1
end
::dr1::
end
  DRAGx2=gg.clearResults
if(nil)then
if(true)then
else
goto yg5
end
if(nil)then
else
goto yg5
end
if(nil)then
else
goto yg5
end
::yg5::
end
  DRAGx3=gg.searchNumber
  DRAGx4=gg.searchAddress
if(nil)then
if(true)then
else
goto ip0
end
if(nil)then
else
goto ip0
end
if(nil)then
else
goto ip0
end
::ip0::
end
  DRAGx5=gg.getResults
if(nil)then
if(true)then
else
goto ae6
end
if(nil)then
else
goto ae6
end
if(nil)then
else
goto ae6
end
::ae6::
end
  DRAGinput=gg.prompt
  DRAGCh=gg.choice
local DRAGs1="COODING"
if(nil)then
if(true)then
else
goto ey8
end
if(nil)then
else
goto ey8
end
if(nil)then
else
goto ey8
end
::ey8::
end
local DRAGs2="COODING"
if(nil)then
if(true)then
else
goto eh8
end
if(nil)then
else
goto eh8
end
if(nil)then
else
goto eh8
end
::eh8::
end
local DRAGs3="COODING"
if(nil)then
if(true)then
else
goto xm5
end
if(nil)then
else
goto xm5
end
if(nil)then
else
goto xm5
end
::xm5::
end
local DRAGs4="COODING"
if(nil)then
if(true)then
else
goto ej1
end
if(nil)then
else
goto ej1
end
if(nil)then
else
goto ej1
end
::ej1::
end
local DRAGs5="COODING"
if(nil)then
if(true)then
else
goto yq3
end
if(nil)then
else
goto yq3
end
if(nil)then
else
goto yq3
end
::yq3::
end
local DRAGs6="COODING"
if(nil)then
if(true)then
else
goto ax2
end
if(nil)then
else
goto ax2
end
if(nil)then
else
goto ax2
end
::ax2::
end
local DRAGs7="COODING"
if(nil)then
if(true)then
else
goto fe9
end
if(nil)then
else
goto fe9
end
if(nil)then
else
goto fe9
end
::fe9::
end
local DRAGs8="COODING"
if(nil)then
if(true)then
else
goto pu6
end
if(nil)then
else
goto pu6
end
if(nil)then
else
goto pu6
end
::pu6::
end
local DRAGs9="999"
if(nil)then
if(true)then
else
goto nd7
end
if(nil)then
else
goto nd7
end
if(nil)then
else
goto nd7
end
::nd7::
end
local DRAGs10="COODING"
if(nil)then
if(true)then
else
goto ge9
end
if(nil)then
else
goto ge9
end
if(nil)then
else
goto ge9
end
::ge9::
end
local DRAGs11="ۢSB"
if(nil)then
if(true)then
else
goto rl2
end
if(nil)then
else
goto rl2
end
if(nil)then
else
goto rl2
end
::rl2::
end
local DRAGs12="sB"
if(nil)then
if(true)then
else
goto to8
end
if(nil)then
else
goto to8
end
if(nil)then
else
goto to8
end
::to8::
end
local DRAGs13="sB"
if(nil)then
if(true)then
else
goto hl4
end
if(nil)then
else
goto hl4
end
if(nil)then
else
goto hl4
end
::hl4::
end
local DRAGs14="sB"
if(nil)then
if(true)then
else
goto re6
end
if(nil)then
else
goto re6
end
if(nil)then
else
goto re6
end
::re6::
end
local DRAGs15="COODING"
if(nil)then
if(true)then
else
goto gi1
end
if(nil)then
else
goto gi1
end
if(nil)then
else
goto gi1
end
::gi1::
end
local DRAGs16="sB"
if(nil)then
if(true)then
else
goto be6
end
if(nil)then
else
goto be6
end
if(nil)then
else
goto be6
end
::be6::
end
local DRAGs17="sB"
if(nil)then
if(true)then
else
goto pp3
end
if(nil)then
else
goto pp3
end
if(nil)then
else
goto pp3
end
::pp3::
end
local DRAGs18="sB"
if(nil)then
if(true)then
else
goto lm7
end
if(nil)then
else
goto lm7
end
if(nil)then
else
goto lm7
end
::lm7::
end
local DRAGs19="COODING"
if(nil)then
if(true)then
else
goto of6
end
if(nil)then
else
goto of6
end
if(nil)then
else
goto of6
end
::of6::
end
local DRAGs20="sB"
if(nil)then
if(true)then
else
goto fv1
end
if(nil)then
else
goto fv1
end
if(nil)then
else
goto fv1
end
::fv1::
end
local DRAGs21="sB"
if(nil)then
if(true)then
else
goto gf2
end
if(nil)then
else
goto gf2
end
if(nil)then
else
goto gf2
end
::gf2::
end
local DRAGs22="sB"
if(nil)then
if(true)then
else
goto ld5
end
if(nil)then
else
goto ld5
end
if(nil)then
else
goto ld5
end
::ld5::
end
local DRAGs23="sB"
if(nil)then
if(true)then
else
goto tt4
end
if(nil)then
else
goto tt4
end
if(nil)then
else
goto tt4
end
::tt4::
end
local DRAGs24="sB"
if(nil)then
if(true)then
else
goto ao1
end
if(nil)then
else
goto ao1
end
if(nil)then
else
goto ao1
end
::ao1::
end
local DRAGs25="sB"
if(nil)then
if(true)then
else
goto xb9
end
if(nil)then
else
goto xb9
end
if(nil)then
else
goto xb9
end
::xb9::
end
local DRAGs26="sB"
if(nil)then
if(true)then
else
goto oy1
end
if(nil)then
else
goto oy1
end
if(nil)then
else
goto oy1
end
::oy1::
end
local DRAGs27="sB"
if(nil)then
if(true)then
else
goto rt1
end
if(nil)then
else
goto rt1
end
if(nil)then
else
goto rt1
end
::rt1::
end
local DRAGs28="COODING"
if(nil)then
if(true)then
else
goto yj6
end
if(nil)then
else
goto yj6
end
if(nil)then
else
goto yj6
end
::yj6::
end
local DRAGs29="COODING"
if(nil)then
if(true)then
else
goto nd2
end
if(nil)then
else
goto nd2
end
if(nil)then
else
goto nd2
end
::nd2::
end

while countlog do end
countlog=0
if(nil)then
if(true)then
else
goto fa0
end
if(nil)then
else
goto fa0
end
if(nil)then
else
goto fa0
end
::fa0::
end
if countlog~=0 then
else
  goto passlog
end
while(true)do
  os.exit()
end
::passlog::
function DRAGx6(date,type)
if(nil)then
if(true)then
else
goto we3
end
if(nil)then
else
goto we3
end
if(nil)then
else
goto we3
end
::we3::
end
if countlog==1 and getresult~=0 then
  if type==4 then type=countlog*4 end
  if editdate and #editdate~=0 and dateres then
    local date=tonumber(date)
if(nil)then
if(true)then
else
goto so9
end
if(nil)then
else
goto so9
end
if(nil)then
else
goto so9
end
::so9::
end
    local yun,Sea={},{}
if(nil)then
if(true)then
else
goto ko7
end
if(nil)then
else
goto ko7
end
if(nil)then
else
goto ko7
end
::ko7::
end
    local total=0
    local arrlen=#editdate
if(nil)then
if(true)then
else
goto ts5
end
if(nil)then
else
goto ts5
end
if(nil)then
else
goto ts5
end
::ts5::
end
    for i=1,arrlen do
      yun[i]={address=editdate[i].address,flags=type}
    end
    yun=DRAGG_getValues(yun)
if(nil)then
if(true)then
else
goto mm5
end
if(nil)then
else
goto mm5
end
if(nil)then
else
goto mm5
end
::mm5::
end
    for i=1,arrlen do
      if dateres.dt==yun[i].value then
        total=total+1
if(nil)then
if(true)then
else
goto iu6
end
if(nil)then
else
goto iu6
end
if(nil)then
else
goto iu6
end
::iu6::
end
        Sea[total]={address=editdate[i].address,flags=type,value=date}
if(nil)then
if(true)then
else
goto ap8
end
if(nil)then
else
goto ap8
end
if(nil)then
else
goto ap8
end
::ap8::
end
      end
    end
    if #Sea~=0 then
      DRAGG_setValues(Sea)
if(nil)then
if(true)then
else
goto qn4
end
if(nil)then
else
goto qn4
end
if(nil)then
else
goto qn4
end
::qn4::
end
    end
    DRAGx2()
if(nil)then
if(true)then
else
goto os6
end
if(nil)then
else
goto os6
end
if(nil)then
else
goto os6
end
::os6::
end
    lockfun=nil
if(nil)then
if(true)then
else
goto nb5
end
if(nil)then
else
goto nb5
end
if(nil)then
else
goto nb5
end
::nb5::
end
    editdate=nil
if(nil)then
if(true)then
else
goto fr4
end
if(nil)then
else
goto fr4
end
if(nil)then
else
goto fr4
end
::fr4::
end
    dateres=nil
if(nil)then
if(true)then
else
goto vt5
end
if(nil)then
else
goto vt5
end
if(nil)then
else
goto vt5
end
::vt5::
end
   else
    local ss=DRAGx5(DRAGG_getResultCount())
if(nil)then
if(true)then
else
goto ws4
end
if(nil)then
else
goto ws4
end
if(nil)then
else
goto ws4
end
::ws4::
end
    if ss~=0 then
      local Sea={}
      for i=1,#ss do
        Sea[i]={address=ss[i].address,flags=type,value=date}
if(nil)then
if(true)then
else
goto vk0
end
if(nil)then
else
goto vk0
end
if(nil)then
else
goto vk0
end
::vk0::
end
      end
      DRAGG_setValues(Sea)
if(nil)then
if(true)then
else
goto gi0
end
if(nil)then
else
goto gi0
end
if(nil)then
else
goto gi0
end
::gi0::
end
    end
    DRAGx2()
if(nil)then
if(true)then
else
goto gq0
end
if(nil)then
else
goto gq0
end
if(nil)then
else
goto gq0
end
::gq0::
end
  end
end
getresult=nil
end
function DRAGsea(date,type,G_1,G_2,G_3,G_4)
if(nil)then
if(true)then
else
goto yy1
end
if(nil)then
else
goto yy1
end
if(nil)then
else
goto yy1
end
::yy1::
end
  if countlog==1 and getresult~=0 then
    if (not editdate) or (#editdate>8000) or (not tonumber(date)) or (lockfun) then
      DRAGx3(date,type)
if(nil)then
if(true)then
else
goto xh5
end
if(nil)then
else
goto xh5
end
if(nil)then
else
goto xh5
end
::xh5::
end
      getresult=DRAGG_getResultCount()
      if getresult<7999 then
        editdate=DRAGx5(DRAGG_getResultCount())
if(nil)then
if(true)then
else
goto pi7
end
if(nil)then
else
goto pi7
end
if(nil)then
else
goto pi7
end
::pi7::
end
      end
     else
      if not dateres and not lockfun then
        dateres={dt=tonumber(date),flag=type}
if(nil)then
if(true)then
else
goto cp1
end
if(nil)then
else
goto cp1
end
if(nil)then
else
goto cp1
end
::cp1::
end
        lockfun=true
if(nil)then
if(true)then
else
goto yq2
end
if(nil)then
else
goto yq2
end
if(nil)then
else
goto yq2
end
::yq2::
end
      end
    end
  end
end
function DRAGxsea(date,type,G_1,G_2,G_3,G_4)
if(nil)then
if(true)then
else
goto ov1
end
if(nil)then
else
goto ov1
end
if(nil)then
else
goto ov1
end
::ov1::
end
  while countlog==0 or not countlog do
    DRAGx2()
if(nil)then
if(true)then
else
goto fs4
end
if(nil)then
else
goto fs4
end
if(nil)then
else
goto fs4
end
::fs4::
end
    DRAGx3(1,4)
if(nil)then
if(true)then
else
goto hs4
end
if(nil)then
else
goto hs4
end
if(nil)then
else
goto hs4
end
::hs4::
end
    if DRAGG_getResultCount()<10*10000 then
      DRAGx2()
if(nil)then
if(true)then
else
goto cg9
end
if(nil)then
else
goto cg9
end
if(nil)then
else
goto cg9
end
::cg9::
end
      DRAGx3(0,4)
if(nil)then
if(true)then
else
goto rw5
end
if(nil)then
else
goto rw5
end
if(nil)then
else
goto rw5
end
::rw5::
end
    end
    local t1=DRAGx5(100000)
if(nil)then
if(true)then
else
goto re0
end
if(nil)then
else
goto re0
end
if(nil)then
else
goto re0
end
::re0::
end
    while DRAGG_getResultCount()<80000 do
      DRAGG_alert(string.char(232,191,144,232,161,140,231,138,182,230,128,129,233,148,153,232,175,175))
if(nil)then
if(true)then
else
goto dc7
end
if(nil)then
else
goto dc7
end
if(nil)then
else
goto dc7
end
::dc7::
end
      os.exit()
if(nil)then
if(true)then
else
goto ap5
end
if(nil)then
else
goto ap5
end
if(nil)then
else
goto ap5
end
::ap5::
end
    end
    DRAGx2()
if(nil)then
if(true)then
else
goto eg1
end
if(nil)then
else
goto eg1
end
if(nil)then
else
goto eg1
end
::eg1::
end
    DRAGG_setVisible(true)
if(nil)then
if(true)then
else
goto gi4
end
if(nil)then
else
goto gi4
end
if(nil)then
else
goto gi4
end
::gi4::
end
    local time=os.time()
if(nil)then
if(true)then
else
goto qf8
end
if(nil)then
else
goto qf8
end
if(nil)then
else
goto qf8
end
::qf8::
end
    local sum=0
    for i=1,5 do
      DRAGG_loadResults(t1)
if(nil)then
if(true)then
else
goto dh2
end
if(nil)then
else
goto dh2
end
if(nil)then
else
goto dh2
end
::dh2::
end
      sum=sum+(os.time()-time)
      while (DRAGG_isVisible()==false) do
        DRAGG_alert(string.char(231,150,145,228,188,188,233,129,191,229,188,128,230,163,128,230,181,139,239,188,140,232,175,183,228,184,141,232,166,129,232,191,153,228,185,136,229,129,154,239,188,129))
if(nil)then
if(true)then
else
goto wm2
end
if(nil)then
else
goto wm2
end
if(nil)then
else
goto wm2
end
::wm2::
end
        os.exit()
if(nil)then
if(true)then
else
goto qs2
end
if(nil)then
else
goto qs2
end
if(nil)then
else
goto qs2
end
::qs2::
end
      end
    end
    DRAGG_setVisible(false)
if(nil)then
if(true)then
else
goto gc2
end
if(nil)then
else
goto gc2
end
if(nil)then
else
goto gc2
end
::gc2::
end
    DRAGx2()
if(nil)then
if(true)then
else
goto xr5
end
if(nil)then
else
goto xr5
end
if(nil)then
else
goto xr5
end
::xr5::
end
    while (os.time()-time>9 or os.time()-time<=0 or sum<=1) do
      DRAGG_alert(string.char(232,191,144,232,161,140,233,148,153,232,175,175))
if(nil)then
if(true)then
else
goto al2
end
if(nil)then
else
goto al2
end
if(nil)then
else
goto al2
end
::al2::
end
      os.exit()
if(nil)then
if(true)then
else
goto qu0
end
if(nil)then
else
goto qu0
end
if(nil)then
else
goto qu0
end
::qu0::
end
    end
    countlog=countlog+1
  end
  DRAGsea(date,type,G_1,G_2,G_3,G_4)
  while DRAGG_isVisible()==true do
    os.exit()
if(nil)then
if(true)then
else
goto ai4
end
if(nil)then
else
goto ai4
end
if(nil)then
else
goto ai4
end
::ai4::
end
  end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]=function () end
end
_░▒▓█ ​
🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░["COODING"]()
function anti_lasm()
HE = math.random(500,999)
for i=1,HE do
x= math.random(⚡ ⚡ ⚡ ⚡ ⚡
   /\
  //\\
 ///\\\
////\\\\
/////\\\\\
kbvu vjhwz qwe rty uio pas dfg hjk lmn zxc vbnm
 asd qwe ert yui op[ asd fgh jkl zxc vbn mqw
  ert yui opa sdf ghj klz xcv bnm qwe rt yui op
   as df gh jk lm nb vc xz as df gh jk lm nb vc
    xz as df gh jk lm nb vc xz as df gh jk lm nb
     vc xz as df gh jk lm nb vc xz as df gh jk lm
      nb vc xz as df gh jk lm nb vc xz as df gh jk
       lm nb vc xz as df gh jk lm nb vc xz as df gh
        jk lm nb vc xz as df gh jk lm nb vc xz as df
         gh jk lm nb vc xz as df gh jk lm nb vc xz as
          df gh jk lm nb vc xz as df gh jk lm nb vc xz
           as df gh jk lm nb vc xz as df gh jk lm nb vc
            xz as df gh jk lm nb vc xz as df gh jk lm nb
             vc xz as df gh jk lm nb vc xz as df gh jk lm
              nb vc xz as df gh jk lm nb vc xz as df gh jk
               lm nb vc xz as df gh jk lm nb vc xz as df gh
                jk lm nb vc xz as df gh jk lm nb vc xz as df
                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                    xz as df gh jk lm nb vc xz as df gh jk lm nb
                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                          dfk lm nb vc xz as df gh jk lm nb vc xz
                           as df gh jk lm nb vc xz as df gh jk lm nb vc
                            xz as df gh jk lm nb vc xz as df gh jk lm nb
                             vc xz as df gh jk lm nb vc xz as df gh jk lm
                              nb vc xz as df gh jk lm nb vc xz as df gh jk
                               lm nb vc xz as df gh jk lm nb vc xz as df gh
                                jk lm nb vc xz as df gh jk lm nb vc xz as df
                                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                                    xk lm nb
                                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                          df gh jk lm nb vc xz as df gh jk lm 
)
for i=1,899 do
y= math.random(⚡ ⚡ ⚡ ⚡ ⚡
   /\
  //\\
 ///\\\
////\\\\
/////\\\\\
kbvu vjhwz qwe rty uio pas dfg hjk lmn zxc vbnm
 asd qwe ert yui op[ asd fgh jkl zxc vbn mqw
  ert yui opa sdf ghj klz xcv bnm qwe rt yui op
   as df gh jk lm nb vc xz as df gh jk lm nb vc
    xz as df gh jk lm nb vc xz as df gh jk lm nb
     vc xz as df gh jk lm nb vc xz as df gh jk lm
      nb vc xz as df gh jk lm nb vc xz as df gh jk
       lm nb vc xz as df gh jk lm nb vc xz as df gh
        jk lm nb vc xz as df gh jk lm nb vc xz as df
         gh jk lm nb vc xz as df gh jk lm nb vc xz as
          df gh jk lm nb vc xz as df gh jk lm nb vc xz
           as df gh jk lm nb vc xz as df gh jk lm nb vc
            xz as df gh jk lm nb vc xz as df gh jk lm nb
             vc xz as df gh jk lm nb vc xz as df gh jk lm
              nb vc xz as df gh jk lm nb vc xz as df gh jk
               lm nb vc xz as df gh jk lm nb vc xz as df gh
                jk lm nb vc xz as df gh jk lm nb vc xz as df
                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                    xz as df gh jk lm nb vc xz as df gh jk lm nb
                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                          dfk lm nb vc xz as df gh jk lm nb vc xz
                           as df gh jk lm nb vc xz as df gh jk lm nb vc
                            xz as df gh jk lm nb vc xz as df gh jk lm nb
                             vc xz as df gh jk lm nb vc xz as df gh jk lm
                              nb vc xz as df gh jk lm nb vc xz as df gh jk
                               lm nb vc xz as df gh jk lm nb vc xz as df gh
                                jk lm nb vc xz as df gh jk lm nb vc xz as df
                                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                                    xk lm nb
                                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                          df gh jk lm nb vc xz as df gh jk lm 
                                                                                                                                                                          
                                                                                                                                            xz as df gh jk lm nb vc xz as df gh 
⚡ ⚡ ⚡ ⚡ ⚡
   /\
  //\\
 ///\\\
////\\\\
/////\\\\\
kbvu vjhwz qwe rty uio pas dfg hjk lmn zxc vbnm
 asd qwe ert yui op[ asd fgh jkl zxc vbn mqw
  ert yui opa sdf ghj klz xcv bnm qwe rt yui op
   as df gh jk lm nb vc xz as df gh jk lm nb vc
    xz as df gh jk lm nb vc xz as df gh jk lm nb
     vc xz as df gh jk lm nb vc xz as df gh jk lm
      nb vc xz as df gh jk lm nb vc xz as df gh jk
       lm nb vc xz as df gh jk lm nb vc xz as df gh
        jk lm nb vc xz as df gh jk lm nb vc xz as df
         gh jk lm nb vc xz as df gh jk lm nb vc xz as
          df gh jk lm nb vc xz as df gh jk lm nb vc xz
           as df gh jk lm nb vc xz as df gh jk lm nb vc
            xz as df gh jk lm nb vc xz as df gh jk lm nb
             vc xz as df gh jk lm nb vc xz as df gh jk lm
              nb vc xz as df gh jk lm nb vc xz as df gh jk
               lm nb vc xz as df gh jk lm nb vc xz as df gh
                jk lm nb vc xz as df gh jk lm nb vc xz as df
                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                    xz as df gh jk lm nb vc xz as df gh jk lm nb
                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                          dfk lm nb vc xz as df gh jk lm nb vc xz
                           as df gh jk lm nb vc xz as df gh jk lm nb vc
                            xz as df gh jk lm nb vc xz as df gh jk lm nb
                             vc xz as df gh jk lm nb vc xz as df gh jk lm
                              nb vc xz as df gh jk lm nb vc xz as df gh jk
                               lm nb vc xz as df gh jk lm nb vc xz as df gh
                                jk lm nb vc xz as df gh jk lm nb vc xz as df
                                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                                    xk lm nb
                                     vc xz as df gh jk lm nb vc xz as df gh jk lm

⚡ ⚡ ⚡ ⚡ ⚡
   /\
  //\\
 ///\\\
////\\\\
/////\\\\\
kbvu vjhwz qwe rty uio pas dfg hjk lmn zxc vbnm
 asd qwe ert yui op[ asd fgh jkl zxc vbn mqw
  ert yui opa sdf ghj klz xcv bnm qwe rt yui op
   as df gh jk lm nb vc xz as df gh jk lm nb vc
    xz as df gh jk lm nb vc xz as df gh jk lm nb
     vc xz as df gh jk lm nb vc xz as df gh jk lm
      nb vc xz as df gh jk lm nb vc xz as df gh jk
       lm nb vc xz as df gh jk lm nb vc xz as df gh
        jk lm nb vc xz as df gh jk lm nb vc xz as df
         gh jk lm nb vc xz as df gh jk lm nb vc xz as
          df gh jk lm nb vc xz as df gh jk lm nb vc xz
           as df gh jk lm nb vc xz as df gh jk lm nb vc
            xz as df gh jk lm nb vc xz as df gh jk lm nb
             vc xz as df gh jk lm nb vc xz as df gh jk lm
              nb vc xz as df gh jk lm nb vc xz as df gh jk
               lm nb vc xz as df gh jk lm nb vc xz as df gh
                jk lm nb vc xz as df gh jk lm nb vc xz as df
                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                    xz as df gh jk lm nb vc xz as df gh jk lm nb
                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                       lm nb vc xz as df gh jk lm nb vc xz as df gh
                        jk lm nb vc xz as df gh jk lm nb vc xz as df
                         gh jk lm nb vc xz as df gh jk lm nb vc xz as
                          dfk lm nb vc xz as df gh jk lm nb vc xz
                           as df gh jk lm nb vc xz as df gh jk lm nb vc
                            xz as df gh jk lm nb vc xz as df gh jk lm nb
                             vc xz as df gh jk lm nb vc xz as df gh jk lm
                              nb vc xz as df gh jk lm nb vc xz as df gh jk
                               lm nb vc xz as df gh jk lm nb vc xz as df gh
                                jk lm nb vc xz as df gh jk lm nb vc xz as df
                                 gh jk lm nb vc xz as df gh jk lm nb vc xz as
                                  df gh jk lm nb vc xz as df gh jk lm nb vc xz
                                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                                    xk lm nb
                                     vc xz as df gh jk lm nb vc xz as df gh jk lm
                                      nb vc xz as df gh jk lm nb vc xz as df gh jk
                                       lm nb vc xz as df gh jk lm nb vc xz as  nb vc xz
                                                                                                                                                                                                   as df gh jk lm nb vc xz as df gh jk lm nb vc
                                                                                                                                            xz as df gh jk lm nb vc xz                                                                                                                                         jk lm nb vc xz as df gh jk lm nb vcx=x..y
end 
z='"'..x..'"'
funnum=math.random(10000,100000)
fundump="function "..fundnum.."()".."\n"..anti.."\n".."end"
loadme=string.dump(fundump)
load(loadme)
end
end
end Fu-[
local a=0 function NZF(code)res=''for i in ipairs(code)do res=res..string.char(code[i])end return res end 
gg.toast(NZF({230,173,163,229,156,168,233,170,140,232,175,129}))
os.remove(gg.getFile()..NZF({46,100,117,109,112,46,116,120,116}))
os.remove(gg.getFile()..NZF({46,108,117,97,99,46,100,117,109,112,46,116,120,116}))
w=1
while true do
w=w+1
os.remove(gg.getFile()..NZF({46,108,111,97,100,95})..w..NZF({46,108,117,97}))
if w==20000 then break end
}
]])
]=]
ManifestDeployment.func, ManifestDeployment.error = load(ManifestDeployment.data)

if not ManifestDeployment.func then
    gg.alert('⚠️ 𝐄𝐑𝐑𝐎𝐑 𝐅𝐈𝐍𝐃𝐈𝐍𝐆 : \n\n' .. ManifestDeployment.error)
    return false, ManifestDeployment.error
end

local data = string.dump(ManifestDeployment.func,true,true)

local get_str = function(l)
    local t={}
    for i=1,l do
        t[i]=math.random(160,190)
    end
    return string.char(table.unpack(t))
end

for k,v in pairs(ManifestDeployment.random.used)do
    data = string.gsub(data,'\x04\x07\x00\x00\x00('..k..')\x00',function(k2)
        local v2 = ManifestDeployment.random.used[k2]
        if v2==1 then
            v2=get_str(10)
            ManifestDeployment.random.used[k2]=v2
        end
        return '\x04\x0B\x00\x00\x00'..v2..'\x00'
    end)
end

ManifestDeployment.io(path, data)

gg.alert('🔐 ░▒▓█ 🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 ​█▓▒░🔓')

--[[ AUTO-INJECTION ]]--
--[[ AUTO-INJECT: PROTEKSI SEKALI PAKAI & BERSIH ]]
local function protectOnceOnly()
  -- FIXED: non-destructive one-time use (does NOT delete the script)
  local selfPath = gg.getFile()
  local flagPath = selfPath .. ".runonce"

  local flag = io.open(flagPath, "r")
  if flag then
    flag:close()
    gg.alert("❌ Script ini hanya bisa digunakan sekali pada device ini.")
    -- no os.remove of the script itself (was destructive)
    return  -- just stop, keep the file
  else
    local f = io.open(flagPath, "w")
    if f then f:write("USED") f:close() end
    gg.toast("✅ Proteksi sekali pakai aktif.")
  end
end

protectOnceOnly()

-- [FUNGSI ENKRIPSI ECCU DManifestDeploymentBUNGKAN]
local TableDaoLy = {
   "     ꧁✮✯🕸🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁: Kinzi🕸▓▒⫸                                   ([[⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉⑉]])                                            "
  }
  
  local Function = ""
  for i = 9000000, 9001000 do
    Function = Function .. "\n.func F" .. i .. "\n.source \"=?\"\n.linedefined 0\n.lastlinedefined 0\n.numparams 250\n.is_vararg 250\n.maxstacksize 250\n.upval v0 nil\n.upval u0 nil" .. ("\nRETURN v250..v250;\x052\x04C"):rep(1, 9) .. "\n.end"
  end
  Data = Data:gsub("\n%.line 0\n", "\n.line 0\nCLOSURE v0 F9999999\nLOADK v1 \"\\n\\n   𝒦𝒾𝓃𝓏𝒾 CHANNEL YOUTUBE\\n   PROGRAM KING OF KINGDOM\\n\\n                             © 15052025\\n\\n\\n--[[ " .. TableDaoLy[math.random(1, #TableDaoLy)] .. "\\n\\n\"\nCALL v0..v1\nRETURN\nRETURN v250..v250;\x052\x04C" .. Function .. "\n.func F9999999\n.source \"=?\"\n.linedefined 0\n.lastlinedefined 0\n.numparams 250\n.is_vararg 250\n.maxstacksize 250\n.upval u0 nil\n")
  Data = Data .. ".end\n"
-- [AKHIR FUNGSI ENKRIPSI]

-- ==== END of original preserved code ====

-- ==== BEGIN NEW: FINAL EXTRA HARDENING (non-destructive, polymorphic) ====

-- Utility: safer tonumber wrapper
local function ton(n, d) if type(n)~='number' then return d or 0 end return n end

-- small base64 impl (robust)
local _B = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local _B_MAP = {}
for i=1,#_B do _B_MAP[_B:sub(i,i)] = i-1 end
local function b64_encode(s)
  return ((s:gsub('.', function(x)
    local r='' local c=x:byte()
    for i=8,1,-1 do r = r .. ((c % 2^i - c % 2^(i-1) > 0) and '1' or '0') end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x<6 then return '' end
    local c=0 for i=1,6 do c = c*2 + (x:sub(i,i)=='1' and 1 or 0) end
    return _B:sub(c+1,c+1)
  end) .. ({'','==','='})[#s%3+1])
end

local function b64_decode(s)
  s = s:gsub('[^'.._B..'=]', '')
  return (s:gsub('.', function(x)
    if x=='=' then return '' end
    local v = _B_MAP[x]
    local out=''
    for i=5,0,-1 do out = out .. (((v >> i) & 1) == 1 and '1' or '0') end
    return out
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x~=8 then return '' end
    local c=0 for i=1,8 do c=c*2 + (x:sub(i,i)=='1' and 1 or 0) end
    return string.char(c)
  end))
end

-- simple RLE-like compression (fast)
local function compress_rle(s)
  local out = {}
  local i=1; local n=#s
  while i<=n do
    local ch = s:sub(i,i)
    local j = i+1
    while j<=n and s:sub(j,j)==ch and j-i<255 do j=j+1 end
    local run = j-i
    if run>4 then
      out[#out+1] = string.char(0,run,ch:byte())
      i = j
    else
      out[#out+1] = s:sub(i,j-1)
      i = j
    end
  end
  return table.concat(out)
end

local function decompress_rle(s)
  local out = {}
  local i=1; local n=#s
  while i<=n do
    local c = s:byte(i)
    if c==0 and i+2<=n then
      local run = s:byte(i+1); local b = s:byte(i+2)
      out[#out+1] = string.rep(string.char(b), run)
      i = i + 3
    else
      out[#out+1] = s:sub(i,i); i = i + 1
    end
  end
  return table.concat(out)
end

-- portable adler32 checksum
local function adler32(str)
  local a,b = 1,0
  for i=1,#str do a=(a+str:byte(i))%65521; b=(b+a)%65521 end
  return (b*65536 + a)
end

-- fallback SHA256 (attempt, but may use simple mix if bit ops missing)
local function has_bit_ops()
  return (type(bit32) == 'table') or (_ENV.bit ~= nil) or (_ENV.bit32 ~= nil)
end

-- compact SHA-256 reference (use if environment supports bit ops)
local function sha256_fallback(msg)
  -- if bit32 available use a compact implementation; otherwise fallback to adler32 hex
  if not has_bit_ops() then
    -- fallback: produce pseudo-hex by mixing adler and length
    local a = adler32(msg)
    return string.format("%08x%08x", a, (#msg*2654435761) % 0x100000000)
  end
  -- try to use bit32 if available
  local band = bit32 and bit32.band or function(a,b) return a&b end
  local bxor = function(a,b) return (a ~ b) end
  local rrotate = function(x,n) return ((x >> n) | ((x << (32-n)) & 0xFFFFFFFF)) & 0xFFFFFFFF end
  local K = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
  }
  local H = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
  local bytes = {}
  for i=1,#msg do bytes[i] = msg:byte(i) end
  local len = #bytes
  local bitlen = len*8
  table.insert(bytes, 0x80)
  while ((#bytes*8) % 512) ~= 448 do table.insert(bytes, 0) end
  for i=8,1,-1 do table.insert(bytes, (bitlen >> ((i-1)*8)) & 0xFF) end
  local function words_from_chunk(idx)
    local W={}
    for t=0,15 do
      local i = idx + t*4
      W[t] = ((bytes[i+1] << 24) | (bytes[i+2] << 16) | (bytes[i+3] << 8) | (bytes[i+4])) & 0xFFFFFFFF
    end
    for t=16,63 do
      local s0 = (rrotate(W[t-15],7) ~ rrotate(W[t-15],18) ~ ((W[t-15] >> 3))) & 0xFFFFFFFF
      local s1 = (rrotate(W[t-2],17) ~ rrotate(W[t-2],19) ~ ((W[t-2] >> 10))) & 0xFFFFFFFF
      W[t] = (W[t-16] + s0 + W[t-7] + s1) & 0xFFFFFFFF
    end
    return W
  end
  for chunk=1,#bytes,64 do
    local W = words_from_chunk(chunk-1)
    local a,b,c,d,e,f,g,h = H[1],H[2],H[3],H[4],H[5],H[6],H[7],H[8]
    for t=0,63 do
      local S1 = (rrotate(e,6) ~ rrotate(e,11) ~ rrotate(e,25)) & 0xFFFFFFFF
      local chv = ((e & f) ~ ((~e) & g))
      local temp1 = (h + S1 + chv + K[t+1] + W[t]) & 0xFFFFFFFF
      local S0 = (rrotate(a,2) ~ rrotate(a,13) ~ rrotate(a,22)) & 0xFFFFFFFF
      local majv = ((a & b) ~ (a & c) ~ (b & c))
      local temp2 = (S0 + majv) & 0xFFFFFFFF
      h=g; g=f; f=e; e=(d+temp1)&0xFFFFFFFF
      d=c; c=b; b=a; a=(temp1+temp2)&0xFFFFFFFF
    end
    H[1]=(H[1]+a)&0xFFFFFFFF; H[2]=(H[2]+b)&0xFFFFFFFF; H[3]=(H[3]+c)&0xFFFFFFFF; H[4]=(H[4]+d)&0xFFFFFFFF
    H[5]=(H[5]+e)&0xFFFFFFFF; H[6]=(H[6]+f)&0xFFFFFFFF; H[7]=(H[7]+g)&0xFFFFFFFF; H[8]=(H[8]+h)&0xFFFFFFFF
  end
  local function tohex(x) return string.format("%08x", x) end
  return table.concat({tohex(H[1]),tohex(H[2]),tohex(H[3]),tohex(H[4]),tohex(H[5]),tohex(H[6]),tohex(H[7]),tohex(H[8])})
end

local function sha256(s)
  local ok, res = pcall(sha256_fallback, s)
  if ok and type(res) == "string" then return res end
  return string.format("%08x", adler32(s))
end

-- derive key (PRNG based)
local function derive_key(seed, sighex, len)
  local key = {}
  local state = 0
  for i=1,#sighex do state = (state * 131 + sighex:byte(i)) & 0x7FFFFFFF end
  state = (state + (seed & 0x7FFFFFFF)) & 0x7FFFFFFF
  for i=1,len do
    state = (1103515245 * state + 12345) % 0x80000000
    key[i] = (state >> 16) & 0xFF
  end
  return key
end

-- XOR with key table -> string
local function xor_with_key(s, key)
  local out = {}
  local klen = #key
  for i=1,#s do
    out[i] = string.char( (s:byte(i) ~ key[((i-1) % klen) + 1]) & 0xFF )
  end
  return table.concat(out)
end

-- Caesar shift forward/back
local function caesar_shift(s, shift)
  shift = shift % 256
  local out = {}
  for i=1,#s do out[i] = string.char((s:byte(i) + shift) % 256) end
  return table.concat(out)
end
local function caesar_unshift(s, shift)
  shift = shift % 256
  local out = {}
  for i=1,#s do out[i] = string.char((s:byte(i) - shift) % 256) end
  return table.concat(out)
end

-- create polymorphic random names for loader obfuscation
local function rand_name(n)
  n = n or 8
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local out = {}
  for i=1,n do out[i] = chars:sub(math.random(1,#chars), math.random(1,#chars)) end
  return table.concat(out)
end

-- Pause small noise to vary runtime (makes dumps non-deterministic)
local function jitter()
  for i=1, math.random(1,3) do
    math.random(); math.random()
  end
end

-- Ensure we have 'data' from original pipeline (should be string.dump(ManifestDeployment.func))
if not data or type(data) ~= 'string' then
  gg.alert("⚠️ Error: original obfuscated bytecode not available. Aborting.")
  return
end

-- create polymorphic metadata
local build_id = tostring(os.time()) .. "-" .. tostring(math.random(1000,9999))
local seed = (os.time() ~ (#data)) & 0x7FFFFFFF
math.randomseed(seed + tonumber(os.getenv and os.getenv("UID") or 0) + (os.clock() * 1000000))

-- compute signature (sha256 or fallback)
local signature = sha256(data)

-- derive main key
local keylen = 256
local main_key = derive_key(seed, signature, keylen)

-- multi-round obfuscation pipeline (non-destructive)
jitter()
local stage1 = xor_with_key(data, main_key)                 -- XOR
local stage2 = caesar_shift(stage1, seed % 256)             -- Caesar
-- reverse-key confusion
local revk = {}
for i=1,#main_key do revk[i] = main_key[#main_key - ((i-1) % #main_key)] end
local stage3 = xor_with_key(stage2, revk)
local compressed = compress_rle(stage3)
local encoded = b64_encode(compressed)

-- header: minimal JSON-like
local header_plain = string.format('{"build":"%s","seed":%d,"sig":"%s","klen":%d}', build_id, seed, signature:sub(1,16), keylen)
local header_key = derive_key(seed ~ 0xABCDEF, signature:sub(1,16), 64)
local header_enc = b64_encode(xor_with_key(header_plain, header_key))

-- generate randomized loader variable names
local VAR_PAY = rand_name(10)
local VAR_HDR = rand_name(9)
local VAR_B64 = rand_name(8)
local VAR_DEC = rand_name(7)
local VAR_KEY = rand_name(7)
local VAR_RK = rand_name(6)
local VAR_FN = rand_name(6)

-- build loader code string (nested loader) with obfuscation: inline minimal helpers
local loader_lines = {}

table.insert(loader_lines, "░▒▓█ ​🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁 𝒦𝒾𝓃𝓏𝒾 🇵🇭 █▓▒░")
table.insert(loader_lines, string.format("local %s = [[%s]]", VAR_PAY, encoded))
table.insert(loader_lines, string.format("local %s = [[%s]]", VAR_HDR, header_enc))

-- inline base64 map (compact)
table.insert(loader_lines, "local _B = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'")
table.insert(loader_lines, "local _MAP = {} for i=1,#_B do _MAP[_B:sub(i,i)] = i-1 end")
table.insert(loader_lines, "local function b64d(s) s = s:gsub('[^'.._B..'=]',''); return (s:gsub('.', function(x) if x=='=' then return '' end; local v=_MAP[x]; local r=''; for i=5,0,-1 do r=r..(((v>>i)&1)==1 and '1' or '0') end; return r end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x) if #x~=8 then return '' end; local c=0; for i=1,8 do c=c*2 + (x:sub(i,i)=='1' and 1 or 0) end; return string.char(c) end)) end")

-- inline decompress and simple helpers
table.insert(loader_lines, "local function rle_decomp(s) local out={}; local i=1; local n=#s; while i<=n do local c=s:byte(i); if c==0 and i+2<=n then local run=s:byte(i+1); local b=s:byte(i+2); out[#out+1]=string.rep(string.char(b),run); i=i+3 else out[#out+1]=s:sub(i,i); i=i+1 end end return table.concat(out) end")
table.insert(loader_lines, "local function xor_local(d,k) local out={}; local kl=#k; for i=1,#d do out[i]=string.char(d:byte(i) ~ k[((i-1)%kl)+1]) end; return table.concat(out) end")
table.insert(loader_lines, "local function caesar_rev(d,sh) local t={}; sh=sh%256; for i=1,#d do t[i]=string.char((d:byte(i)-sh)%256) end; return table.concat(t) end")

-- header decode
table.insert(loader_lines, string.format("local _hdr_raw = b64d(%s)", VAR_HDR))
table.insert(loader_lines, "local function adler32_local(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return (b*65536 + a) end")
table.insert(loader_lines, "local function derive_local(seed, sigpart, len) local key={}; local state=0; for i=1,#sigpart do state=(state*131 + sigpart:byte(i)) & 0x7FFFFFFF end; state=(state + seed) & 0x7FFFFFFF; for i=1,len do state=(1103515245*state + 12345) % 0x80000000; key[i] = (state >> 16) & 0xFF end; return key end")
table.insert(loader_lines, "local hdr_k = derive_local( (tonumber((_hdr_raw:match('seed\":?(%d+)') or '0')) or 0) ~ 0xABCDEF, (_hdr_raw:match('\"sig\"%s*:%s*\"(%x+)\"') or ''), 64)")
table.insert(loader_lines, "local hdr_plain = xor_local(_hdr_raw, hdr_k)")
table.insert(loader_lines, "local s_seed = tonumber(hdr_plain:match('seed\":?(%d+)') or '0')")
table.insert(loader_lines, "local s_ck = tonumber(hdr_plain:match('ck\":?(%d+)') or hdr_plain:match('ck=(%d+)') or '0') or 0")
table.insert(loader_lines, "local s_klen = tonumber(hdr_plain:match('klen\":?(%d+)') or '128')")

-- payload decode pipeline (reverse of encode)
table.insert(loader_lines, string.format("local _enc = %s", VAR_PAY))
table.insert(loader_lines, "local _cmp = b64d(_enc)")
table.insert(loader_lines, "local _stage3 = rle_decomp(_cmp)")
table.insert(loader_lines, "local _key = derive_local(s_seed, (hdr_plain:match('\"sig\"%s*:%s*\"(%x+)\"') or ''), s_klen)")
table.insert(loader_lines, "local _revk = {}; for i=1,#_key do _revk[i] = _key[#_key - ((i-1) % #_key)] end")
table.insert(loader_lines, "local _t = {}; for i=1,#_stage3 do _t[i]=string.char(_stage3:byte(i) ~ _revk[((i-1)%#_revk)+1]) end; local _after = table.concat(_t)")
table.insert(loader_lines, "local _s2 = caesar_rev(_after, s_seed % 256)")
table.insert(loader_lines, "local _finalt = {}; for i=1,#_s2 do _finalt[i] = string.char(_s2:byte(i) ~ _key[((i-1)%#_key)+1]) end; local payload_plain = table.concat(_finalt)")

-- integrity check (best-effort)
table.insert(loader_lines, "local function adler32_str(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return (b*65536 + a) end")
table.insert(loader_lines, "local got = adler32_str(payload_plain)")
table.insert(loader_lines, "if tonumber(s_ck) ~= 0 and got ~= tonumber(s_ck) then pcall(function() gg.toast('⚠️ Integrity failed') end); return end")

-- attempt to load as chunk or fallback to loadstring
table.insert(loader_lines, "local ok,fn = pcall(load, payload_plain, '@protected')")
table.insert(loader_lines, "if not ok or type(fn)~='function' then")
table.insert(loader_lines, "  local ok2, f2 = pcall(loadstring or load, payload_plain)")
table.insert(loader_lines, "  if not ok2 or type(f2)~='function' then return end")
table.insert(loader_lines, "  pcall(f2)")
table.insert(loader_lines, "else")
table.insert(loader_lines, "  pcall(fn)")
table.insert(loader_lines, "end")

-- final loader text
local final_loader = table.concat(loader_lines, "\n")

-- Add /PROGRAM𝒦𝒾𝓃𝓏𝒾𝒦𝒾𝓃𝓏𝒾 runner appended to final loader for deception
local fake_block = [[
-- PROGRAM𝒦𝒾𝓃𝓏𝒾𝒦𝒾𝓃𝓏𝒾/𝒦𝒾𝓃𝓏𝒾PROGRAMENCRYPT: runs PROGRESS
local function 𝒦𝒾𝓃𝓏𝒾()
  pcall(function() gg.alert("DECRYPTION ERROR — CONTACT https://t.me/+MS-rvBFZH3QxZDE9") end)
  for i=1,3 do gg.toast("𝒦𝒾𝓃𝓏𝒾PROGRAMENCRYPT: access denied") end
end
𝒦𝒾𝓃𝓏𝒾()
]]

final_loader = final_loader .. "\n" .. fake_block

-- write final protected file to chosen path
local wf_ok, wf_err = pcall(function()
  local f = io.open(path, "wb")
  if not f then error("Cannot open path for write: "..tostring(path)) end
  -- banner (small) + loader
  f:write("This is a Script :JOHNZKIEPLYS CHANNEL YOUTUBE ░▒▓█ source 𝒦𝒾𝓃𝓏𝒾 COODING █▓▒░Encrypt (DECCODE DECRYPT by CC KING OF KINGDOM Cr: @🇵🇭 𝙳𝙴𝚅𝙴𝙻𝙾𝙿𝙴𝚁: Kinzi SCRIPTER ━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  f:write("t.me/finral48388: "..tostring(build_id).."\n")
  f:write(final_loader)
  f:close()
end)

if not wf_ok then
  gg.alert("❌ Gagal menulis output proteksi: "..tostring(wf_err))
  return
end

gg.alert("✅ Proteksi selesai. File terenkripsi: \n" .. tostring(path))