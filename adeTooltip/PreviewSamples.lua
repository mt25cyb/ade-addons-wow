-- adeTooltip — 预览样例（C0 骨架）。
-- 修正旧版 UnitAura 误用：旧版取第 3 返回（实为 count 非 spellId）且未 pcall；
-- 本版统一用 SetHyperlink / SetUnit，绝不依赖 UnitAura 的返回位。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true, "adeTooltip")
if not AF then return end
local L = ADT.L or {}

function ADT:ShowPreviewSample(kind)
    if not GameTooltip then return end
    local tip = self.previewTip
    if not tip then
        tip = CreateFrame("GameTooltip", "adeTooltipPreviewTip", UIParent, "GameTooltipTemplate")
        self.previewTip = tip
    end
    tip:SetOwner(UIParent, "ANCHOR_CURSOR")
    tip:ClearLines()
    if kind == "unit" then
        -- SetUnit("player") 在玩家登录后可用；pcall 防未就绪。
        pcall(function() tip:SetUnit("player") end)
    elseif kind == "item" then
        -- 用物品超链接，稳定可复现（此处取一个通用物品）。
        tip:SetHyperlink("item:19019:0:0:0:0:0:0:0:0:0")
    elseif kind == "spell" then
        tip:SetHyperlink("spell:1")
    end
    tip:Show()
end

function ADT:PreviewSamplesBuild(content)
    local y = 8
    local note = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    note:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
    note:SetWidth((AF.LAYOUT and AF.LAYOUT.contentW or 640) - 16)
    note:SetText(L.PREVIEW_NOTE or "")
    note:SetJustifyH("LEFT")
    y = y + (note:GetStringHeight() or 32) + 12

    local samples = {
        { kind = "unit", label = L.PREVIEW_BTN_UNIT or "Preview: Player Unit" },
        { kind = "item", label = L.PREVIEW_BTN_ITEM or "Preview: Item" },
        { kind = "spell", label = L.PREVIEW_BTN_SPELL or "Preview: Spell" },
    }
    for _, s in ipairs(samples) do
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(220, 26)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
        btn:SetText(s.label)
        btn:SetScript("OnClick", function() ADT:ShowPreviewSample(s.kind) end)
        y = y + 32
    end

    if ADT.options and ADT.options.scroll then
        content:SetHeight(y + 8)
        ADT.options.scroll:SetContentHeight(y + 8)
    end
end
