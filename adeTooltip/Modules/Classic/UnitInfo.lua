------------------------------------------------------------
-- 單位資料層（Classic 路線 · C1 字段集）
--
-- 所有「讀」都走 S.* 守衛：UnitName / UnitFactionGroup / UnitIsConnected … 的結果
-- 在 12.1 之後可能是秘密值，不能直接比較 / 當 key / 做算術。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local L = ns.L or {}

ns.UnitInfo = {}
local UnitInfo = ns.UnitInfo

------------------------------------------------------------
-- 性別字串
------------------------------------------------------------
function UnitInfo.GetGender(token)
    local plain = S.SafeValue(token)
    if plain then
        -- UnitSex：1=neuter、2=male、3=female（warcraft wiki）
        if plain == 2 then return L.GENDER_MALE end
        if plain == 3 then return L.GENDER_FEMALE end
    end
    return nil
end

------------------------------------------------------------
-- 職責圖示（C1 先用文字標記，C2 再換真圖標）
------------------------------------------------------------
function UnitInfo.GetRoleIcon(unit)
    local role = S.SafeValue(S.SafeCall(UnitGroupRolesAssigned, unit))
    if role == "TANK" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t" end
    if role == "HEALER" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t" end
    if role == "DAMAGER" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t" end
    return ""
end

------------------------------------------------------------
-- NPC 頭銜：開一條私有隱藏 tooltip 來掃 TextLeft1（不動使用者的 GameTooltip）
------------------------------------------------------------
local titleTip
local function GetTitle(unit)
    if S.IsSecret(unit) then unit = "mouseover" end
    if not titleTip then
        titleTip = CreateFrame("GameTooltip", "ADTTitleScanTip", nil, "GameTooltipTemplate")
        titleTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    titleTip:SetOwner(UIParent, "ANCHOR_NONE")
    titleTip:SetUnit(unit)
    local npcTitle = _G["ADTTitleScanTipTextLeft1"] and _G["ADTTitleScanTipTextLeft1"]:GetText()
    titleTip:Hide()
    if not npcTitle or npcTitle == "" then return end
    local name = S.PlainText((S.SafeCall(UnitName, unit)))
    if name then
        local s, e = string.find(npcTitle, name, 1, true)
        if s and e and e < #npcTitle then
            npcTitle = string.sub(npcTitle, e + 1)
        end
    end
    return (npcTitle:match("^%s*(.-)%s*$"))
end
UnitInfo.GetTitle = GetTitle

------------------------------------------------------------
-- 組裝單位資料
------------------------------------------------------------
function UnitInfo.GetUnitInfo(unit, kind)
    kind = kind or (S.SafeBool(UnitIsPlayer, unit) and "player" or "npc")
    local data = {}
    data.kind = kind
    data.isPlayer, data.isNpc, data.isPlayerControlled =
        S.SafeBool(UnitIsPlayer, unit), S.SafeBool(UnitIsNPC, unit), S.SafeBool(UnitIsPlayerControlled, unit)

    local name, realm = S.SafeCall(UnitName, unit)
    data.name = name
    data.server = realm

    data.statusAFK, data.statusDND, data.statusDC =
        S.SafeBool(UnitIsAFK, unit), S.SafeBool(UnitIsDND, unit), not S.SafeBool(UnitIsConnected, unit)

    local pvpName = S.SafeCall(UnitPVPName, unit)
    if pvpName and pvpName ~= name then data.pvpName = pvpName end

    local gname, grank, gindex, grealm = S.SafeCall(GetGuildInfo, unit)
    if gname then data.guild = gname; data.guildRank = grank end
    -- 第 4 返回值：跨服玩家公會的伺服器名（對照 MiliUI UnitInfo.lua:663）
    if grealm then data.guildRealm = grealm end

    local raid = S.SafeCall(GetRaidTargetIndex, unit)
    if raid then data.raidIcon = raid end

    local role = S.SafeCall(UnitGroupRolesAssigned, unit)
    data.roleIcon = role

    -- ⚠ 第 1 返回是本地化職業名、第 2 是英文文件名（對照 MiliUI UnitInfo.lua:660）。
    -- 本地化名用來配對暴雪原生「專精 職業」行；英文文件名用來上色（RAID_CLASS_COLORS）。
    local className, class = S.SafeCall(UnitClass, unit)
    data.className = className
    data.class = class

    local raceEn = S.SafeCall(UnitRace, unit)
    data.race = raceEn

    data.gender = S.SafeCall(UnitSex, unit)
    data.level = S.SafeCall(UnitLevel, unit)

    if not data.isPlayer then
        local ctype = S.SafeCall(UnitClassification, unit)
        data.classif = ctype
        data.npcTitle = GetTitle(unit)
        data.faction = S.SafeCall(UnitFactionGroup, unit)
        data.classColoredLevel = true
    else
        data.classColoredLevel = true
    end

    return data
end

------------------------------------------------------------
-- 設定 → 哪些欄位要顯示（C1 子集）
------------------------------------------------------------
local function FormatData(unitData, elements)
    local function Show(key, default)
        if elements == nil then return default end
        local v = elements[key]
        if v == nil then v = default end
        return v
    end

    local status, server, guild, className, race, npcTitle, level, title, roleIcon, raidIcon, pvpIcon
    local classColoredLevel = false

    if unitData.isPlayer then
        status = Show("status", true)
        server = Show("server", true)
        guild = Show("guild", true)
        className = Show("className", false)
        pvpIcon = Show("pvpIcon", false)
    else
        status = Show("status", true)
        guild = Show("guild", false)
        className = Show("className", true)
        race = Show("race", true)
        npcTitle = Show("title", true)
        level = Show("level", false)
        classColoredLevel = Show("classColoredLevel", true)
        raidIcon = Show("raidIcon", true)
        roleIcon = Show("roleIcon", false)
        pvpIcon = Show("pvpIcon", false)
    end
    title = Show("title", false)

    return status, server, guild, className, race, npcTitle, level, title, roleIcon, raidIcon, pvpIcon, classColoredLevel
end

------------------------------------------------------------
-- 把多段字串用空格併成一行；最後一個參數若是 |c 著色字串就接在尾端
------------------------------------------------------------
local function JoinRow(...)
    local strings = { ... }
    local result = strings[1]
    local color = strings[#strings]
    for i = 2, #strings - 1 do
        if strings[i] then
            if not result or result == "" then
                result = strings[i]
            else
                result = result .. " " .. strings[i]
            end
        end
    end
    if result == nil then return "" end
    if color then
        if type(color) ~= "string" or string.sub(color, 1, 2) ~= "|c" then
            return result
        end
        return result .. color
    else
        return result
    end
end
UnitInfo.JoinRow = JoinRow

------------------------------------------------------------
-- 組出 GetUnitData：供 UnitLines.Apply 取用
------------------------------------------------------------
-- 階級配色（difficulty by level，照原生 GetCreatureDifficultyColor）。
-- 必須定義在 GetUnitData 之前：Lua 的 local function 不提升，晚定義會被解析成全局 nil。
local function Colors_LevelColor(level)
    local c = GetQuestDifficultyColor and GetQuestDifficultyColor(level) or { r = 1, g = 1, b = 1 }
    return (c.r * 255), (c.g * 255), (c.b * 255)
end

function UnitInfo.GetUnitData(tip, unit, kind)
    local unitData = UnitInfo.GetUnitInfo(unit, kind)
    local data = {
        kind = unitData.kind,
        isPlayer = unitData.isPlayer,
        isNpc = unitData.isNpc,
        isPlayerControlled = unitData.isPlayerControlled,
    }
    local route = unitData.isPlayer and "player" or "npc"
    local normal = ns.db and ns.db.unit and ns.db.unit[route] or {}
    local elements = normal.elements or {}
    if unitData.isPlayerControlled then
        local npc = ns.db and ns.db.unit and ns.db.unit.npc or {}
        for k, v in pairs(npc.elements or {}) do
            if elements[k] == nil then elements[k] = v end
        end
    end
    data.elements = elements

    local status, server, guild, className, race, npcTitle, level, title, roleIcon, raidIcon, pvpIcon, classColoredLevel =
        FormatData(unitData, elements)

    data.guild, data.realm, data.pvpName = unitData.guild, unitData.server, unitData.pvpName
    data.raidIcon, data.roleIcon, data.pvpIcon = raidIcon, roleIcon, pvpIcon
    data.name = unitData.name
    data.className, data.race, data.npcTitle = className, race, npcTitle
    data.classColoredLevel = classColoredLevel
    data.faction, data.classif = unitData.faction, unitData.classif

    -- 性別
    if unitData.gender ~= nil then
        local sex = UnitInfo.GetGender(unitData.gender)
        if sex then data.gender = sex end
    end

    -- 階級
    if level ~= nil then
        local lv = S.PlainNumber(level)
        if lv ~= nil then
            if classColoredLevel then
                local r, g, b = Colors_LevelColor(lv)
                data.level = string.format("|cff%02x%02x%02x%d|r", r, g, b, lv)
            else
                data.level = tostring(lv)
            end
        end
    end

    -- 稱號
    if title and unitData.pvpName then
        data.title = unitData.pvpName
    elseif title and unitData.npcTitle then
        data.title = unitData.npcTitle
    end

    -- 狀態（AFK/DND/DC）
    if status then
        if unitData.statusAFK then
            data.status = L.AFK
        elseif unitData.statusDND then
            data.status = L.DND
        elseif unitData.statusDC then
            data.status = L.DC
        end
    end

    -- 伺服器
    if server then
        data.serverText = S.PlainText(unitData.server)
    end

    return data
end
