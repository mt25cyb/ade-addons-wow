-- adeAchDateFormat — 默认值唯一权威源。
-- 存档结构：adeAchDateFormatDB = { settings = {...} }；无配置档、无主题色选项。
local ADF = _G.adeAchDateFormat or {}
_G.adeAchDateFormat = ADF

ADF.DEFAULTS = {
    settings = {
        dateFormat = {
            preset = "5",                -- "1".."7" = UIKit 预设；"custom" = 自定义格式串
            custom = "%Y/%m/%d %R",      -- Krowi EventReminders 的 Custom 回退值
            hideTime = true,             -- 不显示 时:分（剥掉格式串中的 %R / %I:%M %p；%c 改 %x）
        },
        enableNative = true,             -- 暴雪原生成就 UI 的 6 处 hook
        enableKrowi = true,              -- Krowi_AchievementFilter 行日期
        enablePrat = true,               -- Prat 3.0 聊天成就链接日期（默认关，对齐可选扩展语义）
    },
}
