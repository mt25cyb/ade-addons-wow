-- adeBagPack — 设置页：ade_UIKit RegisterTab 四分组（计划 §二决策 2/3/7，P2）
-- 分组：整理 / 排序（行为 + 分类顺序）/ 界面 / 外部插件支持。
-- 注册时点：Core:Init 内 ABP.InitOptionsStub()（achDateFormat 同款，KAF Stub 同款时点）。
local ABP = _G.adeBagPack
if not ABP then return end
local L = ABP.L or {}
local UIKit = ABP.UIKit or (_G.ResolveBOFNamespace and _G.ResolveBOFNamespace("ade_UIKit"))

local function GetOF()
    return ABP.UIKit or (GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true))
end

-- a8：tab 引用必须在 AddRuleItem / onDrop 之前声明（词法作用域）——
-- 这些路径从**外部数组**添加条目，UIKit ListRow 不会自行重绘，需要显式刷新页面。
local tabRef
local function RefreshRules()
    if tabRef and tabRef.Refresh then tabRef:Refresh() end
end

-- profile 为层级表（InitDB），选项 key 用点路径（"minimap.hide"）。
local function PathParts(key)
    local parts = {}
    for part in key:gmatch("[^%.]+") do parts[#parts + 1] = part end
    return parts
end

local function GetKey(key)
    local node = ABP:GetProfile()
    for _, part in ipairs(PathParts(key)) do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end
    return node
end

local function SetKey(key, value)
    local parts = PathParts(key)
    local node = ABP:GetProfile()
    for i = 1, #parts - 1 do
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

local function GetDefault(key)
    local node = ABP.defaults and ABP.defaults.profile
    for _, part in ipairs(PathParts(key)) do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end
    return node
end

-- a3 修复：「恢复默认」对 orders 两键不能用 defaults 里的空表占位（defaults.orders.*
-- 只是结构占位 {}，恢复后清单会被清空）——真实默认顺序在 ABP.DefaultCategoryOrder /
-- DefaultEquipLocOrder（Core:Init 首启迁移同一来源）。
local ORDER_DEFAULT_ATTRS = {
    ["orders.CustomOrder"] = "DefaultCategoryOrder",
    ["orders.EquipLocOrder"] = "DefaultEquipLocOrder",
}
local function GetSectionDefault(key)
    local attr = ORDER_DEFAULT_ATTRS[key]
    if attr and ABP[attr] then return ABP[attr] end
    return GetDefault(key)
end

-- 排序相关键变更后必须重建 Rule（sortKeyCache / CategoryOrder），否则面板改值不生效。
local SORT_KEYS = { desc = true, symmetricJunk = true }
local function OnRuleChanged()
    if ABP.Rule and ABP.Rule.OnProfileUpdate then
        ABP.Rule:OnProfileUpdate()
    end
end

-- P3.5：入口接管键变更即时生效（原生按钮 hook / 外部插件挂卸）
local function AfterSet(key)
    if SORT_KEYS[key] or key:find("^orders%.") then
        OnRuleChanged()
    end
    if (key == "overrideNativeSort" or key == "useBlizzardSort")
            and ABP.Blizzard and ABP.Blizzard.ApplyOverride then
        ABP.Blizzard:ApplyOverride()
    end
    if key:find("^external%.") and ABP.External and ABP.External.Apply then
        ABP.External:Apply()
    end
end

local function KeySpec(spec, key)
    spec.key = key
    spec.get = spec.get or function() return GetKey(key) end
    spec.set = spec.set or function(value)
        SetKey(key, value)
        AfterSet(key)
    end
    if spec.default == nil then spec.default = GetDefault(key) end
    return spec
end
-- ============ 分区 ============

local sections = {}

sections.pack = {
    { kind = "note", text = L["NOTE_USAGE"] },
    KeySpec({ kind = "toggle", label = L["LABEL_OVERRIDE_NATIVE"], desc = L["DESC_OVERRIDE_NATIVE"] }, "overrideNativeSort"),
    KeySpec({ kind = "toggle", label = L["LABEL_USE_BLIZZARD"], desc = L["DESC_USE_BLIZZARD"] }, "useBlizzardSort"),
}

sections.sort = {
    { kind = "note", text = L["NOTE_SORT"] },
    KeySpec({ kind = "toggle", label = L["LABEL_REVERSE"], desc = L["DESC_REVERSE"] }, "desc"),
    -- a11：垃圾钉放区 → 垃圾对称整理（Baganator OrderBags 同款：非垃圾正向、垃圾逆向）
    KeySpec({ kind = "toggle", label = L["LABEL_SYMMETRIC_JUNK"], desc = L["DESC_SYMMETRIC_JUNK"] },
        "symmetricJunk"),
}

-- 分类顺序编辑（计划 §二决策 3：getItems 数组引用语义，UIKit ListRow 按钮排序；
-- 变更经 onChanged 重建 Rule，整理即时生效）。
-- a5：移植旧 Settings「添加规则」入口；a6：按用户反馈撤掉列表内 +/T 按钮（跨 tab
-- 复用串位、且每行按钮不合适），改回源插件同款弹出对话框（UI/RuleDialog.lua 全量移植）。
local OpenRuleDialog = ABP.OpenRuleDialog -- UI/RuleDialog.lua 导出（Core 挂载）

local function AddRuleItem(value)
    local items = GetKey("orders.CustomOrder")
    if not items then return end
    items[#items + 1] = value
    OnRuleChanged()
    RefreshRules() -- a8：外部数组变更后 UI 不会自动重绘（ListRow 只在自身操作时 Refresh）
end

sections.categories = {
    { kind = "note", text = L["NOTE_CATEGORY_ORDER"] },
    { kind = "execute", label = "", text = L["RULE_ADD_OPEN"], desc = L["RULE_ADD_DESC"],
        onClick = function() OpenRuleDialog(AddRuleItem) end },
    { kind = "list", key = "orders.CustomOrder", label = L["LABEL_CATEGORY_ORDER"],
        getItems = function() return GetKey("orders.CustomOrder") end,
        display = function(value)
            -- a5：数字 = 物品 ID 规则条目 → 显示物品名（旧版裸 ID，升级显示）
            if type(value) == "number" then
                local ok, name = pcall(C_Item.GetItemNameByID, value)
                if ok and name then return name .. " (ID:" .. value .. ")" end
                return "ID:" .. value
            end
            return ABP:GetRuleText(value)
        end,
        -- 拖入物品 = 添加物品 ID 规则（旧 Settings.lua:161 同款；去重防重复）
        accept = { item = true }, unique = true,
        onDrop = function(kind, id, idx)
            local itemID = ABP.GetItemID and ABP:GetItemID(id)
            if not itemID then return end
            local items = GetKey("orders.CustomOrder")
            if not items then return end
            if idx > #items + 1 then idx = #items + 1 end
            for _, v in ipairs(items) do
                if v == itemID then return end
            end
            table.insert(items, idx, itemID)
            OnRuleChanged()
            RefreshRules()
        end,
        showDelete = true, showMove = true, reorder = "buttons",
        onChanged = function() OnRuleChanged() end },
    { kind = "note", text = L["NOTE_EQUIPLOC_ORDER"] },
    { kind = "list", key = "orders.EquipLocOrder", label = L["LABEL_EQUIPLOC_ORDER"],
        getItems = function() return GetKey("orders.EquipLocOrder") end,
        display = function(value)
            if type(value) == "string" and _G[value] then return _G[value] end
            return tostring(value)
        end,
        showDelete = true, showMove = true, reorder = "buttons",
        onChanged = function() OnRuleChanged() end },
}

sections.interface = {
    { kind = "note", text = L["NOTE_INTERFACE"] },
    KeySpec({ kind = "toggle", label = L["LABEL_SHOW_MESSAGE"], desc = L["DESC_SHOW_MESSAGE"] }, "showmessage"),
    KeySpec({ kind = "select", label = L["LABEL_MESSAGE_FRAME"],
        items = {
            { value = 1, text = L["MSG_CHAT"] },
            { value = 2, text = L["MSG_ERRORS"] },
        } }, "messageframe"),
    KeySpec({ kind = "toggle", label = L["LABEL_MINIMAP_HIDE"], desc = L["DESC_MINIMAP_HIDE"] }, "minimap.hide"),
    KeySpec({ kind = "range", label = L["LABEL_MINIMAP_POS"], desc = L["DESC_MINIMAP_POS"],
        min = 0, max = 360, step = 5 }, "minimap.minimapPos"),
}

-- 外部插件支持（计划 §二决策 7 + 规范 _docs/External-Addon-Support-Convention.md）：
-- 目标插件未加载 → disabled 禁用 + desc 动态提示；选项值存档先行，消费端 P3.5 External.lua。
sections.external = {
    { kind = "note", text = L["NOTE_EXTERNAL"] },
    KeySpec({
        kind = "select", label = L["LABEL_JUNK_SOURCE"],
        items = {
            { value = "builtin", text = L["SRC_BUILTIN"] },
            { value = "dejunk", text = "Dejunk" },
        },
        disabled = function() return not UIKit.IsAddOnLoaded("Dejunk") end,
        desc = function()
            if UIKit.IsAddOnLoaded("Dejunk") then return L["DESC_JUNK_SOURCE"] end
            return L["DESC_NEED_DEJUNK"]
        end,
    }, "external.junkSource"),
    KeySpec({
        kind = "select", label = L["LABEL_INFO_SOURCE"],
        items = {
            { value = "builtin", text = L["SRC_BUILTIN"] },
            { value = "itemera", text = "ItemEra" },
        },
        disabled = function() return not UIKit.IsAddOnLoaded("ItemEra") end,
        desc = function()
            if UIKit.IsAddOnLoaded("ItemEra") then return L["DESC_INFO_SOURCE"] end
            return L["DESC_NEED_ITEMERA"]
        end,
    }, "external.infoSource"),
    KeySpec({
        kind = "toggle", label = L["LABEL_BAGANATOR_SORT"],
        disabled = function() return not UIKit.IsAddOnLoaded("Baganator") end,
        desc = function()
            if UIKit.IsAddOnLoaded("Baganator") then return L["DESC_BAGANATOR_SORT"] end
            return L["DESC_NEED_BAGANATOR"]
        end,
    }, "external.baganatorSort"),
    KeySpec({
        kind = "toggle", label = L["LABEL_BAGANATOR_BUTTON"],
        disabled = function() return not UIKit.IsAddOnLoaded("Baganator") end,
        desc = function()
            if UIKit.IsAddOnLoaded("Baganator") then return L["DESC_BAGANATOR_BUTTON"] end
            return L["DESC_NEED_BAGANATOR"]
        end,
    }, "external.baganatorButton"),
}
-- ============ 统计 / 恢复默认 ============

local sectionNames = {
    pack = L["SEC_PACK"], sort = L["SEC_SORT"], categories = L["SEC_CATEGORIES"],
    interface = L["SEC_INTERFACE"], external = L["SEC_EXTERNAL"],
}

local sectionKeys = {
    pack = { "useBlizzardSort", "overrideNativeSort" },
    sort = { "desc", "symmetricJunk" },
    categories = { "orders.CustomOrder", "orders.EquipLocOrder" },
    interface = { "showmessage", "messageframe", "minimap.hide", "minimap.minimapPos" },
    external = { "external.junkSource", "external.infoSource", "external.baganatorSort", "external.baganatorButton" },
}

local function SameValue(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for k, v in pairs(a) do if not SameValue(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function CountChanged()
    local count = 0
    for _, keys in pairs(sectionKeys) do
        for _, key in ipairs(keys) do
            if not SameValue(GetKey(key), GetSectionDefault(key)) then count = count + 1 end
        end
    end
    return count
end

local function ResetSection(id)
    local keys = sectionKeys[id]
    if not keys then return false end
    local changed = false
    for _, key in ipairs(keys) do
        local def = GetSectionDefault(key)
        if not SameValue(GetKey(key), def) then
            if type(def) == "table" and UIKit.DB and UIKit.DB.DeepCopy then
                def = UIKit.DB.DeepCopy(def)
            end
            SetKey(key, def)
            changed = true
        end
    end
    if changed then OnRuleChanged() end
    return changed
end

-- ============ 注册 ============

local tab

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = ABP.title,
        saved = ABP.db or {},
        groups = {
            { name = L["GROUP_PACK"], sections = { "pack" } },
            { name = L["GROUP_SORT"], sections = { "sort", "categories" } },
            { name = L["GROUP_INTERFACE"], sections = { "interface" } },
            { name = L["GROUP_EXTERNAL"], sections = { "external" } },
        },
        sectionName = function(id) return sectionNames[id] or id end,
        elements = function(id) return sections[id] or sections.pack end,
        landing = function() return "pack" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
    })
    tabRef = tab -- a8：供外部数组变更后的页面刷新
    if lib.RegisterOptionsStub then
        lib.RegisterOptionsStub({
            title = ABP.title,
            version = ABP.version,
            tab = tab,
        })
    end
    return tab
end

--- 加载期注册 tab 与原生 stub 页（Core:Init 调用；KAF Stub 同款时点）。
--- ade_UIKit 为 ## Dependencies 硬依赖，失败直接 error 暴露，不做静默降级。
function ABP.InitOptionsStub()
    if not Build() then
        error("adeBagPack: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
    end
end

--- /adebp 空参数入口（Core.lua 斜杠命令调用）。
function ABP.OpenSettings()
    local registered = Build()
    if not registered then
        print("|cff00AAFF[ADE]|r " .. tostring(L["SLASH_NO_SETTINGS"]))
        return
    end
    registered:Toggle("pack")
end