gg.setVisible(false)
gg.clearResults()

------------------------------------------------
-- Get libil2cpp base
------------------------------------------------
local function getLibBase()
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges == 0 then
        gg.alert("❌ libil2cpp.so not found")
        os.exit()
    end
    for _, r in ipairs(ranges) do
        if r.state == "Xa" then
            return r.start
        end
    end
    return ranges[1].start
end

local base = getLibBase()

------------------------------------------------
-- Patch helper
------------------------------------------------
local function carPatch(baseRva, patches)
    local t = {}
    for _, p in ipairs(patches) do
        t[#t+1] = {
            address = base + baseRva + p[1],
            flags   = gg.TYPE_DWORD,
            value   = p[2]
        }
    end
    gg.setValues(t)
end

------------------------------------------------
-- Unlock Cars (BuyThisVehicle d__248)
------------------------------------------------
function unlockCars()

    ------------------------------------------------
    -- PATCH 1 : MoveNext of <BuyThisVehicle>d__248
    -- RVA: 0x2F81A20
    ------------------------------------------------
    local MoveNext = 0x2F81A20

    carPatch(MoveNext, {
        {0x5C0, -721215457},
        {0x684, -721215457},
        {0x7B4, -721215457},
        {0x800, -721215457},
        {0x804,  1384120360},
    })

    ------------------------------------------------
    -- PATCH 2 : SetStateMachine relative patches
    -- RVA: 0x2F819C8
    ------------------------------------------------
    local SetStateMachine = 0x2F819C8

    carPatch(SetStateMachine, {
        {-0xB5C, 1384120360},
        {-0xA98, 1384120360},
        {-0x968, 1384120360},
        {-0x91C, 1384120360},
        {-0x918, 1384120360},
    })

    ------------------------------------------------
    -- PATCH 3 : GetCarPrice
    -- RVA: 0x36F1758
    ------------------------------------------------
    local GetCarPrice = 0x36F1758

    carPatch(GetCarPrice, {
        {0x30, 1384122227},
    })

    gg.toast("✅ Unlock Cars ON")
end

------------------------------------------------
-- Menu
------------------------------------------------
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)

        local choice = gg.choice({
            "🚗 Unlock Cars",
            "❌ Exit"
        }, nil, "CPM2 - BuyThisVehicle d__248")

        if choice == 1 then
            unlockCars()
        elseif choice == 2 then
            os.exit()
        end
    end
    gg.sleep(150)
end
