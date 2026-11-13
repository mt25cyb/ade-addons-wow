-- 单值滑动条：轨道固定灰 + 黑边，只有 8 x 8 滑块随主题色；三态后缀 editbox / value / none。
-- 底本 1041:1125:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Slider = W

function W.Create(parent, opts)
    opts = opts or {}
    local low, high, step = opts.min or 0, opts.max or 100, opts.step or 1
    local width = opts.width or 240
    local suffix = opts.suffix or "editbox" -- "editbox" | "value" | "none"
    local suffixW = (suffix == "none") and 0 or 54

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width, 20)

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetPoint("LEFT", 0, 0)
    slider:SetSize(width - suffixW, 10)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true) -- 2134:z-ref_wow-dev-doc/wow_API_wiki.gg/_2-1_Widget_API.md
    AF.Stylize(slider, AF.C.WIDGET_FILL, AF.C.EDGE)

    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture(AF.WHITE)
    thumb:SetSize(8, 8)
    AF.Tint(thumb, "accent", 0.75)
    slider:SetThumbTexture(thumb) -- 2140:z-ref_wow-dev-doc/wow_API_wiki.gg/_2-1_Widget_API.md
    slider:SetScript("OnEnter", function() AF.Tint(thumb, "accent", 1) end)
    slider:SetScript("OnLeave", function() AF.Tint(thumb, "accent", 0.75) end)

    local display
    if suffix == "editbox" then
        display = AF.Widget.Editbox.CreateSingle(holder, 48, 18)
        display:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        display:SetJustifyH("CENTER")
        display:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then slider:SetValue(AF.Quantize(v, low, high, step)) end
            self:ClearFocus()
        end)
    elseif suffix == "value" then
        display = holder:CreateFontString(nil, "OVERLAY")
        display:SetFontObject(AF.fontSmall)
        display:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        display:SetWidth(48)
        display:SetJustifyH("CENTER")
    end

    local function Refresh(v)
        local text = (step < 1) and string.format("%.2f", v) or tostring(AF.Round(v))
        if suffix == "editbox" then display:SetText(text) elseif suffix == "value" then display:SetText(text) end
    end

    slider:SetScript("OnValueChanged", function(_, v)
        v = AF.Quantize(v, low, high, step)
        Refresh(v)
        if opts.onChange then opts.onChange(v) end
    end)
    slider:SetScript("OnMouseWheel", function(_, delta)
        slider:SetValue(AF.Quantize(slider:GetValue() + delta * step, low, high, step))
    end)
    slider:EnableMouseWheel(true)

    holder.slider, holder.display, holder.suffix = slider, display, suffix
    function holder:SetValue(v) slider:SetValue(AF.Quantize(v, low, high, step)) end
    function holder:GetValue() return slider:GetValue() end
    holder:SetValue(opts.value or low)
    return holder
end
