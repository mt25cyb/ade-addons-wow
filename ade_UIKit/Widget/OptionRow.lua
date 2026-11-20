------------------------------------------------------------
-- 选项行 OptionRow（控件组合，b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowOption.lua 更名）：
-- 一行 = label + 右列控件（toggle/range/select/execute/input/multiline/key/color 八类按
-- option.Type 二选一）+ with 副控件 + 悬停/变更/重置装饰。含宿主扁平 spec →
-- KAF option 接口的适配（MakeOption）与键位捕获（StartKeyCapture 族）。
-- b034：① execute 类型点击 onClick 优先于 set（spec 可同时带两者——KeySpec 无条件塞
-- set 曾致 onClick 永不执行，用户实测 adeMapExt 颜色按钮点击无反应）；② 新增 kind="color"
-- 颜色选择器：色块（BackdropTemplate WHITE8X8 着色）+ 官方 ColorPickerFrame
-- （SetupColorPickerAndShow/swatchFunc/cancelFunc），get/set/default 均为 8 位 hex。
-- b031/b032：select 类支持材质/字体直接预览（参照 DBM-GUI_DropDownNEW.lua:160-181）——
-- items 项带 texture / font 字段或 spec.preview(value) 函数（string=材质 / table={font,size,flags}）；
-- 材质项 AttachTexture 铺满整行（200×25），字体项 fontString:SetFontObject 直接用该字体渲染，
-- 选中区铺满当前材质。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L, Internal = lib.L, lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry
local Protected, Ask = Internal.Protected, Internal.Ask

-- [[ 宿主 spec → KAF option 接口 ]] --
function Internal.MakeOption(spec)
    -- KAF RowMixins.lua:21：Type 是控件类型；宿主的 key 是存档键，不能当类型用。
    local kind = spec.type or spec.kind or "toggle"
    local known = { toggle = true, range = true, select = true, execute = true, input = true, key = true, multiline = true, color = true }
    if not known[kind] then kind = "toggle" end
    local option = { Type = kind, Spec = spec,
        Indent = spec.indent, Placeholder = spec.placeholder }
    function option:GetLabel() return tostring(spec.label or spec.text or "") end
    -- b039：desc 支持函数式（每次取描述时求值）——外部联动选项未加载时动态提示
    -- 「未检测到 XX，已禁用」；配合函数式 disabled（IsDisabled 每次 Refresh 重估）。
    function option:GetDescription()
        local desc = spec.desc
        if type(desc) == "function" then desc = desc() end
        return desc
    end
    function option:IsHidden() return spec.hidden == true end
    function option:IsDisabled()
        if type(spec.disabled) == "function" then return spec.disabled() == true end
        return spec.disabled == true
    end
    function option:Get() return Ask(spec.default, spec.get) end
    function option:Set(value)
        -- 键位行的 value 必须是字符串：异常值不写入绑定系统（SetBinding 会抛断言）。
        if option.Type == "key" and type(value) ~= "string" then return end
        if spec.set then Protected(spec.set, value)
        elseif spec.onClick then Protected(spec.onClick) end
        if self.Window then self.Window:OnOptionChanged(self) end
    end
    function option:GetDefault() return spec.default ~= nil, spec.default end
    function option:IsChanged()
        local has, def = option:GetDefault()
        return has and option:Get() ~= def
    end
    function option:Reset()
        local has, def = option:GetDefault()
        if has then option:Set(def) end
    end
    function option:GetNeedsReload() return spec.needsReload == true end
    function option:GetRange() return spec.low or spec.min or 0, spec.high or spec.max or 100, spec.step or 1 end
    function option:Format(value)
        if type(spec.format) == "function" then return Ask(tostring(value), spec.format, value) end
        if spec.format then return tostring(spec.format):gsub("%%d", tostring(value)) end
        return tostring(math.floor((tonumber(value) or 0) * 100 + 0.5) / 100)
    end
    function option:GetButtonText() return tostring(spec.text or spec.label or "") end
    -- b019：multiline 行把实际 EditBox 暴露给宿主（导出按钮写串/全选用）。
    function option:SetEditBox(edit)
        spec.editBox = edit
        if type(spec.onEditBox) == "function" then spec.onEditBox(edit) end
    end
    function option:GetValues()
        -- b025：items 支持函数式（调用时求值），供宿主做动态下拉——LSM 介质注册
        -- 晚于宿主加载、来源可用性随外部插件加载而变（Init/Refresh 每次行渲染都会
        -- 重跑 GetValues，快照始终最新）。
        local items = spec.items
        if type(items) == "function" then items = items() end
        local values = {}
        for i, item in ipairs(items or {}) do
            if type(item) == "table" then
                values[i] = { value = item.value ~= nil and item.value or item[1], text = tostring(item.text or item[2] or item[1]),
                    -- b032：材质/字体预览——每项可带 texture（路径/FileID）或 font（字体文件路径）
                    texture = item.texture, font = item.font }
            else
                values[i] = { value = item, text = tostring(item) }
            end
        end
        return values
    end
    -- b032：预览解析。宿主可在 spec.preview(value) 里做 LSM 名→路径转换（UIKit 本身不依赖
    -- LibSharedMedia）：返回 string = 材质路径；返回 table {font=,size=,flags=} = 字体组；
    -- 返回 nil 表示该项无预览。
    function option:GetPreview(value)
        if type(spec.preview) == "function" then return spec.preview(value) end
        return nil
    end
    if option.Type == "key" then
        -- KAF RowMixins.lua:25：Slots 可有两个键位；宿主 slots 数组给各自的 get/set，缺省回落到本 option。
        local slots = (type(spec.slots) == "table" and #spec.slots > 0) and spec.slots or { spec }
        option.Slots = {}
        -- 单项恢复默认（Reset）必须清全部键位槽：只走 option:Set 只会写主槽，双键位的第二槽残留脏值。
        function option:Reset()
            local has, def = option:GetDefault()
            if not has then return end
            for i = 1, #slots do option.Slots[i]:Set(def) end
        end
        for i, slot in ipairs(slots) do
            option.Slots[i] = {
                Get = function(self)
                    if slot ~= spec and slot.get then return Ask(slot.default, slot.get) end
                    return option:Get()
                end,
                Set = function(self, value)
                    -- 冒号调用 slotOption:Set(combo) 会传入 self（即本 Slots 表）：
                    -- 必须显式接住，否则 value 错位成 self，键位值永远收不到字符串（log 实证）。
                    if option.Type == "key" and type(value) ~= "string" then return end
                    if slot ~= spec and slot.set then
                        Protected(slot.set, value)
                        if option.Window then option.Window:OnOptionChanged(option) end
                    else
                        option:Set(value)
                    end
                end,
            }
        end
    end
    return option
end

-- [[ 行内控件定位 ]] --  KAF RowMixins.lua:150-154（列几何本体在 Parts）
local function Place(region, row, spec)
    region:ClearAllPoints()
    region:SetPoint("LEFT", row, spec[1], spec[2], 0)
end
local placedControls = { Toggle = "Toggle", Range = "Range", Select = "Select", Execute = "Execute", Input = "Input", Key = "Key1", Color = "Color" }

-- [[ 子控件构建 ]] --  KAF RowFrames.lua:128-179
local iconButtonScripts = { "OnShow", "OnMouseDown", "OnMouseUp", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }
local function IconButton(parent, normalAtlas, disabledAtlas)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(26, 25)
    button.Background = button:CreateTexture(nil, "BACKGROUND")
    button.Background:SetPoint("CENTER")
    button.Icon = button:CreateTexture(nil, "OVERLAY")
    button.Icon:SetPoint("CENTER")
    Mixin(button, WowStyle2IconButtonMixin)
    button.normalAtlas, button.disabledAtlas = normalAtlas, disabledAtlas
    for _, script in ipairs(iconButtonScripts) do
        if button[script] then button:SetScript(script, button[script]) end
    end
    if button.OnLoad then button:OnLoad() end
    return button
end

function build.Select(parent)
    local select = CreateFrame("Frame", nil, parent)
    select:SetSize(250, 26)
    select.IncrementButton = IconButton(select, "common-dropdown-icon-next", "common-dropdown-icon-next-disabled")
    select.DecrementButton = IconButton(select, "common-dropdown-icon-back", "common-dropdown-icon-back-disabled")
    select.Dropdown = CreateFrame("DropdownButton", nil, select, "WowStyle2DropdownTemplate")
    select.Dropdown:SetSize(220, 26)
    select.Dropdown:SetPoint("CENTER")
    -- b031：材质预览层。铺满选中区（SetBackdrop 的 bgFile 同为拉伸铺满，观感即实际效果），
    -- 位置在模板 Background atlas 之上、Text/Arrow（OVERLAY 层）之下。
    select.Dropdown.Preview = select.Dropdown:CreateTexture(nil, "BACKGROUND")
    select.Dropdown.Preview:SetAllPoints()
    select.Dropdown.Preview:Hide()
    Mixin(select, DropdownWithSteppersMixin)
    if select.OnLoad then select:OnLoad() end
    return select
end

-- b034：颜色选择器色块（kind="color"）。显示当前颜色的方块按钮，点击打开官方
-- ColorPickerFrame（12.x 契约 SetupColorPickerAndShow + swatchFunc/cancelFunc，
-- 实证 adeStatPlus/adeMapExt 同款用法）。get/set/default 均为 8 位 hex（AARRGGBB）。
local function HexRGBA(hex)
    local color = CreateColorFromHexString(tostring(hex))
    if color then return color.r, color.g, color.b, color.a end
    return 1, 1, 1, 1
end
local function RGBAHex(r, g, b, a)
    local byte = function(v) return math.max(0, math.min(255, math.floor(v * 255 + 0.5))) end
    return string.format("%02x%02x%02x%02x", byte(a or 1), byte(r), byte(g), byte(b))
end

-- b036：色块控件改用暴雪原生 ColorSwatch 观感（Blizzard_SharedXMLBase/ColorSwatch.xml
-- ColorSwatchTemplate 16×16 三层嵌套方块 + ColorSwatch.lua 的悬停边框变色）：
-- 金色外框 14×14（静止 HIGHLIGHT_FONT_COLOR、悬停 NORMAL_FONT_COLOR）→ 黑框 12×12 → 色块 10×10。
-- ⚠ 不得叫 build.Color——Parts.lua 的 build.Color(frame,layer,r,g,b,a) 是纯色 Texture 积木
-- （ChangedBar 前置标识同用），b034 曾因重名覆盖导致变更条变黑（用户实测）。
function build.ColorSwatch(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(16, 16)
    button.SwatchBg = button:CreateTexture(nil, "BACKGROUND", nil, -3)
    button.SwatchBg:SetColorTexture(HIGHLIGHT_FONT_COLOR:GetRGB())
    button.InnerBorder = button:CreateTexture(nil, "BACKGROUND", nil, -2)
    button.InnerBorder:SetColorTexture(BLACK_FONT_COLOR:GetRGB())
    button.Color = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.Color:SetColorTexture(1, 1, 1)
    for _, tex in ipairs({ button.SwatchBg, button.InnerBorder, button.Color }) do
        tex:SetPoint("CENTER")
        tex.texelSnappingBias = 0.0
        tex.snapToPixelGrid = false
    end
    PixelUtil.SetSize(button.SwatchBg, 14, 14)
    PixelUtil.SetSize(button.InnerBorder, 12, 12)
    PixelUtil.SetSize(button.Color, 10, 10)
    -- 悬停边框变色（ColorSwatch.lua OnEnter/OnLeave 同款）
    button:SetScript("OnEnter", function(self) self.SwatchBg:SetColorTexture(NORMAL_FONT_COLOR:GetRGB()) end)
    button:SetScript("OnLeave", function(self) self.SwatchBg:SetColorTexture(HIGHLIGHT_FONT_COLOR:GetRGB()) end)
    return button
end

-- b034：色块着色（当前存档 hex → 内层 Color 纹理；无效 hex 白色兜底）
local function RefreshSwatch(row, option)
    if not row.Color or not option then return end
    local r, g, b, a = HexRGBA(option:Get())
    row.Color.Color:SetVertexColor(r, g, b, a)
end

function build.OptionRow(parent) -- KAF RowFrames.lua:192-270
    local row = build.Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = build.Hover(row)
    row.Label = build.Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(true)
    row.Label:SetMaxLines(2)
    row.Label:SetPoint("LEFT", 16, 0)
    row.ReloadIcon = row:CreateTexture(nil, "ARTWORK")
    row.ReloadIcon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    row.ReloadIcon:SetSize(12, 12)
    row.ReloadIcon:SetPoint("LEFT", row.Label, "RIGHT", 6, 0)
    row.ReloadIcon:Hide()
    row.ChangedBar = build.Color(row, "ARTWORK", 1, 0.82, 0, 1)
    row.ChangedBar:SetWidth(2)
    row.ChangedBar:SetPoint("TOPLEFT", 0, -4)
    row.ChangedBar:SetPoint("BOTTOMLEFT", 0, 4)
    row.ChangedBar:Hide()
    local reset = CreateFrame("Button", nil, row)
    reset:SetSize(12, 12)
    reset:SetPoint("RIGHT", row.Label, "LEFT", -2, 0)
    reset:SetNormalAtlas("common-icon-undo")
    reset:SetHighlightAtlas("common-icon-undo", "ADD")
    reset:Hide()
    row.Reset = reset
    row.Toggle = build.CheckButton(row)
    row.Toggle:Hide()
    row.Range = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    row.Range:SetSize(geometry.SliderWidth, 20)
    row.Range:Hide()
    row.Select = build.Select(row)
    row.Select:Hide()
    row.Execute = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.Execute:SetSize(200, 22)
    row.Execute:Hide()
    row.Color = build.ColorSwatch(row)
    row.Color:Hide()
    row.Input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.Input:SetAutoFocus(false)
    row.Input:SetSize(240, 20)
    row.Input:Hide()
    -- b019：多行文本行（kind="multiline"），holder + ScrollFrameTemplate + 多行 EditBox。
    -- EditBox 作为 ScrollChild 高度随内容增长；空框时点击 holder 中间也能把焦点导给 EditBox。
    row.Multi = CreateFrame("Frame", nil, row, "BackdropTemplate")
    -- edgeSize 必须给：edgeFile 用 WHITE8X8 时不限定会被拉伸成整块，造成边框「变形」。
    row.Multi:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    row.Multi:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
    row.Multi:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.85)
    row.Multi:SetPoint("TOPLEFT", row, "TOPLEFT", 16, -22)
    row.Multi:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -16, 3)
    row.Multi:EnableMouse(true)
    row.MultiScroll = CreateFrame("ScrollFrame", nil, row.Multi, "ScrollFrameTemplate")
    row.MultiScroll:SetPoint("TOPLEFT", 4, -4)
    row.MultiScroll:SetPoint("BOTTOMRIGHT", -22, 4)
    row.MultiEdit = CreateFrame("EditBox", nil, row.MultiScroll)
    row.MultiEdit:SetMultiLine(true)
    row.MultiEdit:SetAutoFocus(false)
    row.MultiEdit:SetFontObject("GameFontHighlightSmall")
    row.MultiEdit:SetTextInsets(4, 4, 4, 4)
    row.MultiEdit:SetMaxLetters(0)
    row.MultiEdit:SetWidth(300)
    row.MultiEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.MultiScroll:SetScrollChild(row.MultiEdit)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(row.MultiScroll, row.MultiScroll.ScrollBar)
    end
    row.Multi:SetScript("OnMouseDown", function() row.MultiEdit:SetFocus() end)
    row.Multi:SetScript("OnSizeChanged", function(self)
        if self.Edit then self.Edit:SetWidth(math.max(100, self:GetWidth() - 30)) end
    end)
    row.Multi.Edit = row.MultiEdit
    row.Multi:Hide()
    row.Key1 = build.KeyButton(row)
    row.Key1:Hide()
    row.Key2 = build.KeyButton(row)
    row.Key2:SetPoint("LEFT", row.Key1, "RIGHT")
    row.Key2:Hide()
    return build.Finish(row, mixins.OptionRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ OptionRow 行为 ]] --  KAF RowMixins.lua:138-617
mixins.OptionRow = mixins.OptionRow or {}
local OptionRowMixin = mixins.OptionRow

-- KAF RowMixins.lua:155、:585：键位捕获的键与鼠标键表。必须在 OnLoad 的脚本闭包之前定义（Lua 的 local 作用域），
-- 否则闭包里引用到的是全局，点击键位按钮时崩 "attempt to index global 'mouseButtons'"。
local mouseButtons = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
local ignoredKeys = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, UNKNOWN = true }

local function HoverWhileDisabled(control)
    if control.SetMotionScriptsWhileDisabled then control:SetMotionScriptsWhileDisabled(true) end
end
local function Forward(control, row)
    HoverWhileDisabled(control)
    control:HookScript("OnEnter", function() row:OnEnter(control) end)
    control:HookScript("OnLeave", function() row:OnLeave() end)
end

local function Changed(row)
    local option = row.Option
    if not option then return false end
    return option:IsChanged() or row.With and row.With:IsChanged() or false
end

-- KAF RowMixins.lua:276-303：滑块按 (当前值, 最小, 最大, 步数, 格式) 初始化，刷新时屏蔽变更回调。
local function RangeValue(option, min, max)
    return math.min(math.max(tonumber(option:Get()) or min, min), max)
end
local function InitRange(row, option)
    local min, max, step = option:GetRange()
    row.Updating = true
    local steps = step and step > 0 and math.floor((max - min) / step + 0.5) or 100
    row.Range:Init(RangeValue(option, min, max), min, max, math.max(steps, 1), {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right,
            function(value)
                return option.Format and option:Format(value) or tostring(math.floor(value * 100 + 0.5) / 100)
            end),
    })
    row.Updating = nil
    row.Range:Show()
end
local function RefreshRange(row, option, disabled)
    local min, max = option:GetRange()
    row.Updating = true
    row.Range:SetValue(RangeValue(option, min, max))
    row.Updating = nil
    row.Range:SetEnabled(not disabled)
end

local function InputText(value) return value == nil and "" or tostring(value) end

local function KeepChoices(choices, values)
    choices.Count = #values
    for i, value in ipairs(values) do
        choices[2 * i - 1], choices[2 * i] = value.value, value.text
    end
end
local function SameChoices(choices, values)
    if choices.Count ~= #values then return false end
    for i, value in ipairs(values) do
        if choices[2 * i - 1] ~= value.value or choices[2 * i] ~= value.text then return false end
    end
    return true
end
local function SelectShown(row, option, values)
    local current = option:Get()
    for _, value in ipairs(values) do
        if value.value == current then return current end
    end
    if #values > 0 then
        local first = values[1].value
        option:Set(first)
        return first
    end
    return nil
end

-- b032：菜单项/选中区预览（参照 DBM-GUI_DropDownNEW.lua:160-181 的字体与材质实现）：
--   材质项 = AttachTexture 铺满整行（TOPLEFT(15,0)/BOTTOMRIGHT + return 200,25，DBM 同款）；
--   字体项 = CreateFont 出 Font 对象后 initializer 里 fontString:SetFontObject——
--   ⚠ DBM 实证注释（DBM-GUI_DropDownNEW.lua:170）：initializer 内直接 SetFont 会静默失效。
local defaultFont, defaultFontSize = GameFontHighlightSmall:GetFont()

-- 解析第 i 项的预览：{ type="texture", texture=path } 或 { type="font", font, size, flags }，nil = 无。
local function ResolvePreview(row, option, values, i)
    local item, value = values[i], values[i].value
    if item.font then return { type = "font", font = item.font, size = item.fontsize, flags = item.fontflags } end
    if item.texture then return { type = "texture", texture = item.texture } end
    local p = option:GetPreview(value)
    if type(p) == "table" and p.font then
        return { type = "font", font = p.font, size = p.size, flags = p.flags }
    elseif type(p) == "table" and p.texture then
        return { type = "texture", texture = p.texture }
    elseif type(p) == "string" then
        return { type = "texture", texture = p }
    end
    return nil
end

-- Init/Refresh 时重建每项预览快照（GetValues 的动态项每次渲染都重解析）。
local function BuildPreviewInfo(row, option, values)
    row.PreviewInfo, row.PreviewFonts = row.PreviewInfo or {}, row.PreviewFonts or {}
    for i = 1, #values do
        local info = ResolvePreview(row, option, values, i)
        row.PreviewInfo[i] = info
        if info and info.type == "font" then
            -- Font 对象在菜单外创建（可缓存复用）；initializer 内只做 SetFontObject。
            -- 带唯一名创建（官方用例均带名，FontableFrameMixin.lua:120；DBM 同模式）
            local font = CreateFont("BOF_SELECT_FONT_PREVIEW_" .. tostring(values[i].value))
            font:SetFont(info.font, info.size or defaultFontSize, info.flags or "")
            row.PreviewFonts[i] = font
        end
    end
end

-- 选中区材质预览（build.Select 的 Dropdown.Preview）。◄ ► 步进/点选时同步换材质；
-- 字体预览只作用于菜单项文字（DBM 同款），选中区不铺。
local function RefreshPreview(row, option)
    local preview = row.Select.Dropdown.Preview
    if not preview then return end
    local info
    local shown = row.SelectShown
    if shown ~= nil then
        for i = 1, (row.Choices and row.Choices.Count) or 0 do
            if row.Choices[2 * i - 1] == shown then info = row.PreviewInfo and row.PreviewInfo[i] end
        end
    end
    if info and info.type == "texture" then preview:SetTexture(info.texture); preview:Show()
    else preview:SetTexture(nil); preview:Hide() end
end

local optionTypes = {
    toggle = {
        Place = "Toggle",
        Init = function(row) row.Toggle:Show() end,
        Refresh = function(row, option, disabled)
            row.Toggle:SetChecked(option:Get() and true or false)
            row.Toggle:SetEnabled(not disabled)
        end,
    },
    range = {
        Place = "Range",
        Init = function(row, option) InitRange(row, option) end,
        Refresh = function(row, option, disabled) RefreshRange(row, option, disabled) end,
    },
    select = {
        Place = "Select",
        Init = function(row, option, window)
            local dropdown = row.Select.Dropdown
            local values = option:GetValues()
            row.Choices = row.Choices or {}
            KeepChoices(row.Choices, values)
            row.SelectShown = SelectShown(row, option, values)
            -- b032：每项预览快照（item.texture / item.font 优先，spec.preview(value) 兜底），
            -- 菜单每次展开时按快照挂 DBM 式预览。
            BuildPreviewInfo(row, option, values)
            dropdown:SetupMenu(function(_, root)
                -- b026：长列表滚动。新 Menu 系统默认不滚动（scrollable=false，
                -- 超出屏幕即截断，Menu.lua:227 BaseMenuDescriptionMixin:SetScrollMode），
                -- 显式开启；500 ≈ 19 个 26px 行（暴雪自家取 400–600）。
                root:SetScrollMode(500)
                local choices = row.Choices
                for i = 1, choices.Count or 0 do
                    local value = choices[2 * i - 1]
                    local radio = root:CreateRadio(choices[2 * i], function() return row.SelectShown == value end, function()
                        option:Set(value)
                        window:OnOptionChanged(option)
                    end, value)
                    local info = row.PreviewInfo and row.PreviewInfo[i]
                    if info and info.type == "texture" then
                        -- 材质项铺满整行（DBM-GUI_DropDownNEW.lua:175-181 同款：TOPLEFT 偏移
                        -- 15px、BOTTOMRIGHT 对齐行右缘，行尺寸 200×25；Attach 区域菜单关闭自动回收）。
                        -- 文字提到 OVERLAY 层 + 加深阴影（b035：DBM 同款实现会把文字盖住，
                        -- 用户实测要求材质名称仍可读）
                        radio:AddInitializer(function(button)
                            local t = button:AttachTexture()
                            t:SetPoint("TOPLEFT", 15, 0)
                            t:SetPoint("BOTTOMRIGHT")
                            t:SetTexture(info.texture)
                            local fs = button.fontString
                            if fs then
                                fs:SetDrawLayer("OVERLAY")
                                fs:SetShadowColor(0, 0, 0, 1)
                                fs:SetShadowOffset(1, -1)
                            end
                            return 200, 25
                        end)
                    elseif info and info.type == "font" then
                        -- 字体项：菜单项文字直接用该字体渲染（DBM-GUI_DropDownNEW.lua:172-174 同款
                        -- SetFontObject；⚠ initializer 内直接 SetFont 会静默失效，见 DBM 源注释）
                        local fontObj = row.PreviewFonts and row.PreviewFonts[i]
                        if fontObj then
                            radio:AddInitializer(function(button)
                                button.fontString:SetFontObject(fontObj)
                            end)
                        end
                    end
                end
            end)
            if dropdown.SetDefaultText then dropdown:SetDefaultText(option.Placeholder or "") end
            RefreshPreview(row, option)
            row.Select:Show()
        end,
        Refresh = function(row, option, disabled)
            local values = option:GetValues()
            local shown = SelectShown(row, option, values)
            row.Choices = row.Choices or {}
            if not SameChoices(row.Choices, values) then
                KeepChoices(row.Choices, values)
                row.SelectShown = shown
                BuildPreviewInfo(row, option, values)
                if row.Select.Dropdown.GenerateMenu then row.Select.Dropdown:GenerateMenu() end
            elseif shown ~= row.SelectShown then
                row.SelectShown = shown
                if row.Select.Dropdown.Update then row.Select.Dropdown:Update() end
            end
            RefreshPreview(row, option)
            row.Select:SetEnabled(not disabled)
        end,
    },
    execute = {
        Place = "Execute",
        Init = function(row, option) row.Execute:SetText(option:GetButtonText()); row.Execute:Show() end,
        Refresh = function(row, _, disabled) row.Execute:SetEnabled(not disabled) end,
    },
    color = {
        Place = "Color",
        Init = function(row, option) RefreshSwatch(row, option); row.Color:Show() end,
        Refresh = function(row, option, disabled)
            RefreshSwatch(row, option)
            row.Color:SetEnabled(not disabled)
        end,
    },
    input = {
        Place = "Input",
        Init = function(row) row.Input:Show() end,
        Refresh = function(row, option, disabled)
            local text = InputText(option:Get())
            if not row.Input:HasFocus() or text ~= row.InputStart then
                row.Input:SetText(text)
                row.InputStart = text
            end
            row.Input:SetEnabled(not disabled)
        end,
    },
    -- b019：多行文本行，label 贴顶且与 NameLeft 同缩进、可滚动 EditBox 独占下半部分；失焦时提交。
    multiline = {
        Init = function(row, option)
            row.Multi:Show()
            if option and option.SetEditBox then option:SetEditBox(row.MultiEdit) end
            local left = row.Geometry.NameLeft[2]
            row.Label:ClearAllPoints()
            row.Label:SetPoint("TOPLEFT", row, "TOPLEFT", left, -3)
            row.Label:SetPoint("RIGHT", row, "RIGHT", -16, 0)
            -- b021：框本身也跟随标题缩进（此前固定 16，比标题左移一级）。
            row.Multi:ClearAllPoints()
            row.Multi:SetPoint("TOPLEFT", row, "TOPLEFT", left, -22)
            row.Multi:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -16, 3)
        end,
        Refresh = function(row, option, disabled)
            local text = InputText(option:Get())
            local edit = row.MultiEdit
            if not edit:HasFocus() or text ~= row.MultiStart then
                edit:SetText(text)
                row.MultiStart = text
            end
            edit:SetEnabled(not disabled)
        end,
    },
    key = {
        Place = "Key",
        Init = function(row, option)
            row.Key1:Show()
            row.Key2:SetShown(option.Slots and option.Slots[2] ~= nil)
        end,
        Refresh = function(row, option, disabled, strings)
            local inCombat = row.Window and row.Window:InCombat()
            for slot, button in ipairs({ row.Key1, row.Key2 }) do
                local slotOption = option.Slots and option.Slots[slot]
                if slotOption then
                    local key = slotOption:Get()
                    if key ~= nil and type(key) ~= "string" then key = tostring(key) end
                    -- KAF RowMixins.lua:468-470；对 GetBindingText 可能的空串回落原始键名。
                    local bound = key and key ~= "" and GetBindingText(key) or nil
                    if bound ~= nil and bound == "" then bound = key end
                    local text = row.Capturing == slot and (strings and strings.PressAKey or "Press a key") or bound
                    local fallback = strings and strings.NotBound or "Not bound"
                    if GRAY_FONT_COLOR then fallback = GRAY_FONT_COLOR:WrapTextInColorCode(fallback) end
                    button:SetText(text ~= nil and tostring(text) or fallback)
                    button:SetAlpha(text and 1 or 0.8)
                    button.SelectedHighlight:SetShown(row.Capturing == slot)
                    button:SetEnabled(not disabled and not inCombat)
                end
            end
        end,
    },
}

local function WithControl(row)
    if not row.With then return row.Execute end
    if row.With.Type == "range" then return row.Range end
    if row.With.Type == "color" then return row.Color end
    return row.Execute
end

function OptionRowMixin:OnLoad()
    if not self._forwarded then
        self._forwarded = true
        for _, control in ipairs({ self.Reset, self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Multi, self.Key1, self.Key2, self.Color }) do
            Forward(control, self)
        end
        self.Toggle:SetScript("OnClick", function()
            if not self.Option then return end
            self.Option:Set(not self.Option:Get())
            self.Window:OnOptionChanged(self.Option)
        end)
        self.Execute:SetScript("OnClick", function()
            local option = self.With or self.Option
            if not option then return end
            -- b034：execute 类型 onClick 优先于 set——spec 可能同时带两者（如 KeySpec
            -- 无条件塞 set），用户点击语义是执行 onClick；程序化 Set（Reset）仍走 set。
            if option.Type == "execute" and option.Spec and option.Spec.onClick then
                Protected(option.Spec.onClick)
            else
                option:Set(true)
                if self.Window then self.Window:OnOptionChanged(option) end
            end
        end)
        -- b034：色块点击 → 官方 ColorPickerFrame。swatchFunc 实时回写 hex 并刷新色块；
        -- cancelFunc 还原打开时的存档值（closure 捕获 startHex，比 prev 参数更直接）。
        self.Color:SetScript("OnClick", function()
            -- 色块可能是 toggle 的 with 副控件（如「使用职业色」+自定义色），
            -- 此时要操作 with 的颜色值而非宿主 toggle。
            local option = self.With and self.With.Type == "color" and self.With or self.Option
            if not option or option.Type ~= "color" then return end
            if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
            local startHex = tostring(option:Get() or "")
            local r, g, b, a = HexRGBA(startHex)
            local hasOpacity = option.Spec and option.Spec.opacity == true
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b, hasOpacity = hasOpacity,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = hasOpacity and ColorPickerFrame:GetColorAlpha() or a
                    local hex = RGBAHex(nr, ng, nb, na)
                    option:Set(hex)
                    if self.Window then self.Window:OnOptionChanged(option) end
                    RefreshSwatch(self, option)
                end,
                cancelFunc = function()
                    option:Set(startHex)
                    if self.Window then self.Window:OnOptionChanged(option) end
                    RefreshSwatch(self, option)
                end,
            })
        end)
        self.Range:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if self.Updating then return end
            local option = self.With and self.With.Type == "range" and self.With or self.Option
            if not option or option:Get() == value then return end
            option:Set(value)
        end)
        self.Input:SetScript("OnEnterPressed", function(edit)
            if self.Option then self.Option:Set(edit:GetText()); self.Window:OnOptionChanged(self.Option) end
            edit:ClearFocus()
        end)
        self.Input:SetScript("OnEscapePressed", function(edit)
            edit:SetText(self.Option and InputText(self.Option:Get()) or "")
            edit:ClearFocus()
        end)
        -- b019：多行框失焦即提交；Esc 先还原原值再失焦，故不会误写。
        self.MultiEdit:SetScript("OnEditFocusLost", function(edit)
            if not self.Option then return end
            local text = edit:GetText()
            if text ~= InputText(self.Option:Get()) then
                self.Option:Set(text)
                if self.Window then self.Window:OnOptionChanged(self.Option) end
            end
        end)
        self.MultiEdit:SetScript("OnEscapePressed", function(edit)
            edit:SetText(self.Option and InputText(self.Option:Get()) or "")
            edit:ClearFocus()
        end)
        -- b019：文本变化回调（导入框实时校验用），只在用户真正键入时触发。
        self.MultiEdit:SetScript("OnTextChanged", function(edit, userChanged)
            local spec = self.Option and self.Option.Spec
            if spec and spec.onTextChanged then spec.onTextChanged(edit, userChanged) end
        end)
        self.Reset:SetScript("OnClick", function()
            if not self.Option then return end
            self.Option:Reset()
            if self.With then self.With:Reset() end
            if self.Window then self.Window:OnOptionChanged(self.Option, self.With) end
        end)
        for slot, button in ipairs({ self.Key1, self.Key2 }) do
            button:SetScript("OnClick", function() self:StartKeyCapture(slot) end)
            button:SetScript("OnKeyDown", function(_, key) self:OnKeyCaptured(slot, key) end)
            -- KAF RowMixins.lua:256-259：捕获期也收鼠标侧键与滚轮。
            button:HookScript("OnMouseDown", function(_, mouseButton)
                if mouseButtons[mouseButton] then self:OnKeyCaptured(slot, mouseButtons[mouseButton]) end
            end)
            button:SetScript("OnMouseWheel", function(_, delta)
                self:OnKeyCaptured(slot, delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
            end)
            -- KAF RowMixins.lua:260-261：构建时就要关键盘/滚轮，只在捕获期临时打开。
            -- 缺这两行时按钮一进可视范围就吞掉全部按键；点一次走到 EndKeyCapture 才恢复，正是用户看到的症状。
            button:EnableKeyboard(false)
            button:EnableMouseWheel(false)
        end
    end
end

function OptionRowMixin:Init(element, window)
    self.Option = nil
    self:EndKeyCapture()
    for _, control in ipairs({ self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Multi, self.Key1, self.Key2, self.Color }) do
        control:Hide()
    end
    self.InputKept, self.InputStart, self.MultiStart, self.Repaired = false, false, false, false
    self.Element, self.Window, self.Option = element, window, element.Option
    local option = self.Option
    if not option then return end
    option.Window = window
    self.With = option.Type == "toggle" and element.With and not element.With:IsHidden() and element.With or nil
    if self.With then self.With.Window = window end
    local g = Internal.RowGeometry(option.Indent)
    self.Geometry = g
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", self, g.NameLeft[1], g.NameLeft[2], 0)
    self.Label:SetPoint("RIGHT", self, g.NameRight[1], g.NameRight[2], 0)
    for place, key in next, placedControls do
        if self[key] then Place(self[key], self, g[place]) end
    end
    self.Range:SetWidth(geometry.SliderWidth)
    self.Label:SetText(option:GetLabel())
    local optionType = optionTypes[option.Type]
    if optionType then optionType.Init(self, option, window) end
    local with, control = self.With, WithControl(self)
    if with then
        control:ClearAllPoints()
        control:SetPoint("LEFT", self.Toggle, "RIGHT", 5, 0)
        if with.Type == "range" then
            self.Range:SetWidth(geometry.WithSliderWidth)
            InitRange(self, with)
        elseif with.Type == "color" then
            RefreshSwatch(self, with)
            self.Color:Show()
        else
            self.Execute:SetText(with:GetButtonText())
            self.Execute:Show()
        end
    end
    self:Refresh()
end

local function UnderMouse(row)
    return row:IsMouseOver() and row.Window and row.Window.PageScrollBox and row.Window.PageScrollBox:IsMouseOver()
end

function OptionRowMixin:Refresh()
    local option = self.Option
    if not option then return end
    local disabled = option:IsDisabled()
    local strings = self.Window and self.Window.Strings
    self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    local optionType = optionTypes[option.Type]
    if optionType then optionType.Refresh(self, option, disabled, strings) end
    local with = self.With
    local needsReload = option:GetNeedsReload() or with ~= nil and with:GetNeedsReload()
    self.ReloadIcon:SetShown(needsReload)
    if needsReload then
        self.ReloadIcon:SetPoint("LEFT", self.Label, "LEFT", math.min(self.Label:GetStringWidth(), self.Label:GetWidth()) + 6, 0)
    end
    local changed = Changed(self)
    self.ChangedBar:SetShown(changed)
    self.Reset:SetShown(changed and UnderMouse(self))
    if with then
        local withDisabled = disabled or with:IsDisabled()
        if with.Type == "range" then
            RefreshRange(self, with, withDisabled)
        elseif with.Type == "color" then
            RefreshSwatch(self, with)       -- 职业色开关切换时色块随之更新
            self.Color:SetEnabled(not withDisabled)
        else
            self.Execute:SetEnabled(not withDisabled)
        end
    end
end

function OptionRowMixin:StartKeyCapture(slot)
    local cancel = self.Capturing == slot
    if self.Window then self.Window:EndKeyCaptures() end
    if cancel or InCombatLockdown() then self:Refresh(); return end
    self.Capturing = slot
    if self.Window then self.Window.CapturingRow = self end
    local button = slot == 1 and self.Key1 or self.Key2
    button:EnableKeyboard(true)
    button:EnableMouseWheel(true)
    self:Refresh()
end
function OptionRowMixin:EndKeyCapture()
    if not self.Capturing then return end
    self.Capturing = nil
    for _, button in ipairs({ self.Key1, self.Key2 }) do
        button:EnableKeyboard(false)
        button:EnableMouseWheel(false)
    end
    if self.Window and self.Window.CapturingRow == self then self.Window.CapturingRow = nil end
    if self.Option then self:Refresh() end
end
function OptionRowMixin:OnKeyCaptured(slot, key)
    -- 键名必须是字符串（type 判断而非索引比较，防御任何异常实参）
    if type(key) ~= "string" then return end
    if self.Capturing ~= slot or ignoredKeys[key] then return end
    self:EndKeyCapture()
    if InCombatLockdown() then return end
    local slotOption = self.Option and self.Option.Slots and self.Option.Slots[slot]
    if not slotOption then return end
    local combo = key == "ESCAPE" and "" or
        (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    slotOption:Set(combo)
    if self.Window then self.Window:OnOptionChanged(self.Option) end
end

function OptionRowMixin:OnEnter(control)
    self.Hover:Show()
    self.Reset:SetShown(self.Option and Changed(self))
    if not self.Window then return end
    -- 对齐暴雪原生选项的 tooltip：锚在悬停的行内控件本身（Forward 传入）。
    -- KAF :600-604：悬停 with 子控件时显示 with 自己的说明、锚在 with 控件上。
    local option, anchor = self.Option, control
    if self.With then
        option = self.With
        anchor = WithControl(self)
    end
    self.Window:OnRowEnter(option, self, anchor)
end
function OptionRowMixin:OnLeave()
    self.Hover:Hide()
    if not UnderMouse(self) then self.Reset:Hide() end
    if self.Window then self.Window:OnRowLeave(self.Option) end
end
