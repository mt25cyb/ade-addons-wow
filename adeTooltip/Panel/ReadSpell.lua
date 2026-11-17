------------------------------------------------------------
-- 法術 reader：CollectLines 的 rows → model（逐字對照 MiliUI_Tooltip/Panel/ReadSpell.lua）
-- 純邏輯（Panel.ReadSpellRows 吃 rows＋game 介面）。描述整段不切句、|n 原樣保留。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Panel = ns.Panel or {}
ns.Panel = Panel
local Patterns = ns.Patterns

local LT = Enum and Enum.TooltipDataLineType or {}
Panel.readers = Panel.readers or {}
Panel.views = Panel.views or {}

local function Trim(s)
    return (type(s) == "string" and s:match("^%s*(.-)%s*$")) or ""
end
Panel.Trim = Trim

function Panel.IsRed(c)
    return c ~= nil and c[1] > 0.9 and c[2] < 0.3 and c[3] < 0.3
end

local function Colored(c)
    return c ~= nil and not (c[1] > 0.95 and c[2] > 0.95 and c[3] > 0.95)
end

local function IsGold(c)
    return c ~= nil and c[1] > 0.9 and c[2] > 0.65 and c[2] < 0.9 and c[3] < 0.3
end

local function Num(s)
    if type(s) ~= "string" then return tonumber(s) end
    return tonumber((s:gsub(",", "")))
end
Panel.Num = Num

local function NewPart()
    return { requirements = {}, details = {}, description = {}, extras = {} }
end

local function Typed(row, name)
    return row.type ~= nil and LT[name] ~= nil and row.type == LT[name]
end

local function ClassifyText(part, text, row)
    local plain = Trim(Patterns.StripColors(text))
    if plain == "" then return true end

    if Patterns.Match("SPELL_PASSIVE", plain) then part.passive = plain return true end
    local key, a, b = Patterns.Find("talent", plain)
    if key then part.talent = { text = plain, rank = Num(a), max = Num(b) } return true end
    key, a = Patterns.Find("cost", plain)
    if key then part.cost = { text = plain, key = key, power = Patterns.PowerOf(key) } return true end
    key, a = Patterns.Find("cast", plain)
    if key then part.cast = { text = plain, key = key, value = (a ~= true) and a or nil } return true end
    key = Patterns.Find("cooldownLeft", plain)
    if key then part.details[#part.details + 1] = { left = plain, remaining = true } return true end
    key, a = Patterns.Find("cooldown", plain)
    if key then
        part.cooldown = { text = plain, key = key, value = (a ~= true) and a or nil,
            recharge = key:find("_CHARGES_", 1, true) ~= nil }
        return true
    end
    key, a = Patterns.Find("range", plain)
    if key then part.range = { text = plain, key = key } return true end
    key, a = Patterns.Find("charges", plain)
    if key then part.charges = { text = plain, count = Num(a) } return true end
    key = Patterns.Find("requires", plain)
    if key then part.requirements[#part.requirements + 1] = { left = plain, unmet = Panel.IsRed(row and row.color) } return true end
    if Patterns.Prefix("SPELL_REAGENTS", plain) or Patterns.Prefix("SPELL_TOTEMS", plain) then
        part.details[#part.details + 1] = { left = text }
        return true
    end
    return false
end

local function Unmet(row, text, game)
    if row.usable == false then return true end
    if Panel.IsRed(row.color) then return true end
    local level = Patterns.Match("ITEM_MIN_LEVEL", Trim(Patterns.StripColors(text)))
    local mine = game and game.playerLevel and game.playerLevel()
    if level and level ~= true and mine then return mine < (Num(level) or 0) end
    return false
end
Panel.Unmet = Unmet

local function Extra(part, row, left, right, model)
    local list = row.appended and model and model.appended or part.extras
    list[#list + 1] = { left = left or "", right = right, color = row.color, rightColor = row.rightColor }
end

function Panel.ReadSpellRows(rows, game, id)
    local model = NewPart()
    model.kind = "spell"
    model.appended = {}
    model.tags = {}
    local seenBody = false
    local part = model
    local nextRank
    local nameTaken = false

    local first = rows[1]
    if first and Typed(first, "NestedBlock") and Trim(first.left or "") == "" and not first.right then
        local inner = {}
        for i = 2, #rows do inner[#inner + 1] = rows[i] end
        rows = inner
        id = S.PlainNumber(id) or S.PlainNumber(first.tooltipID)
    end
    local outer = {}
    for _, row in ipairs(rows) do
        if Typed(row, "NestedBlock") then break end
        outer[#outer + 1] = row
    end
    for _, row in ipairs(rows) do
        if row.appended then outer[#outer + 1] = row end
    end
    local nameRow
    for _, row in ipairs(outer) do
        if Typed(row, "SpellName") then nameRow = row break end
    end
    if not nameRow then
        for _, row in ipairs(outer) do
            if row.lineIndex == 1 and Trim(row.left) ~= "" then nameRow = row break end
        end
    end
    if not nameRow then
        for _, row in ipairs(outer) do
            if not row.appended and Trim(row.left) ~= "" then nameRow = row break end
        end
    end

    for _, row in ipairs(rows) do
        local left, right = row.left or "", row.right
        if row == nameRow and not nameTaken then
            nameTaken = true
            model.name = Trim(Patterns.StripTextures(left))
            model.nameColor = row.color
            if right and Trim(right) ~= "" then model.subtitle = Trim(right) end
        elseif Typed(row, "NestedBlock") then
            local sub = NewPart()
            sub.kind = "spell"
            sub.id = S.PlainNumber(row.tooltipID)
            sub.icon = sub.id and game and game.spellIcon and game.spellIcon(sub.id) or nil
            model.nested = sub
            part = sub
        elseif part == model.nested and not part.name and Typed(row, "SpellName") then
            part.name = Trim(Patterns.StripTextures(left))
        elseif row.appended and nextRank and not left:find("|c", 1, true) then
            nextRank[#nextRank + 1] = { left = left, right = right, color = row.color, rightColor = row.rightColor }
        elseif row.appended and Patterns.Find("nextRank", Trim(Patterns.StripColors(left))) then
            nextRank = {}
            model.nextRank = { label = Trim(left), rows = nextRank }
        elseif Typed(row, "Blank") or Typed(row, "Separator") then
            if seenBody or #part.description > 0 then part.tail = part.tail or {} end
        elseif part.tail and not row.appended then
            part.tail[#part.tail + 1] = { left = left, right = right, color = row.color, rightColor = row.rightColor }
        elseif Typed(row, "SpellPassive") and not right then
            part.passive = Trim(left)
        elseif Typed(row, "SpellDescription") then
            seenBody = true
            if Trim(left) ~= "" then part.description[#part.description + 1] = (left:gsub("\r", "")) end
        elseif Typed(row, "UsageRequirement") then
            part.requirements[#part.requirements + 1] = { left = Trim(left), right = right, unmet = Unmet(row, left, game) }
        else
            local okLeft = Trim(left) == "" or ClassifyText(part, left, row)
            local okRight = not right or ClassifyText(part, right, row)
            if not seenBody and not row.appended and part == model then
                if not okLeft and Colored(row.color) then
                    model.tags[#model.tags + 1] = { Trim(left), row.color }
                    okLeft = true
                end
                if not okRight and Colored(row.rightColor) then
                    model.tags[#model.tags + 1] = { Trim(right), row.rightColor }
                    okRight = true
                end
            end
            if part.cost or part.cast or part.cooldown or part.range then seenBody = true end
            if not okLeft and not row.appended and not right and (row.wrap or IsGold(row.color)) then
                part.description[#part.description + 1] = left
            elseif not okLeft or not okRight then
                Extra(part, row, okLeft and "" or left, (not okRight) and right or nil, model)
            end
        end
    end

    if not model.name or model.name == "" then return end
    model.id = S.PlainNumber(id)
    model.icon = model.id and game and game.spellIcon and game.spellIcon(model.id) or nil
    return model
end

------------------------------------------------------------
-- 遊戲端介面
------------------------------------------------------------
Panel.Game = Panel.Game or {}
local Game = Panel.Game

function Game.spellIcon(id)
    if not (C_Spell and C_Spell.GetSpellTexture) then return end
    local ok, icon = pcall(C_Spell.GetSpellTexture, id)
    return ok and S.PlainNumber(icon) or nil
end

function Game.playerLevel()
    local ok, level = pcall(UnitLevel, "player")
    return ok and S.PlainNumber(level) or nil
end

Panel.readers.spell = function(tip, data, _, rows, n)
    if not rows then rows, n = Panel.CollectLines(tip, data) end
    if not rows then return end
    local model = Panel.ReadSpellRows(rows, Panel.Game, data and data.id)
    if not model then return end
    model.rows, model.numLines = rows, n
    return model
end
