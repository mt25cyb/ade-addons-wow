--[==[==========================================================================
    ade_MediaPack / MediaPack_ElvUI.lua

    来源：ElvUI_CustomMedia（Atwood）的 Statusbar\，共 18 个 .tga。
    原插件注册名取文件名去扩展名（"ElvUI A" ~ "ElvUI R"），并硬依赖 ElvUI；
    这里去掉重复的品牌词，统一为 "-ElvUI- <字母>"，引入后不再依赖 ElvUI。
    源插件未提供 border / background / sound，故本文件只注册 statusbar。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_STATUSBAR = ns.LSM.MediaType.STATUSBAR

local ROOT = [[Interface\AddOns\ade_MediaPack\material_3rd-party\ElvUI\statusbar\]]
local P_ELVUI = "-ElvUI- "

local bars = {
    { "A", "ElvUI A.tga" },
    { "B", "ElvUI B.tga" },
    { "C", "ElvUI C.tga" },
    { "D", "ElvUI D.tga" },
    { "E", "ElvUI E.tga" },
    { "F", "ElvUI F.tga" },
    { "G", "ElvUI G.tga" },
    { "H", "ElvUI H.tga" },
    { "I", "ElvUI I.tga" },
    { "J", "ElvUI J.tga" },
    { "K", "ElvUI K.tga" },
    { "L", "ElvUI L.tga" },
    { "M", "ElvUI M.tga" },
    { "N", "ElvUI N.tga" },
    { "O", "ElvUI O.tga" },
    { "P", "ElvUI P.tga" },
    { "Q", "ElvUI Q.tga" },
    { "R", "ElvUI R.tga" },
}

for _, entry in ipairs(bars) do
    ns.Register(MediaType_STATUSBAR, P_ELVUI .. entry[1], ROOT .. entry[2])
end
