--[==[==========================================================================
    ade_FontPack / FontPack_ToriWhite.lua

    来源：ToriWhite_SharedMedia 的 Media\Fonts\，共 3 个字库。
    原插件注册名带彩色转义代码，且 langmask 为 ruRU + western，中文客户端不可见；
    此处统一为 "-ToriWhite- " 前缀 + 纯文本名，并传 zhALL 让中文客户端可取用。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\ToriWhite\]]
local P_TW = "-ToriWhite- "

ns.Register(MediaType_FONT, P_TW .. "T_W", ROOT .. "ToriWhite.ttf", zhALL)
ns.Register(MediaType_FONT, P_TW .. "3D", ROOT .. "ToriWhite 3D.ttf", zhALL)
ns.Register(MediaType_FONT, P_TW .. "Bold", ROOT .. "ToriWhite Bold.ttf", zhALL)
