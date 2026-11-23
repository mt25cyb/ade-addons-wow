local _, addon = ...
local Settings = addon.Settings
local L = addon.L
-- 设置页骨架（背景 / 边框 / 标题 / 关闭按钮 / 滚动容器）由主插件公共函数创建。
local MapTab = LibStub("AdeMapTab-1.0")

-- 设置面板：逐项复刻 WorldQuestTab 的设置页结构（Settings.xml）。
--   面板      WQT_SettingsFrame            :744-794（newplayerchat-signup-background + QuestLogBorderFrameTemplate + 标题 + 滚动条）
--   分组标题  WQT_SettingCategoryTemplate  :7-69 （Options_ListExpand_* + 悬停发光 + 点击折叠）
--   复选框行  WQT_SettingCheckboxTemplate  :230-273（checkbox-minimal / checkmark-minimal，行高 32）
-- 分组折叠状态不落盘，随会话保留（与 WQT 一致）。

local CATEGORY_HEIGHT = 34
local CHECK_ROW_HEIGHT = 32
local CATEGORY_GAP = 6
local CHILD_INDENT = 14 -- 子选项比父选项再往右缩进
local SUBSECTION_HEIGHT = 22 -- 子分组 header（视觉分隔，不可折叠）
-- 第二阶段 9.5.4：下拉行改成「上方文本下方下拉」，一行要装得下标题(约 26) + 下拉(26)。
local DROPDOWN_ROW_HEIGHT = 54
local DROPDOWN_CONTROL_HEIGHT = 26

-- 「时间格式」的几种写法（用户 2026-10-29）：{YYYY-MM-DD} 系列 + 美式 MM/DD/YYYY、
-- 欧式 DD/MM/YYYY，是否带时分（秒）看具体项。
local TIME_FORMAT_OPTIONS = {
    { text = "SETTING_ROSTER_TIME_FORMAT_YMD", value = "ymd" },
    { text = "SETTING_ROSTER_TIME_FORMAT_YMD_HM", value = "ymd_hm" },
    { text = "SETTING_ROSTER_TIME_FORMAT_YMD_HMS", value = "ymd_hms" },
    { text = "SETTING_ROSTER_TIME_FORMAT_MDY", value = "mdy" },
    { text = "SETTING_ROSTER_TIME_FORMAT_MDY_HM", value = "mdy_hm" },
    { text = "SETTING_ROSTER_TIME_FORMAT_DMY", value = "dmy" },
    { text = "SETTING_ROSTER_TIME_FORMAT_DMY_HM", value = "dmy_hm" },
}

-- 小时制：24 小时制为真，12 小时制（带 AM/PM）为假。
local TIME_HOUR_OPTIONS = {
    { text = "SETTING_ROSTER_TIME_HOUR_24", value = true },
    { text = "SETTING_ROSTER_TIME_HOUR_12", value = false },
}

-- 战团角色统计清单的分组方式。
local ROSTER_GROUPING_OPTIONS = {
    { text = "SETTING_ROSTER_GROUPING_NONE", value = "none" },
    { text = "SETTING_ROSTER_GROUPING_REALM", value = "realm" },
    { text = "SETTING_ROSTER_GROUPING_FACTION", value = "faction" },
}

-- 第二阶段 9.4.3：二级只有两种模式——默认（按类型）/ 按地图。
local ENTRY_SORT_OPTIONS = {
    { value = "default", text = "SORT_DEFAULT" },
    { value = "map", text = "SORT_BY_MAP" },
}

-- 第二阶段 9.5.3 / 9.5.4：设置面板为「分组 → 项」两层。
-- 「地下堡列表」「丰饶列表」是独立分组；原「信息列表」分组已按用户 2026-10-30 要求解散，
-- 其下选项并入「常规」；「常规」置顶。
-- item 可以是字符串 key、{ key, child, parent } 表，或 { kind="dropdown", key, options } 表。
local LAYOUT = {
    {
        -- ① 常规（置顶）：插件级开关 + 原「信息列表」并入的列表显示 / 排序开关。
        category = "SETTINGS_CATEGORY_GENERAL",
        items = {
            "defaultTab", "showMinimapIcon",
            "showAbundance",
            "showRitual",
            { kind = "dropdown", key = "entrySortMode", options = ENTRY_SORT_OPTIONS },
            "eventActiveFirst",
        },
    },
    {
        -- ② 地下堡列表：各资料片 / 类型地下堡显示开关。
        category = "SETTINGS_CATEGORY_DELVE",
        items = {
            "showMidnight", "showTWW", "showNemesis", "showLabyrinth",
            "showStoryVariant", "showTasks", "showAchievements", "hideCompleted",
        },
    },
    {
        -- ④ 丰饶列表（原子分组升为独立分组）。
        category = "SETTINGS_CATEGORY_ABUNDANCE",
        items = {
            "showTimeLeft",
        },
    },
    {
        -- ⑤ 战团面板：分组与上次登录时间。
        category = "SETTINGS_CATEGORY_ROSTER",
        items = {
            { kind = "dropdown", key = "rosterGrouping", options = ROSTER_GROUPING_OPTIONS },
            "rosterShowLastLogin",
            { key = "rosterTimeFormat", kind = "dropdown", options = TIME_FORMAT_OPTIONS,
              child = true, parent = "rosterShowLastLogin" },
            { key = "rosterTime24", kind = "dropdown", options = TIME_HOUR_OPTIONS,
              child = true, parent = "rosterShowLastLogin" },
        },
    },
}

--- 设置项 key 是 camelCase（如 showMinimapIcon），locale key 是 SCREAMING_SNAKE_CASE
--- （SETTING_SHOW_MINIMAP_ICON），必须转换后才能命中，否则会静默回退显示 key 本身。
local function SettingKey(key)
    return "SETTING_" .. string.upper(string.gsub(key, "(%l)(%u)", "%1_%2"))
end

-------------------------------------------------------------------------------
-- 分组标题（WQT_SettingCategoryTemplate）
-------------------------------------------------------------------------------

-- WQT_SettingCategoryTemplate 的三件套纹理 / 高亮 / 标签已抽到主插件公共函数，
-- 这里保留局部函数名供 Layout / Refresh 继续调用（返回字段 Label / Right 不变）。
local function CreateCategoryButton(parent, text)
    return MapTab.CreateCategoryButton(parent, text)
end

-- LAYOUT 里的 item 可以是老写法的 key 字符串，也可以是 { key, child, parent } 表：
-- child → 子选项，向右再缩进；parent → 依附的上级开关，上级关闭时本行灰掉不可用。
local function ItemKey(item)
    return type(item) == "table" and item.key or item
end

local function ItemIndent(item)
    return (type(item) == "table" and item.child) and CHILD_INDENT or 0
end

local function RowIsDisabled(item)
    local key = ItemKey(item)
    if key == "defaultTab" and addon.MapPanel.IsDefaultTabClaimed() then return true end
    if type(item) == "table" and item.parent and not addon.db[item.parent] then return true end
    return false
end

--- 设置行：整行可点，复选框在左 40、标签在右（WQT Settings.xml:236-262）。
local function CreateCheckRow(parent, item, ownerFrame)
    local key = ItemKey(item)
    local indent = ItemIndent(item)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(CHECK_ROW_HEIGHT)

    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(1, 1, 1, 0.05)
    highlight:Hide()
    row.Highlight = highlight

    -- 纹理逐个显式建：CreateFrame("CheckButton") 不带模板，不保证已有 normal/checked 纹理。
    -- 图集名见 WQT Settings.xml:241-244（checkbox-minimal / checkmark-minimal）。
    local check = CreateFrame("CheckButton", nil, row)
    check:SetSize(25, 25)
    check:SetPoint("LEFT", 40 + indent, 0)

    local normal = check:CreateTexture(nil, "ARTWORK")
    normal:SetAtlas("checkbox-minimal", true)
    normal:SetAllPoints(check)
    check:SetNormalTexture(normal)

    local pushed = check:CreateTexture(nil, "ARTWORK")
    pushed:SetAtlas("checkbox-minimal", true)
    pushed:SetAllPoints(check)
    check:SetPushedTexture(pushed)

    local checked = check:CreateTexture(nil, "ARTWORK")
    checked:SetAtlas("checkmark-minimal", true)
    checked:SetAllPoints(check)
    check:SetCheckedTexture(checked)

    local disabledChecked = check:CreateTexture(nil, "ARTWORK")
    disabledChecked:SetAtlas("checkmark-minimal-disabled", true)
    disabledChecked:SetAllPoints(check)
    check:SetDisabledCheckedTexture(disabledChecked)
    -- 复选框自己不吃鼠标，整行点击统一走 row 的 OnClick（WQT 同款）。
    check:EnableMouse(false)
    row.Check = check

    local labelKey = SettingKey(key)
    local descKey = labelKey .. "_DESC"

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -15, 0)
    label:SetJustifyH("LEFT")
    label:SetText(tostring(L[labelKey] or key))
    row.Label = label

    row:SetScript("OnEnter", function(self)
        self.Highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tostring(L[labelKey] or key), 1, 0.82, 0)
        if L[descKey] then
            GameTooltip:AddLine(L[descKey], 1, 1, 1, true)
        end
        if key == "defaultTab" and addon.MapPanel.IsDefaultTabClaimed() then
            GameTooltip:AddLine(L["SETTING_DEFAULT_TAB_CONFLICT"], 1, 0.4, 0.4, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.Highlight:Hide()
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        if RowIsDisabled(item) then return end
        addon.db[key] = not addon.db[key]
        check:SetChecked(addon.db[key])
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.MapPanel.RefreshPanel()
        if key == "showMinimapIcon" and addon.MinimapIcon then addon.MinimapIcon:ApplyShown() end
        -- 值改了要整体重排：子选项的可用状态依附父项（「时间格式」「时间小时制」依附
        -- 「显示角色上次登录时间」），不重排的话要关掉再打开设置面板才更新（用户 2026-10-29）。
        Settings:Refresh(ownerFrame)
        -- 战团统计面板相关的开关要即刻反映到名单窗口（若正打开着）。
        if addon.RosterWindow and addon.RosterWindow.Refresh then addon.RosterWindow:Refresh() end
    end)

    row.RefreshState = function(self)
        local value = addon.db[key] == true
        self.Check:SetChecked(value)
        local disabled = RowIsDisabled(item)
        self.Check:SetEnabled(not disabled)
        self.Check:SetAlpha(disabled and 0.5 or 1)
        self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    end

    return row
end

--- 下拉行：出现在需要多选一的设置项。结构与 adePortalTab/UI/SettingsPanel.lua 的
--- CreateDropdownRow 一致（同一套 WowStyle1DropdownTemplate + 说明 tooltip）。
local function CreateDropdownRow(parent, item, ownerFrame)
    local key = ItemKey(item)
    local indent = ItemIndent(item)
    local row = CreateFrame("Frame", nil, parent)
    -- 第二阶段 9.5.4：文本在上、下拉在下，行高改用 DROPDOWN_ROW_HEIGHT。
    row:SetHeight(DROPDOWN_ROW_HEIGHT)
    row:EnableMouse(true)
    row.isDropdown = true

    local labelKey = SettingKey(key)
    local descKey = labelKey .. "_DESC"

    -- 上方：标题（与复选框行的缩进口径一致 LEFT 40 + indent），占满行宽便于长文案换行。
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 40 + indent, -4)
    label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -4)
    label:SetJustifyH("LEFT")
    label:SetText(tostring(L[labelKey] or key))
    row.Label = label

    -- 下方：下拉与行同宽（左侧对齐到标题同一缩进，右侧留 8）。
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetHeight(DROPDOWN_CONTROL_HEIGHT)
    dropdown:SetPoint("TOPLEFT", row, "TOPLEFT", 40 + indent, -28)
    dropdown:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(40 + indent), -28)
    row.Dropdown = dropdown

    local function CurrentValue()
        local stored = addon.db[key]
        for _, option in ipairs(item.options) do
            if option.value == stored then return option.value end
        end
        return item.options[1].value
    end

    dropdown:SetupMenu(function(_, root)
        for _, option in ipairs(item.options) do
            local value = option.value
            root:CreateRadio(L[option.text] or tostring(value), function() return CurrentValue() == value end,
                function()
                    if InCombatLockdown() then return end
                    addon.db[key] = value
                    -- 改动后要整体重排：子项可用状态依附父项，名单窗口也可能正开着。
                    Settings:Refresh(ownerFrame)
                    if addon.RosterWindow and addon.RosterWindow.Refresh then addon.RosterWindow:Refresh() end
                    -- 第二阶段 9.5.5：下拉改动同步刷新地图面板（与复选框 OnClick 一致）。
                    if addon.MapPanel and addon.MapPanel.RefreshPanel then addon.MapPanel:RefreshPanel() end
                end)
        end
    end)

    row:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(tostring(L[labelKey] or key), 1, 0.82, 0)
        if L[descKey] then GameTooltip:AddLine(L[descKey], 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.RefreshState = function(self)
        local current = CurrentValue()
        for _, option in ipairs(item.options) do
            if option.value == current then
                self.Dropdown:SetDefaultText(L[option.text] or tostring(current))
                break
            end
        end
        local disabled = RowIsDisabled(item)
        self.Dropdown:SetEnabled(not disabled)
        self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    end

    return row
end

--- 子分组 header：不可折叠的视觉分隔标签（第二阶段 9.5.3）。
--- LAYOUT 里用 { subsection = "LOCALE_KEY" } 标记，渲染时按 locale 显示一行金色小标题。
local function CreateSubsectionHeader(parent, localeKey)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(SUBSECTION_HEIGHT)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", parent, "LEFT", 24, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.9, 0.8, 0.5)
    label:SetText(tostring(L[localeKey] or localeKey))
    row.Label = label
    row.isSubsection = true
    row.RefreshState = function() end -- 占位，避免 Settings:Refresh 末尾批量刷新时报 nil
    return row
end

-------------------------------------------------------------------------------
-- 面板
-------------------------------------------------------------------------------

function Settings:Create(parent)
    -- 骨架逐行同构于 WorldQuestTab Settings.xml:744-794 与 adePortalTab，
    -- 已抽到主插件 MapTab.CreateSettingsFrame（含 12.x MinimalScrollBar 重锚与 Update）。
    return MapTab.CreateSettingsFrame(parent, {
        title = L["SETTINGS_TITLE"],
        closeTooltip = L["SETTINGS_CLOSE"],
        onClose = function()
            if addon.MapPanel and addon.MapPanel.ToggleSettings then addon.MapPanel:ToggleSettings() end
        end,
        onShow = function(frame) Settings:Refresh(frame) end,
    })
end

--- 重排：按折叠状态显示/隐藏分组内的行，再按实际高度重新定位。
function Settings:Layout(frame)
    local offset = 0
    for _, section in ipairs(frame.sections) do
        local expanded = not frame.collapsed[section.key]
        section.button.Right:SetAtlas(expanded and "Options_ListExpand_Right_Expanded"
            or "Options_ListExpand_Right", true)
        section.button:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 0, -offset)
        -- 分组标题铺满内容区宽度（RIGHT 锚到 Content 右），否则右侧留空不贴边（用户 2026-10-28）。
        section.button:SetPoint("RIGHT", frame.Content, "RIGHT", 0, 0)
        offset = offset + CATEGORY_HEIGHT

        for _, row in ipairs(section.rows) do
            local isSub = row.isSubsection
            row:SetShown(expanded)
            if expanded then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 0, -offset)
                row:SetPoint("RIGHT", frame.Content, "RIGHT", 0, 0)
                -- 子分组 header 始终随分组展开显示，固定占 SUBSECTION_HEIGHT；
                -- 第二阶段 9.5.4：下拉行（文本在上、下拉在下）单独用更高的行高。
                local rowHeight = isSub and SUBSECTION_HEIGHT
                    or (row.isDropdown and DROPDOWN_ROW_HEIGHT or CHECK_ROW_HEIGHT)
                offset = offset + rowHeight
            end
        end
        offset = offset + CATEGORY_GAP
    end
    -- 内容宽度 = 滚动区实际宽度（scroll 左右各 2，见本文件 scroll:SetPoint）。
    -- 滚动条已移到面板外侧（本文件 scroll.ScrollBar 锚 frame TOPRIGHT 8），
    -- 不再需要为它扣 16px，否则分组标题右侧空一条（用户 2026-10-28）。
    local width = (frame:GetWidth() or 260) - 4
    frame.Content:SetSize(width, math.max(offset, 1))
    if frame.Scroll and frame.Scroll.UpdateScrollChildRect then
        frame.Scroll:UpdateScrollChildRect()
    end
    if frame.Scroll and frame.Scroll.ScrollBar then
        frame.Scroll.ScrollBar:Update()
    end
end

function Settings:Refresh(frame)
    if not frame or not addon.db then return end

    if not frame.sections then
        frame.sections = {}
        local content = frame.Content
        for index, section in ipairs(LAYOUT) do
            local key = section.category
            local category = CreateCategoryButton(content, L[key] or key)
            category:SetPoint("RIGHT", content, "RIGHT", 0, 0)
            category:SetScript("OnClick", function()
                frame.collapsed[key] = not frame.collapsed[key]
                Settings:Layout(frame)
            end)

            local rows = {}
            for _, item in ipairs(section.items) do
                local row
                if type(item) == "table" and item.subsection then
                    row = CreateSubsectionHeader(content, item.subsection)
                elseif type(item) == "table" and item.kind == "dropdown" then
                    row = CreateDropdownRow(content, item, frame)
                else
                    row = CreateCheckRow(content, item, frame)
                end
                rows[#rows + 1] = row
                frame.rows[#frame.rows + 1] = row
            end

            frame.sections[index] = { key = key, button = category, rows = rows }
        end
    end

    Settings:Layout(frame)
    for _, row in ipairs(frame.rows) do
        row:RefreshState()
    end
end
