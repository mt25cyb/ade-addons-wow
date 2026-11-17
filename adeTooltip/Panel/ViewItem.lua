------------------------------------------------------------
-- 物品 view：model → view 表（Render.lua 畫）（逐字對照 MiliUI_Tooltip/Panel/ViewItem.lua）
--   標題：圖示（40²）+ 品質色名字 + 等級/綁定/部位/獨特/套装名 徽章列；
--   品質細線、描述、武器/護甲數據、附魔/插槽、套裝、需求、效果、 ketter。
--   ⚠ 數字著色走 Panel.NumberHex()（ViewSpell 定義）；別人後加的行走 extras。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local L = ns.L
local Panel = ns.Panel or {}
ns.Panel = Panel
local LOOK = Panel.LOOK
local S = ns.Secret

local Trim = Panel.Trim or function(s) return (type(s) == "string" and s:match("^%s*(.-)%s*$")) or "" end
local StripColors = ns.Patterns.StripColors

local function Hex(c)
    return ("%02x%02x%02x"):format(math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5),
        math.floor(c[3] * 255 + 0.5))
end

local function QualityColor(row)
    local c = row and row.color
    if c and type(c.r) == "number" then return { c.r, c.g, c.b } end
    if c and type(c[1]) == "number" then return c end
    return LOOK.TEXT
end
Panel.QualityColor = QualityColor

local function Dim(c, t)
    return { c[1] + (LOOK.TEXT[1] - c[1]) * t, c[2] + (LOOK.TEXT[2] - c[2]) * t,
        c[3] + (LOOK.TEXT[3] - c[3]) * t }
end

local function Pair(label, value)
    return { left = label, right = value }
end

local function Pct(n)
    return n and (("%." .. (math.floor(n) == n and 0 or 1) .. "f%%"):format(n)) or nil
end

local function Coins(price)
    local gold = math.floor((price or 0) / 10000)
    local silver = math.floor((price or 0) / 100) % 100
    local copper = (price or 0) % 100
    local out = {}
    if gold > 0 then out[#out + 1] = ("|cffffd700%dg|r"):format(gold) end
    if silver > 0 then out[#out + 1] = ("|cffc7c7cf%ds|r"):format(silver) end
    if copper > 0 or #out == 0 then out[#out + 1] = ("|cffeda55f%dc|r"):format(copper) end
    return table.concat(out, " ")
end

function Panel.BadgeText(text, color)
    if not text or text == "" then return nil end
    return { text = text, color = color }
end

local function AddBadge(list, text, color)
    if not text or text == "" then return end
    if type(text) == "table" then
        if text.text and text.text ~= "" then list[#list + 1] = text end
    else
        list[#list + 1] = { text = text, color = color }
    end
end

local function Stats(part, numberHex)
    local rows = {}
    local function color(v)
        if v < 0 then return LOOK.UNUSABLE end
        if numberHex then return nil, "|cff" .. numberHex end
        return nil, nil
    end
    for _, s in ipairs(part.stats) do
        local c = s.color or LOOK.TEXT
        local neg, numPrefix = color(s.value)
        local text = s.text
        if numPrefix and s.value then
            local _, a = Patterns.Stat(text)
            if a then text = text:gsub(tostring(a), numPrefix .. tostring(a) .. "|r", 1) end
        end
        rows[#rows + 1] = { left = text, color = s.disabled and LOOK.DIM or (neg or c) }
    end
    if part.armor and part.armor.value then
        local a = part.armor
        local text = a.text or ("%s %s"):format(_G.ARMOR or "Armor", tostring(a.value))
        rows[#rows + 1] = { left = text, color = LOOK.TEXT }
    end
    if part.block and part.block.value then
        rows[#rows + 1] = { left = part.block.text, color = LOOK.TEXT }
    end
    if part.weapon then
        local w = part.weapon
        if w.damage then rows[#rows + 1] = { left = w.damage.text, color = LOOK.TEXT } end
        if w.dps then rows[#rows + 1] = { left = w.dps.text, color = LOOK.TEXT } end
        if w.speed then rows[#rows + 1] = { left = w.speed.text, color = LOOK.TEXT } end
    end
    if part.durability and part.durability.cur and part.durability.max then
        rows[#rows + 1] = { left = part.durability.text, color = LOOK.TEXT }
    end
    return rows
end

local function EnchantRows(part)
    local rows = {}
    for _, e in ipairs(part.enchants) do
        rows[#rows + 1] = { left = e.left, right = e.right, color = e.color or LOOK.SECONDARY }
    end
    for _, s in ipairs(part.sockets) do
        local left = s.left
        if s.gemIcon then left = ("|T%s:14|t "):format(s.gemIcon) .. left end
        rows[#rows + 1] = { left = left, right = s.right, color = s.color or LOOK.TEXT }
    end
    return rows
end

local function EffectRows(part, numberHex)
    local rows = {}
    for _, e in ipairs(part.effects) do
        local label = e.label and ("%s %s"):format(e.label, _G.USE or "") or nil
        rows[#rows + 1] = { left = e.text, color = LOOK.TEXT }
    end
    return rows
end

local function BuildHeader(model, color)
    local badges = {}
    if model.tag then AddBadge(badges, model.tag, LOOK.SECONDARY) end
    if model.subtitle then AddBadge(badges, StripColors(model.subtitle), LOOK.SECONDARY) end
    if model.itemLevel then AddBadge(badges, model.itemLevel.text, LOOK.SECONDARY) end
    if model.binding then AddBadge(badges, model.binding, LOOK.SECONDARY) end
    if model.slot then AddBadge(badges, model.slot, LOOK.SECONDARY) end
    if model.armorType then AddBadge(badges, model.armorType, LOOK.SECONDARY) end
    for _, u in ipairs(model.unique) do AddBadge(badges, u, LOOK.SECONDARY) end
    if model.upgrade then AddBadge(badges, StripColors(model.upgrade), LOOK.SECONDARY) end
    if model.craftQuality then AddBadge(badges, StripColors(model.craftQuality), LOOK.SECONDARY) end
    local header = { { text = model.name, style = "title", color = color } }
    if #badges > 0 then header[2] = { badges = badges, style = "small" } end
    for _, row in ipairs(model.headerRows or {}) do
        header[#header + 1] = { text = row.left, style = "small", color = row.color or LOOK.SECONDARY }
    end
    return header
end

local function PriceRow(model)
    if not model.price or model.price <= 0 then return nil end
    local right = Coins(model.price)
    if model.unitPrice and model.stackCount then
        right = right .. "  " .. ("|cff9d9d9d%d × %s|r"):format(model.stackCount, Coins(model.unitPrice))
    end
    return { left = _G.SELL_PRICE or "Sell Price", right = right, color = LOOK.SECONDARY }
end

function Panel.ViewItem(model)
    local color = QualityColor(model.nameColor)
    local view = {
        icon = model.icon, iconSize = LOOK.ICON_ITEM,
        header = BuildHeader(model, color),
        sections = {},
    }

    if model.quality then
        view.sections[#view.sections + 1] = { kind = "rows", rows = { { left = model.quality, color = color } },
            separator = { space = LOOK.HEADER_BOTTOM } }
    end
    if #model.flavor > 0 then
        local rows = {}
        for i, line in ipairs(model.flavor) do rows[i] = { left = line, color = LOOK.FLAVOR } end
        view.sections[#view.sections + 1] = { kind = "prose", paragraphs = model.flavor, color = LOOK.FLAVOR,
            separator = { space = LOOK.HEADER_BOTTOM } }
    end

    local numberHex = Panel.NumberHex and Panel.NumberHex() or nil
    local statRows = Stats(model, numberHex)
    if #statRows > 0 then
        view.sections[#view.sections + 1] = { kind = "rows", rows = statRows, separator = { rule = true } }
    end

    local ench = EnchantRows(model)
    if #ench > 0 then
        view.sections[#view.sections + 1] = { kind = "rows", rows = ench, wrap = true, separator = { rule = true } }
    end

    if #model.requirements > 0 or #model.restrictions > 0 or model.levelReq or model.skill then
        local rows = {}
        if model.levelReq then rows[#rows + 1] = { left = model.levelReq.text, color = model.levelReq.unmet and LOOK.UNUSABLE or LOOK.TEXT } end
        if model.skill then rows[#rows + 1] = { left = model.skill.text, color = model.skill.unmet and LOOK.UNUSABLE or LOOK.TEXT } end
        for _, r in ipairs(model.requirements) do rows[#rows + 1] = { left = r.left, color = r.unmet and LOOK.UNUSABLE or LOOK.TEXT } end
        for _, r in ipairs(model.restrictions) do rows[#rows + 1] = { left = r.text, color = r.unmet and LOOK.UNUSABLE or LOOK.TEXT } end
        view.sections[#view.sections + 1] = { kind = "rows", rows = rows, wrap = true, separator = { rule = true } }
    end

    local effects = EffectRows(model, numberHex)
    if #effects > 0 then
        view.sections[#view.sections + 1] = { kind = "rows", rows = effects, wrap = true, separator = { rule = true } }
    end

    if model.reagents and #model.reagents > 0 then
        local rows = {}
        for _, r in ipairs(model.reagents) do
            local left = r.icon and ("|T%s:14|t "):format(r.icon) .. r.name or r.name
            local have = r.have
            local right = have and ("%d / %d"):format(have, r.count) or ("×%d"):format(r.count)
            rows[#rows + 1] = { left = left, right = right,
                color = (have and have >= r.count) and LOOK.EFFECT or LOOK.TEXT }
        end
        view.sections[#view.sections + 1] = { separator = { rule = true }, kind = "rows", rows = rows, wrap = true }
    end

    if model.set then
        local set = model.set
        local rows = {}
        rows[#rows + 1] = { left = set.name, color = LOOK.SET_NAME }
        if set.owned and set.total then
            rows[#rows].right = ("%d/%d"):format(set.owned, set.total)
        end
        for _, item in ipairs(set.items) do
            rows[#rows + 1] = { left = item.text, color = item.owned and LOOK.TEXT or LOOK.DIM, indent = 8 }
        end
        for _, bonus in ipairs(set.bonuses) do
            rows[#rows + 1] = { left = bonus.text, color = bonus.active and LOOK.EFFECT or LOOK.DIM, indent = 8 }
        end
        view.sections[#view.sections + 1] = { kind = "rows", rows = rows, wrap = true, separator = { rule = true } }
    end

    if #model.details > 0 then
        view.sections[#view.sections + 1] = { kind = "rows", rows = model.details, wrap = true,
            separator = { rule = true } }
    end

    local price = PriceRow(model)
    if price then
        view.sections[#view.sections + 1] = { kind = "rows", rows = { price }, separator = { rule = true } }
    end

    if model.created then
        local sub = Panel.ViewItem(model.created)
        view.sections[#view.sections + 1] = { separator = { rule = true }, kind = "rows",
            rows = { { left = model.created.name, color = QualityColor(model.created.nameColor) } } }
        for _, s in ipairs(sub.sections) do view.sections[#view.sections + 1] = s end
    end

    if #model.extras > 0 then
        view.sections[#view.sections + 1] = { kind = "rows", rows = model.extras, wrap = true,
            separator = { rule = true }, color = LOOK.SECONDARY }
    end
    view.extras = { rows = model.appended or {} }
    return view
end

Panel.views = Panel.views or {}
Panel.views.item = Panel.ViewItem
