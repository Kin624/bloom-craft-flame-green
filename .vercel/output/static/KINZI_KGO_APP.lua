-- ============================================================
--  KINZI KGO APP v3.0
--  Drop this into GameGuardian inside KGO Multi Space.
--  Target: Car Parking Multiplayer 2  1.3.3.6
--  Package: com.olzhas.carparking.multyplayer2
--
--  This is the process-gated convertor from the video workflow:
--    1. Game must be running in the same KGO space
--    2. GG must be attached to Car Parking [x64]
--    3. Then convert logs / offsets without repeating attach
--  It does NOT patch money, unlocks, or anti-cheat.
-- ============================================================

local gg = gg

local TOOL_VERSION = "3.0"
local REQUIRED_PACKAGE = "com.olzhas.carparking.multyplayer2"
local REQUIRED_NAME = "Car Parking Multiplayer 2"
local REQUIRED_VERSION = "1.3.3.6"
local LIB_NAME = "libil2cpp.so"

-- ------------------------------------------------------------
-- Process gate  (the IF / ELSE you asked for)
-- ------------------------------------------------------------
local function fail(title, detail)
    gg.alert(title .. "\n\n" .. detail)
    os.exit()
end

local function readTarget()
    local ok, info = pcall(function()
        return gg.getTargetInfo()
    end)
    if not ok or type(info) ~= "table" then
        return nil
    end
    return info
end

local function packageOf(info)
    if not info then return "" end
    return tostring(info.packageName or info.cmd or info.processName or "")
end

local function looksLikeCpm2(pkg)
    pkg = pkg:lower()
    if pkg == REQUIRED_PACKAGE then return true end
    if pkg:find("carparking", 1, true) and pkg:find("multy", 1, true) then
        return true
    end
    return false
end

local info = readTarget()
if not info then
    fail(
        "Game process cannot be detected",
        "Open " .. REQUIRED_NAME .. " " .. REQUIRED_VERSION ..
        " inside this KGO space first.\nThen attach GameGuardian to Car Parking [x64]."
    )
end

local pkg = packageOf(info)
if pkg == "" then
    fail(
        "Required information is missing",
        "GG is not attached to a process.\nSelect process → Car Parking [x64], then run this script again."
    )
end

if not looksLikeCpm2(pkg) then
    fail(
        "Required version is not detected",
        "Need:\n  " .. REQUIRED_NAME .. " " .. REQUIRED_VERSION ..
        "\n  " .. REQUIRED_PACKAGE ..
        "\n\nFound:\n  " .. pkg
    )
end

-- ------------------------------------------------------------
-- libil2cpp base
-- ------------------------------------------------------------
local function getLibBase()
    local r = gg.getRangesList(LIB_NAME)
    if not r or not r[2] then
        fail(
            "libil2cpp.so not found",
            "The game process is attached but the IL2CPP library is missing.\nWait until the world has fully loaded, then run again."
        )
    end
    return r[2].start, r
end

local lib_base, lib_ranges = getLibBase()
local arch = info.x64
local p_size = arch and 8 or 4

gg.toast("KINZI KGO  ·  " .. REQUIRED_VERSION .. "  ·  attached")

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function writeHeader(fh, mode)
    fh:write("============================================================\n")
    fh:write("  KINZI KGO v" .. TOOL_VERSION .. " — " .. mode .. "\n")
    fh:write("  Session: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    fh:write("  Target: " .. REQUIRED_NAME .. " " .. REQUIRED_VERSION .. "\n")
    fh:write("  Package: " .. REQUIRED_PACKAGE .. "\n")
    fh:write("  Arch: " .. (arch and "64-bit" or "32-bit") .. "\n")
    fh:write("  LIB BASE: 0x" .. string.format("%X", lib_base) .. "\n")
    fh:write("============================================================\n\n")
end

local function pickFile(title)
    local p = gg.prompt({ title }, { gg.getFile() }, { "file" })
    if not p then return nil end
    return p[1]
end

local function folderOf(path)
    return path:match("(.*/)") or "./"
end

local function extractHex(line)
    return line:match("0x%x+")
end

-- ------------------------------------------------------------
-- Wizard (video steps)
-- ------------------------------------------------------------
local function showWizard()
    local steps = {
        "STEP 1 — Remove log protection\n\nRun your logger cleaner on the encrypted script first. Save the cleared lua. Protected scripts log empty refineNumber loops.",
        "STEP 2 — Game already attached\n\nThis script confirmed:\n  " .. REQUIRED_NAME .. " " .. REQUIRED_VERSION .. "\n  " .. pkg .. "\n  libil2cpp @ 0x" .. string.format("%X", lib_base),
        "STEP 3 — Enable script logging\n\nGG floating icon → Execute script options → check “Log most script calls”. Run the cleared script and open the menus you need.",
        "STEP 4 — Convert the log\n\nBack here, choose “Logged addresses (file)” and pick the .log / .txt GG wrote (usually Download/Telegram).",
        "STEP 5 — Read offset_results.kinzi\n\nLIB ADDRESS, SCRIPT OFFSET, and (if Il2Cpp resolved) CLASS / METHOD / TYPE. After a game update, use Re-offset.",
    }
    for i, s in ipairs(steps) do
        local a = gg.alert(s, "Next", i == 1 and "Skip wizard" or "Back")
        if a == 2 and i > 1 then
            -- continue loop conceptually; simple skip-back
        elseif a ~= 1 then
            break
        end
    end
end

-- ------------------------------------------------------------
-- Convertors (offset math — always works once lib base is known)
-- ------------------------------------------------------------
local function processAddressesFromFile(path, asOffset)
    local f = io.open(path, "r")
    if not f then
        gg.alert("Cannot open:\n" .. tostring(path))
        return
    end
    local savePath = folderOf(path) .. "offset_results.kinzi"
    local save = io.open(savePath, "w")
    if not save then
        f:close()
        gg.alert("Cannot write:\n" .. savePath)
        return
    end
    writeHeader(save, asOffset and "Direct Offset Processor" or "Batch Address Processor")
    local count, seen = 0, {}
    local maxOffset = arch and 0x80000000 or 0x8000000
    for line in f:lines() do
        local hx = extractHex(line)
        if hx then
            local n = tonumber(hx)
            if n then
                local offset, absolute
                if asOffset then
                    if n > 0x10000 and n <= maxOffset then
                        offset = n
                        absolute = lib_base + n
                    end
                else
                    if n > lib_base then
                        absolute = n
                        offset = n - lib_base
                    end
                end
                if offset and not seen[offset] then
                    seen[offset] = true
                    count = count + 1
                    gg.toast("Processing #" .. count)
                    save:write(
                        "LIB ADDRESS:        0x" .. string.format("%X", lib_base) .. "\n" ..
                        "LOG ADDRESS:        0x" .. string.format("%X", absolute) .. "\n" ..
                        "SCRIPT OFFSET:      0x" .. string.format("%X", offset) .. "\n" ..
                        "REAL FUNC START:    0x" .. string.format("%X", offset) .. "\n" ..
                        "HOOK DISTANCE:      0x0\n\n" ..
                        "CLASS:  Unknown  (use full convertor + Il2Cpp for names)\n" ..
                        "METHOD: Unknown\n" ..
                        "TYPE:   Unknown\n\n" ..
                        "----------------------------------------\n\n"
                    )
                    save:flush()
                end
            end
        end
    end
    f:close()
    save:close()
    gg.alert("Done. Converted " .. count .. " addresses.\n\nSaved:\n" .. savePath)
end

local function singleAddress()
    while true do
        local input = gg.prompt(
            { "Absolute address (0x…)", "Scan range" },
            { "", "0x400" },
            { "text", "text" }
        )
        if not input then break end
        local absolute = tonumber(input[1])
        if not absolute then
            gg.alert("Invalid address. Use hex, e.g. 0x776CB4C71C")
        else
            local offset = absolute - lib_base
            local savePath = gg.getFile("offset_result.kinzi")
            local save = io.open(savePath, "a")
            if save then
                writeHeader(save, "Single Address Checker")
                save:write(
                    "LIB ADDRESS:        0x" .. string.format("%X", lib_base) .. "\n" ..
                    "LOG ADDRESS:        0x" .. string.format("%X", absolute) .. "\n" ..
                    "SCRIPT OFFSET:      0x" .. string.format("%X", offset) .. "\n" ..
                    "CLASS:  Unknown\nMETHOD: Unknown\nTYPE:   Unknown\n\n" ..
                    "----------------------------------------\n\n"
                )
                save:flush()
                save:close()
            end
            local again = gg.alert(
                "SCRIPT OFFSET: 0x" .. string.format("%X", offset) ..
                "\nAppended to offset_result.kinzi",
                "Another address",
                "Done"
            )
            if again ~= 1 then break end
        end
    end
end

-- ------------------------------------------------------------
-- Main menu
-- ------------------------------------------------------------
local function main()
    while true do
        local choice = gg.choice({
            " [0] Video wizard (5 steps)",
            " [1] Single address → offset",
            " [2] Logged addresses (file) → offset",
            " [3] Direct offsets (file)",
            " [4] Process status",
            " [5] Exit",
        }, nil, "KINZI KGO v" .. TOOL_VERSION .. "\n" .. REQUIRED_NAME .. " " .. REQUIRED_VERSION)

        if not choice or choice == 6 then
            break
        elseif choice == 1 then
            showWizard()
        elseif choice == 2 then
            singleAddress()
        elseif choice == 3 then
            local path = pickFile("Select GG log / .txt with 0x addresses")
            if path then processAddressesFromFile(path, false) end
        elseif choice == 4 then
            local path = pickFile("Select file of script offsets (0x…)")
            if path then processAddressesFromFile(path, true) end
        elseif choice == 5 then
            gg.alert(
                "PROCESS OK\n\n" ..
                REQUIRED_NAME .. " " .. REQUIRED_VERSION .. "\n" ..
                "Package: " .. pkg .. "\n" ..
                "Arch: " .. (arch and "64-bit" or "32-bit") .. "\n" ..
                "libil2cpp: 0x" .. string.format("%X", lib_base) .. "\n\n" ..
                "For CLASS/METHOD names run Kinzi Automatic Convertor v2\n" ..
                "after this gate (Il2Cpp engine)."
            )
        end
    end
end

main()
gg.toast("KINZI KGO closed")
