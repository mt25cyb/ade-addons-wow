-- 右键菜单：勾用原生 Atlas（不使用勾字符），标题/分隔线/tooltip/keepOpen。
-- 勾的贴图底本 205:218:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/ContextMenu.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.ContextMenu = W

local menu = CreateFrame("Frame", "AF_ContextMenu", UIParent)
menu:SetFrameStrata("DIALOG")
menu:EnableMouse(true)
menu:Hide()
local menuSkin = AF.Stylize(menu, AF.C.WIDGET_FILL, AF.C.EDGE)
menu.rows = {}

local function Acquire(index)
    local row = menu.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, menu)
    row:SetHeight(20)
    local fill = AF.Fill(row, AF.C.WIDGET_FILL, "BACKGROUND", 0)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetFontObject(AF.fontNormal)
    row.text:SetPoint("LEFT", 22, 0)
    row.text:SetPoint("RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetSize(14, 14)
    row.check:SetPoint("LEFT", 4, 0)
    row:HookScript("OnEnter", function() fill:SetVertexColor(unpack(AF.C.BTN_HOVER)) end)
    row:HookScript("OnLeave", function() fill:SetVertexColor(unpack(AF.C.WIDGET_FILL)) end)
    menu.rows[index] = row
    return row
end

function W.Show(entries, anchor, opts)
    opts = opts or {}
    local y, maxW = 0, 140
    for i, entry in ipairs(entries or {}) do
        local row = Acquire(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 4, -4 - y)
        row:SetPoint("TOPRIGHT", -4, -4 - y)
        if entry.isTitle then
            row.text:SetText(entry.text or "")
            row.text:SetTextColor(unpack(AF.C.TEXT_MUTED))
            row.check:Hide()
            row:SetScript("OnClick", nil)
        elseif entry.isDivider then
            row.text:SetText("")
            row.check:Hide()
            row:SetScript("OnClick", nil)
            local line = AF.Fill(row, AF.C.DD_BORDER, "ARTWORK", 0)
            line:ClearAllPoints()
            line:SetPoint("LEFT", 4, 0)
            line:SetPoint("RIGHT", -4, 0)
            line:SetHeight(AF.Pixel(row))
        else
            row.text:SetText(entry.text or "")
            row.text:SetTextColor(unpack(AF.C.TEXT_MAIN))
            AF.ResolveIcon(row.check, { atlas = "common-icon-checkmark" }, { atlas = true })
            row.check:SetShown(entry.checked and true or false)
            row:SetScript("OnClick", function(_, button)
                if entry.onClick then entry.onClick(button) end
                if not entry.keepOpen then menu:Hide() end
            end)
            row:SetScript("OnEnter", function()
                if entry.tooltip then
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetText(entry.tooltip, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        maxW = math.max(maxW, (row.text:GetStringWidth() or 0) + 46)
        y = y + 20
        row:Show()
    end
    for i = #(entries or {}) + 1, #menu.rows do menu.rows[i]:Hide() end
    menu:SetSize(maxW, y + 8)
    menu:ClearAllPoints()
    -- 锚点必须是 Frame/Region；调用方误传（如 onClick 的 button 字符串）时落到当前光标位置
    if type(anchor) ~= "table" or not anchor.GetBottom then
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale() or 1
        menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s - 2)
    else
        menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    end
    menu:Show()
    return menu
end

function W.Hide() menu:Hide() end
function W.IsOpen() return menu:IsShown() end
