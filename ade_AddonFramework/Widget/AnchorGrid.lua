-- 九宫锚点：方向用原生 Atlas（不用字符箭头），选中格只染边框。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.AnchorGrid = W

-- 基准方向实证：common-icon-backarrow 原生指向左、common-icon-forwardarrow 原生指向右
--（参照 84:93:Blizzard_TransformManipulator/Blizzard_ScaleControlFrame.xml 的前进/后退用法；
-- SetRotation 正值 = 视觉逆时针，本网格左列三个方向 2026-11-13 实机确认无误，作为基准反推）。
local ARROWS = {
    { "common-icon-backarrow", -45 }, { "common-icon-backarrow", -90 }, { "common-icon-forwardarrow", 45 },
    { "common-icon-backarrow", 0 }, nil, { "common-icon-forwardarrow", 0 },
    { "common-icon-backarrow", 45 }, { "common-icon-backarrow", 90 }, { "common-icon-forwardarrow", -45 },
}

function W.Create(parent, opts)
    opts = opts or {}
    local grid = CreateFrame("Frame", nil, parent)
    local cell = opts.cellSize or 22
    grid:SetSize(cell * 3 + 8, cell * 3 + 8)
    grid.cells, grid.value = {}, opts.value or "CENTER"

    local points = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
    for i = 1, 9 do
        local col, r = (i - 1) % 3, math.floor((i - 1) / 3)
        local b = CreateFrame("Button", nil, grid)
        b:SetSize(cell, cell)
        b:SetPoint("TOPLEFT", col * (cell + 4), -(r * (cell + 4)))
        local skin = AF.Stylize(b, AF.C.WIDGET_FILL, AF.C.EDGE)
        b.skin = skin
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("CENTER", 0, 0)
        tex:SetSize(cell - 6, cell - 6)
        if i == 5 then
            -- CENTER 单元没有方向箭头：仅在禁用中心时画红叉
            if opts.centerDisabled then
                AF.ResolveIcon(tex, { atlas = "common-icon-redx" }, { atlas = true })
            end
        else
            local arrow = ARROWS[i]
            AF.ResolveIcon(tex, { atlas = arrow[1] }, { atlas = true })
            tex:SetRotation(math.rad(arrow[2]))
        end
        b:SetScript("OnClick", function()
            if i == 5 and opts.centerDisabled then return end
            grid.value = points[i]
            grid:Refresh()
            if opts.onSelect then opts.onSelect(points[i]) end
        end)
        b:SetScript("OnEnter", function() skin:SetBorder(AF.ColorTable("accent")) end)
        b:SetScript("OnLeave", function() grid:Refresh() end)
        grid.cells[i] = b
    end

    function grid:Refresh()
        for i, b in ipairs(self.cells) do
            b.skin:SetBorder(points[i] == self.value and AF.ColorTable("accent") or AF.C.EDGE)
        end
    end
    function grid:SetValue(v) self.value = v; self:Refresh() end
    function grid:GetValue() return self.value end
    grid:Refresh()
    return grid
end
