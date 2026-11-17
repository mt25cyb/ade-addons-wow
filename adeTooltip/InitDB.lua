-- adeTooltip — 默认值与校验表（C0 骨架；经典路线优先）。
-- 存档两层：settings 进配置档（profiles），state 为会话状态（不落档）。
-- 选项键沿用开发计划 v2 §二（MiliUI 经典路线真实范围）；未落地阶段只存键、不在选项页暴露。
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT

ADT.DEFAULTS = {
    settings = {
        useNewLayout = false,          -- LABEL_USE_NEW_LAYOUT：预留的新版排版开关（默认 false = 经典路线）
        scale = 1,                     -- LABEL_SCALE：整体缩放（RANGES 0.5–1.5）
        themeColor = { red = 238 / 255, green = 228 / 255, blue = 174 / 255 }, -- LABEL_THEME_COLOR：主题色 #EEE4AE
        -- 以下为经典/新版路线共用的子表；经典路线（C1–C6）与新版路线（N 阶段）按需读取。
        -- Panel 重绘外观（对照 MiliUI DB.BuildDefaults:171-181；ADE 原键保留兼容）
        panel = {
            qualityTint = true, separators = true, strip = true, minWidth = 260, maxWidth = 408,
            statMarkers = true, levelBadge = true,
            numberColor = "class", numberCustom = { r = 1, g = 0.82, b = 0, a = 1 },
            extrasBox = true, hideDuplicatePrice = true, unitWatermark = true,
        },
        -- item/spell 的 panel 开关：true=Panel 重绘主力路径（对照 MiliUI DB:156,164）
        item = {
            icon = true, qualityBorder = true, statMarkers = true, hideDupPrice = true, maxStack = true,
            panel = true, modifierShowAll = true, coloredItemBorder = true,
            showItemIcon = true, showItemId = false, showItemBonusId = false,
            showItemEnhancementId = false, showItemGemId = false, showItemMaxStack = true,
            showItemIconId = false, showItemExpansion = true,
        },
        spell = {
            icon = true, schoolTint = true, detailCoefficients = true,
            panel = true, modifierShowAll = true, showIcon = true,
            showSpellId = false, showSpellIconId = false, showMountSource = true,
        },
        aura = { showDuration = true, showCaster = true, dispellable = true },
        macro = { showBodyClassic = true },
        unit = {
            watermark = true,
            healthBar = true,
            -- 元素表逐字照搬 MiliUI DB.BuildDefaults:61-144（原名 + {enable,...}，
            -- 数字键数组是面板行布局）。Panel reader 按原名读 elements.*，不可改名。
            -- ADE 旧样式的扁平布尔键移到 config 顶层（status/server/...），供 panel=false 兜底。
            player = {
                coloredBorder = "class",
                background = { colorfunc = "default", alpha = 0.9 },
                grayForDead = false,
                showTarget = true, showTargetBy = true, showModel = false,
                modifierShowAll = true,
                panel = true,
                -- 旧样式扁平键（panel=false 时 UnitLines.Apply 从 config 顶层读）
                status = true, server = true, guild = true,
                className = false, race = false, title = false, level = false,
                raidIcon = false, roleIcon = false, pvpIcon = false, factionBig = false,
                elements = {
                    raidIcon    = { enable = true, filter = "none" },
                    roleIcon    = { enable = true, filter = "none" },
                    pvpIcon     = { enable = true, filter = "none" },
                    factionIcon = { enable = true, filter = "none" },
                    factionBig  = { enable = false, filter = "none" },
                    classIcon   = { enable = true, filter = "none" },
                    friendIcon  = { enable = true, filter = "none" },
                    title       = { enable = true, color = "ccffff", wildcard = "%s",   filter = "none" },
                    name        = { enable = true, color = "class",  wildcard = "%s",   filter = "none" },
                    realm       = { enable = true, color = "00eeee", wildcard = "%s",   filter = "none" },
                    statusAFK   = { enable = true, color = "ffd200", wildcard = "(%s)", filter = "none" },
                    statusDND   = { enable = true, color = "ffd200", wildcard = "(%s)", filter = "none" },
                    statusDC    = { enable = true, color = "999999", wildcard = "(%s)", filter = "none" },
                    guildName   = { enable = true, color = "ff00ff", wildcard = "<%s>", filter = "none" },
                    guildIndex  = { enable = true, color = "cc88ff", wildcard = "%s",   filter = "none" },
                    guildRank   = { enable = true, color = "cc88ff", wildcard = "(%s)", filter = "none" },
                    guildRealm  = { enable = false, color = "00cccc", wildcard = "%s",  filter = "none" },
                    levelValue  = { enable = true, color = "level",  wildcard = "%s",   filter = "none" },
                    itemLevel   = { enable = true, color = "itemLevel", wildcard = "%s", filter = "none", icon = false, decimals = 2 },
                    achievementPoints = { enable = true, color = "achievement", wildcard = "%s", filter = "none", icon = false },
                    factionName = { enable = true, color = "faction", wildcard = "%s",  filter = "none" },
                    gender      = { enable = false, color = "999999", wildcard = "%s",  filter = "none" },
                    raceName    = { enable = true, color = "cccccc", wildcard = "%s",   filter = "none" },
                    className   = { enable = true, color = "class",  wildcard = "%s",   filter = "none", icon = false },
                    isPlayer    = { enable = false, color = "ffffff", wildcard = "(%s)", filter = "none" },
                    role        = { enable = false, color = "ffffff", wildcard = "(%s)", filter = "none" },
                    moveSpeed   = { enable = false, color = "e8e7a8", wildcard = "%d%%", filter = "none" },
                    mplusScore  = { enable = true,  color = "mplus",  wildcard = "%s",   filter = "none", icon = false },
                    zone        = { enable = false, color = "ffffff", wildcard = "%s",   filter = "none" },
                    mount       = { enable = true,  color = "ffffff", wildcard = "%s",   filter = "none", icon = false },
                    { "friendIcon", "raidIcon", "roleIcon", "pvpIcon", "factionIcon", "classIcon", "title", "name", "realm", "statusAFK", "statusDND", "statusDC" },
                    { "guildName", "guildIndex", "guildRank", "guildRealm" },
                    { "levelValue", "factionName", "gender", "raceName", "className", "isPlayer", "role", "moveSpeed" },
                    { "mount" }, { "mplusScore" }, { "itemLevel" }, { "achievementPoints" }, { "zone" },
                },
            },
            npc = {
                coloredBorder = "reaction",
                background = { colorfunc = "default", alpha = 1 },
                grayForDead = true,
                showTarget = true, showTargetBy = true, showModel = false,
                modifierShowAll = true,
                panel = true,
                status = true, guild = false, className = true,
                race = true, title = true, level = false,
                classColoredLevel = true, raidIcon = true, roleIcon = false,
                pvpIcon = false, factionBig = false,
                elements = {
                    factionBig   = { enable = false, filter = "none" },
                    raidIcon     = { enable = true,  filter = "none" },
                    classIcon    = { enable = false, filter = "none" },
                    questIcon    = { enable = true,  filter = "none" },
                    name         = { enable = true, color = "default", wildcard = "%s",  filter = "none" },
                    npcTitle     = { enable = true, color = "99e8e8", wildcard = "<%s>", filter = "none" },
                    levelValue   = { enable = true, color = "level",  wildcard = "%s",  filter = "none" },
                    classifBoss  = { enable = true, color = "ff0000", wildcard = "(%s)", filter = "none" },
                    classifElite = { enable = true, color = "ffff33", wildcard = "(%s)", filter = "none" },
                    classifRare  = { enable = true, color = "ffaaff", wildcard = "(%s)", filter = "none" },
                    creature     = { enable = true, color = "selection", wildcard = "%s", filter = "none" },
                    reactionName = { enable = true, color = "33ffff", wildcard = "<%s>", filter = "reaction6" },
                    moveSpeed    = { enable = false, color = "e8e7a8", wildcard = "%d%%", filter = "none" },
                    { "raidIcon", "classIcon", "questIcon", "name" },
                    { "levelValue", "classifBoss", "classifElite", "classifRare", "creature", "reactionName", "moveSpeed" },
                },
            },
        },
        statusbar = {
            enable = true,
            texture = nil,
            height = 6,
            position = "bottom",
            color = "auto",
            customColor = { red = 0, green = 0.9, blue = 0.1 },
            textFormat = "percent",
            fontSize = 10,
            hideInCombat = false,
        },
        quest = { parchment = true },
        types = { unit = true, item = true, spell = true, aura = true, macro = true, quest = true, mail = true, object = true },
        modifier = { original = "ALT", details = "SHIFT" },
        anchor = { mode = "cursor", cursor = { point = "AUTO", x = 0, y = 0 }, static = { point = "CENTER", x = 0, y = 0 }, hiddenInCombat = false, showKey = "NONE" },
        general = {
            iconLabels = false,
            -- 皮肤外观（Skin.lua 读取；MiliUI 经典路线同源）
            bgfile = "Interface\\Tooltips\\UI-Tooltip-Background",
            borderColor = { r = 0, g = 0, b = 0, a = 1 },
            background = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
            borderSize = 1,
            mask = true,
            hideUnitFrameHint = true,
        },
    },
    state = {
        minimapShown = true,
        minimapAngle = 200,
        previewOpen = false,
    },
}

ADT.RANGES = {
    scale = { 0.5, 1.5 },
    ["panel.minWidth"] = { 220, 360 },
    ["panel.maxWidth"] = { 320, 560 },
    ["anchor.cursor.x"] = { -200, 200 },
    ["anchor.cursor.y"] = { -200, 200 },
    ["anchor.static.x"] = { -800, 800 },
    ["anchor.static.y"] = { -600, 600 },
}

ADT.CHOICES = {
    ["modifier.original"] = { "NONE", "ALT", "CTRL", "SHIFT" },
    ["modifier.details"] = { "NONE", "ALT", "CTRL", "SHIFT", "ALWAYS" },
    ["anchor.mode"] = { "cursor", "static", "default" },
    ["anchor.cursor.point"] = { "AUTO", "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
    ["anchor.static.point"] = { "CENTER", "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
    ["anchor.showKey"] = { "NONE", "ALT", "CTRL", "SHIFT" },
}

-- 下拉项的显示文本（CHOICES 的值是程序值，这里是本地化标签）。
ADT.CHOICE_TEXT = {
    cursor = "跟随鼠标", static = "固定锚点", default = "默认锚点",
    NONE = "无", ALT = "ALT", CTRL = "CTRL", SHIFT = "SHIFT", ALWAYS = "总是",
}

-- 会话状态键（不进配置档）。
ADT.STATE_KEYS = {
    minimapShown = true,
    minimapAngle = true,
    previewOpen = true,
}
