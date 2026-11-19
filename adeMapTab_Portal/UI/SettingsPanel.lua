local _, addon = ...
local Settings = addon.Settings
local L = addon.L
-- 设置页骨架（背景 / 边框 / 标题 / 关闭按钮 / 滚动容器）由主插件公共函数创建。
local MapTab = LibStub("AdeMapTab-1.0")

-- 设置面板：参照 WorldQuestTab 的 Settings（整块面板切换、分组标题、每项带说明 tooltip）。
-- 取代旧的齿轮下拉菜单（UI/SettingsMenu.lua）；炉石多选在这里做成一组复选框行。

-- 尺寸取自 WorldQuestTab Settings.xml：
-- WQT_SettingCategoryTemplate y=34、WQT_SettingCheckboxTemplate y=32（CheckBox 缩进 40）、
-- WQT_SettingSliderTemplate y=49（Slider 锚 BOTTOMLEFT 40,4 → RIGHT -80）。
local ROW_HEIGHT = 32
local SLIDER_HEIGHT = 49
local CATEGORY_HEIGHT = 34
local CHECK_INDENT = 40
local CHILD_INDENT = 14

-- 区域按钮位置：「按钮位置」与「排列方向」已合并为一组预设（用户 2026-10-29），
-- value 与 ZoneTeleportButtons 的 LAYOUTS 表一一对应；基准偏移在那一侧定义。
local LAYOUT_OPTIONS = {
    { text = "SETTING_ZONE_BUTTONS_LAYOUT_TOPLEFT_ROW", value = "topLeftRow" },
    { text = "SETTING_ZONE_BUTTONS_LAYOUT_TOPLEFT_COLUMN", value = "topLeftColumn" },
    { text = "SETTING_ZONE_BUTTONS_LAYOUT_TOPRIGHT_ROW", value = "topRightRow" },
    { text = "SETTING_ZONE_BUTTONS_LAYOUT_BOTTOMRIGHT_ROW", value = "bottomRightRow" },
    { text = "SETTING_ZONE_BUTTONS_LAYOUT_BOTTOMRIGHT_COLUMN", value = "bottomRightColumn" },
}

--- 区域按钮的偏移按布局项各自独立（用户 2026-10-29）：这里取「当前布局」自己的那份。
local function CurrentOffset()
    local slot = addon.ZoneButtons and addon.ZoneButtons.OffsetFor and addon.ZoneButtons.OffsetFor()
    return slot or { x = 0, y = 0 }
end

-- 角色分组传送的类型筛选（多选，用户 2026-10-29）：炉石 / 职业 / 种族 / 住宅区。
local CHARACTER_FILTER_OPTIONS = {
    { text = "SETTING_ZONE_BUTTONS_FILTER_HEARTHSTONE", value = "hearthstone" },
    { text = "SETTING_ZONE_BUTTONS_FILTER_CLASS", value = "class" },
    { text = "SETTING_ZONE_BUTTONS_FILTER_RACE", value = "race" },
    { text = "SETTING_ZONE_BUTTONS_FILTER_HOUSING", value = "housing" },
}

local LAYOUT = {
    {
        category = "SETTINGS_CATEGORY_GENERAL",
        items = {
            { key = "teleportsWorldMapEnabled" },
            { key = "defaultTab" },
            { key = "showRecentTeleports" },
            { key = "recentTeleportsCount", kind = "slider", min = 1, max = 20, step = 1,
              get = function() return addon.db["recentTeleportsCount"] or 6 end,
              set = function(v) addon.db["recentTeleportsCount"] = v end },
            { key = "showFavorites" },
            { key = "portalHideMissing" },
            { key = "portalShowTooltip" },
            { key = "portalTooltipDestination", parent = "portalShowTooltip" },
        },
    },
    {
        category = "SETTINGS_CATEGORY_ZONE",
        items = {
            { key = "zoneButtonsEnabled" },
            { key = "zoneButtonsShowUnknown" },
            -- 「显示角色传送按钮」：在所有地图都显示角色分组的传送，不受当前地图限制；
            -- 类型筛选是它的子选项（用户 2026-10-29）。
            { key = "zoneButtonsShowCharacter" },
            { key = "zoneButtonsCharacterFilters", kind = "dropdown", multiselect = true,
              options = CHARACTER_FILTER_OPTIONS, child = true, parent = "zoneButtonsShowCharacter" },
            { key = "zoneButtonsShowContinent" },
            { key = "portalButtonSquare" },
            -- 禁用 Masque 皮肤：仅方形外观生效；圆形始终走自带圆形描边（照 EQoLPlusMapExt 关联禁用，parent 在圆形下置灰）。
            { key = "portalDisableMasque", parent = "portalButtonSquare" },
            { key = "portalButtonEdgeShadow", kind = "slider", min = 0, max = 4, step = 1,
              get = function() return addon.db["portalButtonEdgeShadow"] or 0 end,
              set = function(v) addon.db["portalButtonEdgeShadow"] = v end },
            -- 位置+排列合并为单一预设；按钮尺寸固定 28px，故不再有 size 行（用户 2026-10-29）。
            { key = "zoneButtonsLayout", kind = "dropdown", options = LAYOUT_OPTIONS },
            -- 这两个滑块读写的都是「当前布局项」的那份偏移，切换布局项时值随之切换。
            { key = "zoneButtonsOffsetX", kind = "slider", min = -100, max = 100, step = 1,
              get = function() return CurrentOffset().x end,
              set = function(value) CurrentOffset().x = value end },
            { key = "zoneButtonsOffsetY", kind = "slider", min = -100, max = 100, step = 1,
              get = function() return CurrentOffset().y end,
              set = function(value) CurrentOffset().y = value end },
        },
    },
}

-- 分组标题按钮：可点击折叠/展开。右端图集随展开态切换（WQT Settings.lua:754-761）。
-- 三件套纹理 / 高亮 / 标签由主插件公共函数创建，本文件只补 Portal 特有的交互与折叠态。
local function CreateCategoryButton(parent, text, onClick)
    local button = MapTab.CreateCategoryButton(parent, text)
    button.BGRight = button.Right

    button:SetScript("OnMouseDown", function(self)
        if self.Label then self.Label:AdjustPointsOffset(1, -1) end
    end)
    button:SetScript("OnMouseUp", function(self)
        if self.Label then self.Label:AdjustPointsOffset(-1, 1) end
    end)
    button:SetScript("OnClick", function(self)
        if onClick then onClick(self) end
    end)

    function button.SetExpandedState(self, expanded)
        self.isExpanded = expanded
        self.BGRight:SetAtlas(expanded and "Options_ListExpand_Right_Expanded" or "Options_ListExpand_Right", true)
    end

    return button
end

--- 设置项 key 是 camelCase（如 portalHideMissing），locale key 是 SCREAMING_SNAKE_CASE
--- （SETTING_PORTAL_HIDE_MISSING），必须转换后才能命中，否则会静默回退显示 key 本身。
local function SettingKey(key)
    return "SETTING_" .. string.upper(string.gsub(key, "(%l)(%u)", "%1_%2"))
end

--- 下一帧合并刷新，避免连点重复重建列表（旧齿轮菜单 Menu.Refresh 的同款节流）。
function Settings:Apply()
    if Settings.pending then return end
    Settings.pending = true
    C_Timer.After(0, function()
        Settings.pending = nil
        addon.Hearthstones.UpdateHomeEntry(true)
        if addon.MapPanel and addon.MapPanel.Refresh then addon.MapPanel.Refresh() end
        if addon.ZoneButtons and addon.ZoneButtons.Refresh then addon.ZoneButtons.Refresh() end
    end)
end

-- 复选框与行样式取自 WQT_SettingCheckboxTemplate：
-- checkbox-minimal / checkmark-minimal 图集、25x25、缩进 40、行背景 socialqueuing-row-select(ADD,0.1)。
local function CreateCheckButton(row, indent)
    local check = CreateFrame("CheckButton", nil, row)
    check:SetSize(25, 25)
    check:SetPoint("LEFT", indent or CHECK_INDENT, 0)
    -- CheckButton 没有 SetXxxAtlas：先占位纹理，再把图集刷到纹理上。
    -- 图集照 WQT_SettingCheckboxTemplate（checkbox-minimal / checkmark-minimal）。
    local function ApplyAtlas(texture, atlas)
        if texture and texture.SetAtlas then texture:SetAtlas(atlas, false) end
    end
    check:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    check:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    check:SetCheckedTexture("Interface\\Buttons\\WHITE8X8")
    check:SetDisabledCheckedTexture("Interface\\Buttons\\WHITE8X8")
    ApplyAtlas(check:GetNormalTexture(), "checkbox-minimal")
    ApplyAtlas(check:GetPushedTexture(), "checkbox-minimal")
    ApplyAtlas(check:GetCheckedTexture(), "checkmark-minimal")
    ApplyAtlas(check:GetDisabledCheckedTexture(), "checkmark-minimal-disabled")
    check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    row.Check = check

    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints(row)
    highlight:SetAtlas("socialqueuing-row-select", true)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.1)
    highlight:Hide()
    row.Highlight = highlight

    return check
end

local function CreateRowLabel(row)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", row.Check, "RIGHT", 5, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -15, 0)
    label:SetJustifyH("LEFT")
    row.Label = label
    return label
end

local function AttachTooltip(row, title, description, extra)
    row:SetScript("OnEnter", function(self)
        self.Highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0)
        if description then GameTooltip:AddLine(description, 1, 1, 1, true) end
        if extra then GameTooltip:AddLine(extra, 1, 0.4, 0.4, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.Highlight:Hide()
        GameTooltip:Hide()
    end)
end

-- 选项依赖：父开关关闭时子项禁用（如「在提示中添加传送目的地」依赖「在传送按钮上显示提示」）。
local PARENT_OF = {}
for _, section in ipairs(LAYOUT) do
    for _, item in ipairs(section.items or {}) do
        if item.key then PARENT_OF[item.key] = item.parent end
    end
end

local function CreateSettingRow(parent, key)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    CreateCheckButton(row)
    local labelKey = SettingKey(key)
    local descKey = labelKey .. "_DESC"
    local label = CreateRowLabel(row)
    label:SetText(L[labelKey] or key)

    local function ConflictText()
        if key == "defaultTab" and addon.MapPanel and addon.MapPanel.IsDefaultTabClaimed() then
            return L["SETTING_DEFAULT_TAB_CONFLICT"]
        end
        return nil
    end

    AttachTooltip(row, tostring(L[labelKey] or key), L[descKey], ConflictText())

    row:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        if key == "defaultTab" and addon.MapPanel and addon.MapPanel.IsDefaultTabClaimed() then return end
        addon.db[key] = not addon.db[key]
        -- row.Check 是自建子控件，LuaLS 认不出动态字段。
        ---@diagnostic disable-next-line: undefined-field
        row.Check:SetChecked(addon.db[key])
        if key == "teleportsWorldMapEnabled" and addon.MapPanel.Initialize then
            addon.MapPanel.Initialize()
        end
        -- Masque 开关可热切换：把已注册按钮退组 / 重新入组，不必 reload。
        if key == "portalDisableMasque" and addon.ButtonSkin and addon.ButtonSkin.RefreshAll then
            addon.ButtonSkin:RefreshAll()
        end
        Settings:Apply()
    end)

    row.RefreshState = function(self)
        local value = addon.db[key] == true
        self.Check:SetChecked(value)
        -- 父开关关闭时本项禁用（如「在提示中添加传送目的地」依赖「在传送按钮上显示提示」）。
        local disabled = (key == "defaultTab" and addon.MapPanel and addon.MapPanel.IsDefaultTabClaimed())
            or (PARENT_OF[key] and not addon.db[PARENT_OF[key]]) or false
        self.Check:SetEnabled(not disabled)
        self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    end

    return row
end

local function CreateRowHighlight(row)
    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints(row)
    highlight:SetAtlas("socialqueuing-row-select", true)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.1)
    highlight:Hide()
    row.Highlight = highlight
    row:EnableMouse(true)
    return highlight
end

--- 滑动条行：结构照 WQT_SettingSliderTemplate（标签在上、滑块在下、右侧数值）。
--- 控件用 MinimalSliderWithSteppersTemplate，与应用内其它设置观感一致。
local function CreateSliderRow(parent, item)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(SLIDER_HEIGHT)
    CreateRowHighlight(row)

    local labelKey = SettingKey(item.key)
    local descKey = labelKey .. "_DESC"

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 42, -7)
    label:SetPoint("RIGHT", -15, 0)
    label:SetJustifyH("LEFT")
    label:SetText(L[labelKey] or item.key)
    row.Label = label

    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetHeight(20)
    slider:SetPoint("BOTTOMLEFT", 40, 4)
    slider:SetPoint("RIGHT", -80, 0)
    row.Slider = slider

    -- 数值框：WQT 在滑块右侧额外挂一个 InputBoxTemplate（Settings.xml:299-315），
    -- 之前这里只是 FontString，只能拖不能输入（用户 2026-10-27 反馈）。
    local box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    box:SetSize(30, 20)
    box:SetPoint("LEFT", slider, "RIGHT", 10, 1)
    box:SetPoint("RIGHT", row, "RIGHT", -40, 1)
    box:SetAutoFocus(false)
    box:SetJustifyH("CENTER")
    box:SetMaxLetters(4)
    if NumberFont_Shadow_Small then box:SetFontObject(NumberFont_Shadow_Small) end
    row.Value = box

    AttachTooltip(row, tostring(L[labelKey] or item.key), L[descKey])

    local minValue, maxValue = item.min, item.max
    local step = item.step or 1
    local steps = math.max(1, math.floor((maxValue - minValue) / step))
    -- 默认直接读写 addon.db[key]；带 get/set 的项走自己的存取。区域按钮的偏移是
    -- 「每个布局项各一份」，同一个滑块在不同布局下对应不同的存档位置（用户 2026-10-29）。
    local function ReadValue()
        if item.get then return item.get() or minValue end
        return addon.db[item.key]
    end
    local function WriteValue(value)
        if item.set then item.set(value) return end
        addon.db[item.key] = value
    end
    slider:Init(Clamp(ReadValue() or minValue, minValue, maxValue), minValue, maxValue, steps)

    slider:RegisterCallback("OnValueChanged", function(_, newValue)
        if InCombatLockdown() then return end
        local rounded = math.floor((tonumber(newValue) or minValue) + 0.5)
        rounded = Clamp(rounded, minValue, maxValue)
        if not box:HasFocus() then box:SetText(tostring(rounded)) end
        if ReadValue() == rounded then return end
        WriteValue(rounded)
        Settings:Apply()
    end)

    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(ReadValue() or minValue))
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        local raw = tonumber(self:GetText())
        if raw and not InCombatLockdown() then
            local rounded = Clamp(math.floor(raw + 0.5), minValue, maxValue)
            WriteValue(rounded)
            row.Slider:SetValue(rounded)
            Settings:Apply()
        end
        self:SetText(tostring(ReadValue() or minValue))
    end)

    row.RefreshState = function(self)
        local current = Clamp(ReadValue() or minValue, minValue, maxValue)
        self.Slider:SetValue(current)
        if not box:HasFocus() then self.Value:SetText(tostring(current)) end
        self.Slider:SetEnabled(not InCombatLockdown())
        self.Label:SetFontObject(InCombatLockdown() and "GameFontDisable" or "GameFontNormal")
    end

    return row
end

--- 下拉行：区域按钮位置（左上/右上/左下/右下）。
local function CreateDropdownRow(parent, item)
    local indent = item.child and CHILD_INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    CreateRowHighlight(row)

    local labelKey = SettingKey(item.key)
    local descKey = labelKey .. "_DESC"

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", 42 + indent, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -160, 0)
    label:SetJustifyH("LEFT")
    label:SetText(L[labelKey] or item.key)
    row.Label = label

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetSize(130, 26)
    dropdown:SetPoint("RIGHT", -15, 0)
    row.Dropdown = dropdown

    local function CurrentValue()
        local stored = addon.db[item.key]
        for _, option in ipairs(item.options) do
            if option.value == stored then return option.value end
        end
        return item.options[1].value
    end

    -- 多选（item.multiselect）：值是一张 { [value] = true } 表，用 CreateCheckbox 呈现；
    -- 缺省/非表时按「全选」补齐（用户 2026-10-29）。
    local function SelectedSet()
        local set = addon.db[item.key]
        if type(set) ~= "table" then
            set = {}
            for _, option in ipairs(item.options) do set[option.value] = true end
            addon.db[item.key] = set
        end
        return set
    end

    dropdown:SetupMenu(function(_, root)
        if item.multiselect then
            local set = SelectedSet()
            for _, option in ipairs(item.options) do
                local value = option.value
                local text = L[option.text] or tostring(value)
                root:CreateCheckbox(text, function() return set[value] == true end, function()
                    if InCombatLockdown() then return end
                    set[value] = not set[value] or nil
                    Settings:Apply()
                    if addon.ZoneButtons and addon.ZoneButtons.Refresh then addon.ZoneButtons.Refresh() end
                end)
            end
            return
        end
        for _, option in ipairs(item.options) do
            local value = option.value
            local text = L[option.text] or value
            root:CreateRadio(text, function() return CurrentValue() == value end, function()
                if InCombatLockdown() then return end
                addon.db[item.key] = value
                Settings:Apply()
            end)
        end
    end)

    AttachTooltip(row, tostring(L[labelKey] or item.key), L[descKey])

    row.RefreshState = function(self)
        if item.multiselect then
            local set = SelectedSet()
            local names, count = {}, 0
            for _, option in ipairs(item.options) do
                if set[option.value] then
                    count = count + 1
                    names[#names + 1] = L[option.text] or tostring(option.value)
                end
            end
            local summary
            if count == #item.options then
                summary = L["ZONE_FILTER_ALL"] or tostring(count)
            elseif count == 0 then
                summary = L["ZONE_FILTER_NONE"] or "0"
            else
                summary = table.concat(names, "/")
            end
            self.Dropdown:SetDefaultText(summary)
        else
            local current = CurrentValue()
            for _, option in ipairs(item.options) do
                if option.value == current then
                    self.Dropdown:SetDefaultText(L[option.text] or current)
                    break
                end
            end
        end
        -- 子选项：父开关关闭时灰掉不可用（用户 2026-10-29）。
        local disabled = (item.parent and not addon.db[item.parent]) or false
        self.Dropdown:SetEnabled(not disabled and not InCombatLockdown())
        self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    end

    return row
end

-- ============ 偏好炉石（多选，取代旧齿轮菜单的子菜单） ============

local function IsRandomSelection()
    local selection = addon.db and addon.db["teleportsPreferredHearthstone"]
    return type(selection) ~= "table" or next(selection) == nil
end

local function SetAllHearthstonesSelected()
    local selection = {}
    for _, option in ipairs(addon.Hearthstones.GetSelectionOptions(true)) do
        selection[option.value] = true
    end
    addon.db["teleportsPreferredHearthstone"] = selection
    return selection
end

--- 勾选某个炉石；全选时回落为「随机」（空表 = 随机，与旧菜单一致）。
local function ToggleHearthstone(key)
    if InCombatLockdown() then return end
    local selection = addon.db["teleportsPreferredHearthstone"]
    if IsRandomSelection() then selection = SetAllHearthstonesSelected() end

    selection[key] = not selection[key] or nil

    local allSelected = true
    local options = addon.Hearthstones.GetSelectionOptions(true)
    if #options == 0 then allSelected = false end
    for _, option in ipairs(options) do
        if selection[option.value] ~= true then allSelected = false; break end
    end
    if allSelected then addon.db["teleportsPreferredHearthstone"] = {} end

    Settings:Apply()
end

local function CreateHearthstoneRow(parent, key, text, isRandom)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    CreateCheckButton(row, isRandom and CHECK_INDENT or (CHECK_INDENT + CHILD_INDENT))
    local label = CreateRowLabel(row)
    label:SetText(text)
    row.key = key
    row.isRandom = isRandom

    AttachTooltip(
        row,
        text,
        isRandom and L["SETTING_TELEPORTS_PREFERRED_HEARTHSTONE_RANDOM_DESC"] or nil
    )

    row:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        if isRandom then
            addon.db["teleportsPreferredHearthstone"] = {}
        else
            ToggleHearthstone(key)
        end
        Settings:Apply()
    end)

    row.RefreshState = function(self)
        if self.isRandom then
            self.Check:SetChecked(IsRandomSelection())
        else
            local selection = addon.db["teleportsPreferredHearthstone"]
            self.Check:SetChecked(IsRandomSelection() or (type(selection) == "table" and selection[self.key] == true))
        end
        self.Check:SetEnabled(not InCombatLockdown())
        self.Label:SetFontObject(InCombatLockdown() and "GameFontDisable" or "GameFontHighlight")
    end

    return row
end

--- 炉石列表是动态的（拥有数量会变），每次刷新都重建这一组。
--- 只负责更新内容，显示与否由 AnchorRows 统一控制（折叠时不能残留可见行）。
local function RebuildHearthstoneRows(frame)
    local row = frame.hearthstoneRows[1]
    if not row then
        row = CreateHearthstoneRow(frame.Content, "random", L["SETTING_TELEPORTS_PREFERRED_HEARTHSTONE_RANDOM"], true)
        frame.hearthstoneRows[1] = row
    end
    row:SetParent(frame.Content)

    local options = addon.Hearthstones and addon.Hearthstones.GetSelectionOptions
        and addon.Hearthstones.GetSelectionOptions(true) or {}
    for index, option in ipairs(options) do
        local entryRow = frame.hearthstoneRows[index + 1]
        if not entryRow then
            entryRow = CreateHearthstoneRow(frame.Content, option.value, option.text)
            frame.hearthstoneRows[index + 1] = entryRow
        end
        entryRow.key = option.value
        entryRow.Label:SetText(option.text)
        entryRow:SetParent(frame.Content)
    end

    for index = #options + 2, #frame.hearthstoneRows do
        frame.hearthstoneRows[index]:Hide()
    end

    return 1 + #options
end

function Settings:Create(parent)
    -- 骨架逐行同构于 WorldQuestTab Settings.xml:744-794 与 adeMapTab_Delve，
    -- 已抽到主插件 MapTab.CreateSettingsFrame（含 12.x MinimalScrollBar 重锚、Update
    -- 与 frame.UpdateScrollRange）。子插件专属字段经 opts.init 追加。
    return MapTab.CreateSettingsFrame(parent, {
        title = L["SETTINGS_TITLE"],
        closeTooltip = L["SETTINGS_CLOSE"],
        onClose = function()
            if addon.MapPanel and addon.MapPanel.ToggleSettings then addon.MapPanel:ToggleSettings() end
        end,
        onShow = function(frame) Settings:Refresh(frame) end,
        init = function(frame, scroll)
            -- 静态分区只建一次；炉石行每次重排（数量可变），故单独一张引用表。
            frame.categories = {}
            frame.hearthstoneRows = {}
            scroll:HookScript("OnSizeChanged", function() frame:UpdateScrollRange() end)
        end,
    })
end

--- 静态分区只建一次；炉石行每次重排（数量可变）。
--- 折叠状态记在 frame.collapsed，点分组标题切换后整块重排（WQT 的 Reconstruct 同款做法）。
function Settings:AnchorRows(frame)
    local offset = 0
    local content = frame.Content

    for _, row in pairs(frame.rows) do row:Hide() end
    for _, row in ipairs(frame.hearthstoneRows) do row:Hide() end

    local function AnchorSection(categoryKey, items, resolveRow)
        local category = frame.categories[categoryKey]
        if not category then
            category = CreateCategoryButton(content, L[categoryKey] or categoryKey, function()
                frame.collapsed[categoryKey] = not frame.collapsed[categoryKey]
                -- 走完整 Refresh：重排布局并同步各行状态（含展开后行内复选框）。
                Settings:Refresh(frame)
            end)
            frame.categories[categoryKey] = category
        end

        local collapsed = frame.collapsed[categoryKey] == true
        category:ClearAllPoints()
        category:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -offset)
        category:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        category:SetExpandedState(not collapsed)
        offset = offset + CATEGORY_HEIGHT

        if collapsed then return end

        for _, item in ipairs(items) do
            local row = resolveRow(item)
            if row then
                row:Show()
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -offset)
                row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
                offset = offset + (row:GetHeight() or ROW_HEIGHT)
            end
        end
        offset = offset + 6
    end

    for _, section in ipairs(LAYOUT) do
        AnchorSection(section.category, section.items, function(item)
            local row = frame.rows[item.key]
            if not row then
                if item.kind == "slider" then
                    row = CreateSliderRow(content, item)
                elseif item.kind == "dropdown" then
                    row = CreateDropdownRow(content, item)
                else
                    row = CreateSettingRow(content, item.key)
                end
                frame.rows[item.key] = row
            end
            return row
        end)
    end

    local hearthstoneCount = RebuildHearthstoneRows(frame)
    local hearthstoneItems = {}
    for index = 1, hearthstoneCount do hearthstoneItems[index] = index end
    AnchorSection("SETTINGS_CATEGORY_HEARTHSTONE", hearthstoneItems, function(index)
        return frame.hearthstoneRows[index]
    end)

    -- 内容宽度去掉之前给「内部滚动条」留的 -30；滚动条已移到面板外侧（WorldMapPanel.lua:265），
    -- 右侧只需留 2px 边距，否则分组标题右到 content 右会空出 30px（用户 2026-10-28）。
    content:SetSize((frame:GetWidth() or 280) - 4, offset)
    if frame.UpdateScrollRange then frame:UpdateScrollRange() end
end

function Settings:Refresh(frame)
    if not frame or not addon.db then return end
    frame.categories = frame.categories or {}
    frame.collapsed = frame.collapsed or {}

    Settings:AnchorRows(frame)

    for _, row in pairs(frame.rows) do
        if row:IsShown() and row.RefreshState then row:RefreshState() end
    end
    for _, row in ipairs(frame.hearthstoneRows) do
        if row:IsShown() and row.RefreshState then row:RefreshState() end
    end
end
