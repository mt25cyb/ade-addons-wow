-- adeTimerHUD / Locales/zhCN.lua — 简体中文
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
ns.Loc = ns.Loc or {}

ns.Loc.zhCN = {
    GROUP_CLOCK = "时钟",
    SEC_CLOCK = "时钟面板",
    NOTE_CLOCK = "屏幕时钟：时间（可选缩写前缀）与闹钟，右侧为日期与星期；拖动面板可移动，缩放比例控制大小。",

    LABEL_SHOWN = "显示时钟",
    LABEL_USE24 = "24 小时制",
    LABEL_SHOW_PREFIX = "显示缩写前缀 [S]/[L]",
    LABEL_SCALE = "面板缩放",
    LABEL_LOCKED = "锁定位置",
    LABEL_SHOW_BORDER = "显示边框",
    LABEL_FRAME_COLOR = "背景颜色",
    LABEL_FRAME_ALPHA = "背景透明度",
    LABEL_PANEL_ALPHA = "面板透明度",
    LABEL_BORDER_COLOR = "边框颜色",
    LABEL_CENTER_X = "水平居中 - 时间",
    LABEL_CENTER_PANEL = "水平居中 - 面板",

    SUBH_CONTENT = "显示内容",
    SUBH_APPEARANCE = "外观",
    SUBH_FONT_TIME = "时间字体",
    SUBH_FONT_ALARM = "闹钟字体",
    SUBH_FONT_DATE = "日期字体",
    SUBH_FONT_WEEKDAY = "星期字体",
    SUBH_FONT_MERIDIEM = "AM/PM 字体",
    SUBH_FONT_PREFIX = "前缀字体",

    OPT_TIMESOURCE = "时间源",
    SRC_SERVER = "服务器时间",
    SRC_LOCAL = "本地时间",
    OPT_MERIDIEM = "AM/PM 格式",
    LABEL_FORCE_CHINESE_MERIDIEM = "强制使用中文格式",
    NOTE_FORCE_CHINESE_MERIDIEM = "非中日韩客户端可能缺少中文字形，开启后才能选择中文/古代时段格式（可能显示乱码）。",
    MERIDIEM_INTERNATIONAL = "国际通用（AM/PM）",
    MERIDIEM_CHINESE = "中文格式（凌晨/上午/…）",
    MERIDIEM_ANCIENT = "中国古代计时（子时/丑时/…）",
    CN_PERIOD_LABELS = "凌晨,早晨,上午,中午,下午,傍晚,晚上",
    ANCIENT_HOUR_LABELS = "子时,丑时,寅时,卯时,辰时,巳时,午时,未时,申时,酉时,戌时,亥时",

    OPT_DATEMODE = "日期面板",
    DATE_NONE = "不显示",
    DATE_DATE = "仅日期",
    DATE_WEEKDAY = "仅星期",
    DATE_BOTH = "日期 + 星期",
    OPT_DATEFORMAT = "日期格式",
    LABEL_DATE_HIDE_YEAR = "日期不显示年份",
    DATE_STYLE_LOCAL = "本地语言",
    DATE_STYLE_US = "美式",
    DATE_STYLE_UK = "英式",
    OPT_WEEKDAY_STYLE = "星期文本",
    WEEKDAY_LOCAL_FULL = "本地语言 · 全称",
    WEEKDAY_LOCAL_SHORT = "本地语言 · 缩写",
    WEEKDAY_EN_FULL = "英文 · 全称",
    WEEKDAY_EN_SHORT = "英文 · 缩写",
    LABEL_USE_CLASS_COLOR = "显示职业颜色",
    LABEL_CHILD_FONT_OFFSET = "子面板字号微调",
    NOTE_CHILD_FONT_OFFSET = "以 20 号为基础，可 ±8 微调（日期/星期/时段标记/前缀）。",

    OPT_ALARM_ENABLED = "显示闹钟",
    LABEL_ALARM_WARN_MINUTES = "紧急阈值（分钟）",
    NOTE_ALARM_WARN_MINUTES = "剩余大于10分钟显示绿色，n 至 10 分钟显示橙色，小于等于 n 分钟显示红色；目标时刻取自暴雪原生时钟设置的提醒时间。",
    LABEL_ALARM_FLASH = "到期闪烁",

    OPT_FONT = "字体",
    OPT_COLOR = "颜色",
    OPT_OUTLINE = "描边",
    OUTLINE_NONE = "无",
    OUTLINE_NORMAL = "描边",
    OUTLINE_THICK = "粗描边",
    FONT_GAME_DEFAULT = "游戏默认",

    LABEL_RESET_POSITION = "重置位置与缩放",

    CMD_HELP = "命令：/ath、/ath options、/ath reset",
    MSG_RESET = "设置已恢复默认。",
    MSG_RESET_POSITION = "时钟位置与缩放已重置。",
}
