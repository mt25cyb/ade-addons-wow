-- adeTimerHUD / Locales/enUS.lua — English
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
ns.Loc = ns.Loc or {}

ns.Loc.enUS = {
    GROUP_CLOCK = "Clock",
    SEC_CLOCK = "Clock Panel",
    NOTE_CLOCK = "Clock HUD: time (with optional short prefix) and alarm, with date and weekday to the right. Drag to move; use Scale to resize.",

    LABEL_SHOWN = "Show clock",
    LABEL_USE24 = "24-hour clock",
    LABEL_SHOW_PREFIX = "Show short prefix [S]/[L]",
    LABEL_SCALE = "Panel scale",
    LABEL_LOCKED = "Lock position",
    LABEL_SHOW_BORDER = "Show border",
    LABEL_FRAME_COLOR = "Background color",
    LABEL_FRAME_ALPHA = "Background opacity",
    LABEL_PANEL_ALPHA = "Panel opacity",
    LABEL_BORDER_COLOR = "Border color",
    LABEL_CENTER_X = "Center Horizontally - Time",
    LABEL_CENTER_PANEL = "Center Horizontally - Panel",

    SUBH_CONTENT = "Content",
    SUBH_APPEARANCE = "Appearance",
    SUBH_FONT_TIME = "Time Font",
    SUBH_FONT_ALARM = "Alarm Font",
    SUBH_FONT_DATE = "Date Font",
    SUBH_FONT_WEEKDAY = "Weekday Font",
    SUBH_FONT_MERIDIEM = "AM/PM Font",
    SUBH_FONT_PREFIX = "Prefix Font",

    OPT_TIMESOURCE = "Time Source",
    SRC_SERVER = "Server time",
    SRC_LOCAL = "Local time",
    OPT_MERIDIEM = "AM/PM Format",
    MERIDIEM_INTERNATIONAL = "International (AM/PM)",
    MERIDIEM_CHINESE = "Chinese periods (凌晨/上午/...)",
    MERIDIEM_ANCIENT = "Ancient Chinese hours (子时/丑时/...)",
    CN_PERIOD_LABELS = "凌晨,早晨,上午,中午,下午,傍晚,晚上",
    ANCIENT_HOUR_LABELS = "子时,丑时,寅时,卯时,辰时,巳时,午时,未时,申时,酉时,戌时,亥时",
    LABEL_FORCE_CHINESE_MERIDIEM = "Force Chinese format",
    NOTE_FORCE_CHINESE_MERIDIEM = "Chinese/ancient labels need glyphs missing on non-CJK clients. Turn on the switch below to use them (may render as tofu).",

    OPT_DATEMODE = "Date Panel",
    DATE_NONE = "Hidden",
    DATE_DATE = "Date only",
    DATE_WEEKDAY = "Weekday only",
    DATE_BOTH = "Date + Weekday",
    OPT_DATEFORMAT = "Date Format",
    LABEL_DATE_HIDE_YEAR = "Hide year in date",
    DATE_STYLE_LOCAL = "Local",
    DATE_STYLE_US = "US",
    DATE_STYLE_UK = "UK",
    OPT_WEEKDAY_STYLE = "Weekday Text",
    WEEKDAY_LOCAL_FULL = "Local · Full",
    WEEKDAY_LOCAL_SHORT = "Local · Short",
    WEEKDAY_EN_FULL = "English · Full",
    WEEKDAY_EN_SHORT = "English · Short",
    LABEL_USE_CLASS_COLOR = "Use Class Color",
    LABEL_CHILD_FONT_OFFSET = "Child panel font offset",
    NOTE_CHILD_FONT_OFFSET = "Base size 20, adjustable +/-8 (date, weekday, meridiem, prefix).",

    OPT_ALARM_ENABLED = "Show alarm",
    LABEL_ALARM_WARN_MINUTES = "Urgent threshold (min)",
    NOTE_ALARM_WARN_MINUTES = "Remain >10 min: green; n~10 min: orange; <=n min: red. Alarm time comes from Blizzard's Time Manager.",
    LABEL_ALARM_FLASH = "Flash when due",

    OPT_FONT = "Font",
    OPT_COLOR = "Color",
    OPT_OUTLINE = "Outline",
    OUTLINE_NONE = "None",
    OUTLINE_NORMAL = "Outline",
    OUTLINE_THICK = "Thick Outline",
    FONT_GAME_DEFAULT = "Game Default",

    LABEL_RESET_POSITION = "Reset Position & Scale",

    CMD_HELP = "Commands: /ath, /ath options, /ath reset",
    MSG_RESET = "Settings restored to defaults.",
    MSG_RESET_POSITION = "Clock position and scale reset.",
}
