------------------------------------------------------------
-- 12.1 秘密值工具（共用層）
--
-- 通則（完整版在 .claude/notes/wow-121-secret-values.md）：
--   允許：存變數、傳參數、字串串接、format、對**非布林**做布林測試（x or y）、
--         type(v)、原封不動交給吃得下秘密值的 C API
--   禁止：算術、比較（== <）、#、當 table key、對它 index、
--         對**布林**秘密做布林測試、tostring
--
-- 一句話：當傳遞者，不當讀取者。
--
-- ⚠ 這支沒有任何相依（不讀 Env、不讀語系），排序在 TOC 最前面。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local _issecretvalue = _G.issecretvalue

ns.Secret = {}
local S = ns.Secret

------------------------------------------------------------
-- 判斷
------------------------------------------------------------
function S.IsSecret(v)
    return _issecretvalue and _issecretvalue(v) and true or false
end

------------------------------------------------------------
-- 洗值
------------------------------------------------------------
function S.SafeValue(v, default)
    if v == nil or S.IsSecret(v) then return default end
    return v
end

-- 秘密布林 → nil。布林秘密值連 v and true or false 都會炸，所以「不給知道」
-- 必須是第三種答案，讓呼叫端自己決定 fail-open 還是 fail-closed。
function S.ToBool(v)
    if v == nil or S.IsSecret(v) then return nil end
    return v and true or false
end

function S.PlainText(v)
    if type(v) ~= "string" then return end
    if S.IsSecret(v) then return end
    return v
end

function S.PlainNumber(v)
    if type(v) ~= "number" then return end
    if S.IsSecret(v) then return end
    return v
end

------------------------------------------------------------
-- 包呼叫
------------------------------------------------------------
function S.SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e, f, g, h, i, j = pcall(fn, ...)
    if ok then return a, b, c, d, e, f, g, h, i, j end
end

-- 呼叫 ＋「結果是不是明文 true」。秘密布林與失敗一律回 false。
function S.SafeBool(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok then return false end
    if S.IsSecret(value) then return false end
    return value == true
end

------------------------------------------------------------
-- forbidden object
------------------------------------------------------------
function S.IsForbiddenObject(obj)
    return (obj and obj.IsForbidden and obj:IsForbidden()) and true or false
end

------------------------------------------------------------
-- 顯示秘密值而不讀取它的官方管道
------------------------------------------------------------
local INTERP = Enum and Enum.StatusBarInterpolation
function S.BarInterp(smooth)
    if smooth and INTERP then return INTERP.ExponentialEaseOut end
    return nil
end

local _EvalBool = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
function S.BoolColor(secretBool, rT, gT, bT, rF, gF, bF)
    if not _EvalBool then return rF, gF, bF end
    return _EvalBool(secretBool, rT, rF), _EvalBool(secretBool, gT, gF), _EvalBool(secretBool, bT, bF)
end
