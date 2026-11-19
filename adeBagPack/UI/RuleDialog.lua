
-- adeBagPack / UI / RuleDialog.lua
-- 「添加排序规则」对话框：旧 adeBackpack UI/Settings.lua:508-724 全量移植（a6，用户指定
-- 恢复源插件同款交互——列表内 +/T 按钮方案撤销，见 CHANGELOG a6）。
-- 四类规则：按物品（拖入/ID） / 按类型（拖入自动 #类型##子类） / 按主类子类（下拉） / 按分类（下拉）。
-- 差异：旧 ADE.CreateHeaderedFrame/Switch/Dropdown 库件 → 手绘 BackdropTemplate 帧 +
--   UIPanelButtonTemplate tab + MenuUtil 菜单下拉轻量替代；12.x GetItemSubClassInfo 已移除
--   → C_Item.GetItemSubClassInfo（Config.lua:5 适配先例同款）。
local ABP = _G.adeBagPack
local L = ABP.L

local dialog
local mask -- a7：模态遮罩（打开时盖住设置页并吞掉鼠标事件，背后控件不可操作）
local OnConfirm -- Options 层注入的确认回调（AddRuleItem + Rule 重建）

-- a9：设置窗口引用（lib.WindowName = "AdeBlizzOptionsFrame_Window"，Namespace.lua:65）
local function GetOptionsWindow()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
        or (BOF_LIBS and BOF_LIBS["ade_UIKit"])
    return lib and lib.WindowName and _G[lib.WindowName] or nil
end

-- a8：模态遮罩——按用户要求只覆盖 ade_UIKit 设置窗口内容区（不铺满全屏），
-- parent 取设置窗（lib.WindowName = "AdeBlizzOptionsFrame_Window"，Namespace.lua:65）。
-- 设置窗 strata=HIGH，遮罩同 strata + 高 level；对话框 strata=DIALOG 高于两者。
-- 遮罩吞鼠标/滚轮；ESC 由 UISpecialFrames 关闭 dialog（OnHide 同步隐藏遮罩）。
local function EnsureMask()
    if mask then return end
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
        or (BOF_LIBS and BOF_LIBS["ade_UIKit"])
    local window = lib and lib.WindowName and _G[lib.WindowName]
    if not window then return end -- 设置窗不存在（不从设置页入口触发）则不建
    mask = CreateFrame("Frame", nil, window, "BackdropTemplate")
    -- a9：只覆盖内容区（body insets，WindowLayout.lua:115-116）——标题栏排除在外
    local g = lib and lib.Internal and lib.Internal.Geometry or {}
    mask:SetPoint("TOPLEFT", window, "TOPLEFT", g.BodyLeft or 18, g.BodyTop or -76)
    mask:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", g.BodyRight or -18, g.BodyBottom or 46)
    mask:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    mask:SetBackdropColor(0, 0, 0, 0.55)
    mask:SetFrameStrata("HIGH")
    mask:SetFrameLevel(window:GetFrameLevel() + 10)
    mask:EnableMouse(true)
    mask:SetScript("OnMouseDown", function() end)
    mask:SetScript("OnMouseWheel", function() end)
    mask:Hide()
end
-- 旧 Settings.lua:512-519；12.x 无 LE_ITEM_CLASS_* 常量，枚举 0-20 与旧版一致
local function BuildClassList()
    local list = {}
    for classID = 0, 20 do
        local name = C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(classID)
        if name then list[#list + 1] = { value = classID, text = name } end
    end
    return list
end

-- 旧 Settings.lua:521-529
local function BuildSubClassList(classID)
    local list = { { value = -1, text = L["RULE_ALL_SUBCLASS"] } }
    if not classID then return list end
    for subClassID = 0, 30 do
        local name = C_Item.GetItemSubClassInfo and C_Item.GetItemSubClassInfo(classID, subClassID)
        if name then list[#list + 1] = { value = subClassID, text = name } end
    end
    return list
end

-- 旧 Settings.lua:531-537
local function BuildCategoryList()
    local list = {}
    for _, c in ipairs(ABP.Categories or {}) do
        -- a8：junk 不参与用户顺序调整（整理时固定末尾），下拉里也不提供添加入口
        if c.key ~= 'junk' then
            list[#list + 1] = { value = c.key, text = L[c.name] or c.name }
        end
    end
    return list
end

-- 旧 Settings.lua:539-558
local function ComputeRule()
    if not dialog then return end
    local kind = dialog.activeKind
    if kind == "id" then
        return dialog.capturedID
    elseif kind == "type" then
        return dialog.capturedTypeRule
    elseif kind == "class" then
        if not dialog.classSel then return end
        local cn = C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(dialog.classSel)
        if not cn then return end
        if dialog.subSel and dialog.subSel ~= -1 then
            local sn = C_Item.GetItemSubClassInfo and C_Item.GetItemSubClassInfo(dialog.classSel, dialog.subSel)
            return "#" .. cn .. "##" .. (sn or "")
        end
        return "#" .. cn
    elseif kind == "category" then
        if not dialog.catSel then return end
        return (ABP.CATEGORY_PREFIX or "@category:") .. dialog.catSel
    end
end

local function UpdateRulePreview()
    if not dialog or not dialog.preview then return end
    local rule = ComputeRule()
    if not rule then
        dialog.preview:SetText(L["RULE_PREVIEW"]:format(L["RULE_NONE"]))
        return
    end
    local text = rule
    local prefix = ABP.CATEGORY_PREFIX or "@category:"
    if type(rule) == "string" and rule:sub(1, #prefix) == prefix then
        text = ABP:GetRuleText(rule)
    elseif type(rule) == "number" then
        text = "ID:" .. rule
    end
    dialog.preview:SetText(L["RULE_PREVIEW"]:format(text))
end

-- 旧 Settings.lua:577-591：拖入物品 → 同时捕获 ID 与 #类型##子类（id/type 两 tab 共用槽）
local function OnDialogDrop()
    local kind, info = GetCursorInfo()
    if kind ~= "item" then return end
    local itemID = ABP:GetItemID(info)
    if not itemID then return end
    dialog.capturedID = itemID
    local _, itemType, itemSubType = ABP:GetItemInfo(itemID)
    dialog.capturedTypeRule = "#" .. (itemType or "") .. "##" .. (itemSubType or "")
    local ok, link = pcall(GetItemInfo, itemID)
    if dialog.slotLabel then
        dialog.slotLabel:SetText((ok and link) or ("ID:" .. itemID))
    end
    ClearCursor()
    UpdateRulePreview()
end

-- 旧 Settings.lua:593-605；tab 选中态 = 禁用按钮（唯一高亮源）
local function ShowDialogPanel(which)
    if not dialog then return end
    dialog.slotPanel:SetShown(which == "id" or which == "type")
    if which == "type" then
        dialog.slotLabel:SetText(L["RULE_DRAG_HINT"] .. "（" .. L["RULE_BY_TYPE"] .. "）")
    else
        dialog.slotLabel:SetText(L["RULE_DRAG_HINT"])
    end
    dialog.classPanel:SetShown(which == "class")
    dialog.catPanel:SetShown(which == "category")
    dialog.activeKind = which
    if dialog.tabs then
        for _, tab in ipairs(dialog.tabs) do
            tab:SetEnabled(tab.value ~= which)
        end
    end
    UpdateRulePreview()
end

-- 下拉按钮：文本显示当前选择，点击弹 MenuUtil 菜单（旧 ADE.CreateDropdown 轻量替代）
local function CreateDropdownButton(parent, labelText, width)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -6)
    label:SetText(labelText)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    button:SetText(L["RULE_NONE"])
    return button
end

local function FillDropdownMenu(button, items, onSelect)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(button, function(_, rootDescription)
        for _, item in ipairs(items) do
            rootDescription:CreateButton(item.text, function()
                button:SetText(item.text)
                onSelect(item.value)
            end)
        end
    end)
end

local function BuildRuleDialog()
    -- a9：parent = 设置窗口（与遮罩同一父级），固定在设置窗中心
    local optionsWindow = GetOptionsWindow()
    dialog = CreateFrame("Frame", "ABPRuleDialog", optionsWindow or UIParent, "BackdropTemplate")
    dialog:SetSize(420, 300)
    dialog:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    dialog:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
    EnsureMask()
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(20) -- 高于遮罩（10）
    -- a9：固定在设置窗口中心（不再相对 UIParent 偏移）
    dialog:SetPoint("CENTER", optionsWindow or UIParent, "CENTER", 0, 0)
    dialog:EnableMouse(true)
    dialog:SetClampedToScreen(true) -- a9：固定在设置窗中心，不再可拖动
    dialog:SetScript("OnHide", function()
        if mask then mask:Hide() end -- ESC（UISpecialFrames）/ 关闭按钮 / 取消 / 添加 统一收遮罩
    end)
    dialog:Hide()
    UISpecialFrames[#UISpecialFrames + 1] = "ABPRuleDialog" -- ESC 关闭

    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 14, -10)
    title:SetText(L["RULE_DIALOG_TITLE"])
    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() dialog:Hide() end)

    -- 四个规则类型 tab（旧 ADE.CreateSwitch 轻量替代：文字按钮 + 选中禁用高亮）
    dialog.tabs = {}
    local tabDefs = {
        { text = L["RULE_BY_ID"], value = "id" },
        { text = L["RULE_BY_TYPE"], value = "type" },
        { text = L["RULE_BY_CLASS"], value = "class" },
        { text = L["RULE_BY_CATEGORY"], value = "category" },
    }
    -- a7：全部相对 dialog 绝对定位（此前后续 tab 相对前一个 TOPRIGHT 且每次 Y-28，
    -- 偏移累积成阶梯错位，中文客户端截图实证）——固定 X 步进 100，Y 恒定 -28。
    for i, def in ipairs(tabDefs) do
        local tab = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        tab:SetSize(96, 22)
        tab:SetText(def.text)
        tab:SetPoint("TOPLEFT", dialog, "TOPLEFT", 14 + (i - 1) * 100, -28)
        tab:SetScript("OnClick", function() ShowDialogPanel(def.value) end)
        tab.value = def.value
        dialog.tabs[i] = tab
    end

    local function NewPanel()
        local p = CreateFrame("Frame", nil, dialog)
        p:SetSize(392, 150)
        p:SetPoint("TOPLEFT", dialog, "TOPLEFT", 14, -60)
        p:Hide()
        return p
    end

    -- 按物品 / 按类型 共用拖拽槽（旧 Settings.lua:652-658）
    local slotPanel = NewPanel()
    local slotLabel = slotPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    slotLabel:SetPoint("TOPLEFT", slotPanel, "TOPLEFT", 8, -10)
    slotLabel:SetTextColor(0.8, 0.8, 0.8)
    slotLabel:SetText(L["RULE_DRAG_HINT"])
    local slotFrame = CreateFrame("Frame", nil, slotPanel, "BackdropTemplate")
    slotFrame:SetSize(380, 104)
    slotFrame:SetPoint("TOPLEFT", slotLabel, "BOTTOMLEFT", 0, -6)
    slotFrame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    slotFrame:SetBackdropColor(0, 0, 0, 0.3)
    slotFrame:EnableMouse(true)
    slotFrame:SetScript("OnReceiveDrag", function() OnDialogDrop() end)
    slotFrame:SetScript("OnMouseUp", function() OnDialogDrop() end)
    dialog.slotLabel = slotLabel
    dialog.slotPanel = slotPanel

    -- 按主类/子类（旧 Settings.lua:661-680）
    local classPanel = NewPanel()
    dialog.classDD = CreateDropdownButton(classPanel, L["RULE_CLASS"], 360)
    dialog.classDD:SetPoint("TOPLEFT", classPanel, "TOPLEFT", 4, -6)
    dialog.subDD = CreateDropdownButton(classPanel, L["RULE_SUBCLASS"], 360)
    dialog.subDD:SetPoint("TOPLEFT", dialog.classDD, "BOTTOMLEFT", 0, -26)
    dialog.classDD:SetScript("OnClick", function(self)
        FillDropdownMenu(self, BuildClassList(), function(v)
            dialog.classSel = v
            dialog.subSel = nil
            dialog.subDD:SetText(L["RULE_NONE"])
            dialog.subItems = BuildSubClassList(v)
            UpdateRulePreview()
        end)
    end)
    dialog.subDD:SetScript("OnClick", function(self)
        FillDropdownMenu(self, dialog.subItems or BuildSubClassList(dialog.classSel), function(v)
            dialog.subSel = v
            UpdateRulePreview()
        end)
    end)
    dialog.classPanel = classPanel

    -- 按分类（旧 Settings.lua:683-692）
    local catPanel = NewPanel()
    dialog.catDD = CreateDropdownButton(catPanel, L["RULE_CATEGORY"], 360)
    dialog.catDD:SetPoint("TOPLEFT", catPanel, "TOPLEFT", 4, -6)
    dialog.catDD:SetScript("OnClick", function(self)
        FillDropdownMenu(self, BuildCategoryList(), function(v)
            dialog.catSel = v
            UpdateRulePreview()
        end)
    end)
    dialog.catPanel = catPanel

    -- 预览 + 确认/取消（旧 Settings.lua:695-704）
    dialog.preview = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dialog.preview:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 14, 42)
    dialog.preview:SetTextColor(1, 0.9, 0.4)
    dialog.preview:SetText(L["RULE_PREVIEW"]:format(L["RULE_NONE"]))

    local confirm = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    confirm:SetSize(120, 24)
    confirm:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -14, 10)
    confirm:SetText(L["BTN_ADD_RULE"])
    confirm:SetScript("OnClick", function()
        local rule = ComputeRule()
        if not rule then
            print("|cff00AAFF[ADE]|r " .. tostring(L["RULE_NONE"]))
            return
        end
        if OnConfirm then OnConfirm(rule) end
        dialog:Hide()
    end)
    local cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancel:SetSize(100, 24)
    cancel:SetPoint("RIGHT", confirm, "LEFT", -8, 0)
    cancel:SetText(CANCEL)
    cancel:SetScript("OnClick", function() dialog:Hide() end)

    -- 旧 Settings.lua:706-708：必须最后触发（面板字段齐备后）
    ShowDialogPanel("id")
end

-- 导出：ABP.OpenRuleDialog(onConfirm)——onConfirm(rule) 在点击「添加规则」且规则非空时回调
-- （模块自挂载：TOC 加载序在 Options 之前，Options 直接消费 ABP.OpenRuleDialog）
ABP.OpenRuleDialog = function(onConfirm)
    OnConfirm = onConfirm
    if not dialog then BuildRuleDialog() end
    dialog.capturedID = nil
    dialog.capturedTypeRule = nil
    dialog.classSel = nil
    dialog.subSel = nil
    dialog.catSel = nil
    dialog.subItems = BuildSubClassList(nil)
    dialog.classDD:SetText(L["RULE_NONE"])
    dialog.subDD:SetText(L["RULE_NONE"])
    dialog.catDD:SetText(L["RULE_NONE"])
    dialog.slotLabel:SetText(L["RULE_DRAG_HINT"])
    dialog.preview:SetText(L["RULE_PREVIEW"]:format(L["RULE_NONE"]))
    EnsureMask()
    if mask then mask:Show() end -- 打开子窗口时同步启用模态遮罩（设置窗内容区不可操作）
    dialog:Show()
end
