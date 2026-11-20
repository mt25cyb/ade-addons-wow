-- 自建多语言机制（CompassHUD 本体改造，2026-11-19）：
--   * 界面文案原文一律用 L["<英文原文>"]（英文原文即 key）；
--   * 各语种文件（本文件与 Locales/zhCN.lua，…可按语种追加）直接往全局表
--     CompassHUDLocale 里登记「英文原文 -> 译文」；
--   * 本文件是英文语言文件：只建全局表与回退机制，不登记词条；
--   * 任何语种缺失相应 key 时，由下方 __index 元方法返回 key 本身（即英文原文）作为最终文本输出。
--
-- 本文件必须是 TOC 的第一个 Lua 文件（位于 Libs 之前）：
--   * Profiles 页无需干预：Libs\AceDBOptions-3.0 自带完整 zhCN 语言块（GetLocale 分发），
--     第三方库文件保持原样不做修改；
--   * 插件共享环境 Addon.env 由 Init.lua 建立，并在其中注入 L = CompassHUDLocale，
--     因此 Init.lua 之后的本体文件直接引用 L 即可，无需各自的 local 声明。
_G.CompassHUDLocale = setmetatable({}, {
    __index = function(_, key)
        -- 缺键回退：key 即英文原文，直接作为最终文本输出
        return key
    end,
})

-- English needs no entries: for any key not registered by a language file, the
-- CompassHUDLocale table's __index metamethod above returns the key itself,
-- i.e. the English original, as the final text output. Registering nothing here
-- keeps the fallback intact and avoids double maintenance.
--
-- If a wording change ever breaks an existing key, register the OLD key here with the NEW text:
--     CompassHUDLocale["<old English original>"] = "<new text>"
