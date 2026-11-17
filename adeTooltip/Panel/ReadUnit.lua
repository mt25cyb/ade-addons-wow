------------------------------------------------------------
-- 單位（玩家／NPC）reader：Unit API 的明文事實 ＋ 暴雪原樣的提示行 → model
--
-- 跟物品／法術同一條「重繪面板」管線（Try.lua），差在三件事：
--   1. 入口 Panel.TryUnit：先問開關、解析明文單位 token、問身分是不是秘密（C_Secrets）——受限走受限畫法
--   2. 面板接手時不改寫暴雪的行（舊樣式那條才寫）
--   3. 目標、死亡、暫離不在行裡 ⇒ Panel.UnitDynamic 給簽章，輪詢比它
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Panel = ns.Panel or {}
ns.Panel = Panel
local Patterns = ns.Patterns

local LT = Enum and Enum.TooltipDataLineType or {}
Panel.readers = Panel.readers or {}

local function Strip(text)
    if type(text) ~= "string" then return "" end
    local s = Patterns.StripColors(Patterns.StripTextures(text))
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local words
local function Words()
    if words then return words end
    words = { exact = {}, skin = {} }
    local function add(t, key) local v = _G[key]; if type(v) == "string" and v ~= "" then t[v] = key end end
    for _, key in ipairs({ "FACTION_ALLIANCE", "FACTION_HORDE", "PVP", "DEAD", "CORPSE" }) do add(words.exact, key) end
    for _, key in ipairs({ "UNIT_SKINNABLE_LEATHER", "UNIT_SKINNABLE_HERB", "UNIT_SKINNABLE_ROCK",
        "UNIT_SKINNABLE_BOLTS", "UNIT_SKINNABLE_ENGINEERING" }) do add(words.skin, key) end
    words.level = type(_G.LEVEL) == "string" and _G.LEVEL ~= "" and _G.LEVEL or nil
    local fmt = _G.TOOLTIP_UNIT_LEVEL
    words.levelReliable = words.level ~= nil and (type(fmt) ~= "string" or fmt:sub(1, #words.level) == words.level)
    words.hint = type(_G.UNIT_POPUP_RIGHT_CLICK) == "string" and _G.UNIT_POPUP_RIGHT_CLICK or nil
    return words
end
Panel.ResetUnitWords = function() words = nil end

local function IsLevelLine(text)
    local w = Words()
    return w.level ~= nil and text:sub(1, #w.level) == w.level
end

local function DropLevel(facts)
    facts.level, facts.levelColor, facts.classif, facts.classifPlain = nil, nil, nil, nil
end

local levelTyped = false
local function IsLevelType(row)
    if LT.UnitLevel == nil or row.type ~= LT.UnitLevel then return false end
    levelTyped = true
    return true
end

local function IsGuildLine(text, guild)
    if text:sub(1, 1) == "<" then return text:find(guild, 1, true) ~= nil end
    return text == guild or text:sub(1, #guild + 1) == guild .. "-"
end

local function IsBreak(row)
    if row.type ~= nil and (row.type == LT.Blank or row.type == LT.Separator) then return true end
    return Strip(row.left) == "" and not row.right
end

function Panel.ReadUnitRows(rows, facts, hideHint)
    local w = Words()
    local model = { facts = facts, quests = {}, others = {}, extras = {}, skin = {} }
    local nameSeen, levelSeen = false, false
    local beforeLevel = {}
    local className = facts.isPlayer and (facts.classLine or facts.className) or nil
    local guildLine = facts.isPlayer and (facts.guildLine or facts.guild) or nil
    local zoneLine = facts.isPlayer and (facts.zoneLine or facts.zone) or nil
    local creatureLine = not facts.isPlayer and facts.creatureLine or nil
    if creatureLine == "" then creatureLine = nil end
    local specIndex, specLen
    local pending = {}

    for _, row in ipairs(rows) do
        local text = Strip(row.left)
        if row.appended then
            if text ~= "" or (row.right and row.right ~= "") then
                if not (hideHint and w.hint and text == w.hint) then model.extras[#model.extras + 1] = row end
            end
        elseif not nameSeen then
            if not IsBreak(row) then nameSeen = true end
        elseif IsBreak(row) then
        elseif w.hint and text == w.hint then
            if not hideHint then pending[#pending + 1] = row end
        elseif LT.UnitOwner and row.type == LT.UnitOwner then
            model.owner = row.left
        elseif (LT.QuestTitle and row.type == LT.QuestTitle) then
            model.quests[#model.quests + 1] = { left = row.left, right = row.right, color = row.color,
                rightColor = row.rightColor, title = true }
        elseif (LT.QuestObjective and row.type == LT.QuestObjective) or (LT.QuestPlayer and row.type == LT.QuestPlayer) then
            model.quests[#model.quests + 1] = { left = row.left, right = row.right, color = row.color, rightColor = row.rightColor }
        elseif IsLevelType(row) or IsLevelLine(text) then
            levelSeen = true
            if not facts.isPlayer then
                for i, r in ipairs(beforeLevel) do
                    if i == 1 then model.npcTitle = r.left else pending[#pending + 1] = r end
                end
                beforeLevel = {}
            end
        elseif w.exact[text] or (LT.UnitDead and row.type == LT.UnitDead) then
        elseif w.skin[text] then
            model.skin[#model.skin + 1] = row.left
        elseif guildLine and IsGuildLine(text, guildLine) then
        elseif (LT.UnitType and row.type == LT.UnitType) or (creatureLine and text == creatureLine) then
        elseif zoneLine and text == zoneLine then
            model.zone = text
        elseif not facts.isPlayer and not levelSeen then
            beforeLevel[#beforeLevel + 1] = row
        else
            pending[#pending + 1] = row
            if className and className ~= "" and text:sub(1, 1) ~= "<" and text:find(className, 1, true) then
                if not specLen or #text < specLen then specIndex, specLen = #pending, #text end
            end
        end
    end
    if not facts.isPlayer and not levelSeen and (w.levelReliable or levelTyped) then DropLevel(facts) end
    for i, r in ipairs(beforeLevel) do
        if i == 1 then model.npcTitle = r.left else pending[#pending + 1] = r end
    end
    for i, r in ipairs(pending) do
        if i == specIndex then model.specLine = Strip(r.left)
        else model.others[#model.others + 1] = { left = r.left, right = r.right, color = r.color, rightColor = r.rightColor } end
    end
    return model
end

local function GuidOf(token) return S.PlainText((S.SafeCall(UnitGUID, token))) end

function Panel.UnitToken(unit, data)
    local rawGuid = type(data) == "table" and data.guid or nil
    local guid = S.PlainText(rawGuid)
    local plain = S.PlainText(unit)
    if S.IsSecret(rawGuid) then
        if plain and plain ~= "" then return plain, nil, true end
        if S.IsSecret(unit) and S.SafeBool(UnitExists, "mouseover") then return "mouseover", nil, true end
        return nil
    end
    if plain and plain ~= "" then
        if not guid or GuidOf(plain) == guid then return plain, guid end
    end
    if not guid then return nil end
    if UnitTokenFromGUID then
        local t = S.PlainText((S.SafeCall(UnitTokenFromGUID, guid)))
        if t and t ~= "" then return t, guid end
    end
    if GuidOf("mouseover") == guid then return "mouseover", guid end
end

local function IdentitySecret(token)
    local api = C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret
    if not api then return false end
    local ok, v = pcall(api, token)
    if not ok or S.IsSecret(v) then return true end
    return v and true or false
end

local function Restore(tip, state)
    if state.native or (state.panel and state.panel:IsShown()) then Panel.Restore(tip, state) end
    return false
end

function Panel.UnitWanted()
    local u = ns.settings and ns.settings.unit
    return u ~= nil and ((u.player and u.player.panel) or (u.npc and u.npc.panel)) and true or false
end

function Panel.TryUnit(tip, state, unit, data)
    local token, guid, restricted = Panel.UnitToken(unit, data)
    if not token or not (guid or restricted) then return Restore(tip, state) end
    local isPlayer = S.SafeBool(UnitIsPlayer, token)
    local config = ns.settings.unit[isPlayer and "player" or "npc"]
    if not (config and config.panel) then return Restore(tip, state) end
    if not restricted and IdentitySecret(token) then restricted, guid = true, nil end
    local blockKey = restricted and Panel.UNIT_BLOCK_RESTRICTED or ("unit:" .. guid)
    if state.unitBlockKey == blockKey and GetTime() < (state.unitBlockUntil or 0) then return Restore(tip, state) end
    state.panelUnit, state.panelGuid, state.panelRestricted = token, guid, restricted or nil
    return Panel.Try(tip, state, "unit", data)
end

function Panel.UnitGone(state)
    local token = state.panelUnit
    if not token then return true end
    local exists = S.SafeCall(UnitExists, token)
    if not S.IsSecret(exists) and exists ~= nil and not exists then return true end
    if state.panelRestricted then return false end
    local guid = GuidOf(token)
    return guid == nil or guid ~= state.panelGuid
end

local function B(fn, token) return S.SafeBool(fn, token) and "1" or "0" end

function Panel.UnitDynamic(state)
    if Panel.UnitGone(state) then return nil end
    local token = state.panelUnit
    local target = "-"
    local tt = token .. "target"
    if S.SafeBool(UnitExists, tt) then target = GuidOf(tt) or "?" end
    local cache = ""
    local info = ns.UnitInfo
    local guid = state.panelGuid
    if info and guid then
        local ins = info.inspectState and info.inspectState.cache[guid]
        local ach = info.achieveState and info.achieveState.cache[guid]
        cache = (ins and ins.level or "") .. "/" .. (ach and ach.points or "")
    end
    return table.concat({ target, B(UnitIsDead, token), B(UnitIsAFK, token), B(UnitIsDND, token),
        B(UnitIsTapDenied, token), B(UnitIsPVP, token), cache,
        (IsAltKeyDown() or IsControlKeyDown()) and "m" or "" }, "|")
end

function Panel.UnitTick(state)
    local fs = state.panelTargetFS
    if not fs or not state.panelUnit then return end
    local name = S.SafeCall(UnitName, state.panelUnit .. "target")
    if name ~= nil then fs:SetText(name) end
end

local function ColorTable(r, g, b)
    r, g, b = S.PlainNumber(r), S.PlainNumber(g), S.PlainNumber(b)
    if r and g and b then return { r, g, b } end
end

local function ClassColor(classFile)
    classFile = S.PlainText(classFile)
    local c = classFile and ((_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[classFile]) or
        (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[classFile]))
    if c and type(c.r) == "number" then return { c.r, c.g, c.b } end
end
Panel.ClassColor = ClassColor

local function UnitColorOf(token)
    if S.SafeBool(UnitIsPlayer, token) then
        local _, cls = S.SafeCall(UnitClass, token)
        local c = ClassColor(cls)
        if c then return c end
    end
    local r, g, b = ns.Colors.UnitColor(token)
    return ColorTable(ns.Colors.Readable(r, g, b)) or { 1, 1, 1 }
end
Panel.UnitColorOf = UnitColorOf

local function DifficultyColor(level)
    if level == -1 then return { 1, 0.1, 0.1 } end
    if GetCreatureDifficultyColor then
        local ok, c = pcall(GetCreatureDifficultyColor, level)
        if ok and type(c) == "table" and type(c.r) == "number" then return { c.r, c.g, c.b } end
    end
    return { 1, 0.82, 0 }
end

local function Target(token)
    local tt = token .. "target"
    if not S.SafeBool(UnitExists, tt) then return nil end
    if S.SafeBool(UnitIsUnit, tt, "player") then return { you = true } end
    local name = S.SafeCall(UnitName, tt)
    if name == nil then return nil end
    if S.IsSecret(name) then return { secret = true, color = { 1, 1, 1 } } end
    if name == "" then return nil end
    return { name = name, color = UnitColorOf(tt) }
end

local function TargetedBy(token)
    local num = GetNumGroupMembers and GetNumGroupMembers() or 0
    if num < 1 then return nil end
    local prefix = IsInRaid() and "raid" or "party"
    local listNames = prefix == "party" or S.SafeBool(UnitIsPlayer, token)
    local names, count = {}, 0
    for i = 1, num do
        local member = prefix .. i
        if S.SafeBool(UnitIsUnit, token, member .. "target") and not S.SafeBool(UnitIsUnit, member, "player") then
            count = count + 1
            if listNames then
                local name = S.PlainText((S.SafeCall(UnitName, member)))
                local _, cls = S.SafeCall(UnitClass, member)
                if name then names[#names + 1] = { name = name, color = ClassColor(cls) } end
            end
        end
    end
    if count == 0 then return nil end
    return { count = count, names = listNames and names or nil, self = S.SafeBool(UnitIsUnit, token, "player") }
end

function Panel.UnitFacts(token, config)
    local UnitInfo = ns.UnitInfo
    local raw = UnitInfo.GetPanelInfo(token)
    local name = S.PlainText(raw.name)
    if not name or name == "" then return nil end
    local showAll = UnitInfo.ModifierShowAll(config)
    local el = config.elements or {}
    local function on(key)
        local c = el[key]
        return c ~= nil and UnitInfo.CheckFilter(c, raw, showAll) and true or false
    end
    local isPlayer = S.SafeBool(UnitIsPlayer, token)
    local f = { isPlayer = isPlayer, name = name, showAll = showAll }

    if isPlayer then
        if on("title") then f.title, f.titlePrefix = S.PlainText(raw.title), raw.titleIsPrefix end
        local _, realm = S.SafeCall(UnitName, token)
        realm = S.PlainText(realm)
        if on("realm") and realm and realm ~= "" then f.realm = realm end
        if on("friendIcon") then f.friendIcon = raw.friendIcon end
        if on("roleIcon") then f.roleIcon = raw.roleIcon end
    end

    local level = S.PlainNumber(raw.level)
    if on("levelValue") and level then
        f.level = level
        local lv = S.PlainNumber(raw.effectiveLevel) or level
        f.levelColor = DifficultyColor(level == -1 and -1 or lv)
    end

    if isPlayer then
        f.guildLine = S.PlainText(raw.guildName)
        f.classLine = S.PlainText(raw.className)
        f.zoneLine = S.PlainText(raw.zone)
        if on("guildName") then f.guild = f.guildLine end
        if f.guild and on("guildRank") then f.guildRank = S.PlainText(raw.guildRank) end
        if on("raceName") then f.race = S.PlainText(raw.raceName) end
        if on("className") then f.className = S.PlainText(raw.className) end
        if on("gender") then f.gender = S.PlainText(raw.gender) end
        f.classFile = S.PlainText(raw.class)
        if on("factionName") then
            local fn = S.PlainText(raw.factionName)
            if fn then
                local r, g, b = ns.Colors.colorfunc.faction(raw)
                f.factionName, f.factionColor = fn, ColorTable(r, g, b)
            end
        end
        if on("statusAFK") then f.afk = raw.statusAFK ~= nil end
        if on("statusDND") then f.dnd = raw.statusDND ~= nil end
        if on("statusDC") then f.dc = raw.statusDC ~= nil end
        if on("isPlayer") then f.playerTag = _G.PLAYER end
    else
        f.creatureLine = S.PlainText(raw.creature)
        if on("creature") then f.creature = f.creatureLine end
        local classif = S.PlainText(raw.classif)
        if level == -1 or classif == "worldboss" then
            if on("classifBoss") then f.classif = "boss" end
        elseif classif == "rareelite" then
            f.classif = on("classifRare") and (on("classifElite") and "rareelite" or "rare") or (on("classifElite") and "elite") or nil
        elseif classif == "rare" then
            if on("classifRare") then f.classif = "rare" end
        elseif classif == "elite" then
            if on("classifElite") then f.classif = "elite" end
        end
        if on("reactionName") then f.reactionName = S.PlainText(raw.reactionName) end
        f.npcTitleOn = on("npcTitle")
        f.tapped = S.SafeBool(UnitIsTapDenied, token)
    end
    f.factionGroup = S.PlainText(raw.factionGroup)
    f.classifPlain = S.PlainText(raw.classif)
    f.pvp = S.SafeBool(UnitIsPVP, token)
    f.dead = S.SafeBool(UnitIsDeadOrGhost, token)

    if isPlayer then
        if on("mount") then
            UnitInfo.FillMount(raw, token)
            local mount = S.PlainText(raw.mountName)
            if mount then f.mount, f.mountCollected = mount, raw.mountCollected end
        end
        if on("itemLevel") then
            local v = raw.itemLevel
            if v == ns.L["unknown"] then UnitInfo.RequestInspect(token) end
            f.itemLevel = v
            f.itemLevelDecimals = el.itemLevel and el.itemLevel.decimals
            if type(v) == "number" then
                local r, g, b = ns.Colors.colorfunc.itemLevel(raw)
                f.itemLevelColor = ColorTable(r, g, b)
            end
        end
        if on("achievementPoints") then
            local v = raw.achievementPoints
            if v == ns.L["unknown"] then UnitInfo.RequestAchievements(token) end
            f.achievement = v
            if type(v) == "number" then
                local r, g, b = ns.Colors.colorfunc.achievement(raw)
                f.achievementColor = ColorTable(r, g, b)
            end
        end
        if on("mplusScore") and type(raw.mplusScoreNumber) == "number" and raw.mplusScoreNumber > 0 then
            local r, g, b = ns.Colors.colorfunc.mplus(raw)
            f.mplus, f.mplusBest, f.mplusColor = raw.mplusScoreNumber, raw.mplusBestText, ColorTable(r, g, b)
        end
        if on("zone") then f.zone = S.PlainText(raw.zone) end
    end
    if on("moveSpeed") and type(raw.moveSpeed) == "number" then f.speed = raw.moveSpeed end

    if isPlayer then f.color = ClassColor(f.classFile) or { 1, 1, 1 }
    else
        local r, g, b = ns.Colors.UnitColor(token)
        f.color = ColorTable(ns.Colors.Readable(r, g, b)) or { 1, 1, 1 }
    end
    if f.tapped then f.color = { 0.6, 0.6, 0.6 } end
    local token2 = config.coloredBorder
    local cf = token2 and ns.Colors.colorfunc[token2]
    if cf then
        local r, g, b = cf(raw)
        f.border = ColorTable(r, g, b)
    elseif type(token2) == "string" and token2:match("^%x%x%x%x%x%x$") then
        f.border = { ns.Colors.FromHex(token2) }
    end
    if config.grayForDead and f.dead then
        f.gray = true
        f.color = { 0.6, 0.6, 0.6 }
        f.border = { 0.6, 0.6, 0.6 }
        if f.levelColor then f.levelColor = { 0.6, 0.6, 0.6 } end
    end

    if config.showTarget then f.target = Target(token) end
    if config.showTargetBy then f.targetedBy = TargetedBy(token) end
    return f
end

local function Plain(fn, ...)
    local v = S.SafeCall(fn, ...)
    if S.IsSecret(v) then return nil end
    return v
end

function Panel.UnitFactsRestricted(token, config)
    local level = S.PlainNumber(Plain(UnitLevel, token))
    local effective = S.PlainNumber(Plain(UnitEffectiveLevel, token)) or level
    local reaction = S.PlainNumber(Plain(UnitReaction, token, "player"))
    local classif = S.PlainText(Plain(UnitClassification, token))
    local raw = { unit = token, level = level, effectiveLevel = effective, reaction = reaction, classif = classif }
    local UnitInfo = ns.UnitInfo
    local showAll = UnitInfo.ModifierShowAll(config)
    local el = config.elements or {}
    local function on(key)
        local c = el[key]
        return c ~= nil and UnitInfo.CheckFilter(c, raw, showAll) and true or false
    end
    local isPlayer = S.SafeBool(UnitIsPlayer, token)
    local f = { restricted = true, isPlayer = isPlayer, showAll = showAll, classifPlain = classif }
    f.name = S.SafeCall(UnitName, token)
    if f.name == nil then return nil end
    if on("levelValue") and level then
        f.level = level
        f.levelColor = DifficultyColor(level == -1 and -1 or effective)
    end
    if not isPlayer then
        if level == -1 or classif == "worldboss" then
            if on("classifBoss") then f.classif = "boss" end
        elseif classif == "rareelite" then
            f.classif = on("classifRare") and (on("classifElite") and "rareelite" or "rare") or (on("classifElite") and "elite") or nil
        elseif classif == "rare" then
            if on("classifRare") then f.classif = "rare" end
        elseif classif == "elite" then
            if on("classifElite") then f.classif = "elite" end
        end
        if on("reactionName") and reaction then f.reactionName = S.PlainText(_G["FACTION_STANDING_LABEL" .. reaction]) end
        f.tapped = S.SafeBool(UnitIsTapDenied, token)
    end
    f.dead = S.SafeBool(UnitIsDeadOrGhost, token)

    local r, g, b = ns.Colors.UnitColor(token)
    f.color = ColorTable(ns.Colors.Readable(r, g, b)) or { 1, 1, 1 }
    if f.tapped then f.color = { 0.6, 0.6, 0.6 } end
    local token2 = config.coloredBorder
    local cf = token2 and ns.Colors.colorfunc[token2]
    if cf then f.border = ColorTable(cf(raw))
    elseif type(token2) == "string" and token2:match("^%x%x%x%x%x%x$") then f.border = { ns.Colors.FromHex(token2) } end
    if config.grayForDead and f.dead then
        f.gray = true
        f.color = { 0.6, 0.6, 0.6 }
        f.border = { 0.6, 0.6, 0.6 }
        if f.levelColor then f.levelColor = { 0.6, 0.6, 0.6 } end
    end
    if config.showTarget then f.target = Target(token) end
    return f
end

local RESTRICTED_USE
local function RestrictedUse()
    if RESTRICTED_USE then return RESTRICTED_USE end
    RESTRICTED_USE = {}
    local function use(name, how) if LT[name] then RESTRICTED_USE[LT[name]] = how end end
    use("None", "none")
    use("UnitLevel", "level")
    use("UnitType", "none")
    use("QuestTitle", "questTitle")
    use("QuestObjective", "quest")
    use("QuestPlayer", "quest")
    use("UnitOwner", "other")
    use("UnitThreat", "other")
    use("UnitCriteriaProgress", "other")
    return RESTRICTED_USE
end

function Panel.CollectRestrictedLines(tip, data)
    if type(data) ~= "table" then return end
    local lines = data.lines
    if type(lines) ~= "table" or S.IsSecret(lines) then return end
    local okName, name = pcall(tip.GetName, tip)
    name = okName and S.PlainText(name)
    if not name then return end
    local use = RestrictedUse()
    local rows, covered = {}, {}
    for _, line in ipairs(lines) do
        if type(line) ~= "table" or S.IsSecret(line) then return end
        local lineType, index = line.type, line.lineIndex
        if S.IsSecret(lineType) or S.IsSecret(index) then return end
        if type(index) == "number" then covered[index] = true end
        local how = lineType ~= nil and use[lineType]
        if how then rows[#rows + 1] = { left = "", type = lineType, lineIndex = index, use = how, secretText = line.leftText } end
    end
    local n = Panel.CollectAppended(tip, name, covered, rows, true)
    if not n then return end
    return rows, n
end

function Panel.ReadRestrictedUnitRows(rows, facts, hideHint)
    local w = Words()
    local model = { facts = facts, quests = {}, others = {}, extras = {}, skin = {},
        secretHeader = {}, secretQuests = {}, secretOthers = {} }
    for _, row in ipairs(rows) do if row.use == "level" then IsLevelType(row) end end
    local typed = levelTyped
    local levelSeen = false
    for _, row in ipairs(rows) do
        if row.appended then
            local text = Strip(row.left)
            if (text ~= "" or (row.right and row.right ~= "")) and not (hideHint and w.hint and text == w.hint) then
                model.extras[#model.extras + 1] = row
            end
        elseif row.use == "level" then levelSeen = true
        elseif row.use == "none" then
            if levelSeen or typed then model.secretHeader[#model.secretHeader + 1] = { value = row.secretText }
            else levelSeen = true end
        elseif row.use == "questTitle" then model.secretQuests[#model.secretQuests + 1] = { value = row.secretText, title = true }
        elseif row.use == "quest" then model.secretQuests[#model.secretQuests + 1] = { value = row.secretText }
        elseif row.use == "other" then model.secretOthers[#model.secretOthers + 1] = { value = row.secretText }
        end
    end
    if not facts.isPlayer and not levelSeen then DropLevel(facts) end
    return model
end

function Panel.UnitPreviewModel(raw, config, icon)
    local UnitInfo = ns.UnitInfo
    local showAll = UnitInfo.ModifierShowAll(config)
    local el = config.elements or {}
    local function on(key)
        local c = el[key]
        return c ~= nil and UnitInfo.CheckFilter(c, raw, showAll) and true or false
    end
    local f = { isPlayer = false, name = raw.name, classifPlain = raw.classif }
    if on("levelValue") and type(raw.level) == "number" then f.level, f.levelColor = raw.level, DifficultyColor(raw.level) end
    if on("creature") then f.creature = raw.creature end
    if raw.classif == "elite" and on("classifElite") then f.classif = "elite" end
    if on("reactionName") then f.reactionName = raw.reactionName end
    local c = _G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[raw.reaction or 4]
    f.color = c and { c.r, c.g, c.b } or { 1, 0.82, 0 }
    if config.showTarget then
        local name = S.PlainText((S.SafeCall(UnitName, "player")))
        local _, cls = S.SafeCall(UnitClass, "player")
        if name then f.target = { name = name, color = ClassColor(cls) } end
    end
    return { kind = "unit", facts = f, quests = {}, others = {}, extras = {}, skin = {}, icon = icon }
end

Panel.readers.unit = function(tip, data, _, rows, n, state)
    if not state or not state.panelUnit or not rows then return end
    local token = state.panelUnit
    local isPlayer = S.SafeBool(UnitIsPlayer, token)
    local config = ns.settings.unit[isPlayer and "player" or "npc"]
    local hideHint = ns.settings.general and ns.settings.general.hideUnitFrameHint
    local facts, model
    if state.panelRestricted then
        facts = Panel.UnitFactsRestricted(token, config)
        if not facts then return end
        model = Panel.ReadRestrictedUnitRows(rows, facts, hideHint)
    else
        facts = Panel.UnitFacts(token, config)
        if not facts then return end
        model = Panel.ReadUnitRows(rows, facts, hideHint)
    end
    model.kind, model.numLines, model.rows = "unit", n, rows
    model.unit, model.guid = token, state.panelGuid
    if not facts.npcTitleOn then model.npcTitle = nil end
    local b = facts.border
    if b and ns.Skin and ns.Skin.SetBorderColor then
        state.panelBorder = { b[1], b[2], b[3], 1 }
        ns.Skin.SetBorderColor(tip, b[1], b[2], b[3], 1)
    else
        state.panelBorder = nil
    end
    return model
end
