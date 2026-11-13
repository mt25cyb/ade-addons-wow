-- 关于页可复用范本：单一 FontString + table.concat + 空行分段。
-- 骨架依据 200:236:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Options/Panel.lua；
-- 改造：ABOUT_* 键名、颜色由 AF.AccentHex() 生成、关于页不再放重置按钮（规划 §十一）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Options = AF.Options or {}
local W = {}
AF.Template.AboutPage = W    -- 组合模板：关于页
AF.Options.AboutPage = W    -- 别名兼容

--- ctx = {
---   L = 本地化表, addonName = string, version = string,
---   description = { "ABOUT_DESC_1", ... },
---   features = { { label = "ABOUT_FEATURE_1_LABEL", text = "ABOUT_FEATURE_1" }, ... },
---   commands = "ABOUT_COMMANDS", author = "ABOUT_AUTHOR",
---   creditsTitle = "ABOUT_CREDITS_TITLE", credits = { "ABOUT_CREDITS", ... },
---   notes = { "ABOUT_NOTES", ... },
--- }
function W.Build(parent, ctx)
    ctx = ctx or {}
    local L = ctx.L or AF.L
    local function T(key) return key and (L[key] or key) or "" end

    local function BuildText()
        local accent = AF.AccentHex()
        -- 固定色（不随主题）：标签黄、指令青蓝
        local YELLOW = "|cffffcc00"
        local CYAN = "|cff22ccff"
        local lines = {}
        -- 版本号：TOC 已是 v 开头时不要再拼出 vv（2026-11-14 用户反馈）
        local ver = tostring(ctx.version or "")
        if ver ~= "" and not ver:match("^[vV]") then ver = "v" .. ver end
        lines[#lines + 1] = accent .. tostring(ctx.addonName or "") .. "|r " .. ver
        lines[#lines + 1] = ""
        for _, key in ipairs(ctx.description or {}) do lines[#lines + 1] = T(key) end
        if #(ctx.description or {}) > 0 then lines[#lines + 1] = "" end
        if ctx.features and #ctx.features > 0 then
            for _, f in ipairs(ctx.features) do
                lines[#lines + 1] = accent .. T(f.label) .. "|r  " .. T(f.text)
            end
            lines[#lines + 1] = ""
        end
        -- 命令：标签 [命令] 黄、指令 /xxx 青蓝（固定色，不随主题）；标签走本地化键，勿硬编码
        if ctx.commands then
            lines[#lines + 1] = YELLOW .. "[" .. T("ABOUT_CMD_LABEL") .. "]" .. "|r "
                .. (T(ctx.commands):gsub("/%S+", CYAN .. "%0" .. "|r"))
            lines[#lines + 1] = ""
        end
        if ctx.author then
            lines[#lines + 1] = YELLOW .. "[" .. T("ABOUT_AUTHOR_LABEL") .. "]" .. "|r " .. T(ctx.author)
            lines[#lines + 1] = ""
        end
        if ctx.creditsTitle then
            lines[#lines + 1] = YELLOW .. "[" .. T(ctx.creditsTitle) .. "]" .. "|r"
            for _, key in ipairs(ctx.credits or {}) do lines[#lines + 1] = T(key) end
            lines[#lines + 1] = ""
        end
        for _, key in ipairs(ctx.notes or {}) do lines[#lines + 1] = T(key) end
        return table.concat(lines, "\n")
    end

    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(AF.fontNormal)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(6)
    fs:SetWordWrap(true)
    fs:SetWidth(ctx.width or AF.LAYOUT.contentW)
    fs:SetPoint("TOPLEFT", 0, 0)
    fs:SetText(BuildText())
    parent:SetHeight((fs:GetStringHeight() or 0) + 16)
    AF.RegisterTheme(parent, function() fs:SetText(BuildText()) end)
    return fs
end
