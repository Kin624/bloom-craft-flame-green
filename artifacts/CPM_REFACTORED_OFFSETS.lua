






function Patch(lib, offset, hex)
    local ms = ""
    if tabl0001 == nil then
        tabl0001 = {}
    end
    local targetAddr = 0
    local hexStrCount = #hex:gsub("%s+", "") -- remove spaces between hex
    if hexStrCount % 2 ~= 0 then
        return print("Look at your hex again. Something went wrong there.")
    end -- hexs must be an even number, not odd.
    local hexCount = hexStrCount / 2

    for i, v in ipairs(gg.getRangesList(lib)) do
        if v.type:sub(3, 3) == "x" then
            targetAddr = v.start + offset
            break
        end
    end
    local editHex = {}
    local ed = {}
    for i = 1, hexCount do
        editHex[i] = { address = targetAddr + (i - 1), flags = gg.TYPE_BYTE }
    end
    gg.loadResults(editHex)
    local res = gg.getResults(gg.getResultsCount())
    for i in ipairs(res) do
        ms = string.format("%x", res[i].value)
        ms = string.upper(ms)
        ms = ms:gsub("FFFFFFFFFFFFFF", "")
        if ms == "0" then
            ms = ms:gsub("0", "00")
        end
        if #ms == 1 then
            ms = "0" .. ms
        end
        ed[i] = ms
    end
    ms = table.concat(ed)
    ms = "h" .. ms
    lob = #tabl0001 + 1
    oft = #tabl0001 + 2
    eiz = #tabl0001 + 3
    tabl0001[lob] = lib
    tabl0001[oft] = offset
    tabl0001[eiz] = ms
    gg.loadResults(editHex)
    gg.getResults(hexCount)
    gg.editAll("h" .. hex, gg.TYPE_BYTE)
    gg.clearResults()
end

function Restore(lib, offset)
    for i = 1, #tabl0001 do
        if tabl0001[i] == lib and tabl0001[i + 1] == offset then
            edi = tabl0001[i + 2]
            hex = #tabl0001[i + 2] - 1
        end
    end
    for i, v in ipairs(gg.getRangesList(lib)) do
        if v.type:sub(3, 3) == "x" then
            targetAddr = v.start + offset
            break
        end
    end
    local editHex = {}
    local ed = {}
    hex = hex / 2
    for i = 1, hex do
        editHex[i] = { address = targetAddr + (i - 1), flags = gg.TYPE_BYTE }
    end
    gg.loadResults(editHex)
    gg.getResults(gg.getResultsCount())
    gg.editAll(edi, 1)
    gg.clearResults()
end

local gg = gg
v = gg.getTargetInfo()
L = v.label
V = v.processName
local info = gg.getTargetInfo()
local LibTable = {}

-- Confirmar 64 bits
function isProcess64Bit()
    local regions = gg.getRangesList()
    local lastAddress = regions[#regions]["end"]
    return (lastAddress >> 32) ~= 0
end

local ISA = isProcess64Bit()

-- Definir
function ISAOffsets()
    if (ISA == false) then
        edi = "+0x"
        ed = "-0x"
    elseif (ISA == true) then
        edi = "0x"
        ed = "-0x"
    end
end

ISAOffsets()

-- Definir
function ISAOffsetss()
    if (ISA == false) then
        edit = "~A B " .. edits
    elseif (ISA == true) then
        edit = "~A8 B [PC,#" .. edits .. "]"
    end
end

xg = {}

-- Obter e armazenar
function gets(g)
    gg.loadResults(end_hook)
    xg[g] = gg.getResults(gg.getResultsCount())
    gg.clearResults()
end

-- Funcao de configurar biblioteca
function libs(loz)
    liby = 1
    libf = 0
    libzz = loz
    libx = gg.getRangesList(loz)
    for i, v in ipairs(libx) do
        if libx[i].state == "Xa" then
            libz = loz .. "[" .. liby .. "].start"
            xand = gg.getRangesList(loz)[liby].start
            libf = 1
            break
        end
        liby = liby + 1
    end
    lib = xand
end

function __()
    xHEX = string.format("%X", aaaa)
    if (#xHEX > 8) then
        act = (#xHEX - 8) + 1
        xHEX = string.sub(xHEX, act)
    end
    edits = edi .. xHEX
    ISAOffsetss()
end

function _()
    aaa = b - a
    xHEX = string.format("%X", aaa)
    if (#xHEX > 8) then
        act = (#xHEX - 8) + 1
        xHEX = string.sub(xHEX, act)
    end
    edits = ed .. xHEX
    ISAOffsetss()
end

function endhook(cc, g)
    LibStart = lib
    local eh = {}
    eh[1] = { address = (LibStart + cc), flags = gg.TYPE_DWORD, value = xg[g][1].value, freeze = true }
    gg.addListItems(eh)
    gg.clearList()
end

function hook_void(cc, bb, g)
    LibStart = lib
    local m = {}
    m[1] = { address = (LibStart + bb), flags = gg.TYPE_DWORD }
    gg.addListItems(m)
    a = m[1].address
    gg.clearList()
    local p = {}
    p[1] = { address = (LibStart + cc), flags = gg.TYPE_DWORD }
    gg.addListItems(p)
    gg.loadResults(p)
    end_hook = gg.getResults(1)
    gets(g)
    local n = {}
    n[1] = { address = (LibStart + cc), flags = gg.TYPE_DWORD }
    gg.addListItems(n)
    b = n[1].address
    gg.clearResults()
    gg.clearList()
    aaaa = a - b
    if (tonumber(aaaa) < 0) then
        _()
    end
    if (tonumber(aaaa) > 0) then
        __()
    end
    local n = {}
    n[1] = { address = (LibStart + cc), flags = gg.TYPE_DWORD, value = edit, freeze = true }
    gg.addListItems(n)
    gg.clearList()
end

function TesterLua() end
function setvalue(address,flags,value) TesterLua('Modify address value(Address, value type, value to be modified)')
local tt = {}
tt[1]= {}
tt[1].address = address
tt[1].flags = flags
tt[1].value = value
gg.setValues(tt)
end




Results = {}
function valueFromClass(class, offset, tryHard, bit32, valueType, SearchMode)
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
   if userMode == 1 then
      UI()
   elseif error == 3 then
      os.exit()
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







------------------------------------------------------------------------------  
function Edit(lib, offset, value, type)
    local ranges = gg.getRangesList(lib)
    local libBase

    for i, range in ipairs(ranges) do
        if range.state == "Xa" then
            libBase = range.start
            break
        end
    end

    if not libBase then
        return
    end

    local numericOffset = tonumber(offset)
    local finalAddress = libBase + numericOffset
    local dwordValue = tonumber(value, 16)
    gg.setValues({
        {
            address = finalAddress,
            flags = type,
            value = dwordValue
        }
    })
end


function patchBytes(offset, hexString) 
    local addr = base + offset 
    local bytes = {} 
    for byte in hexString:gmatch("[^%s]+") do 
        table.insert(bytes, {address = addr, flags = gg.TYPE_BYTE, value = tonumber(byte, 16)}) 
        addr = addr + 1 
    end 
    gg.setValues(bytes) 
end



-- ============================================================
-- LIB + SecreDevPatch (named offsets style)
-- ============================================================
local libs = gg.getRangesList('libil2cpp.so')[2].start

function SecreDevPatch(secretablepatch, baseOffset) --==========[ FUNCTION LIB TABLE ]=======
    if #secretablepatch < 1 then
        return false
    end
    -- refresh lib base each call (safer after process resume)
    libs = gg.getRangesList('libil2cpp.so')[2].start
    local R = {}
    for _, patch in ipairs(secretablepatch) do
        table.insert(R, {
            address = libs + baseOffset + patch[1],
            value = patch[2],
            freeze = true,
            flags = gg.TYPE_DWORD
        })
    end
    gg.setRanges(gg.REGION_CODE_APP)
    gg.addListItems(R)
    gg.removeListItems(R)
end

-- ============================================================
-- NAMED OFFSETS (libil2cpp.so)
-- ============================================================
local OFF_GetFloat_Money          = 0x2F1A554   -- ObscuredPrefs.GetFloat / Instant & Max Money
local OFF_IsBought_Police         = 0x39C682C   -- IsBought (Police cars)
local OFF_AirSus_A                = 0x38F38A4 + 0x448
local OFF_AirSus_B                = 0x39A8EDC - 0x28C
local OFF_Tyres                   = 0x3B7540C   -- Tyres 0% / 100%
local OFF_IgnoreCollision         = 0x32B9948   -- IgnoreCollisionWithOtherCars
local OFF_CheckCarPassenger       = 0x32966AC   -- CheckCarForEnterPassenger / CheckCarForEnter
local OFF_LockCar                 = 0x3997EE4   -- LockCar
local OFF_KickedFromCar           = 0x32363E0   -- KickedFromCar
local OFF_LogoRank                = 0x31F9470   -- Rank / Logo getter
local OFF_SlotMod                 = 0x38567F4 + 0xC0
local OFF_WheelUnlock             = 0x34C399C
local OFF_hasHouse                = 0x3256CB8
local OFF_Paint_A                 = 0x384D240
local OFF_Paint_B                 = 0x384CD74
local OFF_Paint_C                 = 0x384D148
local OFF_Bodykit_CoinPrice       = 0x38F7718   -- GetCoinPriceForKit
local OFF_Bodykit_MoneyPrice      = 0x37E0098   -- get_BodyKitsMoneyPrice
local OFF_Bodykit_Extra           = 0x37DF3B8
local OFF_IsBlackVehicle          = 0x380CA48   -- bypass server
local OFF_IDChanger               = 0x6A34BF0 + 0x9C  -- SetString (PlayerPrefs)
local OFF_UnlockAll_A             = 0x384D148
local OFF_UnlockAll_B             = 0x384CD74
local OFF_UnlockAll_C             = 0x384D240
local OFF_UnlockAll_D             = 0x35361F8
local OFF_UnlockAll_E             = 0x32B9668
local OFF_UnlockAll_F             = 0x38531D4
local OFF_UnlockAll_G             = 0x3854528




local title =
"╔क════════क⊱✫⊰क═══════क╗\n" ..
" " .. gg.getTargetInfo()["label"]  .. " "  .. gg.getTargetInfo()["versionName"] .. " 『 " .. gg.getTargetInfo()["versionCode"] .. "』\n" ..
"╚क════════क⊱✫⊰क═══════क╝\n"





    on = " 🔴⃢  "
    off = "      ⃢🔵"
    duplicat1 = on
    money = on
    sale = on
    racing = on
    lemans = on
    teleport = on
    place3 = on

_unlockall = false
_unlockpolice = false
_unlockAirSus = false
_maxMoneyActive = false
_tyres100 = false
_tyres0 = false


_prevUnlockAll = false
_prevUnlockPolice = false
_prevUnlockAirSus = false
_prevMaxMoneyActive = false
_prevTyres100 = false
_prevTyres0 = false


running = true
TEMPLATE = 1
gg.setVisible(false)
gg.toast("༒□□□□□□□□□□0%༒")
gg.sleep(50)
gg.toast("༒■□□□□□□□□□10%༒")
gg.sleep(51)
gg.toast("༒■■□□□□□□□□20%༒")
gg.sleep(52)
gg.toast("༒■■■□□□□□□□30%༒")
gg.sleep(53)
gg.toast("༒■■■■□□□□□□40%༒")
gg.sleep(54)
gg.toast("༒■■■■■□□□□□50%༒")
gg.sleep(55)
gg.toast("༒■■■■■■□□□□60%༒")
gg.sleep(56)
gg.toast("༒■■■■■■■□□□70%༒")
gg.sleep(57)
gg.toast("༒■■■■■■■■□□80%༒")
gg.sleep(58)
gg.toast("༒■■■■■■■■■□90%༒")
gg.sleep(59)
gg.toast("༒■■■■■■■■■■100%༒")
gg.sleep(200)






 gg.setVisible(true)
    function HomeMenu()
 local menuKINZi = gg.multiChoice({
"『༒ Instant Money༒』", 
"『༒  Unlock All༒』",
"『༒  Unlock Police༒』",
"『༒  Unlock AirSuspension༒』",
"『༒ 📁TyresMenu༒』",
"『༒  Max Money ༒』",
"『༒ Unlock Air Suspension v2༒』",  
"『༒ Unlock Bodykit ༒』",
"『༒ Unlock Paint/calipers/brakes ༒』",
"『༒ Unlock house ༒』",
"『༒ Unlock Police Siren༒』",
"『༒ Unlock Police bodykits༒』",
"『༒ Unlock Clothes༒』",
"『༒ Unlock Flags༒』",
"『༒ Unlock Wheels༒』",
"『༒ Unlock Slots ༒』",
"『༒ Unlock Slots v2 ༒』",
"『📁ACHIEVEMENT MENU༒』",   
"『📁BOOSTER MENU༒』", 
"『📁BYPASS MENU༒』", 
"『📁LOGO MENU༒』", 
"『📁X Y Z TELEPORTATION MENU༒』", 
"『📁MODIFICATIONS MENU༒』", 
"『📁GB,ENGINE,TIME MENU༒』", 
"『📁RACE MENU ༒』", 
"『📁😂PRANK MENU😂』", 
   "𝓔𝔁𝓲𝓽" 
 }, nil, title)

   if menuKINZi == nil then return end
   if menuKINZi[1] then Menu_Money() end
  -- Inserted toggle logic (Items 2 to 6)
    if menuKINZi[2] then 
        if _unlockall then
            revertUnlockAll()
            _unlockall = false
        else
            applyUnlockAll()
            _unlockall = true
        end
    end

    if menuKINZi[3] then
        if _unlockpolice then
            revertPolice()
            _unlockpolice = false
        else
            applyPolice()
            _unlockpolice = true
        end
    end

    if menuKINZi[4] then
        if _unlockAirSus then
            revertAirSus()
            _unlockAirSus = false
        else
            applyAirSus()
            _unlockAirSus = true
        end
    end

    if menuKINZi[5] then tyresMenu() end

    if menuKINZi[6] then
        if _maxMoneyActive then
            revertMaxMoney()
            _maxMoneyActive = false
        else
            applyMaxMoney()
            _maxMoneyActive = true
        end
    end
   if menuKINZi[7] then unlockAirSuspension() end
   if menuKINZi[8] then bodykit() end
   if menuKINZi[9] then paint() end
   if menuKINZi[10] then hasHouse() end
   if menuKINZi[11] then policeautoset() end
   if menuKINZi[12] then unlockPolice() end
   if menuKINZi[13] then unlockClothes() end
   if menuKINZi[14] then unlockFlags() end
   if menuKINZi[15] then wheelUnlock() end
   if menuKINZi[16] then ThirtyTwoSlots() end
   if menuKINZi[17] then slotmod() end
   if menuKINZi[18] then Menu_Achievement() end
   if menuKINZi[19] then Menu_booster() end
   if menuKINZi[20] then Menu_bypassmenu() end
   if menuKINZi[21] then Menu_logorank() end
   if menuKINZi[22] then xyzteleport() end
   if menuKINZi[23] then menu_modifications() end
   if menuKINZi[24] then menubypassgb() end
   if menuKINZi[25] then Mainracingmenu() end
   if menuKINZi[26] then Menu_prank() end
   if menuKINZi[27] then exit() end
   TEMPLATE = -1 
   end   


function tyresMenu()
    local t = gg.choice({
        "Tyres 100%",
        "Tyres 0%",
        "Back"
    }, nil, title)

    if t == nil then return end

    if t == 1 then
        if _tyres100 then
            revertTyres100()
            _tyres100 = false
        else
            _tyres0 = false
            applyTyres100()
            _tyres100 = true
        end
    end

    if t == 2 then
        if _tyres0 then
            revertTyres0()
            _tyres0 = false
        else
            _tyres100 = false
            applyTyres0()
            _tyres0 = true
        end
    end

    if t == 3 then
        HomeMenu()
    end
end



-- ==================== FLAGS ====================

-- ==================== Functions  ====================
function getLib()
    local ranges = gg.getRangesList("libil2cpp.so")
    if not ranges or #ranges < 2 then return nil end
    return ranges[2].start
end

-- ==================== MAX MONEY ====================
function applyMaxMoney()
    -- OFF_GetFloat_Money = 0x2F1A554
    SecreDevPatch({
        {0x0, 310934496},
        {0x4, 1923712960},
        {0x8, 505872384},
        {0xC, -698416192},
    }, OFF_GetFloat_Money)
    gg.toast("Max Money ON (50M)")
end

function revertMaxMoney()
    SecreDevPatch({
        {0x0, -65204248},
        {0x4, -1459529730},
        {0x8, -1459466252},
        {0xC, -1342009036},
    }, OFF_GetFloat_Money)
    gg.toast("Max Money OFF")
end

-- ==================== UNLOCK ALL ====================
function applyUnlockAll()
    local list = {
        OFF_UnlockAll_A, OFF_UnlockAll_B, OFF_UnlockAll_C,
        OFF_UnlockAll_D, OFF_UnlockAll_E, OFF_UnlockAll_F, OFF_UnlockAll_G
    }
    for _, off in ipairs(list) do
        SecreDevPatch({
            {0x0, -763363296},
            {0x4, -698416192},
        }, off)
    end
    gg.toast("Unlock All ON")
end

function revertUnlockAll()
    applyUnlockAll()
    gg.toast("Unlock All OFF")
end

-- ==================== POLICE ====================
function applyPolice()
    -- OFF_IsBought_Police = 0x39C682C
    SecreDevPatch({
        {0x0, -763363296},
        {0x4, -698416192},
    }, OFF_IsBought_Police)
    gg.toast("Police ON")
end

function revertPolice()
    SecreDevPatch({
        {0x0, -132182018},
        {0x4, -1275068159},
    }, OFF_IsBought_Police)
    gg.toast("Police OFF")
end

-- ==================== AIR SUSPENSION ====================
function applyAirSus()
    SecreDevPatch({
        {0x0, -721215457},
    }, OFF_AirSus_A)
    SecreDevPatch({
        {0x0, 335544398},
    }, OFF_AirSus_B)
    gg.toast("AirSuspension ON")
end

function revertAirSus()
    SecreDevPatch({
        {0x0, 905972544},
    }, OFF_AirSus_A)
    SecreDevPatch({
        {0x0, 1795687071},
    }, OFF_AirSus_B)
    gg.toast("AirSuspension OFF")
end

-- ==================== TYRES ====================
function applyTyres100()
    -- OFF_Tyres = 0x3B7540C
    SecreDevPatch({
        {0x0, 1384120320},
        {0x4, 1923608576},
        {0x8, 505872384},
        {0xC, -698416192},
    }, OFF_Tyres)
    gg.toast("Tyres 100% ON")
end

function revertTyres100()
    SecreDevPatch({
        {0x0, -1119699968},
        {0x4, -698416192},
        {0x8, -132182018},
        {0xC, -113139704},
    }, OFF_Tyres)
    gg.toast("Tyres 100% OFF")
end

function applyTyres0()
    SecreDevPatch({
        {0x0, -763363328},
        {0x4, -698416192},
        {0x8, -132182018},
        {0xC, -113139704},
    }, OFF_Tyres)
    gg.toast("Tyres 0% ON")
end

function revertTyres0()
    SecreDevPatch({
        {0x0, 1384120320},
        {0x4, 1923608576},
        {0x8, 505872384},
        {0xC, -698416192},
    }, OFF_Tyres)
    gg.toast("Tyres 0% OFF")
end



   
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
        "⚠️ WARNING ⚠️\n\nThis feature may cause your Game to crash or freeze.\nDo you want to continue?"
    )
    if proceed == nil or proceed ~= 1 then
        gg.alert("❌ Operation cancelled for safety.")
        return
    end
    -- OFF_IgnoreCollision = 0x32B9948
    -- public static void IgnoreCollisionWithOtherCars(...)
    SecreDevPatch({
        {0x0, "D2800020h"}, -- MOV X0, #1
        {0x4, "D65F03C0h"}, -- RET
    }, OFF_IgnoreCollision)
    gg.toast("༒ON༒")
    gg.sleep(1000)
end


local patchOn = false

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
    -- OFF_CheckCarPassenger = 0x32966AC
    -- private void CheckCarForEnterPassenger(...)
    SecreDevPatch({
        {0x0, "D2800020h"}, -- MOV X0, #1
        {0x4, "D65F03C0h"}, -- RET
    }, OFF_CheckCarPassenger)
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
    -- OFF_KickedFromCar = 0x32363E0
    -- public void KickedFromCar()
    SecreDevPatch({
        {0x0, "D2800020h"}, -- MOV X0, #1
        {0x4, "D65F03C0h"}, -- RET
    }, OFF_KickedFromCar)
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
    -- OFF_CheckCarPassenger = 0x32966AC  (CheckCarForEnter)
    SecreDevPatch({
        {0x0, "D2800020h"},
        {0x4, "D65F03C0h"},
    }, OFF_CheckCarPassenger)

    -- OFF_LockCar = 0x3997EE4
    SecreDevPatch({
        {0x0, "D2800020h"},
        {0x4, "D65F03C0h"},
    }, OFF_LockCar)

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


function fastCharacter()
   gg.alert(
  "📌 FAST CHARACTER 📌\n\n" ..
  "Activate this inside the lobby while playing.\n\n" ..
  "When active:\n" ..
  "🏃 Your character’s movement speed will increase immediately.\n\n" ..
  "How to use:\n" ..
  "1️⃣ Enter the lobby.\n" ..
  "2️⃣ Activate 『Fast Character』.\n" ..
  "3️⃣ Move your character and enjoy the faster speed.\n\n" ..
  "⚠️ WARNING: May cause desync, lag, or crashes on some devices.\n\n" ..
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
    gg.searchNumber("1", gg.TYPE_DOUBLE)
    gg.getResults(250)
    gg.editAll("10", gg.TYPE_DOUBLE)
    gg.toast("Fast Character ON")
    gg.clearResults()
end

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


function hook1()
    UnlockKinz = gg.choice({
        "〇 | Hook Laps | 1 Lap",
        "〇 | Dumb Enemies",
        "〇 | Hook All Penaltys",
        "〇 | Teleport Patch",
        "〇 | Instant Win",
        "〇 | Active All",
        "『༒BACK⌦ ༒』"
 }, nil, title)

    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end

    if UnlockKinz == 1 then racing1() end
    if UnlockKinz == 2 then racing2() end
    if UnlockKinz == 3 then racing3() end
    if UnlockKinz == 4 then racing4() end
    if UnlockKinz == 5 then racing5() end
    if UnlockKinz == 6 then activeall1() end
    if UnlockKinz == 7 then Mainracingmenu() end
end


function racing1() --RaceConfigSO 0x34
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

--IsFinalLap
setvalue(libil2cpp + 0x318D9B0, gg.TYPE_DWORD, -763363296)
setvalue(libil2cpp + 0x318D9B0 + 0x4, gg.TYPE_DWORD, -698416192)
gg.toast('Laps Hooked')
end

function racing2()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

--ChangeSteeringState~CircuitCarStearing
setvalue(libil2cpp + 0x32F3E48, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + 0x32F3E48 + 0x4, gg.TYPE_DWORD, -698416192)
gg.toast'Dumb Enemies Actived'
end

function racing3()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end


-- IsCheatFinish~LapRaceCar (Bypass Rewards)
local CheatDetect = 0x318D21C
-- GetCurrentLapTime
local Time1 = 0x318D7E4
local Time2 = 0x318D79C
local Time3 = 0x318D7EC
local Time4 = 0x318D880
local Time6 = 0x3184ED8
local Time7 = 0x3184EAC
local Time8 = 0x318DB80
local Time9 = 0x3BC1B8C
local Time10 = 0x3BC1B8C
local Time11 = 0x3BC1B60
local Time12 = 0x3A8301C
-- GetPenaltyDistance~LapRaceCar
local Penalty1 = 0x318D528
local Penalty2 = 0x318D8C8
local Penalty3 = 0x3184ECC
local Penalty4 = 0x3BC1558
local Penalty5 = 0x3BC1568
local Penalty6 = 0x3BD6614
local Penalty7 = 0x3BD661C
local Penalty8 = 0x3BD6624
local Penalty9 = 0x3BD6630
local Penalty10 = 0x3BD6638
-- GetTotalProgress~LapRaceCar
local Distance1 = 0x318D448
local Distance2 = 0x318D538
local Distance3 = 0x318D4E4
local Distance4 = 0x3189D44
local Distance5 = 0x3BC2898
local Distance6 = 0x3BC28EC



setvalue(libil2cpp + CheatDetect, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + CheatDetect + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time1, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time1 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time2, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time2 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time3, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time3 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time4, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time4 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time6, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time6 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time7, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time7 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time8, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time8 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time9, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time9 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time10, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time10 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time11, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time11 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Time12, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Time12 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty1, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty1 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty2, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty2 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty3, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty3 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty4, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty4 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty5, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty5 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty6, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty6 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty7, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty7 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty8, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty8 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty9, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty9 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Penalty10, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Penalty10 + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance1, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance1 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance1 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance1 + 0xC, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance2, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance2 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance2 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance2 + 0xC, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance3, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance3 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance3 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance3 + 0xC, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance4, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance4 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance4 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance4 + 0xC, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance5, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance5 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance5 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance5 + 0xC, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Distance6, gg.TYPE_DWORD, 310934496)
setvalue(libil2cpp + Distance6 + 0x4, gg.TYPE_DWORD, 1923712960)
setvalue(libil2cpp + Distance6 + 0x8, gg.TYPE_DWORD, 505872384)
setvalue(libil2cpp + Distance6 + 0xC, gg.TYPE_DWORD, -698416192)
gg.toast('Removed All Penalty')
end

function racing4()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end


-- CheckParent~CircuitRaceControlller
local BypassLocal = 0x32FB40C
-- CalculatePos~LapRaceCar
local TeleportPatch = 0x318DD50


setvalue(libil2cpp + BypassLocal, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + BypassLocal + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + TeleportPatch, gg.TYPE_DWORD, -721215457)
setvalue(libil2cpp + TeleportPatch + 0x4, gg.TYPE_DWORD, -698416192)
gg.alert'Auto Win Actived✅\n Run until you reach the halfway point of the race (75%) then Teleport Car To Start Race, Then WIN'
gg.toast'Auto Win Race Actived ✅'
end

function racing5()
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("4692750812804284416", gg.TYPE_QWORD)
local results = gg.getResults(1000)

local check_minus4 = {}
local addr_refs = {}
for _, r in ipairs(results) do
    check_minus4[#check_minus4 + 1] = { address = r.address - 0x4, flags = gg.TYPE_DWORD }
    addr_refs[#addr_refs + 1] = r.address
end
local values_minus4 = gg.getValues(check_minus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_minus4) do
    if v.value == 1092616192 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x4, flags = gg.TYPE_DWORD }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus4 = gg.getValues(candidates)

local check_minus8 = {}
for i = 1, #candidate_refs do
    check_minus8[#check_minus8 + 1] = { address = candidate_refs[i] - 0x8, flags = gg.TYPE_DWORD }
end
local values_minus8 = gg.getValues(check_minus8)

local edits = {}
for i, v in ipairs(values_plus4) do
if v.value == 1092616192 and (values_minus8[i].value == 0 or values_minus8[i].value == 1 or values_minus8[i].value == 2) then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x20,
            flags = gg.TYPE_DWORD,
            value = 288,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x34,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.setVisible(false)
-- RaceStartTrigger
gg.clearResults()
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_DWORD)
local r = gg.getResults(100000)

local t1 = {}
local t1Refs = {}
for _, v in ipairs(r) do
    t1[#t1+1] = { address = v.address + 0x40, flags = gg.TYPE_DWORD }
    t1Refs[#t1Refs+1] = v.address
end
t1 = gg.getValues(t1)

local t2 = {}
local t2Refs = {}
for i, v in ipairs(t1) do
    if v.value >= 1 and v.value <= 60 then
        t2[#t2+1] = { address = t1Refs[i] - 0xA4, flags = gg.TYPE_DWORD }
        t2Refs[#t2Refs+1] = t1Refs[i]
    end
end

if #t2 == 0 then gg.toast("Nothing") return end
t2 = gg.getValues(t2)

local t3 = {}
local t3Refs = {}
for i, v in ipairs(t2) do
if v.value >= 90 and v.value <= 118 then
        t3[#t3+1] = { address = t2Refs[i] - 0xB4, flags = gg.TYPE_QWORD }
        t3Refs[#t3Refs+1] = t2Refs[i]
    end
end

if #t3 == 0 then gg.toast("Nothing") return end
t3 = gg.getValues(t3)

local t4 = {}
local t4Refs = {}
for i, v in ipairs(t3) do
    if v.value == 4294967296 then
        t4[#t4+1] = { address = t3Refs[i] - 0xB0, flags = gg.TYPE_DWORD }
        t4Refs[#t4Refs+1] = t3Refs[i]
    end
end

if #t4 == 0 then gg.toast("Nothing") return end
t4 = gg.getValues(t4)

local e = {}
for i, v in ipairs(t4) do
    if v.value == 1 then
        e[#e+1] = {
            address = t4Refs[i] - 0xB0,
            flags = gg.TYPE_DWORD,
            value = 3,
            freeze = true
        }
    end
end

if #e == 0 then
    local tOpt = {}
    local tOptRefs = {}
    for i, v in ipairs(t4) do
        tOpt[#tOpt+1] = { address = t4Refs[i] - 0x128, flags = gg.TYPE_DWORD }
        tOpt[#tOpt+1] = { address = t4Refs[i] - 0x188, flags = gg.TYPE_FLOAT }
        tOptRefs[#tOptRefs+1] = t4Refs[i]
    end
    tOpt = gg.getValues(tOpt)

    for i, _ in ipairs(tOptRefs) do
        local idx = (i - 1) * 2 + 1
        if tOpt[idx].value == 2 and tOpt[idx+1].value == 0.10000000149 then
            e[#e+1] = {
                address = tOptRefs[i] - 0xB0,
                flags = gg.TYPE_DWORD,
                value = 3,
                freeze = true
            }
        end
    end
end

if #e == 0 then gg.toast("Nothing ") return end

gg.addListItems(e)
gg.clearResults()
gg.setVisible(false)
gg.toast('Auto Win On ✅')
end

function activeall1()
    racing1()
    racing2()
    racing3()
    racing4()
gg.toast'All Function Actived ✅'
end



function lemans1()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

-- SetTime~LemanRaceController
local LemansHook = 0x3334B64
--OnLapFinish
local Finish = 0x318D56C

setvalue(libil2cpp + LemansHook, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + LemansHook + 0x4, gg.TYPE_DWORD, -698416192)
setvalue(libil2cpp + Finish, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + Finish + 0x4, gg.TYPE_DWORD, -698416192)
gg.alert'Dont Use Hook Penaltys With This Function'
gg.toast'Lemans 0s ✅'
end


function lemans2() --OFF
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

-- SetTime~LemanRaceController
local LemansHook = 0x3334B64

setvalue(libil2cpp + LemansHook, gg.TYPE_DWORD, -132247554)
setvalue(libil2cpp + LemansHook + 0x4, gg.TYPE_DWORD, -1459531788)
gg.toast'Lemans 24min ✅'
end


function hook3()
    UnlockKinz = gg.choice({
        "〇 | Instant Win",
        "〇 | Always Win",
        "〇 | Select Class",
        "〇 | One Race Win",
        "〇 | Win 2Place",
        "〇 | Win 3Place " .. place3,
        "『༒BACK⌦ ༒』"
 }, nil, title)

    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end

    if UnlockKinz == 1 then drager1() end
    if UnlockKinz == 2 then drager2() end
    if UnlockKinz == 3 then drager3() end
    if UnlockKinz == 4 then drager4() end
    if UnlockKinz == 5 then drager5() end

    if UnlockKinz == 6 then
        if place3 == on then
            pos1(on)
            place3 = off
        else
            pos2(off)
            place3 = on
        end
    end

    if UnlockKinz == 7 then Mainracingmenu() end
end

function drager1()
gg.alert("GO TO DRAG, WHEN THE RACE STARTS ACTIVATE THE HACK")
local search
local offset
local R

gg.setRanges(gg.REGION_ANONYMOUS)
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
  gg.toast'CLICK GG LOGO'

repeat
  repeat
	for i = 1, 200 do
	  gg.sleep(1)
	  if gg.isVisible() then break end
	end
	if R and #R.Z > 0 then
	end
  until gg.isVisible()
  gg.setVisible(false)
  menu = gg.prompt({"CLICK OK TO START","[[Back Menu]]"},LastInput,{"checkbox","checkbox"})
  if menu then
	if not tonumber(menu[1]) then menu[1] = "Click OK" end
	LastInput = {menu[1],menu[2]}
  end
  if menu and menu[2] then return end
  if menu and (menu[4] or R == nil) then
	gg.clearList()
	R = {Z = {}}
  end
  if menu then
	if #R.Z < 1 then
	  gg.clearResults()
	  gg.searchNumber(search,4)
	  local XResults = gg.getResults(gg.getResultsCount())
	  gg.clearResults()
	  for i, v in pairs(XResults) do
		local Xvalue = gg.getValues({{address = v.address + offset.s,flags = 16}})[1].value
		local Xvalue1, Xvalue2, Xvalue3 = gg.getValues({{address = v.address + offset.x,flags = 16}})[1].value, gg.getValues({{address = v.address + offset.y,flags = 16}})[1].value, gg.getValues({{address = v.address + offset.z,flags = 16}})[1].value
		if Xvalue == 1.0000000331813535E32 and ((Xvalue1 > 0 or Xvalue1 < 0) or (Xvalue2 > 0 or Xvalue < 0) or (Xvalue3 > 0 or Xvalue < 0)) then
		  R["Z"][#R.Z + 1] = {address = v.address + offset.z,flags = 16,value = "-500",freeze = true}
		end
	  end
	end
	for i, v in pairs(R.Z) do v.value = "-500" end
	gg.setValues(R.Z)
	if menu[2] then gg.addListItems(R.Z) else gg.removeListItems(R.Z) end
  end
until 1>2
gg.loadResults(R.Z)
gg.addListItems(gg.getResults(9))
gg.clearResults()
gg.clearList()
end

function drager2()
--DragRacingController
gg.setVisible(false)
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(20)
local e = {}

for _,v in ipairs(r) do
    e[#e+1] = {
        address = v.address - 0x70,
        flags = gg.TYPE_DWORD,
        value = 1
    }
end

gg.setValues(e)
gg.setVisible(false)
gg.clearList()
gg.clearResults()
gg.toast("Always Win On ✅")
end

function drager3()
    gg.setVisible(false)

    UnlockKinz = gg.choice({
        "Unlimited Class",
        "S9 Class",
        "S10 Class",
        "S11 Class",
        "S12 Class",
        "S13 Class",
        "『༒BACK⌦ ༒』"
    }, nil, "title")

    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end

    local value = 0

    if UnlockKinz == 1 then value = 8 end
    if UnlockKinz == 2 then value = 9 end
    if UnlockKinz == 3 then value = 10 end
    if UnlockKinz == 4 then value = 11 end
    if UnlockKinz == 5 then value = 12 end
    if UnlockKinz == 6 then value = 13 end
    if UnlockKinz == 7 then hook3() return end

    
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do
    e[#e+1] = {
        address = v.address - 0xC4,
        flags = gg.TYPE_DWORD,
        value = value
    }
end

gg.setValues(e)
gg.toast("Class Activated ✅")
gg.clearList()
gg.clearResults()
gg.setVisible(false)
end


function drager4()
gg.setVisible(false)
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do

    -- Hook Race
    e[#e+1] = {
        address = v.address - 0xD0,
        flags = gg.TYPE_DWORD,
        value = 4
    }

    -- void AlwaysWin
    e[#e+1] = {
        address = v.address - 0x70,
        flags = gg.TYPE_BYTE,
        value = 1
    }

    e[#e+1] = {
        address = v.address - 0x6F,
        flags = gg.TYPE_BYTE,
        value = 1
    }

    e[#e+1] = {
        address = v.address - 0x6E,
        flags = gg.TYPE_BYTE,
        value = 1
    }

    e[#e+1] = {
        address = v.address - 0x6D,
        flags = gg.TYPE_BYTE,
        value = 1
    }

    -- hook Win
    e[#e+1] = {
        address = v.address + 0x48,
        flags = gg.TYPE_BYTE,
        value = 1
    }

    -- hook String 
    e[#e+1] = {
        address = v.address + 0x49,
        flags = gg.TYPE_BYTE,
        value = 1
    }

end
gg.setValues(e)
gg.toast("One Race Win Actived ✅")
gg.clearList()
gg.clearResults()
gg.setVisible(false)
end

function drager5()
gg.setVisible(false)
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do

    -- Hook Race
    e[#e+1] = {
        address = v.address - 0xD0,
        flags = gg.TYPE_DWORD,
        value = 2
    }

end
gg.setValues(e)
gg.alert'⚠️ Dont use [Always Win] Before First Race\nNow Active Always Win and Win Race'
gg.toast("2 Place Win Actived ✅")
gg.clearList()
gg.clearResults()
gg.setVisible(false)
end


function pos1()
gg.setVisible(false)
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do
    e[#e+1] = {
        address = v.address - 0xC7,
        flags = gg.TYPE_BYTE,
        value = 1
    }
end

gg.setValues(e)
gg.toast("3rd Place On ✅")
gg.clearList()
gg.clearResults()
gg.setVisible(false)
end

function pos2()
gg.setVisible(false)
gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("56983420928", gg.TYPE_QWORD)
local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do
    e[#e+1] = {
        address = v.address - 0xC7,
        flags = gg.TYPE_BYTE,
        value = 0
    }
end

gg.setValues(e)
gg.toast("3rd Place Off ❌")
gg.clearList()
gg.clearResults()
gg.setVisible(false)
end


function hook4()
    UnlockKinz = gg.choice({
        "〇 | Hook Time",
        "〇 | Hook All Penaltys",
        "〇 | Teleport Patch",
        "〇 | Auto Win [Road]",
        "〇 | Auto Win [Japan]",
        "〇 | Auto Win [Italy]",
        "〇 | Bypass Reward",
        "〇 | How to Use?",
        "『༒BACK⌦ ༒』"
    }, nil, title)

    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end

    if UnlockKinz == 1 then rally1() end
    if UnlockKinz == 2 then rally2() end
    if UnlockKinz == 3 then rally3() end
    if UnlockKinz == 4 then rally4() end
    if UnlockKinz == 5 then rally5() end
    if UnlockKinz == 6 then rally6() end
    if UnlockKinz == 7 then rally7() end
    if UnlockKinz == 8 then tutorial() end
    if UnlockKinz == 9 then Mainracingmenu() end
end



-- 296 Road
-- 292 Japan
-- ? Ilaty
function tutorial()
gg.alert'Active Auto Win in {Road, Japan, Italy}, Active after start race, dont go to start Point\nClick in start and Active the cheat then Teleport in (Back To Road) then hit npc'
hook4()
end

function rally1()
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_FLOAT)
local results = gg.getResults(1000)

local addr_refs = {}
local check_plus4 = {}
for _, r in ipairs(results) do
    check_plus4[#check_plus4 + 1] = { address = r.address + 0x4, flags = gg.TYPE_FLOAT }
    addr_refs[#addr_refs + 1] = r.address
end
local values_plus4 = gg.getValues(check_plus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_plus4) do
    if v.value == 5 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x8, flags = gg.TYPE_FLOAT }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus8 = gg.getValues(candidates)

local edits = {}
for i, v in ipairs(values_plus8) do
    if v.value == 10 then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x5C,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.toast("Time Hooked")
gg.setVisible(false)
end

function rally2()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

-- IsCarOffRoad~RallyCar
setvalue(libil2cpp + 0x3727954, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + 0x3727954 + 0x4, gg.TYPE_DWORD, -698416192)
-- get_Penalty~RallyCar
setvalue(libil2cpp + 0x37268D8, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + 0x37268D8 + 0x4, gg.TYPE_DWORD, -698416192)
-- get_MissedCheckpoints~RallyCar
setvalue(libil2cpp + 0x37268E0, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + 0x37268E0 + 0x4, gg.TYPE_DWORD, -698416192)
local base = gg.getRangesList('libil2cpp.so')[2].start

    gg.setValues({
        -- AddPenalty~RallyCar
        {address = base + 0x3726F2C, flags = 4, value = "-698416192"},

        -- ApplyMissedCheckpointsPenalty~RallyCar
        {address = base + 0x3728C48, flags = 4, value = "-698416192"},

        -- FinishWithMarshalPenalty~RallyController
      --  {address = base + 0x3728DC8, flags = 4, value = "-698416192"},
    })
gg.toast'Bypass Actived ✅'
end


function rally3()
gg.alert'Test Function'
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)

gg.searchNumber("10", gg.TYPE_FLOAT)
local results = gg.getResults(1000)

local addr_refs = {}
local check_plus4 = {}
for _, r in ipairs(results) do
    check_plus4[#check_plus4 + 1] = { address = r.address + 0x4, flags = gg.TYPE_FLOAT }
    addr_refs[#addr_refs + 1] = r.address
end
local values_plus4 = gg.getValues(check_plus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_plus4) do
    if v.value == 5 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x8, flags = gg.TYPE_FLOAT }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus8 = gg.getValues(candidates)

local edits = {}
for i, v in ipairs(values_plus8) do
    if v.value == 10 then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x24,
            flags = gg.TYPE_DWORD,
            value = 360,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x5C,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.setVisible(false)
gg.toast("Teleporte to finish race ✅")
gg.setVisible(false)
end

function rally4() -- road
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_FLOAT)
local results = gg.getResults(5000)

local addr_refs = {}
local check_plus4 = {}
for _, r in ipairs(results) do
    check_plus4[#check_plus4 + 1] = { address = r.address + 0x4, flags = gg.TYPE_FLOAT }
    addr_refs[#addr_refs + 1] = r.address
end
local values_plus4 = gg.getValues(check_plus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_plus4) do
    if v.value == 5 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x8, flags = gg.TYPE_FLOAT }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus8 = gg.getValues(candidates)

local edits = {}
for i, v in ipairs(values_plus8) do
    if v.value == 10 then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x20,
            flags = gg.TYPE_DWORD,
            value = 1,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x24,
            flags = gg.TYPE_DWORD,
            value = 360,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x5C,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.setVisible(false)
-- RaceStartTrigger RallyController 0x28
gg.clearResults()
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("15", gg.TYPE_QWORD)
local r = gg.getResults(50000)

local t1 = {}
local t1Refs = {}
for _, v in ipairs(r) do
    t1[#t1+1] = { address = v.address + 0x40, flags = gg.TYPE_DWORD }
    t1Refs[#t1Refs+1] = v.address
end
t1 = gg.getValues(t1)

local t2 = {}
local t2Refs = {}
for i, v in ipairs(t1) do
    if v.value >= 1 and v.value <= 60 then
        t2[#t2+1] = { address = t1Refs[i] - 0xC4, flags = gg.TYPE_DWORD }
        t2Refs[#t2Refs+1] = t1Refs[i]
    end
end

if #t2 == 0 then gg.toast("Nothing 1") return end
t2 = gg.getValues(t2)

local t3 = {}
local t3Refs = {}
for i, v in ipairs(t2) do
    if v.value == 0 then
        t3[#t3+1] = { address = t2Refs[i] - 0xCC, flags = gg.TYPE_QWORD }
        t3Refs[#t3Refs+1] = t2Refs[i]
    end
end

if #t3 == 0 then gg.toast("Nothing 2") return end
t3 = gg.getValues(t3)

local t4 = {}
local t4Refs = {}
for i, v in ipairs(t3) do
    if v.value == 4294967296 then
        t4[#t4+1] = { address = t3Refs[i] - 0xC8, flags = gg.TYPE_DWORD }
        t4Refs[#t4Refs+1] = t3Refs[i]
    end
end

if #t4 == 0 then gg.toast("Nothing 3") return end
t4 = gg.getValues(t4)

local check_minusBC = {}
for i = 1, #t4Refs do
    check_minusBC[#check_minusBC+1] = { address = t4Refs[i] - 0xBC, flags = gg.TYPE_DWORD }
end
local values_minusBC = gg.getValues(check_minusBC)

local check_plus104 = {}
for i = 1, #t4Refs do
    check_plus104[#check_plus104+1] = { address = t4Refs[i] + 0x3C, flags = gg.TYPE_DWORD }
end
local values_plus104 = gg.getValues(check_plus104)

local e = {}
for i, v in ipairs(t4) do
    if v.value == 1 then
        if (values_minusBC[i].value == 109 or values_minusBC[i].value == 111 or values_minusBC[i].value == 118) and
           (values_plus104[i].value == 109 or values_plus104[i].value == 111 or values_plus104[i].value == 118) then
            e[#e+1] = {
                address = t4Refs[i] - 0xC8,
                flags = gg.TYPE_DWORD,
                value = 3,
                freeze = true
            }
        end
    end
end

if #e == 0 then gg.toast("Nothing 4") return end

gg.addListItems(e)
gg.clearResults()
gg.clearList()
gg.setVisible(false)
rally2()
gg.toast('Auto Win On ✅')
end

function rally5() --japan
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_FLOAT)
local results = gg.getResults(1000)

local addr_refs = {}
local check_plus4 = {}
for _, r in ipairs(results) do
    check_plus4[#check_plus4 + 1] = { address = r.address + 0x4, flags = gg.TYPE_FLOAT }
    addr_refs[#addr_refs + 1] = r.address
end
local values_plus4 = gg.getValues(check_plus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_plus4) do
    if v.value == 5 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x8, flags = gg.TYPE_FLOAT }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus8 = gg.getValues(candidates)

local edits = {}
for i, v in ipairs(values_plus8) do
    if v.value == 10 then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x20,
            flags = gg.TYPE_DWORD,
            value = 1,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x24,
            flags = gg.TYPE_DWORD,
            value = 360,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x5C,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.setVisible(false)
-- RaceStartTrigger RallyController 0x28
gg.clearResults()
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_QWORD)
local r = gg.getResults(30000)

local t1 = {}
local t1Refs = {}
for _, v in ipairs(r) do
    t1[#t1+1] = { address = v.address + 0x40, flags = gg.TYPE_DWORD }
    t1Refs[#t1Refs+1] = v.address
end
t1 = gg.getValues(t1)

local t2 = {}
local t2Refs = {}
for i, v in ipairs(t1) do
    if v.value >= 1 and v.value <= 60 then
        t2[#t2+1] = { address = t1Refs[i] - 0xC4, flags = gg.TYPE_DWORD }
        t2Refs[#t2Refs+1] = t1Refs[i]
    end
end

if #t2 == 0 then gg.toast("Nothing") return end
t2 = gg.getValues(t2)

local t3 = {}
local t3Refs = {}
for i, v in ipairs(t2) do
    if v.value == 0 then
        t3[#t3+1] = { address = t2Refs[i] - 0xCC, flags = gg.TYPE_QWORD }
        t3Refs[#t3Refs+1] = t2Refs[i]
    end
end

if #t3 == 0 then gg.toast("Nothing") return end
t3 = gg.getValues(t3)

local t4 = {}
local t4Refs = {}
for i, v in ipairs(t3) do
    if v.value == 4294967296 then
        t4[#t4+1] = { address = t3Refs[i] - 0xC8, flags = gg.TYPE_DWORD }
        t4Refs[#t4Refs+1] = t3Refs[i]
    end
end

if #t4 == 0 then gg.toast("Nothing") return end
t4 = gg.getValues(t4)

local check_minusBC = {}
for i = 1, #t4Refs do
    check_minusBC[#check_minusBC+1] = { address = t4Refs[i] - 0xBC, flags = gg.TYPE_DWORD }
end
local values_minusBC = gg.getValues(check_minusBC)

local check_plus104 = {}
for i = 1, #t4Refs do
    check_plus104[#check_plus104+1] = { address = t4Refs[i] + 0x3C, flags = gg.TYPE_DWORD }
end
local values_plus104 = gg.getValues(check_plus104)

local e = {}
for i, v in ipairs(t4) do
    if v.value == 1 then
        if (values_minusBC[i].value == 109 or values_minusBC[i].value == 111 or values_minusBC[i].value == 118) and
           (values_plus104[i].value == 109 or values_plus104[i].value == 111 or values_plus104[i].value == 118) then
            e[#e+1] = {
                address = t4Refs[i] - 0xC8,
                flags = gg.TYPE_DWORD,
                value = 3,
                freeze = true
            }
        end
    end
end

if #e == 0 then gg.toast("Nothing") return end

gg.addListItems(e)
gg.clearResults()
gg.clearList()
gg.setVisible(false)
rally2()
gg.toast('Auto Win On ✅')
end

function rally6()-- italy
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("10", gg.TYPE_FLOAT)
local results = gg.getResults(1000)

local addr_refs = {}
local check_plus4 = {}
for _, r in ipairs(results) do
    check_plus4[#check_plus4 + 1] = { address = r.address + 0x4, flags = gg.TYPE_FLOAT }
    addr_refs[#addr_refs + 1] = r.address
end
local values_plus4 = gg.getValues(check_plus4)

local candidates = {}
local candidate_refs = {}
for i, v in ipairs(values_plus4) do
    if v.value == 5 then
        candidates[#candidates + 1] = { address = addr_refs[i] + 0x8, flags = gg.TYPE_FLOAT }
        candidate_refs[#candidate_refs + 1] = addr_refs[i]
    end
end

if #candidates == 0 then gg.toast("error") return end

local values_plus8 = gg.getValues(candidates)

local edits = {}
for i, v in ipairs(values_plus8) do
    if v.value == 10 then
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x20,
            flags = gg.TYPE_DWORD,
            value = 1,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x24,
            flags = gg.TYPE_DWORD,
            value = 360,
            freeze = true
        }
        edits[#edits + 1] = {
            address = candidate_refs[i] + 0x5C,
            flags = gg.TYPE_FLOAT,
            value = 0.00100000005,
            freeze = true
        }
    end
end

if #edits == 0 then gg.toast("error") return end

gg.addListItems(edits)
gg.clearResults()
gg.setVisible(false)
-- RaceStartTrigger RallyController 0x28
gg.clearResults()
gg.setVisible(false)
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("14", gg.TYPE_QWORD)
local r = gg.getResults(30000)

local t1 = {}
local t1Refs = {}
for _, v in ipairs(r) do
    t1[#t1+1] = { address = v.address + 0x40, flags = gg.TYPE_DWORD }
    t1Refs[#t1Refs+1] = v.address
end
t1 = gg.getValues(t1)

local t2 = {}
local t2Refs = {}
for i, v in ipairs(t1) do
    if v.value >= 1 and v.value <= 60 then
        t2[#t2+1] = { address = t1Refs[i] - 0xC4, flags = gg.TYPE_DWORD }
        t2Refs[#t2Refs+1] = t1Refs[i]
    end
end

if #t2 == 0 then gg.toast("Nothing") return end
t2 = gg.getValues(t2)

local t3 = {}
local t3Refs = {}
for i, v in ipairs(t2) do
    if v.value == 0 then
        t3[#t3+1] = { address = t2Refs[i] - 0xCC, flags = gg.TYPE_QWORD }
        t3Refs[#t3Refs+1] = t2Refs[i]
    end
end

if #t3 == 0 then gg.toast("Nothing") return end
t3 = gg.getValues(t3)

local t4 = {}
local t4Refs = {}
for i, v in ipairs(t3) do
    if v.value == 4294967296 then
        t4[#t4+1] = { address = t3Refs[i] - 0xC8, flags = gg.TYPE_DWORD }
        t4Refs[#t4Refs+1] = t3Refs[i]
    end
end

if #t4 == 0 then gg.toast("Nothing") return end
t4 = gg.getValues(t4)

local check_minusBC = {}
for i = 1, #t4Refs do
    check_minusBC[#check_minusBC+1] = { address = t4Refs[i] - 0xBC, flags = gg.TYPE_DWORD }
end
local values_minusBC = gg.getValues(check_minusBC)

local check_plus104 = {}
for i = 1, #t4Refs do
    check_plus104[#check_plus104+1] = { address = t4Refs[i] + 0x3C, flags = gg.TYPE_DWORD }
end
local values_plus104 = gg.getValues(check_plus104)

local e = {}
for i, v in ipairs(t4) do
    if v.value == 1 then
        if (values_minusBC[i].value == 109 or values_minusBC[i].value == 111 or values_minusBC[i].value == 118) and
           (values_plus104[i].value == 109 or values_plus104[i].value == 111 or values_plus104[i].value == 118) then
            e[#e+1] = {
                address = t4Refs[i] - 0xC8,
                flags = gg.TYPE_DWORD,
                value = 3,
                freeze = true
            }
        end
    end
end

if #e == 0 then gg.toast("Nothing") return end

gg.addListItems(e)
gg.clearResults()
gg.setVisible(false)
rally2()
gg.toast('Auto Win On ✅')
end

function rally7()
-- RallyController 0x30
getField("RallyController", 0x28, gg.TYPE_DWORD)
gg.refineNumber('1~4', gg.TYPE_DWORD)

local r = gg.getResults(500)
local e = {}

for _,v in ipairs(r) do
    e[#e+1] = {
        address = v.address,
        flags = gg.TYPE_DWORD,
        value = 3,
        freeze = true
    }
end

gg.addListItems(e)
gg.clearResults()
gg.setVisible(false)
rally2()
gg.toast('Bypass On ✅')
end



function hook5()
gg.setVisible(false)
local ranges = gg.getRangesList("libil2cpp.so")
if not ranges or #ranges < 2 then
    gg.toast("nothing found")
    return
end
local libil2cpp = ranges[2].start

function setvalue(address, flags, value)
    local vdata = { address = address, flags = flags, value = value, freeze = true }
    gg.addListItems({vdata})
    gg.removeListItems({vdata})
end

-- IsCheatFinish~LapRaceCar
setvalue(libil2cpp + 0x3BC25D0, gg.TYPE_DWORD, -763363328)
setvalue(libil2cpp + 0x3BC25D0 + 0x4, gg.TYPE_DWORD, -698416192)
gg.toast'Bypass Actived ✅'
end








function menubypassgb()
    UnlockKinz = gg.choice({
      "『༒BYPASS UNLOCK ALL GEARBOX༒』",
       "『༒BYPASS ALL PART ENGINE ༒』",
        "『༒BYPASS ALL ENGINE COMPATIBLE༒』",
         "『༒BYPASS SERVICE TIME ༒』",
          "『༒BYPASS DETECT ENGINE AND GEARBOX༒』",
      "『༒BACK⌦ ༒』"
    }, nil, title)
    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end


      if UnlockKinz == 1 then unlockallgb() end
      if UnlockKinz == 2 then unlcokpartenmgine() end
      if UnlockKinz == 3 then bypassenginecomp() end
      if UnlockKinz == 4 then bypasseservvicetrime() end
      if UnlockKinz == 5 then buyefasf() end
      if UnlockKinz == 6 then HomeMenu() end
      end




function unlockallgb()
   gg.alert("BUY ENGINE AND CLIK GG LOGO")
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_CODE_APP)
gg.setVisible(false)
gg.searchNumber("-1746402792", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
gg.refineNumber("-1746402792", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
    local LibStart = gg.getRangesList('libil2cpp.so')[2].start

 gg.setValues({ -- table(8558382)
	[1] = { -- table(c4f3ad0)
		['address'] = LibStart + 0x3097E94,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-2999674700105252864',
	},
	[2] = { -- table(306ca93)
		['address'] = LibStart + 0x3097E94 + 4,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-6266943638792633408',
	},
})
gg.clearList()
gg.clearResults()
gg.toast("on")
gg.setVisible(false)
end

function unlcokpartenmgine()
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_CODE_APP)
gg.setVisible(false)
gg.searchNumber("-1746937010", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.refineNumber("-1746937010", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.getResults(10)
--[[ count: 1 ]]
    local LibStart = gg.getRangesList('libil2cpp.so')[2].start

gg.setValues({ -- table(dec97eb)
	[1] = { -- table(5ffc3e1)
		['address'] =  LibStart  + 0x37C6F2C,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-2999674700105252864',
	},
	[2] = { -- table(ec87948)
		['address'] =  LibStart + 0x37C6F2C + 4,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '3026704770378171328',
	},
})
gg.clearList()
gg.clearResults()
gg.toast("on")
gg.setVisible(false)
end

function bypassenginecomp()

    local LibStart = gg.getRangesList('libil2cpp.so')[2].start
gg.setVisible(false)
gg.clearResults()
gg.clearList()
gg.clearResults()
gg.clearList()
gg.setRanges(gg.REGION_CODE_APP)
gg.setVisible(false)
gg.searchNumber("-1746402792", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.refineNumber("-1746402792", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.getResults(10)
--[[ count: 1 ]]
gg.setValues({ -- table(c1742a0)
	[1] = { -- table(baaa1e)
		['address'] =  LibStart+ 0x30A19DC,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-2999674700105252864',
	},
	[2] = { -- table(3f44e59)
		['address'] = LibStart + 0x30A19DC + 4,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-2999674700105252864',
	},
})
gg.clearList()
gg.clearResults()
gg.alert("GO TO LEVEL ANDA BACK MENU")
--[[ return: 1 ]]
gg.toast("DONE")
gg.setVisible(false)
end




function bypasseservvicetrime()

    local LibStart = gg.getRangesList('libil2cpp.so')[2].start
gg.alert("TURN OF STUCK O%")
--[[ return: 1 ]]
gg.getRangesList("libil2cpp.so")
gg.addListItems({ -- table(bcecee5)
	[1] = { -- table(4360dba)
		['address'] = libstart + 0x37CD444,
		['flags'] = 4, -- gg.TYPE_DWORD
		['freeze'] = true,
		['freezeType'] = 0, -- gg.FREEZE_NORMAL
		['value'] = '-763363328',
	},
})
gg.getRangesList("libil2cpp.so")
gg.addListItems({ -- table(5fd9bc8)
	[1] = { -- table(7227461)
		['address'] = libstart + 0x37CD444 + 4,
		['flags'] = 4, -- gg.TYPE_DWORD
		['freeze'] = true,
		['freezeType'] = 0, -- gg.FREEZE_NORMAL
		['value'] = '-698416192',
	},
})
gg.clearList()
gg.clearResults()
gg.toast("✅ on ")
gg.setVisible(false)
end


function buyefasf()

    local LibStart = gg.getRangesList('libil2cpp.so')[2].start
gg.searchNumber("-1747481233", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.refineNumber("-1747481233", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
--[[ found: 1 ]]
gg.getResults(10)
--[[ count: 1 ]]
gg.setValues({ -- table(9f2746a)
	[1] = { -- table(16999f8)
		['address'] =  LibStart + 0x3A3E624,
		['flags'] = 4, -- gg.TYPE_DWORD
		['value'] = '-698416192',
	},
	[2] = { -- table(fb00d5b)
		['address'] = LibStart + 0x3A3E624 + 4,
		['flags'] = 32, -- gg.TYPE_QWORD
		['value'] = '-6266059601379130432',
	},
})
gg.clearList()
gg.clearResults()
gg.alert("GO TO LEVEL AND BACK MENU")
--[[ return: 1 ]]
gg.toast("DONE")
gg.setVisible(false)

end




function menu_modifications()
    UnlockKinz = gg.choice({
      "『༒0% tires༒』",
      "『༒100% tires༒』",
      "『༒0% tires༒』",
      "『📁BUMBER MENU༒』",
      "『༒BACK⌦ ༒』"
    }, nil, title)
    if UnlockKinz == nil then
        gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
    end


      if UnlockKinz == 1 then lastik100() end
      if UnlockKinz == 2 then lastik0() end
         if UnlockKinz == 3 then unlockTires() end
      if UnlockKinz == 4 then Menu_Bumper() end
      if UnlockKinz == 5 then HomeMenu() end
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
        "How to use:\n1️⃣ Garage ON → 2️⃣ Enter lobby → 3️⃣ Logo shows King Rank (temporary)\n\n✅ Done!"
    )
    gg.sleep(100)
    -- OFF_LogoRank = 0x31F9470
    SecreDevPatch({
        {0x0, "hC00080D2"}, -- MOV X0, #6 (King)
        {0x4, "hC0035FD6"}, -- RET
    }, OFF_LogoRank)
    gg.toast("༒ON༒")
end

function Logo2() --- YouTube Rank
    gg.alert("📌 YouTube RANK LOGO (Temporary) 📌\nGarage ON → Enter lobby → temporary YouTube logo")
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "h000180D2"},
        {0x4, "hC0035FD6"},
    }, OFF_LogoRank)
    gg.toast("༒ON༒")
end

function Logo3() --- TikTok Rank
    gg.alert("📌 TikTok RANK LOGO (Temporary) 📌\nGarage ON → Enter lobby → temporary TikTok logo")
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "h200180D2"},
        {0x4, "hC0035FD6"},
    }, OFF_LogoRank)
    gg.toast("༒ON༒")
end

function Logo4() --- Instagram Rank
    gg.alert("📌 Instagram RANK LOGO (Temporary) 📌\nGarage ON → Enter lobby → temporary Instagram logo")
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "h400180D2"},
        {0x4, "hC0035FD6"},
    }, OFF_LogoRank)
    gg.toast("༒ON༒")
end

function Logo5() --- Developer Rank
    gg.alert("📌 Developer RANK LOGO (Temporary) 📌\nGarage ON → Enter lobby → temporary Developer logo")
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "hE00080D2"},
        {0x4, "hC0035FD6"},
    }, OFF_LogoRank)
    gg.toast("༒ON༒")
end










-- OFF_SlotMod = 0x38567F4 + 0xC0
function slotmod()
    -- ON (unlock)
    SecreDevPatch({
        {0x0, "h 94 02 80 52"},
    }, OFF_SlotMod)
    gg.toast("UNLOCK SLOT")

    while true do
        if gg.isVisible() then break end
    end
    gg.setVisible(false)

    -- restore
    SecreDevPatch({
        {0x0, "h F4 03 00 2A"},
    }, OFF_SlotMod)
    gg.toast("VALUE ARE RESTORE")
end

function ThirtyTwoSlots()
    gg.setVisible(false)
    libs = gg.getRangesList("libil2cpp.so")[2].start
    local target = libs + OFF_SlotMod
    local originalHex = "2A0003F4"
    local patchHex = "52800294"
    local currentHex = gg.getValues({{address = target, flags = gg.TYPE_DWORD}})[1].value

    if currentHex == tonumber("0x" .. patchHex) then
        SecreDevPatch({{0x0, tonumber("0x" .. originalHex)}}, OFF_SlotMod)
        gg.toast("🔴 SlotMod OFF (Restored)")
    else
        SecreDevPatch({{0x0, tonumber("0x" .. patchHex)}}, OFF_SlotMod)
        gg.toast("🟢 SlotMod ON")
    end
end

-- OFF_WheelUnlock = 0x34C399C
function wheelUnlock()
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "h20008052"}, -- MOV W0, #1
        {0x4, "hC0035FD6"}, -- RET
    }, OFF_WheelUnlock)
    gg.toast("Coin Wheels Unlocked!")
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
    -- OFF_IsBought_Police = 0x39C682C
    -- public override bool IsBought(CarInfo carInfo)
    SecreDevPatch({
        {0x0, "~A8 MOV  X0, #0x1"},
        {0x4, "~A8 RET"},
    }, OFF_IsBought_Police)
    gg.toast('✅ unlock police')
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
    -- OFF_IsBought_Police = 0x39C682C
    SecreDevPatch({
        {0x0, "D2800020h"},
        {0x4, "D65F03C0h"},
    }, OFF_IsBought_Police)

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





function hasHouse() --- House Unlock
    -- OFF_hasHouse = 0x3256CB8
    -- private bool hasHouse(int check)
    gg.sleep(100)
    SecreDevPatch({
        {0x0, "D2800020h"}, -- MOV X0, #1
        {0x4, "D65F03C0h"}, -- RET
    }, OFF_hasHouse)
    gg.toast("༒ON༒")
end

function paint()
    gg.toast("༒OWNER༒:『Kinzi』")
    gg.sleep(100)
    -- OFF_Paint_A/B/C
    SecreDevPatch({
        {0x0, "~A8 MOV  X0, #0x1"},
        {0x4, "~A8 RET"},
    }, OFF_Paint_A)
    SecreDevPatch({
        {0x0, "~A8 MOV  X0, #0x1"},
        {0x4, "~A8 RET"},
    }, OFF_Paint_B)
    SecreDevPatch({
        {0x0, "~A8 MOV  X0, #0x1"},
        {0x4, "~A8 RET"},
    }, OFF_Paint_C)
    gg.toast("Paint unlocked")
    gg.toast("༒ON༒")
end

function bodykit() --- Bodykit Unlock
    gg.toast("༒OWNER༒:『Kinzi』")
    gg.sleep(100)
    -- OFF_Bodykit_CoinPrice = 0x38F7718  GetCoinPriceForKit
    SecreDevPatch({
        {0x0, "~A8 MOV  X0, #0x1"},
        {0x4, "~A8 RET"},
    }, OFF_Bodykit_CoinPrice)
    -- OFF_Bodykit_MoneyPrice = 0x37E0098
    SecreDevPatch({
        {0x0, "h000080D2"},
        {0x4, "hC0035FD6"},
    }, OFF_Bodykit_MoneyPrice)
    -- OFF_Bodykit_Extra = 0x37DF3B8
    SecreDevPatch({
        {0x0, "-2999674700105252832"},
    }, OFF_Bodykit_Extra)
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
      if UnlockKinz == 9 then volkswagenscirocco() end
      if UnlockKinz == 10 then HomeMenu() end
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





function Menu_bypassmenu()   UnlockKinz = gg.choice({
      "『༒ID Changer༒』",--1
      "『༒bypass server༒』",--1
      "『༒check password༒』",--1
      "『༒bypass unlock all gearbox༒』",--1
      "『༒bypass all part engine ༒』",--1
      "『༒bypass all engine compatible ༒』",--1
      "『༒bypass service time ༒』",--1
      "『༒bypass use no detect engine and gearbox ༒』",--1
         "『༒BACK⌦ ༒』"--7
        },nil , title)
      if UnlockKinz == nil then
gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
return
end
      if UnlockKinz == 1 then IDChanger() end
      if UnlockKinz == 2 then bypassserver() end
      if UnlockKinz == 3 then checkpassword() end
      if UnlockKinz == 4 then Bypassserver22() end
      if UnlockKinz == 5 then bypassgearbox() end
      if UnlockKinz == 6 then bypassengine1() end
      if UnlockKinz == 7 then bypassgengine() end
      if UnlockKinz == 8 then bypassgtime() end
      if UnlockKinz == 9 then bypassgdetece() end
      if UnlockKinz == 10 then HomeMenu() end
      end



      
function bypassgdetece()
 gg.alert("TURN OF STUCK O%")

gg.sleep(1000)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil
KINZI={}
KINZI[1]={}
KINZI[2]={}
KINZI[1].address=LibStart+0x3A3D794 
KINZI[1].value='-6261837476728470592'
KINZI[1].flags=4
KINZI[2].address=LibStart+(0x3A3D794+0xCB0)
KINZI[2].value='-6266059601379130432'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.alert("on")

end
      
function bypassgtime()
 gg.alert("TURN OF STUCK O%")

gg.sleep(1000)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil
KINZI={}
KINZI[1]={}
KINZI[2]={}
KINZI[1].address=LibStart+(0x37CD444+0x4)
KINZI[1].value='-2999674700105252864'
KINZI[1].flags=4
KINZI[2].address= LibStart+0x37CD444 
KINZI[2].value='-6266943638792633408'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.alert("on")

end



function bypassgengine()
   gg.alert("BUY ENGINE AND CLIK GG LOGO")

gg.sleep(1000)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil
KINZI={}
KINZI[1]={}
KINZI[2]={}
KINZI[1].address=LibStart+0x30A19EC 
KINZI[1].value='-2999674700105252864'
KINZI[1].flags=4
KINZI[2].address=LibStart+(0x30A19EC+0x4)
KINZI[2].value='5334513760543441352'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.alert("GO TO LEVEL ANDA BACK MENU")

gg.toast("DONE")

end

function bypassengine1()
gg.sleep(1000)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil
KINZI={}
KINZI[1]={}
KINZI[2]={}
KINZI[1].address=LibStart+0x37C3DA0 
KINZI[1].value='-2999674700105252864'
KINZI[1].flags=4
KINZI[2].address=LibStart+(0x37C3DA0+0x4)
KINZI[2].value='-3026704770378171328'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.toast("on")
end

function bypassgearbox()
gg.sleep(1000)
LibStart=gg.getRangesList('libil2cpp.so')[2].start
KINZI=nil
KINZI={}
KINZI[1]={}
KINZI[2]={}
KINZI[1].address=LibStart+0x358375 
KINZI[1].value='-2999674700105252864'
KINZI[1].flags=4
KINZI[2].address=LibStart+(0x358375+0x4)
KINZI[2].value='-6266943638792633408'
KINZI[2].flags=4
gg.setValues(KINZI)
gg.toast("on")
end



function checkpassword()
gg.alert(
    "📌 CHECK PASSWORD 📌\n\n" ..
    "This function helps you find possible room passwords in the range of 1 to 9999.\n\n" ..
    "When you activate this function:\n" ..
    "🔍 It searches for potential room passwords and displays them in a list.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Tap this function to start the search.\n" ..
    "2️⃣ Wait for the results to appear in a popup alert.\n\n" ..
    "✅ Done!"
)


gg.setVisible(false)
gg.clearResults()
gg.clearList()
valueFromClass("RoomDataItem", "0x8C", false, false, gg.TYPE_DWORD)
        gg.getResults(9999)
        gg.refineNumber("1~9999", gg.TYPE_DWORD)
        local results = gg.getResults(9999)

        local values = {}
        for i, v in ipairs(results) do
            table.insert(values, v.value)
        end

        local valuesStr = table.concat(values, ", ")

        if #values > 0 then
            gg.alert("Possible room passwords are: (" .. valuesStr .. ")")
        else
            gg.alert("No possible passwords found in the range 1~9999.")
        end

        gg.clearResults()
        stopClose()
gg.toast("ON")
end



function bypassserver()
    gg.sleep(100)
    -- OFF_IsBlackVehicle = 0x380CA48
    -- public static bool IsBlackVehicle()
    SecreDevPatch({
        {0x0, "D2800020h"},
        {0x4, "D65F03C0h"},
    }, OFF_IsBlackVehicle)
    gg.toast("༒ON༒")
    gg.sleep(1000)
end




function IDChanger()
   gg.alert(
    "📌 I.D CHANGER 📌\n\n" ..
    "This function gives you a new random in-game ID each time you turn it ON.\n\n" ..
    "When you activate this function:\n" ..
    "🆔 Your account ID will be replaced with a new one.\n" ..
    "🔄 Turning it OFF will only stop the changer, it will not return your previous ID.\n\n" ..
    "How to use:\n" ..
    "1️⃣ Enter the lobby.\n" ..
    "2️⃣ Activate 『I.D Changer』 to generate a new random ID.\n" ..
    "3️⃣ Each activation gives a different ID.\n\n" ..
    "⚠️ NOTE: Once changed, your old ID cannot be restored automatically.\n\n" ..
    "✅ Done!"
)

    gg.setVisible(false)
    -- OFF_IDChanger = 0x6A34BF0 + 0x9C  (SetString)
    libs = gg.getRangesList("libil2cpp.so")[2].start
    local target = libs + OFF_IDChanger
    local movW8WZR = 0x2A1F03E0  -- MOV W8, WZR
    local original = 0x944B2C92

    local current = gg.getValues({{address = target, flags = gg.TYPE_DWORD}})[1].value

    if current == movW8WZR then
        SecreDevPatch({{0x0, original}}, OFF_IDChanger)
        gg.toast("🟢 I.D Changer OFF (Restored)")
    else
        SecreDevPatch({{0x0, movW8WZR}}, OFF_IDChanger)
        gg.toast("🔴 I.D Changer ON ")
    end
end



























function Menu_duplication()
   gg.alert("under maintenance")
end

function Menu_Achievement()
      wchrome54 = gg.choice({
        "『📁༒Achievements 1༒』",
        "『📁༒Achievements 2༒』",
        "『༒BACK⌦ ༒』"
      }, nil, title)
      if wchrome54 == nil then
    gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
      end
      if wchrome54 == 1 then achievements1Menu() end
      if wchrome54 == 2 then achievements2Menu() end
      if wchrome54 == 3 then HomeMenu() end
    end

 function achievements1Menu()
      local choice = gg.choice({
        "『༒Parking Mission༒』",
        "『༒Taxi + Delivery + Cargo༒』",
        "『༒BACK⌦ ༒』"
      }, nil, title)
      if choice == nil then
    gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
        return
      end
  
      if choice == 1 then parkingMission()
      elseif choice == 2 then taxiDeliveryCargo()
      elseif choice == 3 then Menu_Achievement() end
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

    function taxiDeliveryCargo()
        
gg.sleep(100)
      local base = gg.getRangesList('libil2cpp.so')[2].start
      local KINZI = {
        {address = base + 0x34121D4, value = '528BF520h'},
        {address = base + 0x34121D4+4, value = '72AB0C60h'},
        {address = base + 0x34121DC, value = '1E270000h'},
        {address = base + 0x34121DC+4, value = 'D65F03C0h'}
      }
      for _, v in ipairs(KINZI) do v.flags = 4 end
      gg.setValues(KINZI)
      gg.toast("Activated")
      gg.alert("Complete one task each from Taxi, Delivery and Cargo missions.")
       gg.toast("༒ON༒")
    end


   function achievements2Menu()
      local options = {
         "『༒Car Wash(Car Wash) ༒』",
         "『༒Emotions(Expressions) ༒』",
         "『༒Fuel Consumed(Fuel) ༒』",
         "『༒Tire Burnt(Tires) ༒』",
         "『༒Police (Police༒』",
         "『༒Car Repair(Mechanic) ༒』",
         "『༒Drag Wins(Racing) ༒』",
         "『༒Speed Banner(Speed) ༒』",
         "『༒Block Post(Security) ༒』",
         "『༒Distance Session(Road King) ༒』",
         "『༒Distance Drifted(Drift King) ༒』",
         "『༒Distance Offroad Travelled(Offroad) ༒』",
         "『༒Distance Current Drifted (Drift Master)༒』",
         "『༒Distance  (Marathon)༒』",
         "『༒Mileage Passenger Move Person(Passenger) ༒』",
         "『༒Level (Time)༒』",
         "『༒BACK⌦ ༒』"
      }
      local selected = gg.multiChoice(options, nil, title)
      if selected == nil then
         gg.toast("ᴍᴇɴᴜ ᴄᴀɴᴄᴇʟʟᴇᴅ \n  ")
         return
      end
      if selected[1] then carWash() end
      if selected[2] then emotions() end
      if selected[3] then fuelConsumed() end
      if selected[4] then tireBurnt() end
      if selected[5] then police() end
      if selected[6] then carRepair() end
      if selected[7] then dragWins() end
      if selected[8] then speedBanner() end
      if selected[9] then blockPost() end
      if selected[10] then distanceSession() end
      if selected[11] then distanceDrifted() end
      if selected[12] then distanceOffroadTravelled() end
      if selected[13] then distanceCurrentDrifted() end
      if selected[14] then distanceCurrentDriftedTouchMovePerson() end
      if selected[15] then mileagePassengerMovePerson() end
      if selected[16] then levelAnalyticWheres() end
      if selected[17] then Menu_Achievement() end
   end


  -- if (valueType == gg.TYPE_BYTE or valueType == gg.TYPE_DWORD or valueType == gg.TYPE_QWORD or valueType == gg.TYPE_FLOAT or valueType == gg.TYPE_DOUBLE) then
  
function carWash()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x1B8", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
   gg.toast("༒ON༒")
end

function emotions()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x208", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
      gg.toast("༒ON༒")
end

function fuelConsumed()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x190", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
gg.toast("༒ON༒")
end

function tireBurnt()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x17C", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function police()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x140", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function carRepair()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x1E0", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function dragWins()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x12C", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function speedBanner()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0x104", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function blockPost()
     
gg.sleep(100)
  valueFromClass("FreeDriveDB", "0xDC", false, false, gg.TYPE_QWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_QWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function distanceSession()
     
gg.sleep(100)
  valueFromClass("Powertrain", "0x144", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function distanceDrifted()
     
gg.sleep(100)
  valueFromClass("Powertrain", "0x15C", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function distanceOffroadTravelled()
     
gg.sleep(100)
  valueFromClass("Powertrain", "0x174", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end

function distanceCurrentDrifted()
     
gg.sleep(100)
  valueFromClass("Powertrain", "0x18C", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end



function distanceCurrentDriftedTouchMovePerson()
     
gg.sleep(100)
valueFromClass("TouchMovePerson", "0xF4", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end



function mileagePassengerMovePerson()
     
gg.sleep(100)
valueFromClass("TouchMovePerson", "0x130", false, false, gg.TYPE_DWORD)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_DWORD
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end




function levelAnalyticWheres()
     
gg.sleep(100)
valueFromClass("AnalyticWheres", "0x60", false, false, gg.TYPE_FLOAT)
  local KINZI = gg.getResults(100)
  for i, v in pairs(KINZI) do
    v.value = 9999
    v.flags = gg.TYPE_FLOAT
  end
  gg.setValues(KINZI)
  gg.clearResults()
  gg.clearList()
  gg.toast("༒ON༒")
end










function Menu_Money()
    gg.alert(
        "📌 HOW TO USE 📌\n\n" ..
        "1️⃣ Find the 💰 Money logo\n" ..
        "2️⃣ Wait until it’s activated\n" ..
        "3️⃣ Tap the 💰 Money logo to add money\n\n" ..
        "✅ Finished!"
    )
    -- OFF_GetFloat_Money = 0x2F1A554  public static float GetFloat(...)
    SecreDevPatch({
        {0x0, 1385091872},
        {0x4, 1924125376},
        {0x8, 505872384},
        {0xC, -698416192},
    }, OFF_GetFloat_Money)
    gg.toast("Instant Money Activated")
end






 

function exit()
running = false
end

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


