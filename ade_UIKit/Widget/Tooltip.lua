------------------------------------------------------------
-- 暴雪原生设置面板的 SettingsTooltip（替代自建 GameTooltipTemplate 实例）。
-- 依据：仓内 LibEditMode widgets（Falcon/ExtraQuestButton/ls_Toasts 等）
-- 统一用 SettingsTooltip:SetOwner(self, "ANCHOR_NONE") 显示设置项说明——
-- 它就是原生选项界面的 tooltip，字体/缩放与原生一致。自建
-- GameTooltipTemplate 实例的字体受 UI Scale 影响，实测比原生大 1.5 倍。
-- 锚定仍用 ANCHOR_NONE + 手动 SetPoint 到悬停控件右缘（SetOwner(control,
-- "ANCHOR_RIGHT") 在本客户端触发 "Usage: SetOwner(region)" 断言）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local fallback = CreateFrame("GameTooltip", "AdeBlizzOptionsFrame_Tooltip", nil, "GameTooltipTemplate")
fallback:SetOwner(UIParent, "ANCHOR_NONE")
fallback:Hide()

local Tooltip = {}
local active

local function ResolveTooltip()
    return _G.SettingsTooltip or fallback
end

local function HideActive()
    if active then active:Hide() end
end

function Tooltip:ShowRow(option, row, anchor)
    if not option then HideActive() return end
    local text = option.GetDescription and option:GetDescription()
    if not text or text == "" then HideActive() return end
    -- 实参可能是任意类型（log 实证 false）：非 frame 一律回落锚行。
    if type(anchor) ~= "table" or anchor.IsObjectType == nil or not anchor:IsObjectType("Frame") then anchor = row end
    local tt = ResolveTooltip()
    local ok = pcall(tt.SetOwner, tt, row, "ANCHOR_NONE")
    if not ok then HideActive() return end
    if active and active ~= tt then active:Hide() end
    active = tt
    tt:ClearAllPoints()
    tt:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, -2)
    tt:ClearLines()
    local label = option.GetLabel and option:GetLabel()
    if label and label ~= "" then tt:AddLine(label, 1, 1, 1) end
    tt:AddLine(text, nil, nil, nil, true)
    if option.GetDefault then
        local has, value = option:GetDefault()
        if has and value ~= nil then
            tt:AddLine((lib.L["BOF_DEFAULT"] or "Default: %s"):format(tostring(value)), 0.6, 0.6, 0.6, true)
        end
    end
    tt:Show()
end

function Tooltip:HideRow(option)
    HideActive()
end

function Tooltip:HideAll()
    HideActive()
end

lib.Tooltip = Tooltip
return Tooltip
