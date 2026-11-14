-- 复选框：框底固定 0.28 灰 + 纯黑边，只有「勾」随主题色；hover 只染边框。
-- 底本 955:1035:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Checkbox = W

function W.Create(parent, opts)
    opts = opts or {}
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(18, 18)
    local skin = AF.Stylize(cb, AF.C.CHECKBOX_FILL, AF.C.EDGE)
    cb.skin = skin

    cb.label = cb:CreateFontString(nil, "OVERLAY")
    cb.label:SetFontObject(AF.fontNormal)
    cb.label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    cb.label:SetText(opts.label or "")
    if opts.label and opts.label ~= "" then
        cb:SetHitRectInsets(0, -((cb.label:GetStringWidth() or 0) + 8), 0, 0)
    end

    -- 勾：自带材质（白勾 + 黑框），乘法染色 ⇒ 白勾变主题色、黑框保持黑
    local check = cb:CreateTexture(nil, "OVERLAY")
    check:SetTexture(AF.CHECK_TEX)
    check:SetSize(24 / 0.64, 24 / 0.64)
    check:SetPoint("CENTER", 0, 0)
    AF.Tint(check, "accent")
    check:Hide()
    cb.check = check

    local function Update(self) check:SetShown(self:GetChecked() and true or false) end
    local rawSetChecked = cb.SetChecked
    function cb:SetChecked(v) rawSetChecked(self, v); Update(self) end
    cb:SetScript("OnClick", function(self)
        Update(self)
        if opts.onChange then opts.onChange(self:GetChecked() and true or false) end
    end)
    cb:SetScript("OnEnter", function() skin:SetBorder(AF.ThemeColorTable(cb, "accent")) end)
    cb:SetScript("OnLeave", function() skin:SetBorder(AF.C.EDGE) end)
    -- 勾已由 AF.Tint 登记到弱表，主题变更时自动重刷，这里不需要额外订阅
    if opts.checked then cb:SetChecked(true) end
    return cb
end
