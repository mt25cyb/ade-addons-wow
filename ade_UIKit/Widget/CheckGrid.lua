------------------------------------------------------------
-- 网格行族（b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowGrid.lua 更名）：
-- SubRow（组标题行 + 全选/全不选）、GridHeaderRow（列标题行）、GridRow（5 列复选网格）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry

-- [[ 构建 ]] --  KAF RowFrames.lua:273-299
function build.SubRow(parent)
    local row = build.Row("Frame", parent)
    row.Text = build.Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.All = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.All:SetSize(70, 20)
    row.None = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.None:SetSize(70, 20)
    row.None:SetPoint("LEFT", row.All, "RIGHT", 6, 0)
    return build.Finish(row, mixins.SubRow, { OnLoad = "OnLoad" })
end

function build.GridHeaderRow(parent) -- KAF :287-290：纯列标题行，All/None 属于 SubRow
    local row = build.Row("Frame", parent)
    return build.Finish(row, mixins.GridHeaderRow, { OnLoad = "OnLoad" })
end

function build.GridRow(parent)
    local row = build.Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = build.Hover(row)
    row.Label = build.Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetWidth(180)
    row.Label:SetPoint("LEFT", 16, 0)
    return build.Finish(row, mixins.GridRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ 行为 ]] --  KAF RowMixins.lua:619-705
mixins.SubRow = mixins.SubRow or {}
function mixins.SubRow:OnLoad() end
function mixins.SubRow:Init(element, window)
    self.Element, self.Window = element, window
    self.Text:SetText(element.Text or "")
    local strings = window and window.Strings or {}
    self.All:SetText(strings.All or "All")
    self.None:SetText(strings.None or "None")
    -- KAF SubRowMixin:Init：All 用 RowGeometry(0).Sub 定位，None 在构建器里相对 All。
    local g = Internal.RowGeometry(0)
    self.All:ClearAllPoints()
    self.All:SetPoint("LEFT", self, g.Sub[1], g.Sub[2], 0)
    local function apply(value)
        if element.setAll then element.setAll(value)
        else
            for _, option in ipairs(element.Members or {}) do
                if not option:IsDisabled() then option:Set(value) end
            end
        end
        window:OnOptionChanged()
    end
    self.All:SetScript("OnClick", function() apply(true) end)
    self.None:SetScript("OnClick", function() apply(false) end)
end

mixins.GridHeaderRow = mixins.GridHeaderRow or {}
function mixins.GridHeaderRow:OnLoad() end
function mixins.GridHeaderRow:Init(element)
    -- KAF GridHeaderRowMixin:Init：只有列标题，All/None 回 SubRow 家族标题行。
    self.Columns = self.Columns or {}
    for _, col in ipairs(self.Columns) do col:Hide() end
    for i, title in ipairs(element.Columns or {}) do
        local col = self.Columns[i]
        if not col then
            col = build.Text(self, "ARTWORK", "GameFontNormalSmall", "LEFT", "BOTTOM")
            col:SetPoint("TOP", 0, -6)
            self.Columns[i] = col
        end
        col:SetText(title)
        col:SetPoint("LEFT", geometry.GridLeft + (i - 1) * geometry.GridColumn, 0)
        col:Show()
    end
end

mixins.GridRow = mixins.GridRow or {}
function mixins.GridRow:OnLoad()
    self.Cells = {}
    for i = 1, 5 do -- KAF :673-687：固定 5 列，CENTER 锚到 gridLeft + (i-0.5)*gridColumn
        local cell = build.CheckButton(self)
        cell:SetPoint("CENTER", self, "LEFT", geometry.GridLeft + (i - 0.5) * geometry.GridColumn, 0)
        cell:SetScript("OnClick", function()
            local option = self.Element.Cells[i]
            if not option then return end
            option:Set(not option:Get())
            self.Window:OnOptionChanged(option)
        end)
        cell:HookScript("OnEnter", function() self:OnEnter(i) end)
        cell:HookScript("OnLeave", function() self:OnLeave() end)
        self.Cells[i] = cell
    end
end
function mixins.GridRow:Init(element, window)
    self.Element, self.Window = element, window
    self.Label:SetText(element.Label or "")
    self:Refresh()
end
function mixins.GridRow:Refresh()
    for i, cell in ipairs(self.Cells) do -- KAF :695-704：无 option 的单元格隐藏
        local option = self.Element and self.Element.Cells and self.Element.Cells[i]
        cell:SetShown(option ~= nil)
        if option then
            cell:SetChecked(option:Get() and true or false)
            cell:SetEnabled(not option:IsDisabled())
        end
    end
end
function mixins.GridRow:OnEnter(column)
    self.Hover:Show()
    if not self.Window then return end
    column = type(column) == "number" and column or 1
    local cell = self.Cells[column]
    self.Window:OnRowEnter(self.Element.Cells[column], self, cell) -- tooltip 锚在列复选框本身
end
function mixins.GridRow:OnLeave()
    self.Hover:Hide()
    if self.Window then self.Window:OnRowLeave(nil) end
end
