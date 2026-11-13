-- 文本：正文/标签固定白灰，只有标题类与标题下 1px 线可着色。
-- 底本 1753:1785:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Text = W

function W.Label(parent, text, width, font)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or AF.fontNormal)
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    if width then fs:SetWidth(width); fs:SetWordWrap(true) end
    return fs
end

function W.Desc(parent, text, width)
    local fs = W.Label(parent, text, width, AF.fontSmall)
    fs:SetJustifyV("TOP")
    return fs
end

--- 分节标题：字固定白，底下 1px 线随主题色（W.Accent(0.777)）。
function W.SectionTitle(parent, text, width)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width or AF.LAYOUT.contentW, 22)

    local fs = holder:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(AF.fontTitle)
    fs:SetPoint("BOTTOMLEFT", 0, 5)
    fs:SetText(text or "")

    local px = AF.Pixel(holder)
    local shadow = holder:CreateTexture(nil, "ARTWORK", nil, -1)
    shadow:SetTexture(AF.WHITE)
    AF.NoSnap(shadow)
    AF.Fixed(shadow, "EDGE")
    shadow:SetPoint("BOTTOMLEFT", px, -px)
    shadow:SetPoint("BOTTOMRIGHT", px, -px)
    shadow:SetHeight(px)

    local line = holder:CreateTexture(nil, "ARTWORK")
    line:SetTexture(AF.WHITE)
    AF.NoSnap(line)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetHeight(px)
    AF.Tint(line, "accent", 0.777)

    holder.text, holder.line = fs, line
    return holder
end

--- 分组小标题：字是着色部位（W.Accent(1)）。
function W.GroupLabel(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(AF.fontSmall)
    fs:SetText(text or "")
    AF.Tint(fs, "accent")
    return fs
end
