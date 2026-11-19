--[==[ adeStatPlus 多语言（简体中文），逐项覆写 enUS 全部 key
    注意：「属性缩写」段落依用户 2026-11-09 手动修改后的代码，原样保留。 ]==]
local addonName = ...
-- ADE v6.5：私有 locale 表
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns
ns.Loc = ns.Loc or {}

ns.Loc.zhCN = {
    -- 分组名
    GRP_PRIMARY = "主属性",
    GRP_SECONDARY = "副属性",
    GRP_TERTIARY = "第三属性",
    GRP_DEFENSIVE = "防护属性",
    GRP_OTHERS = "其他",

    -- 属性全称（用户 2026-11-09 定稿中文名）
    STAT_STRENGTH = "力量",
    STAT_AGILITY = "敏捷",
    STAT_INTELLECT = "智力",
    STAT_STAMINA = "耐力",
    STAT_CRIT = "爆击",
    STAT_HASTE = "急速",
    STAT_MASTERY = "精通",
    STAT_VERS = "全能",
    STAT_ARMOR = "护甲",
    STAT_AVOIDANCE = "闪避",
    STAT_LEECH = "吸血",
    STAT_DODGE = "躲闪",
    STAT_PARRY = "招架",
    STAT_BLOCK = "格挡",
    STAT_STAGGER = "醉拳",
    STAT_LEVEL = "等级",
    STAT_ILVL = "装备等级",
    STAT_DURABILITY = "装备耐久度",
    STAT_SPEED = "移动速度",

    -- 属性缩写（依用户 2026-11-09 修改后的代码，原样保留）
    ABBR_STRENGTH = "力量",
    ABBR_AGILITY = "敏捷",
    ABBR_INTELLECT = "智力",
    ABBR_STAMINA = "耐力",
    ABBR_CRIT = "爆击",
    ABBR_HASTE = "急速",
    ABBR_MASTERY = "精通",
    ABBR_VERS = "全能",
    ABBR_ARMOR = "护甲",
    ABBR_AVOIDANCE = "闪避",
    ABBR_LEECH = "吸血",
    ABBR_PARRY = "招架",
    ABBR_BLOCK = "格挡",
    ABBR_DODGE = "躲闪",
    ABBR_STAGGER = "醉拳",
    ABBR_LEVEL = "等级",
    ABBR_ILVL = "装等",
    ABBR_DURABILITY = "耐久",
    ABBR_SPEED = "移速",

    -- 设置页分类
    TAB_GENERAL = "常规",
    TAB_CHARPANEL = "角色面板",
    TAB_CONFIG = "配置管理",
    BTN_SORT_WINDOW = "自定义",
    GRP_BARS = "进度条",
    GRP_CHARTS = "图形",

    -- 数据面板页：通用
    OPT_LOCK = "锁定面板",
    OPT_SCALE = "面板缩放",
    OPT_FONT = "字体",
    FONT_GAME_DEFAULT = "游戏默认字体",
    OPT_FONT_SIZE = "字号",
    OPT_OUTLINE = "描边",
    OUTLINE_NONE = "无",
    OUTLINE_NORMAL = "描边",
    OUTLINE_THICK = "粗描边",
    OPT_SHOW_GROUP_NAMES = "显示分组名",
    OPT_ABBR = "属性名缩写",
    OPT_BG = "面板背景",
    OPT_BG_ENABLE = "启用背景",
    OPT_BG_COLOR = "背景颜色",
    OPT_BG_ALPHA = "背景透明度",
    OPT_BG_BORDER = "显示边框",
    OPT_SOURCE = "属性推荐值来源",
    SOURCE_NONE = "无",
    OPT_MINIMAP_HIDE = "隐藏小地图图标",
    GRP_DISPLAY_COLOR_SORT = "显示 / 颜色 / 排序",
    OPT_COLOR_ILVL_BY_QUALITY = "按装备品质着色装等",
    OPT_AUTO_COLOR_DURABILITY = "按比例自动着色耐久度",
    OPT_SORT_SECONDARY_BY_SOURCE = "依属性推荐值来源排序副属性",

    -- 数值显示风格（D53）
    OPT_TEXT_STYLE = "数值显示风格",
    OPT_SEGMENTED = "分段显示",
    OPT_JOINED_ALIGN = "文本对齐",
    OPT_NAME_ALIGN = "名称列文本对齐",
    OPT_DATA_ALIGN = "数据列文本对齐",
    ALIGN_LEFT = "左对齐",
    ALIGN_CENTER = "居中",
    ALIGN_RIGHT = "右对齐",
    OPT_SECONDARY_PARTS = "副属性数据",
    OPT_TERTIARY_PARTS = "第三属性数据",
    PARTS_VALUE = "仅数值",
    PARTS_PERCENT = "仅百分比",
    PARTS_VALUE_PERCENT = "数值+百分比",
    PARTS_PERCENT_VALUE = "百分比+数值",
    OPT_FORMAT = "显示格式",
    OPT_PERCENT_DECIMALS = "百分比小数位",
    OPT_ILVL_DECIMALS = "物品等级小数位",
    OPT_VERS_MODE = "全能显示",
    VERS_COMBINED = "合并",
    VERS_SPLIT = "伤害 / 减伤",

    -- 自动隐藏属性（D55）
    GRP_AUTO_HIDE = "自动隐藏",
    OPT_AUTO_HIDE_STATS = "自动隐藏角色面板中未显示的属性",
    OPT_HIDE_LEVEL_AT_MAX = "满级时隐藏等级",

    -- 数据面板进度条分组
    OPT_BAR_ENABLED = "显示进度条",
    OPT_BAR_STYLE = "条显示风格",
    BAR_STYLE_SEPARATE = "分离显示（文本下方）",
    BAR_STYLE_EMBEDDED = "内嵌显示（文本衬底）",
    OPT_BAR_HEIGHT = "条高度",
    OPT_BAR_TEXTURE = "条材质",
    OPT_BAR_BG_ALPHA = "条背景透明度",
    OPT_BAR_TEXTURE_ALPHA = "条材质透明度",
    OPT_BAR_SPARK = "显示火花",
    OPT_BAR_THRESHOLD = "显示阀值",

    -- 角色面板页
    OPT_CP_BAR_ENABLED = "显示进度条（四个副属性）",

    -- 角色面板页：图形组
    OPT_CHART_ENABLED = "显示图形|cff808080(显示效果不佳，不推荐开启)|r",  -- 临时灰色后缀：图形显示效果差，不推荐开启（后续移除时改回原值）
    OPT_CHART_STYLE = "图形风格",
    CHART_RADAR = "雷达图",
    CHART_RING = "环形图",
    OPT_CHART_SIZE = "图形尺寸",
    OPT_RING_WIDTH = "环宽度",

    -- 排序窗口
    SORT_TITLE = "显示 / 排序 / 颜色",
    SORT_COL_SHOW = "显示",
    SORT_COL_ORDER = "排序",
    SORT_COL_COLOR = "颜色",
    SORT_GROUP_SUFFIX = "(组)",
    SORT_RESET_DISPLAY = "重置显示",
    SORT_RESET_ORDER = "重置排序",
    SORT_RESET_COLOR = "重置颜色",
    SORT_BY_SOURCE = "依属性推荐值来源",
    SORT_GROUP = "分组设置",
    SORT_PRIMARY = "主属性组设置",
    SORT_SECONDARY = "副属性组设置",
    SORT_TERTIARY = "第三属性组设置",
    SORT_DEFENSIVE = "防护属性组设置",

    -- 配置 / 命令 / 小地图
    ABOUT_DESC = "ADE v5 属性信息面板：属性分组、独立排序、行内进度条与四维图形。",
    CMD_USAGE = "用法：/adsp panel | config | sort",
    CMD_PANEL = "显示 / 隐藏面板",
    CMD_CONFIG = "打开设置",
    CMD_SORT = "打开排序窗口",
    MM_LEFT = "左键：显示 / 隐藏面板",
    MM_RIGHT = "右键：打开设置",
}
