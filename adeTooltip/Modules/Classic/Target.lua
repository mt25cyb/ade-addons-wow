------------------------------------------------------------
-- 目標行（目標: XXX）與「被誰關注」
--
-- 行的參照存自己的 state，不寫 tip 欄位。輪詢走 Skin.Poll 的共用 ticker。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local L = ns.L or {}
local Skin = ns.Skin
local Lines = ns.Lines
local Colors = ns.Colors
local UnitInfo = ns.UnitInfo

local YOU, TARGET = YOU, TARGET

ns.Target = {}
local Target = ns.Target

local function GetUnitSettings()
    local db = ns.settings
    if not db or not db.unit then return end
    return db.unit.player, db.unit.npc
end

local function ClassColorCode(unit)
    local _, class = S.SafeCall(UnitClass, unit)
    class = S.SafeValue(class)
    if not class then return end
    local c = RAID_CLASS_COLORS[class]
    if not c then return end
    return "ff" .. Colors.Hex(c.r, c.g, c.b)
end

local function GetTargetString(unit)
    if type(unit) ~= "string" then return end
    if not S.SafeBool(UnitExists, unit) then return end
    local name = S.SafeCall(UnitName, unit)
    if name == nil then return end
    local icon = ""
    do
        local index = S.PlainNumber(S.SafeCall(GetRaidTargetIndex, unit))
        local listed = index and ICON_LIST and ICON_LIST[index]
        if listed then icon = listed .. "0|t" end
    end
    if S.SafeBool(UnitIsUnit, unit, "player") then
        return string.format("|cffff3333>>%s<<|r", string.upper(YOU))
    end
    if S.SafeBool(UnitIsPlayer, unit) then
        local colorCode = ClassColorCode(unit) or "ffffffff"
        return string.format("%s|c%s%s|r", icon, colorCode, name)
    end
    local r, g, b = Colors.UnitColor(unit)
    local hex = Colors.Hex(r, g, b) or "ffffff"
    if S.SafeBool(UnitIsOtherPlayersPet, unit) then
        return string.format("%s|cff%s<%s>|r", icon, hex, name)
    end
    return string.format("%s|cff%s[%s]|r", icon, hex, name)
end

local function UpdateTargetLine(tip, state, targetUnit, relayout)
    if S.IsForbiddenObject(tip) then return end
    local text = targetUnit and GetTargetString(targetUnit) or nil

    local line = state.targetLine
    if line then
        local ok = false
        local name = tip:GetName()
        local n = 0
        local okN, num = pcall(tip.NumLines, tip)
        if okN and not S.IsSecret(num) then n = tonumber(num) or 0 end
        for i = 1, n do
            if _G[name .. "TextLeft" .. i] == line then ok = true break end
        end
        if not ok then line = nil end
    end
    if not line then
        line = Lines.Find(tip, TARGET .. ":")
    end
    state.targetLine = line

    -- 清掃：暴雪的原生「目標:」行晚於 post-call 才填進來（post-call 裡 Find 撲空 ⇒ 我們
    -- AddLine 追加，之後原生行出現 ⇒ 兩行並存，實機截圖實錄）。
    -- 這裡把除 line 之外、以「目標:」開頭的行清掉；秘密文本 PlainText 為 nil，跳過。
    do
        local name = tip:GetName()
        local okN, num = pcall(tip.NumLines, tip)
        local n = (okN and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
        local prefix = TARGET .. ":"
        for i = 2, n do
            local l = _G[name .. "TextLeft" .. i]
            if l and l ~= line then
                local value = S.PlainText(l:GetText())
                if value and value ~= "" and value:find(prefix, 1, true) then
                    pcall(l.SetText, l, nil)
                end
            end
        end
    end

    local changed = false
    if not text then
        if line then
            pcall(line.SetText, line, nil)
            state.targetLine = nil
            changed = true
        end
    else
        local formatted = string.format("%s: %s", TARGET, text)
        if not line then
            pcall(tip.AddLine, tip, formatted)
            local okN, num = pcall(tip.NumLines, tip)
            local n = (okN and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
            state.targetLine = _G[tip:GetName() .. "TextLeft" .. n]
            changed = true
        else
            pcall(line.SetText, line, formatted)
            changed = true
        end
    end

    if changed and relayout and not S.IsForbiddenObject(tip) then
        local ok, shown = pcall(tip.IsShown, tip)
        if ok and shown then pcall(tip.Show, tip) end
    end
end

local function AddTargetedBy(tip, state, mouseover)
    local num = GetNumGroupMembers()
    if num < 1 then return end
    local player, npc = GetUnitSettings()
    if not player or not npc then return end
    local isPlayer = S.SafeBool(UnitIsPlayer, mouseover)
    if isPlayer and not player.showTargetBy then return end
    if not isPlayer and not npc.showTargetBy then return end

    local prefix = IsInRaid() and "raid" or "party"
    local label = S.SafeBool(UnitIsUnit, mouseover, "player") and (L.TARGETING_YOU or "Targeting you") or (L.TARGETED_BY or "Targeted by")
    local count, first = 0, true
    for i = 1, num do
        if S.SafeBool(UnitIsUnit, mouseover, prefix .. i .. "target")
            and not S.SafeBool(UnitIsUnit, prefix .. i, "player") then
            count = count + 1
            if isPlayer or prefix == "party" then
                if first then
                    pcall(tip.AddLine, tip, string.format("%s:", label))
                    first = false
                end
                local roleIcon = UnitInfo.GetRoleIcon(prefix .. i) or ""
                local colorCode = ClassColorCode(prefix .. i) or "ffffffff"
                local name = S.SafeCall(UnitName, prefix .. i)
                if name ~= nil then
                    pcall(tip.AddLine, tip, "   " .. roleIcon .. " |c" .. colorCode .. name .. "|r")
                end
            end
        end
    end
    if count > 0 and not isPlayer and prefix ~= "party" then
        pcall(tip.AddLine, tip, string.format("%s: |cff33ffff%d|r", label, count), nil, nil, nil, true)
    end
end

function Target.OnUnit(tip, state, unit)
    local player, npc = GetUnitSettings()
    if not player or not npc then return end

    local targetUnit
    if S.SafeBool(UnitIsUnit, unit, "player") then
        targetUnit = player.showTarget and "playertarget" or nil
    elseif S.SafeBool(UnitIsUnit, unit, "mouseover") then
        local isPlayer = S.SafeBool(UnitIsPlayer, "mouseover")
        if (isPlayer and player.showTarget) or (not isPlayer and npc.showTarget) then
            targetUnit = "mouseovertarget"
        end
    elseif type(unit) == "string" then
        local isPlayer = S.SafeBool(UnitIsPlayer, unit)
        if (isPlayer and player.showTarget) or (not isPlayer and npc.showTarget) then
            local ok, concat = pcall(function() return unit .. "target" end)
            if ok and S.SafeBool(UnitExists, concat) then
                targetUnit = concat
            end
        end
    end
    UpdateTargetLine(tip, state, targetUnit, false)

    if S.SafeBool(UnitExists, "mouseover") then
        AddTargetedBy(tip, state, "mouseover")
    end
end

function Target.Update(tip, state)
    if not state.unit then return end
    Target.OnUnit(tip, state, state.unit)
end

------------------------------------------------------------
-- 輪詢：mouseover 的目標會一直換，0.2s 更新一次目標行
------------------------------------------------------------
local POLL = 0.2
Skin.Poll("target", POLL, function()
    local tip = GameTooltip
    local state = Skin.Get(tip)
    if not state or not state.isUnitTip then return end
    if S.SafeValue(state.unit) ~= "mouseover" then return end
    if not tip:IsShown() or S.IsForbiddenObject(tip) then return end
    local owner = tip:GetOwner()
    if owner then
        local ok, ownerUnit = pcall(function() return owner.unit end)
        if ok and ownerUnit then return end
        if owner.GetAttribute then
            local okAttr, attrUnit = pcall(owner.GetAttribute, owner, "unit")
            if okAttr and attrUnit then return end
        end
    end
    if not S.SafeBool(UnitExists, "mouseover") then return end
    local player, npc = GetUnitSettings()
    if not player or not npc then return end
    local isPlayer = S.SafeBool(UnitIsPlayer, "mouseover")
    if (isPlayer and player.showTarget) or (not isPlayer and npc.showTarget) then
        UpdateTargetLine(tip, state, "mouseovertarget", true)
    end
end)
