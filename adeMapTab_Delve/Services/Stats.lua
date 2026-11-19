local _, addon = ...
local Stats = addon.Stats
local Data = addon.Data

-- 综合统计与进度查询。数值一律走 API，静态表只提供 ID。

--- 货币三量：总数 / 本周已获取 / 每周上限。
-- 取法见 EverythingDelves UI/TabShardTracker.lua:37-47 与 DelveCompanion ConsumablesFrame.lua:51-63。
function Stats:GetCurrency(currencyID)
    if not currencyID or not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if not ok or type(info) ~= "table" then return nil end
    return {
        quantity = info.quantity or 0,
        earnedThisWeek = info.quantityEarnedThisWeek or 0,
        maxWeekly = info.maxWeeklyQuantity or 0,
        maxQuantity = info.maxQuantity or 0,
        name = info.name,
        icon = info.iconFileID,
        discovered = info.discovered ~= false,
    }
end

function Stats:GetItemCount(itemID)
    if not itemID then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID)
        if ok and type(count) == "number" then return count end
    end
    return 0
end

--- 鎏金藏匿物：widget 的 spellInfo 里同时有名称、spellID 与 tooltip（结构是
-- SpellDisplayVisualizationInfo.spellInfo : UIWidgetSpellInfo，
-- UIWidgetManagerDocumentation.lua:1750）。全部走 API，语言文件里不再硬编码名称
--（用户 2026-10-28）。
function Stats:GetGildedStashInfo()
    if not (C_UIWidgetManager and C_UIWidgetManager.GetSpellDisplayVisualizationInfo) then return nil end
    local ok, info = pcall(C_UIWidgetManager.GetSpellDisplayVisualizationInfo, Data.GILDED_WIDGET_ID)
    if not ok or not info then return nil end
    return info.spellInfo
end

--- 名称走 API：spellID → C_Spell.GetSpellName。
-- spellID 的读法照原生模板（Blizzard_UIWidgetTemplateSpellDisplay.lua:107）。
function Stats:GetGildedStashName()
    local spellInfo = Stats:GetGildedStashInfo()
    local spellID = spellInfo and spellInfo.spellID
    if not spellID or spellID == 0 then return nil end
    if not (C_Spell and C_Spell.GetSpellName) then return nil end
    local ok, name = pcall(C_Spell.GetSpellName, spellID)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

function Stats:GetGildedStashTooltip()
    local spellInfo = Stats:GetGildedStashInfo()
    return spellInfo and spellInfo.tooltip or nil
end

--- 数量：DelveCompanion GildedStashFrame.lua:109-153 读 spellInfo.tooltip。
-- DC 用 strsub 取单字符，超过 9 会出错；这里改为匹配 "a/b"。
function Stats:GetGildedStash()
    local tooltip = Stats:GetGildedStashTooltip()
    if not tooltip then return nil, nil end
    local collected, total = string.match(tooltip, "(%d+)%s*/%s*(%d+)")
    return tonumber(collected), tonumber(total)
end

--- 词缀：优先 API（DelvesUIDocumentation.lua:156-163），空结果回退静态常量。
function Stats:GetAffixSpellIDs()
    if C_DelvesUI and C_DelvesUI.GetDelvesAffixSpellsForSeason then
        local ok, spells = pcall(C_DelvesUI.GetDelvesAffixSpellsForSeason)
        if ok and type(spells) == "table" and #spells > 0 then return spells end
    end
    return { Data.AFFIX_FALLBACK_SPELL_ID }
end

function Stats:GetCurrentSeason()
    if C_DelvesUI and C_DelvesUI.GetCurrentDelvesSeasonNumber then
        local ok, season = pcall(C_DelvesUI.GetCurrentDelvesSeasonNumber)
        if ok and type(season) == "number" then return season end
    end
    return nil
end

--- 宿敌是否为当前赛季：拿不到赛季号时用 Data.CURRENT_SEASON 里登记的号。
function Stats:IsCurrentNemesis(entry)
    if not entry or entry.kind ~= "nemesis" then return false end
    local seasons = Data.CURRENT_SEASON
    local fallbackSeason = seasons and seasons[entry.expansion]
    if not fallbackSeason then return false end
    local season = Stats:GetCurrentSeason()
    if season then
        -- API 返回的赛季号只对「当前资料片」有意义，所以先限定资料片再比号。
        return entry.expansion == Data.CURRENT_EXPANSION and entry.season == season
    end
    return entry.season == fallbackSeason
end

--- 成就进度：返回已完成数、总数、是否全部完成。
-- GetAchievementCriteriaInfo 的返回顺序见 Blizzard_AchievementUI.lua:1952。
function Stats:GetAchievementProgress(achievementID)
    if not achievementID or not GetAchievementNumCriteria then return nil, nil, false end
    local ok, numCriteria = pcall(GetAchievementNumCriteria, achievementID)
    if not ok or not numCriteria then return nil, nil, false end

    if numCriteria == 0 then
        local ok2, _, _, completed = pcall(GetAchievementInfo, achievementID)
        if ok2 then return completed and 1 or 0, 1, completed and true or false end
        return nil, nil, false
    end

    local done, total = 0, 0
    for index = 1, numCriteria do
        local ok3, _, _, completed, quantity, reqQuantity = pcall(GetAchievementCriteriaInfo, achievementID, index)
        if ok3 then
            local need = reqQuantity or 0
            if need <= 0 then need = 1 end
            total = total + need
            if completed then
                done = done + need
            elseif quantity and quantity > 0 then
                done = done + quantity
            end
        end
    end
    return done, total, (total > 0 and done >= total)
end

--- 某个故事变种在该地下堡的「{地下堡}故事」成就里是否已完成。
-- 成就 criteria 的返回顺序：第 1 个是条目名、第 3 个是 completed
-- （实证：Achievement.lua:33 / Achievements.lua:6 / AchievementService.lua:24
--  都是 `local _, _, done = GetAchievementCriteriaInfo(id, index)`）。
-- 返回 true / false；拿不到（成就没有 criteria、名字对不上）返回 nil，调用方按「未知」处理。
function Stats:IsStoryVariantCompleted(achievementID, variantName)
    if not achievementID or not variantName or variantName == "" then return nil end
    if not GetAchievementNumCriteria then return nil end
    local ok, numCriteria = pcall(GetAchievementNumCriteria, achievementID)
    if not ok or not numCriteria or numCriteria == 0 then return nil end
    for index = 1, numCriteria do
        local ok2, description, _, completed = pcall(GetAchievementCriteriaInfo, achievementID, index)
        if ok2 and type(description) == "string" and description ~= "" then
            if description:find(variantName, 1, true) then
                return completed and true or false
            end
        end
    end
    return nil
end

--- 成就图标：12.x 优先走 C_AchievementInfo，回退全局 GetAchievementInfo。
-- 两种签名都要兼容：C_AchievementInfo 若返回 table 读字段，否则按多返回值取第 10 个（icon）。
-- 成就详情按需加载，未预热时可能拿不到图标，所以先 RequestAchievementInfo。
-- 取不到返回 nil，由调用方决定「不显示」，不用占位图冒充（用户 2026-10-27 反馈图标异常）。
function Stats:GetAchievementIcon(achievementID)
    if not achievementID then return nil end

    if C_AchievementInfo and C_AchievementInfo.RequestAchievementInfo then
        pcall(C_AchievementInfo.RequestAchievementInfo, achievementID)
    end

    local api = C_AchievementInfo and C_AchievementInfo.GetAchievementInfo
    if not api then api = GetAchievementInfo end
    if not api then return nil end

    local ok, r1, _, _, _, _, _, _, _, _, r10 = pcall(api, achievementID)
    if not ok then return nil end
    if type(r1) == "table" then
        return r1.iconTexture or r1.icon
    end
    return r10
end

--- 成就名：与 GetAchievementIcon 同一套兼容写法。
-- 全局 GetAchievementInfo 的第二个返回值就是名字（原生 Blizzard_AchievementUI.lua 里
-- `local _, achievementName, ... = GetAchievementInfo(id)` 实证）；
-- C_AchievementInfo 若返回 table 就读 name 字段。
-- tooltip 要显示「成就: {成就名}」（用户 2026-10-28）。
function Stats:GetAchievementName(achievementID)
    if not achievementID then return nil end

    if C_AchievementInfo and C_AchievementInfo.RequestAchievementInfo then
        pcall(C_AchievementInfo.RequestAchievementInfo, achievementID)
    end

    local api = C_AchievementInfo and C_AchievementInfo.GetAchievementInfo
    if not api then api = GetAchievementInfo end
    if not api then return nil end

    local ok, r1, r2 = pcall(api, achievementID)
    if not ok then return nil end
    if type(r1) == "table" then
        return r1.name
    end
    return r2
end

--- 地下堡行者的召唤：none / active / turnin / done。
-- 判定链见 EverythingDelves UI/TabDelversCall.lua:20-48。
function Stats:GetCallState(questID)
    if not questID then return nil end
    if not C_QuestLog then return nil end

    if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        return "done"
    end

    local index = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
    if index then
        if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(index) then return "turnin" end
        if C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then return "turnin" end
        return "active"
    end
    return "none"
end

--- 条目主成就：宿敌用 nemesisSolo，其余优先用 chest（宝箱），没有则用 story。
function Stats:GetEntryAchievement(entry)
    if not entry then return nil end
    if entry.kind == "nemesis" then return entry.achNemesis end
    return entry.achChest or entry.achStory
end

--- 玩具冷却：地下堡机器人 7001 型。
function Stats:GetToyCooldown()
    local itemID = Data.TOY and Data.TOY.itemID
    if not itemID then return nil, nil end
    if C_Item and C_Item.GetItemCooldown then
        local ok, start, duration = pcall(C_Item.GetItemCooldown, itemID)
        if ok then return start, duration end
    end
    return nil, nil
end

function Stats:HasToy()
    local itemID = Data.TOY and Data.TOY.itemID
    if not itemID or not PlayerHasToy then return false end
    return PlayerHasToy(itemID) and true or false
end
