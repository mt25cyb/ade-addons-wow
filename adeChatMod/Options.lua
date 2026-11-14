-- adeChatMod — 设置窗口：强依赖 ade_AddonFramework 模板。
-- 窗口 = AF.Template.TabbedFrame（单选项页 720 布局；页切换按钮由模板放入标题栏右侧——
-- ADE-v6-FrameDesign，后续选项增多改 opts.layout="multi" 即切左栏页切换，内容区两种布局等宽 672）；
-- 三页 = 设置（Form.Build 每行 label + 控件 + 逐项重置）/ 配置管理（ProfilePage 配置档）/ 关于（AboutPage）。
-- 主题色（settings.themeColor）经 AF.ApplyAccent 派生：AF 控件的勾/滑块/箭头/标题线自动随色刷新，
-- 不再需要自维护 accentRefreshers。
local ACM = _G.adeChatMod
if not ACM then return end
local AF = GetFramework("ade_AddonFramework", true, "adeChatMod")
if not AF then return end
local L = ACM.L or {}

local function ChoiceItems(key)
    local items = {}
    for _, v in ipairs(ACM.CHOICES[key] or {}) do
        items[#items + 1] = { value = v, text = ACM.CHOICE_TEXT[v] or tostring(v) }
    end
    return items
end

-- 每行偏离默认值时显示逐项重置按钮（Row reset="changed"），default 用 GetDefault 解析点号路径。
function ACM:BuildSettings(content)
    local R = self.RANGES
    local spec = {
        { type = "header", label = L.HEADING_APPEARANCE },
        { type = "dropdown", label = L.LABEL_COLOR_SCHEME, key = "colorScheme",
            items = ChoiceItems("colorScheme"), default = self:GetDefault("colorScheme"), reset = "changed" },
        { type = "slider", label = L.LABEL_BTN_SIZE, key = "btnSize",
            min = R.btnSize[1], max = R.btnSize[2], step = 1, suffix = "value",
            default = self:GetDefault("btnSize"), reset = "changed" },
        { type = "slider", label = L.LABEL_BTN_GAP, key = "btnGap",
            min = R.btnGap[1], max = R.btnGap[2], step = 1, suffix = "value",
            default = self:GetDefault("btnGap"), reset = "changed" },
        { type = "slider", label = L.LABEL_FONT_SIZE, key = "fontSize",
            min = R.fontSize[1], max = R.fontSize[2], step = 1, suffix = "value",
            default = self:GetDefault("fontSize"), reset = "changed" },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_THEME },
        -- 颜色行不带逐项重置：取色器自带取消还原，回默认走 /acm reset
        { type = "color", label = L.LABEL_THEME_COLOR, key = "themeColor", default = self:GetDefault("themeColor") },
        { type = "text", label = L.NOTE_THEME_COLOR },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_CHANNELS },
        { type = "input", label = L.LABEL_WORLD_CHANNEL, key = "worldChannel",
            default = self:GetDefault("worldChannel"), reset = "changed" },
        { type = "input", label = L.LABEL_TRADE_CHANNEL, key = "tradeChannel",
            default = self:GetDefault("tradeChannel"), reset = "changed" },
        { type = "toggle", label = L.LABEL_AUTO_JOIN, key = "autoJoinWorldChannel",
            default = self:GetDefault("autoJoinWorldChannel"), reset = "changed" },
        { type = "slider", label = L.LABEL_AUTO_JOIN_DELAY, key = "autoJoinDelay",
            min = R.autoJoinDelay[1], max = R.autoJoinDelay[2], step = 1, suffix = "value",
            default = self:GetDefault("autoJoinDelay"), reset = "changed" },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_POSITION },
        { type = "input", label = L.LABEL_ATTACH_TARGET, key = "attachTarget",
            default = self:GetDefault("attachTarget"), reset = "changed" },
        { type = "dropdown", label = L.LABEL_ATTACH_POINT, key = "attachPosition.point",
            items = ChoiceItems("attachPosition.point"), default = self:GetDefault("attachPosition.point"), reset = "changed" },
        { type = "dropdown", label = L.LABEL_ATTACH_RELATIVE_POINT, key = "attachPosition.relativePoint",
            items = ChoiceItems("attachPosition.relativePoint"), default = self:GetDefault("attachPosition.relativePoint"), reset = "changed" },
        { type = "slider", label = L.LABEL_ATTACH_X, key = "attachPosition.x",
            min = R["attachPosition.x"][1], max = R["attachPosition.x"][2], step = 1, suffix = "value",
            default = self:GetDefault("attachPosition.x"), reset = "changed" },
        { type = "slider", label = L.LABEL_ATTACH_Y, key = "attachPosition.y",
            min = R["attachPosition.y"][1], max = R["attachPosition.y"][2], step = 1, suffix = "value",
            default = self:GetDefault("attachPosition.y"), reset = "changed" },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_FALLBACK },
        { type = "slider", label = L.LABEL_FALLBACK_X, key = "defaultPosition.x",
            min = R["defaultPosition.x"][1], max = R["defaultPosition.x"][2], step = 10, suffix = "value",
            default = self:GetDefault("defaultPosition.x"), reset = "changed" },
        { type = "slider", label = L.LABEL_FALLBACK_Y, key = "defaultPosition.y",
            min = R["defaultPosition.y"][1], max = R["defaultPosition.y"][2], step = 10, suffix = "value",
            default = self:GetDefault("defaultPosition.y"), reset = "changed" },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_MINIMAP },
        { type = "toggle", label = L.LABEL_BAR_SHOWN, key = "barShown",
            default = self:GetDefault("barShown"), reset = "changed" },
        { type = "toggle", label = L.LABEL_MINIMAP_SHOWN, key = "minimapShown",
            default = self:GetDefault("minimapShown"), reset = "changed" },
    }
    -- 每次改动统一走 ApplyAll（与旧版 Changed() 等效）；主题色先 ApplyAccent 再 ApplyAll
    self.form = AF.Form.Build(content, spec, {
        get = function(key) return self:Get(key) end,
        set = function(key, value)
            self:Set(key, value)
            if key == "themeColor" then self:ApplyAccent() end
            self:ApplyAll()
        end,
        width = AF.LAYOUT.contentW,
    })
    -- 滚动高度用 Form 返回的实测高度，不依赖页 holder 的 GetHeight（holder 是 SetAllPoints 帧）
    self.options.scroll:SetContentHeight(self.form.height)
end

-- 「配置管理」页（ADE-v6-FrameDesign）：配置档切换/新建/复制/重命名/删除 + 导出/导入 + 当前档重置。
-- 数据层见 Core.lua 的 profileDB（AF.Template.ProfileDB 适配器）；界面为库 ProfilePage 模板。
function ACM:BuildConfig(content)
    local res = AF.Options.ProfilePage.Build(content, {
        db = self.profileDB,
        L = AF.L,
        notify = function(msg) self:Print(msg) end,
    })
    if res and res.height then self.options.scroll:SetContentHeight(res.height) end
end

function ACM:BuildAbout(content)
    return AF.Template.AboutPage.Build(content, {
        L = L,
        addonName = self.name,
        version = self.version,
        description = { "ABOUT_DESC_1" },
        features = {
            { label = "ABOUT_FEATURE_1_LABEL", text = "ABOUT_FEATURE_1" },
            { label = "ABOUT_FEATURE_2_LABEL", text = "ABOUT_FEATURE_2" },
            { label = "ABOUT_FEATURE_3_LABEL", text = "ABOUT_FEATURE_3" },
        },
        commands = "ABOUT_COMMANDS",
        author = "ABOUT_AUTHOR",
        creditsTitle = "ABOUT_CREDITS_TITLE",
        credits = { "ABOUT_CREDITS", "ABOUT_LICENSE" },
        notes = { "ABOUT_NOTES" },
    })
end

function ACM:CreateOptions()
    if self.options then return self.options end
    -- 图标沿用 TOC 元数据（## IconAtlas / ## IconTexture），与旧版一致
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconTexture")
    local icon = iconAtlas and { atlas = iconAtlas } or (iconTexture and { file = iconTexture } or nil)

    local frame = AF.Template.TabbedFrame.Create({
        layout = "single", -- 选项增多后切 "multi"（左栏页切换）；本行是唯一的布局开关
        title = L.ADDON_TITLE or "adeChatMod",
        icon = icon or { atlas = "communities-icon-chat" },
    })
    self.options = frame
    frame:AddPage("settings", L.TAB_SETTINGS or "Settings", function(content) self:BuildSettings(content) end)
    frame:AddPage("config", L.TAB_CONFIG or "Config", function(content) self:BuildConfig(content) end)
    frame:AddPage("about", L.TAB_ABOUT or "About", function(content)
        local fs = self:BuildAbout(content)
        frame.scroll:SetContentHeight((fs:GetStringHeight() or 0) + 16)
    end)

    -- 只添加自己的弹窗条目，不重赋值 Blizzard 的 StaticPopupDialogs。
    if type(_G.StaticPopupDialogs) == "table" and not _G.StaticPopupDialogs["ADECHATMOD_RESET"] then
        _G.StaticPopupDialogs["ADECHATMOD_RESET"] = {
            text = L.RESET_CONFIRM,
            button1 = _G.YES or "Yes",
            button2 = _G.NO or "No",
            OnAccept = function() ACM:ResetProfile() end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end
    return frame
end

function ACM:RefreshOptions()
    if self.form and self.form.Refresh then self.form:Refresh() end
end

function ACM:ToggleOptions(page)
    local frame = self:CreateOptions()
    if page and frame.pages[page] then frame:ShowPage(page) end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
