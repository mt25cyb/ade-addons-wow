-- 基础工具：1px 换算、尺寸、量化、文字量测。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

--- n 个物理像素在 frame 坐标系里是多少 UI 单位。
-- 公式逐字对齐 32:38:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/PixelPerfect.lua
--（PixelUtil.GetPixelToUIUnitFactor() / 框自己的有效缩放）。旧实现 1/scale 在高分辨率下
-- 会把 1px 边画粗（2026-11-13 用户反馈「线过粗」的根因之一）。
-- 兼容两种调用：AF.Pixel(frame)（旧签名，n 视为 1）与 AF.Pixel(n, frame)。
function AF.Pixel(n, frame)
    if type(n) == "table" then frame, n = n, 1 end
    n = math.floor((tonumber(n) or 1) + 0.5)
    if n <= 0 then return 0 end
    local factor = PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor() or 1
    local scale = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale())
        or (UIParent and UIParent:GetEffectiveScale()) or 1
    if not scale or scale <= 0 then scale = 1 end
    return n * factor / scale
end

--- 关掉引擎像素贴齐，回传原物件。贴齐开着时，小数座标上的 1px 边会整条变 0px，
-- 或与相邻贴图舍入方向不同时变 2px（「线过粗」的另一根因）。
-- 逐字对齐 47:57:…/PixelPerfect.lua 的 P.NoSnap。
function AF.NoSnap(obj)
    if type(obj) ~= "table" then return obj end
    local t = obj
    if not t.SetSnapToPixelGrid and t.GetStatusBarTexture then t = t:GetStatusBarTexture() end
    if type(t) == "table" and t.SetSnapToPixelGrid then
        pcall(function()
            t:SetSnapToPixelGrid(false)
            t:SetTexelSnappingBias(0)
        end)
    end
    return obj
end

function AF.Size(frame, w, h)
    frame:SetSize(w, h)
end

function AF.Clamp(v, low, high)
    if v < low then return low end
    if v > high then return high end
    return v
end

function AF.Round(v)
    return math.floor(v + 0.5)
end

function AF.Quantize(v, low, high, step)
    step = step or 1
    v = math.floor((v - low) / step + 0.5) * step + low
    return tonumber(string.format("%.2f", AF.Clamp(v, low, high)))
end

--- 一段文字换行之后多出来的高度（没换行回 0），呼叫端拿它垫列高。
-- 底本 92:101:…/Widgets.lua 的 W.TextExtraHeight
function AF.TextExtraHeight(fs, text)
    fs:SetText("A")
    local lineH = fs:GetStringHeight()
    fs:SetText(text or "")
    local total = fs:GetStringHeight()
    if lineH > 0 and total > lineH * 1.5 then
        return math.ceil(total - lineH)
    end
    return 0
end

--- 量一段定宽文字的高度（用调用方自己的 FontString，避免共享量尺状态污染）。
function AF.MeasureTextHeight(fs, text, width)
    local oldW = fs:GetWidth()
    fs:SetWidth(width)
    fs:SetText(text or "")
    local h = fs:GetStringHeight() or 0
    fs:SetWidth(oldW)
    return h
end

function AF.SetFontSize(fs, size)
    local file, _, flags = fs:GetFont()
    fs:SetFont(file or STANDARD_TEXT_FONT, size, flags or "")
end
