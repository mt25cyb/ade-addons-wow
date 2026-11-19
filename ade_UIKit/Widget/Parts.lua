------------------------------------------------------------
-- 控件公共积木（b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowParts.lua 更名）：
-- 帧积木（Text/Color/Finish/Row/Hover/CheckButton）、行几何（RowGeometry/RowX）、
-- 宿主调用保护（Protected/Ask）、按钮文字适配（FitButton）。各控件文件共享本文件。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry

-- 按钮文字自适应宽度（页脚按钮同用；b029 自 WindowTabs.lua 收编，原 WindowMixin.lua:241-243）
function Internal.FitButton(button)
    button:SetWidth(math.max(96, (button:GetFontString() and button:GetFontString():GetStringWidth() or 0) + 24))
end

-- [[ 调用保护 ]] --  原 RowMixins.lua:12-23（升为 Internal 单一来源，Window 族共用）
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
Internal.Protected, Internal.Ask = Protected, Ask

-- [[ Pieces ]] --  KAF RowFrames.lua:27-69
local function Text(frame, layer, font, justifyH, justifyV)
    local text = frame:CreateFontString(nil, layer, font)
    if justifyH then text:SetJustifyH(justifyH) end
    if justifyV then text:SetJustifyV(justifyV) end
    return text
end
build.Text = Text

local function Color(frame, layer, r, g, b, a, subLevel)
    local texture = frame:CreateTexture(nil, layer, nil, subLevel)
    texture:SetColorTexture(r, g, b, a)
    return texture
end
build.Color = Color

local function Finish(frame, mixin, scripts)
    if mixin then Mixin(frame, mixin) end
    for script, method in next, scripts or {} do
        if script ~= "OnLoad" then
            local fn = frame[method]
            if not fn then return end
            frame:SetScript(script, fn)
        end
    end
    if scripts and scripts.OnLoad and frame[scripts.OnLoad] then frame[scripts.OnLoad](frame) end
    return frame
end
build.Finish = Finish

local function Row(frameType, parent)
    local row = CreateFrame(frameType, nil, parent)
    row:Hide()
    return row
end
build.Row = Row

-- 悬停高亮层（行/卡片共用）  KAF RowFrames.lua:183-188
local function Hover(row, layer, subLevel)
    local hover = Color(row, layer or "BACKGROUND", 1, 1, 1, 0.05, subLevel)
    hover:SetAllPoints()
    hover:Hide()
    return hover
end
build.Hover = Hover

-- 复选框（OptionRow.Toggle / GridRow.Cells / TabRow.ShowCheck 共用）  KAF :57-66
local function StateAtlas(button, atlas)
    local texture = button:CreateTexture()
    texture:SetAtlas(atlas)
    texture:SetAllPoints()
    return texture
end

function build.CheckButton(parent)
    local button = CreateFrame("CheckButton", nil, parent)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetSize(30, 29)
    button:SetNormalTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetPushedTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetCheckedTexture(StateAtlas(button, "checkmark-minimal"))
    button:SetDisabledCheckedTexture(StateAtlas(button, "checkmark-minimal-disabled"))
    return button
end

-- [[ 行内控件列几何 ]] --  KAF RowMixins.lua:60-98 与 :125-154
local controlColumn = geometry.ControlColumn
local selectIn, inputIn = 18.5, 6
local placement = {
    Toggle = { "RIGHT", -controlColumn }, Range = { "RIGHT", -controlColumn },
    Select = { "RIGHT", -controlColumn + selectIn }, Execute = { "RIGHT", -controlColumn },
    Color = { "RIGHT", -controlColumn + inputIn },
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
