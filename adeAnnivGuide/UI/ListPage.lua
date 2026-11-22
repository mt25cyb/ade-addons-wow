--[==[ adeAnnivGuide / UI/ListPage.lua — 主界面：搜索栏 + 条目两列网格
    12.x 原生风格（用户 2026-11-21）：
    · 搜索栏 = SearchBoxTemplate（adeMapTab_Delve/UI/WorldMapPanel.lua:241-250 同款：
      SearchBoxTemplate_OnTextChanged 保持占位符/清除按钮行为 + SetAutoFocus(false)，
      ade_UIKit/Widget/WindowFrame.lua:65 同款）。
    · 条目按钮 = UIPanelButtonTemplate 原生按钮。
    · 搜索即时过滤：标题 + 该条目全部文本步骤（不区分大小写，子串匹配），
      可见条目按列向重排（左列前半、右列后半），隐藏不匹配项并重算内容高度。
    滚动容器 = ScrollFrameTemplate + ScrollUtil.InitScrollFrameWithScrollBar
    （adeMapTab_Delve/UI/RosterWindow.lua:114-120 / adeStatPlus/Modules/SortWindow.lua:349-365 同款）。 ]==]
local ns = _G.adeAnnivGuide
local ListPage = {}
ns.ListPage = ListPage

local GAP_X = 16
local PAD = 12
local BTN_H = 24
local ROW_STEP = BTN_H + 6
local SEARCH_H = 22

local content, entryItems = nil, {}

--- 滚动容器（ScrollFrameTemplate 自带 MinimalScrollBar，自动维护范围）。
local function CreateAutoScrollFrame(parent)
    --@diagnostic disable-next-line: undefined-global
    local ScrollUtil = ScrollUtil
    local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate", {
        scrollBarX = 8,
        scrollBarTopY = -2,
        scrollBarBottomY = 4,
        scrollBarHideIfUnscrollable = true,
    })
    ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    return scroll, content
end

--- 即时过滤：query 为空显示全部；否则按子串匹配（不区分大小写）。
local function ApplyFilter(query)
    query = (query or ""):lower()
    local visible = {}
    for _, item in ipairs(entryItems) do
        local match = query == "" or item.hay:find(query, 1, true) ~= nil
        item.btn:SetShown(match)
        if match then visible[#visible + 1] = item end
    end

    local leftCount = math.ceil(#visible / 2)
    local colX = { [1] = PAD, [2] = PAD + ListPage.COL_W + GAP_X }
    local maxRows = 0
    for i, item in ipairs(visible) do
        local col = (i <= leftCount) and 1 or 2
        local row = (col == 1) and i or (i - leftCount)
        maxRows = math.max(maxRows, row)
        item.btn:ClearAllPoints()
        item.btn:SetPoint("TOPLEFT", content, "TOPLEFT", colX[col], -(PAD + (row - 1) * ROW_STEP))
    end
    content:SetHeight(PAD + maxRows * ROW_STEP + 4)
end

--- 创建主界面页；返回页 Frame。
function ListPage.Create(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    -- 搜索栏（整行，紧贴原生标题栏下；原生标题区按 36px 预留）
    local search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
    search:SetAutoFocus(false)
    search:SetHeight(SEARCH_H)
    search:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -36)
    search:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -28, -36)
    search:SetScript("OnTextChanged", function(self)
        -- 先走模板脚本：保持占位符显隐与清除按钮行为（WorldMapPanel.lua:598-600 同款）
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
        ApplyFilter(self:GetText())
    end)

    -- 列表滚动区（搜索栏下方）
    local scroll = CreateAutoScrollFrame(page)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -(36 + SEARCH_H + 6))
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 12)
    content = scroll.content

    -- 内容宽 = 滚动区宽 680 − 滚动条 ~10 − 余量 14 = 656
    local CONTENT_W = 656
    content:SetWidth(CONTENT_W)
    ListPage.COL_W = math.floor((CONTENT_W - PAD * 2 - GAP_X) / 2)

    -- 条目按钮一次建齐，过滤只做显隐 + 重排
    for _, entry in ipairs(ns.GUIDE) do
        local hay = { entry.title:lower() }
        for _, st in ipairs(entry.steps) do
            if st.t == "text" then hay[#hay + 1] = st.s:lower() end
        end

        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(ListPage.COL_W, BTN_H)
        btn:SetText(entry.title)
        btn:SetScript("OnClick", function()
            ns.Window.ShowContent(entry)
        end)
        entryItems[#entryItems + 1] = { entry = entry, btn = btn, hay = table.concat(hay, "\n") }
    end

    ApplyFilter("")
    return page
end
