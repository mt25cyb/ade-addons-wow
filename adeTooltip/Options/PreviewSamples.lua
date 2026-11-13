-- adeTooltip — 预览样例（P1 骨架：占位内容 + 页联动标题）。
-- P7 将替换为真实分类样例（GameTooltip:SetItemByID/SetSpellByID/SetUnit 等驱动，
-- §九.3–9.4），并给可点元素挂 optionKey 元数据实现「点击预览元素定位设置项」。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true)
if not AF then return end
local L = ADT.L or {}

function ADT:BuildPreview(content)
    local title = AF.Widget.Text.SectionTitle(content, L.PREVIEW_TITLE, 300)
    title:SetPoint("TOPLEFT", 0, 0)
    local desc = AF.Widget.Text.Desc(content, L.PREVIEW_NOTE, 300)
    desc:SetPoint("TOPLEFT", 0, -36)
    self.previewSampleText = AF.Widget.Text.Desc(content, "", 300)
    self.previewSampleText:SetPoint("TOPLEFT", 0, -140)
    self:UpdatePreviewSample()
end

-- 页切换/设置变化时刷新占位文本（P7 起改为重渲真实样例）。
function ADT:UpdatePreviewSample()
    local fs = self.previewSampleText
    if not fs then return end
    local key = self.previewPage and ("TAB_" .. tostring(self.previewPage):upper())
    local label = (key and L[key]) or ""
    fs:SetText((L.PREVIEW_PAGE or "Page: %s"):format(label))
end
