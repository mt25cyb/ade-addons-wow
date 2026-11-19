------------------------------------------------------------
-- 元素 Kind / 几何 / Flatten / 双层行池。
-- 逐块复刻 KAF Libs/Krowi_Options/Kinds.lua；两栏适配：删除 Help 相关 Kind 与几何。
-- 额外适配：宿主用小写 kind 与扁平 spec，此处归一化为 KAF 的 element.Kind / element.Option。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal

-- [[ Geometry ]] --  KAF Kinds.lua:39-59；HelpWidth 删除，其余沿用两栏既有数值。
local geometry = {
    WindowWidth = 920, WindowHeight = 720, MinHeight = 560,
    NavWidth = 199, NavEnd = 199,
    BodyTop = -76, BodyBottom = 46, BodyLeft = 18, BodyRight = -18,
    InnerLeft = 17, InnerTop = -64, InnerRight = -17, InnerBottom = 42,
    PageLeftPad = 16, PageRightPad = 16, ControlColumn = 330, NameRight = 342,
    GridLeft = 200, GridColumn = 72, GridColumns = 5,
    SliderWidth = 250, WithSliderWidth = 214,
    CardPictureHeight = 86, CardBorderColor = { 1, 1, 1, 0.12 }, TabCheckX = 34,
    RowHeight = 30, RowGap = 2, SearchWidth = 160,
}
lib.Geometry = geometry
Internal.Geometry = geometry

-- [[ Kinds ]] --  KAF Kinds.lua:61-157，删除 Help 专用项。
local kinds = {}
Internal.Kinds = kinds

kinds.Header = { Build = "HeaderRow", Height = 34, Search = { Heading = 1 } }
kinds.SubHeading = { Build = "SubHeadingRow", Height = 26, Search = { Heading = 2 } }
kinds.Note = {
    Build = "NoteRow",
    Height = function(window, element)
        local text = element.Text
        if type(text) == "function" then text = text() end
        local indent = element.indent or 0
        return window:MeasureText(text or "", "GameFontDisable", window:PageWidth() - 32 - indent * 20) + 8
    end,
}
kinds.Option = {
    Build = "OptionRow",
    -- b018：multiline 行独占下半部分，高度按 Type 区分；其余行沿用 30。
    Height = function(_, element)
        if element.Option and element.Option.Type == "multiline" then return 118 end
        return 30
    end,
    Hidden = function(element) return element.Option:IsHidden() end,
    Names = function(element)
        local with = element.With
        local withName = with and not with:IsHidden() and (with.Type == "execute" and with:GetButtonText() or with:GetLabel()) or nil
        return element.Option:GetLabel(), withName
    end,
    Options = function(element) return element.Option, element.With end,
    Descriptions = function(element) -- KAF Kinds.lua:83-87：搜索的描述来源，勾选"搜索描述"后参与命中。
        local option, with = element.Option, element.With
        local withDescription = with and not with:IsHidden() and with.GetDescription and with:GetDescription() or nil
        return option.GetDescription and option:GetDescription(), withDescription
    end,
    Search = { Indented = true },
}
kinds.Sub = {
    Build = "SubRow", Height = 28,
    Names = function(element) return element.Text end,
    Search = { Indented = true, BringsMembers = true },
}
kinds.Grid = {
    Expand = function(element, list)
        -- KAF Kinds.lua:101-106：列标题行与每数据行一组复选框；All/None 属于独立的 Sub 家族标题行。
        list[#list + 1] = { Kind = "GridHeader", Columns = element.Columns }
        for _, row in ipairs(element.Rows) do
            list[#list + 1] = { Kind = "GridRow", Label = row.Label, Cells = row.Cells }
        end
    end,
}
kinds.GridHeader = { Build = "GridHeaderRow", Height = 34, Search = { Columns = true } }
kinds.GridRow = {
    Build = "GridRow", Height = 28,
    Names = function(element) return element.Label end,
    Cells = function(element) return element.Cells end,
    Search = { UnderColumns = true },
}
kinds.TabList = {
    Expand = function(element, list)
        for _, item in ipairs(element.Items) do list[#list + 1] = { Kind = "TabRow", Item = item } end
    end,
}
kinds.TabRow = {
    Build = "TabRow", Height = 28,
    Names = function(element)
        local item = element.Item
        if not item then return nil end
        if item.Show then return item.Show:GetLabel() end
        return item.Name
    end,
    Options = function(element) return element.Item and element.Item.Show end,
}
kinds.Link = { Build = "LinkRow", Height = 26 }
-- b038：列表行（kind="list"，Widget/ListRow.lua）——拖动排序/拖入物品/组合条目/斑马纹。
kinds.List = {
    Build = "ListRow",
    Height = function(_, element)
        local spec = element.Option and element.Option.Spec or {}
        -- 标题行 26 + Inset 上下内衬 24 + visibleRows × 条目高
        return 50 + (spec.visibleRows or 8) * (spec.rowHeight or 26)
    end,
    Hidden = function(element) return element.Option:IsHidden() end,
    Names = function(element) return element.Option:GetLabel() end,
    Options = function(element) return element.Option end,
    Descriptions = function(element) return element.Option.GetDescription and element.Option:GetDescription() end,
    Search = { Indented = true },
}
kinds.Cards = {
    Expand = function(element, list)
        local cards, columns = element.Cards, Internal.CardColumns or 3
        for first = 1, #cards, columns do
            local row, names = { Kind = "CardRow", Cards = {} }, {}
            for i = first, math.min(first + columns - 1, #cards) do
                row.Cards[#row.Cards + 1] = cards[i]
                names[#names + 1] = cards[i].Name or ""
            end
            row.Key = table.concat(names, ",")
            list[#list + 1] = row
        end
    end,
}
kinds.CardRow = {
    Build = "CardRow",
    Height = function(window, element) return Internal.CardRowHeight and Internal.CardRowHeight(window, element) or 120 end,
}
kinds.SearchHeading = { Build = "SearchHeadingRow", Height = 45 }

-- [[ 宿主 spec 适配 ]] --
-- Demo 用 { kind="option", key="toggle", label=..., get=..., set=... }；KAF 用 { Kind="Option", Option=option }。
-- 这里做一次性归一化并缓存到宿主表，避免每次 Flatten 改表身份（CreateDataProvider 按表身份工作）。
local kindMap = {
    header = "Header", subheading = "SubHeading", sub = "Sub", note = "Note",
    option = "Option", toggle = "Option", range = "Option", select = "Option",
    input = "Option", execute = "Option", key = "Option", multiline = "Option",
    color = "Option", -- b034 起新增的颜色选择器控件（漏登记时 fallback 出未知 Kind，整行被丢弃）
    list = "List",    -- b038 列表行（Widget/ListRow.lua）
    grid = "Grid", link = "Link", tablist = "TabList", card = "Cards", cards = "Cards",
}

local function Normalize(element)
    if type(element) ~= "table" then return element end
    if element.Kind then return element end
    if element._bofNormalized then return element._bofNormalized end
    local copy = {}
    for k, v in pairs(element) do copy[k] = v end
    copy.Kind = kindMap[element.kind] or (element.kind and element.kind:gsub("^%l", string.upper)) or "Option"
    if copy.Text == nil then copy.Text = element.text or element.label end
    if copy.Detail == nil then copy.Detail = element.detail end
    if copy.Kind == "Option" and not copy.Option and Internal.MakeOption then
        copy.Option = Internal.MakeOption(copy)
        -- KAF RowMixins.lua:28-33：toggle 可跟一个 range 或 execute 作为 With 组合控件。
        if copy.Option.Type == "toggle" and element.with then
            copy.With = Internal.MakeOption(element.with)
        end
    elseif copy.Kind == "List" and not copy.Option and Internal.MakeOption then
        -- b038：列表行同样走 MakeOption 适配（label/indent/Spec 契约与 Option 一致）
        copy.Option = Internal.MakeOption(copy)
    elseif copy.Kind == "Sub" then
        copy.Members = element.members or element.Members
    end
    if copy.Kind == "Grid" then
        copy.Columns = element.columns or element.Columns
        local rows = {}
        for _, row in ipairs(element.rows or element.Rows or {}) do
            local cells = {}
            for _, cell in ipairs(row.cells or row.Cells or {}) do
                cells[#cells + 1] = (cell.Get and cell.Set) and cell or (Internal.MakeOption and Internal.MakeOption(cell))
            end
            rows[#rows + 1] = { Kind = "GridRow", Label = row.label or row.Label, Cells = cells }
        end
        copy.Rows = rows
    elseif copy.Kind == "Cards" then
        local cards = {}
        for _, c in ipairs(element.cards or element.Cards or {}) do
            cards[#cards + 1] = {
                Name = c.name or c.text or c.Name, Text = c.detail or c.Text,
                IsNew = c.isNew or c.IsNew, OnClick = c.onClick or c.OnClick,
                Icon = c.icon or c.Icon, Picture = c.picture or c.Picture,
                Width = c.width or c.Width, Height = c.height or c.Height,
                TexCoords = c.texCoords or c.TexCoords, Part = c.part or c.Part,
                Section = c.section,
            }
        end
        copy.Cards = cards
    elseif copy.Kind == "TabList" then
        local items = {}
        for i, item in ipairs(element.items or element.Items or {}) do
            items[i] = {
                Position = item.position or i, Name = item.label or item.name or item.Name,
                Source = item.source or item.Source,
                MoveUp = item.moveUp or item.MoveUp, MoveDown = item.moveDown or item.MoveDown,
                Show = (item.show and Internal.MakeOption and Internal.MakeOption(item.show)) or item.Show,
            }
        end
        copy.Items = items
    end
    element._bofNormalized = copy
    return copy
end
Internal.NormalizeElement = Normalize

-- KAF Kinds.lua:163-176：Hidden 在展平阶段剔除，Expand 展开为多行，known 限定保留的 Kind。
function Internal.Flatten(elements, known)
    local list = {}
    local underSubHeading = false
    for _, raw in ipairs(elements or {}) do
        local element = Normalize(raw)
        local kind = kinds[element.Kind]
        if kind and kind.Expand then
            kind.Expand(element, list)
        elseif kind and kind.Hidden then
            if not kind.Hidden(element) then list[#list + 1] = element end
        elseif not known or known[element.Kind] then
            list[#list + 1] = element
        end
        -- KAF 视觉层级：Header 为基准；SubHeading 与无 SubHeading 时的选项同为 X 级
        --（SubHeadingRow 左 16 / Option Indent 0 左 16）；其下选项进一级到 2X（左 36），
        -- 宿主显式给了 indent 时不覆盖。KAF 由数据层 Map.lua 指定 Indent，此处对扁平 spec 自动补齐。
        if element.Kind == "Header" or kinds[element.Kind] and kinds[element.Kind].Expand then
            underSubHeading = false
        elseif element.Kind == "SubHeading" then
            underSubHeading = true
        elseif element.Kind == "Option" and underSubHeading and element.Option and element.Option.Indent == nil then
            element.Option.Indent = 1
        end
    end
    return list
end

-- [[ 列表：host + 每 Kind 行池 ]] --  KAF Kinds.lua:180-234 原样复刻，rightPad 为两栏右侧留白。
local function Extent(window, listKinds, element)
    local height = listKinds[element.Kind].Height
    if type(height) == "function" then return height(window, element) end
    return height
end

function Internal.InitList(window, scrollBox, scrollBar, listKinds, leftPad, spacing, rightPad)
    local free = {}
    local function Release(host)
        local row = host.Row
        if not row then return end
        row:Hide()
        row:ClearAllPoints()
        free[row.ListKind] = free[row.ListKind] or {}
        tinsert(free[row.ListKind], row)
        host.Row = nil
    end
    local view = CreateScrollBoxListLinearView(0, 0, leftPad or 0, rightPad or 0, spacing or 0)
    view:SetElementFactory(function(factory, element)
        local kind = element.Kind
        factory("Frame", function(host, data)
            if host.Row and host.Row.ListKind ~= kind then Release(host) end
            local row = host.Row
            if not row then
                row = free[kind] and tremove(free[kind])
                if not row then
                    local builder = listKinds[kind] and listKinds[kind].Build
                    local build = builder and Internal.Build[builder]
                    if not build then return end
                    row = build(host)
                    row.ListKind = kind
                end
                row:SetParent(host)
                row:SetAllPoints(host)
                row:Show()
                host.Row = row
            end
            if row.Init then row:Init(data, window) end
        end)
    end)
    view:SetFrameFactoryResetter(function(_, host)
        Release(host)
        host:Hide()
        host:ClearAllPoints()
    end)
    view:SetElementExtentCalculator(function(_, element) return Extent(window, listKinds, element) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    return ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)
end
