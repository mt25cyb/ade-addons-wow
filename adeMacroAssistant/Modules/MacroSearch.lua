--[==[ adeMacroAssistant / Modules/MacroSearch.lua
宏界面搜索栏（过滤宏列表）。

设计要点（对齐 v4 功能规格 _backup/ADE_Dev_V4/_docs/adeMacroAssistant-DevPlan.md §4；
v5 移植计划见 _docs/adeMacroAssistant-v5-DevPlan.md）：
  · UI：原生 SearchBoxTemplate（Q3），容器置于 Tab 行下方、MacroSelector 上方（Q7）。
    宽度解耦于布局模块：container 宽直接取布局后的 MacroFrame 实际宽（整框宽），searchBox 用
    固定左右偏移（SEARCHBAR_X_LEFT / SEARCHBAR_X_RIGHT）双锚定，随布局/每行宏数自动变宽。
  · index 语义「方案 B」（§4.4）：数据提供者返回过滤后元素（name/texture/body 三值），
    并在 SetSetupCallback 里把按钮的 selectionIndex / GetElementData 改写回**真实下标**，
    保证点击、拖拽（PickupMacro）、保存、删除都命中真实宏。
  · 与原生刷新共存（§4.5）：不覆写 MacroFrame.Update，改用 hooksecurefunc 后置重应用过滤。
  · 战斗中禁用输入框（不改动过滤态，避免战斗中数据变更）。
  · 不占全局名（ADE 全局污染禁令）；MacroToolkit override 守卫经 ns 共用（Q6 / §4.7）。
]==]

local ns = _G.adeMacroAssistant

-- 文件顶部批量缓存全局/API（12.x 要求显式 local 化，禁全局别名）
local hooksecurefunc, C_AddOns, C_Timer = _G.hooksecurefunc, _G.C_AddOns, _G.C_Timer
local RunNextFrame = _G.RunNextFrame
-- 展示文案统一走 ns.L（Core 设置的 locale 表）；Core 最后加载，故用懒 getter 避免加载期 nil。
local L = function(k) return ns.L[k] end
local wipe, tinsert = table.wipe, table.insert
local strlower, strfind = string.lower, string.find

local module = {}
ns.MacroSearch = module

-- ===== 常量（与 MacroUIResize 基础值表 §6.3.1 一致） =====

local SEARCHBAR_BASE_H = 20         -- 搜索栏高（参考 Choco；草案，P0 校准）
local SEARCHBAR_Y = -64             -- 搜索栏顶部离整框顶（Tab 行下方）
-- 搜索栏横跨整框宽（container 宽跟随布局后的 MacroFrame 实际宽），searchBox 用固定左右偏移双锚定：
local SEARCHBAR_X_LEFT = 18         -- 左留白：与 MacroSelector 对齐（原生 TOPLEFT 12,-66；与 Choco 一致）
local SEARCHBAR_X_RIGHT = -32       -- 右留白（含 clearButton 区；与 Choco 一致，右侧另放设置按钮）
local DEBOUNCE_DELAY = 0.05

-- ===== 状态 =====

local container          -- 搜索栏容器（无名 frame，不占全局）
local searchBox          -- EditBox（SearchBoxTemplate）
local optionBtn          -- 搜索栏右侧设置按钮（Choco 同款材质）
local emptyText          -- 空结果提示
local filtered = {}      -- 过滤结果：{ index = 真实下标, name, texture, body }
local searchText = ""
local hooksInstalled = false
local waitFrame
local combatFrame

-- ============ 配置 / 守卫 ============

local function GetCfg()
    local p = ns.db and ns.db.profile
    return p and p.macrosearch
end

local function IsEnabled()
    local cfg = GetCfg()
    if not (cfg and cfg.enabled) then return false end
    -- Q6：MacroToolkit override 接管时搜索栏同样不生效
    if ns.IsMacroToolkitOverrideActive and ns.IsMacroToolkitOverrideActive() then return false end
    return true
end

--- 搜索栏占位高度：供 MacroUIResize 参与几何计算（§4.1）
function module.GetOffset()
    if not IsEnabled() then return 0 end
    return SEARCHBAR_BASE_H
end

-- ============ 过滤 ============

-- 宽度跟随布局后的 MacroFrame 实际宽（解耦布局模块：布局重排后由 Reapply → ApplyFilter 触发）
local function SyncSearchBarWidth()
    if not container or not MacroFrame then return end
    container:SetWidth(math.max(1, MacroFrame:GetWidth()))
end

local function GetMacroMax(useAccount)
    local c = _G.Constants and _G.Constants.MacroConsts
    if c then
        return useAccount and c.MAX_ACCOUNT_MACROS or c.MAX_CHARACTER_MACROS
    end
    return useAccount and 120 or 18   -- 兜底（Constants 未就绪时；不静默，仅为防 nil 报错）
end

local function BuildFiltered()
    wipe(filtered)
    if not MacroFrame then return end
    local useAccount = _G.PanelTemplates_GetSelectedTab(MacroFrame) == 1
    local maxMacros = GetMacroMax(useAccount)
    -- macroBase：账号宏 0，角色宏 = MAX_ACCOUNT_MACROS（与原生 GetMacroDataIndex 一致）
    local macroBase = MacroFrame.macroBase
    if macroBase == nil then macroBase = useAccount and 0 or GetMacroMax(true) end

    local cfg = GetCfg()
    local includeBody = cfg and cfg.includeBody
    local query = (searchText ~= "") and strlower(searchText) or nil

    for i = 1, maxMacros do
        local name, texture, body = GetMacroInfo(macroBase + i)
        if not query then
            -- 无搜索词：保留原生行为（含空槽，name 为 nil）
            tinsert(filtered, { index = i, name = name, texture = texture, body = body })
        elseif name then
            local hit = strfind(strlower(name), query, 1, true) ~= nil
            if not hit and includeBody and body then
                hit = strfind(strlower(body), query, 1, true) ~= nil
            end
            if hit then
                tinsert(filtered, { index = i, name = name, texture = texture, body = body })
            end
        end
    end
end

--- 按钮初始化劫持（方案 B 的 index 改写，§4.4）
local function SetupButton(button, selectionIndex, name, texture, body)
    if name ~= nil then
        button:SetIconTexture(texture or "")
        button.Name:SetText(name)
        button:Enable()
        local e = filtered[selectionIndex]
        if e then
            -- 点击走 SetSelectionIndex(真实下标)；拖拽走 GetElementData() → GetMacroDataIndex
            if button.SetSelectionIndex then button:SetSelectionIndex(e.index) end
            button.GetElementData = function() return e.index end
        end
    else
        button:SetIconTexture("")
        button.Name:SetText("")
        button:Disable()
    end
end

-- ============ 应用过滤 ============

local function ApplyFilter()
    if not MacroFrame or not MacroFrame.MacroSelector then return end
    if not IsEnabled() then return end   -- 未启用：不接管数据提供者，保持原生

    SyncSearchBarWidth()
    BuildFiltered()

    local sel = MacroFrame.MacroSelector
    local function GetInfo(selectionIndex)
        local e = filtered[selectionIndex]
        if not e then return nil end
        return e.name, e.texture, e.body      -- 三值，原生 setup 语义
    end
    local function GetNum() return #filtered end

    sel:SetSelectionsDataProvider(GetInfo, GetNum)
    sel.numMacros = #filtered                 -- ★ 同步原生字段，否则按钮 enable 判定错乱
    sel:SetSetupCallback(SetupButton)

    -- ⚠ UpdateButtons 内部有「numMacros < self.macroMax」比较（Blizzard_MacroUI.lua:200），
    -- 而 self.macroMax 要到 Tab 选中（Blizzard_MacroUI.lua:148/156）才赋值。
    -- 本模块会在 ADDON_LOADED 期间被 LayoutMacroFrame → Reapply 调起（LoadAddOn 栈内），
    -- 此时 macroMax 仍是 nil ⇒ 直接调用必报「attempt to compare number with nil」。
    -- 故先判存在；未就绪则推迟到下一帧（此时原生已选好 Tab），不改变最终表现。
    if MacroFrame.UpdateButtons then
        if MacroFrame.macroMax then
            MacroFrame:UpdateButtons()
        else
            RunNextFrame(function()
                if MacroFrame and MacroFrame.macroMax and MacroFrame.UpdateButtons then
                    MacroFrame:UpdateButtons()
                end
            end)
        end
    end
    if emptyText then
        emptyText:SetShown(#filtered == 0)
        emptyText:SetText(L("SEARCH_NO_RESULT") or "No macros found")
    end
end

--- 供布局模块在重排 / 还原后调用（§4.1）
function module.Reapply()
    ApplyFilter()
end

-- ============ UI ============

-- 输入去抖：同一去抖窗口内只排一次过滤，避免每键都触发一次全量重建
local filterScheduled = false
local function ScheduleFilter()
    if filterScheduled then return end
    filterScheduled = true
    C_Timer.After(DEBOUNCE_DELAY, function()
        filterScheduled = false
        ApplyFilter()
    end)
end

local function OnTextChanged(self)
    searchText = self:GetText() or ""
    ScheduleFilter()
end

-- 回写设置页控件（若「宏界面」面板已打开），保持搜索栏菜单 ↔ 设置的双向联动
local function SyncSettingsPanel()
    local S = ns.Settings
    if S and S.UpdateValues then S.UpdateValues() end
end

-- 搜索栏设置菜单：切换到另一种布局（关联设置页的「布局模式」）
-- 直接改 macroresize.layoutMode 后重排界面，并刷新设置页（若打开则同步滑条范围/置灰）
local function SetLayoutMode(mode)
    local p = ns.db and ns.db.profile
    local c = p and p.macroresize
    if not c then return end
    c.layoutMode = mode
    if ns.MacroUIResize then ns.MacroUIResize.ApplySettings() end
    local S = ns.Settings
    if S and S.UpdateValues then S.UpdateValues() end
end

-- 打开设置界面并定位到「宏界面」分类页。直接复用 Settings.Toggle（与斜杠命令同路径：
-- ADE.OpenSettings(addonName)，默认落在「宏界面」页），避免经 ns.Bus 间接跳转的注册/时机隐患。
local function OpenResizeSettings()
    if ns.Settings and ns.Settings.Toggle then ns.Settings.Toggle() end
end

local function EnsureUI()
    if container or not MacroFrame then return end

    container = CreateFrame("Frame", nil, MacroFrame)
    container:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 0, SEARCHBAR_Y)   -- 锚整框左，宽由 SyncSearchBarWidth 设
    container:SetHeight(SEARCHBAR_BASE_H)
    SyncSearchBarWidth()

    searchBox = CreateFrame("EditBox", nil, container, "SearchBoxTemplate")
    -- 双锚定：宽高自动 = container 宽高 − 左右/上下偏移，随宏界面布局变宽
    searchBox:SetPoint("TOPLEFT", container, "TOPLEFT", SEARCHBAR_X_LEFT, 0)
    searchBox:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", SEARCHBAR_X_RIGHT, 0)
    -- HookScript 追加（非覆盖）：保留模板自带的清空按钮显隐逻辑
    searchBox:HookScript("OnTextChanged", OnTextChanged)
    searchBox:HookScript("OnEscapePressed", function(self)
        self:SetText("")
    end)

    -- 搜索栏右侧设置按钮：暴雪 UIPanelIconDropdownButtonTemplate（自带 questlog-icon-setting 齿轮图标 +
    -- HIGHLIGHT 层 ADD 0.4 同图标高亮，与 WQT 设置按钮一致；菜单样式参考 AstralGate，用 SetupMenu 弹出）
    optionBtn = CreateFrame("DropdownButton", nil, container, "UIPanelIconDropdownButtonTemplate")
    optionBtn:SetSize(18, 18)
    optionBtn:SetPoint("RIGHT", container, "RIGHT", -12, -1)
    optionBtn:SetFrameLevel(searchBox:GetFrameLevel() + 2)
    optionBtn:SetupMenu(function(_, rootDescription)
        rootDescription:CreateCheckbox(
            L("SEARCH_BODY"),
            function() local c = GetCfg() return c and c.includeBody end,
            function()
                -- 菜单 Checkbox 的 setChecked 是否回传新值因版本/接口而异；
                -- 显式翻转当前值，确保「勾选 / 取消」双向都生效（不再依赖回调参数）。
                local c = GetCfg()
                if c then
                    c.includeBody = not c.includeBody
                    ApplyFilter()
                    SyncSettingsPanel()
                end
            end)
        -- 切换布局：垂直时显示「切换到水平布局」，水平时显示「切换到垂直布局」
        local mode = (ns.MacroUIResize and ns.MacroUIResize.GetMode()) or "vertical"
        if mode == "vertical" then
            rootDescription:CreateButton(L("SWITCH_TO_HORIZONTAL"), function() SetLayoutMode("horizontal") end)
        else
            rootDescription:CreateButton(L("SWITCH_TO_VERTICAL"), function() SetLayoutMode("vertical") end)
        end
        rootDescription:CreateButton(L("OPEN_SETTINGS"), function() OpenResizeSettings() end)
    end)

    emptyText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyText:SetPoint("CENTER", MacroFrame.MacroSelector.ScrollBox, "CENTER", 0, 0)
    emptyText:Hide()
end

local function UpdateVisibility()
    if not container then return end
    container:SetShown(IsEnabled())
    SyncSearchBarWidth()
end

-- ============ 钩子 / 事件 ============

local function EnsureHooks()
    if hooksInstalled or not MacroFrame then return end
    hooksInstalled = true
    -- 不覆写 MacroFrame.Update：后置重应用过滤，保证搜索态不被原生刷新冲掉（§4.5）
    hooksecurefunc(MacroFrame, "Update", function()
        ApplyFilter()
    end)
    -- 切页（账号/角色宏）后重填：原生 ChangeTab → SetAccountMacros → Update，已被上面覆盖；
    -- 这里再兜一层，防止将来原生改路径。
    if MacroFrame.ChangeTab then
        hooksecurefunc(MacroFrame, "ChangeTab", function()
            C_Timer.After(0, ApplyFilter)
        end)
    end
end

local function EnsureCombatFrame()
    if combatFrame then return end
    combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if searchBox then searchBox:Disable() end
        else
            if searchBox then searchBox:Enable() end
        end
    end)
end

local function Setup()
    EnsureUI()
    EnsureHooks()
    EnsureCombatFrame()
    UpdateVisibility()
    ApplyFilter()
end

-- ============ 生命周期（V5 模块调度） ============

function module.Init()
    if MacroFrame then
        Setup()
        return
    end
    -- Blizzard_MacroUI 未加载：等待其 ADDON_LOADED
    if not waitFrame then
        waitFrame = CreateFrame("Frame")
        waitFrame:RegisterEvent("ADDON_LOADED")
        waitFrame:SetScript("OnEvent", function(_, _, addon)
            if addon == "Blizzard_MacroUI" then
                Setup()
            end
        end)
    end
end

function module.ApplySettings()
    UpdateVisibility()
    -- 占位高度可能变化（启用/禁用切换），通知布局模块重排
    if ns.MacroUIResize and ns.MacroUIResize.ApplyResize then
        ns.MacroUIResize.ApplyResize()
    end
    ApplyFilter()
end

function module.Disable()
    if container then container:Hide() end
    -- 交还原生数据提供者
    if MacroFrame and MacroFrame.Update then
        MacroFrame:Update()
    end
end

function module.Refresh()
    ApplyFilter()
end

module.IsEnabled = IsEnabled
