--[==[==========================================================================
    ade_FontPack / FontPack_mMT.lua

    来源：!mMT_MediaPack 的 media\fonts\，共 23 个字库。
    原包注册名与文件名同名，此处统一加 "-mMT- " 前缀，避免与其它材质包键名冲突。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\mMT\]]
local P_MMT = "-mMT- "

local fonts = {
    "BarlowCondensed-Bold.ttf",
    "BarlowCondensed-Medium.ttf",
    "BarlowCondensed-Regular.ttf",
    "BarlowCondensed-SemiBold.ttf",
    "Beep-Bold.otf",
    "Beep-Medium.otf",
    "Beep-Regular.otf",
    "Inter-Bold.ttf",
    "Inter-Regular.ttf",
    "Inter-SemiBold.ttf",
    "Lemon-Regular.ttf",
    "Montserrat-Bold.ttf",
    "Montserrat-Medium.ttf",
    "Montserrat-Regular.ttf",
    "Montserrat-SemiBold.ttf",
    "NotoSans-Bold.ttf",
    "NotoSans-SemiBold.ttf",
    "RingLink-Bold.otf",
    "RingLink-Medium.otf",
    "SimplySans-Bold.ttf",
    "SimplySans-Book.ttf",
    "Ubuntu-Bold.ttf",
    "Ubuntu-Medium.ttf",
}

for _, file in ipairs(fonts) do
    local name = (file:gsub("%.%w+$", ""))
    ns.Register(MediaType_FONT, P_MMT .. name, ROOT .. file, zhALL)
end
