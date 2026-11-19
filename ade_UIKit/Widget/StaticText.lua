------------------------------------------------------------
-- 文本行族（b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowText.lua 更名）：
-- HeaderRow / SubHeadingRow / NoteRow——三者的构建与行为完全同构，仅字体与锚点差异。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins = Internal.Build, Internal.Mixins

-- [[ 构建 ]] --  KAF RowFrames.lua:158-181
function build.HeaderRow(parent)
    local row = build.Row("Frame", parent)
    row.Text = build.Text(row, "ARTWORK", "GameFontHighlightLarge", "LEFT")
    row.Text:SetPoint("BOTTOMLEFT", 6, 6)
    row.Text:SetPoint("RIGHT", -6, 0)
    return build.Finish(row, mixins.TextRow)
end

function build.SubHeadingRow(parent)
    local row = build.Row("Frame", parent)
    row.Text = build.Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.Text:SetPoint("RIGHT", -16, 0)
    return build.Finish(row, mixins.TextRow)
end

function build.NoteRow(parent)
    local row = build.Row("Frame", parent)
    row.Text = build.Text(row, "ARTWORK", "GameFontDisable", "LEFT", "TOP")
    row.Text:SetPoint("TOPLEFT", 16, -4)
    row.Text:SetPoint("BOTTOMRIGHT", -16, 0)
    return build.Finish(row, mixins.TextRow)
end

-- [[ 行为 ]] --  KAF RowMixins.lua:130-148
mixins.TextRow = mixins.TextRow or {}
function mixins.TextRow:Init(element)
    self.Element = element
    local indent = element.indent or 0
    self.Text:ClearAllPoints()
    self.Text:SetPoint("TOPLEFT", 16 + indent * 20, -4)
    self.Text:SetPoint("BOTTOMRIGHT", -16, 0)
    self:Refresh()
end

-- b022：TextRow 也参与就地 Refresh；Text 为函数时每次重算，
-- 供宿主做实时状态提示（此前只有切页 Init 才更新）。
function mixins.TextRow:Refresh()
    local element = self.Element
    if not element then return end
    local text = element.Text
    if type(text) == "function" then text = text() end
    self.Text:SetText(text or "")
end
