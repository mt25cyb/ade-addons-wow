-- 预览按钮三态：GM-icon-visible / -hover / -pressed（用户已在游戏内验证存在）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.PreviewButton = W

function W.Create(parent, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(opts.size or 20, opts.size or 20)
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    b.texture = tex

    local function Set(atlas) AF.ResolveIcon(tex, { atlas = atlas }, { atlas = true }) end
    Set("GM-icon-visible")
    b:SetScript("OnEnter", function() Set("GM-icon-visible-hover") end)
    b:SetScript("OnLeave", function() Set(b.down and "GM-icon-visible-pressed" or "GM-icon-visible") end)
    b:SetScript("OnMouseDown", function() b.down = true; Set("GM-icon-visible-pressed") end)
    b:SetScript("OnMouseUp", function()
        b.down = false
        Set(b:IsMouseOver() and "GM-icon-visible-hover" or "GM-icon-visible")
    end)
    b:SetScript("OnClick", function(_, button) if opts.onClick then opts.onClick(button) end end)
    if opts.tooltip then
        b:HookScript("OnEnter", function()
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end
