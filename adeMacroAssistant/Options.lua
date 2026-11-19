-- adeMacroAssistant — 设置窗口：基于 ade_UIKit（v6.5）原生 Tab/elements。
-- 按已确认口径：不设配置档管理页、关于页与主题色选项；4 个 AceGUI 页改为 3 个 UIKit 分区。
-- 宏体就地 multiline 编辑；导入/导出走 UIKit ShareString（CBOR→压缩→Base64）字符串 + 按钮。
local AM = _G.adeMacroAssistant
if not AM then return end
local L = AM.L or {}
local S = AM.Settings

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
    return copy
end

local function SameValue(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not SameValue(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function SplitKey(key)
    return key:match("^([^%.]+)%.(.+)$")
end

local function ReadPath(t, key)
    if type(t) ~= "table" or type(key) ~= "string" then return nil end
    local first, rest = SplitKey(key)
    if rest then
        if type(t[first]) ~= "table" then return nil end
        return ReadPath(t[first], rest)
    end
    return t[key]
end

local function WritePath(t, key, value)
    if type(t) ~= "table" then return end
    local first, rest = SplitKey(key)
    if rest then
        if type(t[first]) ~= "table" then t[first] = {} end
        WritePath(t[first], rest, value)
    else
        t[key] = value
    end
end

local function Apply()
    if AM.ApplyAll then AM:ApplyAll() end
end

local sectionSpecs = {}

--- 补上 UIKit 行契约：get/set/default 直接转发到 ADEMA_DB.profile 的点分路径。
local function KeySpec(section, spec, key, after)
    spec.key = key
    spec.get = spec.get or function()
        return ReadPath(AM.db and AM.db.profile, key)
    end
    spec.set = spec.set or function(value)
        if not AM.db then return end
        WritePath(AM.db.profile, key, value)
        if after then after(value) else Apply() end
    end
    spec.default = ReadPath(AM.defaults and AM.defaults.profile, key)
    sectionSpecs[section] = sectionSpecs[section] or {}
    sectionSpecs[section][#sectionSpecs[section] + 1] = spec
    return spec
end

local function LayoutAfter()
    if AM.MacroUIResize and AM.MacroUIResize.ApplySettings then AM.MacroUIResize.ApplySettings() end
    if AM.RefreshOptions then AM:RefreshOptions() end
end

local function SearchAfter()
    if AM.MacroSearch and AM.MacroSearch.ApplySettings then AM.MacroSearch.ApplySettings() end
end

local function LayoutItems()
    return {
        { value = "vertical", text = L.LAYOUT_VERTICAL or "Vertical" },
        { value = "horizontal", text = L.LAYOUT_HORIZONTAL or "Horizontal" },
    }
end

--- 从源插件既有本地化取 tooltip 文案；带 %d 的按给定实参 format。
--- 返回 nil 表示无该文案（UIKit tooltip 不显示），绝不臆造说明。
local function Tip(key, ...)
    local text = L[key]
    if not text then return nil end
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then return formatted end
    end
    return text
end

--- 按各宏体默认宏体实际使用的法术占位符生成彼此不同的说明。
--- 文案取自既有本地化：HINT_TOKEN_ONE "%s -> 实际 %s" 与 TOKEN_<SPELL> 的法术含义。
local function BodyDesc(typeKey)
    local body = ReadPath(AM.defaults and AM.defaults.profile, "automacro." .. typeKey .. ".body") or ""
    local hint = L.HINT_TOKEN_ONE or "HINT_TOKEN_ONE"
    local lines, seen = {}, {}
    -- 只匹配以 _SPELL 结尾的全大写占位符；; / 换行等分隔符自然断开。
    -- 不能用 %f[%w] 收尾：token 后紧跟换行时是 word→非word，frontier 方向相反会零匹配。
    for token in body:gmatch("([A-Z][A-Z0-9_]*_SPELL)") do
        if not seen[token] then
            seen[token] = true
            lines[#lines + 1] = hint:format(token, L["TOKEN_" .. token] or ("TOKEN_" .. token))
        end
    end
    return table.concat(lines, "\n")
end

local sections = { resize = {}, auto = {}, importexport = {} }

-- ============ 分区 1：宏界面尺寸 / 搜索栏 ============
-- 分组标题用 subheading（不是 note），其下选项由 UIKit Flatten 自动缩进一级。
sections.resize[1] = { kind = "subheading", label = L.SECTION_RESIZE }
sections.resize[2] = KeySpec("resize",
    { kind = "toggle", label = L.ENABLE_RESIZE, desc = Tip("HINT_RESIZE") },
    "macroresize.enabled", LayoutAfter)
sections.resize[3] = KeySpec("resize",
    { kind = "select", label = L.RESIZE_LAYOUT, items = LayoutItems(), desc = Tip("HINT_RESIZE") },
    "macroresize.layoutMode", LayoutAfter)
sections.resize[4] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_COLS_V, min = 6, max = 12, step = 1,
      desc = Tip("RESIZE_COLS_DESC", 6, 12, 8, 6, 12, 6) },
    "macroresize.vertical.buttonCols", LayoutAfter)
sections.resize[5] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_ROWS_V, min = 3, max = 12, step = 1,
      desc = Tip("RESIZE_ROWS_DESC", 3, 12, 4, 3, 12, 8) },
    "macroresize.vertical.buttonRows", LayoutAfter)
sections.resize[6] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_COLS_H, min = 6, max = 12, step = 1,
      desc = Tip("RESIZE_COLS_DESC", 6, 12, 8, 6, 12, 6) },
    "macroresize.horizontal.buttonCols", LayoutAfter)
sections.resize[7] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_ROWS_H, min = 3, max = 12, step = 1,
      desc = Tip("RESIZE_ROWS_DESC", 3, 12, 4, 3, 12, 8) },
    "macroresize.horizontal.buttonRows", LayoutAfter)
sections.resize[8] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_TEXT, min = 0, max = 120, step = 1,
      desc = Tip("RESIZE_TEXT_DESC", 0, 120, 1, 40) },
    "macroresize.addTextY", LayoutAfter)
sections.resize[9] = KeySpec("resize",
    { kind = "range", label = L.RESIZE_RIGHTW, min = 200, max = 500, step = 5,
      desc = Tip("RESIZE_RIGHTW_DESC", 200, 500, 5, 320) },
    "macroresize.horizontal.rightWidth", LayoutAfter)
sections.resize[9].default = 320 -- 旧默认值未含此键，回退 MacroUIResize 的 LAYOUT_SPECS.rightWidth

sections.resize[10] = { kind = "subheading", label = L.SECTION_SEARCH }
sections.resize[11] = KeySpec("resize",
    { kind = "toggle", label = L.SEARCH_ENABLE, desc = Tip("SEARCH_HINT") },
    "macrosearch.enabled", SearchAfter)
sections.resize[12] = KeySpec("resize",
    { kind = "toggle", label = L.SEARCH_BODY, desc = Tip("SEARCH_HINT") },
    "macrosearch.includeBody", SearchAfter)
sections.resize[13] = {
    kind = "execute", text = L.BTN_RESET_LAYOUT or "Reset layout",
    onClick = function()
        local mode = AM.MacroUIResize and AM.MacroUIResize.GetMode and AM.MacroUIResize.GetMode() or "vertical"
        local defaults = AM.defaults and AM.defaults.profile and AM.defaults.profile.macroresize
        local profile = AM.db and AM.db.profile
        if not defaults or not profile then return end
        profile.macroresize[mode] = CopyValue(defaults[mode])
        if mode == "vertical" then profile.macroresize.addTextY = defaults.addTextY end
        LayoutAfter()
    end,
}

-- ============ 分区 2：自动宏 ============
-- 「宏名前缀」分组标题 + 其下 3 个选项（源插件本节结构）
sections.auto[1] = { kind = "subheading", label = L.SECTION_PREFIX }
sections.auto[2] = KeySpec("auto",
    { kind = "toggle", label = L.ENABLE_AUTOMACRO, desc = Tip("HINT_PREFIX") }, "automacro.enabled")
sections.auto[3] = KeySpec("auto",
    { kind = "toggle", label = L.ENABLE_PREFIX, desc = Tip("ENABLE_PREFIX_DESC") }, "automacro.prefixEnabled")
sections.auto[4] = KeySpec("auto",
    { kind = "input", label = L.PREFIX_CHAR, desc = Tip("HINT_PREFIX") }, "automacro.prefixChar")

if S then
    for _, typeKey in ipairs(S.TYPE_ORDER) do
        local label = L[S.TYPE_LABELS[typeKey]] or typeKey
        local prefix = "automacro." .. typeKey
        sections.auto[#sections.auto + 1] = { kind = "subheading", label = label }
        sections.auto[#sections.auto + 1] = KeySpec("auto",
            { kind = "toggle", label = (L.ENABLE_TYPE or "%s"):format(label),
              desc = Tip("DESC_TYPE", label) },
            prefix .. ".enabled")
        sections.auto[#sections.auto + 1] = KeySpec("auto",
            { kind = "input", label = L.NAME_TYPE or "Macro name",
              desc = Tip("HINT_PREFIX") },
            prefix .. ".base")
        sections.auto[#sections.auto + 1] = KeySpec("auto",
            { kind = "multiline", label = L.BODY_TYPE or "Body" },
            prefix .. ".body", function()
                if AM.AutoMacro and AM.AutoMacro.Refresh then AM.AutoMacro.Refresh() end
            end)
        -- 说明另起一行、灰色文本（note 行），紧接在宏体内容框下方。
        -- indent=1 让它与「宏体」标题、多行框左缘同级。
        sections.auto[#sections.auto + 1] = { kind = "note", text = BodyDesc(typeKey), indent = 1 }
    end
end

-- ============ 分区 3：导入/导出宏（UIKit ShareString 字符串） ============
-- 导出：按钮生成 ADEMA! 前缀的 Base64 字符串并全选；导入：贴入后实时解码，成功才亮按钮。
-- 注意：Normalize 会浅拷贝 spec，故所有运行时状态放闭包，spec 的 disabled/text 用函数读取。
local pendingImportData
local exportEdit
local importEdit
local importText = ""
local importStatus = ""
local importDisabled = true

local function ShareErr(err)
    return L[err] or tostring(err)
end

sections.importexport[1] = { kind = "note", text = L.EXPORT_HINT or "" }
local exportText = ""
sections.importexport[2] = { kind = "multiline", label = L.BTN_EXPORT or "Export",
    get = function() return exportText end, set = function(value) exportText = value or "" end,
    onEditBox = function(edit) exportEdit = edit end }
sections.importexport[3] = {
    kind = "execute", text = L.BTN_EXPORT_GEN or "Generate export string",
    onClick = function()
        if not S then return end
        local of = GetOF()
        if not of or not of.ShareString then
            AM:Print(ShareErr("SHARE_NO_CODEC")); return
        end
        local str, err = of.ShareString.Encode(S.WIRE_PREFIX, S.BuildExport())
        if str and exportEdit then
            exportText = str
            exportEdit:SetText(str)
            exportEdit:HighlightText()
            exportEdit:SetFocus()
            AM:Print(L.EXPORT_OK or "Export string generated (Ctrl+C).")
        else
            AM:Print("|cffff5555" .. ShareErr(err or "SHARE_ENCODE_FAILED"))
        end
    end,
}
sections.importexport[4] = { kind = "note", text = L.IMPORT_HINT or "" }
sections.importexport[5] = { kind = "multiline", label = L.IMPORT_BOX_LABEL or "Import string",
    get = function() return importText end,
    set = function(value) importText = value or "" end,
    onEditBox = function(edit) importEdit = edit end,
    onTextChanged = function(edit, userChanged)
        if not userChanged then return end
        importText = edit:GetText()
        pendingImportData = nil
        importDisabled = true
        if not S then return end
        local of = GetOF()
        local text = importText
        if not of or not of.ShareString then
            importStatus = "|cffff5555" .. ShareErr("SHARE_NO_CODEC")
        elseif text == "" then
            importStatus = ""
        else
            local data, err = of.ShareString.Decode(text, S.WIRE_PREFIX, S.ValidatePayload)
            if data then
                pendingImportData = data
                importDisabled = false
                importStatus = "|cff44ff44" .. (L.IMPORT_VALID or "String is valid") .. "|r"
            else
                importStatus = "|cffff5555" .. (L.IMPORT_INVALID or "Invalid string") .. ": " .. ShareErr(err)
            end
        end
        if AM.RefreshOptions then AM:RefreshOptions() end
    end,
}
sections.importexport[6] = { kind = "execute", text = L.BTN_IMPORT_DO or "Import macros",
    disabled = function() return importDisabled end,
    onClick = function()
        if not pendingImportData or not S then return end
        if S.ApplyPayload(pendingImportData) then
            AM:Print(L.MSG_IMPORT_OK or "Auto macros imported.")
            pendingImportData = nil
            importDisabled = true
            importStatus = ""
            importText = ""
            if importEdit then importEdit:SetText("") end
            if AM.RefreshOptions then AM:RefreshOptions() end
        else
            AM:Print("|cffff5555" .. (L.IMPORT_INVALID or "Invalid string"))
        end
    end,
}
-- 状态/错误提示放在「导入宏」按钮的下一行（b022）
sections.importexport[7] = { kind = "note", text = function() return importStatus end, indent = 1 }

local sectionNames = {
    resize = L.TAB_RESIZE or "Macro UI",
    auto = L.TAB_AUTOMACRO or "Auto Macro",
    importexport = L.TAB_IMPORTEXPORT or "Import/Export",
}

local function CountChanged()
    local count = 0
    for _, specs in pairs(sectionSpecs) do
        for _, spec in ipairs(specs) do
            if spec.get and spec.default ~= nil and not SameValue(spec.get(), spec.default) then
                count = count + 1
            end
        end
    end
    return count
end

local function ResetSection(id)
    local specs = sectionSpecs[id]
    if not specs then return false end
    local changed = false
    for _, spec in ipairs(specs) do
        if spec.get and spec.set and spec.default ~= nil and not SameValue(spec.get(), spec.default) then
            spec.set(CopyValue(spec.default))
            changed = true
        end
    end
    if changed then Apply() end
    return changed
end

local tab

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = AM.title,
        saved = AM.db or {},
        groups = {
            { name = sectionNames.resize, sections = { "resize" } },
            { name = sectionNames.auto, sections = { "auto" } },
            { name = sectionNames.importexport, sections = { "importexport" } },
        },
        sectionName = function(id) return sectionNames[id] or id end,
        elements = function(id) return sections[id] or sections.resize end,
        landing = function() return "resize" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        onCreated = function() end,
    })
    if lib.RegisterOptionsStub then
        lib.RegisterOptionsStub({
            title = AM.title,
            version = AM.version,
            tab = tab,
        })
    end
    return tab
end

--- 加载期注册 tab 与 stub 页（Core:Init 调用；KAF Stub 同款时点）。
--- ade_UIKit 为 ## Dependencies 硬依赖，失败直接 error 暴露，不做静默降级。
function AM:InitOptionsStub()
    if not Build() then
        error("adeMacroAssistant: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
    end
end

function AM:RefreshOptions()
    if tab and tab.Refresh then tab:Refresh() end
end

function AM:ToggleOptions()
    local registered = Build()
    if not registered then
        self:Print("ade_UIKit 未加载：请确认该插件已勾选。")
        return
    end
    registered:Toggle("resize")
end
