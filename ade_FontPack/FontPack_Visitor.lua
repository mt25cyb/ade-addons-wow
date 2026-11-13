--[==[==========================================================================
    ade_FontPack / FontPack_Visitor.lua

    来源：LSM-Visitor，两个点阵风格字体。原注册名 "Visitor TT1/TT2"，
    此处保留语义并加 "-Visitor- " 前缀。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\Visitor\]]
local P_VISITOR = "-Visitor- "

ns.Register(MediaType_FONT, P_VISITOR .. "TT1", ROOT .. "visitor1.ttf", zhALL)
ns.Register(MediaType_FONT, P_VISITOR .. "TT2", ROOT .. "visitor2.ttf", zhALL)
