--[==[==========================================================================
    ade_FontPack / FontPack_Blizzlike.lua

    来源：BlizzlikeTextures 的 front\expressway.ttf。
    原插件把字体注册路径写成 font\expressway.ttf，磁盘上却是 front\，属于失效路径；
    这里按引入后的真实目录注册。FRIZQT__.ttf 为暴雪内置字体，不重复引入。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\Blizzlike\]]
local P_BLIZZ = "-Blizzlike- "

ns.Register(MediaType_FONT, P_BLIZZ .. "Expressway", ROOT .. "expressway.ttf", zhALL)
