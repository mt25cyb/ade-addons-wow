-- adeTooltip — 默认值与校验表（P1 骨架）。
-- 存档两层（adeTooltip 开发计划 §三.1）：settings 进配置档（profiles），state 为会话状态。
-- 每个选项默认值行尾注明对应 LABEL_*（项目规范 §3.4）；后续阶段新增的键同步补注释。
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT

ADT.DEFAULTS = {
    settings = {
        usePrettyStyle = true,          -- LABEL_USE_PRETTY：使用新版排版（Pretty 风格面板）；false = MiliUI 经典排版（修改原生行）
        twoStage = true,                -- LABEL_TWO_STAGE：物品/法术两段式（原生整体拆两段，其他插件信息并入段二）
        scale = 1,                      -- LABEL_SCALE：整体缩放（RANGES 0.5–1.5）
        themeColor = { red = 238 / 255, green = 228 / 255, blue = 174 / 255 }, -- LABEL_THEME_COLOR：主题色 #EEE4AE
        -- 各类型是否参与新版排版（§三.2 types.*；P2 起被 ShouldPanel 消费）
        types = {
            unit = true, item = true, spell = true, aura = true,
            macro = true, quest = true, mail = true, object = true,
        },
    },
    state = {
        minimapShown = true,            -- LABEL_MINIMAP_SHOWN：小地图按钮显隐（会话状态，不入档）
        minimapAngle = 200,             -- 小地图圆周角度 0–360（会话状态，不入档）
        previewOpen = false,            -- 预览面板开合（会话状态，不入档）
    },
}

ADT.RANGES = {
    scale = { 0.5, 1.5 },
}

ADT.CHOICES = {}
