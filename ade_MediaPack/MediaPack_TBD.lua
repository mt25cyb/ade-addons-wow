--[==[==========================================================================
    ade_MediaPack / MediaPack_TBD.lua

    来源：SharedMedia_TBD，仅引入用户指定的 statusbar\Line.tga。
    原插件注册名 "Line" 不带来源标识，这里加 "-TBD- " 前缀避免键名冲突。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_STATUSBAR = ns.LSM.MediaType.STATUSBAR
local ROOT = [[Interface\AddOns\ade_MediaPack\material_3rd-party\SharedMedia_TBD\]]
local ROOT_BAR = ROOT .. [[statusbar\]]
local P_MMT = "-TBD- "

ns.Register(MediaType_STATUSBAR, P_MMT .. "Line", ROOT_BAR .. "Line.tga")
