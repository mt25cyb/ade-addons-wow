------------------------------------------------------------
-- 12.1 秘密值工具（ADE 移植自 MiliUI Libs/MiliUIWidgets/Secret.lua）。
-- 通则：允许存变量、传参、字符串拼接、format、对非布尔做布尔测试（x or y）、
--       type(v)、原封不动交给吃得下秘密值的 C API；
--       禁止：算术、比较（== <）、#、当 table key、对它 index、对布尔秘密做布尔测试、tostring。
-- 一句话：当传递者，不当读取者。
-- 依赖：无（不读 Env、不读语系），排在 TOC 最前。
------------------------------------------------------------
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT

local _issecretvalue = _G.issecretvalue

ADT.Secret = {}
local S = ADT.Secret

function S.IsSecret(v)
    return _issecretvalue and _issecretvalue(v) and true or false
end

-- 秘密或 nil → default。要比较、当 table key、做算术之前一律先过这里。
function S.SafeValue(v, default)
    if v == nil or S.IsSecret(v) then return default end
    return v
end

-- 秘密布尔 → nil。布林秘密值连 `v and true or false` 都会炸，所以「不给知道」必须是第三种答案。
function S.ToBool(v)
    if v == nil or S.IsSecret(v) then return nil end
    return v and true or false
end

-- 明文字串才回传。秘密字串不能 gsub/find/sub/#，跑字串运算前先过这里。
function S.PlainText(v)
    if type(v) ~= "string" then return end
    if S.IsSecret(v) then return end
    return v
end

-- 明文数字才回传。
function S.PlainNumber(v)
    if type(v) ~= "number" then return end
    if S.IsSecret(v) then return end
    return v
end

-- pcall 包，最多回十个值；失败回 nil。吃掉 ok 旗标（跟裸 pcall 不同）。
function S.SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e, f, g, h, i, j = pcall(fn, ...)
    if ok then return a, b, c, d, e, f, g, h, i, j end
end

-- 呼叫 + 「结果是不是明文 true」。秘密布林与失败一律回 false。
function S.SafeBool(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok then return false end
    if S.IsSecret(value) then return false end
    return value == true
end

-- 12.1 之后某些暴雪物件（tooltip 最常见）会被系统借走、动态变成 forbidden，
-- 对它呼叫任何方法（连 NumLines()）都会抛错。这是动态状态，每个入口都要重问。
function S.IsForbiddenObject(obj)
    return (obj and obj.IsForbidden and obj:IsForbidden()) and true or false
end

-- StatusBar 的原生内插：SetValue(value, interpolation) 是 C 端做的，吃秘密值。
-- 绝不用 SmoothStatusBarMixin —— 那是 Lua，会对秘密值做 Clamp 算术。
local INTERP = Enum and Enum.StatusBarInterpolation
function S.BarInterp(smooth)
    if smooth and INTERP then return INTERP.ExponentialEaseOut end
    return nil
end

-- 秘密布林选色：回传可直接餵 SetVertexColor 的三个值（可能是秘密）。
local _EvalBool = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
function S.BoolColor(secretBool, rT, gT, bT, rF, gF, bF)
    if not _EvalBool then return rF, gF, bF end
    return _EvalBool(secretBool, rT, rF), _EvalBool(secretBool, gT, gF), _EvalBool(secretBool, bT, bF)
end
