-- adeMacroAssistant / Modules/AutoMacroData.lua
-- 各类型涉及的技能 ID（AM_*）。Data 先于 AutoMacro.lua 加载。
-- 可通过 https://www.wowhead.com/cn/spell=%spellID 查看技能信息。
local ns = _G.adeMacroAssistant

-- 净化技能 用于敌方
ns.AM_PURGE_SPELL_ARRAY = {
    19801,  -- 宁神射击 (猎人)    Tranquilizing Shot (Hunter)
    528,    -- 驱散魔法 (牧师)    Dispel Magic (Priest)
    30449,  -- 法术吸取 (法师)    Spellsteal (Mage)
    2908,   -- 安抚 (德鲁伊)      Sooth (Druid)
}

-- 清除技能 用于友方
ns.AM_CLEANSE_SPELL_ARRAY = {
    4987,   -- 清洁术 (神圣 圣骑士)       Cleanse (Holy Paladin)
    213644, -- 清毒术 (防护/惩戒 圣骑士)  Cleanse Toxins (prot/ret Paladin)
    527,    -- 纯净术 (牧师)             Purify (Priest)
    213634, -- 净化疾病 (暗影 牧师)       Purify Disease (Shadow Priest)
    51886,  -- 净化灵魂 (元素/增强 萨满)  Cleanse Spirit (ele/enh Shaman)
    77130,  -- 净化灵魂 (恢复 萨满)       Purify Spirit (Resto Shaman)
    475,    -- 解除诅咒 (法师)           Remove Curse (Mage)
    115450, -- 清创生血 (武僧)           Detox (Monk)
    218164, -- 清创生血 (武僧)           Detox (Monk)
    2782,   -- 清除腐蚀 (德鲁伊)         Remove Corruption (Druid)
    88423,  -- 自然之愈 (德鲁伊)         Nature's Cure (Druid)
    360823, -- 自然平衡 (唤魔师)         Naturalize (Evoker)
    365585, -- 净除 (唤魔师)             Expunge (Evoker)
}

-- 打断技能
ns.AM_INTERRUPT_SPELL_ARRAY = {
    6552,   -- 拳击 (战士)         Pummel (Warrior)
    96231,  -- 责难 (圣骑士)       Rebuke (Paladin)
    41084,  -- 沉默射击 (猎人)     Silencing Shot (Hunter)
    147362, -- 反制射击 (猎人)     Counter Shot (Hunter)
    187707, -- 压制 (猎人)         Muzzle (Hunter)
    1766,   -- 脚踢 (潜行者)       Kick (Rogue)
    15487,  -- 沉默 (牧师)         Silence (Priest)
    47528,  -- 心灵冰冻 (死亡骑士) Mind Freeze (Death Knight)
    57994,  -- 风剪 (萨满)         Wind Shear (Shaman)
    2139,   -- 法术反制 (法师)     Counterspell (Mage)
    19647,  -- 法术封锁 (术士)     Spell Lock (Warlock)
    116705, -- 切喉手 (武僧)       Spear Hand Strike (Monk)
    97547,  -- 日光术 (德鲁伊)     Solar Beam (Druid)
    78675,  -- 日光术 (德鲁伊)     Solar Beam (Druid)
    106839, -- 迎头痛击 (德鲁伊)   Skull Bash (Druid)
    183752, -- 瓦解 (恶魔猎手)     Consume Magic (Demon Hunter)
    351338, -- 镇压 (唤魔师)       Quell (Evoker)
}

-- 战斗复活技能
ns.AM_COMBATRESURRECTION_SPELL_ARRAY = {
    391054, -- 代祷 (圣骑士)    Intercession (Paladin)
    61999,  -- 复活盟友 (死亡骑士) Raise Ally (Death Knight)
    20707,  -- 灵魂石 (术士)    Soulstone (Warlock)
    20484,  -- 复生 (德鲁伊)    Rebirth (Druid)
}

-- 疾跑技能
ns.AM_SPRINT_SPELL_ARRAY = {
    190784, -- 神圣马驹 (圣骑士)  Divine Steed (Paladin)
    186257, -- 猎豹守护 (猎人)    Aspect of the Cheetah (Hunter)
    5118,   -- 猎豹守护 (猎人)    Aspect of the Cheetah (Hunter)
    2983,   -- 疾跑 (潜行者)      Sprint (Rogue)
    212552, -- 幻影步 (死亡骑士)  Wraith Walk (Death Knight)
    58875,  -- 幽魂步 (萨满)      Spirit Walk (enh Shaman)
    108843, -- 炽热疾速 (法师)    Blazing Speed (Mage)
    1850,   -- 急奔 (德鲁伊)      Dash (Druid)
    358267, -- 悬空 (唤魔师)      Hover (Evoker)
}

-- 嘲讽技能
ns.AM_TAUNT_SPELL_ARRAY = {
    355,    -- 嘲讽 (战士)           Taunt (Warrior)
    62124,  -- 清算之手 (圣骑士)     Hand of Reckoning (Paladin)
    2649,   -- 低吼 (猎人)           Growl (Hunter)
    56222,  -- 黑暗命令 (死亡骑士)   Dark Command (Death Knight)
    36213,  -- 大地之怒 (萨满)       Angered Earth (Shaman)
    17735,  -- 受难 (术士 - 虚空行者) Suffering (Warlock - VoidWalker)
    115546, -- 嚎镇八方 (武僧)       Provoke (Monk)
    6795,   -- 低吼 (德鲁伊)         Growl (Druid)
    185245, -- 折磨 (恶魔猎手)       Torment (Demon Hunter)
}
