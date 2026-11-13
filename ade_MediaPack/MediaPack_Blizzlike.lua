--[==[==========================================================================
    ade_MediaPack / MediaPack_Blizzlike.lua

    来源：BlizzlikeTextures，statusbar\ 12 个文件（11 .blp + 1 .tga）、border\ 2 个文件。
    .png 是同名 .blp 的副本，原插件注册代码只引用 .blp，故不引入 .png。
    原插件只注册了 11 条状态条（BlizzPortraitFrameRound.blp 未用，
    "BlizzPortraitFrameRound" 实际指向 BlizzPortraitFrameRound2.blp）；
    这里按引入后的真实文件逐条注册，两个 Round 文件都可用且不再同名混淆。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local MediaType_BORDER = ns.LSM.MediaType.BORDER
local MediaType_STATUSBAR = ns.LSM.MediaType.STATUSBAR

local ROOT = [[Interface\AddOns\ade_MediaPack\material_3rd-party\Blizzlike\]]
local ROOT_BAR = ROOT .. [[statusbar\]]
local ROOT_BORDER = ROOT .. [[border\]]
local P_BLIZZ = "-Blizzlike- "

local function AddBar(name, file)
    ns.Register(MediaType_STATUSBAR, P_BLIZZ .. name, ROOT_BAR .. file)
end

local function AddBorder(name, file)
    ns.Register(MediaType_BORDER, P_BLIZZ .. name, ROOT_BORDER .. file)
end

-- ============ statusbar ============
AddBar("QuestTrackerHeadline", "BlizzQuestTrackerHeadline.blp")
AddBar("QuestTrackerLineHighlight", "BlizzQuestTrackerLineHighlight.blp")
AddBar("PortraitFrameRound", "BlizzPortraitFrameRound.blp")
AddBar("PortraitFrameRound2", "BlizzPortraitFrameRound2.blp")
AddBar("UfBar", "BlizzUfBar.blp")
AddBar("UfBarCarbon", "BlizzUfBarCarbon.blp")
AddBar("UfBorderBottom", "BlizzUfBorderBottom.blp")
AddBar("UfBorderLeft", "BlizzUfBorderLeft.blp")
AddBar("UfBorderMiddle", "BlizzUfBorderMiddle.blp")
AddBar("UfBorderRight", "BlizzUfBorderRight.blp")
AddBar("UfBorderTop", "BlizzUfBorderTop.blp")
AddBar("ElvUI", "ElvUI.tga")

-- ============ border ============
AddBorder("Glow", "glow.tga")
AddBorder("TooltipBorder", "BlizzardTooltipBorder.blp")
