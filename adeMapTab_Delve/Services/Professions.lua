local _, addon = ...
addon.Professions = addon.Professions or {}
local Professions = addon.Professions
local Data = addon.Data
local L = addon.L

-- 玩家自身专业的判定。
-- ⚠ 这个 Professions 挂在 addon 表下，不是 Blizzard 的全局 `Professions` 命名空间，不污染 _G。
--
-- 按**专业 ID** 判断，不读本地化名，因此在任何语种客户端都成立
-- （用户 2026-10-30 要求）。判定手段照 HandyNotes_MapNotes
-- Core/ProfessionDetection.lua 的实证做法：用该专业代表性技能的 `IsSpellKnown`
-- 判断是否学会（技能 ID 表见 Data\Professions.lua）。

local knownProfessions = nil

--- 作废缓存，下次查询重新检测（学了 / 忘了专业后调用）。
function Professions:Invalidate()
    knownProfessions = nil
end

--- 玩家已学会的专业集合：{ [专业 ID] = true }。
function Professions:GetKnownProfessions()
    if knownProfessions then return knownProfessions end
    knownProfessions = {}
    for _, prof in ipairs(Data.PROFESSIONS or {}) do
        for _, spellID in ipairs(prof.spells or {}) do
            -- 12.x 用 C_SpellBook.IsSpellKnown：旧全局 IsSpellKnown 已废弃，只保留在
            -- Blizzard_DeprecatedSpellBook（Deprecated_SpellBook.lua:16 转发到新 API）。
            if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then
                knownProfessions[prof.id] = true
                break
            end
        end
    end
    return knownProfessions
end

--- 玩家是否学会了该专业（按专业 ID 判断，语种无关）。
function Professions:HasProfession(professionID)
    if not professionID then return false end
    return self:GetKnownProfessions()[professionID] == true
end

--- 专业的显示名：走 locale（L["PROF_<key>"]）。
function Professions:GetProfessionName(professionID)
    for _, prof in ipairs(Data.PROFESSIONS or {}) do
        if prof.id == professionID then
            return (L and L["PROF_" .. prof.key]) or tostring(professionID)
        end
    end
    return tostring(professionID)
end

-- 12.x 要求：先挂脚本再注册事件。
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
    if event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL" then
        Professions:Invalidate()
        -- 丰饶条目的专业高亮依赖这里，专业变了要重排列表。
        if addon.MapPanel and addon.MapPanel.RefreshPanel then addon.MapPanel:RefreshPanel() end
    end
end)
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("CHAT_MSG_SKILL")
