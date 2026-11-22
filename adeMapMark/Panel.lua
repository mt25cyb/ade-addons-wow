--[[
adeMapMark - Panel（世界地图主面板 / 表单 / 收藏 / 大编辑弹窗 / IO）
定位：ADE v6.5；世界地图内嵌主面板，Tab 由 LibWorldMapTabs 托管（计划 §4.3）
来源：_temp/_map/old_dev/BDmap_ade/BDmap.lua UI 段，已移除旧 Tab/设置页/命令
计划：_docs/plans/adeMapMark-dev-plan.md §4.3
--]]

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L
local PANEL_MODE = "adeMapMark_PANEL_MODE"
local REPUTATION_STAR = "Interface\\Common\\ReputationStar"
local DEFAULT_TEXT_SIZE = ns.DEFAULT_TEXT_SIZE

-- 工具转发：Core/Provider/WorldMapPin 已实现，UI 段沿用旧名以减少改动
local encodeCoord = ns.encodeCoord
local decodeCoord = ns.decodeCoord
local cloneColor = ns.cloneColor
local GetDB = ns.db
local GetDisplayNote = ns.GetDisplayNote
local RefreshMapPins = ns.RefreshMapPins
local RefreshAllPins = ns.RefreshAllPins
local GetProviderFavKey = ns.GetProviderFavKey
local IsProviderFavorited = ns.IsProviderFavorited
local CallPlus = ns.CallPlus

local panel, tabButton
local editBoxCoords, editBoxTitle, editBoxNote, sizeSlider, textSizeSlider, btnAdd, btnDelete, colorBtn, grayBtn, bigNotePopup, resetOverrideBtn
local recentRowPool = {}
local f = CreateFrame("Frame")

function ns.CallPlus(funcName, ...)
    local Plus = ns.Plus
    if Plus and Plus[funcName] then return Plus[funcName](...) end
end
CallPlus = ns.CallPlus

-- GetDisplayNote（完整备注换行转空格的单行预览）见顶部转发，实现由 WorldMapPin.lua 提供

-- 限制 EditBox 最多 maxLines 行
local function LimitEditBoxLines(eb, maxLines)
    eb:HookScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local text = (self:GetText() or ""):gsub("\r\n?", "\n")
        local pos, n = 0, 0
        while n < maxLines do
            local found = text:find("\n", pos + 1, true)
            if not found then return end  -- 换行数 < maxLines，无需截断
            pos, n = found, n + 1
        end
        local newText = text:sub(1, pos - 1)
        self:SetText(newText)
        self:SetCursorPosition(math.min(self:GetCursorPosition(), #newText))
    end)
end

-- 获取当前玩家所在位置的地图 ID 和坐标 (x, y)
local function GetCurrentPlayerMapCoord()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID and WorldMapFrame then mapID = WorldMapFrame:GetMapID() end
    if not mapID then return nil, nil, nil end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return mapID, nil, nil end
    return mapID, pos:GetXY()
end

-- 解析输入的坐标字符串
local function parseCoordInput(text)
    local xStr, yStr = tostring(text or ""):match("^%s*([%d%.]+)[,%s]+([%d%.]+)%s*$")
    if not xStr or not yStr then return nil, nil end
    local x, y = tonumber(xStr), tonumber(yStr)
    if not x or not y then return nil, nil end
    if x > 1 or y > 1 then x, y = x/100, y/100 end
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil, nil end
    return x, y
end

-- 查找图标名称：若 adeMapMarkPlus 已加载则委托给它，否则返回通用名
local function FindIconName(tex)
    if not tex then return nil end
    return CallPlus("FindIconName", tex) or L.ICON_LABEL
end

-- 各种按钮和输入框的预览同步整合函数
local function SyncPreviewStyle()
    if not colorBtn then return end
    local c = colorBtn.curColor
    local isGray = grayBtn and grayBtn.isGray or false
    local cr, cg, cb = c.r, c.g, c.b
    if isGray then
        local lum = cr * 0.299 + cg * 0.587 + cb * 0.114
        cr, cg, cb = lum, lum, lum
    end
    -- 调色按钮
    colorBtn.tex:SetColorTexture(cr, cg, cb, c.a or 1)
    -- 主面板标题输入框
    if editBoxTitle then
        editBoxTitle:SetTextColor(cr, cg, cb)
        editBoxTitle:SetAlpha(c.a or 1)
    end
    -- 弹出大编辑框的标题输入框
    if bigNotePopup and bigNotePopup:IsShown() and bigNotePopup.titleBox then
        bigNotePopup.titleBox:SetTextColor(cr, cg, cb)
        bigNotePopup.titleBox:SetAlpha(c.a or 1)
    end
    -- 图标选择器
    if panel and panel.iconSelectorBtn and panel.iconSelectorBtn.tex:IsShown() then
        panel.iconSelectorBtn.tex:SetAlpha(c.a or 1)
        panel.iconSelectorBtn.tex:SetDesaturated(isGray)
        ns.ApplyIconTexCoord(panel.iconSelectorBtn.tex, panel.selectedIcon, panel.iconCrop)
        if panel.rotatorFrame and panel.rotatorFrame.SetAngle then
            panel.rotatorFrame.SetAngle(panel.iconRotation or 0)
        end
    end
end



-- ============================================================================
-- 弹窗大编辑器
-- ============================================================================

local function ShowBigNoteEditor(sourceTitleBox, sourceNoteBox)
    if not bigNotePopup then
        bigNotePopup = CreateFrame("Frame", "BD_BigNotePopup", UIParent, "BackdropTemplate")
        tinsert(UISpecialFrames, "BD_BigNotePopup")

        bigNotePopup:SetSize(450, 480)

        -- 读取上次保存的弹窗位置，若无则居中
        local db = ns.db()
        if db.settings.bigNotePos then
            local pos = db.settings.bigNotePos
            bigNotePopup:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        else
            bigNotePopup:SetPoint("CENTER")
        end

        bigNotePopup:SetFrameStrata("DIALOG")
        bigNotePopup:SetMovable(true)
        bigNotePopup:EnableMouse(true)
        bigNotePopup:RegisterForDrag("LeftButton")

        -- 拖拽开始
        bigNotePopup:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self.isDragging = true
        end)

        -- 拖拽结束：将新位置持久化到数据库
        bigNotePopup:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self.isDragging = false
            local point, _, relativePoint, x, y = self:GetPoint()
            local db = ns.db()
            db.settings.bigNotePos = {
                point         = point,
                relativePoint = relativePoint,
                x             = x,
                y             = y,
            }
        end)

        -- 关闭按钮
        local closeBtn = CreateFrame("Button", nil, bigNotePopup, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", bigNotePopup, "TOPRIGHT", -5, -5)

        -- 顶部标题文字
        local titleText = bigNotePopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("TOP", bigNotePopup, "TOP", 0, -18)
        titleText:SetText(L.BIGNOTE_TITLE)
        titleText:SetTextColor(1, 1, 1)

        -- 点击空白处清除输入框焦点
        bigNotePopup:SetScript("OnMouseDown", function()
            if bigNotePopup.titleBox then bigNotePopup.titleBox:ClearFocus() end
            if bigNotePopup.noteBox  then bigNotePopup.noteBox:ClearFocus()  end
        end)

        -- 背景纹理
        if not bigNotePopup.bg then
            bigNotePopup.bg = bigNotePopup:CreateTexture(nil, "BACKGROUND")
        end
        bigNotePopup.bg:SetAtlas("QuestLog-main-background", true)
        bigNotePopup.bg:SetPoint("TOPLEFT",     bigNotePopup, "TOPLEFT",     4,  -4)
        bigNotePopup.bg:SetPoint("BOTTOMRIGHT", bigNotePopup, "BOTTOMRIGHT", -4,  4)
        bigNotePopup.bg:SetVertexColor(1, 1, 1, 0.95)

        -- 边框
        if not bigNotePopup.Border then
            bigNotePopup.Border = CreateFrame("Frame", nil, bigNotePopup, "QuestLogBorderFrameTemplate")
        end
        bigNotePopup.Border:SetAllPoints(bigNotePopup)

        -- ── 标题输入框 ────────────────────────────────────────────────────

        local lTitle = bigNotePopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lTitle:SetPoint("TOPLEFT", 20, -50)
        lTitle:SetText(L.BIGNOTE_TITLE_LABEL)

        -- 标题输入框背景
        local titleBg = CreateFrame("Frame", nil, bigNotePopup, "BackdropTemplate")
        titleBg:SetSize(400, 48)
        titleBg:SetPoint("TOPLEFT", lTitle, "BOTTOMLEFT", 0, -5)
        titleBg:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        titleBg:SetBackdropColor(0, 0, 0, 0.3)
        titleBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

        -- 标题编辑框
        local ebTitle = CreateFrame("EditBox", nil, titleBg)
        titleBg:SetScript("OnMouseDown", function() ebTitle:SetFocus() end)
        ebTitle:SetMultiLine(true)
        ebTitle:SetFontObject(ChatFontNormal)
        ebTitle:SetSpacing(3)
        ebTitle:SetPoint("TOPLEFT",     titleBg, "TOPLEFT",     6,  -6)
        ebTitle:SetPoint("BOTTOMRIGHT", titleBg, "BOTTOMRIGHT", -6,  6)
        ebTitle:SetAutoFocus(false)
        LimitEditBoxLines(ebTitle, 2)   -- 限制最多 2 行

        ebTitle:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        bigNotePopup.titleBox = ebTitle

        -- ── 备注输入框 ────────────────────────────────────────────────────

        local lNote = bigNotePopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lNote:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, -15)
        lNote:SetText(L.BIGNOTE_NOTE_LABEL)

        -- 备注输入框背景（400 为左右宽度，260 为上下高度）
        local noteBg = CreateFrame("Frame", nil, bigNotePopup, "BackdropTemplate")
        noteBg:SetSize(400, 260)
        noteBg:SetPoint("TOPLEFT", lNote, "BOTTOMLEFT", 0, -5)
        noteBg:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        noteBg:SetBackdropColor(0, 0, 0, 0.3)
        noteBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

        -- 滚动框（右侧留出滚动条空间）
        local scrollFrame = CreateFrame("ScrollFrame", "adeMapMark_BigNoteScroll", bigNotePopup, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT",     noteBg, "TOPLEFT",     6,  -6)
        scrollFrame:SetPoint("BOTTOMRIGHT", noteBg, "BOTTOMRIGHT", -26, 6)

        -- 备注编辑框
        local ebNote = CreateFrame("EditBox", nil, scrollFrame)
        noteBg:SetScript("OnMouseDown",      function() ebNote:SetFocus() end)
        scrollFrame:SetScript("OnMouseDown", function() ebNote:SetFocus() end)
        ebNote:SetMultiLine(true)
        ebNote:SetMaxLetters(2000)
        ebNote:SetFontObject(ChatFontNormal)
        local scrollWidth = 400 - 6 - 26 - 0   -- 略微缩窄，避免遮挡滚动条
        ebNote:SetWidth(scrollWidth)
        ebNote:SetJustifyH("LEFT")
        ebNote:SetAutoFocus(false)
        ebNote:SetScript("OnEnterPressed", function(self) self:Insert("\n") end)

        ebNote:SetScript("OnEscapePressed", function(self)
            if self:HasFocus() then self:ClearFocus() end
        end)

        ebNote:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
        scrollFrame:SetScrollChild(ebNote)
        bigNotePopup.noteBox = ebNote

        -- ── 保存按钮 ──────────────────────────────────────────────────────

        local btnOk = CreateFrame("Button", nil, bigNotePopup, "UIPanelButtonTemplate")
        btnOk:SetSize(220, 30)
        btnOk:SetPoint("BOTTOM", 0, 20)
        btnOk:SetText(L.BIGNOTE_OK)
        local fontString = btnOk:GetFontString()
        if fontString then fontString:SetJustifyH("LEFT") end

        btnOk:SetScript("OnClick", function()
            if bigNotePopup.targetTitle then
                bigNotePopup.targetTitle:SetText(bigNotePopup.titleBox:GetText())
            end
            if bigNotePopup.targetNote then
                local fullNote = bigNotePopup.noteBox:GetText()
                bigNotePopup.targetNote.fullText = fullNote
                bigNotePopup.targetNote:SetText(GetDisplayNote(fullNote))
                bigNotePopup.targetNote:SetCursorPosition(0)
            end
            bigNotePopup:Hide()
        end)

        -- 拖拽或移动时降低透明度，停止后恢复
        bigNotePopup:SetScript("OnUpdate", function(self, elapsed)
            if self.isDragging or IsPlayerMoving() then
                if self:GetAlpha() ~= 0.6 then self:SetAlpha(0.6) end
            else
                if self:GetAlpha() ~= 1.0 then self:SetAlpha(1.0) end
            end
        end)

        -- 弹框显示/隐藏时自动同步放大缩小按钮状态
        bigNotePopup:HookScript("OnShow", function()
            if panel and panel.btnExpand then
                panel.btnExpand.MaximizeButton:Hide()
                panel.btnExpand.MinimizeButton:Show()
            end
        end)
        bigNotePopup:HookScript("OnHide", function()
            if panel and panel.btnExpand then
                panel.btnExpand.MaximizeButton:Show()
                panel.btnExpand.MinimizeButton:Hide()
            end
        end)
    end

    -- 每次打开时，将主面板当前内容同步到弹窗
    bigNotePopup.targetTitle = sourceTitleBox
    bigNotePopup.targetNote  = sourceNoteBox
    bigNotePopup.titleBox:SetText(sourceTitleBox:GetText())

    local currentNote = sourceNoteBox.fullText or sourceNoteBox:GetText()
    bigNotePopup.noteBox:SetText(currentNote)
    bigNotePopup:Show()
    SyncPreviewStyle()
end


-- 刷新可折叠分组清单：收藏点 / 手动标记 / 各数据包
local recentHeaderPool, recentEmptyPool = {}, {}

local function RefreshRecentList()
    if not panel or not panel.recentContainer then return end

    for _, row in ipairs(recentRowPool) do row:Hide(); row:ClearAllPoints() end
    for _, h in ipairs(recentHeaderPool) do h:Hide(); h:ClearAllPoints() end
    for _, e in ipairs(recentEmptyPool) do e:Hide(); e:ClearAllPoints() end

    local db           = ns.db()
    local markers      = db.markers or {}
    local yOffset      = 0
    local currentMapID = WorldMapFrame:GetMapID()
    db.settings.listCollapsed = db.settings.listCollapsed or {}
    local collapsed = db.settings.listCollapsed
    local shownCount = 0

    -- ① 收藏点（本地 + 外挂）与 ② 手动标记
    -- 隐藏项也要保留在清单里，否则勾选框无法再次把它打开
    local favList, manualList = {}, {}
    for i = #markers, 1, -1 do
        local m = markers[i]
        tinsert(manualList, m)
        if m.isFavorite then tinsert(favList, m) end
    end
    -- ③ 各数据包：includeHidden=true 让被隐藏的标记仍可勾选恢复
    local providerItems = {}
    for _, m in ipairs(ns:GetProviderMarkers(true)) do
        if IsProviderFavorited(m) then tinsert(favList, m) end
        local n = m.providerName or "?"
        providerItems[n] = providerItems[n] or {}
        tinsert(providerItems[n], m)
    end

    local groups = {}
    if #favList > 0 then
        tinsert(groups, { key = "favorites", title = L.MARK_FAVORITE .. " (" .. #favList .. ")", items = favList })
    end
    tinsert(groups, { key = "manual", title = "手动标记点 (" .. #manualList .. ")", items = manualList, empty = "暂无手动标记点" })
    for _, prov in ipairs(ns.markProviders) do
        local items = providerItems[prov.name]
        if items and #items > 0 then
            tinsert(groups, {
                key = "prov:" .. prov.name,
                title = "[数据包] " .. ns.GetProviderDisplayName(prov.name) .. " (" .. #items .. ")",
                items = items,
            })
        end
    end

    local rowWidth = (panel.markListScrollFrame and panel.markListScrollFrame:GetWidth() or 280) - 22

    local function AcquireHeader(idx)
        local h = recentHeaderPool[idx]
        if not h then
            h = CreateFrame("Button", nil, panel.recentContainer)
            h:SetHeight(30)
            local l = h:CreateTexture(nil, "BACKGROUND")
            l:SetAtlas("Options_ListExpand_Left", true); l:SetPoint("LEFT", 10, 0)
            local r = h:CreateTexture(nil, "BACKGROUND")
            r:SetAtlas("Options_ListExpand_Right", true); r:SetPoint("RIGHT", -10, 0)
            local m = h:CreateTexture(nil, "BACKGROUND")
            m:SetAtlas("_Options_ListExpand_Middle"); m:SetHorizTile(true)
            m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
            h.RightAtlas = r
            h.Label = h:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
            h.Label:SetPoint("LEFT", 30, -1); h.Label:SetPoint("RIGHT", -30, -1)
            h:SetScript("OnClick", function(self)
                if not self.groupKey then return end
                local d = ns.db()
                d.settings.listCollapsed = d.settings.listCollapsed or {}
                d.settings.listCollapsed[self.groupKey] = not d.settings.listCollapsed[self.groupKey]
                RefreshRecentList()
            end)
            recentHeaderPool[idx] = h
        end
        return h
    end

    local function AcquireEmpty(idx)
        local e = recentEmptyPool[idx]
        if not e then
            e = panel.recentContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            recentEmptyPool[idx] = e
        end
        return e
    end

    local headerIndex, emptyIndex = 0, 0
    for _, group in ipairs(groups) do
        headerIndex = headerIndex + 1
        local header = AcquireHeader(headerIndex)
        header.groupKey = group.key
        header.Label:SetText(group.title)
        header.RightAtlas:SetAtlas(collapsed[group.key] and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded", true)
        header:SetSize(rowWidth, 30)
        header:SetPoint("TOPLEFT", 0, yOffset)
        header:Show()
        yOffset = yOffset - 30

        if not collapsed[group.key] then
            if #group.items == 0 and group.empty then
                emptyIndex = emptyIndex + 1
                local e = AcquireEmpty(emptyIndex)
                e:SetText(group.empty)
                e:SetPoint("TOPLEFT", 12, yOffset)
                e:Show()
                yOffset = yOffset - 26
            else
            for _, data in ipairs(group.items) do
                shownCount = shownCount + 1

            -- 从对象池获取行，池子不够时才新建
            local row = recentRowPool[shownCount]
            if not row then
                row = CreateFrame("Frame", nil, panel.recentContainer)

                row.coordFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")

                -- 左侧可见性勾选框（WQT 同款 atlas，手动维护 checked 状态）
                row.chkBtn = CreateFrame("Button", nil, row)
                row.chkBtn:SetSize(16, 16)
                row.chkBtn:SetPoint("LEFT", row, "LEFT", 2, 0)
                row.chkBtn.tex = row.chkBtn:CreateTexture(nil, "ARTWORK")
                row.chkBtn.tex:SetAllPoints()

                -- 右侧收藏星标按钮：ReputationStar 2x2 图集裁单象限（BDmap.lua:1906/1958）
                row.starBtn = CreateFrame("Button", nil, row)
                row.starBtn:SetSize(20, 20)
                row.starBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                row.starTex = row.starBtn:CreateTexture(nil, "OVERLAY")
                row.starTex:SetAllPoints()
                row.starTex:SetTexture("Interface\\Common\\ReputationStar")

                row.iconTex = row:CreateTexture(nil, "ARTWORK")
                row.iconTex:SetSize(18, 18)
                row.iconTex:SetPoint("LEFT", row, "LEFT", 24, 0)
                row.iconTex:Hide()
                row.titleFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.titleFS:SetPoint("LEFT", row, "LEFT", 24, 0)
                row.titleFS:SetJustifyH("LEFT")
                row.titleFS:SetWordWrap(false)
                row.btn = CreateFrame("Button", nil, row)
                row.btn:SetAllPoints()
                row.btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row.btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
                row.btn:GetHighlightTexture():SetAlpha(0.2)

                -- 勾选框/星标按钮压在整行按钮之上，保证优先接收点击
                row.chkBtn:SetFrameLevel(row.btn:GetFrameLevel() + 1)
                row.starBtn:SetFrameLevel(row.btn:GetFrameLevel() + 1)

                row.chkBtn:SetScript("OnClick", function(self)
                    local d = self:GetParent().rowData
                    if not d then return end
                    local v = not self.checked
                    if d.isExternal then
                        ns.SetProviderVisibility(d, v)
                    else
                        d.isVisible = v
                        ns.RefreshAllPins()
                        RefreshRecentList()
                    end
                end)
                row.starBtn:SetScript("OnClick", function(self)
                    local d = self:GetParent().rowData
                    if not d then return end
                    if d.isExternal then
                        ns.SetProviderFavorite(d, not ns.IsProviderFavorited(d))
                    else
                        d.isFavorite = not d.isFavorite
                    end
                    RefreshRecentList()
                end)

                -- 加入对象池
                recentRowPool[shownCount] = row
            end

            -- 每次刷新：复用框架并更新排版与数据（rowWidth 用 RefreshRecentList 外层的统一值）
            row:SetSize(rowWidth, 26)
            row:SetPoint("TOPLEFT", 0, yOffset)
            row.rowData = data

            -- 左侧勾选框：外挂读子插件 visibility，本地读 isVisible
            local isVisible = data.isExternal and ns.IsProviderVisible(data) or (data.isVisible ~= false)
            row.chkBtn.checked = isVisible
            row.chkBtn.tex:SetAtlas(isVisible and "checkmark-minimal" or "checkbox-minimal")

            local x, y     = decodeCoord(data.coord)
            local coordStr = string.format("%.2f, %.2f", x*100, y*100)

            local c        = cloneColor(data.color)
            local rawTitle = (data.title ~= "" and data.title or nil)
            local hasIcon = data.icon ~= nil
            local singleLineTitle
            if hasIcon and rawTitle then
                singleLineTitle = rawTitle
            elseif hasIcon then
                singleLineTitle = ""        -- 纯图标点位，标题留空
            else
                singleLineTitle = rawTitle or L.MARK_UNNAMED
            end

            if singleLineTitle:find("\n") then
                singleLineTitle = singleLineTitle:gsub("\n.*", "") .. "..."
            end

            -- 左侧起始位置：为可见性勾选框留出 24px
            local leftOffset = 24

            -- 设置最左侧的图标（如果有图标，图标跟在边缘，文字跟在图标后面）
            if data.icon then
                ns.ApplyIconTexture(row.iconTex, data.icon, data.iconCrop)
                row.iconTex:SetAlpha(c.a or 1)
                row.iconTex:SetDesaturated(data.isGrayscale == true)
                row.iconTex:SetRotation(-math.rad(data.iconRotation or 0))
                row.iconTex:ClearAllPoints()
                row.iconTex:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
                row.iconTex:Show()
                leftOffset = leftOffset + 22
            else
                row.iconTex:Hide()
            end

            -- 组装右侧合并文本：[地图名 坐标]
            local mapPrefix = ""
            if data.mapID ~= currentMapID then
                local mapInfo = C_Map.GetMapInfo(data.mapID)
                local mapName = mapInfo and mapInfo.name or L.CROSS_MAP
                mapPrefix = "|cffaaaaaa" .. mapName .. " |r"
            end

            -- 右侧收藏星标：按钮可点击切换，坐标仍为其留出图标宽度的空位
            local isFav = data.isExternal and IsProviderFavorited(data) or (data.isFavorite == true)
            row.starBtn.checked = isFav
            row.starTex:SetTexCoord(isFav and 0 or 0.5, isFav and 0.5 or 1, 0, 0.5)

            -- 使用深灰色方括号包裹，内部地图灰白，坐标纯白。
            local rightMergedText = string.format("|cff777777[|r%s|cffffffff%s|r|cff777777]|r", mapPrefix, coordStr)
            row.coordFS:ClearAllPoints()
            row.coordFS:SetPoint("RIGHT", row.starBtn, "LEFT", -2, 0)
            row.coordFS:SetText(rightMergedText)
            row.coordFS:SetFont(STANDARD_TEXT_FONT, 13)

            -- 设置中间的标题：左边跟图标/边缘，右边撞在合并的坐标框上
            local hexColor   = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
            row.titleFS:SetText(hexColor .. singleLineTitle .. "|r")
            row.titleFS:SetAlpha(c.a or 1)
            row.titleFS:ClearAllPoints()
            row.titleFS:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            row.titleFS:SetPoint("RIGHT", row.coordFS, "LEFT", -1, 0)

            -- 鼠标悬停提示
            row.btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(data.title or L.MARK_UNNAMED, c.r, c.g, c.b)
                if data.note and data.note ~= "" then
                    GameTooltip:AddLine(data.note, 1, 1, 1, false)
                end
                GameTooltip:Show()
            end)
            row.btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- 点击事件
            row.btn:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    local nowMapID = WorldMapFrame:GetMapID()
                    if data.mapID ~= nowMapID then
                        WorldMapFrame:SetMapID(data.mapID)
                        -- 跨地图时先切换，再延迟触发高亮特效
                        if ns.PingPin then
                            C_Timer.After(0.1, function() ns.PingPin(data) end)
                        end
                    else
                        if ns.PingPin then ns.PingPin(data) end
                    end
                    if db.settings.leftClickEditMode then
                        -- 本地/外挂标记统一走主面板编辑模块，外挂字段由 OpenForEdit 置只读
                        ns.Panel.OpenForEdit(data)
                    end
                elseif button == "RightButton" then
                    local px, py = decodeCoord(data.coord)
                    -- 先判断当前地图是否支持导航
                    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(data.mapID) then
                        print("|cffff4444[ADE]|r " .. L.ERR_NAV_UNSUPPORTED)
                        return
                    end
                    if db.settings.useTomTom and TomTom and TomTom.AddWaypoint then
                        TomTom:AddWaypoint(data.mapID, px, py, {
                            title      = data.title,
                            persistent = false,
                            minimap    = true,
                            world      = true,
                            silent     = true,
                            from       = addonName,
                        })
                    else
                        local wp = UiMapPoint.CreateFromCoordinates(data.mapID, px, py)
                        if wp then
                            C_Map.SetUserWaypoint(wp)
                            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                            end
                        end
                    end
                end
            end)

            row:Show()
            yOffset = yOffset - 26
            end
            end
        end
    end

    -- 内容高度驱动 MinimalScrollBar 范围（12.x ScrollUtil 自动管理）
    panel.recentContainer:SetHeight(math.max(1, -yOffset))
    -- 空态已由「手动标记点」组的“暂无手动标记点”条目承担，隐藏旧的整体空提示
    if panel.emptyFrame then panel.emptyFrame:Hide() end
end


-- ── 辅助：获取当前编辑数据的实时索引（防止删除导致索引漂移）─────────────────

local function GetEditingIndex()
    if not panel or not panel.editingData then return nil end
    local db = ns.db()
    for i, marker in ipairs(db.markers) do
        if marker == panel.editingData then
            return i
        end
    end
    return nil
end

-- 表单值与数据包内置原值比较：color 按分量比，灰度把 nil 当 false，空串/nil/false 视为同义；
-- textSize 在数据包未提供该字段时与原 size（渲染回落基准）一致即视为未自定义
local function ExternalValueEqual(field, a, b, original)
    if field == "color" then
        if type(a) ~= "table" or type(b) ~= "table" then return a == b end
        local function alpha(c) return c.a == nil and 1 or c.a end
        return math.abs((a.r or 0) - (b.r or 0)) < 0.001
            and math.abs((a.g or 0) - (b.g or 0)) < 0.001
            and math.abs((a.b or 0) - (b.b or 0)) < 0.001
            and math.abs(alpha(a) - alpha(b)) < 0.001
    end
    if field == "isGrayscale" then return (a == true) == (b == true) end
    if field == "textSize" and b == nil and original then b = original.size end
    if a == nil or a == "" or a == false then a = nil end
    if b == nil or b == "" or b == false then b = nil end
    return a == b
end

-- 等于原值就删掉该字段覆写，只有真正不同才写入。
-- 否则点「更新标记」会把默认值又写成自定义，还原图标随即重新出现。
local function SyncExternalOverride(data, field, value, original)
    original = original or ns:GetProviderOriginalMark(data)
    if ExternalValueEqual(field, value, original and original[field], original) then
        ns.RemoveProviderMarkOverride(data, field)
    else
        ns.SetProviderMarkOverride(data, field, value)
    end
    data[field] = value
end

-- 「还原为数据包内置数据」图标：仅当正在编辑的外挂标记存在自定义覆写时显示
local function UpdateResetOverrideButton()
    if not resetOverrideBtn then return end
    local data = panel and panel.editingData
    resetOverrideBtn:SetShown(data ~= nil and data.isExternal == true and ns.HasProviderMarkOverrides(data))
end

-- 外挂标记的实时覆写写入：只写子插件 DB，主插件存档不落任何外挂自定义数据
local function WriteExternalOverride(field, value)
    local data = panel and panel.editingData
    if not data or not data.isExternal then return false end
    SyncExternalOverride(data, field, value)
    ns:RefreshExternal()
    RefreshMapPins()
    UpdateResetOverrideButton()
    return true
end

-- 重置表单（清空所有输入区域并恢复默认值）
local function ClearPanelForm()
    if not panel then return end
    panel.editingExternal = false
    -- 1. 清空基础数据和文本
    panel.editingData = nil
    UpdateResetOverrideButton()
    editBoxCoords:SetText("")
    editBoxTitle:SetText("")
    editBoxCoords:SetEnabled(true)
    editBoxTitle:SetEnabled(true)
    if btnDelete then btnDelete:SetEnabled(true) end
    editBoxNote:SetText("")
    editBoxNote.fullText = ""
    if editBoxNote.ellipsis then editBoxNote.ellipsis:Hide() end
    btnAdd:SetText(L.MARK_ADD_POINT)
    if panel.chkFav then panel.chkFav:SetChecked(false) end
    -- 2. 恢复默认颜色和尺寸
    local db = ns.db()
    local lastColor = db.settings.lastColor or { r = 0.2, g = 1, b = 0.73 }
    colorBtn.curColor = cloneColor(lastColor)
    if grayBtn then grayBtn:SetGray(false) end
    SyncPreviewStyle()
    sizeSlider:SetValue(DEFAULT_TEXT_SIZE)
    textSizeSlider:SetValue(db.settings.lastTextSize or DEFAULT_TEXT_SIZE)
    -- 3. 彻底清空 Plus 模块的图标数据（传 true）
    if ns.Plus and ns.Plus.ResetIconAndRotator then
        ns.Plus.ResetIconAndRotator(true)
    end
end


-- ── 创建主面板（右侧标签页内容）─────────────────────────────────────────

local function EnsurePanel(parent)
    if panel then return panel end
    panel = CreateFrame("Frame", "adeMapMark_WorldMapPanel", parent, "BackdropTemplate")
    panel:Hide()
    panel.editingData = nil
    panel.editingExternal = false

    -- 面板定位
    local ca = QuestMapFrame.ContentsAnchor
    if not ca then return panel end
    panel:SetPoint("TOPLEFT", ca, "TOPLEFT", 0, -29)
    panel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -22, 0)

    -- 背景纹理
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAtlas("QuestLog-main-background", true)
    bg:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -1)
    bg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 0)

    -- 边框
    local border = CreateFrame("Frame", nil, panel, "QuestLogBorderFrameTemplate")
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", panel, "TOPLEFT", -3, 7)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 3, -6)
    border:SetFrameLevel(panel:GetFrameLevel() + 2)
    border:EnableMouse(false)
    panel.Border = border

    -- 标题（对齐 WQT 设置界面标题样式：Game15Font_Shadow，边框上方居中）
    local title = panel:CreateFontString(nil, "OVERLAY", "Game15Font_Shadow")
    -- 本面板 border 相对 panel 下移 7px（TOPLEFT y=7），故 y 用 3 抵消，使标题与设置面板标题绝对位置一致
    title:SetPoint("BOTTOM", border, "TOP", -1, 3)
    title:SetText(L.PANEL_TITLE)
    panel.Title = title


    -- ── 图标大小 / 文本字体滑块 ───────────────────────────────────────────
    -- 原「尺寸」一个值同时驱动图标与文字，现拆成两个字段：size 只管图标（含小地图），
    -- textSize 只管大地图文字字号；旧数据没有 textSize 时渲染回落到 size，行为不变。

    local offsetY = -10  -- 首行控件起始 Y 偏移
    local offsetX = 15  -- 每行第一个控件 X 偏移

    local lIconSize = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lIconSize:SetPoint("TOPLEFT", offsetX, offsetY)
    lIconSize:SetText(L.MARK_ICON_SIZE)

    sizeSlider = CreateFrame("Slider", "adeMapMark_SizeSlider", panel, "OptionsSliderTemplate")
    panel.sizeSlider = sizeSlider  -- 暴露给 Plus 模块（Item 4：图标尺寸联动）
    sizeSlider:SetPoint("LEFT", lIconSize, "RIGHT", 4, 0)
    sizeSlider:SetWidth(160)
    sizeSlider:SetMinMaxValues(10, 120)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetValue(ns.db().settings.lastSize)
    _G[sizeSlider:GetName() .. "Low"]:SetText(L.SIZE_LOW)
    _G[sizeSlider:GetName() .. "High"]:SetText(L.SIZE_HIGH)

    -- 将滑块当前值文字移到滑块右侧
    local sizeText = _G[sizeSlider:GetName() .. "Text"]
    sizeText:ClearAllPoints()
    sizeText:SetPoint("LEFT", sizeSlider, "RIGHT", 20, 0)
    sizeText:SetText(sizeSlider:GetValue())

    -- 编辑模式下实时预览；非编辑模式下修改默认大小
    sizeSlider:SetScript("OnValueChanged", function(s, v)
        v = math.floor(v)
        _G[s:GetName() .. "Text"]:SetText(v)
        local db = ns.db()
        if panel.editingData then
            if panel.editingData.size ~= v then  -- 只有真正改变才刷新
                if not WriteExternalOverride("size", v) then
                    panel.editingData.size = v
                    RefreshMapPins()
                    local idx = GetEditingIndex()
                    if idx then CallPlus("UpdateMinimapPinStyle", idx) end
                end
            end
        else
            db.settings.lastSize = v
        end
    end)

    -- ── 文本字体滑块 ─────────────────────────────────────────────────────
    -- 与图标大小同一尺度（渲染仍乘 0.34*zoomAdj），只是独立作用于大地图文字。

    local lTextSize = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local lTextSizeY = -32  -- 控件 Y 偏移
    lTextSize:SetPoint("TOPLEFT", lIconSize, "TOPLEFT", 0, lTextSizeY)
    lTextSize:SetText(L.MARK_TEXT_SIZE)

    textSizeSlider = CreateFrame("Slider", "adeMapMark_TextSizeSlider", panel, "OptionsSliderTemplate")
    textSizeSlider:SetPoint("LEFT", lTextSize, "RIGHT", 4, 0)
    textSizeSlider:SetWidth(160)
    textSizeSlider:SetMinMaxValues(10, 120)
    textSizeSlider:SetValueStep(1)
    textSizeSlider:SetValue(ns.db().settings.lastTextSize or ns.db().settings.lastSize or DEFAULT_TEXT_SIZE)
    _G[textSizeSlider:GetName() .. "Low"]:SetText(L.SIZE_LOW)
    _G[textSizeSlider:GetName() .. "High"]:SetText(L.SIZE_HIGH)

    local textSizeText = _G[textSizeSlider:GetName() .. "Text"]
    textSizeText:ClearAllPoints()
    textSizeText:SetPoint("LEFT", textSizeSlider, "RIGHT", 20, 0)
    textSizeText:SetText(textSizeSlider:GetValue())

    textSizeSlider:SetScript("OnValueChanged", function(s, v)
        v = math.floor(v)
        _G[s:GetName() .. "Text"]:SetText(v)
        local db = ns.db()
        if panel.editingData then
            if (panel.editingData.textSize or panel.editingData.size) ~= v then
                if not WriteExternalOverride("textSize", v) then
                    panel.editingData.textSize = v
                    RefreshMapPins()
                end
            end
        else
            db.settings.lastTextSize = v
        end
    end)

    -- ── 坐标输入框 ───────────────────────────────────────────────────────

    local lCoords = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local lCoordsY = -34  -- 控件 Y 偏移
    lCoords:SetPoint("TOPLEFT", lTextSize, "TOPLEFT", 0, lCoordsY)
    lCoords:SetText(L.MARK_COORDS)

    editBoxCoords = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    editBoxCoords:SetSize(170, 20)
    editBoxCoords:SetPoint("LEFT", lCoords, "RIGHT", 24, 0)
    editBoxCoords:SetAutoFocus(false)
    editBoxCoords:SetMaxLetters(20)

    -- 空时显示占位提示文字
    editBoxCoords.hint = editBoxCoords:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    editBoxCoords.hint:SetPoint("LEFT", editBoxCoords, "LEFT", 15, 0)
    editBoxCoords.hint:SetText(L.COORD_HINT)
    editBoxCoords:SetScript("OnTextChanged", function(self)
        self.hint:SetShown(self:GetText() == "")
    end)

    -- ── 收藏星星按钮 ─────────────────────────────────────────────────────

    local chkFav = CreateFrame("Button", nil, panel)
    chkFav:SetSize(24, 24)
    chkFav:SetPoint("LEFT", editBoxCoords, "RIGHT", 18, 0)

    chkFav.tex = chkFav:CreateTexture(nil, "ARTWORK")
    chkFav.tex:SetAllPoints()
    chkFav.tex:SetTexture(REPUTATION_STAR)
    chkFav.tex:SetTexCoord(0.5, 1, 0, 0.5)  -- 默认空星

    -- 点击切换收藏状态并实时写入数据库（复用下方 SetChecked，保持星标纹理与状态一致）
    chkFav:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if panel and panel.editingData then
            if panel.editingData.isExternal then
                ns.SetProviderFavorite(panel.editingData, self.checked)
            else
                panel.editingData.isFavorite = self.checked
            end
            RefreshRecentList()
        end
    end)

    -- 外部设置收藏状态的方法
    function chkFav:SetChecked(val)
        self.checked = val
        if val then
            self.tex:SetTexCoord(0, 0.5, 0, 0.5)
        else
            self.tex:SetTexCoord(0.5, 1, 0, 0.5)
        end
    end
    function chkFav:GetChecked() return self.checked end

    panel.chkFav = chkFav

    -- ── 标题输入框 ───────────────────────────────────────────────────────

    local lTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local lTitleY = -27  -- 控件 Y 偏移
    lTitle:SetPoint("TOPLEFT", lCoords, "TOPLEFT", 0, lTitleY)
    lTitle:SetText(L.MARK_TITLE)

    -- 标题输入框背景
    local titleBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    titleBg:SetSize(178, 51)
    titleBg:SetPoint("TOPLEFT", lTitle, "TOPRIGHT", 18, 8)
    titleBg:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    titleBg:SetBackdropColor(0, 0, 0, 0.3)
    titleBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

    -- 标题输入框（支持最多 2 行）
    editBoxTitle = CreateFrame("EditBox", nil, titleBg)
    editBoxTitle:SetMultiLine(true)
    editBoxTitle:SetFontObject(ChatFontNormal)
    editBoxTitle:SetSpacing(3)
    editBoxTitle:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 6,  -4)
    editBoxTitle:SetPoint("BOTTOMRIGHT", titleBg, "BOTTOMRIGHT", -6,  4)
    editBoxTitle:SetMaxLetters(0)
    editBoxTitle:SetAutoFocus(false)
    LimitEditBoxLines(editBoxTitle, 2)   -- 限制最多 2 行

    -- ESC 只清焦点
    editBoxTitle:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- ── 图标选择器（由 adeMapMarkPlus 提供）──────────────────────────────────
    CallPlus("SetupIconSelector", panel, titleBg)

    -- 放大/缩小按钮
    local btnExpand = CreateFrame("Frame", nil, panel, "MaximizeMinimizeButtonFrameTemplate")
    btnExpand:SetSize(22, 22)
    btnExpand:SetPoint("TOP", lTitle, "BOTTOM", 0, -4)
    panel.btnExpand = btnExpand

    -- 根据展开状态切换最大化/最小化按钮的显示
    local function UpdateVisuals(isExpanded)
        if isExpanded then
            btnExpand.MaximizeButton:Hide()
            btnExpand.MinimizeButton:Show()
        else
            btnExpand.MaximizeButton:Show()
            btnExpand.MinimizeButton:Hide()
        end
    end

    btnExpand.MaximizeButton:SetScript("OnClick", function()
        ShowBigNoteEditor(editBoxTitle, editBoxNote)
        UpdateVisuals(true)
    end)
    btnExpand.MinimizeButton:SetScript("OnClick", function()
        if bigNotePopup then bigNotePopup:Hide() end
        UpdateVisuals(false)
    end)

    UpdateVisuals(false)

    -- ── 备注输入框 ───────────────────────────────────────────────────────

    local lNote = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local lNoteY = -47  -- 控件 Y 偏移
    lNote:SetPoint("TOPLEFT", lTitle, "TOPLEFT", 0, lNoteY)
    lNote:SetText(L.MARK_NOTE)

    editBoxNote = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    editBoxNote:SetSize(220, 20)
    editBoxNote:SetPoint("LEFT", lNote, "RIGHT", 24, 0)
    editBoxNote:SetAutoFocus(false)
    editBoxNote.fullText = ""   -- 保存完整文本（含换行）

    -- 测量器（用于计算文本溢出）
    editBoxNote.measureFS = panel:CreateFontString(nil, "OVERLAY")
    editBoxNote.measureFS:Hide()

    -- 文本改变时实时检测是否需要显示省略号
    editBoxNote:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self.fullText = self:GetText() end
        local font, height, flags = self:GetFont()
        if font then
            self.measureFS:SetFont(font, height, flags)
        end
        local displayText = self:GetText() or ""
        self.measureFS:SetText(displayText)
        local textWidth = self.measureFS:GetStringWidth()
        if self.ellipsis then
            if textWidth > 200 then
                self.ellipsis:Show()
            else
                self.ellipsis:Hide()
            end
        end
    end)

    -- 带换行的备注自动弹出大编辑框
    editBoxNote:SetScript("OnEditFocusGained", function(self)
        if self.fullText and self.fullText:find("\n") then
            self:ClearFocus()
            ShowBigNoteEditor(editBoxTitle, self)
            return
        end
    end)

    -- 省略号指示
    local ellipsisText = editBoxNote:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ellipsisText:SetPoint("RIGHT", editBoxNote, "RIGHT", 15, 0)
    ellipsisText:SetText("...")
    ellipsisText:SetTextColor(0.9, 0.9, 0.9)
    ellipsisText:Hide()
    editBoxNote.ellipsis = ellipsisText

    -- 立即触发一次测量，初始化省略号状态
    editBoxNote:GetScript("OnTextChanged")(editBoxNote)

    -- ── 调色选择器 ─────────────────────────────────────────────────────────

    -- 调色行：必须锚到面板「顶部」偏移。误用 LEFT 时 y 变成相对垂直中心，整行会下沉与清单重叠。
    local lColor = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local lColorY = -26  -- 控件 Y 偏移
    lColor:SetText(L.MARK_COLOR_LABEL)
    -- 左边缘固定 15，与坐标/标题/备注标签同一垂直列（此前 RIGHT 锚到色块左侧，左边缘随字宽浮动）
    lColor:SetPoint("TOPLEFT", lNote, "TOPLEFT", 0, lColorY)

    -- 调色按钮：与设置页颜色控件一致（UIMenuButtonStretchTemplate + LootBanner-IconGlow）
    colorBtn = CreateFrame("Button", nil, panel, "UIMenuButtonStretchTemplate")
    colorBtn:SetSize(26, 26)
    colorBtn:SetPoint("LEFT", lColor, "RIGHT", 20, 0)
    colorBtn.tex = colorBtn:CreateTexture(nil, "ARTWORK", nil, 2)
    colorBtn.tex:SetAtlas("LootBanner-IconGlow")
    colorBtn.tex:SetSize(14, 14)
    colorBtn.tex:SetPoint("CENTER")
    local lastColor = ns.db().settings.lastColor or { r = 0.2, g = 1, b = 0.73 }
    colorBtn.curColor = cloneColor(lastColor)
    colorBtn.tex:SetColorTexture(colorBtn.curColor.r, colorBtn.curColor.g, colorBtn.curColor.b, colorBtn.curColor.a)

    -- 打开取色器，实时写入颜色
    colorBtn:SetScript("OnClick", function()
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = colorBtn.curColor.r,
                g = colorBtn.curColor.g,
                b = colorBtn.curColor.b,
                opacity = colorBtn.curColor.a or 1, -- 传入当前透明度
                hasOpacity = true,                  -- 激活原生的透明度调节滑块
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha() -- 获取回调的透明度
                    colorBtn.curColor = { r = r, g = g, b = b, a = a }
                    colorBtn.tex:SetColorTexture(r, g, b, a)
                    SyncPreviewStyle()
                    local db = ns.db()
                    if panel.editingData then
                        local c = { r = r, g = g, b = b, a = a }
                        if not WriteExternalOverride("color", c) then
                            panel.editingData.color = c
                            RefreshMapPins()
                            local idx = GetEditingIndex()
                            if idx then CallPlus("UpdateMinimapPinStyle", idx) end
                        end
                    else
                        db.settings.lastColor = { r = r, g = g, b = b, a = a }
                    end
                end,
            })
            grayBtn:Show()
        end
    end)

    -- 还原图标：ADE v6.5 设置页同款 common-icon-undo（ade_UIKit/Widget/OptionRow.lua:243），
    -- 仅当外挂标记存在自定义覆写时显示；点击清除覆写，恢复数据包内置数据。
    resetOverrideBtn = CreateFrame("Button", nil, panel)
    resetOverrideBtn:SetSize(20, 20)
    -- 与 26px 色块垂直居中对齐；硬编码 TOPLEFT 的 y 会让 20px 图标比同排 25px 按钮偏上
    resetOverrideBtn:SetPoint("LEFT", colorBtn, "RIGHT", 4, 0)
    resetOverrideBtn:SetNormalAtlas("common-icon-undo")
    resetOverrideBtn:SetHighlightAtlas("common-icon-undo", "ADD")
    resetOverrideBtn:Hide()
    resetOverrideBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.RESET_PROVIDER_OVERRIDE)
        GameTooltip:Show()
    end)
    resetOverrideBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resetOverrideBtn:SetScript("OnClick", function()
        local data = panel and panel.editingData
        if not data or not data.isExternal then return end
        local key = ns.GetProviderFavKey(data)
        ns.ClearProviderMarkOverrides(data)
        ns:RefreshExternal()
        RefreshMapPins()
        RefreshRecentList()
        -- 覆写已清，重新取一份数据包原值回填表单（旧 data 仍带着自定义字段）
        local restored
        for _, m in ipairs(ns:GetProviderMarkers(true)) do
            if ns.GetProviderFavKey(m) == key then restored = m; break end
        end
        if restored then ns.Panel.OpenForEdit(restored) else ClearPanelForm() end
        UpdateResetOverrideButton()
    end)

    -- ── 灰度切换复选框（动态挂载至颜色选择器） ────────────────────────────────

    grayBtn = CreateFrame("CheckButton", "adeMapMark_GrayCheck", ColorPickerFrame, "InterfaceOptionsCheckButtonTemplate")
    -- 吸附在颜色选择器右下角外侧
    grayBtn:SetPoint("BOTTOMLEFT", ColorPickerFrame, "BOTTOMRIGHT", -102, 80)
    grayBtn.Text:SetText(L.MARK_GRAYSCALE_BTN)
    grayBtn.Text:SetTextColor(1, 1, 1)
    grayBtn:Hide() -- 默认必须隐藏

    grayBtn.isGray = false
    function grayBtn:SetGray(val)
        self.isGray = val
        self:SetChecked(val)
    end
    grayBtn:SetGray(false)

    grayBtn:SetScript("OnClick", function(self)
        self.isGray = self:GetChecked()
        SyncPreviewStyle()
        if panel.editingData then
            if not WriteExternalOverride("isGrayscale", self.isGray) then
                panel.editingData.isGrayscale = self.isGray
                RefreshMapPins()
                local idx = GetEditingIndex()
                if idx then CallPlus("UpdateMinimapPinStyle", idx) end
            end
        end
    end)

    -- 核心安全防御：原生调色板关闭时，立刻隐藏复选框，防止污染其他插件或系统的颜色设置
    ColorPickerFrame:HookScript("OnHide", function()
        grayBtn:Hide()
    end)

    -- ── 添加/更新按钮 ────────────────────────────────────────────────────

    btnAdd = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnAdd:SetSize(90, 25)
    btnAdd:SetPoint("LEFT", colorBtn, "RIGHT", 46, 0)
    btnAdd:SetText(L.MARK_ADD_POINT)

    btnAdd:SetScript("OnClick", function()
        -- 外挂标记：只把可自定义字段写回子插件 DB，坐标/标题保持数据包原值
        if panel and panel.editingExternal and panel.editingData then
            local data = panel.editingData
            local overrides = {
                note = (editBoxNote.fullText or editBoxNote:GetText() or ""):gsub("||", "|"),
                color = cloneColor(colorBtn.curColor),
                size = math.floor(sizeSlider:GetValue()),
                textSize = math.floor(textSizeSlider:GetValue()),
                isGrayscale = grayBtn and grayBtn.isGray or false,
            }
            CallPlus("OnBeforeSaveMarker", overrides, panel)
            overrides.icon = panel.selectedIcon
            local original = ns:GetProviderOriginalMark(data)
            for field, value in pairs(overrides) do
                if field ~= "title" then
                    SyncExternalOverride(data, field, value, original)
                end
            end
            if panel.chkFav then ns.SetProviderFavorite(data, panel.chkFav:GetChecked()) end
            ns:RefreshExternal()
            RefreshMapPins()
            ClearPanelForm()
            editBoxTitle:ClearFocus()
            RefreshRecentList()
            return
        end
        local mapID = WorldMapFrame:GetMapID()
        if not mapID then return end

        -- 解析坐标（为空则取当前玩家位置）
        local targetX, targetY
        local coordStr = editBoxCoords:GetText()
        if coordStr == "" then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if not pos then
                print("|cffff4444[ADE]|r " .. L.ERR_NO_POSITION)
                return
            end
            targetX, targetY = pos:GetXY()
        else
            targetX, targetY = parseCoordInput(coordStr)
            if not targetX or not targetY then
                print("|cffff4444[ADE]|r " .. L.ERR_COORD_FORMAT)
                return
            end
        end

        local titleText  = editBoxTitle:GetText()
        local titleRaw   = titleText:match("^%s*$") and "" or titleText
        local title      = titleRaw:gsub("||", "|")
        local noteText   = editBoxNote.fullText or editBoxNote:GetText()
        local noteRaw    = noteText:match("^%s*$") and "" or noteText
        local note       = noteRaw:gsub("||", "|")
        local isFav      = panel.chkFav and panel.chkFav:GetChecked() or false
        local finalTitle = (title ~= "") and title or L.MARK_UNNAMED
        local newData    = {
            mapID      = mapID,
            coord      = encodeCoord(targetX, targetY),
            title      = finalTitle,
            note       = note,
            color      = cloneColor(colorBtn.curColor),
            size       = math.floor(sizeSlider:GetValue()),
            textSize   = math.floor(textSizeSlider:GetValue()),
            isFavorite = isFav,
            isVisible  = true,
            isGrayscale = grayBtn and grayBtn.isGray or false,
        }
        CallPlus("OnBeforeSaveMarker", newData, panel)

        local db      = ns.db()
        local editIdx = GetEditingIndex()
        if editIdx then
            -- 更新模式：覆盖现有点位
            db.markers[editIdx] = newData
            panel.editingData = nil
            btnAdd:SetText(L.MARK_ADD_POINT)
        else
            -- 添加模式：插入新点位
            table.insert(db.markers, newData)
            db.settings.lastColor = cloneColor(colorBtn.curColor)
            db.settings.lastSize  = math.floor(sizeSlider:GetValue())
            db.settings.lastTextSize = math.floor(textSizeSlider:GetValue())
        end

        -- 清空表单
        ClearPanelForm()
        editBoxTitle:ClearFocus()

        RefreshAllPins()
        RefreshRecentList()
    end)

    -- ── 删除按钮 ─────────────────────────────────────────────────────────

    btnDelete = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnDelete:SetSize(60, 25)
    btnDelete:SetPoint("LEFT", btnAdd, "RIGHT", 4, 0)
    btnDelete:SetText(L.MARK_DELETE)

    btnDelete:SetScript("OnClick", function()
        if panel and panel.editingExternal then return end
        local editIdx = GetEditingIndex()
        if not editIdx then
            print("|cffffff00[ADE]|r " .. L.ERR_NO_SELECTION)
            return
        end

        local db          = ns.db()
        local deletedData = db.markers[editIdx]
        if deletedData and not deletedData.isExternal then
            table.remove(db.markers, editIdx)
            ClearPanelForm()
            RefreshAllPins()
            RefreshRecentList()
        end
    end)

	local markListY = offsetY + lTextSizeY + lCoordsY + lTitleY + lNoteY + lColorY * 2
    -- 调色行与清单之间的分隔线：主题色 #EEE4AE 亮线 + 下方暗衬线，深色背景上清晰可见
    local editDivider = panel:CreateTexture(nil, "ARTWORK")
    editDivider:SetColorTexture(0.9333, 0.8941, 0.6824, 0.9)
    editDivider:SetHeight(1)
    editDivider:SetPoint("TOPLEFT", 8, markListY)
    editDivider:SetPoint("TOPRIGHT", -8, markListY)

    local editDividerShadow = panel:CreateTexture(nil, "ARTWORK")
    editDividerShadow:SetColorTexture(0, 0, 0, 0.8)
    editDividerShadow:SetHeight(1)
    editDividerShadow:SetPoint("TOPLEFT", 8, markListY - 2)
    editDividerShadow:SetPoint("TOPRIGHT", -8, markListY - 2)

    -- 点击地图空白处清空输入框焦点
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnMouseDown", function()
            if editBoxTitle  then editBoxTitle:ClearFocus()  end
            if editBoxNote   then editBoxNote:ClearFocus()   end
            if editBoxCoords then editBoxCoords:ClearFocus() end
            if bigNotePopup and bigNotePopup.noteBox then bigNotePopup.noteBox:ClearFocus() end
        end)
    end

    -- ── 清单容器（收藏 + 手动标记 + 各数据包分组）─────────────────────────────
    -- 依据 SecureUIPanelTemplates.lua:26-27：ScrollFrame_OnLoad 把 ScrollBar 锚在
    -- TOPLEFT@TOPRIGHT(left, top) / BOTTOMLEFT@BOTTOMRIGHT(left, bottom)，left 是滚动条
    -- **左边缘**偏移；ScrollDefine.lua:2 的默认 left=+6 表示滚动条在滚动框**外侧**。
    -- r015 依赖 CreateFrame 的 keyValues 表设置 scrollBarX，实测滚动条仍落在外侧压住内边框，
    -- 故这里显式按模板同款锚点重设，位置与长度都可控。
    local markListScrollFrame = CreateFrame("ScrollFrame", "adeMapMark_MarkListScrollFrame", panel, "ScrollFrameTemplate")
    markListScrollFrame:SetPoint("TOPLEFT",     0, markListY - 6)
    markListScrollFrame:SetPoint("BOTTOMRIGHT", 4, 10)

    local recentContainer = CreateFrame("Frame", nil, markListScrollFrame)
    recentContainer:SetWidth(markListScrollFrame:GetWidth() or 280)
    recentContainer:SetHeight(1)
    markListScrollFrame:SetScrollChild(recentContainer)
    ScrollUtil.InitScrollFrameWithScrollBar(markListScrollFrame, markListScrollFrame.ScrollBar)

    -- 左边缘内移 20px（MinimalScrollBar.xml:16 宽 8 → 右边缘距滚动框右边缘 12px，
    -- 再距面板右边 8px，共 20px）：不与装饰内边框重叠，也不像 r014 那样过度偏左；
    -- 上下各留 2px，滚动条贯穿清单全高。
    do
        local bar = markListScrollFrame.ScrollBar
        if bar then
            if bar.SetHideIfUnscrollable then bar:SetHideIfUnscrollable(true) end
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", markListScrollFrame, "TOPRIGHT", -20, -2)
            bar:SetPoint("BOTTOMLEFT", markListScrollFrame, "BOTTOMRIGHT", -20, -2)
        end
    end

    markListScrollFrame:SetScript("OnSizeChanged", function(self, w)
        recentContainer:SetWidth(math.max(80, w))
        -- 布局稳定后按真实宽度重排，否则行宽停留在首次刷新的旧值，右侧会出现大片空白
        if w < 80 then return end
        if panel.lastListWidth and math.abs(panel.lastListWidth - w) <= 1 then return end
        panel.lastListWidth = w
        RefreshRecentList()
    end)

    panel.recentContainer     = recentContainer
    panel.markListScrollFrame = markListScrollFrame
    panel.markListScrollBar   = markListScrollFrame.ScrollBar

    -- 空状态提示（无收藏点时显示）
    local emptyFrame = CreateFrame("Frame", nil, recentContainer)
    emptyFrame:SetAllPoints()
    local emptyText = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("TOP", 0, -50)
    emptyText:SetText(L.EMPTY_LIST_TEXT)
    emptyFrame:Hide()
    panel.emptyFrame = emptyFrame

    -- ── 面板显示/隐藏事件 ────────────────────────────────────────────────

    panel:SetScript("OnShow", RefreshRecentList)

    panel:SetScript("OnHide", function()
        -- 切页签/关地图都要执行：防卡死、收起下拉菜单（传 false 不清数据）
        if ns.Plus and ns.Plus.ResetIconAndRotator then
            ns.Plus.ResetIconAndRotator(false)
        end
        if editBoxTitle  then editBoxTitle:ClearFocus()  end
        if editBoxNote   then editBoxNote:ClearFocus()   end
        if editBoxCoords then editBoxCoords:ClearFocus() end
        if bigNotePopup and bigNotePopup.noteBox then bigNotePopup.noteBox:ClearFocus() end
        if grayBtn then grayBtn:Hide() end
        -- 只有彻底关闭地图时才大扫除
        if not WorldMapFrame:IsVisible() then
            ClearPanelForm()
        end
    end)

    -- ── 地图点击交互 ─────────────────────────────────────────────────────

    if WorldMapFrame.ScrollContainer then
        local lastMapClickTime = 0

        WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function(self, button)
            if button ~= "LeftButton" or not panel or not panel:IsShown() then return end
            local mapID = WorldMapFrame:GetMapID()
            if not mapID then return end

            local currentTime = GetTime()
            if currentTime - lastMapClickTime < 0.3 then
                -- 双击：退出编辑模式，准备添加新点位
                local relX, relY = self:GetNormalizedCursorPosition()
                relX = math.max(0, math.min(1, relX or 0))
                relY = math.max(0, math.min(1, relY or 0))

                ClearPanelForm()  -- 含灰度、颜色、图标、收藏等所有重置
                editBoxCoords:SetText(string.format("%.2f %.2f", relX * 100, relY * 100))

                editBoxTitle:SetFocus()
                lastMapClickTime = 0
            else
                -- 单击：仅更新坐标输入框
                local relX, relY = self:GetNormalizedCursorPosition()
                relX = math.max(0, math.min(1, relX or 0))
                relY = math.max(0, math.min(1, relY or 0))
                editBoxCoords:SetText(string.format("%.2f %.2f", relX * 100, relY * 100))
                lastMapClickTime = currentTime
            end
        end)
    end

    return panel
end


-- ============================================================================
-- 初始化事件与地图钩子
-- ============================================================================

-- 监听插件加载完成，初始化面板、标签页和数据
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    -- 阶段 2：Blizzard_WorldMap 就绪 → Tab 与面板由 ns.SetupWorldMapTab（Settings.lua）统一接入
    if WorldMapFrame and not panel then
        local mainPanel = EnsurePanel(QuestMapFrame)

        hooksecurefunc(WorldMapFrame, "SetMapID", function()
            if panel and panel:IsShown() then RefreshRecentList() end
        end)

        WorldMapFrame:AddDataProvider(adeMapMarkDataProvider)

        -- 每次打开世界地图都重新同步外挂数据包（确保注册晚于地图初始化时也能生效）
        WorldMapFrame:HookScript("OnShow", function()
            C_Timer.After(0, function() ns:RefreshExternal() end)
        end)
        ns:RefreshExternal()

        -- LibWorldMapTabs 托管 Tab + 双 panel（计划 §4.3/§4.4）
        if ns.SetupWorldMapTab then ns.SetupWorldMapTab(mainPanel) end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- 说明：跨地图的小地图重建由 HereBeDragons-Pins 自身的 PlayerZoneChanged 回调处理，
-- 大地图 pin 由 Blizzard 的 OnMapChanged 刷新；此处无需再注册聚合回调。


-- ============================================================================
-- 左键编辑入口（供 WorldMapPin 调用）
-- ============================================================================

ns.Panel = ns.Panel or {}
ns.RefreshRecentList = function() RefreshRecentList() end
function ns.Panel.OpenForEdit(data)
    if not data or not panel then return end
    local isExternal = data.isExternal == true
    panel.editingExternal = isExternal
    local px, py = decodeCoord(data.coord)
    editBoxCoords:SetText(string.format("%.2f %.2f", px * 100, py * 100))
    editBoxTitle:SetText(data.title or "")
    -- 外挂标记的坐标/标题来自数据包：只显示，禁用输入
    editBoxCoords:SetEnabled(not isExternal)
    editBoxTitle:SetEnabled(not isExternal)
    editBoxCoords:ClearFocus()
    editBoxTitle:ClearFocus()
    editBoxNote.fullText = data.note or ""
    editBoxNote:SetText(GetDisplayNote(data.note))
    editBoxNote:SetCursorPosition(0)
    panel.editingData = data
    sizeSlider:SetValue(data.size or ns.db().settings.lastSize)
    textSizeSlider:SetValue(data.textSize or data.size or ns.db().settings.lastTextSize or ns.db().settings.lastSize)
    colorBtn.curColor = cloneColor(data.color)
    btnAdd:SetText(isExternal and L.MARK_UPDATE_EXTERNAL or L.MARK_UPDATE_POINT)
    if btnDelete then btnDelete:SetEnabled(not isExternal) end
    if grayBtn then grayBtn:SetGray(data.isGrayscale == true) end
    CallPlus("OnPinLeftClick", data, panel)
    SyncPreviewStyle()
    local fav = isExternal and ns.IsProviderFavorited(data) or (data.isFavorite == true)
    if panel.chkFav then panel.chkFav:SetChecked(fav) end
    UpdateResetOverrideButton()
end

-- ============================================================================
-- 快捷标记（供 /amm 调用，计划 §4.5）
-- ============================================================================

function ns.QuickMark(msg)
    local title = strtrim(msg or "")
    local mapID, x, y = GetCurrentPlayerMapCoord()
    if not mapID or not x or not y then
        ns.Print("|cffff4444" .. L.ERR_QUICKMARK_FAIL .. "|r")
        return
    end
    local db = ns.db()
    local finalTitle = (title ~= "") and title or L.MARK_DEFAULT_TITLE
    tinsert(db.markers, {
        mapID = mapID, coord = encodeCoord(x, y), title = finalTitle, note = "",
        color = cloneColor(db.settings.lastColor), size = ns.DEFAULT_TEXT_SIZE,
        textSize = ns.DEFAULT_TEXT_SIZE,
        isFavorite = false, isVisible = true, icon = nil,
    })
    ns.Print("|cff88ff88" .. string.format(L.QUICKMARK_OK, finalTitle, x * 100, y * 100) .. "|r")
    RefreshAllPins()
    if panel and panel:IsShown() then RefreshRecentList() end
    CallPlus("ResetIconAndRotator")
end


-- ============================================================================
-- 数据导入/导出（通过 /amm io 开启面板）
-- ============================================================================

-- 字符串转义（防止标题/备注中的特殊字符破坏数据结构）
-- 转义规则：% → %p，; → %s，换行 → %n，| → %l
local function EncodeString(str)
    if not str then return "" end
    return tostring(str):gsub("%%", "%%p"):gsub(";", "%%s"):gsub("\n", "%%n"):gsub("|", "%%l")
end

-- 字符串反转义
local function DecodeString(str)
    if not str or str == "" then return nil end
    return str:gsub("%%l", "|"):gsub("%%n", "\n"):gsub("%%s", ";"):gsub("%%p", "%%")
end

-- 将当前数据库标记序列化为单行字符串
local function SerializeMarkers()
    local db      = ns.db()
    local markers = db.markers or {}
    local lines   = {}

    for _, m in ipairs(markers) do
        local r   = m.color and m.color.r or 0.2
        local g   = m.color and m.color.g or 1
        local b   = m.color and m.color.b or 0.73
        local a   = m.color and m.color.a or 1
        local isF = m.isFavorite and "1" or "0"
        local isE = m.isVisible ~= false and "1" or "0"

        -- 数据格式
        local str = string.format("%s;%s;%s;%s;%.3f;%.3f;%.3f;%.3f;%s;%s;%s;%s;%s;%.2f;%s;%s",
            tostring(m.mapID or ""),
            tostring(m.coord or ""),
            EncodeString(m.title),
            EncodeString(m.note),
            r, g, b, a,
            tostring(m.size or 100),
            isF, isE,
            EncodeString(m.icon),
            string.format("%.0f", math.deg(m.iconRotation or 0)),
            m.iconCrop or 1.0,
            EncodeString(CallPlus("FindIconName", m.icon) or ""),
            m.isGrayscale and "1" or "0"
        )
        table.insert(lines, str)
    end
    local markerStr = "!BDM!" .. table.concat(lines, "|")

    -- 遍历"游戏内提取"抽屉，单独打包图标库
    local iconLines = {}
    for _, ic in ipairs(db.gameInIcons or {}) do
        table.insert(iconLines, EncodeString(ic.name) .. ";" .. tostring(ic.tex))
    end

    -- 如果抽屉里有图标，在代码尾部加上 !ICO! 标识
    if #iconLines > 0 then
        return markerStr .. "!ICO!" .. table.concat(iconLines, "|")
    else
        return markerStr
    end
end

-- 将传入字符串解析为标记数据数组
local function DeserializeMarkers(str)
    if not str or not str:match("^!BDM!") then return nil, nil end

    -- 用 !ICO! 把点位数据和图标库数据切开
    local markerPart, iconPart = str:match("^!BDM!(.*)!ICO!(.*)$")
    if not markerPart then
        markerPart = str:match("^!BDM!(.*)$") -- 兼容旧版(没带图标库的代码)
    end

    local newMarkers = {}
    if markerPart then
        for record in markerPart:gmatch("[^|]+") do
            local mapID, coord, t, n, r, g, b, a, size, isF, isE, ic, rot, crop, gameinIconName, gray = strsplit(";", record)
            local mID = tonumber(mapID)
            local co  = tonumber(coord)
            if mID and co then
                local iconStr = DecodeString(ic)
                table.insert(newMarkers, {
                    mapID        = mID,
                    coord        = co,
                    title        = DecodeString(t),
                    note         = DecodeString(n),
                    color        = { r = tonumber(r) or 0.2, g = tonumber(g) or 1, b = tonumber(b) or 0.73, a = tonumber(a) or 1 },
                    size         = tonumber(size) or 100,
                    isFavorite   = (isF == "1"),
                    isVisible    = (isE == "1"),
                    icon         = tonumber(iconStr) or iconStr,
                    iconRotation = math.rad(tonumber(rot) or 0),
                    iconCrop     = tonumber(crop) or 1.0,
                    gameinIconName = DecodeString(gameinIconName),
                    isGrayscale  = (gray == "1"),
                })
            end
        end
    end

    -- 解析附加的独立图标库数据
    local newIcons = {}
    if iconPart then
        for record in iconPart:gmatch("[^|]+") do
            local nameStr, texStr = strsplit(";", record)
            local tex = tonumber(texStr) or texStr
            if nameStr and tex then
                table.insert(newIcons, { name = DecodeString(nameStr), tex = tex })
            end
        end
    end

    return newMarkers, newIcons
end


-- ── 导入导出 UI 面板 ───────────────────────────────────────────────────────────
local bdmapIOFrame
local function ShowIOFrame()
    if not bdmapIOFrame then
        -- 基础面板设定
        bdmapIOFrame = CreateFrame("Frame", "adeMapMark_IOFrame", UIParent, "BackdropTemplate")
        bdmapIOFrame:SetSize(550, 520)
        bdmapIOFrame:SetPoint("CENTER")
        bdmapIOFrame:SetFrameStrata("DIALOG")
        bdmapIOFrame:SetMovable(true)
        bdmapIOFrame:EnableMouse(true)
        bdmapIOFrame:RegisterForDrag("LeftButton")
        bdmapIOFrame:SetScript("OnDragStart", bdmapIOFrame.StartMoving)
        bdmapIOFrame:SetScript("OnDragStop", bdmapIOFrame.StopMovingOrSizing)
        tinsert(UISpecialFrames, "adeMapMark_IOFrame")

        -- 背景与边框
        bdmapIOFrame:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        bdmapIOFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)

        -- 标题与提示语
        local title = bdmapIOFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText(L.IO_TITLE)

		local hint = bdmapIOFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", bdmapIOFrame, "TOPLEFT", 20, -35)
        hint:SetJustifyH("LEFT")
        hint:SetText(L.IO_HINT)
        hint:SetTextColor(0.8, 0.8, 0.8)

        local closeBtn = CreateFrame("Button", nil, bdmapIOFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", bdmapIOFrame, "TOPRIGHT", -5, -5)

        -- 输入框背景区
        local inputBg = CreateFrame("Frame", nil, bdmapIOFrame, "BackdropTemplate")
        inputBg:SetPoint("TOPLEFT", 15, -70)
        inputBg:SetPoint("BOTTOMRIGHT", -15, 60)
        inputBg:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 14,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        inputBg:SetBackdropColor(0, 0, 0, 0.6)

        -- 滚动框
        local sf = CreateFrame("ScrollFrame", "adeMapMark_IOScroll", inputBg, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -8)
        sf:SetPoint("BOTTOMRIGHT", -28, 8)

        -- 多行文本输入框
        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(sf:GetWidth() - 5)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        sf:SetScrollChild(eb)
        bdmapIOFrame.editBox = eb

        -- 按钮：导入数据
        local btnImport = CreateFrame("Button", nil, bdmapIOFrame, "UIPanelButtonTemplate")
        btnImport:SetSize(140, 30)
        btnImport:SetPoint("BOTTOMRIGHT", bdmapIOFrame, "BOTTOM", -15, 15)
        btnImport:SetText(L.IO_IMPORT_BTN)
        btnImport:SetScript("OnClick", function()
            local str = eb:GetText()
            local newMarkers, newIcons = DeserializeMarkers(str)
            if not newMarkers then
                print("|cffff4444[ADE]|r " .. L.IO_ERR_FORMAT)
                return
            end

            local db = ns.db()

            -- 1. 纯粹处理点位 (不干涉抽屉)
            local existing = {}
            for _, m in ipairs(db.markers) do
                existing[m.mapID .. "_" .. m.coord] = true
            end

            local addCount = 0
            for _, m in ipairs(newMarkers) do
                if not existing[m.mapID .. "_" .. m.coord] then
                    m.gameinIconName = nil -- 清理掉没用的临时变量
                    table.insert(db.markers, m)
                    addCount = addCount + 1
                end
            end
            -- 2. 纯粹处理抽屉图标 (只处理 !ICO! 里的数据)
            local iconCount = 0
            if newIcons and #newIcons > 0 then
                db.gameInIcons = db.gameInIcons or {}
                for _, newIc in ipairs(newIcons) do
                    local isDuplicate = false
                    -- 认脸又认名，完全一致才算重复
                    for _, ci in ipairs(db.gameInIcons) do
                        if ci.tex == newIc.tex and ci.name == newIc.name then
                            isDuplicate = true
                            break
                        end
                    end
                    if not isDuplicate then
                        table.insert(db.gameInIcons, { name = newIc.name, tex = newIc.tex })
                        iconCount = iconCount + 1
                    end
                end
            end
            -- 3. 收尾与刷新
            if addCount > 0 or iconCount > 0 then
                print("|cff88ff88[ADE]|r " .. string.format(L.IO_DONE, addCount, iconCount))
            else
                print("|cffffff00[ADE]|r " .. L.IO_NO_NEW)
            end
            RefreshAllPins()
            if panel and panel:IsShown() then RefreshRecentList() end
            CallPlus("RefreshCustomMenu")
            CallPlus("ResetIconAndRotator")
            bdmapIOFrame:Hide()
        end)

        -- 按钮：重新生成
        local btnExport = CreateFrame("Button", nil, bdmapIOFrame, "UIPanelButtonTemplate")
        btnExport:SetSize(130, 30)
        btnExport:SetPoint("BOTTOMLEFT", bdmapIOFrame, "BOTTOM", 15, 15)
        btnExport:SetText(L.IO_REFRESH_EXPORT)
        btnExport:SetScript("OnClick", function()
            eb:SetText(SerializeMarkers())
            eb:HighlightText()
            eb:SetFocus()
        end)
    end

    -- 每次打开面板时，默认生成自身数据并全选高亮，方便直接 Ctrl+C
    bdmapIOFrame:Show()
    bdmapIOFrame.editBox:SetText(SerializeMarkers())
    bdmapIOFrame.editBox:HighlightText()
    bdmapIOFrame.editBox:SetFocus()
end

-- 供 /amm io 调用（命令收敛到 Commands.lua）
ns.ShowIOFrame = ShowIOFrame


