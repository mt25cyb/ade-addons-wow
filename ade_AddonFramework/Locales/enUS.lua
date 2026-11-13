-- enUS（库自身可见文本；key 即原文兜底）
-- 三个语种文件同时列在 TOC 中，按 2:2:z-ref_retail_Interface_AddOns/MiliUI_AuraEnhance/Locales/zhTW.lua 的条件写法隔离
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
if GetLocale() ~= "enUS" then return end
-- 宿主若把本包加载在 Env.lua 之前，AF.L 可能还没建：这里兜底初始化（键缺译文时回显 key 本身）
AF.L = AF.L or setmetatable({}, { __index = function(_, key) return key end })
local L = AF.L

L["AF_NEW"] = "New"
L["AF_COPY"] = "Copy"
L["AF_RENAME"] = "Rename"
L["AF_RESET"] = "Reset"
L["AF_DELETE"] = "Delete"
L["AF_RESET_ROW"] = "Reset this option"
L["AF_RESET_ALL"] = "Restore every setting to its default?"
L["AF_NAME_EXISTS"] = "A profile with that name already exists"
L["AF_NAME_EMPTY"] = "Type a name for the new profile first"
L["AF_PROFILE_SHARED"] = "The shared profile can't be deleted"
L["AF_DELETE_CONFIRM"] = "Delete the current profile?"
L["AF_RENAME_PROMPT"] = "Rename the current profile to:"
L["AF_ABOUT"] = "About"
L["AF_PROFILES"] = "Profiles"
L["AF_EXPORT"] = "Export"
L["AF_IMPORT"] = "Import"
L["AF_PREFIX_MISMATCH"] = "Prefix mismatch"
L["AF_IMPORT_INVALID"] = "Invalid string"
L["AF_EXPORT_COPY"] = "Export (Ctrl+C to copy)"
L["AF_IMPORT_VALID"] = "Import: |cff44ff44string is valid|r"
L["AF_IMPORT_COLON"] = "Import: "
L["AF_IMPORT_CONFIRM"] = "Importing overwrites every current setting. Continue?"
L["AF_EXPORT_NOTE"] = "The export string contains this profile's settings only. The import button lights up once a valid string is pasted."
L["AF_CLOSE"] = "Close"
L["AF_PREVIEW_OPEN"] = "Open Preview"
L["AF_PREVIEW_CLOSE"] = "Close Preview"
L["AF_OK"] = "OK"
L["AF_CANCEL"] = "Cancel"
L["AF_NONE"] = "None"
L["AF_SEARCH"] = "Search..."
L["AF_SELECT_ALL"] = "Select all"
L["AF_SECTION_TITLE"] = "Section"
L["AF_PROFILE_HINT"] = "Each character can use its own profile. Export and import work on the current profile only."
L["AF_NUDGE_UP"] = "Move up"
L["AF_NUDGE_DOWN"] = "Move down"
L["AF_NUDGE_LEFT"] = "Move left"
L["AF_NUDGE_RIGHT"] = "Move right"
L["AF_CENTER_H"] = "Center horizontally"
L["AF_CENTER_V"] = "Center vertically"
