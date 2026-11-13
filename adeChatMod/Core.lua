-- adeChatMod — 核心层：存档、设置数据、统一应用与 slash 入口。
-- 强依赖 ade_AddonFramework（TOC ## Dependencies）：绘图/样式/主题色全部委托库，
-- 本文件只保留业务数据层（RANGES/CHOICES/DEFAULTS 合并校验）与入口，不再自带控件工厂。
-- b013 起配置档方案（ADE-v6-FrameDesign）：db.profiles = { current, list }（AF.Template.ProfileDB 适配），
-- db.settings 不再是存档键；barShown/minimapShown/minimapAngle 属会话状态，固定存 db.state。
local addonName = ...
local ACM = _G.adeChatMod or {}
_G.adeChatMod = ACM
ACM.name = addonName or "adeChatMod"
ACM.version = "v6-r001-b013"
ACM.AF = GetFramework("ade_AddonFramework", true)
if not ACM.AF then return end -- 库未加载（理论上 Dependencies 已保证）
local AF = ACM.AF

local L = ACM.L or {}
ACM.L = L

ACM.CHOICES = {
    colorScheme = { "COLORFUL", "DEFAULT" },
    ["attachPosition.point"] = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" },
    ["attachPosition.relativePoint"] = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" },
}

ACM.RANGES = {
    btnSize = { 16, 40 },
    btnGap = { -5, 12 },
    fontSize = { 10, 20 },
    autoJoinDelay = { 0, 30 },
    ["attachPosition.x"] = { -400, 400 },
    ["attachPosition.y"] = { -400, 400 },
    ["defaultPosition.x"] = { -800, 800 },
    ["defaultPosition.y"] = { 0, 1200 },
}

ACM.CHOICE_TEXT = {
    COLORFUL = L.CHOICE_COLORFUL or "Colorful",
    DEFAULT = L.CHOICE_DEFAULT or "Default",
    TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT", CENTER = "CENTER",
}

-- 会话状态键（不进配置档）：显隐/小地图角度随登录保留，切换/重置配置档不影响。
local STATE_KEYS = {
    barShown = true,
    minimapShown = true,
    minimapAngle = true,
}

---------------------------------------------------------------------------
-- 数值限幅（InitDB 校验用）
---------------------------------------------------------------------------
function ACM.Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

---------------------------------------------------------------------------
-- 设置读写（支持 "table.key" 点号路径；状态键走 db.state，其余走当前配置档）
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

--- 当前配置档的设置表（profiles.list[profiles.current]）。
function ACM:CurrentSettings()
    local p = self.db and self.db.profiles
    if type(p) ~= "table" or type(p.list) ~= "table" then return nil end
    return p.list[p.current]
end

function ACM:Get(key)
    if not self.db then return nil end
    if STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then return nil end
        return self.db.state[key]
    end
    return ReadPath(self:CurrentSettings(), key)
end

function ACM:Set(key, value)
    if not self.db then return end
    if STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then self.db.state = {} end
        self.db.state[key] = value
        return
    end
    WritePath(self:CurrentSettings(), key, value)
end

function ACM:GetDefault(key)
    if STATE_KEYS[key] then return ReadPath(self.DEFAULTS.state, key) end
    return ReadPath(self.DEFAULTS.settings, key)
end

---------------------------------------------------------------------------
-- 默认值合并 + RANGES 限幅 + CHOICES 校验（对任意设置表执行；配置档切换/导入/重置复用）
---------------------------------------------------------------------------
function ACM:EnsureProfile(tbl)
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
-- 存档（b013 迁移：旧 db.settings 整体搬进 profiles.list["Shared"]，状态键搬进 db.state）
---------------------------------------------------------------------------
function ACM:InitDB()
    if type(_G.adeChatModDB) ~= "table" then _G.adeChatModDB = {} end
    local db = _G.adeChatModDB
    if type(db.state) ~= "table" then db.state = {} end
    -- 迁移：仅旧结构（有 settings、无 profiles）执行一次
    if type(db.settings) == "table" and type(db.profiles) ~= "table" then
        for key in pairs(STATE_KEYS) do
            if db.settings[key] ~= nil and db.state[key] == nil then db.state[key] = db.settings[key] end
            db.settings[key] = nil
        end
        db.profiles = { current = "Shared", list = { Shared = db.settings } }
        db.settings = nil
    end
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
    -- 状态键不入档；serialize/deserialize 用库线格式（C_EncodingUtil CBOR，缺失退回 Lua 序列化）
    self.profileDB = AF.Options.ProfileDB.New(db.profiles, {
        serialize = AF.DB.Encode,
        deserialize = AF.DB.Decode,
        onSwitch = function()
            ACM:EnsureProfile(ACM:CurrentSettings())
            ACM:ApplyAccent()
            ACM:ApplyAll()
        end,
        onReset = function()
            ACM:EnsureProfile(ACM:CurrentSettings())
            ACM:ApplyAccent()
            ACM:ApplyAll()
        end,
        onImport = function()
            ACM:EnsureProfile(ACM:CurrentSettings())
            ACM:ApplyAccent()
            ACM:ApplyAll()
        end,
    })
    db.version = self.version
    return db
end

--- 恢复当前配置档默认（/acm reset；配置管理页的重置按钮走 ProfilePage 自带确认弹窗）。
function ACM:ResetProfile()
    if not self.profileDB then return end
    self.profileDB.Reset() -- onReset 钩子已补默认值 + ApplyAccent + ApplyAll
    self:Print(L.MSG_RESET or "settings reset to defaults.")
end

-- 对应旧 ApplyAll()：把当前设置重新应用到业务 UI。
function ACM:ApplyAll()
    if not self.db then return end
    if self.RefreshBar then self:RefreshBar() end
    if self.SetBarShown then self:SetBarShown(self:Get("barShown")) end
    if self.SyncMinimapShown then self:SyncMinimapShown() end
    if self.RefreshOptions then self:RefreshOptions() end
end

-- 主题色委托 AF.ApplyAccent（AF.T 派生 + 弱键自刷新 + ThemeChanged 广播）。
-- 默认黄色见 InitDB.lua 的 settings.themeColor；设置页「主题色」分区可改。
function ACM:ApplyAccent()
    AF.ApplyAccent(self:Get("themeColor") or self:GetDefault("themeColor") or AF.DEFAULT_ACCENT)
end

function ACM:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(AF.AccentHex() .. "adeChatMod|r: " .. tostring(msg))
    end
end

---------------------------------------------------------------------------
-- 事件：ADDON_LOADED 初始化存档；PLAYER_LOGIN 创建小地图按钮并统一下发设置。
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ACM.name then
        ACM:InitDB()
        events:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if not ACM.db then ACM:InitDB() end
        if ACM.CreateMinimapButton then
            local ok, err = pcall(ACM.CreateMinimapButton, ACM)
            if not ok then ACM:Print("|cffff5555minimap button error:|r " .. tostring(err)) end
        end
        ACM:ApplyAll()
        events:UnregisterEvent("PLAYER_LOGIN")
    end
end)

---------------------------------------------------------------------------
-- Slash 命令
---------------------------------------------------------------------------
_G.SLASH_ADECHATMOD1 = "/acm"
_G.SLASH_ADECHATMOD2 = "/adechatmod"
SlashCmdList["ADECHATMOD"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ACM:ToggleOptions()
    elseif cmd == "about" or cmd == "help" then
        ACM:ToggleOptions("about")
    elseif cmd == "reset" then
        -- 弹窗条目在 CreateOptions() 中注册；先确保窗口已构建，/acm reset 才能独立使用。
        ACM:CreateOptions()
        if StaticPopup_Show then StaticPopup_Show("ADECHATMOD_RESET") end
    elseif cmd == "minimap" then
        ACM:ToggleMinimap()
    else
        ACM:Print(L.CMD_HELP or "commands: /acm, /acm about, /acm reset, /acm minimap")
    end
end
