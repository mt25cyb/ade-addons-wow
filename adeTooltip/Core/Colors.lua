------------------------------------------------------------
-- 單位取色：職業 / 反應 / 陣營（12.1 秘密值安全）
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local L = ns.L or {}

ns.Colors = {}
local Colors = ns.Colors

------------------------------------------------------------
-- RGB 表 → 著色字串 "#RRGGBB"
------------------------------------------------------------
local function colorfunc(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Colors.Hex(r, g, b)
    return string.format("%02x%02x%02x", (r or 0) * 255, (g or 0) * 255, (b or 0) * 255)
end

------------------------------------------------------------
-- 單位色：職業色優先、退反應色
------------------------------------------------------------
-- 明文 class 查表；秘密 class 走 C_ClassColor（分量可能是秘密 → 直接餵 SetVertexColor）
function Colors.UnitColor(unit, useFallback)
    local _, class = S.SafeCall(UnitClass, unit)   -- 秘密 class ⇒ 失敗
    if class then
        local plain = S.SafeValue(class)
        if plain then
            local c = RAID_CLASS_COLORS[plain]
            if c then return c.r, c.g, c.b end
        elseif C_ClassColor and C_ClassColor.GetClassColor then
            local ok, c = pcall(C_ClassColor.GetClassColor, class)
            if ok and type(c) == "table" then return c.r, c.g, c.b end
        end
    end
    local r, g, b = Colors.ReactionColor(unit)
    if r == nil and useFallback then return 0.6, 0.6, 0.6 end
    return r, g, b
end

-- 反應色：玩家對玩家一律灰；其餘走 FACTION_BAR_COLORS
-- （12.x 沒有 UnitReactionColor 這個全局表，對照 MiliUI Core/Colors.lua:96）
function Colors.ReactionColor(unit)
    if S.SafeBool(UnitIsPlayer, unit) then
        return 0.6, 0.6, 0.6
    end
    local reaction = S.SafeCall(UnitReaction, unit, "player")
    reaction = S.PlainNumber(reaction)
    local c = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    if c then
        return c.r, c.g, c.b
    end
    return nil
end

------------------------------------------------------------
-- 字串可讀化：明文 class/race 維持原樣，秘密回 "?"
------------------------------------------------------------
function Colors.Readable(token)
    local plain = S.SafeValue(token)
    if plain then return plain end
    if S.IsSecret(token) then return "?" end
    return L.UNKNOWN or "UNKNOWN"
end

------------------------------------------------------------
-- Panel 路径依赖的注册表（逐字对煊 MiliUI Core/Colors.lua:15-17,104-259）
-- colorfunc(raw) → r,g,b,hex；hex 只有在明文时才会给（秘密时 nil ⇒ 文字不上色）
------------------------------------------------------------
Colors.colorfunc = {}
Colors.filterfunc = {}
local colorfunc, filterfunc = Colors.colorfunc, Colors.filterfunc

function Colors.FromHex(hex)
    if type(hex) ~= "string" or not hex:match("^%x%x%x%x%x%x$") then return 1, 1, 1 end
    return (tonumber(hex:sub(1, 2), 16) or 255) / 255,
           (tonumber(hex:sub(3, 4), 16) or 255) / 255,
           (tonumber(hex:sub(5, 6), 16) or 255) / 255
end

local function PlainNumber(v)
    if type(v) ~= "number" or S.IsSecret(v) then return end
    return v
end
local function SafeValue(v, default)
    if v == nil or S.IsSecret(v) then return default end
    return v
end

colorfunc.class = function(raw)
    local class = SafeValue(raw and raw.class)
    if class then
        local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b) end
        return 1, 1, 1, "ffffff"
    end
    if raw and raw.class ~= nil and C_ClassColor and C_ClassColor.GetClassColor then
        local ok, c = pcall(C_ClassColor.GetClassColor, raw.class)
        if ok and type(c) == "table" then return c.r, c.g, c.b end
    end
    return 1, 1, 1, "ffffff"
end

colorfunc.level = function(raw)
    local lv = PlainNumber(raw and raw.effectiveLevel) or PlainNumber(raw and raw.level)
    local color = GetCreatureDifficultyColor and GetCreatureDifficultyColor((lv and lv > 0) and lv or 999)
                  or { r = 1, g = 1, b = 1 }
    return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b)
end

colorfunc.reaction = function(raw)
    local color = FACTION_BAR_COLORS[SafeValue(raw and raw.reaction, 4)] or FACTION_BAR_COLORS[4]
    return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b)
end

colorfunc.itemQuality = function(raw)
    local color = ITEM_QUALITY_COLORS[SafeValue(raw and raw.itemQuality, 0)] or ITEM_QUALITY_COLORS[0]
    if color then return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b) end
    return 1, 1, 1, "ffffff"
end

colorfunc.selection = function(raw)
    local r, g, b = S.SafeCall(UnitSelectionColor, raw and raw.unit)
    if r == nil then return 1, 1, 1, "ffffff" end
    return r, g, b, Colors.Hex(r, g, b)
end

colorfunc.faction = function(raw)
    local group = SafeValue(raw and raw.factionGroup)
    if group == "Neutral" then
        return 0.9, 0.7, 0, "e5b200"
    elseif group ~= nil and group == UnitFactionGroup("player") then
        return 0, 1, 0.2, "00cc33"
    elseif group ~= nil then
        return 1, 0.2, 0, "dd3300"
    end
    return 1, 1, 1, "ffffff"
end

colorfunc.mplus = function(raw)
    local c = raw and raw.mplusScoreColor
    if type(c) == "table" and PlainNumber(c.r) then
        return c.r, c.g, c.b, Colors.Hex(c.r, c.g, c.b)
    end
    return 1, 1, 1, "ffffff"
end

colorfunc.achievement = function(raw)
    local value = tonumber(PlainNumber(raw and raw._numericColorValue) or PlainNumber(raw and raw.achievementPoints))
    if not value then return 0.6, 0.6, 0.6, "999999" end
    local color
    if value >= 40000 then color = ITEM_QUALITY_COLORS[5]
    elseif value >= 20000 then color = ITEM_QUALITY_COLORS[4]
    elseif value >= 10000 then color = ITEM_QUALITY_COLORS[3]
    elseif value >= 5000 then color = ITEM_QUALITY_COLORS[2] end
    if color then return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b) end
    return 1, 1, 1, "ffffff"
end

colorfunc.itemLevel = function(raw)
    local value = tonumber(PlainNumber(raw and raw._numericColorValue) or PlainNumber(raw and raw.itemLevel))
    if not value then return 0.6, 0.6, 0.6, "999999" end
    local color
    if value >= 233 then color = ITEM_QUALITY_COLORS[4]
    elseif value >= 220 then color = ITEM_QUALITY_COLORS[3]
    else color = ITEM_QUALITY_COLORS[2] end
    if color then return color.r, color.g, color.b, Colors.Hex(color.r, color.g, color.b) end
    return 1, 1, 1, "ffffff"
end

filterfunc.reaction6 = function(raw) return SafeValue(raw and raw.reaction, 4) >= 6 end
filterfunc.reaction5 = function(raw) return SafeValue(raw and raw.reaction, 4) >= 5 end
filterfunc.reaction = function(raw, reaction) return SafeValue(raw and raw.reaction, 4) >= (tonumber(reaction) or 5) end
filterfunc.inraid = function() return IsInRaid() end
filterfunc.incombat = function() return InCombatLockdown() end
filterfunc.samerealm = function(raw)
    local realm = S.PlainText(raw and raw.realm)
    return realm ~= nil and realm == GetRealmName()
end
filterfunc.samecrossrealm = function(raw)
    local rel = S.SafeCall(UnitRealmRelationship, raw and raw.unit)
    return SafeValue(rel) ~= LE_REALM_RELATION_COALESCED
end
filterfunc.inpvp = function() return select(2, IsInInstance()) == "pvp" end
filterfunc.inarena = function() return select(2, IsInInstance()) == "arena" end
filterfunc.ininstance = function() return IsInInstance() and true or false end
filterfunc.sameguild = function(raw)
    local name, _, _, server = GetGuildInfo("player")
    local gName = S.PlainText(raw and raw.guildName)
    if name and gName and name == gName and server == S.PlainText(raw and raw.guildRealm) then return true end
end
