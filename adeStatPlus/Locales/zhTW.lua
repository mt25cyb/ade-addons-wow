--[==[ adeStatPlus 多語言（繁體中文），逐項覆寫 enUS 全部 key ]==]
local addonName = ...
-- ADE v6.5：私有 locale 表
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns
ns.Loc = ns.Loc or {}

ns.Loc.zhTW = {
    -- 分組名
    GRP_PRIMARY = "主屬性",
    GRP_SECONDARY = "副屬性",
    GRP_TERTIARY = "第三屬性",
    GRP_DEFENSIVE = "防護屬性",
    GRP_OTHERS = "其他",

    -- 屬性全稱（用戶 2026-11-09 定稿中文名，繁體）
    STAT_STRENGTH = "力量",
    STAT_AGILITY = "敏捷",
    STAT_INTELLECT = "智力",
    STAT_STAMINA = "耐力",
    STAT_CRIT = "爆擊",
    STAT_HASTE = "急速",
    STAT_MASTERY = "精通",
    STAT_VERS = "全能",
    STAT_ARMOR = "護甲",
    STAT_AVOIDANCE = "閃避",
    STAT_LEECH = "吸血",
    STAT_DODGE = "躲閃",
    STAT_PARRY = "招架",
    STAT_BLOCK = "格擋",
    STAT_STAGGER = "醉拳",
    STAT_LEVEL = "等級",
    STAT_ILVL = "裝備等級",
    STAT_DURABILITY = "裝備耐久度",
    STAT_SPEED = "移動速度",

    -- 屬性縮寫
    ABBR_STRENGTH = "力量",
    ABBR_AGILITY = "敏捷",
    ABBR_INTELLECT = "智力",
    ABBR_STAMINA = "耐力",
    ABBR_CRIT = "爆擊",
    ABBR_HASTE = "急速",
    ABBR_MASTERY = "精通",
    ABBR_VERS = "全能",
    ABBR_ARMOR = "護甲",
    ABBR_AVOIDANCE = "閃避",
    ABBR_LEECH = "吸血",
    ABBR_PARRY = "招架",
    ABBR_BLOCK = "格擋",
    ABBR_DODGE = "閃躲",
    ABBR_STAGGER = "醉拳",
    ABBR_LEVEL = "等級",
    ABBR_ILVL = "裝等",
    ABBR_DURABILITY = "耐久",
    ABBR_SPEED = "移速",

    -- 設定頁分類
    TAB_GENERAL = "常規",
    TAB_CHARPANEL = "角色面板",
    TAB_CONFIG = "設定管理",
    BTN_SORT_WINDOW = "自訂",
    GRP_BARS = "進度條",
    GRP_CHARTS = "圖形",

    -- 資料面板頁：通用
    OPT_LOCK = "鎖定面板",
    OPT_SCALE = "面板縮放",
    OPT_FONT = "字型",
    FONT_GAME_DEFAULT = "遊戲預設字體",
    OPT_FONT_SIZE = "字型大小",
    OPT_OUTLINE = "描邊",
    OUTLINE_NONE = "無",
    OUTLINE_NORMAL = "描邊",
    OUTLINE_THICK = "粗描邊",
    OPT_SHOW_GROUP_NAMES = "顯示分組名",
    OPT_ABBR = "屬性名縮寫",
    OPT_BG = "面板背景",
    OPT_BG_ENABLE = "啟用背景",
    OPT_BG_COLOR = "背景顏色",
    OPT_BG_ALPHA = "背景透明度",
    OPT_BG_BORDER = "顯示邊框",
    OPT_SOURCE = "屬性推薦值來源",
    SOURCE_NONE = "無",
    OPT_MINIMAP_HIDE = "隱藏小地圖圖示",
    GRP_DISPLAY_COLOR_SORT = "顯示 / 顏色 / 排序",
    OPT_COLOR_ILVL_BY_QUALITY = "按裝備品質著色裝等",
    OPT_AUTO_COLOR_DURABILITY = "按比例自動著色耐久度",
    OPT_SORT_SECONDARY_BY_SOURCE = "依屬性推薦值來源排序副屬性",

    -- 數值顯示風格（D53）
    OPT_TEXT_STYLE = "數值顯示風格",
    OPT_SEGMENTED = "分段顯示",
    OPT_JOINED_ALIGN = "文字對齊",
    OPT_NAME_ALIGN = "名稱欄文字對齊",
    OPT_DATA_ALIGN = "資料欄文字對齊",
    ALIGN_LEFT = "靠左",
    ALIGN_CENTER = "置中",
    ALIGN_RIGHT = "靠右",
    OPT_SECONDARY_PARTS = "副屬性資料",
    OPT_TERTIARY_PARTS = "第三屬性資料",
    PARTS_VALUE = "僅數值",
    PARTS_PERCENT = "僅百分比",
    PARTS_VALUE_PERCENT = "數值+百分比",
    PARTS_PERCENT_VALUE = "百分比+數值",
    OPT_FORMAT = "顯示格式",
    OPT_PERCENT_DECIMALS = "百分比小數位",
    OPT_ILVL_DECIMALS = "物品等級小數位",
    OPT_VERS_MODE = "臨機應變顯示",
    VERS_COMBINED = "合併",
    VERS_SPLIT = "傷害 / 減傷",

    -- 自動隱藏屬性（D55）
    GRP_AUTO_HIDE = "自動隱藏",
    OPT_AUTO_HIDE_STATS = "自動隱藏角色面板中未顯示的屬性",
    OPT_HIDE_LEVEL_AT_MAX = "滿級時隱藏等級",

    -- 資料面板進度條分組
    OPT_BAR_ENABLED = "顯示進度條",
    OPT_BAR_STYLE = "條顯示風格",
    BAR_STYLE_SEPARATE = "分離顯示（文字下方）",
    BAR_STYLE_EMBEDDED = "內嵌顯示（文字襯底）",
    OPT_BAR_HEIGHT = "條高度",
    OPT_BAR_TEXTURE = "條材質",
    OPT_BAR_BG_ALPHA = "條背景透明度",
    OPT_BAR_TEXTURE_ALPHA = "條材質透明度",
    OPT_BAR_SPARK = "顯示火花",
    OPT_BAR_THRESHOLD = "顯示閥值",

    -- 角色面板頁
    OPT_CP_BAR_ENABLED = "顯示進度條（四個副屬性）",

    -- 角色面板頁：圖形組
    OPT_CHART_ENABLED = "顯示圖形|cff808080(顯示效果不佳，不推薦開啟)|r",  -- 臨時灰色後綴：圖形顯示效果差，不推薦開啟
    OPT_CHART_STYLE = "圖形風格",
    CHART_RADAR = "雷達圖",
    CHART_RING = "環形圖",
    OPT_CHART_SIZE = "圖形尺寸",
    OPT_RING_WIDTH = "環寬度",

    -- 排序視窗
    SORT_TITLE = "顯示 / 排序 / 顏色",
    SORT_COL_SHOW = "顯示",
    SORT_COL_ORDER = "排序",
    SORT_COL_COLOR = "顏色",
    SORT_GROUP_SUFFIX = "(組)",
    SORT_RESET_DISPLAY = "重置顯示",
    SORT_RESET_ORDER = "重置排序",
    SORT_RESET_COLOR = "重置顏色",
    SORT_BY_SOURCE = "依屬性推薦值來源",
    SORT_GROUP = "分組設定",
    SORT_PRIMARY = "主屬性組設定",
    SORT_SECONDARY = "副屬性組設定",
    SORT_TERTIARY = "第三屬性組設定",
    SORT_DEFENSIVE = "防護屬性組設定",

    -- 設定檔 / 命令 / 小地圖
    ABOUT_DESC = "ADE v5 屬性資訊面板：屬性分組、獨立排序、行內進度條與四維圖形。",
    CMD_USAGE = "用法：/adsp panel | config | sort",
    CMD_PANEL = "顯示 / 隱藏面板",
    CMD_CONFIG = "開啟設定",
    CMD_SORT = "開啟排序視窗",
    MM_LEFT = "左鍵：顯示 / 隱藏面板",
    MM_RIGHT = "右鍵：開啟設定",
}
