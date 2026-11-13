-- English (default fallback, loaded unconditionally).
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L

L.ADDON_TITLE = "adeTooltip"
L.TAB_GENERAL = "General"
L.TAB_UNIT = "Unit"
L.TAB_ITEM = "Item"
L.TAB_SPELL = "Spell"
L.TAB_OTHER = "Other"
L.TAB_ANCHOR = "Anchor"
L.TAB_CONFIG = "Config Manager"
L.TAB_ABOUT = "About"

L.HEADING_LAYOUT = "LAYOUT"
L.HEADING_APPEARANCE = "APPEARANCE"
L.HEADING_ITEM = "ITEM"

L.LABEL_USE_PRETTY = "Use the new layout"
L.NOTE_USE_PRETTY = "On: PrettyTooltip-style panel. Off: the classic MiliUI layout (modifies native tooltip lines). Options that only affect the new layout are disabled while off."
L.LABEL_SCALE = "Scale"
L.LABEL_THEME_COLOR = "Theme color"
L.NOTE_THEME_COLOR = "Click to change the theme color (default yellow)."
L.LABEL_TWO_STAGE = "Two-stage layout (items/spells)"
L.NOTE_TWO_STAGE = "Splits the native tooltip into two blocks; lines appended by other addons are merged into the lower block. Only effective with the new layout."
L.NOTE_PENDING = "Options for this page land in later stages (see the dev plan P2-P7)."
L.LABEL_MINIMAP_SHOWN = "Show minimap button"

L.PREVIEW_TITLE = "Preview"
L.PREVIEW_NOTE = "Real categorized samples (with click-to-locate) arrive in P7. This is the P1 placeholder."
L.PREVIEW_PAGE = "Current page: %s"

L.TT_LEFT = "Left-click: open settings"
L.TT_DRAG = "Drag to reposition"

L.RESET_CONFIRM = "Reset all adeTooltip settings of the current profile to defaults?"
L.MSG_RESET = "Settings reset to defaults."
L.MSG_MINIMAP_SHOWN = "Minimap button shown."
L.MSG_MINIMAP_HIDDEN = "Minimap button hidden. Type /atip minimap to show it again."
L.MSG_CONFLICT = "MiliUI_Tooltip is loaded. Running two tooltip addons together is not recommended."
L.CMD_HELP = "Commands: /adeTooltip, /atip, /adeTooltip about, /adeTooltip minimap, /adeTooltip reset"

-- About page body: structured ABOUT_* keys consumed by AF.Template.AboutPage.Build.
L.ABOUT_CMD_LABEL = "Commands"
L.ABOUT_AUTHOR_LABEL = "Author"
L.ABOUT_DESC_1 = "Tooltip restyling for ADE v6: MiliUI_Tooltip as the blueprint, PrettyTooltip visuals for the new layout, PrimeTooltip for extra capabilities."
L.ABOUT_FEATURE_1_LABEL = "Two layouts"
L.ABOUT_FEATURE_1 = "The new PrettyTooltip-style panel or the classic MiliUI layout, toggled by 'Use the new layout'."
L.ABOUT_FEATURE_2_LABEL = "Two-stage"
L.ABOUT_FEATURE_2 = "Item/spell tooltips split into two blocks; lines from other addons merge into the lower block."
L.ABOUT_FEATURE_3_LABEL = "Options"
L.ABOUT_FEATURE_3 = "Eight pages in the multi-page layout, profile management, and a dockable preview component."
L.ABOUT_COMMANDS = "/adeTooltip  —  open or close the options window\n/atip  —  same as /adeTooltip\n/adeTooltip about  —  open this page\n/adeTooltip minimap  —  show or hide the minimap button\n/adeTooltip reset  —  reset the current profile (confirmation dialog)"
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "CREDITS"
L.ABOUT_CREDITS = "Blueprint: MiliUI_Tooltip. Visuals and modifiers: PrettyTooltip. Extra capabilities: PrimeTooltip."
L.ABOUT_LICENSE = "Released under the MIT license."
L.ABOUT_NOTES = "Built on ade_AddonFramework (b010). b001 is the P0/P1 skeleton; the render pipeline lands in P2-P9."
