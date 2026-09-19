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
local SCRIPT_ID = "UNLOCKSMENU" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10"
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CPM1_UNLOCKS_MENU_v" .. CURRENT_VERSION .. ".lua"

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
if JOHNZKIEPLYS == name then
else
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
        user = login_data[saved_u]
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
    
    server_cfg.version = content:match('"version":%s-"([^"]+)"')
    server_cfg.url = content:match('"script_url":%s-"([^"]+)"')
    server_cfg.new_name = content:match('"new_name":%s-"([^"]+)"')
    server_cfg.news = content:match('"news_msg":%s-"([^"]+)"')
    server_cfg.show_news = content:match('"show_news":%s-(true)') == "true"
    server_cfg.maintenance = content:match('"maintenance":%s-(true)') == "true"
    
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
  CPM1 UNLOCKS MENU v4.9.10  — SCRIPT_ID = UNLOCKSMENU
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

local function getLib2()
    return gg.getRangesList("libil2cpp.so")[2].start
end
local function getLibXa()
    return gg.getRangesList("libil2cpp.so")[1].start
end

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

-- ============================================================
-- LOADING
-- ============================================================
gg.setVisible(false)
for i = 0, 10 do
    local filled   = string.rep("#", i)
    local unfilled = string.rep("-", 10 - i)
    gg.toast("[" .. filled .. unfilled .. "] " .. (i * 10) .. "%")
    gg.sleep(40)
end

local title =
"╔═══════════⊱✫⊰═══════════╗\n" ..
" CPM1 UNLOCKS MENU 4.9.10\n" ..
" SCRIPT_ID: UNLOCKSMENU\n" ..
"╚═══════════⊱✫⊰═══════════╝"


-- ============================================================
-- UNLOCKS FUNCTIONS (from original 4.9.10)
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


-- ============================================================
-- HOME (Unlocks panel)
-- ============================================================
local running = true
local TEMPLATE = 1
gg.setVisible(true)

function Home()
    local m = gg.choice({
        "『 UNLOCK W16 ༒』",
        "『 UNLOCK ALL (Rims/Smoke/House/Light/W16) ༒』",
        "『 CLOTHES MENU ༒』",
        "『 UNLOCK TOYOTA CROWN ༒』",
        "『 UNLOCK TOYOTA CAMRY ༒』",
        "『 PREMIUM BODY KITS ༒』",
        "『 PREMIUM BODY KITS (manual) ༒』",
        "『 POLICE SIREN ༒』",
        "『 UNLOCK HOUSE ༒』",
        "『 FIX CHARACTERS ༒』",
        "『 EVENT CARS ༒』",
        "『 UNLOCK CAR (v1 lobby) ༒』",
        "『 UNLOCK CAR (v2 premium/V16) ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m == 1  then pcall(W16) end
    if m == 2  then pcall(unlockAll) end
    if m == 3  then pcall(Menu_Clothes) end
    if m == 4  then pcall(unlocktoyotacrown) end
    if m == 5  then pcall(unlocktoyotacamry) end
    if m == 6  then pcall(premiumkits) end
    if m == 7  then pcall(premiumkits_auto) end
    if m == 8  then pcall(unlockpolicecar) end
    if m == 9  then pcall(house) end
    if m == 10 then pcall(fixCharacters) end
    if m == 11 then pcall(eventCarsMenu) end
    if m == 12 then pcall(carunlock) end
    if m == 13 then pcall(unlockcar2) end
    if m == 14 then running = false end
    TEMPLATE = -1
end

function Exit()
    running = false
end

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
