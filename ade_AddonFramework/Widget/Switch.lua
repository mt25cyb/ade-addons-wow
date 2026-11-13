-- 胶囊开关：轨道固定灰，只有滑块随主题色；hover 只改边框。
-- 形态底本 217:238:z-ref_retail_Interface_AddOns/GoodRange/Style.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Switch = W

function W.Create(parent, opts)
    opts = opts or {}
    local sw = CreateFrame("Button", nil, parent)
    local w, h = opts.width or 42, opts.height or 18
    sw:SetSize(w, h)
    local skin = AF.Stylize(sw, AF.C.WIDGET_FILL, AF.C.EDGE)
    sw.skin = skin

    local knob = sw:CreateTexture(nil, "ARTWORK")
    knob:SetTexture(AF.WHITE)
    knob:SetSize(h - 6, h - 6)
    knob:SetPoint("LEFT", 3, 0)
    AF.Tint(knob, "accent", 0.75)
    sw.knob = knob

    sw.label = sw:CreateFontString(nil, "OVERLAY")
    sw.label:SetFontObject(AF.fontNormal)
    sw.label:SetPoint("LEFT", sw, "RIGHT", 8, 0)
    sw.label:SetText(opts.label or "")

    local function Place(on)
        knob:ClearAllPoints()
        if on then knob:SetPoint("RIGHT", -3, 0) else knob:SetPoint("LEFT", 3, 0) end
    end
    sw.on = opts.checked and true or false
    Place(sw.on)
    sw:SetScript("OnClick", function()
        sw.on = not sw.on
        Place(sw.on)
        if opts.onChange then opts.onChange(sw.on) end
    end)
    sw:SetScript("OnEnter", function() skin:SetBorder(AF.ColorTable("accent")) end)
    sw:SetScript("OnLeave", function() skin:SetBorder(AF.C.EDGE) end)
    function sw:SetChecked(on) sw.on = on and true or false; Place(sw.on) end
    function sw:GetChecked() return sw.on end
    return sw
end
