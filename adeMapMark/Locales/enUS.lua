-- adeMapMark - English locale
local addonName = ...
local ns = _G.adeMapMark
local L = ns.L

L.ADDON_TAG = "ADE"

L.MARK_TITLE = "Title"
L.MARK_NOTE = "Note"
L.MARK_COORDS = "Coordinates"
L.MARK_SIZE = "Size"
L.MARK_COLOR = "Color"
L.MARK_GRAYSCALE = "Grayscale"
L.MARK_FAVORITE = "Favorite"
L.MARK_ADD = "Add Marker"
L.MARK_UPDATE = "Update"
L.MARK_DELETE = "Delete"
L.MARK_EDIT = "Edit Marker"
L.MARK_GOTO = "Navigate"
L.MARK_BIG_EDITOR = "Large Editor"
L.MARK_FAVORITES = "Favorites"
L.MARK_ALL = "All Markers"
L.MARK_NO_MARKS = "No markers on this map."
L.MARK_HINT_CLICK = "Click map to pick coordinates"
L.MARK_DEFAULT_TITLE = "New Marker"

L.PROVIDER_SOURCE = "Source"
L.RESET_PROVIDER_OVERRIDE = "Restore built-in provider data (applies immediately; no need to click Update)"
L.PROVIDER_SECTION = "Data Providers"
L.PROVIDER_ENABLE = "Enable package"
L.PROVIDER_EXPAND = "Expand"
L.PROVIDER_MARKS = "%d markers"
L.PROVIDER_NO_MARKS = "No data providers registered."

L.SETTINGS = "Settings"
L.SETTINGS_GENERAL = "General"
L.SETTINGS_MARKERS = "Markers"
L.SETTINGS_TOMTOM = "Use TomTom for navigation"
L.SETTINGS_LEFT_CLICK = "Left click opens editor"
L.SETTINGS_MINIMAP = "Show markers on minimap"
L.SETTINGS_ARROW = "Show player arrow"
L.SETTINGS_PROVIDERS = "Data Providers"
L.SETTINGS_CLOSE = "Close"

L.COMMAND_USAGE = "Usage: /amm [io|debug|config]"
L.IMPORT_TITLE = "Import / Export"
L.IMPORT_PROMPT = "Paste data below"
L.EXPORT_TITLE = "Exported data (Ctrl+C)"
L.IMPORT_OK = "Import complete: %d markers"
L.IMPORT_FAIL = "Invalid data format"

-- Main panel
L.PANEL_TITLE = "Map Markers"
L.MARK_ICON_SIZE = "Icon Size"
L.MARK_TEXT_SIZE = "Text Font"
L.SIZE_LOW = "Small"
L.SIZE_HIGH = "Large"
L.COORD_HINT = "Leave blank for current position"
L.MARK_COLOR_LABEL = "Color"
L.MARK_GRAYSCALE_BTN = "Grayscale"
L.MARK_ADD_POINT = "Add Marker"
L.MARK_UPDATE_EXTERNAL = "Update Marker"
L.MARK_UPDATE_POINT = "Update Marker"
L.MARK_UNNAMED = "Unnamed"
L.EMPTY_LIST_TEXT = "No favorites yet\nAdd with the form above; click the star to favorite\n\nQuick add at cursor: /amm"

-- Big note editor
L.BIGNOTE_TITLE = "Details Editor (supports color codes)"
L.BIGNOTE_TITLE_LABEL = "Title (max 2 lines):"
L.BIGNOTE_NOTE_LABEL = "Note:"
L.BIGNOTE_OK = "Save & Close (still needs Update)"

-- Hints & errors
L.ERR_NAV_UNSUPPORTED = "Navigation not supported on this map"
L.ERR_NO_POSITION = "Cannot get current position; enter coordinates manually"
L.ERR_COORD_FORMAT = "Invalid coordinates, expected: 50 50 or 0.50 0.50"
L.ERR_NO_SELECTION = "No marker selected"
L.ERR_QUICKMARK_FAIL = "Quick marker failed: cannot get coordinates here"
L.QUICKMARK_OK = "Quick marker added: [%s] (%.0f, %.0f)"
L.MINIMAP_ARROW_CHECK = "Use addon player arrow to draw above markers (reload required)"

-- Import / Export
L.IO_TITLE = "[ADE] Marker Data  Export / Import"
L.IO_HINT = "【Export】Copy the code below.\n【Import】Replace the text, paste a code, then click Import."
L.IO_IMPORT_BTN = "Import (skip existing)"
L.IO_REFRESH_EXPORT = "Refresh export code"
L.IO_ERR_FORMAT = "Import failed: invalid data or empty code"
L.IO_DONE = "Import done! Added |cffffd100%d|r markers and |cffffd100%d|r icons."
L.IO_NO_NEW = "Import finished, but nothing new was added (duplicates skipped)"

-- Icon selector
L.ICON_LABEL = "Icon"
L.ICON_SELECTOR_TITLE = "Icon Selector"
L.ICON_SELECTOR_HELP = "\n【Left click】Open the dropdown\n【Right click】Clear current icon\n\n【Red handle】Rotate the icon; right-click to reset\n【Scroll】Zoom to crop the visible area\n\n【Double click】Enter an ID to add an extracted icon\n【Drag】Drop an item/spell here to add it\n\n <Extracted>  Right-click a list entry to delete it"
L.ICON_EXTRACT_OK = "Extracted in-game icon: %s"
L.ICON_EXTRACT_FAIL = "Extract failed: enter a valid ID!"
L.ICON_DELETE_FORBID = "You can only delete icons you extracted"

-- Provider registration
L.ERR_PROVIDER_NO_NAME = "RegisterMarkProvider failed: provider lacks a name field"
L.PROVIDER_REGISTERED = "Registered provider: %s"

-- Misc fallbacks
L.CROSS_MAP = "Cross-map"
L.ICON_ITEM = "Item"
L.ICON_SPELL = "Spell"
L.ICON_MACRO = "Macro"
