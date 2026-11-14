-- adeTooltip — 设置窗口：强依赖 ade_AddonFramework 模板。
-- 窗口 = AF.Template.TabbedFrame（单选项页布局）。
-- C0 仅暴露已落地的核心设置（useNewLayout / 缩放 / 主题色 / 小地图），不暴露未实现项。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true, "adeTooltip")
if not AF then return end
local L = ADT.L or {}

local function ChoiceItems(key)
    local items = {}
    for _, v in ipairs(ADT.CHOICES[key] or {}) do
        items[#items + 1] = { value = v, text = ADT.CHOICE_TEXT[v] or tostring(v) }
    end
    return items
end

function ADT:BuildSettings(content)
    local R = ADT.RANGES
    local spec = {
        { type = "header", label = L.HEADING_GENERAL },
        { type = "toggle", label = L.LABEL_USE_NEW_LAYOUT, key = "useNewLayout",
            default = ADT:GetDefault("useNewLayout"), reset = "changed" },
        { type = "text", label = L.NOTE_USE_NEW_LAYOUT },
        { type = "slider", label = L.LABEL_SCALE, key = "scale",
            min = R.scale[1], max = R.scale[2], step = 0.05, suffix = "value",
            default = ADT:GetDefault("scale"), reset = "changed" },
        { type = "color", label = L.LABEL_THEME_COLOR, key = "themeColor",
            default = ADT:GetDefault("themeColor") },
    }
    self.form = AF.Form.Build(content, spec, {
        get = function(key) return self:Get(key) end,
        set = function(key, value)
            self:Set(key, value)
            if key == "themeColor" then self:ApplyAccent() end
            self:ApplyAll()
        end,
        width = AF.LAYOUT.contentW,
    })
    self.options.scroll:SetContentHeight(self.form.height)
end

function ADT:BuildMinimap(content)
    local spec = {
        { type = "header", label = L.HEADING_MINIMAP },
        { type = "toggle", label = L.LABEL_MINIMAP_SHOWN, key = "minimapShown",
            default = ADT:GetDefault("minimapShown"), reset = "changed" },
        { type = "slider", label = L.LABEL_MINIMAP_ANGLE, key = "minimapAngle",
            min = 0, max = 360, step = 1, suffix = "value",
            default = ADT:GetDefault("minimapAngle"), reset = "changed" },
    }
    self.form = AF.Form.Build(content, spec, {
        get = function(key) return self:Get(key) end,
        set = function(key, value)
            self:Set(key, value)
            if key == "minimapShown" then self:SyncMinimapShown() end
            if key == "minimapAngle" then self:ApplyMinimapPosition() end
            self:RefreshOptions()
        end,
        width = AF.LAYOUT.contentW,
    })
    self.options.scroll:SetContentHeight(self.form.height)
end

function ADT:BuildAbout(content)
    return AF.Template.AboutPage.Build(content, {
        L = L,
        addonName = self.name,
        version = self.version,
        description = { "ABOUT_DESC_1" },
        features = {
            { label = "ABOUT_FEATURE_1_LABEL", text = "ABOUT_FEATURE_1" },
            { label = "ABOUT_FEATURE_2_LABEL", text = "ABOUT_FEATURE_2" },
        },
        commands = "ABOUT_COMMANDS",
        author = "ABOUT_AUTHOR",
        creditsTitle = "ABOUT_CREDITS_TITLE",
        credits = { "ABOUT_LICENSE" },
        notes = {},
    })
end

function ADT:CreateOptions()
    if self.options then return self.options end
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(self.name, "IconTexture")
    local icon = iconAtlas and { atlas = iconAtlas } or (iconTexture and { file = iconTexture } or { atlas = "communities-icon-chat" })

    local frame = AF.Template.TabbedFrame.Create({
        layout = "single",
        title = L.ADDON_TITLE or "adeTooltip",
        icon = icon,
    })
    self.options = frame
    frame:AddPage("settings", L.TAB_SETTINGS or "Settings", function(content) self:BuildSettings(content) end)
    frame:AddPage("minimap", L.TAB_MINIMAP or "Minimap", function(content) self:BuildMinimap(content) end)
    frame:AddPage("preview", L.TAB_PREVIEW or "Preview", function(content) self:PreviewSamplesBuild(content) end)
    frame:AddPage("about", L.TAB_ABOUT or "About", function(content)
        local fs = self:BuildAbout(content)
        local h = 16
        if fs and fs.GetStringHeight then h = h + (fs:GetStringHeight() or 0) end
        frame.scroll:SetContentHeight(h)
    end)

    if type(_G.StaticPopupDialogs) == "table" and not _G.StaticPopupDialogs["ADETOOLTIP_RESET"] then
        _G.StaticPopupDialogs["ADETOOLTIP_RESET"] = {
            text = L.RESET_CONFIRM or "Reset adeTooltip settings to defaults?",
            button1 = _G.YES or "Yes",
            button2 = _G.NO or "No",
            OnAccept = function() ADT:ResetProfile() end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end
    return frame
end

function ADT:RefreshOptions()
    if self.form and self.form.Refresh then self.form:Refresh() end
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
