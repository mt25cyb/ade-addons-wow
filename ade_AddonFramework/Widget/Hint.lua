-- 提示按钮：用原生 Atlas 代替「!」字符，避免字体缺字形。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Hint = W

function W.Create(parent, opts)
    opts = opts or {}
    local b = AF.Widget.Icon.CreateButton(parent, {
        size = opts.size or 16,
        atlas = "GM-icon-visible",
        tooltip = opts.text,
        onClick = opts.onClick,
    })
    return b
end

--- 自绘提示面板（可选）：显示多行说明文字。
function W.CreateTooltipPanel(parent, opts)
    opts = opts or {}
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(opts.width or 220, opts.height or 80)
    local skin = AF.Stylize(f, AF.C.PANEL, AF.C.EDGE)
    f.skin = skin
    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(AF.fontSmall)
    fs:SetPoint("TOPLEFT", 8, -8)
    fs:SetPoint("BOTTOMRIGHT", -8, 8)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(opts.text or "")
    f:Hide()
    return f
end
