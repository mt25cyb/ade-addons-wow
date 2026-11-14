-- 下拉单选框：底固定灰、静置边与编辑框/按钮一致（暗色 1px），只有下拉箭头随主题色；hover/展开只染边框。
-- 底本 1504:1560:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
-- （2026-11-14 用户反馈：下拉静置边框原先是 0.22 灰，与其他控件黑边不一致 → 改回 EDGE）
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Dropdown = W

local menuFrame

local function EnsureMenu()
    if menuFrame then return menuFrame end
    menuFrame = CreateFrame("Frame", "AF_DropdownMenu", UIParent)
    menuFrame:SetFrameStrata("DIALOG")
    menuFrame:EnableMouse(true)
    menuFrame:Hide()
    local skin = AF.Stylize(menuFrame, AF.C.WIDGET_FILL, AF.C.EDGE)
    menuFrame.skin = skin
    menuFrame.rows = {}
    menuFrame:SetScript("OnHide", function(self)
        local owner = self.owner
        if owner and owner.skin then owner.skin:SetBorder(AF.C.EDGE) end
        self.owner = nil
    end)
    return menuFrame
end

local function AcquireRow(index)
    local m = EnsureMenu()
    local row = m.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, m)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 20)
    row:SetPoint("TOPRIGHT", -4, -4 - (index - 1) * 20)
    local fill = AF.Fill(row, AF.C.WIDGET_FILL, "BACKGROUND", 0)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetFontObject(AF.fontNormal)
    row.text:SetPoint("LEFT", 6, 0)
    row.text:SetPoint("RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("RIGHT", -4, 0)
    row:HookScript("OnEnter", function() fill:SetVertexColor(unpack(AF.C.BTN_HOVER)) end)
    row:HookScript("OnLeave", function() fill:SetVertexColor(unpack(AF.C.WIDGET_FILL)) end)
    m.rows[index] = row
    return row
end

function W.Create(parent, opts)
    opts = opts or {}
    local dd = CreateFrame("Button", nil, parent)
    local width = opts.width or 160
    dd:SetSize(width, 20)
    local skin = AF.Stylize(dd, AF.C.WIDGET_FILL, AF.C.EDGE)
    dd.skin = skin

    dd.text = dd:CreateFontString(nil, "OVERLAY")
    dd.text:SetFontObject(AF.fontNormal)
    dd.text:SetPoint("LEFT", 5, 0)
    dd.text:SetPoint("RIGHT", -16, 0)
    dd.text:SetJustifyH("LEFT")
    dd.text:SetWordWrap(false)

    -- 下拉箭头：贴图去色后再染主题色（素材本身是金色，直接染会红黄相加）
    local arrow = dd:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    arrow:SetRotation(math.rad(-90))
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -3, 0)
    arrow:SetDesaturated(true)
    AF.Tint(arrow, "accent")
    dd.arrow = arrow

    dd.items, dd.value = opts.items or {}, opts.value

    local function SyncText()
        local label = tostring(dd.value or "")
        for _, item in ipairs(dd.items) do
            if item.value == dd.value then label = item.text or label; break end
        end
        dd.text:SetText(label)
    end

    local function Open()
        local m = EnsureMenu()
        if m.owner and m.owner ~= dd then m:Hide() end
        m.owner = dd
        skin:SetBorder(AF.ThemeColorTable(dd, "accent"))
        for i, item in ipairs(dd.items) do
            local row = AcquireRow(i)
            row.text:SetText(item.text or "")
            if item.icon or item.atlas or item.texture then
                AF.ResolveIcon(row.icon, item.icon or item.atlas or item.texture, { atlas = item.atlas and true or nil })
                row.icon:Show()
            else
                row.icon:Hide()
            end
            row:SetScript("OnClick", function()
                dd.value = item.value
                SyncText()
                m:Hide()
                if opts.onSelect then opts.onSelect(item.value, item) end
            end)
            row:Show()
        end
        for i = #dd.items + 1, #m.rows do m.rows[i]:Hide() end
        m:SetSize(width, #dd.items * 20 + 8)
        m:ClearAllPoints()
        m:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        m:Show()
    end

    dd:SetScript("OnClick", function()
        if EnsureMenu().owner == dd and menuFrame:IsShown() then menuFrame:Hide() else Open() end
    end)
    dd:SetScript("OnEnter", function() skin:SetBorder(AF.ThemeColorTable(dd, "accent")) end)
    dd:SetScript("OnLeave", function()
        if not (menuFrame and menuFrame:IsShown() and menuFrame.owner == dd) then
            skin:SetBorder(AF.C.EDGE)
        end
    end)
    dd:HookScript("OnHide", function()
        if menuFrame and menuFrame.owner == dd then menuFrame:Hide() end
    end)

    function dd:SetItems(items) dd.items = items or {}; SyncText() end
    function dd:SetValue(v) dd.value = v; SyncText() end
    function dd:GetValue() return dd.value end
    SyncText()
    return dd
end
