--[==[ adeStatPlus 多语言（enUS，全量默认）
    key 统一 SCREAMING_SNAKE_CASE。enUS 为首个注册且 silent=true；
    zhCN / zhTW 逐项覆写，key 集合必须一致（由 _tools/validate_adestatplus.py 校验）。
    属性名/排序依用户 2026-11-09 定稿表。 ]==]
local addonName = ...
-- ADE v6.5：私有 locale 表（不再经 ADE:RegisterLocale / AceLocale）
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns
ns.Loc = ns.Loc or {}

ns.Loc.enUS = {
    -- 分组名
    GRP_PRIMARY = "Primary",
    GRP_SECONDARY = "Secondary",
    GRP_TERTIARY = "Tertiary",
    GRP_DEFENSIVE = "Defensive",
    GRP_OTHERS = "Other",

    -- 属性全称（用户 2026-11-09 定稿英文名）
    STAT_STRENGTH = "Strength",
    STAT_AGILITY = "Agility",
    STAT_INTELLECT = "Intellect",
    STAT_STAMINA = "Stamina",
    STAT_CRIT = "Crit",
    STAT_HASTE = "Haste",
    STAT_MASTERY = "Mastery",
    STAT_VERS = "Vers",
    STAT_ARMOR = "Armor",
    STAT_AVOIDANCE = "Avoidance",
    STAT_LEECH = "Lifesteal",
    STAT_DODGE = "Dodge",
    STAT_PARRY = "Parry",
    STAT_BLOCK = "Block",
    STAT_STAGGER = "Stagger",
    STAT_LEVEL = "Level",
    STAT_ILVL = "Item Level",
    STAT_DURABILITY = "Durability",
    STAT_SPEED = "Speed",

    -- 属性缩写（enUS 用社区习惯缩写）
    ABBR_STRENGTH = "Str",
    ABBR_AGILITY = "Agi",
    ABBR_INTELLECT = "Int",
    ABBR_STAMINA = "Sta",
    ABBR_CRIT = "Crit",
    ABBR_HASTE = "Haste",
    ABBR_MASTERY = "Mast",
    ABBR_VERS = "Vers",
    ABBR_ARMOR = "Armor",
    ABBR_AVOIDANCE = "Avoid",
    ABBR_LEECH = "Leech",
    ABBR_DODGE = "Dodge",
    ABBR_PARRY = "Parry",
    ABBR_BLOCK = "Block",
    ABBR_STAGGER = "Stagger",
    ABBR_LEVEL = "Lvl",
    ABBR_ILVL = "iLvl",
    ABBR_DURABILITY = "Dura",
    ABBR_SPEED = "Speed",

    -- 设置页分类
    TAB_GENERAL = "General",
    TAB_CHARPANEL = "Character Panel",
    TAB_CONFIG = "Config Management",
    BTN_SORT_WINDOW = "Customize",
    GRP_BARS = "Bars",
    GRP_CHARTS = "Chart",

    -- 数据面板页：通用
    OPT_LOCK = "Lock panel",
    OPT_SCALE = "Panel scale",
    OPT_FONT = "Font",
    FONT_GAME_DEFAULT = "Game default",
    OPT_FONT_SIZE = "Font size",
    OPT_OUTLINE = "Outline",
    OUTLINE_NONE = "None",
    OUTLINE_NORMAL = "Outline",
    OUTLINE_THICK = "Thick",
    OPT_SHOW_GROUP_NAMES = "Show group names",
    OPT_ABBR = "Abbreviate stat names",
    OPT_BG = "Panel background",
    OPT_BG_ENABLE = "Enable background",
    OPT_BG_COLOR = "Background color",
    OPT_BG_ALPHA = "Background opacity",
    OPT_BG_BORDER = "Show border",
    OPT_SOURCE = "Stat recommendation source",
    SOURCE_NONE = "None",
    OPT_MINIMAP_HIDE = "Hide minimap icon",
    GRP_DISPLAY_COLOR_SORT = "Display / Color / Sort",
    OPT_COLOR_ILVL_BY_QUALITY = "Color item level by equipment quality",
    OPT_AUTO_COLOR_DURABILITY = "Auto-color durability by ratio",
    OPT_SORT_SECONDARY_BY_SOURCE = "Sort secondary by recommendation source",

    -- 数值显示风格（D53）
    OPT_TEXT_STYLE = "Value display style",
    OPT_SEGMENTED = "Segmented display",
    OPT_JOINED_ALIGN = "Text alignment",
    OPT_NAME_ALIGN = "Name column alignment",
    OPT_DATA_ALIGN = "Data column alignment",
    ALIGN_LEFT = "Left",
    ALIGN_CENTER = "Center",
    ALIGN_RIGHT = "Right",
    OPT_SECONDARY_PARTS = "Secondary data",
    OPT_TERTIARY_PARTS = "Tertiary data",
    PARTS_VALUE = "Value only",
    PARTS_PERCENT = "Percent only",
    PARTS_VALUE_PERCENT = "Value + Percent",
    PARTS_PERCENT_VALUE = "Percent + Value",
    OPT_FORMAT = "Display format",
    OPT_PERCENT_DECIMALS = "Percent decimals",
    OPT_ILVL_DECIMALS = "Item level decimals",
    OPT_VERS_MODE = "Versatility display",
    VERS_COMBINED = "Combined",
    VERS_SPLIT = "Damage / Reduction",

    -- 自动隐藏属性（D55）
    GRP_AUTO_HIDE = "Auto Hide",
    OPT_AUTO_HIDE_STATS = "Auto hide stats not shown in the character panel",
    OPT_HIDE_LEVEL_AT_MAX = "Hide level at max level",

    -- 数据面板进度条分组
    OPT_BAR_ENABLED = "Show bars",
    OPT_BAR_STYLE = "Bar display style",
    BAR_STYLE_SEPARATE = "Separate (below text)",
    BAR_STYLE_EMBEDDED = "Embedded (behind text)",
    OPT_BAR_HEIGHT = "Bar height",
    OPT_BAR_TEXTURE = "Bar texture",
    OPT_BAR_BG_ALPHA = "Bar background opacity",
    OPT_BAR_TEXTURE_ALPHA = "Bar texture opacity",
    OPT_BAR_SPARK = "Show spark",
    OPT_BAR_THRESHOLD = "Show threshold",

    -- 角色面板页
    OPT_CP_BAR_ENABLED = "Show bars (four secondary stats)",

    -- 角色面板页：图形组
    OPT_CHART_ENABLED = "Show chart|cff808080 (display effect poor, not recommended)|r",  -- temporary gray suffix: chart display quality is poor, not recommended
    OPT_CHART_STYLE = "Chart style",
    CHART_RADAR = "Radar",
    CHART_RING = "Ring",
    OPT_CHART_SIZE = "Chart size",
    OPT_RING_WIDTH = "Ring width",

    -- 排序窗口（列标题与段标题由用户修改后的 SortWindow.lua 消费）
    SORT_TITLE = "Display / Sort / Color",
    SORT_COL_SHOW = "Show",
    SORT_COL_ORDER = "Order",
    SORT_COL_COLOR = "Color",
    SORT_GROUP_SUFFIX = "(Group)",
    SORT_RESET_DISPLAY = "Reset display",
    SORT_RESET_ORDER = "Reset order",
    SORT_RESET_COLOR = "Reset colors",
    SORT_BY_SOURCE = "Sort by recommendation source",
    SORT_GROUP = "Group settings",
    SORT_PRIMARY = "Primary group settings",
    SORT_SECONDARY = "Secondary group settings",
    SORT_TERTIARY = "Tertiary group settings",
    SORT_DEFENSIVE = "Defensive group settings",

    -- 配置 / 命令 / 小地图
    ABOUT_DESC = "Attribute information panel for ADE v5. Grouping, independent sorting, inline bars and four-stat charts.",
    CMD_USAGE = "Usage: /adsp panel | config | sort",
    CMD_PANEL = "Toggle the stat panel",
    CMD_CONFIG = "Open settings",
    CMD_SORT = "Open the sort window",
    MM_LEFT = "Left-click: toggle panel",
    MM_RIGHT = "Right-click: open settings",
}
