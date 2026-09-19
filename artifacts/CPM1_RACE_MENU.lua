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
local SCRIPT_ID = "RACEMENU" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10"
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CPM1_RACE_MENU_v" .. CURRENT_VERSION .. ".lua"

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
  CPM1 RACE / DRIFT / ENGINE MENU v4.9.10  — SCRIPT_ID = RACEMENU
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
" CPM1 RACE / DRIFT / ENGINE MENU 4.9.10\n" ..
" SCRIPT_ID: RACEMENU\n" ..
"╚═══════════⊱✫⊰═══════════╝"


-- ============================================================
-- RACE / DRIFT / ENGINE
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


-- ============================================================
-- HOME
-- ============================================================
local running = true
local TEMPLATE = 1
gg.setVisible(true)

function Home()
    local m = gg.choice({
        "『 🏁 RACE MENU ༒』",
        "『 🌀 DRIFT MENU ༒』",
        "『 🔧 ENGINE / HP MENU ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m == 1 then pcall(raceMenu) end
    if m == 2 then pcall(driftmenu) end
    if m == 3 then pcall(hp) end
    if m == 4 then running = false end
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
