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
local SCRIPT_ID = "PRANKMENU" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10"
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CPM1_PRANK_MENU_v" .. CURRENT_VERSION .. ".lua"

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
  CPM1 PRANK MENU v4.9.10  — SCRIPT_ID = PRANKMENU
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
" CPM1 PRANK MENU 4.9.10\n" ..
" SCRIPT_ID: PRANKMENU\n" ..
"╚═══════════⊱✫⊰═══════════╝"


-- ============================================================
-- PRANK FUNCTIONS
-- ============================================================
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


-- Minimal stubs needed by F22
function W16()
    SecreDevPatch({ { 0x0, "2A0103F4h" } }, 0x4323978)
    gg.toast("W16 Unlocked")
end
function unlockpolicecar()
    SecreDevPatch({
        { 0x0, "52800020h" },
        { 0x4, "D65F03C0h" }
    }, 0x3FD9990)
    gg.toast("Police Siren ON")
end

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


-- ============================================================
-- HOME
-- ============================================================
local running = true
local TEMPLATE = 1
gg.setVisible(true)

function Home()
    local m = gg.choice({
        "『 🎭 OPEN PRANK MENU ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m == 1 then pcall(Prankmenu) end
    if m == 2 then running = false end
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
