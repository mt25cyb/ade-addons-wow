-- 颜色编辑框：色块本身即用户选择的颜色（不随主题派生），边框聚焦时才染主题色。
-- SetupColorPickerAndShow 字段底本 1212:1241:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Color = W

function W.Create(parent, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(14, 14)
    local skin = AF.Stylize(b, { 1, 1, 1, 1 }, AF.C.EDGE)
    b.skin = skin

    b.label = b:CreateFontString(nil, "OVERLAY")
    b.label:SetFontObject(AF.fontNormal)
    b.label:SetPoint("LEFT", b, "RIGHT", 6, 0)
    b.label:SetText(opts.label or "")

    b.color = opts.color or { red = 1, green = 1, blue = 1 }

    function b:SetColor(c, silent)
        if not c then return end
        b.color = { red = c.red or c.r or 1, green = c.green or c.g or 1, blue = c.blue or c.b or 1 }
        skin:SetFill({ b.color.red, b.color.green, b.color.blue, 1 })
        if not silent and opts.onChange then opts.onChange(b.color.red, b.color.green, b.color.blue) end
    end

    b:SetScript("OnClick", function()
        local c = b.color
        local info = {
            r = c.red, g = c.green, b = c.blue,
            opacity = 1, hasOpacity = opts.hasAlpha and true or false,
            swatchFunc = function()
                local r, g, bl = ColorPickerFrame:GetColorRGB()
                b:SetColor({ red = r, green = g, blue = bl })
            end,
            opacityFunc = function()
                local r, g, bl = ColorPickerFrame:GetColorRGB()
                b:SetColor({ red = r, green = g, blue = bl })
            end,
            cancelFunc = function(prev)
                if prev then b:SetColor({ red = prev.r, green = prev.g, blue = prev.b }) end
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    b:SetScript("OnEnter", function() skin:SetBorder(AF.ThemeColorTable(b, "accent")) end)
    b:SetScript("OnLeave", function() skin:SetBorder(AF.C.EDGE) end)
    b:SetColor(b.color, true)
    return b
end
