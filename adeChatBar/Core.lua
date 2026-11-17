-- adeChatBar — 核心层：存档、设置数据、统一应用与 slash 入口。
-- 设置窗口基于 ade_BlizzOptionsFrame v6.5；零 ade_AddonFramework 依赖。
-- 主题色按既定口径硬编码 ADE #EEE4AE，不设颜色选项、配置档与关于页。
local addonName = ...
local ACB = _G.adeChatBar or {}
_G.adeChatBar = ACB
ACB.name = addonName or "adeChatBar"
ACB.version = "v6.5-r001"
ACB.ACCENT = "|cFFEEE4AE"

local L = ACB.L or {}
ACB.L = L

ACB.CHOICES = {
    colorScheme = { "COLORFUL", "DEFAULT" },
    ["attachPosition.point"] = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" },
    ["attachPosition.relativePoint"] = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" },
}

ACB.RANGES = {
    btnSize = { 16, 40 },
    btnGap = { -5, 12 },
    fontSize = { 10, 20 },
    autoJoinDelay = { 0, 30 },
    ["attachPosition.x"] = { -400, 400 },
    ["attachPosition.y"] = { -400, 400 },
    ["defaultPosition.x"] = { -800, 800 },
    ["defaultPosition.y"] = { 0, 1200 },
}

ACB.CHOICE_TEXT = {
    COLORFUL = L.CHOICE_COLORFUL or "Colorful",
    DEFAULT = L.CHOICE_DEFAULT or "Default",
    TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT", CENTER = "CENTER",
}

local STATE_KEYS = {
    barShown = true,
    minimapShown = true,
    minimapAngle = true,
}

function ACB.Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

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

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
    return copy
end

function ACB:Get(key)
    if not self.db then return nil end
    if STATE_KEYS[key] then return self.db.state and self.db.state[key] end
    return ReadPath(self.db.settings, key)
end

function ACB:Set(key, value)
    if not self.db then return end
    if STATE_KEYS[key] then
        if type(self.db.state) ~= "table" then self.db.state = {} end
        self.db.state[key] = value
        return
    end
    WritePath(self.db.settings, key, value)
end

function ACB:GetDefault(key)
    if STATE_KEYS[key] then return ReadPath(self.DEFAULTS.state, key) end
    return ReadPath(self.DEFAULTS.settings, key)
end

--- 补全默认值 + RANGES 限幅 + CHOICES 校验。
function ACB:EnsureSettings(tbl)
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

function ACB:InitDB()
    if type(_G.adeChatBarDB) ~= "table" then _G.adeChatBarDB = {} end
    local db = _G.adeChatBarDB
    if type(db.settings) ~= "table" then db.settings = {} end
    if type(db.state) ~= "table" then db.state = {} end
    self.db = db
    self:EnsureSettings(db.settings)
    for key, value in pairs(self.DEFAULTS.state) do
        if type(db.state[key]) ~= type(value) then db.state[key] = value end
    end
    db.version = self.version
    return db
end

--- 恢复全部设置（/acb reset）；BOF 的逐分区恢复在 Options.lua 的 resetSection 中实现。
function ACB:ResetSettings()
    if not self.db then return end
    self.db.settings = {}
    self:EnsureSettings(self.db.settings)
    for key, value in pairs(self.DEFAULTS.state) do self.db.state[key] = CopyValue(value) end
    self:ApplyAll()
end

function ACB:ApplyAll()
    if not self.db then return end
    if self.RefreshBar then self:RefreshBar() end
    if self.SetBarShown then self:SetBarShown(self:Get("barShown")) end
    if self.SyncMinimapShown then self:SyncMinimapShown() end
    if self.RefreshOptions then self:RefreshOptions() end
end

function ACB:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.ACCENT .. "adeChatBar|r: " .. tostring(msg))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ACB.name then
        ACB:InitDB()
        events:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if not ACB.db then ACB:InitDB() end
        if ACB.CreateMinimapButton then
            local ok, err = pcall(ACB.CreateMinimapButton, ACB)
            if not ok then ACB:Print("|cffff5555minimap button error:|r " .. tostring(err)) end
        end
        ACB:ApplyAll()
        events:UnregisterEvent("PLAYER_LOGIN")
    end
end)

_G.SLASH_ADECHATBAR1 = "/acb"
_G.SLASH_ADECHATBAR2 = "/adechatbar"
SlashCmdList["ADECHATBAR"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ACB:ToggleOptions()
    elseif cmd == "minimap" then
        ACB:ToggleMinimap()
    elseif cmd == "reset" then
        ACB:ResetSettings()
        ACB:Print(L.MSG_RESET or "settings reset to defaults.")
    else
        ACB:Print(L.CMD_HELP or "commands: /acb, /acb minimap, /acb reset")
    end
end
