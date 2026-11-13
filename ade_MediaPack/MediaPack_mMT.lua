--[==[==========================================================================
    ade_MediaPack / MediaPack_mMT.lua

    来源：!mMT_MediaPack，按类型拆到 material_3rd-party\mMT\ 下：
      statusbar\ 340 个 .tga、border\ 32 个 .tga、background\ 23 个 .tga、sound\ 25 个 .ogg。
    状态条沿用原包 "mMediaTag <系列字母><序号>" 的编号体系，用循环生成；
    编号之外的具名状态条单独列出。原包缺 n15.tga，故 skip 表跳过它。
    所有注册名统一加 "-mMT- " 前缀，避免与其它材质包键名冲突。
==========================================================================]==]

local _, ns = ...
if not ns.Register or not ns.LSM then
    return
end

local strupper = string.upper

local MediaType_BACKGROUND = ns.LSM.MediaType.BACKGROUND
local MediaType_BORDER = ns.LSM.MediaType.BORDER
local MediaType_STATUSBAR = ns.LSM.MediaType.STATUSBAR
local MediaType_SOUND = ns.LSM.MediaType.SOUND

local ROOT = [[Interface\AddOns\ade_MediaPack\material_3rd-party\mMT\]]
local ROOT_BAR = ROOT .. [[statusbar\]]
local ROOT_BORDER = ROOT .. [[border\]]
local ROOT_BG = ROOT .. [[background\]]
local ROOT_SOUND = ROOT .. [[sound\]]
local P_MMT = "-mMT- "

local function AddBar(name, file)
    ns.Register(MediaType_STATUSBAR, P_MMT .. name, ROOT_BAR .. file)
end

local function AddBorder(name, file)
    ns.Register(MediaType_BORDER, P_MMT .. name, ROOT_BORDER .. file)
end

local function AddBackground(name, file)
    ns.Register(MediaType_BACKGROUND, P_MMT .. name, ROOT_BG .. file)
end

local function AddSound(name, file)
    ns.Register(MediaType_SOUND, P_MMT .. name, ROOT_SOUND .. file)
end

-- ============ statusbar ============
local series = {
    a = 15, b = 16, c = 15, d = 15, e = 13, f = 15, g = 15, h = 18, i = 10, j = 10,
    k = 36, l = 15, m = 15, n = 39, o = 15, p = 18, q = 4, r = 29, s = 10, t = 8,
}

-- 原包中缺失的编号，磁盘上确实没有 n15.tga
local skip = { n15 = true }

for key, count in pairs(series) do
    local upper = strupper(key)
    for i = 1, count do
        local id = key .. i
        if not skip[id] then
            AddBar(upper .. i, id .. ".tga")
        end
    end
end

-- 游离于编号体系之外的状态条
AddBar("N38v2", "n38v2.tga")
AddBar("N38v3", "n38v3.tga")
AddBar("Caith UI 1", "Wglass.tga")
AddBar("Caith UI 2", "Wisps.tga")
AddBar("MaUIv3", "MaUIv3.tga")
AddBar("MaUIv3 LEFT", "MaUIv3Left.tga")
AddBar("MaUIv3 RIGHT", "MaUIv3Right.tga")
AddBar("Blank", "mMT_Blank.tga")
AddBar("Target", "mMT_Target.tga")
AddBar("Dark", "mMT_Dark.tga")

-- ============ background ============
for i = 1, 11 do
    AddBackground("BG" .. i, "bg" .. i .. ".tga")
end
for i = 1, 12 do
    AddBackground("Chat" .. i, "chat" .. i .. ".tga")
end

-- ============ border ============
AddBorder("Border1", "mborder1.tga")
AddBorder("Border2", "mborder2.tga")
AddBorder("yborder", "yborder.tga")
AddBorder("yborder2", "yborder2.tga")
AddBorder("YuluBorderSwitch", "YuluBorderSwitch.tga")
AddBorder("YuluBorderXI", "YuluBorderXI.tga")
AddBorder("Pixel", "pixel.tga")
AddBorder("Pencil and Lieneal", "pencilandlieneal.tga")
AddBorder("Pencil and Lieneal black/white", "pencilandlienealblack.tga")
AddBorder("Speech Bubble", "bubble.tga")
AddBorder("Speech Bubble mirror", "bubblem.tga")
AddBorder("Speech Bubble red", "bubbler.tga")
AddBorder("Speech Bubble red/mirror", "bubblerm.tga")
AddBorder("Speech Bubble 2", "bubble2.tga")
AddBorder("Speech Bubble 2 mirror", "bubble2m.tga")
AddBorder("Speech Bubble 2 red", "bubble2r.tga")
AddBorder("Speech Bubble 2 red/mirror", "bubble2rm.tga")
AddBorder("Speech Bubble 3", "bubble3.tga")
AddBorder("Speech Bubble 3 mirror", "bubble3m.tga")
AddBorder("Speech Bubble 3 red", "bubble3r.tga")
AddBorder("Speech Bubble 3 red/mirror", "bubble3rm.tga")
AddBorder("Squares", "squares.tga")
AddBorder("Squares mirror", "squaresm.tga")
AddBorder("Squares red", "squaresr.tga")
AddBorder("Squares red/mirror", "squaresrm.tga")
AddBorder("Corners", "corners.tga")
AddBorder("Round", "round.tga")
AddBorder("Drawn", "drawn.tga")
AddBorder("Wood", "wood.tga")
AddBorder("Glass", "glass.tga")
AddBorder("Heart and Star", "heartandstar.tga")
AddBorder("Round Corners", "roundcorners.tga")

-- ============ sound ============
AddSound("Bewegen - female", "bewegen_female.ogg")
AddSound("Unterbrechen - female", "unterbrechen_female.ogg")
AddSound("Bewegen - male", "bewegen_male.ogg")
AddSound("Unterbrechen - male", "unterbrechen_male.ogg")
AddSound("Feet - female", "feet_female.ogg")
AddSound("Feet - male", "feet_male.ogg")
AddSound("Get out - female", "getout_female.ogg")
AddSound("Interrupt - female", "interrupt_female.ogg")
AddSound("Interrupt - male", "interrupt_male.ogg")
AddSound("Kick - female", "kick_female.ogg")
AddSound("STUN! - female", "loud_stun_female.ogg")
AddSound("Stun - female", "stun_female.ogg")
AddSound("Stun - male", "stun_male.ogg")
AddSound("AOE - DE - male", "aoe_de_male.ogg")
AddSound("AOE - DE - female", "aoe_de_female.ogg")
AddSound("AOE - male", "aoe_male.ogg")
AddSound("AOE - female", "aoe_female.ogg")
AddSound("AOE 2 - female", "aoe_b_female.ogg")
AddSound("Frontal - male", "frontal_male.ogg")
AddSound("Frontal - female", "frontal_female.ogg")
AddSound("Frontal 2 - female", "frontal_b_female.ogg")
AddSound("Incorp - male", "incorp_male.ogg")
AddSound("Incorp - female", "incorp_female.ogg")
AddSound("Incorporeal - male", "incorporeal_male.ogg")
AddSound("Incorporeal - female", "incorporeal_female.ogg")
