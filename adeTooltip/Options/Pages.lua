-- adeTooltip — 选项页构建（P1 骨架）。
-- 常规页 = 真实表单（usePrettyStyle/scale/themeColor）；物品页先挂两段式开关用于验证
-- 框架 b010 的 enabled 禁用态（usePrettyStyle=false 时置灰）；单位/法术/其他/锚点页为占位，
-- 真实选项按开发计划 P2–P7 逐页接入；配置管理页 = ProfilePage；关于页 = AboutPage。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true)
if not AF then return end
local L = ADT.L or {}

-- 常规页：排版 + 外观（P1 可用的最小真实选项集）
function ADT:BuildGeneral(content)
    local R = self.RANGES
    local spec = {
        { type = "header", label = L.HEADING_LAYOUT },
        { type = "toggle", label = L.LABEL_USE_PRETTY, key = "usePrettyStyle",
            default = self:GetDefault("usePrettyStyle"), reset = "changed" },
        { type = "text", label = L.NOTE_USE_PRETTY },
        { type = "space", height = 4 },
        { type = "header", label = L.HEADING_APPEARANCE },
        { type = "slider", label = L.LABEL_SCALE, key = "scale",
            min = R.scale[1], max = R.scale[2], step = 0.05, suffix = "value",
            default = self:GetDefault("scale"), reset = "changed" },
        -- 颜色行不带逐项重置：取色器自带取消还原，回默认走配置管理页重置
        { type = "color", label = L.LABEL_THEME_COLOR, key = "themeColor", default = self:GetDefault("themeColor") },
        { type = "text", label = L.NOTE_THEME_COLOR },
    }
    self.forms.general = AF.Form.Build(content, spec, {
        get = function(key) return self:Get(key) end,
        set = function(key, value)
            self:Set(key, value)
            if key == "themeColor" then self:ApplyAccent() end
            self:ApplyAll()
        end,
        width = AF.LAYOUT.contentW,
    })
    self.options.scroll:SetContentHeight(self.forms.general.height)
end

-- 物品页（P1 骨架）：两段式开关 + 禁用态演示（usePrettyStyle=false 时置灰，§八.3）
function ADT:BuildItem(content)
    local spec = {
        { type = "header", label = L.HEADING_ITEM },
        { type = "toggle", label = L.LABEL_TWO_STAGE, key = "twoStage",
            default = self:GetDefault("twoStage"), reset = "changed",
            enabled = function() return ADT:Get("usePrettyStyle") == true end },
        { type = "text", label = L.NOTE_TWO_STAGE },
        { type = "space", height = 4 },
        { type = "text", label = L.NOTE_PENDING },
    }
    self.forms.item = AF.Form.Build(content, spec, {
        get = function(key) return self:Get(key) end,
        set = function(key, value)
            self:Set(key, value)
            self:ApplyAll()
        end,
        width = AF.LAYOUT.contentW,
    })
    self.options.scroll:SetContentHeight(self.forms.item.height)
end

-- 占位页：分区标题 + 说明（真实选项在 P2–P7 接入）
function ADT:BuildPlaceholder(content, page)
    local key = "TAB_" .. tostring(page):upper()
    local title = AF.Widget.Text.SectionTitle(content, L[key] or tostring(page), AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0)
    local desc = AF.Widget.Text.Desc(content, L.NOTE_PENDING, AF.LAYOUT.contentW)
    desc:SetPoint("TOPLEFT", 0, -40)
    self.options.scroll:SetContentHeight(100)
end

-- 配置管理页：配置档切换/新建/复制/重命名/删除 + 导出/导入 + 当前档重置
function ADT:BuildConfig(content)
    local res = AF.Options.ProfilePage.Build(content, {
        db = self.profileDB,
        L = AF.L,
        notify = function(msg) self:Print(msg) end,
    })
    if res and res.height then self.options.scroll:SetContentHeight(res.height) end
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
            { label = "ABOUT_FEATURE_3_LABEL", text = "ABOUT_FEATURE_3" },
        },
        commands = "ABOUT_COMMANDS",
        author = "ABOUT_AUTHOR",
        creditsTitle = "ABOUT_CREDITS_TITLE",
        credits = { "ABOUT_CREDITS", "ABOUT_LICENSE" },
        notes = { "ABOUT_NOTES" },
    })
end
