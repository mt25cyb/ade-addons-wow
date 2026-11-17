-- adeTooltip — 核心层：存档、设置数据、统一应用与 slash 入口。
-- 强依赖 ade_AddonFramework（TOC ## Dependencies）：绘图/样式/主题色全部委托库，
-- 本文件只保留业务数据层（RANGES/CHOICES/DEFAULTS 合并校验）与入口，不再自带控件工厂。
-- 配置档方案（ADE-v6-FrameDesign）：db.profiles = { current, list }；db.settings 不再是存档键；
-- minimap* 属会话状态，固定存 db.state。
local addonName = ...
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
ADT.name = addonName or "adeTooltip"
ADT.version = "v6-r001-b016"
-- 玩家職業英文文件名（player token 不受 12.1 身分限制；Panel/Render.lua、Frame.lua、
-- ViewSpell 的數字著色都讀它）。對照 MiliUI Core/Init.lua:18。
ADT.playerClass = select(2, UnitClass("player"))
ADT.AF = GetFramework("ade_AddonFramework", true, "adeTooltip")
if not ADT.AF then return end -- 库未加载（理论上 Dependencies 已保证）
local AF = ADT.AF

local L = ADT.L or {}
ADT.L = L

-- 模块应用钩子注册表（C1+ 的 Classic 模块注册 ApplyAll 钩子）。
ADT.applyHooks = {}

---------------------------------------------------------------------------
-- 数值限幅（InitDB 校验用）
---------------------------------------------------------------------------
function ADT.Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

---------------------------------------------------------------------------
-- 设置读写（支持 "table.key" 点号路径；状态键走 db.state，其余走当前配置档）
---------------------------------------------------------------------------
local function ReadPath(t, key)
    if type(t) ~= "table" then return nil end
    local first, rest = key:match("^([^%.]+)%.(.+)$")
    if first then return ReadPath(t[first], rest) end
    return t[key]
end

local function WritePath(t, key, value)
    local first, rest = key:match("^([^%.]+)%.(.+)$")
    if first then
        if type(t[first]) ~= "table" then t[first] = {} end
        WritePath(t[first], rest, value)
    else
        t[key] = value
    end
end

function ADT:CurrentSettings()
    local p = self.db and self.db.profiles
    if type(p) ~= "table" or type(p.list) ~= "table" then return nil end
    return p.list[p.current]
end

function ADT:Get(key)
    if not self.db then return nil end
    if ADT.STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then return nil end
        return self.db.state[key]
    end
    return ReadPath(self:CurrentSettings(), key)
end

function ADT:Set(key, value)
    if not self.db then return end
    if ADT.STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then self.db.state = {} end
        self.db.state[key] = value
        return
    end
    WritePath(self:CurrentSettings(), key, value)
end

function ADT:GetDefault(key)
    if ADT.STATE_KEYS[key] then return ReadPath(ADT.DEFAULTS.state, key) end
    return ReadPath(ADT.DEFAULTS.settings, key)
end

---------------------------------------------------------------------------
-- 默认值合并 + RANGES 限幅 + CHOICES 校验（对任意设置表执行；配置档切换/导入/重置复用）
---------------------------------------------------------------------------
-- 递归合并默认值：缺失的嵌套键（如 unit.*.elements）也会被补齐，
-- 仅填充缺失项、绝不删除用户已存值（修复旧配置档缺少深层默认键的问题）。
local function MergeDefaults(tbl, defaults)
    if type(tbl) ~= "table" or type(defaults) ~= "table" then return end
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(tbl[key]) ~= "table" then tbl[key] = {} end
            MergeDefaults(tbl[key], value)
        elseif type(tbl[key]) ~= type(value) then
            tbl[key] = value
        end
    end
end

function ADT:EnsureProfile(tbl)
    if type(tbl) ~= "table" then return end
    MergeDefaults(tbl, ADT.DEFAULTS.settings)
    for key, range in pairs(ADT.RANGES) do
        local v = ReadPath(tbl, key)
        if type(v) == "number" then WritePath(tbl, key, self.Clamp(v, range[1], range[2])) end
    end
    for key, list in pairs(ADT.CHOICES) do
        local v = ReadPath(tbl, key)
        local valid = false
        for _, candidate in ipairs(list) do if v == candidate then valid = true end end
        if not valid then WritePath(tbl, key, self:GetDefault(key)) end
    end
end

---------------------------------------------------------------------------
-- 存档（与 adeChatMod 同方案：db.profiles + db.state）
---------------------------------------------------------------------------
function ADT:InitDB()
    if type(_G.adeTooltipDB) ~= "table" then _G.adeTooltipDB = {} end
    local db = _G.adeTooltipDB
    if type(db.state) ~= "table" then db.state = {} end
    if type(db.profiles) ~= "table" then db.profiles = {} end
    if type(db.profiles.list) ~= "table" then db.profiles.list = {} end
    if type(db.profiles.current) ~= "string" then db.profiles.current = "Shared" end
    if type(db.profiles.list[db.profiles.current]) ~= "table" then
        db.profiles.list[db.profiles.current] = {}
    end
    for key, value in pairs(ADT.DEFAULTS.state) do
        if type(db.state[key]) ~= type(value) then db.state[key] = value end
    end
    self.db = db
    self.settings = self:CurrentSettings()
    self:EnsureProfile(self:CurrentSettings())
    self:ApplyAccent()

    self.profileDB = AF.Options.ProfileDB.New(db.profiles, {
        serialize = AF.DB.Encode,
        deserialize = AF.DB.Decode,
        onSwitch = function()
            ADT.settings = ADT:CurrentSettings()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
        onReset = function()
            ADT.settings = ADT:CurrentSettings()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
        onImport = function()
            ADT.settings = ADT:CurrentSettings()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
    })
    db.version = self.version
    return db
end

function ADT:ResetProfile()
    if not self.profileDB then return end
    self.profileDB.Reset()
    self:Print(L.MSG_RESET or "settings reset to defaults.")
end

-- 模块注册 ApplyAll 钩子（C1+ 使用）。
function ADT:RegisterApply(fn)
    if type(fn) == "function" then
        ADT.applyHooks[#ADT.applyHooks + 1] = fn
    end
end

-- 把当前设置重新应用到业务 UI。
function ADT:ApplyAll()
    if not self.db then return end
    for _, fn in ipairs(self.applyHooks) do
        local ok, err = pcall(fn, self)
        if not ok then self:Print("|cffff5555apply error:|r " .. tostring(err)) end
    end
    if self.SyncMinimapShown then self:SyncMinimapShown() end
    if self.RefreshOptions then self:RefreshOptions() end
end

-- 主题色委托 AF.ApplyAccent（AF.T 派生 + 弱键自刷新 + ThemeChanged 广播）。
function ADT:ApplyAccent()
    AF.ApplyAccent(self:Get("themeColor") or self:GetDefault("themeColor") or AF.DEFAULT_ACCENT)
end

function ADT:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(AF.AccentHex() .. "adeTooltip|r: " .. tostring(msg))
    end
end

-- Skin/Bar 的错误汇聚路径以点号调用（ns.ReportError(err)），故此处同样用点号定义。
function ADT.ReportError(err)
    ADT:Print("|cffff5555error:|r " .. tostring(err))
end

---------------------------------------------------------------------------
-- 事件：ADDON_LOADED 初始化存档；PLAYER_LOGIN 创建小地图按钮并统一下发设置。
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADT.name then
        ADT:InitDB()
        events:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if not ADT.db then ADT:InitDB() end
        if ADT.CreateMinimapButton then
            local ok, err = pcall(ADT.CreateMinimapButton, ADT)
            if not ok then ADT:Print("|cffff5555minimap button error:|r " .. tostring(err)) end
        end
        -- C1+ 的 Classic 模块在此注册并应用（ApplyAll 已含 applyHooks）
        ADT:ApplyAll()
        if ADT.InitHooks then ADT:InitHooks() end
        events:UnregisterEvent("PLAYER_LOGIN")
    end
end)

---------------------------------------------------------------------------
-- Slash 命令
---------------------------------------------------------------------------
_G.SLASH_ADETOOLTIP1 = "/adt"
_G.SLASH_ADETOOLTIP2 = "/adeTooltip"
SlashCmdList["ADETOOLTIP"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ADT:ToggleOptions()
    elseif cmd == "about" or cmd == "help" then
        ADT:ToggleOptions("about")
    elseif cmd == "minimap" then
        ADT:ToggleMinimap()
    elseif cmd == "reset" then
        ADT:CreateOptions()
        if StaticPopup_Show then StaticPopup_Show("ADETOOLTIP_RESET") end
    else
        ADT:Print(L.CMD_HELP or "commands: /adt, /adt about, /adt minimap")
    end
end
