--[==[ adeAnnivGuide / Core/Namespace.lua — 全局私有表 + 常量
    界面走 12.x 原生风格（用户 2026-11-21）：BasicFrameTemplate 原生窗口 +
    SearchBoxTemplate 搜索栏 + UIPanelButtonTemplate 按钮，不再自绘 MiliUI 深色壳。
    主题色仅用于正文富文本内的任务名【】/坐标强调与 tooltip 标题。 ]==]
local ns = _G.adeAnnivGuide or {}
_G.adeAnnivGuide = ns

ns.name = "adeAnnivGuide"

ns.THEME = { r = 238 / 255, g = 228 / 255, b = 174 / 255 }              -- #EEE4AE
ns.THEME_HEX = "|cffEEE4AE"

-- 几何常量（用户 2026-11-21：720×600）
ns.WIN_W, ns.WIN_H = 720, 600

-- 资源
ns.IMG_BASE = "Interface\\AddOns\\adeAnnivGuide\\assets\\guide\\"
