------------------------------------------------------------
-- 像素 / 縮放工具
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

ns.P = {}
local P = ns.P

-- n 個實體像素 → UI 單位（照 Frame 有效縮放換算；讀不到退 1）
function P.Pixel(n)
    n = math.floor((tonumber(n) or 0) + 0.5)
    if n <= 0 then return 0 end
    local f = PixelUtil and PixelUtil.GetPixelToUIUnitFactor or (function() return 1 / 768 end)
    return n * (type(f) == "function" and f() or 1)
end

-- 設定縮放（C1 先走 1，後續接 general.scale）
function P.Scale(n)
    return n
end
