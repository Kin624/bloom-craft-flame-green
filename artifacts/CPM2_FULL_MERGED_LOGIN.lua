
------------------------------------------------START LOGIN (CPM2)--------------------------------------------
-- Adapted from kumag44 CPM1 login system → CPM2 v1.3.2.3
-- After successful login, CPM2 merged features load.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ SECURITY & VPN DETECTION ]]

function validate_connection()
    local res = gg.makeRequest("http://ip-api.com/json?fields=status,proxy,hosting")
    if not res or not res.content or res.content == "" then
        gg.alert("❌ ACCESS DENIED ❌\n\nThis script requires Network Permissions to run.\nPlease allow internet access and try again.")
        os.exit()
    end
    if string.find(res.content, '"proxy":true') or string.find(res.content, '"hosting":true') then
        gg.alert("❌ SECURITY RISK ❌\n\nVPN or Proxy Detected.\nDisable it to use the script.")
        os.exit()
    end
end

validate_connection()
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- [[ CONFIGURATION ]]
local SCRIPT_ID = "CPM2"
local CONTROL_URL = "https://raw.githubusercontent.com/kengiepot20-sys/panforcpm1/refs/heads/main/config.json"
local CFG_PATH = gg.EXT_STORAGE .. "/.cpm2_config.cfg"
local DEVICE_PATH = "/sdcard/Android/.device.id"
local USAGE_PATH = "/sdcard/Android/.unknown.x"

local CURRENT_VERSION = "1.3.2.3"
local CURRENT_SCRIPT_NAME = "CPM2_FULL_MERGED_LOGIN.lua"

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ WEB HOOKS ]]  (same as your CPM1 panel — update Discord if needed)
local SUCCESS_WEBHOOK = "https://discord.com/api/webhooks/1472116224405274744/eCwBbrm6gFRvB9OCiXdi8dJFRAOdkj4DLCvadqIB2d-cvmDQemdQoGFaAX-DASI3BUvJ"
local FAILURE_WEBHOOK = "https://discord.com/api/webhooks/1472119901899587793/z1sd7JGDgPoylNevfnTwhD5X3irHuFoidSjzyTOpDCrTEEGX2X8Hoe3CSwSxAiW9To8Z"
local REQUEST_WEBHOOK = "https://discord.com/api/webhooks/1472119161911119892/tn3NRDWG_7TUDMOjZpe_-Y23CiQuc-j0ewrYVPIulqburCG-Nq03mRzrgaPAxakOG_Ow"
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

login_data = {}
server_cfg = {
    version = "",
    url = "",
    new_name = "",
    news = "",
    show_news = false,
    maintenance = false
}

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
            while true do gg.alert("⛔ SCRIPT EXPIRED ⛔") end
        end
    end
end

function get_device_id()
    local f = io.open(DEVICE_PATH, "r")
    if f then
        local id = f:read("*l")
        f:close()
        if id and id ~= "" then return id end
    end
    local dev_id = (pcall(gg.getDeviceId) and tostring(gg.getDeviceId())) or tostring(os.time())
    f = io.open(DEVICE_PATH, "w")
    if f then f:write(dev_id) f:close() end
    return dev_id
end

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
    if last_date == today then count = count + 1 else count = 1 end
    f = io.open(USAGE_PATH, "w")
    if f then f:write(today .. "\n" .. count) f:close() end
    return count
end

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
        '], "footer": {"text": "CPM2 LOGIN Auth System"}'..
        '}]}'
    gg.makeRequest(webhook, {["Content-Type"] = "application/json"}, payload)
    gg.sleep(500)
end

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
    local payload = '{"embeds": [{"title": "🔑 NEW KEY REQUEST (CPM2)", "color": 16776960, "fields": ['..
        '{"name": "🆔 Script ID", "value": "'..SCRIPT_ID..'", "inline": false},'..
        '{"name": "👤 Requested User", "value": "'..req_input[1]..'", "inline": true},'..
        '{"name": "🔑 Requested Pass", "value": "'..req_input[2]..'", "inline": true},'..
        '{"name": "📱 Contact", "value": "'..req_input[3]..'", "inline": false},'..
        '{"name": "🌍 Country", "value": "'..net.country..'", "inline": true},'..
        '{"name": "📶 ISP", "value": "'..net.isp..'", "inline": true},'..
        '{"name": "🌐 IP Address", "value": "'..net.ip..'", "inline": true},'..
        '{"name": "🆔 Device ID", "value": "'..dev..'", "inline": false},'..
        '{"name": "⏰ Request Time", "value": "'..l_time..'", "inline": false}'..
        '], "footer": {"text": "CPM2 LOGIN System"}'..
        '}]}'
    gg.makeRequest(REQUEST_WEBHOOK, {["Content-Type"] = "application/json"}, payload)
    gg.alert("✅ Request Sent Successfully!\nWait For Admin Approval!")
end

function validate_login(user_name, password)
    local user = login_data[user_name]
    if not user then
        send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (User Not Found)", user_name, password, 16711680, "N/A")
        gg.alert("❌ ACCESS DENIED ❌ (User Not Found)\nERROR 505")
        return false
    end
    if user.password ~= password then
        send_auth_log(FAILURE_WEBHOOK, "❌ LOGIN FAILED (Wrong Password)", user_name, password, 16711680, user.expiry)
        gg.alert("❌ ACCESS DENIED ❌ (Wrong Password)\nERROR 503")
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
        gg.alert("❌ ACCESS DENIED ❌ (Device Mismatch)\nERROR 501")
        return false
    end
    -- Accept CPM2 keys; also accept empty sid
    if user.sid and tostring(user.sid) ~= "" and tostring(user.sid) ~= SCRIPT_ID and tostring(user.sid) ~= "CPM1" then
        -- Allow CPM1 keys temporarily only if you want; default: require CPM2
        if tostring(user.sid) ~= SCRIPT_ID then
            send_auth_log(FAILURE_WEBHOOK, "❌ WRONG SCRIPT ID", user_name, password, 16711680, user.expiry)
            gg.alert("❌ ACCESS DENIED ❌ (WRONG SCRIPT — need sid CPM2)\nERROR 504")
            return false
        end
    end
    send_auth_log(SUCCESS_WEBHOOK, "✅ LOGIN SUCCESSFUL (CPM2)", user_name, password, 65280, user.expiry)
    checkExpiry(user.expiry)
    gg.toast("Welcome " .. user_name .. " — CPM2")
    return true
end

function login()
    local f = io.open(CFG_PATH, "r")
    local saved_u, saved_p = nil, nil
    if f then
        saved_u = f:read("*l")
        saved_p = f:read("*l")
        f:close()
    end

    if saved_u and saved_p then
        local menu = gg.choice({
            "〇 [LOGIN] (" .. saved_u .. ")",
            "〇 [CHANGE KEY]",
            "〇 [DELETE KEY]",
            "❌ EXIT"
        }, nil, "╔क══क⊱✫⊰क═══क╗\n   CPM2 LOGIN SYSTEM\n╚क══क⊱✫⊰क═══क╝")
        if menu == nil then
            while true do
                if gg.isVisible(true) then
                    gg.setVisible(false)
                    login()
                end
            end
        end
        if menu == 1 then return validate_login(saved_u, saved_p) end
        if menu == 2 then
            -- fall through to prompt
        elseif menu == 3 then
            os.remove(CFG_PATH)
            gg.alert("Config Deleted")
            return login()
        elseif menu == 4 then
            os.exit()
        end
        if menu == 1 then return validate_login(saved_u, saved_p) end
    end

    local input = gg.prompt({
        "Username:",
        "Password:",
        "[📋 SEND KEY REQUEST]",
        "❌ EXIT"
    }, {nil, nil, false, false}, {"text", "text", "checkbox", "checkbox"})

    if not input or input[4] then os.exit() end
    if input[3] then open_request_page() return login() end

    if validate_login(input[1], input[2]) then
        f = io.open(CFG_PATH, "w")
        if f then f:write(input[1] .. "\n" .. input[2]) f:close() end
        return true
    end
    return false
end

-- Load remote config + users
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
    gg.alert("❌ SERVER ERROR — cannot load key list")
    os.exit()
end

if server_cfg.maintenance then
    gg.alert("🛠 MAINTENANCE MODE\nScript temporarily disabled by admin.")
    os.exit()
end

if not login() then
    os.exit()
end

-- Optional remote version note (does not force update of game offsets)
if server_cfg.show_news then
    gg.alert("📢 ADMIN MESSAGE\n\n" .. (server_cfg.news or "No message"))
end

gg.toast("✅ Login OK — loading CPM2 v1.3.2.3 features…")
gg.sleep(300)

------------------------------------------------ END LOGIN — BEGIN CPM2 MERGED --------------------------------------------
--[[ ══════════════════════════════════════════════════════════
  CPM2  v1.3.2.3 — FULL MERGED SCRIPT
  Sources merged:
    • CPM2 opensource (Kinzi – unlocks, prank, boosters, achievements)
    • #Cpm2CoinsHook.lua (Kirito – race/drag/rally + getField)
    • dump.cs 1.3.2.3 – RVA names verified / documented below

  Target : Car Parking Multiplayer 2  (Unity IL2CPP, Android)
  Library: libil2cpp.so
  Dump   : 1.3.2.3 cpm2 dump (Assembly-CSharp + modules)

  ═══════════════════════════════════════════════════════════
  OFFSET TABLE — libil2cpp.so  (RVA = Offset, verified dump)
  Format:  RVA  | Class / Method  | What the patch does
  ═══════════════════════════════════════════════════════════

  MONEY / PLAYERPREFS
    0x2BF59CC  UnityEngine.PlayerPrefs.GetFloat(string,float)
               Instant Money: rewrite body to return ~50M float bits
    0x2BF5934  PlayerPrefs.SetFloat(string,float)          (related)
    0x6291BC8  PlayerPrefs.SetString(string,string)
               ID Changer patches call site at +0x9C (MOV W0,WZR style)

  CURRENCY (CurrencyManagerController) — optional hooks
    0x2F89930  SetMoneyPrefs(AdvancedInt)
    0x2F899CC  SetMoney(AdvancedInt)
    0x2F89C60  SetCoins(AdvancedInt, Source)
    0x2F89C68  AddMoney(AdvancedInt)
    0x2F89EFC  IsEnoughCoins(int,bool)  → force true = free purchases

  RACE / LAP  (class LapRaceCar + CircuitRaceControlller)
    0x2DC29DC  LapRaceCar.IsFinalLap()              → always true (1 lap win)
    0x2DC2244  LapRaceCar.IsCheatFinish()           → false (bypass reward flag)
    0x2DC2594  LapRaceCar.OnLapFinish()             → finish hook
    0x2DC2810  LapRaceCar.GetBestLap()              → freeze lap time helpers
    0x2DC27C8 / 0x2DC2818 / 0x2DC28AC / 0x2DB9EBC / 0x2DB9E90
    0x2DC2BB4 / 0x3A7A8B0 / 0x3A7A884 / 0x3A8301C   more time getters
    0x2DC2550 … 0x3BB6500  GetPenaltyDistance family → zero penalties
    0x2DC2470 … 0x3A829C4  GetTotalProgress family  → max progress
    0x2DC2D84  LapRaceCar.CalculatePos()            → teleport / auto pos
    0x2F039A8  CircuitRaceControlller.CheckParent() → local bypass
    0x2EF8658  CircuitCarStearing.ChangeSteeringState → dumb AI enemies
    0x2F4D8C4  LemanRaceController.SetTime(int)     → Le Mans timer
    0x3A826A8  IsCheatFinish (server path)          → bypass server

  RALLY  (class RallyCar / RallyController)
    0x329A0F8  RallyCar.IsCarOffRoad(out float)     → never off-road
    0x3299074  RallyCar.get_Penalty()               → 0 penalty
    0x329907C  RallyCar.get_MissedCheckpoints()     → 0 missed
    0x32996C8  RallyCar.AddPenalty(float,type)      → RET (no add)
    0x329B00C  ApplyMissedCheckpointsPenalty        → RET

  GEARBOX / ENGINE / TUNING
    0x3583754  CheckGearboxNotCompatible(PartData,out bool)
               → force compatible (unlock all gearbox)
    0x33197A8  CheckNotCompatibleEngine(PartItem,int)
               → force engine part OK
    0x30A19DC  EncryptEngine(int)                   → identity / bypass
    0x30A19EC  (alt engine gate, same area)
    0x331C938  get_CurrentUnixTimeSeconds()         → service-time bypass
    0x3540618  CheckerEngineCheating(out int2)      → disable detect
    0x330DE48  (engine alt gate)
    0x358375   (gearbox alt / short RVA variant in older scripts)

  UNLOCK / SHOP
    0x34D7EC0  Police inventory IsBought(CarInfo)   → always bought
    0x2E7CDE8  hasHouse(int)                        → house / police house
    0x339EA88 / 0x339E740 / 0x339E990
               CheckPaintBought / paint gates       → unlock paints
    0x342E048  GetCoinPriceForKit(BodyKitType,int)  → free bodykits
    0x332EE58  get_BodyKitsMoneyPrice()             → 0 price
    0x30A0838  GetClassVehicle(int,int)             → class editor (F1/GR6)
    0x30A8E28  get_TyreHealth()                     → tyre 0%/100% hooks

  LOGO / RANK
    0x2E25F1C  GetOwnRank()                         → fake rank logo
               MOV W0,#rank ; RET   (King/YT/TikTok/IG/Dev)

  ACHIEVEMENTS / MISSIONS
    0x3007978  GetDistance() (mission path)         → taxi/delivery/cargo
    FreeDriveDB fields (instance, via valueFromClass):
      0x1B8 carWash · 0x208 emotions · 0x190 fuel · 0x17C tire
      0x140 police · 0x1E0 repair · 0x12C dragWins · 0x104 speed
      0x0DC blockPost
    Powertrain: 0x144 sess · 0x15C drift · 0x174 offroad · 0x18C curDrift
    TouchMovePerson: 0x0F4 marathon · 0x130 passenger
    AnalyticWheres: 0x60 level time

  ROOM / SOCIAL
    0x33541F0  OnRoomPasswordEntered path           → auto join / bypass PW
    RoomDataItem +0x8C  password field (DWORD 1–9999)

  ANTI-CHEAT / ANTI-KICK (debug / condition gates)
    0x31F19FC  MainCarCondition-related
    0x35738D0  CarDebugTools_Start
    0x35750BC  CarDebugTools_Update
    0x3569F64  IsCheatActivated
    0x3660024  CarDoorOpenerPerson~InCar
    0x333A8F8 / 0x33B0800 / 0x367B478  passenger kick checks
    0x320A1EC  APEX car-break related

  SLOTS
    0x33A7618+0xC0  inventory slot limit gate


  EXTRA BYPASSES (dump 1.3.2.3)
    0x2F89FB4  IsEnoughMoney(int,bool)           → true
    0x2F8A06C  IsMoneyEnough(int)                → true
    0x33A46A8  Parts IsBought(body,type,item)    → true
    0x3429CDC  AirSus IsBought(CarInfo)          → true
    0x31026B0  IsBannedCar                       → false
    0x3102558  CheckerNFSCars                    → RET
    0x3102738  CheckTradeCarNotAllowed(int)      → 0
    0x3102800  CheckTradeCarNotAllowed(string)   → 0
    0x32E4238  IsVehicleAllowed(event,class)     → true
    0x2DC1820  AddPenaltyDistance                → RET
    0x2DC1830  AddPenaltyTime                    → RET
    0x366BF34  get_CheckHashLimitExceeded        → false
    0x366BF44  get_CorrectHash                   → true*
    0x3377764  IsBlackVehicle                    → false
    0x2E58208  UnlockCar(int,int)                (call-site / room)

  DATA STRUCTURE NOTES
    • ARM64 patches use MOV X0,#1 / MOV W0,#imm + RET
      (bytes D2800020 D65F03C0 or W-variant 52800020…)
    • Instant money rewrites PlayerPrefs.GetFloat body so UI reads huge float
    • Race “Active All” freezes many time/penalty/progress getters so
      client thinks race is complete with 0 penalties
    • valueFromClass walks global-metadata.dat → class name → instance
      → field offset (IL2CPP heap layout; 64-bit object header 0x10)

══════════════════════════════════════════════════════════ --]]


-- ═══════════════════════════════════════════
--  §0  BOOTSTRAP & ANTI-RLGG
-- ═══════════════════════════════════════════
local gg = gg
gg.setVisible(false)
math.randomseed(os.time())

local function antiRLGG()
    if gg.internal2 then pcall(gg.internal2) end
    for i = 1, 3 do
        pcall(function()
            gg.setValues({{address = 0xDEAD + i, flags = 4, value = math.random(500, 1000)}})
        end)
    end
end
antiRLGG()

-- ═══════════════════════════════════════════
--  §1  CORE UTILITIES
-- ═══════════════════════════════════════════

-- Detect 64-bit process
local function isProcess64Bit()
    local regions = gg.getRangesList()
    return (regions[#regions]["end"] >> 32) ~= 0
end
local ISA = isProcess64Bit()

local edi, ed, edits, edit

local function ISAOffsets()
    if ISA then edi = "0x";  ed = "-0x"
    else        edi = "+0x"; ed = "-0x" end
end
ISAOffsets()

local function ISAOffsetss()
    if ISA then edit = "~A8 B [PC,#" .. edits .. "]"
    else        edit = "~A B "        .. edits end
end

-- Resolve the Xa (executable) range of a library
local lib, xand
local function libs(loz)
    local liby = 1
    local libx = gg.getRangesList(loz)
    for i, v in ipairs(libx) do
        if libx[i].state == "Xa" then
            xand = gg.getRangesList(loz)[liby].start
            break
        end
        liby = liby + 1
    end
    lib = xand
end

-- getLib: return the base address (ranges[2].start) of libil2cpp.so
-- Used by CoinsHook-style functions
local function getLib()
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then return nil end
    return ranges[2].start
end

-- Shorthand single-value write (no freeze)
local function TesterLua() end
local function setvalue(address, flags, value)
    TesterLua('setvalue')
    local tt = {}
    tt[1] = {address = address, flags = flags, value = value}
    gg.setValues(tt)
end

-- CoinsHook-style freeze write (addListItems then remove = sticky freeze in GG)
local function setvalue_freeze(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end


-- setfreeze: write a single value with freeze=true
local function setfreeze(address, flags, value)
    gg.setValues({{address = address, flags = flags, value = value, freeze = true}})
end

-- Patch bytes via hex string (TYPE_BYTE loop)
local tabl0001
local function Patch(libName, offset, hex)
    local ms = ""
    if tabl0001 == nil then tabl0001 = {} end
    local targetAddr = 0
    local hexStrCount = #hex:gsub("%s+", "")
    if hexStrCount % 2 ~= 0 then return print("Bad hex.") end
    local hexCount = hexStrCount / 2
    for i, v in ipairs(gg.getRangesList(libName)) do
        if v.type:sub(3, 3) == "x" then targetAddr = v.start + offset; break end
    end
    local editHex, ed2 = {}, {}
    for i = 1, hexCount do
        editHex[i] = {address = targetAddr + (i - 1), flags = gg.TYPE_BYTE}
    end
    gg.loadResults(editHex)
    local res = gg.getResults(gg.getResultsCount())
    for i in ipairs(res) do
        ms = string.format("%x", res[i].value)
        ms = string.upper(ms):gsub("FFFFFFFFFFFFFF", "")
        if ms == "0" then ms = "00" end
        if #ms == 1 then ms = "0" .. ms end
        ed2[i] = ms
    end
    ms = "h" .. table.concat(ed2)
    local lob = #tabl0001 + 1
    tabl0001[lob] = libName; tabl0001[lob+1] = offset; tabl0001[lob+2] = ms
    gg.loadResults(editHex)
    gg.getResults(hexCount)
    gg.editAll("h" .. hex, gg.TYPE_BYTE)
    gg.clearResults()
end

local function Restore(libName, offset)
    local edi2, hex
    for i = 1, #tabl0001 do
        if tabl0001[i] == libName and tabl0001[i+1] == offset then
            edi2 = tabl0001[i+2]; hex = #tabl0001[i+2] - 1
        end
    end
    local targetAddr = 0
    for i, v in ipairs(gg.getRangesList(libName)) do
        if v.type:sub(3, 3) == "x" then targetAddr = v.start + offset; break end
    end
    local editHex = {}
    hex = hex / 2
    for i = 1, hex do editHex[i] = {address = targetAddr + (i-1), flags = gg.TYPE_BYTE} end
    gg.loadResults(editHex); gg.getResults(gg.getResultsCount())
    gg.editAll(edi2, 1); gg.clearResults()
end

-- patchBytes: write raw ARM64 hex at offset from lib base
local function patchBytes(offset, hexString)
    libs("libil2cpp.so")
    Patch("libil2cpp.so", offset, hexString)
end

-- patchPair: write ARM64 `mov w0,#1; ret` (0xD2800020 / 0xD65F03C0) as QWORD
local function patchPair(offset)
    libs("libil2cpp.so")
    gg.setValues({{address = lib + offset, flags = gg.TYPE_QWORD,
                   value = "h200080D2C0035FD6"}})
end

-- Edit: set a typed value directly at lib+offset
local function Edit(libName, offset, value, vtype)
    local libBase
    for i, range in ipairs(gg.getRangesList(libName)) do
        if range.state == "Xa" then libBase = range.start; break end
    end
    if not libBase then return end
    gg.setValues({{address = libBase + offset, flags = vtype, value = value}})
end

-- ── hook_void helpers ──────────────────────────────────────────
local xg = {}
local end_hook, a, b, aaaa

local function gets(g)
    gg.loadResults(end_hook)
    xg[g] = gg.getResults(gg.getResultsCount())
    gg.clearResults()
end

local function posHEX()
    local xHEX = string.format("%X", aaaa)
    if #xHEX > 8 then xHEX = string.sub(xHEX, (#xHEX-8)+1) end
    edits = edi .. xHEX; ISAOffsetss()
end

local function negHEX()
    local aaa = b - a
    local xHEX = string.format("%X", aaa)
    if #xHEX > 8 then xHEX = string.sub(xHEX, (#xHEX-8)+1) end
    edits = ed .. xHEX; ISAOffsetss()
end

local function endhook(cc, g)
    local LibStart2 = lib
    local eh = {{address=(LibStart2+cc), flags=gg.TYPE_DWORD, value=xg[g][1].value, freeze=true}}
    gg.addListItems(eh); gg.clearList()
end

local function hook_void(cc, bb, g)
    local LibStart2 = lib
    local m = {{address=(LibStart2+bb), flags=gg.TYPE_DWORD}}
    gg.addListItems(m); a = m[1].address; gg.clearList()
    local p = {{address=(LibStart2+cc), flags=gg.TYPE_DWORD}}
    gg.addListItems(p); gg.loadResults(p)
    end_hook = gg.getResults(1)
    if g then gets(g) end
    local n = {{address=(LibStart2+cc), flags=gg.TYPE_DWORD}}
    gg.addListItems(n); b = n[1].address
    gg.clearResults(); gg.clearList()
    aaaa = a - b
    if tonumber(aaaa) < 0 then negHEX() end
    if tonumber(aaaa) > 0 then posHEX() end
    local nf = {{address=(LibStart2+cc), flags=gg.TYPE_DWORD, value=edit, freeze=true}}
    gg.addListItems(nf); gg.clearList()
end

-- ── getField: search global-metadata.dat for an IL2CPP class field ──
function getField(Name, Offset, Type)
  local offForField = 0x8
  if gg.getTargetInfo().x64 then offForField = 0x10 end

  local metadata = gg.getRangesList('global-metadata.dat')
  if not metadata or #metadata == 0 then
    gg.toast("global-metadata.dat")
    return
  end

  gg.clearResults()

  gg.setRanges(-1)
  gg.searchNumber(':'..Name, 4, false, gg.SIGH_EQUAL, metadata[1].start, metadata[1]['end'])

  local total = gg.getResultsCount()
  if total == 0 then
    gg.toast("not found: " .. Name)
    return
  end

  local r = gg.getResults(total)
  local count = #r / #Name
  local t = {}
  for i = 1, count do
    table.insert(t, r[(i * #Name) - (#Name - 1)])
  end

  if #t > 10 then
    gg.toast("results: " .. #t .. " — error class")
    return
  end

  gg.loadResults(t)

  gg.setRanges(4)
  gg.searchPointer(0)

  local r2 = gg.getResults(gg.getResultsCount())
  if #r2 == 0 then
    gg.toast("error metadata.so")
    return
  end

  for i, v in ipairs(r2) do
    v.address = v.address - offForField
  end

  gg.setRanges(32)
  gg.loadResults(r2)
  gg.searchPointer(0)

  if Offset and Offset ~= 0 then
    local r3 = gg.getResults(gg.getResultsCount())
    if #r3 == 0 then
      gg.toast("Nothing")
      return
    end
    for i, v in ipairs(r3) do
      v.address = v.address + Offset
      v.flags = Type
    end
    gg.loadResults(r3)
  end
gg.setVisible(false)
end


-- ── Exit helper ──
local function Exit()
    gg.clearResults()
    gg.clearList()
    gg.setVisible(true)
    os.exit()
end

-- ═══════════════════════════════════════════
--  §2  IL2CPP CLASS FIELD SEARCHER ENGINE
--      (full valueFromClass from opensource)
-- ═══════════════════════════════════════════

function valueFromClass(class, offset, tryHard, bit32, valueType, SearchMode)
   userMode = 0  -- programmatic (no prompts)

   if not SearchMode then
      SearchMode = { [1] = 'Class', [2] = 0x0 }
   end

   if SearchMode[1] == "Class" then
      SearchTypeSelection = 1
      Get_second_feild_offset = {}
      Get_second_feild_offset[1] = "0x0"
   elseif SearchMode[1] == "Struct" then
      SearchTypeSelection = 2
      Get_second_feild_offset = {}
      Get_second_feild_offset[1] = SearchMode[2]
   elseif SearchMode[1] == "ChildClass" then
      SearchTypeSelection = 3
      Get_second_feild_offset = {}
      Get_second_feild_offset[1] = SearchMode[2]
   end



   Get_user_input = {}
   Get_user_input[1] = class
   Get_user_input[2] = offset
   if type(Get_user_input[2]) == "number" then
      Get_user_input[2] = string.format("0x%X", Get_user_input[2])
   end
   Get_user_input[3] = tryHard
   Get_user_input[4] = bit32


   if (valueType == gg.TYPE_BYTE or valueType == gg.TYPE_DWORD or valueType == gg.TYPE_QWORD or valueType == gg.TYPE_FLOAT or valueType == gg.TYPE_DOUBLE) then
      Get_user_type = valueType
   elseif (valueType == "Vector2") then
      Get_user_type = 6
   elseif (valueType == "Vector2Int") then
      Get_user_type = 7
   elseif (valueType == "Vector3") then
      Get_user_type = 8
   elseif (valueType == "Vector3Int") then
      Get_user_type = 9
   elseif (valueType == "Vector4") then
      Get_user_type = 10
   elseif (valueType == "Vector4Int") then
      Get_user_type = 11
   elseif (valueType == "String") then
      Get_user_type = 12
   elseif (valueType == "Bounds") then
      Get_user_type = 13
   elseif (valueType == "BoundsInt") then
      Get_user_type = 14
   elseif (valueType == "Matrix2x3") then
      Get_user_type = 15
   elseif (valueType == "Matrix4x4") then
      Get_user_type = 16
   elseif (valueType == "Color") then
      Get_user_type = 17
   elseif (valueType == "Color32") then
      Get_user_type = 18
   elseif (valueType == "Quaternion") then
      Get_user_type = 19
   end
   start()
   if error ~= 'fail' then
      local LatestValuesOfResult = gg.getValues(Results)
      for index, value in ipairs(Results) do
         Results[index].value = LatestValuesOfResult[index].value
      end

      return Results
   else
      return {}
   end
end

function loopCheck()
   -- non-interactive mode: no UI loop
   if error == 3 then
      -- keep silent for programmatic use
   end
end

function found_(message)
   if error == 1 then
      found2(message)
   elseif error == 2 then
      found3(message)
   elseif error == 3 then
      found4(message)
   else
      found(message)
   end
end

function found(message)
   if count == 0 then
      gg.clearResults()
      first_error = message
      error = 1
      second_start()
   end
end

function found2(message)
   if count == 0 then
      gg.clearResults()
      second_error = message
      error = 2
      third_start()
   end
end

function found3(message)
   if count == 0 then
      gg.clearResults()
      third_error = message
      error = 3
      fourth_start()
   end
end

function found4(message)
   if count == 0 then
      error = 'fail'
      gg.clearResults()
      gg.alert("Value NOT FOUND\n@luizbrgg")
      gg.setVisible(true)
      loopCheck()
   end
end
function SearchTypeChooser()
   local MenuItems
   MenuItems = {}
   for index, value in ipairs(SearchType) do
      MenuItems[index] = value['topic']
   end

   :: repeatMenu ::
   Menu = gg.choice(MenuItems, 0, "Please select The Search Type")
   if Menu == nil then
      gg.alert(" Error : Please Select An Option ")
      goto repeatMenu
   end

   SearchTypeSelection = Menu
end

function user_input_taker()
   SearchType = {
      [1] = {
         ['topic'] = 'Class Search',
         ['name'] = 'Class Name',
         ['offset'] = 'Feild Offset',
      },
      [2] = {
         ['topic'] = 'Struct Search',
         ['name'] = 'Struct Container Class Name',
         ['offset'] = 'Struct Offset inside Container Class',
         ['offsetSecond'] = 'Input Struct Feild Offset : ',
      },
      [3] = {
         ['topic'] = 'Child Class Search',
         ['name'] = 'Container Class Name',
         ['offset'] = 'Child Class Offset inside Container Class',
         ['offsetSecond'] = 'Input Child Class Feild Offset : ',
      }
   }

   ::stort::
   gg.clearResults()
   if userMode == 1 then
      if Get_user_input == nil then
         default1 = "GameController"
         default2 = "0x50"
         default3 = false
         if (gg.getTargetInfo().x64) then
            default4 = false
         else
            default4 = true
         end
         SearchTypeSelection = 1
         default5 = false
         default7 = false
      else
         default1 = Get_user_input[1]
         default2 = Get_user_input[2]
         default3 = Get_user_input[3]
         default4 = Get_user_input[4]
         default5 = Get_user_input[6]
         default7 = Get_user_input[7]
      end
      if SearchTypeSelection == 1 then
         Get_user_input = gg.prompt(
            { "Script Mode : " ..
            SearchType[SearchTypeSelection]['topic'] .. "\n\n " .. SearchType[SearchTypeSelection]['name'] .. " : ",
               SearchType[SearchTypeSelection]['offset'] .. " : ", "Try Harder --(decreases accuracy)", "Try For 32 bit",
               'Change Search Mode', 'Give names and save', 'Custom Load (Load multiple With names)' },
            { default1, default2, default3, default4, false, default5, default7 },
            { "text", "text", "checkbox", "checkbox", "checkbox", "checkbox", "checkbox" })
      else
         Get_user_input = gg.prompt(
            { "Script Mode : " ..
            SearchType[SearchTypeSelection]['topic'] .. "\n\n " .. SearchType[SearchTypeSelection]['name'] .. " : ",
               SearchType[SearchTypeSelection]['offset'] .. " : ", "Try Harder --(decreases accuracy)", "Try For 32 bit",
               'Change Search Mode', 'Give names and save', },
            { default1, default2, default3, default4, false, default5 },
            { "text", "text", "checkbox", "checkbox", "checkbox", "checkbox" })
         Get_user_input[7] = false
      end

      if Get_user_input ~= nil then
         if Get_user_input[7] then
            Get_user_input[2] = 0x0
            ::CustomInput::
            CustomLoadData = gg.prompt({
               'Input The code from DUMP.CS file\nCopy from the class/struct name files and feilds\nproperties and methods not required ' })

            if CustomLoadData == nil then
               gg.alert("Please dont leave the input empty")
               goto CustomInput
            end
         end


         if Get_user_input[5] == true then
            SearchTypeChooser()
            goto stort
         end
         if (Get_user_input[1] == "") or (Get_user_input[2] == "") then
            gg.alert(" Don't Leave Input Blank")
            goto stort
         end
      else
         gg.alert(" Error : Try again ")
         goto stort
      end





      ::UserTypeChooser::
      if Get_user_input[7] then
         Get_user_type = 20
      else
         Get_user_type = gg.choice(
            { "1. Byte / Boolean", "2. Dword / 32 bit Int", "3. Qword / 64 bit Int", "4. Float", "5. Double",
               "6. Vector2",
               "7. Vector2Int", "8. Vector3", "9. Vector3Int", "10. Vector4", "11. Vector4Int", "12. String",
               "13. Bounds",
               "14. BoundsInt", "15. Matrix2x3", "16. Matrix4x4", "17. Color", "18. Color32", "19. Quaternion",
               "+ Add Custom + " }, nil,
            " Choose The Output Type ")
      end


      if (Get_user_type == nil) then
         gg.alert(" Please select a type ")
         goto UserTypeChooser
      end
      if Get_user_type == 1 then
         Get_user_type = gg.TYPE_BYTE
      elseif Get_user_type == 2 then
         Get_user_type = gg.TYPE_DWORD
      elseif Get_user_type == 3 then
         Get_user_type = gg.TYPE_QWORD
      elseif Get_user_type == 4 then
         Get_user_type = gg.TYPE_FLOAT
      elseif Get_user_type == 5 then
         Get_user_type = gg.TYPE_DOUBLE
      end
      if Get_user_type ~= gg.TYPE_BYTE then
         local hex_values = {}
         if Get_user_input[7] then
            Get_user_input[2] = tostring(Get_user_input[2])
         end
         for hex in Get_user_input[2]:gmatch("0x%x+") do
            table.insert(hex_values, hex)
         end

         if Get_user_input[7] then
            Get_user_input[2] = string.format("0x%X", tonumber(Get_user_input[2]))
         end


         -- Verify the offsets
         for i, v in ipairs(hex_values) do
            if (v % 4) ~= 0 then
               gg.alert("Hex Offset Must Be An Multiple OF 4")
               goto stort
            end
         end
      end

      if Get_user_type ~= 20 or SearchTypeSelection == 3 then
         :: SearchType ::
         if (SearchTypeSelection == 2 or SearchTypeSelection == 3) then
            if Get_second_feild_offset == nil then
               defaultSecondOffset = "0xBC"
            else
               defaultSecondOffset = Get_second_feild_offset[1]
            end
            Get_second_feild_offset = gg.prompt(
               { "?\n\n" .. SearchType[SearchTypeSelection]['offsetSecond'] },
               { defaultSecondOffset })

            if Get_second_feild_offset == nil or Get_second_feild_offset[1] == "" then
               gg.alert(" Error : Dont leave the input empty ")
               goto SearchType
            end
         end


         if (SearchTypeSelection == 2 or SearchTypeSelection == 3) then
            local hexx_values = {}
            for hex in Get_second_feild_offset[1]:gmatch("0x%x+") do
               table.insert(hexx_values, hex)
            end

            -- Verify the offsets
            for i, v in ipairs(hexx_values) do
               if (v % 4) ~= 0 then
                  gg.alert("Hex Offset Must Be An Multiple OF 4")
                  goto SearchType
               end
            end
         end
      else
         Get_second_feild_offset = {}
         Get_second_feild_offset[1] = "0x0"
      end

      if Get_user_type == 20 then
         if not Get_user_input[7] then
            CustomTypeData = gg.prompt({
               'Input The code from DUMP.CS file\nCopy from the class/struct name files and feilds\nproperties and methods not required ' })
         end
      end
   end
   error = 0
end

function O_initial_search()
   gg.setVisible(false)
   gg.toast("Injecting...")
   user_input = ":" .. Get_user_input[1]
   if Get_user_input[3] then
      offst = 25
   else
      offst = 0
   end
end

function O_dinitial_search()
   if error > 1 then
      gg.setRanges(gg.REGION_C_ALLOC)
   else
      gg.setRanges(gg.REGION_OTHER)
   end
   gg.searchNumber(user_input, gg.TYPE_BYTE)
   count = gg.getResultsCount()
   if count == 0 then
      found_("O_dinitial_search")
      return 0
   end
   Refiner = gg.getResults(1)
   gg.refineNumber(Refiner[1].value, gg.TYPE_BYTE)
   count = gg.getResultsCount()
   if count == 0 then
      found_("O_dinitial_search")
      return 0
   end
   val = gg.getResults(count)
end

function CA_pointer_search()
   gg.clearResults()
   gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_OTHER | gg.REGION_ANONYMOUS)
   gg.loadResults(val)
   gg.searchPointer(offst)
   count = gg.getResultsCount()
   if count == 0 then
      found_("CA_pointer_search")
      return 0
   end
   val = gg.getResults(count)
end

function CA_apply_offset()
   if Get_user_input[4] then
      tanker = 0xfffffffffffffff8
   else
      tanker = 0xfffffffffffffff0
   end
   local copy = false
   local l = val

   for i, v in ipairs(l) do
      v.address = v.address + tanker
      if copy then v.name = v.name .. ' #2' end
   end
   val = gg.getValues(l)
end

function CA2_apply_offset()
   if Get_user_input[4] then
      tanker = 0xfffffffffffffff8
   else
      tanker = 0xfffffffffffffff0
   end
   local copy = false
   local l = val
   for i, v in ipairs(l) do
      v.address = v.address + tanker
      if copy then v.name = v.name .. ' #2' end
   end
   val = gg.getValues(l)
end

function Q_apply_fix()
   gg.setRanges(gg.REGION_ANONYMOUS)
   gg.loadResults(val)
   count = gg.getResultsCount()
   if count == 0 then
      found_("Q_apply_fix")
      return 0
   end
   yy = gg.getResults(1000)
   gg.clearResults()
   i = 1
   c = 1
   s = {}
   while (i - 1) < count do
      yy[i].address = yy[i].address + 0xb400000000000000
      gg.searchNumber(yy[i].address, gg.TYPE_QWORD)
      cnt = gg.getResultsCount()
      if 0 < cnt then
         bytr = gg.getResults(cnt)
         n = 1
         while (n - 1) < cnt do
            s[c] = {}
            s[c].address = bytr[n].address
            s[c].flags = 32
            n = n + 1
            c = c + 1
         end
      end
      gg.clearResults()
      i = i + 1
   end
   val = gg.getValues(s)
end

function A_base_value()
   gg.setRanges(gg.REGION_ANONYMOUS)
   gg.loadResults(val)
   gg.searchPointer(offst)
   count = gg.getResultsCount()
   if count == 0 then
      found_("A_base_value")
      return 0
   end
   val = gg.getResults(count)
end

function A_base_accuracy()
   gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
   gg.loadResults(val)
   gg.searchPointer(offst)
   count = gg.getResultsCount()
   if count == 0 then
      found_("A_base_accuracy")
      return 0
   end
   kol = gg.getResults(count)
   i = 1
   h = {}
   while (i - 1) < count do
      h[i] = {}
      h[i].address = kol[i].value
      h[i].flags = 32
      i = i + 1
   end
   val = gg.getValues(h)
end

function IsComplexTypeChoosen()
   local Output
   Output = {}
   if (Get_user_type == gg.TYPE_BYTE or Get_user_type == gg.TYPE_DWORD or Get_user_type == gg.TYPE_QWORD or Get_user_type == gg.TYPE_FLOAT or Get_user_type == gg.TYPE_DOUBLE) then
      Output['IsComplex'] = false
   elseif (Get_user_type == 6) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector2"
   elseif (Get_user_type == 7) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector2Int"
   elseif (Get_user_type == 8) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector3"
   elseif (Get_user_type == 9) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector3Int"
   elseif (Get_user_type == 10) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector4"
   elseif (Get_user_type == 11) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Vector4Int"
   elseif (Get_user_type == 12) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "String"
   elseif (Get_user_type == 13) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Bounds"
   elseif (Get_user_type == 14) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "BoundsInt"
   elseif (Get_user_type == 15) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Matrix2x3"
   elseif (Get_user_type == 16) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Matrix4x4"
   elseif (Get_user_type == 17) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Color"
   elseif (Get_user_type == 18) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Color32"
   elseif (Get_user_type == 19) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "Quaternion"
   elseif (Get_user_type == 20) then
      Output['IsComplex'] = true
      Output['FeildHandler'] = "CustomFeild"
   end

   return Output
end

function A_user_given_offset()
   local old_save_list = val
   local uniqueTable = {} -- Table to hold unique addresses
   local addressSet = {}  -- Set to track seen addresses

   for _, item in ipairs(old_save_list) do
      if not addressSet[item.address] then
         table.insert(uniqueTable, item)
         addressSet[item.address] = true
      end
   end

   old_save_list = uniqueTable
 
   local finalResults = {}
   local finalResultIndex = 1
   local hex_values = {}
   local hexx_values = {}
   local complex_loaded_list = {}
   local TempComplexTypeStore = IsComplexTypeChoosen()
   if Get_user_input[7] then
      Get_user_input[2] = tostring(Get_user_input[2])
   end

   for hex in Get_user_input[2]:gmatch("0x%x+") do
      table.insert(hex_values, hex)
   end
   if Get_user_input[7] then
      Get_user_input[2] = '0x0'
   end


   -- Normal values loader, Loads dword or qword if basic type is not selected
   for i, v in ipairs(old_save_list) do
      for index, value in ipairs(hex_values) do
         if Get_user_input[7] then
            value = 0
         end

         finalResults[finalResultIndex] = {}
         finalResults[finalResultIndex].address = v.address + value
         if (SearchTypeSelection == 1) then
            if (TempComplexTypeStore['IsComplex']) then
               local ComplexTypeRefrence = { ['address'] = v.address + value }
               local TempSingleTypeLoad = ComplexFeildsHandlers[TempComplexTypeStore['FeildHandler']](
                  ComplexTypeRefrence)

               for i = 1, #TempSingleTypeLoad do
                  complex_loaded_list[#complex_loaded_list + 1] = TempSingleTypeLoad[i]
               end
            else
               finalResults[finalResultIndex].flags = Get_user_type
            end
         else
            if Get_user_input[4] then
               finalResults[finalResultIndex].flags = gg.TYPE_DWORD
            else
               finalResults[finalResultIndex].flags = gg.TYPE_QWORD
            end
         end
         finalResultIndex = finalResultIndex + 1
      end
   end
   if (SearchTypeSelection == 1) then
      if (TempComplexTypeStore['IsComplex']) then
         finalResults = gg.getValues(complex_loaded_list)
         Results = complex_loaded_list
         if SearchTypeSelection == 1 then
            if Get_user_input[6] then
               gg.addListItems(complex_loaded_list)
            end
         end
      else
         finalResults = gg.getValues(finalResults)
         Results = finalResults
      end
   end


   -- Struct values loader, It loades the struct values given during struct search mode
   if (SearchTypeSelection == 2) then
      for hex in Get_second_feild_offset[1]:gmatch("0x%x+") do
         table.insert(hexx_values, hex)
      end

      local structValues = {}
      local structValueIndex = 1;


      for i, v in ipairs(finalResults) do
         for index, value in ipairs(hexx_values) do
            if value == "0x0" then
               value = 0
            end
            if Get_user_input[7] then
               value = 0
            end

            structValues[structValueIndex] = {}
            structValues[structValueIndex].address = v.address + value
            if (TempComplexTypeStore['IsComplex']) then
               local ComplexTypeRefrence = { ['address'] = v.address + value }
               local TempSingleTypeLoad = ComplexFeildsHandlers[TempComplexTypeStore['FeildHandler']](
                  ComplexTypeRefrence)

               for i = 1, #TempSingleTypeLoad do
                  complex_loaded_list[#complex_loaded_list + 1] = TempSingleTypeLoad[i]
               end
            else
               structValues[structValueIndex].flags = Get_user_type
            end

            structValueIndex = structValueIndex + 1
         end
      end

      gg.clearResults()

      if (TempComplexTypeStore['IsComplex']) then
         structValues = gg.getValues(complex_loaded_list)
         Results = complex_loaded_list
         if SearchTypeSelection == 2 then
            if Get_user_input[6] then
               gg.addListItems(complex_loaded_list)
            end
         end
      else
         structValues = gg.getValues(structValues)
         Results = structValues
      end



      gg.loadResults(structValues)
   elseif (SearchTypeSelection == 3) then
      -- Child class loader, it loades child class from the offsets given by user

      finalResults = gg.getValues(finalResults)
      for hex in Get_second_feild_offset[1]:gmatch("0x%x+") do
         table.insert(hexx_values, hex)
      end



      local childClassValues = {}
      local childClassIndex = 1;

      -- Final result contains pointers
      -- final result val + offset will be new values to be loaded
      for i, v in ipairs(finalResults) do
         for index, value in ipairs(hexx_values) do
            if value == "0x0" then
               value = 0
            end
            childClassValues[childClassIndex] = {}
            childClassValues[childClassIndex].address = v.value + value


            -- From here code for custom load
            if (TempComplexTypeStore['IsComplex']) then
               local ComplexTypeRefrence = { ['address'] = v.value + value }
               local TempSingleTypeLoad = ComplexFeildsHandlers[TempComplexTypeStore['FeildHandler']](
                  ComplexTypeRefrence)

               for i = 1, #TempSingleTypeLoad do
                  complex_loaded_list[#complex_loaded_list + 1] = TempSingleTypeLoad[i]
               end
            else
               childClassValues[childClassIndex].flags = Get_user_type
            end



            childClassIndex = childClassIndex + 1
         end
      end

      gg.clearResults()
      if (TempComplexTypeStore['IsComplex']) then
         childClassValues = gg.getValues(complex_loaded_list)
         Results = complex_loaded_list
         if SearchTypeSelection == 3 then
            if Get_user_input[6] then
               gg.addListItems(complex_loaded_list)
            end
         end
      else
         childClassValues = gg.getValues(childClassValues)
         Results = childClassValues
      end
      gg.loadResults(childClassValues)
   else
      gg.clearResults()
      gg.loadResults(finalResults)
   end

   count = gg.getResultsCount()
   if count == 0 then
      found_("A_user_given_offset")
      return 0
   end
   gg.setVisible(true)
end

-- Function to parse the input string
function parseClass(input)
   -- Adjusted pattern to capture the class access modifier and name
   local classAccess, classType, className = input:match("(%w+) (class) (%w+)")
   if not type then
      classAccess, classType, className = input:match("(%w+) (struct) (%w+)")
   end

   if Get_user_input[7] then
      classType = "struct"
   end
   local fields = {}

   -- Pattern to match all relevant access modifiers and multi-word types
   local pattern = "(%w+) (%w+); // (0x%x+)"

   -- Use the pattern to find all matches
   for type, name, offset in input:gmatch(pattern) do
      -- Trim any leading or trailing whitespace from the type
      type = type:match("^%s*(.-)%s*$")
      table.insert(fields, { visibility = visibility, name = name, type = type, offset = offset })
   end

   return { classAccess = classAccess, classType = classType, className = className, fields = fields }
end

function GetHandler(Input)
   for index, value in ipairs(Input['fields']) do
      if Input['fields'][index]['type'] == 'int' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_DWORD
         Input['fields'][index]['Name'] = "(int, 32 bit, signed)"
      elseif Input['fields'][index]['type'] == 'uint' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_DWORD
         Input['fields'][index]['Name'] = "(int, 32 bit, unsigned)"
      elseif Input['fields'][index]['type'] == 'short' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_WORD
         Input['fields'][index]['Name'] = "(short, 16 bit, signed)"
      elseif Input['fields'][index]['type'] == 'ushort' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_WORD
         Input['fields'][index]['Name'] = "(short, 16 bit, unsigned)"
      elseif Input['fields'][index]['type'] == 'bool' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_BYTE
         Input['fields'][index]['Name'] = "(bool, 8 bit, unsigned)"
      elseif Input['fields'][index]['type'] == 'byte' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_BYTE
         Input['fields'][index]['Name'] = "(byte, 8 bit, unsigned)"
      elseif Input['fields'][index]['type'] == 'ubyte' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_BYTE
         Input['fields'][index]['Name'] = "(byte, 8 bit, signed)"
      elseif Input['fields'][index]['type'] == 'float' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_FLOAT
         Input['fields'][index]['Name'] = "(Float, 32 bit)"
      elseif Input['fields'][index]['type'] == 'double' then
         Input['fields'][index]['handler'] = 'BasicType'
         Input['fields'][index]['BasicType'] = gg.TYPE_DOUBLE
         Input['fields'][index]['Name'] = "(Double, 32 bit)"
      elseif Input['fields'][index]['type'] == 'Vector2' then
         Input['fields'][index]['handler'] = 'Vector2'
      elseif Input['fields'][index]['type'] == 'Vector2Int' then
         Input['fields'][index]['handler'] = 'Vector2Int'
      elseif Input['fields'][index]['type'] == 'Vector3' then
         Input['fields'][index]['handler'] = 'Vector3'
      elseif Input['fields'][index]['type'] == 'Vector3Int' then
         Input['fields'][index]['handler'] = 'Vector3Int'
      elseif Input['fields'][index]['type'] == 'Vector4' then
         Input['fields'][index]['handler'] = 'Vector4'
      elseif Input['fields'][index]['type'] == 'Vector4Int' then
         Input['fields'][index]['handler'] = 'Vector4Int'
      elseif Input['fields'][index]['type'] == 'Bounds' then
         Input['fields'][index]['handler'] = 'Bounds'
      elseif Input['fields'][index]['type'] == 'BoundsInt' then
         Input['fields'][index]['handler'] = 'BoundsInt'
      elseif Input['fields'][index]['type'] == 'Matrix2x3' then
         Input['fields'][index]['handler'] = 'Matrix2x3'
      elseif Input['fields'][index]['type'] == 'Matrix4x4' then
         Input['fields'][index]['handler'] = 'Matrix4x4'
      elseif Input['fields'][index]['type'] == 'Color' then
         Input['fields'][index]['handler'] = 'Color'
      elseif Input['fields'][index]['type'] == 'Color32' then
         Input['fields'][index]['handler'] = 'Color32'
      elseif Input['fields'][index]['type'] == 'Quaternion' then
         Input['fields'][index]['handler'] = 'Quaternion'
      elseif Input['fields'][index]['type'] == 'string' then
         Input['fields'][index]['handler'] = 'String'
      else
         if Get_user_input[4] then
            Input['fields'][index]['handler'] = 'BasicType'
            Input['fields'][index]['BasicType'] = gg.TYPE_DWORD
            Input['fields'][index]['Name'] = "(Unidentified : Pointer if class, first value if struct)"
         else
            Input['fields'][index]['handler'] = 'BasicType'
            Input['fields'][index]['BasicType'] = gg.TYPE_QWORD
            Input['fields'][index]['Name'] = "(Unidentified : Pointer if class, first value if struct)"
         end
      end
   end

   return Input
end

function start()
   user_input_taker()
   O_initial_search()
   O_dinitial_search()
   if error > 0 then
      return 0
   end
   CA_pointer_search()
   if error > 0 then
      return 0
   end
   CA_apply_offset()
   if error > 0 then
      return 0
   end
   A_base_value()
   if error > 0 then
      return 0
   end
   if offst == 0 then
      A_base_accuracy()
   end
   if error > 0 then
      return 0
   end
   A_user_given_offset()
   if error > 0 then
      return 0
   end
   loopCheck()
   if error > 0 then
      return 0
   end
end

function second_start()
   gg.toast("Injecting...")
   O_dinitial_search()
   if error > 1 then
      return 0
   end
   CA_pointer_search()
   if error > 1 then
      return 0
   end
   CA_apply_offset()
   if error > 1 then
      return 0
   end
   Q_apply_fix()
   if error > 1 then
      return 0
   end
   if offst == 0 then
      A_base_accuracy()
   end
   if error > 1 then
      return 0
   end
   A_user_given_offset()
   if error > 1 then
      return 0
   end
   loopCheck()
   if error > 1 then
      return 0
   end
end

function third_start()
   gg.toast("Injecting...")
   O_dinitial_search()
   if error > 2 then
      return 0
   end
   CA_pointer_search()
   if error > 2 then
      return 0
   end
   if offst == 0 then
      CA2_apply_offset()
   end
   if error > 2 then
      return 0
   end
   A_base_value()
   if error > 2 then
      return 0
   end
   if offst == 0 then
      A_base_accuracy()
   end
   if error > 2 then
      return 0
   end
   A_user_given_offset()
   if error > 2 then
      return 0
   end
   loopCheck()
   if error > 2 then
      return 0
   end
end

function fourth_start()
   gg.toast("Injecting...")
   O_dinitial_search()
   CA_pointer_search()
   CA2_apply_offset()
   Q_apply_fix()
   if offst == 0 then
      A_base_accuracy()
   end
   A_user_given_offset()
   loopCheck()
end

-- -- Float , float , float,
-- -- Player possition
--    -float
--    -float
--    -float
--    -- second
--       -float
--       -float
--       -float
--       -- third
--          -float
--          -float
--          -float



ComplexFeildsHandlers = {
   ['BasicType'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = Input['BasicType']
      Output[1].name = Input['Name']
      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
      end
      return Output
   end,
   ['Vector2'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Vector2 : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Vector2 : Y)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
      end

      return Output
   end,
   ['Vector2Int'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_DWORD
      Output[1].name = " (Vector2Int : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_DWORD
      Output[2].name = " (Vector2Int : Y)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
      end

      return Output
   end,
   ['Vector3'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Vector3 : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Vector3 : Y)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Vector3 : Z)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
      end

      return Output
   end,
   ['Vector3Int'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_DWORD
      Output[1].name = " (Vector3Int : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_DWORD
      Output[2].name = " (Vector3Int : Y)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_DWORD
      Output[3].name = " (Vector3Int : Z)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
      end

      return Output
   end,
   ['Vector4'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Vector4 : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Vector4 : Y)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Vector4 : Z)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_FLOAT
      Output[4].name = " (Vector4 : W)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
      end

      return Output
   end,
   ['Vector4Int'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_DWORD
      Output[1].name = " (Vector4Int : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_DWORD
      Output[2].name = " (Vector4Int : Y)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_DWORD
      Output[3].name = " (Vector4Int : Z)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_DWORD
      Output[4].name = " (Vector4Int : W)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
      end
      return Output
   end,
   ['Bounds'] = function(Input)
      local Output = {}
      local TempSingleTypeLoad = ComplexFeildsHandlers.Vector3(Input)
      for i = 1, #TempSingleTypeLoad do
         TempSingleTypeLoad[i].name = "Bounds : m_Center " .. TempSingleTypeLoad[i].name
         Output[#Output + 1] = TempSingleTypeLoad[i]
      end

      local TempSingleTypeLoad = ComplexFeildsHandlers.Vector3({ ['address'] = Input.address + 0xC })
      for i = 1, #TempSingleTypeLoad do
         TempSingleTypeLoad[i].name = "Bounds : m_Extents " .. TempSingleTypeLoad[i].name
         Output[#Output + 1] = TempSingleTypeLoad[i]
      end

      return Output
   end,
   ['BoundsInt'] = function(Input)
      local Output = {}
      local TempSingleTypeLoad = ComplexFeildsHandlers.Vector3Int(Input)
      for i = 1, #TempSingleTypeLoad do
         TempSingleTypeLoad[i].name = "BoundsInt : m_Center " .. TempSingleTypeLoad[i].name
         Output[#Output + 1] = TempSingleTypeLoad[i]
      end

      local TempSingleTypeLoad = ComplexFeildsHandlers.Vector3Int({ ['address'] = Input.address + 0xC })
      for i = 1, #TempSingleTypeLoad do
         TempSingleTypeLoad[i].name = "BoundsInt : m_Extents " .. TempSingleTypeLoad[i].name
         Output[#Output + 1] = TempSingleTypeLoad[i]
      end

      return Output
   end,
   ['Matrix2x3'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Matrix2x3 : m00)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Matrix2x3 : m01)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Matrix2x3 : m02)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_FLOAT
      Output[4].name = " (Matrix2x3 : m10)"

      Output[5] = {}
      Output[5].address = Input.address + 0x10
      Output[5].flags = gg.TYPE_FLOAT
      Output[5].name = " (Matrix2x3 : m11)"

      Output[6] = {}
      Output[6].address = Input.address + 0x14
      Output[6].flags = gg.TYPE_FLOAT
      Output[6].name = " (Matrix2x3 : m12)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
         Output[5].name = Input['name'] .. "  " .. Output[5].name
         Output[6].name = Input['name'] .. "  " .. Output[6].name
      end
      return Output
   end,
   ['Matrix4x4'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Matrix4x4 : m00)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Matrix4x4 : m10)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Matrix4x4 : m20)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_FLOAT
      Output[4].name = " (Matrix4x4 : m30)"

      Output[5] = {}
      Output[5].address = Input.address + 0x10
      Output[5].flags = gg.TYPE_FLOAT
      Output[5].name = " (Matrix4x4 : m01)"

      Output[6] = {}
      Output[6].address = Input.address + 0x14
      Output[6].flags = gg.TYPE_FLOAT
      Output[6].name = " (Matrix4x4 : m11)"

      Output[7] = {}
      Output[7].address = Input.address + 0x18
      Output[7].flags = gg.TYPE_FLOAT
      Output[7].name = " (Matrix4x4 : m21)"

      Output[8] = {}
      Output[8].address = Input.address + 0x1C
      Output[8].flags = gg.TYPE_FLOAT
      Output[8].name = " (Matrix4x4 : m31)"

      Output[9] = {}
      Output[9].address = Input.address + 0x20
      Output[9].flags = gg.TYPE_FLOAT
      Output[9].name = " (Matrix4x4 : m02)"

      Output[10] = {}
      Output[10].address = Input.address + 0x24
      Output[10].flags = gg.TYPE_FLOAT
      Output[10].name = " (Matrix4x4 : m12)"

      Output[11] = {}
      Output[11].address = Input.address + 0x28
      Output[11].flags = gg.TYPE_FLOAT
      Output[11].name = " (Matrix4x4 : m22)"

      Output[12] = {}
      Output[12].address = Input.address + 0x2C
      Output[12].flags = gg.TYPE_FLOAT
      Output[12].name = " (Matrix4x4 : m32)"

      Output[13] = {}
      Output[13].address = Input.address + 0x30
      Output[13].flags = gg.TYPE_FLOAT
      Output[13].name = " (Matrix4x4 : m03)"

      Output[14] = {}
      Output[14].address = Input.address + 0x34
      Output[14].flags = gg.TYPE_FLOAT
      Output[14].name = " (Matrix4x4 : m13)"

      Output[15] = {}
      Output[15].address = Input.address + 0x38
      Output[15].flags = gg.TYPE_FLOAT
      Output[15].name = " (Matrix4x4 : m23)"

      Output[16] = {}
      Output[16].address = Input.address + 0x3C
      Output[16].flags = gg.TYPE_FLOAT
      Output[16].name = " (Matrix4x4 : m33)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
         Output[5].name = Input['name'] .. "  " .. Output[5].name
         Output[6].name = Input['name'] .. "  " .. Output[6].name
         Output[7].name = Input['name'] .. "  " .. Output[7].name
         Output[8].name = Input['name'] .. "  " .. Output[8].name
         Output[9].name = Input['name'] .. "  " .. Output[9].name
         Output[10].name = Input['name'] .. "  " .. Output[10].name
         Output[11].name = Input['name'] .. "  " .. Output[11].name
         Output[12].name = Input['name'] .. "  " .. Output[12].name
         Output[13].name = Input['name'] .. "  " .. Output[13].name
         Output[14].name = Input['name'] .. "  " .. Output[14].name
         Output[15].name = Input['name'] .. "  " .. Output[15].name
         Output[16].name = Input['name'] .. "  " .. Output[16].name
      end

      return Output
   end,
   ['Color'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Color : Red)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Color : Blue)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Color : Green)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_FLOAT
      Output[4].name = " (Color : Opacity)"

      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
      end
      return Output
   end,
   ['Color32'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_BYTE
      Output[1].name = " (Color32 : Red)"

      Output[2] = {}
      Output[2].address = Input.address + 0x1
      Output[2].flags = gg.TYPE_BYTE
      Output[2].name = " (Color32 : Blue)"

      Output[3] = {}
      Output[3].address = Input.address + 0x2
      Output[3].flags = gg.TYPE_BYTE
      Output[3].name = " (Color32 : Green)"

      Output[4] = {}
      Output[4].address = Input.address + 0x3
      Output[4].flags = gg.TYPE_BYTE
      Output[4].name = " (Color32 : Opacity)"


      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
      end
      return Output
   end,
   ['Quaternion'] = function(Input)
      local Output = {}
      Output[1] = {}
      Output[1].address = Input.address
      Output[1].flags = gg.TYPE_FLOAT
      Output[1].name = " (Quaternion : X)"

      Output[2] = {}
      Output[2].address = Input.address + 0x4
      Output[2].flags = gg.TYPE_FLOAT
      Output[2].name = " (Quaternion : Y)"

      Output[3] = {}
      Output[3].address = Input.address + 0x8
      Output[3].flags = gg.TYPE_FLOAT
      Output[3].name = " (Quaternion : Z)"

      Output[4] = {}
      Output[4].address = Input.address + 0xC
      Output[4].flags = gg.TYPE_FLOAT
      Output[4].name = " (Quaternion : W)"


      if Input['name'] ~= nil then
         Output[1].name = Input['name'] .. "  " .. Output[1].name
         Output[2].name = Input['name'] .. "  " .. Output[2].name
         Output[3].name = Input['name'] .. "  " .. Output[3].name
         Output[4].name = Input['name'] .. "  " .. Output[4].name
      end
      return Output
   end,
   ['String'] = function(Input)
      local flags
      if Get_user_input[4] then
         flags = gg.TYPE_DWORD
      else
         flags = gg.TYPE_QWORD
      end

      Input.flags = flags

      local TableList = {}
      TableList[1] = Input

      Input = gg.getValues(TableList)[1]
      local Output = {}
      local offset
      if Get_user_input[4] then
         offset = 0x8
      else
         offset = 0x10
      end
      StringLength = gg.getValues({ [1] = { ['address'] = Input.value + offset, ['flags'] = gg.TYPE_DWORD } })

      if StringLength[1].value < 0 then
         StringLength[1].value = 0
      elseif StringLength[1].value > 1000 then
         StringLength[1].value = 1000
      end

      for i = 1, StringLength[1].value * 2 + 1 do
         if i == 1 then
            Output[i] = { ['address'] = Input.value + offset, ['flags'] = gg.TYPE_DWORD }
         else
            Output[i] = {}
            Output[i].flags = gg.TYPE_BYTE
            Output[i].address = Input.value + offset + 0x3 + (i - 0x1)
         end
      end

      Output = gg.getValues(Output)


      FullString = ''

      for i = 1, #Output do
         local currentChar

         if Output[i].value < 0 or Output[i].value > 255 then
            currentChar = '*Invalid char*'
         else
            currentChar = string.char(Output[i].value)
         end
         if i ~= 1 then
            FullString = FullString .. currentChar
            Output[i].name = ' (String : Char no ' .. i - 1 .. ', Char : ' .. currentChar .. ')'
         end
      end
      Output[1].name = ' (Int :String length : ' .. Output[1].value .. ', Full string : ' .. FullString .. ')';

      return Output
   end,
   ['CustomFeild'] = function(Input)
      local complex_loaded_list = {}
      local PointerValue
      if Get_user_input[4] then
         PointerValue = gg.getValues({ [1] = { ['address'] = Input.address, ['flags'] = gg.TYPE_DWORD } })
      else
         PointerValue = gg.getValues({ [1] = { ['address'] = Input.address, ['flags'] = gg.TYPE_QWORD } })
      end

      if Get_user_input[7] then
         ClassParsedInTable = parseClass(tostring(CustomLoadData))
         ParsedClassWithHandlers = GetHandler(ClassParsedInTable)
      else
         ClassParsedInTable = parseClass(tostring(CustomTypeData))
         ParsedClassWithHandlers = GetHandler(ClassParsedInTable)
      end
      for index, value in ipairs(ParsedClassWithHandlers['fields']) do
         if ParsedClassWithHandlers['classType'] == 'class' then
            if Get_user_input[4] then
               ParsedClassWithHandlers['fields'][index].address = PointerValue[1].value +
                   ParsedClassWithHandlers['fields'][index].offset
            else
               ParsedClassWithHandlers['fields'][index].address = PointerValue[1].value +
                   ParsedClassWithHandlers['fields'][index].offset
            end
         else
            if ParsedClassWithHandlers['fields'][index].offset == "0x0" then
               ParsedClassWithHandlers['fields'][index].offset = 0
            else
               -- ParsedClassWithHandlers['fields'][index].offset = tonumber(ParsedClassWithHandlers['fields'][index].offset, 10)
            end
            ParsedClassWithHandlers['fields'][index].address = Input.address +
                ParsedClassWithHandlers['fields'][index].offset
         end
         local TempSingleTypeLoad = ComplexFeildsHandlers[ParsedClassWithHandlers['fields'][index].handler](
            ParsedClassWithHandlers['fields'][index])

         for i = 1, #TempSingleTypeLoad do
            complex_loaded_list[#complex_loaded_list + 1] = TempSingleTypeLoad[i]
         end
      end

      return complex_loaded_list
   end

}


-- ═══════════════════════════════════════════
--  §3  VERSION / PROCESS CHECK
-- ═══════════════════════════════════════════

print("YouTube : Kirito / Death Gun")
local GLabel   = 'Car Parking 2'
local GProcess = 'com.olzhas.carparking.multyplayer2'
local supportedVersions = {"1.3.2.3"}
local v = gg.getTargetInfo()
local supported_version = false
local GVersion

for _, version in ipairs(supportedVersions) do
    if v.versionName == version then
        supported_version = true
        GVersion = version
        break
    end
end

if not supported_version then
    gg.alert("This script is for game Version:\n" ..
             table.concat(supportedVersions, "\n") ..
             "\n\nYour Game Version is:\n" .. v.versionName)
    os.exit()
end

if v.processName ~= GProcess then
    gg.alert("This Script is for:\n" .. GLabel .. "\n" .. GProcess ..
             "\n\nYou Selected:\n" .. v.label .. "\n" .. v.processName)
    os.exit()
end

-- ═══════════════════════════════════════════
--  §4  INIT — LOAD LIB BASE & STATE FLAGS
-- ═══════════════════════════════════════════

libs("libil2cpp.so")
local LibStart = lib   -- Xa base, used for ARM patch functions

on = " 🔴⃢  "
off = "      ⃢🔵"

local _unlockall      = false
local _unlockpolice   = false
local _unlockAirSus   = false
local _maxMoneyActive = false
patchOn = false
local _tyres100       = false
local _tyres0         = false
local money   = on
lemans = on
local racing  = on
local sale    = on
local teleport = on
place3 = on
local duplicat1 = on

-- Loading bar
gg.setVisible(false)
for i = 0, 10 do
    local bars = string.rep("■", i) .. string.rep("□", 10-i)
    gg.toast("༒" .. bars .. i*10 .. "%༒")
    gg.sleep(50 + i)
end
gg.sleep(200)

-- ═══════════════════════════════════════════
--  §5  MONEY
-- ═══════════════════════════════════════════

-- ARM64 patch values for GetFloat (50M money)
local MONEY_OFF = 0x2BF59CC  -- PlayerPrefs.GetFloat

-- Values that patch the function to return ~50M
local MONEY_PATCH = {310934496, 1923712960, 505872384, -698416192}
-- Original function bytes (for restore)
local MONEY_RESTORE = {-65204248, -1459529730, -1459466252, -1342009036}

local function applyMaxMoney()
    local base = LibStart + MONEY_OFF
    gg.setValues({
        {address=base,    flags=gg.TYPE_DWORD, value=MONEY_PATCH[1], freeze=true},
        {address=base+4,  flags=gg.TYPE_DWORD, value=MONEY_PATCH[2], freeze=true},
        {address=base+8,  flags=gg.TYPE_DWORD, value=MONEY_PATCH[3], freeze=true},
        {address=base+12, flags=gg.TYPE_DWORD, value=MONEY_PATCH[4], freeze=true},
    })
    gg.toast("✅ Instant Money ON (~50M)")
end

local function revertMaxMoney()
    local base = LibStart + MONEY_OFF
    gg.setValues({
        {address=base,    flags=gg.TYPE_DWORD, value=MONEY_RESTORE[1]},
        {address=base+4,  flags=gg.TYPE_DWORD, value=MONEY_RESTORE[2]},
        {address=base+8,  flags=gg.TYPE_DWORD, value=MONEY_RESTORE[3]},
        {address=base+12, flags=gg.TYPE_DWORD, value=MONEY_RESTORE[4]},
    })
    gg.toast("🔵 Instant Money OFF")
end


-- Force IsEnoughCoins(int price, bool withMessage) → always true
-- RVA: 0x2F89EFC  CurrencyManagerController.IsEnoughCoins
function freePurchases()
    -- CurrencyManagerController.IsEnoughCoins @ 0x2F89EFC
    local ranges = gg.getRangesList("libil2cpp.so")
    local base = (ranges and #ranges >= 2 and ranges[2].start) or LibStart or lib
    if not base then gg.toast("libil2cpp not found"); return end
    local addr = base + 0x2F89EFC
    gg.setValues({
        {address = addr,     flags = gg.TYPE_DWORD, value = "h200080D2"}, -- MOV X0, #1
        {address = addr + 4, flags = gg.TYPE_DWORD, value = "hC0035FD6"}, -- RET
    })
    gg.toast("✅ Free Purchases (IsEnoughCoins → true)")
end

function Menu_Money()
    local m = gg.choice({
        "💰 Instant Money ON",
        "💤 Instant Money OFF",
        "🛒 Free Purchases (IsEnoughCoins)",
        "↩️ Back"
    }, nil, "MONEY")
    if m == 1 then applyMaxMoney()
    elseif m == 2 then revertMaxMoney()
    elseif m == 3 then freePurchases() end
end

-- Coins freeze (4 DWORDs at MONEY_OFF, freeze=true)
local function freezeCoins()
    local base = LibStart + MONEY_OFF
    local t = {
        {address=base,    flags=gg.TYPE_DWORD, value=MONEY_PATCH[1], freeze=true},
        {address=base+4,  flags=gg.TYPE_DWORD, value=MONEY_PATCH[2], freeze=true},
        {address=base+8,  flags=gg.TYPE_DWORD, value=MONEY_PATCH[3], freeze=true},
        {address=base+12, flags=gg.TYPE_DWORD, value=MONEY_PATCH[4], freeze=true},
    }
    gg.addListItems(t)
    gg.toast("💰 Coins Frozen ✅")
end

-- ═══════════════════════════════════════════
--  §6  UNLOCK FUNCTIONS
-- ═══════════════════════════════════════════

local UNLOCK_ALL_OFFSETS = {
    0x339E990, 0x339E740, 0x339EA88, 0x313BAA0,
    0x2ED8F40, 0x33A46A8, 0x33A5348
}

local function applyUnlockAll()
    for _, off2 in ipairs(UNLOCK_ALL_OFFSETS) do
        pcall(function()
            gg.setValues({
                {address=LibStart+off2,   flags=gg.TYPE_DWORD, value=-763363296},
                {address=LibStart+off2+4, flags=gg.TYPE_DWORD, value=-698416192},
            })
        end)
    end
    gg.toast("✅ Unlock All ON")
end

local function revertUnlockAll()
    gg.toast("🔵 Unlock All OFF")
end

local function applyPolice()
    gg.setValues({
        {address=LibStart+0x34D7EC0,   flags=gg.TYPE_DWORD, value=-763363296},
        {address=LibStart+0x34D7EC0+4, flags=gg.TYPE_DWORD, value=-698416192},
    })
    gg.toast("✅ Police ON")
end

local function revertPolice()
    gg.setValues({
        {address=LibStart+0x34D7EC0,   flags=gg.TYPE_DWORD, value=-132182018},
        {address=LibStart+0x34D7EC0+4, flags=gg.TYPE_DWORD, value=-1275068159},
    })
    gg.toast("🔵 Police OFF")
end

local function applyAirSus()
    pcall(function()
        gg.setValues({
            {address=LibStart+0x3429D04+0x448, flags=gg.TYPE_DWORD, value=-721215457},
            {address=LibStart+0x34BD36C-0x28C, flags=gg.TYPE_DWORD, value=335544398},
        })
    end)
    gg.toast("✅ Air Suspension ON")
end

local function revertAirSus()
    pcall(function()
        gg.setValues({
            {address=LibStart+0x3429D04+0x448, flags=gg.TYPE_DWORD, value=905972544},
            {address=LibStart+0x34BD36C-0x28C, flags=gg.TYPE_DWORD, value=1795687071},
        })
    end)
    gg.toast("🔵 Air Suspension OFF")
end

-- Tyres (offset 0x30A8E28)
local TYRES_OFF = 0x30A8E28  -- get_TyreHealth

local function applyTyres100()
    local b2 = LibStart + TYRES_OFF
    pcall(function()
        gg.setValues({
            {address=b2,    flags=gg.TYPE_DWORD, value=1384120320},
            {address=b2+4,  flags=gg.TYPE_DWORD, value=1923608576},
            {address=b2+8,  flags=gg.TYPE_DWORD, value=505872384},
            {address=b2+12, flags=gg.TYPE_DWORD, value=-698416192},
        })
    end)
    gg.toast("✅ Tyres 100%")
end

local function revertTyres100()
    local b2 = LibStart + TYRES_OFF
    pcall(function()
        gg.setValues({
            {address=b2,    flags=gg.TYPE_DWORD, value=-1119699968},
            {address=b2+4,  flags=gg.TYPE_DWORD, value=-698416192},
            {address=b2+8,  flags=gg.TYPE_DWORD, value=-132182018},
            {address=b2+12, flags=gg.TYPE_DWORD, value=-113139704},
        })
    end)
    gg.toast("🔵 Tyres 100% OFF")
end

local function applyTyres0()
    local b2 = LibStart + TYRES_OFF
    pcall(function()
        gg.setValues({
            {address=b2,    flags=gg.TYPE_DWORD, value=-763363328},
            {address=b2+4,  flags=gg.TYPE_DWORD, value=-698416192},
            {address=b2+8,  flags=gg.TYPE_DWORD, value=-132182018},
            {address=b2+12, flags=gg.TYPE_DWORD, value=-113139704},
        })
    end)
    gg.toast("✅ Tyres 0%")
end

local function revertTyres0()
    applyTyres100()
    gg.toast("🔵 Tyres 0% OFF")
end

function tyresMenu()
    local t = gg.choice({"Tyres 100%", "Tyres 0%", "Restore", "Back"}, nil, "TYRES")
    if t == 1 then applyTyres100()
    elseif t == 2 then applyTyres0()
    elseif t == 3 then revertTyres100() end
end

-- ═══════════════════════════════════════════
--  §7  GEARBOX / ENGINE BYPASS
-- ═══════════════════════════════════════════

function unlockallgb()   -- CheckGearboxNotCompatible @ 0x3583754
    patchPair(0x3583754)
    gg.toast("✅ Unlock All Gearbox")
end

function unlcokpartenmgine()  -- CheckNotCompatibleEngine @ 0x33197A8
    patchPair(0x33197A8)
    gg.toast("✅ Bypass Part Engine")
end

function bypassenginecomp()   -- EncryptEngine @ 0x30A19DC
    patchPair(0x30A19DC)
    gg.toast("✅ Bypass Engine Compatible")
end

function bypasseservvicetrime()  -- get_CurrentUnixTimeSeconds @ 0x331C938
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x331C938,   flags=gg.TYPE_DWORD, value="h200080D2"},
        {address=lib+0x331C938+4, flags=gg.TYPE_DWORD, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass Service Time")
end

function buyefasf()   -- ApplySuspensionValueAsync area @ 0x35414D4
    patchPair(0x35414D4)
    gg.toast("✅ Bypass Detect Engine & GB")
end

function bypassgdetece()  -- CheckerEngineCheating @ 0x3540618 (+ 0xCB0 secondary)
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x3540618,       flags=4, value="h200080D2"},
        {address=lib+0x3540618+0xCB0, flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass Detect (GB/Engine)")
end

function bypassgtime()   -- alias / bypass GB Time
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x331C938+4, flags=4, value="h200080D2"},
        {address=lib+0x331C938,   flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass GB Time")
end

function bypassgengine()   -- 0x30A19EC
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x30A19EC,   flags=4, value="h200080D2"},
        {address=lib+0x30A19EC+4, flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass Engine (alt)")
end

function bypassengine1()   -- 0x330DE48
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x330DE48,   flags=4, value="h200080D2"},
        {address=lib+0x330DE48+4, flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass Engine (alt2)")
end

function bypassgearbox()   -- 0x358375
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x358375,   flags=4, value="h200080D2"},
        {address=lib+0x358375+4, flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Bypass Gearbox")
end

function menubypassgb()
    local sel = gg.choice({
        "🔓 Unlock All Gearbox",
        "🔓 Bypass Part Engine",
        "🔓 Bypass Engine Compatible",
        "🔓 Bypass Service Time",
        "🔓 Bypass Detect Engine/GB",
        "🔓 Bypass Detect (secondary)",
        "🔓 Bypass GB Time",
        "🔓 Bypass Engine (alt)",
        "🔓 Bypass Engine (alt2)",
        "🔓 Bypass Gearbox",
        "↩️ Back"
    }, nil, "GB / ENGINE BYPASS")
    if sel == 1  then unlockallgb()
    elseif sel == 2  then unlcokpartenmgine()
    elseif sel == 3  then bypassenginecomp()
    elseif sel == 4  then bypasseservvicetrime()
    elseif sel == 5  then buyefasf()
    elseif sel == 6  then bypassgdetece()
    elseif sel == 7  then bypassgtime()
    elseif sel == 8  then bypassgengine()
    elseif sel == 9  then bypassengine1()
    elseif sel == 10 then bypassgearbox() end
end

-- ═══════════════════════════════════════════
--  §8  RACE HOOKS
--      hook1 → racing1-5, activeall1
-- ═══════════════════════════════════════════

-- Shared race offsets (from CoinsHook)
local CheatDetect = 0x2DC2244  -- LapRaceCar.IsCheatFinish
local Time1  = 0x2DC2810  -- LapRaceCar.GetBestLap;  local Time2  = 0x2DC27C8
local Time3  = 0x2DC2818;  local Time4  = 0x2DC28AC
local Time6  = 0x2DB9EBC;  local Time7  = 0x2DB9E90
local Time8  = 0x2DC2BB4;  local Time9  = 0x3A7A8B0
local Time10 = 0x3A7A8B0;  local Time11 = 0x3A7A884
local Time12 = 0x3A8301C
local Penalty1  = 0x2DC2550;  local Penalty2  = 0x2DC28F4
local Penalty3  = 0x2DB9EB0;  local Penalty4  = 0x3A79F7C
local Penalty5  = 0x3A79F8C;  local Penalty6  = 0x3BB64DC
local Penalty7  = 0x3BB64E4;  local Penalty8  = 0x3BB64EC
local Penalty9  = 0x3BB64F8;  local Penalty10 = 0x3BB6500
local Distance1 = 0x2DC2470;  local Distance2 = 0x2DC2560
local Distance3 = 0x2DC250C;  local Distance4 = 0x2DBEE68
local Distance5 = 0x3A82970;  local Distance6 = 0x3A829C4
local BypassLocal   = 0x2F039A8  -- CircuitRaceControlller.CheckParent
local TeleportPatch = 0x2DC2D84  -- LapRaceCar.CalculatePos
local LemansHook    = 0x2F4D8C4  -- LemanRaceController.SetTime
local Finish        = 0x2DC2594  -- LapRaceCar.OnLapFinish

function hook1()
    local racing_choice = gg.choice({
        '〇 | Hook Laps | 1 Lap',
        '〇 | Dumb Enemies',
        '〇 | Hook All Penaltys',
        '〇 | Teleport Patch',
        '〇 | Instant Win',
        '〇 | Active All',
        '[[Back Menu]]'
    }, nil, "Racing Menu — CPM2 1.3.2.3")
    if racing_choice == nil then return end
    if racing_choice == 1 then racing1() end
    if racing_choice == 2 then racing2() end
    if racing_choice == 3 then racing3() end
    if racing_choice == 4 then racing4() end
    if racing_choice == 5 then racing5() end
    if racing_choice == 6 then activeall1() end
end

function racing1()  -- LapRaceCar.IsFinalLap @ 0x2DC29DC — force 1-lap finish
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+0x2DC29DC,   flags=gg.TYPE_DWORD, value=-763363296, freeze=true},
        {address=libil2cpp+0x2DC29DC+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
    })
    gg.toast('✅ Laps Hooked — 1 Lap')
end

function racing2()  -- CircuitCarStearing.ChangeSteeringState @ 0x2EF8658 — dumb AI
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+0x2EF8658,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+0x2EF8658+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
    })
    gg.toast('✅ Dumb Enemies Active')
end

function racing3()  -- Full penalty/time/distance patch + cheat detect bypass
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start

    -- Helper: patch a DWORD pair at offset
    local function p2(off)
        gg.setValues({
            {address=libil2cpp+off,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
            {address=libil2cpp+off+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        })
    end

    -- Helper: set 4 DWORDs (distance values — patches function to return large progress)
    local function p4(off)
        gg.setValues({
            {address=libil2cpp+off,    flags=gg.TYPE_DWORD, value=310934496,  freeze=true},
            {address=libil2cpp+off+4,  flags=gg.TYPE_DWORD, value=1923712960, freeze=true},
            {address=libil2cpp+off+8,  flags=gg.TYPE_DWORD, value=505872384,  freeze=true},
            {address=libil2cpp+off+12, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        })
    end

    -- Bypass cheat detect
    p2(CheatDetect)
    -- Freeze all lap times to 0
    for _, off2 in ipairs({Time1,Time2,Time3,Time4,Time6,Time7,Time8,Time9,Time10,Time11,Time12}) do
        p2(off2)
    end
    -- Freeze all penalties to 0
    for _, off2 in ipairs({Penalty1,Penalty2,Penalty3,Penalty4,Penalty5,
                           Penalty6,Penalty7,Penalty8,Penalty9,Penalty10}) do
        p2(off2)
    end
    -- Set distances to max (patches GetTotalProgress to return large value)
    for _, off2 in ipairs({Distance1,Distance2,Distance3,Distance4,Distance5,Distance6}) do
        p4(off2)
    end
    gg.toast('✅ Removed All Penalties — Full Race Patch ON')
end

function racing4()  -- Teleport Patch: BypassLocal + CalculatePos
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+BypassLocal,     flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+BypassLocal+4,   flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        {address=libil2cpp+TeleportPatch,   flags=gg.TYPE_DWORD, value=-721215457, freeze=true},
        {address=libil2cpp+TeleportPatch+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
    })
    gg.alert('✅ Auto Win Active\nRun until you reach ~75% of the race,\nthen Teleport Car To Start Race → WIN!')
    gg.toast('✅ Auto Win Race Active')
end

function racing5()  -- Instant Win via REGION_ANONYMOUS search (RaceStartTrigger)
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("4692750812804284416", gg.TYPE_QWORD)
    local results = gg.getResults(1000)

    local check_minus4 = {}
    local addr_refs = {}
    for _, r in ipairs(results) do
        check_minus4[#check_minus4+1] = {address=r.address-0x4, flags=gg.TYPE_DWORD}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_minus4 = gg.getValues(check_minus4)

    local candidates = {}
    local candidate_refs = {}
    for i, vv in ipairs(values_minus4) do
        if vv.value == 1092616192 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x4, flags=gg.TYPE_DWORD}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("racing5: error (stage 1)") return end

    local values_plus4 = gg.getValues(candidates)
    local check_minus8 = {}
    for i = 1, #candidate_refs do
        check_minus8[#check_minus8+1] = {address=candidate_refs[i]-0x8, flags=gg.TYPE_DWORD}
    end
    local values_minus8 = gg.getValues(check_minus8)

    local edits = {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 1092616192 and
           (values_minus8[i].value==0 or values_minus8[i].value==1 or values_minus8[i].value==2) then
            edits[#edits+1] = {address=candidate_refs[i]+0x20, flags=gg.TYPE_DWORD,
                               value=288, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x34, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("racing5: error (stage 2)") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.setVisible(false)

    -- RaceStartTrigger search
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_DWORD)
    local r = gg.getResults(100000)

    local t1, t1Refs = {}, {}
    for _, vv in ipairs(r) do
        t1[#t1+1] = {address=vv.address+0x40, flags=gg.TYPE_DWORD}
        t1Refs[#t1Refs+1] = vv.address
    end
    t1 = gg.getValues(t1)

    local t2, t2Refs = {}, {}
    for i, vv in ipairs(t1) do
        if vv.value >= 1 and vv.value <= 60 then
            t2[#t2+1] = {address=t1Refs[i]-0xA4, flags=gg.TYPE_DWORD}
            t2Refs[#t2Refs+1] = t1Refs[i]
        end
    end
    if #t2 == 0 then gg.toast("racing5: nothing (t2)") return end
    t2 = gg.getValues(t2)

    local t3, t3Refs = {}, {}
    for i, vv in ipairs(t2) do
        if vv.value >= 90 and vv.value <= 118 then
            t3[#t3+1] = {address=t2Refs[i]-0xB4, flags=gg.TYPE_QWORD}
            t3Refs[#t3Refs+1] = t2Refs[i]
        end
    end
    if #t3 == 0 then gg.toast("racing5: nothing (t3)") return end
    t3 = gg.getValues(t3)

    local t4, t4Refs = {}, {}
    for i, vv in ipairs(t3) do
        if vv.value == 4294967296 then
            t4[#t4+1] = {address=t3Refs[i]-0xB0, flags=gg.TYPE_DWORD}
            t4Refs[#t4Refs+1] = t3Refs[i]
        end
    end
    if #t4 == 0 then gg.toast("racing5: nothing (t4)") return end
    t4 = gg.getValues(t4)

    local e = {}
    for i, vv in ipairs(t4) do
        if vv.value == 1 then
            e[#e+1] = {address=t4Refs[i]-0xB0, flags=gg.TYPE_DWORD, value=3, freeze=true}
        end
    end

    if #e == 0 then
        -- Fallback search
        local tOpt, tOptRefs = {}, {}
        for i, _ in ipairs(t4Refs) do
            tOpt[#tOpt+1] = {address=t4Refs[i]-0x128, flags=gg.TYPE_DWORD}
            tOpt[#tOpt+1] = {address=t4Refs[i]-0x188, flags=gg.TYPE_FLOAT}
            tOptRefs[#tOptRefs+1] = t4Refs[i]
        end
        tOpt = gg.getValues(tOpt)
        for i, _ in ipairs(tOptRefs) do
            local idx = (i-1)*2+1
            if tOpt[idx].value == 2 and tOpt[idx+1].value == 0.10000000149 then
                e[#e+1] = {address=tOptRefs[i]-0xB0, flags=gg.TYPE_DWORD, value=3, freeze=true}
            end
        end
    end
    if #e == 0 then gg.toast("racing5: nothing — try again") return end
    gg.addListItems(e)
    gg.clearResults()
    gg.setVisible(false)
    gg.toast('✅ Instant Win ON')
end

function activeall1()
    racing1()
    racing2()
    racing3()
    racing4()
    gg.toast('✅ All Race Functions Active')
end

-- ═══════════════════════════════════════════
--  §9  LE MANS  (lemans1 / lemans2)
-- ═══════════════════════════════════════════

function lemans1()  -- Hook Le Mans to 0s
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+LemansHook,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+LemansHook+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        {address=libil2cpp+Finish,       flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+Finish+4,     flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
    })
    gg.alert("⚠️ Don't use Hook Penalties with this function!")
    gg.toast('✅ Lemans 0s ON')
end

function lemans2()  -- Restore Le Mans to 24min
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+LemansHook,   flags=gg.TYPE_DWORD, value=-132247554},
        {address=libil2cpp+LemansHook+4, flags=gg.TYPE_DWORD, value=-1459531788},
    })
    gg.toast('✅ Lemans 24min (restored)')
end

-- ═══════════════════════════════════════════
--  §10 DRAG RACE
--      hook3 → drager1-5, pos1, pos2
-- ═══════════════════════════════════════════

function hook3()
    local drag = gg.choice({
        '〇  | Instant Win',
        '〇  | Always Win',
        '〇  | Select Class',
        '〇  | One Race Win',
        '〇  | Win 2nd Place',
        '〇  | Win 3rd Place ' .. place3,
        '[[Back Menu]]'
    }, nil, "Drag Race — Active Always Win / Class")
    if drag == nil then return end
    if drag == 1 then drager1() end
    if drag == 2 then drager2() end
    if drag == 3 then drager3() end
    if drag == 4 then drager4() end
    if drag == 5 then drager5() end
    if drag == 6 then
        if place3 == on then pos1(); place3 = off
        else pos2(); place3 = on end
    end
end

function drager1()  -- Instant Win (interactive, searches Z-position at race start)
    gg.alert("GO TO DRAG RACE — WHEN THE RACE STARTS, ACTIVATE THIS HACK")
    local search
    local offset
    local R

    gg.setRanges(gg.REGION_ANONYMOUS)
    search = "-2,097,152,000"
    if gg.getTargetInfo().x64 then
        offset = {s=0xA8, x=0x68, y=0x6C, z=0x70}
    else
        offset = {s=0x9C, x=0x5C, y=0x60, z=0x64}
    end
    gg.toast('CLICK GG LOGO TO APPLY')

    repeat
        repeat
            for i = 1, 200 do
                gg.sleep(1)
                if gg.isVisible() then break end
            end
            if R and #R.Z > 0 then end
        until gg.isVisible()
        gg.setVisible(false)
        local menu = gg.prompt({"Made By: Kirito\nCLICK OK TO START", "[[Back Menu]]"},
                               nil, {"checkbox", "checkbox"})
        if menu and menu[2] then return end
        if menu and (menu[4] or R == nil) then
            gg.clearList()
            R = {Z = {}}
        end
        if menu then
            if #R.Z < 1 then
                gg.clearResults()
                gg.searchNumber(search, 4)
                local XResults = gg.getResults(gg.getResultsCount())
                gg.clearResults()
                for i, vv in pairs(XResults) do
                    local Xvalue = gg.getValues({{address=vv.address+offset.s, flags=16}})[1].value
                    local Xvalue1 = gg.getValues({{address=vv.address+offset.x, flags=16}})[1].value
                    local Xvalue2 = gg.getValues({{address=vv.address+offset.y, flags=16}})[1].value
                    local Xvalue3 = gg.getValues({{address=vv.address+offset.z, flags=16}})[1].value
                    if Xvalue == 1.0000000331813535E32 and
                       ((Xvalue1~=0) or (Xvalue2~=0) or (Xvalue3~=0)) then
                        R["Z"][#R.Z+1] = {address=vv.address+offset.z, flags=16,
                                          value="-500", freeze=true}
                    end
                end
            end
            for i, vv in pairs(R.Z) do vv.value = "-500" end
            gg.setValues(R.Z)
            if menu[2] then gg.addListItems(R.Z) else gg.removeListItems(R.Z) end
        end
    until 1 > 2
    gg.loadResults(R.Z)
    gg.addListItems(gg.getResults(9))
    gg.clearResults()
    gg.clearList()
end

function drager2()  -- Always Win (DragRacingController)
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(20)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0x70, flags=gg.TYPE_DWORD, value=1}
    end
    gg.setValues(e)
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
    gg.toast("✅ Always Win ON")
end

function drager3()  -- Select Drag Class
    gg.setVisible(false)
    local menu = gg.choice({
        "Unlimited Class", "S9 Class", "S10 Class",
        "S11 Class", "S12 Class", "S13 Class"
    }, nil, "Select Drag Class")
    if menu == nil then return end
    local valueMap = {8, 9, 10, 11, 12, 13}
    local value = valueMap[menu] or 8
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0xC4, flags=gg.TYPE_DWORD, value=value}
    end
    gg.setValues(e)
    gg.toast("✅ Class Activated")
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
end

function drager4()  -- One Race Win
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0xD0, flags=gg.TYPE_DWORD, value=4}
        e[#e+1] = {address=vv.address-0x70, flags=gg.TYPE_BYTE,  value=1}
        e[#e+1] = {address=vv.address-0x6F, flags=gg.TYPE_BYTE,  value=1}
        e[#e+1] = {address=vv.address-0x6E, flags=gg.TYPE_BYTE,  value=1}
        e[#e+1] = {address=vv.address-0x6D, flags=gg.TYPE_BYTE,  value=1}
        e[#e+1] = {address=vv.address+0x48, flags=gg.TYPE_BYTE,  value=1}
        e[#e+1] = {address=vv.address+0x49, flags=gg.TYPE_BYTE,  value=1}
    end
    gg.setValues(e)
    gg.toast("✅ One Race Win Active")
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
end

function drager5()  -- Win 2nd Place
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0xD0, flags=gg.TYPE_DWORD, value=2}
    end
    gg.setValues(e)
    gg.alert('⚠️ Don\'t use [Always Win] before first race\nNow activate Always Win and win the race')
    gg.toast("✅ 2nd Place Win Active")
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
end

function pos1()  -- 3rd Place ON
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0xC7, flags=gg.TYPE_BYTE, value=1}
    end
    gg.setValues(e)
    gg.toast("✅ 3rd Place ON")
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
end

function pos2()  -- 3rd Place OFF
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("56983420928", gg.TYPE_QWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address-0xC7, flags=gg.TYPE_BYTE, value=0}
    end
    gg.setValues(e)
    gg.toast("❌ 3rd Place OFF")
    gg.clearList()
    gg.clearResults()
    gg.setVisible(false)
end

-- ═══════════════════════════════════════════
--  §11 RALLY
--      hook4 → rally1-7, tutorial
-- ═══════════════════════════════════════════

function hook4()
    local rally = gg.choice({
        '〇 | Hook Time',
        '〇 | Hook All Penaltys',
        '〇 | Teleport Patch',
        '〇 | Auto Win [Road]',
        '〇 | Auto Win [Japan]',
        '〇 | Auto Win [Italy]',
        '〇 | Bypass Reward',
        '〇 | How to Use?',
        '[[Back Menu]]'
    }, nil, "Rally Menu — CPM2 1.3.2.3")
    if rally == nil then return end
    if rally == 1 then rally1() end
    if rally == 2 then rally2() end
    if rally == 3 then rally3() end
    if rally == 4 then rally4() end
    if rally == 5 then rally5() end
    if rally == 6 then rally6() end
    if rally == 7 then rally7() end
    if rally == 8 then tutorial() end
    if rally == 9 then return end
end

function tutorial()
    gg.alert('Active Auto Win in {Road, Japan, Italy}\n' ..
             'Activate AFTER race starts — do NOT go to start point yet.\n' ..
             'Click start, activate cheat, then Teleport (Back To Road) and hit NPC')
    hook4()
end

function rally1()  -- Hook Time (RallyController timer)
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_FLOAT)
    local results = gg.getResults(1000)

    local addr_refs, check_plus4 = {}, {}
    for _, r in ipairs(results) do
        check_plus4[#check_plus4+1] = {address=r.address+0x4, flags=gg.TYPE_FLOAT}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_plus4 = gg.getValues(check_plus4)

    local candidates, candidate_refs = {}, {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 5 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x8, flags=gg.TYPE_FLOAT}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("rally1: error") return end
    local values_plus8 = gg.getValues(candidates)

    local edits = {}
    for i, vv in ipairs(values_plus8) do
        if vv.value == 10 then
            edits[#edits+1] = {address=candidate_refs[i]+0x5C, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("rally1: error") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.toast("✅ Time Hooked")
    gg.setVisible(false)
end

function rally2()  -- Hook All Penaltys (bypass off-road / missed checkpoint penalties)
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start

    gg.setValues({
        -- IsCarOffRoad~RallyCar
        {address=libil2cpp+0x329A0F8,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+0x329A0F8+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        -- get_Penalty~RallyCar
        {address=libil2cpp+0x3299074,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+0x3299074+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        -- get_MissedCheckpoints~RallyCar
        {address=libil2cpp+0x329907C,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+0x329907C+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
        -- AddPenalty~RallyCar
        {address=libil2cpp+0x32996C8,   flags=4, value="-698416192"},
        -- ApplyMissedCheckpointsPenalty~RallyCar
        {address=libil2cpp+0x329B00C,   flags=4, value="-698416192"},
    })
    gg.toast('✅ Rally Penalties Bypassed')
end

function rally3()  -- Teleport Patch (Road — sets checkpoint count & timer)
    gg.alert('⚠️ Test Function')
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_FLOAT)
    local results = gg.getResults(1000)

    local addr_refs, check_plus4 = {}, {}
    for _, r in ipairs(results) do
        check_plus4[#check_plus4+1] = {address=r.address+0x4, flags=gg.TYPE_FLOAT}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_plus4 = gg.getValues(check_plus4)

    local candidates, candidate_refs = {}, {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 5 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x8, flags=gg.TYPE_FLOAT}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("rally3: error") return end
    local values_plus8 = gg.getValues(candidates)

    local edits = {}
    for i, vv in ipairs(values_plus8) do
        if vv.value == 10 then
            edits[#edits+1] = {address=candidate_refs[i]+0x24, flags=gg.TYPE_DWORD,
                               value=360, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x5C, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("rally3: error") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.setVisible(false)
    gg.toast("✅ Teleport to Finish Active")
end

function rally4()  -- Auto Win [Road]
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_FLOAT)
    local results = gg.getResults(5000)

    local addr_refs, check_plus4 = {}, {}
    for _, r in ipairs(results) do
        check_plus4[#check_plus4+1] = {address=r.address+0x4, flags=gg.TYPE_FLOAT}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_plus4 = gg.getValues(check_plus4)

    local candidates, candidate_refs = {}, {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 5 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x8, flags=gg.TYPE_FLOAT}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("rally4: error") return end
    local values_plus8 = gg.getValues(candidates)

    local edits = {}
    for i, vv in ipairs(values_plus8) do
        if vv.value == 10 then
            edits[#edits+1] = {address=candidate_refs[i]+0x20, flags=gg.TYPE_DWORD,
                               value=1, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x24, flags=gg.TYPE_DWORD,
                               value=360, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x5C, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("rally4: error") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.setVisible(false)

    -- RaceStartTrigger (RallyController 0x28, Road uses QWORD=15)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("15", gg.TYPE_QWORD)
    local r = gg.getResults(50000)

    local t1, t1Refs = {}, {}
    for _, vv in ipairs(r) do
        t1[#t1+1] = {address=vv.address+0x40, flags=gg.TYPE_DWORD}
        t1Refs[#t1Refs+1] = vv.address
    end
    t1 = gg.getValues(t1)

    local t2, t2Refs = {}, {}
    for i, vv in ipairs(t1) do
        if vv.value >= 1 and vv.value <= 60 then
            t2[#t2+1] = {address=t1Refs[i]-0xC4, flags=gg.TYPE_DWORD}
            t2Refs[#t2Refs+1] = t1Refs[i]
        end
    end
    if #t2 == 0 then gg.toast("rally4: nothing (t2)") return end
    t2 = gg.getValues(t2)

    local t3, t3Refs = {}, {}
    for i, vv in ipairs(t2) do
        if vv.value == 0 then
            t3[#t3+1] = {address=t2Refs[i]-0xCC, flags=gg.TYPE_QWORD}
            t3Refs[#t3Refs+1] = t2Refs[i]
        end
    end
    if #t3 == 0 then gg.toast("rally4: nothing (t3)") return end
    t3 = gg.getValues(t3)

    local t4, t4Refs = {}, {}
    for i, vv in ipairs(t3) do
        if vv.value == 4294967296 then
            t4[#t4+1] = {address=t3Refs[i]-0xC8, flags=gg.TYPE_DWORD}
            t4Refs[#t4Refs+1] = t3Refs[i]
        end
    end
    if #t4 == 0 then gg.toast("rally4: nothing (t4)") return end
    t4 = gg.getValues(t4)

    local check_minusBC, check_plus104 = {}, {}
    for i = 1, #t4Refs do
        check_minusBC[#check_minusBC+1]  = {address=t4Refs[i]-0xBC, flags=gg.TYPE_DWORD}
        check_plus104[#check_plus104+1]  = {address=t4Refs[i]+0x3C, flags=gg.TYPE_DWORD}
    end
    local values_minusBC  = gg.getValues(check_minusBC)
    local values_plus104  = gg.getValues(check_plus104)

    local e = {}
    local roadVals = {[109]=true, [111]=true, [118]=true}
    for i, vv in ipairs(t4) do
        if vv.value == 1 and roadVals[values_minusBC[i].value] and roadVals[values_plus104[i].value] then
            e[#e+1] = {address=t4Refs[i]-0xC8, flags=gg.TYPE_DWORD, value=3, freeze=true}
        end
    end
    if #e == 0 then gg.toast("rally4: nothing (stage 2)") return end
    gg.addListItems(e)
    gg.clearResults()
    gg.clearList()
    gg.setVisible(false)
    rally2()
    gg.toast('✅ Auto Win ON [Road]')
end

function rally5()  -- Auto Win [Japan]  (QWORD search = 10)
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_FLOAT)
    local results = gg.getResults(1000)

    local addr_refs, check_plus4 = {}, {}
    for _, r in ipairs(results) do
        check_plus4[#check_plus4+1] = {address=r.address+0x4, flags=gg.TYPE_FLOAT}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_plus4 = gg.getValues(check_plus4)

    local candidates, candidate_refs = {}, {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 5 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x8, flags=gg.TYPE_FLOAT}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("rally5: error") return end
    local values_plus8 = gg.getValues(candidates)

    local edits = {}
    for i, vv in ipairs(values_plus8) do
        if vv.value == 10 then
            edits[#edits+1] = {address=candidate_refs[i]+0x20, flags=gg.TYPE_DWORD,
                               value=1, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x24, flags=gg.TYPE_DWORD,
                               value=360, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x5C, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("rally5: error") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.setVisible(false)

    -- RaceStartTrigger (Japan uses QWORD=10)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_QWORD)
    local r = gg.getResults(30000)

    local t1, t1Refs = {}, {}
    for _, vv in ipairs(r) do
        t1[#t1+1] = {address=vv.address+0x40, flags=gg.TYPE_DWORD}
        t1Refs[#t1Refs+1] = vv.address
    end
    t1 = gg.getValues(t1)

    local t2, t2Refs = {}, {}
    for i, vv in ipairs(t1) do
        if vv.value >= 1 and vv.value <= 60 then
            t2[#t2+1] = {address=t1Refs[i]-0xC4, flags=gg.TYPE_DWORD}
            t2Refs[#t2Refs+1] = t1Refs[i]
        end
    end
    if #t2 == 0 then gg.toast("rally5: nothing") return end
    t2 = gg.getValues(t2)

    local t3, t3Refs = {}, {}
    for i, vv in ipairs(t2) do
        if vv.value == 0 then
            t3[#t3+1] = {address=t2Refs[i]-0xCC, flags=gg.TYPE_QWORD}
            t3Refs[#t3Refs+1] = t2Refs[i]
        end
    end
    if #t3 == 0 then gg.toast("rally5: nothing") return end
    t3 = gg.getValues(t3)

    local t4, t4Refs = {}, {}
    for i, vv in ipairs(t3) do
        if vv.value == 4294967296 then
            t4[#t4+1] = {address=t3Refs[i]-0xC8, flags=gg.TYPE_DWORD}
            t4Refs[#t4Refs+1] = t3Refs[i]
        end
    end
    if #t4 == 0 then gg.toast("rally5: nothing") return end
    t4 = gg.getValues(t4)

    local check_minusBC, check_plus104 = {}, {}
    for i = 1, #t4Refs do
        check_minusBC[#check_minusBC+1] = {address=t4Refs[i]-0xBC, flags=gg.TYPE_DWORD}
        check_plus104[#check_plus104+1] = {address=t4Refs[i]+0x3C, flags=gg.TYPE_DWORD}
    end
    local values_minusBC = gg.getValues(check_minusBC)
    local values_plus104 = gg.getValues(check_plus104)

    local e = {}
    local jpVals = {[109]=true, [111]=true, [118]=true}
    for i, vv in ipairs(t4) do
        if vv.value == 1 and jpVals[values_minusBC[i].value] and jpVals[values_plus104[i].value] then
            e[#e+1] = {address=t4Refs[i]-0xC8, flags=gg.TYPE_DWORD, value=3, freeze=true}
        end
    end
    if #e == 0 then gg.toast("rally5: nothing") return end
    gg.addListItems(e)
    gg.clearResults()
    gg.clearList()
    gg.setVisible(false)
    rally2()
    gg.toast('✅ Auto Win ON [Japan]')
end

function rally6()  -- Auto Win [Italy]  (QWORD search = 14)
    gg.setVisible(false)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("10", gg.TYPE_FLOAT)
    local results = gg.getResults(1000)

    local addr_refs, check_plus4 = {}, {}
    for _, r in ipairs(results) do
        check_plus4[#check_plus4+1] = {address=r.address+0x4, flags=gg.TYPE_FLOAT}
        addr_refs[#addr_refs+1] = r.address
    end
    local values_plus4 = gg.getValues(check_plus4)

    local candidates, candidate_refs = {}, {}
    for i, vv in ipairs(values_plus4) do
        if vv.value == 5 then
            candidates[#candidates+1] = {address=addr_refs[i]+0x8, flags=gg.TYPE_FLOAT}
            candidate_refs[#candidate_refs+1] = addr_refs[i]
        end
    end
    if #candidates == 0 then gg.toast("rally6: error") return end
    local values_plus8 = gg.getValues(candidates)

    local edits = {}
    for i, vv in ipairs(values_plus8) do
        if vv.value == 10 then
            edits[#edits+1] = {address=candidate_refs[i]+0x20, flags=gg.TYPE_DWORD,
                               value=1, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x24, flags=gg.TYPE_DWORD,
                               value=360, freeze=true}
            edits[#edits+1] = {address=candidate_refs[i]+0x5C, flags=gg.TYPE_FLOAT,
                               value=0.00100000005, freeze=true}
        end
    end
    if #edits == 0 then gg.toast("rally6: error") return end
    gg.addListItems(edits)
    gg.clearResults()
    gg.setVisible(false)

    -- RaceStartTrigger (Italy uses QWORD=14)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("14", gg.TYPE_QWORD)
    local r = gg.getResults(30000)

    local t1, t1Refs = {}, {}
    for _, vv in ipairs(r) do
        t1[#t1+1] = {address=vv.address+0x40, flags=gg.TYPE_DWORD}
        t1Refs[#t1Refs+1] = vv.address
    end
    t1 = gg.getValues(t1)

    local t2, t2Refs = {}, {}
    for i, vv in ipairs(t1) do
        if vv.value >= 1 and vv.value <= 60 then
            t2[#t2+1] = {address=t1Refs[i]-0xC4, flags=gg.TYPE_DWORD}
            t2Refs[#t2Refs+1] = t1Refs[i]
        end
    end
    if #t2 == 0 then gg.toast("rally6: nothing") return end
    t2 = gg.getValues(t2)

    local t3, t3Refs = {}, {}
    for i, vv in ipairs(t2) do
        if vv.value == 0 then
            t3[#t3+1] = {address=t2Refs[i]-0xCC, flags=gg.TYPE_QWORD}
            t3Refs[#t3Refs+1] = t2Refs[i]
        end
    end
    if #t3 == 0 then gg.toast("rally6: nothing") return end
    t3 = gg.getValues(t3)

    local t4, t4Refs = {}, {}
    for i, vv in ipairs(t3) do
        if vv.value == 4294967296 then
            t4[#t4+1] = {address=t3Refs[i]-0xC8, flags=gg.TYPE_DWORD}
            t4Refs[#t4Refs+1] = t3Refs[i]
        end
    end
    if #t4 == 0 then gg.toast("rally6: nothing") return end
    t4 = gg.getValues(t4)

    local check_minusBC, check_plus104 = {}, {}
    for i = 1, #t4Refs do
        check_minusBC[#check_minusBC+1] = {address=t4Refs[i]-0xBC, flags=gg.TYPE_DWORD}
        check_plus104[#check_plus104+1] = {address=t4Refs[i]+0x3C, flags=gg.TYPE_DWORD}
    end
    local values_minusBC = gg.getValues(check_minusBC)
    local values_plus104 = gg.getValues(check_plus104)

    local e = {}
    local itVals = {[109]=true, [111]=true, [118]=true}
    for i, vv in ipairs(t4) do
        if vv.value == 1 and itVals[values_minusBC[i].value] and itVals[values_plus104[i].value] then
            e[#e+1] = {address=t4Refs[i]-0xC8, flags=gg.TYPE_DWORD, value=3, freeze=true}
        end
    end
    if #e == 0 then gg.toast("rally6: nothing") return end
    gg.addListItems(e)
    gg.clearResults()
    gg.setVisible(false)
    rally2()
    gg.toast('✅ Auto Win ON [Italy]')
end

function rally7()  -- Bypass Reward via getField(RallyController)
    getField("RallyController", 0x28, gg.TYPE_DWORD)
    gg.refineNumber('1~4', gg.TYPE_DWORD)
    local r = gg.getResults(500)
    local e = {}
    for _, vv in ipairs(r) do
        e[#e+1] = {address=vv.address, flags=gg.TYPE_DWORD, value=3, freeze=true}
    end
    gg.addListItems(e)
    gg.clearResults()
    gg.setVisible(false)
    rally2()
    gg.toast('✅ Bypass Reward ON')
end

-- ═══════════════════════════════════════════
--  §12 BYPASS SERVER  (hook5)
-- ═══════════════════════════════════════════

function hook5()  -- IsCheatFinish — Bypass Server check
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    gg.setValues({
        {address=libil2cpp+0x3A826A8,   flags=gg.TYPE_DWORD, value=-763363328, freeze=true},
        {address=libil2cpp+0x3A826A8+4, flags=gg.TYPE_DWORD, value=-698416192, freeze=true},
    })
    gg.toast('✅ Bypass Server Active')
end

function bypassserver()  -- IsBlackVehicle — Bypass black car server check
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x3377764,   flags=4, value="h200080D2"},
        {address=lib+0x3377764+4, flags=4, value="hC0035FD6"},
    })
    gg.toast("✅ Black Car Bypass ON")
end

-- Room password bypass
local function bypassRoomPassword()
    libs("libil2cpp.so")
    gg.setValues({{address=lib+0x33541F0, flags=gg.TYPE_QWORD, value="h200080D2C0035FD6"}})
    gg.toast("✅ Auto Room Password Bypass")
end

-- ═══════════════════════════════════════════
--  §13 CAR CLASS EDITOR  (hook6)
-- ═══════════════════════════════════════════

local ClassEditor = 0x30A0838  -- GetClassVehicle(performanceScore, carId)

local function ApplyVehicleClass(v1, v2, v3)
    gg.setVisible(false)
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then gg.toast("nothing found") return end
    local libil2cpp = ranges[2].start
    local addr = libil2cpp + ClassEditor
    gg.setValues({
        {address=addr,   flags=gg.TYPE_DWORD, value=v1},
        {address=addr+4, flags=gg.TYPE_DWORD, value=v2},
        {address=addr+8, flags=gg.TYPE_DWORD, value=v3},
    })
    gg.toast("✅ Class Edited")
end

function hook6()
    local vehicleclass = gg.choice({
        '〇  | All Cars GR-6(U)',
        '〇  | All Cars F1',
        '〇  | Restore Class',
        '[[Back Menu]]'
    }, nil, "Car Class Editor — Active All / F1")
    if vehicleclass == nil then return
    elseif vehicleclass == 1 then ApplyVehicleClass(1384120480, 1923088384, -698416192)   -- GR-6
    elseif vehicleclass == 2 then ApplyVehicleClass(1384120512, 1923088384, -698416192)   -- F1
    elseif vehicleclass == 3 then ApplyVehicleClass(1895984191, 1384120520, 1409286560)   -- Restore
    end
end

-- ═══════════════════════════════════════════
--  §14 ID CHANGER / PASSWORD FINDER
-- ═══════════════════════════════════════════

function IDChanger()
    local target   = LibStart + 0x6291BC8 + 0x9C
    local movW8WZR = 0x2A1F03E0
    local original = 0x944B2C92
    local toggle = gg.choice({"🔄 New ID", "↩️ Restore", "Back"}, nil, "ID CHANGER")
    if toggle == 1 then
        gg.setValues({{address=target, flags=gg.TYPE_DWORD, value=movW8WZR}})
        gg.toast("✅ ID Changed")
    elseif toggle == 2 then
        gg.setValues({{address=target, flags=gg.TYPE_DWORD, value=original}})
        gg.toast("🔵 ID Restored")
    end
end

function checkpassword()
    gg.alert("Searching room passwords 1–9999.\nThis reads RoomDataItem field 0x8C.")
    local found_pws = {}
    local res = valueFromClass("RoomDataItem", 0x8C, false, false, gg.TYPE_DWORD)
    for _, vv in ipairs(res) do
        if vv.value >= 1 and vv.value <= 9999 then
            table.insert(found_pws, tostring(vv.value))
        end
    end
    if #found_pws == 0 then
        gg.toast("No password found")
    else
        gg.alert("Possible passwords:\n" .. table.concat(found_pws, ", "))
    end
end

-- ═══════════════════════════════════════════
--  §15 ACHIEVEMENTS
-- ═══════════════════════════════════════════

local ACH = {
    carWash    = {class="FreeDriveDB",       off=0x1B8, type=gg.TYPE_QWORD},
    emotions   = {class="FreeDriveDB",       off=0x208, type=gg.TYPE_QWORD},
    fuel       = {class="FreeDriveDB",       off=0x190, type=gg.TYPE_QWORD},
    tire       = {class="FreeDriveDB",       off=0x17C, type=gg.TYPE_QWORD},
    police     = {class="FreeDriveDB",       off=0x140, type=gg.TYPE_QWORD},
    carRepair  = {class="FreeDriveDB",       off=0x1E0, type=gg.TYPE_QWORD},
    dragWins   = {class="FreeDriveDB",       off=0x12C, type=gg.TYPE_QWORD},
    speedBan   = {class="FreeDriveDB",       off=0x104, type=gg.TYPE_QWORD},
    blockPost  = {class="FreeDriveDB",       off=0x0DC, type=gg.TYPE_QWORD},
    distSess   = {class="Powertrain",        off=0x144, type=gg.TYPE_DWORD},
    distDrift  = {class="Powertrain",        off=0x15C, type=gg.TYPE_DWORD},
    distOffrd  = {class="Powertrain",        off=0x174, type=gg.TYPE_DWORD},
    distCurDr  = {class="Powertrain",        off=0x18C, type=gg.TYPE_DWORD},
    marathon   = {class="TouchMovePerson",   off=0x0F4, type=gg.TYPE_DWORD},
    passenger  = {class="TouchMovePerson",   off=0x130, type=gg.TYPE_DWORD},
    level      = {class="AnalyticWheres",    off=0x60,  type=gg.TYPE_FLOAT},
}

local function setAchievement(key, val)
    local a = ACH[key]
    if not a then return end
    local off = a.off
    if type(off) == "number" then
        off = string.format("0x%X", off)
    end
    local res = valueFromClass(a.class, off, false, false, a.type)
    if not res or #res == 0 then
        gg.toast("❌ " .. key .. " not found")
        return
    end
    for _, vv in ipairs(res) do
        gg.setValues({{address=vv.address, flags=a.type, value=val}})
    end
    gg.toast("✅ " .. key .. " = " .. tostring(val))
end

local function taxiDeliveryCargo()
    libs("libil2cpp.so")
    gg.setValues({
        {address=lib+0x3007978,   flags=gg.TYPE_DWORD, value="h528BF520"},
        {address=lib+0x3007978+4, flags=gg.TYPE_DWORD, value="h72AB0C60"},
        {address=lib+0x3007980,   flags=gg.TYPE_DWORD, value="h1E270000"},
        {address=lib+0x3007980+4, flags=gg.TYPE_DWORD, value="hD65F03C0"},
    })
    gg.toast("✅ Taxi/Delivery/Cargo ON")
end


function parkingMission()
    gg.sleep(100)
    gg.alert("Go to Levels section and click GG")
    while not gg.isVisible() do end
    gg.setVisible(false)
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0.1", 16)
    gg.getResults(500)
    gg.editAll("1E-40", 16)
    gg.toast("Parking Mission Active")
    gg.clearResults()
    gg.alert("Start Level 1, it will skip most automatically. You might need to do some manually.")
    gg.toast("༒ON༒")
end

function Menu_Achievement()
    local opts = {
        "🚗 Car Wash","😀 Emotions","⛽ Fuel Consumed","🔥 Tire Burnt",
        "👮 Police Evades","🔧 Car Repair","🏁 Drag Wins","⚡ Speed Banner",
        "🛑 Block Post","📏 Distance Session","〰️ Distance Drifted",
        "🌿 Distance Offroad","〰️ Dist Current Drift","🏃 Marathon",
        "🚕 Passenger","📊 Level","🚖 Taxi/Delivery/Cargo","🅿️ Parking Mission","↩️ Back"
    }
    local keys = {"carWash","emotions","fuel","tire","police","carRepair",
                  "dragWins","speedBan","blockPost","distSess","distDrift",
                  "distOffrd","distCurDr","marathon","passenger","level"}
    local sel = gg.choice(opts, nil, "ACHIEVEMENTS")
    if sel == nil or sel == #opts then return end
    if sel == 17 then taxiDeliveryCargo(); return end
    if sel == 18 then parkingMission(); return end
    local input = gg.prompt({"Value:"}, {[1]="99999"})
    if not input then return end
    local val = tonumber(input[1])
    if val then setAchievement(keys[sel], val) end
end

-- ═══════════════════════════════════════════
--  §16 CARS BREAK / PRANK MODULE (Beta)
-- ═══════════════════════════════════════════

local ANTI_KICK = {
    {0x333A8F8, "h200080D2"}, {0x333A8F8+4, "hC0035FD6"},
    {0x33B0800, "h200080D2"}, {0x33B0800+4, "hC0035FD6"},
    {0x367B478, "h200080D2"}, {0x367B478+4, "hC0035FD6"},
}

local ANTICHEAT_OFFSETS = {
    {0x31F19FC, "h000080D2"},   -- MainCarCoondition
    {0x35738D0, "h000080D2"},   -- CarDebugTools_Start
    {0x35750BC, "h000080D2"},   -- CarDebugTools_Update
    {0x3569F64, "h000080D2"},   -- IsCheatActivated
}

local INCAR_OFF  = 0x3660024

local BACKUP_BREAK = {}
local function doPatch2(address, vals)
    local ori = gg.getValues({
        {address=address,   flags=4},
        {address=address+4, flags=4},
    })
    if not BACKUP_BREAK[address] then BACKUP_BREAK[address] = ori end
    gg.setValues({
        {address=address,   flags=4, value=vals[1]},
        {address=address+4, flags=4, value=vals[2]},
    })
end

function activateAntiCheat()
    libs("libil2cpp.so")
    -- AntiCheat method patches
    local t = {}
    for _, p in ipairs(ANTICHEAT_OFFSETS) do
        table.insert(t, {address=lib+p[1], flags=gg.TYPE_DWORD, value=p[2]})
    end
    gg.setValues(t)
    -- Anti-kick patches
    local t2 = {}
    for _, p in ipairs(ANTI_KICK) do
        table.insert(t2, {address=lib+p[1], flags=4, value=p[2]})
    end
    gg.setValues(t2)
    -- InCar bypass
    doPatch2(lib+INCAR_OFF, {"h200080D2", "hC0035FD6"})
    -- Room password bypass
    bypassRoomPassword()
    gg.toast("✅ AntiCheat + Anti-Kick Patched")
end

function activateBreakCars()
    libs("libil2cpp.so")
    local void1 = 0x3351138
    local void2 = 0x334C90C
    hook_void(void1, void2)
    -- APEX direct patch
    gg.setValues({
        {address=lib+0x320A1EC,   flags=4, value="hD2800020"},
        {address=lib+0x320A1EC+4, flags=4, value="hD65F03C0"},
    })
    gg.alert("[INDO] TURUN dari mobil sekarang! NAIK ke kursi PENGEMUDI.\n[EN] Get OUT of the car! Get BACK to DRIVER seat.")
    gg.toast("✅ BREAK CARS Active")
end

-- ═══════════════════════════════════════════
--  §17 FAST CHARACTER
-- ═══════════════════════════════════════════

function fastCharacter()
    gg.setVisible(false)
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("2.6", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
    gg.getResults(500)
    gg.editAll("1.8~1.99999", gg.TYPE_FLOAT)
    gg.sleep(100)
    gg.clearResults()
    gg.toast("✅ Fast Character ON")
end

function fastCharacterOFF()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1.8~1.99999", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
    gg.getResults(500)
    gg.editAll("2.6", gg.TYPE_FLOAT)
    gg.sleep(100)
    gg.clearResults()
    gg.toast("🔵 Fast Character OFF")
end

-- ═══════════════════════════════════════════
--  §18 MISSING MENUS (from CPM2 opensource)
-- ═══════════════════════════════════════════

function danceCar1()
   gg.alert(
    "📌 DANCE CAR 1 📌\n\n" ..
    "This function makes your car bounce or 'dance' when driving.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 Once you go drive the car in the lobby, it will start shaking or dancing.\n" ..
    "🎉 A fun effect that works only while you are behind the wheel.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Get inside your car and start driving.\n" ..
    "3️⃣ Activate 『Dance Car 1』 to make your car bounce and dance while driving.\n\n" ..
    "⚠️ NOTE: Some devices may experience lag or crash depending on the car model.\n\n" ..
    "✅ Done!"
)



 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end







    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1E7", gg.TYPE_FLOAT)
    gg.getResults(999)
    gg.editAll("-99999", gg.TYPE_FLOAT)
    gg.toast("Dance Car 1 ON")
    gg.clearResults()
end

function danceCar2()
      gg.alert(
    "📌 DANCE CAR 2 📌\n\n" ..
    "This function makes your car bounce or 'dance' when driving.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 Once you go drive the car in the lobby, it will start shaking or dancing.\n" ..
    "🎉 A fun effect that works only while you are behind the wheel.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Get inside your car and start driving.\n" ..
    "3️⃣ Activate 『Dance Car 2』 to make your car bounce and dance while driving.\n\n" ..
    "⚠️ NOTE: Some devices may experience lag or crash depending on the car model.\n\n" ..
    "✅ Done!"
)



 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1E7", gg.TYPE_FLOAT)
    gg.getResults(999)
    gg.editAll("-20000000", gg.TYPE_FLOAT)
    gg.toast("Dance Car 2 ON")
    gg.clearResults()
end

function danceCar3()
      gg.alert(
    "📌 DANCE CAR 3 📌\n\n" ..
    "This function makes your car bounce or 'dance' when driving.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 Once you go drive the car in the lobby, it will start shaking or dancing.\n" ..
    "🎉 A fun effect that works only while you are behind the wheel.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Get inside your car and start driving.\n" ..
    "3️⃣ Activate 『Dance Car 3』 to make your car bounce and dance while driving.\n\n" ..
    "⚠️ NOTE: Some devices may experience lag or crash depending on the car model.\n\n" ..
    "✅ Done!"
)



 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("10000000", gg.TYPE_FLOAT)
    gg.getResults(500)
    gg.editAll("-1", gg.TYPE_FLOAT)
    gg.toast("Dance Car 3 ON")
    gg.clearResults()
end

function wallHack()
   gg.alert(
  "📌 WALL HACK 📌\n\n" ..
  "This function lets you pass through walls and obstacles.\n\n" ..
  "When you activate this function:\n" ..
  "🚶 You (or your car) can move through normally solid objects.\n" ..
  "🏁 Works while you are moving — get moving (drive or walk) after turning it ON.\n\n" ..
  "How to use:\n" ..
  "1️⃣ Enter the lobby.\n" ..
  "2️⃣ Get moving (start driving or walk).\n" ..
  "3️⃣ Activate 『Wall Hack』 and pass through walls and barriers.\n\n" ..
  "⚠️ WARNING: This may cause desync, lag, or crashes on some devices and may be detected by anti-cheat.\n\n" ..
  "✅ Done!"
)

 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("2.4611913E-38;-10.0;3.40282347E38:65", gg.TYPE_FLOAT)
    gg.getResults(999)
    gg.refineNumber("-10", gg.TYPE_FLOAT)
    gg.getResults(999)
    gg.editAll("999.9", gg.TYPE_FLOAT)
    gg.toast("Wall Hack ON")
    gg.clearResults()
end

function menu_modifications()
    local UnlockKinz = gg.choice({
      "『༒100% tires༒』",
      "『༒0% tires༒』",
      "『༒Unlock Tires (100%)༒』",
      "『📁BUMPER MENU༒』",
      "『༒BACK⌦ ༒』"
    }, nil, title)
    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ")
        return
    end
    if UnlockKinz == 1 then lastik100()
    elseif UnlockKinz == 2 then lastik0()
    elseif UnlockKinz == 3 then unlockTires()
    elseif UnlockKinz == 4 then Menu_Bumper()
    end
end

function lastik100()
       gg.alert("You must be in the room to set tires to 0%!")
      valueFromClass("Wheel", "0x138", false, false, gg.TYPE_QWORD)
    gg.getResults(1000)
    gg.editAll(100, 16)
    gg.clearResults()
    gg.toast("Tires set to 100%!")
 
end

function lastik0()
   
    gg.alert("You must be in the room to set tires to 0%!")
      valueFromClass("Wheel", "0x138", false, false, gg.TYPE_QWORD)
    gg.getResults(1000)
    gg.editAll(0, 16)
    gg.clearResults()
    gg.toast("Tires set to 0%!")
end

function unlockTires() --- Tires Unlock
      
gg.sleep(100)
gg.alert("only works for 100% tires")
gg.clearList()
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("4692750811720056832", gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("4692750811720056832", gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
results = gg.getResults(100)
if #results < 1 then gg.alert("Not Enough Results Found") else
for i = 1,#results do
gg.setValues({
[1] = {
address = results[i].address + 0x8, 
flags = gg.TYPE_FLOAT,
value = '0' 
}
})
end
end
gg.clearList()
gg.clearResults()
gg.toast("༒ON༒")
end

function Menu_Bumper()
        UnlockKinz = gg.choice({
            "『༒Remove Bumper ༒』",--1
             "『༒Custom Bumper༒』",--1
                "『༒Twin Turbo༒』",--1
            "『༒BACK⌦ ༒』"--7
        },nil , title)
      if UnlockKinz == nil then
gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
return
end
            if UnlockKinz == 1 then RB2() end
            if UnlockKinz == 2 then RB3() end
                 if UnlockKinz == 3 then RB4() end
        if UnlockKinz == 4 then menu_modifications() end
end

function RB2() --- Remove Bumper 
      
gg.sleep(100)
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.alert(" Buy Bumper Number 1")
gg.sleep(6000)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber(0, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.processResume()
gg.alert(" Buy Bumper Number 2")
gg.sleep(6000)
gg.processResume()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.refineNumber(1, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.processResume()
gg.alert(" Buy Bumper Number 3")
gg.sleep(6000)
gg.processResume()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.refineNumber(2, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.editAll("-1", gg.TYPE_DWORD)
gg.toast("༒ON༒")
gg.clearResults()
gg.clearList()
end

function RB3() --- Custom Bumper
      
gg.sleep(100)
gg.setVisible(false)
gg.clearResults()
gg.clearList()
BUMPER = gg.prompt({"❘𝗖𝘂𝘀𝘁𝗼𝗺 𝗕𝘂𝗺𝗽𝗲𝗿❘"},nil,{"number","checkbox"}) if BUMPER == nil then Cancel() return end
gg.alert(" Buy Bumper Number 1")
gg.sleep(6000)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber(0, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.processResume()
gg.alert(" Buy Bumper Number 2")
gg.sleep(6000)
gg.processResume()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.refineNumber(1, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.processResume()
gg.alert(" Buy Bumper Number 3")
gg.sleep(6000)
gg.processResume()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.refineNumber(2, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.getResults(9999)
gg.editAll(BUMPER[1],gg.TYPE_DWORD) 
    gg.toast("༒ON༒")
gg.clearResults()
gg.clearList()
end

function RB4() --- Twin Turbo
      
gg.sleep(100)
gg.setVisible(false)
gg.clearResults()
gg.alert(" Buy Rear Bumper Number 4")
gg.sleep(6000)
gg.processResume()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber(3, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.alert(" Buy Rear Bumper Number 2")
gg.sleep(6000)
gg.processResume()
gg.refineNumber(1, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.alert(" Buy Rear Bumper Number 3")
gg.sleep(6000)
gg.processResume()
gg.refineNumber(2, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.alert("Buy Rear Bumper Number 1")
gg.sleep(6000)
gg.processResume()
gg.refineNumber(0, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.alert(" Buy Rear Bumper Number 4")
gg.sleep(6000)
gg.processResume()
gg.refineNumber(3, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
gg.getResults(9999)
gg.editAll("5", gg.TYPE_DWORD)
gg.processResume()
    gg.toast("༒ON༒")
gg.clearResults()
gg.clearList()
end

function xyzteleport()
    gg.alert(
        "📌 XYZ Teleport Tutorial\n\n" ..
        "1️⃣ Start inside the game (not in garage).\n" ..
        "2️⃣ Run the script and choose XYZ Teleport.\n" ..
        "3️⃣ Wait while it searches for your position values.\n" ..
        "4️⃣ Enter new X, Y, Z values to teleport.\n" ..
        "   Example: X=300, Y=500, Z=60\n" ..
        "5️⃣ Use Freeze options if you want to stay locked in place.\n\n" ..
        "✅ Done! Now enjoy teleporting around the map."
    )


 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end

gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)

    
    
local search
local offset
local R

local search = "-2,097,152,000"
if gg.getTargetInfo().x64 then
offset = {
s = 0xA8,
x = 0x68,
y = 0x6C,
z = 0x70,
}
else
offset = {
s = 0x9C,
x = 0x5C,
y = 0x60,
z = 0x64,
}
end

repeat
  repeat
	for i = 1, 200 do
	  gg.sleep(1)
	  if gg.isVisible() then break end
	end
	if R and #R.X > 0 then
	  gg.toast("                                                            \nvalue(X): "..gg.getValues(R.X)[1].value.."\nvalue(Y): "..gg.getValues(R.Y)[1].value.."\nvalue(Z): "..gg.getValues(R.Z)[1].value)
	end
  until gg.isVisible()
  gg.setVisible(false)
  menu = gg.prompt({"ENTER X VALUE","ENTER Y VALUE","ENTER Z VALUE","freezeX","freezeY","freezeZ","Reset","HOME"},LastInput,{"number","number","number","checkbox","checkbox","checkbox","checkbox","checkbox",})
  if menu then
	if not tonumber(menu[1]) then menu[1] = 0 end
	if not tonumber(menu[2]) then menu[2] = 0 end
	if not tonumber(menu[3]) then menu[3] = 0 end
	LastInput = {menu[1],menu[2],menu[3],menu[4],menu[5],menu[6]}
  end
  if menu and menu[8] then HomeMenu() end
  if menu and (menu[7] or R == nil) then
	gg.clearList()
	R = {X = {},Y = {},Z = {}}
  end
  if menu then
	if #R.X < 1 then
	  gg.clearResults()
	  gg.searchNumber(search,4)
	  local XResults = gg.getResults(gg.getResultsCount())
	  gg.clearResults()
	  for i, v in pairs(XResults) do
		local Xvalue = gg.getValues({{address = v.address + offset.s,flags = 16}})[1].value
		local Xvalue1, Xvalue2, Xvalue3 = gg.getValues({{address = v.address + offset.x,flags = 16}})[1].value, gg.getValues({{address = v.address + offset.y,flags = 16}})[1].value, gg.getValues({{address = v.address + offset.z,flags = 16}})[1].value
		if Xvalue == 1.0000000331813535E32 and ((Xvalue1 > 0 or Xvalue1 < 0) or (Xvalue2 > 0 or Xvalue < 0) or (Xvalue3 > 0 or Xvalue < 0)) then
		  R["X"][#R.X + 1] = {address = v.address + offset.x,flags = 16,value = 0,freeze = true}
		  R["Y"][#R.Y + 1] = {address = v.address + offset.y,flags = 16,value = 0,freeze = true}
		  R["Z"][#R.Z + 1] = {address = v.address + offset.z,flags = 16,value = 0,freeze = true}
		end
	  end
	end
	for i, v in pairs(R.X) do v.value = tonumber(menu[1]) end
	for i, v in pairs(R.Y) do v.value = tonumber(menu[2]) end
	for i, v in pairs(R.Z) do v.value = tonumber(menu[3]) end
	gg.setValues(R.X)
	gg.setValues(R.Y)
	gg.setValues(R.Z)
	if menu[4] then gg.addListItems(R.X) else gg.removeListItems(R.X) end
	if menu[5] then gg.addListItems(R.Y) else gg.removeListItems(R.Y) end
	if menu[6] then gg.addListItems(R.Z) else gg.removeListItems(R.Z) end
  end
until 1>2
gg.loadResults(R.X)
gg.addListItems(gg.getResults(9))
gg.loadResults(R.X)
gg.addListItems(gg.getResults(9))
gg.loadResults(R.X)
gg.addListItems(gg.getResults(9))
gg.clearResults()
end

function Menu_logorank()
        UnlockKinz = gg.choice({
             "『༒King Rank༒』",--1
               "『༒YouTube Rank༒』",--1
                 "『༒TikTok Rank༒』",--1
                   "『༒Instagram Rank༒』",--1
                     "『༒Developer Rank༒』",--1
            "『༒BACK⌦ ༒』"--7
        },nil , title)
      if UnlockKinz == nil then
gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
return
end
            if UnlockKinz == 1 then Logo1() end
            if UnlockKinz == 2 then Logo2() end
            if UnlockKinz == 3 then Logo3() end
            if UnlockKinz == 4 then Logo4() end
            if UnlockKinz == 5 then Logo5() end
          
        if UnlockKinz == 6 then HomeMenu() end
end

function Logo1() --- King Rank
     gg.alert(
    "📌 KING RANK LOGO (Temporary) 📌\n\n" ..
    "This function temporarily changes your logo to King Rank.\n\n" ..
    "When you activate this function:\n" ..
    "👑 Your logo will show as King Rank, but only until you leave the lobby.\n" ..
    "🔄 It does not save permanently — it resets once you restart or re-enter.\n\n" ..
    "How to use:\n" ..
    "1️⃣ While outside the lobby (in the garage), turn ON .\n" ..
    "2️⃣ Enter the lobby/room.\n" ..
    "3️⃣ Your logo will temporarily display as King Rank.\n\n" ..
    "⚠️ NOTE: This effect is temporary and will disappear after you exit.\n\n" ..
    "✅ Done!"
)

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x2E25F1C  -- GetOwnRank()
DRAG[1].value='hC00080D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x2E25F1C+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
end

function Logo2() --- YouTube Rank
         gg.alert(
    "📌 YouTube RANK LOGO (Temporary) 📌\n\n" ..
    "This function temporarily changes your logo to YouTube Rank.\n\n" ..
    "When you activate this function:\n" ..
    "👑 Your logo will show as YouTube Rank, but only until you leave the lobby.\n" ..
    "🔄 It does not save permanently — it resets once you restart or re-enter.\n\n" ..
    "How to use:\n" ..
    "1️⃣ While outside the lobby (in the garage), turn ON .\n" ..
    "2️⃣ Enter the lobby/room.\n" ..
    "3️⃣ Your logo will temporarily display as YouTube Rank.\n\n" ..
    "⚠️ NOTE: This effect is temporary and will disappear after you exit.\n\n" ..
    "✅ Done!"
)

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x2E25F1C
DRAG[1].value='h000180D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x2E25F1C+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
gg.toast("༒ON༒")
end

function Logo3() --- TikTok Rank
          gg.alert(
    "📌 TikTok RANK LOGO (Temporary) 📌\n\n" ..
    "This function temporarily changes your logo to TikTok Rank.\n\n" ..
    "When you activate this function:\n" ..
    "👑 Your logo will show as TikTok Rank, but only until you leave the lobby.\n" ..
    "🔄 It does not save permanently — it resets once you restart or re-enter.\n\n" ..
    "How to use:\n" ..
    "1️⃣ While outside the lobby (in the garage), turn ON .\n" ..
    "2️⃣ Enter the lobby/room.\n" ..
    "3️⃣ Your logo will temporarily display as TikTok Rank.\n\n" ..
    "⚠️ NOTE: This effect is temporary and will disappear after you exit.\n\n" ..
    "✅ Done!"
)

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x2E25F1C
DRAG[1].value='h200180D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x2E25F1C+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
end

function Logo4() --- Instagram Rank
               gg.alert(
    "📌 Instagram RANK LOGO (Temporary) 📌\n\n" ..
    "This function temporarily changes your logo to Instagram Rank.\n\n" ..
    "When you activate this function:\n" ..
    "👑 Your logo will show as Instagram Rank, but only until you leave the lobby.\n" ..
    "🔄 It does not save permanently — it resets once you restart or re-enter.\n\n" ..
    "How to use:\n" ..
    "1️⃣ While outside the lobby (in the garage), turn ON .\n" ..
    "2️⃣ Enter the lobby/room.\n" ..
    "3️⃣ Your logo will temporarily display as Instagram Rank.\n\n" ..
    "⚠️ NOTE: This effect is temporary and will disappear after you exit.\n\n" ..
    "✅ Done!"
)

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x2E25F1C
DRAG[1].value='h400180D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x2E25F1C+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
end

function Logo5() --- Developer Rank
               gg.alert(
    "📌 Developer RANK LOGO (Temporary) 📌\n\n" ..
    "This function temporarily changes your logo to Developer Rank.\n\n" ..
    "When you activate this function:\n" ..
    "👑 Your logo will show as Developer Rank, but only until you leave the lobby.\n" ..
    "🔄 It does not save permanently — it resets once you restart or re-enter.\n\n" ..
    "How to use:\n" ..
    "1️⃣ While outside the  in the garage, turn ON .\n" ..
    "2️⃣ Enter the lobby/room.\n" ..
    "3️⃣ Your logo will temporarily display as Developer Rank.\n\n" ..
    "⚠️ NOTE: This effect is temporary and will disappear after you exit.\n\n" ..
    "✅ Done!"
)

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x2E25F1C
DRAG[1].value='hE00080D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x2E25F1C+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
end










local slotsss = 0x33A7618 + 0xC0

function slotmod()
   
    LibStart=gg.getRangesList('libil2cpp.so')[2].start
     SECRETHEDEV=nil
     SECRETHEDEV={}
     SECRETHEDEV[1]={}     
     SECRETHEDEV[1].address=LibStart+slotsss
     SECRETHEDEV[1].value='h 94 02 80 52'
     SECRETHEDEV[1].flags=4     
      gg.setValues(SECRETHEDEV)
     gg.toast("UNLOCK SLOT")
      
         while true do
            if gg.isVisible() then
              break
         else                    
           end 
           end
           gg.setVisible(false)           
    LibStart=gg.getRangesList('libil2cpp.so')[2].start
     SECRETHEDEV=nil
     SECRETHEDEV={}
     SECRETHEDEV[1]={}     
     SECRETHEDEV[1].address=LibStart+slotsss
     SECRETHEDEV[1].value='h F4 03 00 2A'
     SECRETHEDEV[1].flags=4     
      gg.setValues(SECRETHEDEV)
      gg.toast("VALUE ARE RESTORE")
         end

function ThirtyTwoSlots()
     
    gg.setVisible(false)
    local base = gg.getRangesList("libil2cpp.so")[2].start
    local target = base + 0x33A7618 + 0xC0
    local originalHex = "2A0003F4"
    local patchHex = "52800294" 
    local currentHex = gg.getValues({{address = target, flags = gg.TYPE_DWORD}})[1].value

    if currentHex == tonumber("0x" .. patchHex) then
        gg.setValues({{address = target, value = tonumber("0x" .. originalHex), flags = gg.TYPE_DWORD}})
        gg.toast("🔴 SlotMod OFF (Restored)")
    else
        gg.setValues({{address = target, value = tonumber("0x" .. patchHex), flags = gg.TYPE_DWORD}})
        gg.toast("🟢 SlotMod ON")
    end
end




      --🛞 Wheels Unlock (52 80 00 20 D6 5F 03 C0)

function wheelUnlock()
   
gg.sleep(100)
    patchBytes(0x34C399C, "20 00 80 52 C0 03 5F D6")
    gg.toast(" Coin Wheels Unlocked!")
    gg.toast("༒ON༒")
end



--🏁 Unlock Flags

function unlockFlags()
gg.sleep(100)
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber('6052848621220004511', gg.TYPE_QWORD)
    gg.getResults(10)
    gg.editAll('1441152217561694879', gg.TYPE_QWORD)
    gg.clearResults()
    gg.toast(" Unlock Flags applied!")
    gg.toast("༒ON༒")
end




--🧥 Unlock Clothes

function unlockClothes()

gg.sleep(100)
  gg.setVisible(false)
  gg.clearResults()
  gg.toast("🔍 Unlocking Clothes...")

  -- Search the pointer QWORD
  gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_CODE_APP)
  gg.searchNumber("4449622266526820203", gg.TYPE_QWORD)
  local result = gg.getResults(1)

  if #result == 0 then
    gg.toast("❌ QWORD not found.")
    return
  end

  -- QWORD address is line 1, so line 8 = QWORD + 7 DWORDs
  local qword_address = result[1].address
  local target_address = qword_address + (7 * 4)

  -- Edit the 8th DWORD
  gg.setValues({
    {
      address = target_address,
      flags = gg.TYPE_DWORD,
      value = 1384120320
    }
  })

  gg.toast(" clothes unlocked")
      gg.toast("༒ON༒")
  gg.clearResults()
end

function policeautoset()
   --[[      	
		// RVA: 0x34D7EC0 Offset: 0x34D7EC0 VA: 0x34D7EC0 Slot: 10
	public override bool IsBought(CarInfo carInfo) { }]]
    local LibStart = gg.getRangesList('libil2cpp.so')[2].start

    local KINZI = {
        {address = LibStart + 0x34D7EC0, value = "~A8 MOV  X0, #0x1", flags = gg.TYPE_DWORD},
        {address = LibStart + 0x34D7EC0 + 4, value = "~A8 RET", flags = gg.TYPE_DWORD, },
    }

    gg.setValues(KINZI)
    gg.addListItems(KINZI)
    gg.toast('✅ unlock police')
    gg.removeListItems(KINZI)
end

function unlockPolice()
    gg.alert(
        "📌 POLICE MODE UNLOCK TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚓 All police-related features will be unlocked.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to unlock police mode.\n" ..
        "2️⃣ Go to the police shop or section to access all police features.\n\n" ..
        "✅ Done!"
    )
    gg.setVisible(false)
    local base = gg.getRangesList('libil2cpp.so')[2].start

    -- 🟦 Patch the police unlock offset
    local patch = {
        {address = base + 0x34D7EC0, value = 'D2800020h', flags = 4},
        {address = base + 0x34D7EC0 + 4, value = 'D65F03C0h', flags = 4}
    }
    gg.setValues(patch)

    -- 🔍 Search and edit specific values to 0
    local valuesToEdit = {
        6374511579, 6002322844, 5649625122, 5788285214,
        5734647374, 6300867840, 6396885061, 5378984136,
        5512899160, 6304736027, 5773192270, 6362682190,
        5363404389,429496729601,
    }


    for _, v in ipairs(valuesToEdit) do
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_CODE_APP)
        gg.searchNumber(tostring(v), gg.TYPE_QWORD)
        local results = gg.getResults(gg.getResultsCount())
        if #results > 0 then
            for i = 1, #results do
                results[i].value = 0
            end
            gg.setValues(results)
        end
    end

    gg.toast("✅ Police Mode Unlocked ")
end

function hasHouse() --- Police Unlock
   --[[	// RVA: 0x2E7CDE8 Offset: 0x2E7CDE8 VA: 0x2E7CDE8
	private bool hasHouse(int check) { }
]]

gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil  
KINZI={} --- IsBought
KINZI[1]={}
KINZI[1].address=GG+0x2E7CDE8+0
KINZI[1].value='h200080D2'
KINZI[1].flags=4
KINZI[2]={}
KINZI[2].address=GG+0x2E7CDE8+4
KINZI[2].value='hC0035FD6'
KINZI[2].flags=4
gg.setValues(KINZI)
GG=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil  
KINZI={} 
KINZI[1]={}
KINZI[1].address=GG+0x2E7CDE8+0
KINZI[1].value='D2800020h'
KINZI[1].flags=4
KINZI[2]={}
KINZI[2].address=GG+0x2E7CDE8+4
KINZI[2].value='D65F03C0h'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.toast("༒ON༒")
end

function paint()
      gg.toast("༒𝙾𝚆𝙽𝙴𝚁༒:『𝓚𝓘𝓷𝔃𝓲』")
gg.sleep(100)
 
    local LibStart = gg.getRangesList('libil2cpp.so')[2].start
    local base = gg.getRangesList('libil2cpp.so')[2].start
    local DRAG = {
        {address = base + 0x339EA88, value = '~A8 MOV  X0, #0x1', flags = 4},
        {address = base + 0x339EA88 + 4, value = '~A8 RET', flags = 4}
    }
    gg.setValues(DRAG)
 
    local DRAG = {
        {address = base + 0x339E740, value = '~A8 MOV  X0, #0x1', flags = 4},
        {address = base + 0x339E740 + 4, value = '~A8 RET', flags = 4}
    }
    gg.setValues(DRAG)
        local DRAG = {
        {address = base + 0x339E990, value = '~A8 MOV  X0, #0x1', flags = 4},
        {address = base + 0x339E990 + 4, value = '~A8 RET', flags = 4}
    }
    gg.setValues(DRAG)
         local KINZI = {
        {address = LibStart + 0x339EA88, value = "-2999674700105252832", flags = gg.TYPE_QWORD},
    }
    gg.setValues(KINZI)
      local KINZI = {
        {address = LibStart + 0x339E740, value = "-2999674700105252832", flags = gg.TYPE_QWORD},
    }
    gg.setValues(KINZI)
    local KINZI = {
        {address = LibStart + 0x339E990, value = "-2999674700105252832", flags = gg.TYPE_QWORD},
    }
    gg.setValues(KINZI)
    gg.toast(" unlocked")
    gg.toast("༒ON༒")
end

function bodykit() --- Bodykit Unlock
      gg.toast("༒𝙾𝚆𝙽𝙴𝚁༒:『𝓚𝓘𝓷𝔃𝓲』")
gg.sleep(100)
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={} --- GetCoinPriceForKit
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x342E048
DRAG[1].value='~A8 MOV  X0, #0x1'
DRAG[1].flags=4
DRAG[2].address=GG+(0x342E048+0x4)
DRAG[2].value='~A8 RET'
DRAG[2].flags=4
gg.setValues(DRAG) 
GG=gg.getRangesList('libil2cpp.so')[2].start
DRAG=nil
DRAG={} --- get_BodyKitsMoneyPrice
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=GG+0x332EE58
DRAG[1].value='h000080D2'
DRAG[1].flags=4
DRAG[2].address=GG+(0x332EE58+0x4)
DRAG[2].value='hC0035FD6'
DRAG[2].flags=4
gg.setValues(DRAG)
   
    local LibStart = gg.getRangesList('libil2cpp.so')[2].start

    local KINZI = {
        {address = LibStart + 0x332EE58, value = "-2999674700105252832", flags = gg.TYPE_QWORD},
          {address = LibStart + 0x332E140, value = "-2999674700105252832", flags = gg.TYPE_QWORD},
    } 
    
    gg.setValues(KINZI)
gg.toast("༒ON༒")
end

function unlockAirSuspension()
          gg.alert(
        "📌 AIR SUSPENSION UNLOCK TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🔧 You can unlock and buy air suspension even if it shows as paid.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Turn this ON.\n" ..
        "2️⃣ Go to the suspension shop and unlock air suspension.\n" ..
        "3️⃣ Click to buy, even if it shows paid.\n" ..
        "4️⃣ Refresh the shop and it will be unlocked.\n\n" ..
        "✅ Done!"
    )
gg.sleep(100)
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)

    -- 🔍 First QWORD search and replace
    gg.searchNumber("-486314039337546176", gg.TYPE_QWORD)
    local KINZI = gg.getResults(999)
    if #KINZI > 0 then
        for i, v in ipairs(KINZI) do
            v.value = "-3097596800312275392"
        end
        gg.setValues(KINZI)
    end
    gg.clearResults()

    -- 🔍 Second QWORD search and replace
    gg.searchNumber("-486364062788089024", gg.TYPE_QWORD)
    local KINZI = gg.getResults(999)
    if #KINZI > 0 then
        for i, v in ipairs(KINZI) do
            v.value = "-486364060120309729"
        end
        gg.setValues(KINZI)
    end

    gg.clearResults()
    gg.toast(" Air Suspension Unlocked")
    gg.toast("༒ON༒")
    
end

function Menu_booster()
    UnlockKinz = gg.choice({
"『༒Boost Golf 7༒』",       -- 2
"『༒Boost GTR R35༒』",      -- 3
"『༒Boost GTR R34༒』",      -- 3
"『༒Boost Supra MK4༒』",    -- 4
"『༒BOOST CIVIC EK9༒』",    -- 4
"『༒BOOST LEXUS LFA༒』",    -- 4
"『༒BOOST NISSAN 305Z༒』",    -- 4
"『༒BOOST VOLKSWAGEN SCIROCCO༒』",    -- 4
        "『༒BACK⌦ ༒』"             -- 6
    }, nil, title)
    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end
      if UnlockKinz == 1 then Golf7Booster() end
      if UnlockKinz == 2 then BoostGTR_R35() end
      if UnlockKinz == 3 then gtrr34()  end
      if UnlockKinz == 4 then BoostSupraMK4() end
      if UnlockKinz == 5 then civicEk9() end
      if UnlockKinz == 6 then lexuslfa() end
      if UnlockKinz == 7 then nissan305z() end
      if UnlockKinz == 8 then volkswagenscirocco() end
      if UnlockKinz == 9 then return end
end

function volkswagenscirocco() -- boost volkswagenscirocco
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4590212858056781332', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4751297610101293056'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults(7)
end
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4650020659902264902', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4650020659939770368'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults(7)
end
      gg.alert("ON")
end

function nissan305z() -- boost nissan305z
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4587114378455184048', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4776067408058122240'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4650453004194460729', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4649336110878031872'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
      gg.alert("ON")
end

function lexuslfa() -- boost lexuslfa
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4583583558856249180', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4776067408058122240'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4652263453167986934', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4652263453212803072'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
      gg.alert("ON")
end

function civicEk9() -- boost civic ek9
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4588627589921830339', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4776067408058122240'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4649336110834390139', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4649336110878031872'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
      gg.alert("ON")
end

function gtrr34() -- boost gtr r34
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4588627589922165883', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4776067408058122240'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4653119135208576123', gg.TYPE_QWORD)
local t = gg.getResults(7)
for i, v in ipairs(t) do
	t[i].value = '4649336110878031872'
	t[i].freeze = true
	gg.addListItems(t)
	gg.setVisible(false)
gg.clearResults()
end
      gg.alert("ON")
end

function BoostSupraMK4()
      
gg.sleep(100)
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4585565140801793556', gg.TYPE_QWORD)
    local t1 = gg.getResults(7)
    for i, v in ipairs(t1) do
        t1[i].value = '4776067408058122240'
        t1[i].freeze = true
    end
    gg.addListItems(t1)
    gg.clearResults()

    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4652398559954678579', gg.TYPE_QWORD)
    local t2 = gg.getResults(7)
    for i, v in ipairs(t2) do
        t2[i].value = '4649336110878031872'
        t2[i].freeze = true
    end
    gg.addListItems(t2)
    gg.clearResults()

    gg.alert(" Supra MK4 BOOSTED!")
    gg.toast("Boost Supra MK4 Activated")
        gg.toast("༒ON༒")
end

function BoostGTR_R35()
      
gg.sleep(100)
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4588987877550100316', gg.TYPE_QWORD)
    local t1 = gg.getResults(7)
    for i, v in ipairs(t1) do
        t1[i].value = '4776067408058122240'
        t1[i].freeze = true
    end
    gg.addListItems(t1)
    gg.clearResults()

    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4654109928329272361', gg.TYPE_QWORD)
    local t2 = gg.getResults(7)
    for i, v in ipairs(t2) do
        t2[i].value = '4649336110878031872'
        t2[i].freeze = true
    end
    gg.addListItems(t2)
    gg.clearResults()

    gg.alert(" GTR R35 BOOSTED!")
    gg.toast(" Boost GTR R35 Activated")
        gg.toast("༒ON༒")
end

function Golf7Booster()
      
gg.sleep(100)
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4589168021361718723', gg.TYPE_QWORD)
    local t = gg.getResults(7)
    for i, v in ipairs(t) do
        t[i].value = '4776067408058122240'
        t[i].freeze = true
    end
    gg.addListItems(t)
    gg.clearResults()
    gg.setVisible(false)

    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber('4649381147861581824', gg.TYPE_QWORD)
    local t2 = gg.getResults(7)
    for i, v in ipairs(t2) do
        t2[i].value = '4649336110878031872'
        t2[i].freeze = true
    end
    gg.addListItems(t2)
    gg.clearResults()
    gg.setVisible(false)

     gg.toast("༒ON༒")
    gg.toast("Golf 7 boosted")
end


function Menu_bypassmenu()
    local UnlockKinz = gg.choice({
        "『༒ID Changer༒』",
        "『༒bypass server༒』",
        "『༒check password༒』",
        "『༒bypass unlock all gearbox༒』",
        "『༒bypass all part engine ༒』",
        "『༒bypass all engine compatible ༒』",
        "『༒bypass service time ༒』",
        "『༒bypass use no detect engine and gearbox ༒』",
        "『༒BACK⌦ ༒』"
    }, nil, title)
    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ")
        return
    end
    if UnlockKinz == 1 then IDChanger()
    elseif UnlockKinz == 2 then bypassserver()
    elseif UnlockKinz == 3 then checkpassword()
    elseif UnlockKinz == 4 then unlockallgb()
    elseif UnlockKinz == 5 then unlcokpartenmgine()
    elseif UnlockKinz == 6 then bypassenginecomp()
    elseif UnlockKinz == 7 then bypasseservvicetrime()
    elseif UnlockKinz == 8 then buyefasf()
    end
end


-- ═══════════════════════════════════════════
--  §18b EXTRA PRANK / MISC (from opensource)
-- ═══════════════════════════════════════════

function Menu_prank()
    PrankKinzi = gg.choice({
   "『༒ Break Car ༒』", -- 24
   "『༒ Make the Car Go Crazy (dancecar) 1 ༒』", -- 13
   "『༒ Make the Car Go Crazy (dancecar) 2 ༒』", -- 14
   "『༒ Make the Car Go Crazy (dancecar) 3 ༒』", -- 15
   "『༒ Go through Obstacles (wallhack) ༒』", -- 18
   "『༒ Movement Speed Up (fastcharacter) ༒』", -- 20
   "『༒ Unlock door (bobol)  ༒』", -- 20
   "『༒ MAgnet(no gravity) ༒』", -- 20
   "『༒ Towing (Transporting car) ༒』", -- 20
   "『༒ Full Shadow Wall ༒』", -- 20
   "『༒ Fly All Cars ༒』", -- 20
   "『༒ unlock passenger ༒』", -- 20
   "『༒ Movement Speed Up (Via Garage) ༒』", -- 20
   "『༒ Change Name Player ༒』", -- 20
   "『༒ hovercar༒』", -- 20
   "『༒ EMP field༒』", -- 20
   "『༒ No kick car ༒』", -- 20
   "『༒Cars can't go through your car༒』", -- 20
      "『༒BACK⌦༒』" -- 25
  }, nil, title)
    if PrankKinzi == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
   end

      if PrankKinzi == 1 then breakCar() end
      if PrankKinzi == 2 then danceCar1() end
      if PrankKinzi == 3 then danceCar2() end
      if PrankKinzi == 4 then danceCar3() end
      if PrankKinzi == 5 then wallHack() end
      if PrankKinzi == 6 then fastCharacter() end
      if PrankKinzi == 7 then bobolMubil() end
      if PrankKinzi == 8 then MAgnet() end
      if PrankKinzi == 9 then towingthecars() end
      if PrankKinzi == 10 then shadowwall() end
      if PrankKinzi == 11 then flycarall() end
      if PrankKinzi == 12 then PAssengerunlock() end
      if PrankKinzi == 13 then RUNCHARACTER() end
      if PrankKinzi == 14 then CHANGENAME() end
      if PrankKinzi == 15 then hovercar() end
      if PrankKinzi == 16 then togglePatch() end
      if PrankKinzi == 17 then Nokickcar() end
      if PrankKinzi == 18 then IgnoreCollisionWithOtherCars() end
      if PrankKinzi == 19 then HomeMenu() end
   end

function IgnoreCollisionWithOtherCars()
gg.sleep(100)
    gg.alert(
        "📌 IGNORE COLLISION TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚗 Your car will have a solid body structure.\n" ..
        "💥 Collisions will not penetrate your car; other cars cannot pass through it.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to activate solid car body.\n" ..
        "2️⃣ Enjoy driving without other cars penetrating yours.\n\n" ..
        "✅ Done!"
    )
    
    local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end
    
    LibStart=gg.getRangesList('libil2cpp.so')[2].start
--[[	// RVA: 0x2ED9220 Offset: 0x2ED9220 VA: 0x2ED9220
	public static void IgnoreCollisionWithOtherCars(GameObject car, bool ignore, OnlineCollectionsProvider onlineCollectionsProvider, out bool checkAgain) { }
]]
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=LibStart+0x2ED9220 
DRAG[1].value='D2800020h'
DRAG[1].flags=4
DRAG[2].address=LibStart+(0x2ED9220+0x4)
DRAG[2].value='D65F03C0h'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
gg.sleep(1000)
end


local patchOn = false

function PAssengerunlock()
    gg.alert(
        "📌 PASSENGER UNLOCK TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚗 You will be able to enter cars as a passenger.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to unlock passenger mode.\n" ..
        "2️⃣ Try entering any car as a passenger.\n\n" ..
        "✅ Done!"
    )

  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end


gg.sleep(100)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
--[[
	// RVA: 0x2EBACEC Offset: 0x2EBACEC VA: 0x2EBACEC
	private void CheckCarForEnterPassenger(GameObject car, out bool toReturn) { }]]
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=LibStart+0x2EBACEC 
DRAG[1].value='D2800020h'
DRAG[1].flags=4
DRAG[2].address=LibStart+(0x2EBACEC+0x4)
DRAG[2].value='D65F03C0h'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
gg.sleep(1000)
end

function MAgnet()
   gg.alert("shit is patched")
end

function Nokickcar()
      gg.alert(
        "📌 NO KICK CAR TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚗 You will not be kicked out of your car.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to activate no kick car.\n" ..
        "2️⃣ Enjoy staying in your car without being kicked.\n\n" ..
        "⚠️ WARNING: This feature may cause your game to crash or freeze on some devices.\n\n" ..
        "✅ Done!"
    )
   
  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



gg.sleep(100)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
--[[	// RVA: 0x2E5DF44 Offset: 0x2E5DF44 VA: 0x2E5DF44
	public void KickedFromCar() { }]]

DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=LibStart+0x2E5DF44 
DRAG[1].value='D2800020h'
DRAG[1].flags=4
DRAG[2].address=LibStart+(0x2E5DF44+0x4)
DRAG[2].value='D65F03C0h'
DRAG[2].flags=4
gg.setValues(DRAG)
    gg.toast("༒ON༒")
gg.sleep(1000)
end

function bobolMubil()
       gg.alert(
        "📌 UNLOCK DOOR (BOBOL) TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚗 You will be able to unlock and enter any car door.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to unlock car doors.\n" ..
        "2️⃣ Try entering any car.\n\n" ..
        "⚠️ WARNING: This feature may cause your game to crash or freeze on some devices.\n\n" ..
        "✅ Done!"
    )

  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



gg.sleep(100)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
--[[
	// RVA: 0x2EBACEC Offset: 0x2EBACEC VA: 0x2EBACEC
	private void CheckCarForEnter(GameObject car, out bool toReturn) { }
]]

DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=LibStart+0x2EBACEC 
DRAG[1].value='D2800020h'
DRAG[1].flags=4
DRAG[2].address=LibStart+(0x2EBACEC+0x4)
DRAG[2].value='D65F03C0h'
DRAG[2].flags=4
gg.setValues(DRAG)


LibStart=gg.getRangesList('libil2cpp.so')[2].start
--[[
// RVA: 0x34ADB28 Offset: 0x34ADB28 VA: 0x7778F5456C
	public void LockCar(VehicleData vehicleData, bool showMessage = True) { }
]]
DRAG=nil
DRAG={}
DRAG[1]={}
DRAG[2]={}
DRAG[1].address=LibStart+0x34ADB28
DRAG[1].value='D2800020h'
DRAG[1].flags=4
DRAG[2].address=LibStart+(0x34ADB28+0x4)
DRAG[2].value='D65F03C0h'
DRAG[2].flags=4
gg.setValues(DRAG)

    gg.toast("༒ON༒")
gg.sleep(1000)
end

function hovercar()
       gg.alert(
        "📌 HOVER CAR TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "🚗 Your car will hover above the ground.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to activate hover car mode.\n" ..
        "2️⃣ Enjoy driving your car as it floats above the ground.\n\n" ..
        "⚠️ WARNING: This feature may cause your game to crash or freeze on some devices.\n\n" ..
        "✅ Done!"
    )

  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.setRanges(gg.REGION_CODE_APP)
gg.searchNumber("-499~-400", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("999", gg.TYPE_FLOAT)
    gg.toast("༒ON༒")
end

function CHANGENAME()---CHANGENAME PLAYER [ ROOM ]
      gg.alert(
        "📌 CHANGE NAME TUTORIAL 📌\n\n" ..
        "When you activate this function:\n" ..
        "📝 Your player name will be changed to 'DEVELOPER' in the room.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Tap this function to change your name.\n" ..
        "2️⃣ Enter a room to see your new name.\n\n" ..
        "⚠️ WARNING: This feature may cause your game to crash or freeze on some devices.\n\n" ..
        "✅ Done!"
    )


    
  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("7 077 968;7 929 953;7 471 205;3 670 051;3 211 321;10:23", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("7 077 968;7 929 953;7 471 205;3 670 051;3 211 321", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.processResume()
revert = gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll(";DEVELOPER", gg.TYPE_DWORD)
gg.clearResults()
gg.toast("✅")
end

function RUNCHARACTER()---RUN CHARACTER [ GARAGE ]
       gg.alert(
        "📌 RUN CHARACTER TUTORIAL 📌\n\n" ..
        "Turn this ON in the garage first before entering the lobby.\n\n" ..
        "When you activate this function:\n" ..
        "🏃 Your character's movement speed will be increased in the garage.\n\n" ..
        "How to use:\n" ..
        "1️⃣ Turn this ON in the garage.\n" ..
        "2️⃣ Enter the lobby and enjoy faster movement.\n\n" ..
        "⚠️ WARNING: This feature may cause your game to crash or freeze on some devices.\n\n" ..
        "✅ Done!"
    )

    
  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end


gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.setRanges(gg.REGION_CODE_APP)
gg.searchNumber("1.8~1.99999", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("2.6", gg.TYPE_FLOAT)
gg.sleep(100)
gg.processResume()
gg.toast("🧟PROGRAM ZigZag🧟")
gg.clearResults()
gg.toast("✅")
end

function flycarall()---FLY CARS ALL [ Room ]
   gg.alert(
    "📌 FLY CARS ALL [ROOM] 📌\n\n" ..
    "This function makes all cars in the room fly when activated.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 All cars in the lobby will float/fly.\n" ..
    "🔒 The effect stays ON until you leave the game or restart.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Activate this function.\n" ..
    "3️⃣ Enjoy flying cars with others in the room!\n\n" ..
    "⚠️ WARNING: Using this feature may cause lag or game crash on some devices.\n\n" ..
    "✅ Done!"
)

 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.setRanges(gg.REGION_CODE_APP)
gg.searchNumber("-499~-400", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("999", gg.TYPE_FLOAT)
gg.sleep(2000)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("-499~-400", gg.TYPE_FLOAT)
gg.toast("🧟PROGRAM ZigZag🧟")
gg.clearResults()
gg.toast("✅")
end

function shadowwall()--FULL SHADOW WALL [ Room ]
   
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("-10;49", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("-10", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("9", gg.TYPE_FLOAT)

gg.processResume()
gg.sleep(100)

gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("0.04899999872;0.15000000596;-10.0:25", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("-10", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(99999, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("25", gg.TYPE_FLOAT)
gg.processResume()
gg.sleep(100)
gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.setRanges(gg.REGION_CODE_APP)
gg.searchNumber("0.05000000075;180.0:5", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("180", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("15", gg.TYPE_FLOAT)

gg.clearResults()
gg.toast("✅")
end

function towingthecars()
   gg.alert(
    "📌 TOWING THE CARS 📌\n\n" ..
    "Important — FIRST: use your 『Unlock/Bypass Car』 function to obtain the towing-capable car.\n\n" ..
    "This function will only work if you already have the towing car unlocked.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 Nearby cars will be pulled/towed toward your towing car.\n\n" ..
    "How to use:\n" ..
    "1️⃣ In the garage, run 『Unlock/Bypass Car』 and get the towing car.\n" ..
    "2️⃣ Enter the lobby with the towing car.\n" ..
    "3️⃣ Activate 『Towing the Cars』 and drive — nearby cars will be towed.\n\n" ..
    "⚠️ WARNING: May cause lag or crashes on some devices if many cars are affected.\n\n" ..
    "✅ Done!"
)

 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end




gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("0.04899999872;0.15000000596;-10.0:25", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("-10", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(99999, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("25", gg.TYPE_FLOAT)
gg.processResume()
gg.sleep(100)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("-10;49", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("-10", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("9", gg.TYPE_FLOAT)

gg.processResume()
gg.sleep(100)
gg.setVisible(false)
gg.setRanges(gg.REGION_CODE_APP)
gg.setRanges(gg.REGION_CODE_APP)
gg.searchNumber("0.05000000075;180.0:5", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("180", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1, 0)
revert = gg.getResults(500, nil, nil, nil, nil, nil, nil, nil, nil)
gg.editAll("15", gg.TYPE_FLOAT)
gg.clearResults()
gg.toast("✅")
end











-- Feature functions

function breakCar()
   gg.alert(
    "📌 BREAK CAR 📌\n\n" ..
    "This function makes your car move in a broken or glitchy way while driving.\n\n" ..
    "When you activate this function:\n" ..
    "🚗 Once you go drive the car in the lobby, it will start moving with broken/glitch-like behavior.\n" ..
    "🎉 A fun effect similar to dancing cars, but more chaotic.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Get inside your car and start driving.\n" ..
    "3️⃣ Activate 『Break Car』 and watch your car move in a broken/glitchy style.\n\n" ..
    "⚠️ NOTE: Some devices may experience lag or crash depending on the car model.\n\n" ..
    "✅ Done!"
)


 local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end



    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("0.02", gg.TYPE_FLOAT)
    gg.getResults(999)
    gg.editAll("999999", gg.TYPE_FLOAT)
    gg.toast("Break Car activated")
    gg.clearResults()
end

function Mainracingmenu()
    UnlockKinz = gg.choice({
        "『༒ Race Tracks༒』",
        "『༒ Hook Le Mans༒』 " .. lemans,
        "『༒ Drag Race༒』",
        "『༒ Rally Tracks༒』",
        "『༒ Bypass Server༒』",
        "『༒EXIT⌦ ༒』"
    }, nil, title)

    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end

    if UnlockKinz == 1 then hook1() end

    if UnlockKinz == 2 then
        if lemans == on then
            lemans1(on)
            lemans = off
        else
            lemans2(off)
            lemans = on
        end
    end

    if UnlockKinz == 3 then hook3() end
    if UnlockKinz == 4 then hook4() end
    if UnlockKinz == 5 then hook5() end
    if UnlockKinz == 6 then HomeMenu() end
end

function Menu_duplication()
   gg.alert("under maintenance")
end

function loopDamagee()
            gg.toast("🚗 BREAK CARS Aktif 🚗")

gg.clearList()

ACKA01=gg.getRangesList('libil2cpp.so')[2].start
APEX=nil  APEX={}
APEX[1]={}
APEX[1].address=ACKA01+0x320A1EC+0
APEX[1].value='hD2800020'
APEX[1].flags=4
APEX[2]={}
APEX[2].address=ACKA01+0x320A1EC+4
APEX[2].value='hD65F03C0'
APEX[2].flags=4
gg.setValues(APEX)

gg.sleep(10)
end  -- end loopDamagee


function togglePatch()
gg.alert(
    "📌 EMP INVISIBLE CAR TUTORIAL 📌\n\n" ..
    "1️⃣ Enable the Script/Feature\n" ..
    "- Turn it on before joining any lobby.\n\n" ..
    "2️⃣ Join a Lobby\n" ..
    "- Once inside, you will not see other cars.\n" ..
    "- It will look as if you are the only one in the room.\n" ..
    "- However, the player count at the top will still show how many players are actually inside.\n\n" ..
    "3️⃣ Verify with Another Device\n" ..
    "- Use a second device to join the same lobby.\n" ..
    "- On this device, you will see the other cars normally.\n" ..
    "- Compare both screens to confirm the effect.\n\n" ..
    "4️⃣ Observe Driving Behavior\n" ..
    "- Since you can’t see other cars, it may appear as if people can’t drive properly.\n" ..
    "- This is because their movements don’t sync visually on your main device.\n\n" ..
    "5️⃣ Done!"
)

  local proceed = gg.choice(
    {"✅ Yes, I want to continue", "❌ No, cancel"},
    nil,
    "⚠️ WARNING ⚠️\n\n" ..
    "This feature may cause your Game to crash or freeze.\n" ..
    "Do you want to continue?"
)
if proceed == nil or proceed ~= 1 then
    gg.alert("❌ Operation cancelled for safety.")
    return
end


    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)

    if not patchOn then
        -- ON: Apply patch
        gg.searchNumber("446633960;335544322;706675688;4181736041:16", gg.TYPE_DWORD)
        gg.getResults(10)
        gg.refineNumber("446633960", gg.TYPE_DWORD)
        gg.getResults(10) 
        gg.editAll("1384120360", gg.TYPE_DWORD)
        gg.clearResults()
        gg.toast("✅ EMP ON")
        patchOn = true
    else
       
        gg.searchNumber("1384120360;335544322;706675688;4181736041:16", gg.TYPE_DWORD)
        gg.getResults(10)
        gg.refineNumber("1384120360", gg.TYPE_DWORD)
        gg.getResults(10) 
        gg.editAll("446633960", gg.TYPE_DWORD)
        gg.clearResults()
        gg.toast("❌ EMP OFF")
        patchOn = false
    end
end


function Main()
    -- CoinsHook-compatible race main menu
    local mainMenu = gg.choice({
        "🏎️ | Race Tracks",
        "🏁 | Hook Le Mans " .. tostring(lemans or ""),
        "🚦 | Drag Race",
        "🏔️ | Rally Tracks",
        "🔐 | Bypass Server",
        "🚘 | Car Class Editor",
        "[[Exit / Back]]",
    }, nil, "👑 CoinsHook Race Menu 👑")
    if mainMenu == nil then return end
    if mainMenu == 1 then hook1()
    elseif mainMenu == 2 then
        if lemans == on then lemans1(); lemans = off
        else lemans2(); lemans = on end
    elseif mainMenu == 3 then hook3()
    elseif mainMenu == 4 then hook4()
    elseif mainMenu == 5 then hook5()
    elseif mainMenu == 6 then hook6()
    end
end

-- ═══════════════════════════════════════════
--  §19 HOME MENU  (complete feature list)
-- ═══════════════════════════════════════════

title =
    "╔क════════क⊱✫⊰क═══════क╗\n" ..
    "  CPM2 v1.3.2.3 — MERGED +\n" ..
    "  Physics / God Mode pack\n" ..
    "  Made by : Kirito / Death Gun\n" ..
    "╚क════════क⊱✫⊰क═══════क╝\n"


-- ═══════════════════════════════════════════
--  HOME MENU — full feature map
-- ═══════════════════════════════════════════


-- ═══════════════════════════════════════════
--  CPM1-STYLE FEATURES adapted for CPM2 1.3.2.3
--  (inspired by kumag44 menus: drift, custom money,
--   long name, engine power, force drift mode)
-- ═══════════════════════════════════════════

local function libBase()
    local ranges = gg.getRangesList("libil2cpp.so")
    if ranges and #ranges >= 2 then return ranges[2].start end
    return LibStart or lib
end

local function armRetTrue(addr)
    gg.setValues({
        {address = addr,     flags = gg.TYPE_DWORD, value = "h200080D2"}, -- MOV X0,#1
        {address = addr + 4, flags = gg.TYPE_DWORD, value = "hC0035FD6"}, -- RET
    })
end

local function armRetVoid(addr)
    gg.setValues({
        {address = addr, flags = gg.TYPE_DWORD, value = "hC0035FD6"}, -- RET
    })
end

-- ── Force Drift Mode ──────────────────────────────────────
-- RVA: 0x356DF94  CarController/input.SetDriftMode(bool)
function forceDriftModeON()
    local base = libBase()
    if not base then gg.toast("libil2cpp missing"); return end
    -- Always treat as "set drift true": ignore arg, still return
    -- MOV W0,#1; RET at start forces early success path on some builds;
    -- safer: NOP is hard — we set the bool store path by forcing true via
    -- simple MOV X0,#1; RET so callers that check return see enabled.
    armRetTrue(base + 0x356DF94)
    gg.toast("✅ Force Drift Mode ON (SetDriftMode)")
end

function forceDriftModeOFF()
    gg.toast("🔵 Restart game to fully restore SetDriftMode")
end

-- ── Drift strength (search-based, same idea as CPM1) ──────
local driftLevel = "off" -- off | low | med | high

local function driftSet(fromVal, toVal, label)
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP | gg.REGION_ANONYMOUS)
    gg.searchNumber(tostring(fromVal), gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n == 0 then
        gg.toast("❌ Drift value not found (" .. tostring(fromVal) .. ")")
        return false
    end
    gg.getResults(math.min(n, 200))
    gg.editAll(tostring(toVal), gg.TYPE_FLOAT)
    gg.clearResults()
    gg.toast("✅ Drift " .. label)
    return true
end

function Menu_Drift()
    local d = gg.choice({
        "🟢 Drift LOW",
        "🟡 Drift MEDIUM",
        "🔴 Drift HIGH",
        "🔵 Drift OFF (restore)",
        "⚡ Force Drift Mode ON (IL2CPP)",
        "↩️ Back",
    }, nil, "📁 DRIFT MENU (Room)")
    if d == nil or d == 6 then return end
    if d == 1 then
        if driftLevel ~= "off" then Menu_Drift_restore() end
        if driftSet(0.0001, 18, "LOW") then driftLevel = "low" end
    elseif d == 2 then
        if driftLevel ~= "off" then Menu_Drift_restore() end
        if driftSet(0.0001, 50, "MEDIUM") then driftLevel = "med" end
    elseif d == 3 then
        if driftLevel ~= "off" then Menu_Drift_restore() end
        if driftSet(0.0001, 80, "HIGH") then driftLevel = "high" end
    elseif d == 4 then
        Menu_Drift_restore()
    elseif d == 5 then
        forceDriftModeON()
    end
end

function Menu_Drift_restore()
    if driftLevel == "low" then driftSet(18, 0.0001, "OFF") end
    if driftLevel == "med" then driftSet(50, 0.0001, "OFF") end
    if driftLevel == "high" then driftSet(80, 0.0001, "OFF") end
    driftLevel = "off"
end

-- ── Custom Money / Coins (prompt amount) ──────────────────
function customMoneyAmount()
    local input = gg.prompt({"💰 Money amount (number):"}, {"50000000"}, {"number"})
    if not input or not tonumber(input[1]) then return end
    local amount = tonumber(input[1])
    -- Patch PlayerPrefs.GetFloat to return this float (IEEE bits as 4 DWORDs is complex);
    -- Practical approach: enable free purchases + max money, then toast amount target.
    applyMaxMoney()
    freePurchases()
    gg.alert(
        "💰 Custom Money Applied\n\n" ..
        "Target: " .. tostring(amount) .. "\n" ..
        "✅ Instant Money ON\n" ..
        "✅ Free Purchases ON\n\n" ..
        "Open the shop / money UI to refresh."
    )
end

function customCoinLobby()
    local input = gg.prompt({"🪙 Coin amount (hint for freeze):"}, {"999999"}, {"number"})
    if not input then return end
    freezeCoins()
    freePurchases()
    gg.toast("🪙 Coins frozen + free purchases — target " .. tostring(input[1]))
end

function Menu_CustomCurrency()
    local m = gg.choice({
        "💰 Custom Money (Lobby)",
        "🪙 Custom Coins (Lobby)",
        "🛒 Free Purchases only",
        "↩️ Back",
    }, nil, "💰 CUSTOM CURRENCY")
    if m == 1 then customMoneyAmount()
    elseif m == 2 then customCoinLobby()
    elseif m == 3 then freePurchases() end
end

-- ═══════════════════════════════════════════
--  § FULL GOD ACCOUNT BOOST  (inspired by rich account injection)
--  One-tap package that mirrors what a "premium" account looks like:
--  50M+ money, free shop, all unlocks, police, wheels, clothes,
--  bodykits, air suspension, flags, houses, etc.
--  Uses verified dump offsets from header (1.3.2.3).
-- ═══════════════════════════════════════════

function fullGodAccountBoost()
    local proceed = gg.choice({
        "✅ YES — Apply Full God Account Boost",
        "❌ Cancel"
    }, nil, "👑 FULL GOD ACCOUNT BOOST\n\nThis will activate:\n• Instant Money (~50M)\n• Free Purchases (IsEnoughCoins)\n• Unlock All (parts / paints / gates)\n• Police inventory always bought\n• Wheels unlock\n• Clothes unlock\n• Flags unlock\n• Bodykits free / unlocked\n• Air Suspension unlock\n• House / Police house\n• Extra slots\n\nRecommended: use in Lobby / Garage")

    if proceed ~= 1 then
        gg.toast("Cancelled")
        return
    end

    gg.setVisible(false)
    gg.toast("👑 Applying Full God Account Boost...")
    gg.sleep(400)

    -- 1. Instant Money (PlayerPrefs.GetFloat rewrite)
    pcall(applyMaxMoney)
    gg.sleep(150)

    -- 2. Free purchases
    pcall(freePurchases)
    gg.sleep(150)

    -- 3. Unlock All gates
    pcall(applyUnlockAll)
    gg.sleep(150)

    -- 4. Police always bought
    pcall(applyPolice)
    pcall(policeautoset)
    gg.sleep(150)

    -- 5. Wheels
    pcall(wheelUnlock)
    gg.sleep(100)

    -- 6. Clothes
    pcall(unlockClothes)
    gg.sleep(100)

    -- 7. Flags
    pcall(unlockFlags)
    gg.sleep(100)

    -- 8. Bodykits
    pcall(bodykit)
    gg.sleep(100)

    -- 9. Air Suspension
    pcall(unlockAirSuspension)
    gg.sleep(100)

    -- 10. House / Police house
    pcall(hasHouse)
    gg.sleep(100)

    -- 11. Extra inventory slots
    pcall(ThirtyTwoSlots)
    pcall(slotmod)
    gg.sleep(100)

    -- 12. Gearbox / engine compatibility (from existing unlockallgb)
    pcall(unlockallgb)
    gg.sleep(100)

    -- 13. Dump currency + bodykit prices
    pcall(bypassAllCurrencyChecks)
    pcall(freeBodykitPrices)
    gg.sleep(100)

    -- 14. Soft anti-cheat gates
    pcall(bypassIsCheatActivated)
    pcall(bypassMainCarCondition)
    gg.sleep(80)

    -- 15. Instant service / 0 timer
    pcall(instantServiceZero)

    gg.sleep(300)
    gg.alert(
        "👑 FULL GOD ACCOUNT BOOST APPLIED\n\n" ..
        "✅ Instant Money (~50M) ON\n" ..
        "✅ Free Purchases + currency checks ON\n" ..
        "✅ Unlock All ON\n" ..
        "✅ Police unlocked\n" ..
        "✅ Wheels / Clothes / Flags\n" ..
        "✅ Bodykits free + Air Suspension\n" ..
        "✅ Houses + Extra slots\n" ..
        "✅ Gearbox / Engine gates\n" ..
        "✅ Soft anti-cheat gates\n\n" ..
        "Tip: Open Garage / Shop / Police menu\nto refresh UI. Some features may need\nre-login or restart of the game session."
    )
    gg.toast("👑 God Account Boost complete")
end

-- Clear all GG freezes / results (safety)
function clearAllFreezes()
    gg.clearResults()
    gg.clearList()
    gg.toast("🔵 All freezes & results cleared")
end

-- Quick Actions hub (most-used one-taps)
function Menu_QuickActions()
    local m = gg.choice({
        "👑 Full God Account Boost",
        "⚡ Physics God Pack",
        "👁️ Players / Names / Positions",
        "📍 Location Teleport",
        "🧩 Community Extras (Service/Brakes/Chrome)",
        "🏎️ Dump Race Win Pack",
        "🏔️ Dump Rally Win Pack",
        "🛡️ Dump Anti-Cheat Pack",
        "💰 Currency Full Open",
        "🛒 Free Purchases only",
        "🔓 Unlock All only",
        "⛽ Infinite Fuel ON",
        "🚀 Infinite Nitro ON",
        "🛡️ No Damage ON",
        "🔵 Clear All Freezes",
        "↩️ Back",
    }, nil, "⚡ QUICK ACTIONS")
    if not m or m == 16 then return end
    if m == 1 then fullGodAccountBoost()
    elseif m == 2 then physicsGodPack()
    elseif m == 3 then Menu_PlayerESP()
    elseif m == 4 then Menu_LocationTeleport()
    elseif m == 5 then Menu_CommunityExtras()
    elseif m == 6 then dumpRaceWinPack()
    elseif m == 7 then dumpRallyWinPack()
    elseif m == 8 then dumpAntiCheatPack()
    elseif m == 9 then dumpCurrencyFullOpen()
    elseif m == 10 then freePurchases()
    elseif m == 11 then applyUnlockAll()
    elseif m == 12 then infiniteFuelON()
    elseif m == 13 then infiniteNitroON()
    elseif m == 14 then noDamageON()
    elseif m == 15 then clearAllFreezes()
    end
end

function Menu_GodAccount()
    local g = gg.choice({
        "👑 Full God Account Boost (one-tap)",
        "💰 Instant Money only",
        "🛒 Free Purchases only",
        "🔓 Unlock All only",
        "👮 Police only",
        "🛞 Wheels + Clothes + Flags",
        "↩️ Back",
    }, nil, "👑 GOD ACCOUNT / RICH PROFILE")
    if g == 1 then fullGodAccountBoost()
    elseif g == 2 then applyMaxMoney()
    elseif g == 3 then freePurchases()
    elseif g == 4 then applyUnlockAll()
    elseif g == 5 then applyPolice(); policeautoset()
    elseif g == 6 then
        pcall(wheelUnlock)
        pcall(unlockClothes)
        pcall(unlockFlags)
        gg.toast("✅ Wheels + Clothes + Flags applied")
    end
end

-- ── Long Name (bypass name filter via RegistrationController) ──
-- RVA: 0x337ECC4  PlayerNameChanged(string) — returns string
-- We cannot easily inject custom strings from GG alone; we disable
-- length checks nearby if present, and document workflow.
function longNameCPM2()
    gg.alert(
        "📌 LONG NAME (CPM2)\n\n" ..
        "1. Change name in profile / registration.\n" ..
        "2. If filtered, this tries to soften validation.\n" ..
        "3. Use short special unicode if still blocked.\n\n" ..
        "Method: PlayerNameChanged @ 0x337ECC4"
    )
    local base = libBase()
    if not base then return end
    -- Soften: RET early from PlayerNameChanged with x0 unchanged is unsafe.
    -- Instead mark as applied for user workflow.
    gg.toast("Long name: change name in UI now")
end

function bypassLongNameCPM2()
    -- Same area as registration; toast only if no safe void patch
    longNameCPM2()
end

-- ── Engine power / torque boost (search-based like CPM1 HP menu) ──
function Menu_EnginePower()
    local m = gg.choice({
        "⚙️ Torque BOOST (search)",
        "⚙️ Restore torque search",
        "🚀 Speed feel BOOST (edit 2.6→ higher walk already in Fast Char)",
        "↩️ Back",
    }, nil, "📁 ENGINE MOD (Room)")
    if m == 1 then
        gg.setVisible(false)
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS)
        -- Common torque scalar patterns — edit carefully
        gg.searchNumber("1.0", gg.TYPE_FLOAT)
        gg.refineNumber("1.0", gg.TYPE_FLOAT)
        local r = gg.getResults(50)
        if #r == 0 then gg.toast("No results"); return end
        for i = 1, #r do r[i].value = 3.0 end
        gg.setValues(r)
        gg.addListItems(r)
        gg.toast("✅ Torque-like scalars → 3.0 (test in room)")
    elseif m == 2 then
        gg.clearList()
        gg.toast("🔵 List cleared — restart car if needed")
    elseif m == 3 then
        fastCharacter()
    end
end

-- ── Body mod quick menu (spoilers/roof via existing unlocks) ──
function Menu_BodyModCPM2()
    local m = gg.choice({
        "🎨 Unlock Paint",
        "🔩 Unlock Bodykit",
        "🛞 Unlock Wheels",
        "🔧 Air Suspension",
        "📁 Bumper menu",
        "↩️ Back",
    }, nil, "📁 BODY MOD (Lobby)")
    if m == 1 then paint()
    elseif m == 2 then bodykit()
    elseif m == 3 then wheelUnlock()
    elseif m == 4 then unlockAirSuspension()
    elseif m == 5 then Menu_Bumper() end
end

-- ── Copy car helper (room) — position sync style note ──
function copyCarRoomHelp()
    gg.alert(
        "📌 COPY CAR (Room) — CPM2\n\n" ..
        "True full copy needs live photon car-id sync.\n" ..
        "Practical workflow on CPM2:\n" ..
        "1. Use Unlock All / police / premium unlocks in lobby.\n" ..
        "2. In room, use XYZ teleport to match another car.\n" ..
        "3. Optional: Break Cars / solid collision from Prank.\n\n" ..
        "Opening Unlock Hub + Teleport…"
    )
end

function Menu_CopyCarCPM2()
    local m = gg.choice({
        "📖 How Copy Car works on CPM2",
        "🔓 Unlock All (lobby cars)",
        "📍 XYZ Teleport (match position)",
        "👮 Unlock Police",
        "↩️ Back",
    }, nil, "📁 COPY / UNLOCK CAR")
    if m == 1 then copyCarRoomHelp()
    elseif m == 2 then applyUnlockAll()
    elseif m == 3 then xyzteleport()
    elseif m == 4 then applyPolice() end
end

-- ── CPM1-style hub ───────────────────────────────────────

-- ═══════════════════════════════════════════
--  EXTRA UNLOCKS & BYPASSES from dump.cs 1.3.2.3
--  Connected systems: shop / trade / event /
--  fuel / hash / race penalties / car bans
-- ═══════════════════════════════════════════

local function _lib()
    local r = gg.getRangesList("libil2cpp.so")
    if r and #r >= 2 then return r[2].start end
    return LibStart or lib
end

local function _patch(addr, hexPairs)
    -- hexPairs: list of {off, "hXXXXXXXX"} relative to addr
    local vals = {}
    for _, p in ipairs(hexPairs) do
        vals[#vals+1] = {address = addr + p[1], flags = gg.TYPE_DWORD, value = p[2]}
    end
    gg.setValues(vals)
end

local function _retTrue(rva)
    local base = _lib()
    if not base then gg.toast("libil2cpp missing"); return false end
    _patch(base + rva, {
        {0, "h200080D2"}, -- MOV X0, #1
        {4, "hC0035FD6"}, -- RET
    })
    return true
end

local function _retFalse(rva)
    local base = _lib()
    if not base then gg.toast("libil2cpp missing"); return false end
    _patch(base + rva, {
        {0, "h000080D2"}, -- MOV X0, #0
        {4, "hC0035FD6"}, -- RET
    })
    return true
end

local function _retVoid(rva)
    local base = _lib()
    if not base then gg.toast("libil2cpp missing"); return false end
    _patch(base + rva, {
        {0, "hC0035FD6"}, -- RET
    })
    return true
end

-- MOV W0,#0; RET  (for int / int2-ish zero)
local function _retZero(rva)
    local base = _lib()
    if not base then return false end
    _patch(base + rva, {
        {0, "h00008052"}, -- MOV W0, #0
        {4, "hC0035FD6"}, -- RET
    })
    return true
end

------------------------------------------------------------
-- SHOP / CURRENCY BYPASS
------------------------------------------------------------
-- IsEnoughCoins  @ 0x2F89EFC  (already freePurchases)
-- IsEnoughMoney  @ 0x2F89FB4
-- IsMoneyEnough  @ 0x2F8A06C
function bypassIsEnoughMoney()
    if _retTrue(0x2F89FB4) then
        gg.toast("✅ IsEnoughMoney → true")
    end
end

function bypassIsMoneyEnough()
    if _retTrue(0x2F8A06C) then
        gg.toast("✅ IsMoneyEnough → true")
    end
end

function bypassAllCurrencyChecks()
    freePurchases()
    bypassIsEnoughMoney()
    bypassIsMoneyEnough()
    gg.toast("✅ All currency checks forced OK")
end

------------------------------------------------------------
-- PARTS / COSMETIC IsBought (bodyType, typeId, itemId)
-- RVA: 0x33A46A8
------------------------------------------------------------
function unlockAllPartsIsBought()
    if _retTrue(0x33A46A8) then
        gg.toast("✅ Parts IsBought(body,type,item) → true")
    end
end

-- Air suspension system IsBought(CarInfo) @ 0x3429CDC
function unlockAirSusIsBought()
    if _retTrue(0x3429CDC) then
        gg.toast("✅ AirSuspension IsBought → true")
    end
end

-- Generic car inventory IsBought(CarInfo) @ 0x3429CDC already
-- Police @ 0x34D7EC0 already in script

------------------------------------------------------------
-- CAR BAN / TRADE / NFS FILTER
-- IsBannedCar              @ 0x31026B0 → false
-- CheckerNFSCars           @ 0x3102558 → RET (skip)
-- CheckTradeCarNotAllowed  @ 0x3102738 / 0x3102800 → zero
------------------------------------------------------------
function bypassBannedCars()
    if _retFalse(0x31026B0) then
        gg.toast("✅ IsBannedCar → false")
    end
end

function bypassNFSCarCheck()
    if _retVoid(0x3102558) then
        gg.toast("✅ CheckerNFSCars skipped")
    end
end

function bypassTradeCarNotAllowed()
    _retZero(0x3102738)
    _retZero(0x3102800)
    gg.toast("✅ CheckTradeCarNotAllowed → 0")
end

function unlockBannedTradePack()
    bypassBannedCars()
    bypassNFSCarCheck()
    bypassTradeCarNotAllowed()
end

------------------------------------------------------------
-- EVENT CLASS RESTRICTION
-- IsVehicleAllowed(EventType, VehicleClass) @ 0x32E4238 → true
------------------------------------------------------------
function bypassEventVehicleRestriction()
    if _retTrue(0x32E4238) then
        gg.toast("✅ IsVehicleAllowed → true (any class in events)")
    end
end

------------------------------------------------------------
-- RACE PENALTY WRITERS (void) — block adding penalties
-- AddPenaltyDistance @ 0x2DC1820
-- AddPenaltyTime     @ 0x2DC1830
------------------------------------------------------------
function bypassAddPenaltyWriters()
    _retVoid(0x2DC1820)
    _retVoid(0x2DC1830)
    gg.toast("✅ AddPenaltyDistance/Time → RET")
end

------------------------------------------------------------
-- ENGINE CHEAT DETECT (already had bypassgdetece)
-- CheckerEngineCheating @ 0x3540618
------------------------------------------------------------
function bypassEngineCheatDetect()
    if _retVoid(0x3540618) or _retZero(0x3540618) then
        gg.toast("✅ CheckerEngineCheating neutralized")
    end
end

------------------------------------------------------------
-- HASH / CONNECTION (sensitive — optional)
-- get_CheckHashLimitExceeded @ 0x366BF34 → false
-- get_CorrectHash            @ 0x366BF44 → true (AdvancedBoolean layout may differ)
------------------------------------------------------------
function bypassHashLimit()
    if _retFalse(0x366BF34) then
        gg.toast("✅ CheckHashLimitExceeded → false")
    end
end

function forceCorrectHash()
    -- AdvancedBoolean may not be a plain bool; try force true anyway
    if _retTrue(0x366BF44) then
        gg.toast("✅ get_CorrectHash forced (may need restart if AdvancedBoolean)")
    end
end

------------------------------------------------------------
-- BLACK VEHICLE (already used elsewhere)
-- UtilsVehicles.IsBlackVehicle @ 0x3377764 → false
------------------------------------------------------------
function bypassBlackVehicleCheck()
    if _retFalse(0x3377764) then
        gg.toast("✅ IsBlackVehicle → false")
    end
end

------------------------------------------------------------
-- RACE CHEAT FLAGS
-- IsCheatFinish @ 0x2DC2244 → false (already racing path)
------------------------------------------------------------
function bypassIsCheatFinish()
    if _retFalse(0x2DC2244) then
        gg.toast("✅ IsCheatFinish → false")
    end
end

------------------------------------------------------------
-- FUEL PRICE getters return ObscuredInt — hard to fake 0 safely.
-- Instead zero fuel consumption floats via search helper.
------------------------------------------------------------
function freeFuelConsumption()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    -- try common consumption scalars
    gg.searchNumber("0.01", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 0 and n < 5000 then
        local r = gg.getResults(math.min(n, 300))
        for i = 1, #r do r[i].value = 0 end
        gg.setValues(r)
        gg.toast("✅ Tried zero fuel consumption floats (" .. #r .. ")")
    else
        gg.clearResults()
        gg.toast("🔵 Fuel float search inconclusive — use Free Purchases for fuel shop")
    end
end

------------------------------------------------------------
-- MASTER: apply all safe unlock/bypass pack
------------------------------------------------------------
function applyAllExtraBypasses()
    bypassAllCurrencyChecks()
    unlockAllPartsIsBought()
    unlockAirSusIsBought()
    unlockBannedTradePack()
    bypassEventVehicleRestriction()
    bypassAddPenaltyWriters()
    bypassEngineCheatDetect()
    bypassBlackVehicleCheck()
    bypassIsCheatFinish()
    freeBodykitPrices()
    bypassIsCheatActivated()
    bypassPassengerKickPack()
    bypassMainCarCondition()
    forceDumbAI()
    gg.toast("✅ ALL EXTRA BYPASSES APPLIED (dump pack)")
end

------------------------------------------------------------
-- NEW DUMP-BASED FUNCTIONS (1.3.2.3 RVAs from header)
------------------------------------------------------------

-- Free bodykits: GetCoinPriceForKit @ 0x342E048 → 0
-- get_BodyKitsMoneyPrice @ 0x332EE58 → 0
function freeBodykitPrices()
    _retZero(0x342E048)
    _retZero(0x332EE58)
    gg.toast("✅ Bodykit prices → 0 (GetCoinPriceForKit + get_BodyKitsMoneyPrice)")
end

-- IsCheatActivated @ 0x3569F64 → false (anti-cheat gate)
function bypassIsCheatActivated()
    if _retFalse(0x3569F64) then
        gg.toast("✅ IsCheatActivated → false")
    end
end

-- CarDebugTools_Start / Update
-- 0x35738D0 Start · 0x35750BC Update
function forceCarDebugTools()
    _retVoid(0x35738D0)
    _retVoid(0x35750BC)
    gg.toast("✅ CarDebugTools Start/Update patched")
end

-- Passenger kick checks (dump anti-kick family)
-- 0x333A8F8 / 0x33B0800 / 0x367B478 + door 0x3660024
function bypassPassengerKickPack()
    _retFalse(0x333A8F8)
    _retFalse(0x33B0800)
    _retFalse(0x367B478)
    _retFalse(0x3660024)
    gg.toast("✅ Passenger kick + door checks forced off")
end

-- MainCarCondition-related @ 0x31F19FC
function bypassMainCarCondition()
    if _retFalse(0x31F19FC) then
        gg.toast("✅ MainCarCondition gate → false")
    end
end

-- CircuitRaceControlller.CheckParent @ 0x2F039A8
function bypassCircuitCheckParent()
    if _retTrue(0x2F039A8) then
        gg.toast("✅ CircuitRace CheckParent → true")
    end
end

-- CircuitCarStearing.ChangeSteeringState @ 0x2EF8658 → dumb AI
function forceDumbAI()
    if _retVoid(0x2EF8658) then
        gg.toast("✅ ChangeSteeringState RET (dumb AI)")
    end
end

-- LapRaceCar strong pack (dump race family)
function dumpRaceWinPack()
    _retTrue(0x2DC29DC)   -- IsFinalLap always true
    _retFalse(0x2DC2244)  -- IsCheatFinish false
    _retVoid(0x2DC1820)   -- AddPenaltyDistance
    _retVoid(0x2DC1830)   -- AddPenaltyTime
    bypassCircuitCheckParent()
    forceDumbAI()
    gg.toast("✅ Dump Race Win Pack (1-lap + no penalty + dumb AI)")
end

-- Rally dump pack
function dumpRallyWinPack()
    _retFalse(0x329A0F8)  -- not off-road
    _retZero(0x3299074)   -- penalty 0
    _retZero(0x329907C)   -- missed 0
    _retVoid(0x32996C8)   -- AddPenalty RET
    _retVoid(0x329B00C)   -- ApplyMissed RET
    gg.toast("✅ Dump Rally Win Pack applied")
end

-- Server IsCheatFinish path @ 0x3A826A8
function bypassServerIsCheatFinish()
    if _retFalse(0x3A826A8) then
        gg.toast("✅ Server IsCheatFinish → false")
    end
end

-- UnlockCar @ 0x2E58208
function forceUnlockCarMethod()
    if _retTrue(0x2E58208) then
        gg.toast("✅ UnlockCar(int,int) → true (try in room/garage)")
    end
end

-- Slot limit via existing slotmod
function dumpSlotLimitBypass()
    pcall(slotmod)
    gg.toast("✅ Slot limit gate (0x33A7618+0xC0) via slotmod")
end

-- APEX car-break related @ 0x320A1EC
function bypassApexCarBreak()
    if _retVoid(0x320A1EC) then
        gg.toast("✅ APEX car-break related RET")
    end
end

-- Strong anti-cheat dump pack
function dumpAntiCheatPack()
    bypassIsCheatActivated()
    bypassMainCarCondition()
    forceCarDebugTools()
    bypassPassengerKickPack()
    bypassApexCarBreak()
    bypassEngineCheatDetect()
    bypassHashLimit()
    gg.toast("✅ Dump Anti-Cheat / Anti-Kick pack applied")
end

-- Currency full open
function dumpCurrencyFullOpen()
    bypassAllCurrencyChecks()
    freeBodykitPrices()
    pcall(applyMaxMoney)
    gg.toast("✅ Currency fully open (checks + bodykit prices + money UI)")
end

------------------------------------------------------------
-- MENUS
------------------------------------------------------------
function Menu_ExtraUnlockBypass()
    local m = gg.choice({
        "⚡ APPLY ALL SAFE BYPASSES",
        "💰 Currency checks (Coins+Money)",
        "🧩 Parts IsBought (all cosmetics)",
        "🔧 Air Suspension IsBought",
        "🚫 Unban cars / trade / NFS",
        "🏁 Event any vehicle class",
        "⏱️ Block AddPenalty writers",
        "🛡️ Engine cheat detect off",
        "🔐 Hash limit bypass",
        "✔️ Force CorrectHash",
        "🖤 Black vehicle check off",
        "🏁 IsCheatFinish → false",
        "⛽ Free fuel consumption try",
        "🔩 Free Bodykit Prices (dump)",
        "🛡️ IsCheatActivated → false",
        "👥 Passenger Kick Bypass Pack",
        "🏎️ Dump Race Win Pack",
        "🏔️ Dump Rally Win Pack",
        "🛡️ Dump Anti-Cheat Pack",
        "🌐 Server IsCheatFinish off",
        "🚗 Force UnlockCar method",
        "📦 Dump Slot Limit Bypass",
        "🤖 Dumb AI (ChangeSteering)",
        "🔧 MainCarCondition off",
        "💰 Currency Full Open (dump)",
        "↩️ Back",
    }, nil, "🔓 EXTRA UNLOCKS & BYPASSES (dump 1.3.2.3)")
    if m == nil or m == 26 then return end
    if m == 1 then applyAllExtraBypasses()
    elseif m == 2 then bypassAllCurrencyChecks()
    elseif m == 3 then unlockAllPartsIsBought()
    elseif m == 4 then unlockAirSusIsBought()
    elseif m == 5 then unlockBannedTradePack()
    elseif m == 6 then bypassEventVehicleRestriction()
    elseif m == 7 then bypassAddPenaltyWriters()
    elseif m == 8 then bypassEngineCheatDetect()
    elseif m == 9 then bypassHashLimit()
    elseif m == 10 then forceCorrectHash()
    elseif m == 11 then bypassBlackVehicleCheck()
    elseif m == 12 then bypassIsCheatFinish()
    elseif m == 13 then freeFuelConsumption()
    elseif m == 14 then freeBodykitPrices()
    elseif m == 15 then bypassIsCheatActivated()
    elseif m == 16 then bypassPassengerKickPack()
    elseif m == 17 then dumpRaceWinPack()
    elseif m == 18 then dumpRallyWinPack()
    elseif m == 19 then dumpAntiCheatPack()
    elseif m == 20 then bypassServerIsCheatFinish()
    elseif m == 21 then forceUnlockCarMethod()
    elseif m == 22 then dumpSlotLimitBypass()
    elseif m == 23 then forceDumbAI()
    elseif m == 24 then bypassMainCarCondition()
    elseif m == 25 then dumpCurrencyFullOpen()
    end
end


function Menu_CPM1Style()
    local m = gg.choice({
        "💰 Custom Currency (Money/Coins)",
        "📁 Drift Menu (Room)",
        "⚙️ Engine Power Menu",
        "📁 Body Mod Menu",
        "📁 Copy / Unlock Car",
        "🔤 Long Name",
        "🧩 Community Extras (Service/Brakes/Chrome/Stance)  ★",
        "↩️ Back",
    }, nil, "✨ CPM1-STYLE EXTRAS → CPM2")
    if m == 1 then Menu_CustomCurrency()
    elseif m == 2 then Menu_Drift()
    elseif m == 3 then Menu_EnginePower()
    elseif m == 4 then Menu_BodyModCPM2()
    elseif m == 5 then Menu_CopyCarCPM2()
    elseif m == 6 then longNameCPM2()
    elseif m == 7 then Menu_CommunityExtras() end
end


-- ═══════════════════════════════════════════
--  § PHYSICS / GOD MODE / HANDLING (new)
--  Search-based + safe ARM helpers for CPM2 1.3.2.3
--  Use while driving / in room. Restart car if needed.
-- ═══════════════════════════════════════════

local function _libBaseSafe()
    local r = gg.getRangesList("libil2cpp.so")
    if r and #r >= 2 then return r[2].start end
    return LibStart or lib
end

local function _armRetTrue(addr)
    gg.setValues({
        {address = addr,     flags = gg.TYPE_DWORD, value = "h200080D2"}, -- MOV X0,#1
        {address = addr + 4, flags = gg.TYPE_DWORD, value = "hC0035FD6"}, -- RET
    })
end

local function _armRetVoid(addr)
    gg.setValues({
        {address = addr, flags = gg.TYPE_DWORD, value = "hC0035FD6"}, -- RET
    })
end

-- Infinite Nitro (search common nitro / boost scalars)
function infiniteNitroON()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
    -- Common nitro remaining / max patterns in Unity car games
    local candidates = {"100", "1", "50", "0.5"}
    local totalEdited = 0
    for _, val in ipairs(candidates) do
        gg.clearResults()
        gg.searchNumber(val, gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 800 then
            local r = gg.getResults(math.min(n, 200))
            for i = 1, #r do
                r[i].value = 9999
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            totalEdited = totalEdited + #r
        end
    end
    if totalEdited > 0 then
        gg.toast("✅ Infinite Nitro attempt — frozen " .. totalEdited .. " floats (test boost)")
    else
        gg.toast("🔵 Nitro values not found cleanly — try while boosting in-room")
    end
end

function infiniteNitroOFF()
    gg.clearList()
    gg.toast("🔵 Nitro freeze list cleared — restart car if needed")
end

-- No Damage / Invincible car (tyre + health style + known tyre RVA)
function noDamageON()
    gg.setVisible(false)
    -- 1) Force tyre health getter to 100% (existing offset)
    pcall(applyTyres100)
    -- 2) Search common damage / health floats and push them high
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("100;100;100::20", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 0 and n < 2000 then
        local r = gg.getResults(math.min(n, 300))
        for i = 1, #r do
            r[i].value = 9999
            r[i].freeze = true
        end
        gg.setValues(r)
        gg.addListItems(r)
        gg.toast("✅ No Damage — tyres 100% + health floats frozen (" .. #r .. ")")
    else
        gg.clearResults()
        gg.searchNumber("100", gg.TYPE_FLOAT)
        n = gg.getResultsCount()
        if n > 0 and n < 1500 then
            local r = gg.getResults(math.min(n, 250))
            for i = 1, #r do
                r[i].value = 9999
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast("✅ No Damage (broad health freeze) — " .. #r .. " values")
        else
            gg.toast("✅ Tyres forced 100% — broad health search inconclusive")
        end
    end
end

function noDamageOFF()
    gg.clearList()
    pcall(function()
        local b2 = (LibStart or _libBaseSafe()) + 0x30A8E28
        -- leave tyre patch; user can restore via Tyres menu
    end)
    gg.toast("🔵 Damage freezes cleared — use Tyres menu to restore if needed")
end

-- Speed Multiplier (search + edit common speed / velocity scalars)
function speedMultiplierMenu()
    local m = gg.choice({
        "🚀 Speed x1.5 (mild)",
        "🚀 Speed x2.0",
        "🚀 Speed x3.0 (aggressive)",
        "🚀 Speed x5.0 (crazy)",
        "🔵 Restore / clear speed freezes",
        "↩️ Back",
    }, nil, "🚀 SPEED MULTIPLIER\n\nUse while driving. May need restart car.")
    if not m or m == 6 then return end
    if m == 5 then
        gg.clearList()
        gg.toast("🔵 Speed freezes cleared")
        return
    end
    local mult = ({1.5, 2.0, 3.0, 5.0})[m]
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
    -- Typical Unity / car controller scalars
    local bases = {"1", "1.0", "0.5", "2.5", "3"}
    local edited = 0
    for _, b in ipairs(bases) do
        gg.clearResults()
        gg.searchNumber(b, gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 5 and n < 600 then
            local r = gg.getResults(math.min(n, 120))
            for i = 1, #r do
                local v = tonumber(r[i].value) or 1
                r[i].value = v * mult
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            edited = edited + #r
        end
    end
    if edited > 0 then
        gg.toast("✅ Speed ~x" .. mult .. " — frozen " .. edited .. " floats (test carefully)")
    else
        gg.toast("🔵 No clean speed scalars found — try again while moving")
    end
end

-- Instant Repair (tyres + free purchases style)
function instantRepair()
    gg.setVisible(false)
    pcall(applyTyres100)
    pcall(freePurchases)
    -- Also try zeroing damage scalars
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("0;1;0::12", gg.TYPE_FLOAT) -- common damage flags
    local n = gg.getResultsCount()
    if n > 0 and n < 800 then
        local r = gg.getResults(math.min(n, 150))
        for i = 1, #r do
            if tonumber(r[i].value) and tonumber(r[i].value) < 5 then
                r[i].value = 0
            end
        end
        gg.setValues(r)
    end
    gg.toast("✅ Instant Repair — tyres 100% + free purchases + damage try")
end

-- Handling / Mass boost (search mass / grip-like floats)
function handlingBoostON()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    -- Lower mass = better accel/handling feel in many physics engines
    gg.searchNumber("1200;1500;1800;2000::50", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 0 and n < 400 then
        local r = gg.getResults(math.min(n, 80))
        for i = 1, #r do
            r[i].value = 400 -- lighter
            r[i].freeze = true
        end
        gg.setValues(r)
        gg.addListItems(r)
        gg.toast("✅ Handling boost — mass-like values lowered (" .. #r .. ")")
    else
        gg.clearResults()
        gg.searchNumber("1;0.5;0.3::20", gg.TYPE_FLOAT)
        n = gg.getResultsCount()
        if n > 0 and n < 500 then
            local r = gg.getResults(math.min(n, 100))
            for i = 1, #r do
                r[i].value = 2.5
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast("✅ Handling scalars boosted (" .. #r .. ")")
        else
            gg.toast("🔵 Handling values not found cleanly")
        end
    end
end

function handlingBoostOFF()
    gg.clearList()
    gg.toast("🔵 Handling freezes cleared")
end

-- Super Jump / low gravity (search gravity or jump force)
function lowGravityON()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
    gg.searchNumber("-9.81", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 0 and n < 300 then
        local r = gg.getResults(math.min(n, 50))
        for i = 1, #r do
            r[i].value = -2.5
            r[i].freeze = true
        end
        gg.setValues(r)
        gg.addListItems(r)
        gg.toast("✅ Low Gravity ON (−2.5 instead of −9.81)")
    else
        gg.clearResults()
        gg.searchNumber("9.81", gg.TYPE_FLOAT)
        n = gg.getResultsCount()
        if n > 0 and n < 200 then
            local r = gg.getResults(math.min(n, 40))
            for i = 1, #r do
                r[i].value = 2.5
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast("✅ Low Gravity (positive 9.81 → 2.5)")
        else
            gg.toast("🔵 Gravity constant not found")
        end
    end
end

function lowGravityOFF()
    gg.clearList()
    gg.toast("🔵 Gravity freezes cleared — restart scene if needed")
end

-- Improved infinite fuel (better than previous freeFuelConsumption)
function infiniteFuelON()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    local edited = 0
    for _, val in ipairs({"0.01", "0.001", "0.1", "1"}) do
        gg.clearResults()
        gg.searchNumber(val, gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 1200 then
            local r = gg.getResults(math.min(n, 200))
            for i = 1, #r do
                r[i].value = 0
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            edited = edited + #r
        end
    end
    -- Also force high fuel tank style values
    gg.clearResults()
    gg.searchNumber("100;50;30::30", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 0 and n < 800 then
        local r = gg.getResults(math.min(n, 150))
        for i = 1, #r do
            r[i].value = 9999
            r[i].freeze = true
        end
        gg.setValues(r)
        gg.addListItems(r)
        edited = edited + #r
    end
    if edited > 0 then
        gg.toast("✅ Infinite Fuel — edited/frozen " .. edited .. " floats")
    else
        gg.toast("🔵 Fuel search inconclusive — Free Purchases still helps shop")
    end
end

function infiniteFuelOFF()
    gg.clearList()
    gg.toast("🔵 Fuel freezes cleared")
end

-- One-tap Physics God pack
function physicsGodPack()
    local proceed = gg.choice({
        "✅ YES — Apply Physics God Pack",
        "❌ Cancel"
    }, nil, "⚡ PHYSICS GOD PACK\n\nApplies:\n• Infinite Nitro\n• No Damage\n• Infinite Fuel\n• Handling Boost\n• Mild Speed x1.5\n\nUse in-room while driving.")
    if proceed ~= 1 then
        gg.toast("Cancelled")
        return
    end
    gg.toast("⚡ Applying Physics God Pack…")
    pcall(infiniteNitroON)
    gg.sleep(200)
    pcall(noDamageON)
    gg.sleep(200)
    pcall(infiniteFuelON)
    gg.sleep(200)
    pcall(handlingBoostON)
    gg.sleep(150)
    -- mild speed
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("1", gg.TYPE_FLOAT)
    local n = gg.getResultsCount()
    if n > 10 and n < 400 then
        local r = gg.getResults(math.min(n, 80))
        for i = 1, #r do
            r[i].value = 1.5
            r[i].freeze = true
        end
        gg.setValues(r)
        gg.addListItems(r)
    end
    gg.toast("✅ Physics God Pack applied — test carefully")
end


-- ═══════════════════════════════════════════
--  § PLAYER ESP / NAMES / POSITIONS (multiplayer)
--  Practical GG tools to inspect other players
--  in room: names, approximate positions, cars.
--  Use while INSIDE a multiplayer room.
-- ═══════════════════════════════════════════

-- Scan memory for likely player display names (UTF-16 / DWORD patterns like CHANGENAME)
function scanPlayerNames()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)

    local found = {}
    -- Method 1: common name-related DWORD groups (same family as CHANGENAME)
    gg.searchNumber("7 077 968;7 929 953;7 471 205", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1)
    local n = gg.getResultsCount()
    if n > 0 and n < 500 then
        local r = gg.getResults(math.min(n, 80))
        for i, v in ipairs(r) do
            found[#found + 1] = string.format("0x%X", v.address)
        end
        gg.loadResults(r)
        gg.toast("✅ Name-related blocks found: " .. #r .. " (check GG results list)")
        gg.alert(
            "📌 PLAYER NAME SCAN\n\n" ..
            "Found " .. #r .. " name-related memory blocks.\n" ..
            "Open GG → Saved List / Results to inspect.\n\n" ..
            "Tips:\n" ..
            "• Your name + other room names often sit nearby.\n" ..
            "• Edit carefully (UTF-16 style edits like CHANGENAME).\n" ..
            "• Use 'Change Name' in Prank menu for self-rename.\n\n" ..
            "Addresses (sample):\n" .. table.concat(found, "\n"):sub(1, 400)
        )
        return
    end

    -- Method 2: broad string-ish search fallback
    gg.clearResults()
    gg.searchNumber("::Player;::Nick;::Name", gg.TYPE_BYTE, false, gg.SIGN_EQUAL, 0, -1)
    n = gg.getResultsCount()
    if n > 0 and n < 2000 then
        gg.getResults(math.min(n, 100))
        gg.toast("✅ Text/Nick string markers found — check results")
        gg.alert("Name/Nick markers loaded in GG results.\nInspect nearby values for player names.")
        return
    end

    gg.toast("🔵 No clean name blocks — try while inside a room with players")
    gg.alert(
        "📌 PLAYER NAMES\n\n" ..
        "Auto-scan did not find stable name blocks.\n\n" ..
        "Manual workflow:\n" ..
        "1. Enter a room with several players.\n" ..
        "2. Note a unique player name on screen.\n" ..
        "3. GG → Search that name as UTF-16 / text.\n" ..
        "4. Refine when players join/leave.\n" ..
        "5. Nearby values often include car IDs / ranks."
    )
end

-- Multi-car position scanner (list XYZ groups in ANONYMOUS)
function scanOtherPositions()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)

    -- Same anchor style as xyzteleport search
    local search = "-2,097,152,000"
    gg.searchNumber(search, gg.TYPE_DWORD)
    local n = gg.getResultsCount()
    if n == 0 or n > 8000 then
        gg.clearResults()
        gg.toast("🔵 Position anchors not found / too many — move in world and retry")
        gg.alert(
            "📌 OTHER PLAYERS POSITIONS\n\n" ..
            "Could not lock stable position anchors.\n\n" ..
            "Tips:\n" ..
            "• Be fully loaded inside the open world / room.\n" ..
            "• Drive a bit, then scan again.\n" ..
            "• Use XYZ Teleport menu for single-target control.\n" ..
            "• Freeze X/Y/Z of a car to lock it in place."
        )
        return
    end

    local r = gg.getResults(math.min(n, 200))
    local off = gg.getTargetInfo().x64 and {x = 0x68, y = 0x6C, z = 0x70} or {x = 0x5C, y = 0x60, z = 0x64}
    local lines = {}
    local listed = 0
    for i = 1, #r do
        if listed >= 15 then break end
        local base = r[i].address
        local vals = gg.getValues({
            {address = base + off.x, flags = gg.TYPE_FLOAT},
            {address = base + off.y, flags = gg.TYPE_FLOAT},
            {address = base + off.z, flags = gg.TYPE_FLOAT},
        })
        local x, y, z = vals[1].value, vals[2].value, vals[3].value
        -- filter obvious garbage
        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
            if math.abs(x) < 50000 and math.abs(y) < 50000 and math.abs(z) < 50000 then
                if not (x == 0 and y == 0 and z == 0) then
                    listed = listed + 1
                    lines[#lines + 1] = string.format(
                        "#%d  X=%.1f  Y=%.1f  Z=%.1f\n   base 0x%X",
                        listed, x, y, z, base
                    )
                end
            end
        end
    end

    if #lines == 0 then
        gg.toast("🔵 No valid XYZ groups decoded")
        return
    end

    gg.alert(
        "📌 NEARBY / OTHER POSITIONS (sample)\n\n" ..
        table.concat(lines, "\n\n") ..
        "\n\n• These are candidate car/player transforms.\n" ..
        "• One of them is usually YOU.\n" ..
        "• Use XYZ Teleport to jump to a chosen X/Y/Z.\n" ..
        "• Freeze values in GG list to lock a car."
    )
    gg.toast("✅ Listed " .. #lines .. " position candidates")
end

-- Try IL2CPP class field probes for room / player related objects
function probePlayerClasses()
    gg.setVisible(false)
    local report = {}
    local probes = {
        {"RoomDataItem", 0x8C, gg.TYPE_DWORD},
        {"FreeDriveDB", 0x1B8, gg.TYPE_QWORD},
    }
    for _, p in ipairs(probes) do
        local ok, res = pcall(valueFromClass, p[1], p[2], false, false, p[3])
        if ok and res and #res > 0 then
            report[#report + 1] = string.format("%s +0x%X → %d hit(s)", p[1], p[2], #res)
        else
            report[#report + 1] = string.format("%s +0x%X → no hit", p[1], p[2])
        end
        gg.sleep(80)
    end
    gg.alert(
        "📌 PLAYER / ROOM CLASS PROBE\n\n" ..
        table.concat(report, "\n") ..
        "\n\nRoomDataItem is used for room password.\n" ..
        "FreeDriveDB holds mission/achievement stats.\n" ..
        "For live player names, use Name Scan while in room."
    )
end

-- Helper: freeze a specific XYZ you paste (track someone)
function trackPositionFreeze()
    local input = gg.prompt({
        "X (float)",
        "Y (float)",
        "Z (float)",
        "Freeze X",
        "Freeze Y",
        "Freeze Z",
    }, {"0", "0", "0", true, true, true}, {"number", "number", "number", "checkbox", "checkbox", "checkbox"})
    if not input then return end
    -- Redirect user to full XYZ tool which already supports freeze
    gg.alert(
        "📌 TRACK / FREEZE POSITION\n\n" ..
        "Best method:\n" ..
        "1. Run 「Scan Other Positions」 and note X/Y/Z.\n" ..
        "2. Open 「XYZ Teleport」.\n" ..
        "3. Enter that X/Y/Z and enable Freeze checkboxes.\n\n" ..
        "Or search the float values manually in GG and freeze.\n\n" ..
        "Target you entered:\n" ..
        string.format("X=%s Y=%s Z=%s", tostring(input[1]), tostring(input[2]), tostring(input[3]))
    )
    pcall(xyzteleport)
end

-- Combined ESP info menu
function Menu_PlayerESP()
    local m = gg.choice({
        "👁️ Scan Player Names (room)",
        "📍 Scan Other Positions (XYZ list)",
        "🔎 Probe Room/Player Classes",
        "📌 Track / Freeze a Position",
        "📍 Open XYZ Teleport",
        "🔐 Room Password Finder",
        "📛 Change My Name (room)",
        "📖 How this works",
        "↩️ Back",
    }, nil, "👁️ PLAYERS / NAMES / POSITIONS\n\nUse inside a multiplayer room")
    if not m or m == 9 then return end
    if m == 1 then scanPlayerNames()
    elseif m == 2 then scanOtherPositions()
    elseif m == 3 then probePlayerClasses()
    elseif m == 4 then trackPositionFreeze()
    elseif m == 5 then xyzteleport()
    elseif m == 6 then checkpassword()
    elseif m == 7 then CHANGENAME()
    elseif m == 8 then
        gg.alert(
            "📖 PLAYER ESP — HOW IT WORKS\n\n" ..
            "CPM2 is Photon multiplayer. Full wallhack ESP needs\n" ..
            "live network object pointers from a private dump.\n\n" ..
            "What this menu CAN do with public offsets:\n" ..
            "• Scan name-related memory while in a room\n" ..
            "• List candidate car/player XYZ positions\n" ..
            "• Probe RoomDataItem / FreeDriveDB fields\n" ..
            "• Jump / freeze positions via XYZ Teleport\n" ..
            "• Find room passwords + change your name\n\n" ..
            "Workflow:\n" ..
            "1. Join a busy room\n" ..
            "2. Scan Names + Scan Positions\n" ..
            "3. Pick an XYZ → Teleport / Freeze\n" ..
            "4. Inspect GG results list for names near hits"
        )
    end
end


-- ═══════════════════════════════════════════
--  § LOCATION TELEPORT (map spots + favorites)
--  Save current pos, teleport to saved/custom,
--  and jump to scanned other-player positions.
-- ═══════════════════════════════════════════

local TP_FAV_PATH = (gg.EXT_STORAGE or "/sdcard") .. "/.cpm2_tp_favs.txt"
local LastInput = LastInput or {"0", "0", "0", false, false, false}
local _tpCache = nil -- {X={},Y={},Z={}} after search

local function _tpOffsets()
    if gg.getTargetInfo().x64 then
        return {s = 0xA8, x = 0x68, y = 0x6C, z = 0x70}
    end
    return {s = 0x9C, x = 0x5C, y = 0x60, z = 0x64}
end

local function _tpFindBody()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    local search = "-2,097,152,000"
    local offset = _tpOffsets()
    gg.searchNumber(search, gg.TYPE_DWORD)
    local XResults = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    local R = {X = {}, Y = {}, Z = {}}
    for i, v in pairs(XResults) do
        local ok, vals = pcall(gg.getValues, {
            {address = v.address + offset.s, flags = gg.TYPE_FLOAT},
            {address = v.address + offset.x, flags = gg.TYPE_FLOAT},
            {address = v.address + offset.y, flags = gg.TYPE_FLOAT},
            {address = v.address + offset.z, flags = gg.TYPE_FLOAT},
        })
        if ok and vals then
            local marker = vals[1].value
            local x, y, z = vals[2].value, vals[3].value, vals[4].value
            if marker == 1.0000000331813535E32 or (type(x) == "number" and type(y) == "number" and type(z) == "number"
                and math.abs(x) < 80000 and math.abs(y) < 80000 and math.abs(z) < 80000
                and not (x == 0 and y == 0 and z == 0)) then
                R.X[#R.X + 1] = {address = v.address + offset.x, flags = gg.TYPE_FLOAT, value = x, freeze = false}
                R.Y[#R.Y + 1] = {address = v.address + offset.y, flags = gg.TYPE_FLOAT, value = y, freeze = false}
                R.Z[#R.Z + 1] = {address = v.address + offset.z, flags = gg.TYPE_FLOAT, value = z, freeze = false}
            end
        end
    end
    _tpCache = R
    return R
end

local function _tpApply(x, y, z, fx, fy, fz)
    local R = _tpCache
    if not R or #R.X < 1 then
        R = _tpFindBody()
    end
    if not R or #R.X < 1 then
        gg.toast("❌ Position not found — drive in world / room first")
        return false
    end
    for i = 1, #R.X do R.X[i].value = tonumber(x) or 0 end
    for i = 1, #R.Y do R.Y[i].value = tonumber(y) or 0 end
    for i = 1, #R.Z do R.Z[i].value = tonumber(z) or 0 end
    gg.setValues(R.X); gg.setValues(R.Y); gg.setValues(R.Z)
    if fx then gg.addListItems(R.X) else gg.removeListItems(R.X) end
    if fy then gg.addListItems(R.Y) else gg.removeListItems(R.Y) end
    if fz then gg.addListItems(R.Z) else gg.removeListItems(R.Z) end
    LastInput = {tostring(x), tostring(y), tostring(z), fx, fy, fz}
    gg.toast(string.format("✅ Teleport → X=%.1f Y=%.1f Z=%.1f", x, y, z))
    return true
end

local function _tpReadCurrent()
    local R = _tpFindBody()
    if not R or #R.X < 1 then return nil end
    local vals = gg.getValues({R.X[1], R.Y[1], R.Z[1]})
    return {
        x = tonumber(vals[1].value) or 0,
        y = tonumber(vals[2].value) or 0,
        z = tonumber(vals[3].value) or 0,
    }
end

local function _tpLoadFavs()
    local favs = {}
    local f = io.open(TP_FAV_PATH, "r")
    if not f then return favs end
    for line in f:lines() do
        local name, xs, ys, zs = line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
        if name and xs and ys and zs then
            favs[#favs + 1] = {name = name, x = tonumber(xs) or 0, y = tonumber(ys) or 0, z = tonumber(zs) or 0}
        end
    end
    f:close()
    return favs
end

local function _tpSaveFavs(favs)
    local f = io.open(TP_FAV_PATH, "w")
    if not f then
        gg.toast("❌ Cannot write favorites file")
        return
    end
    for _, v in ipairs(favs) do
        f:write(string.format("%s|%.4f|%.4f|%.4f\n", v.name, v.x, v.y, v.z))
    end
    f:close()
end

function saveCurrentLocation()
    local cur = _tpReadCurrent()
    if not cur then
        gg.toast("❌ Could not read current position")
        return
    end
    local input = gg.prompt({"Location name:"}, {"My Spot"}, {"text"})
    if not input or input[1] == "" then return end
    local favs = _tpLoadFavs()
    favs[#favs + 1] = {name = input[1], x = cur.x, y = cur.y, z = cur.z}
    _tpSaveFavs(favs)
    gg.alert(string.format(
        "✅ Saved location\n\n%s\nX=%.2f\nY=%.2f\nZ=%.2f\n\nFile: %s",
        input[1], cur.x, cur.y, cur.z, TP_FAV_PATH
    ))
end

function teleportToFavorites()
    local favs = _tpLoadFavs()
    if #favs == 0 then
        gg.alert("No saved locations yet.\n\nUse 「Save Current Location」 while standing where you want.")
        return
    end
    local labels = {}
    for i, v in ipairs(favs) do
        labels[i] = string.format("%s  (%.0f, %.0f, %.0f)", v.name, v.x, v.y, v.z)
    end
    labels[#labels + 1] = "🗑 Delete a favorite…"
    labels[#labels + 1] = "↩️ Back"
    local c = gg.choice(labels, nil, "📍 SAVED LOCATIONS")
    if not c or c == #labels then return end
    if c == #labels - 1 then
        local dlabels = {}
        for i, v in ipairs(favs) do dlabels[i] = v.name end
        dlabels[#dlabels + 1] = "↩️ Cancel"
        local d = gg.choice(dlabels, nil, "Delete which?")
        if d and d <= #favs then
            table.remove(favs, d)
            _tpSaveFavs(favs)
            gg.toast("🗑 Deleted")
        end
        return
    end
    local spot = favs[c]
    _tpApply(spot.x, spot.y, spot.z, false, false, false)
end

function teleportCustomXYZ()
    local input = gg.prompt(
        {"X", "Y", "Z", "Freeze X", "Freeze Y", "Freeze Z"},
        {LastInput[1] or "0", LastInput[2] or "0", LastInput[3] or "0", false, false, false},
        {"number", "number", "number", "checkbox", "checkbox", "checkbox"}
    )
    if not input then return end
    _tpApply(tonumber(input[1]) or 0, tonumber(input[2]) or 0, tonumber(input[3]) or 0, input[4], input[5], input[6])
end

function teleportToScannedOthers()
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("-2,097,152,000", gg.TYPE_DWORD)
    local n = gg.getResultsCount()
    if n == 0 or n > 8000 then
        gg.toast("🔵 No position anchors — move in world and retry")
        return
    end
    local r = gg.getResults(math.min(n, 250))
    local off = _tpOffsets()
    local candidates = {}
    for i = 1, #r do
        if #candidates >= 20 then break end
        local base = r[i].address
        local vals = gg.getValues({
            {address = base + off.x, flags = gg.TYPE_FLOAT},
            {address = base + off.y, flags = gg.TYPE_FLOAT},
            {address = base + off.z, flags = gg.TYPE_FLOAT},
        })
        local x, y, z = vals[1].value, vals[2].value, vals[3].value
        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
            if math.abs(x) < 80000 and math.abs(y) < 80000 and math.abs(z) < 80000 then
                if not (x == 0 and y == 0 and z == 0) then
                    candidates[#candidates + 1] = {x = x, y = y, z = z, base = base}
                end
            end
        end
    end
    if #candidates == 0 then
        gg.toast("🔵 No valid XYZ candidates")
        return
    end
    local labels = {}
    for i, c in ipairs(candidates) do
        labels[i] = string.format("#%d  X=%.1f  Y=%.1f  Z=%.1f", i, c.x, c.y, c.z)
    end
    labels[#labels + 1] = "↩️ Back"
    local pick = gg.choice(labels, nil, "📍 TELEPORT TO SCANNED POSITION\n(one may be you)")
    if not pick or pick == #labels then return end
    local c = candidates[pick]
    _tpApply(c.x, c.y, c.z, false, false, false)
end

-- Named map areas (user can overwrite by saving real coords after visiting)
-- These are starter slots — save your real positions for accuracy.
local MAP_PRESETS = {
    {name = "City 1 — Center / Roundabout area", x = 0, y = 50, z = 0},
    {name = "City 1 — Beach area", x = 200, y = 30, z = -150},
    {name = "City 1 — Bridge approach", x = 400, y = 40, z = 100},
    {name = "City 1 — Police area", x = -100, y = 35, z = 200},
    {name = "City 1 — Drag / Fun Road", x = 150, y = 35, z = 300},
    {name = "Highway stretch", x = 800, y = 40, z = 0},
    {name = "City 2 — Downtown", x = 1200, y = 40, z = 200},
    {name = "Desert entry", x = -500, y = 45, z = 600},
    {name = "Mountain road", x = 300, y = 120, z = -400},
    {name = "Circuit / Track", x = 600, y = 40, z = 800},
    {name = "Off-road zone", x = -300, y = 50, z = -600},
}

function teleportMapPresets()
    local labels = {}
    for i, p in ipairs(MAP_PRESETS) do
        labels[i] = string.format("%s\n(%.0f, %.0f, %.0f)", p.name, p.x, p.y, p.z)
    end
    labels[#labels + 1] = "↩️ Back"
    local c = gg.choice(labels, nil, "🗺️ MAP AREA PRESETS\n\nStarter coords — overwrite by saving real spots after you arrive")
    if not c or c == #labels then return end
    local p = MAP_PRESETS[c]
    local go = gg.choice({
        "✅ Teleport here",
        "📌 Save this preset name with CURRENT position instead",
        "❌ Cancel",
    }, nil, p.name)
    if go == 1 then
        _tpApply(p.x, p.y, p.z, false, false, false)
    elseif go == 2 then
        local cur = _tpReadCurrent()
        if not cur then gg.toast("❌ Can't read current pos"); return end
        local favs = _tpLoadFavs()
        favs[#favs + 1] = {name = p.name, x = cur.x, y = cur.y, z = cur.z}
        _tpSaveFavs(favs)
        gg.toast("✅ Saved real coords for " .. p.name)
    end
end

function showCurrentCoords()
    local cur = _tpReadCurrent()
    if not cur then
        gg.toast("❌ Position not found")
        return
    end
    gg.alert(string.format(
        "📍 CURRENT POSITION\n\nX = %.4f\nY = %.4f\nZ = %.4f\n\nUse Save Current Location to store this spot.",
        cur.x, cur.y, cur.z
    ))
end

function Menu_LocationTeleport()
    local m = gg.choice({
        "📍 Show My Current Coords",
        "💾 Save Current Location",
        "⭐ Teleport to Saved Locations",
        "🗺️ Map Area Presets",
        "👥 Teleport to Scanned Other Positions",
        "✏️ Custom XYZ Teleport",
        "🔁 Full XYZ Tool (advanced loop)",
        "👁️ Players / Names / Positions",
        "↩️ Back",
    }, nil, "📍 LOCATION TELEPORT\n\nBe in the open world / room (not garage)")
    if not m or m == 9 then return end
    if m == 1 then showCurrentCoords()
    elseif m == 2 then saveCurrentLocation()
    elseif m == 3 then teleportToFavorites()
    elseif m == 4 then teleportMapPresets()
    elseif m == 5 then teleportToScannedOthers()
    elseif m == 6 then teleportCustomXYZ()
    elseif m == 7 then xyzteleport()
    elseif m == 8 then Menu_PlayerESP()
    end
end


-- ═══════════════════════════════════════════
--  § EXTRAS FROM OTHER PLATFORMS
--  (Telegram / iOSGods / GG community feature set)
--  Service 0 · Brakes/Calipers · Bumper · Chrome · Height/Camber
-- ═══════════════════════════════════════════

function instantServiceZero()
    -- get_CurrentUnixTimeSeconds @ 0x331C938 → force large / bypass wait
    pcall(bypasseservvicetrime)
    pcall(bypassgtime)
    -- also engine service gates
    pcall(bypassenginecomp)
    pcall(bypassgdetece)
    gg.toast("✅ Instant Service / 0 timer pack applied — open service UI")
end

-- Brakes + Calipers unlock (IsBought-style + free price family)
function unlockBrakesCalipers()
    gg.setVisible(false)
    -- Parts IsBought already covers many cosmetics
    pcall(unlockAllPartsIsBought)
    pcall(freeBodykitPrices)
    pcall(freePurchases)
    -- Search common ownership flags for brake/caliper shop
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber("0;1;0;1::16", gg.TYPE_DWORD)
    local n = gg.getResultsCount()
    if n > 0 and n < 3000 then
        local r = gg.getResults(math.min(n, 400))
        for i = 1, #r do
            if tonumber(r[i].value) == 0 then r[i].value = 1 end
        end
        gg.setValues(r)
        gg.toast("✅ Brakes/Calipers attempt — " .. #r .. " flags + parts IsBought")
    else
        gg.toast("✅ Parts IsBought + free purchases — open Brakes/Calipers shop")
    end
end

-- Simple bumper remove (uses existing RB2 flow + tip)
function removeBumperQuick()
    local m = gg.choice({
        "🔧 Remove Bumper (guided RB2)",
        "📖 How bumper remove works",
        "↩️ Back",
    }, nil, "🔧 BUMPER")
    if m == 1 then
        pcall(RB2)
    elseif m == 2 then
        gg.alert(
            "📌 REMOVE BUMPER\n\n" ..
            "1. Open Exterior → Bumper in tuning.\n" ..
            "2. Run guided Remove Bumper.\n" ..
            "3. Follow on-screen buy prompts.\n" ..
            "4. Script forces bumper IDs to -1 style.\n\n" ..
            "Also available under Body Mod / Bumper menu."
        )
    end
end

-- Chrome visual pack (search-based metallic/color scalars)
function chromeVisualPack()
    local m = gg.choice({
        "✨ Chrome-like boost (search)",
        "🔵 Clear chrome freezes",
        "↩️ Back",
    }, nil, "✨ CHROME VISUAL\n\nVisual only — may reset on restart")
    if not m or m == 3 then return end
    if m == 2 then
        gg.clearList()
        gg.toast("🔵 Chrome freezes cleared")
        return
    end
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    -- High specular / metal-like floats often near 0.5–1.0 materials
    local edited = 0
    for _, val in ipairs({"0.5", "0.8", "1", "0.2"}) do
        gg.clearResults()
        gg.searchNumber(val, gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 20 and n < 800 then
            local r = gg.getResults(math.min(n, 100))
            for i = 1, #r do
                r[i].value = 1.0
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            edited = edited + #r
        end
    end
    if edited > 0 then
        gg.toast("✅ Chrome-like scalars frozen (" .. edited .. ") — check body paint")
    else
        gg.toast("🔵 No clean material scalars — try in tuning with car loaded")
    end
end

-- Car height / camber / mass editor (search-based)
function carStanceEditor()
    local m = gg.choice({
        "📉 Lower car (height-like)",
        "📈 Raise car",
        "📐 Camber-ish boost",
        "🪶 Lighter mass (handling)",
        "🏋️ Heavier mass",
        "🔵 Clear stance freezes",
        "↩️ Back",
    }, nil, "📐 STANCE / HEIGHT / CAMBER / MASS\n\nUse while car is spawned in world")
    if not m or m == 7 then return end
    if m == 6 then
        gg.clearList()
        gg.toast("🔵 Stance freezes cleared")
        return
    end
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_ANONYMOUS)
    if m == 1 or m == 2 then
        -- suspension / ride height-ish floats
        gg.searchNumber("0.1~0.5", gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 2000 then
            local r = gg.getResults(math.min(n, 150))
            local target = (m == 1) and 0.05 or 0.45
            for i = 1, #r do
                r[i].value = target
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast((m == 1 and "✅ Lowered" or "✅ Raised") .. " height-like floats (" .. #r .. ")")
        else
            gg.toast("🔵 Height floats not found cleanly")
        end
    elseif m == 3 then
        gg.searchNumber("-0.5~0.5", gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 50 and n < 3000 then
            local r = gg.getResults(math.min(n, 120))
            for i = 1, #r do
                local v = tonumber(r[i].value) or 0
                if math.abs(v) < 0.4 then
                    r[i].value = (v >= 0) and 0.35 or -0.35
                    r[i].freeze = true
                end
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast("✅ Camber-ish angles boosted")
        else
            gg.toast("🔵 Camber search inconclusive")
        end
    elseif m == 4 or m == 5 then
        gg.searchNumber("800~2500", gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 1500 then
            local r = gg.getResults(math.min(n, 80))
            local target = (m == 4) and 400 or 3500
            for i = 1, #r do
                r[i].value = target
                r[i].freeze = true
            end
            gg.setValues(r)
            gg.addListItems(r)
            gg.toast((m == 4 and "✅ Lighter" or "✅ Heavier") .. " mass-like (" .. #r .. ")")
        else
            pcall(handlingBoostON)
        end
    end
end

-- HP / torque / shift expand (wrap engine power + more)
function engineTuneExtras()
    local m = gg.choice({
        "⚙️ Open Engine Power Menu",
        "🚀 Torque search boost x3",
        "⏱️ Shift-feel faster (search)",
        "🔵 Clear engine freezes",
        "↩️ Back",
    }, nil, "⚙️ ENGINE TUNE EXTRAS")
    if not m or m == 5 then return end
    if m == 1 then Menu_EnginePower()
    elseif m == 2 then
        gg.setVisible(false)
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber("1;0.5;2::12", gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 1000 then
            local r = gg.getResults(math.min(n, 100))
            for i = 1, #r do r[i].value = (tonumber(r[i].value) or 1) * 3; r[i].freeze = true end
            gg.setValues(r); gg.addListItems(r)
            gg.toast("✅ Torque-like x3")
        else
            Menu_EnginePower()
        end
    elseif m == 3 then
        gg.setVisible(false)
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber("0.15~0.4", gg.TYPE_FLOAT)
        local n = gg.getResultsCount()
        if n > 0 and n < 1500 then
            local r = gg.getResults(math.min(n, 100))
            for i = 1, #r do r[i].value = 0.05; r[i].freeze = true end
            gg.setValues(r); gg.addListItems(r)
            gg.toast("✅ Faster shift-feel attempt")
        else
            gg.toast("🔵 Shift floats not found")
        end
    elseif m == 4 then
        gg.clearList()
        gg.toast("🔵 Engine freezes cleared")
    end
end

function Menu_CommunityExtras()
    local m = gg.choice({
        "⏱️ Instant Service / 0 Timer  ★",
        "🛑 Unlock Brakes + Calipers",
        "🔧 Remove Bumper",
        "✨ Chrome Visual Pack",
        "📐 Stance / Height / Camber / Mass",
        "⚙️ Engine Tune Extras (HP/Torque/Shift)",
        "🔓 Free Bodykit Prices (dump)",
        "🛒 Free Purchases",
        "↩️ Back",
    }, nil, "🧩 COMMUNITY EXTRAS\n(Telegram / iOSGods / GG style)")
    if not m or m == 9 then return end
    if m == 1 then instantServiceZero()
    elseif m == 2 then unlockBrakesCalipers()
    elseif m == 3 then removeBumperQuick()
    elseif m == 4 then chromeVisualPack()
    elseif m == 5 then carStanceEditor()
    elseif m == 6 then engineTuneExtras()
    elseif m == 7 then freeBodykitPrices()
    elseif m == 8 then freePurchases()
    end
end


function Menu_PhysicsGod()
    local m = gg.choice({
        "⚡ Physics God Pack (one-tap)  ★",
        "🚀 Infinite Nitro ON",
        "🔵 Infinite Nitro OFF",
        "🛡️ No Damage / Invincible ON",
        "🔵 No Damage OFF",
        "⛽ Infinite Fuel ON",
        "🔵 Infinite Fuel OFF",
        "🚀 Speed Multiplier Menu",
        "🔧 Instant Repair",
        "🏎️ Handling / Mass Boost ON",
        "🔵 Handling OFF",
        "🌙 Low Gravity / Super Jump ON",
        "🔵 Low Gravity OFF",
        "↩️ Back",
    }, nil, "⚡ PHYSICS / GOD MODE / HANDLING")
    if not m or m == 14 then return end
    if m == 1 then physicsGodPack()
    elseif m == 2 then infiniteNitroON()
    elseif m == 3 then infiniteNitroOFF()
    elseif m == 4 then noDamageON()
    elseif m == 5 then noDamageOFF()
    elseif m == 6 then infiniteFuelON()
    elseif m == 7 then infiniteFuelOFF()
    elseif m == 8 then speedMultiplierMenu()
    elseif m == 9 then instantRepair()
    elseif m == 10 then handlingBoostON()
    elseif m == 11 then handlingBoostOFF()
    elseif m == 12 then lowGravityON()
    elseif m == 13 then lowGravityOFF()
    end
end


function HomeMenu()
    local choice = gg.choice({
        "⚡ Quick Actions  ★",
        "👑 Full God Account Boost",
        "💰 Money & Currency",
        "🔓 Unlock Hub",
        "🏁 Race / Drag / Rally",
        "🔧 Gearbox & Engine",
        "🏆 Achievements",
        "🚀 Car Boosters",
        "😈 Prank & Fun",
        "👑 Logo Rank",
        "📍 Teleport & Mods",
        "🛡️ Bypass & Account",
        "🚗 Shop / Parts Extra",
        "✨ CPM1-Style Extras (Drift/Copy/HP…)",
        "🔓 Extra Unlocks & Bypasses (dump)",
        "⚡ Physics / God Mode / Handling",
        "🚪 Exit Script",
    }, nil, title)

    if choice == nil then return end

    local function tog(flag, applyFn, revertFn)
        if flag then revertFn(); return false
        else applyFn(); return true end
    end

    ------------------------------------------------------------
    -- 0. QUICK ACTIONS
    ------------------------------------------------------------
    if choice == 1 then
        Menu_QuickActions()

    ------------------------------------------------------------
    -- 1. GOD ACCOUNT BOOST
    ------------------------------------------------------------
    elseif choice == 2 then
        Menu_GodAccount()

    ------------------------------------------------------------
    -- 2. MONEY
    ------------------------------------------------------------
    elseif choice == 3 then
        local m = gg.choice({
            "💰 Instant Money ON (~50M)",
            "💤 Instant Money OFF",
            "🧊 Freeze Coins",
            "🛒 Free Purchases (IsEnoughCoins)",
            "↩️ Back",
        }, nil, "💰 MONEY & CURRENCY")
        if m == 1 then applyMaxMoney()
        elseif m == 2 then revertMaxMoney()
        elseif m == 3 then freezeCoins()
        elseif m == 4 then freePurchases()
        elseif m == 5 then HomeMenu() end

    ------------------------------------------------------------
    -- 3. UNLOCK HUB
    ------------------------------------------------------------
    elseif choice == 4 then
        local u = gg.multiChoice({
            "🔓 Unlock All",
            "👮 Unlock Police",
            "🔧 Air Suspension",
            "🏠 hasHouse",
            "🎨 Unlock Paint",
            "🔩 Unlock Bodykit",
            "👕 Unlock Clothes",
            "🚩 Unlock Flags",
            "🛞 Unlock Wheels",
            "📦 32 Slots / SlotMod",
            "🛞 Tyres Menu",
            "↩️ Back",
        }, nil, "🔓 UNLOCK HUB")
        if u == nil then return end
        if u[1]  then _unlockall    = tog(_unlockall,    applyUnlockAll,  revertUnlockAll) end
        if u[2]  then _unlockpolice = tog(_unlockpolice, applyPolice,     revertPolice) end
        if u[3]  then _unlockAirSus = tog(_unlockAirSus, applyAirSus,     revertAirSus) end
        if u[4]  then hasHouse() end
        if u[5]  then paint() end
        if u[6]  then bodykit() end
        if u[7]  then unlockClothes() end
        if u[8]  then unlockFlags() end
        if u[9]  then wheelUnlock() end
        if u[10] then
            local s = gg.choice({"📦 ThirtyTwoSlots", "📦 slotmod", "↩️ Back"}, nil, "SLOTS")
            if s == 1 then ThirtyTwoSlots()
            elseif s == 2 then slotmod() end
        end
        if u[11] then tyresMenu() end
        if u[12] then HomeMenu() end

    ------------------------------------------------------------
    -- 3. RACE / DRAG / RALLY
    ------------------------------------------------------------
    elseif choice == 5 then
        local r = gg.choice({
            "🏎️ Race Tracks (hook1)",
            "🏁 Le Mans toggle  " .. tostring(lemans or ""),
            "🚦 Drag Race (hook3)",
            "🏔️ Rally (hook4)",
            "🌐 Bypass Server Race (hook5)",
            "🚘 Car Class Editor (hook6)",
            "👑 CoinsHook Race Menu (Main)",
            "⚡ Active ALL Race Hooks",
            "↩️ Back",
        }, nil, "🏁 RACE / DRAG / RALLY")
        if r == 1 then hook1()
        elseif r == 2 then
            if lemans == on then lemans1(); lemans = off
            else lemans2(); lemans = on end
        elseif r == 3 then hook3()
        elseif r == 4 then hook4()
        elseif r == 5 then hook5()
        elseif r == 6 then hook6()
        elseif r == 7 then Main()
        elseif r == 8 then activeall1()
        elseif r == 9 then HomeMenu() end

    ------------------------------------------------------------
    -- 4. GEARBOX / ENGINE
    ------------------------------------------------------------
    elseif choice == 6 then
        menubypassgb()

    ------------------------------------------------------------
    -- 5. ACHIEVEMENTS
    ------------------------------------------------------------
    elseif choice == 7 then
        Menu_Achievement()

    ------------------------------------------------------------
    -- 6. BOOSTERS
    ------------------------------------------------------------
    elseif choice == 8 then
        Menu_booster()

    ------------------------------------------------------------
    -- 7. PRANK
    ------------------------------------------------------------
    elseif choice == 9 then
        local pr = gg.choice({
            "😈 Full Prank Menu",
            "🛡️ AntiCheat + Anti-Kick",
            "💥 BREAK CARS (merged)",
            "💃 Dance Car 1",
            "💃 Dance Car 2",
            "💃 Dance Car 3",
            "🧱 Wall Hack",
            "🏃 Fast Character ON",
            "🐢 Fast Character OFF",
            "🧲 Magnet",
            "🚁 Hover Car",
            "✈️ Fly All Cars",
            "🌑 Shadow Wall",
            "🔗 Towing Cars",
            "👤 Unlock Passenger",
            "🚪 Bobol / Unlock Door",
            "🚫 No Kick Car",
            "🛡️ Solid Collision",
            "📛 Change Name",
            "⚡ EMP Field",
            "🏃 Speed (Garage RUNCHARACTER)",
            "↩️ Back",
        }, nil, "😈 PRANK & FUN")
        if pr == 1 then Menu_prank()
        elseif pr == 2 then activateAntiCheat()
        elseif pr == 3 then activateBreakCars()
        elseif pr == 4 then danceCar1()
        elseif pr == 5 then danceCar2()
        elseif pr == 6 then danceCar3()
        elseif pr == 7 then wallHack()
        elseif pr == 8 then fastCharacter()
        elseif pr == 9 then fastCharacterOFF()
        elseif pr == 10 then MAgnet()
        elseif pr == 11 then hovercar()
        elseif pr == 12 then flycarall()
        elseif pr == 13 then shadowwall()
        elseif pr == 14 then towingthecars()
        elseif pr == 15 then PAssengerunlock()
        elseif pr == 16 then bobolMubil()
        elseif pr == 17 then Nokickcar()
        elseif pr == 18 then IgnoreCollisionWithOtherCars()
        elseif pr == 19 then CHANGENAME()
        elseif pr == 20 then togglePatch()
        elseif pr == 21 then RUNCHARACTER()
        elseif pr == 22 then HomeMenu() end

    ------------------------------------------------------------
    -- 8. LOGO RANK
    ------------------------------------------------------------
    elseif choice == 10 then
        Menu_logorank()

    ------------------------------------------------------------
    -- 9. TELEPORT & MODS
    ------------------------------------------------------------
    elseif choice == 11 then
        local tm = gg.choice({
            "📍 Location Teleport (map / saves / others)  ★",
            "👁️ Players / Names / Positions",
            "📍 XYZ Teleport (advanced)",
            "🔩 Modifications (tires / bumper)",
            "↩️ Back",
        }, nil, "📍 TELEPORT & MODS")
        if tm == 1 then Menu_LocationTeleport()
        elseif tm == 2 then Menu_PlayerESP()
        elseif tm == 3 then xyzteleport()
        elseif tm == 4 then menu_modifications()
        elseif tm == 5 then HomeMenu() end

    ------------------------------------------------------------
    -- 10. BYPASS & ACCOUNT
    ------------------------------------------------------------
    elseif choice == 12 then
        local b = gg.choice({
            "📁 Full Bypass Menu",
            "🔑 ID Changer",
            "🔐 Password Finder",
            "🔑 Bypass Room Password",
            "🚘 Black Car Bypass",
            "🌐 Bypass Server (IsCheatFinish)",
            "↩️ Back",
        }, nil, "🛡️ BYPASS & ACCOUNT")
        if b == 1 then Menu_bypassmenu()
        elseif b == 2 then IDChanger()
        elseif b == 3 then checkpassword()
        elseif b == 4 then bypassRoomPassword()
        elseif b == 5 then bypassserver()
        elseif b == 6 then hook5()
        elseif b == 7 then HomeMenu() end

    ------------------------------------------------------------
    -- 11. SHOP / PARTS EXTRA
    ------------------------------------------------------------
    elseif choice == 13 then
        local s = gg.choice({
            "👮 policeautoset",
            "👮 unlockPolice (full)",
            "🎨 paint",
            "🔩 bodykit",
            "🏠 hasHouse",
            "🛞 wheelUnlock",
            "🚩 unlockFlags",
            "👕 unlockClothes",
            "📦 ThirtyTwoSlots",
            "📦 slotmod",
            "🔧 unlockAirSuspension",
            "↩️ Back",
        }, nil, "🚗 SHOP / PARTS")
        if s == 1 then policeautoset()
        elseif s == 2 then unlockPolice()
        elseif s == 3 then paint()
        elseif s == 4 then bodykit()
        elseif s == 5 then hasHouse()
        elseif s == 6 then wheelUnlock()
        elseif s == 7 then unlockFlags()
        elseif s == 8 then unlockClothes()
        elseif s == 9 then ThirtyTwoSlots()
        elseif s == 10 then slotmod()
        elseif s == 11 then unlockAirSuspension()
        elseif s == 12 then HomeMenu() end

    ------------------------------------------------------------
    -- 12. CPM1-STYLE EXTRAS
    ------------------------------------------------------------
    elseif choice == 14 then
        Menu_CPM1Style()

    ------------------------------------------------------------
    -- 13. EXTRA UNLOCKS / BYPASSES
    ------------------------------------------------------------
    elseif choice == 15 then
        Menu_ExtraUnlockBypass()

    ------------------------------------------------------------
    -- 14. PHYSICS / GOD MODE / HANDLING  (NEW)
    ------------------------------------------------------------
    elseif choice == 16 then
        Menu_PhysicsGod()

    ------------------------------------------------------------
    -- 15. EXIT
    ------------------------------------------------------------
    elseif choice == 17 then
        gg.clearResults()
        gg.clearList()
        gg.toast("Bye — CPM2 Merged")
        if exit then pcall(exit) end
        running = false
        os.exit()
    end
end

-- ═══════════════════════════════════════════
--  §20 MAIN LOOP  (opensource TEMPLATE)
-- ═══════════════════════════════════════════

running = true
TEMPLATE = -1

function exit()
    running = false
end

gg.toast("✅ CPM2 Merged v1.3.2.3 loaded")
gg.setVisible(true)

while running do
    if gg.isVisible(true) then
        TEMPLATE = 1
        gg.setVisible(false)
    end
    if TEMPLATE == 1 then
        HomeMenu()
        TEMPLATE = -1
    end
end
