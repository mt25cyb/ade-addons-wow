--[==[==========================================================================
    ade_FontPack / ade_FontPack.lua

    ADE 套件共享字体库主入口，职责：
      1. 取 LibSharedMedia-3.0 实例，向 ns 暴露统一注册入口 ns.Register；
      2. 注册本插件精选字库（font/ 目录）。
    第三方来源字体由 FontPack_<来源>.lua 各自注册，文件放 font_3rd-party/<来源>/。

    LSM 由本插件 libs\ 下的 LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0
    按 TOC 顺序自行注册，不依赖任何外部插件；统一经全局 LibStub 取用。
    库缺失时本文件静默返回，后续来源文件检测 ns.Register 后同样跳过，不注册任何假数据。

    关于 langmask：LSM 的 Register 会在非 western 客户端过滤掉未带掩码的 font。
    这里统一传 zhALL，让 zhCN/zhTW 客户端也能取到这些字体；不含中文字形的
    拉丁字体在显示名后补 "(无中文)" 提示，避免被误用于中文文本。
==========================================================================]==]

local _, ns = ...
local L = ns.L

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if not LSM then
    return
end

ns.LSM = LSM

local MediaType_FONT = LSM.MediaType.FONT
local zhALL = LSM.LOCALE_BIT_zhCN + LSM.LOCALE_BIT_zhTW + LSM.LOCALE_BIT_western

--- 统一注册入口，供各来源注册文件经 ns.Register 调用。
---@param mediaType string
---@param name string
---@param path string 完整的 Interface\... 路径
---@param mask number? 字体区域掩码
---@return boolean?
function ns.Register(mediaType, name, path, mask)
    return LSM:Register(mediaType, name, path, mask)
end

local ROOTFONT = [[Interface\AddOns\ade_FontPack\font\]]
local P_ADE = "-ade- "

local function AddFont(name, file)
    ns.Register(MediaType_FONT, P_ADE .. name, ROOTFONT .. file, zhALL)
end

-- 精选通用字体（9 个，拉丁字形，显示名带"无中文"提示）
AddFont("Vells Mono" .. L["NO_CHINESE"], "VellsMono.ttf")
AddFont("FFXLCD" .. L["NO_CHINESE"], "FFXLCD.ttf")
AddFont("REDCIRCL" .. L["NO_CHINESE"], "REDCIRCL.ttf")
AddFont("Batolah" .. L["NO_CHINESE"], "Batolah.ttf")
AddFont("DeadKansas" .. L["NO_CHINESE"], "DeadKansas.ttf")
AddFont("Fish" .. L["NO_CHINESE"], "Fish.ttf")
AddFont("HotelCoralEssex" .. L["NO_CHINESE"], "HotelCoralEssex.ttf")
AddFont("RacingNumbers" .. L["NO_CHINESE"], "RacingNumbers.ttf")
AddFont("Showpop" .. L["NO_CHINESE"], "Showpop.ttf")

-- 游戏字体（2 个拉丁字形 + 3 个含中文字形）
AddFont(L["FONT_DIABLO"] .. " Light" .. L["NO_CHINESE"], "Diablo-Light.ttf")
AddFont(L["FONT_DIABLO"] .. " Medium" .. L["NO_CHINESE"], "Diablo-Medium.ttf")
AddFont(L["FONT_GENSHIN"], "Genshin.ttf")
AddFont(L["FONT_OVERWATCH"], "Overwatch.ttf")
AddFont(L["FONT_TARISLAND"], "TARISLAND.ttf")

-- 中文大字库（4 个）
AddFont(L["FONT_FZCY_GBK"], "FZCY_GBK.ttf")
AddFont(L["FONT_FZKT_GBK"], "FZKT_GBK.ttf")
AddFont(L["FONT_WDYQH"], "WDYQH.ttf")
AddFont(L["FONT_GENKAIMINCHO"], "genkai-mincho.ttf")
