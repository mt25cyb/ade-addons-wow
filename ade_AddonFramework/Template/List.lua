-- 行池列表：行底固定灰、字固定白；hover / 选中只染边框；图标三态。
-- 可开启 opts.draggable：每行左侧挂移动控件，拖动整行调序（参考 RowDrag 的鼠标轮询结束方式）。
-- 行池与修饰键行为底本 31:113:z-ref_retail_Interface_AddOns/Dejunk/src/ui/components/card-list.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Widget = AF.Widget or {}
local W = {}
AF.Template.List = W        -- 组合模板：清单列表
AF.Widget.List = W         -- 别名兼容

function W.Create(parent, opts)
    opts = opts or {}
    local list = CreateFrame("Frame", nil, parent)
    list:SetSize(opts.width or 300, opts.height or 160)
    local skin = AF.Stylize(list, AF.C.CARD_FILL, AF.C.EDGE)
    list.skin = skin

    local scroll = CreateFrame("ScrollFrame", nil, list, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 2, -2)
    scroll:SetPoint("BOTTOMRIGHT", -18, 2)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((opts.width or 300) - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and scroll.ScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
    end
    list.scroll, list.content = scroll, content

    local rowH = opts.rowH or 24
    local draggable = opts.draggable
    local pool = {}
    local dragState
    list.items, list.selected = opts.items or {}, nil

    local function Acquire(index)
        local row = pool[index]
        if row then return row end
        row = CreateFrame("Button", nil, content)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", 0, -((index - 1) * rowH))
        row:SetPoint("TOPRIGHT", 0, -((index - 1) * rowH))
        local rs = AF.Stylize(row, AF.C.WIDGET_FILL, AF.C.EDGE)
        row.skin = rs
        local iconX = draggable and 20 or 4
        if draggable then
            row.handle = CreateFrame("Button", nil, row)
            row.handle:SetSize(16, 16)
            row.handle:SetPoint("LEFT", 2, 0)
            row.handle.tex = row.handle:CreateTexture(nil, "ARTWORK")
            AF.NoSnap(row.handle.tex)
            row.handle.tex:SetAllPoints()
            AF.ResolveIcon(row.handle.tex, { atlas = "common-icon-move" }, { atlas = true })
            row.handle.tex:SetVertexColor(unpack(AF.C.TEXT_MUTED))
            row.handle:SetScript("OnMouseDown", function(_, button)
                if button ~= "LeftButton" then return end
                local sx, sy = GetCursorPosition()
                dragState = { index = row.index, startX = sx, startY = sy, active = false }
            end)
        end
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", iconX, 0)
        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetFontObject(AF.fontNormal)
        row.text:SetPoint("LEFT", iconX + 20, 0)
        row.text:SetPoint("RIGHT", -50, 0)
        row.text:SetJustifyH("LEFT")
        row.value = row:CreateFontString(nil, "OVERLAY")
        row.value:SetFontObject(AF.fontSmall)
        row.value:SetPoint("RIGHT", -6, 0)
        row:HookScript("OnEnter", function() rs:SetBorder(AF.ThemeColorTable(row, "accent")) end)
        row:HookScript("OnLeave", function()
            if list.selected ~= row.index then rs:SetBorder(AF.C.EDGE) end
        end)
        pool[index] = row
        return row
    end

    function list:SetItems(items)
        self.items = items or {}
        self:Refresh()
    end
    function list:Refresh()
        for i, item in ipairs(self.items) do
            local row = Acquire(i)
            row.index = i
            row:Show()
            AF.ResolveIcon(row.icon, item.icon, item)
            row.icon:SetShown(item.icon ~= nil)
            row.text:SetText(item.text or "")
            row.value:SetText(item.value and tostring(item.value) or "")
            row.skin:SetBorder(self.selected == i and AF.ThemeColorTable(row, "accent") or AF.C.EDGE)
            row:SetScript("OnClick", function(_, button)
                self.selected = i
                self:Refresh()
                if opts.onClick then opts.onClick(item, button, row) end
            end)
        end
        for i = #self.items + 1, #pool do pool[i]:Hide() end
        content:SetHeight(#self.items * rowH)
    end

    if draggable then
        local updater = CreateFrame("Frame", nil, list)
        updater:SetScript("OnUpdate", function()
            if not dragState then return end
            local x, y = GetCursorPosition()
            if not dragState.active then
                if math.abs(x - dragState.startX) > 6 or math.abs(y - dragState.startY) > 6 then
                    dragState.active = true
                end
                return
            end
            for i, row in ipairs(pool) do
                if i <= #list.items then
                    if row:IsMouseOver() then
                        row.skin:SetBorder(AF.ThemeColorTable(row, "accent"))
                    else
                        row.skin:SetBorder(list.selected == i and AF.ThemeColorTable(row, "accent") or AF.C.EDGE)
                    end
                end
            end
            if not IsMouseButtonDown("LeftButton") then
                local target
                for i = 1, #list.items do
                    if pool[i]:IsMouseOver() then target = i; break end
                end
                if target and target ~= dragState.index then
                    local moving = table.remove(list.items, dragState.index)
                    if moving then table.insert(list.items, target, moving) end
                    if opts.onReorder then opts.onReorder(list.items) end
                end
                dragState = nil
                list:Refresh()
            end
        end)
    end

    list:Refresh()
    return list
end
