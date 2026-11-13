-- 主题色：可派生部分只有强调色系；固定黑白灰在 AF.C，永不参与派生。
-- 机制对齐 ADE 的 ApplyAccent 原地更新 + 广播（325:365:_docs/plans/ADE-v6-settings-sys-dev-plan.md）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

AF.T = {
    accent      = { 0, 0, 0, 1 },
    accentHover = { 0, 0, 0, 1 },
    accentDim   = { 0, 0, 0, 1 },
    divider     = { 0, 0, 0, 1 },
}

local function Put(t, r, g, b, a)
    t[1], t[2], t[3], t[4] = r, g, b, a
end

local function Derive(r, g, b)
    Put(AF.T.accent, r, g, b, 1)
    Put(AF.T.accentHover, math.min(1, r * 1.15 + 0.05), math.min(1, g * 1.15 + 0.05), math.min(1, b * 1.15 + 0.05), 1)
    Put(AF.T.accentDim, r * 0.75, g * 0.75, b * 0.75, 1)
    Put(AF.T.divider, r, g, b, 0.777) -- 标题下 1px 线：1770:1770:…/Widgets.lua 用 W.Accent(0.777)
end

--- 取颜色：先查固定常量 AF.C，再查主题派生 AF.T。
function AF.Color(key, alpha)
    local c = AF.C[key] or AF.T[key] or AF.T.accent
    return c[1], c[2], c[3], alpha or c[4] or 1
end

--- 返回表形式，供 skin:SetBorder / SetFill 使用。
function AF.ColorTable(key, alpha)
    local r, g, b, a = AF.Color(key, alpha)
    return { r, g, b, a }
end

function AF.Accent(alpha)
    return AF.Color("accent", alpha)
end

--- 关于页标题用的 |cffRRGGBB（由主题色生成，禁止硬编码颜色转义）。
function AF.AccentHex()
    local r, g, b = AF.Color("accent")
    return string.format("|cff%02X%02X%02X", AF.Round(r * 255), AF.Round(g * 255), AF.Round(b * 255))
end

--- 原地更新色表（不换表）+ 重刷已登记的着色部位 + 广播。
function AF.ApplyAccent(color)
    local c = color or AF.DEFAULT_ACCENT
    local r = c.red or c.r or c[1]
    local g = c.green or c.g or c[2]
    local b = c.blue or c.b or c[3]
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return end
    Derive(r, g, b)
    for target, state in pairs(AF.__tinted) do
        local cr, cg, cb, ca = AF.Color(state.key, state.alpha)
        if target.SetVertexColor then
            target:SetVertexColor(cr, cg, cb, ca)
        elseif target.SetTextColor then
            target:SetTextColor(cr, cg, cb, ca)
        end
    end
    for _, fn in pairs(AF.__themeRefs) do
        local ok, err = pcall(fn)
        if not ok and geterrorhandler then geterrorhandler()(tostring(err)) end
    end
    AF.FireCallback("ThemeChanged", { red = r, green = g, blue = b })
    return { red = r, green = g, blue = b }
end

function AF.OnTheme(key, fn)
    return AF.RegisterCallback("ThemeChanged", key, fn)
end

-- 控件自刷新登记（弱键：控件被回收时自动清理，不会像回调注册表那样常驻）
AF.__themeRefs = setmetatable({}, { __mode = "k" })
function AF.RegisterTheme(owner, fn)
    AF.__themeRefs[owner] = fn
end

AF.ApplyAccent(AF.DEFAULT_ACCENT)
