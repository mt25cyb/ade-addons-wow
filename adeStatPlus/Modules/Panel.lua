--[==[ 信息面板（F1 / D36 / D53–D57）
    锚点模型严格对齐 StatSsul（StatSsul.lua:45-56,60-73,188-205）：
      25×25 固定容器 + 唯一 ▼/▲ 按钮（唯一拖动手柄）；内容帧锚在容器下方，
      按钮不在背景/边框内；折叠只 Hide 内容帧，按钮屏幕位置恒定。

    数值显示风格（D53，用户 2026-11-09 定稿）：
      · 安全间距 SAFE_GAP = 4，用于列间、文本与背景、宽度自适应追加。
      · segmented=false（默认，不分段）：单串 `<名称>: <数据>`，
        面板宽度 = 最宽文本实际宽度 + 安全间距 + 两侧内边距；
        专属「文本对齐」joinedAlign（LEFT 默认 / CENTER / RIGHT）。
      · segmented=true（分段）：左 `<名称>` 列（宽 = 最宽名称实宽 + 安全间距）、
        右 `<数据>` 列；名称列 nameAlign（RIGHT 默认）、数据列 dataAlign（LEFT 默认）。
        数据列可拆第一组 / 第二组，仅「数值+百分比」「百分比+数值」才有第二组，
        连接符 ` | `。左对齐时完整串靠左；右对齐时只第一组右对齐，第二组连带
        连接符跟在第一组右侧（用两个 FontString 实现）。
      · 副属性 / 第三属性可分别选 VALUE / PERCENT / VALUE_PERCENT / PERCENT_VALUE。
      · 宽度用隐藏测量 FontString 的 GetStringWidth() 实测，不用臆造字符宽估算。
    主属性按专精只显示一个（D58），耐力不受限；自动隐藏（D55）见 ShouldAutoHide。
    secret 纪律：secret 通道原值直通 FontString:SetText，绝不 format / 算术 / 比较。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local Panel = {}
ns.Panel = Panel

-- ADE v6.5：字体走原生 Media 表，不再依赖 LibSharedMedia
local Media = ns.Media

local BTN_SIZE = 25
local SAFE_GAP = 4            -- 用户定稿安全间距
local PAD = SAFE_GAP          -- 背景/边框与内容的安全间距
local MIN_PANEL_W = 120
local HEADER_H = 20

-- D68：文本行高跟随字号（默认字号 13 → 18，与旧固定值一致）。
-- embedded 进度条铺满文本行，故条高度随之联动。
local function RowH()
    return ns.db.profile.font.size + 5
end

local anchor, content, toggleBtn, btnTex, measureFS
local SetArrow           -- 前向声明：根据折叠态/高亮更新三角 atlas（D74）
local rows = {}
local headerPool = {}
local activeRows = 0
local activeHeaders = 0
local BuildEntriesWithText, MakeRowEntry, Measure   -- 前向声明

local function L(key) return ns.L[key] end

local function FontFlags()
    local outline = ns.db.profile.font.outline
    if outline == "THICKOUTLINE" then return "THICKOUTLINE" end
    if outline == "NONE" then return "" end
    return "OUTLINE"
end

local function ApplyFont(fs, extraSize)
    local f = ns.db.profile.font
    fs:SetFont(Media.FontPath(f.face), f.size + (extraSize or 0), FontFlags())
end

-- D88：耐久度按比例自动着色（参考 DejaCharacterStats 单件耐久度配色：>66% 绿 / >33% 黄 / 否则红）
local function DurabilityRGB(pct)
    if pct > 66 then return { r = 0, g = 1, b = 0 }
    elseif pct > 33 then return { r = 1, g = 1, b = 0 }
    else return { r = 1, g = 0, b = 0 } end
end

-- D88：平均装备品质 → ITEM_QUALITY_COLORS（同步原生角色面板装等颜色）
local function EquipmentQualityRGB()
    local total, n = 0, 0
    for slot = 1, 19 do
        local quality = GetInventoryItemQuality("player", slot)
        if quality and quality >= 0 then total = total + quality; n = n + 1 end
    end
    if n == 0 then return nil end
    local c = ITEM_QUALITY_COLORS[math.floor(total / n + 0.5)]
    if c then return { r = c.r, g = c.g, b = c.b } end
    return nil
end

local function RowColor(key, def)
    local p = ns.db.profile
    -- D88：按装备品质着色装等（优先于自定义颜色）
    if key == "ilvl" and p.panel.colorIlvlByQuality then
        local c = EquipmentQualityRGB()
        if c then return c end
    end
    -- D88：按比例自动着色耐久度（优先于自定义颜色）
    if key == "durability" and p.panel.autoColorDurability and def and def.read then
        local _, pct = def.read()
        if type(pct) == "number" then return DurabilityRGB(pct) end
    end
    -- D85：属性配置按组分流——others 组在 profile.others[key]，其余在 profile.stats[key]
    local statCfg = (def.group == "others") and p.others[key] or p.stats[key]
    if statCfg and statCfg.color then return statCfg.color end
    local group = p.groups[def.group]
    if group and group.color then return group.color end
    return def.color
end

--- 面板值：除物品等级外固定整数；ilvl 用独立小数位。仅在 valuePlain 时调用。
local function FormatPanelValue(key, value)
    if key == "ilvl" then
        return string.format("%." .. ns.db.profile.format.ilvlDecimals .. "f", value)
    end
    return string.format("%d", math.floor(value + 0.5))
end

local function FormatPercent(value)
    return string.format("%." .. ns.db.profile.format.percentDecimals .. "f%%", value)
end

-- D70：移速固定不带小数（不受 percentDecimals 影响）
local function FormatSpeedPercent(value)
    return string.format("%d%%", math.floor(value + 0.5))
end

local function FormatSplitPercent(def)
    local dmg, red = def.readSplit()
    if ns.Collector.IsSecret(dmg) or ns.Collector.IsSecret(red) then return nil end
    if dmg == nil or red == nil then return nil end
    local fmt = "%." .. ns.db.profile.format.percentDecimals .. "f%%"
    return string.format(fmt .. " / " .. fmt, dmg, red)
end

--- 通道文本：返回结构化 part = { text=string } 或 { secret=原值 }，无数据返回 nil。
--- 用 table 承载，使后续「是否有数据」的判断只比较 table，绝不比较 secret 值本身。
--- secret 时优先用上次已知值（Collector.lastValue/lastPercent，战斗外已确认的
--- plain number）渲染完整格式——旧 Stats 的战斗策略（用户 2026-11-18）；从未读到过
--- 才裸直通 secret 原值。
local function ChannelPart(value, isSecret, isPlain, lastKnown, formatter)
    if isSecret then
        if lastKnown ~= nil then
            return { text = formatter and formatter(lastKnown) or tostring(lastKnown) }
        end
        return { isSecret = true, secret = value }
    end
    if value == nil or not isPlain then return nil end
    return { text = formatter and formatter(value) or tostring(value) }
end

--[==[ 自动隐藏属性（D55）
    优先按「原生角色面板右侧栏当前实际渲染的属性行」判断
    （StatMarks/Bars.lua:2127-2149 的 statsFramePool:EnumerateActive + :208-215
      的本地化 Label 匹配，:60-73 说明 Blizzard 对 hideAt=0 的属性不建行）；
    角色面板未打开 / 池不可读时，回退到规则判断：
      · 防护：Stats/Stats.lua:651-662 IsTankSpec + :223-232 职业白名单；
              醉拳仅酒仙武僧 specID 268（StatDisplay/StatDisplay.lua:225-232,440-446）
      · 第三：Stats/Stats.lua:163 明确 Armor 不纳入；闪避/吸血按 rating 是否非 0
              （StatsPro/StatsPro.lua:4734-4755 shouldShow 的 val~=0 与 secret 缓存）
    一个开关 `panel.autoHideStats` 统一控制第三属性组与防护属性组（D61）。 ]==]
local TANK_DEFENSIVES = {
    DEATHKNIGHT = { parry = true },
    PALADIN     = { block = true, parry = true },
    DRUID       = { dodge = true },
    MONK        = { dodge = true },
    WARRIOR     = { block = true, parry = true },
    DEMONHUNTER = { parry = true },
}
local NATIVE_LABEL_GLOBALS = {
    strength = "STAT_STRENGTH", agility = "STAT_AGILITY",
    intellect = "STAT_INTELLECT", stamina = "STAT_STAMINA",
    crit = "STAT_CRITICAL_STRIKE", haste = "STAT_HASTE",
    mastery = "STAT_MASTERY", vers = "STAT_VERSATILITY",
    armor = "STAT_ARMOR", avoidance = "STAT_AVOIDANCE", leech = "STAT_LIFESTEAL",
    dodge = "STAT_DODGE", parry = "STAT_PARRY", block = "STAT_BLOCK",
    stagger = "STAT_STAGGER",
}
local zeroRatingCache = {}

local function NativeVisibleSet()
    local pane = _G.CharacterStatsPane
    -- statsFramePool 为 12.x 原生运行期字段（实证 StatMarks/Bars.lua:2127-2149），
    -- wowlua_ls 的 CharacterStatsPane stub 未收录
    ---@diagnostic disable-next-line: undefined-field
    local pool = pane and pane.statsFramePool
    if not (pool and pool.EnumerateActive) then return nil end
    local visible, count = {}, 0
    for row in pool:EnumerateActive() do
        if row:IsShown() and row.Label and row.Label.GetText then
            local label = row.Label:GetText()
            if type(label) == "string" and not ns.Collector.IsSecret(label) then
                for key, globalName in pairs(NATIVE_LABEL_GLOBALS) do
                    local name = _G[globalName]
                    if type(name) == "string" and label:find(name, 1, true) then
                        visible[key] = true
                        count = count + 1
                    end
                end
            end
        end
    end
    return count > 0 and visible or nil
end

local function IsTankSpec()
    local index = GetSpecialization()
    if not index then return false end
    local specID, _, _, _, role = GetSpecializationInfo(index)
    if role == "TANK" then return true end
    if specID then
        local _, _, _, _, byIDRole = GetSpecializationInfoByID(specID)
        if byIDRole == "TANK" then return true end
    end
    return false
end

local function FallbackVisible(key)
    if key == "armor" then return true end
    if key == "avoidance" or key == "leech" then
        local cr = (key == "avoidance") and CR_AVOIDANCE or CR_LIFESTEAL
        local rating = cr and GetCombatRating(cr) or nil
        -- secret 必须先判：12.x 中 secret 值连 `== nil` 比较都不允许；
        -- 战斗中沿用上次已知可见性（StatsPro/StatsPro.lua:4734-4755 同款缓存）
        if ns.Collector.IsSecret(rating) then
            return zeroRatingCache[key] ~= false
        end
        if rating == nil then return true end
        ---@diagnostic disable-next-line: secret-comparison
        local nonZero = rating ~= 0
        zeroRatingCache[key] = nonZero
        return nonZero
    end
    -- 防护属性
    local index = GetSpecialization()
    local specID = index and GetSpecializationInfo(index) or nil
    if key == "stagger" then return specID == 268 end
    if not IsTankSpec() then return false end
    local _, class = UnitClass("player")
    local allowed = TANK_DEFENSIVES[class]
    return allowed and allowed[key] == true
end

--- 是否应自动隐藏。返回 true 表示隐藏。
--- 三态判定：只有该属性对应的暴雪本地化 STAT_* 常量存在、且原生行集合可读取时，
--- 才以「原生角色面板是否建了这一行」为准；否则回退到专精/职业规则，
--- 避免本地化常量缺失导致所有属性被误判为「未显示」而全部隐藏。
local function ShouldAutoHide(key, group)
    local cfg = ns.db.profile.panel
    -- D61：一个开关统一控制；仅第三属性 / 防护属性组参与自动隐藏
    -- （主属性按专精只显示一个是独立规则 D58，副属性四绿始终显示）
    local enabled = cfg.autoHideStats
        and (group == "tertiary" or group == "defensive")
    if not enabled then return false end
    if type(_G[NATIVE_LABEL_GLOBALS[key]]) == "string" then
        local native = NativeVisibleSet()
        if native then return not native[key] end
    end
    return not FallbackVisible(key)
end

local function AcquireRow()
    activeRows = activeRows + 1
    local row = rows[activeRows]
    if row then return row end

    row = CreateFrame("Frame", nil, content)
    row:SetHeight(RowH())
    row:SetFrameLevel(content:GetFrameLevel() + 2)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.joined = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.dataA = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.dataB = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    for _, fs in ipairs({ row.name, row.joined, row.dataA, row.dataB }) do
        fs:SetWordWrap(false)
    end
    row.visual = ns.Bars.CreateRowBar(row)
    rows[activeRows] = row
    return row
end

local function AcquireHeader()
    activeHeaders = activeHeaders + 1
    local h = headerPool[activeHeaders]
    if h then return h end
    h = CreateFrame("Frame", nil, content)
    h:SetHeight(HEADER_H)
    h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h.text:SetAllPoints(h)
    h.text:SetJustifyH("CENTER")
    headerPool[activeHeaders] = h
    return h
end

local function GroupVisible(group)
    local g = ns.db.profile.groups[group]
    if group == "primary" or group == "secondary" then return true end
    return g.enabled
end

local function ItemEnabled(key, def)
    local cfg = (def.group == "others") and ns.db.profile.others[key] or ns.db.profile.stats[key]
    if cfg and cfg.enabled == false then return false end
    -- D79：满级时隐藏「等级」属性（默认启用，设置开关控制）
    -- D83：最大等级复用 Bars.lua 等级进度条口径 GetMaxLevelForExpansionLevel(GetServerExpansionLevel())，
    --       角色等级 == 最大等级即视为满级（等级不会超过 maxLevel，故用 >= 等价且更稳）
    if def.key == "level" and ns.db.profile.panel.hideLevelAtMax then
        local maxLevel = GetMaxLevelForExpansionLevel(GetServerExpansionLevel())
        if maxLevel and maxLevel > 0 and UnitLevel("player") >= maxLevel then
            return false
        end
    end
    return not ShouldAutoHide(key, def.group)
end

--- 主属性：力/敏/智按专精只显示一个，耐力不受限（D58）。
local function GroupOrder(group)
    local order = ns.db.profile.order
    if group == "primary" then
        local statID = ns.PrimaryStatIndex()
        local cur = (statID == 1 and "strength") or (statID == 2 and "agility")
            or (statID == 4 and "intellect") or nil
        local out = {}
        for _, key in ipairs(order.primary) do
            if key == "stamina" or key == cur then out[#out + 1] = key end
        end
        return out
    elseif group == "secondary" then
        if order.secondaryBySource then
            local priority = ns.Registry.Sources.GetPriority()
            if priority then return priority end
        end
        return order.secondary
    elseif group == "tertiary" then
        return order.tertiary
    elseif group == "defensive" then
        return order.defensive
    end
    return nil
end

--- 构建数据列的第一组 / 第二组 part（按用户 D53 定稿）。
--- 每个 part 为 { text=string } 或 { secret=原值 }；无数据为 nil。
---@return table|nil first
---@return table|nil second
local function BuildDataParts(key, def, entry)
    local fmt = ns.db.profile.format
    local valuePart = ChannelPart(entry.value, entry.valueSecret, entry.valuePlain,
        entry.lastValue, function(v) return FormatPanelValue(key, v) end)
    local percentPart = ChannelPart(entry.percent, entry.percentSecret, entry.percentPlain,
        entry.lastPercent, (key == "speed") and FormatSpeedPercent or FormatPercent)
    if fmt.versatility == "split" and key == "vers" and def.readSplit then
        local split = FormatSplitPercent(def)
        if split then percentPart = { text = split } end
    end
    -- 任一通道为 secret 时整行数据退化为单值直通（不能拼接、不能分两组）
    if (valuePart and valuePart.isSecret) or (percentPart and percentPart.isSecret) then
        local chosen = (valuePart and valuePart.isSecret) and valuePart or percentPart
        return chosen, nil
    end

    local group = def.group
    local mode
    if group == "secondary" then mode = fmt.secondaryParts
    elseif group == "tertiary" then mode = fmt.tertiaryParts
    else mode = "VALUE_PERCENT" end

    local first, second
    if mode == "VALUE" then
        first = valuePart
    elseif mode == "PERCENT" then
        first = percentPart
    elseif mode == "PERCENT_VALUE" then
        first, second = percentPart, valuePart
    else
        first, second = valuePart, percentPart
    end
    -- 非副/第三组按「有啥显示啥」压缩，避免出现空的第一组
    if group ~= "secondary" and group ~= "tertiary" then
        if first == nil and second ~= nil then first, second = second, nil end
    end
    if first == nil then first, second = second, nil end
    return first, second
end

--- 测量字符串实际宽度（隐藏 FontString，字体与面板一致）。
Measure = function(text)
    if type(text) ~= "string" then return 0 end
    measureFS:SetText(text)
    return measureFS:GetStringWidth()
end

local function ApplyBackground()
    local bg = ns.db.profile.panel.background
    if bg.enabled then
        content:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = bg.border and "Interface\\Buttons\\WHITE8X8" or nil,
            edgeSize = bg.border and 1 or 0,
        })
        local c = bg.color
        content:SetBackdropColor(c.r, c.g, c.b, c.a)
        if bg.border then content:SetBackdropBorderColor(0.55, 0.55, 0.60, 0.9) end
    else
        content:SetBackdrop(nil)
    end
end

local function ApplyPosition()
    local p = ns.db.profile.panel
    anchor:ClearAllPoints()
    anchor:SetPoint(p.point, UIParent, p.point, p.x, p.y)
    anchor:SetScale(p.scale)
end

local function ApplyCollapse()
    local collapsed = ns.db.profile.panel.collapsed
    content:SetShown(not collapsed)
    if SetArrow then SetArrow(collapsed, false) end
end

--- 全量刷新：先测量宽度，再布局（保证即时生效）。
function Panel.RefreshAll()
    if not anchor then return end
    local p = ns.db.profile
    local fmt = p.format
    ApplyPosition()
    ApplyBackground()
    ApplyCollapse()
    ApplyFont(measureFS)

    -- 第 1 遍：构建每行文本并测量（宽度按最宽的一组文本 + 安全间距）
    local entries = BuildEntriesWithText()
    local maxJoined, maxName, maxDataA, maxDataB = 0, 0, 0, 0
    for _, e in ipairs(entries) do
        if e.type == "row" then
            e.nameWidth = Measure(e.nameText)
            maxJoined = math.max(maxJoined, e.joinedWidth or 0)
            maxName = math.max(maxName, e.nameWidth)
            maxDataA = math.max(maxDataA, Measure(e.firstText or ""))
            maxDataB = math.max(maxDataB, Measure(e.secondText and (" | " .. e.secondText) or ""))
        end
    end

    local segmented = fmt.segmented
    local textW, nameW, dataW, firstW, secondW
    if not segmented then
        textW = math.max(MIN_PANEL_W, maxJoined + SAFE_GAP)
        nameW, dataW, firstW, secondW = 0, 0, 0, 0
    else
        nameW = math.max(20, maxName + SAFE_GAP)
        -- D63（手绘图）：第一组列宽是**全局固定**的（所有行第一组文本的最宽值 + 安全间距），
        -- 第二组列宽也是全局固定（含连接符 ` | `）。这样所有行的第一组右边界统一，
        -- 连接符与第二组左起点统一；不能按每行自己的第二组宽度反推 wA（会导致参差）。
        firstW = math.max(1, maxDataA + SAFE_GAP)
        secondW = maxDataB
        dataW = firstW + secondW
        textW = nameW + dataW
    end
    local contentW = textW + PAD * 2
    content:SetWidth(contentW)

    -- 第 2 遍：布局
    activeRows, activeHeaders = 0, 0
    local y = -PAD
    local thresholds = ns.Registry.Sources.GetThresholds()
    local showBar = p.bars.enabled
    local barStyle = p.bars.style
    local showThreshold = p.bars.showThreshold
    local rowH = RowH()           -- D68：本轮统一行高，字号变动即时生效

    for _, e in ipairs(entries) do
        if e.type == "header" then
            local h = AcquireHeader()
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            h:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, y)
            h.text:SetText(e.headerText)
            local gcolor = p.groups[e.group] and p.groups[e.group].color
            if gcolor then h.text:SetTextColor(ns.ColorRGB(gcolor))
            else h.text:SetTextColor(1, 0.82, 0) end
            ApplyFont(h.text)
            h:Show()
            y = y - HEADER_H
        else
            local row = AcquireRow()
            row:ClearAllPoints()
            row:SetHeight(rowH)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, y)
            local cr, cg, cb = ns.ColorRGB(RowColor(e.key, e.def))
            for _, fs in ipairs({ row.name, row.joined, row.dataA, row.dataB }) do
                ApplyFont(fs)
                fs:SetTextColor(cr, cg, cb)
                fs:ClearAllPoints()
                fs:SetText("")
            end

            if not segmented then
                row.name:SetShown(false)
                row.dataA:SetShown(false)
                row.dataB:SetShown(false)
                row.joined:SetShown(true)
                row.joined:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                row.joined:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
                row.joined:SetWidth(textW)
                row.joined:SetJustifyH(fmt.joinedAlign)
                if e.secretJoined ~= nil then
                    row.joined:SetText(e.secretJoined)
                else
                    row.joined:SetText(e.joinedText or "")
                end
            else
                row.joined:SetShown(false)
                row.name:SetShown(true)
                row.dataA:SetShown(true)
                row.dataB:SetShown(true)
                row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                row.name:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
                row.name:SetWidth(nameW)
                row.name:SetJustifyH(fmt.nameAlign)
                row.name:SetText(e.nameText or "")

                local first = e.firstText
                local second = e.secondText
                local hasSecond = type(second) == "string" and second ~= ""
                local rightAlign = (fmt.dataAlign == "RIGHT")
                local hasSecret = (e.hasSecret == true)
                -- D63（手绘图）：右对齐时 dataA 固定占 firstW（所有行第一组右边界统一），
                -- dataB 固定占 secondW、锚在 dataA 右侧（所有行第二组左起点统一），
                -- 内容连带连接符 ` | `。左对齐时完整数据单串靠左、dataA 占满 dataW。
                local wA = (rightAlign and not hasSecret) and firstW or dataW
                local wB = (rightAlign and not hasSecret) and secondW or 0
                row.dataA:SetPoint("TOPLEFT", row, "TOPLEFT", nameW, 0)
                row.dataA:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", nameW, 0)
                row.dataA:SetWidth(math.max(1, wA))
                row.dataB:SetPoint("TOPLEFT", row.dataA, "TOPRIGHT", 0, 0)
                row.dataB:SetPoint("BOTTOMLEFT", row.dataA, "BOTTOMRIGHT", 0, 0)
                row.dataB:SetWidth(math.max(1, wB))
                row.dataB:SetJustifyH("LEFT")

                if hasSecret then
                    row.dataA:SetJustifyH(rightAlign and "RIGHT" or "LEFT")
                    row.dataA:SetText(e.secretFirst)
                    row.dataB:SetText("")
                elseif rightAlign then
                    row.dataA:SetJustifyH("RIGHT")
                    row.dataA:SetText(first or "")
                    row.dataB:SetText(hasSecond and (" | " .. second) or "")
                else
                    row.dataA:SetJustifyH("LEFT")
                    row.dataA:SetText(hasSecond and ((first or "") .. " | " .. second) or (first or ""))
                    row.dataB:SetText("")
                end
            end

            if showBar then
                ns.Bars.ApplyStyle(row.visual, barStyle, rowH)
                ns.Bars.Update(row.visual, e.entry, thresholds and thresholds[e.key],
                    RowColor(e.key, e.def), showThreshold)
                ns.Bars.Show(row.visual)
                if barStyle == "separate" then
                    y = y - rowH - p.bars.height - 2
                else
                    y = y - rowH
                end
            else
                ns.Bars.Hide(row.visual)
                y = y - rowH
            end
            row:Show()
        end
    end

    for i = activeRows + 1, #rows do rows[i]:Hide() end
    for i = activeHeaders + 1, #headerPool do headerPool[i]:Hide() end
    content:SetHeight(-y + PAD)
end

--- 排序展开 + 文本构建（第 1 遍）。测量与 secret 直通在此分离。
BuildEntriesWithText = function()
    local p = ns.db.profile
    local out = {}
    local showGroups = p.panel.showGroupNames
    local abbr = p.abbr
    local segmented = p.format.segmented
    for _, key in ipairs(p.order.blocks) do
        local def = ns.StatDefs[key]
        if def then
            -- D84：others 组单项（level/ilvl/durability/speed）此前绕过 ItemEnabled
            -- 直接渲染，导致「满级隐藏等级」等判定对其失效；统一经 ItemEnabled 过滤。
            if ItemEnabled(key, def) then
                out[#out + 1] = MakeRowEntry(key, def, abbr, segmented)
            end
        elseif ns.GROUP_LABEL_KEYS[key] and GroupVisible(key) then
            -- D62：先收集可见成员；整组都被隐藏（自动隐藏或逐项关闭）时，
            -- 组名也一并隐藏，避免留下空标题。
            local visible = {}
            for _, member in ipairs(GroupOrder(key)) do
                local mdef = ns.StatDefs[member]
                if mdef and ItemEnabled(member, mdef) then
                    visible[#visible + 1] = MakeRowEntry(member, mdef, abbr, segmented)
                end
            end
            if #visible > 0 then
                if showGroups then
                    out[#out + 1] = { type = "header", group = key,
                                      headerText = L(ns.GROUP_LABEL_KEYS[key]) }
                end
                for i = 1, #visible do out[#out + 1] = visible[i] end
            end
        end
    end
    return out
end

--- 生成一行的数据与文本；secret 原值单独保存，绝不参与字符串拼接。
---@param first table|nil { text=string } 或 { secret=原值 }
---@param second table|nil
MakeRowEntry = function(key, def, abbr, segmented)
    local entry = ns.Collector.Read(key)
    if not entry then
        error(("adeStatPlus: no StatDefs entry for %q"):format(key))
    end
    local nameText = L(abbr and def.abbrKey or def.labelKey)
    local first, second = BuildDataParts(key, def, entry)
    local e = {
        type = "row", key = key, def = def, entry = entry,
        nameText = nameText,
    }
    -- 只用布尔标记判断，绝不对 secret 原值做 or / ~= nil 运算
    local firstSecretPart = (first ~= nil and first.isSecret == true) and first or nil
    local secondSecretPart = (second ~= nil and second.isSecret == true) and second or nil
    local secretPart = firstSecretPart or secondSecretPart
    if secretPart then
        e.hasSecret = true
        e.secretJoined = secretPart.secret
        e.secretFirst = secretPart.secret
        e.firstText = ""
        e.secondText = nil
        -- secret 值无法测量宽度，用同格式占位串估算（不臆造固定像素）
        e.joinedWidth = Measure(nameText .. ": " .. FormatPercent(0))
        return e
    end

    e.firstText = (first and first.text) or ""
    e.secondText = second and second.text or nil
    local dataText = e.firstText
    if e.secondText and e.secondText ~= "" then
        dataText = dataText .. " | " .. e.secondText
    end
    e.joinedText = nameText .. ": " .. dataText
    e.joinedWidth = Measure(e.joinedText)
    return e
end

function Panel.Toggle()
    ns.db.profile.panel.shown = not ns.db.profile.panel.shown
    anchor:SetShown(ns.db.profile.panel.shown)
end

function Panel.Init()
    anchor = CreateFrame("Frame", "adeStatPlusAnchor", UIParent)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:SetSize(BTN_SIZE, BTN_SIZE)
    anchor:SetFrameStrata("MEDIUM")

    toggleBtn = CreateFrame("Button", nil, anchor)
    toggleBtn:SetAllPoints()
    -- D74：用 atlas 纹理代替 ▼/▲ 文字（避免某些字体下乱码）。
    -- 实测 atlas（尺寸 32×32）：常态/高亮 × 上/下 共四枚。
    btnTex = toggleBtn:CreateTexture(nil, "OVERLAY")
    btnTex:SetSize(32, 32)
    btnTex:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)
    SetArrow = function(collapsed, hover)
        local dir = collapsed and "arrowDown" or "arrowUp"
        local hi = hover and "-hover" or ""
        btnTex:SetAtlas("glues-characterSelect-icon-" .. dir .. hi, false)
    end
    toggleBtn:RegisterForClicks("LeftButtonUp")
    toggleBtn:SetScript("OnClick", function()
        ns.db.profile.panel.collapsed = not ns.db.profile.panel.collapsed
        Panel.RefreshAll()
    end)
    toggleBtn:SetScript("OnEnter", function() SetArrow(ns.db.profile.panel.collapsed, true) end)
    toggleBtn:SetScript("OnLeave", function() SetArrow(ns.db.profile.panel.collapsed, false) end)
    toggleBtn:SetScript("OnMouseDown", function() SetArrow(ns.db.profile.panel.collapsed, true) end)
    toggleBtn:SetScript("OnMouseUp", function() SetArrow(ns.db.profile.panel.collapsed, false) end)
    toggleBtn:RegisterForDrag("LeftButton")
    toggleBtn:SetScript("OnDragStart", function()
        if not ns.db.profile.panel.locked then anchor:StartMoving() end
    end)
    toggleBtn:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        local point, _, _, x, y = anchor:GetPoint()
        local cfg = ns.db.profile.panel
        cfg.point, cfg.x, cfg.y = point, x, y
    end)

    content = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    -- D72：数据面板左上角直接锚到三角按钮左下角，坐标 0,4
    content:SetPoint("TOPLEFT", toggleBtn, "BOTTOMLEFT", 0, 4)
    toggleBtn:SetFrameLevel(content:GetFrameLevel() + 5)

    -- 测量 FontString：与内容同字体，仅用于 GetStringWidth()。
    -- 不用 Hide()（隐藏帧的 GetStringWidth 在部分客户端返回 0），改用透明 + 移除文本。
    measureFS = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    measureFS:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    measureFS:SetAlpha(0)
    measureFS:SetText("")
    measureFS:SetWordWrap(false)

    anchor:SetShown(ns.db.profile.panel.shown)
    ns.Collector.RegisterRefresh(Panel.RefreshAll)
    Panel.RefreshAll()
end
