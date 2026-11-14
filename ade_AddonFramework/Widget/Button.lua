-- 普通按钮：字固定白、底固定灰；hover 只改底一阶。边框一律暗色 1px 细边、不随主题色
-- （2026-11-13 用户反馈：按 MiliUI 风格按钮边框是暗色细边；主题色只用于 primary 变体的底）。
-- 底本 190:300、432:451:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Button = W

function W.Create(parent, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(opts.width or 64, opts.height or 20)
    local skin = AF.Stylize(b, AF.C.WIDGET_FILL, AF.C.EDGE)

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetJustifyH("CENTER")
    fs:SetWordWrap(false)
    fs:SetFontObject(AF.fontNormal)
    b:SetFontString(fs)
    b:SetNormalFontObject(AF.fontNormal)
    b:SetDisabledFontObject(AF.fontNormal)
    b:SetText(opts.text or "")
    b:SetPushedTextOffset(0, -1)
    b.text, b.variant = fs, opts.variant or "normal"
    b.skin = skin

    function b:Paint(hover)
        if not self:IsEnabled() then
            if self.variant == "primary" then
                -- primary 停用：退回中性（底+边都收掉），停用按钮不能看起来像能按
                skin:SetFill(AF.C.WIDGET_FILL)
                skin:SetBorder(AF.C.EDGE)
            else
                -- accent/red/green/normal 停用：底色保留静置色、只把字转灰
                -- （对齐 MiliUI：停用按钮不退底，只灰字；否则淡强调色底会被吃成灰）
            end
            fs:SetTextColor(unpack(AF.C.TEXT_DISABLED))
            return
        end
        -- 边框永远保持创建时的暗色，任何变体/hover 都不改（skin:SetBorder 只在创建时调用一次）
        if self.variant == "primary" then
            skin:SetFill(hover and AF.ThemeColorTable(self, "accent") or AF.ThemeColorTable(self, "accentDim"))
            fs:SetTextColor(unpack(AF.C.TEXT_MAIN))
        elseif self.variant == "accent" then
            -- 静置淡强调色、hover 满强调色（MiliUI "accent" 变体：idle=accent×0.3、hover=accent×0.6）
            skin:SetFill(hover and AF.ThemeColorTable(self, "accent") or AF.ThemeColorTable(self, "accentDim"))
            AF.Tint(fs, "accent")
        elseif self.variant == "red" then
            skin:SetFill(hover and { 0.6, 0.1, 0.1, 1 } or { 0.6, 0.1, 0.1, 0.6 })
            fs:SetTextColor(unpack(AF.C.TEXT_MAIN))
        elseif self.variant == "green" then
            skin:SetFill(hover and { 0.1, 0.6, 0.1, 1 } or { 0.1, 0.6, 0.1, 0.6 })
            fs:SetTextColor(unpack(AF.C.TEXT_MAIN))
        else
            skin:SetFill(hover and AF.C.BTN_HOVER or AF.C.WIDGET_FILL)
            fs:SetTextColor(unpack(AF.C.TEXT_MAIN))
        end
    end

    b:SetScript("OnEnter", function() b:Paint(true) end)
    b:SetScript("OnLeave", function() b:Paint(false) end)
    -- 第一个参数必须是按钮框本身：调用方用它作弹层锚点（ContextMenu）/发光宿主（Glow）
    b:SetScript("OnClick", function(self, button)
        if opts.onClick then opts.onClick(self, button) end
    end)
    local rawSetEnabled = b.SetEnabled
    function b:SetEnabled(on) rawSetEnabled(self, on); self:Paint(false) end

    AF.RegisterTheme(b, function() b:Paint(false) end)
    b:Paint(false)
    return b
end

function W.SetVariant(b, variant)
    b.variant = variant or "normal"
    b:Paint(false)
end

--- 译文比基准宽的语系：按字宽撑开按钮，链式锚点会让后面的按钮跟着让位。
-- 依据 251:253:…/Widgets.lua 与规划 §十.2
function W.FitButton(b, minW, h)
    local w = math.max(minW or 64, math.ceil((b.text:GetStringWidth() or 0) + 12))
    b:SetSize(w, h or b:GetHeight() or 20)
    return w
end
