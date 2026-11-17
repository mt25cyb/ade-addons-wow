-- Default locale: enUS. zhCN / zhTW override below when GetLocale() matches.
local ACB = _G.adeChatBar or {}
_G.adeChatBar = ACB
local L = ACB.L or {}
ACB.L = L

L.ADDON_TITLE = "adeChatBar"
L.GROUP_UI = "UI"
L.GROUP_LAYOUT = "Layout"

L.HEADING_APPEARANCE = "APPEARANCE"
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

L.CHOICE_COLORFUL = "Colorful"
L.CHOICE_DEFAULT = "Default"

L.NOTE_APPEARANCE = "Changes apply immediately. Button color switches between the colorful scheme and the single gold one."
L.NOTE_CHANNELS = "Channel names are matched with GetChannelName. Auto join runs on a real login only, never on /reload."
L.NOTE_POSITION = "Attach frame is a global frame name (for example ChatFrame1EditBox). If it is missing or hidden, the fallback position is used."
L.NOTE_FALLBACK = "Fallback offsets are relative to UIParent's BOTTOMLEFT corner."
L.NOTE_MINIMAP = "Left-click the minimap button to show/hide the channel bar, right-click to open settings, drag to move it around the minimap. Hidden it? Type /acb minimap."

L.TT_LEFT = "Left-click: show/hide the channel bar"
L.TT_RIGHT = "Right-click: open settings"
L.TT_DRAG = "Drag to reposition"

L.MSG_RESET = "settings reset to defaults."
L.MSG_MINIMAP_SHOWN = "minimap button shown."
L.MSG_MINIMAP_HIDDEN = "minimap button hidden. Type /acb minimap to show it again."
L.CMD_HELP = "commands: /acb, /acb minimap, /acb reset"
L.STATUS_ATTACH_OK = "Attach frame found; the bar is anchored to it."
L.STATUS_ATTACH_MISSING = "Attach frame not found or hidden; fallback position is used."
L.STATUS_ATTACH_EMPTY = "Attach frame is empty; fallback position is used."
