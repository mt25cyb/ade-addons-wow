--[==[ adeAnnivGuide / UI/Blocks.lua — 富文本与图块工具
    ⚠ 本表修复（2026-11-21 实测 _debug.log）：此前 local Blocks={} 与 ns.Blocks={}
    是两张表，方法全定义在局部表上、ns.Blocks.RichText 恒 nil，致内容页
    「attempt to call a nil value」且富文本为空——ns.Blocks 必须指向同一张表。
    富文本 = FontString 控制字符标记（非 HTML）：任务名【】与坐标（63,53）
    上主题色；图片走 PoT 贴图 + SetTexCoord 裁补边（数据 u/v）。 ]==]
local ns = _G.adeAnnivGuide
local Blocks = {}
ns.Blocks = Blocks

--- 正文富文本化：任务名【…】与坐标（…）染主题色，其余保持纯文本。
function Blocks.RichText(s)
    local hex = ns.THEME_HEX
    s = s:gsub("【([^】]+)】", hex .. "【%1】|r")
    s = s:gsub("（%s*%d[%d%.,%s]*%s*）", function(m)
        return hex .. m .. "|r"
    end)
    return s
end

--- 图片贴图完整路径。
function Blocks.ImagePath(f)
    return ns.IMG_BASE .. f
end

--- 图块 TexCoord（8 参：UL/LL/UR/LR，裁掉 PoT 补边，只显示内容区 u×v）。
function Blocks.ApplyCrop(texture, u, v)
    texture:SetTexCoord(0, 0, 0, v, u, 0, u, v)
end
