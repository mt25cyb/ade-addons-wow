-- 表单构建：每行 label + 控件 + 可选逐项重置按钮（§六.1）。
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

function F.Build(parent, spec, ctx)
    ctx = ctx or {}
    local width = ctx.width or AF.LAYOUT.contentW
    local labelW = ctx.labelW or AF.LAYOUT.labelW
    local y = 0
    local rows = {}

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
                y = y + rowH + 4
            end
        end
        if row then rows[#rows + 1] = row end
    end

    parent:SetHeight(y + 10)
    local obj = { rows = rows, height = y + 10 }
    function obj:Refresh()
        for _, row in ipairs(rows) do if row.Refresh then row:Refresh() end end
    end
    return obj
end
