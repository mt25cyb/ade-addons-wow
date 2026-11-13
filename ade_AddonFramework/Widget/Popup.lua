-- 确认/输入弹窗：边框随主题色、正文固定白；ESC 关闭。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Popup = W

local seq = 0

function W.Create(opts)
    opts = opts or {}
    seq = seq + 1
    local frame = CreateFrame("Frame", "AF_Popup" .. seq, AF.PopupParent or UIParent)
    frame:SetSize(opts.width or 320, opts.height or 130)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    local skin = AF.Stylize(frame, AF.C.PANEL, AF.ColorTable("accent"))
    AF.RegisterTheme(frame, function() skin:SetBorder(AF.ColorTable("accent")) end)
    frame.skin = skin

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject(AF.fontTitle)
    frame.title:SetPoint("TOP", 0, -10)
    frame.title:SetText(opts.title or "")

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetFontObject(AF.fontNormal)
    frame.text:SetPoint("TOPLEFT", 16, -36)
    frame.text:SetPoint("TOPRIGHT", -16, -36)
    frame.text:SetJustifyH("LEFT")
    frame.text:SetWordWrap(true)
    frame.text:SetText(opts.text or "")

    local close = AF.Widget.Icon.CreateButton(frame, {
        size = 16, atlas = "common-icon-redx", tooltip = AF.L["AF_CLOSE"],
        onClick = function() frame:Hide() end,
    })
    close:SetPoint("TOPRIGHT", -5, -4)
    close:SetFrameLevel(frame:GetFrameLevel() + 2)

    function frame:Close() self:Hide() end
    function frame:Open() self:Show() end
    frame:Hide()
    return frame
end

function W.Confirm(opts)
    opts = opts or {}
    local frame = W.Create(opts)
    local ok = AF.Widget.Button.Create(frame, {
        text = opts.acceptText or AF.L["AF_OK"], width = 100, variant = "primary",
        onClick = function() frame:Hide(); if opts.onAccept then opts.onAccept() end end,
    })
    ok:SetPoint("BOTTOMRIGHT", -12, 12)
    local cancel = AF.Widget.Button.Create(frame, {
        text = opts.cancelText or AF.L["AF_CANCEL"], width = 100,
        onClick = function() frame:Hide(); if opts.onCancel then opts.onCancel() end end,
    })
    cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
    return frame
end

function W.Input(opts)
    opts = opts or {}
    local frame = W.Create({ title = opts.title, text = opts.text, width = opts.width or 340, height = 160 })
    local eb = AF.Widget.Editbox.CreateSingle(frame, (frame:GetWidth() or 340) - 32, 22)
    eb:SetPoint("TOP", 0, -70)
    frame.editBox = eb
    local ok = AF.Widget.Button.Create(frame, {
        text = AF.L["AF_OK"], width = 100, variant = "primary",
        onClick = function()
            frame:Hide()
            if opts.onAccept then opts.onAccept(eb:GetText()) end
        end,
    })
    ok:SetPoint("BOTTOMRIGHT", -12, 12)
    function frame:SetText(t) eb:SetText(t or "") end
    return frame
end
