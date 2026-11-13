--[==[==========================================================================
    ade_FontPack / FontPack_ElvUI.lua

    来源：ElvUI_CustomMedia（Atwood）的 Fonts\，共 14 个字库（10 .ttf + 4 .otf）。
    原插件注册名取文件名去扩展名（"ElvUI A" ~ "ElvUI N"），并硬依赖 ElvUI；
    这里去掉重复的品牌词，统一为 "-ElvUI- <字母>"，引入后不再依赖 ElvUI。
    字体统一传 zhALL，让 zhCN/zhTW 客户端也能在 LSM 里取到（见主入口说明）。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\ElvUI\]]
local P_ELVUI = "-ElvUI- "

local fonts = {
    { "A", "ElvUI A.ttf" },
    { "B", "ElvUI B.ttf" },
    { "C", "ElvUI C.ttf" },
    { "D", "ElvUI D.ttf" },
    { "E", "ElvUI E.ttf" },
    { "F", "ElvUI F.ttf" },
    { "G", "ElvUI G.ttf" },
    { "H", "ElvUI H.otf" },
    { "I", "ElvUI I.ttf" },
    { "J", "ElvUI J.otf" },
    { "K", "ElvUI K.otf" },
    { "L", "ElvUI L.otf" },
    { "M", "ElvUI M.ttf" },
    { "N", "ElvUI N.ttf" },
}

for _, entry in ipairs(fonts) do
    ns.Register(MediaType_FONT, P_ELVUI .. entry[1], ROOT .. entry[2], zhALL)
end
