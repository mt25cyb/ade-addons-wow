--[[
adeMapMark - Settings（地图 Tab 与内嵌设置窗口）
定位：LibWorldMapTabs 托管 Tab；主面板/设置面板双 panel + 齿轮切换；行契约数据驱动
体系：ADE v6.5
来源：WorldQuestTab Settings.lua/.xml（行契约 + 滚动列表）+ LibWorldMapTabs API
计划：_docs/plans/adeMapMark-dev-plan.md §4.3/§4.4
]]

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L

local PanelIDEnum = _G.adeMapMarkPanelID

local tabLib = LibStub("LibWorldMapTabs")
local contentFrame, settingsFrame, activeTab, gearButton

-- ---------------------------------------------------------------------------
-- 分组（WQT_SettingsCategoryMixin 同款：点击展开/折叠 + 折叠图标切换）
-- 证据：WorldQuestTab/Settings.lua:742-783、Settings.xml:7-126
-- ---------------------------------------------------------------------------

local CategoryMixin = {}
function CategoryMixin:Init(data)
    self.data = data
    self.isExpanded = data.expanded == true
    if self.Label then self.Label:SetText(data.label or "") end
    self:UpdateState()
end
function CategoryMixin:UpdateState()
    if self.ExpandIcon then
        self.ExpandIcon:SetAtlas(self.isExpanded and "UI-QuestTrackerButton-Secondary-Collapse" or "UI-QuestTrackerButton-Secondary-Expand", true)
    elseif self.BGRight then
        self.BGRight:SetAtlas(self.isExpanded and "Options_ListExpand_Right_Expanded" or "Options_ListExpand_Right", true)
    end
end
function CategoryMixin:OnClick()
    if self.data and self.data.onToggle then self.data.onToggle() end
end
function CategoryMixin:OnMouseDown()
    if self.Label then self.Label:AdjustPointsOffset(1, -1) end
end
function CategoryMixin:OnMouseUp()
    if self.Label then self.Label:AdjustPointsOffset(-1, 1) end
end
function CategoryMixin:OnEnter() end
function CategoryMixin:OnLeave() end

-- ---------------------------------------------------------------------------
-- 行契约 mixin（6 类）
-- ---------------------------------------------------------------------------

local RowBaseMixin = {}
function RowBaseMixin:Init(data)
    self.data = data
    if self.Label then
        self.Label:SetText(data.label or "")
        if data.indent then self.Label:SetPoint("LEFT", 42 + data.indent, 0) end
    end
    if self.BgHighlight then self.BgHighlight:Hide() end
    if self.UpdateState then self:UpdateState() end
end
function RowBaseMixin:IsDisabled() return self.data and self.data.disabled == true end
function RowBaseMixin:UpdateState() end
function RowBaseMixin:OnLoad() end
function RowBaseMixin:OnValueChanged(value, userInput)
    if self.data and self.data.onChanged then self.data.onChanged(value, userInput) end
end
function RowBaseMixin:OnEnter()
    if self.BgHighlight then self.BgHighlight:Show() end
    if self.data and self.data.tooltip and GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, -20)
        GameTooltip:SetText(self.data.tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end
function RowBaseMixin:OnLeave()
    if self.BgHighlight then self.BgHighlight:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

-- 复选框：WQT_SettingCheckboxTemplate（CheckButton + Label，整行可点）
local CheckboxMixin = CreateFromMixins(RowBaseMixin)
function CheckboxMixin:OnLoad()
    local row = self
    if self.CheckBox then
        self.CheckBox:SetScript("OnClick", function(btn)
            row:OnValueChanged(btn:GetChecked(), true)
        end)
    end
    self:SetScript("OnClick", function()
        if not row.CheckBox then return end
        row.CheckBox:SetChecked(not row.CheckBox:GetChecked())
        row:OnValueChanged(row.CheckBox:GetChecked(), true)
    end)
end
function CheckboxMixin:UpdateState()
    if self.CheckBox then
        self.CheckBox:SetChecked(self.data and self.data.value == true)
        self.CheckBox:SetEnabled(not self:IsDisabled())
    end
end

-- 滑动条：WQT_SettingSliderTemplate（MinimalSliderWithSteppers + 数值框）
local SliderMixin = CreateFromMixins(RowBaseMixin)
function SliderMixin:OnLoad()
    local row = self
    if self.TextBox then self.TextBox.parent = self end
    if self.SliderWithSteppers then
        self.SliderWithSteppers:RegisterCallback("OnValueChanged", function(_, value)
            row:OnValueChanged(value, true)
        end, self)
    end
end
function SliderMixin:Init(data)
    RowBaseMixin.Init(self, data)
    self.min = data.min or 0
    self.max = data.max or 100
    local step = data.step or 1
    local steps = math.max(1, math.floor((self.max - self.min) / step))
    local value = ns.clamp(data.value or self.min, self.min, self.max)
    if self.SliderWithSteppers then
        self.SliderWithSteppers:Init(value, self.min, self.max, steps)
        self.SliderWithSteppers:SetValue(value)
    end
    if self.TextBox then self.TextBox:SetText(tostring(math.floor(value))) end
end
function SliderMixin:UpdateState()
    local enabled = not self:IsDisabled()
    if self.SliderWithSteppers then self.SliderWithSteppers:SetEnabled(enabled) end
    if self.TextBox then self.TextBox:SetEnabled(enabled) end
end
function SliderMixin:OnValueChanged(value, userInput)
    value = tonumber(value)
    if not value then return end
    value = ns.clamp(math.floor(value), self.min or 0, self.max or 100)
    if self.TextBox then self.TextBox:SetText(tostring(value)) end
    RowBaseMixin.OnValueChanged(self, value, userInput)
end

-- 下拉框：WQT_SettingDropDownTemplate（WowStyle1DropdownTemplate + SetupMenu）
local DropdownMixin = CreateFromMixins(RowBaseMixin)
function DropdownMixin:OnValueChanged(value, userInput)
    RowBaseMixin.OnValueChanged(self, value, userInput)
    self:UpdateState()
end
function DropdownMixin:UpdateState()
    if not self.data or not self.Dropdown then return end
    local row, current = self, self.data.value
    local text = tostring(current or "")
    for _, item in ipairs(self.data.items or {}) do
        if item.value == current then text = item.text; break end
    end
    -- WowStyle1DropdownTemplate 的主文本由 SetDefaultText 提供；Button:SetText 对它无效
    if self.Dropdown.SetDefaultText then self.Dropdown:SetDefaultText(text) end
    if self.Dropdown.SetupMenu then
        self.Dropdown:SetupMenu(function(_, rootDescription)
            for _, item in ipairs(row.data.items or {}) do
                rootDescription:CreateRadio(item.text, function() return item.value == current end, function()
                    row:OnValueChanged(item.value, true)
                end)
            end
        end)
    end
    self.Dropdown:SetEnabled(not self:IsDisabled())
end

-- 颜色：WQT_SettingColorTemplate（Picker + LootBanner-IconGlow）
local ColorMixin = CreateFromMixins(RowBaseMixin)
function ColorMixin:OnLoad()
    local row = self
    if self.Picker then
        self.Picker:SetScript("OnClick", function()
            local c = ns.cloneColor(row.data and row.data.value)
            ColorPickerFrame:SetupColorPickerAndShow({
                r = c.r, g = c.g, b = c.b,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    if row.Picker and row.Picker.Color then row.Picker.Color:SetColorTexture(r, g, b, 1) end
                    RowBaseMixin.OnValueChanged(row, { r = r, g = g, b = b }, true)
                end,
            })
        end)
    end
end
function ColorMixin:UpdateState()
    local c = ns.cloneColor(self.data and self.data.value)
    if self.Picker and self.Picker.Color then self.Picker.Color:SetColorTexture(c.r, c.g, c.b, c.a) end
    if self.Picker then self.Picker:SetEnabled(not self:IsDisabled()) end
end

-- 外挂标记行：可见性勾选 + 单标颜色覆写 + 收藏星标（同一行，避免两行堆叠）
local REPUTATION_STAR = "Interface\\Common\\ReputationStar"

local ExternalMarkMixin = CreateFromMixins(RowBaseMixin)
function ExternalMarkMixin:OnLoad()
    local row = self
    if self.CheckBox then
        self.CheckBox:SetScript("OnClick", function(btn)
            row:OnValueChanged(btn:GetChecked(), true)
        end)
    end
    if self.Picker then
        self.Picker:SetScript("OnClick", function()
            local c = ns.cloneColor(row.data and row.data.color)
            ColorPickerFrame:SetupColorPickerAndShow({
                r = c.r, g = c.g, b = c.b,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    local newColor = { r = r, g = g, b = b, a = c.a or 1 }
                    if row.data then row.data.color = newColor end
                    if row.Picker and row.Picker.Color then row.Picker.Color:SetColorTexture(r, g, b, newColor.a) end
                    if row.data and row.data.onColorChanged then row.data.onColorChanged(newColor) end
                end,
            })
        end)
    end
    if self.Favorite then
        self.Favorite:SetScript("OnClick", function()
            if not row.data then return end
            row.data.favorite = not row.data.favorite
            row:UpdateState()
            if row.data.onFavoriteChanged then row.data.onFavoriteChanged(row.data.favorite) end
        end)
    end
    self:SetScript("OnClick", function()
        if not row.CheckBox then return end
        row.CheckBox:SetChecked(not row.CheckBox:GetChecked())
        row:OnValueChanged(row.CheckBox:GetChecked(), true)
    end)
end
function ExternalMarkMixin:UpdateState()
    local data = self.data
    if self.CheckBox then
        self.CheckBox:SetChecked(data and data.value == true)
        self.CheckBox:SetEnabled(not self:IsDisabled())
    end
    local c = ns.cloneColor(data and data.color)
    if self.Picker and self.Picker.Color then self.Picker.Color:SetColorTexture(c.r, c.g, c.b, c.a) end
    if self.Picker then self.Picker:SetEnabled(not self:IsDisabled()) end
    -- 星标：ReputationStar 是 2x2 图集，必须裁切象限才是单颗五角星（BDmap.lua:1906/1958）
    local star = self.Favorite and self.Favorite.Star
    if star then
        star:SetTexture(REPUTATION_STAR)
        if data and data.favorite then
            star:SetTexCoord(0, 0.5, 0, 0.5)
        else
            star:SetTexCoord(0.5, 1, 0, 0.5)
        end
    end
    if self.Favorite then self.Favorite:SetEnabled(not self:IsDisabled()) end
end

-- 按钮：WQT_SettingFunctionButtonTemplate（UIMenuButtonStretch）
local ButtonMixin = CreateFromMixins(RowBaseMixin)
function ButtonMixin:OnLoad()
    local row = self
    if self.Button then
        self.Button:SetScript("OnClick", function()
            if row.data and row.data.onClick then row.data.onClick() end
        end)
    end
end
function ButtonMixin:UpdateState()
    if self.Button then
        self.Button:SetText(self.data and self.data.text or (self.data and self.data.label or ""))
        self.Button:SetEnabled(not self:IsDisabled())
    end
end

-- 分隔线：WQT_SettingSeparatorTemplate（ChallengeMode-ThinDivider）
local SeparatorMixin = CreateFromMixins(RowBaseMixin)
function SeparatorMixin:UpdateState()
    if self.Divider then self.Divider:SetShown(self.data and self.data.label == nil) end
end

local ROW_TEMPLATES = {
    checkbox  = { template = "adeMapMarkSettingCheckboxTemplate", mixin = CheckboxMixin, height = 32 },
    slider    = { template = "adeMapMarkSettingSliderTemplate", mixin = SliderMixin, height = 49 },
    dropdown  = { template = "adeMapMarkSettingDropdownTemplate", mixin = DropdownMixin, height = 55 },
    color     = { template = "adeMapMarkSettingColorTemplate", mixin = ColorMixin, height = 32 },
    button    = { template = "adeMapMarkSettingButtonTemplate", mixin = ButtonMixin, height = 32 },
    separator = { template = "adeMapMarkSettingSeparatorTemplate", mixin = SeparatorMixin, height = 16 },
    category  = { template = "adeMapMarkSettingCategoryTemplate", mixin = CategoryMixin, height = 34 },
    subcategory = { template = "adeMapMarkSettingSubCategoryTemplate", mixin = CategoryMixin, height = 36 },
    externalmark = { template = "adeMapMarkSettingExternalMarkTemplate", mixin = ExternalMarkMixin, height = 32 },
}

-- ---------------------------------------------------------------------------
-- 设置面板
-- ---------------------------------------------------------------------------

adeMapMarkSettingsPanelMixin = {}

function adeMapMarkSettingsPanelMixin:OnLoad()
    if self.TitleText then self.TitleText:SetText(L.SETTINGS) end
    self.view = CreateScrollBoxListLinearView()
    -- 只设 SetElementFactory：把初始化回调作为 factory 第二参传入。
    -- 不可再调用 SetElementInitializer，否则会覆盖 factory 并把函数误当模板名（C_XMLUtil.GetTemplateInfo 报错根因）。
    self.view:SetElementFactory(function(factory, data)
        local cfg = ROW_TEMPLATES[data.type] or ROW_TEMPLATES.checkbox
        factory(cfg.template, function(frame, elementData)
            if frame.rowType ~= elementData.type then
                frame.rowType = elementData.type
                Mixin(frame, cfg.mixin)
                frame:SetScript("OnEnter", function(self) self:OnEnter() end)
                frame:SetScript("OnLeave", function(self) self:OnLeave() end)
                if elementData.type == "category" or elementData.type == "subcategory" then
                    frame:SetScript("OnClick", function(self) self:OnClick() end)
                    frame:SetScript("OnMouseDown", function(self) self:OnMouseDown() end)
                    frame:SetScript("OnMouseUp", function(self) self:OnMouseUp() end)
                end
                if frame.OnLoad then frame:OnLoad() end
            end
            frame:Init(elementData)
        end)
    end)
    self.view:SetElementExtentCalculator(function(dataIndex, data)
        local cfg = ROW_TEMPLATES[data.type] or ROW_TEMPLATES.checkbox
        return cfg.height
    end)
    ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, self.view)
end

function adeMapMarkSettingsPanelMixin:OnShow()
    self:Reconstruct()
end

function adeMapMarkSettingsPanelMixin:Reconstruct()
    local dataProvider = CreateDataProvider()
    local db = ns.db()
    local collapsed = db.settings.collapsed
    if type(collapsed) ~= "table" then collapsed = {}; db.settings.collapsed = collapsed end
    local panel = self
    local function toggle(key)
        collapsed[key] = not collapsed[key]
        panel:Reconstruct()
    end

    -- ── 一级分组：综合 ──────────────────────────────────────────────────
    dataProvider:Insert({
        type = "category", label = L.SETTINGS_MARKERS,
        expanded = collapsed.general ~= false,
        onToggle = function() toggle("general") end,
    })
    if collapsed.general ~= false then
        dataProvider:Insert({
            type = "checkbox", label = L.SETTINGS_TOMTOM,
            value = db.settings.useTomTom == true,
            onChanged = function(v) db.settings.useTomTom = v end,
        })
        dataProvider:Insert({
            type = "checkbox", label = L.SETTINGS_MINIMAP,
            value = db.settings.showMinimapMarkers ~= false,
            onChanged = function(v) db.settings.showMinimapMarkers = v; ns.RefreshAllPins() end,
        })
        dataProvider:Insert({
            type = "checkbox", label = L.SETTINGS_ARROW,
            value = db.settings.useHandyArrow == true,
            onChanged = function(v)
                db.settings.useHandyArrow = v
                if ns.Plus and ns.Plus.SetHandyArrow then ns.Plus.SetHandyArrow(v) end
            end,
        })
        dataProvider:Insert({
            type = "checkbox", label = L.SETTINGS_LEFT_CLICK,
            value = db.settings.leftClickEditMode == true,
            onChanged = function(v) db.settings.leftClickEditMode = v end,
        })
        dataProvider:Insert({
            type = "slider", label = L.MARK_SIZE,
            min = 12, max = 36, step = 1, value = db.settings.lastSize or 22,
            onChanged = function(v) db.settings.lastSize = v end,
        })
        dataProvider:Insert({
            type = "dropdown", label = L.SETTINGS_DISPLAY_MODE,
            value = db.settings.displayMode or "icon",
            items = {
                { text = L.DISPLAY_MODE_ICON, value = "icon" },
                { text = L.DISPLAY_MODE_TEXT, value = "text" },
                { text = L.DISPLAY_MODE_BOTH, value = "both" },
            },
            onChanged = function(v)
                db.settings.displayMode = v
                ns.RefreshAllPins()
            end,
        })
        dataProvider:Insert({
            type = "color", label = L.MARK_COLOR,
            value = db.settings.lastColor,
            onChanged = function(c) db.settings.lastColor = c end,
        })
    end

    -- 外挂数据包管理已由主界面分组清单（勾选/颜色/收藏）承担，设置页不再重复展示。

    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

-- ---------------------------------------------------------------------------
-- Tab 接入
-- ---------------------------------------------------------------------------

function ns.SetupWorldMapTab(mainPanel)
    if activeTab then return end

    activeTab = tabLib:CreateTab({
        tooltipText = L.MARK_ALL,
        activeAtlas = "poi-hub",
        inactiveAtlas = "poi-hub",
    }, "adeMapMark_WorldMapTab")

    contentFrame = tabLib:CreateContentFrameForTab(activeTab, nil, "adeMapMarkContent")
    contentFrame:SetAllPoints(QuestMapFrame.ContentsAnchor)

    -- 面板锚点对齐 WorldQuestTab 的 WQT_WorldQuestFrame：
    --   TOPLEFT = ContentsAnchor y-29（给顶部工具栏留位），BOTTOMRIGHT = ContentsAnchor x-22（给滚动条/Tab 栏留位）
    -- 不能用 SetAllPoints(contentFrame)，否则标题栏被原生工具栏遮挡、滚动条外溢。
    local ca = QuestMapFrame.ContentsAnchor
    local function anchorPanel(frame)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", ca, "TOPLEFT", 0, -29)
        frame:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -22, 0)
    end

    -- 主面板挂到内容帧（两 panel 之一；沿用 EnsurePanel 已建好的背景/边框/标题栏）
    mainPanel:SetParent(contentFrame)
    anchorPanel(mainPanel)
    mainPanel.panelID = PanelIDEnum.Markers
    mainPanel.ChangePanel = function(_, id) contentFrame:ChangePanel(id) end

    -- 设置面板（XML 虚模板创建实例，挂到内容帧；手动挂 mixin/脚本/panelID）
    settingsFrame = CreateFrame("Frame", "adeMapMarkSettingsPanelInstance", contentFrame, "adeMapMarkSettingsPanelTemplate")
    anchorPanel(settingsFrame)
    Mixin(settingsFrame, adeMapMarkSettingsPanelMixin)
    settingsFrame.panelID = PanelIDEnum.Settings
    settingsFrame:SetScript("OnShow", settingsFrame.OnShow)
    settingsFrame:SetScript("OnLoad", settingsFrame.OnLoad)
    settingsFrame:OnLoad()
    settingsFrame.CloseButton:SetScript("OnClick", function()
        contentFrame:ChangePanel(PanelIDEnum.Markers)
    end)
    settingsFrame.CloseButton:SetScript("OnEnter", function(self)
        if self.texture then self.texture:SetAlpha(1) end
    end)
    settingsFrame.CloseButton:SetScript("OnLeave", function(self)
        if self.texture then self.texture:SetAlpha(0.5) end
    end)

    contentFrame.panels = {}
    contentFrame.panels[PanelIDEnum.Markers] = mainPanel
    contentFrame.panels[PanelIDEnum.Settings] = settingsFrame
    function contentFrame:ChangePanel(id)
        for panelID, f in pairs(self.panels) do f:SetShown(panelID == id) end
    end
    contentFrame:ChangePanel(PanelIDEnum.Markers)

    -- 设置入口按钮（对齐 WorldQuestTab：顶部工具栏右侧齿轮 questlog-icon-setting）
    gearButton = CreateFrame("Button", nil, mainPanel)
    gearButton:SetSize(15, 16)
    gearButton.Icon = gearButton:CreateTexture(nil, "ARTWORK")
    gearButton.Icon:SetAtlas("questlog-icon-setting", true)
    gearButton.Icon:SetPoint("CENTER")
    gearButton:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", 19, 25)
    gearButton:SetScript("OnClick", function() contentFrame:ChangePanel(PanelIDEnum.Settings) end)

    -- 供 /amm config 使用
    ns.OpenSettingsPanel = function()
        if WorldMapFrame then WorldMapFrame:Show() end
        tabLib:SetDisplayMode(activeTab.displayMode)
        contentFrame:ChangePanel(PanelIDEnum.Settings)
    end
end
