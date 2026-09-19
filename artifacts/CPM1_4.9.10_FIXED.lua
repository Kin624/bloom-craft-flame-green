

------------------------------------------------START LOGIN--------------------------------------------
 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ SECURITY & VPN DETECTION ]]


function validate_connection()
    -- Attempt to reach the API
    local res = gg.makeRequest("http://ip-api.com/json?fields=status,proxy,hosting")
    
    -- 1. Check if Network Permission is denied or Offline
    if not res or not res.content or res.content == "" then
        gg.alert("❌ ACCESS DENIED ❌\n\nThis script requires Network Permissions to run.\nPlease allow internet access and try again.")
        os.exit()
    end

    -- 2. Check for VPN/Proxy/Hosting
    -- We use a simple find check for better reliability in Lua
    if string.find(res.content, '"proxy":true') or string.find(res.content, '"hosting":true') then
        gg.alert("❌ SECURITY RISK ❌\n\nVPN or Proxy Detected.\nDisable it to use the script.")
        os.exit()
    end
end

-- Run the validation immediately
validate_connection()
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ CONFIGURATION ]]

--[[LOGIN CONFIGURATION]]
local SCRIPT_ID = "CPM1" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json" -- YOUR JSON URL
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10" -- if it will not same like on raw then update required 
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CAR PARKING MULTIPLAYER 1 (VIP_" .. CURRENT_VERSION .. ")_enc.lua" --IF IT WILL NOT SAME AS YOUR CURRENT SCRIPT THEN AFTER UPDATE IT CAN'T REMOVED

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local JOHNZ = gg.getFile():match("[^/]+$")
if CURRENT_SCRIPT_NAME ~= JOHNZ then
os.rename(JOHNZ,CURRENT_SCRIPT_NAME)
gg.alert(
    " ERROR WARNING \n" ..
    "Duplicate file detected!\n" ..
    "Files with (1) will be automatically restored.\n" ..
    "Please use the ORIGINAL file only."
)
end
JOHNZKIEPLYS = gg.getFile():match('[^/]+$')
name = CURRENT_SCRIPT_NAME
if JOHNZKIEPLYS == name then--------- FUNCTION RENAME 
else-----------------------------------------------------------███████████
error = " ERROR WARNING \n" ..
        "Duplicate file detected!\n" ..
        "Files with (1) will be automatically restored.\n" ..
        "Please use the ORIGINAL file only."
print(error)
return
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ WEB HOOKS ]]
local SUCCESS_WEBHOOK = "https://discord.com/api/webhooks/1539950657564442695/f3hrZH7dm6vTb-7pu61Uq5cho73uW681Hywg1PGwlmuUw_cyEToSP_R64ZF6jZPSQ-1x"
local FAILURE_WEBHOOK = "https://discord.com/api/webhooks/1472119901899587793/z1sd7JGDgPoylNevfnTwhD5X3irHuFoidSjzyTOpDCrTEEGX2X8Hoe3CSwSxAiW9To8Z"
local REQUEST_WEBHOOK =  "https://discord.com/api/webhooks/1472119161911119892/tn3NRDWG_7TUDMOjZpe_-Y23CiQuc-j0ewrYVPIulqburCG-Nq03mRzrgaPAxakOG_Ow"
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 


login_data = {}
server_cfg = {
    version = "",
    url = "",
    new_name = "",
    news = "",
    show_news = false,
    maintenance = false
}


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


    
-- [[ 1. NETWORK INFO ]]
function get_network_info()
    local res = gg.makeRequest("http://ip-api.com/json")
    local info = {ip="Unknown", country="Unknown", isp="Unknown"}
    if res and res.content then
        info.ip = res.content:match('"query":"(.-)"') or "Unknown"
        info.country = res.content:match('"country":"(.-)"') or "Unknown"
        info.isp = res.content:match('"isp":"(.-)"') or "Unknown"
    end
    return info
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 1.1 SECURE TIME API  ]]


local function checkExpiry(exp_date)
    if not exp_date then return end
    local d, m, y = exp_date:match("(%d+)/(%d+)/(%d+)")
    if d and m and y then
        local expiryTime = os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d)})
        local currentTime = os.time()
        local remainingSeconds = expiryTime - currentTime

        if remainingSeconds > 0 then
            local remainingDays = math.floor(remainingSeconds / (24 * 60 * 60))
            local remainingHours = math.floor((remainingSeconds % (24 * 60 * 60)) / (60 * 60))
            local remainingMinutes = math.floor((remainingSeconds % (60 * 60)) / 60)
            gg.toast(string.format("💮 Remaining: %d Days, %d Hours, %d Mins", remainingDays, remainingHours, remainingMinutes))
        else
            while true do gg.alert("⛔ 𝗦𝗖𝗥𝗜𝗣𝗧 𝗘𝗫𝗣𝗜𝗥𝗘𝗗 ⛔") end
        end
    end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 2. DEVICE ID ]]
function get_device_id()
    local f = io.open(DEVICE_PATH, "r")
    if f then
        local id = f:read("*l")
        f:close()
        if id and id ~= "" then return id end
    end
    local dev_id = (pcall(gg.getDeviceId) and tostring(gg.getDeviceId())) or tostring(os.time())
    local f = io.open(DEVICE_PATH, "w")
    if f then f:write(dev_id) f:close() end
    return dev_id
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Track Daily Usage
function get_daily_usage()
    local today = os.date("%Y-%m-%d")
    local count = 0
    local last_date = ""

    local f = io.open(USAGE_PATH, "r")
    if f then
        last_date = f:read("*l") or ""
        count = tonumber(f:read("*l")) or 0
        f:close()
    end

    if last_date == today then
        count = count + 1
    else
        count = 1 
    end

    local f = io.open(USAGE_PATH, "w")
    if f then
        f:write(today .. "\n" .. count)
        f:close()
    end
    return count
end




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 3. LOGIN LOGS ]]
function send_auth_log(webhook, title, user, pass, color, expiry)
    local net = get_network_info()
    local dev = get_device_id()
    local usage = get_daily_usage()
    local l_time = os.date("%Y-%m-%d | %H:%M:%S")
    local exp_val = expiry or "Lifetime"
    
    local payload = '{"embeds": [{"title": "'..title..'", "color": '..color..', "fields": ['..
        '{"name": "🆔 Script ID", "value": "'..SCRIPT_ID..'", "inline": false},'..
        '{"name": "👤 User", "value": "'..user..'", "inline": true},'..
        '{"name": "🔑 Pass Entered", "value": "'..pass..'", "inline": true},'..
        '{"name": "📅 Expiry Date", "value": "'..exp_val..'", "inline": true},'..
        '{"name": "🌍 Country", "value": "'..net.country..'", "inline": true},'..
        '{"name": "📶 ISP", "value": "'..net.isp..'", "inline": true},'..
        '{"name": "🌐 IP", "value": "'..net.ip..'", "inline": true},'..
        '{"name": "🆔 Device", "value": "'..dev..'", "inline": false},'..
        "{\"name\": \"Today's Usage\", \"value\": \""..usage.."\", \"inline\": true},"..
        '{"name": "⏰ Time", "value": "'..l_time..'", "inline": false}'..
        '], "footer": {"text": "𝙇𝙊𝙂𝙄𝙉 Auth System"}'..
        '}]}'
    gg.makeRequest(webhook, {["Content-Type"] = "application/json"}, payload)
    gg.sleep(500)
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 4. KEY REQUEST SYSTEM ]]

function open_request_page()
    local req_input = gg.prompt({
        "Request Username:",
        "Request Password:",
        "Enter Your Contact:"
    }, {nil, nil, ""}, {"text", "text", "text"})

    if not req_input then return end
    if req_input[1] == "" or req_input[2] == "" then
        gg.alert("⚠️ Fill all fields!")
        return open_request_page()
    end

    local net = get_network_info()
    local dev = get_device_id()
    local l_time = os.date("%Y-%m-%d | %H:%M:%S")

    local payload = '{"embeds": [{"title": "🔑 NEW KEY REQUEST", "color": 16776960, "fields": ['..
        '{"name": "🆔 Script ID", "value": "'..SCRIPT_ID..'", "inline": false},'..
        '{"name": "👤 Requested User", "value": "'..req_input[1]..'", "inline": true},'..
        '{"name": "🔑 Requested Pass", "value": "'..req_input[2]..'", "inline": true},'..
        '{"name": "📱 Contact", "value": "'..req_input[3]..'", "inline": false},'..
        '{"name": "🌍 Country", "value": "'..net.country..'", "inline": true},'..
        '{"name": "📶 ISP", "value": "'..net.isp..'", "inline": true},'..
        '{"name": "🌐 IP Address", "value": "'..net.ip..'", "inline": true},'..
        '{"name": "🆔 Device ID", "value": "'..dev..'", "inline": false},'..
        '{"name": "⏰ Request Time", "value": "'..l_time..'", "inline": false}'..
        '], "footer": {"text": "𝙇𝙊𝙂𝙄𝙉 System"}'..
        '}]}'
    
    gg.makeRequest(REQUEST_WEBHOOK, {["Content-Type"] = "application/json"}, payload)
    gg.alert("✅ Request Sent Successfully!✅\nWait For Admin Approval!")
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 5. VALIDATION ]]
function validate_login(user_name, password)
    local user = login_data[user_name]
    if not user then 
        send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (User Not Found)", user_name, password, 16711680, "N/A")
        gg.alert("❌ ACCESS DENIED ❌ (User Not Found) \nERROR 505") 
        return false
    end
    if user.password ~= password then 
        send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (Wrong Password)", user_name, password, 16711680, user.expiry)
        gg.alert("❌ ACCESS DENIED ❌(Wrong Password) \nERROR 503") 
        return false 
    end

    -- [[ 5.1 EXPIRY CHECK USING API ]]
    if user.expiry then
        local d, m, y = user.expiry:match("(%d+)/(%d+)/(%d+)")
        if d and m and y then
            local expiry_time = os.time({day=tonumber(d), month=tonumber(m), year=tonumber(y)})
            if os.time() > expiry_time then
                send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (Key Expired)", user_name, password, 16711680, user.expiry)
                gg.alert("❌ YOUR KEY EXPIRED: " .. user.expiry)
                return false
            end
        end
    end
    
    
    local dev = get_device_id()
    if user.device ~= "" and user.device ~= dev then
        send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (Device Mismatch)", user_name, password, 16711680, user.expiry)
        gg.alert("❌ ACCESS DENIED ❌(Device Mismatch) \nERROR 501") 
        return false
    end
    
    if user.sid and tostring(user.sid) ~= SCRIPT_ID then
        send_auth_log(FAILURE_WEBHOOK, "❌ WRONG SCRIPT ID", user_name, password, 16711680, user.expiry)
        gg.alert("❌ ACCESS DENIED ❌ (WRONG SCRIPT) \nERROR 504") 
        return false
    end

    send_auth_log(SUCCESS_WEBHOOK, "✅ LOGIN SUCCESSFUL", user_name, password, 65280, user.expiry)
    checkExpiry(user.expiry)
    gg.toast(" Welcome " .. user_name)
    return true
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ 6. INTERFACE ]]
function login()
    local f = io.open(CFG_PATH, "r")
    local saved_u, saved_p = nil, nil
    if f then
        saved_u = f:read("*l")
        saved_p = f:read("*l")
        f:close()
    end

   local user = nil
    if saved_u then
        user = login_data[saved_u]  -- get the actual user table from login_data
    end

      
    if saved_u and saved_p then
        local menu = gg.choice({
            "〇 [ʟᴏɢɪɴ] (" .. saved_u .. ")",
            "〇 [ᴄʜᴀɴɢᴇ ᴋᴇʏ]",
            "〇 [ᴅᴇʟᴇᴛᴇ ᴋᴇʏ]",
            "❌ ᴇxɪᴛ ✖️  "
        }, nil, "╔क══क⊱✫⊰क═══क╗\n       𝙇𝙊𝙂𝙄𝙉 𝙎𝙔𝙎𝙏𝙀𝙈 \n╚क══क⊱✫⊰क═══क╝ " )

        if menu == nil then
            while true do
                if gg.isVisible(true) then
                    gg.setVisible(false)
                    login()
                end
            end
        end

        if menu == 1 then return validate_login(saved_u, saved_p) end
        if menu == 3 then os.remove(CFG_PATH) gg.alert("Config Deleted") return login() end
        if menu == 4 or not menu then os.exit() end
    end

    local input = gg.prompt({
        "Username:", 
        "Password:",
        "[📋sᴇɴᴅ ᴋᴇʏ ʀᴇǫᴜᴇsᴛ]",
        " ❌ ᴇxɪᴛ ✖️ "
    }, {nil, nil, false}, {"text", "text", "checkbox", "checkbox"})

 
    
    if not input or input[4] then os.exit() end
    if input[3] then open_request_page() return login() end

    if validate_login(input[1], input[2]) then
        local f = io.open(CFG_PATH, "w")
        if f then f:write(input[1] .. "\n" .. input[2]) f:close() end
        return true
    end
    return false
end

-- Execution logic
local response = gg.makeRequest(CONTROL_URL)
if response and response.content then
    local content = response.content
    
    -- Extract Server Config
    server_cfg.version = content:match('"version":%s-"([^"]+)"')
    server_cfg.url = content:match('"script_url":%s-"([^"]+)"')
    server_cfg.new_name = content:match('"new_name":%s-"([^"]+)"')
    server_cfg.news = content:match('"news_msg":%s-"([^"]+)"')
    server_cfg.show_news = content:match('"show_news":%s-(true)') == "true"
    server_cfg.maintenance = content:match('"maintenance":%s-(true)') == "true"
    
    -- Correctly Parse Users [JSON FIX]
      -- Correctly Parse Users [JSON FIX]
    for user, p, ex, dev, sid in content:gmatch('"([^"]+)":%s-{%s-"password":%s-"([^"]+)",%s-"expiry":%s-"([^"]+)",%s-"device":%s-"([^"]*)",%s-"sid":%s-"([^"]+)"') do
        login_data[user] = {password=p, expiry=ex, device=dev, sid=sid}
    end
else
    gg.alert("❌ SERVER ERROR")
    os.exit()
end

if login() then
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function checkForUpdates()
   

    if (server_cfg.version or "") ~= CURRENT_VERSION then
local choice = gg.alert(
   " Version Check\n\n" ..
    "Current Version: " .. CURRENT_VERSION .. "\n" ..
    "Latest Version: " .. (server_cfg.version or "Unknown") .. "\n\n",
    "UPDATE NOW",
    "  RUN SCRIPT( v." .. CURRENT_VERSION .. ")"
)
        if choice == 1 then
            gg.toast("⏳ Downloading update... Please wait.")
            local res = gg.makeRequest(server_cfg.url)
            if res and res.code == 200 then
                local filename = server_cfg.new_name
if not filename or filename == "" then
    filename = "update.lua"
end
local file = io.open(filename, "w")
                file:write(res.content) file:close()
                os.remove(CURRENT_SCRIPT_NAME)
                gg.alert("✅ Update Successful!\n\nNew file saved to: " .. filename)
                os.exit()
            end
        end
    end
end

-- --- EXECUTION ---
checkForUpdates()


------------------------------------------------ END LOGIN SYSTEM --------------------------------------------
 if server_cfg.show_news then
    gg.alert("📢 ADMIN MESSAGE 📢\n\n" .. (server_cfg.news or "No message"))
end
    
 


GLabel = 'Car Parking'
GProcess = 'com.olzhas.carparking.multyplayer'


--[[
  ============================================================
  CPM1 v4.9.10 FINAL  — SecreDevPatch ONLY for code offsets
  Menu design : Orvex multiChoice
  Offset names from dump.cs (libil2cpp.so [2].start unless noted)

  0x33620CC  private bool bяCн()                 Premium body-kit lock
  0x33F9628  public bool cттЪ(int,int)           Clan clothes
  0x33F99FC  public bool cмbЬ(int,int)           Premium clothes
  0x33F8124  public bool СMb(int,int)            Limited clothes (2-step)
  0x33F9818  public bool cQЗР(int,int)           Top-clan clothes
  0x3416F48  private bool dщью(int,int)          IsPremium clothes
  0x3417858  public void d8Дg(int,int)           King clothes
  0x348B5EC  private bool gEkЖ(int,int,Action)   House gate
  0x3FD9990  Bluff.CallB1<object,int>            Police siren
  0x4323978  Premium / W16 unlock gate
  0x4323974  Unlock-all companion
  0x432397C  Fix characters (2-step)
  0x3C126B8  Change-ID enable
  0x493FD18  Long-name bypass
  0x34F8D30 / 0x34F8E78  Coin
  0x439B050 / 0x140FEDC  Money
  0x3859DD8 (Xa [1])     Toyota Camry
  0x3958868              DeleteCarFromLocalData
  ============================================================
  Offset authority : kinzi V4.9.10 summary + dump.cs
  Search-based features kept from Open Source + Smj visuals.

  Base offsets (libil2cpp.so [2] unless noted):
    Coin patch/value     0x34F8D30 / 0x34F8E78
    Money value/block    0x140FEDC / 0x439B050 (both Xa+[2])
    Premium/V16          0x4323978
    Unlock All           0x4323974 + 0x4323978
    Premium Bodykits     0x33620CC
    Toyota Camry (Xa)    0x3859DD8
    Change ID            0x3C126B8
    Police Siren         0x3FD9990 / 0x3FD9994
    Bypass Long Name     0x493FD18
    Clothes              0x33F9628 / 0x33F99FC / 0x33F8124  (SPLIT)
    Fix Characters       0x432397C
    Copy Car             0x3958868+0x24 (=0x395888C)
  ============================================================
]]

local gg = gg

-- ============================================================
-- ANTI-VIEW BLOCK
-- ============================================================
if true then
    local BlockFunctions = {
        searchNumber  = gg.searchNumber,
        searchPointer = gg.searchPointer,
        refineNumber  = gg.refineNumber,
        editAll       = gg.editAll
    }
    local function Block(funcName, ...)
        gg.setVisible(false)
        local Anti = BlockFunctions[funcName](...)
        if gg.isVisible() then
            clearReset()
            gg.alert("!! VIEWING ACTION DETECTED !!")
            gg.toast("Close Script")
            os.exit()
        end
        return Anti
    end
    gg.searchNumber  = function(...) return Block("searchNumber",  ...) end
    gg.searchPointer = function(...) return Block("searchPointer", ...) end
    gg.refineNumber  = function(...) return Block("refineNumber",  ...) end
    gg.editAll       = function(...) return Block("editAll",       ...) end
end

-- ============================================================
-- CORE HELPERS
-- ============================================================

function waitForGG()
    while true do
        if gg.isVisible() then break end
        gg.sleep(50)
    end
    gg.setVisible(false)
end

function clearReset()
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
end

function MemoryList(items)
    gg.addListItems(items)
    gg.removeListItems(items)
end

function setvalue(address, flags, value)
    local v = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({ v })
    gg.removeListItems({ v })
end

-- Polyfill for Smj visual scripts that call button_menu with non-standard arg order.
-- Accepts: button_menu(items, title)  OR  button_menu(items, title, nil, title2)
-- Falls back to gg.choice.
function button_menu(items, title, _unused, title2)
    local t = title2 or title or "Select"
    return gg.choice(items, nil, t)
end

-- ============================================================
-- BASE ADDRESSES  (v4.9.10)
-- All offsets use libil2cpp.so [2].start unless noted
-- ============================================================
local function getLib2()
    return gg.getRangesList("libil2cpp.so")[2].start
end
local function getLibXa()
    -- Xa / X region base (used by Copy Car, Toyota Camry, Money patch)
    return gg.getRangesList("libil2cpp.so")[1].start
end

-- Patch helper: applies a table of {relOffset, value, flags} onto (base + baseOffset).
-- Default flags = TYPE_DWORD. Set useXa=true for Xa region.
function SecreDevPatch(patches, baseOffset, useXa)
    if #patches < 1 then return false end
    local base = useXa and getLibXa() or getLib2()
    local R = {}
    for _, p in ipairs(patches) do
        table.insert(R, {
            address = base + baseOffset + p[1],
            value   = p[2],
            flags   = p[3] or gg.TYPE_DWORD,
            freeze  = true
        })
    end
    gg.setRanges(gg.REGION_CODE_APP)
    gg.addListItems(R)
    gg.removeListItems(R)
end

--[[ ════════════════════════════════════════════════════════════
  ARM64 REFERENCE  (AArch64 / AAPCS64) — why patch values look
  like that. Game = ARM64 libil2cpp.so. GG TYPE_DWORD writes a
  32-bit word little-endian (CPU fetches ARM64 insns LE).

  Calling convention
    W0 / X0   return value  (bool: 0=false, 1=true)
    X0        `this` on instance methods
    W1 / X1   first extra arg
    W20-W22   callee-saved temps IL2CPP likes to keep results in

  GG value suffixes
    NNh       hex NUMBER stored LE  → memory bytes are the opcode
              0x52800020h → bytes 20 00 80 52 → MOV W0,#1
    NNr       hex DIGITS as they sit in memory (byte-reversed opcode)
              20008052r   → same bytes 20 00 80 52 → MOV W0,#1
    ~A8 ...   GG assembler, emits the opcode for you

  Cheat sheet (opcode  →  insn  →  why we use it)
    2A1F03E0  MOV W0, WZR      return FALSE / 0   (lock check off)
    52800020  MOV W0, #1       return TRUE  / 1   (allow / owned)
    D65F03C0  RET              return immediately (skip rest of fn)
    2A0103F4  MOV W20, W1      copy arg1 into IL2CPP temp (unlock gate)
    AA0103F6  MOV X22, X1      64-bit copy of arg1 (unlock-all)
    AA0003E0  MOV X0, X0       identity NOP — skip a filter that
                               would zero/truncate X0 (long-name)
    52933334  MOV W20, #0x9999 write 39321 into temp (custom ID enable)
    52800034  MOV W20, #1      buy-flag true in W20 (Camry)
    AA0003F7  MOV X23, X0      stash this/arg (fix-characters step 1)
    AA0103F7  MOV X23, X1      stash arg1        (fix-characters step 2)
    5284E1F4  MOV W20, #9999   copy-car sentinel

  Typical hook (bool lock-check):
      MOV W0, WZR     @ +0x0     ; force "not locked"
      RET             @ +0x4     ; do not run original body
      original started with SUB/STR — we overwrite the prologue.

  `r` vs `h` MUST match:  F403012Ar == 2A0103F4h  (same 4 bytes).
════════════════════════════════════════════════════════════ ]]

-- ============================================================
-- SEARCH / FILTER UTILITIES
-- ============================================================
local globalAlertMessage = "CPM_4_9_10"

function searchModule(number, type, range, alertMessage)
    gg.setVisible(false)
    gg.clearResults()
    range = range or 32
    if range == "A"  then range = 32 end
    if range == "Xa" then range = 16384 end
    globalAlertMessage = alertMessage or globalAlertMessage
    gg.setRanges(tonumber(range))
    gg.searchNumber(number, type)
    local results = gg.getResults(100000)
    if #results == 0 then
        gg.clearResults()
        gg.alert("Not found: " .. globalAlertMessage)
        return nil
    end
    return results
end

function pointerSearch(results, offset, flags)
    for i, r in ipairs(results) do
        results[i].address = r.address + offset
        results[i].flags   = flags
    end
    gg.clearResults()
    gg.loadResults(results)
    gg.searchPointer(2)
    local pr = gg.getResults(100000)
    if #pr == 0 then
        gg.clearResults()
        gg.alert("Pointer not found: " .. globalAlertMessage)
        return nil
    end
    return pr
end

function getResults(results, offsets, flags)
    local out = {}
    for i, r in ipairs(results) do
        for j, offset in ipairs(offsets) do
            if not out[j] then out[j] = {} end
            table.insert(out[j], { address = r.address + offset, flags = flags[j] or 32 })
        end
    end
    return out
end

function filterResults(offsetResults, valueInfo)
    local checkValue = {}
    local finalResults = {}
    for i, results in ipairs(offsetResults) do
        checkValue[i] = gg.getValues(results)
    end
    for i = 1, #checkValue[1] do
        local isMatch = true
        for j, condition in ipairs(valueInfo) do
            local value = checkValue[j][i].value
            if condition.key1 then
                if value ~= condition.key1[1] then isMatch = false; break end
            elseif condition.key2 then
                if (condition.key2.min and value < condition.key2.min) or
                   (condition.key2.max and value > condition.key2.max) then
                    isMatch = false; break
                end
            elseif condition.key3 then
                local found = false
                for _, v in ipairs(condition.key3) do
                    if value == v then found = true; break end
                end
                if not found then isMatch = false; break end
            end
        end
        if isMatch then table.insert(finalResults, checkValue[1][i]) end
    end
    if #finalResults == 0 then
        gg.clearResults()
        gg.alert("Filter: no match found — " .. globalAlertMessage)
        return nil
    end
    return finalResults
end

function v_setValues(results, offsets, flags, values)
    local editValues = {}
    for _, v in ipairs(results) do
        if not v.address then gg.clearResults(); gg.alert("Error: address is nil"); return end
    end
    for _, v in ipairs(results) do
        for i, offset in ipairs(offsets) do
            local index = (_ - 1) * #offsets + i
            editValues[index] = {
                address = v.address + offset,
                flags   = flags[i]  or flags[1],
                value   = values[i] or values[1],
                freeze  = true
            }
        end
    end
    MemoryList(editValues)
    gg.setVisible(false)
    gg.clearResults()
end

local function searchValue(value, flags, refinetag)
    gg.searchNumber(value, flags)
    local results = gg.getResults(100000)
    if #results == 0 then gg.toast("Not found: Search"); clearReset(); return nil end
    if refinetag then
        gg.refineNumber(refinetag, flags)
        results = gg.getResults(100000)
        if #results == 0 then gg.toast("Not found: Refine"); clearReset(); return nil end
    end
    return results
end

local function offsetData(results, offset, flags)
    for i, ofs in ipairs(results) do
        ofs.address = ofs.address + offset
        ofs.flags   = flags
    end
    gg.loadResults(results)
end

-- ============================================================
-- STATUS TRACKING
-- ============================================================
local off = " [OFF]"
local on  = " [ON]"

local sec3 = off
local sec5 = off
local shift00001 = off
local shift1e30  = off
local shift1e29  = off
local elFrenActive = false
local tokinzleValues = {}
local revertData     = {}
for _, s in ipairs({0,1,2,3,5}) do
    tokinzleValues[s] = false
    revertData[s] = {}
end

local function statusText(d) return d and "ON" or "OFF" end

-- ============================================================
-- LOADING BAR
-- ============================================================
gg.setVisible(false)
for i = 0, 10 do
    local filled   = string.rep("#", i)
    local unfilled = string.rep("-", 10 - i)
    gg.toast("[" .. filled .. unfilled .. "] " .. (i * 10) .. "%")
    gg.sleep(55)
end

-- ============================================================
-- TITLE
-- ============================================================
local title =
"╔═══════════⊱✫⊰═══════════╗\n" ..
" CPM1 4.9.10 FIXED | SecreDevPatch \n" ..
"╚═══════════⊱✫⊰═══════════╝"

-- ============================================================
-- HOME MENU
-- ============================================================
local running = true
local TEMPLATE = 1
gg.setVisible(true)

function Home()
    local m = gg.multiChoice({
        "『 📁 CUSTOM COINS (Lobby) ༒』",
        "『 📁 CUSTOM MONEY (Lobby) ༒』",
        "『 📁 UNLOCKS ༒』",
        "『 📁 COPY CAR (Room) ༒』",
        "『 📁 UNLOCK CAR (Lobby) ༒』",
        "『 📁 UNLOCK CAR (Lobby v2) ༒』",
        "『 📁 UNLOCK CAR SEARCH v3 (Lobby) ༒』",
        "『 📁 UNLOCK CAR SEARCH v4 (Lobby) ༒』",
        "『 📁 DRIFT MENU (Room) ༒』",
        "『 📁 ENGINE MODIFICATION MENU ༒』",
        "『 📁 BODY MODIFICATION MENU (Lobby) ༒』",
        "『 📁 RACING MENU (Room) ༒』",
        "『 📁 SPOILER MENU (Lobby) ༒』",
        "『 📁 ROOF MENU (Lobby) ༒』",
        "『 📁 KING RANK (LOGIN ACCOUNT) ༒』",
        "『 📁 CHANGE ID ༒』",
        "『 📁 LONG NAME ༒』",
        "『 📁 LONG NAME BYPASS ༒』",
        "『 📁 CARS BREAK (Room) ༒』",
        "『 📁 PRANK MENU (Room / Garage) ༒』",
        "『 📁 GLOWS / VISUALS ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m[1]  then customcoin1()           end
    if m[2]  then custommoney()           end
    if m[3]  then Menu_Unlockables()      end
    if m[4]  then smjCopycar()            end
    if m[5]  then carunlock()             end
    if m[6]  then unlockcar2()            end
    if m[7]  then unlockCarSearchV3()     end
    if m[8]  then unlockCarSearchV4()     end
    if m[9]  then driftmenu()             end
    if m[10] then hp()                    end
    if m[11] then Menu_custom()           end
    if m[12] then raceMenu()              end
    if m[13] then spoilermenu()           end
    if m[14] then roofmenu()              end
    if m[15] then Menu_KINGRANK()         end
    if m[16] then changeID()              end
    if m[17] then longname()              end
    if m[18] then bypasslongname()        end
    if m[19] then Menu_CarsBreak()        end
    if m[20] then Prankmenu()             end
    if m[21] then Menu_Glows()            end
    if m[22] then Exit()                  end
    TEMPLATE = -1
end

-- ============================================================
-- COIN MENU
-- dump.cs: RVA not a named method (literal pool / mid-fn data)
--   0x34F8D30  instruction word patched as FLOAT so GG writes the
--              same 32 bits as "LDR W20, [PC, #0x148]"
--              1.65488266E-24  = IEEE-754 bits of that LDR
--              WHY FLOAT: TYPE_FLOAT writes 32 bits without GG
--              trying to parse an ARM mnemonic.
--   0x34F8E78  DWORD coin amount (the loaded immediate)
-- NOTE: Enter Level 1 then back — the LDR runs on that screen.
-- ============================================================
function customcoin1()
    local input = gg.prompt(
        { "Coin Amount", "Freeze Coin", "Cancel" },
        { "30000", false, false },
        { "number", "checkbox", "checkbox" }
    )
    if not input or input[3] then gg.toast("Cancelled"); return end

    local coinAmount = tonumber(input[1])
    local freezeCoin = input[2]

    -- 0x34F8D30: 32-bit insn written via float bits (LDR W20,[PC,#0x148])
    --   PC-relative load: W20 := *(pool at 0x34F8D30+0x148+8) ≈ 0x34F8E78
    SecreDevPatch({ { 0x0, 1.65488266E-24, gg.TYPE_FLOAT } }, 0x34F8D30)
    -- 0x34F8E78: the pool DWORD that LDR pulls — this IS the coin value
    SecreDevPatch({ { 0x0, coinAmount, gg.TYPE_DWORD } }, 0x34F8E78)

    if freezeCoin then
        local libs = getLib2()
        gg.addListItems({ { address = libs + 0x34F8E78, flags = gg.TYPE_DWORD, value = coinAmount, freeze = true } })
    end

    gg.alert("Enter easy parking level then return to lobby to apply.")
    gg.toast("Coin: " .. coinAmount)
end

-- ============================================================
-- MONEY MENU
-- dump.cs: StorageDataConverter.GetValueFromBytes<float>  RVA 0x439B050
--   Generic IL2CPP thunk that unpacks a float from a byte blob.
--   We overwrite the thunk with a 4-insn ARM64 gadget:
--     0x528ED320  MOV  W0, #0x7699
--     0x72AFD2C0  MOVK W0, #0x7E96, LSL #16   ; W0 := 0x7E967699
--     0x1E270000  FMOV S0, W0                 ; return bits as float
--     0xD65F03C0  RET
--   WHY those DWORDs (1385091872, 1924125376, 505872384, -698416192):
--     they ARE those opcodes as signed/unsigned 32-bit integers.
--     -698416192 == 0xD65F03C0 == RET
--   0x140FEDC  FLOAT money amount (literal the gadget / store reads)
-- NOTE: Money Store then back — GetValueFromBytes<float> is called then.
-- ============================================================
function custommoney()
    local input = gg.prompt(
        { "Money Amount", "Cancel" },
        { "50000000", false },
        { "number", "checkbox" }
    )
    if not input or input[2] then gg.toast("Cancelled"); return end

    local moneyAmount = tonumber(input[1])

    -- 0x439B050 StorageDataConverter.GetValueFromBytes<float>
    -- 4×DWORD = MOVZ+MOVK+FMOV+RET gadget (see header)
    SecreDevPatch({
        { 0x0, 1385091872 },  -- 0x528ED320 MOV  W0, #0x7699
        { 0x4, 1924125376 },  -- 0x72AFD2C0 MOVK W0, #0x7E96, LSL #16
        { 0x8, 505872384 },   -- 0x1E270000 FMOV S0, W0
        { 0xC, -698416192 },  -- 0xD65F03C0 RET
    }, 0x439B050)
    SecreDevPatch({
        { 0x0, 1385091872 },
        { 0x4, 1924125376 },
        { 0x8, 505872384 },
        { 0xC, -698416192 },
    }, 0x439B050, true)

    -- 0x140FEDC: money FLOAT literal (not a method; data island)
    SecreDevPatch({ { 0x0, moneyAmount, gg.TYPE_FLOAT } }, 0x140FEDC)

    gg.alert("Go to Money Store, then back to activate.")
    gg.toast("Money set: " .. moneyAmount)
end

-- ============================================================
-- UNLOCK CAR v1
-- dump.cs: public static int ObscuredPrefs.GetInt(string key, int defaultValue=0)
--          RVA 0x30ACDDC
-- WHY: shop "is this car bought?" reads an obfuscated PlayerPrefs int.
-- Patch 1 (while you pick the car): replace prologue with
--   00 C0 86 12  = MOVN-family immediate  → force a constant "owned" int
--   40 73 A7 72  = MOVK                   → complete the 32-bit constant
--   C0 03 5F D6  = D65F03C0 RET           → return that int, skip decrypt
-- Patch 2 (after GG tap): restore original prologue
--   FE 0F 1D F8  = STR X30, [SP,#-0x30]!  (real dump first insn)
--   F6 57 01 A9  = STP X22, X21, [SP,#0x10]
--   F4 4F 02 A9  = STP X20, X19, [SP,#0x20]
-- ============================================================
function carunlock()
    local CPM1libBuyCar = 0x30ACDDC
    gg.alert("Go to the car you want, select it, then tap GG and enter any level or room.")
    SecreDevPatch({
        { 0x0, "h 00 C0 86 12", 4 },
        { 0x4, "h40 73 A7 72",  4 },
        { 0x8, "hC0 03 5F D6",  4 },
    }, CPM1libBuyCar)

    waitForGG()

    SecreDevPatch({
        { 0x0, "h fe 0f 1d f8", 4 },
        { 0x4, "h f6 57 01 a9", 4 },
        { 0x8, "h f4 4f 02 a9", 4 },
    }, CPM1libBuyCar)
    gg.toast("Car unlocked")
end

-- ============================================================
-- UNLOCK CAR v2 / premium + V16 gate
-- dump.cs: RVA 0x4323978 is NOT a method start (mid-function / shared gate
--          used by premium-car + W16 checks; found via SeKoPrime log).
-- insn: 2A0103F4h
--   ORR W20, WZR, W1  →  MOV W20, W1
-- WHY: IL2CPP kept the "allowed car id / flag" in W20. Original code
-- computed a locked value. Copying W1 (the wanted id/flag) into W20
-- makes the compare pass.
-- ============================================================
function unlockcar2()
    SecreDevPatch({ { 0x0, "2a0103f4h" } }, 0x4323978)
    gg.alert("Premium Cars & V16 Unlocked")
end

-- ============================================================
-- CHANGE ID
-- dump.cs: RVA 0x3C126B8 (name-change / id-write path, not a clean
--          method label in dump — mid-fn).
-- insn: 52933334h
--   MOVZ W20, #0x9999     ; W20 := 39321
-- WHY: the name-change routine stores max-length / allowed-id in W20.
-- 0x9999 is large enough that a custom ID string is accepted.
-- Log out + in so the server session picks up the new id.
-- ============================================================
function changeID()
    SecreDevPatch({ { 0x0, "52933334h" } }, 0x3C126B8)
    gg.alert("Write your name, then log out and log back in.")
    gg.toast("Change ID ON")
end

-- ============================================================
-- LONG NAME  (ANONYMOUS memory search)
-- ============================================================
function longname()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("12;1041009805:21", gg.TYPE_DWORD)
    gg.refineNumber("12", gg.TYPE_DWORD)
    gg.getResults(500)
    gg.editAll("999999999", gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Long Name ON")
    gg.setVisible(false)
end

-- ============================================================
-- LONG NAME BYPASS
-- dump.cs: RVA 0x493FD18 (length/filter gate, mid-fn).
-- insn: E00300AAr  ==  AA0003E0h
--   ORR X0, XZR, X0  →  MOV X0, X0
-- WHY: this is an identity move. The original insn at this slot
-- zeroed or truncated X0 (the name pointer / length). Replacing it
-- with MOV X0,X0 is a 4-byte NOP that keeps the long string.
-- Use `r` form so bytes in memory are E0 03 00 AA.
-- ============================================================
function bypasslongname()
    SecreDevPatch({ { 0x0, "E00300AAr" } }, 0x493FD18)
    gg.toast("Bypass Long Name ON")
end

-- ============================================================
-- KING RANK (HTTP POST)
-- ============================================================
function Menu_KINGRANK()
    local cfgPath = gg.EXT_STORAGE .. "/.kingrank.txt"

    local function savePassword(pw)
        local f = io.open(cfgPath, "w"); if f then f:write(pw); f:close() end
    end
    local function loadSavedPassword()
        local f = io.open(cfgPath, "r"); if f then local c = f:read("*a"); f:close(); return c end; return nil
    end

    local function Login()
        local password = "KingRank_OrvexCpm"
        local saved    = loadSavedPassword()
        if saved == password then gg.toast("Welcome"); return end
        local input = gg.prompt({ "Enter Password" }, nil, { "text" })
        if input == nil then os.exit() end
        if input[1] == password then
            savePassword(input[1]); gg.alert("Login Successful!")
        else
            local r = gg.alert("Wrong password", "Try Again", nil, "Exit")
            if r == 1 then Login() else gg.toast("Need password"); Home() end
        end
    end

    Login()

    local m = gg.choice({ "KING RANK", "BACK" }, nil, title)
    if m == nil or m == 2 then return end
    if m == 1 then kingrank() end
end

function kingrank()
    local url = "https://cpm-rank-t3f2.onrender.com/rank"
    gg.alert("Log out of your account first, then tap GG.")
    waitForGG()
    local input = gg.prompt({ "Email:", "Password:" }, nil, { "text", "text" })
    if input == nil then gg.alert("Cancelled"); return end
    if input[1]:match("^%s*$") or input[2]:match("^%s*$") then gg.alert("Email or password missing."); return end
    local res = gg.makeRequest(url, { ["Content-Type"] = "application/json" },
        string.format('{"email":"%s","password":"%s"}', input[1], input[2]))
    if not res or res.code ~= 200 then
        return gg.alert("Error: " .. (res and res.code or "Offline"))
    end
    local msg = res.content:match('"message"%s*:%s*"([^"]+)"') or "Rank set successfully!"
    gg.alert(msg)
end

-- ============================================================
-- UNLOCKS MENU
-- ============================================================
function Menu_Unlockables()
    local m = gg.choice({
        "『༒ UNLOCK W16 ༒』",
        "『༒ UNLOCK ALL (Rims/Smoke/House/Light/W16) ༒』",
        "『༒ CLOTHES MENU (split) ༒』",
        "『༒ UNLOCK TOYOTA CROWN ༒』",
        "『༒ UNLOCK TOYOTA CAMRY ༒』",
        "『༒ UNLOCK PREMIUM BODY KITS ༒』",
        "『༒ UNLOCK PREMIUM BODY KITS (manual) ༒』",
        "『༒ UNLOCK POLICE SIREN ༒』",
        "『༒ UNLOCK HOUSE ༒』",
        "『༒ FIX CHARACTERS NOT SHOWING ༒』",
        "『༒ EVENT CARS ༒』",
        "『༒ BACK ⌦ ༒』"
    }, nil, title)
    if m == nil or m == 12 then return end
    if m == 1  then W16()               end
    if m == 2  then unlockAll()         end
    if m == 3  then Menu_Clothes()      end
    if m == 4  then unlocktoyotacrown() end
    if m == 5  then unlocktoyotacamry() end
    if m == 6  then premiumkits()       end
    if m == 7  then premiumkits_auto()  end
    if m == 8  then unlockpolicecar()   end
    if m == 9  then house()             end
    if m == 10 then fixCharacters()     end
    if m == 11 then eventCarsMenu()     end
end

-- ============================================================
-- CLOTHES MENU  (SPLIT — do NOT run all at once)
-- All of these are tiny 9-insn bool wrappers in dump.cs:
--   they STR X30, BL eлЕб.cОl7, CBZ this, then CMP a flag, CSET W0.
-- Hooking the prologue with MOV W0,? ; RET skips the flag test.
--
-- WHY bool=0 (MOV W0,WZR): dump shows CSET W0,eq after CMP w8,#1
--   i.e. returns "isRestricted/isLocked". 0 = not locked = wearable.
-- Limited is 2-step because Wardrobe RE-INVOKES СMb after UI refresh.
-- ============================================================

function clothes_clan()
    -- dump.cs  RVA 0x33F9628  public bool cттЪ(int p0, int p1)
    -- original: STR X30,[SP,#-0x10]! ; BL eлЕб.cОl7 ; CBZ X0,...
    -- patch:
    --   2A1F03E0  MOV W0, WZR     ; return false (not locked)
    --   D65F03C0  RET
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x33F9628)
    gg.toast("Clan Clothes ON")
end

function clothes_premium()
    -- dump.cs  RVA 0x33F99FC  public bool cмbЬ(int p0, int p1)
    -- same 9-insn shape as cттЪ — premium wardrobe gate
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x33F99FC)
    gg.toast("Premium Clothes ON")
end

function clothes_limited_step1()
    -- dump.cs  RVA 0x33F8124  public bool СMb(int p0, int p1)
    -- STEP 1 (before Wardrobe): force TRUE so limited items are listed
    --   20008052r = bytes 20 00 80 52 = 52800020 MOV W0, #1
    --   C0035FD6r = bytes C0 03 5F D6 = D65F03C0 RET
    SecreDevPatch({ { 0x0, "20008052r" }, { 0x4, "C0035FD6r" } }, 0x33F8124)
    gg.alert("Limited Clothes STEP 1 done.\n\nOpen Wardrobe, then run STEP 2.")
    gg.toast("Limited Step 1 ON")
end

function clothes_limited_step2()
    -- same RVA 0x33F8124 public bool СMb
    -- STEP 2 (after Wardrobe populated): switch to FALSE
    --   E0031F2Ar = bytes E0 03 1F 2A = 2A1F03E0 MOV W0, WZR
    -- WHY: leaving MOV W0,#1 after wardrobe retriggers anti-cheat /
    -- a "is currently unlocking" latch. WZR looks like a normal deny
    -- on later polls, but items are already in the list.
    SecreDevPatch({ { 0x0, "E0031F2Ar" } }, 0x33F8124)
    gg.toast("Limited Clothes STEP 2 ON")
end

function clothes_king()
    -- dump.cs  RVA 0x3417858  public void d8Дg(int p0, int p1)
    -- original: STR X30,[SP,#-0x30]!  (126 insns, applies king outfit)
    -- MOV W0,WZR; RET  → skip the "player is not king" early-out inside
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x3417858)
    gg.toast("King Clothes ON")
end

function clothes_ispremium()
    -- dump.cs  RVA 0x3416F48  private bool dщью(int p0, int p1)
    -- original: SUB SP,SP,#0x50  (171 insns) — "is this clothes premium-only?"
    -- return 0 so premium check fails-open
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x3416F48)
    gg.toast("IsPremium Clothes ON")
end

function clothes_topclan()
    -- dump.cs  RVA 0x33F9818  public bool cQЗР(int p0, int p1)
    -- same 9-insn wrapper as clan (STR / BL cОl7 / CBZ)
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x33F9818)
    gg.toast("Top Clan Clothes ON")
end

function Menu_Clothes()
    local c = gg.choice({
        "『 Clan Clothes 』",
        "『 Premium Clothes 』",
        "『 Limited Clothes – STEP 1 』",
        "『 Limited Clothes – STEP 2 (after Wardrobe) 』",
        "『 King Clothes 』",
        "『 IsPremium Clothes 』",
        "『 Top Clan Clothes 』",
        "『 BACK ⌦ 』"
    }, nil, title .. "\nCLOTHES (split – one at a time)")
    if not c or c == 8 then return end
    if c == 1 then clothes_clan() end
    if c == 2 then clothes_premium() end
    if c == 3 then clothes_limited_step1() end
    if c == 4 then clothes_limited_step2() end
    if c == 5 then clothes_king() end
    if c == 6 then clothes_ispremium() end
    if c == 7 then clothes_topclan() end
end

-- dump.cs: shared unlock gate @ 0x4323978 (not a method start)
-- 2A0103F4h = MOV W20, W1   (ORR W20, WZR, W1)
-- W1 = requested vehicle/flag, W20 = slot the later CMP uses.
function W16()
    SecreDevPatch({ { 0x0, "2A0103F4h" } }, 0x4323978)
    gg.toast("W16 Unlocked")
end

-- Unlock All (Rims/Smoke/House/Light/W16)
-- 0x4323974  F60301AAr = bytes F6 03 01 AA = AA0103F6 MOV X22, X1
-- 0x4323978  F403012Ar = bytes F4 03 01 2A = 2A0103F4 MOV W20, W1
-- WHY two writes: the same compare uses X22 (64-bit object/flag) AND
-- W20 (32-bit id). Copying X1/W1 into both makes every subtype pass.
function unlockAll()
    SecreDevPatch({ { 0x0, "F60301AAr" } }, 0x4323974)
    SecreDevPatch({ { 0x0, "F403012Ar" } }, 0x4323978)
    gg.alert("Unlock All (Rims / Smoke / House / Light / W16) applied.")
    gg.toast("Unlock All ON")
end

-- Toyota Crown — NO code offset. ANONYMOUS heap struct:
-- group search 3;0;218;-1 : 218 is the internal car-id for Crown.
-- Editing 218→0 marks the slot "id 0 / unlocked/owned" in that struct.
function unlocktoyotacrown()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("3;0;218;-1:13", gg.TYPE_DWORD)
    gg.refineNumber(218, gg.TYPE_DWORD)
    gg.getResults(500)
    gg.editAll(0, gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Toyota Crown ON")
    gg.setVisible(false)
end

-- Toyota Camry — Xa [1] base, RVA 0x3859DD8 (mid-fn, not in dump as RVA)
-- Buy:    52800034h = MOV W20, #1      ; "purchased" flag in W20
-- Bypass: 2A0103F4h = MOV W20, W1      ; accept whatever id was requested
function unlocktoyotacamry()
    local m = gg.choice({ "Buy Camry", "Bypass Camry", "BACK" }, nil, title)
    if m == nil or m == 3 then return end
    local val = (m == 1) and "52800034h" or "2A0103F4h"
    SecreDevPatch({ { 0x0, val } }, 0x3859DD8, true)
    gg.toast("Toyota Camry patch applied")
end

-- dump.cs: Bluff.CallB1<object, int>  generic inst  RVA 0x3FD9990
-- Bluff.CallB1 is an IL2CPP wrapper: invoke a Func and return int.
-- Police siren path calls this; forcing return 1 means "unlocked/ok".
--   52800020h = MOV W0, #1
--   D65F03C0h = RET
-- (same 4 bytes as 20008052r / C0035FD6r)
function unlockpolicecar()
    SecreDevPatch({
        { 0x0, "52800020h" },
        { 0x4, "D65F03C0h" }
    }, 0x3FD9990)
    gg.toast("Police Siren ON")
end

-- dump.cs: private bool bяCн()  RVA 0x33620CC
-- original prologue (dump):
--   0x33620CC  SUB SP, SP, #0x60
--   0x33620D0  STR X30, [SP, #0x20]
-- 256 insns / 38 blocks — "is this premium kit locked?"
-- MOV W0,WZR; RET → always "not locked" (bool false).
function premiumkits()
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x33620CC)
    gg.toast("Premium Body Kits Unlocked")
end

-- Premium Body Kits — manual kit selection
function premiumkits_auto()
    local items = { "SPOILER", "BUMPER", "ROOF", "HOOD", "SIDE SKIRT", "FENDER" }
    local menu  = gg.choice(items, nil, title)
    if not menu then return end

    local kit = items[menu]
    local function unlockPremium(k)
        gg.setVisible(false)
        gg.alert("Tap the PREMIUM " .. k .. ", then tap GG.")
        waitForGG()
        clearReset()
        gg.setRanges(32)
        gg.searchNumber("7", 32)
        local results = gg.getResults(100000)
        for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
        gg.loadResults(results)
        gg.refineNumber("2", 32)
        results = gg.getResults(100000)
        for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
        gg.loadResults(results)
        gg.refineNumber("4294967295", 32)
        results = gg.getResults(100000)
        for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
        gg.loadResults(results)
        gg.getResults(9999)
        local v = gg.getResults(1)
        for _, item in ipairs(v) do item.freeze = true end
        gg.addListItems(v)
        gg.clearResults()
        gg.alert("Now buy another " .. k .. ", then tap another car and come back.")
        gg.toast("ON")
    end
    unlockPremium(kit)
end

-- dump.cs:
--   0x348B5EC  private bool gEkЖ(int, int, Action)   house-ownership gate
--              original: STR X30,[SP,#-0x30]!  (142 insns)
--   0x348CD2C  private void fВ0н(long=0)            tail B to ShowAllEnvironment
--   0x348B604  companion site next to gEkЖ
-- MOV W0,WZR; RET on the bool → "does not own / check failed-open"
-- so the house appears available. RET on fВ0н stops the environment hide.
function house()
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x348B5EC)
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x348CD2C)
    SecreDevPatch({ { 0x0, "~A8 MOV W0, WZR" }, { 0x4, "~A8 RET" } }, 0x348B604)
    gg.toast("House Unlocked")
end

-- dump.cs: RVA 0x432397C (same cluster as W16 gate, +8)
-- Step 1: F70300AAr = bytes F7 03 00 AA = AA0003F7 MOV X23, X0
--         stash `this`/driver object so clothes UI can resolve meshes
-- Step 2: F70301AAr = bytes F7 03 01 AA = AA0103F7 MOV X23, X1
--         after switching female driver, copy the new arg into X23
-- WHY X23: callee-saved; the renderer reads the character from X23
-- across the clothes-area call. Original insn overwrote it with 0.
function fixCharacters()
    local m = gg.choice({
        "Step 1 (go to Clothes & tap GG)",
        "Step 2 (change driver to Female → Lobby)",
        "BACK"
    }, nil, "Fix Characters Not Showing")
    if m == nil or m == 3 then return end
    if m == 1 then
        SecreDevPatch({ { 0x0, "F70300AAr" } }, 0x432397C)
        gg.alert("Now go to Clothes area and tap the GG icon to continue.")
    elseif m == 2 then
        SecreDevPatch({ { 0x0, "F70301AAr" } }, 0x432397C)
        gg.alert("Change driver to Female, then return to Lobby.")
    end
    gg.toast("Fix Characters Step " .. m .. " applied")
end

-- [NEW] Event Cars — ANONYMOUS region search
-- Summary values: W124=258, Celica=262, Fortuner=259, F650=253, 3000GT=272, Supra=269
function eventCarsMenu()
    local carNames = {
        "Mercedes Benz W124   (value 258)",
        "Toyota Celica ST205  (value 262)",
        "Toyota Fortuner      (value 259)",
        "Ford F650            (value 253)",
        "Mitsubishi 3000GT VR4(value 272)",
        "Toyota Supra MK3     (value 269)",
        "BACK"
    }
    local carValues = { 258, 262, 259, 253, 272, 269 }

    local m = gg.choice(carNames, nil, "Event Cars")
    if m == nil or m == 7 then return end

    local val = carValues[m]
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(tostring(val), gg.TYPE_DWORD)
    local results = gg.getResults(100000)
    if #results == 0 then
        gg.clearResults()
        gg.alert("Event car value not found. Make sure you are in the right screen.")
        return
    end
    gg.editAll("0", gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Event Car unlocked: value " .. val)
end

-- ============================================================
-- COPY CAR
-- dump.cs: public void DeleteCarFromLocalData(int p0, Action p1)
--          RVA 0x3958868  Slot 27
--          original: STR X30,[SP,#-0x40]!  (247 insns)
-- We do NOT hook the entry. We write +0x24 into the body:
--   0x395888C  5284E1F4h = MOV W20, #9999   ; MOVZ W20, #0x270F
-- WHY 9999: later CMP uses W20 as "deleted-car id". 9999 never matches
-- a real garage id, so DeleteCarFromLocalData becomes a no-op on yours.
--
-- Companion RVAs (same type, all "did the car disappear?" / save):
--   MOV W0,#1 ; RET  → force success on save/get-id
--   MOV W0,WZR; RET  → force false on WasDeleted / Delete* / RemoveFromList
-- Those opcodes: 52800020 + D65F03C0  and  2A1F03E0 + D65F03C0
-- ============================================================
function smjCopycar()
    local ASADA = getLib2()

    local function write2(offset, val1, val2)
        SecreDevPatch({ { 0x0, val1 }, { 0x4, val2 } }, offset)
    end

    -- DeleteCarFromLocalData +0x24 : MOV W20, #9999
    SecreDevPatch({ { 0x0, "5284E1F4h" } }, 0x395888C)

    local nullRet1 = "~A8 MOV\t W0, WZR"
    local nullRet2 = "~A8 RET"

    write2(0x3956148, "~A8 MOV W0, #1", nullRet2)      -- SaveCurrentCarAfterTime
    write2(0x3957A18, "~A8 MOV W0, #1", nullRet2)      -- GetCarIDnStatus
    write2(0x3956250, "~A8 MOV W0, #1", nullRet2)      -- SaveCurrentCar
    write2(0x39556C0, nullRet1, nullRet2)               -- bool_WasCarDeleted
    write2(0x3957964, nullRet1, nullRet2)               -- GetDeletedCarIDList
    write2(0x3956FD4, nullRet1, nullRet2)               -- RemoveFromList
    write2(0x3955D70, nullRet1, nullRet2)               -- fзуъ
    write2(0x3958270, nullRet1, nullRet2)               -- eGсx / apJS
    write2(0x3957878, nullRet1, nullRet2)               -- dwШв
    write2(0x39587AC, nullRet1, nullRet2)               -- DeleteCarFull
    write2(0x3958C44, nullRet1, nullRet2)               -- DeleteCarFromDatabaseAsync
    write2(0x39591AC, nullRet1, nullRet2)               -- dяБR
    write2(0x39567D0, nullRet1, nullRet2)               -- bRГЩ
    write2(0x3958D78, nullRet1, nullRet2)               -- bEйз
    write2(0x3959630, nullRet1, nullRet2)               -- .ctor

    -- car-count cap: MOV W20, #0x270F (9999) — same encoding as 5284E1F4h
    SecreDevPatch({ { 0x0, "~A8 MOV W20, #0x270F" } }, 0x3958844)

    gg.alert("Car sold or traded will NOT be deleted.\nGame may kick you — log in again.")
    gg.toast("Copy Car ON")
end

-- ============================================================
-- RACE MENU  (+ improved City / HW style helpers, search-based)
-- ============================================================
function raceMenu()
    local m = gg.choice({
        "Speed / Sec Menu",
        "Drift Menu",
        "Handbrake Speed Boost [" .. statusText(elFrenActive) .. "]",
        "3 Sec / 5 Sec Race",
        "City Race Boost (search)",
        "Highway Race Boost (search)",
        "No Damage + Unlimited Tires (search)",
        "BACK"
    }, nil, title)
    if m == nil or m == 8 then return end
    if m == 1 then speedMenu()              end
    if m == 2 then driftmenu()              end
    if m == 3 then elFrenHizliAraba()       end
    if m == 4 then racing32()               end
    if m == 5 then raceCityBoost()          end
    if m == 6 then raceHighwayBoost()       end
    if m == 7 then raceNoDmgUnlimited()     end
end

-- Search-based race helpers (safer than old hardcoded RVAs that break every update)
function raceCityBoost()
    gg.alert("When traffic light is about to turn GREEN, press GG icon.")
    while not gg.isVisible() do gg.sleep(80) end
    gg.setVisible(false)
    -- No-damage style search (body / tire related floats used by many race scripts)
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("-99999", gg.TYPE_FLOAT)
    local r1 = gg.getResults(500)
    if #r1 > 0 then gg.editAll("-99999", gg.TYPE_FLOAT) end
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0", gg.TYPE_FLOAT)
    local r2 = gg.getResults(500)
    if #r2 > 0 then gg.editAll("30", gg.TYPE_FLOAT) end
    gg.clearResults()
    -- Speed / gravity cluster commonly used for City
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("-9.80000019073;0.01999999955;50.0;0.75:85", gg.TYPE_FLOAT)
    gg.refineNumber("-9.80000019073", gg.TYPE_FLOAT)
    local t = gg.getResults(9999)
    if #t > 0 then
        gg.addListItems(t)
        local list = gg.getListItems()
        for i, v in ipairs(list) do
            v.address = v.address + 0x4
        end
        gg.addListItems(list)
        gg.removeListItems(list)
    end
    gg.clearResults()
    gg.toast("City Race Boost applied")
end

function raceHighwayBoost()
    gg.alert("When traffic light is about to turn GREEN, press GG icon.")
    while not gg.isVisible() do gg.sleep(80) end
    gg.setVisible(false)
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("-9.80000019073;0.01999999955;50.0;0.75:85", gg.TYPE_FLOAT)
    gg.refineNumber("-9.80000019073", gg.TYPE_FLOAT)
    local t = gg.getResults(9999)
    if #t > 0 then
        gg.addListItems(t)
        local list = gg.getListItems()
        for i, v in ipairs(list) do
            -- HW style: slightly different pointer adjustment
            v.address = v.address - 4
        end
        gg.addListItems(list)
        gg.removeListItems(list)
    end
    gg.clearResults()
    gg.toast("Highway Race Boost applied")
end

function raceNoDmgUnlimited()
    -- Soft no-damage / tire wear style (search based, no broken RVA)
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0.45775", gg.TYPE_FLOAT)
    local r = gg.getResults(1000)
    if #r > 0 then gg.editAll("998659", gg.TYPE_FLOAT) end
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1", gg.TYPE_FLOAT)
    local r2 = gg.getResults(1000)
    if #r2 > 0 then gg.editAll("3588534", gg.TYPE_FLOAT) end
    gg.clearResults()
    gg.processResume()
    gg.toast("No Damage / Unlimited Tires style applied")
end

function racing32()
    local m = gg.choice({
        sec3 .. "3 SEC",
        sec5 .. "5 SEC",
        "BACK"
    }, nil, title)
    if m == nil or m == 3 then return end
    if m == 1 then threesec() end
    if m == 2 then fivesec()  end
end

-- 3 SEC race
function threesec()
    gg.setVisible(false)
    if sec3 == on then
        gg.setRanges(32);     gg.searchNumber("-100000", gg.TYPE_FLOAT); gg.editAll("2500",     gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("3",       gg.TYPE_FLOAT); gg.editAll("1.1",      gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("925",     gg.TYPE_FLOAT); gg.editAll("3.6",      gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("4E-4",    gg.TYPE_FLOAT); gg.editAll("10000000", gg.TYPE_FLOAT); gg.clearResults()
        gg.toast("3 SEC OFF"); clearReset(); sec3 = off
    else
        gg.setRanges(32);     gg.searchNumber("2500",     gg.TYPE_FLOAT); gg.editAll("-100000", gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("1.1",      gg.TYPE_FLOAT); gg.editAll("3",       gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("3.6",      gg.TYPE_FLOAT); gg.editAll("925",     gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("10000000", gg.TYPE_FLOAT); gg.editAll("4E-4",    gg.TYPE_FLOAT); gg.clearResults()
        gg.toast("3 SEC ON"); clearReset(); sec3 = on
    end
end

-- 5 SEC race
function fivesec()
    gg.setVisible(false)
    if sec5 == on then
        gg.setRanges(32);     gg.searchNumber("-100000", gg.TYPE_FLOAT); gg.editAll("2500",     gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("30",      gg.TYPE_FLOAT); gg.editAll("3.6",      gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("4E-4",    gg.TYPE_FLOAT); gg.editAll("10000000", gg.TYPE_FLOAT); gg.clearResults()
        gg.toast("5 SEC OFF"); sec5 = off
    else
        gg.setRanges(32);     gg.searchNumber("2500",     gg.TYPE_FLOAT); gg.editAll("-100000", gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("3.6",      gg.TYPE_FLOAT); gg.editAll("30",      gg.TYPE_FLOAT); gg.clearResults()
        gg.setRanges(16384);  gg.searchNumber("10000000", gg.TYPE_FLOAT); gg.editAll("4E-4",    gg.TYPE_FLOAT); gg.clearResults()
        gg.toast("5 SEC ON"); clearReset(); sec5 = on
    end
end

function elFrenHizliAraba()
    elFrenActive = not elFrenActive
    gg.setRanges(gg.REGION_ANONYMOUS)
    local newV    = elFrenActive and "-6800" or "6000"
    local searchV = elFrenActive and "6000"  or "-6800"
    gg.searchNumber(searchV, gg.TYPE_DWORD)
    local results = gg.getResults(10000)
    if #results > 0 then
        for i, v in ipairs(results) do v.value = tonumber(newV) end
        gg.setValues(results)
    end
    gg.clearResults()
    if elFrenActive then gg.alert("Pull parking brake when speedo exceeds 100.") end
    gg.toast(elFrenActive and "Handbrake Boost ON" or "Handbrake Boost OFF")
end

-- Speed menu (1/2/3/5 sec / instant)
local function applyEdit(range, searchVal, editVal)
    gg.setRanges(range)
    gg.searchNumber(searchVal, gg.TYPE_FLOAT)
    gg.getResults(1000)
    gg.editAll(editVal, gg.TYPE_FLOAT)
    gg.clearResults()
end

local function revertEdits(seconds)
    local data = revertData[seconds]
    if data then
        for _, d in ipairs(data) do if d then gg.setValues(d) end end
        gg.toast(seconds .. " sec disabled")
    end
end

local function tokinzleValue(seconds)
    for s, active in pairs(tokinzleValues) do
        if s ~= seconds and active then tokinzleValues[s] = false; revertEdits(s) end
    end
    tokinzleValues[seconds] = not tokinzleValues[seconds]
    if tokinzleValues[seconds] then
        gg.toast(seconds .. " sec enabled")
        local r = {}
        r[1] = { applyEdit(gg.REGION_ANONYMOUS, "2500", "-100000") }
        if seconds == 5 then
            r[2] = { applyEdit(gg.REGION_CODE_APP, "3.6",      "30")  }
            r[3] = { applyEdit(gg.REGION_CODE_APP, "10000000", "4E-4") }
        elseif seconds == 3 then
            r[2] = { applyEdit(gg.REGION_CODE_APP, "1.1",      "3")   }
            r[3] = { applyEdit(gg.REGION_CODE_APP, "3.6",      "925") }
            r[4] = { applyEdit(gg.REGION_CODE_APP, "10000000", "4E-4") }
        elseif seconds == 2 then
            r[2] = { applyEdit(gg.REGION_CODE_APP, "1.1",      "2.8") }
            r[3] = { applyEdit(gg.REGION_CODE_APP, "10000000", "8E-4") }
        elseif seconds == 1 then
            r[2] = { applyEdit(gg.REGION_CODE_APP, "1.1",      "10")  }
            r[3] = { applyEdit(gg.REGION_CODE_APP, "10000000", "3E-4") }
        elseif seconds == 0 then
            r[2] = { applyEdit(gg.REGION_CODE_APP, "1.1",      "999") }
            r[3] = { applyEdit(gg.REGION_CODE_APP, "10000000", "3E-4") }
        end
        revertData[seconds] = r
    else
        revertEdits(seconds)
    end
end

function speedMenu()
    local secim = gg.choice({
        "5 Seconds  [" .. statusText(tokinzleValues[5]) .. "]",
        "3 Seconds  [" .. statusText(tokinzleValues[3]) .. "]",
        "2 Seconds  [" .. statusText(tokinzleValues[2]) .. "]",
        "1 Second   [" .. statusText(tokinzleValues[1]) .. "]",
        "Instant    [" .. statusText(tokinzleValues[0]) .. "]",
        "BACK"
    }, nil, title)
    if secim == nil or secim == 6 then raceMenu(); return end
    local secondsList = { 5, 3, 2, 1, 0 }
    local selected = secondsList[secim]
    if selected ~= nil then tokinzleValue(selected) end
end

-- ============================================================
-- DRIFT MENU
-- ============================================================
local driftLow = false
local driftMed = false
local driftHi  = false

function driftmenu()
    local m = gg.choice({
        "Drift LOW  [" .. (driftLow and "ON" or "OFF") .. "]",
        "Drift MED  [" .. (driftMed and "ON" or "OFF") .. "]",
        "Drift HIGH [" .. (driftHi  and "ON" or "OFF") .. "]",
        "BACK"
    }, nil, title)
    if m == nil or m == 4 then return end

    local function setDrift(val, offVal, label)
        gg.clearResults(); gg.clearList()
        gg.setRanges(gg.REGION_CODE_APP)
        gg.searchNumber(offVal, gg.TYPE_FLOAT)
        gg.getResults(100)
        gg.editAll(tostring(val), gg.TYPE_FLOAT)
        gg.toast("Drift " .. label)
        gg.clearResults()
    end

    if m == 1 then
        driftLow = not driftLow
        if driftLow then setDrift(18,     "0.0001", "LOW ON")  else setDrift(0.0001, "18",    "LOW OFF") end
    elseif m == 2 then
        driftMed = not driftMed
        if driftMed then setDrift(50,     "0.0001", "MED ON")  else setDrift(0.0001, "50",    "MED OFF") end
    elseif m == 3 then
        driftHi  = not driftHi
        if driftHi  then setDrift(80,     "0.0001", "HIGH ON") else setDrift(0.0001, "80",    "HIGH OFF") end
    end
end

-- ============================================================
-- ENGINE / HP MENU
-- ============================================================
function hp()
    local m = gg.choice({
        "HP Adjusted Menu",
        "Custom HP",
        "Transmission Menu",
        "HP Menu v2",
        "Custom Mass & Gearbox",
        "BACK"
    }, nil, title)
    if m == nil or m == 6 then return end
    if m == 1 then hpMenu()        end
    if m == 2 then hpOzel()        end
    if m == 3 then sanzimanMenu()  end
    if m == 4 then hpmenu22()      end
    if m == 5 then custommenu_hp() end
end

local function hpSearchApply(hp, torque, maxRpm, idleRpm)
    gg.alert("Buy an engine, then tap GG.")
    waitForGG()
    clearReset()
    gg.setRanges(32)
    gg.searchNumber("5124040845977993216", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x3C; ofs.flags = 32 end
    gg.loadResults(results)
    gg.refineNumber("274877906944", 32)
    results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x4; ofs.flags = 32 end
    gg.loadResults(results)
    gg.refineNumber("0", 32)
    local R = gg.getResults(gg.getResultsCount())

    local edits = {}
    for _, r in ipairs(R) do
        table.insert(edits, { address = r.address + 0x14, flags = 16, value = hp,      freeze = true })
        table.insert(edits, { address = r.address + 0x1C, flags = 16, value = torque  })
        table.insert(edits, { address = r.address + 0x18, flags = 16, value = maxRpm  })
        table.insert(edits, { address = r.address + 0x20, flags = 16, value = idleRpm })
    end
    gg.setValues(edits)
    gg.alert("Tap another car, come back, then tap SET.")
    gg.toast("HP Applied")
    clearReset()
end

function hpMenu()
    local m = gg.choice({
        "HP 99",  "HP 300", "HP 324", "HP 400",
        "HP 414", "HP 925", "HP 1695", "HP 1695 (Fast)", "BACK"
    }, nil, title)
    if m == nil or m == 9 then hp(); return end
    local sets = {
        {"99","2300","8000","7789"},{"300","3000","8000","7789"},
        {"324","2300","8000","7789"},{"400","2300","8000","7789"},
        {"414","2300","8000","7789"},{"925","2300","8000","7789"},
        {"1695","2254","7000","3500"},{"1695","2254","1000","1001"}
    }
    local s = sets[m]
    if s then hpSearchApply(tonumber(s[1]), tonumber(s[2]), tonumber(s[3]), tonumber(s[4])) end
end

function hpmenu22()
    local names = {"320 HP","90 HP","1695 HP","1466 HP","2000 HP","300 HP","98 HP","925 HP","BACK"}
    local sets  = {
        {320,2299,8000,5000},{90,2300,8000,7899},{1695,2254,7000,3500},
        {1466,1690,5948,5937},{2000,3000,7000,3500},{300,2300,8000,7899},
        {98,2300,100000,7899},{925,1804,7000,3500}
    }
    local m = gg.choice(names, nil, title)
    if m == nil or m == 9 then hp(); return end
    local s = sets[m]
    if s then hpSearchApply(s[1], s[2], s[3], s[4]) end
end

function hpOzel()
    local engines = {"L4 2.0","L4 2.5","V6 3.0","V6 3.5","V8 4.0","V8 4.5","V10 5.0","V10 6.0","V12 6.0","V16 8.0","BACK"}
    local data    = {
        {"150","220","5900","4100"},{"90","300","5900","4100"},
        {"240","310","6800","4500"},{"280","350","6300","4500"},
        {"360","500","6300","3400"},{"415","430","7000","4000"},
        {"500","620","7000","5600"},{"580","680","7000","5000"},
        {"612","1000","7000","3500"},{"1120","1250","7000","3500"}
    }
    local m = gg.choice(engines, nil, title)
    if m == nil or m == 11 then hp(); return end
    local d = data[m]
    if not d then return end

    gg.alert("Buy " .. engines[m] .. " then tap GG.")
    waitForGG()

    local girdi = gg.prompt(
        {"Vehicle HP","Vehicle Torque","Interior HP","Interior Torque","Back"},
        { d[1], d[2], d[3], d[4], false },
        {"number","number","number","number","checkbox"}
    )
    if not girdi or girdi[5] then return end

    local function AVD(aranan, yeniDeger)
        gg.clearResults(); gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber(aranan, gg.TYPE_FLOAT)
        gg.getResults(1000)
        gg.editAll(yeniDeger, gg.TYPE_FLOAT)
        gg.clearResults()
    end
    AVD(d[1], girdi[1]); AVD(d[2], girdi[2]); AVD(d[3], girdi[3]); AVD(d[4], girdi[4])
    gg.alert("Tap SET")
end

function custommenu_hp()
    local m = gg.choice({ "Custom Mass", "Custom Gearbox", "BACK" }, nil, title)
    if m == nil or m == 3 then hp(); return end
    if m == 1 then custommass()    end
    if m == 2 then customgearbox() end
end

function custommass()
    local d = gg.prompt({ "Search Value (current mass)", "New Value", "Cancel" }, nil, { "number", "number", "checkbox" })
    if not d or d[3] then return end
    clearReset()
    gg.setRanges(16384)
    gg.searchNumber(d[1], gg.TYPE_FLOAT)
    gg.getResults(1000)
    gg.editAll(d[2], gg.TYPE_FLOAT)
    gg.toast("Mass set")
    clearReset()
end

function customgearbox()
    local d = gg.prompt({ "New Gearbox Value", "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return end
    gg.alert("Set gearbox to 6, then tap GG.")
    waitForGG()
    gg.setRanges(32)
    gg.searchNumber("6", gg.TYPE_FLOAT)
    gg.getResults(1000)
    gg.editAll(d[1], gg.TYPE_FLOAT)
    gg.toast("Gearbox set")
    clearReset()
end

-- ============================================================
-- TRANSMISSION MENU
-- Shift time offset: 0x15A7730
-- ============================================================
function sanzimanMenu()
    local m = gg.choice({
        "Transmission 1E-20",
        "Transmission 1E-30",
        "Custom Transmission",
        "Shift Time 0.0001 [" .. (shift00001 == on and "ON" or "OFF") .. "]",
        "Shift Time 1E-30  [" .. (shift1e30  == on and "ON" or "OFF") .. "]",
        "Shift Time 1E-29  [" .. (shift1e29  == on and "ON" or "OFF") .. "]",
        "BACK"
    }, nil, title)
    if m == nil or m == 7 then hp(); return end
    if m == 1 then sanziman("1E-20") end
    if m == 2 then sanziman("1E-30") end
    if m == 3 then sanzimanOzel()    end
    if m == 4 then shifttime(0.0001, "00001") end
    if m == 5 then shifttime("1e-30", "1e30") end
    if m == 6 then shifttime("1e-29", "1e29") end
end

function sanziman(val)
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0.1", gg.TYPE_FLOAT)
    gg.getResults(100)
    gg.editAll(val, gg.TYPE_FLOAT)
    gg.clearResults()
    gg.setVisible(false)
    gg.alert("Purchase fast transmission.")
    gg.toast("Active!")
    gg.setVisible(false)
end

function sanzimanOzel()
    local old = gg.prompt({ "Current Transmission Value:" }, { "" }, { "number" })
    if not old then gg.toast("Cancelled"); return end
    local new = gg.prompt({ "New Transmission Value:" }, { "" }, { "number" })
    if not new then gg.toast("Cancelled"); return end
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber(old[1], gg.TYPE_FLOAT)
    gg.getResults(100)
    gg.editAll(new[1], gg.TYPE_FLOAT)
    gg.clearResults()
    gg.setVisible(false)
    gg.alert("Purchase fast transmission.")
    gg.toast("Active!")
    gg.setVisible(false)
end

local shiftStates = { ["00001"] = false, ["1e30"] = false, ["1e29"] = false }
local shiftValMap = { ["00001"] = 0.0001, ["1e30"] = "1e-30", ["1e29"] = "1e-29" }

function shifttime(val, key)
    local libs   = getLib2()
    local offset = 0x15A7730
    shiftStates[key] = not shiftStates[key]
    local writeVal = shiftStates[key] and val or 0.1
    local item = {
        { address = libs + offset, flags = 16, value = tostring(writeVal), freeze = shiftStates[key],
          freezeType = gg.FREEZE_NORMAL }
    }
    gg.addListItems(item)
    if shiftStates[key] then
        gg.alert("Buy Fast Gearbox now.")
        gg.toast("Shift Time ON")
    else
        gg.clearResults(); clearReset()
        gg.toast("Shift Time OFF")
    end
end

-- ============================================================
-- BODY MODIFICATION MENU
-- ============================================================
function Menu_custom()
    local m = gg.choice({
        "Add Custom Body Kit",
        "Find Body Kit Code",
        "Bumper Removal Menu",
        "UFO Suspension",
        "Chrome Customization",
        "Maintenance (Repair / Fuel / No Damage)",
        "BACK"
    }, nil, title)
    if m == nil or m == 7 then return end
    if m == 1 then ekgovde()        end
    if m == 2 then degerAra()       end
    if m == 3 then Menu_bumper()    end
    if m == 4 then ufoMenu()        end
    if m == 5 then Menu_chromecar() end
    if m == 6 then Menu_modified()  end
end

-- Internal pointer chain (ExteriorTuning)
error = 0
function O_initial_search()
    gg.setVisible(false)
    user_input = ":" .. Get_user_input[1]
    offst = Get_user_input[3] and 25 or 0
end
function O_dinitial_search()
    if error > 1 then gg.setRanges(gg.REGION_C_ALLOC) else gg.setRanges(gg.REGION_OTHER) end
    gg.searchNumber(user_input, gg.TYPE_BYTE)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    Refiner = gg.getResults(1)
    gg.refineNumber(Refiner[1].value, gg.TYPE_BYTE)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    val = gg.getResults(count)
end
function CA_pointer_search()
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)
    gg.loadResults(val)
    gg.searchPointer(offst)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    val = gg.getResults(count)
end
function CA_apply_offset()
    local tanker = Get_user_input[4] and -8 or -16
    for i, v in ipairs(val) do v.address = v.address + tanker end
    val = gg.getValues(val)
end
function A_base_value()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.loadResults(val)
    gg.searchPointer(offst)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    val = gg.getResults(count)
end
function A_base_accuracy()
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
    gg.loadResults(val)
    gg.searchPointer(offst)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    local kol = gg.getResults(count)
    local h = {}
    for i = 1, count do h[i] = { address = kol[i].value, flags = 32 } end
    val = gg.getValues(h)
end
function A_user_given_offset()
    local old_save_list = val
    local uniqueTable = {}; local addressSet = {}
    for _, item in ipairs(old_save_list) do
        if not addressSet[item.address] then
            table.insert(uniqueTable, item); addressSet[item.address] = true
        end
    end
    old_save_list = uniqueTable
    local finalResults = {}; local finalResultIndex = 1
    local hex_values = {}
    for hex in Get_user_input[2]:gmatch("0x%x+") do table.insert(hex_values, hex) end
    for i, v in ipairs(old_save_list) do
        for _, value in ipairs(hex_values) do
            finalResults[finalResultIndex] = { address = v.address + value }
            if Get_user_input[4] then
                finalResults[finalResultIndex].flags = gg.TYPE_DWORD
            else
                finalResults[finalResultIndex].flags = gg.TYPE_QWORD
            end
            finalResultIndex = finalResultIndex + 1
        end
    end
    gg.clearResults()
    gg.loadResults(finalResults)
    count = gg.getResultsCount()
    if count == 0 then return 0 end
    gg.setVisible(false)
end
function start()
    O_initial_search()
    O_dinitial_search(); if error > 0 then return 0 end
    CA_pointer_search(); if error > 0 then return 0 end
    CA_apply_offset();   if error > 0 then return 0 end
    A_base_value();      if error > 0 then return 0 end
    if offst == 0 then A_base_accuracy() end
    if error > 0 then return 0 end
    A_user_given_offset(); if error > 0 then return 0 end
end

local function value_search(name, hexOffset, tryHard, bit32, valType)
    Get_user_input = {}
    Get_user_input[1] = name
    Get_user_input[2] = hexOffset
    Get_user_input[3] = tryHard
    Get_user_input[4] = bit32
    start()
end

function ekgovde()
    gg.alert("Select the body part in game, then tap GG.")
    waitForGG()
    local c = gg.prompt({ "Enter code (e.g. trunk = 6)", "Cancel" }, nil, { "number", "checkbox" })
    if not c or c[2] then return end
    value_search("ExteriorTuning", "0xF0", false, false, 4)
    local results = gg.getResults(gg.getResultsCount())
    local DRAG = {}
    for i, v in ipairs(results) do
        if v.value > 0 and v.value <= 999 then table.insert(DRAG, v) end
    end
    if #DRAG == 0 then gg.alert("No valid results found"); return end
    for i, v in ipairs(DRAG) do v.value = c[1]; v.freeze = false end
    gg.setValues(DRAG)
    gg.alert("Purchase the body kit now.")
    gg.clearResults()
end

function degerAra()
    gg.alert("Select the body part you want to find the code for, then tap GG.")
    waitForGG()
    value_search("ExteriorTuning", "0xF0", false, false, 4)
    local results = gg.getResults(50)
    local filteredValues = {}
    for i, v in ipairs(results) do
        local n = tonumber(v.value)
        if n and n >= 1 and n <= 999 then table.insert(filteredValues, n) end
    end
    if #filteredValues > 0 then
        local resultText = table.concat(filteredValues, "\n")
        gg.copyText(resultText)
        gg.alert("Code:\n" .. resultText .. "\n\nCopied to clipboard.")
        gg.clearResults()
    else
        gg.alert("No suitable values found.")
    end
end

-- ============================================================
-- BUMPER MENU
-- ============================================================
function Menu_bumper()
    local m = gg.choice({
        "Remove Front Bumper",
        "Remove Rear Bumper",
        "Get Premium Bumper",
        "BACK"
    }, nil, title)
    if m == nil or m == 4 then Menu_custom(); return end
    if m == 1 then removefrontbumper() end
    if m == 2 then removebackbumper()  end
    if m == 3 then premiumbumper()     end
end

local function bumperSearch(alertMsg, filterOffset, editOffset)
    gg.setVisible(false)
    gg.alert(alertMsg)
    waitForGG()
    clearReset()
    local results = searchModule("1657333858397323264", 32, "A", "Bumper")
    if not results then return end
    local pr = pointerSearch(results, -0x550, 32)
    if not pr then return end
    local offsets   = { 0x14, filterOffset }
    local flags     = { 32, 4 }
    local valueInfo = {
        { key1 = { 34359738368 } },
        { key2 = { min = -2, max = 9 } },
    }
    local gr = getResults(pr, offsets, flags)
    local fr = filterResults(gr, valueInfo)
    if fr then
        v_setValues(fr, { editOffset }, { 4 }, { -1 }, true)
    end
    clearReset()
    gg.alert("Tap another car, then come back.")
    gg.toast("ON")
end

function removefrontbumper()
    bumperSearch("Tap EXTERIOR then tap GG.", 0x24, 0x10)
end
function removebackbumper()
    bumperSearch("Tap EXTERIOR then tap GG.", 0x28, 0x14)
end

function premiumbumper()
    gg.setVisible(false)
    gg.alert("Tap the PREMIUM BUMPER then tap GG.")
    waitForGG(); clearReset()
    gg.setRanges(32); gg.searchNumber("7", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("2", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("4294967295", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
    gg.loadResults(results); gg.getResults(9999)
    gg.setVisible(false)
    local v = gg.getResults(1)
    for _, item in ipairs(v) do item.freeze = true end
    gg.addListItems(v)
    local value = v[1] and v[1].value or nil
    gg.clearResults()

    gg.alert("Now buy another BUMPER then tap GG.")
    waitForGG(); gg.setVisible(false)
    local results2 = searchModule("1657333858397323264", 32, "A", "Bumper")
    if not results2 then return end
    local pr2 = pointerSearch(results2, -0x550, 32)
    if not pr2 then return end
    local gr2 = getResults(pr2, { 0x14, 0x28 }, { 32, 4 })
    local fr2 = filterResults(gr2, { { key1 = { 34359738368 } }, { key2 = { min = -2, max = 9 } } })
    if fr2 and value then v_setValues(fr2, { 0 }, { 4 }, { value }, true) end
    gg.alert("Tap another car then come back."); gg.toast("ON"); clearReset()
end

-- ============================================================
-- UFO / SUSPENSION MENU
-- ============================================================
function ufoMenu()
    local m = gg.choice({
        "UFO 70 (v1)", "UFO 90 (v1)", "UFO 120 (v1)", "Custom UFO (v1)",
        "UFO 1 (v2)",  "UFO 2 (v2)",  "UFO 3 (v2)",   "Custom UFO (v2)",
        "Angle 90", "Angle 110", "Angle 105", "Custom Angle",
        "BACK"
    }, nil, title)
    if m == nil or m == 13 then Menu_custom(); return end
    if m == 1 then commonSuspension(70)  end
    if m == 2 then commonSuspension(90)  end
    if m == 3 then commonSuspension(120) end
    if m == 4 then customUFO()           end
    if m == 5 then ufoV2(-130)           end
    if m == 6 then ufoV2(-90)            end
    if m == 7 then ufoV2(-75)            end
    if m == 8 then customufo()           end
    if m == 9  then applyAngle(90)       end
    if m == 10 then applyAngle(110)      end
    if m == 11 then applyAngle(105)      end
    if m == 12 then customangle()        end
end

function commonSuspension(value)
    gg.alert("In suspension settings:\n1. Move camber and axle sliders to max\n2. Save\n3. Tap GG")
    waitForGG()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("-10", gg.TYPE_FLOAT); gg.refineNumber("-10", gg.TYPE_FLOAT)
    gg.getResults(1000); gg.editAll("-" .. value, gg.TYPE_FLOAT); gg.clearResults()
    gg.searchNumber("0.30", gg.TYPE_FLOAT); gg.refineNumber("0.30", gg.TYPE_FLOAT)
    gg.getResults(250);  gg.editAll("3",         gg.TYPE_FLOAT); gg.clearResults()
    gg.alert("Go to suspension and tap Done."); gg.toast("Done")
end

function customUFO()
    gg.alert("Move suspension sliders to max, save, tap GG.")
    waitForGG()
    local input = gg.prompt({ "Value (e.g. 100)" }, nil, { "number" })
    if not input or not tonumber(input[1]) then gg.alert("Invalid value"); return end
    commonSuspension(tonumber(input[1]))
end

local function ufoV2Base()
    gg.setRanges(32)
    gg.searchNumber("3240099840", 32)
    local results = gg.getResults(100000)
    local FirstResults = {}; local SecondResults = {}; local FinalResults = {}; local NIndex = 1
    for i, result in ipairs(results) do
        FirstResults[NIndex]  = { address = result.address - 40,  flags = 32 }
        SecondResults[NIndex] = { address = result.address - 84,  flags = 32 }
        NIndex = NIndex + 1
    end
    FirstResults  = gg.getValues(FirstResults)
    SecondResults = gg.getValues(SecondResults)
    NIndex = 1
    for i, value in ipairs(FirstResults) do
        if FirstResults[i].value == 1099511627776 and SecondResults[i].value == 1099511627776 then
            FinalResults[NIndex] = value; NIndex = NIndex + 1
        end
    end
    for i, FR in ipairs(FinalResults) do FR.address = FR.address + 40; FR.flags = 16 end
    gg.loadResults(FinalResults)
    gg.getResults(gg.getResultsCount())
    return FinalResults
end

function ufoV2(editVal)
    gg.setVisible(false)
    gg.alert("Set incline to 10, then tap GG.")
    waitForGG(); clearReset()
    ufoV2Base()
    gg.editAll(tostring(editVal), 16)
    gg.toast("UFO ON"); clearReset()
end

function customufo()
    gg.setVisible(false)
    local d = gg.prompt({ "UFO Value:", "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return end
    gg.alert("Set incline to 10, then tap GG.")
    waitForGG(); clearReset()
    ufoV2Base()
    gg.editAll("-" .. d[1], 16)
    gg.toast("UFO ON"); clearReset()
end

local function angleBase()
    gg.setRanges(32)
    gg.searchNumber("5051983251797285274", 32)
    local results = gg.getResults(100000)
    local FirstResults = {}; local SecondResults = {}; local FinalResults = {}; local NIndex = 1
    for i, result in ipairs(results) do
        FirstResults[NIndex]  = { address = result.address + 76, flags = 32 }
        SecondResults[NIndex] = { address = result.address - 4,  flags = 32 }
        NIndex = NIndex + 1
    end
    FirstResults  = gg.getValues(FirstResults)
    SecondResults = gg.getValues(SecondResults)
    NIndex = 1
    for i, value in ipairs(FirstResults) do
        if FirstResults[i].value == 4870080048181673984 and SecondResults[i].value == 4510805389542529434 then
            FinalResults[NIndex] = value; NIndex = NIndex + 1
        end
    end
    for i, FR in ipairs(FinalResults) do FR.address = FR.address - 28; FR.flags = 16 end
    gg.loadResults(FinalResults)
    gg.refineNumber("30", 16)
    gg.getResults(gg.getResultsCount())
end

function applyAngle(val)
    gg.setVisible(false)
    gg.alert("Set steering to 30 and save, then tap GG.")
    waitForGG(); clearReset()
    angleBase()
    gg.editAll(tostring(val), 16)
    gg.toast("Angle " .. val .. " ON"); clearReset()
end

function customangle()
    gg.setVisible(false)
    local d = gg.prompt({ "Angle Value:", "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return end
    gg.alert("Set steering to 30 and save, then tap GG.")
    waitForGG(); clearReset()
    angleBase()
    gg.editAll(d[1], 16)
    gg.toast("Angle ON"); clearReset()
end

-- ============================================================
-- CHROME MENU
-- ============================================================
function Menu_chromecar()
    local m = gg.choice({
        "Chrome Specular (any part)",
        "Chrome Main (any part)",
        "1-Tap Chrome Rim",
        "1-Tap Chrome Body (main)",
        "Chrome Car",
        "Chrome Wheel",
        "Chrome Headlight",
        "Chrome Caliper",
        "Chrome Windows",
        "Custom Chrome Car",
        "Custom Chrome Wheel",
        "Custom Chrome Headlight",
        "Custom Chrome Caliper",
        "Custom Chrome Windows",
        "BACK"
    }, nil, title)
    if m == nil or m == 15 then Menu_custom(); return end
    if m == 1  then chromeCarRim()                        end
    if m == 2  then chromeHeadlightFlasherCaliperWindow() end
    if m == 3  then chromerims()                          end
    if m == 4  then runEdit()                             end
    if m == 5  then chromecar()                           end
    if m == 6  then chromewheel()                         end
    if m == 7  then chromeheadlight()                     end
    if m == 8  then chromecaliper()                       end
    if m == 9  then chromewindows()                       end
    if m == 10 then customchromecar()                     end
    if m == 11 then customchromewheel()                   end
    if m == 12 then customchromeheadlight()               end
    if m == 13 then customchromecaliper()                 end
    if m == 14 then customchromewindows()                 end
end

local function chromeScan()
    for i = 1, 3 do
        gg.setVisible(false)
        gg.alert("Slide color UP then tap GG.")
        waitForGG()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber(1, gg.TYPE_FLOAT)
        gg.setVisible(false)
        gg.alert("Slide color DOWN then tap GG.")
        waitForGG()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.refineNumber(0, gg.TYPE_FLOAT)
    end
end

function chromeCarRim()
    gg.alert("Select body part (SPECULAR), then tap GG.")
    waitForGG()
    gg.setVisible(false); gg.setRanges(gg.REGION_ANONYMOUS)
    chromeScan()
    local results = gg.getResults(999)
    if #results > 0 then gg.editAll(4, gg.TYPE_FLOAT); gg.toast("Chrome ON")
    else gg.alert("No values found.") end
    gg.clearResults()
end

local function colorPickerMenu()
    local colors = {"Blue #00FFFF","Green #00FF00","White #FFFFFF","Red #FF0000",
                    "Yellow #FFFF00","Orange #FF9900","Navy #0000FF","Purple #9900FF","Pink #FF00FF"}
    local codes  = {"#00FFFF","#00FF00","#FFFFFF","#FF0000","#FFFF00","#FF9900","#0000FF","#9900FF","#FF00FF"}
    local sel    = gg.choice(colors, nil, "Pick a Color")
    if not sel then return nil end
    gg.copyText(codes[sel])
    gg.alert("Code copied: " .. codes[sel] .. "\nPaste in color field, tap OK, then tap GG.")
    return codes[sel]
end

function chromeHeadlightFlasherCaliperWindow()
    colorPickerMenu()
    waitForGG(); gg.setVisible(false); gg.setRanges(gg.REGION_ANONYMOUS)
    chromeScan()
    gg.getResults(999); gg.editAll(4, gg.TYPE_FLOAT); gg.toast("Chrome ON"); gg.clearResults()
end

local function oneTapChrome(searchVal, offsetVal, validOffsets)
    gg.clearResults(); gg.setVisible(false); gg.setRanges(32)
    gg.searchNumber(searchVal, 32)
    local results = gg.getResults(9999)
    if #results == 0 then gg.alert("Value not found."); return end
    local value = 5; local edits = {}
    for _, res in ipairs(results) do
        local base = res.address + offsetVal
        local checkList = {}
        for j = 0, 2 do table.insert(checkList, { address = base - j * 4, flags = 16 }) end
        local values = gg.getValues(checkList)
        local valid = true
        for _, v in ipairs(values) do
            if v.value ~= 0 and (v.value < 0.0000000001 or v.value > 30) then valid = false; break end
        end
        if valid then for _, v in ipairs(values) do v.value = value; table.insert(edits, v) end end
    end
    if #edits > 0 then gg.setValues(edits); gg.toast("Done")
    else gg.toast("No matching values.") end
end

function chromerims()  oneTapChrome("50465865729",         0x104) end
function runEdit()     oneTapChrome("4942137642064704526", 0x104) end

local function sliderChromeSearch(searchQW, offsetCC, offsets3)
    gg.setVisible(false)
    gg.alert("Open car color section, then tap GG.")
    waitForGG(); clearReset(); gg.setRanges(32)
    local results = searchValue(searchQW, 32, nil)
    if not results then return end
    offsetData(results, offsetCC, 32)
    results = searchValue("2", 32, nil)
    if not results then return end
    local modifiedResults = {}
    for _, offset in ipairs(offsets3) do
        for i, result in ipairs(results) do
            table.insert(modifiedResults, { address = result.address + offset, flags = 16, value = -99 })
        end
    end
    gg.setValues(modifiedResults); gg.toast("ON"); clearReset()
end

function chromecar()   sliderChromeSearch("4251398048237748224", 0xCC,  {-0x68, -0x64, -0x60}) end
function chromewheel() sliderChromeSearch("4287426845256712192", 0x15C, {-0x58, -0x54, -0x50}) end

local function sliderChromeCustom(searchQW, offsetCC, offsets3, customVal)
    if not customVal then return end
    gg.setVisible(false)
    gg.alert("Open car color section, then tap GG.")
    waitForGG(); clearReset(); gg.setRanges(32)
    local results = searchValue(searchQW, 32, nil)
    if not results then return end
    offsetData(results, offsetCC, 32)
    results = searchValue("2", 32, nil)
    if not results then return end
    local modifiedResults = {}
    for _, offset in ipairs(offsets3) do
        for i, result in ipairs(results) do
            table.insert(modifiedResults, { address = result.address + offset, flags = 16, value = customVal })
        end
    end
    gg.setValues(modifiedResults); gg.toast("ON"); clearReset()
end

local function sliderChromeFull(label, doColor)
    gg.setVisible(false)
    gg.alert("Go to " .. label .. " slider, slide UP, tap GG.")
    waitForGG(); clearReset(); gg.setRanges(32)
    gg.searchNumber("1", 16); gg.getResults(9999)
    for i = 1, 2 do
        gg.setVisible(false)
        gg.alert("Slide DOWN, tap GG.")
        waitForGG(); gg.setVisible(false)
        gg.refineNumber("0", 16); gg.getResults(999999)
        gg.setVisible(false)
        gg.alert("Slide UP, tap GG.")
        waitForGG(); gg.setVisible(false)
        gg.refineNumber("1", 16); gg.getResults(999999)
    end
    local finalVal = "9"
    if doColor then
        local choice = gg.alert("Paste color code or pick one?", "Pick Color", "OK")
        if choice == 1 then colorPickerMenu() end
        gg.setVisible(false)
        gg.alert("Tap GG when ready.")
        waitForGG()
    end
    gg.refineNumber("1", 16); gg.getResults(9999); gg.editAll(finalVal, 16)
    gg.toast("ON"); clearReset()
end

local function sliderChromeFullCustom(label)
    local d = gg.prompt({ "Custom Chrome Value:", "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return end
    gg.setVisible(false)
    gg.alert("Go to " .. label .. " slider, slide UP, tap GG.")
    waitForGG(); clearReset(); gg.setRanges(32)
    gg.searchNumber("1", 16); gg.getResults(9999)
    for i = 1, 2 do
        gg.setVisible(false); gg.alert("Slide DOWN, tap GG."); waitForGG()
        gg.setVisible(false); gg.refineNumber("0", 16); gg.getResults(999999)
        gg.setVisible(false); gg.alert("Slide UP, tap GG."); waitForGG()
        gg.setVisible(false); gg.refineNumber("1", 16); gg.getResults(999999)
    end
    gg.refineNumber("1", 16); gg.getResults(9999); gg.editAll(d[1], 16)
    gg.toast("ON"); clearReset()
end

function chromeheadlight()   sliderChromeFull("HEADLIGHT", true)  end
function chromecaliper()     sliderChromeFull("CALIPER",   true)  end
function chromewindows()
    clearReset(); gg.setRanges(16384)
    gg.searchNumber("0.3", 16); gg.getResults(100); gg.editAll("3", 16)
    gg.alert("Go to Windows color."); gg.toast("ON"); clearReset()
end

function promptNum(label)
    local d = gg.prompt({ label, "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return nil end
    return d[1]
end

function customchromecar()
    local v = promptNum("Custom Chrome Car value")
    if v then sliderChromeCustom("4251398048237748224", 0xCC,  {-0x68,-0x64,-0x60}, v) end
end
function customchromewheel()
    local v = promptNum("Custom Chrome Wheel value")
    if v then sliderChromeCustom("4287426845256712192", 0x15C, {-0x58,-0x54,-0x50}, v) end
end

function customchromeheadlight() sliderChromeFullCustom("HEADLIGHT") end
function customchromecaliper()   sliderChromeFullCustom("CALIPER")   end
function customchromewindows()
    local d = gg.prompt({ "Custom Chrome Windows Value:", "Cancel" }, nil, { "number", "checkbox" })
    if not d or d[2] then return end
    clearReset(); gg.setRanges(16384)
    gg.searchNumber("0.3", 16); gg.getResults(100); gg.editAll(d[1], 16)
    gg.alert("Go to Windows color."); gg.toast("ON"); clearReset()
end

-- ============================================================
-- MAINTENANCE MENU
-- ============================================================
function Menu_modified()
    local m = gg.choice({
        "Max Fuel",
        "Repair Car",
        "No Damage (Engine)",
        "No Damage (Body)",
        "No Damage (Glass)",
        "Unlimited Fuel",
        "BACK"
    }, nil, title)
    if m == nil or m == 7 then Menu_custom(); return end
    if m == 1 then maxFuel()       end
    if m == 2 then repairCar()     end
    if m == 3 then nodamagengine() end
    if m == 4 then nodaamagebody() end
    if m == 5 then repaircarbody() end
    if m == 6 then unlimitedfuel() end
end

function nodamagengine()
    SecreDevPatch({ { 0x0, "D2800000h" }, { 0x4, "~A8 RET" } }, 0x3270C38)
    gg.toast("No Damage Engine ON")
end

function nodaamagebody()
    SecreDevPatch({ { 0x0, "D2800000h" }, { 0x4, "~A8 RET" } }, 0x3270C38)
    gg.toast("No Damage Body ON")
end

function repaircarbody()
    SecreDevPatch({ { 0x0, "D2800000h" }, { 0x4, "~A8 RET" } }, 0x32D19A8)
    gg.toast("Repair Body ON")
    gg.setVisible(false)
end

function repairCar()
    gg.setVisible(false); gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("4453159313487167488", gg.TYPE_QWORD)
    local count = gg.getResultsCount()
    if count == 0 then gg.alert("No repair data found!"); gg.clearResults(); return end
    local results = gg.getResults(math.min(count, 2))
    for i = 1, #results do results[i].flags = gg.TYPE_DWORD; results[i].value = 1 end
    gg.setValues(results); gg.clearResults(); gg.clearList()
    gg.toast("Car Repaired!")
end

function maxFuel()
    gg.setVisible(false); gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("4556721927168720896", gg.TYPE_QWORD)
    local count = gg.getResultsCount()
    if count == 0 then gg.alert("Fuel value not found!"); gg.clearResults(); return end
    local results = gg.getResults(1)
    results[1].flags = gg.TYPE_FLOAT; results[1].value = 80
    gg.setValues(results); gg.clearResults(); gg.clearList()
    gg.toast("Max Fuel Applied!")
end

function unlimitedfuel()
    gg.setVisible(false); gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("4556721927168720896", gg.TYPE_QWORD)
    local count = gg.getResultsCount()
    if count == 0 then gg.alert("Fuel value not found!"); gg.clearResults(); return end
    local results = gg.getResults(1)
    results[1].flags = gg.TYPE_FLOAT; results[1].value = 80; results[1].freeze = true
    gg.addListItems(results); gg.clearResults(); gg.clearList()
    gg.toast("Unlimited Fuel ON")
end

-- ============================================================
-- SPOILER MENU
-- FIX: syntax error — orphaned elseif branches are now inside the if block
-- ============================================================
local SPOILER_VALUES = {
    95, 172, 160, 120, 110, 111, 109, 113, 114, 115,
    117, 119, 106, 105, 101, 171, 168, 162, 161, 159,
    158, 157, 156, 155, 153, 151, 148, 147, 146, 127,
    198, 187, 188, 65, 69
}

local function spoilerBase(val)
    gg.setVisible(false)
    gg.alert("Tap EXTERIOR, then tap GG.")
    waitForGG(); clearReset()
    local results = searchModule("1657333858397323264", 32, "A", "Spoiler")
    if not results then return end
    local pr = pointerSearch(results, -0x550, 32)
    if not pr then return end
    local offsets   = { 0x20, 0x14, 0x3C }
    local flags     = { 4, 32, 4 }
    local valueInfo = {
        { key2 = { min = -2, max = 249 } },
        { key3 = { 34359738368, 68719476736 } },
        { key1 = { -2 } },
    }
    local gr = getResults(pr, offsets, flags)
    local fr = filterResults(gr, valueInfo)
    if fr then v_setValues(fr, { 0 }, { 4 }, { val }, true) end
    gg.alert("Tap another car, then come back."); gg.toast("ON"); clearReset()
end

function spoilermenu()
    local choices = {}
    for i = 1, 35 do table.insert(choices, "Spoiler " .. i) end
    table.insert(choices, "Custom Spoiler")   -- 36
    table.insert(choices, "Get Spoiler Code") -- 37
    table.insert(choices, "Get Premium Spoiler") -- 38
    table.insert(choices, "BACK")             -- 39

    local m = gg.choice(choices, nil, title)
    if m == nil or m == 39 then return end

    -- FIX: all branches now inside one if/elseif block (no orphaned elseif)
    if m >= 1 and m <= 35 then
        spoilerBase(SPOILER_VALUES[m])
    elseif m == 36 then
        local d = gg.prompt({ "Custom Spoiler Code:", "Cancel" }, nil, { "number", "checkbox" })
        if not d or d[2] then return end
        spoilerBase(d[1])
    elseif m == 37 then
        getSpoilerCode()
    elseif m == 38 then
        getPremiumSpoiler()
    end
end

function getSpoilerCode()
    gg.setVisible(false)
    gg.alert("Tap SPOILER, then tap GG.")
    waitForGG(); clearReset()
    gg.setRanges(32); gg.searchNumber("7", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("2", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("4294967295", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
    gg.loadResults(results); gg.getResults(9999)
    gg.alert("Tap a spoiler to get its code.")
    gg.setVisible(false)
    local v = gg.getResults(1)
    while not gg.isVisible() do
        local old = v[1].value; v = gg.getValues(v)
        if old ~= v[1].value then gg.toast("Code: " .. v[1].value) end
        gg.sleep(100)
    end
end

function getPremiumSpoiler()
    gg.setVisible(false)
    gg.alert("Tap PREMIUM SPOILER, then tap GG.")
    waitForGG(); clearReset()
    gg.setRanges(32); gg.searchNumber("7", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("2", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("4294967295", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
    gg.loadResults(results); gg.getResults(9999)
    gg.setVisible(false)
    local v = gg.getResults(1)
    for _, item in ipairs(v) do item.freeze = true end
    gg.addListItems(v)
    local value = v[1] and v[1].value or nil
    gg.clearResults()
    gg.alert("Buy another spoiler, then tap GG.")
    waitForGG(); gg.setVisible(false)
    local results2 = searchModule("1657333858397323264", 32, "A", "Spoiler")
    if not results2 then return end
    local pr2 = pointerSearch(results2, -0x550, 32)
    if not pr2 then return end
    local gr2 = getResults(pr2, { 0x20, 0x14, 0x3C }, { 4, 32, 4 })
    local fr2 = filterResults(gr2, {
        { key2 = { min = -2, max = 249 } },
        { key1 = { 34359738368 } },
        { key1 = { -2 } },
    })
    if fr2 and value then v_setValues(fr2, { 0 }, { 4 }, { value }, true) end
    gg.alert("Tap another car, then come back."); gg.toast("ON"); clearReset()
end

-- ============================================================
-- ROOF MENU
-- FIX: syntax error — orphaned elseif branches are now inside the if block
-- ============================================================
local ROOF_VALUES = { 4, 5, 6, 13, 14, 15, 16, 17, 20, 21, 35, 39, 32, 69, 75 }

local function roofBase(val)
    gg.setVisible(false)
    gg.alert("Tap EXTERIOR, then tap GG.")
    waitForGG(); clearReset()
    local results = searchModule("1657333858397323264", 32, "A", "Roof")
    if not results then return end
    local pr = pointerSearch(results, -0x550, 32)
    if not pr then return end
    local offsets   = { 0x14, 0x24, 0x20 }
    local flags     = { 32, 4, 4 }
    local valueInfo = {
        { key1 = { 34359738368 } },
        { key2 = { min = -2, max = 9 } },
    }
    local gr = getResults(pr, offsets, flags)
    local fr = filterResults(gr, valueInfo)
    if fr then v_setValues(fr, { 0x24, 0x20 }, { 4 }, { val }, true) end
    gg.alert("Tap another car, then come back."); gg.toast("ON"); clearReset()
end

function roofmenu()
    local choices = {}
    for i = 1, 15 do table.insert(choices, "Roof " .. i) end
    table.insert(choices, "Custom Roof")      -- 16
    table.insert(choices, "Get Roof Code")    -- 17
    table.insert(choices, "Get Premium Roof") -- 18
    table.insert(choices, "BACK")             -- 19

    local m = gg.choice(choices, nil, title)
    if m == nil or m == 19 then return end

    -- FIX: all branches now inside one if/elseif block (no orphaned elseif)
    if m >= 1 and m <= 15 then
        roofBase(ROOF_VALUES[m])
    elseif m == 16 then
        local d = gg.prompt({ "Custom Roof Code:", "Cancel" }, nil, { "number", "checkbox" })
        if not d or d[2] then return end
        roofBase(d[1])
    elseif m == 17 then
        getRoofCode()
    elseif m == 18 then
        getPremiumRoof()
    end
end

function getRoofCode()
    gg.setVisible(false)
    gg.alert("Tap ROOF, then tap GG.")
    waitForGG(); clearReset()
    gg.setRanges(32); gg.searchNumber("7", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("2", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("4294967295", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
    gg.loadResults(results); gg.getResults(9999)
    gg.alert("Tap a roof to get its code.")
    gg.setVisible(false)
    local v = gg.getResults(1)
    while not gg.isVisible() do
        local old = v[1].value; v = gg.getValues(v)
        if old ~= v[1].value then gg.toast("Code: " .. v[1].value) end
        gg.sleep(100)
    end
end

function getPremiumRoof()
    gg.setVisible(false)
    gg.alert("Tap PREMIUM ROOF, then tap GG.")
    waitForGG(); clearReset()
    gg.setRanges(32); gg.searchNumber("7", 32)
    local results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0xF0; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("2", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address + 0x70; ofs.flags = 32 end
    gg.loadResults(results); gg.refineNumber("4294967295", 32); results = gg.getResults(100000)
    for i, ofs in ipairs(results) do ofs.address = ofs.address - 0x38; ofs.flags = 4 end
    gg.loadResults(results); gg.getResults(9999)
    gg.setVisible(false)
    local v = gg.getResults(1)
    for _, item in ipairs(v) do item.freeze = true end
    gg.addListItems(v)
    local value = v[1] and v[1].value or nil
    gg.clearResults()
    gg.alert("Buy another roof, then tap GG.")
    waitForGG(); gg.setVisible(false)
    local results2 = searchModule("1657333858397323264", 32, "A", "Roof")
    if not results2 then return end
    local pr2 = pointerSearch(results2, -0x550, 32)
    if not pr2 then return end
    local gr2 = getResults(pr2, { 0x14, 0x24, 0x20 }, { 32, 4, 4 })
    local fr2 = filterResults(gr2, {
        { key1 = { 34359738368 } },
        { key2 = { min = -2, max = 9 } },
    })
    if fr2 and value then v_setValues(fr2, { 0 }, { 4 }, { value }, true) end
    gg.alert("Tap another car, then come back."); gg.toast("ON"); clearReset()
end

-- ============================================================
-- [NEW] CARS BREAK MENU (integrated from BETA script)
-- Room-based prank: break other players' cars by entering them
-- Anti-cheat patches + car physics exploits
-- ============================================================
function Menu_CarsBreak()
    local lib2  = getLib2()
    local libXa = getLibXa()

    -- Anti-cheat / anti-kick via SecreDevPatch (consistent with rest of script)
    SecreDevPatch({ { 0x0, "000080D2h" } }, 0x31F19FC) -- MainCarCondition
    SecreDevPatch({ { 0x0, "000080D2h" } }, 0x35738D0) -- CarDebugTools Start
    SecreDevPatch({ { 0x0, "000080D2h" } }, 0x35750BC) -- CarDebugTools Update
    SecreDevPatch({ { 0x0, "000080D2h" } }, 0x3569F64) -- IsCheatActivated
    SecreDevPatch({ { 0x0, "200080D2h" }, { 0x4, "C0035FD6h" } }, 0x333A8F8)
    SecreDevPatch({ { 0x0, "200080D2h" }, { 0x4, "C0035FD6h" } }, 0x33B0800)
    SecreDevPatch({ { 0x0, "200080D2h" }, { 0x4, "C0035FD6h" } }, 0x367B478)
    SecreDevPatch({ { 0x0, "200080D2h" }, { 0x4, "C0035FD6h" } }, 0x33541F0) -- Room password bypass style
    gg.toast("Anti-Cheat patched ✅")

    local INCARS_OFFSET = 0x3660024

    local function applyBreakPatch()
        SecreDevPatch({ { 0x0, "200080D2h" }, { 0x4, "C0035FD6h" } }, INCARS_OFFSET)
        gg.toast("InCar patch applied ✅")
    end

    local function applyPhysicsBreak()
        -- Teleport / physics crash from BETA script
        local void1 = 0x31FE6D0
        gg.setRanges(gg.REGION_CODE_APP)
        gg.searchNumber("2.6", gg.TYPE_FLOAT)
        local rev = gg.getResults(500)
        gg.editAll("1.8~1.99999", gg.TYPE_FLOAT)
        gg.sleep(100); gg.processResume()
        gg.clearResults()

        local pDRAG = {
            { address = lib2 + void1, flags = 4, value = "FF4302D1h" }
        }
        gg.setValues(pDRAG)
        gg.sleep(80)
        gg.alert("[INDO] TURUN dari mobil KAMU! NAIK ke kursi PENGEMUDI.\n[EN] Get OUT of YOUR car! Get BACK into DRIVER seat!")
        gg.toast("Break Cars applied ✅")
    end

    local function revertPhysicsBreak()
        gg.setRanges(gg.REGION_CODE_APP)
        gg.searchNumber("1.8~1.99999", gg.TYPE_FLOAT)
        local rev = gg.getResults(500)
        gg.editAll("2.6", gg.TYPE_FLOAT)
        gg.sleep(100); gg.processResume(); gg.clearResults()
        gg.toast("Physics reverted ✅")
    end

    -- Show tutorial on first entry
    local tutorial = gg.choice({
        "Read Tutorial (ID/EN)",
        "SKIP Tutorial",
    }, nil, "CARS BREAK - PROGRAM BETA")
    if tutorial == 1 then
        gg.alert(
            "[INDO] Masuk room, naik ke kursi PENUMPANG mobil lawan, lalu aktifkan CARS BREAK.\n" ..
            "Turun dari mobil mereka. Naik ke kursi pengemudi.\n\n" ..
            "[EN] Enter room, get into PASSENGER SEAT of enemy car, activate CARS BREAK.\n" ..
            "Get out, then get into driver seat.\n\n" ..
            "⚠️ PROGRAM BETA - no force close on your end."
        )
    end

    -- Main Cars Break loop
    local aktif = true
    while aktif do
        if gg.isVisible(true) then
            gg.setVisible(false)
            local menu = gg.choice({
                "🗝️ ON RUN SPEED (In/Out Cars)",
                "🔑 OFF RUN SPEED (In/Out Cars)",
                "😈 CARS BREAK (Enter enemy car first)",
                "💥 DAMAGE CARS (Physics break)",
                "🚪 BACK to Main Menu",
            }, nil, "CARS BREAK — PROGRAM BETA")

            if menu == 1 then
                applyBreakPatch()
                gg.alert("Now enter another player's passenger seat, then get out.")
            elseif menu == 2 then
                revertPhysicsBreak()
            elseif menu == 3 then
                -- MainCarCondition: MOV W0, #1 + RET via SecreDevPatch
                SecreDevPatch({ { 0x0, "D2800020h" }, { 0x4, "D65F03C0h" } }, 0x320A1EC)
                applyBreakPatch()
                gg.alert("[INDO] Naik ke kursi PENUMPANG lawan, lalu turun.\n[EN] Get into PASSENGER seat, then exit.")
                gg.toast("Cars Break ON ✅")
            elseif menu == 4 then
                applyPhysicsBreak()
            elseif menu == 5 then
                aktif = false
            end
        end
        gg.sleep(100)
    end
end

-- SMJ VISUAL / GLOW / COLOR / KITS (search-based)

function caliper_blue()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒃𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒃𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#0000FF")
    gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function caliper_cayan()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑪𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑪𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FFFF")
    gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function caliper_green()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FF00")
    gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.clearResults()
gg.setRanges(0)
end

function caliper_orange()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFA500")
    gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end



-- ~~ FEATURE FUNCTIONS: WING COLORS ~~

function caliper_pink()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF00FF")
    gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function caliper_purple()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#9a5cff")
    gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅")

gg.clearResults()
gg.setRanges(0)
end

function caliper_red()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF0000")
    gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function caliper_white()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFFFF")
    gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function caliper_yellow()
gg.alert("𝑮𝒐 𝒕𝒐 𝑪𝒂𝒊𝒍𝒑𝒆𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFF00")
    gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")

gg.clearResults()
gg.setRanges(0)
end

function chrome_body()
gg.alert("𝑮𝒐 𝒕𝒐 𝑺𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒊𝒏 𝒄𝒂𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒐𝒐𝒔𝒆 𝒚𝒐𝒖𝒓 𝒄𝒐𝒍𝒐𝒓 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("1000", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.toast("𝒂𝒅𝒅𝒆𝒅 𝒔𝒖𝒄𝒄𝒆𝒔𝒔𝒇𝒖𝒍𝒍𝒚 ✅️")
end

function color_blue()
local code = "#0000FF"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_cayan()
local code = "#00FFFF"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end





--Change ID ✅️


-- ~~ FEATURE FUNCTIONS: SUB-MENU WRAPPERS (M1..M19) ~~

function color_green()
local code = "#00FF00"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_orange()
local code = "#FFA500"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_pink()
local code = "#FF00FF"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_purple()
    local code = "#9a5cff"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_red()
local code = "#FF0000"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function color_white()
    local code = "#FFFFFF"
    gg.setClipboard(code)
    gg.toast("Copied: " .. code)
    color()  
end

function color_yellow()
local code = "#FFFF00"
    gg.copyText(code)
    gg.toast("Copied: " .. code)
    color()
end

function gg_windows()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒅𝒐𝒘𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝑴𝒂𝒊𝒏 𝒄𝒐𝒍𝒐𝒓 𝒂𝒏𝒅 𝒔𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒕𝒐 𝒂𝒏𝒚 𝒄𝒐𝒍𝒐𝒓 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒕𝒉𝒊𝒄𝒌𝒏𝒆𝒔𝒔 𝒐𝒇 𝒕𝒊𝒏𝒕 𝒕𝒐 𝒕𝒉𝒆 𝒍𝒆𝒂𝒔𝒕 𝒊𝒏 𝒃𝒐𝒕𝒉 𝒔𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒂𝒏𝒅 𝒎𝒂𝒊𝒏 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑵𝒐𝒘 𝒈𝒐 𝒕𝒐 𝒔𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.processResume()
gg.searchNumber("0.3", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("3", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.alert("𝑫𝒐𝒏𝒆, 𝒄𝒍𝒐𝒔𝒆 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒈𝒆𝒕 𝒃𝒂𝒄𝒌 𝒕𝒉𝒆𝒏 𝒓𝒆𝒔𝒕𝒂𝒓𝒕 𝒈𝒂𝒎𝒆")
end

--Change ID

function glow_rims()
gg.alert("𝑮𝒐 𝒕𝒐 𝑺𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒊𝒏 𝒄𝒂𝒓 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_JAVA_HEAP | gg.REGION_ANONYMOUS | gg.REGION_CODE_APP)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒐𝒐𝒔𝒆 𝒚𝒐𝒖𝒓 𝒄𝒐𝒍𝒐𝒓 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("1000", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.toast("𝑪𝒖𝒔𝒕𝒐𝒎 𝒄𝒐𝒍𝒐𝒓 𝒂𝒅𝒅𝒆𝒅 𝒔𝒖𝒄𝒄𝒆𝒔𝒔𝒇𝒖𝒍𝒍𝒚 ✅️")
end

function headlights_blue()-- -100;-100;100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑩𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑩𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#0000FF")
    gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_cyan()-- -100;100;100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒄𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒄𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FFFF")
    gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_green()-- 100;-100;100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FF00")
    gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_orange()
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFA500")
    gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_pink()-- 100;100;-100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF00FF")
    gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_purple()
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#9a5cff")
    gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_red()-- -100;100;-100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF0000")
    gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_white()-- 100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFFFF")
    gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function headlights_yellow()-- 100;-100;-100
gg.alert("𝑮𝒐 𝒕𝒐 𝒉𝒆𝒂𝒅𝒍𝒊𝒈𝒉𝒕𝒔 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFF00")
    gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

-- kits() was broken (called undefined findCode/main). Redirect to working unlocks.
function kits()
    local m = gg.choice({
        "Premium Body Kits (SecreDevPatch)",
        "Event Cars Unlock",
        "BACK"
    }, nil, "Kits / Event Cars")
    if not m or m == 3 then return end
    if m == 1 then pcall(premiumkits) end
    if m == 2 then pcall(eventCarsMenu) end
end

-- longName() was broken (called undefined main). Redirect to working bypass.
function longName()
    bypasslongname()
end




--suspension ✅️

function matte_rims()
gg.alert("𝑮𝒐 𝒕𝒐 𝒓𝒊𝒎𝒔 𝒓𝒆𝒇𝒍𝒆𝒄𝒕𝒊𝒐𝒏 𝒑𝒂𝒈𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("-13", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.toast("𝒂𝒅𝒅𝒆𝒅 𝒔𝒖𝒄𝒄𝒆𝒔𝒔𝒇𝒖𝒍𝒍𝒚 ✅️")
end

function shiny_body()
gg.alert("𝑮𝒐 𝒕𝒐 𝒄𝒂𝒓 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒔𝒆𝒕 𝒎𝒂𝒊𝒏 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒔𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒐𝒐𝒔𝒆 𝒚𝒐𝒖𝒓 𝒄𝒐𝒍𝒐𝒓 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("3", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.toast("𝒂𝒅𝒅𝒆𝒅 𝒔𝒖𝒄𝒄𝒆𝒔𝒔𝒇𝒖𝒍𝒍𝒚 ✅️")
end

function shiny_rims()
gg.alert("𝑮𝒐 𝒕𝒐 𝒓𝒊𝒎𝒔 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒔𝒆𝒕 𝒎𝒂𝒊𝒏 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒔𝒑𝒆𝒄𝒖𝒍𝒂𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
    gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.processResume()
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("3", gg.TYPE_FLOAT)
gg.processResume()

gg.clearResults()
gg.setRanges(0)
gg.toast("𝒂𝒅𝒅𝒆𝒅 𝒔𝒖𝒄𝒄𝒆𝒔𝒔𝒇𝒖𝒍𝒍𝒚 ✅️")
end

function vinyls()
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.searchNumber("4125403948678906056", gg.TYPE_QWORD)
gg.getResults(10)
gg.editAll("4107389518468874273", gg.TYPE_QWORD)
gg.toast("Limits Vinyls Increased")
end




------------------------------------------Start of prank
-- CHANGENAME + RUNCHARACTER removed per salman's request.



  





---------------------------------------------End of Prank





-- ~~ MAIN MENU (main()) ~~

gg.toast("وَإِنْ تَعُدُّوا نِعْمَةَ اللَّهِ لَا تُحْصُوهَا")

function wing_blue()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑩𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑩𝒍𝒖𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#0000FF")
    gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐁𝐥𝐮𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_cyan()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒄𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒄𝒚𝒂𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FFFF")
    gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐂𝐲𝐚𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_green()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑮𝒓𝒆𝒆𝒏 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#00FF00")
    gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐆𝐫𝐞𝐞𝐧 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_orange()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑶𝒓𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFA500")
    gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐎𝐫𝐚𝐧𝐠𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_pink()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒊𝒏𝒌 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF00FF")
    gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐢𝐧𝐤 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_purple()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑷𝒖𝒓𝒑𝒍𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#9a5cff")
    gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐏𝐮𝐫𝐩𝐥𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end



-- ~~ FEATURE FUNCTIONS: RIM / BODY / WINDOW / VINYL COLORS ~~

function wing_red()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑹𝒆𝒅 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FF0000")
    gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐑𝐞𝐝 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_white()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝑾𝒉𝒊𝒕𝒆 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFFFF")
    gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐖𝐡𝐢𝐭𝐞 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end

function wing_yellow()
gg.alert("𝑮𝒐 𝒕𝒐 𝒘𝒊𝒏𝒈𝒔 𝒌𝒊𝒕 𝒑𝒂𝒈𝒆 𝒂𝒏𝒅 𝒄𝒉𝒐𝒐𝒔𝒆 𝒂𝒏𝒚 𝒘𝒊𝒏𝒈 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑪𝒉𝒂𝒏𝒈𝒆 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒃𝒍𝒂𝒄𝒌 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.refineNumber("0", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("𝑺𝒆𝒕 𝒄𝒐𝒍𝒐𝒓 𝒕𝒐 𝒘𝒉𝒊𝒕𝒆 \n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
local brightness_options = {
    "𝑳𝒐𝒘",
    "𝑴𝒆𝒅𝒊𝒖𝒎",
    "𝑯𝒊𝒈𝒉",
    "𝑽𝒆𝒓𝒚 𝑯𝒊𝒈𝒉",
}
local dialog_title = "𝑪𝒉𝒐𝒐𝒔𝒆 𝒄𝒐𝒍𝒐𝒓 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔:"

-- Use the non-standard argument order for button_menu that works for your GG setup
local choice_index = button_menu(brightness_options, dialog_title, nil, "𝑪𝒉𝒐𝒐𝒔𝒆 𝑩𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔")

local selected_brightness_value

if choice_index == 1 then
    selected_brightness_value = "5"
elseif choice_index == 2 then
    selected_brightness_value = "5000"
elseif choice_index == 3 then
    selected_brightness_value = "9000"
elseif choice_index == 4 then
    selected_brightness_value = "90000"
else
    -- Fallback or error handling if no valid choice is made (user might cancel)
    gg.toast("𝑵𝒐 𝒃𝒓𝒊𝒈𝒉𝒕𝒏𝒆𝒔𝒔 𝒔𝒆𝒍𝒆𝒄𝒕𝒆𝒅, 𝒅𝒆𝒇𝒂𝒖𝒍𝒕𝒊𝒏𝒈 𝒕𝒐 𝑯𝒊𝒈𝒉.")
    selected_brightness_value = "9000" -- Default to medium if user cancels or an issue occurs
end
gg.alert("𝑨𝒑𝒑𝒍𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆\n\n𝑾𝒉𝒆𝒏 𝒚𝒐𝒖 𝒂𝒓𝒆 𝒓𝒆𝒂𝒅𝒚 𝒄𝒍𝒊𝒄𝒌 𝒐𝒏 𝒈𝒈")
local copy_cayan = button_menu({"Yes", "No"}, nil, "𝑫𝒐 𝒚𝒐𝒖 𝒘𝒂𝒏𝒕 𝒕𝒐 𝒄𝒐𝒑𝒚 𝒕𝒉𝒆 𝒀𝒆𝒍𝒍𝒐𝒘 𝒄𝒐𝒍𝒐𝒓 𝒄𝒐𝒅𝒆?")
if copy_cayan == 1 then
    gg.copyText("#FFFF00")
    gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐝𝐞 𝐜𝐨𝐩𝐢𝐞𝐝 ✅️")
end
while not gg.isVisible() do
 gg.sleep(100)
end
gg.setVisible(false)
gg.processResume()
gg.refineNumber("1", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(selected_brightness_value, gg.TYPE_FLOAT)
gg.processResume()
gg.toast("𝐘𝐞𝐥𝐥𝐨𝐰 𝐜𝐨𝐥𝐨𝐫 𝐚𝐝𝐝𝐞𝐝 𝐬𝐮𝐜𝐜𝐞𝐬𝐬𝐟𝐮𝐥𝐥𝐲 ✅️")
gg.setRanges(0)

gg.clearResults()
gg.processResume()
end




-- ============================================================
-- SEARCH UNLOCKS (Open Source)
-- ============================================================
function unlockCarSearchV3()
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("13;133;132;29;53;99;100;102;37;21;48;77;74;2;23;51;163;186;158;55;39;181;196;160;220;197;47;66;1;106;76;0;43;254;152;108;82;81;146;204;147;210;148;149;49::200", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then gg.alert("No results found."); return end
    local input = gg.prompt({"Example: lambo = 18\nEnter Car Value:"}, {"18"}, {"number"})
    if not input then return end
    gg.editAll(tonumber(input[1]), gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Car bypassed (Search V3)")
end

function unlockCarSearchV4()
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("119;0;0;0;0;256;0;13:29", gg.TYPE_DWORD)
    gg.refineNumber("13", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then gg.alert("No results found."); return end
    local input = gg.prompt({"Example: lambo = 18\nEnter Car Value:"}, {"18"}, {"number"})
    if not input then return end
    gg.editAll(tonumber(input[1]), gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Car bypassed (Search V4)")
end

-- ============================================================
-- PRANK MENU (search-based)
-- ============================================================
function Prankmenu()
    local m = gg.choice({
        "SPAM CHAT ROOM",
        "BUY CAR CELL (Room)",
        "FULL SHADOW WALL (Room)",
        "FLY CARS ALL (Room)",
        "RUN CHARACTER (Garage)",
        "CHANGE NAME PLAYER (Room)",
        "ADD MONEY IN DONATS CIRCLE",
        "TOWING FIGHT / COG RESET",
        "TOWING EK9 / SHADOW BODY",
        "OPEN W16 + POLICE SIREN",
        "BACK"
    }, nil, "PRANK MENU")
    if not m or m == 11 then return end
    if m == 1 then F1() end
    if m == 2 then F2() end
    if m == 3 then F3() end
    if m == 4 then F4() end
    if m == 5 then F5() end
    if m == 6 then F12() end
    if m == 7 then F15() end
    if m == 8 then F18() end
    if m == 9 then F20() end
    if m == 10 then F22() end
end

function F1()
    pcall(function()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber("12", gg.TYPE_FLOAT)
        local r = gg.getResults(50)
        if #r > 0 then gg.editAll("9999999999", gg.TYPE_FLOAT) end
        gg.clearResults()
    end)
    gg.toast("Spam Chat limits raised")
end

function F2()
    local d = gg.prompt({"ENTER THE PRICE","BACK"}, nil, {"number","checkbox"})
    if not d or d[2] then return end
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(d[1].."x4", 4)
    gg.getResults(1000)
    gg.editAll("0x4", 4)
    gg.clearResults()
    gg.toast("Buy Car Cell ON")
end

function F3()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("-10;49", gg.TYPE_FLOAT)
    gg.refineNumber("-10", gg.TYPE_FLOAT)
    gg.getResults(500)
    gg.editAll("9", gg.TYPE_FLOAT)
    gg.processResume()
    gg.sleep(100)
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("0.04899999872;0.15000000596;-10.0:25", gg.TYPE_FLOAT)
    gg.refineNumber("-10", gg.TYPE_FLOAT)
    gg.getResults(99999)
    gg.editAll("25", gg.TYPE_FLOAT)
    gg.processResume()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0.05000000075;180.0:5", gg.TYPE_FLOAT)
    gg.refineNumber("180", gg.TYPE_FLOAT)
    gg.getResults(500)
    gg.editAll("15", gg.TYPE_FLOAT)
    gg.clearResults()
    gg.toast("Shadow Wall ON")
end

function F4()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("-499~-400", gg.TYPE_FLOAT)
    gg.getResults(500)
    gg.editAll("999", gg.TYPE_FLOAT)
    gg.sleep(1500)
    gg.getResults(500)
    gg.editAll("-499~-400", gg.TYPE_FLOAT)
    gg.clearResults()
    gg.toast("Fly Cars applied")
end

function F5()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1.8~1.99999", gg.TYPE_FLOAT)
    gg.getResults(500)
    gg.editAll("2.6", gg.TYPE_FLOAT)
    gg.processResume()
    gg.clearResults()
    gg.toast("Run Character ON")
end

function F12()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("7 077 968;7 929 953;7 471 205;3 670 051;3 211 321;10:23", gg.TYPE_DWORD)
    gg.refineNumber("7 077 968;7 929 953;7 471 205;3 670 051;3 211 321", gg.TYPE_DWORD)
    gg.getResults(100)
    gg.editAll(";DEVELOPER", gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Name change applied")
end

function F15()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("6;5;4;444444;1:289", gg.TYPE_DWORD)
    gg.refineNumber("1", gg.TYPE_DWORD)
    local t = gg.getResults(500)
    gg.addListItems(t)
    local o = gg.getResults(1)
    if o and o[1] then
        gg.setValues({{address = o[1].address + 0x4, flags = gg.TYPE_DWORD, value = 1472902653, freeze = true}})
    end
    gg.clearResults()
    gg.toast("Donats money applied")
end

function F18()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("0,04899999872;-1.,14199995995;0,15000000596;-10,0:25", gg.TYPE_FLOAT)
    gg.refineNumber("-1.14199995995", gg.TYPE_FLOAT)
    gg.getResults(100)
    gg.editAll("-3005", gg.TYPE_FLOAT)
    gg.clearResults()
    gg.toast("Towing / Cog Reset ON")
end

function F20()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("0.64705002308;0.99995863438;0.97:25", gg.TYPE_FLOAT)
    gg.refineNumber("0.64", gg.TYPE_FLOAT)
    gg.getResults(99999)
    gg.editAll("290", gg.TYPE_DWORD)
    gg.clearResults()
    gg.toast("Shadow Body ON")
end

function F22()
    pcall(W16)
    pcall(unlockpolicecar)
    gg.toast("W16 + Police Siren applied")
end

-- ============================================================
-- GLOWS / VISUALS (Smj search-based)
-- ============================================================
function Menu_Glows()
    local m = gg.choice({
        "Headlights Colors",
        "Calipers Colors",
        "Wings Colors",
        "Rims (Matte / Shiny / Glow)",
        "Body (Chrome / Shiny)",
        "Windows (GG Windows)",
        "Color Codes (copy)",
        "Vinyls Limit Increase",
        "Find Kits Codes",
        "BACK"
    }, nil, "GLOWS / VISUALS (search-based)")
    if not m or m == 10 then return end
    if m == 1 then Menu_Headlights() end
    if m == 2 then Menu_Calipers() end
    if m == 3 then Menu_Wings() end
    if m == 4 then Menu_Rims() end
    if m == 5 then Menu_BodyVisual() end
    if m == 6 then pcall(gg_windows) end
    if m == 7 then Menu_ColorCodes() end
    if m == 8 then pcall(vinyls) end
    if m == 9 then pcall(kits) end
end

function Menu_Headlights()
    local m = gg.choice({"Cyan","Blue","Red","Yellow","Green","Pink","White","Purple","Orange","BACK"}, nil, "Headlights")
    if not m or m == 10 then return end
    local fns = {headlights_cyan,headlights_blue,headlights_red,headlights_yellow,headlights_green,headlights_pink,headlights_white,headlights_purple,headlights_orange}
    pcall(fns[m])
end

function Menu_Calipers()
    local m = gg.choice({"Cyan","Blue","Red","Yellow","Green","Pink","White","Purple","Orange","BACK"}, nil, "Calipers")
    if not m or m == 10 then return end
    local fns = {caliper_cayan,caliper_blue,caliper_red,caliper_yellow,caliper_green,caliper_pink,caliper_white,caliper_purple,caliper_orange}
    pcall(fns[m])
end

function Menu_Wings()
    local m = gg.choice({"Cyan","Blue","Red","Yellow","Green","Pink","White","Orange","Purple","BACK"}, nil, "Wings")
    if not m or m == 10 then return end
    local fns = {wing_cyan,wing_blue,wing_red,wing_yellow,wing_green,wing_pink,wing_white,wing_orange,wing_purple}
    pcall(fns[m])
end

function Menu_Rims()
    local m = gg.choice({"Matte Rims","Shiny Rims","Glow Rims","BACK"}, nil, "Rims")
    if not m or m == 4 then return end
    if m == 1 then pcall(matte_rims) end
    if m == 2 then pcall(shiny_rims) end
    if m == 3 then pcall(glow_rims) end
end

function Menu_BodyVisual()
    local m = gg.choice({"Chrome Body","Shiny Body","BACK"}, nil, "Body Visual")
    if not m or m == 3 then return end
    if m == 1 then pcall(chrome_body) end
    if m == 2 then pcall(shiny_body) end
end

function Menu_ColorCodes()
    local m = gg.choice({
        "Purple #9a5cff","Red #FF0000","Orange #FFA500","Yellow #FFFF00",
        "Green #00FF00","White #FFFFFF","Blue #0000FF","Pink #FF00FF","Cyan #00FFFF","BACK"
    }, nil, "Color Codes (copy)")
    if not m or m == 10 then return end
    local fns = {color_purple,color_red,color_orange,color_yellow,color_green,color_white,color_blue,color_pink,color_cayan}
    pcall(fns[m])
end


-- ============================================================
-- EXIT
-- ============================================================
function Exit()
    running = false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
while running do
    if gg.isVisible(true) then
        TEMPLATE = 1
        gg.setVisible(false)
    end
    if TEMPLATE == 1 then
        Home()
        TEMPLATE = -1
    end
end






    
    
    
 ------------------------------------------------ END --------------------------------------------
 -- DON'T DELETE IT

else
    os.exit()
end
 ------------------------------------------------ END --------------------------------------------