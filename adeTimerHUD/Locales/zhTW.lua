-- adeTimerHUD / Locales/zhTW.lua — 繁體中文
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
ns.Loc = ns.Loc or {}

ns.Loc.zhTW = {
    GROUP_CLOCK = "時鐘",
    SEC_CLOCK = "時鐘面板",
    NOTE_CLOCK = "螢幕時鐘：時間（可選縮寫前綴）與鬧鐘，右側為日期與星期；拖曳面板可移動，縮放比例控制大小。",

    LABEL_SHOWN = "顯示時鐘",
    LABEL_USE24 = "24 小時制",
    LABEL_SHOW_PREFIX = "顯示縮寫前綴 [S]/[L]",
    LABEL_SCALE = "面板縮放",
    LABEL_LOCKED = "鎖定位置",
    LABEL_SHOW_BORDER = "顯示邊框",
    LABEL_FRAME_COLOR = "背景顏色",
    LABEL_FRAME_ALPHA = "背景透明度",
    LABEL_PANEL_ALPHA = "面板透明度",
    LABEL_BORDER_COLOR = "邊框顏色",
    LABEL_CENTER_X = "水平置中 - 時間",
    LABEL_CENTER_PANEL = "水平置中 - 面板",

    SUBH_CONTENT = "顯示內容",
    SUBH_APPEARANCE = "外觀",
    SUBH_FONT_TIME = "時間字體",
    SUBH_FONT_ALARM = "鬧鐘字體",
    SUBH_FONT_DATE = "日期字體",
    SUBH_FONT_WEEKDAY = "星期字體",
    SUBH_FONT_MERIDIEM = "AM/PM 字體",
    SUBH_FONT_PREFIX = "前綴字體",

    OPT_TIMESOURCE = "時間來源",
    SRC_SERVER = "伺服器時間",
    SRC_LOCAL = "本機時間",
    OPT_MERIDIEM = "AM/PM 格式",
    LABEL_FORCE_CHINESE_MERIDIEM = "強制使用中文格式",
    NOTE_FORCE_CHINESE_MERIDIEM = "非中日韓客戶端可能缺少中文字形，開啟後才能選擇中文/古代時段格式（可能顯示亂碼）。",
    MERIDIEM_INTERNATIONAL = "國際通用（AM/PM）",
    MERIDIEM_CHINESE = "中文格式（凌晨/上午/…）",
    MERIDIEM_ANCIENT = "中國古代計時（子時/丑時/…）",
    CN_PERIOD_LABELS = "凌晨,早晨,上午,中午,下午,傍晚,晚上",
    ANCIENT_HOUR_LABELS = "子時,丑時,寅時,卯時,辰時,巳時,午時,未時,申時,酉時,戌時,亥時",

    OPT_DATEMODE = "日期面板",
    DATE_NONE = "不顯示",
    DATE_DATE = "僅日期",
    DATE_WEEKDAY = "僅星期",
    DATE_BOTH = "日期 + 星期",
    OPT_DATEFORMAT = "日期格式",
    LABEL_DATE_HIDE_YEAR = "日期不顯示年份",
    DATE_STYLE_LOCAL = "本地語言",
    DATE_STYLE_US = "美式",
    DATE_STYLE_UK = "英式",
    OPT_WEEKDAY_STYLE = "星期文字",
    WEEKDAY_LOCAL_FULL = "本地語言 · 全稱",
    WEEKDAY_LOCAL_SHORT = "本地語言 · 縮寫",
    WEEKDAY_EN_FULL = "英文 · 全稱",
    WEEKDAY_EN_SHORT = "英文 · 縮寫",
    LABEL_USE_CLASS_COLOR = "顯示職業顏色",
    LABEL_CHILD_FONT_OFFSET = "子面板字級微調",
    NOTE_CHILD_FONT_OFFSET = "以 20 號為基礎，可 ±8 微調（日期/星期/時段標記/前綴）。",

    OPT_ALARM_ENABLED = "顯示鬧鐘",
    LABEL_ALARM_WARN_MINUTES = "緊急閾值（分鐘）",
    NOTE_ALARM_WARN_MINUTES = "剩餘大於10分鐘顯示綠色，n 至 10 分鐘顯示橙色，小於等於 n 分鐘顯示紅色；目標時刻取自暴雪原生時鐘設定的提醒時間。",
    LABEL_ALARM_FLASH = "到期閃爍",

    OPT_FONT = "字體",
    OPT_COLOR = "顏色",
    OPT_OUTLINE = "描邊",
    OUTLINE_NONE = "無",
    OUTLINE_NORMAL = "描邊",
    OUTLINE_THICK = "粗描邊",
    FONT_GAME_DEFAULT = "遊戲預設",

    LABEL_RESET_POSITION = "重置位置與縮放",

    CMD_HELP = "命令：/ath、/ath options、/ath reset",
    MSG_RESET = "設定已恢復預設。",
    MSG_RESET_POSITION = "時鐘位置與縮放已重置。",
}
