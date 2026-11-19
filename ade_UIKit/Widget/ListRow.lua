------------------------------------------------------------
-- 列表行 ListRow（kind="list"，单控件文件；计划 _docs/plans/ade_UIKit-ListRow-dev-plan.md）。
-- 条目可拖动排序、可接收拖入物品/法术、条目 = 图标/文本/尾部按钮组合、
-- 支持鼠标按键+修饰键赋予功能、斑马纹错行背景、缩进跟随标题层级。
-- spec 契约：
--   getItems()   → 宿主数组【引用】（增删/排序直接改数组，旧 adeBackpack ListFrame 同款语义）
--   display(value, idx) → text[, icon]（icon 可选：atlas/fileID/路径）
--   onChanged(reason, value, idx) → 宿主回调（reason: "sort"/"add"/"delete"/"move"/"drop"/"binding"）
-- 可选：
--   rowHeight=26 / visibleRows=8（条目高与可视行数 → 整行高度）
--   accept = { item = true, spell = true }（拖入 opt-in；默认关闭）
--   onDrop(kind, id, targetIdx) → 自定义拖入插入（默认追加/插入 + spec.unique 去重）
--   unique = true（拖入去重：按值比较）
--   entryButtons = { { atlas=, text=, tooltip=, onClick(value, idx, button) } }
--     （b048：onClick 第三参 = 按钮自身，可作 MenuUtil.CreateContextMenu owner 定位）
--   showDelete / showMove（预置便捷项，追加在 entryButtons 之后；
--     b050 起 showMove = 移到最上/上移/下移/移到最下四按钮）
--   bindings = { ["LeftButton"]=fn, ["RightButton"]=fn, ["LeftButton+shift"]=fn, ... }
--     键格式 ButtonName[+修饰键...]（修饰键小写 shift/ctrl/alt）；条目点击命中则调 fn(value, idx)
--   bindingsTooltip（条目悬停提示当前绑定文案）
--   rowBuilder(frame, value, idx) → 覆盖默认条目布局（高级定制口）
--   emptyText（空态文案）/ stripes = true（斑马纹，默认开）
-- 官方溯源：
--   拖动排序 ScrollUtil.AddLinearDragBehavior + SetReorderable(true) + SetDragRelativeToCursor
--     （ScrollUtil.lua:1336/887/795-804；Inside=交换、Above/Below=插入，:1450-1520 实证直接重排
--     DataProvider，宿主写回走 SetFinalizeDrop——OnDragStopInternal 调 finalizeDrop，
--     ScrollUtil.lua:853-857/1069）
--   斑马纹 ScrollUtil.RegisterAlternateRowBehavior + auctionhouse-rowstripe-1/2
--     （ScrollUtil.lua:1626-1633；Blizzard_AuctionHouseItemList 先例）
--   行池 CreateScrollBoxListLinearView + SetElementFactory（Kinds.InitList 同款模式）
--   拖入接收 OnReceiveDrag + GetCursorInfo + ClearCursor + IG_ABILITY_ICON_DROP
--     （PetCollection 范本 Blizzard_PetCollection.xml:571-605）
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local mixins = Internal.Mixins
mixins.ListRow = mixins.ListRow or {}
local ListRowMixin = mixins.ListRow
local build = Internal.Build
local L = lib.L

local ENTRY_HEIGHT, ENTRY_ICON, VISIBLE_ROWS = 26, 22, 8
local LABEL_TOP = 26

--- spec 必需项校验（无兜底纪律：配置错误 error 暴露）
local function Validate(spec)
    if type(spec.getItems) ~= "function" then
        error("ListRow: spec.getItems 必须为函数（返回宿主数组引用）", 3)
    end
    if type(spec.display) ~= "function" then
        error("ListRow: spec.display 必须为函数（value, idx → text[, icon]）", 3)
    end
end

--- 尾部小按钮（b044：去掉 WowStyle2IconButtonMixin 的外框底——外框对 14px 图标明显偏大
--- （用户反馈），与 TabRow 页签顺序行的裸材质箭头风格统一；悬停反馈改为图标提亮发白，
--- 禁用态由 -disable 材质承担。材质模式支持 disabledAtlas 与 rotation；文字模式兜底。
--- b046：常态调暗（0.6 灰）+ 悬停高亮（>1 提亮发白）——用户指定「常态调暗些、指向高亮」；
--- 禁用态仍走 -disable 灰材质（1,1,1 不再叠加调暗）。
local ENTRY_BTN_DIM = { 0.6, 0.6, 0.6 }
local ENTRY_BTN_HOVER = { 1.3, 1.3, 1.15 }

local function EntryButton(parent, specButton)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(20, 20)
    button.Icon = button:CreateTexture(nil, "OVERLAY")
    button.Icon:SetPoint("CENTER")
    button.Icon:SetSize(16, 16)
    local function SetIcon(atlas)
        if atlas then button.Icon:SetAtlas(atlas) end
        if specButton.rotation then button.Icon:SetRotation(specButton.rotation) end
    end
    SetIcon(specButton.atlas)
    button.Icon:SetVertexColor(unpack(ENTRY_BTN_DIM)) -- 常态调暗
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self.Icon:SetVertexColor(unpack(ENTRY_BTN_HOVER)) -- 悬停高亮
        end
        if specButton.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(specButton.tooltip)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            self.Icon:SetVertexColor(unpack(ENTRY_BTN_DIM))
        end
        GameTooltip:Hide()
    end)
    button:SetScript("OnEnable", function()
        button.Icon:SetVertexColor(unpack(ENTRY_BTN_DIM))
        SetIcon(specButton.atlas)
    end)
    button:SetScript("OnDisable", function()
        button.Icon:SetVertexColor(1, 1, 1)
        SetIcon(specButton.disabledAtlas or specButton.atlas)
    end)
    if specButton.text then
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        button:SetFontString(text) -- SetText 需要显式 FontString，否则显示为空白方块
        button:SetText(specButton.text)
    end
    return button
end

--- 预置便捷项 + 声明式尾部按钮合并。
--- b041 历史：▲▼✕ 文字改材质（▲ 字体缺字形乱码）；b050 起本控件排序按钮换
--- CovenantSanctum 组，旧 backarrow/forwardarrow 组仍用于 TabRow 页签顺序行。
--- b050：预置排序按钮由 ▲▼ 两项扩为四项——视觉从左到右：
--- 移到最上 → 上移 → 下移 → 移到最下 → 删除（删除仍最右）。布局自右向左按数组次序
--- 放置（第 1 项最右），故构建次序 = delete/moveToBottom/moveDown/moveUp/moveToTop，
--- 自定义 entryButtons 追加在后（最左）。
--- 用户指定材质：单箭头（移一层）= CovenantSanctum-Renown-Arrow[-Hover/-Disabled]；
--- 双箭头（移到顶/底）= CovenantSanctum-Renown-DoubleArrow[-Hover/-Disabled]。
--- 均为向左箭头：SetRotation -90° = 向上，+90° = 向下（b041 实证）。
local function EntryButtonsFor(spec)
    local buttons = {}
    if spec.showDelete then
        buttons[#buttons + 1] = { atlas = "common-icon-delete", disabledAtlas = "common-icon-delete-disable",
            tooltip = L["BOF_LIST_DELETE"], action = "delete" }
    end
    if spec.showMove then
        local SINGLE = "CovenantSanctum-Renown-Arrow"
        local DOUBLE = "CovenantSanctum-Renown-DoubleArrow"
        buttons[#buttons + 1] = { atlas = DOUBLE, hoverAtlas = DOUBLE .. "-Hover",
            disabledAtlas = DOUBLE .. "-Disabled", rotation = math.rad(90),
            tooltip = L["BOF_LIST_MOVE_BOTTOM"], action = "moveToBottom" }
        buttons[#buttons + 1] = { atlas = SINGLE, hoverAtlas = SINGLE .. "-Hover",
            disabledAtlas = SINGLE .. "-Disabled", rotation = math.rad(90),
            tooltip = L["BOF_LIST_MOVE_DOWN"], action = "moveDown" }
        buttons[#buttons + 1] = { atlas = SINGLE, hoverAtlas = SINGLE .. "-Hover",
            disabledAtlas = SINGLE .. "-Disabled", rotation = -math.rad(90),
            tooltip = L["BOF_LIST_MOVE_UP"], action = "moveUp" }
        buttons[#buttons + 1] = { atlas = DOUBLE, hoverAtlas = DOUBLE .. "-Hover",
            disabledAtlas = DOUBLE .. "-Disabled", rotation = -math.rad(90),
            tooltip = L["BOF_LIST_MOVE_TOP"], action = "moveToTop" }
    end
    for _, b in ipairs(spec.entryButtons or {}) do buttons[#buttons + 1] = b end
    return buttons
end

--- 条目内容初始化（host 即条目帧，行池复用时仅执行一次）
local function SetupEntry(frame, list)
    frame.Stripe = frame:CreateTexture(nil, "BACKGROUND")
    frame.Stripe:SetAllPoints()
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetSize(ENTRY_ICON, ENTRY_ICON)
    frame.Icon:SetPoint("LEFT", 8, 0)
    frame.Text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    frame.Text:SetJustifyH("LEFT")
    frame.AllEntryButtons = {} -- b049：历次构建的按钮实体（跨 list 复用时 Hide 旧集）
    -- 拖动排序的 RegisterForDrag/OnDragStart 由 AddLinearDragBehavior 的
    -- OnInitializedFrame 统一挂载，此处不重复
    frame:SetScript("OnReceiveDrag", function(self)
        list:ReceiveDrag(self:GetElementDataIndex() or 1)
    end)
    frame:SetScript("OnClick", function(self, mouseButton)
        list:EntryClicked(self, mouseButton)
    end)
    if list.Spec.bindingsTooltip then
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(list.Spec.bindingsTooltip)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

--- 尾部按钮集构建（b049：按 spec 身份重建——内层行跨 list 复用时实体/闭包固化是
--- b038 起 bug（adeBagPack：entryButtons 按钮串位到另一清单）。同 spec 复用跳过；
--- 异 spec 先 Hide 全部旧实体再重建，旧实体保留在 AllEntryButtons 防泄漏。
local function BuildEntryButtons(frame, list)
    local spec = list.Spec
    if frame.ButtonsOwner == spec then return end
    for _, old in ipairs(frame.AllEntryButtons) do old:Hide() end
    wipe(frame.AllEntryButtons)
    frame.Buttons = list.EntryButtonsSpec
    frame.ButtonTop, frame.ButtonUp, frame.ButtonDown, frame.ButtonBottom = nil, nil, nil, nil
    local prev
    for _, b in ipairs(frame.Buttons) do
        local button = EntryButton(frame, b)
        -- b047：首个（最右）按钮右侧留 6px 空白，其余按钮间距 2px
        button:SetPoint("RIGHT", prev or frame, prev and "LEFT" or "RIGHT", prev and -2 or -6, 0)
        if b.action == "moveToTop" then frame.ButtonTop = button
        elseif b.action == "moveUp" then frame.ButtonUp = button
        elseif b.action == "moveDown" then frame.ButtonDown = button
        elseif b.action == "moveToBottom" then frame.ButtonBottom = button end
        button:SetScript("OnClick", function()
            local value, idx = frame.value, frame.idx
            if b.action == "delete" then list:Delete(idx)
            elseif b.action == "moveToTop" then list:MoveTo(idx, 1)
            elseif b.action == "moveUp" then list:Move(idx, -1)
            elseif b.action == "moveDown" then list:Move(idx, 1)
            elseif b.action == "moveToBottom" then list:MoveTo(idx, #list.Spec.getItems())
            elseif b.onClick then
                -- b048：第三参 = 按钮自身（宿主可作 MenuUtil.CreateContextMenu 的 owner 定位）
                b.onClick(value, idx, button)
                list:Changed("binding", value, idx)
            end
        end)
        frame.AllEntryButtons[#frame.AllEntryButtons + 1] = button
        prev = button
    end
    frame.ButtonsOwner = spec
end

--- 条目渲染（每次 acquire/数据变化）
local function RenderEntry(frame, value, idx, spec)
    frame.value, frame.idx = value, idx
    -- b048：display 包 xpcall——宿主 display 报错时行文本显式显示 ERR+消息（诊断纪律），
    -- 渲染不再中断。此前错误中断本函数 → 行池残留上一轮文本且 ▲▼ 禁用状态错乱
    -- （adeBagPack 分类清单实测）。禁用状态设置移到无条件路径。
    local ok, text, icon = xpcall(spec.display, tostring, value, idx)
    frame.Text:ClearAllPoints()
    if ok and icon then
        frame.Icon:Show()
        if type(icon) == "number" then frame.Icon:SetTexture(icon)
        elseif C_Texture and C_Texture.GetAtlasInfo(icon) then frame.Icon:SetAtlas(icon)
        else frame.Icon:SetTexture(icon) end
        frame.Text:SetPoint("LEFT", frame.Icon, "RIGHT", 6, 0)
    else
        frame.Icon:Hide()
        frame.Text:SetPoint("LEFT", frame, "LEFT", 10, 0)
    end
    frame.Text:SetPoint("RIGHT", frame, "RIGHT", -(#frame.Buttons * 24 + 10), 0)
    frame.Text:SetText(tostring(text ~= nil and text or ""))
    -- b050：首项的「移到最上/上移」、末项的「下移/移到最下」禁用（disabledAtlas 自动切换）
    local count = #spec.getItems()
    if frame.ButtonTop then frame.ButtonTop:SetEnabled(idx > 1) end
    if frame.ButtonUp then frame.ButtonUp:SetEnabled(idx > 1) end
    if frame.ButtonDown then frame.ButtonDown:SetEnabled(idx < count) end
    if frame.ButtonBottom then frame.ButtonBottom:SetEnabled(idx < count) end
    if spec.rowBuilder then spec.rowBuilder(frame, value, idx) end
end

function build.ListRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    Mixin(row, ListRowMixin)
    row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.EmptyText = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    row.EmptyText:Hide()
    -- Inset 内衬（标准内衬观感）+ 滚动区（WindowFrame.lua:69-72 WowScrollBoxList 同款）
    row.Inset = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.Inset:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    row.Inset:SetBackdropColor(0, 0, 0, 0.4)
    row.ScrollBox = CreateFrame("ScrollFrame", nil, row.Inset, "WowScrollBoxList")
    row.ScrollBox:SetPoint("TOPLEFT", 6, -6)
    row.ScrollBox:SetPoint("BOTTOMRIGHT", -24, 6)
    row.ScrollBar = CreateFrame("EventFrame", nil, row.Inset, "MinimalScrollBar")
    row.ScrollBar:SetPoint("TOPLEFT", row.Inset, "TOPRIGHT", -20, -6)
    row.ScrollBar:SetPoint("BOTTOMLEFT", row.Inset, "BOTTOMRIGHT", -20, 6)
    return row
end

--- 修饰键组合键名（bindings 键格式 ButtonName[+修饰键...]，修饰键小写）
local function BindingKey(mouseButton)
    local parts = {}
    if IsShiftKeyDown() then parts[#parts + 1] = "shift" end
    if IsControlKeyDown() then parts[#parts + 1] = "ctrl" end
    if IsAltKeyDown() then parts[#parts + 1] = "alt" end
    parts[#parts + 1] = mouseButton
    return table.concat(parts, "+")
end

function ListRowMixin:Init(element, window)
    self.Window = window
    local option = element.Option
    self.Option = option
    if not option then return end
    local spec = option.Spec
    self.Spec = spec
    Validate(spec)
    self.EntryButtonsSpec = EntryButtonsFor(spec)
    local left = 16 + (option.Indent or 0) * 20 -- 组合类控件缩进规则：16 + indent×20（b021 先例）
    self.Label:ClearAllPoints()
    self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", left, -3)
    self.Label:SetText(option:GetLabel())
    self.Inset:ClearAllPoints()
    self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", left, -LABEL_TOP)
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -16, 4)
    self.EmptyText:ClearAllPoints()
    self.EmptyText:SetPoint("TOPLEFT", self.Inset, "TOPLEFT", 12, -12)
    self.EmptyText:SetText(spec.emptyText or L["BOF_LIST_EMPTY"])
    local list = self
    if not self.View then
        self.View = CreateScrollBoxListLinearView(0, 0, 0, 0, 0)
        self.View:SetElementExtent(spec.rowHeight or ENTRY_HEIGHT)
        self.View:SetElementFactory(function(factory, elementData)
            -- 内层回调第二参 = 数据值本身（Kinds.InitList 的 (host, data) 同款签名），
            -- 不是 elementData——b038 实跑报「index a number value」即此（_debug.log）
            -- b049：spec 必须经 list.Spec 动态取（闭包捕获局部 spec 是 b038 起 bug）——
            -- Panel 行池跨 list 复用 ListRow 帧时（`if not self.View` 跳过重建），
            -- 固化的 spec 使 display/getItems 用错列表：分类/装备清单切页互换复用后
            -- 显示原串 key、▲▼ 按错表禁用（adeBagPack 中文客户端实测，奇偶交替）。
            factory("Button", function(frame, value)
                if not frame.Stripe then SetupEntry(frame, list) end
                BuildEntryButtons(frame, list) -- b049：按钮集按 spec 身份同步（跨 list 复用）
                RenderEntry(frame, value, frame:GetElementDataIndex() or 1, list.Spec)
            end)
        end)
        ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.View)
        -- 拖动排序：官方 behavior 直接重排 provider；宿主数组写回在 finalizeDrop。
        -- b045：排序形式三规格（用户要求，后续清单控件沿用同语义）——
        -- spec.reorder = "buttons"（仅按钮）| "drag"（仅拖动）| "both"（默认，向后兼容）；
        -- showMove 控制按钮显隐不变，"buttons" 时拖动 behavior 不挂载。
        if spec.reorder ~= "buttons" then
            self.DragBehavior = ScrollUtil.AddLinearDragBehavior(self.ScrollBox)
        -- 拖动 ghost 必须显式 SetCursorFactory：默认 cursorFactory 为空 → 拖动开始
        -- AcquireFromPool(nil) 报「templateInfo (a nil value)」（ScrollUtil.lua:921，
        -- _debug.log 实证；CharacterSelectList.lua:240-242 官方先例同款显式设置）。
        -- ghost = InsetFrameTemplate 边框 + 候选条目文本（条目 initializer 在 cursor
        -- 路径的实参签名与正常 acquire 不一致，不复用）。
        self.DragBehavior:SetCursorFactory(function()
            return "InsetFrameTemplate", function(cursorFrame, candidateFrame)
                cursorFrame:SetSize(candidateFrame:GetSize())
                if not cursorFrame.text then
                    cursorFrame.text = cursorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    cursorFrame.text:SetPoint("LEFT", 8, 0)
                end
                cursorFrame.text:SetText(candidateFrame.Text and candidateFrame.Text:GetText() or "")
            end
        end)
        self.DragBehavior:SetReorderable(true)
        self.DragBehavior:SetDragRelativeToCursor(true)
        self.DragBehavior:SetAreaIntersectMargin(4)
        self.DragBehavior:SetFinalizeDrop(function(contextData)
            list:WriteBack(contextData.dataProvider, "sort")
        end)
        end -- reorder ~= "buttons"
        -- 斑马纹：黑底上 auctionhouse-rowstripe atlas 无感（用户实测），改 WHITE8X8 淡白交替
        ScrollUtil.RegisterAlternateRowBehavior(self.ScrollBox, function(frame, alternate)
            if frame.Stripe then
                frame.Stripe:SetColorTexture(1, 1, 1, alternate and 0.07 or 0)
            end
        end)
        -- 空白区拖入 = 追加（条目自身 OnReceiveDrag = 插入该条目前）
        self.ScrollBox:SetScript("OnReceiveDrag", function() list:ReceiveDrag(nil) end)
        self.ScrollBox:EnableMouseWheel(true)
    end
    self:Refresh()
end

function ListRowMixin:Refresh()
    if not self.Spec then return end
    local items = self.Spec.getItems()
    self.DataProvider = CreateDataProvider(items)
    self.ScrollBox:SetDataProvider(self.DataProvider)
    self.EmptyText:SetShown(#items == 0)
end

--- 拖放结束：provider 顺序写回宿主数组引用（finalizeDrop 的 contextData.dataProvider）。
--- b043 修正：官方 OnDragStop 已用 provider:Remove/InsertAtIndex 真实重排 collection
--- （ScrollUtil.lua:1447-1498），collection 元素即原始数据（CreateDataProvider 不包装
--- elementData，官方先例数据本就是表）——EnumerateEntireRange 产出 (index, value)，
--- 直接取 value 写回即可（b042 的 GetData() 在 number 数据上报「index a number value」）。
--- provider 顺序已正确、ScrollBox 已随 OnInsert/OnRemove 事件自动重渲染，无需 Refresh。
function ListRowMixin:WriteBack(provider, reason)
    local items = self.Spec.getItems()
    local order = {}
    for _, value in provider:EnumerateEntireRange() do
        order[#order + 1] = value
    end
    for i = #items, 1, -1 do items[i] = nil end
    for _, v in ipairs(order) do items[#items + 1] = v end
    self:Changed(reason)
end

function ListRowMixin:Changed(reason, value, idx)
    if self.Spec.onChanged then self.Spec.onChanged(reason, value, idx) end
end

--- 删除条目（showDelete / 自定义 entryButtons 通用入口）
function ListRowMixin:Delete(idx)
    local items = self.Spec.getItems()
    local value = table.remove(items, idx)
    self:Refresh()
    self:Changed("delete", value, idx)
end

--- 上下移条目
function ListRowMixin:Move(idx, delta)
    local items = self.Spec.getItems()
    local target = idx + delta
    if target < 1 or target > #items then return end
    items[idx], items[target] = items[target], items[idx]
    self:Refresh()
    self:Changed("move", items[target], target)
end

--- 移到指定位置（b050：移到最上/最下按钮；remove+insert 保序搬运，非交换）
function ListRowMixin:MoveTo(idx, target)
    local items = self.Spec.getItems()
    if idx < 1 or idx > #items or target < 1 or target > #items or idx == target then return end
    local value = table.remove(items, idx)
    table.insert(items, target, value)
    self:Refresh()
    self:Changed("move", value, target)
end

--- 条目点击：bindings 声明式匹配（未命中任何键 no-op）
function ListRowMixin:EntryClicked(frame, mouseButton)
    local bindings = self.Spec.bindings
    if not bindings then return end
    local fn = bindings[BindingKey(mouseButton)] or bindings[mouseButton]
    if fn then fn(frame.value, frame.idx) end
end

--- 拖入接收（物品/法术）：targetIdx = 条目索引（插入该条目前）；nil = 追加。
function ListRowMixin:ReceiveDrag(targetIdx)
    local kind, id = GetCursorInfo()
    ClearCursor()
    local spec = self.Spec
    if not kind or not (spec.accept and spec.accept[kind]) then return end
    local value = id
    if spec.unique then
        for _, v in ipairs(spec.getItems()) do
            if v == value then return end
        end
    end
    local items = spec.getItems()
    local idx = targetIdx or (#items + 1)
    if idx > #items + 1 then idx = #items + 1 end
    if spec.onDrop then
        spec.onDrop(kind, id, idx)
    else
        table.insert(items, idx, value)
    end
    PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
    self:Refresh()
    self:Changed("drop", value, idx)
end
