-- 预览块 / 多页面板：贴图与字固定，选中页签边框着色。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Preview = W

function W.CreateTile(parent, opts)
    opts = opts or {}
    local tile = CreateFrame("Button", nil, parent)
    tile:SetSize(opts.width or 120, opts.height or 56)
    local skin = AF.Stylize(tile, AF.C.WIDGET_FILL, AF.C.EDGE)
    tile.skin = skin
    local tex = tile:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 2, -2)
    tex:SetPoint("BOTTOMRIGHT", -2, 2)
    if opts.icon then AF.ResolveIcon(tex, opts.icon, opts) end
    tile.text = tile:CreateFontString(nil, "OVERLAY")
    tile.text:SetFontObject(AF.fontNormal)
    tile.text:SetPoint("CENTER", 0, 0)
    tile.text:SetText(opts.text or "")
    tile:SetScript("OnEnter", function() skin:SetBorder(AF.ThemeColorTable(tile, "accent")) end)
    tile:SetScript("OnLeave", function() skin:SetBorder(AF.C.EDGE) end)
    return tile
end

function W.CreatePane(parent, opts)
    opts = opts or {}
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetSize(opts.width or 240, opts.height or 120)
    local skin = AF.Stylize(pane, AF.C.CARD_FILL, AF.C.EDGE)
    pane.skin, pane.pages = skin, {}

    function pane:AddPage(id, label, build)
        local page = CreateFrame("Frame", nil, pane)
        page:SetPoint("TOPLEFT", 4, -28)
        page:SetPoint("BOTTOMRIGHT", -4, 4)
        page:Hide()
        if build then build(page) end
        local tab = AF.Widget.Button.Create(pane, {
            text = label, width = 70, height = 20,
            onClick = function() pane:Select(id) end,
        })
        tab:SetPoint("TOPLEFT", 4 + #self.pages * 74, -4)
        self.pages[#self.pages + 1] = { id = id, page = page, tab = tab }
        if #self.pages == 1 then self:Select(id) end
    end

    function pane:Select(id)
        for _, entry in ipairs(self.pages) do
            entry.page:SetShown(entry.id == id)
            AF.Widget.Button.SetVariant(entry.tab, entry.id == id and "primary" or "normal")
        end
    end
    return pane
end
