------------------------------------------------------------
-- 單位 view：model（ReadUnit.lua）→ view 表（Render.lua 畫）
-- （逐字對照 MiliUI_Tooltip/Panel/ViewUnit.lua；僅 ns 宣告與 MEDIA 路徑改成 ADE）
--
--   左欄：頭像（SetPortraitTexture，方形）＋ 底下的等級徽章
--   標題：名字（大一號，職業色／立場色；頭銜、跨服、好友／職責小圖示）
--         <公會> 階級 ／ NPC 的 <頭銜>／ 種族 專精 職業 ／ 生物類型
--         狀態徽章：精英 · PvP · 暫離 · 死亡 · 可剝皮…
--   ◆ 細節：目標、主人、誰在打他、坐騎、裝等、傳奇鑰石評分、成就點數、區域、移動速度
--   ─ 其他：認不出用途的暴雪行
--   ◆ 任務：標題金、目標縮排
--   附屬框：別人後加的行
--   浮水印（panel.unitWatermark）：玩家陣營徽記、精英／稀有／首領的龍，裁在面板內
--
-- 身分受限的單位（facts.restricted）：名字與暴雪的其餘 None 行是秘密字串 ⇒ 標題區改秘密行。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local L = ns.L
local Panel = ns.Panel
local LOOK = Panel.LOOK

Panel.views = Panel.views or {}

local floor = math.floor

local function Hex(c)
    return ("%02x%02x%02x"):format(floor(c[1] * 255 + 0.5), floor(c[2] * 255 + 0.5), floor(c[3] * 255 + 0.5))
end
local function Paint(text, c) return "|cff" .. Hex(c) .. text .. "|r" end
local function Lighten(c, t) return { c[1] + (1 - c[1]) * t, c[2] + (1 - c[2]) * t, c[3] + (1 - c[3]) * t } end

------------------------------------------------------------
-- 狀態徽章的色
------------------------------------------------------------
local BADGE = {
    elite = { 1, 0.82, 0.30 },
    rare = { 0.72, 0.80, 0.96 },
    boss = { 1, 0.36, 0.26 },
    pvp = { 1, 0.45, 0.35 },
    status = LOOK.SECONDARY,
    dead = { 0.6, 0.6, 0.6 },
    skin = { 0.82, 0.64, 0.44 },
}
local QUEST_TITLE = { 1, 0.82, 0 }

local function ClassifBadge(classif)
    if classif == "boss" then return { _G.BOSS or "Boss", BADGE.boss } end
    if classif == "rareelite" then return { _G.MAP_LEGEND_RAREELITE or "Rare Elite", BADGE.rare } end
    if classif == "rare" then return { _G.MAP_LEGEND_RARE or "Rare", BADGE.rare } end
    if classif == "elite" then return { _G.ELITE or "Elite", BADGE.elite } end
end

------------------------------------------------------------
-- 標題區
------------------------------------------------------------
local function NameText(f)
    local text = f.name
    if f.realm then
        text = text .. Paint("-" .. f.realm, LOOK.SECONDARY)
    end
    if f.title then
        if f.titlePrefix then
            text = Paint(f.title, LOOK.SECONDARY) .. " " .. text
        else
            text = text .. " " .. Paint(f.title, LOOK.SECONDARY)
        end
    end
    local icons = (f.friendIcon or "") .. (f.roleIcon or "")
    if icons ~= "" then text = text .. " " .. icons end
    return text
end

local function InfoText(f, model)
    local parts = {}
    if f.isPlayer then
        if f.race then parts[#parts + 1] = f.race end
        if f.className then parts[#parts + 1] = model.specLine or f.className end
        if f.gender then parts[#parts + 1] = f.gender end
    elseif f.creature and f.creature ~= "" then
        parts[#parts + 1] = f.creature
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ")
end

local function Badges(f, model)
    local list = {}
    local function add(text, color) if text and text ~= "" then list[#list + 1] = { text, color } end end
    local c = ClassifBadge(f.classif)
    if c then list[#list + 1] = c end
    if f.factionName then add(f.factionName, f.factionColor or LOOK.SECONDARY) end
    if f.playerTag then add(f.playerTag, LOOK.SECONDARY) end
    if f.pvp then add(_G.PVP or "PvP", BADGE.pvp) end
    if f.reactionName then add(f.reactionName, LOOK.SECONDARY) end
    if f.afk then add(_G.AFK or "AFK", BADGE.status) end
    if f.dnd then add(_G.DND or "DND", BADGE.status) end
    if f.dc then add(_G.FRIENDS_LIST_OFFLINE or "Offline", BADGE.status) end
    if f.dead then add(_G.DEAD or "Dead", BADGE.dead) end
    for _, text in ipairs(model.skin or {}) do add(text, BADGE.skin) end
    return list
end

------------------------------------------------------------
-- 細節：目標列（名字可能是秘密值 ⇒ 自訂段落，不量、不讀，直接交給 SetText）
------------------------------------------------------------
local function TargetSection(target)
    local label = _G.STATUS_TEXT_TARGET or "Target"
    local value, color
    if target.you then
        value, color = ">> " .. (_G.YOU or "You") .. " <<", LOOK.UNUSABLE
    elseif not target.secret then
        value, color = target.name, target.color or LOOK.TEXT
    end
    local section = { kind = "custom" }
    section.measure = function(_, ctx)
        local st, m = ctx.styles.body, ctx.m
        local w = Panel.Measure(label, st) + m.columnGap + (value and (Panel.Measure(value, st) + 2) or 0)
        return w + 2 * m.pad
    end
    section.draw = function(panel, y, ctx)
        local st, m = ctx.styles.body, ctx.m
        local inner = panel.width - 2 * m.pad
        local lw = Panel.Measure(label, st) + 2
        local h = Panel.TextAt(panel, ctx, label, m.pad, y, lw, st, LOOK.DETAIL)
        local rw = inner - lw - m.columnGap
        local x = panel.width - m.pad - rw
        if value then
            h = math.max(h, Panel.TextAt(panel, ctx, value, x, y, rw, st, color, "RIGHT"))
        else
            local fs = Panel.SecretText(panel, st)
            fs:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
            fs:SetWidth(rw)
            fs:SetJustifyH("RIGHT")
            fs:SetTextColor(color and color[1] or 1, color and color[2] or 1, color and color[3] or 1)
            local state = ctx.state
            local name = state and state.panelUnit and ns.Secret.SafeCall(UnitName, state.panelUnit .. "target")
            fs:SetText(name or "")
            if state then state.panelTargetFS = fs end
            h = math.max(h, st.size + 2)
        end
        return y + h + m.rowGap
    end
    return section
end

local function SecretRowsSection(rows, prefix)
    local section = { kind = "custom" }
    section.measure = function() return 0 end
    section.draw = function(panel, y, ctx)
        local st, m = ctx.styles.body, ctx.m
        for i, row in ipairs(rows) do
            local indent = m.sc(row.indent or 0)
            local h = Panel.SecretLine(panel, ctx, { value = row.value, slot = prefix .. i, color = row.color },
                m.pad + indent, y, panel.width - 2 * m.pad - indent, st)
            y = y + h + m.rowGap
        end
        return y
    end
    return section
end

local function Label(text, value) return { left = text, right = value, color = LOOK.DETAIL } end

local function DetailRows(f, model)
    local rows = {}
    if model.owner then rows[#rows + 1] = { left = model.owner, color = LOOK.DETAIL } end
    local by = f.targetedBy
    if by then
        local value
        if by.names and #by.names > 0 then
            local names = {}
            for i, n in ipairs(by.names) do names[i] = n.color and Paint(n.name, n.color) or n.name end
            value = table.concat(names, L[", "])
        else
            value = Paint(tostring(by.count), { 0.2, 1, 1 })
        end
        rows[#rows + 1] = Label(by.self and L["Targeting you"] or L["Targeted by"], value)
    end
    if f.mount then
        local value = f.mount
        if f.mountCollected == true then
            value = value .. " " .. Paint(L["collected"], LOOK.EFFECT)
        elseif f.mountCollected == false then
            value = value .. " " .. Paint(L["uncollected"], LOOK.DIM)
        end
        rows[#rows + 1] = Label(L["Mount"], value)
    end
    if f.itemLevel ~= nil then
        local v = f.itemLevel
        rows[#rows + 1] = Label(L["ItemLevel"], type(v) == "number" and Paint(("%." .. (f.itemLevelDecimals or 2) .. "f"):format(v), f.itemLevelColor or LOOK.TEXT)
            or Paint(L["unknown"], LOOK.DIM))
    end
    if f.mplus then
        rows[#rows + 1] = Label(L["Mythic+ Score"], Paint(tostring(f.mplus), f.mplusColor or LOOK.TEXT) ..
            ((f.mplusBest and f.mplusBest ~= "") and Paint(f.mplusBest, LOOK.SECONDARY) or ""))
    end
    if f.achievement ~= nil then
        local v = f.achievement
        rows[#rows + 1] = Label(L["Achievement"], type(v) == "number" and Paint(tostring(v), f.achievementColor or LOOK.TEXT)
            or Paint(L["unknown"], LOOK.DIM))
    end
    local zone = f.zone or model.zone
    if zone then rows[#rows + 1] = Label(_G.ZONE or "Zone", zone) end
    if f.speed then rows[#rows + 1] = Label(_G.STAT_MOVEMENT_SPEED or "Speed", ("%d%%"):format(f.speed)) end
    return rows
end

------------------------------------------------------------
-- 浮水印：面板右上角、固定大小、裁在面板內
------------------------------------------------------------
local MEDIA = "Interface\\AddOns\\adeTooltip\\Media\\"
local FACTION_ART = {
    Alliance = { file = MEDIA .. "faction-alliance.png", color = { 0.40, 0.60, 1 } },
    Horde = { file = MEDIA .. "faction-horde.png", color = { 0.90, 0.25, 0.20 } },
}
local FACTION_SIZE, FACTION_RIGHT, FACTION_TOP, FACTION_ALPHA = 200, -44, -24, 0.12
local DRAGONS = {
    elite = { file = MEDIA .. "dragon-elite.png", color = BADGE.elite },
    boss = { file = MEDIA .. "dragon-boss.png", color = BADGE.elite },
    rare = { file = MEDIA .. "dragon-rare.png", color = BADGE.rare },
    rareelite = { file = MEDIA .. "dragon-rareelite.png", color = BADGE.rare },
}
local DRAGON_SIZE, DRAGON_MIN, DRAGON_RIGHT, DRAGON_MARGIN, DRAGON_CUT, DRAGON_ALPHA = 150, 100, -12, 6, 0.05, 0.30

local function DrawWatermark(panel, ctx, art)
    local m = ctx.m
    local inset = m.px
    local W, H = panel.width, panel.height
    local w, h = m.sc(art.width), m.sc(art.height)
    local top
    if art.fit then
        local fitH = H - 2 * m.sc(art.fit)
        local fh = math.max(m.sc(art.fitMin or 0), math.min(h, fitH))
        w, h = w * fh / h, fh
        top = fh <= fitH and m.sc(art.fit) or -h * (art.fitCut or 0)
    else
        top = m.sc(art.top)
    end
    local left = W - w - m.sc(art.right)
    local x0, x1 = math.max(left, inset), math.min(left + w, W - inset)
    local y0, y1 = math.max(top, inset), math.min(top + h, H - inset)
    if x1 <= x0 or y1 <= y0 then return end
    local u0, u1, v0, v1 = art.coords[1], art.coords[2], art.coords[3], art.coords[4]
    local function u(x) return u0 + (u1 - u0) * (x - left) / w end
    local function v(y) return v0 + (v1 - v0) * (y - top) / h end
    local tex = Panel.Texture(panel, -4)
    tex:SetTexture(art.file)
    tex:SetTexCoord(u(x0), u(x1), v(y0), v(y1))
    tex:SetPoint("TOPLEFT", panel, "TOPLEFT", x0, -y0)
    tex:SetSize(x1 - x0, y1 - y0)
    local c = art.color
    tex:SetVertexColor(c[1], c[2], c[3], art.alpha)
end

local function Watermark(f)
    if not Panel.Option("unitWatermark") then return nil end
    local art
    if f.isPlayer then
        local fa = FACTION_ART[f.factionGroup]
        if fa then
            art = { file = fa.file, coords = { 0, 1, 0, 1 }, width = FACTION_SIZE, height = FACTION_SIZE,
                right = FACTION_RIGHT, top = FACTION_TOP, color = fa.color, alpha = FACTION_ALPHA }
        end
    else
        local key = f.classif
        if not key then
            local c = f.classifPlain
            key = (c == "worldboss" and "boss") or (c == "rareelite" and "rareelite") or (c == "rare" and "rare")
                or (c == "elite" and "elite") or nil
        end
        local d = key and DRAGONS[key]
        if d then
            art = { file = d.file, coords = { 0, 1, 0, 1 }, width = DRAGON_SIZE, height = DRAGON_SIZE,
                right = DRAGON_RIGHT, fit = DRAGON_MARGIN, fitMin = DRAGON_MIN, fitCut = DRAGON_CUT,
                color = d.color, alpha = DRAGON_ALPHA }
            if f.gray then art.color = BADGE.dead end
        end
    end
    if not art or not art.file then return nil end
    return function(panel, ctx) DrawWatermark(panel, ctx, art) end
end

------------------------------------------------------------
-- view
------------------------------------------------------------
local PORTRAIT_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"

function Panel.ViewUnit(model)
    local f = model.facts
    local color = f.color or LOOK.TEXT
    local gap = LOOK.UNIT_HEADER_GAP

    local header
    if f.restricted then
        header = { { secret = true, value = f.name, slot = "name", style = "name", color = color, gap = gap } }
        for i, line in ipairs(model.secretHeader or {}) do
            header[#header + 1] = { secret = true, value = line.value, slot = "info" .. i, style = "body",
                color = LOOK.DETAIL, gap = gap }
        end
    else
        header = { { text = NameText(f), style = "name", color = color, gap = gap } }
        if f.guild then
            local text = "<" .. f.guild .. ">"
            if f.guildRank then text = text .. " " .. Paint(f.guildRank, LOOK.SECONDARY) end
            header[#header + 1] = { text = text, style = "body", color = Lighten(color, 0.5), gap = gap }
        elseif model.npcTitle then
            header[#header + 1] = { text = model.npcTitle, style = "body", color = Lighten(color, 0.5), gap = gap }
        end
        local info = InfoText(f, model)
        if info then header[#header + 1] = { text = info, style = "body", color = LOOK.DETAIL, gap = gap } end
    end
    local badges = Badges(f, model)
    if #badges > 0 then header[#header + 1] = { badges = badges, style = "body", gap = gap } end

    local sections = {}
    local function first() return #sections == 0 end
    local details = DetailRows(f, model)
    if f.target then
        sections[#sections + 1] = TargetSection(f.target)
        sections[#sections].separator = { divider = true }
    end
    if #details > 0 then
        sections[#sections + 1] = { separator = first() and { divider = true } or nil, kind = "rows", rows = details,
            color = LOOK.DETAIL, wrap = true }
    end
    if #model.others > 0 then
        sections[#sections + 1] = { separator = first() and { divider = true } or { rule = true }, kind = "rows",
            rows = model.others, color = LOOK.DETAIL, wrap = true }
    end
    local secretOthers = model.secretOthers or {}
    if #secretOthers > 0 then
        local rows = {}
        for i, r in ipairs(secretOthers) do rows[i] = { value = r.value, color = LOOK.DETAIL } end
        local s = SecretRowsSection(rows, "other")
        s.separator = first() and { divider = true } or { rule = true }
        sections[#sections + 1] = s
    end
    local secretQuests = model.secretQuests or {}
    if #secretQuests > 0 then
        local rows = {}
        for i, q in ipairs(secretQuests) do
            rows[i] = q.title and { value = q.value, color = QUEST_TITLE } or { value = q.value, color = LOOK.DETAIL, indent = 8 }
        end
        local s = SecretRowsSection(rows, "quest")
        s.separator = { divider = true }
        sections[#sections + 1] = s
    end
    if #model.quests > 0 then
        local rows = {}
        for i, q in ipairs(model.quests) do
            rows[i] = q.title and { left = q.left, right = q.right, color = QUEST_TITLE, rightColor = QUEST_TITLE }
                or { left = q.left, right = q.right, color = q.color or LOOK.DETAIL, rightColor = q.rightColor, indent = 8 }
        end
        sections[#sections + 1] = { separator = { divider = true }, kind = "rows", rows = rows, wrap = true }
    end

    local level = f.level
    local plate = f.levelColor or LOOK.TEXT
    return {
        portrait = model.unit, portraitKey = model.guid,
        icon = model.icon or PORTRAIT_FALLBACK, iconSize = LOOK.ICON_UNIT,
        desaturate = f.gray or f.tapped or nil,
        badge = level and (level == -1 and "??" or tostring(level)) or nil,
        badgeBelow = true,
        badgeTint = level and plate or nil,
        header = header,
        sections = sections,
        extras = { rows = model.extras },
        minWidth = LOOK.UNIT_MIN_W,
        secretHint = f.restricted or nil,
        decorate = Watermark(f),
    }
end
Panel.views.unit = Panel.ViewUnit
