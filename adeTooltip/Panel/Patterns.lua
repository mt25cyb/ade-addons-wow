------------------------------------------------------------
-- 語系 pattern：從 GlobalStrings 動態產生，不寫任何語言的字面
--
-- 重繪面板要從 tooltip 的行文字認出「這是耗能／施法時間／冷卻／屬性…」。
-- 那些行沒有型別，只能比對文字；而文字是暴雪拿 GlobalStrings 的格式字串
-- format 出來的 ⇒ 把同一支格式字串反轉成 Lua pattern，三個語系自動成立。
--
--   Patterns.FromGlobal(fmt)     格式字串 → pattern 陣列（|4 單複數展開）＋ capture 順序
--   Patterns.Match(key, text)    _G[key] 存在才編（lazy、cache），回所有 capture（照參數順序）
--   Patterns.Find(field, text)   語意表那一欄的 key 逐一試，回 key, captures...
--   Patterns.Stat(text)          屬性行 → 數值、key、分類（primary／secondary／tertiary／other）
--   Patterns.PowerOf(costKey)    耗能 key → PowerBarColor 的資源名（上色用）
--   Patterns.ColorNumbers(text, hex)   數字上色（跳過跳脫碼；緊接的 % 一起上色）
--   Patterns.StripTextures／StripColors
--
-- 純邏輯：只讀 _G 的字串與 PowerBarColor，不碰任何框。秘密值不准進來——
-- 呼叫端（reader）要先過 S.PlainText，這裡收到的一律當明文。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

ns.Panel = ns.Panel or {}
ns.Patterns = {}
local Patterns = ns.Patterns

local _G = _G
local type, pairs, ipairs, tonumber = type, pairs, ipairs, tonumber
local strfind, strsub, strgsub, strmatch = string.find, string.sub, string.gsub, string.match
local tconcat, tsort = table.concat, table.sort
local unpack = unpack or table.unpack

------------------------------------------------------------
-- 格式字串 → pattern
------------------------------------------------------------
local function Escape(s)
    return (strgsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local NUMBER_CAPTURE = "([%d,%.]+)"
local ANY_CAPTURE = "(.-)"
local NUMERIC_CONV = { d = true, i = true, u = true, f = true, g = true, G = true, e = true, E = true }

local function Tokenize(fmt)
    local parts, buf = {}, {}
    local function flush()
        if #buf > 0 then
            parts[#parts + 1] = { lit = tconcat(buf) }
            buf = {}
        end
    end
    local i, n, nextArg = 1, #fmt, 0
    while i <= n do
        local c = strsub(fmt, i, i)
        if c == "%" then
            if strsub(fmt, i + 1, i + 1) == "%" then
                buf[#buf + 1] = "%"
                i = i + 2
            else
                local j, pos = i + 1, nil
                local _, posEnd, posStr = strfind(fmt, "^(%d+)%$", j)
                if posEnd then
                    pos = tonumber(posStr)
                    j = posEnd + 1
                end
                local _, convEnd, conv = strfind(fmt, "^[%-%+ #0]*%d*%.?%d*([sdifgGeExXcuq])", j)
                if convEnd then
                    flush()
                    nextArg = nextArg + 1
                    parts[#parts + 1] = {
                        cap = NUMERIC_CONV[conv] and NUMBER_CAPTURE or ANY_CAPTURE,
                        arg = pos or nextArg,
                    }
                    i = convEnd + 1
                else
                    buf[#buf + 1] = "%"
                    i = i + 1
                end
            end
        elseif c == "|" and strsub(fmt, i + 1, i + 1) == "4" then
            local close = strfind(fmt, ";", i + 2, true)
            local one, many
            if close then
                one, many = strmatch(strsub(fmt, i + 2, close - 1), "^(.-):(.*)$")
            end
            if one then
                flush()
                parts[#parts + 1] = { plural = { one, many, strsub(fmt, i, close) } }
                i = close + 1
            else
                buf[#buf + 1] = c
                i = i + 1
            end
        else
            buf[#buf + 1] = c
            i = i + 1
        end
    end
    flush()
    return parts
end

function Patterns.FromGlobal(fmt)
    if type(fmt) ~= "string" then return {}, {} end
    fmt = strmatch(fmt, "^%s*(.-)%s*$")
    if fmt == "" then return {}, {} end
    local parts = Tokenize(fmt)
    local order, hasPlural = {}, false
    for _, p in ipairs(parts) do
        if p.cap then order[#order + 1] = p.arg end
        if p.plural then hasPlural = true end
    end
    local list, seen = {}, {}
    for variant = 1, hasPlural and 3 or 1 do
        local out = { "^%s*" }
        for _, p in ipairs(parts) do
            if p.lit then
                out[#out + 1] = Escape(p.lit)
            elseif p.cap then
                out[#out + 1] = p.cap
            else
                out[#out + 1] = Escape(p.plural[variant])
            end
        end
        out[#out + 1] = "%s*$"
        local pat = tconcat(out)
        if not seen[pat] then
            seen[pat] = true
            list[#list + 1] = pat
        end
    end
    return list, order
end

local compiled = {}

local function Compile(key)
    local c = compiled[key]
    if c == nil then
        local fmt = _G[key]
        if type(fmt) == "string" and fmt ~= "" then
            local pats, order = Patterns.FromGlobal(fmt)
            c = { pats = pats, order = order }
        else
            c = false
        end
        compiled[key] = c
    end
    return c or nil
end

local function Reorder(order, ...)
    local n = select("#", ...)
    if n == 0 or #order == 0 then return true end
    local caps, maxArg = {}, 0
    for k = 1, n do
        local arg = order[k] or k
        caps[arg] = (select(k, ...))
        if arg > maxArg then maxArg = arg end
    end
    return unpack(caps, 1, maxArg)
end

function Patterns.Match(key, text)
    if type(text) ~= "string" then return end
    local c = Compile(key)
    if not c then return end
    for _, pat in ipairs(c.pats) do
        if strfind(text, pat) then
            return Reorder(c.order, strmatch(text, pat))
        end
    end
end

function Patterns.Prefix(key, text)
    local label = _G[key]
    if type(label) ~= "string" or type(text) ~= "string" then return end
    label = strgsub(strgsub(label, "|n", ""), "%s+$", "")
    if label == "" then return end
    if strsub(text, 1, #label) == label then
        local rest = strgsub(strsub(text, #label + 1), "^|n", "")
        return (strgsub(rest, "^%s+", ""))
    end
end

local function Expand(prefix, suffixes)
    local out = {}
    for i, s in ipairs(suffixes) do out[i] = prefix .. s end
    return out
end

local TIME_UNITS = { "_SEC", "_MIN", "_HOURS", "_DAYS", "_INSTANT" }

local function Concat(...)
    local out = {}
    for i = 1, select("#", ...) do
        for _, k in ipairs((select(i, ...))) do out[#out + 1] = k end
    end
    return out
end

local STATIC = {
    cast = {
        "SPELL_CAST_TIME_SEC", "SPELL_CAST_TIME_MIN", "SPELL_CAST_TIME_INSTANT",
        "SPELL_CAST_TIME_INSTANT_NO_MANA", "SPELL_CAST_CHANNELED", "SPELL_ON_NEXT_SWING",
        "SPELL_CAST_TIME_RANGED",
    },
    cooldown = Concat(
        Expand("SPELL_RECAST_TIME", TIME_UNITS),
        Expand("SPELL_RECAST_TIME_CHARGES", TIME_UNITS),
        Expand("SPELL_RECAST_TIME_CHARGEUP", TIME_UNITS),
        { "ITEM_COOLDOWN_TOTAL_SEC", "ITEM_COOLDOWN_TOTAL_MIN", "ITEM_COOLDOWN_TOTAL_HOURS",
          "ITEM_COOLDOWN_TOTAL_DAYS", "ITEM_COOLDOWN_TOTAL" }),
    cooldownLeft = {
        "ITEM_COOLDOWN_TIME_SEC", "ITEM_COOLDOWN_TIME_MIN", "ITEM_COOLDOWN_TIME_HOURS",
        "ITEM_COOLDOWN_TIME_DAYS", "ITEM_COOLDOWN_TIME",
    },
    range = { "SPELL_RANGE_DUAL", "SPELL_RANGE", "SPELL_RANGE_AREA", "SPELL_RANGE_UNLIMITED", "MELEE_RANGE" },
    charges = { "SPELL_MAX_CHARGES" },
    requires = { "SPELL_EQUIPPED_ITEM", "SPELL_EQUIPPED_ITEM_NOSPACE" },
    nextRank = { "TOOLTIP_TALENT_NEXT_RANK" },
    passive = { "SPELL_PASSIVE" },
    talent = { "TOOLTIP_TALENT_RANK" },
    level = { "ITEM_LEVEL_RANGE_CURRENT", "ITEM_LEVEL_RANGE", "ITEM_MIN_LEVEL" },
    skill = { "ITEM_MIN_SKILL", "ITEM_REQ_SKILL" },
    armor = { "ARMOR_TEMPLATE" },
    damage = { "DAMAGE_TEMPLATE" },
    dps = { "DPS_TEMPLATE" },
    speed = { "WEAPON_SPEED" },
    durability = { "DURABILITY_TEMPLATE" },
    setName = { "ITEM_SET_NAME" },
    setBonus = { "ITEM_SET_BONUS_GRAY", "ITEM_SET_BONUS", "ITEM_SET_BONUS_NO_VALID_SPEC" },
    unique = { "ITEM_UNIQUE_MULTIPLE", "ITEM_UNIQUE_EQUIPPABLE", "ITEM_UNIQUE" },
    trigger = { "ITEM_SPELL_TRIGGER_ONUSE", "ITEM_SPELL_TRIGGER_ONEQUIP", "ITEM_SPELL_TRIGGER_ONPROC" },
    maker = { "ITEM_CREATED_BY", "ITEM_WRAPPED_BY" },
    equipped = { "CURRENTLY_EQUIPPED" },
    itemLevel = { "ITEM_LEVEL_ALT", "ITEM_LEVEL" },
    upgrade = { "ITEM_UPGRADE_TOOLTIP_FORMAT_STRING", "ITEM_UPGRADE_TOOLTIP_FORMAT" },
    craftQuality = { "PROFESSIONS_CRAFTING_QUALITY" },
    enchant = { "ENCHANTED_TOOLTIP_LINE" },
    binding = {
        "ITEM_SOULBOUND", "ITEM_BIND_ON_PICKUP", "ITEM_BIND_ON_EQUIP", "ITEM_BIND_ON_USE", "ITEM_BIND_QUEST",
        "ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP", "ITEM_BIND_TO_ACCOUNT", "ITEM_BIND_TO_BNETACCOUNT",
        "ITEM_ACCOUNTBOUND_UNTIL_EQUIP", "ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND",
    },
    block = { "SHIELD_BLOCK_TEMPLATE" },
    enchantTemp = { "ITEM_ENCHANT_TIME_LEFT_SEC", "ITEM_ENCHANT_TIME_LEFT_MIN", "ITEM_ENCHANT_TIME_LEFT_HOURS",
        "ITEM_ENCHANT_TIME_LEFT_DAYS" },
    socketable = { "ITEM_SOCKETABLE" },
    transmog = { "TRANSMOGRIFIED", "TRANSMOGRIFIED_HEADER", "TRANSMOGRIFIED_ENCHANT" },
    difficulty = {
        "ENCOUNTER_JOURNAL_SECTION_FLAG3", "ENCOUNTER_JOURNAL_SECTION_FLAG12", "ITEM_HEROIC",
        "PLAYER_DIFFICULTY1", "PLAYER_DIFFICULTY2", "PLAYER_DIFFICULTY3", "PLAYER_DIFFICULTY6",
        "PLAYER_DIFFICULTY_MYTHIC_PLUS", "PLAYER_DIFFICULTY_TIMEWALKER",
    },
    restriction = { "ITEM_CLASSES_ALLOWED", "ITEM_RACES_ALLOWED", "ITEM_REQ_REPUTATION", "ITEM_REQ_SPECIALIZATION" },
    misc = {
        "ITEM_SOCKET_BONUS", "ITEM_SPELL_KNOWN", "ITEM_STARTS_QUEST", "ITEM_CLASSES_ALLOWED",
        "ITEM_RACES_ALLOWED", "ITEM_REQ_REPUTATION", "ITEM_REQ_SPECIALIZATION", "SELL_PRICE",
    },
}
Patterns.STATIC = STATIC

local COST_SUFFIXES = {
    "_COST", "_COST_PER_TIME", "_COST_PER_TIME_NO_BASE",
    "_COST_LARGE", "_COST_LARGE_PER_TIME", "_COST_LARGE_PER_TIME_NO_BASE",
    "_COST_PCT",
}
local COST_EXCLUDE = {
    "TRAINER_", "SEND_MAIL_", "REPAIR_", "BUYOUT_", "SKILL_", "BONUS_ROLL_", "RESEARCH",
    "HOUSING", "CONFIRM_", "BALANCE_", "POWER_DISPLAY_", "ORDER_HALL_", "REAGENT_",
}
Patterns.COST_EXCLUDE = COST_EXCLUDE

local function CostSuffixOf(key)
    local best
    for _, suf in ipairs(COST_SUFFIXES) do
        if #key > #suf and strsub(key, -#suf) == suf and (not best or #suf > #best) then
            best = suf
        end
    end
    return best
end

local function IsCostKey(key)
    if type(key) ~= "string" or not strfind(key, "^[A-Z_]+$") then return false end
    if not CostSuffixOf(key) then return false end
    for _, prefix in ipairs(COST_EXCLUDE) do
        if strsub(key, 1, #prefix) == prefix then return false end
    end
    return true
end
Patterns.IsCostKey = IsCostKey

local function SortCostKeys(keys)
    tsort(keys, function(a, b)
        local sa, sb = #CostSuffixOf(a), #CostSuffixOf(b)
        if sa ~= sb then return sa > sb end
        return a < b
    end)
    return keys
end

local scanned = {}

local function ScanCostKeys()
    local keys = {}
    for k, v in pairs(_G) do
        if type(v) == "string" and IsCostKey(k) then keys[#keys + 1] = k end
    end
    return SortCostKeys(keys)
end

function Patterns.Keys(field)
    if field == "cost" then
        scanned.cost = scanned.cost or ScanCostKeys()
        return scanned.cost
    end
    return STATIC[field]
end

function Patterns.Find(field, text)
    local keys = Patterns.Keys(field)
    if not keys or type(text) ~= "string" then return end
    for _, key in ipairs(keys) do
        local c = Compile(key)
        if c then
            for _, pat in ipairs(c.pats) do
                if strfind(text, pat) then
                    return key, Reorder(c.order, strmatch(text, pat))
                end
            end
        end
    end
end

function Patterns.PowerOf(key)
    local suf = type(key) == "string" and CostSuffixOf(key)
    if not suf then return end
    local name = strsub(key, 1, #key - #suf)
    local colors = _G.PowerBarColor
    if type(colors) ~= "table" then return name end
    local probe = name
    while probe and probe ~= "" do
        if colors[probe] then return probe end
        probe = strmatch(probe, "^[^_]+_(.+)$")
    end
end

local PRIMARY = { STRENGTH = true, AGILITY = true, INTELLECT = true, STAMINA = true }
local SECONDARY = { CRIT_RATING = true, HASTE_RATING = true, MASTERY_RATING = true, VERSATILITY = true }
local TERTIARY = { CR_LIFESTEAL = true, CR_AVOIDANCE = true, CR_SPEED = true, CR_STURDINESS = true }
local CATEGORY_RANK = { primary = 1, secondary = 2, tertiary = 3, other = 4 }

local function StatCore(key)
    return strmatch(key, "^ITEM_MOD_(.+)_SHORT$") or strmatch(key, "^ITEM_MOD_(.+)$")
end

function Patterns.StatCategory(key)
    local core = type(key) == "string" and StatCore(key)
    if not core then return "other" end
    if PRIMARY[core] then return "primary" end
    if strfind(core, "_OR_", 1, true) then
        local all = true
        for part in (core .. "_OR_"):gmatch("(.-)_OR_") do
            if not PRIMARY[part] then all = false end
        end
        if all then return "primary" end
    end
    if SECONDARY[core] then return "secondary" end
    if TERTIARY[core] then return "tertiary" end
    return "other"
end

local function BuildStatNames()
    local map = {}
    local function consider(key, name)
        if type(name) ~= "string" or name == "" then return end
        local cur = map[name]
        if cur then
            local a, b = CATEGORY_RANK[Patterns.StatCategory(key)], CATEGORY_RANK[Patterns.StatCategory(cur)]
            if a > b or (a == b and key > cur) then return end
        end
        map[name] = key
    end
    for k, v in pairs(_G) do
        if type(k) == "string" and strfind(k, "^ITEM_MOD_.+_SHORT$") then consider(k, v) end
    end
    consider("ITEM_MOD_VERSATILITY", _G.ITEM_MOD_VERSATILITY)
    return map
end

function Patterns.Stat(text)
    if type(text) ~= "string" then return end
    local plain = Patterns.StripColors(text)
    local value, name = strmatch(plain, "^%s*%+%s*([%d,%.]+)%%?%s*(.-)%s*$")
    if not value then return end
    scanned.stats = scanned.stats or BuildStatNames()
    local key = scanned.stats[name]
    if not key then return end
    return value, key, Patterns.StatCategory(key)
end

function Patterns.StripTextures(text)
    if type(text) ~= "string" then return text end
    text = strgsub(text, "|T.-|t", "")
    text = strgsub(text, "|A.-|a", "")
    return (strgsub(text, "^%s+", ""))
end

function Patterns.StripColors(text)
    if type(text) ~= "string" then return text end
    text = strgsub(text, "|cn[^:]*:", "")
    text = strgsub(text, "|[cC]%x%x%x%x%x%x%x%x", "")
    text = strgsub(text, "|[cC][%x ][%x ][%x ][%x ][%x ][%x ][%x ][%x ]", "")
    return (strgsub(text, "|[rR]", ""))
end

local ESCAPES = {
    "|[cC]%x%x%x%x%x%x%x%x", "|cn[^:]*:", "|[rR]", "|T.-|t", "|A.-|a", "|H.-|h", "|K.-|k", "|4[^;]*;", "|n",
}

local function ResolvePlurals(text)
    return (strgsub(text, "(%d+)(%s*)|4([^:;]*):([^;]*);", function(number, space, one, many)
        return number .. space .. (tonumber(number) == 1 and one or many)
    end))
end

local function ColorPlain(text, hex)
    return (strgsub(text, "%f[%w](%d+%.?%d*%%?)", function(number)
        local trailing = ""
        if strsub(number, -1) == "." then number, trailing = strsub(number, 1, -2), "." end
        return "|cff" .. hex .. number .. "|r" .. trailing
    end))
end

function Patterns.ColorNumbers(text, hex)
    if type(text) ~= "string" or type(hex) ~= "string" or hex == "" then return text end
    text = ResolvePlurals(text)
    local out, plainStart, pos = {}, 1, 1
    while true do
        local bar = strfind(text, "|", pos, true)
        if not bar then break end
        local escapeEnd
        for _, pattern in ipairs(ESCAPES) do
            local _, stop = strfind(text, "^" .. pattern, bar)
            if stop then escapeEnd = stop break end
        end
        escapeEnd = escapeEnd or math.min(bar + 1, #text)
        out[#out + 1] = ColorPlain(strsub(text, plainStart, bar - 1), hex)
        out[#out + 1] = strsub(text, bar, escapeEnd)
        plainStart, pos = escapeEnd + 1, escapeEnd + 1
    end
    out[#out + 1] = ColorPlain(strsub(text, plainStart), hex)
    return tconcat(out)
end

function Patterns.Reset()
    compiled = {}
    scanned = {}
end
