-- 宿主接点：仅此文件允许放宿主相关配置，不引入参考插件字体。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

AF.L = AF.L or setmetatable({}, { __index = function(_, key) return key end })
AF.VERSION = "v6-r001-b010"

-- 内置形态的宿主在加载本包之前覆盖此值，即可复用同一份素材（见 SYNC.md）。
AF.ADDON_DIR = AF.ADDON_DIR or "ade_AddonFramework"

AF.WHITE = "Interface\\BUTTONS\\WHITE8X8" -- 17:17:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
AF.DEFAULT_ACCENT = { red = 238 / 255, green = 228 / 255, blue = 174 / 255 } -- #EEE4AE

-- 双布局规格：61:82:_docs/plans/ADE-v6-settings-sys-dev-plan.md
AF.LAYOUT = {
    singleW = 720,
    multiW = 860,
    height = 680,
    sidebarW = 140,
    contentW = 672,
    rowH = 26,
    cellGap = 8,
    labelW = 160,
}

AF.PopupParent = UIParent
AF.LABEL_W = AF.LAYOUT.labelW

function AF.MediaPath(file)
    return "Interface\\AddOns\\" .. AF.ADDON_DIR .. "\\assets\\textures\\" .. file
end
AF.CHECK_TEX = AF.MediaPath("check-outline.tga")

-- 字体对象带固定命名空间前缀：CreateFont 撞名会回传既有对象（Widgets.lua:39-41 实证）。
local function MakeFont(name, size, r, g, b)
    local f = CreateFont("AF_" .. name)
    f:SetFont(STANDARD_TEXT_FONT, size, "")
    f:SetTextColor(r, g, b)
    f:SetShadowColor(0, 0, 0)
    f:SetShadowOffset(1, -1)
    return f
end
AF.fontNormal = MakeFont("FontNormal", 13, 1, 1, 1)          -- 43:44:…/Widgets.lua
AF.fontTitle = MakeFont("FontTitle", 14, 1, 1, 1)            -- 49:50:…/Widgets.lua
AF.fontSmall = MakeFont("FontSmall", 11, 0.8, 0.8, 0.8)     -- 62:63:…/Widgets.lua

function AF.Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(AF.AccentHex() .. "ade_AddonFramework|r: " .. tostring(msg))
    end
end
function AF.Printf(fmt, ...)
    AF.Print(string.format(fmt, ...))
end
