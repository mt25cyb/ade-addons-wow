local _, addon = ...
addon.Data = addon.Data or {}

-- 综合统计面板用到的 ID 常量。ID 本身无法从 API 枚举，故建表；数量一律走 API。
-- 货币/道具 ID：DelveCompanion Data/Config.lua:80-107 与 EverythingDelves Core/Constants.lua:303-307。

addon.Data.CURRENCIES = {
    shards = 3310, -- 宝匣钥匙碎片
    keys = 3028, -- 修复的宝匣钥匙
    resonance = 2803, -- 晦幽铸币
    manaCrystal = 3356, -- 未被污染的法力水晶
}

addon.Data.SHARDS_FOR_KEY = 100 -- DelveCompanion Config.lua:85

addon.Data.ITEMS = {
    bountyMap = 274374, -- 珍宝猎手的奖赏
    nemesisLure = 275910, -- 鳞裔先驱之笛
    heroicSoulFragment = 285801, -- 英雄灵魂残片（EverythingDelves Core/LabLog.lua:10）
}

-- 鎏金藏匿物：EverythingDelves Core/Data.lua:16 使用单一 widget，
-- DelveCompanion 的 Midnight 条目 gildedStashUiWidgetID 同为 7591。
addon.Data.GILDED_WIDGET_ID = 7591

-- 玩具：地下堡机器人 7001 型
addon.Data.TOY = {
    spellID = 467470,
    itemID = 230850,
}

-- 词缀：优先用 C_DelvesUI.GetDelvesAffixSpellsForSeason()（DelvesUIDocumentation.lua:156-163），
-- API 返回空时回退到 DelveCompanion 的常量（Config.lua:138-143）。
addon.Data.AFFIX_FALLBACK_SPELL_ID = 1270179

-- 周常：EverythingDelves Core/Data.lua:15
addon.Data.WEEKLY_QUEST_ID = 93909
-- EverythingDelves Core/Constants.lua:265（questIDs）
addon.Data.CALL_QUEST_ID = 93889

-- 成就系列：EverythingDelves Core/Achievements.lua:21-26（DelveDepthsSeries）
addon.Data.DEPTHS_SERIES = { 61707, 61708, 61709, 61710 }
