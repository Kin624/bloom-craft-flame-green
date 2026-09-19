-- ============================================================
--   KINZI AUTOMATIC CONVERTOR TOOL v2.0
--   Fixed & Enhanced by Claude | Original by Kinzi
-- ============================================================
-- FIXES:
--   [1] Duplicate 'local ranges' / 'local base' shadowing globals
--   [2] 'local choice' defined before Il2cpp() but used after it
--   [3] Menu choice == 4 block runs BEFORE Il2cpp() is called
--   [4] choice == 5 exit check placed after Il2cpp init block
--   [5] findRealHook defined twice (global + local in choice==1)
--   [6] findClassSafe: extra return causes only first loop item to return
--   [7] tonumber(addr) already handles 0x prefix — double parse bug
--   [8] Option 3 offset filter upper limit 0x8000000 too small for 64-bit
--   [9] save file never flushed in choice==2 / choice==3 (data loss on crash)
--   [10] No nil-guard on Il2cpp() call failure
-- NEW FEATURES:
--   [A] Option 5 → Auto Update Script Template generator
--   [B] Option 6 → Batch Export to Lua patch template
--   [C] Progress toasts for batch modes
--   [D] Session log with version header in every output file
--   [E] findRealHook now respects user-supplied scan range globally
--   [F] Duplicate-offset dedup in batch modes
-- ============================================================

local gg = gg

-- ============================================================
-- GLOBAL CONSTANTS
-- ============================================================
local TOOL_VERSION   = "2.0"
local LIB_NAME       = "libil2cpp.so"
local ti             = gg.getTargetInfo()
local arch           = ti.x64
local p_size         = arch and 8 or 4
local p_type         = arch and 32 or 4   -- gg.TYPE_QWORD or gg.TYPE_DWORD

-- ============================================================
-- [FIX #1] Get lib base ONCE, stored in one place
-- ============================================================
local function getLibBase()
    local r = gg.getRangesList(LIB_NAME)
    if not r or not r[2] then
        gg.alert(LIB_NAME .. " not found!\nMake sure the game is running.")
        os.exit()
    end
    return r[2].start, r
end

local lib_base, lib_ranges = getLibBase()

-- ============================================================
-- MEMORY HELPERS
-- ============================================================
local function countResults()
    return gg.getResultsCount()
end

local function getvalue(address, flags)
    local t = gg.getValues({{address = address, flags = flags}})
    if not t or not t[1] then return 0 end
    return t[1].value
end

local function ptr(address)
    return getvalue(address, p_type)
end

local function CString(address, str)
    local bytes = gg.bytes(str)
    for i = 1, #bytes do
        if (getvalue(address + (i - 1), 1) & 0xFF) ~= bytes[i] then
            return false
        end
    end
    return getvalue(address + #bytes, 1) == 0
end

-- ============================================================
-- PROCESS CLASS + METHOD (for Option 4 re-offset)
-- ============================================================
local function processMethod(clazz, method)
    gg.setRanges(-2080835)
    gg.clearResults()
    gg.searchNumber(string.format("Q 00 '%s' 00", method))
    if countResults() == 0 then return "NOT FOUND" end

    gg.refineNumber(method:byte(), 1)
    gg.searchPointer(0, p_type)

    local pointer_results = gg.getResults(
        countResults(), nil, nil, nil, nil, nil,
        p_type, nil,
        gg.POINTER_EXECUTABLE |
        gg.POINTER_EXECUTABLE_WRITABLE |
        gg.POINTER_WRITABLE |
        gg.POINTER_READ_ONLY
    )
    gg.clearResults()

    if #pointer_results == 0 then return "POINTER NOT FOUND" end

    for _, v in ipairs(pointer_results) do
        if CString(ptr(ptr(v.address + p_size) + (p_size * 2)), clazz) then
            local base_address = ptr(v.address - (p_size * 2))
            local offset = base_address - lib_base
            return string.format("0x%X", offset)
        end
    end
    return "NO MATCH"
end

-- ============================================================
-- [FIX #6] findClassSafe — corrected early-return logic
-- ============================================================
local function findClassSafe(offset)
    local function tryOffset(off)
        local ok, r = pcall(function()
            return Il2cpp.FindMethods({off})
        end)
        if not ok or not r then return nil, nil, nil end
        for _, a in pairs(r) do
            for _, m in pairs(a) do
                -- [FIX #6] was: `return\nm.ClassName` which broke the call
                local cn = m.ClassName   or "Unknown"
                local mn = m.MethodName  or "Unknown"
                local rt = m.ReturnType  or "Unknown"
                return cn, mn, rt
            end
        end
        return nil, nil, nil
    end

    local c, m, t = tryOffset(offset)
    if c then return c, m, t end
    c, m, t = tryOffset(offset - 0x4)
    if c then return c, m, t end
    c, m, t = tryOffset(offset + 0x4)
    if c then return c, m, t end
    return "Unknown", "Unknown", "Unknown"
end

-- ============================================================
-- [FIX #5] findRealHook defined ONCE with range parameter
-- ============================================================
local function findRealHook(offset, base, range)
    range = range or 0x400
    local functionStart = offset
    -- scan backward
    for i = offset, offset - range, -4 do
        local v = gg.getValues({{address = base + i, flags = gg.TYPE_DWORD}})
        if not v or v[1].value == 0 then
            functionStart = i + 4
            break
        end
    end
    -- scan forward (for completeness but hookDistance only needs start)
    local hookDistance = offset - functionStart
    return functionStart, hookDistance
end

-- ============================================================
-- UTILITY: write session header to a file handle
-- ============================================================
local function writeSessionHeader(fh, mode)
    fh:write("============================================================\n")
    fh:write("  KINZI TOOLS v" .. TOOL_VERSION .. " — " .. mode .. "\n")
    fh:write("  Session: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    fh:write("  Arch: " .. (arch and "64-bit" or "32-bit") .. "\n")
    fh:write("  LIB BASE: 0x" .. string.format("%X", lib_base) .. "\n")
    fh:write("============================================================\n\n")
end

-- ============================================================
-- [FIX #2/3] SHOW MAIN MENU FIRST — then init Il2cpp
-- ============================================================
local mainChoice = gg.choice({
    " [1] Single Address (manual) → offset & Class/Method Info  ",
    " [2] Logged addresses (file) → offset & Class/Method Info  ",
    " [3] Direct offset (file)    → offset & Class/Method Info  ",
    " [4] Re-offset from result file (update version)           ",
    " [5] Auto-Update Script Template Generator (NEW)           ",
    " [6] Batch Export → Lua Patch Template (NEW)               ",
    " [7] Exit                                                   ",
}, nil, "╔═══════════════════╗\n   KINZI TOOLS v" .. TOOL_VERSION .. "\n╚═══════════════════╝")

-- [FIX #4] Handle exit BEFORE expensive Il2cpp() init
if mainChoice == 7 or not mainChoice then
    gg.alert("Exiting Kinzi Tools...")
    os.exit()
end

-- ============================================================
-- Option 4 is the re-offset mode — does NOT need Il2cpp()
-- ============================================================
if mainChoice == 4 then
    gg.alert(
        "Batch Re-Offset Processor\n\n" ..
        "PURPOSE:\n" ..
        "Recalculate fresh offsets using class/method data from a\n" ..
        "previous result file (generated by Option 3).\n\n" ..
        "INPUT FILE FORMAT:\n" ..
        "CLASS: <name>\n" ..
        "METHOD: <name>\n" ..
        "TYPE: <value>\n\n" ..
        "The game must be running & fully loaded.\n" ..
        "Output saved as 'reprocessed_offsets.kinzi'."
    )

    local fileInput = gg.prompt({"Select Option-3 result file"},
                                {gg.getFile()}, {"file"})
    if not fileInput then os.exit() end

    local path = fileInput[1]
    local inputFile = io.open(path, "r")
    if not inputFile then
        gg.alert("Failed to open file: " .. tostring(path))
        os.exit()
    end

    local folder   = path:match("(.*/)") or "./"
    local savePath = folder .. "reprocessed_offsets.kinzi"
    local save     = io.open(savePath, "w")
    if not save then
        gg.alert("Cannot create output file at:\n" .. savePath)
        os.exit()
    end

    writeSessionHeader(save, "Re-Offset Processor")

    local currentBlock = {}
    local class_name, method_name = nil, nil
    local blockCount = 0

    for line in inputFile:lines() do
        table.insert(currentBlock, line)
        local c = line:match("CLASS:%s*(.+)")
        if c then class_name = c:match("^%s*(.-)%s*$") end  -- trim whitespace
        local m = line:match("METHOD:%s*(.+)")
        if m then method_name = m:match("^%s*(.-)%s*$") end

        if line:match("TYPE:") and class_name and method_name then
            blockCount = blockCount + 1
            gg.toast("Re-offsetting #" .. blockCount .. ": " .. method_name)

            local newOffset = processMethod(class_name, method_name)

            for _, l in ipairs(currentBlock) do
                save:write(l .. "\n")
            end
            save:write("\n")
            save:write(
                class_name .. "::" .. method_name ..
                " → " .. newOffset ..
                "\n\n----------------------------------------\n\n"
            )
            save:flush()

            currentBlock = {}
            class_name   = nil
            method_name  = nil
        end
    end

    inputFile:close()
    save:close()
    gg.alert("Done! " .. blockCount .. " blocks re-offset.\nSaved to:\n" .. savePath)
    os.exit()
end

-- ============================================================
-- For options 1-3, 5, 6 we need Il2cpp initialised
-- ============================================================
gg.toast("Initialising Il2cpp engine...")
gg.setVisible(false)

-- [FIX #10] Wrap Il2cpp() call
local ok_il2cpp, err_il2cpp = pcall(function()
    -- MODULE BUNDLE (unchanged from original — keep full bundle below)
    __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
        local loadingPlaceholder = {[{}] = true}
        local register, modules, require, loaded = nil, {}, nil, {}
        register = function(name, body)
            if not modules[name] then modules[name] = body end
        end
        require = function(name)
            local loadedModule = loaded[name]
            if loadedModule then
                if loadedModule == loadingPlaceholder then return nil end
            else
                if not modules[name] then
                    if not superRequire then
                        local id = type(name)=='string' and '"'..name..'"' or tostring(name)
                        error('Tried to require '..id..', but no such module has been registered')
                    else
                        return superRequire(name)
                    end
                end
                loaded[name] = loadingPlaceholder
                loadedModule = modules[name](require, loaded, register, modules)
                loaded[name] = loadedModule
            end
            return loadedModule
        end
        return require, loaded, register, modules
    end)(require)

    __bundle_register("GGIl2cpp", function(require, _LOADED, __bundle_register, __bundle_modules)
        require("utils.il2cppconst")
        require("il2cpp")
        return Il2cpp
    end)
    __bundle_register("il2cpp", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Il2cppMemory = require("utils.il2cppmemory")
        local VersionEngine = require("utils.version")
        local AndroidInfo = require("utils.androidinfo")
        local Searcher = require("utils.universalsearcher")
        local PatchApi = require("utils.patchapi")
        local Il2cppBase = {
            il2cppStart = 0, il2cppEnd = 0,
            globalMetadataStart = 0, globalMetadataEnd = 0,
            globalMetadataHeader = 0,
            MainType    = AndroidInfo.platform and gg.TYPE_QWORD or gg.TYPE_DWORD,
            pointSize   = AndroidInfo.platform and 8 or 4,
            Il2CppTypeDefinitionApi = {},
            MetadataRegistrationApi = require("il2cppstruct.metadataRegistration"),
            TypeApi     = require("il2cppstruct.type"),
            MethodsApi  = require("il2cppstruct.method"),
            GlobalMetadataApi = require("il2cppstruct.globalmetadata"),
            FieldApi    = require("il2cppstruct.field"),
            ClassApi    = require("il2cppstruct.class"),
            ObjectApi   = require("il2cppstruct.object"),
            ClassInfoApi = require("il2cppstruct.api.classinfo"),
            FieldInfoApi = require("il2cppstruct.api.fieldinfo"),
            String      = require("il2cppstruct.il2cppstring"),
            MemoryManager = require("utils.malloc"),
            PatchesAddress = function(add, Bytescodes)
                local patchCode = {}
                for code in string.gmatch(Bytescodes, '.') do
                    patchCode[#patchCode+1] = {address=add+#patchCode, value=string.byte(code), flags=gg.TYPE_BYTE}
                end
                local patch = PatchApi:Create(patchCode)
                patch:Patch()
                return patch
            end,
            FindMethods = function(searchParams)
                Il2cppMemory:SaveResults()
                for i=1,#searchParams do searchParams[i]=Il2cpp.MethodsApi:Find(searchParams[i]) end
                Il2cppMemory:ClearSavedResults()
                return searchParams
            end,
            FindClass = function(searchParams)
                Il2cppMemory:SaveResults()
                for i=1,#searchParams do searchParams[i]=Il2cpp.ClassApi:Find(searchParams[i]) end
                Il2cppMemory:ClearSavedResults()
                return searchParams
            end,
            FindObject = function(searchParams)
                Il2cppMemory:SaveResults()
                for i=1,#searchParams do
                    searchParams[i]=Il2cpp.ObjectApi:Find(Il2cpp.ClassApi:Find({Class=searchParams[i]}))
                end
                Il2cppMemory:ClearSavedResults()
                return searchParams
            end,
            FindFields = function(searchParams)
                Il2cppMemory:SaveResults()
                for i=1,#searchParams do
                    local sp = searchParams[i]
                    local sr = Il2cppMemory:GetInformationOfField(sp)
                    if not sr then
                        sr = Il2cpp.FieldApi:Find(sp)
                        Il2cppMemory:SetInformationOfField(sp, sr)
                    end
                    searchParams[i] = sr
                end
                Il2cppMemory:ClearSavedResults()
                return searchParams
            end,
            Utf8ToString = function(Address, length)
                local chars, char = {}, {address=Address, flags=gg.TYPE_BYTE}
                if not length then
                    repeat
                        local _char = string.char(gg.getValues({char})[1].value & 0xFF)
                        chars[#chars+1] = _char
                        char.address = char.address + 0x1
                    until string.find(_char, "[%z%s]")
                    return table.concat(chars, "", 1, #chars-1)
                else
                    for i=1,length do
                        local _char = gg.getValues({char})[1].value
                        chars[i] = string.char(_char & 0xFF)
                        char.address = char.address + 0x1
                    end
                    return table.concat(chars)
                end
            end,
            ChangeBytesOrder = function(bytes)
                local newBytes, index, lenBytes = {}, 0, #bytes/2
                for byte in string.gmatch(bytes, "..") do
                    newBytes[lenBytes-index] = byte
                    index = index+1
                end
                return table.concat(newBytes)
            end,
            FixValue = function(val)
                return AndroidInfo.platform and val & 0x00FFFFFFFFFFFFFF or val & 0xFFFFFFFF
            end,
            GetValidAddress = function(Address)
                local lastByte = Address & 0xF
                local delta = 0
                local checkTable = {[12]=true,[4]=true,[8]=true,[0]=true}
                while not checkTable[lastByte-delta] do delta=delta+1 end
                return Address - delta
            end,
            SearchPointer = function(self, address)
                address = self.ChangeBytesOrder(type(address)=='number' and string.format('%X',address) or address)
                gg.searchNumber('h '..address)
                gg.refineNumber('h '..address:sub(1,6))
                gg.refineNumber('h '..address:sub(1,2))
                local FindsResult = gg.getResults(gg.getResultsCount())
                gg.clearResults()
                return FindsResult
            end,
        }
        Il2cpp = setmetatable({}, {
            __call = function(self, config)
                config = config or {}
                getmetatable(self).__index = Il2cppBase
                if config.libilcpp then
                    self.il2cppStart, self.il2cppEnd = config.libilcpp.start, config.libilcpp['end']
                else
                    self.il2cppStart, self.il2cppEnd = Searcher.FindIl2cpp()
                end
                if config.globalMetadata then
                    self.globalMetadataStart, self.globalMetadataEnd = config.globalMetadata.start, config.globalMetadata['end']
                else
                    self.globalMetadataStart, self.globalMetadataEnd = Searcher:FindGlobalMetaData()
                end
                self.globalMetadataHeader = config.globalMetadataHeader or self.globalMetadataStart
                self.MetadataRegistrationApi.metadataRegistration = config.metadataRegistration
                VersionEngine:ChooseVersion(config.il2cppVersion, self.globalMetadataHeader)
                Il2cppMemory:ClearMemorize()
            end,
            __index = function(self, key)
                assert(key=="PatchesAddress", "You didn't call 'Il2cpp'")
                return Il2cppBase[key]
            end
        })
        return Il2cpp
    end)
    __bundle_register("utils.malloc", function(require, _LOADED, __bundle_register, __bundle_modules)
        local MemoryManager = {
            availableMemory=0, lastAddress=0,
            NewAlloc = function(self)
                self.lastAddress = gg.allocatePage(gg.PROT_READ|gg.PROT_WRITE)
                self.availableMemory = 4096
            end,
        }
        return {
            MAlloc = function(size)
                if size > MemoryManager.availableMemory then MemoryManager:NewAlloc() end
                local address = MemoryManager.lastAddress
                MemoryManager.availableMemory = MemoryManager.availableMemory - size
                MemoryManager.lastAddress = MemoryManager.lastAddress + size
                return address
            end,
        }
    end)
    __bundle_register("il2cppstruct.il2cppstring", function(require, _LOADED, __bundle_register, __bundle_modules)
        local StringApi = {
            EditString = function(self, newStr)
                local _len = gg.getValues{{address=self.address+self.Fields._stringLength,flags=gg.TYPE_DWORD}}[1].value * 2
                local bytes = gg.bytes(newStr,"UTF-16LE")
                if _len == #bytes then
                    local ss = self.address+self.Fields._firstChar
                    for i,v in ipairs(bytes) do bytes[i]={address=ss+(i-1),flags=gg.TYPE_BYTE,value=v} end
                    gg.setValues(bytes)
                elseif _len > #bytes then
                    local ss = self.address+self.Fields._firstChar
                    local _bytes={}
                    for i=1,_len do _bytes[#_bytes+1]={address=ss+(i-1),flags=gg.TYPE_BYTE,value=bytes[i] or 0} end
                    gg.setValues(_bytes)
                else
                    self.address = Il2cpp.MemoryManager.MAlloc(self.Fields._firstChar+#bytes+8)
                    local length = #bytes%2==1 and #bytes+1 or #bytes
                    local _bytes={{address=self.address,flags=Il2cpp.MainType,value=self.ClassAddress},
                                  {address=self.address+self.Fields._stringLength,flags=gg.TYPE_DWORD,value=length/2}}
                    local ss=self.address+self.Fields._firstChar
                    for i=1,length do _bytes[#_bytes+1]={address=ss+(i-1),flags=gg.TYPE_BYTE,value=bytes[i] or 0} end
                    _bytes[#_bytes+1]={address=self.pointToStr,flags=Il2cpp.MainType,value=self.address}
                    gg.setValues(_bytes)
                end
            end,
            ReadString = function(self)
                local _len = gg.getValues{{address=self.address+self.Fields._stringLength,flags=gg.TYPE_DWORD}}[1].value
                local bytes={}
                if _len>0 and _len<200 then
                    local ss=self.address+self.Fields._firstChar
                    for i=0,_len do bytes[#bytes+1]={address=ss+(i<<1),flags=gg.TYPE_WORD} end
                    bytes=gg.getValues(bytes)
                    local code={[[return "]]}
                    for _,v in ipairs(bytes) do code[#code+1]=string.format([[\u{%x}]],v.value&0xFFFF) end
                    code[#code+1]='"'
                    local read=load(table.concat(code))
                    if read then return read() end
                end
                return ""
            end
        }
        local String = {
            From = function(address)
                local pointToStr = gg.getValues({{address=Il2cpp.FixValue(address),flags=Il2cpp.MainType}})[1]
                local str = setmetatable({address=Il2cpp.FixValue(pointToStr.value),Fields={},pointToStr=Il2cpp.FixValue(address)},{__index=StringApi})
                local pca = gg.getValues({{address=str.address,flags=Il2cpp.MainType}})[1].value
                local si = Il2cpp.FindClass({{Class=Il2cpp.FixValue(pca),FieldsDump=true}})[1]
                for _,v in ipairs(si) do
                    if v.ClassNameSpace=="System" then
                        str.ClassAddress=tonumber(v.ClassAddress,16)
                        for _,fi in ipairs(v.Fields) do str.Fields[fi.FieldName]=tonumber(fi.Offset,16) end
                        return str
                    end
                end
                return nil
            end,
        }
        return String
    end)
    __bundle_register("il2cppstruct.api.fieldinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Il2cppMemory = require("utils.il2cppmemory")
        return {
            GetConstValue = function(self)
                if self.IsConst then
                    local fi = getmetatable(self).fieldIndex
                    local dv = Il2cppMemory:GetDefaultValue(fi)
                    if not dv then
                        dv = Il2cpp.GlobalMetadataApi:GetDefaultFieldValue(fi)
                        Il2cppMemory:SetDefaultValue(fi, dv)
                    elseif dv=="nil" then return nil end
                    return dv
                end
                return nil
            end
        }
    end)
    __bundle_register("utils.il2cppmemory", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Il2cppMemory = {
            Methods={}, Classes={}, Fields={}, DefaultValues={}, Results={}, Types={},
            GetInformationOfType=function(s,i) return s.Types[i] end,
            SetInformationOfType=function(s,i,n) s.Types[i]=n end,
            SaveResults=function(self) if gg.getResultsCount()>0 then self.Results=gg.getResults(gg.getResultsCount()) end end,
            ClearSavedResults=function(self) self.Results={} end,
            GetDefaultValue=function(self,fi) return self.DefaultValues[fi] end,
            SetDefaultValue=function(self,fi,dv) self.DefaultValues[fi]=dv or "nil" end,
            GetInformationOfField=function(self,sp) return self.Fields[sp] end,
            SetInformationOfField=function(self,sp,sr) if not sr.Error then self.Fields[sp]=sr end end,
            GetInformaionOfMethod=function(self,sp) return self.Methods[sp] end,
            SetInformaionOfMethod=function(self,sp,sr) if not sr.Error then self.Methods[sp]=sr end end,
            GetInformationOfClass=function(self,sp) return self.Classes[sp] end,
            SetInformationOfClass=function(self,sp,sr) self.Classes[sp]=sr end,
            ClearMemorize=function(self) self.Methods={} self.Classes={} self.Fields={} self.DefaultValues={} self.Results={} self.Types={} end,
        }
        return Il2cppMemory
    end)
    __bundle_register("il2cppstruct.api.classinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
        local ClassInfoApi = {
            GetFieldWithName=function(self,name)
                local fi=self.Fields
                if fi then
                    for i=1,#fi do if fi[i].FieldName==name then return fi[i] end end
                else
                    local ca=tonumber(self.ClassAddress,16)
                    local ci=gg.getValues({{address=ca+Il2cpp.ClassApi.FieldsLink,flags=Il2cpp.MainType},{address=ca+Il2cpp.ClassApi.CountFields,flags=gg.TYPE_WORD}})
                    self.Fields=Il2cpp.ClassApi:GetClassFields(Il2cpp.FixValue(ci[1].value),ci[2].value,{ClassName=self.ClassName,IsEnum=self.IsEnum,TypeMetadataHandle=self.TypeMetadataHandle})
                    return self:GetFieldWithName(name)
                end
                return nil
            end,
            GetMethodsWithName=function(self,name)
                local mi,mir=self.Methods,{}
                if mi then
                    for i=1,#mi do if mi[i].MethodName==name then mir[#mir+1]=mi[i] end end
                    return mir
                else
                    local ca=tonumber(self.ClassAddress,16)
                    local ci=gg.getValues({{address=ca+Il2cpp.ClassApi.MethodsLink,flags=Il2cpp.MainType},{address=ca+Il2cpp.ClassApi.CountMethods,flags=gg.TYPE_WORD}})
                    self.Methods=Il2cpp.ClassApi:GetClassMethods(Il2cpp.FixValue(ci[1].value),ci[2].value,self.ClassName)
                    return self:GetMethodsWithName(name)
                end
            end,
            GetFieldWithOffset=function(self,fo)
                if not self.Fields then
                    local ca=tonumber(self.ClassAddress,16)
                    local ci=gg.getValues({{address=ca+Il2cpp.ClassApi.FieldsLink,flags=Il2cpp.MainType},{address=ca+Il2cpp.ClassApi.CountFields,flags=gg.TYPE_WORD}})
                    self.Fields=Il2cpp.ClassApi:GetClassFields(Il2cpp.FixValue(ci[1].value),ci[2].value,{ClassName=self.ClassName,IsEnum=self.IsEnum,TypeMetadataHandle=self.TypeMetadataHandle})
                end
                if #self.Fields>0 then
                    local klass=self
                    while klass~=nil do
                        if klass.Fields and klass.InstanceSize>=fo then
                            local lf
                            for idx,f in ipairs(klass.Fields) do
                                if not(f.IsStatic or f.IsConst) then
                                    local off=tonumber(f.Offset,16)
                                    if off>0 then
                                        if idx==1 and fo<off then break
                                        elseif off==fo or idx==#klass.Fields then return f
                                        elseif fo<off then return lf
                                        else lf=f end
                                    end
                                end
                            end
                        end
                        klass=klass.Parent~=nil and Il2cpp.FindClass({{Class=tonumber(klass.Parent.ClassAddress,16),FieldsDump=true}})[1][1] or nil
                    end
                end
                return nil
            end,
        }
        return ClassInfoApi
    end)
    __bundle_register("il2cppstruct.object", function(require, _LOADED, __bundle_register, __bundle_modules)
        local AndroidInfo=require("utils.androidinfo")
        local ObjectApi = {
            FilterObjects=function(self,Objects)
                local fo={}
                for k,v in ipairs(gg.getValuesRange(Objects)) do if v=='A' then fo[#fo+1]=Objects[k] end end
                Objects=fo gg.loadResults(Objects) gg.searchPointer(0)
                if gg.getResultsCount()<=0 and AndroidInfo.platform and AndroidInfo.sdk>=30 then
                    local fix={}
                    for _,v in ipairs(Objects) do
                        gg.searchNumber(tostring(v.address|0xB400000000000000),gg.TYPE_QWORD)
                        local r=gg.getResults(gg.getResultsCount())
                        table.move(r,1,#r,#fix+1,fix) gg.clearResults()
                    end
                    gg.loadResults(fix)
                end
                local ro,_fo=gg.getResults(gg.getResultsCount()),{}
                gg.clearResults()
                for k,v in ipairs(gg.getValuesRange(ro)) do
                    if v=='A' then _fo[#_fo+1]={address=Il2cpp.FixValue(ro[k].value),flags=ro[k].flags} end
                end
                gg.loadResults(_fo)
                local r=gg.getResults(gg.getResultsCount()) gg.clearResults() return r
            end,
            FindObjects=function(self,ca)
                gg.clearResults() gg.setRanges(0)
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_C_ALLOC)
                gg.loadResults({{address=tonumber(ca,16),flags=Il2cpp.MainType}}) gg.searchPointer(0)
                if gg.getResultsCount()<=0 and AndroidInfo.platform and AndroidInfo.sdk>=30 then
                    gg.searchNumber(tostring(tonumber(ca,16)|0xB400000000000000),Il2cpp.MainType)
                end
                local r=gg.getResults(gg.getResultsCount()) gg.clearResults()
                return self:FilterObjects(r)
            end,
            Find=function(self,ci)
                local o={}
                for j=1,#ci do local r=self:FindObjects(ci[j].ClassAddress) table.move(r,1,#r,#o+1,o) end
                return o
            end,
            FindHead=function(Address)
                local va=Il2cpp.GetValidAddress(Address)
                local mbh={}
                for i=1,1000 do mbh[i]={address=va-(4*(i-1)),flags=Il2cpp.MainType} end
                mbh=gg.getValues(mbh)
                for _,v in ipairs(mbh) do
                    local mbc=Il2cpp.FixValue(v.value)
                    if Il2cpp.ClassApi.IsClassInfo(mbc) then return v end
                end
                return {value=0,address=0}
            end,
        }
        return ObjectApi
    end)
    __bundle_register("utils.androidinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
        return {platform=gg.getTargetInfo().x64, sdk=gg.getTargetInfo().targetSdkVersion}
    end)
    __bundle_register("il2cppstruct.class", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Protect=require("utils.protect")
        local StringUtils=require("utils.stringutils")
        local Il2cppMemory=require("utils.il2cppmemory")
        local ClassApi = {
            GetClassName=function(self,ca)
                return Il2cpp.Utf8ToString(Il2cpp.FixValue(gg.getValues({{address=Il2cpp.FixValue(ca)+self.NameOffset,flags=Il2cpp.MainType}})[1].value))
            end,
            GetClassMethods=function(self,ml,count,cn)
                local mi,_mi={},{}
                for i=0,count-1 do _mi[#_mi+1]={address=ml+(i<<self.MethodsStep),flags=Il2cpp.MainType} end
                _mi=gg.getValues(_mi)
                for i=1,#_mi do
                    local minfo
                    minfo,_mi[i]=Il2cpp.MethodsApi:UnpackMethodInfo({MethodInfoAddress=Il2cpp.FixValue(_mi[i].value),ClassName=cn})
                    table.move(minfo,1,#minfo,#mi+1,mi)
                end
                mi=gg.getValues(mi) Il2cpp.MethodsApi:DecodeMethodsInfo(_mi,mi) return _mi
            end,
            GetClassFields=function(self,fl,count,cc)
                local fi,_fi={},{}
                for i=0,count-1 do _fi[#_fi+1]={address=fl+(i*self.FieldsStep),flags=Il2cpp.MainType} end
                _fi=gg.getValues(_fi)
                for i=1,#_fi do
                    local finfo=Il2cpp.FieldApi:UnpackFieldInfo(Il2cpp.FixValue(_fi[i].address))
                    table.move(finfo,1,#finfo,#fi+1,fi)
                end
                fi=gg.getValues(fi) _fi=Il2cpp.FieldApi:DecodeFieldsInfo(fi,cc) return _fi
            end,
            UnpackClassInfo=function(self,ci,config)
                local cia=ci.ClassInfoAddress
                local _ci=gg.getValues({
                    {address=cia+self.NameOffset,flags=Il2cpp.MainType},
                    {address=cia+self.CountMethods,flags=gg.TYPE_WORD},
                    {address=cia+self.CountFields,flags=gg.TYPE_WORD},
                    {address=cia+self.MethodsLink,flags=Il2cpp.MainType},
                    {address=cia+self.FieldsLink,flags=Il2cpp.MainType},
                    {address=cia+self.ParentOffset,flags=Il2cpp.MainType},
                    {address=cia+self.NameSpaceOffset,flags=Il2cpp.MainType},
                    {address=cia+self.StaticFieldDataOffset,flags=Il2cpp.MainType},
                    {address=cia+self.EnumType,flags=gg.TYPE_BYTE},
                    {address=cia+self.TypeMetadataHandle,flags=Il2cpp.MainType},
                    {address=cia+self.InstanceSize,flags=gg.TYPE_DWORD},
                    {address=cia+self.Token,flags=gg.TYPE_DWORD},
                })
                local cn=ci.ClassName or Il2cpp.Utf8ToString(Il2cpp.FixValue(_ci[1].value))
                local cc={ClassName=cn,IsEnum=((_ci[9].value>>self.EnumRsh)&1)==1,TypeMetadataHandle=Il2cpp.FixValue(_ci[10].value)}
                return setmetatable({
                    ClassName=cn,
                    ClassAddress=string.format('%X',Il2cpp.FixValue(cia)),
                    Methods=(_ci[2].value>0 and config.MethodsDump) and self:GetClassMethods(Il2cpp.FixValue(_ci[4].value),_ci[2].value,cn) or nil,
                    Fields=(_ci[3].value>0 and config.FieldsDump) and self:GetClassFields(Il2cpp.FixValue(_ci[5].value),_ci[3].value,cc) or nil,
                    Parent=_ci[6].value~=0 and {ClassAddress=string.format('%X',Il2cpp.FixValue(_ci[6].value)),ClassName=self:GetClassName(_ci[6].value)} or nil,
                    ClassNameSpace=Il2cpp.Utf8ToString(Il2cpp.FixValue(_ci[7].value)),
                    StaticFieldData=_ci[8].value~=0 and Il2cpp.FixValue(_ci[8].value) or nil,
                    IsEnum=cc.IsEnum, TypeMetadataHandle=cc.TypeMetadataHandle,
                    InstanceSize=_ci[11].value, Token=string.format("0x%X",_ci[12].value),
                    ImageName=ci.ImageName,
                },{__index=Il2cpp.ClassInfoApi,__tostring=StringUtils.ClassInfoToDumpCS})
            end,
            IsClassInfo=function(Address)
                local ia=Il2cpp.FixValue(gg.getValues({{address=Il2cpp.FixValue(Address),flags=Il2cpp.MainType}})[1].value)
                local is=Il2cpp.Utf8ToString(Il2cpp.FixValue(gg.getValues({{address=ia,flags=Il2cpp.MainType}})[1].value))
                local chk=string.find(is,".-%.dll") or string.find(is,"__Generated")
                return chk and is or nil
            end,
            FindClassWithName=function(self,cn,sr)
                local cnp=Il2cpp.GlobalMetadataApi.GetPointersToString(cn)
                local rt={}
                if #cnp>sr.len then
                    for _,cp in ipairs(cnp) do
                        local ca=cp.address-self.NameOffset
                        local iname=self.IsClassInfo(ca)
                        if iname then rt[#rt+1]={ClassInfoAddress=Il2cpp.FixValue(ca),ClassName=cn,ImageName=iname} end
                    end
                    sr.len=#cnp
                else sr.isNew=false end
                assert(#rt>0,string.format("The '%s' class is not initialized",cn))
                return rt
            end,
            FindClassWithAddressInMemory=function(self,ca,sr)
                local rt={}
                if sr.len<1 then
                    local iname=self.IsClassInfo(ca)
                    if iname then rt[#rt+1]={ClassInfoAddress=ca,ImageName=iname} end
                    sr.len=1
                else sr.isNew=false end
                assert(#rt>0,string.format("nothing was found for this address 0x%X",ca))
                return rt
            end,
            FindParamsCheck={
                ['number']=function(self,_c,sr) return Protect:Call(self.FindClassWithAddressInMemory,self,_c,sr) end,
                ['string']=function(self,_c,sr) return Protect:Call(self.FindClassWithName,self,_c,sr) end,
                ['default']=function() return {Error='Invalid search criteria'} end,
            },
            Find=function(self,class)
                local sr=Il2cppMemory:GetInformationOfClass(class.Class)
                if (not sr) or ((class.FieldsDump or class.MethodsDump) and (sr.config.FieldsDump~=class.FieldsDump or sr.config.MethodsDump~=class.MethodsDump)) then
                    sr={len=0}
                end
                sr.isNew=true
                local ci=(self.FindParamsCheck[type(class.Class)] or self.FindParamsCheck['default'])(self,class.Class,sr)
                if sr.isNew then
                    for k=1,#ci do
                        ci[k]=self:UnpackClassInfo(ci[k],{FieldsDump=class.FieldsDump,MethodsDump=class.MethodsDump})
                    end
                    sr.config={Class=class.Class,FieldsDump=class.FieldsDump,MethodsDump=class.MethodsDump}
                    sr.result=ci
                    Il2cppMemory:SetInformationOfClass(class.Class,sr)
                else ci=sr.result end
                return ci
            end,
        }
        return ClassApi
    end)
    __bundle_register("utils.stringutils", function(require, _LOADED, __bundle_register, __bundle_modules)
        return {
            ClassInfoToDumpCS=function(ci)
                local d={"// ",ci.ImageName,"\n","// Namespace: ",ci.ClassNameSpace,"\n","class ",ci.ClassName,ci.Parent and " : "..ci.Parent.ClassName or "","n","{n"}
                if ci.Fields and #ci.Fields>0 then
                    d[#d+1]="\n\t// Fields\n"
                    for _,v in ipairs(ci.Fields) do
                        local df={"\t",v.Access," ",v.IsStatic and "static " or "",v.IsConst and "const " or "",v.Type," ",v.FieldName,"; // 0x",v.Offset,"\n"}
                        table.move(df,1,#df,#d+1,d)
                    end
                end
                if ci.Methods and #ci.Methods>0 then
                    d[#d+1]="\n\t// Methods\n"
                    for i,v in ipairs(ci.Methods) do
                        local dm={i==1 and "" or "\n","\t// Offset: 0x",v.Offset," VA: 0x",v.AddressInMemory," ParamCount: ",v.ParamCount,"\n","\t",v.Access," ",v.IsStatic and "static " or "",v.IsAbstract and "abstract " or "",v.ReturnType," ",v.MethodName,"() { } \n"}
                        table.move(dm,1,#dm,#d+1,d)
                    end
                end
                d[#d+1]="\n}\n"
                return table.concat(d)
            end
        }
    end)
    __bundle_register("utils.protect", function(require, _LOADED, __bundle_register, __bundle_modules)
        return {
            ErrorHandler=function(e) return {Error=e} end,
            Call=function(self,fun,...) return ({xpcall(fun,self.ErrorHandler,...)})[2] end,
        }
    end)
    __bundle_register("il2cppstruct.field", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Protect=require("utils.protect")
        local FieldApi={
            UnpackFieldInfo=function(self,fa)
                return {{address=fa,flags=Il2cpp.MainType},{address=fa+self.Offset,flags=gg.TYPE_WORD},{address=fa+self.Type,flags=Il2cpp.MainType},{address=fa+self.ClassOffset,flags=Il2cpp.MainType}}
            end,
            DecodeFieldsInfo=function(self,fi,cc)
                local idx,_fi=0,{}
                local fs=gg.getValues({{address=cc.TypeMetadataHandle+Il2cpp.Il2CppTypeDefinitionApi.fieldStart,flags=gg.TYPE_DWORD}})[1].value
                for i=1,#fi,4 do
                    idx=idx+1
                    local ti=Il2cpp.FixValue(fi[i+2].value)
                    local _ti=gg.getValues({{address=ti+self.Type,flags=gg.TYPE_WORD},{address=ti+Il2cpp.TypeApi.Type,flags=gg.TYPE_BYTE},{address=ti,flags=Il2cpp.MainType}})
                    local attrs=_ti[1].value
                    local isConst=(attrs&Il2CppFlags.Field.FIELD_ATTRIBUTE_LITERAL)~=0
                    _fi[idx]=setmetatable({
                        ClassName=cc.ClassName or Il2cpp.ClassApi:GetClassName(fi[i+3].value),
                        ClassAddress=string.format('%X',Il2cpp.FixValue(fi[i+3].value)),
                        FieldName=Il2cpp.Utf8ToString(Il2cpp.FixValue(fi[i].value)),
                        Offset=string.format('%X',fi[i+1].value),
                        IsStatic=(not isConst) and ((attrs&Il2CppFlags.Field.FIELD_ATTRIBUTE_STATIC)~=0),
                        Type=Il2cpp.TypeApi:GetTypeName(_ti[2].value,_ti[3].value),
                        IsConst=isConst,
                        Access=Il2CppFlags.Field.Access[attrs&Il2CppFlags.Field.FIELD_ATTRIBUTE_FIELD_ACCESS_MASK] or "",
                    },{__index=Il2cpp.FieldInfoApi,fieldIndex=fs+idx-1})
                end
                return _fi
            end,
            FindFieldWithName=function(self,fn)
                local fnp=Il2cpp.GlobalMetadataApi.GetPointersToString(fn)
                local rt={}
                for _,v in ipairs(fnp) do
                    local ca=gg.getValues({{address=v.address+self.ClassOffset,flags=Il2cpp.MainType}})[1].value
                    if Il2cpp.ClassApi.IsClassInfo(ca) then
                        local r=self.FindFieldInClass(fn,ca) table.move(r,1,#r,#rt+1,rt)
                    end
                end
                assert(type(rt)=="table" and #rt>0,string.format("The '%s' field is not initialized",fn))
                return rt
            end,
            FindFieldWithAddress=function(self,fa)
                local oh=Il2cpp.ObjectApi.FindHead(fa)
                local fo=fa-oh.address
                local ca=Il2cpp.FixValue(oh.value)
                local rt=self.FindFieldInClass(fo,ca)
                assert(#rt>0,string.format("nothing was found for this address 0x%X",fa))
                return rt
            end,
            FindFieldInClass=function(fsc,ca)
                local rt={}
                local ic=Il2cpp.FindClass({{Class=ca,FieldsDump=true}})[1]
                for _,v in ipairs(ic) do
                    rt[#rt+1]=type(fsc)=="number" and v:GetFieldWithOffset(fsc) or v:GetFieldWithName(fsc)
                end
                return rt
            end,
            FindTypeCheck={
                ['string']=function(self,fn) return Protect:Call(self.FindFieldWithName,self,fn) end,
                ['number']=function(self,fa) return Protect:Call(self.FindFieldWithAddress,self,fa) end,
                ['default']=function() return {Error='Invalid search criteria'} end,
            },
            Find=function(self,fsc)
                return (self.FindTypeCheck[type(fsc)] or self.FindTypeCheck['default'])(self,fsc)
            end,
        }
        return FieldApi
    end)
    __bundle_register("il2cppstruct.globalmetadata", function(require, _LOADED, __bundle_register, __bundle_modules)
        local GlobalMetadataApi = {
            behaviorForTypes={
                [2]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_BYTE) end,
                [3]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_BYTE) end,
                [4]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_BYTE) end,
                [5]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_BYTE) end,
                [6]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_WORD) end,
                [7]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_WORD) end,
                [8]=function(b) local s=Il2cpp.GlobalMetadataApi return s.version<29 and s.ReadNumberConst(b,gg.TYPE_DWORD) or s.ReadCompressedInt32(b) end,
                [9]=function(b) local s=Il2cpp.GlobalMetadataApi return s.version<29 and Il2cpp.FixValue(s.ReadNumberConst(b,gg.TYPE_DWORD)) or s.ReadCompressedUInt32(b) end,
                [10]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_QWORD) end,
                [11]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_QWORD) end,
                [12]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_FLOAT) end,
                [13]=function(b) return Il2cpp.GlobalMetadataApi.ReadNumberConst(b,gg.TYPE_DOUBLE) end,
                [14]=function(b)
                    local s=Il2cpp.GlobalMetadataApi local len,off=0,0
                    if s.version>=29 then len,off=s.ReadCompressedInt32(b)
                    else len=s.ReadNumberConst(b,gg.TYPE_DWORD) off=4 end
                    if len~=-1 then return Il2cpp.Utf8ToString(b+off,len) end
                    return ""
                end,
            },
            GetStringFromIndex=function(self,i) return Il2cpp.Utf8ToString(Il2cpp.globalMetadataStart+self.stringOffset+i) end,
            GetClassNameFromIndex=function(self,i)
                if self.version<27 then
                    local td=Il2cpp.globalMetadataStart+self.typeDefinitionsOffset
                    i=(self.typeDefinitionsSize*i)+td
                else i=Il2cpp.FixValue(i) end
                local td=gg.getValues({{address=i,flags=gg.TYPE_DWORD}})[1].value
                return self:GetStringFromIndex(td)
            end,
            GetFieldOrParameterDefalutValue=function(self,di) return self.fieldAndParameterDefaultValueDataOffset+Il2cpp.globalMetadataStart+di end,
            GetIl2CppFieldDefaultValue=function(self,i)
                gg.clearResults() gg.setRanges(0)
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_OTHER|gg.REGION_C_ALLOC)
                gg.searchNumber(i,gg.TYPE_DWORD,false,gg.SIGN_EQUAL,Il2cpp.globalMetadataStart+self.fieldDefaultValuesOffset,Il2cpp.globalMetadataStart+self.fieldDefaultValuesOffset+self.fieldDefaultValuesSize)
                if gg.getResultsCount()>0 then local r=gg.getResults(1) gg.clearResults() return r end
                return {}
            end,
            ReadCompressedUInt32=function(Address)
                local val,off=0,0
                local r=gg.getValues({{address=Address,flags=gg.TYPE_BYTE},{address=Address+1,flags=gg.TYPE_BYTE},{address=Address+2,flags=gg.TYPE_BYTE},{address=Address+3,flags=gg.TYPE_BYTE}})
                local r1=r[1].value&0xFF off=1
                if(r1&0x80)==0 then val=r1
                elseif(r1&0xC0)==0x80 then val=(r1&~0x80)<<8 val=val|(r[2].value&0xFF) off=off+1
                elseif(r1&0xE0)==0xC0 then val=(r1&~0xC0)<<24 val=val|((r[2].value&0xFF)<<16) val=val|((r[3].value&0xFF)<<8) val=val|(r[4].value&0xFF) off=off+3
                elseif r1==0xF0 then val=gg.getValues({{address=Address+1,flags=gg.TYPE_DWORD}})[1].value off=off+4
                elseif r1==0xFE then val=0xffffffff-1
                elseif r1==0xFF then val=0xffffffff end
                return val,off
            end,
            ReadCompressedInt32=function(Address)
                local encoded,off=Il2cpp.GlobalMetadataApi.ReadCompressedUInt32(Address)
                if encoded==0xffffffff then return -2147483647-1 end
                local isNeg=(encoded&1)==1 encoded=encoded>>1
                if isNeg then return -(encoded+1) end
                return encoded,off
            end,
            ReadNumberConst=function(Address,ggType)
                return gg.getValues({{address=Address,flags=ggType}})[1].value
            end,
            GetDefaultFieldValue=function(self,i)
                local dfv=self:GetIl2CppFieldDefaultValue(tostring(i))
                if #dfv>0 then
                    local _dfv=gg.getValues({{address=dfv[1].address+4,flags=gg.TYPE_DWORD},{address=dfv[1].address+8,flags=gg.TYPE_DWORD}})
                    local blob=self:GetFieldOrParameterDefalutValue(_dfv[2].value)
                    local Il2CppType=Il2cpp.MetadataRegistrationApi:GetIl2CppTypeFromIndex(_dfv[1].value)
                    local typeEnum=Il2cpp.TypeApi:GetTypeEnum(Il2CppType)
                    local behavior=self.behaviorForTypes[typeEnum] or "Not support type"
                    if type(behavior)=="function" then return behavior(blob) end
                    return behavior
                end
                return nil
            end,
            GetPointersToString=function(name)
                local ptrs={}
                gg.clearResults() gg.setRanges(0)
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_OTHER|gg.REGION_C_ALLOC)
                gg.searchNumber(string.format("Q 00 '%s' 00",name),gg.TYPE_BYTE,false,gg.SIGN_EQUAL,Il2cpp.globalMetadataStart,Il2cpp.globalMetadataEnd)
                gg.searchPointer(0)
                ptrs=gg.getResults(gg.getResultsCount())
                assert(type(ptrs)=='table' and #ptrs>0,string.format("this '%s' is not in the global-metadata",name))
                gg.clearResults()
                return ptrs
            end,
        }
        return GlobalMetadataApi
    end)
    __bundle_register("il2cppstruct.method", function(require, _LOADED, __bundle_register, __bundle_modules)
        local AndroidInfo=require("utils.androidinfo")
        local Protect=require("utils.protect")
        local Il2cppMemory=require("utils.il2cppmemory")
        local MethodsApi={
            FindMethodWithName=function(self,mn,sr)
                local fm={}
                local mnp=Il2cpp.GlobalMetadataApi.GetPointersToString(mn)
                if sr.len<#mnp then
                    for _,mp in ipairs(mnp) do
                        mp.address=mp.address-self.NameOffset
                        local ma=Il2cpp.FixValue(gg.getValues({mp})[1].value)
                        if ma>Il2cpp.il2cppStart and ma<Il2cpp.il2cppEnd then
                            fm[#fm+1]={MethodName=mn,MethodAddress=ma,MethodInfoAddress=mp.address}
                        end
                    end
                else sr.isNew=false end
                assert(#fm>0,string.format("The '%s' method is not initialized",mn))
                return fm
            end,
            FindMethodWithOffset=function(self,mo,sr)
                return self:FindMethodWithAddressInMemory(Il2cpp.il2cppStart+mo,sr,mo)
            end,
            FindMethodWithAddressInMemory=function(self,ma,sr,mo)
                local rmi={}
                gg.clearResults()
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_C_ALLOC|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_OTHER)
                if gg.BUILD<16126 then
                    gg.searchNumber(string.format("%Xh",ma),Il2cpp.MainType)
                else
                    gg.loadResults({{address=ma,flags=Il2cpp.MainType}}) gg.searchPointer(0)
                end
                local rc=gg.getResultsCount()
                if rc>sr.len then
                    local r=gg.getResults(rc)
                    for _,v in ipairs(r) do rmi[#rmi+1]={MethodAddress=ma,MethodInfoAddress=v.address,Offset=mo} end
                else sr.isNew=false end
                gg.clearResults()
                assert(#rmi>0,string.format("nothing was found for this address 0x%X",ma))
                return rmi
            end,
            DecodeMethodsInfo=function(self,_mi,mi)
                for i=1,#_mi do
                    local idx=(i-1)*6
                    local ti=Il2cpp.FixValue(mi[idx+5].value)
                    local _ti=gg.getValues({{address=ti+Il2cpp.TypeApi.Type,flags=gg.TYPE_BYTE},{address=ti,flags=Il2cpp.MainType}})
                    local ma=Il2cpp.FixValue(mi[idx+1].value)
                    local mf=mi[idx+6].value
                    _mi[i]={
                        MethodName=_mi[i].MethodName or Il2cpp.Utf8ToString(Il2cpp.FixValue(mi[idx+2].value)),
                        Offset=string.format("%X",_mi[i].Offset or (ma==0 and ma or ma-Il2cpp.il2cppStart)),
                        AddressInMemory=string.format("%X",ma),
                        MethodInfoAddress=_mi[i].MethodInfoAddress,
                        ClassName=_mi[i].ClassName or Il2cpp.ClassApi:GetClassName(mi[idx+3].value),
                        ClassAddress=string.format('%X',Il2cpp.FixValue(mi[idx+3].value)),
                        ParamCount=mi[idx+4].value,
                        ReturnType=Il2cpp.TypeApi:GetTypeName(_ti[1].value,_ti[2].value),
                        IsStatic=(mf&Il2CppFlags.Method.METHOD_ATTRIBUTE_STATIC)~=0,
                        Access=Il2CppFlags.Method.Access[mf&Il2CppFlags.Method.METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK] or "",
                        IsAbstract=(mf&Il2CppFlags.Method.METHOD_ATTRIBUTE_ABSTRACT)~=0,
                    }
                end
            end,
            UnpackMethodInfo=function(self,mi)
                return {
                    {address=mi.MethodInfoAddress,flags=Il2cpp.MainType},
                    {address=mi.MethodInfoAddress+self.NameOffset,flags=Il2cpp.MainType},
                    {address=mi.MethodInfoAddress+self.ClassOffset,flags=Il2cpp.MainType},
                    {address=mi.MethodInfoAddress+self.ParamCount,flags=gg.TYPE_BYTE},
                    {address=mi.MethodInfoAddress+self.ReturnType,flags=Il2cpp.MainType},
                    {address=mi.MethodInfoAddress+self.Flags,flags=gg.TYPE_WORD},
                },{MethodName=mi.MethodName or nil,Offset=mi.Offset or nil,MethodInfoAddress=mi.MethodInfoAddress,ClassName=mi.ClassName}
            end,
            FindParamsCheck={
                ['number']=function(self,m,sr)
                    if m>Il2cpp.il2cppStart and m<Il2cpp.il2cppEnd then
                        return Protect:Call(self.FindMethodWithAddressInMemory,self,m,sr)
                    else return Protect:Call(self.FindMethodWithOffset,self,m,sr) end
                end,
                ['string']=function(self,m,sr) return Protect:Call(self.FindMethodWithName,self,m,sr) end,
                ['default']=function() return {Error='Invalid search criteria'} end,
            },
            Find=function(self,method)
                local sr=Il2cppMemory:GetInformaionOfMethod(method)
                if not sr then sr={len=0} end
                sr.isNew=true
                local _mi=(self.FindParamsCheck[type(method)] or self.FindParamsCheck['default'])(self,method,sr)
                if sr.isNew then
                    local mi={}
                    for i=1,#_mi do
                        local minfo
                        minfo,_mi[i]=self:UnpackMethodInfo(_mi[i])
                        table.move(minfo,1,#minfo,#mi+1,mi)
                    end
                    mi=gg.getValues(mi) self:DecodeMethodsInfo(_mi,mi)
                    sr.len=#_mi sr.result=_mi
                    Il2cppMemory:SetInformaionOfMethod(method,sr)
                else _mi=sr.result end
                return _mi
            end,
        }
        return MethodsApi
    end)
    __bundle_register("il2cppstruct.type", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Il2cppMemory=require("utils.il2cppmemory")
        local TypeApi={
            tableTypes={[1]="void",[2]="bool",[3]="char",[4]="sbyte",[5]="byte",[6]="short",[7]="ushort",[8]="int",[9]="uint",[10]="long",[11]="ulong",[12]="float",[13]="double",[14]="string",[22]="TypedReference",[24]="IntPtr",[25]="UIntPtr",[28]="object",
                [17]=function(i) return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(i) end,
                [18]=function(i) return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(i) end,
                [29]=function(i)
                    local tm=gg.getValues({{address=Il2cpp.FixValue(i),flags=Il2cpp.MainType},{address=Il2cpp.FixValue(i)+Il2cpp.TypeApi.Type,flags=gg.TYPE_BYTE}})
                    return Il2cpp.TypeApi:GetTypeName(tm[2].value,tm[1].value).."[]"
                end,
                [21]=function(i)
                    if not(Il2cpp.GlobalMetadataApi.version<27) then i=gg.getValues({{address=Il2cpp.FixValue(i),flags=Il2cpp.MainType}})[1].value end
                    i=gg.getValues({{address=Il2cpp.FixValue(i),flags=Il2cpp.MainType}})[1].value
                    return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(i)
                end,
            },
            GetTypeName=function(self,ti,i)
                local tn=self.tableTypes[ti] or string.format('(not support type -> 0x%X)',ti)
                if type(tn)=='function' then
                    local rt=Il2cppMemory:GetInformationOfType(i)
                    if not rt then rt=tn(i) Il2cppMemory:SetInformationOfType(i,rt) end
                    tn=rt
                end
                return tn
            end,
            GetTypeEnum=function(self,t) return gg.getValues({{address=t+self.Type,flags=gg.TYPE_BYTE}})[1].value end,
        }
        return TypeApi
    end)
    __bundle_register("il2cppstruct.metadataRegistration", function(require, _LOADED, __bundle_register, __bundle_modules)
        local Searcher=require("utils.universalsearcher")
        return {
            GetIl2CppTypeFromIndex=function(self,i)
                if not self.metadataRegistration then self:FindMetadataRegistration() end
                local types=gg.getValues({{address=self.metadataRegistration+self.types,flags=Il2cpp.MainType}})[1].value
                return Il2cpp.FixValue(gg.getValues({{address=types+(Il2cpp.pointSize*i),flags=Il2cpp.MainType}})[1].value)
            end,
            FindMetadataRegistration=function(self) self.metadataRegistration=Searcher.Il2CppMetadataRegistration() end,
        }
    end)
    __bundle_register("utils.universalsearcher", function(require, _LOADED, __bundle_register, __bundle_modules)
        local AndroidInfo=require("utils.androidinfo")
        local sw=":EnsureCapacity"
        local Searcher={
            searchWord=sw,
            FindGlobalMetaData=function(self)
                gg.clearResults()
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_C_ALLOC|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_OTHER)
                local gm=gg.getRangesList('global-metadata.dat')
                if not self:IsValidData(gm) then
                    gm={}
                    gg.clearResults() gg.searchNumber(sw,gg.TYPE_BYTE) gg.refineNumber(sw:sub(1,2),gg.TYPE_BYTE)
                    local ec=gg.getResults(gg.getResultsCount()) gg.clearResults()
                    for _,v in ipairs(gg.getRangesList()) do
                        if v.state=='Ca' or v.state=='A' or v.state=='Cd' or v.state=='Cb' or v.state=='Ch' or v.state=='O' then
                            for _,val in ipairs(ec) do
                                gm[#gm+1]=(Il2cpp.FixValue(v.start)<=Il2cpp.FixValue(val.address) and Il2cpp.FixValue(val.address)<Il2cpp.FixValue(v['end'])) and v or nil
                            end
                        end
                    end
                end
                return gm[1].start, gm[#gm]['end']
            end,
            IsValidData=function(self,gm)
                if #gm~=0 then
                    gg.searchNumber(sw,gg.TYPE_BYTE,false,gg.SIGN_EQUAL,gm[1].start,gm[#gm]['end'])
                    if gg.getResultsCount()>0 then gg.clearResults() return true end
                end
                return false
            end,
            FindIl2cpp=function()
                local il=gg.getRangesList(LIB_NAME)
                if #il==0 then
                    il=gg.getRangesList('split_config.')
                    local _il={}
                    gg.setRanges(gg.REGION_CODE_APP)
                    for _,v in ipairs(il) do
                        if v.state=='Xa' then
                            gg.searchNumber(':il2cpp',gg.TYPE_BYTE,false,gg.SIGN_EQUAL,v.start,v['end'])
                            if gg.getResultsCount()>0 then _il[#_il+1]=v gg.clearResults() end
                        end
                    end
                    il=_il
                else
                    local _il={}
                    for _,v in ipairs(il) do
                        if string.find(v.type,"..x.") or v.state=="Xa" then _il[#_il+1]=v end
                    end
                    il=_il
                end
                return il[1].start, il[#il]['end']
            end,
            Il2CppMetadataRegistration=function()
                gg.clearResults()
                gg.setRanges(gg.REGION_C_HEAP|gg.REGION_C_ALLOC|gg.REGION_ANONYMOUS|gg.REGION_C_BSS|gg.REGION_C_DATA|gg.REGION_OTHER)
                gg.loadResults({{address=Il2cpp.globalMetadataStart,flags=Il2cpp.MainType}}) gg.searchPointer(0)
                if gg.getResultsCount()==0 and AndroidInfo.platform and AndroidInfo.sdk>=30 then
                    gg.searchNumber(tostring(Il2cpp.globalMetadataStart|0xB400000000000000),Il2cpp.MainType)
                end
                if gg.getResultsCount()>0 then
                    local gmp,sgm=gg.getResults(gg.getResultsCount()),0
                    for i=1,#gmp do
                        if i~=1 then
                            local diff=gmp[i].address-gmp[i-1].address
                            if diff==Il2cpp.pointSize then
                                sgm=Il2cpp.FixValue(gg.getValues({{address=gmp[i].address-(AndroidInfo.platform and 0x10 or 0x8),flags=Il2cpp.MainType}})[1].value)
                            end
                        end
                    end
                    return sgm
                end
                return 0
            end,
        }
        return Searcher
    end)
    __bundle_register("utils.patchapi", function(require, _LOADED, __bundle_register, __bundle_modules)
        return {
            Create=function(self,pc) return setmetatable({newBytes=pc,oldBytes=gg.getValues(pc)},{__index=self}) end,
            Patch=function(self) if self.newBytes then gg.setValues(self.newBytes) end end,
            Undo=function(self) if self.oldBytes then gg.setValues(self.oldBytes) end end,
        }
    end)
    __bundle_register("utils.version", function(require, _LOADED, __bundle_register, __bundle_modules)
        local semver=require("semver.semver")
        local AndroidInfo=require("utils.androidinfo")
        local VersionEngine={
            ConstSemVer={['2018_3']=semver(2018,3),['2019_4_21']=semver(2019,4,21),['2019_4_15']=semver(2019,4,15),['2019_3_7']=semver(2019,3,7),['2020_2_4']=semver(2020,2,4),['2020_2']=semver(2020,2),['2020_1_11']=semver(2020,1,11),['2021_2']=semver(2021,2)},
            Year={
                [2017]=function(self,v) return 24 end,
                [2018]=function(self,v) return not(v<self.ConstSemVer['2018_3']) and 24.1 or 24 end,
                [2019]=function(self,v) local ver=24.2 if not(v<self.ConstSemVer['2019_4_21']) then ver=24.5 elseif not(v<self.ConstSemVer['2019_4_15']) then ver=24.4 elseif not(v<self.ConstSemVer['2019_3_7']) then ver=24.3 end return ver end,
                [2020]=function(self,v) local ver=24.3 if not(v<self.ConstSemVer['2020_2_4']) then ver=27.1 elseif not(v<self.ConstSemVer['2020_2']) then ver=27 elseif not(v<self.ConstSemVer['2020_1_11']) then ver=24.4 end return ver end,
                [2021]=function(self,v) return not(v<self.ConstSemVer['2021_2']) and 29 or 27.2 end,
                [2022]=function(self,v) return 29 end,
            },
            GetUnityVersion=function()
                gg.setRanges(gg.REGION_ANONYMOUS) gg.clearResults()
                gg.searchNumber("00h;32h;30h;0~~0;0~~0;2Eh;0~~0;2Eh::9",gg.TYPE_BYTE,false,gg.SIGN_EQUAL,nil,nil,1)
                local r=gg.getResultsCount()>0 and gg.getResults(3)[3].address or 0
                gg.clearResults() return r
            end,
            ReadUnityVersion=function(va) local vn=Il2cpp.Utf8ToString(va) return string.gmatch(vn,"(%d+)%p(%d+)%p(%d+)")() end,
            ChooseVersion=function(self,ver,gmh)
                if not ver then
                    local uva=self.GetUnityVersion()
                    if uva==0 then ver=gg.getValues({{address=gmh+0x4,flags=gg.TYPE_DWORD}})[1].value
                    else local p1,p2,p3=self.ReadUnityVersion(uva) local uv=semver(tonumber(p1),tonumber(p2),tonumber(p3)) ver=self.Year[uv.major] or 29 if type(ver)=='function' then ver=ver(self,uv) end end
                end
                local api=assert(Il2CppConst[ver],'Not support this il2cpp version')
                Il2cpp.FieldApi.Offset=api.FieldApiOffset Il2cpp.FieldApi.Type=api.FieldApiType Il2cpp.FieldApi.ClassOffset=api.FieldApiClassOffset
                Il2cpp.ClassApi.NameOffset=api.ClassApiNameOffset Il2cpp.ClassApi.MethodsStep=api.ClassApiMethodsStep Il2cpp.ClassApi.CountMethods=api.ClassApiCountMethods Il2cpp.ClassApi.MethodsLink=api.ClassApiMethodsLink Il2cpp.ClassApi.FieldsLink=api.ClassApiFieldsLink Il2cpp.ClassApi.FieldsStep=api.ClassApiFieldsStep Il2cpp.ClassApi.CountFields=api.ClassApiCountFields Il2cpp.ClassApi.ParentOffset=api.ClassApiParentOffset Il2cpp.ClassApi.NameSpaceOffset=api.ClassApiNameSpaceOffset Il2cpp.ClassApi.StaticFieldDataOffset=api.ClassApiStaticFieldDataOffset Il2cpp.ClassApi.EnumType=api.ClassApiEnumType Il2cpp.ClassApi.EnumRsh=api.ClassApiEnumRsh Il2cpp.ClassApi.TypeMetadataHandle=api.ClassApiTypeMetadataHandle Il2cpp.ClassApi.InstanceSize=api.ClassApiInstanceSize Il2cpp.ClassApi.Token=api.ClassApiToken
                Il2cpp.MethodsApi.ClassOffset=api.MethodsApiClassOffset Il2cpp.MethodsApi.NameOffset=api.MethodsApiNameOffset Il2cpp.MethodsApi.ParamCount=api.MethodsApiParamCount Il2cpp.MethodsApi.ReturnType=api.MethodsApiReturnType Il2cpp.MethodsApi.Flags=api.MethodsApiFlags
                Il2cpp.GlobalMetadataApi.typeDefinitionsSize=api.typeDefinitionsSize Il2cpp.GlobalMetadataApi.version=ver
                local consts=gg.getValues({{address=gmh+api.typeDefinitionsOffset,flags=gg.TYPE_DWORD},{address=gmh+api.stringOffset,flags=gg.TYPE_DWORD},{address=gmh+api.fieldDefaultValuesOffset,flags=gg.TYPE_DWORD},{address=gmh+api.fieldDefaultValuesSize,flags=gg.TYPE_DWORD},{address=gmh+api.fieldAndParameterDefaultValueDataOffset,flags=gg.TYPE_DWORD}})
                Il2cpp.GlobalMetadataApi.typeDefinitionsOffset=consts[1].value Il2cpp.GlobalMetadataApi.stringOffset=consts[2].value Il2cpp.GlobalMetadataApi.fieldDefaultValuesOffset=consts[3].value Il2cpp.GlobalMetadataApi.fieldDefaultValuesSize=consts[4].value Il2cpp.GlobalMetadataApi.fieldAndParameterDefaultValueDataOffset=consts[5].value
                Il2cpp.TypeApi.Type=api.TypeApiType Il2cpp.Il2CppTypeDefinitionApi.fieldStart=api.Il2CppTypeDefinitionApifieldStart Il2cpp.MetadataRegistrationApi.types=api.MetadataRegistrationApitypes
            end,
        }
        return VersionEngine
    end)
    __bundle_register("semver.semver", function(require, _LOADED, __bundle_register, __bundle_modules)
        local semver={_VERSION='1.2.1'}
        local function checkPos(n,name) assert(n>=0,name..' must be a valid positive number') assert(math.floor(n)==n,name..' must be an integer') end
        local function present(v) return v and v~='' end
        local function splitByDot(s) s=s or "" local t,c={},0 s:gsub("([^%.]+)",function(x) c=c+1 t[c]=x end) return t end
        local function parsePABwS(s) local pw,bw=s:match("^(-[^+]+)(+.+)$") if not(pw and bw) then pw=s:match("^(-.+)$") bw=s:match("^(%+.+)$") end assert(pw or bw,("param %q must begin with + or -"):format(s)) return pw,bw end
        local function parsePR(pw) if pw then local pr=pw:match("^-(%w[%.%w-]*)$") assert(pr,("prerelease %q invalid"):format(pw)) return pr end end
        local function parseBd(bw) if bw then local b=bw:match("^%+(%w[%.%w-]*)$") assert(b,("build %q invalid"):format(bw)) return b end end
        local function parsePAB(s) if not present(s) then return nil,nil end local pw,bw=parsePABwS(s) return parsePR(pw),parseBd(bw) end
        local function parseVer(s) local sm,sn,sp,sr=s:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$") assert(type(sm)=='string',("Could not extract version from %q"):format(s)) local maj,min,pat=tonumber(sm),tonumber(sn),tonumber(sp) local pr,b=parsePAB(sr) return maj,min,pat,pr,b end
        local function cmp(a,b) return a==b and 0 or a<b and -1 or 1 end
        local function cmpIds(a,b) if a==b then return 0 elseif not a then return -1 elseif not b then return 1 end local na,nb=tonumber(a),tonumber(b) if na and nb then return cmp(na,nb) elseif na then return -1 elseif nb then return 1 else return cmp(a,b) end end
        local function smallerIdList(a,b) local al=#a for i=1,al do local c=cmpIds(a[i],b[i]) if c~=0 then return c==-1 end end return al<#b end
        local function smallerPR(a,b) if a==b or not a then return false elseif not b then return true end return smallerIdList(splitByDot(a),splitByDot(b)) end
        local methods={}
        function methods:nextMajor() return semver(self.major+1,0,0) end
        function methods:nextMinor() return semver(self.major,self.minor+1,0) end
        function methods:nextPatch() return semver(self.major,self.minor,self.patch+1) end
        local mt={__index=methods}
        function mt:__eq(o) return self.major==o.major and self.minor==o.minor and self.patch==o.patch and self.prerelease==o.prerelease end
        function mt:__lt(o) if self.major~=o.major then return self.major<o.major end if self.minor~=o.minor then return self.minor<o.minor end if self.patch~=o.patch then return self.patch<o.patch end return smallerPR(self.prerelease,o.prerelease) end
        function mt:__pow(o) if self.major==0 then return self==o end return self.major==o.major and self.minor<=o.minor end
        function mt:__tostring() local b={("%d.%d.%d"):format(self.major,self.minor,self.patch)} if self.prerelease then b[#b+1]="-"..self.prerelease end if self.build then b[#b+1]="+"..self.build end return table.concat(b) end
        local function new(maj,min,pat,pr,b) assert(maj,"At least one parameter needed") if type(maj)=='string' then maj,min,pat,pr,b=parseVer(maj) end pat=pat or 0 min=min or 0 checkPos(maj,"major") checkPos(min,"minor") checkPos(pat,"patch") return setmetatable({major=maj,minor=min,patch=pat,prerelease=pr,build=b},mt) end
        setmetatable(semver,{__call=function(_,...) return new(...) end})
        semver._VERSION=semver(semver._VERSION)
        return semver
    end)
    __bundle_register("utils.il2cppconst", function(require, _LOADED, __bundle_register, __bundle_modules)
        local AndroidInfo=require("utils.androidinfo")
        Il2CppConst={
            [20]={FieldApiOffset=0xC,FieldApiType=0x4,FieldApiClassOffset=0x8,ClassApiNameOffset=0x8,ClassApiMethodsStep=2,ClassApiCountMethods=0x9C,ClassApiMethodsLink=0x3C,ClassApiFieldsLink=0x30,ClassApiFieldsStep=0x18,ClassApiCountFields=0xA0,ClassApiParentOffset=0x24,ClassApiNameSpaceOffset=0xC,ClassApiStaticFieldDataOffset=0x50,ClassApiEnumType=0xB0,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=0x2C,ClassApiInstanceSize=0x78,ClassApiToken=0x98,MethodsApiClassOffset=0xC,MethodsApiNameOffset=0x8,MethodsApiParamCount=0x2E,MethodsApiReturnType=0x10,MethodsApiFlags=0x28,typeDefinitionsSize=0x70,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=0x6,Il2CppTypeDefinitionApifieldStart=0x38,MetadataRegistrationApitypes=0x1C},
            [21]={FieldApiOffset=0xC,FieldApiType=0x4,FieldApiClassOffset=0x8,ClassApiNameOffset=0x8,ClassApiMethodsStep=2,ClassApiCountMethods=0x9C,ClassApiMethodsLink=0x3C,ClassApiFieldsLink=0x30,ClassApiFieldsStep=0x18,ClassApiCountFields=0xA0,ClassApiParentOffset=0x24,ClassApiNameSpaceOffset=0xC,ClassApiStaticFieldDataOffset=0x50,ClassApiEnumType=0xB0,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=0x2C,ClassApiInstanceSize=0x78,ClassApiToken=0x98,MethodsApiClassOffset=0xC,MethodsApiNameOffset=0x8,MethodsApiParamCount=0x2E,MethodsApiReturnType=0x10,MethodsApiFlags=0x28,typeDefinitionsSize=0x78,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=0x6,Il2CppTypeDefinitionApifieldStart=0x40,MetadataRegistrationApitypes=0x1C},
            [22]={FieldApiOffset=0xC,FieldApiType=0x4,FieldApiClassOffset=0x8,ClassApiNameOffset=0x8,ClassApiMethodsStep=2,ClassApiCountMethods=0x94,ClassApiMethodsLink=0x3C,ClassApiFieldsLink=0x30,ClassApiFieldsStep=0x18,ClassApiCountFields=0x98,ClassApiParentOffset=0x24,ClassApiNameSpaceOffset=0xC,ClassApiStaticFieldDataOffset=0x4C,ClassApiEnumType=0xA9,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=0x2C,ClassApiInstanceSize=0x70,ClassApiToken=0x90,MethodsApiClassOffset=0xC,MethodsApiNameOffset=0x8,MethodsApiParamCount=0x2E,MethodsApiReturnType=0x10,MethodsApiFlags=0x28,typeDefinitionsSize=0x78,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=0x6,Il2CppTypeDefinitionApifieldStart=0x40,MetadataRegistrationApitypes=0x1C},
            [23]={FieldApiOffset=0xC,FieldApiType=0x4,FieldApiClassOffset=0x8,ClassApiNameOffset=0x8,ClassApiMethodsStep=2,ClassApiCountMethods=0x9C,ClassApiMethodsLink=0x40,ClassApiFieldsLink=0x34,ClassApiFieldsStep=0x18,ClassApiCountFields=0xA0,ClassApiParentOffset=0x24,ClassApiNameSpaceOffset=0xC,ClassApiStaticFieldDataOffset=0x50,ClassApiEnumType=0xB1,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=0x2C,ClassApiInstanceSize=0x78,ClassApiToken=0x98,MethodsApiClassOffset=0xC,MethodsApiNameOffset=0x8,MethodsApiParamCount=0x2E,MethodsApiReturnType=0x10,MethodsApiFlags=0x28,typeDefinitionsSize=104,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=0x6,Il2CppTypeDefinitionApifieldStart=0x30,MetadataRegistrationApitypes=0x1C},
            [24]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x114 or 0xAC,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x28 or 0x18,ClassApiCountFields=AndroidInfo.platform and 0x118 or 0xB0,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x129 or 0xC1,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF0 or 0x88,ClassApiToken=AndroidInfo.platform and 0x110 or 0xa8,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4E or 0x2E,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x48 or 0x28,typeDefinitionsSize=104,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x30,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [24.1]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x110 or 0xA8,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x114 or 0xAC,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x126 or 0xBE,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xEC or 0x84,ClassApiToken=AndroidInfo.platform and 0x10c or 0xa4,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=100,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x2C,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [24.2]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x118 or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x11c or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x12e or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF4 or 0x80,ClassApiToken=AndroidInfo.platform and 0x114 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=92,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x24,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [24.3]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x118 or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x11c or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x12e or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF4 or 0x80,ClassApiToken=AndroidInfo.platform and 0x114 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=92,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x24,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [24.4]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x118 or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x11c or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x12e or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF4 or 0x80,ClassApiToken=AndroidInfo.platform and 0x114 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=92,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x24,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [24.5]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x118 or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x11c or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x12e or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF4 or 0x80,ClassApiToken=AndroidInfo.platform and 0x114 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=92,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x24,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [27]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x11C or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x120 or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x132 or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF8 or 0x80,ClassApiToken=AndroidInfo.platform and 0x118 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=88,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x20,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [27.1]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x11C or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x120 or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x132 or 0xBA,ClassApiEnumRsh=3,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF8 or 0x80,ClassApiToken=AndroidInfo.platform and 0x118 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=88,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x20,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [27.2]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x11C or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x120 or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x132 or 0xBA,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF8 or 0x80,ClassApiToken=AndroidInfo.platform and 0x118 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,MethodsApiParamCount=AndroidInfo.platform and 0x4A or 0x2A,MethodsApiReturnType=AndroidInfo.platform and 0x20 or 0x10,MethodsApiFlags=AndroidInfo.platform and 0x44 or 0x24,typeDefinitionsSize=88,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x20,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
            [29]={FieldApiOffset=AndroidInfo.platform and 0x18 or 0xC,FieldApiType=AndroidInfo.platform and 0x8 or 0x4,FieldApiClassOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiNameOffset=AndroidInfo.platform and 0x10 or 0x8,ClassApiMethodsStep=AndroidInfo.platform and 3 or 2,ClassApiCountMethods=AndroidInfo.platform and 0x11C or 0xA4,ClassApiMethodsLink=AndroidInfo.platform and 0x98 or 0x4C,ClassApiFieldsLink=AndroidInfo.platform and 0x80 or 0x40,ClassApiFieldsStep=AndroidInfo.platform and 0x20 or 0x14,ClassApiCountFields=AndroidInfo.platform and 0x120 or 0xA8,ClassApiParentOffset=AndroidInfo.platform and 0x58 or 0x2C,ClassApiNameSpaceOffset=AndroidInfo.platform and 0x18 or 0xC,ClassApiStaticFieldDataOffset=AndroidInfo.platform and 0xB8 or 0x5C,ClassApiEnumType=AndroidInfo.platform and 0x132 or 0xBA,ClassApiEnumRsh=2,ClassApiTypeMetadataHandle=AndroidInfo.platform and 0x68 or 0x34,ClassApiInstanceSize=AndroidInfo.platform and 0xF8 or 0x80,ClassApiToken=AndroidInfo.platform and 0x118 or 0xa0,MethodsApiClassOffset=AndroidInfo.platform and 0x20 or 0x10,MethodsApiNameOffset=AndroidInfo.platform and 0x18 or 0xC,MethodsApiParamCount=AndroidInfo.platform and 0x52 or 0x2E,MethodsApiReturnType=AndroidInfo.platform and 0x28 or 0x14,MethodsApiFlags=AndroidInfo.platform and 0x4C or 0x28,typeDefinitionsSize=88,typeDefinitionsOffset=0xA0,stringOffset=0x18,fieldDefaultValuesOffset=0x40,fieldDefaultValuesSize=0x44,fieldAndParameterDefaultValueDataOffset=0x48,TypeApiType=AndroidInfo.platform and 0xA or 0x6,Il2CppTypeDefinitionApifieldStart=0x20,MetadataRegistrationApitypes=AndroidInfo.platform and 0x38 or 0x1C},
        }
        Il2CppFlags={
            Method={METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK=0x0007,Access={"private","internal","internal","protected","protected internal","public"},METHOD_ATTRIBUTE_STATIC=0x0010,METHOD_ATTRIBUTE_ABSTRACT=0x0400},
            Field={FIELD_ATTRIBUTE_FIELD_ACCESS_MASK=0x0007,Access={"private","internal","internal","protected","protected internal","public"},FIELD_ATTRIBUTE_STATIC=0x0010,FIELD_ATTRIBUTE_LITERAL=0x0040},
        }
    end)

    Il2cpp = __bundle_require("GGIl2cpp")
    Il2cpp()
end)

if not ok_il2cpp then
    gg.alert("⚠ Il2cpp init failed:\n" .. tostring(err_il2cpp) .. "\n\nMake sure the game is running!")
    os.exit()
end

gg.toast("Il2cpp ready ✓")

-- ============================================================
-- OPTION 1 — Single Address Manual Check
-- ============================================================
if mainChoice == 1 then
    gg.alert(
        "Single Address Checker\n\n" ..
        "Enter an absolute address from your log file.\n" ..
        "The game must still be running and loaded.\n\n" ..
        "Results are appended to 'offset_result.kinzi'\n" ..
        "in the same folder as your log file."
    )

    local savePath = gg.getFile("offset_result.kinzi")
    local save = io.open(savePath, "a")
    if not save then gg.alert("Cannot open save file!") os.exit() end

    writeSessionHeader(save, "Single Address Checker")
    local scanCount = 0

    while true do
        local input = gg.prompt(
            {"Absolute address (e.g. 0x7B281BD0E4)", "Scan range (e.g. 0x400)"},
            {"", "0x400"},
            {"text", "text"}
        )
        if not input then break end

        -- [FIX #7] tonumber already handles 0x prefix correctly
        local absolute = tonumber(input[1])
        local scanRange = tonumber(input[2]) or 0x400

        if not absolute then
            gg.alert("Invalid address! Use hex format: 0x7B281BD0E4")
        else
            local offset = absolute - lib_base
            local class, method, retType = findClassSafe(offset)
            local realStart, hookDistance = findRealHook(offset, lib_base, scanRange)

            scanCount = scanCount + 1
            local result =
                "SCAN #" .. scanCount .. "\n" ..
                "Time: " .. os.date("%H:%M:%S") .. "\n\n" ..
                "LIB ADDRESS:        0x" .. string.format("%X", lib_base) .. "\n" ..
                "LOG ADDRESS:        0x" .. string.format("%X", absolute) .. "\n" ..
                "SCRIPT OFFSET:      0x" .. string.format("%X", offset) .. "\n" ..
                "REAL FUNC START:    0x" .. string.format("%X", realStart) .. "\n" ..
                "HOOK DISTANCE:      0x" .. string.format("%X", hookDistance) .. "\n\n" ..
                "CLASS:  " .. class .. "\n" ..
                "METHOD: " .. method .. "\n" ..
                "TYPE:   " .. retType .. "\n\n" ..
                "----------------------------------------\n\n"

            save:write(result)
            save:flush()   -- [FIX #9]

            local action = gg.choice(
                {"🔁 Continue (New Address)", "🔙 Back to Main Menu", "❌ Exit Script"},
                nil, "✔ Saved — SCAN #" .. scanCount
            )
            if action == 1 then
                -- continue
            elseif action == 2 then
                save:close(); return
            else
                save:close(); os.exit()
            end
        end
    end
    save:close()
end

-- ============================================================
-- OPTION 2 — Batch: Logged Absolute Addresses
-- ============================================================
if mainChoice == 2 then
    gg.alert(
        "Batch Address Processor\n\n" ..
        "Select a log file containing absolute addresses.\n" ..
        "Format: any line containing 0x<hex address>\n\n" ..
        "The game must be running while processing.\n" ..
        "Output: 'offset_results.kinzi' next to the log file."
    )

    local fileInput = gg.prompt({"Select log file"}, {gg.getFile()}, {"file"})
    if not fileInput then os.exit() end

    local path = fileInput[1]
    local f = io.open(path, "r")
    if not f then gg.alert("Failed to open: " .. tostring(path)) os.exit() end

    local folder = path:match("(.*/)") or "./"
    local savePath = folder .. "offset_results.kinzi"
    local save = io.open(savePath, "w")
    if not save then f:close() gg.alert("Cannot write to: " .. savePath) os.exit() end

    writeSessionHeader(save, "Batch Address Processor")

    local count, seen = 0, {}

    for line in f:lines() do
        local addr = line:match("0x%x+")
        if addr then
            -- [FIX #7] No double-parse needed
            local absolute = tonumber(addr)
            -- [F] Deduplicate
            if absolute and absolute > lib_base and not seen[absolute] then
                seen[absolute] = true
                local offset = absolute - lib_base
                gg.toast("Processing #" .. (count+1) .. " → 0x" .. string.format("%X", offset))

                local class, method, retType = findClassSafe(offset)
                local realStart, hookDistance = findRealHook(offset, lib_base, 0x400)

                local result =
                    "LIB ADDRESS:        0x" .. string.format("%X", lib_base) .. "\n" ..
                    "LOG ADDRESS:        " .. addr .. "\n" ..
                    "SCRIPT OFFSET:      0x" .. string.format("%X", offset) .. "\n" ..
                    "REAL FUNC START:    0x" .. string.format("%X", realStart) .. "\n" ..
                    "HOOK DISTANCE:      0x" .. string.format("%X", hookDistance) .. "\n\n" ..
                    "CLASS:  " .. class .. "\n" ..
                    "METHOD: " .. method .. "\n" ..
                    "TYPE:   " .. retType .. "\n\n" ..
                    "----------------------------------------\n\n"

                save:write(result)
                save:flush()  -- [FIX #9]
                count = count + 1
            end
        end
    end

    f:close()
    save:close()
    gg.alert("✔ Done!\nConverted: " .. count .. "\nSaved to:\n" .. savePath)
end

-- ============================================================
-- OPTION 3 — Batch: Direct Offsets from File
-- ============================================================
if mainChoice == 3 then
    gg.alert(
        "Direct Offset Processor\n\n" ..
        "Select a file containing script offsets (e.g. 0x1BD0E4).\n" ..
        "Game must be running.\n" ..
        "Output: 'offset_results.kinzi' next to your file."
    )

    local fileInput = gg.prompt({"Select offset file"}, {gg.getFile()}, {"file"})
    if not fileInput then os.exit() end

    local path = fileInput[1]
    local f = io.open(path, "r")
    if not f then gg.alert("Failed to open: " .. tostring(path)) os.exit() end

    local folder = path:match("(.*/)") or "./"
    local savePath = folder .. "offset_results.kinzi"
    local save = io.open(savePath, "w")
    if not save then f:close() gg.alert("Cannot write output file.") os.exit() end

    writeSessionHeader(save, "Direct Offset Processor")

    local count, seen = 0, {}

    for line in f:lines() do
        local offsetHex = line:match("0x%x+")
        if offsetHex then
            local offset = tonumber(offsetHex)
            -- [FIX #8] Use larger upper limit for 64-bit targets
            local maxOffset = arch and 0x80000000 or 0x8000000
            if offset and offset > 0x10000 and offset <= maxOffset and not seen[offset] then
                seen[offset] = true
                gg.toast("Processing #" .. (count+1) .. " → " .. offsetHex)

                local class, method, retType = findClassSafe(offset)
                local realStart, hookDistance = findRealHook(offset, lib_base, 0x400)

                local result =
                    "OFFSET:             " .. offsetHex .. "\n" ..
                    "REAL FUNC START:    0x" .. string.format("%X", realStart) .. "\n" ..
                    "HOOK DISTANCE:      0x" .. string.format("%X", hookDistance) .. "\n\n" ..
                    "CLASS:  " .. class .. "\n" ..
                    "METHOD: " .. method .. "\n" ..
                    "TYPE:   " .. retType .. "\n\n" ..
                    "----------------------------------------\n\n"

                save:write(result)
                save:flush()  -- [FIX #9]
                count = count + 1
            end
        end
    end

    f:close()
    save:close()
    gg.alert("✔ Done!\nConverted: " .. count .. "\nSaved to:\n" .. savePath)
end

-- ============================================================
-- [NEW FEATURE A] OPTION 5 — Auto-Update Script Template
-- ============================================================
if mainChoice == 5 then
    gg.alert(
        "Auto-Update Script Template Generator\n\n" ..
        "This reads an 'offset_results.kinzi' file\n" ..
        "and generates a ready-to-use Lua patch script\n" ..
        "with all detected offsets pre-filled.\n\n" ..
        "The output is named 'generated_patch_<date>.lua'\n" ..
        "and placed next to the result file.\n\n" ..
        "You can then fill in the byte values manually."
    )

    local fileInput = gg.prompt({"Select offset_results.kinzi file"}, {gg.getFile()}, {"file"})
    if not fileInput then os.exit() end

    local path = fileInput[1]
    local f = io.open(path, "r")
    if not f then gg.alert("Cannot open file: " .. tostring(path)) os.exit() end

    -- Parse the result file
    local entries = {}
    local cur = {}
    for line in f:lines() do
        local off  = line:match("OFFSET:%s*(0x%x+)")
        local cls  = line:match("CLASS:%s*(.+)")
        local mth  = line:match("METHOD:%s*(.+)")
        local typ  = line:match("TYPE:%s*(.+)")
        local hook = line:match("HOOK DISTANCE:%s*(0x%x+)")
        if off  then cur.offset = off:match("^%s*(.-)%s*$") end
        if cls  then cur.class  = cls:match("^%s*(.-)%s*$") end
        if mth  then cur.method = mth:match("^%s*(.-)%s*$") end
        if typ  then cur.type   = typ:match("^%s*(.-)%s*$") end
        if hook then cur.hook   = hook:match("^%s*(.-)%s*$") end
        if line:match("^%-%-%-%-") and cur.offset then
            entries[#entries+1] = {
                offset = cur.offset,
                class  = cur.class  or "Unknown",
                method = cur.method or "Unknown",
                rettype= cur.type   or "Unknown",
                hook   = cur.hook   or "0x0",
            }
            cur = {}
        end
    end
    f:close()

    if #entries == 0 then
        gg.alert("No valid OFFSET entries found in the file.\nMake sure you use an offset_results.kinzi from Option 3.")
        os.exit()
    end

    local folder = path:match("(.*/)") or "./"
    local outName = folder .. "generated_patch_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    local out = io.open(outName, "w")
    if not out then gg.alert("Cannot create output file.") os.exit() end

    -- Write template header
    out:write("-- ==========================================================\n")
    out:write("-- AUTO-GENERATED PATCH SCRIPT\n")
    out:write("-- Generated by Kinzi Tools v" .. TOOL_VERSION .. " on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    out:write("-- Total entries: " .. #entries .. "\n")
    out:write("-- ==========================================================\n\n")
    out:write("local gg = gg\n\n")
    out:write("-- Get libil2cpp base\n")
    out:write("local ranges = gg.getRangesList('libil2cpp.so')\n")
    out:write("if not ranges or not ranges[2] then\n")
    out:write("    gg.alert('libil2cpp.so not found!')\n")
    out:write("    os.exit()\n")
    out:write("end\n")
    out:write("local lib_base = ranges[2].start\n\n")
    out:write("-- Patch definitions\n")
    out:write("-- Each entry: { offset, bytes (fill these in), description }\n")
    out:write("local patches = {\n")

    for _, e in ipairs(entries) do
        out:write("    -- " .. e.class .. "::" .. e.method .. " [" .. e.rettype .. "]\n")
        out:write("    -- Hook distance: " .. e.hook .. "\n")
        out:write("    { offset = " .. e.offset .. ", bytes = \"?? ?? ?? ??\", desc = \"" .. e.method .. "\" },\n\n")
    end

    out:write("}\n\n")
    out:write("-- Apply patches\n")
    out:write("for _, p in ipairs(patches) do\n")
    out:write("    if p.bytes ~= \"?? ?? ?? ??\" then\n")
    out:write("        local addr = lib_base + p.offset\n")
    out:write("        -- TODO: use gg.setValues or your preferred patch method\n")
    out:write("        gg.toast('Patched: ' .. p.desc .. ' @ 0x' .. string.format('%X', addr))\n")
    out:write("    end\n")
    out:write("end\n\n")
    out:write("gg.alert('Patch script ran. Fill in the byte values above.')\n")

    out:close()
    gg.alert("✔ Template generated!\n" .. #entries .. " entries written.\n\nFile:\n" .. outName)
end

-- ============================================================
-- [NEW FEATURE B] OPTION 6 — Batch Export to Lua Patch Table
-- ============================================================
if mainChoice == 6 then
    gg.alert(
        "Batch Export → Lua Patch Template\n\n" ..
        "Select a log file with absolute addresses.\n" ..
        "This option will:\n" ..
        "1. Calculate offsets from lib base\n" ..
        "2. Resolve Class::Method names\n" ..
        "3. Export a complete Lua patch table script\n\n" ..
        "Output: 'patch_table_<date>.lua'"
    )

    local fileInput = gg.prompt({"Select log file"}, {gg.getFile()}, {"file"})
    if not fileInput then os.exit() end

    local path = fileInput[1]
    local f = io.open(path, "r")
    if not f then gg.alert("Cannot open: " .. tostring(path)) os.exit() end

    local folder = path:match("(.*/)") or "./"
    local outName = folder .. "patch_table_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    local out = io.open(outName, "w")
    if not out then f:close() gg.alert("Cannot write output.") os.exit() end

    out:write("-- ==========================================================\n")
    out:write("-- PATCH TABLE — Kinzi Tools v" .. TOOL_VERSION .. "\n")
    out:write("-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    out:write("-- LIB BASE (at gen time): 0x" .. string.format("%X", lib_base) .. "\n")
    out:write("-- ==========================================================\n\n")
    out:write("local gg = gg\n")
    out:write("local ranges = gg.getRangesList('libil2cpp.so')\n")
    out:write("if not ranges or not ranges[2] then gg.alert('libil2cpp not found') os.exit() end\n")
    out:write("local base = ranges[2].start\n\n")
    out:write("local offsets = {\n")

    local count, seen = 0, {}
    for line in f:lines() do
        local addr = line:match("0x%x+")
        if addr then
            local absolute = tonumber(addr)
            if absolute and absolute > lib_base and not seen[absolute] then
                seen[absolute] = true
                local offset = absolute - lib_base
                gg.toast("Exporting #" .. (count+1))
                local class, method, retType = findClassSafe(offset)
                out:write(string.format(
                    "    { offset = 0x%X, class = %q, method = %q, rettype = %q },\n",
                    offset, class, method, retType
                ))
                out:flush()
                count = count + 1
            end
        end
    end

    f:close()

    out:write("}\n\n")
    out:write("for i, e in ipairs(offsets) do\n")
    out:write("    local addr = base + e.offset\n")
    out:write("    -- Add your patch logic here\n")
    out:write("    gg.toast(i .. ': ' .. e.class .. '::' .. e.method .. ' @ 0x' .. string.format('%X', addr))\n")
    out:write("end\n\n")
    out:write("gg.alert('Export complete. Total: " .. count .. "')\n")
    out:close()

    gg.alert("✔ Patch table exported!\n" .. count .. " entries.\n\nFile:\n" .. outName)
end
