-- adeMacroAssistant / Modules/MacroUIResize.lua
-- 宏界面尺寸调整（每行宏数 / 图标行数 / 文本区额外高度 / 垂直-水平双布局）。
--
-- 改造要点（对齐 v4 功能规格 _backup/ADE_Dev_V4/_docs/adeMacroAssistant-DevPlan.md；
-- v5 移植计划见 _docs/adeMacroAssistant-v5-DevPlan.md）：
--   · 基础值表（§6.3.1）：所有几何取值集中在文件顶部常量区，分「原生基准」与「派生常量」，
--     还原与两种布局都读此表；暴雪改原生布局时只改此处。
--   · 常量命名：布局/几何相关一律 UPPER_SNAKE_CASE；配置项与函数参数（cols/rows/textExtra）
--     及 widget 句柄保持原命名（见计划 §6.3 命名约定）。
--   · Restore：读基础值表把被修改元素还原回原生值，并算上搜索栏占位 SEARCHBAR_OFFSET_Y；
--     分隔条恢复 Show；搜索栏帧由 MacroSearch 模块独立管理，此处不触碰。
--   · 修 D1（MacroFrameTextButton 尺寸同步）/ D2（UIPanelWindows width 同步）/ D3（步进 49）。
-- taint 注意：仅用 hooksecurefunc 挂全局 ShowUIPanel / HideUIPanel 与 MacroFrame:SelectMacro，
--   不向 MacroFrame 安装 HookScript / 脚本，避免污染其受保护调用栈（ADDON_ACTION_BLOCKED）。

local ns = _G.adeMacroAssistant

-- 文件顶部批量缓存全局/API（12.x 要求显式 local 化，禁全局别名）
local hooksecurefunc, C_AddOns, C_Timer = _G.hooksecurefunc, _G.C_AddOns, _G.C_Timer
local math = _G.math

local module = {}
ns.MacroUIResize = module

-- ============================================================================
-- 基础值表（§6.3.1）：一、暴雪原生基准（来自 Blizzard_MacroUI.xml，勿臆改）
-- ============================================================================

local FRAME_BASE_W, FRAME_BASE_H = 338, 424          -- MacroFrame 原生尺寸

local SELECTOR_BASE_W, SELECTOR_BASE_H = 319, 146    -- 宏按钮区域（MacroSelector）
local SELECTOR_X, SELECTOR_Y = 12, -66

local BAR_LEFT_BASE_W = 256                          -- 分隔条左段（MacroHorizontalBarLeft）
local BAR_LEFT_X, BAR_LEFT_Y = 2, -210

local BACKGROUND_SIZE = 64                           -- 选中宏图标底槽（编辑区根）
local BACKGROUND_X, BACKGROUND_Y = 5, -218

local SCROLL_FRAME_BASE_W, SCROLL_FRAME_BASE_H = 286, 85   -- 宏内容滚动区
local SCROLL_FRAME_X, SCROLL_FRAME_Y = 11, -13             -- 相对 Background BOTTOMLEFT

local TEXT_BACKGROUND_BASE_W, TEXT_BACKGROUND_BASE_H = 322, 95  -- 宏内容背景
local TEXT_BACKGROUND_X, TEXT_BACKGROUND_Y = -10, 6            -- 相对 ScrollFrame 左上

local NAME_BASE_W = 256                              -- MacroFrameSelectedMacroName 原生宽
local EDIT_BUTTON_BASE_W = 170                       -- MacroEditButton 原生宽

local HEADER_H = 66                                  -- 头部区域高（Tab 及其以上）
local SEPARATOR_Y = 210                              -- 分隔条以上高度（头部 + 宏按钮区）
local BOTTOMBAR_BASE_H = 30                          -- 底栏基础高（CharLimitText BOTTOM y=30）

local CHAR_LIMIT_X, CHAR_LIMIT_Y = -15, 30           -- 字数统计（锚 BOTTOM，中心锚点）
local DELETE_BUTTON_X, DELETE_BUTTON_Y = 4, 4        -- 按钮「删除」（BOTTOMLEFT）
local NEW_BUTTON_X, NEW_BUTTON_Y = -82, 4             -- 按钮「新建」（BOTTOMRIGHT）
local EXIT_BUTTON_X, EXIT_BUTTON_Y = -5, 4            -- 按钮「退出」（BOTTOMRIGHT）

-- 网格（原生 SetCustomPadding(5,5,5,5,13,13) + 宏槽 36x36 ⇒ 步进 49，修 D3）
local SLOT_UNIT = 36
local GAP_VALUE = 13
local COLS_BASE = 6
local ROWS_BASE = 3
local STEP = SLOT_UNIT + GAP_VALUE                   -- = 49

-- 文本区额外高度范围（垂直布局专用；水平布局按设计不生效）
local TEXT_MIN, TEXT_MAX, TEXT_STEP = 0, 100, 10
local RIGHTW_MIN, RIGHTW_MAX, RIGHTW_STEP = 300, 480, 10  -- 水平布局宏内容区宽度范围/步进（任务 5）

-- ============================================================================
-- 基础值表（§6.3.1）：二、新布局常量（派生值用相对计算式，★用户第 1 点）
-- ============================================================================

local SEARCHBAR_BASE_H = 20                          -- 搜索栏基础高（参考 Choco；草案，P0 校准）

-- 水平布局：可自定义的两个源常量
local LAYOUT_H_RIGHT_BASE_W = 320                    -- 宏内容区域宽（rightWidth 默认；任务 5：范围 300–480，默认 320）
local LAYOUT_H_ZONE_GAP = -12                        -- 宏按钮区与宏内容区间距（用户 2026-10-31 由 8 调为 2，原先间距过大）
local LAYOUT_H_SAFE_GAP = 8                          -- 宏内容区内元素安全距离（§6.4.5）

-- 水平布局：派生值（不可直接自定义，由上面常量算出）
local LAYOUT_H_BASE_W = FRAME_BASE_W + LAYOUT_H_ZONE_GAP + LAYOUT_H_RIGHT_BASE_W   -- = 640
local LAYOUT_H_BASE_H = SEPARATOR_Y + BOTTOMBAR_BASE_H                            -- = 240
-- 字数统计行自身高度：CharLimitText 锚 BOTTOM y=30，向上还占 10px（GameFontHighlightSmall），
-- 底栏实际占位 = BOTTOMBAR_BASE_H + CHAR_LIMIT_TEXT_H = 40。漏掉它会被内容滚动区压住
-- （用户 2026-10-31：「MacroFrameCharLimitText 被宏内容区滚动区盖住」）。
-- ⚠ 计划 §6.4.4-C 原写「10 已含在 BOTTOMBAR_BASE_H=30 内、正确常数为 173」是错误的，
--    实机证明恰恰相反：30 只是锚点偏移，不含文字高度，必须以实证为准。
local CHAR_LIMIT_TEXT_H = 14
-- EDIT_H = LAYOUT_H_BASE_H + DIFF_HEIGHT - EDIT_H_FIXED
local EDIT_H_FIXED = HEADER_H + BACKGROUND_SIZE + math.abs(SCROLL_FRAME_Y)
                     + BOTTOMBAR_BASE_H + CHAR_LIMIT_TEXT_H                       -- = 183
-- 宏内容区宽差基准（原生整框宽 338 - ScrollFrame 宽 286 = 52）
local SCROLL_FRAME_W_GAP = 52
-- 宏内容区元素安全宽度（§6.4.5）：NAME_W / EDIT_BUTTON_W
local NAME_W_FIXED = 156                             -- NAME_W = RIGHT_WIDTH - 156 - SAFE_GAP
local EDIT_BUTTON_W_FIXED = 151                      -- EDIT_BUTTON_W = RIGHT_WIDTH - 151 - SAFE_GAP

-- ============================================================================
-- 布局参数表（★单一数据源）：默认值 / 范围 / 文本区是否生效
--   两种布局的「每行宏数」「图标行数」取值与范围都不同，且自定义值按布局分开独立保存
--   （用户 2026-10-31）。设置页的滑条 min-max 与置灰状态一律由此表派生，
--   避免设置页与布局计算各写一套范围。
-- ============================================================================

local VERTICAL, HORIZONTAL = "vertical", "horizontal"
local DEFAULT_MODE = VERTICAL

local LAYOUT_SPECS = {
    [VERTICAL] = {
        cols = 8, rows = 4,                        -- 默认 8 个 / 4 行
        colsMin = 6, colsMax = 12,
        rowsMin = 3, rowsMax = 9,
        textEnabled = true,
    },
    [HORIZONTAL] = {
        cols = 6, rows = 8,                        -- 默认 6 个 / 8 行
        colsMin = 6, colsMax = 8,
        rowsMin = 6, rowsMax = 12,
        textEnabled = false,                       -- 高度由 rows 撑满，addTextY 不起作用 ⇒ 设置页置灰
        rightWidth = 320,                          -- 水平布局宏内容文本区宽度（可配置，RIGHTW_MIN..RIGHTW_MAX）
    },
}

---@param mode string
---@return table spec 未知布局回退到默认布局，调用方无需再做分支
local function GetLayoutSpec(mode)
    return LAYOUT_SPECS[mode] or LAYOUT_SPECS[DEFAULT_MODE]
end

-- 开发期微调位（默认 0）
local OFFSET_X, OFFSET_Y = 0, 0

-- ============================================================================
-- 状态
-- ============================================================================

local frame                 -- MacroFrame 未加载时的等待帧
local TEMP_SCROLL_PER       -- 宏选择框滚动条百分比暂存（切换宏后保持）
local HOOKS_INSTALLED = false

-- ============ 配置 / 状态 ============

local function GetCfg()
    local p = ns.db and ns.db.profile
    if not p then return nil end
    return p.macroresize
end

local function IsModuleActive()
    local cfg = GetCfg()
    return not not (cfg and cfg.enabled)
end

--- MacroToolkit override 冲突守卫：override 模式接管默认 MacroFrame 时缩放无意义。
--- 按 §4.7 / Q6 提升至 ns 供 MacroSearch 共用。
local function IsMacroToolkitOverrideActive()
    if not C_AddOns.IsAddOnLoaded("MacroToolkit") then return false end
    local db = _G.MacroToolkitDB
    return not not (db and db.profile and db.profile.override)
end
ns.IsMacroToolkitOverrideActive = IsMacroToolkitOverrideActive

--- 搜索栏占位高度（由 MacroSearch 模块提供；未加载/未启用为 0）
local function GetSearchBarOffset()
    local m = ns.MacroSearch
    if m and m.GetOffset then return m.GetOffset() end
    return 0
end

-- ============ 按布局独立读写的配置访问（★用户 2026-10-31） ============

--- 当前布局模式；存档里的非法值回退默认布局。
---@return string "vertical" | "horizontal"
local function GetMode()
    local cfg = GetCfg()
    local mode = cfg and cfg.layoutMode
    if mode ~= HORIZONTAL and mode ~= VERTICAL then return DEFAULT_MODE end
    return mode
end

--- 读当前布局的三个参数（缺失键走 LAYOUT_SPECS 默认值，并按该布局范围钳制）。
---@param mode? string 省略则用当前布局
---@return number cols, number rows, number textExtra
local function GetLayoutValues(mode)
    mode = mode or GetMode()
    local spec = GetLayoutSpec(mode)
    local preset = GetCfg() and GetCfg()[mode]
    if type(preset) ~= "table" then preset = nil end

    local cols = (preset and preset.buttonCols) or spec.cols
    local rows = (preset and preset.buttonRows) or spec.rows
    local textExtra = (GetCfg() and GetCfg().addTextY) or ns.defaults.profile.macroresize.addTextY

    if cols < spec.colsMin then cols = spec.colsMin elseif cols > spec.colsMax then cols = spec.colsMax end
    if rows < spec.rowsMin then rows = spec.rowsMin elseif rows > spec.rowsMax then rows = spec.rowsMax end
    if textExtra < TEXT_MIN then textExtra = TEXT_MIN elseif textExtra > TEXT_MAX then textExtra = TEXT_MAX end
    return cols, rows, textExtra
end

--- 写回当前布局参数：cols / rows 存进各自子树（两布局互不影响）；
--- addTextY 只作用于垂直布局，统一存在 macroresize 顶层。
local function SetLayoutValues(mode, cols, rows, textExtra, rightWidth)
    local cfg = GetCfg()
    if not cfg then return end
    local spec = GetLayoutSpec(mode)
    local preset = cfg[mode]
    if type(preset) ~= "table" then
        preset = {}
        cfg[mode] = preset
    end
    preset.buttonCols = math.max(spec.colsMin, math.min(spec.colsMax, math.floor(cols + 0.5)))
    preset.buttonRows = math.max(spec.rowsMin, math.min(spec.rowsMax, math.floor(rows + 0.5)))
    if spec.textEnabled and textExtra then
        cfg.addTextY = math.max(TEXT_MIN, math.min(TEXT_MAX, math.floor(textExtra + 0.5)))
    end
    -- 水平布局宏内容区宽度可配置（任务 5）；垂直布局忽略
    if mode == HORIZONTAL and rightWidth ~= nil then
        preset.rightWidth = math.max(RIGHTW_MIN, math.min(RIGHTW_MAX, math.floor(rightWidth + 0.5)))
    end
end

--- 水平布局宏内容区宽度（可配置；垂直布局忽略）。范围见 RIGHTW_*。
local function GetRightWidth(mode)
    mode = mode or GetMode()
    local spec = GetLayoutSpec(mode)
    local preset = GetCfg() and GetCfg()[mode]
    local v = (preset and preset.rightWidth) or spec.rightWidth or RIGHTW_MIN
    if v < RIGHTW_MIN then v = RIGHTW_MIN elseif v > RIGHTW_MAX then v = RIGHTW_MAX end
    return v
end

--- 当前布局回各自的默认值（另一个布局的自定义值保持不动）。
local function ResetLayout(mode)
    local cfg = GetCfg()
    if not cfg then return end
    local spec = GetLayoutSpec(mode)
    cfg[mode] = { buttonCols = spec.cols, buttonRows = spec.rows }
    if spec.textEnabled then cfg.addTextY = ns.defaults.profile.macroresize.addTextY end
end

-- ============ 分隔条（含右侧无名段）显隐 ============

local BAR_FILE = [[Interface\ClassTrainerFrame\UI-ClassTrainer-HorizontalBar]]
local barRegions

--- 原生分隔条是**两条**纹理：命名的 MacroHorizontalBarLeft（256 宽）+ 一条**无名**右段（75 宽，
--- 锚 MacroHorizontalBarLeft 的 RIGHT，见 Blizzard_MacroUI.xml:45-58）。
--- 只 Hide 命名那一条，右段仍会留在原地 ⇒ 用户看到「分隔条还在、连右侧也在」（2026-10-31）。
--- 无名帧拿不到全局变量，故按「同一贴图 + 锚在 MacroHorizontalBarLeft 上」识别并一并处理。
local function CollectBarRegions()
    if barRegions then return barRegions end
    if not MacroFrame then return nil end
    barRegions = {}
    local left = _G.MacroHorizontalBarLeft
    local n = 0
    local function add(r)
        n = n + 1
        barRegions[n] = r
    end
    if left then add(left) end
    for _, region in ipairs({ MacroFrame:GetRegions() }) do
        if region ~= left and region:IsObjectType("Texture") then
            local _, relativeTo = region:GetPoint(1)
            if relativeTo == left then
                add(region)
            elseif (not left) and region.GetTexture and region:GetTexture() == BAR_FILE then
                add(region)
            end
        end
    end
    return barRegions
end

local function SetBarShown(show)
    for _, region in ipairs(CollectBarRegions() or {}) do
        region:SetShown(show)
    end
end

-- ============ 布局引擎 ============

--- 同步 stride：ScrollBoxSelector 的 customStride 只是字段，实际排布由首次 OnShow
--- 创建的 grid view 固定；须 view:SetStride + ScrollBox:Update(true) 才生效。
local function SyncStride(sel, cols)
    if not sel then return end
    sel:SetCustomStride(cols)
    local scrollBox = sel.ScrollBox
    local view = scrollBox and scrollBox.GetView and scrollBox:GetView()
    if view and view.SetStride then
        view:SetStride(cols)
    end
    return scrollBox, view
end

local function UpdateScrollBox(scrollBox, view)
    if scrollBox and view then
        scrollBox:Update(true) -- forceLayout：立即按新 stride + 新尺寸重排可见按钮
    end
end

--- 同步 UIPanelWindows 的 width（修 D2）：窗口变宽后 UIPanel 排布需为其让位
local function SyncUIPanelWidth(w)
    if _G.UIPanelWindows and _G.UIPanelWindows["MacroFrame"] then
        _G.UIPanelWindows["MacroFrame"].width = w
    end
end

--- 还原：把被修改元素还原回基础值表中的原生值（含搜索栏占位下移；分隔条恢复显示）
local function Restore()
    if not MacroFrame then return end
    local soy = GetSearchBarOffset()

    MacroFrame:SetWidth(FRAME_BASE_W + OFFSET_X)
    MacroFrame:SetHeight(FRAME_BASE_H + soy + OFFSET_Y)
    SyncUIPanelWidth(FRAME_BASE_W + OFFSET_X)

    local sel = MacroFrame.MacroSelector
    if sel then
        sel:SetWidth(SELECTOR_BASE_W)
        sel:SetHeight(SELECTOR_BASE_H)
        sel:ClearAllPoints()
        sel:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", SELECTOR_X, SELECTOR_Y - soy)
        local scrollBox, view = SyncStride(sel, COLS_BASE)
        UpdateScrollBox(scrollBox, view)
    end

    -- 分隔条：连同无名右段一起恢复（水平布局 Hide 过，还原须两边都回来）
    if MacroHorizontalBarLeft then
        MacroHorizontalBarLeft:ClearAllPoints()
        MacroHorizontalBarLeft:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", BAR_LEFT_X, BAR_LEFT_Y - soy)
        MacroHorizontalBarLeft:SetWidth(BAR_LEFT_BASE_W)
    end
    SetBarShown(true)

    if MacroFrameSelectedMacroBackground then
        MacroFrameSelectedMacroBackground:ClearAllPoints()
        MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y - soy)
    end

    if MacroFrameScrollFrame then
        MacroFrameScrollFrame:SetWidth(SCROLL_FRAME_BASE_W)
        MacroFrameScrollFrame:SetHeight(SCROLL_FRAME_BASE_H)
    end

    if MacroFrameText then
        MacroFrameText:SetSize(SCROLL_FRAME_BASE_W, SCROLL_FRAME_BASE_H)
    end

    if MacroFrameTextButton then                     -- 修 D1：命中区同步
        MacroFrameTextButton:SetSize(SCROLL_FRAME_BASE_W, SCROLL_FRAME_BASE_H)
    end

    if MacroFrameTextBackground then
        MacroFrameTextBackground:ClearAllPoints()
        -- 还原为原生锚（锚 MacroFrame）；水平布局改锚 ScrollFrame 后须还原
        MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 6, -289 - soy)
        MacroFrameTextBackground:SetWidth(TEXT_BACKGROUND_BASE_W)
        MacroFrameTextBackground:SetHeight(TEXT_BACKGROUND_BASE_H)
    end

    if MacroFrameSelectedMacroName then
        MacroFrameSelectedMacroName:SetWidth(NAME_BASE_W)
    end

    if MacroEditButton then
        MacroEditButton:SetWidth(EDIT_BUTTON_BASE_W)
    end

    if MacroFrameCharLimitText then
        MacroFrameCharLimitText:ClearAllPoints()
        MacroFrameCharLimitText:SetPoint("BOTTOM", MacroFrame, "BOTTOM", CHAR_LIMIT_X, CHAR_LIMIT_Y)
    end

    if MacroDeleteButton then
        MacroDeleteButton:ClearAllPoints()
        MacroDeleteButton:SetPoint("BOTTOMLEFT", MacroFrame, "BOTTOMLEFT", DELETE_BUTTON_X, DELETE_BUTTON_Y)
    end

    if MacroNewButton then
        MacroNewButton:ClearAllPoints()
        MacroNewButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", NEW_BUTTON_X, NEW_BUTTON_Y)
    end

    if MacroExitButton then
        MacroExitButton:ClearAllPoints()
        MacroExitButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", EXIT_BUTTON_X, EXIT_BUTTON_Y)
    end

end

--- 垂直布局：头部 → 主内容（上:宏按钮 → 下:宏内容）→ 底栏（同原生顺序）
local function ApplyVertical(cols, rows, textExtra)
    if not MacroFrame then return end
    -- 范围按布局参数表（垂直分支）统一钳制，避免与设置页各写一套上下界
    local spec = GetLayoutSpec(VERTICAL)
    if cols < spec.colsMin then cols = spec.colsMin elseif cols > spec.colsMax then cols = spec.colsMax end
    if rows < spec.rowsMin then rows = spec.rowsMin elseif rows > spec.rowsMax then rows = spec.rowsMax end
    local soy = GetSearchBarOffset()
    local DIFF_WIDTH = STEP * (cols - COLS_BASE)
    local DIFF_HEIGHT = STEP * (rows - ROWS_BASE)

    local w = FRAME_BASE_W + DIFF_WIDTH + OFFSET_X
    MacroFrame:SetWidth(w)
    MacroFrame:SetHeight(FRAME_BASE_H + DIFF_HEIGHT + textExtra + soy + OFFSET_Y)
    SyncUIPanelWidth(w)

    local sel = MacroFrame.MacroSelector
    if sel then
        sel:SetWidth(SELECTOR_BASE_W + DIFF_WIDTH)
        sel:SetHeight(SELECTOR_BASE_H + DIFF_HEIGHT)
        sel:ClearAllPoints()
        sel:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", SELECTOR_X, SELECTOR_Y - soy)
        local scrollBox, view = SyncStride(sel, cols)
        UpdateScrollBox(scrollBox, view)
    end

    -- 分隔条：整条（含无名右段）随宽展开；左段锚 point 不必重设宽度以外的东西，右段靠锚点自动跟随
    if MacroHorizontalBarLeft then
        MacroHorizontalBarLeft:ClearAllPoints()
        MacroHorizontalBarLeft:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", BAR_LEFT_X, BAR_LEFT_Y - DIFF_HEIGHT - soy)
        MacroHorizontalBarLeft:SetWidth(BAR_LEFT_BASE_W + DIFF_WIDTH)
    end
    SetBarShown(true)

    if MacroFrameSelectedMacroBackground then
        MacroFrameSelectedMacroBackground:ClearAllPoints()
        MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y - DIFF_HEIGHT - soy)
    end

    if MacroFrameScrollFrame then
        MacroFrameScrollFrame:SetWidth(SCROLL_FRAME_BASE_W + DIFF_WIDTH)
        MacroFrameScrollFrame:SetHeight(SCROLL_FRAME_BASE_H + textExtra)
    end

    if MacroFrameText then
        MacroFrameText:SetSize(SCROLL_FRAME_BASE_W + DIFF_WIDTH, SCROLL_FRAME_BASE_H + textExtra)
    end

    if MacroFrameTextButton then                     -- 修 D1
        MacroFrameTextButton:SetSize(SCROLL_FRAME_BASE_W + DIFF_WIDTH, SCROLL_FRAME_BASE_H + textExtra)
    end

    if MacroFrameTextBackground then
        MacroFrameTextBackground:ClearAllPoints()
        MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 6, -289 - DIFF_HEIGHT - soy)
        MacroFrameTextBackground:SetWidth(TEXT_BACKGROUND_BASE_W + DIFF_WIDTH)
        MacroFrameTextBackground:SetHeight(TEXT_BACKGROUND_BASE_H + textExtra)
    end

    -- 垂直布局宽度充足，保留原生宽
    if MacroFrameSelectedMacroName then MacroFrameSelectedMacroName:SetWidth(NAME_BASE_W) end
    if MacroEditButton then MacroEditButton:SetWidth(EDIT_BUTTON_BASE_W) end

    -- 底栏：垂直布局锚整框，无需偏移（还原式重设，防切回时被水平布局的偏移残留）
    if MacroFrameCharLimitText then
        MacroFrameCharLimitText:ClearAllPoints()
        MacroFrameCharLimitText:SetPoint("BOTTOM", MacroFrame, "BOTTOM", CHAR_LIMIT_X, CHAR_LIMIT_Y)
    end
    if MacroDeleteButton then
        MacroDeleteButton:ClearAllPoints()
        MacroDeleteButton:SetPoint("BOTTOMLEFT", MacroFrame, "BOTTOMLEFT", DELETE_BUTTON_X, DELETE_BUTTON_Y)
    end
    if MacroNewButton then
        MacroNewButton:ClearAllPoints()
        MacroNewButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", NEW_BUTTON_X, NEW_BUTTON_Y)
    end
    if MacroExitButton then
        MacroExitButton:ClearAllPoints()
        MacroExitButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", EXIT_BUTTON_X, EXIT_BUTTON_Y)
    end
end

--- 水平布局：头部 → 主内容（左:宏按钮 → 右:宏内容，等高）→ 底栏
local function ApplyHorizontal(cols, rows, textExtra)
    if not MacroFrame then return end
    local soy = GetSearchBarOffset()

    -- 水平布局参数钳制（范围取自布局参数表，与设置页滑条同源）
    local spec = GetLayoutSpec(HORIZONTAL)
    if cols < spec.colsMin then cols = spec.colsMin elseif cols > spec.colsMax then cols = spec.colsMax end
    if rows < spec.rowsMin then rows = spec.rowsMin elseif rows > spec.rowsMax then rows = spec.rowsMax end
    -- 水平布局高度由 rows 撑满，addTextY 按设计不生效（设置页已置灰），此处显式忽略
    textExtra = 0

    local DIFF_WIDTH = STEP * (cols - COLS_BASE)
    local DIFF_HEIGHT = STEP * (rows - ROWS_BASE)

    local LEFT_WIDTH = FRAME_BASE_W + DIFF_WIDTH          -- 左区（宏按钮区）总宽
    local RIGHT_WIDTH = GetRightWidth(HORIZONTAL)          -- 右区（宏内容区）宽（可配置：RIGHTW_MIN..RIGHTW_MAX）
    local ZONE_GAP = LAYOUT_H_ZONE_GAP
    local w = LEFT_WIDTH + RIGHT_WIDTH + ZONE_GAP + OFFSET_X   -- = LAYOUT_H_BASE_W + DIFF_WIDTH
    local h = LAYOUT_H_BASE_H + DIFF_HEIGHT + soy + OFFSET_Y
    MacroFrame:SetWidth(w)
    MacroFrame:SetHeight(h)
    SyncUIPanelWidth(w)

    -- 左区：宏按钮区域（与垂直布局同一定位）
    local sel = MacroFrame.MacroSelector
    if sel then
        sel:SetWidth(SELECTOR_BASE_W + DIFF_WIDTH)
        sel:SetHeight(SELECTOR_BASE_H + DIFF_HEIGHT)
        sel:ClearAllPoints()
        sel:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", SELECTOR_X, SELECTOR_Y - soy)
        local scrollBox, view = SyncStride(sel, cols)
        UpdateScrollBox(scrollBox, view)
    end

    -- 分隔条：水平布局隐藏（Q5）——连同无名右段一起藏，否则右侧那一截会留在右区里
    SetBarShown(false)

    -- 右区：宏内容区域（Background 移到右区左上，同一根锚链整体随移）
    if MacroFrameSelectedMacroBackground then
        MacroFrameSelectedMacroBackground:ClearAllPoints()
        MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", BACKGROUND_X + LEFT_WIDTH + ZONE_GAP, SELECTOR_Y - soy)
    end

    local scrollW = RIGHT_WIDTH - SCROLL_FRAME_W_GAP                 -- = 248（RIGHT_WIDTH=300）
    local EDIT_H = LAYOUT_H_BASE_H + DIFF_HEIGHT - EDIT_H_FIXED      -- = 67 + DIFF_HEIGHT
    if EDIT_H < 0 then EDIT_H = 0 end

    if MacroFrameScrollFrame then
        MacroFrameScrollFrame:SetWidth(scrollW)
        MacroFrameScrollFrame:SetHeight(EDIT_H)
    end

    if MacroFrameText then
        MacroFrameText:SetSize(scrollW, EDIT_H)
    end

    if MacroFrameTextButton then                     -- 修 D1
        MacroFrameTextButton:SetSize(scrollW, EDIT_H)
    end

    if MacroFrameTextBackground then
        MacroFrameTextBackground:ClearAllPoints()
        -- 修 H6：改锚 ScrollFrame（左上 -10,+6），两布局通用；不再用垂直布局的 y 公式
        MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrameScrollFrame, "TOPLEFT", TEXT_BACKGROUND_X, TEXT_BACKGROUND_Y)
        MacroFrameTextBackground:SetWidth(scrollW + 36)              -- 原生 TextBackground 比 ScrollFrame 宽 36
        MacroFrameTextBackground:SetHeight(EDIT_H + 10)              -- 高 10（原生 95 - 85）
    end

    -- §6.4.5：宏内容区元素安全宽度（避免与 Save/Cancel 重叠）
    local NAME_W = RIGHT_WIDTH - NAME_W_FIXED - LAYOUT_H_SAFE_GAP
    local EDIT_BUTTON_W = RIGHT_WIDTH - EDIT_BUTTON_W_FIXED - LAYOUT_H_SAFE_GAP
    if MacroFrameSelectedMacroName then
        MacroFrameSelectedMacroName:SetWidth(math.min(NAME_BASE_W, NAME_W))
    end
    if MacroEditButton then
        MacroEditButton:SetWidth(math.min(EDIT_BUTTON_BASE_W, EDIT_BUTTON_W))
    end

    -- 底栏：宽度拉长后推到宏内容区（右区）下方（修 H4/H5）
    --   注意锚点语义：BOTTOMLEFT 相对整框左 ⇒ 偏移 LEFT_WIDTH + ZONE_GAP；
    --   BOTTOM 是中心锚 ⇒ 偏移 (LEFT_WIDTH + ZONE_GAP) / 2；
    --   BOTTOMRIGHT 相对整框右，而整框右 = 右区右 ⇒ 无需偏移。
    local zoneOffset = LEFT_WIDTH + ZONE_GAP
    if MacroFrameCharLimitText then
        MacroFrameCharLimitText:ClearAllPoints()
        MacroFrameCharLimitText:SetPoint("BOTTOM", MacroFrame, "BOTTOM", CHAR_LIMIT_X + zoneOffset / 2, CHAR_LIMIT_Y)
    end
    if MacroDeleteButton then
        MacroDeleteButton:ClearAllPoints()
        MacroDeleteButton:SetPoint("BOTTOMLEFT", MacroFrame, "BOTTOMLEFT", DELETE_BUTTON_X + zoneOffset, DELETE_BUTTON_Y)
    end
    if MacroNewButton then
        MacroNewButton:ClearAllPoints()
        MacroNewButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", NEW_BUTTON_X, NEW_BUTTON_Y)
    end
    if MacroExitButton then
        MacroExitButton:ClearAllPoints()
        MacroExitButton:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", EXIT_BUTTON_X, EXIT_BUTTON_Y)
    end
end

--- 按当前 layoutMode 分派
local function LayoutMacroFrame(cols, rows, textExtra, mode)
    if mode == HORIZONTAL then
        ApplyHorizontal(cols, rows, textExtra)
    else
        ApplyVertical(cols, rows, textExtra)
    end
    -- 布局重排后 ScrollBox 可能重建，交由搜索模块重新应用过滤（§4.1）
    if ns.MacroSearch and ns.MacroSearch.Reapply then
        ns.MacroSearch.Reapply()
    end
end

--- 按当前配置应用（模块开启且无 MacroToolkit 接管时）
local function ApplyResize()
    if not MacroFrame or not IsModuleActive() or IsMacroToolkitOverrideActive() then return end
    -- 三个参数全部按「当前布局」读取：两种布局各自独立保存，切换布局时自动读到对应的一组值
    local mode = GetMode()
    local cols, rows, textExtra = GetLayoutValues(mode)
    LayoutMacroFrame(cols, rows, textExtra, mode)
end

--- 还原系统默认尺寸（模块关闭 / MacroToolkit 接管时）：读基础值表还原
local function RestoreResize()
    Restore()
    if ns.MacroSearch and ns.MacroSearch.Reapply then
        ns.MacroSearch.Reapply()
    end
end

-- ============ 全局钩子（taint-safe） ============

local function EnsureHooks()
    if HOOKS_INSTALLED then return end
    HOOKS_INSTALLED = true
    -- 开窗按当前状态应用 / 还原；关窗兜底还原（模块已被关闭时）
    hooksecurefunc("ShowUIPanel", function(panel)
        if panel == MacroFrame then
            if IsModuleActive() then
                ApplyResize()
            else
                RestoreResize()
            end
        end
    end)
    hooksecurefunc("HideUIPanel", function(panel)
        if panel == MacroFrame and not IsModuleActive() then
            RestoreResize()
        end
    end)
    -- 切换宏后保持滚动位置（重排发生在 Blizzard 的 SelectMacro 内部，hook 后置执行）
    hooksecurefunc(MacroFrame, "SelectMacro", function()
        if TEMP_SCROLL_PER then
            MacroFrame.MacroSelector.ScrollBox:SetScrollPercentage(TEMP_SCROLL_PER)
            TEMP_SCROLL_PER = nil
        end
    end)
end

local function OnEvent(_, event, addon)
    if event == "ADDON_LOADED" then
        if addon == "Blizzard_MacroUI" then
            EnsureHooks()
            ApplyResize()
        end
    elseif event == "UPDATE_MACROS" then
        local sel = MacroFrame and MacroFrame.MacroSelector
        if sel and sel.ScrollBox then
            TEMP_SCROLL_PER = sel.ScrollBox.scrollPercentage
        end
    end
end

-- ============ 生命周期（V5 模块调度） ============

function module.Init()
    if frame then return end
    if MacroFrame then
        EnsureHooks()
        ApplyResize()
        return
    end
    frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", OnEvent)
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("UPDATE_MACROS")
end

--- 供 Settings 在参数改动后即时生效
function module.ApplySettings()
    if not MacroFrame then return end
    if not MacroFrame:IsShown() then return end
    if IsModuleActive() then
        C_Timer.After(0.05, ApplyResize)
    else
        -- 取消「启用界面尺寸调整」后即时还原原生尺寸（否则要等关窗才还原）
        RestoreResize()
    end
end

function module.Disable()
    if frame then
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        frame = nil
    end
    if MacroFrame and MacroFrame:IsShown() then
        RestoreResize()
    end
end

-- 对外：供设置页 / 其它模块取用
module.Restore = Restore
module.RestoreResize = RestoreResize
module.ApplyResize = ApplyResize
module.GetSearchBarOffset = GetSearchBarOffset
module.SEARCHBAR_BASE_H = SEARCHBAR_BASE_H

-- 对外：布局参数约束单一数据源（设置页据此派生滑条范围 / 置灰状态）；
-- 默认布局值已集中到 InitDB.lua（ns.defaults.profile.macroresize），本模块不再持有 LAYOUT_DEFAULTS / DEFAULT_TEXT
module.LAYOUT_SPECS = LAYOUT_SPECS
module.LAYOUT_MODES = { VERTICAL, HORIZONTAL }
module.DEFAULT_MODE = DEFAULT_MODE
module.TEXT_MIN = TEXT_MIN
module.TEXT_MAX = TEXT_MAX
module.TEXT_STEP = TEXT_STEP
module.GetMode = GetMode
module.GetSpec = GetLayoutSpec
module.GetLayoutValues = GetLayoutValues
module.SetLayoutValues = SetLayoutValues
module.GetRightWidth = GetRightWidth
module.RIGHTW_MIN = RIGHTW_MIN
module.RIGHTW_MAX = RIGHTW_MAX
module.RIGHTW_STEP = RIGHTW_STEP
module.ResetLayout = ResetLayout
