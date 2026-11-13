-- adeTooltip — 钩子层（P1 骨架）。
-- P2 将在此接 TooltipDataProcessor.AddTooltipPostCall（依据：客户端实现
-- Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua:199-201，AllTypes :177-179）。
-- 本版只提供：设置版本号、布局闸门（§四.1）、共存提示（§十三.6）。
local ADT = _G.adeTooltip
if not ADT then return end
local L = ADT.L or {}

-- 设置版本号：ApplyAll 时自增；P2 起渲染层据此判断是否需要重绘已显示的面板。
ADT.settingsVersion = 0
function ADT:BumpSettingsVersion()
    self.settingsVersion = self.settingsVersion + 1
end

--- 布局闸门：usePrettyStyle 开 + 该类型未被排除 → 走新版面板；否则走经典路径。
--- （P1 尚无渲染层，本函数供 P2 起的管线与选项页禁用态共用同一判定。）
function ADT:ShouldPanel(kind)
    if not self.db then return false end
    if self:Get("usePrettyStyle") ~= true then return false end
    local types = self:Get("types")
    if kind and type(types) == "table" and types[kind] == false then return false end
    return true
end

-- 共存提示：与 MiliUI_Tooltip 同装时提示一次（自动停用待 P2 渲染层落地后才有意义）。
local probe = CreateFrame("Frame")
probe:RegisterEvent("PLAYER_LOGIN")
probe:SetScript("OnEvent", function()
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MiliUI_Tooltip") then
        ADT:Print(L.MSG_CONFLICT or "MiliUI_Tooltip detected; do not run both tooltip addons.")
    end
end)
