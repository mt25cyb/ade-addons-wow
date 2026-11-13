-- adeTooltip — 色表（P1 骨架：品质/反应/职业色；学派色随 P3 法术管线补全）。
-- 品质色与客户端 ITEM_QUALITY_COLORS 同值；职业色运行时读 RAID_CLASS_COLORS（12.1.5 有效）。
local ADT = _G.adeTooltip
if not ADT then return end

ADT.Colors = {
    -- 物品品质（灰/白/绿/蓝/紫/橙/传家宝/代币）
    quality = {
        [0] = { 0.62, 0.62, 0.62 },
        [1] = { 1.00, 1.00, 1.00 },
        [2] = { 0.12, 1.00, 0.00 },
        [3] = { 0.00, 0.44, 0.87 },
        [4] = { 0.64, 0.21, 0.93 },
        [5] = { 1.00, 0.50, 0.00 },
        [6] = { 0.90, 0.80, 0.50 },
        [7] = { 0.00, 0.80, 1.00 },
    },
    -- 阵营反应（敌对→友善；取 MiliUI/Pretty 通用观感）
    reaction = {
        hostile  = { 1.00, 0.20, 0.20 },
        neutral  = { 1.00, 0.85, 0.20 },
        friendly = { 0.25, 1.00, 0.35 },
    },
}

--- 职业色（classFile 如 "WARRIOR"）；未知职业回白。
function ADT.ClassColor(classFile)
    local c = classFile and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[classFile]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

--- 品质色；未知品质回白。
function ADT.QualityColor(quality)
    local c = ADT.Colors.quality[quality]
    if c then return c[1], c[2], c[3] end
    return 1, 1, 1
end
