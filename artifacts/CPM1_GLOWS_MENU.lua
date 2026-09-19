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
local SCRIPT_ID = "GLOWSMENU" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10"
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CPM1_GLOWS_MENU_v" .. CURRENT_VERSION .. ".lua"

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
  CPM1 GLOWS / VISUALS MENU v4.9.10  — SCRIPT_ID = GLOWSMENU
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
" CPM1 GLOWS / VISUALS MENU 4.9.10\n" ..
" SCRIPT_ID: GLOWSMENU\n" ..
"╚═══════════⊱✫⊰═══════════╝"


-- ============================================================
-- GLOWS / VISUALS (full)
-- ============================================================
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
        "『 ✨ OPEN GLOWS / VISUALS ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m == 1 then pcall(Menu_Glows) end
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
