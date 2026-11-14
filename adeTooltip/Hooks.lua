-- adeTooltip — 钩子与路线分发（C0 骨架）。
-- 双闸门：ShouldClassic / ShouldNewLayout。
-- C0 仅搭建分发骨架与秘密守卫接入点；经典路线的原地行修饰（C1+）与新版排版（N 阶段）后续填充。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true, "adeTooltip")
if not AF then return end

---------------------------------------------------------------------------
-- 路线闸门
---------------------------------------------------------------------------
-- 经典路线：useNewLayout 关闭，且本类型参与（types.* 未显式关闭）。
function ADT:ShouldClassic(kind)
    if ADT:Get("useNewLayout") then return false end
    return ADT:Get("types." .. (kind or "object")) ~= false
end

-- 新版排版：useNewLayout 开启，且本类型参与。
function ADT:ShouldNewLayout(kind)
    if not ADT:Get("useNewLayout") then return false end
    return ADT:Get("types." .. (kind or "object")) ~= false
end

---------------------------------------------------------------------------
-- 分发入口（C1 起在 ADT.OnTooltip 内实现经典路线修饰；N 阶段实现新版排版）。
---------------------------------------------------------------------------
-- 安全包装：任何钩子错误只打印，不污染原生 tooltip。
function ADT:HookSafe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then self:Print("|cffff5555hook error:|r " .. tostring(err)) end
end

---------------------------------------------------------------------------
-- 初始化钩子（PLAYER_LOGIN 后由 Core 调用）。
-- C0：仅占位。C1 将在此接入 GameTooltip/ItemRefTooltip 的
-- TooltipDataProcessor 与 OnTooltipSetUnit/SetItem/SetSpell 等显示时机，
-- 按 ShouldClassic / ShouldNewLayout 分发到对应路线。
---------------------------------------------------------------------------
function ADT:InitHooks()
    -- 预留接入点（不在此注册任何会改原生行的行为，避免 C0 阶段引入未验证副作用）。
end
