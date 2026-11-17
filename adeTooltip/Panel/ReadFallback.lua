------------------------------------------------------------
-- 讀行（所有 reader 共用）＋ 最簡 reader／view（型別不認得時的退路，永遠不會「少行」）
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Panel = ns.Panel or {}
ns.Panel = Panel
local Patterns = ns.Patterns
local LOOK = Panel.LOOK

local LT = Enum and Enum.TooltipDataLineType or {}

local function PlainColor(c)
    if c == nil then return nil end
    if S.IsSecret(c) or type(c) ~= "table" then return false end
    local r, g, b = c.r, c.g, c.b
    if S.IsSecret(r) or S.IsSecret(g) or S.IsSecret(b) then return false end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
    return { r, g, b }
end

local function PlainString(v)
    if v == nil then return nil end
    if S.IsSecret(v) then return false end
    if type(v) ~= "string" then return nil end
    return v
end

local function FontColor(fs)
    local ok, r, g, b = pcall(fs.GetTextColor, fs)
    if not ok then return nil end
    if S.IsSecret(r) or S.IsSecret(g) or S.IsSecret(b) then return false end
    if type(r) ~= "number" then return nil end
    return { r, g, b }
end

local function Shown(fs)
    local ok, v = pcall(fs.IsShown, fs)
    if not ok or S.IsSecret(v) then return nil end
    return v and true or false
end

local EXTRA_FIELDS = { "tooltipID", "tooltipType", "usable", "gemIcon", "socketType", "price" }

function Panel.CollectLines(tip, data)
    if type(data) ~= "table" or S.IsSecret(data) then return end
    local lines = data.lines
    if type(lines) ~= "table" or S.IsSecret(lines) then return end
    local okName, name = pcall(tip.GetName, tip)
    name = okName and S.PlainText(name)
    if not name then return end

    local rows, covered = {}, {}
    local rightSeen = {}
    for _, line in ipairs(lines) do
        if type(line) ~= "table" or S.IsSecret(line) then return end
        local left, right = PlainString(line.leftText), PlainString(line.rightText)
        local lineType, index = line.type, line.lineIndex
        if left == false or right == false or S.IsSecret(lineType) or S.IsSecret(index) then return end
        local lc, rc = PlainColor(line.leftColor), PlainColor(line.rightColor)
        if lc == false or rc == false then return end
        local wrap = line.wrapText
        if S.IsSecret(wrap) then return end
        if type(index) == "number" then covered[index] = true end
        local row = {
            left = left or "", right = (right and right ~= "") and right or nil,
            color = lc, rightColor = rc, type = lineType, lineIndex = index, wrap = wrap == true,
        }
        for _, field in ipairs(EXTRA_FIELDS) do
            local v = line[field]
            if S.IsSecret(v) then return end
            local t = type(v)
            if t == "number" or t == "string" or t == "boolean" then row[field] = v end
        end
        if row.right and type(index) == "number" then rightSeen[index] = true end
        if not row.right and type(index) == "number" and not rightSeen[index] then
            local rf = _G[name .. "TextRight" .. index]
            if rf and Shown(rf) then
                local ok, text = pcall(rf.GetText, rf)
                if not ok then return end
                local plain = PlainString(text)
                if plain == false then return end
                if plain and plain ~= "" then
                    local rcolor = FontColor(rf)
                    if rcolor == false then return end
                    row.right, row.rightColor = plain, row.rightColor or rcolor
                    rightSeen[index] = true
                end
            end
        end
        rows[#rows + 1] = row
    end

    local n = Panel.CollectAppended(tip, name, covered, rows)
    if not n then return end
    return rows, n
end

function Panel.CollectAppended(tip, name, covered, rows, lenient)
    local okN, n = pcall(tip.NumLines, tip)
    n = okN and S.PlainNumber(n)
    if not n then return end
    for i = 1, n do
        if not covered[i] then
            local lf, rf = _G[name .. "TextLeft" .. i], _G[name .. "TextRight" .. i]
            local left, right, lc, rc
            local skip = false
            if lf and Shown(lf) ~= false then
                local ok, text = pcall(lf.GetText, lf)
                if not ok then return end
                left = PlainString(text)
                if left ~= false then lc = FontColor(lf) end
                if left == false or lc == false then
                    if not lenient then return end
                    skip = true
                end
            end
            if not skip and rf and Shown(rf) then
                local ok, text = pcall(rf.GetText, rf)
                if not ok then return end
                right = PlainString(text)
                if right ~= false then rc = FontColor(rf) end
                if right == false or rc == false then
                    if not lenient then return end
                    skip = true
                end
            end
            if not skip and ((left and left ~= "") or (right and right ~= "")) then
                rows[#rows + 1] = {
                    left = left or "", right = (right and right ~= "") and right or nil,
                    color = lc, rightColor = rc, lineIndex = i, appended = true, wrap = true,
                }
            end
        end
    end
    return n
end

function Panel.CompareHeaderText(tip)
    local header = tip and tip.CompareHeader
    if type(header) ~= "table" or not header.IsShown or S.IsForbiddenObject(header) then return nil end
    local ok, shown = pcall(header.IsShown, header)
    if not ok or S.IsSecret(shown) or not shown then return nil end
    local label = header.Label
    if type(label) == "table" and label.GetText then
        local okT, text = pcall(label.GetText, label)
        text = okT and S.PlainText(text)
        if text and text ~= "" then return text end
    end
    return _G.EQUIPPED
end

function Panel.Coins(copper)
    copper = S.PlainNumber(copper)
    if not copper then return end
    local fn = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or _G.GetCoinTextureString
    if not fn then return end
    local ok, text = pcall(fn, copper)
    return ok and S.PlainText(text) or nil
end

local function IsBreak(row)
    if row.type ~= nil and (row.type == LT.Blank or row.type == LT.Separator) then return true end
    local plain = Patterns.StripColors(row.left or "")
    return (plain == "" or plain:match("^%s+$") ~= nil) and not row.right
end

function Panel.ReadFallback(tip, data, kind, rows, n)
    if not rows then rows, n = Panel.CollectLines(tip, data) end
    if not rows then return end
    local model = { kind = kind, groups = {}, extras = {}, numLines = n, rows = rows }

    local first
    local group = {}
    for _, row in ipairs(rows) do
        if not first and not row.appended and not IsBreak(row)
            and not (_G.CURRENTLY_EQUIPPED and row.left == _G.CURRENTLY_EQUIPPED) then
            first = row
        elseif row.appended then
            if not IsBreak(row) then model.extras[#model.extras + 1] = row end
        elseif IsBreak(row) then
            if #group > 0 then model.groups[#model.groups + 1] = group; group = {} end
        elseif not (_G.CURRENTLY_EQUIPPED and row.left == _G.CURRENTLY_EQUIPPED) then
            if row.price then
                local coins = Panel.Coins(row.price)
                if coins then row = { left = row.left, right = coins, color = row.color } end
            end
            group[#group + 1] = row
        end
    end
    if #group > 0 then model.groups[#model.groups + 1] = group end
    if not first then return end

    local name = Patterns.StripTextures(first.left or "")
    if name == "" then return end
    model.name = name
    model.nameColor = first.color
    model.subtitle = first.right

    local id = S.PlainNumber(data.id)
    if id then
        if kind == "item" and C_Item and C_Item.GetItemIconByID then
            local ok, icon = pcall(C_Item.GetItemIconByID, id)
            model.icon = ok and S.PlainNumber(icon) or nil
        elseif kind == "spell" and C_Spell and C_Spell.GetSpellTexture then
            local ok, icon = pcall(C_Spell.GetSpellTexture, id)
            model.icon = ok and S.PlainNumber(icon) or nil
        end
    end

    model.compareHeader = Panel.CompareHeaderText(tip)
    return model
end

function Panel.ViewFallback(model)
    local view = {
        icon = model.icon,
        iconSize = model.kind == "spell" and LOOK.ICON_SPELL or LOOK.ICON_ITEM,
        header = { { text = model.name, style = "title", color = model.nameColor or LOOK.TEXT } },
        sections = {},
        tag = model.compareHeader,
    }
    if model.subtitle then view.header[2] = { badges = { { model.subtitle } }, style = "small" } end
    for i, group in ipairs(model.groups) do
        view.sections[#view.sections + 1] = {
            separator = (i > 1) and { rule = true } or nil,
            kind = "rows", rows = group, wrap = true, color = LOOK.TEXT,
        }
    end
    view.extras = { rows = model.extras }
    return view
end
