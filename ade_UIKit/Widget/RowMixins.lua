------------------------------------------------------------
-- 行行为。逐块复刻 KAF Libs/Krowi_Options/RowMixins.lua。
-- 含宿主扁平 spec → KAF option 接口的适配（MakeOption）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L, Internal = lib.L, lib.Internal
local mixins = Internal.Mixins
local geometry = Internal.Geometry

local function Protected(func, ...)
    if type(func) ~= "function" then return false end
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end
local function Ask(fallback, func, ...)
    if type(func) ~= "function" then return fallback end
    local ok, result = Protected(func, ...)
    if ok then return result end
    return fallback
end
Internal.Ask = Ask

-- KAF RowMixins.lua:155、:585：键位捕获的键与鼠标键表。必须在 OnLoad 的脚本闭包之前定义（Lua 的 local 作用域），
-- 否则闭包里引用到的是全局，点击键位按钮时崩 "attempt to index global 'mouseButtons'"。
local mouseButtons = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
local ignoredKeys = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, UNKNOWN = true }

-- [[ 宿主 spec → KAF option 接口 ]] --
function Internal.MakeOption(spec)
    -- KAF RowMixins.lua:21：Type 是控件类型；宿主的 key 是存档键，不能当类型用。
    local kind = spec.type or spec.kind or "toggle"
    local known = { toggle = true, range = true, select = true, execute = true, input = true, key = true }
    if not known[kind] then kind = "toggle" end
    local option = { Type = kind, Spec = spec,
        Indent = spec.indent, Placeholder = spec.placeholder }
    function option:GetLabel() return tostring(spec.label or spec.text or "") end
    function option:GetDescription() return spec.desc end
    function option:IsHidden() return spec.hidden == true end
    function option:IsDisabled() return spec.disabled == true end
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
    function option:GetValues()
        local values = {}
        for i, item in ipairs(spec.items or {}) do
            if type(item) == "table" then
                values[i] = { value = item.value ~= nil and item.value or item[1], text = tostring(item.text or item[2] or item[1]) }
            else
                values[i] = { value = item, text = tostring(item) }
            end
        end
        return values
    end
    if option.Type == "key" then
        -- KAF RowMixins.lua:25：Slots 可有两个键位；宿主 slots 数组给各自的 get/set，缺省回落到本 option。
        local slots = (type(spec.slots) == "table" and #spec.slots > 0) and spec.slots or { spec }
        option.Slots = {}
        -- 单项恢复默认（Reset）必须清全部键位槽：只走 option:Set 只会写主槽，双键位的第二槽残留脏值。
        local baseReset = option.Reset
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

-- [[ Where a row's name and controls stand ]] --  KAF RowMixins.lua:60-98
local controlColumn = geometry.ControlColumn
local selectIn, inputIn = 18.5, 6
local placement = {
    Toggle = { "RIGHT", -controlColumn }, Range = { "RIGHT", -controlColumn },
    Select = { "RIGHT", -controlColumn + selectIn }, Execute = { "RIGHT", -controlColumn },
    Input = { "RIGHT", -controlColumn + inputIn }, Key = { "RIGHT", -controlColumn },
    Sub = { "RIGHT", -controlColumn }, TabArrows = { "RIGHT", -controlColumn },
    NameRight = { "RIGHT", -controlColumn - 12 }, NameLeft = 16, Indent = 20,
}
local geometries = {}
function Internal.RowGeometry(indent)
    indent = indent or 0
    local g = geometries[indent]
    if not g then
        g = { NameLeft = { "LEFT", placement.NameLeft + indent * placement.Indent } }
        for key, spec in next, placement do
            if type(spec) == "table" then g[key] = spec end
        end
        geometries[indent] = g
    end
    return g
end
local relativeX = { LEFT = 0, CENTER = 0.5, RIGHT = 1 }
function Internal.RowX(spec, width) return relativeX[spec[1]] * width + spec[2] end
local function Place(region, row, spec)
    region:ClearAllPoints()
    region:SetPoint("LEFT", row, spec[1], spec[2], 0)
end
local placedControls = { Toggle = "Toggle", Range = "Range", Select = "Select", Execute = "Execute", Input = "Input", Key = "Key1" }

-- [[ A key button ]] --  KAF :109-127
mixins.KeyButton = mixins.KeyButton or {}
local KeyButtonMixin = mixins.KeyButton
local keyButtonPieces = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft", "MiddleRight", "BottomMiddle", "MiddleMiddle" }
function KeyButtonMixin:SetPieces(file)
    for _, piece in ipairs(keyButtonPieces) do self[piece]:SetTexture(file) end
end
function KeyButtonMixin:OnMouseDown()
    if self:IsEnabled() then self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Down") end
end
function KeyButtonMixin:Lift() self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Up") end

-- [[ Text row ]] --  KAF :130-135
mixins.TextRow = mixins.TextRow or {}
function mixins.TextRow:Init(element) self.Text:SetText(element.Text or "") end

-- [[ An option ]] --  KAF :138-617
mixins.OptionRow = mixins.OptionRow or {}
local OptionRowMixin = mixins.OptionRow

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
            dropdown:SetupMenu(function(_, root)
                local choices = row.Choices
                for i = 1, choices.Count or 0 do
                    local value = choices[2 * i - 1]
                    root:CreateRadio(choices[2 * i], function() return row.SelectShown == value end, function()
                        option:Set(value)
                        window:OnOptionChanged(option)
                    end)
                end
            end)
            if dropdown.SetDefaultText then dropdown:SetDefaultText(option.Placeholder or "") end
            row.Select:Show()
        end,
        Refresh = function(row, option, disabled)
            local values = option:GetValues()
            local shown = SelectShown(row, option, values)
            row.Choices = row.Choices or {}
            if not SameChoices(row.Choices, values) then
                KeepChoices(row.Choices, values)
                row.SelectShown = shown
                if row.Select.Dropdown.GenerateMenu then row.Select.Dropdown:GenerateMenu() end
            elseif shown ~= row.SelectShown then
                row.SelectShown = shown
                if row.Select.Dropdown.Update then row.Select.Dropdown:Update() end
            end
            row.Select:SetEnabled(not disabled)
        end,
    },
    execute = {
        Place = "Execute",
        Init = function(row, option) row.Execute:SetText(option:GetButtonText()); row.Execute:Show() end,
        Refresh = function(row, _, disabled) row.Execute:SetEnabled(not disabled) end,
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
    return row.With and row.With.Type == "range" and row.Range or row.Execute
end

function OptionRowMixin:OnLoad()
    if not self._forwarded then
        self._forwarded = true
        for _, control in ipairs({ self.Reset, self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Key1, self.Key2 }) do
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
            option:Set(true)
            if self.Window then self.Window:OnOptionChanged(option) end
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
    for _, control in ipairs({ self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Key1, self.Key2 }) do
        control:Hide()
    end
    self.InputKept, self.InputStart, self.Repaired = false, false, false
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

-- [[ Sub / grid / tab / search / link / card ]] --  KAF :619-928 的最小行为复刻
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
            col = Internal.Build.Text(self, "ARTWORK", "GameFontNormalSmall", "LEFT", "BOTTOM")
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
        local cell = Internal.Build.CheckButton(self)
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

-- KAF RowMixins.lua:718-775：页签的位置、显隐复选框与上下移箭头。
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

mixins.SearchHeadingRow = mixins.SearchHeadingRow or {}
function mixins.SearchHeadingRow:Init(element) self.Title:SetText(element.Text or "") end
function mixins.SearchHeadingRow:OnClick() if self.Element and self.Element.OnClick then self.Element.OnClick() end end
function mixins.SearchHeadingRow:OnEnter() self.MouseoverOverlay:Show() end
function mixins.SearchHeadingRow:OnLeave() self.MouseoverOverlay:Hide() end

mixins.LinkRow = mixins.LinkRow or {}
function mixins.LinkRow:Init(element)
    self.Element = element
    self.Text:SetText(element.Text or "")
    self.Detail:SetText(element.Detail or "")
end
function mixins.LinkRow:OnClick() if self.Element and self.Element.OnClick then self.Element.OnClick() end end

-- KAF RowMixins.lua:818-928：三卡一行，图片区 86px，名称/说明与「新」标签，边框随悬停变亮。
Internal.CardColumns = 3
local cardGap, cardBorder = 12, 1
local cardTextInset, nameTop, lineGap, cardBottom, newGap = 10, 8, 3, 10, 6
local borderHoverColor = { 1, 0.82, 0, 0.6 }
function Internal.CardWidth(rowWidth)
    return (rowWidth - (Internal.CardColumns - 1) * cardGap) / Internal.CardColumns
end
function Internal.CardCrop(picture, cardWidth)
    local pictureHeight = geometry.CardPictureHeight
    local width = cardWidth - 2 * cardBorder
    if not picture.Width or not picture.Height or picture.Width <= 0 or picture.Height <= 0 then return 0, 1, 0, 1 end
    local scale = math.max(width / picture.Width, pictureHeight / picture.Height)
    local coords, part = picture.TexCoords or { 0, 1, 0, 1 }, picture.Part or {}
    local shownWidth = width / scale / picture.Width
    local shownHeight = pictureHeight / scale / picture.Height
    local left = (1 - shownWidth) * (part.X or 0)
    local top = (1 - shownHeight) * (part.Y or 0)
    local u, v = coords[2] - coords[1], coords[4] - coords[3]
    return coords[1] + u * left, coords[1] + u * (left + shownWidth),
        coords[3] + v * top, coords[3] + v * (top + shownHeight)
end
function Internal.CardRowHeight(window, element)
    local lineWidth = Internal.CardWidth(window:PageWidth()) - 2 * cardTextInset
    local nameHeight, lineHeight = 0, 0
    for _, card in ipairs(element.Cards or {}) do
        nameHeight = math.max(nameHeight, window:MeasureText(card.Name, "GameFontNormal", 1000))
        if card.Text and card.Text ~= "" then
            lineHeight = math.max(lineHeight, window:MeasureText(card.Text, "GameFontDisableSmall", lineWidth))
        end
    end
    return 2 * cardBorder + geometry.CardPictureHeight + nameTop + nameHeight
        + (lineHeight > 0 and lineGap + lineHeight or 0) + cardBottom + cardGap
end
mixins.CardRow = mixins.CardRow or {}
function mixins.CardRow:OnLoad()
    self.Cards = {}
    for i = 1, Internal.CardColumns do self.Cards[i] = Internal.Build.Card(self) end
end
function mixins.CardRow:Init(element, window)
    self.Element = element
    local width = Internal.CardWidth(window:PageWidth())
    for i, frame in ipairs(self.Cards) do
        local card, x = element.Cards[i], (i - 1) * (width + cardGap)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", x, 0)
        frame:SetPoint("BOTTOMLEFT", x, cardGap)
        frame:SetWidth(width)
        frame:SetShown(card ~= nil)
        if card then frame:Init(card, width) end
    end
end
mixins.Card = mixins.Card or {}
function mixins.Card:Init(card, width)
    self.Card = card
    self.Picture:SetShown(card.Picture ~= nil)
    self.Icon:SetShown(card.Picture == nil and card.Icon ~= nil)
    if card.Picture then
        self.Picture:SetTexture(card.Picture)
        self.Picture:SetTexCoord(Internal.CardCrop(card, width))
    elseif card.Icon then
        self.Icon:SetTexture(card.Icon)
    end
    local newWidth = 0
    local feature = self.NewFeature
    if feature then
        if feature.BGLabel then feature.BGLabel:SetPoint("RIGHT", 0.5, -0.5) end
        if feature.Label then feature.Label:SetPoint("RIGHT", 0, 0) end
        if card.IsNew then
            newWidth = feature.Label and (feature.Label:GetStringWidth() * feature:GetScale() + newGap) or 0
        end
        feature:SetShown(card.IsNew and true or false)
    end
    self.Name:ClearAllPoints()
    self.Name:SetPoint("TOPLEFT", self.PictureArea, "BOTTOMLEFT", cardTextInset - cardBorder, -nameTop)
    self.Name:SetPoint("TOPRIGHT", self.PictureArea, "BOTTOMRIGHT", -(cardTextInset - cardBorder) - newWidth, -nameTop)
    self.Name:SetText(card.Name or "")
    self.Line:SetWidth(width - 2 * cardTextInset)
    self.Line:SetText(card.Text or "")
    self:SetHovered(self:IsMouseOver())
end
function mixins.Card:SetHovered(hovered)
    self.Hover:SetShown(hovered)
    local color = hovered and borderHoverColor or geometry.CardBorderColor
    for _, edge in ipairs(self.Edges or {}) do edge:SetColorTexture(unpack(color)) end
end
function mixins.Card:OnEnter() self:SetHovered(true) end
function mixins.Card:OnLeave() self:SetHovered(false) end
function mixins.Card:OnClick() if self.Card and self.Card.OnClick then self.Card.OnClick() end end
