------------------------------------------------------------
-- 页签排序行（单控件，b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowTabList.lua 更名）：
-- TabRow——位置序号 + 名称 + 显示复选框 + 上下移箭头（宿主排序页用）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry

-- [[ 构建 ]] --  KAF RowFrames.lua:301-328
-- b041：上下移箭头统一 common-icon 材质（用户指定，与 ListRow 一致）；
-- b042：旋转方向修正——SetRotation 正值 = 视觉逆时针（b041 的 +90° 把
-- backarrow（向左）转成了向下，用户实测方向用反）：-90° = 顺时针，向左→向上、向右→向下。
-- -disable 后缀为禁用态（SetEnabled(false) 自动切 Disabled 纹理）。
-- b046：与 ListRow 尾部按钮同款视觉——常态调暗（0.6 灰）+ 悬停高亮（提亮发白）。
local BTN_DIM = 0.6
local BTN_HOVER = 1.3

local function ArrowButton(parent, direction)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(22, 22)
    local atlas = direction == "Up" and "common-icon-backarrow" or "common-icon-forwardarrow"
    button:SetNormalTexture(atlas)
    button:SetPushedTexture(atlas)
    button:SetDisabledTexture(atlas .. "-disable")
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local tex = button[getter](button)
        if tex then tex:SetRotation(-math.rad(90)) end
    end
    -- 常态调暗（Normal/Pushed 纹理）；Disabled 走 -disable 灰材质不叠加
    button:GetNormalTexture():SetVertexColor(BTN_DIM, BTN_DIM, BTN_DIM)
    button:GetPushedTexture():SetVertexColor(BTN_DIM, BTN_DIM, BTN_DIM)
    button:SetScript("OnEnter", function(self)
        local tex = self:GetNormalTexture()
        if tex and self:IsEnabled() then tex:SetVertexColor(BTN_HOVER, BTN_HOVER, BTN_HOVER) end
    end)
    button:SetScript("OnLeave", function(self)
        local tex = self:GetNormalTexture()
        if tex and self:IsEnabled() then tex:SetVertexColor(BTN_DIM, BTN_DIM, BTN_DIM) end
    end)
    button:SetScript("OnEnable", function(self)
        local tex = self:GetNormalTexture()
        if tex then tex:SetVertexColor(BTN_DIM, BTN_DIM, BTN_DIM) end
    end)
    return button
end

function build.TabRow(parent)
    local row = build.Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = build.Hover(row)
    row.Position = build.Text(row, "ARTWORK", "GameFontDisable", "RIGHT")
    row.Position:SetWidth(20)
    row.Position:SetPoint("LEFT", 10, 0)
    row.Label = build.Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetPoint("LEFT", 70, 0)
    row.Source = build.Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Source:SetPoint("LEFT", row.Label, "RIGHT", 8, 0)
    row.ShowCheck = build.CheckButton(row)
    row.ShowCheck:SetPoint("LEFT", geometry.TabCheckX or 34, 0)
    row.Up = ArrowButton(row, "Up")
    row.Down = ArrowButton(row, "Down")
    row.Down:SetPoint("LEFT", row.Up, "RIGHT", 4, 0)
    return build.Finish(row, mixins.TabRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ 行为 ]] --  KAF RowMixins.lua:718-775：页签的位置、显隐复选框与上下移箭头。
mixins.TabRow = mixins.TabRow or {}
function mixins.TabRow:OnLoad()
    self.ShowCheck:SetScript("OnClick", function()
        local option = self.Element and self.Element.Item.Show
        if not option then return end
        option:Set(not option:Get())
        self.Window:OnOptionChanged(option)
    end)
    self.Up:SetScript("OnClick", function()
        if self.Element.Item.MoveUp then self.Element.Item.MoveUp(); self.Window:ReloadSection() end
    end)
    self.Down:SetScript("OnClick", function()
        if self.Element.Item.MoveDown then self.Element.Item.MoveDown(); self.Window:ReloadSection() end
    end)
    for _, control in ipairs({ self.ShowCheck, self.Up, self.Down }) do
        if control.SetMotionScriptsWhileDisabled then control:SetMotionScriptsWhileDisabled(true) end
        control:HookScript("OnEnter", function() self:OnEnter() end)
        control:HookScript("OnLeave", function() self:OnLeave() end)
    end
end
function mixins.TabRow:Init(element, window)
    self.Element, self.Window = element, window
    local item = element.Item
    self.Position:SetText(item.Position)
    self.Label:SetText(item.Show and item.Show:GetLabel() or item.Name or "")
    if self.Source then self.Source:SetText(item.Source or "") end
    local g = Internal.RowGeometry(0)
    self.Up:ClearAllPoints()
    self.Up:SetPoint("LEFT", self, g.TabArrows[1], g.TabArrows[2], 0)
    self.Up:SetEnabled(item.MoveUp ~= nil)
    self.Down:SetEnabled(item.MoveDown ~= nil)
    self:Refresh()
end
function mixins.TabRow:Refresh()
    local option = self.Element.Item.Show
    self.ShowCheck:SetShown(option ~= nil)
    if option then
        self.ShowCheck:SetChecked(option:Get() and true or false)
        self.ShowCheck:SetEnabled(not option:IsDisabled())
    end
end
function mixins.TabRow:OnEnter() self.Hover:Show() end
function mixins.TabRow:OnLeave() self.Hover:Hide() end
