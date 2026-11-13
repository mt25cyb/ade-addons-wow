--[==[==========================================================================
    ade_FontPack / FontPack_Mono.lua

    来源：SharedMediaFontsMono 的 Assets\Fonts\，共 9 个等宽字体。
    原插件除标准 font 外还自定义了 "font-mono" 媒体类型；该类型非 LSM 标准且会
    改动全局 LSM.MediaType，此处只按标准 font 注册。
    注册名沿用原插件 baseName() 规则：去扩展名，_ 与 - 替换为空格；
    原插件把 NotoSansMonoCJKsc-Regular.otf 注册了两次（同名，第二次会被 LSM 忽略），
    这里每个文件只注册一次。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_FONT = ns.LSM.MediaType.FONT
local zhALL = ns.LSM.LOCALE_BIT_zhCN + ns.LSM.LOCALE_BIT_zhTW + ns.LSM.LOCALE_BIT_western

local ROOT = [[Interface\AddOns\ade_FontPack\font_3rd-party\Mono\]]
local P_MONO = "-Mono- "

local fonts = {
    "IBMPlexMono-Medium.ttf",
    "Inconsolata_SemiCondensed-Medium.ttf",
    "JetBrainsMono-Medium.ttf",
    "NotoSansMonoCJKkr-Regular.otf",
    "NotoSansMonoCJKsc-Regular.otf",
    "NotoSansMonoCJKtc-Regular.otf",
    "RobotoMono-Medium.ttf",
    "SourceCodePro-Medium.ttf",
    "UbuntuSansMono-Medium.ttf",
}

for _, file in ipairs(fonts) do
    local name = (file:gsub("%.%w+$", ""):gsub("[_%-]", " "))
    ns.Register(MediaType_FONT, P_MONO .. name, ROOT .. file, zhALL)
end
