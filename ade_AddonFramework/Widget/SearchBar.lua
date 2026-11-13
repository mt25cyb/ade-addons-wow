-- 即时搜索：清除按钮用原生 Atlas，ESC 清空。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.SearchBar = W

function W.Create(parent, opts)
    opts = opts or {}
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(opts.width or 200, 22)
    local skin = AF.Stylize(bar, AF.C.WIDGET_FILL, AF.C.EDGE)
    bar.skin = skin

    local eb = CreateFrame("EditBox", nil, bar)
    eb:SetPoint("TOPLEFT", 5, 0)
    eb:SetPoint("BOTTOMRIGHT", -22, 0)
    eb:SetFontObject(AF.fontNormal)
    eb:SetAutoFocus(false)
    eb:SetTextInsets(2, 2, 0, 0)
    eb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() skin:SetBorder(AF.ColorTable("accent")) end)
    eb:SetScript("OnEditFocusLost", function() skin:SetBorder(AF.C.EDGE) end)

    local placeholder = bar:CreateFontString(nil, "OVERLAY")
    placeholder:SetFontObject(AF.fontSmall)
    placeholder:SetPoint("LEFT", 5, 0)
    placeholder:SetText(AF.L["AF_SEARCH"])
    placeholder:SetTextColor(unpack(AF.C.TEXT_DIM))

    local clear = AF.Widget.Icon.CreateButton(bar, {
        size = 14, atlas = "common-icon-redx",
        onClick = function() eb:SetText(""); eb:ClearFocus(); placeholder:Show() end,
    })
    clear:SetPoint("RIGHT", -3, 0)

    local results
    eb:SetScript("OnTextChanged", function(self, user)
        if not user then return end
        placeholder:SetShown((self:GetText() or "") == "")
        if not opts.items then return end
        if not results then
            results = AF.Widget.Dropdown.Create(bar, { width = opts.width or 200, items = {}, onSelect = function(_, item)
                if opts.onGoto then opts.onGoto(item) end
            end })
            results:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2)
        end
        local q = (self:GetText() or ""):lower()
        local found = {}
        for _, item in ipairs(opts.items) do
            local hay = ((item.label or "") .. " " .. (item.keywords or "")):lower()
            if q == "" or hay:find(q, 1, true) then found[#found + 1] = { text = item.label, value = item } end
        end
        results:SetItems(found)
        results:SetShown(#found > 0 and q ~= "")
    end)
    bar.editBox = eb
    return bar
end
