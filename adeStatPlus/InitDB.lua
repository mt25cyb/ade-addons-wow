--[==[ 默认配置（唯一来源）
    ADE v6.5：存档名保持 ADEDB_ADESTATPLUS 不变，经 ade_UIKit.DB.MergeDefaults 合并默认值。

    2026-11-09 五次澄清后结构：
      · 数值显示风格：默认「不分段」= `<名称>: <数据>` 单串 + 整体文本对齐；
        开启「分段显示」= 左名称 / 右数据，各自独立对齐，数据列可拆两组。
      · 安全间距固定 4（文本测量后追加、列间与背景留白）。
      · 自动隐藏属性：第三属性、防护属性各自独立开关。
      · 防护组不再有「仅防护专精」显示限制；主属性按专精只显示一个。
      · 属性名与顺序依用户 2026-11-09 定稿表。 ]==]
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

-- ADE v6.5：按客户端语言选定私有 locale 表（三个 locale 文件已在 TOC 中先于本文件加载）。
ns.L = ns.Loc and (ns.Loc[GetLocale()] or ns.Loc.enUS) or {}

ns.defaults = {
    profile = {
        abbr = false,               -- 属性名缩写开关（中文缩写依用户修改后的 Locales）
        recommendSource = "none",   -- 推荐值来源：none / 各已安装适配器 key（D23/D29）
        panel = {
            point = "CENTER", x = 0, y = 200,
            scale = 1,              -- 缩放，设置页滑条（不接滚轮）
            locked = false,
            collapsed = false,      -- 只 Hide 内容帧，25×25 锚点容器与按钮不变
            shown = true,           -- 面板显隐（斜杠命令 / 小地图右键切换）
            showGroupNames = false, -- 分组名整行居中，可选显隐
            autoHideStats = true,   -- 统一自动隐藏：角色面板不显示的属性（第三/防护组一并生效）
            hideLevelAtMax = true,  -- 满级时隐藏「等级」属性（默认启用，D79）
            colorIlvlByQuality = false,   -- 按装备品质着色装等（D88）
            autoColorDurability = false,  -- 按比例自动着色耐久度（D88）
            background = {
                enabled = false,
                color = { r = 0.04, g = 0.04, b = 0.04, a = 0.40 },
                border = false
            },
        },
        font = {
            face = "Game Default",      -- 字体：游戏默认（Modules/Media.lua 的 Media.GAME_DEFAULT；路径取 GameFontNormal:GetFont()）
            size = 12,                  -- 字号
            outline = "OUTLINE",        -- 描边：NONE / OUTLINE / THICKOUTLINE（无加粗）
        },
        -- 数值显示风格（D53）：segmented=false 时单串拼接，true 时分左右两段
        format = {
            segmented = false,          -- 分段显示，默认不启用
            joinedAlign = "LEFT",       -- 不分段模式专属：LEFT / CENTER / RIGHT（默认左）
            nameAlign = "LEFT",         -- 分段模式名称列：LEFT / RIGHT（默认右）
            dataAlign = "RIGHT",        -- 分段模式数据列：LEFT / RIGHT（默认左）
            secondaryParts = "VALUE_PERCENT",  -- 副属性数据组合
            tertiaryParts = "VALUE_PERCENT",   -- 第三属性数据组合
            percentDecimals = 2,        -- 所有百分比的小数位
            ilvlDecimals = 1,           -- 物品等级的小数位（其它「值」固定整数）
            versatility = "combined",   -- 全能：combined / split（伤害与减伤分开）
        },
        bars = {                    -- 「数据面板」进度条分组设置
            enabled = true,         -- 显示进度条
            style = "separate",     -- 条显示风格：separate / embedded
            texture = "adeStatPlus Noodle",
            height = 4,             -- 条高度（embedded 时跟随字号、设置项禁用）
            bgAlpha = 0.2,          -- 条背景透明度
            textureAlpha = 0.6,     -- 条材质透明度（D69）
            spark = false,
            showThreshold = true,
        },
        charPanel = {               -- 「角色面板」页：进度条 + 图形，均挂到原生面板内部
            bars = {
                enabled = true,
                texture = "adeStatPlus Noodle",
                bgAlpha = 0.4,
                textureAlpha = 1.0, -- 条材质透明度（D69）
                spark = true,
                showThreshold = true,
            },
            -- 图形（Radar/Ring）功能已删除（用户 2026-11-17）；旧存档残留 charts 键不消费。
        },
        order = {
            blocks    = { "level","ilvl","primary","secondary","tertiary","defensive","durability","speed" },
            primary   = { "strength","agility","intellect","stamina" },  -- 力/敏/智按专精只显示一个
            secondary = { "crit","haste","mastery","vers" },
            secondaryBySource = false,  -- true=依属性推荐值来源排序（D24）
            tertiary  = { "armor","avoidance","leech" },
            defensive = { "dodge","parry","block","stagger" },  -- 用户 2026-11-09 定稿顺序
        },
        -- 四组显示开关与组色（primary / secondary 强制显示，勾选框灰显锁定，D2）
        -- defensive 已无 mode 字段：删除「仅防护专精显示」选项与显示限制（D54）
        groups = {
            primary   = { enabled = true },
            secondary = { enabled = true },
            tertiary  = { enabled = true },
            defensive = { enabled = true },
        },
        -- 每属性独立开关；颜色 nil = 回退 Stats 默认色（Stats/Stats.lua:64-80）
        stats = {
            strength  = { enabled = true },
            agility   = { enabled = true },
            intellect = { enabled = true },
            stamina   = { enabled = true },
            crit      = { enabled = true },
            haste     = { enabled = true },
            mastery   = { enabled = true },
            vers      = { enabled = true },
            armor     = { enabled = true },
            avoidance = { enabled = true },
            leech     = { enabled = true },
            parry     = { enabled = true },
            block     = { enabled = true },
            dodge     = { enabled = true },
            stagger   = { enabled = true },
        },
        others = {
            level      = { enabled = true, color = { r = 1, g = 1, b = 0 } },  -- 默认黄色 #FFFF00（D88）
            ilvl       = { enabled = true },
            durability = { enabled = true },
            speed      = { enabled = true },
        },
        minimap = { hide = false, angle = 200 },
    },
}
