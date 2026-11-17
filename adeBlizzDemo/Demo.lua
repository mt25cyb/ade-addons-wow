-- ade_UIKit 全控件画廊：/bofdemo
-- 库解析延迟到命令执行时：避免插件加载顺序导致顶层 return 后连斜杠命令都没注册。
local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    -- 库入口函数若因加载顺序尚未就绪，仍可从自带注册表取同一张表。
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFFEEE4AE[bofdemo]|r " .. tostring(text)) end
end

-- [[ 真实键位绑定 ]] --  SetBinding 到隐藏代理按钮（CLICK 动作），触发时打印消息，可实测绑定真实生效。
local function BindProxy(i, message)
    local proxy = CreateFrame("Button", "AdeBlizzDemoBindProxy" .. i, UIParent, "SecureActionButtonTemplate")
    proxy:SetSize(1, 1) -- 隐形点击代理：CLICK 绑定按键时调用它的 :Click()
    proxy:SetAlpha(0)
    proxy:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    proxy:SetFrameStrata("TOOLTIP")
    proxy:SetScript("OnClick", function() Print(message) end)
    return proxy
end
local proxies = { BindProxy(1, "演示动作一已触发（键位绑定生效）"), BindProxy(2, "演示动作二已触发（键位绑定生效）"),
    BindProxy(3, "演示动作三已触发（键位绑定生效）") }
local function ClickAction(i) return "CLICK AdeBlizzDemoBindProxy" .. i .. ":LeftButton" end
local function GetBound(i) return GetBindingKey(ClickAction(i)) or "" end
local function SetBound(i, key)
    if InCombatLockdown() then Print("战斗中无法修改按键绑定"); return end
    local action = ClickAction(i)
    -- SetBinding 对不可绑定的键名会抛 Usage 断言（debug log 实证），pcall 兜底防刷屏
    local ok, err = pcall(function()
        local current = GetBindingKey(action)
        if current and current ~= "" then SetBinding(current) end -- 无动作 = 解除该键绑定
        if key and key ~= "" then SetBinding(key, action) end
    end)
    if not ok then
        Print("该键不可绑定: " .. tostring(key) .. " (" .. tostring(err) .. ")")
        return
    end
    SaveBindings(GetCurrentBindingSet())
end
local function ClearAllBindings()
    for i = 1, #proxies do SetBound(i, "") end
end

local defaults, DB = AdeBlizzDemoDefaults, AdeBlizzDemoDB -- InitDB.lua 定义

local tab, tab2
local function Toggle(key, label, desc, extra)
    local spec = {
        kind = "toggle", key = key, label = label, desc = desc,
        get = function() return DB[key] end,
        set = function(value) DB[key] = value end,
        default = true,
    }
    for k, v in pairs(extra or {}) do spec[k] = v end
    return spec
end

-- 基础控件：Header / SubHeading / Note / Option 的六种类型 / With 组合 / 双键位。
local basic = {
    { kind = "header", text = "常规" },
    Toggle("enable", "启用演示", "复选框（toggle）"),
    { kind = "range", key = "scale", label = "缩放", desc = "带步进的滑块（range），无 SubHeading 时缩进 X",
        min = 0.5, max = 2, step = 0.05, default = 1,
        get = function() return DB.scale end, set = function(v) DB.scale = v end },
    { kind = "select", key = "mode", label = "模式", desc = "下拉菜单（select）",
        items = { { text = "模式 A", value = "A" }, { text = "模式 B", value = "B" } },
        default = "A", get = function() return DB.mode end, set = function(v) DB.mode = v end },
    { kind = "key", key = "key", label = "按键（真实绑定）", desc = "绑定到游戏按键系统（聊天框可验证触发）",
        default = "", get = function() return GetBound(1) end, set = function(v) SetBound(1, v) end },
    { kind = "execute", key = "click", label = "执行按钮", text = "执行", desc = "点击立即执行（execute）",
        onClick = function() Print("执行完成") end },

    { kind = "subheading", text = "子分组（缩进 X）" },
    { kind = "input", key = "note", label = "备注（缩进 2X）", desc = "SubHeading 下的选项自动缩进一级",
        default = "", get = function() return DB.note end, set = function(v) DB.note = v end },
    { kind = "toggle", key = "subToggle", label = "子分组开关（缩进 2X）", desc = "与备注同级",
        default = false, get = function() return DB.subToggle end, set = function(v) DB.subToggle = v end },

    { kind = "header", text = "组合控件（KAF With）" },
    { kind = "note", text = "复选框后可跟一个滑块或按钮，与暴雪设置界面同款。" },
    { kind = "toggle", key = "alphaEnabled", label = "启用透明度", desc = "组合：复选框 + 滑块",
        default = true,
        get = function() return DB.alphaEnabled end, set = function(v) DB.alphaEnabled = v end,
        with = { type = "range", label = "透明度", min = 0, max = 1, step = 0.05, default = 0.8,
            get = function() return DB.alpha end, set = function(v) DB.alpha = v end } },
    { kind = "toggle", key = "autoClean", label = "自动清理", desc = "组合：复选框 + 按钮",
        default = false,
        get = function() return DB.autoClean end, set = function(v) DB.autoClean = v end,
        with = { type = "execute", text = "立即清理", default = false,
            get = function() return false end, set = function() Print("已清理") end } },
    { kind = "key", key = "dual", label = "双键位（真实绑定）", desc = "两个键位槽各自绑定到不同动作",
        default = "", get = function() return GetBound(2) end, set = function(v) SetBound(2, v) end,
        slots = {
            { get = function() return GetBound(2) end, set = function(v) SetBound(2, v) end },
            { get = function() return GetBound(3) end, set = function(v) SetBound(3, v) end },
        } },
    { kind = "toggle", key = "reload", label = "需要重载", desc = "改值后点亮底部重载条",
        default = false, needsReload = true,
        get = function() return DB.reload end, set = function(v) DB.reload = v end },
}

-- 固定复选矩阵：Sub（All / None）+ Grid（展开为 GridHeader 与 GridRow）。
local function ViewCell(index, label, needsReload)
    return { key = label, get = function() return DB.view[index] end,
        set = function(v) DB.view[index] = v end, default = false, needsReload = needsReload }
end
local events = {
    { kind = "header", text = "固定复选矩阵" },
    { kind = "sub", label = "事件提醒",
        setAll = function(value) for k in pairs(DB.view) do DB.view[k] = value end end },
    { kind = "grid", columns = { "显示", "副本内", "战斗中" }, rows = {
        { label = "登录时", cells = { ViewCell(1, "登录显示", true), ViewCell(2, "登录副本"), ViewCell(3, "登录战斗") } },
        { label = "进入战斗", cells = { ViewCell(4, "战斗显示"), ViewCell(5, "战斗副本"), ViewCell(6, "战斗战斗") } },
    } },
    { kind = "note", text = "Sub 家族标题行右侧是全部 / 无；Grid 展开为列标题行与每数据行的一组复选框。" },
}

-- 其它形态：Cards → CardRow → Card、TabList → TabRow、Link。
local tabListElement, RebuildTabItems
RebuildTabItems = function()
    tabListElement.items = {}
    for i, item in ipairs(DB.tabs) do
        tabListElement.items[i] = {
            label = item.name, source = "演示数据",
            show = { type = "toggle", label = item.name, default = false,
                get = function() return item.show end, set = function(v) item.show = v end },
            moveUp = i > 1 and function()
                DB.tabs[i - 1], DB.tabs[i] = DB.tabs[i], DB.tabs[i - 1]
                RebuildTabItems()
            end or nil,
            moveDown = i < #DB.tabs and function()
                DB.tabs[i + 1], DB.tabs[i] = DB.tabs[i], DB.tabs[i + 1]
                RebuildTabItems()
            end or nil,
        }
    end
    tabListElement._bofNormalized = nil
end
tabListElement = { kind = "tablist" }
RebuildTabItems()

local gallery = {
    { kind = "header", text = "其它形态" },
    { kind = "subheading", text = "卡片（Cards → CardRow）" },
    { kind = "card", cards = {
        { name = "基础控件", detail = "复选、滑块、下拉、输入、按键与组合",
            icon = "Interface\\Icons\\INV_Misc_Gear_01", isNew = true,
            onClick = function() if tab then tab:Open("basic") end end },
        { name = "事件矩阵", detail = "全选 / 无与固定复选列",
            icon = "Interface\\Icons\\INV_Misc_Note_02",
            onClick = function() if tab then tab:Open("events") end end },
        { name = "其它形态", detail = "卡片、页签、链接与搜索结果",
            icon = "Interface\\Icons\\INV_Misc_Book_09",
            onClick = function() Print("已在本页") end },
    } },
    { kind = "subheading", text = "页签顺序（TabList → TabRow）" },
    tabListElement,
    { kind = "subheading", text = "链接（Link）" },
    { kind = "link", label = "打开事件矩阵", detail = "点击跳转",
        onClick = function() if tab then tab:Open("events") end end },
    { kind = "note", text = "SearchHeading（搜索结果分区标题）由顶部搜索自动生成，输入关键字即可看到。" },
}

local sections = { basic = basic, events = events, gallery = gallery }
local names = { basic = "基础控件", events = "事件矩阵", gallery = "其它形态" }

-- 真实统计与 defaults 不同的项数；恒返回 1 会让「已更改」恒亮、恢复默认按钮恒可用，误导测试。
local function CountChanged()
    local count = 0
    for key, def in pairs(defaults) do
        local value = DB[key]
        if key == "view" then
            for i = 1, #def do if value[i] ~= def[i] then count = count + 1 end end
        elseif type(def) == "table" then
            for i in pairs(def) do if value[i] ~= def[i] then count = count + 1 end end
        elseif value ~= def then
            count = count + 1
        end
    end
    return count
end

-- 第二个 Tab：落地实测 Tab 切换与音效、多 Tab 搜索（勾选「搜索全部」）、UpdateSearchAll 的显示。
local second = {
    { kind = "header", text = "多页测试" },
    { kind = "note", text = "用于实测：Tab 切换与音效、跨 Tab 搜索（勾选「搜索全部」）与「搜索描述」。" },
    { kind = "toggle", key = "secondToggle", label = "第二页开关", desc = "独立的复选框",
        default = false, get = function() return DB.secondToggle end, set = function(v) DB.secondToggle = v end },
    { kind = "execute", label = "第二页按钮", default = false,
        get = function() return false end, set = function() Print("第二页按钮已点击") end },
}

-- 「恢复默认」（footer 按钮）由库委托给宿主的 resetSection(id)：不实现就只是重载一遍、什么都不重置。
-- 各分区对应的存档键（with 子选项 alpha 同属 basic）。
local sectionKeys = {
    basic = { "enable", "scale", "mode", "note", "key", "subToggle", "alphaEnabled", "alpha", "autoClean", "dual", "reload" },
    events = { "view" },
    gallery = { "tabs" },
    second = { "secondToggle" },
}
local function SameTable(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function ResetSection(id)
    local keys = sectionKeys[id]
    if not keys then return false end
    local changed = false
    if id == "basic" then -- 键位走真实绑定系统（不存 DB），恢复默认 = 解除演示绑定
        for i = 1, #proxies do
            if GetBound(i) ~= "" then changed = true end
            SetBound(i, "")
        end
    end
    for _, key in ipairs(keys) do
        local def = defaults[key]
        if type(def) == "table" then
            if not SameTable(DB[key], def) then
                local copy = {}
                for k, v in pairs(def) do
                    if type(v) == "table" then copy[k] = { unpack(v) } else copy[k] = v end
                end
                DB[key] = copy
                changed = true
            end
        elseif DB[key] ~= def then
            DB[key] = def
            changed = true
        end
    end
    if id == "gallery" and changed and RebuildTabItems then RebuildTabItems() end
    return changed
end

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = "Blizz Demo",
        saved = DB,
        groups = { { name = "演示", sections = { "basic", "events" } },
            { name = "其它", sections = { "gallery" } } }, -- 两个分组：实测第二组头前的间隔条
        sectionName = function(id) return names[id] or id end,
        elements = function(id) return sections[id] or basic end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        isNew = function(id) return id == "gallery" end,
        onCreated = function() end,
    })
    tab2 = lib.RegisterTab({
        name = "Demo 2",
        saved = DB,
        groups = { { name = "多页", sections = { "second" } } },
        sectionName = function() return "多页测试" end,
        elements = function() return second end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        onCreated = function() end,
    })
    return tab
end

SLASH_ADEBLIZZDEMO1 = "/bofdemo"
SlashCmdList.ADEBLIZZDEMO = function()
    if not GetOF() then
        Print("ade_UIKit 未加载：请确认该插件已勾选且客户端版本匹配。")
        return
    end
    local registered = Build()
    if not registered then
        Print("注册选项页失败，请查看聊天框中的 Lua 错误。")
        return
    end
    registered:Toggle("basic")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function() Build() end)
