------------------------------------------------------------
-- Panel 路径的單位資料層（逐字對照 MiliUI_Tooltip/Modules/UnitInfo.lua）
--
-- 為什麼另開一支、不改 Modules/Classic/UnitInfo.lua：
--   Classic 那支的 GetUnitInfo 回的是舊樣式字段名（guild/server/race/gender 數字/
--   faction），UnitLines.lua（panel=false 兜底）與 Target.lua 都在吃，b015 已實機驗證。
--   Panel/ReadUnit.lua 吃的是參考源那套字段名（guildName/raceName/gender 文字/
--   factionGroup/itemLevel/achievementPoints/mplusScore*/mount*...）。兩套語義不同，
--   分開落地 ⇒ 舊樣式零回歸。這裡把新方法直接掛到同一個 ns.UnitInfo 上（舊方法保留）。
--
-- 秘密值策略完全照參考源：所有 Unit API 走 S.SafeCall/S.SafeValue/S.SafeBool；
-- 需要比較/查表/字串運算先洗成明文；adiagnostic log 全走 ns.logEnabled 守衛。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local L = ns.L or {}
local Colors = ns.Colors

local UnitInfo = ns.UnitInfo or {}
ns.UnitInfo = UnitInfo

local AFK, DND, PLAYER, BOSS, ELITE = AFK, DND, PLAYER, BOSS, ELITE
local MALE, FEMALE = MALE, FEMALE
local RARE = GARRISON_MISSION_RARE
local OFFLINE = FRIENDS_LIST_OFFLINE
local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7

local MEDIA = "Interface\\AddOns\\adeTooltip\\Media\\"

local function Log(fmt, ...)
    if ns.logEnabled and ns.Log then ns.Log(fmt, ...) end
end

------------------------------------------------------------
-- 圖標集（對照 MiliUI UnitInfo.lua:41-69）
------------------------------------------------------------
local function FactionIcon(atlas, w, h, fallback)
    if type(CreateAtlasMarkup) == "function"
        and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        return CreateAtlasMarkup(atlas, w, h)
    end
    return fallback
end

local icons = {
    Alliance   = FactionIcon("questlog-questtypeicon-alliance", 14, 14,
        "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:14:14:0:0:64:64:10:36:2:38|t"),
    Horde      = FactionIcon("questlog-questtypeicon-horde", 14, 14,
        "|TInterface\\TargetingFrame\\UI-PVP-HORDE:14:14:0:0:64:64:4:38:2:36|t"),
    Neutral    = "|TInterface\\Timer\\Panda-Logo:14|t",
    pvp        = "|TInterface\\TargetingFrame\\UI-PVP-FFA:14:14:0:0:64:64:10:36:0:38|t",
    class      = "|TInterface\\TargetingFrame\\UI-Classes-Circles:14:14:0:0:256:256:%d:%d:%d:%d|t",
    questboss  = "|TInterface\\TargetingFrame\\PortraitQuestBadge:0|t",
    friend     = ("|T%sfriend.blp:14:14:0:0:32:32:1:30:2:30|t"):format(MEDIA),
    bnetfriend = "|TInterface\\ChatFrame\\UI-ChatIcon-BattleNet:14:14:0:0:32:32:1:30:2:30|t",
    TANK       = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:0:19:22:41|t",
    HEALER     = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:1:20|t",
    DAMAGER    = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:22:41|t",
}
local mountIconTag = ("|T%smount.tga:14:14:0:0|t"):format(MEDIA)
local mplusIconTag = ("|T%smplus.tga:14:14:0:0|t"):format(MEDIA)
local itemLevelIconTag = ("|T%sitem_level.blp:14:14:0:0|t"):format(MEDIA)
local achievementIconTag = (type(CreateAtlasMarkup) == "function" and CreateAtlasMarkup("storyheader-cheevoicon", 14, 14))
    or "|A:storyheader-cheevoicon:14:14|a"

------------------------------------------------------------
-- 單項讀取（對照 MiliUI UnitInfo.lua:74-212）
------------------------------------------------------------
local function GetRaidIcon(unit)
    local index = S.PlainNumber(S.SafeCall(GetRaidTargetIndex, unit))
    local icon = index and ICON_LIST and ICON_LIST[index]
    if icon then return icon .. "0|t" end
end

local function GetPVPIcon(unit)
    if S.SafeBool(UnitIsPVPFreeForAll, unit) then return icons.pvp end
end

local function GetRoleIconMarkup(unit)
    local role = S.SafeValue(S.SafeCall(UnitGroupRolesAssigned, unit))
    if type(role) == "string" then return icons[strupper(role)] end
end

local function GetClassIcon(class)
    class = S.PlainText(class)
    if not class then return end
    local coords = CLASS_ICON_TCOORDS[strupper(class)]
    if not coords then return end
    local x1, x2, y1, y2 = unpack(coords)
    return format(icons.class, x1 * 256, x2 * 256, y1 * 256, y2 * 256)
end

local function GetQuestBossIcon(unit)
    if UnitIsQuestBoss and S.SafeBool(UnitIsQuestBoss, unit) then return icons.questboss end
end

local function GetFriendIcon(unit)
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    local guid = S.SafeValue(S.SafeCall(UnitGUID, unit))
    if not guid then return end
    if C_FriendList and S.SafeBool(C_FriendList.IsFriend, guid) then
        return icons.friend
    end
    if guid ~= UnitGUID("player") and C_BattleNet and C_BattleNet.GetAccountInfoByGUID then
        local info = S.SafeCall(C_BattleNet.GetAccountInfoByGUID, guid)
        if type(info) == "table" and info.isFriend then
            return icons.bnetfriend
        end
    end
end

local GetUnitSpeedAPI = GetUnitSpeed
local function GetMoveSpeed(unit)
    local _, speed, flightSpeed, swimSpeed = S.SafeCall(GetUnitSpeedAPI, unit)
    if S.SafeBool(UnitIsOtherPlayersPet, unit) then
        -- keep base speed
    elseif S.SafeBool(IsSwimming, unit) then
        speed = swimSpeed
    elseif IsFlying and S.SafeBool(IsFlying, unit) then
        speed = flightSpeed
    end
    speed = S.PlainNumber(speed)
    if not speed or speed == 0 then return end
    return speed / BASE_MOVEMENT_SPEED * 100 + 0.5
end

local function GetTitle(name, pvpName, surname)
    name, pvpName = S.PlainText(name), S.PlainText(pvpName)
    if not name or not pvpName or name == pvpName then return end
    surname = S.PlainText(surname)
    if surname and surname ~= "" then
        local sep = Constants and Constants.CharacterNameSeparatorConsts
            and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "
        local full = name .. sep .. surname
        if full == pvpName then return end
        if string.find(pvpName, full, 1, true) then name = full end
    end
    local pos = string.find(pvpName, name, 1, true)
    local title = pvpName:gsub(name, "", 1)
    title = title:gsub(",", ""):gsub("，", "")
    title = strtrim(title)
    if title == "" then return end
    return title, pos ~= 1
end

local function GetZone(unit, unitname, realm)
    if not IsInGroup() then return end
    unit = S.PlainText(unit)
    unitname = S.PlainText(unitname)
    if not unit or not unitname then return end
    local t, i = string.match(unit, "^(%a+)(%d+)$")
    if t == "raid" then
        return select(7, GetRaidRosterInfo(tonumber(i)))
    end
    if t ~= "party" and not (S.SafeBool(UnitInParty, unit) or S.PlainNumber((S.SafeCall(UnitInRaid, unit)))) then
        return
    end
    local fullname = unitname .. "-" .. tostring(S.PlainText(realm) or "")
    for j = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, zone = GetRaidRosterInfo(j)
        name = S.PlainText(name)
        if name and not string.find(name, "-", 1, true) and name == unitname then
            return zone
        elseif name and string.find(name, "-", 1, true) and name == fullname then
            return zone
        end
    end
end

local function GetMythicPlusScore(unit)
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    if not (C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then return end
    local summary = S.SafeCall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, unit)
    if type(summary) ~= "table" then return end
    local score = S.PlainNumber(summary.currentSeasonScore)
    if not score then return end
    local color = summary.currentSeasonScoreColor or summary.color
    if not color and C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
        color = S.SafeCall(C_ChallengeMode.GetDungeonScoreRarityColor, score)
    end
    local bestLevel
    if type(summary.runs) == "table" then
        for _, run in ipairs(summary.runs) do
            local lv = run and S.PlainNumber(run.bestRunLevel)
            if lv and (not bestLevel or lv > bestLevel) then bestLevel = lv end
        end
    end
    return score, color, bestLevel
end

------------------------------------------------------------
-- 坐騎（對照 MiliUI UnitInfo.lua:217-263）
------------------------------------------------------------
local function AurasAreSecret()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, res = pcall(C_Secrets.ShouldAurasBeSecret)
        if ok and res then return true end
    end
    return false
end
UnitInfo.AurasAreSecret = AurasAreSecret

local function FindMountAura(unit)
    if not (C_MountJournal and C_MountJournal.GetMountFromSpell) then return end
    if AuraUtil and AuraUtil.ForEachAura then
        local auraName, mountID
        local ok = pcall(AuraUtil.ForEachAura, unit, "HELPFUL", nil, function(aura)
            if type(aura) ~= "table" or not aura.spellId then return end
            local mount = C_MountJournal.GetMountFromSpell(aura.spellId)
            if mount then
                auraName, mountID = aura.name, mount
                return true
            end
        end)
        if not ok then auraName, mountID = nil, nil end
        if auraName then return auraName, mountID end
    end
    if AurasAreSecret() then return end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not ok or not aura then break end
            local mountID = C_MountJournal.GetMountFromSpell(aura.spellId)
            if mountID then return aura.name, mountID end
        end
    end
end

local function GetMountInfo(unit)
    if not (C_MountJournal and C_MountJournal.GetMountInfoByID) then return end
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    local auraName, mountID = FindMountAura(unit)
    if not auraName then return end
    local name, isCollected
    if mountID then
        local ok, mountName, _, _, _, _, _, _, _, _, _, collected = pcall(C_MountJournal.GetMountInfoByID, mountID)
        if ok then name, isCollected = mountName, collected end
    end
    return name or auraName, isCollected
end

------------------------------------------------------------
-- 觀察裝等 / 成就點數：非同步快取（對照 MiliUI UnitInfo.lua:270-641）
------------------------------------------------------------
local INSPECT_TTL, INSPECT_INTERVAL, INSPECT_PENDING_TIMEOUT = 900, 1.2, 1.3
local inspect = { cache = {}, pendingGUID = nil, pendingUnit = nil, lastRequestAt = 0, suspendedUntil = 0 }
local achieve = { cache = {}, pendingGUID = nil, lastRequestAt = 0, suspendedUntil = 0 }
UnitInfo.inspectState = inspect
UnitInfo.achieveState = achieve

local function SafeGuid(unit)
    if not S.SafeBool(UnitExists, unit) then return end
    return S.SafeCall(UnitGUID, unit)
end

local function GuidEquals(a, b)
    if a == nil or b == nil then return false end
    if S.IsSecret(a) or S.IsSecret(b) then return false end
    return a == b
end
UnitInfo.GuidEquals = GuidEquals

local function CacheGet(state, unit, field)
    local guid = S.SafeValue(SafeGuid(unit))
    if not guid then return end
    local cached = state.cache[guid]
    if not cached then return end
    if (GetTime() - cached.time) > INSPECT_TTL then
        state.cache[guid] = nil
        return
    end
    return cached[field]
end

local function CachePut(state, guid, field, value)
    guid = S.SafeValue(guid)
    if not guid or type(value) ~= "number" then return end
    state.cache[guid] = { [field] = value, time = GetTime() }
end

local function TruncItemLevel(v)
    local el = ns.settings and ns.settings.unit and ns.settings.unit.player
        and ns.settings.unit.player.elements and ns.settings.unit.player.elements.itemLevel
    local m = 10 ^ (el and el.decimals or 2)
    return floor(v * m) / m
end

local ILVL_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
local TWO_HAND = { INVTYPE_2HWEAPON = true, INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true }

local function SlotItemLevel(unit, slot)
    local link = S.SafeCall(GetInventoryItemLink, unit, slot)
    if S.IsSecret(link) then return end
    if not link or link == "" then
        local id = S.SafeCall(GetInventoryItemID, unit, slot)
        if S.IsSecret(id) or id then return end
        return 0
    end
    local name, _, _, _, _, _, _, _, equipLoc = S.SafeCall(C_Item.GetItemInfo, link)
    if not S.PlainText(name) then return end
    local lv = S.PlainNumber(S.SafeCall(C_Item.GetDetailedItemLevelInfo, link))
    if not lv or lv <= 0 then return end
    return lv, S.PlainText(equipLoc)
end

local function PreciseInspectItemLevel(unit)
    if not (GetInventoryItemLink and GetInventoryItemID and C_Item
        and C_Item.GetDetailedItemLevelInfo and C_Item.GetItemInfo) then return end
    local total = 0
    for _, slot in ipairs(ILVL_SLOTS) do
        local lv = SlotItemLevel(unit, slot)
        if not lv then return nil, slot end
        total = total + lv
    end
    local mh, mhLoc = SlotItemLevel(unit, 16)
    local oh, ohLoc = SlotItemLevel(unit, 17)
    if not mh then return nil, 16 end
    if not oh then return nil, 17 end
    if mh > 0 and oh > 0 then
        total = total + mh + oh
    elseif TWO_HAND[mhLoc] or TWO_HAND[ohLoc] then
        total = total + max(mh, oh) * 2
    else
        total = total + mh + oh
    end
    return total / 16
end

local function InspectDataPresent(unit)
    if not GetInventoryItemLink then return false end
    for slot = 1, 17 do
        local link = S.SafeCall(GetInventoryItemLink, unit, slot)
        if S.IsSecret(link) or (link and link ~= "") then return true end
    end
    local lv = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel
        and S.PlainNumber(S.SafeCall(C_PaperDollInfo.GetInspectItemLevel, unit))
    return (lv and lv > 0) or false
end

local function RoughInspectItemLevel(unit)
    local rough = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel
        and S.PlainNumber(S.SafeCall(C_PaperDollInfo.GetInspectItemLevel, unit))
    if rough and rough > 0 then return rough end
end

local PRECISE_RETRY_EVERY, PRECISE_RETRY_FOR, PRECISE_SETTLE = 0.25, 5, 0.5
local settle = { guid = nil, value = nil, since = 0 }

local function JudgePrecise(unit, guid, precise)
    local now = GetTime()
    if settle.guid ~= guid or settle.value ~= precise then
        settle.guid, settle.value, settle.since = guid, precise, now
        Log("觀察裝等 候選 %.4f，開始計時", precise)
        return
    end
    local held = now - settle.since
    if held < PRECISE_SETTLE then return end
    local rough = RoughInspectItemLevel(unit)
    if not rough or math.abs(precise - rough) < 1 then return precise end
    Log("觀察裝等 自己算=%.4f 跟暴雪整數=%s 對不上（已等 %.1fs）", precise, tostring(rough), held)
    if held < PRECISE_RETRY_FOR then return end
    return rough
end

local function FinalizePrecise(unit, guid, precise)
    local rough = RoughInspectItemLevel(unit)
    if precise and precise > 0 and (not rough or math.abs(precise - rough) < 1) then
        CachePut(inspect, guid, "level", precise)
        return
    end
    if rough then CachePut(inspect, guid, "level", rough) end
end

local settleRecheckQueued = false
local function QueueSettleRecheck(guid)
    if settleRecheckQueued then return end
    settleRecheckQueued = true
    C_Timer.After(PRECISE_RETRY_EVERY, function()
        settleRecheckQueued = false
        if ns.RefreshUnitTip then ns.RefreshUnitTip(guid) end
    end)
end

local function GetUnitItemLevel(unit)
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    if S.SafeBool(UnitIsUnit, unit, "player") and GetAverageItemLevel then
        local average, equipped = S.SafeCall(GetAverageItemLevel)
        equipped, average = S.PlainNumber(equipped), S.PlainNumber(average)
        if equipped and equipped > 0 then return equipped end
        if average and average > 0 then return average end
    end
    local cached = CacheGet(inspect, unit, "level")
    if cached then return cached end
    local guid = S.SafeValue(SafeGuid(unit))
    if not guid then return end
    local precise = PreciseInspectItemLevel(unit)
    if precise and precise > 0 then
        local level = JudgePrecise(unit, guid, precise)
        if level then
            CachePut(inspect, guid, "level", level)
            return level
        end
        QueueSettleRecheck(guid)
    end
end

local function GetUnitAchievementPoints(unit)
    if S.SafeBool(UnitIsUnit, unit, "player") then
        local points = S.PlainNumber(S.SafeCall(GetTotalAchievementPoints))
        if points and points >= 0 then return points end
        return
    end
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    return CacheGet(achieve, unit, "points")
end

function UnitInfo.RequestInspect(unit)
    if not (NotifyInspect and CanInspect) then return end
    if not S.SafeBool(UnitExists, unit) then return end
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    if S.SafeBool(UnitIsUnit, unit, "player") then return end
    if not S.SafeBool(CanInspect, unit) then return end
    local guid = S.SafeValue(SafeGuid(unit))
    if not guid then return end
    local now = GetTime()
    if (inspect.suspendedUntil or 0) > now then return end
    if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then return end
    local cached = inspect.cache[guid]
    if cached and (now - cached.time) <= INSPECT_TTL then return end
    if inspect.pendingGUID == guid and (now - (inspect.lastRequestAt or 0)) < INSPECT_PENDING_TIMEOUT then return end
    if (now - (inspect.lastRequestAt or 0)) < INSPECT_INTERVAL then return end
    if pcall(NotifyInspect, unit) then
        inspect.pendingGUID = guid
        inspect.pendingUnit = unit
        inspect.lastRequestAt = now
        C_Timer.After(INSPECT_PENDING_TIMEOUT + 0.05, function()
            if inspect.pendingGUID ~= guid or inspect.lastRequestAt ~= now then return end
            if ns.RefreshUnitTip then ns.RefreshUnitTip(guid) end
        end)
    end
end

function UnitInfo.RequestAchievements(unit)
    if not S.SafeBool(UnitExists, unit) then return end
    if not S.SafeBool(UnitIsPlayer, unit) then return end
    if S.SafeBool(UnitIsUnit, unit, "player") then return end
    if not S.SafeBool(CanInspect, unit) then return end
    local guid = S.SafeValue(SafeGuid(unit))
    if not guid then return end
    local now = GetTime()
    if (achieve.suspendedUntil or 0) > now then return end
    local cached = achieve.cache[guid]
    if cached and (now - cached.time) <= INSPECT_TTL then return end
    if achieve.pendingGUID == guid then return end
    if (now - (achieve.lastRequestAt or 0)) < INSPECT_INTERVAL then return end
    if AchievementFrame and AchievementFrame.isComparison then return end
    if AchievementFrameComparison and AchievementFrameComparison.UnregisterEvent then
        pcall(AchievementFrameComparison.UnregisterEvent, AchievementFrameComparison, "INSPECT_ACHIEVEMENT_READY")
    end
    if ClearAchievementComparisonUnit then pcall(ClearAchievementComparisonUnit) end
    local ok, result = pcall(SetAchievementComparisonUnit, unit)
    if ok and result ~= false then
        achieve.pendingGUID = guid
        achieve.lastRequestAt = now
    end
end

local function ResolveUnit(guid, hint)
    if hint and GuidEquals(SafeGuid(hint), guid) then return hint end
    if GuidEquals(SafeGuid("mouseover"), guid) then return "mouseover" end
    if GuidEquals(SafeGuid("target"), guid) then return "target" end
end

local function FinishInspect(guid)
    if ClearInspectPlayer and not (InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown()) then
        pcall(ClearInspectPlayer)
    end
    inspect.pendingGUID, inspect.pendingUnit = nil, nil
    if ns.RefreshUnitTip then ns.RefreshUnitTip(guid) end
end

local function RetryPreciseItemLevel(unit, guid, deadline)
    C_Timer.After(PRECISE_RETRY_EVERY, function()
        if not GuidEquals(inspect.pendingGUID, guid) then return end
        local now = ResolveUnit(guid, unit)
        if not now then FinishInspect(guid) return end
        unit = now
        local precise, slot = PreciseInspectItemLevel(unit)
        local level = precise and precise > 0 and JudgePrecise(unit, guid, precise)
        if level then
            CachePut(inspect, guid, "level", level)
            FinishInspect(guid)
        elseif GetTime() < deadline then
            RetryPreciseItemLevel(unit, guid, deadline)
        else
            FinalizePrecise(unit, guid, precise)
            FinishInspect(guid)
        end
    end)
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("INSPECT_READY")
    f:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
    f:SetScript("OnEvent", function(_, event, guid)
        if event == "INSPECT_READY" then
            local pendingGUID = inspect.pendingGUID
            if not pendingGUID then return end
            local unit = ResolveUnit(pendingGUID, inspect.pendingUnit)
            if not unit then return end
            if not InspectDataPresent(unit) then return end
            guid = pendingGUID
            local precise, slot = PreciseInspectItemLevel(unit)
            local level = precise and precise > 0 and JudgePrecise(unit, guid, precise)
            if level then
                CachePut(inspect, guid, "level", level)
                FinishInspect(guid)
            else
                RetryPreciseItemLevel(unit, guid, GetTime() + PRECISE_RETRY_FOR)
            end
        elseif event == "INSPECT_ACHIEVEMENT_READY" then
            if not achieve.pendingGUID then return end
            if guid and not GuidEquals(guid, achieve.pendingGUID) then return end
            local resolved = guid or achieve.pendingGUID
            local points = S.PlainNumber(S.SafeCall(GetComparisonAchievementPoints))
            if points and points >= 0 then CachePut(achieve, resolved, "points", points) end
            if ClearAchievementComparisonUnit then pcall(ClearAchievementComparisonUnit) end
            achieve.pendingGUID = nil
            if ns.RefreshUnitTip then ns.RefreshUnitTip(resolved) end
        end
    end)
    if InspectUnit then
        hooksecurefunc("InspectUnit", function()
            local now = GetTime()
            inspect.suspendedUntil = now + 3
            inspect.pendingGUID, inspect.pendingUnit = nil, nil
            achieve.suspendedUntil = now + 3
            achieve.pendingGUID = nil
        end)
    end
end

------------------------------------------------------------
-- raw 表（對照 MiliUI UnitInfo.lua:646-738）——新方法名 GetPanelInfo
------------------------------------------------------------
local t = {}
function UnitInfo.GetPanelInfo(unit)
    if not unit or not S.SafeBool(UnitExists, unit) then
        wipe(t)
        t.unit = unit
        return t
    end

    local name, realm = S.SafeCall(UnitName, unit)
    local pvpName = S.SafeCall(UnitPVPName, unit)
    local gender = S.SafeCall(UnitSex, unit)
    local level = S.SafeCall(UnitLevel, unit)
    local effectiveLevel = UnitEffectiveLevel and S.SafeCall(UnitEffectiveLevel, unit) or level
    local raceName, race = S.SafeCall(UnitRace, unit)
    local className, class = S.SafeCall(UnitClass, unit)
    local factionGroup, factionName = S.SafeCall(UnitFactionGroup, unit)
    local reaction = S.SafeValue(S.SafeCall(UnitReaction, unit, "player"))
    local guildName, guildRank, guildIndex, guildRealm = S.SafeCall(GetGuildInfo, unit)
    local classif = S.SafeValue(S.SafeCall(UnitClassification, unit))
    local role = S.SafeValue(S.SafeCall(UnitGroupRolesAssigned, unit))
    local mplusScore, mplusColor, mplusBest = GetMythicPlusScore(unit)
    local isPlayer = S.SafeBool(UnitIsPlayer, unit)
    local itemLevel = isPlayer and GetUnitItemLevel(unit) or nil
    local achievementPoints = isPlayer and GetUnitAchievementPoints(unit) or nil
    local plainLevel = S.PlainNumber(level)

    t.raidIcon     = GetRaidIcon(unit)
    t.pvpIcon      = GetPVPIcon(unit)
    t.factionIcon  = S.PlainText(factionGroup) and icons[factionGroup] or nil
    t.classIcon    = GetClassIcon(class)
    t.roleIcon     = GetRoleIconMarkup(unit)
    t.questIcon    = GetQuestBossIcon(unit)
    t.friendIcon   = GetFriendIcon(unit)
    t.factionName  = factionName
    t.role         = (type(role) == "string" and role ~= "NONE") and role or nil
    t.name         = name
    t.gender       = S.PlainNumber(gender) == 2 and MALE or (S.PlainNumber(gender) == 3 and FEMALE or nil)
    t.realm        = realm or GetRealmName()
    t.levelValue   = (plainLevel and plainLevel >= 0) and plainLevel or L["unknown"]
    t.itemLevel    = isPlayer and ((itemLevel and itemLevel > 0) and TruncItemLevel(itemLevel) or L["unknown"]) or nil
    t.achievementPoints = isPlayer and ((achievementPoints and achievementPoints >= 0) and floor(achievementPoints + 0.5) or L["unknown"]) or nil
    t.className    = className
    t.raceName     = raceName
    t.guildName    = guildName
    t.guildRank    = guildRank
    t.guildIndex   = guildName and guildIndex or nil
    t.guildRealm   = guildRealm
    t.statusAFK    = S.SafeBool(UnitIsAFK, unit) and AFK or nil
    t.statusDND    = S.SafeBool(UnitIsDND, unit) and DND or nil
    t.statusDC     = (S.SafeValue(S.SafeCall(UnitIsConnected, unit), true) == false) and OFFLINE or nil
    t.reactionName = reaction and _G["FACTION_STANDING_LABEL" .. reaction] or nil
    t.creature     = S.SafeCall(UnitCreatureType, unit)
    t.classifBoss  = (S.PlainNumber(level) == -1 or classif == "worldboss") and BOSS or nil
    t.classifElite = classif == "elite" and ELITE or nil
    t.classifRare  = (classif == "rare" or classif == "rareelite") and RARE or nil
    t.isPlayer     = isPlayer and PLAYER or nil
    t.moveSpeed    = GetMoveSpeed(unit)
    t.zone         = GetZone(unit, t.name, t.realm)
    t.unit         = unit
    t.level        = level
    t.effectiveLevel = effectiveLevel or level
    t.race         = race
    t.class        = class
    t.factionGroup = factionGroup
    t.reaction     = reaction
    t.classif      = classif
    t.title, t.titleIsPrefix = GetTitle(name, pvpName, nil)
    if t.classifBoss then t.classifElite = nil end
    if mplusScore and mplusScore > 0 then
        t.mplusScoreNumber = floor(mplusScore + 0.5)
        t.mplusBestText = (mplusBest and mplusBest > 0) and (" (" .. mplusBest .. ")") or ""
        t.mplusScoreColor = mplusColor
    else
        t.mplusScoreNumber = 0
        t.mplusBestText = " (0)"
        t.mplusScoreColor = { r = 0.6, g = 0.6, b = 0.6 }
    end
    t.mountName = nil
    t.mountCollected = nil
    t.classSpecIcon = nil
    return t
end

function UnitInfo.FillMount(raw, unit)
    raw.mountName, raw.mountCollected = GetMountInfo(unit)
end

------------------------------------------------------------
-- 顯示條件（對照 MiliUI UnitInfo.lua:750-807）
------------------------------------------------------------
function UnitInfo.CheckFilter(config, raw, showAll)
    if showAll then return true end
    if not config or not config.enable then return end
    local filter = config.filter
    if not filter or filter == "" or filter == "none" then return true end
    local key = strsplit(":", filter)
    local oppo
    key, oppo = key:gsub("not%s+", "")
    local func = Colors.filterfunc and Colors.filterfunc[key]
    if func then
        local res = func(raw, select(2, strsplit(":", filter)))
        if oppo > 0 then return not res end
        return res
    end
    return true
end

function UnitInfo.ModifierShowAll(config)
    if not (config and config.modifierShowAll) then return false end
    return IsAltKeyDown() or IsControlKeyDown()
end

------------------------------------------------------------
--  Preview 用（對照既有 ADE 約定，供 Options/Preview 呼叫）
------------------------------------------------------------
UnitInfo.mountIconTag = mountIconTag
UnitInfo.mplusIconTag = mplusIconTag
UnitInfo.itemLevelIconTag = itemLevelIconTag
UnitInfo.achievementIconTag = achievementIconTag
UnitInfo.icons = icons
