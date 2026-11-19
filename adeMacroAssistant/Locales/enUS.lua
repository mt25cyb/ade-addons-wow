-- adeMacroAssistant / Locales/enUS.lua
-- ADE v6.5：私有 locale 表（不再经 ADE:RegisterLocale / AceLocale）。
local AM = _G.adeMacroAssistant or {}
_G.adeMacroAssistant = AM
AM.Loc = AM.Loc or {}
AM.Loc.enUS = {
    MACRO_ASSISTANT = "Macro Assistant",

    -- ---- Settings window ----
    SETTINGS_SUFFIX = " Settings",
    BTN_CLOSE = "Close",
    ENABLE_AUTOMACRO = "Enable Auto Macros",
    SECTION_PREFIX = "Macro Name Prefix",
    ENABLE_PREFIX = "Enable Prefix",
    PREFIX_CHAR = "Prefix character (e.g. ' )",
    HINT_PREFIX = "Prefix and base name are stored separately: final macro name = prefix char + (custom base or type default).\nClick 'Refresh Macros' to apply.",
    ENABLE_PREFIX_DESC = "Adding a prefix to macro names avoids name conflicts with other addons or manual macros.",
    SECTION_TYPES = "Macro Types",
    SPELLTYPE_CLEANSE = "Cleanse (Friendly)",
    SPELLTYPE_PURGE = "Clear (Enemy)",
    SPELLTYPE_DISPEL = "Dispel (Friendly/Enemy Both)",
    SPELLTYPE_INTERRUPT = "Interrupt",
    SPELLTYPE_RESURRECTION = "Resurrect / Rebirth",
    SPELLTYPE_SPRINT = "Sprint / Speed",
    SPELLTYPE_TAUNT = "Taunt",
    ENABLE = "Enable",
    BASE_NAME = "Custom base name (blank = default)",
    MACRO_BODY = "Macro body (one command per line)",
    SECTION_RESIZE = "Macro UI Resize",
    ENABLE_RESIZE = "Enable UI resize",
    RESIZE_COLS = "Macros per row",
    RESIZE_ROWS = "Icon rows",
    RESIZE_TEXT = "Extra text area height (vertical layout)",
    RESIZE_RIGHTW = "Text area width (horizontal layout)",
    RESIZE_RIGHTW_DESC = "Width of the macro text area in the horizontal layout (%d–%d, step %d, default %d). Has no effect in the vertical layout, where the text area height comes from the icon rows, so it is greyed out there.",
    -- 描述里同时给出两种布局的取值范围与默认值（标题不再写值，值会随布局变）
    RESIZE_COLS_DESC = "Macros shown per row. Vertical layout %d–%d (default %d), horizontal layout %d–%d (default %d). Each layout keeps its own values.",
    RESIZE_ROWS_DESC = "Icon rows shown. Vertical layout %d–%d (default %d), horizontal layout %d–%d (default %d). Each layout keeps its own values.",
    RESIZE_TEXT_DESC = "Extra height for the macro text area (%d–%d, step %d, default %d). Has no effect in the horizontal layout, where the height comes from the icon rows, so it is greyed out there.",
    HINT_RESIZE = "Changes preview live only while the Macro Frame is open; reverts when closed.",
    BTN_REFRESH = "Refresh Macros Now",
    BTN_APPLY_RESIZE = "Apply UI Resize",
    BTN_RESET_LAYOUT = "Reset Current Layout",
    BTN_RESET_NATIVE = "Restore Native Macro UI",

    -- ---- Layout mode / search bar ----
    RESIZE_LAYOUT = "Layout mode",
    LAYOUT_VERTICAL = "Vertical (buttons above editor)",
    LAYOUT_HORIZONTAL = "Horizontal (buttons left, editor right)",
    SECTION_SEARCH = "Search bar",
    SEARCH_ENABLE = "Enable search bar",
    SEARCH_BODY = "Also search macro body",
    SWITCH_TO_HORIZONTAL = "Switch to horizontal layout",
    SWITCH_TO_VERTICAL = "Switch to vertical layout",
    OPEN_SETTINGS = "Open settings",
    SEARCH_HINT = "Filters the macro list by name; the bar sits below the tabs, above the macro buttons. Disabled in combat.",
    SEARCH_NO_RESULT = "No macros found",

    -- ---- AutoMacro messages ----
    MSG_MACRO_UPDATED = "Macro '%s' updated (%s)",
    MSG_MACRO_CREATED = "Macro '%s' created (%s)",
    MSG_IN_COMBAT = "In combat: prefix change will apply after combat",
    MSG_PREFIX_ENABLED = "Auto macro prefix enabled",
    MSG_PREFIX_DISABLED = "Auto macro prefix disabled",
    MSG_PREFIX_CHAR_UPDATED = "Auto macro prefix character updated",

    -- ---- Default macro names ----
    DEFAULT_NAME_CLEANSE = "Cleanse",
    DEFAULT_NAME_PURGE = "Purge",
    DEFAULT_NAME_DISPEL = "Dispel",
    DEFAULT_NAME_INTERRUPT = "Interrupt",
    DEFAULT_NAME_RESURRECTION = "CR",
    DEFAULT_NAME_SPRINT = "Sprint",
    DEFAULT_NAME_TAUNT = "Taunt",

    -- ---- Tabs ----
    TAB_AUTOMACRO = "Auto Macro",
    TAB_RESIZE = "Macro UI",
    TAB_IMPORTEXPORT = "Import / Export Macros",
    TAB_CONFIG = "Config Management",

    -- ---- Header / About ----
    UI_SCALE = "Scale",
    ABOUT_TITLE = "About",
    ABOUT_AUTHOR = "Author",
    ABOUT_VERSION = "Version",
    ABOUT_TRANSLATOR = "Translator",
    ABOUT_TRANSLATOR_DESC = "English by Martin Good (mt25cyb)",
    ABOUT_NOTES = "Notes",
    ABOUT_COMMANDS = "Commands",
    ABOUT_COMMANDS_DESC = "/adeMacroAssistant or /adema to open this window",
    UNKNOWN = "Unknown",

    -- token -> actual spell meaning (shown per type)
    TOKEN_CLEANSE_SPELL = "friendly dispel spell",
    TOKEN_PURGE_SPELL = "enemy purge spell",
    TOKEN_INTERRUPT_SPELL = "interrupt spell",
    TOKEN_RESURRECTION_SPELL = "combat resurrection spell",
    TOKEN_SPRINT_SPELL = "sprint / movement speed spell",
    TOKEN_TAUNT_SPELL = "taunt spell",
    HINT_TOKEN_ONE = "Use %s as a placeholder for the actual %s name.",

    -- ---- Per-type labels (formatted with type name) ----
    ENABLE_TYPE = "Enable %s",
    NAME_TYPE = "macro name",
    BODY_TYPE = "macro body",
    DESC_TYPE = "Macro for %s",

    -- ---- Import / Export Macros (auto-macro names & bodies only) ----
    SECTION_EXPORT = "Export Auto Macros",
    EXPORT_HINT = "Click the button below to generate a share string (auto macro names & bodies only), then Ctrl+C to copy.",
    SECTION_IMPORT = "Import Auto Macros",
    IMPORT_HINT = "Paste the share string below; the Import button enables once it parses successfully. Only auto macros are updated.",
    BTN_EXPORT = "Export",
    BTN_IMPORT = "Import",
    BTN_EXPORT_GEN = "Generate export string",
    BTN_IMPORT_DO = "Import macros",
    BTN_IMPORT_OK = "Imported.",
    BTN_IMPORT_INVALID = "Invalid",
    EXPORT_OK = "Export string generated (Ctrl+C to copy).",
    IMPORT_BOX_LABEL = "Import string",
    IMPORT_VALID = "String is valid",
    IMPORT_INVALID = "Invalid string",
    SHARE_NO_CODEC = "This client build has no C_EncodingUtil",
    SHARE_BAD_PREFIX = "Wrong prefix (not an ADE export string)",
    SHARE_BAD_PAYLOAD = "Bad payload",
    SHARE_EMPTY = "Empty string",
    SHARE_SERIALIZE_FAILED = "Serialization failed",
    SHARE_COMPRESS_FAILED = "Compression failed",
    SHARE_ENCODE_FAILED = "Encoding failed",
    SHARE_DECODE_FAILED = "Base64 decode failed",
    SHARE_DECOMPRESS_FAILED = "Decompression failed",
    SHARE_DESERIALIZE_FAILED = "Deserialization failed",
    SHARE_VALIDATE_FAILED = "Invalid string",
    MSG_IMPORT_OK = "Auto macros imported.",
    MSG_IMPORT_ERR = "Failed to import auto macros.",

    -- ---- Macro UI layout labels (b018 fix) ----
    RESIZE_COLS_V = "Columns (vertical)",
    RESIZE_ROWS_V = "Rows (vertical)",
    RESIZE_COLS_H = "Columns (horizontal)",
    RESIZE_ROWS_H = "Rows (horizontal)",

    -- minimap
    MENU_SETTINGS = "Settings",
    MENU_REFRESH = "Refresh macros",
    TIP_LEFT = "Left-click",
    TIP_RIGHT = "Right-click",
    TIP_LEFT_SETTINGS = "Open settings",
    TIP_RIGHT_FUNCS = "Functions menu",
    MINIMAP_LIB_MISSING = "LibDBIcon/LibDataBroker not available.",
}
