-- 主题色：可派生部分只有强调色系；固定黑白灰在 AF.C，永不参与派生。
-- 机制对齐 ADE 的 ApplyAccent 原地更新 + 广播（325:365:_docs/plans/ADE-v6-settings-sys-dev-plan.md）。
-- 2026-11-14 改为「按插件隔离」：每个插件经 GetFramework(major, silent, addonName) 取得独立主题门面，
--   拥有自己的 accent 派生表与着色登记表；框架控件/模板在创建时把该插件主题设为活动主题，
--   控件内部 AF.Color/AF.Tint/AF.RegisterTheme 自动落入该插件主题——A 插件的主题色不再泄漏给 B。
--   不传 addonName 时返回裸库（共享全局默认主题，向后兼容）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

-- 全局默认主题（裸库 / 未传 addonName 的插件走这里）
AF._defaultTheme = {
    name = "__default__",
    T = {
        accent      = { 0, 0, 0, 1 },
        accentHover = { 0, 0, 0, 1 },
        accentDim   = { 0, 0, 0,1 },
        divider     = { 0, 0, 0, 1 },
    },
    tinted = setmetatable({}, { __mode = "k" }),
    refs   = setmetatable({}, { __mode = "k" }),
    default = nil, -- 底部初始化为 AF.DEFAULT_ACCENT
}
-- 当前活动主题（由门面在创建控件/应用主题时短暂置位）
AF._activeTheme = nil

local function Put(t, r, g, b, a)
    t[1], t[2], t[3], t[4] = r, g, b, a
end

local function Derive(theme, r, g, b)
    Put(theme.T.accent, r, g, b, 1)
    Put(theme.T.accentHover, math.min(1, r * 1.15 + 0.05), math.min(1, g * 1.15 + 0.05), math.min(1, b * 1.15 + 0.05), 1)
    Put(theme.T.accentDim, r * 0.75, g * 0.75, b * 0.75, 1)
    Put(theme.T.divider, r, g, b, 0.777) -- 标题下 1px 线：1770:1770:…/Widgets.lua 用 W.Accent(0.777)
end

-- 取颜色：先查固定常量 AF.C，再查主题派生 theme.T。
function AF._color(key, alpha, theme)
    theme = theme or AF._activeTheme or AF._defaultTheme
    local c = AF.C[key] or theme.T[key] or theme.T.accent
    return c[1], c[2], c[3], alpha or c[4] or 1
end

-- 主题归属：沿 parent 链向上找第一个带 _afTheme 的帧；控件在哪创建、谁创建都能找到自己的主题。
function AF.ThemeOf(owner)
    while owner do
        if owner._afTheme then return owner._afTheme end
        if owner.GetParent then owner = owner:GetParent() else break end
    end
    return nil
end

-- 着色部位登记（弱键）：仅勾 / 滑块 / 下拉箭头 / 标题类 / hover 边框允许调用本函数。
-- 主题解析优先级：显式 theme > 活动主题 _activeTheme > 着色目标父链 ThemeOf > 默认主题。
function AF._tint(target, key, alpha, theme)
    theme = theme or AF._activeTheme or (target and target.GetParent and AF.ThemeOf(target:GetParent())) or AF._defaultTheme
    theme.tinted[target] = { key = key or "accent", alpha = alpha }
    local r, g, b, a = AF._color(key or "accent", alpha, theme)
    if target.SetVertexColor then
        target:SetVertexColor(r, g, b, a)
    elseif target.SetTextColor then
        target:SetTextColor(r, g, b, a)
    end
    return target
end

-- 原地更新色表（不换表）+ 重刷已登记的着色部位 + 广播。
function AF._applyAccent(color, theme)
    theme = theme or AF._activeTheme or AF._defaultTheme
    local c = color or theme.default or AF.DEFAULT_ACCENT
    local r = c.red or c.r or c[1]
    local g = c.green or c.g or c[2]
    local b = c.blue or c.b or c[3]
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return end
    Derive(theme, r, g, b)
    for target, state in pairs(theme.tinted) do
        local cr, cg, cb, ca = AF._color(state.key, state.alpha, theme)
        if target.SetVertexColor then
            target:SetVertexColor(cr, cg, cb, ca)
        elseif target.SetTextColor then
            target:SetTextColor(cr, cg, cb, ca)
        end
    end
    -- 主题回调（重绘边框等）在活动主题上下文里执行，使其内部 AF.Color 落在本主题。
    local prev = AF._activeTheme
    AF._activeTheme = theme
    for owner, fn in pairs(theme.refs) do
        local ok, err = pcall(fn)
        if not ok and geterrorhandler then geterrorhandler()(tostring(err)) end
    end
    AF._activeTheme = prev
    AF.FireCallback("ThemeChanged", { red = r, green = g, blue = b })
    return { red = r, green = g, blue = b }
end

---------------------------------------------------------------------------
-- 公共委托（全局默认主题）；门面会覆盖 Color/Tint/ApplyAccent/RegisterTheme 走本主题。
---------------------------------------------------------------------------
function AF.Color(key, alpha) return AF._color(key, alpha) end
function AF.ColorTable(key, alpha) local r, g, b, a = AF._color(key, alpha); return { r, g, b, a } end
function AF.Accent(alpha) return AF._color("accent", alpha) end
function AF.AccentHex()
    local r, g, b = AF._color("accent")
    return string.format("|cff%02X%02X%02X", AF.Round(r * 255), AF.Round(g * 255), AF.Round(b * 255))
end
function AF.Tint(target, key, alpha) return AF._tint(target, key, alpha) end
function AF.ApplyAccent(color) return AF._applyAccent(color) end
-- 主题回调：主题解析优先级：显式 theme > 活动主题 _activeTheme > owner 父链 ThemeOf > 默认主题；
-- 这样即便回调注册发生在非包裹作用域（如 TabbedFrame:AddPage 创建的页签按钮），也能落到正确插件主题。
function AF.RegisterTheme(owner, fn, theme)
    theme = theme or AF._activeTheme or AF.ThemeOf(owner) or AF._defaultTheme
    theme.refs[owner] = fn
end
function AF.OnTheme(key, fn) return AF.RegisterCallback("ThemeChanged", key, fn) end

-- 组件专用：按控件自身主题取色（控件在创建时由 Stylize 从 parent 链记了 _afTheme）。
-- 用法：skin:SetFill(AF.ThemeColorTable(self, "accent")) / AF.ThemeColor(self, "accent", 0.12)。
-- 注意参数顺序为 (owner, key, alpha)：所有调用点都把控件 self 作为首参传入。
function AF.ThemeColor(owner, key, alpha)
    return AF._color(key, alpha, (owner and owner._afTheme) or AF._activeTheme or AF._defaultTheme)
end
function AF.ThemeColorTable(owner, key, alpha)
    local r, g, b, a = AF.ThemeColor(owner, key, alpha)
    return { r, g, b, a }
end

-- 向后兼容：外部直接读 AF.T 取默认主题派生表。
AF.T = AF._defaultTheme.T

---------------------------------------------------------------------------
-- 按插件隔离的主题门面：GetFramework(major, silent, addonName) 调用。
---------------------------------------------------------------------------
function AF.MakeFacade(name)
    local d = AF.DEFAULT_ACCENT
    local T = {
        accent      = { d.red, d.green, d.blue, 1 },
        accentHover = { d.red, d.green, d.blue, 1 },
        accentDim   = { d.red * 0.75, d.green * 0.75, d.blue * 0.75, 1 },
        divider     = { d.red, d.green, d.blue, 0.777 },
    }
    local tinted = setmetatable({}, { __mode = "k" })
    local refs = setmetatable({}, { __mode = "k" })
    local theme = { name = name or "__anon__", T = T, tinted = tinted, refs = refs, default = AF.DEFAULT_ACCENT }

    -- 调用期间把全局活动主题置为本主题，使框架内部 AF.Color/AF.Tint/AF.RegisterTheme 落入本主题。
    local function withActive(fn, ...)
        local prev = AF._activeTheme
        AF._activeTheme = theme
        local r = { pcall(fn, ...) }
        AF._activeTheme = prev
        if not r[1] then error(r[2]) end
        return unpack(r, 2)
    end

    local pf = {}
    function pf.Color(key, alpha) return AF._color(key, alpha, theme) end
    function pf.ColorTable(key, alpha) local r, g, b, a = AF._color(key, alpha, theme); return { r, g, b, a } end
    function pf.Accent(alpha) return AF._color("accent", alpha, theme) end
    function pf.AccentHex()
        local r, g, b = AF._color("accent", nil, theme)
        return string.format("|cff%02X%02X%02X", AF.Round(r * 255), AF.Round(g * 255), AF.Round(b * 255))
    end
    function pf.Tint(target, key, alpha) return AF._tint(target, key, alpha, theme) end
    function pf.ApplyAccent(color) return AF._applyAccent(color, theme) end
    function pf.RegisterTheme(owner, fn) theme.refs[owner] = fn end
    function pf.OnTheme(key, fn) return AF.RegisterCallback("ThemeChanged", key, fn) end
    pf.T = T
    pf.name = name

    -- 包装 UI 构造入口：创建期间置活动主题（控件内部着色登记落本主题）。
    -- Widget/Template/Options 是子模块表，逐方法包；子表递归包（如 Widget.Button.Create）。
    -- Stylize/Fill/Edges/HoverBorder/Fixed 直接包调用。
    local function WrapTable(real)
        if type(real) ~= "table" then return real end
        local proxy = setmetatable({}, { __index = function(_, k2)
            local v = real[k2]
            if type(v) == "function" then
                return function(...) return withActive(v, ...) end
            elseif type(v) == "table" then
                return WrapTable(v)
            else
                return v
            end
        end })
        return proxy
    end
    pf.Widget = WrapTable(AF.Widget)
    pf.Template = WrapTable(AF.Template)
    pf.Options = WrapTable(AF.Options)
    pf.Form = WrapTable(AF.Form) -- 设置页控件全由 Form.Build 创建（Template/Form.lua 的顶层别名），漏包会导致控件落到全局默认主题
    for _, k in ipairs({ "Stylize", "Fill", "Edges", "HoverBorder", "Fixed" }) do
        local real = AF[k]
        pf[k] = function(...) return withActive(real, ...) end
    end

    -- 其余成员（C / L / LAYOUT / DB / Callbacks / Pixel / NoSnap / Round / DEFAULT_ACCENT …）委托裸库。
    setmetatable(pf, { __index = function(_, k)
        if k == "Widget" or k == "Template" or k == "Options"
            or k == "Stylize" or k == "Fill" or k == "Edges" or k == "HoverBorder" or k == "Fixed" then
            return rawget(pf, k)
        end
        return AF[k]
    end })
    return pf
end

AF._defaultTheme.default = AF.DEFAULT_ACCENT
AF.ApplyAccent(AF.DEFAULT_ACCENT)
