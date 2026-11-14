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
        panel = { qualityTint = true, separators = true, strip = true, minWidth = 260, maxWidth = 408 },
        item = { icon = true, qualityBorder = true, statMarkers = true, hideDupPrice = true, maxStack = true },
        spell = { icon = true, schoolTint = true, detailCoefficients = true },
        aura = { showDuration = true, showCaster = true, dispellable = true },
        macro = { showBodyClassic = true },
        unit = { watermark = true, healthBar = true },
        quest = { parchment = true },
        types = { unit = true, item = true, spell = true, aura = true, macro = true, quest = true, mail = true, object = true },
        modifier = { original = "ALT", details = "SHIFT" },
        anchor = { mode = "cursor", cursor = { point = "AUTO", x = 0, y = 0 }, static = { point = "CENTER", x = 0, y = 0 }, hiddenInCombat = false, showKey = "NONE" },
        general = { iconLabels = false },
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
