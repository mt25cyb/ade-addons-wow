-- 条状信息条：同条多控件组合 + tooltip + 点击反馈 + 按比例进度填充。
-- 缺口实证 705:719:_temp/HomeworkTracker/UI.lua（原条没有显示进度程度）
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.InfoBar = W

function W.Create(parent, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", nil, parent)
    local width = opts.width or 420
    frame:SetWidth(width)
    frame.rows = {}
    local y = 0

    for _, item in ipairs(opts.items or {}) do
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(width, 26)
        row:SetPoint("TOPLEFT", 0, -y)
        local skin = AF.Stylize(row, AF.C.WIDGET_FILL, AF.C.EDGE)
        row.skin = skin

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", 6, 0)
        AF.ResolveIcon(row.icon, item.icon, item)
        row.icon:SetShown(item.icon ~= nil)

        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFontObject(AF.fontNormal)
        row.name:SetPoint("LEFT", item.icon and 26 or 8, 0)
        row.name:SetText(item.text or "")

        row.value = row:CreateFontString(nil, "OVERLAY")
        row.value:SetFontObject(AF.fontSmall)
        row.value:SetPoint("RIGHT", -8, 0)
        row.value:SetText(item.value and tostring(item.value) or "")

        -- 比例进度条：轨道固定灰，只染填充部分
        local barBg = AF.Fill(row, AF.C.CARD_FILL, "ARTWORK", 0)
        barBg:ClearAllPoints()
        barBg:SetPoint("BOTTOMLEFT", 1, 1)
        barBg:SetPoint("BOTTOMRIGHT", -1, 1)
        barBg:SetHeight(3)
        local barFill = AF.Fill(row, AF.C.WIDGET_FILL, "ARTWORK", 1)
        barFill:ClearAllPoints()
        barFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
        barFill:SetHeight(3)
        AF.Tint(barFill, "accent", 0.777)
        row.barBg, row.barFill = barBg, barFill

        function row:LayoutProgress()
            local p = AF.Clamp(item.progress or 0, 0, 1)
            local w = math.max((row:GetWidth() or width) - 2, 1)
            barFill:SetWidth(w * p)
            barFill:SetShown(p > 0)
            barBg:SetShown(item.showBar or p > 0)
        end
        row:SetScript("OnSizeChanged", function() row:LayoutProgress() end)
        row:LayoutProgress()

        row:SetScript("OnClick", function(_, button) if opts.onClick then opts.onClick(item, button, row) end end)
        row:SetScript("OnEnter", function()
            skin:SetBorder(AF.ColorTable("accent"))
            if item.tooltip then
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(item.tooltip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() skin:SetBorder(AF.C.EDGE); GameTooltip:Hide() end)
        frame.rows[#frame.rows + 1] = row
        y = y + 30
    end
    frame:SetHeight(y)
    return frame
end
