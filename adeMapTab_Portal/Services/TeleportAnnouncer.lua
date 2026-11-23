--[==[ adeMapTab_Portal / Services/TeleportAnnouncer.lua — 传送通报功能模块
功能移植自 TeleportAnnouncer v1.9.0（原作者：电视卫士(SGSwdzgr), KeiraMetz；MIT，
版权与许可声明随实质性副本保留在 Data/TeleportAnnouncer.lua 文件头）。
行为与原插件一致：施法开始/结束向实例/团队/队伍频道通报传送目的地，单人静默；
castGUID 去重（120s）+ 同法术 2s 节流，被节流的施法也记入历史防 SUCCESS 补发。
差异（ADE v6.5 口径）：设置走本插件齿轮页的 addon.db 扁平键（不 vendored LibBlzSettings）；
v6.5-r004 起播报数据与主表统一——可播报法术集合、目的地名与物品 ID 一律经
addon.Catalog.AnnounceInfo(spellID) 从 Data/Teleports.lua / Hearthstones.lua /
DestinationOverrides.lua 派生，新增传送写入主表即自动播报，不再有独立白名单与双语表；
仅 keystone/heartstone 两个过滤标记留在 Data/TeleportAnnouncer.lua 的 TeleportAnnounceFlags。
12.x 纪律——SetScript 必须先于 RegisterEvent（adeBagPack/Modules/Pack.lua:969-972），
事件帧加载期创建、PLAYER_ENTERING_WORLD 才到达，此时 Core.lua 的 SetupDatabase 已完成。

开关：announceTeleport（默认 false，不打扰未启用的用户）。 ]==]
local _, addon = ...
local L = addon.L
local TA = addon.TeleportAnnouncer

local C_Spell_GetSpellLink = C_Spell.GetSpellLink
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_ChatInfo_SendChatMessage = C_ChatInfo.SendChatMessage
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local GetTime = GetTime
local string_format = string.format
local pairs = pairs

local handledCasts, lastAnnounceTimes = {}, {}
local ANNOUNCE_INTERVAL = 2
local CAST_HISTORY_SECONDS = 120

local function Enabled()
    return addon.db and addon.db.announceTeleport == true
end

local function Setting(key, default)
    if not addon.db then return default end
    local v = addon.db[key]
    if v == nil then return default end
    return v
end

local function SendMessage(message)
    local channel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
        channel = Setting("announceTeleportChannel", 1) == 1 and "RAID" or "PARTY"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        channel = "PARTY"
    end
    if channel then
        C_ChatInfo_SendChatMessage(message, channel)
        return true
    end
end

function TA:AnnounceSpell(spellID, isSucceeded, castGUID)
    if not Enabled() then return end
    local info = addon.Catalog.AnnounceInfo(spellID)
    if not info then return end
    if Setting("announceTeleportOnlyKeystone", false) and not info.keystone then return end
    if Setting("announceTeleportIgnoreHearthstone", false) and info.heartstone then return end
    if Setting("announceTeleportTiming", 1) == 2 and not isSucceeded then return end

    local now = GetTime()
    for guid, timestamp in pairs(handledCasts) do
        if now - timestamp > CAST_HISTORY_SECONDS then handledCasts[guid] = nil end
    end
    if castGUID and handledCasts[castGUID] then return end
    -- 被过滤/节流的施法同样记入历史，避免 SUCCESS 事件补发（原插件 TeleportAnnouncer.lua:58）。
    if castGUID then handledCasts[castGUID] = now end
    if lastAnnounceTimes[spellID] and now - lastAnnounceTimes[spellID] < ANNOUNCE_INTERVAL then return end

    local templateUse = isSucceeded and L["ANNOUNCE_USED_HEADING"] or L["ANNOUNCE_USING_HEADING"]
    local templateCast = isSucceeded and L["ANNOUNCE_CAST_HEADING"] or L["ANNOUNCE_CASTING_HEADING"]
    local destination = info.destination
    local message
    if not Setting("announceTeleportNoItem", false) then
        if TA.teleportItems[spellID] then
            message = string_format(templateUse, TA.teleportItems[spellID], destination)
        elseif info.item then
            local _, itemLink = C_Item_GetItemInfo(info.item)
            if itemLink then message = string_format(templateUse, itemLink, destination) end
        end
    end
    if not message then
        local spellLink = C_Spell_GetSpellLink(spellID) or L["ANNOUNCE_UNKNOWN_SPELL"]
        message = string_format(templateCast, spellLink, destination)
    end
    if SendMessage(message) then lastAnnounceTimes[spellID] = now end
end

local frame = CreateFrame("Frame")
-- 12.x：SetScript 先于 RegisterEvent，事件帧回调建立后再注册。
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_EQUIPMENT_CHANGED" then
        -- 物品→法术映射始终构建（开关打开时映射已就绪，不受启用时机影响）。
        TA:buildTeleportItems()
        if event == "PLAYER_ENTERING_WORLD" then self:UnregisterEvent("PLAYER_ENTERING_WORLD") end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        if unitTarget == "player" and castGUID then
            TA:AnnounceSpell(spellID, event == "UNIT_SPELLCAST_SUCCEEDED", castGUID)
        end
    end
end)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
