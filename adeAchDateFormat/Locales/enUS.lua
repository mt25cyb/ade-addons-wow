-- Default locale: enUS.
local ADF = _G.adeAchDateFormat or {}
_G.adeAchDateFormat = ADF
local L = ADF.L or {}
ADF.L = L

L.ADDON_TITLE = "adeAchDateFormat"
L.GROUP_FORMAT = "Date format"
L.GROUP_SCOPE = "Scope"
L.HEADING_DATE_FORMAT = "ACHIEVEMENT DATE FORMAT"
L.HEADING_SCOPE = "WHERE IT APPLIES"

L.LABEL_PRESET = "Preset"
L.LABEL_HIDE_TIME = "Hide Time (no HH:MM)"
L.LABEL_CUSTOM = "Custom format"
L.LABEL_ENABLE_NATIVE = "Blizzard achievement UI"
L.LABEL_ENABLE_KROWI = "Krowi's Achievement Filter"
L.LABEL_ENABLE_PRAT = "Prat 3.0 (chat achievement date)"

L.PRESET_1 = "Day/Month/Year 24h"
L.PRESET_2 = "Day/Month/Year 12h"
L.PRESET_3 = "Month/Day/Year 24h"
L.PRESET_4 = "Month/Day/Year 12h"
L.PRESET_5 = "Year/Month/Day 24h"
L.PRESET_6 = "Year/Month/Day 12h"
L.PRESET_7 = "Locale full date"
L.PRESET_CUSTOM = "Custom"

L.NOTE_FORMAT = "Presets mirror Krowi's event reminder formats. Achievement dates have no time, so %R / %I:%M %p show 00:00 / 12:00 AM — enable \"Hide Time\" to strip them. Custom is used only when Custom is selected."
L.NOTE_FORMAT_TOKENS = "%Y year (4 digits) | %y year (2 digits) | %m month | %d day | %H hour | %M minute | %R HH:MM | %I 12-hour | %p AM/PM | %B full month | %b short month | %A full weekday | %a short weekday | %c locale date/time. Month and weekday names use your client's locale."
L.NOTE_SCOPE = "Direct text writes apply to every locale. The achievement-link tooltip rewrite is active only on zhCN. Disable Z_AchievementDateFormat when using this addon to avoid two addons writing the same text."
L.NOTE_Z_CONFLICT = "If Z_AchievementDateFormat is also enabled, both addons may write the same date text; disable Z to keep one format."

L.MSG_RESET = "settings reset to defaults."
L.MSG_NATIVE_HOOKED = "Blizzard achievement UI date hooks installed."
L.MSG_KROWI_HOOKED = "Krowi's Achievement Filter date hook installed."
L.MSG_PRAT_HOOKED = "Prat 3.0 achievements date hook installed."
L.MSG_PRAT_UNHOOKED = "Prat 3.0 achievements date hook removed."
L.MSG_LINK_HOOKED = "achievement link tooltip hook installed."
L.CMD_HELP = "commands: /aadf, /aadf reset"

L.DESC_ENABLE_KROWI = "Apply the date format to Krowi's Achievement Filter list display."
L.DESC_NEED_KROWI = "Krowi's Achievement Filter not detected; this option is disabled."
L.DESC_ENABLE_PRAT = "Apply the date format to achievement links in chat via Prat 3.0."
L.DESC_NEED_PRAT = "Prat 3.0 not detected; this option is disabled."

