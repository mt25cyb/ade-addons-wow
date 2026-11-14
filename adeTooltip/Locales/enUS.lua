local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L

L.ADDON_TITLE = "adeTooltip"
L.TAB_SETTINGS = "Settings"
L.TAB_MINIMAP = "Minimap"
L.TAB_PREVIEW = "Preview"
L.TAB_ABOUT = "About"

L.HEADING_GENERAL = "General"
L.LABEL_USE_NEW_LAYOUT = "Use New Layout"
L.NOTE_USE_NEW_LAYOUT = "Enable the rewritten panel (later stage); disable to use the classic route (in-place native tooltip editing)."
L.LABEL_SCALE = "Global Scale"
L.LABEL_THEME_COLOR = "Theme Color"

L.HEADING_MINIMAP = "Minimap"
L.LABEL_MINIMAP_SHOWN = "Show Minimap Button"
L.LABEL_MINIMAP_ANGLE = "Minimap Button Angle"

L.PREVIEW_NOTE = "Click a button below to preview a sample in a separate tooltip (reflects classic-route edits once implemented)."
L.PREVIEW_BTN_UNIT = "Preview: Player Unit"
L.PREVIEW_BTN_ITEM = "Preview: Item"
L.PREVIEW_BTN_SPELL = "Preview: Spell"

L.MSG_MINIMAP_SHOWN = "Minimap button shown."
L.MSG_MINIMAP_HIDDEN = "Minimap button hidden. Type /adt minimap to show it again."
L.CMD_HELP = "Commands: /adt, /adt about, /adt minimap"

L.ABOUT_DESC_1 = "adeTooltip: World of Warcraft tooltip enhancer (classic route first)."
L.ABOUT_FEATURE_1_LABEL = "Classic Route"
L.ABOUT_FEATURE_1 = "In-place native tooltip editing (class color / reaction color / item level / health bar, etc.), landed per-stage with live testing."
L.ABOUT_FEATURE_2_LABEL = "New Layout"
L.ABOUT_FEATURE_2 = "Optional rewritten panel (later stage; interface reserved for now)."
L.ABOUT_AUTHOR = "ade"
L.ABOUT_LICENSE = "License: MIT"
L.ABOUT_COMMANDS = "/adt, /adt about, /adt minimap"
