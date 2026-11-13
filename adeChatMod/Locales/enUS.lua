-- 默认语言：英文。后续 zhCN / zhTW 按 GetLocale() 覆盖。
local ACM = _G.adeChatMod or {}
_G.adeChatMod = ACM
local L = ACM.L or {}
ACM.L = L

L.ADDON_TITLE = "adeChatMod"
L.TAB_SETTINGS = "Settings"
L.TAB_CONFIG = "Config Manager"
L.TAB_ABOUT = "About"

L.HEADING_APPEARANCE = "APPEARANCE"
L.HEADING_THEME = "THEME COLOR"
L.HEADING_CHANNELS = "CHANNELS"
L.HEADING_POSITION = "POSITION"
L.HEADING_FALLBACK = "FALLBACK POSITION"
L.HEADING_MINIMAP = "MINIMAP BUTTON"

L.LABEL_COLOR_SCHEME = "Button color"
L.LABEL_BTN_SIZE = "Button size"
L.LABEL_BTN_GAP = "Button gap"
L.LABEL_FONT_SIZE = "Font size"
L.LABEL_WORLD_CHANNEL = "World channel name"
L.LABEL_TRADE_CHANNEL = "Trade channel name"
L.LABEL_AUTO_JOIN = "Auto join world channel"
L.LABEL_AUTO_JOIN_DELAY = "Auto join delay"
L.LABEL_ATTACH_TARGET = "Attach frame (global name)"
L.LABEL_ATTACH_POINT = "Bar anchor point"
L.LABEL_ATTACH_RELATIVE_POINT = "Target anchor point"
L.LABEL_ATTACH_X = "Offset X"
L.LABEL_ATTACH_Y = "Offset Y"
L.LABEL_FALLBACK_X = "Fallback offset X"
L.LABEL_FALLBACK_Y = "Fallback offset Y"
L.LABEL_BAR_SHOWN = "Show channel bar"
L.LABEL_MINIMAP_SHOWN = "Show minimap button"
L.LABEL_RESET_MINIMAP_POS = "Reset button position"
L.LABEL_THEME_COLOR = "Theme color"
L.NOTE_THEME_COLOR = "Click to change the theme color (default: yellow)"

L.CHOICE_COLORFUL = "Colorful"
L.CHOICE_DEFAULT = "Default"

L.NOTE_APPEARANCE = "Changes apply immediately. Button color switches between the colorful scheme and the single gold one."
L.NOTE_CHANNELS = "Channel names are matched with GetChannelName. Auto join runs on a real login only, never on /reload."
L.NOTE_POSITION = "Attach frame is a global frame name (for example ChatFrame1EditBox). If it is missing or hidden, the fallback position is used."
L.NOTE_FALLBACK = "Fallback offsets are relative to UIParent's BOTTOMLEFT corner."
L.NOTE_MINIMAP = "Left-click the minimap button to show/hide the channel bar, right-click to open settings, drag to move it around the minimap. Hidden it? Type /acm minimap."

L.TT_LEFT = "Left-click: show/hide the channel bar"
L.TT_RIGHT = "Right-click: open settings"
L.TT_DRAG = "Drag to reposition"

L.RESET_CONFIRM = "Reset all adeChatMod settings to defaults?"
L.MSG_RESET = "settings reset to defaults."
L.MSG_MINIMAP_SHOWN = "minimap button shown."
L.MSG_MINIMAP_HIDDEN = "minimap button hidden. Type /acm minimap to show it again."
L.CMD_HELP = "commands: /acm, /acm about, /acm minimap, /acm reset"
L.STATUS_ATTACH_OK = "Attach frame found; the bar is anchored to it."
L.STATUS_ATTACH_MISSING = "Attach frame not found or hidden; fallback position is used."
L.STATUS_ATTACH_EMPTY = "Attach frame is empty; fallback position is used."

-- About page body: structured keys consumed by AF.Template.AboutPage.Build (spec: framework Template/AboutPage.lua).
-- Colors come from AF.AccentHex(); no hardcoded |cff...|r escapes in plain text lines.
L.ABOUT_DESC_1 = "A compact chat channel button bar with channel-name abbreviation, plus a minimap button and a settings window."
L.ABOUT_FEATURE_1_LABEL = "Channel bar"
L.ABOUT_FEATURE_1 = "12 channel/action buttons; attach to any global frame with offsets, fallback position when missing."
L.ABOUT_FEATURE_2_LABEL = "Abbreviation"
L.ABOUT_FEATURE_2 = "Channel names shown as short tags (for example [World]) by hooking ChatFrameN.AddMessage."
L.ABOUT_FEATURE_3_LABEL = "Settings"
L.ABOUT_FEATURE_3 = "Options apply immediately and are saved account-wide in adeChatModDB."
L.ABOUT_COMMANDS = "/acm  —  open or close the options window\n/acm about  —  open this page\n/acm minimap  —  show or hide the minimap button\n/acm reset  —  reset all settings (confirmation dialog)\n/adechatmod works the same as /acm."
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "CREDITS"
L.ABOUT_CREDITS = "ChannelBar by CHANGEEN (MIT); options window and minimap button based on PrimeTooltip (PrimeCraze)."
L.ABOUT_LICENSE = "Released under the MIT license."
L.ABOUT_NOTES = "Built on ade_AddonFramework: window, form rows, about page and theme color all come from the framework templates."
