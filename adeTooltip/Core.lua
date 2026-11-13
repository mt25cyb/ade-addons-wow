-- adeTooltip — 核心层：存档、设置数据、统一应用与 slash 入口（P1 骨架）。
-- 强依赖 ade_AddonFramework（TOC ## Dependencies）：绘图/样式/主题色全部委托库。
-- 数据层模式同 adeChatMod b013：db.profiles = { current, list }（AF.Template.ProfileDB 适配），
-- db.state 存会话状态（minimapShown/minimapAngle/previewOpen），切换/重置配置档不影响。
local addonName = ...
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
ADT.name = addonName or "adeTooltip"
ADT.version = "v6-r001-b001"
ADT.AF = GetFramework("ade_AddonFramework", true)
if not ADT.AF then return end -- 库未加载（Dependencies 已保证）
local AF = ADT.AF

local L = ADT.L or {}
ADT.L = L

-- 会话状态键（不进配置档）
local STATE_KEYS = {
    minimapShown = true,
    minimapAngle = true,
    previewOpen = true,
}

---------------------------------------------------------------------------
-- 数值限幅
---------------------------------------------------------------------------
function ADT.Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

---------------------------------------------------------------------------
-- 设置读写（"table.key" 点号路径；状态键走 db.state，其余走当前配置档）
---------------------------------------------------------------------------
local function SplitKey(key)
    return key:match("^([^%.]+)%.(.+)$")
end

local function ReadPath(t, key)
    if type(t) ~= "table" then return nil end
    local first, rest = SplitKey(key)
    if rest then return t[first] and t[first][rest] end
    return t[key]
end

local function WritePath(t, key, value)
    local first, rest = SplitKey(key)
    if rest then
        if type(t[first]) ~= "table" then t[first] = {} end
        t[first][rest] = value
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
    if STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then return nil end
        return self.db.state[key]
    end
    return ReadPath(self:CurrentSettings(), key)
end

function ADT:Set(key, value)
    if not self.db then return end
    if STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then self.db.state = {} end
        self.db.state[key] = value
        return
    end
    WritePath(self:CurrentSettings(), key, value)
end

function ADT:GetDefault(key)
    if STATE_KEYS[key] then return ReadPath(self.DEFAULTS.state, key) end
    return ReadPath(self.DEFAULTS.settings, key)
end

---------------------------------------------------------------------------
-- 默认值合并 + RANGES 限幅 + CHOICES 校验（配置档切换/导入/重置复用）
---------------------------------------------------------------------------
function ADT:EnsureProfile(tbl)
    if type(tbl) ~= "table" then return end
    for key, value in pairs(self.DEFAULTS.settings) do
        if type(value) == "table" then
            if type(tbl[key]) ~= "table" then tbl[key] = {} end
            for subKey, subValue in pairs(value) do
                if type(tbl[key][subKey]) ~= type(subValue) then
                    tbl[key][subKey] = subValue
                end
            end
        elseif type(tbl[key]) ~= type(value) then
            tbl[key] = value
        end
    end
    for key, range in pairs(self.RANGES) do
        local v = ReadPath(tbl, key)
        if type(v) == "number" then WritePath(tbl, key, self.Clamp(v, range[1], range[2])) end
    end
    for key, list in pairs(self.CHOICES) do
        local v = ReadPath(tbl, key)
        local valid = false
        for _, candidate in ipairs(list) do if v == candidate then valid = true end end
        if not valid then WritePath(tbl, key, self:GetDefault(key)) end
    end
end

---------------------------------------------------------------------------
-- 存档（新插件无旧档迁移；db.version 供后续迁移用）
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
    for key, value in pairs(self.DEFAULTS.state) do
        if type(db.state[key]) ~= type(value) then db.state[key] = value end
    end
    self.db = db
    self:EnsureProfile(self:CurrentSettings())
    self:ApplyAccent()

    -- 配置档适配器（AF.Template.ProfileDB）：切换/新建/复制/重命名/删除/导入导出/重置
    self.profileDB = AF.Options.ProfileDB.New(db.profiles, {
        serialize = AF.DB.Encode,
        deserialize = AF.DB.Decode,
        onSwitch = function()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
        onReset = function()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
        onImport = function()
            ADT:EnsureProfile(ADT:CurrentSettings())
            ADT:ApplyAccent()
            ADT:ApplyAll()
        end,
    })
    db.version = self.version
    return db
end

--- 恢复当前配置档默认（/adeTooltip reset；配置管理页重置走 ProfilePage 自带确认弹窗）。
function ADT:ResetProfile()
    if not self.profileDB then return end
    self.profileDB.Reset()
    self:Print(L.MSG_RESET or "settings reset to defaults.")
end

--- 统一下发：设置版本号 + 小地图 + 选项页刷新（含 enabled 禁用态重算）+ 预览刷新。
function ADT:ApplyAll()
    if not self.db then return end
    if self.BumpSettingsVersion then self:BumpSettingsVersion() end
    if self.SyncMinimapShown then self:SyncMinimapShown() end
    if self.RefreshOptions then self:RefreshOptions() end
    if self.RefreshPreview then self:RefreshPreview() end
end

function ADT:ApplyAccent()
    AF.ApplyAccent(self:Get("themeColor") or self:GetDefault("themeColor") or AF.DEFAULT_ACCENT)
end

function ADT:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(AF.AccentHex() .. "adeTooltip|r: " .. tostring(msg))
    end
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
        ADT:ApplyAll()
        events:UnregisterEvent("PLAYER_LOGIN")
    end
end)

---------------------------------------------------------------------------
-- Slash 命令：/adeTooltip 与 /atip 等价（§八.6）
---------------------------------------------------------------------------
_G.SLASH_ADETOOLTIP1 = "/adeTooltip"
_G.SLASH_ADETOOLTIP2 = "/atip"
SlashCmdList["ADETOOLTIP"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ADT:ToggleOptions()
    elseif cmd == "about" or cmd == "help" then
        ADT:ToggleOptions("about")
    elseif cmd == "reset" then
        -- 弹窗条目在 CreateOptions() 中注册；先确保窗口已构建，reset 才能独立使用。
        ADT:CreateOptions()
        if StaticPopup_Show then StaticPopup_Show("ADETOOLTIP_RESET") end
    elseif cmd == "minimap" then
        ADT:ToggleMinimap()
    else
        ADT:Print(L.CMD_HELP or "commands: /adeTooltip, /atip, /adeTooltip reset, /adeTooltip minimap")
    end
end
