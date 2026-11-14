-- 表单构建：每行 label + 控件 + 可选逐项重置按钮（§六.1）。
-- b010 新增（adeTooltip 开发计划 §十）：
--   spec.enabled = boolean | function() → 禁用态（灰化 + 鼠标遮挡拦截 + Refresh 重算），
--     如 adeTooltip「不使用新版排版时，仅新版生效的选项置灰」；
--   ScrollToRow(scroll, key) / HighlightRow(key) → 预览区点击元素后定位到对应设置行。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Form = AF.Form or {}
local F = {}
AF.Template.Form = F        -- 组合模板：配置页
AF.Form = F                 -- 别名兼容

local function Get(ctx, key, default)
    if not key or not ctx.get then return default end
    local v = ctx.get(key)
    if v == nil then return default end
    return v
end

local function Set(ctx, key, value)
    if key and ctx.set then ctx.set(key, value) end
end

-- 禁用态实现：灰色标签 + 控件半透明 + 一张鼠标遮挡层。
-- 遮挡层而不是逐控件 EnableMouse(false)：Frame:EnableMouse 不影响子帧，
-- 下拉/滑块等控件的交互在子帧上，统一遮挡最稳；键盘输入用 ClearFocus 收尾。
local function ApplyEnabled(meta)
    local entry, row, control = meta.entry, meta.row, meta.control
    local en = entry.enabled
    if type(en) == "function" then en = en() and true or false end
    if en == nil then en = true end
    if control then
        control:SetAlpha(en and 1 or 0.45)
        if not en then
            if control.ClearFocus then control:ClearFocus() end
            if control.editBox and control.editBox.ClearFocus then control.editBox:ClearFocus() end
        end
    end
    if not en then
        if not meta.blocker then
            local blocker = CreateFrame("Frame", nil, row)
            blocker:SetAllPoints()
            blocker:EnableMouse(true)
            blocker:SetFrameLevel(row:GetFrameLevel() + 50)
            meta.blocker = blocker
        end
        meta.blocker:Show()
        row.label:SetTextColor(0.42, 0.42, 0.42)
    else
        if meta.blocker then meta.blocker:Hide() end
        -- 启用时标签色交还 Row.Refresh（reset="changed" 的偏离默认变色逻辑）
        if not row.Refresh then row.label:SetTextColor(unpack(AF.C.TEXT_MAIN)) end
    end
end

function F.Build(parent, spec, ctx)
    ctx = ctx or {}
    local width = ctx.width or AF.LAYOUT.contentW
    local labelW = ctx.labelW or AF.LAYOUT.labelW
    local y = 0
    local rows = {}
    local rowByKey, rowY, enabledRows = {}, {}, {}

    for _, entry in ipairs(spec or {}) do
        local kind = entry.type or "text"
        local rowH = entry.height or 26
        local row
        if kind == "header" then
            row = AF.Widget.Text.SectionTitle(parent, entry.label or "", width)
            row:SetPoint("TOPLEFT", 0, -y)
            y = y + 28
        elseif kind == "space" then
            y = y + (entry.height or 8)
        elseif kind == "text" then
            local fs = AF.Widget.Text.Desc(parent, entry.label or "", width)
            fs:SetPoint("TOPLEFT", 0, -y)
            y = y + 22
        else
            local control, resetValue, get, default
            if kind == "toggle" then
                default = entry.default
                get = function() return Get(ctx, entry.key, default) end
                control = AF.Widget.Checkbox.Create(parent, {
                    checked = get(), onChange = function(v) Set(ctx, entry.key, v) end,
                })
                resetValue = function() control:SetChecked(default); Set(ctx, entry.key, default) end
            elseif kind == "slider" then
                default = entry.default or entry.min or 0
                get = function() return Get(ctx, entry.key, default) end
                control = AF.Widget.Slider.Create(parent, {
                    width = entry.width or 240, min = entry.min or 0, max = entry.max or 100,
                    step = entry.step or 1, suffix = entry.suffix or "editbox", value = get(),
                    onChange = function(v) Set(ctx, entry.key, v) end,
                })
                resetValue = function() control:SetValue(default); Set(ctx, entry.key, default) end
            elseif kind == "dropdown" then
                default = entry.default
                get = function() return Get(ctx, entry.key, default) end
                control = AF.Widget.Dropdown.Create(parent, {
                    width = entry.width or 180, items = entry.items or {}, value = get(),
                    onSelect = function(v) Set(ctx, entry.key, v) end,
                })
                resetValue = function() control:SetValue(default); Set(ctx, entry.key, default) end
            elseif kind == "input" then
                default = entry.default or ""
                get = function() return Get(ctx, entry.key, default) end
                if entry.multiline then
                    -- 走 onTextChanged 回调把业务逻辑挂进 CreateMulti 内部处理器：
                    -- 直接 SetScript("OnTextChanged", …) 会覆盖内部撑高 ScrollChild 的 Resize，
                    -- 导致内容变高后滚动范围恒 0、滚动条滑块不激活（2026-11-14 用户反馈根因）。
                    control = AF.Widget.Editbox.CreateMulti(parent, entry.width or 300, entry.height or 70, {
                        onTextChanged = function(self, user)
                            if user then Set(ctx, entry.key, self:GetText()) end
                        end,
                    })
                    control.editBox:SetText(get())
                    resetValue = function() control.editBox:SetText(default); Set(ctx, entry.key, default) end
                else
                    control = AF.Widget.Editbox.CreateSingle(parent, entry.width or 200, 20)
                    control:SetText(get())
                    control:SetScript("OnTextChanged", function(self, user)
                        if user then Set(ctx, entry.key, self:GetText()) end
                    end)
                    resetValue = function() control:SetText(default); Set(ctx, entry.key, default) end
                end
            elseif kind == "color" then
                default = entry.default or { red = 1, green = 1, blue = 1 }
                get = function() return Get(ctx, entry.key, default) end
                control = AF.Widget.Color.Create(parent, {
                    color = get(), onChange = function(r, g, b)
                        Set(ctx, entry.key, { red = r, green = g, blue = b })
                    end,
                })
                resetValue = function() control:SetColor(default); Set(ctx, entry.key, default) end
            elseif kind == "custom" and entry.build then
                control = entry.build(parent)
            end
            if control then
                row = AF.Widget.Row.Create(parent, {
                    width = width, labelW = labelW, height = rowH, label = entry.label or "",
                    control = control, reset = entry.reset, default = default, get = get,
                    resetValue = resetValue,
                    onChange = function() if entry.onChange then entry.onChange() end end,
                })
                row:SetPoint("TOPLEFT", 0, -y)
                if entry.key then
                    rowByKey[entry.key] = row
                    rowY[entry.key] = y
                end
                if entry.enabled ~= nil then
                    enabledRows[#enabledRows + 1] = { row = row, control = control, entry = entry }
                end
                y = y + rowH + 4
            end
        end
        if row then rows[#rows + 1] = row end
    end

    parent:SetHeight(y + 10)
    local obj = { rows = rows, height = y + 10, rowByKey = rowByKey }
    function obj:Refresh()
        for _, row in ipairs(rows) do if row.Refresh then row:Refresh() end end
        for _, meta in ipairs(enabledRows) do ApplyEnabled(meta) end
    end

    --- 滚动到指定 key 的设置行（scroll = AF.Widget.Scroll 容器，有 :ScrollTo）。
    function obj:ScrollToRow(scroll, key)
        local top = rowY[key]
        if not top or not scroll then return false end
        if scroll.ScrollTo then scroll:ScrollTo(math.max(top - 8, 0)) end
        return true
    end

    --- 高亮指定 key 的设置行（主题色底纹，默认 1.5 秒后自动消退；重复调用重置计时）。
    function obj:HighlightRow(key, duration)
        local row = rowByKey[key]
        if not row then return false end
        if not row._afHighlight then
            local hl = AF.Fill(row, AF.ThemeColorTable(row, "accent"), "BACKGROUND", 0)
            hl:SetAllPoints()
            hl:SetAlpha(0.12)
            row._afHighlight = hl
        end
        local hl = row._afHighlight
        row._afHlToken = (row._afHlToken or 0) + 1
        local token = row._afHlToken
        hl:Show()
        C_Timer.After(duration or 1.5, function()
            if row._afHlToken == token then hl:Hide() end
        end)
        return true
    end

    obj:Refresh()
    return obj
end
