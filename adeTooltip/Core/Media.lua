------------------------------------------------------------
-- 貼圖 / 字型 / 狀態條材質（最小實作，滿足 Classic 單位路線）
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

ns.Media = {}
local Media = ns.Media

Media.WHITE8X8 = "Interface\\Buttons\\WHITE8X8"

-- 不貼齊像素格：避免縮放時條身/邊框露半格縫
function Media.NoSnap(tex)
    if tex and tex.SetSnapToPixelGrid then
        pcall(tex.SetSnapToPixelGrid, tex, false)
    end
    return tex
end

-- 字型：預設用系統字（ADE 設定可換，C1 先走預設）
function Media.Font(key)
    if key == "default" then return STANDARD_TEXT_FONT end
    return key or STANDARD_TEXT_FONT
end

-- 背景材質
function Media.Background(file)
    return file or "Interface\\Tooltips\\UI-Tooltip-Background"
end

-- 狀態條材質
function Media.BarTexture(file)
    return file or "Interface\\TargetingFrame\\UI-StatusBar"
end
