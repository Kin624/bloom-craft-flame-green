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
local SCRIPT_ID = "BODYMODMENU" 
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.your_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"



--[[UPDATE CONFIGURATION]]
local CURRENT_VERSION = "4.9.10"
--[[CURRENT SCRIPT NAME]] 
local CURRENT_SCRIPT_NAME = "CPM1_BODYMOD_MENU_v" .. CURRENT_VERSION .. ".lua"

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
  CPM1 BODY / SPOILER / ROOF MENU v4.9.10  — SCRIPT_ID = BODYMODMENU
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
" CPM1 BODY / SPOILER / ROOF MENU 4.9.10\n" ..
" SCRIPT_ID: BODYMODMENU\n" ..
"╚═══════════⊱✫⊰═══════════╝"


-- ============================================================
-- BODY / SPOILER / ROOF / CARS BREAK
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


-- ============================================================
-- HOME
-- ============================================================
local running = true
local TEMPLATE = 1
gg.setVisible(true)

function Home()
    local m = gg.choice({
        "『 🛠️ BODY MODIFICATION ༒』",
        "『 🏁 SPOILER MENU ༒』",
        "『 🏠 ROOF MENU ༒』",
        "『 💥 CARS BREAK ༒』",
        "『༒ EXIT ⌦ ༒』",
    }, nil, title)

    if m == nil then return end
    if m == 1 then pcall(Menu_custom) end
    if m == 2 then pcall(spoilermenu) end
    if m == 3 then pcall(roofmenu) end
    if m == 4 then pcall(Menu_CarsBreak) end
    if m == 5 then running = false end
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
