local _, addon = ...
addon.Data = addon.Data or {}

-- 专业表（用户 2026-10-30 要求：按「专业 ID」判断，不硬编码中文，跨语种兼容）。
--
-- id     = 该专业的 SkillLine ID（Blizzard 口径的数字 ID，与玩家语言无关）。
-- ⚠ 这组 ID 沿用各专业传统的 SkillLine 值；当前客户端若有变动，可实机
--   `C_TradeSkillUI.GetAllProfessionTradeSkillLines()` dump 核对（该函数返回已学专业的
--   skillLineID 数组，实证见 z-ref_wow-ui-source .../Blizzard_APIDocumentationGenerated/
--   TradeSkillUIDocumentation.lua:105-113）。
--
-- 判定方式照 HandyNotes_MapNotes Core/ProfessionDetection.lua 的实证做法：
-- 用该专业代表性技能判定「是否学会」，而不是读本地化名，因此在任何语种客户端都成立。
-- 运行时走 12.x 的 `C_SpellBook.IsSpellKnown`（旧全局 IsSpellKnown 已废弃，见
-- Services/Professions.lua）。spells 只保留「Vanilla 基础技能 + 至暗之夜(471003-471015)」，
-- 玩家只要学过该专业必有其一（技能 ID 列表出处同上，HandyNotes 已含 Midnight 一组）。
--
-- 字段：
--   id      专业 ID（SkillLine ID）
--   key     本地化键后缀，专业显示名走 L["PROF_<key>"]
--   spells  判定用技能 ID（任一 IsSpellKnown 即视为已学该专业）

addon.Data.PROFESSIONS = {
    { id = 171, key = "ALCHEMY",        spells = { 2259, 471003 } },         -- 炼金
    { id = 164, key = "BLACKSMITHING",  spells = { 2018, 471004 } },         -- 锻造
    { id = 185, key = "COOKING",        spells = { 818, 2550, 471005 } },    -- 烹饪
    { id = 333, key = "ENCHANTING",     spells = { 13262, 471006 } },        -- 附魔
    { id = 202, key = "ENGINEERING",    spells = { 4036, 471007 } },         -- 工程
    { id = 356, key = "FISHING",        spells = { 131474, 471008 } },       -- 钓鱼
    { id = 182, key = "HERBALISM",      spells = { 2366, 193290, 471009 } }, -- 采药
    { id = 773, key = "INSCRIPTION",    spells = { 45357, 471010 } },        -- 铭文
    { id = 755, key = "JEWELCRAFTING",  spells = { 25229, 471011 } },        -- 珠宝
    { id = 165, key = "LEATHERWORKING", spells = { 2108, 471012 } },         -- 制皮
    { id = 186, key = "MINING",         spells = { 2575, 471013 } },         -- 采矿
    { id = 393, key = "SKINNING",       spells = { 8613, 471014 } },         -- 剥皮
    { id = 197, key = "TAILORING",      spells = { 3908, 471015 } },         -- 裁缝
    { id = 794, key = "ARCHAEOLOGY",    spells = { 80451 } },                -- 考古
}

-- 便捷映射：key → 专业 ID，供其它 Data 表按名字引用而不写死数字
-- （加载顺序：本文件在 TOC 中先于 Data\AbundanceData.lua）。
addon.Data.PROFESSION = {}
for _, prof in ipairs(addon.Data.PROFESSIONS) do
    addon.Data.PROFESSION[prof.key] = prof.id
end
