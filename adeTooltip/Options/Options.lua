-- adeTooltip — 设置窗口组装（P1 骨架，§八：多选项页 860×680，8 页）。
-- 窗口 = AF.Template.TabbedFrame（layout="multi"）；预览区 = AF.Template.PreviewPanel 独立组件，
-- 双布局侧只留开关（侧栏页脚按钮 BindButton）；页脚最底槽位 = 小地图图标显示复选框。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true)
if not AF then return end
local L = ADT.L or {}

function ADT:CreateOptions()
    if self.options then return self.options end
    -- 图标沿用 TOC 元数据（## IconAtlas / ## IconTexture）
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconTexture")
    local icon = iconAtlas and { atlas = iconAtlas } or (iconTexture and { file = iconTexture } or nil)

    local frame = AF.Template.TabbedFrame.Create({
        layout = "multi", -- §八：多选项页布局（本插件固定多布局）
        title = L.ADDON_TITLE or "adeTooltip",
        icon = icon or "Interface\\AddOns\\adeTooltip\\assets\\ade_128.tga",
    })
    self.options = frame
    self.forms = {}

    -- 预览面板：独立组件（P0，框架 b010）；P1 为占位内容，P7 接真实分类样例 + 点击定位。
    local preview = AF.Template.PreviewPanel.New({
        width = 340,
        build = function(content) self:BuildPreview(content) end,
    })
    preview:AttachTo(frame)
    preview:SetRefresh(function() self:UpdatePreviewSample() end)
    self.previewPanel = preview
    -- 侧栏页脚：上 = 打开预览按钮；最底槽位 = 小地图图标显示复选框（§八.1）
    preview:BindButton(frame:AddSidebarFooterButton(AF.L["AF_PREVIEW_OPEN"]))
    frame:AddSidebarFooterCheckbox(L.LABEL_MINIMAP_SHOWN,
        function() return self:Get("minimapShown") end,
        function(v) self:SetMinimapShown(v) end)

    -- 页切换 → 预览联动（P1 仅同步样例标题；P7 切换真实样例）
    frame:SetOnPageChanged(function(id)
        self.previewPage = id
        self:UpdatePreviewSample()
    end)

    frame:AddPage("general", L.TAB_GENERAL, function(content) self:BuildGeneral(content) end)
    frame:AddPage("unit", L.TAB_UNIT, function(content) self:BuildPlaceholder(content, "unit") end)
    frame:AddPage("item", L.TAB_ITEM, function(content) self:BuildItem(content) end)
    frame:AddPage("spell", L.TAB_SPELL, function(content) self:BuildPlaceholder(content, "spell") end)
    frame:AddPage("other", L.TAB_OTHER, function(content) self:BuildPlaceholder(content, "other") end)
    frame:AddPage("anchor", L.TAB_ANCHOR, function(content) self:BuildPlaceholder(content, "anchor") end)
    frame:AddPage("config", L.TAB_CONFIG, function(content) self:BuildConfig(content) end)
    frame:AddPage("about", L.TAB_ABOUT, function(content)
        local fs = self:BuildAbout(content)
        frame.scroll:SetContentHeight((fs:GetStringHeight() or 0) + 16)
    end)

    self:RegisterPopups()
    return frame
end

function ADT:RefreshOptions()
    for _, form in pairs(self.forms or {}) do
        if form.Refresh then form:Refresh() end
    end
end

function ADT:RefreshPreview()
    if self.previewPanel then self.previewPanel:Refresh() end
end

function ADT:ToggleOptions(page)
    local frame = self:CreateOptions()
    if page and frame.pages[page] then frame:ShowPage(page) end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
