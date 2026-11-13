--[==[==========================================================================
    ade_MediaPack / StyleDBM.lua

    DBM 计时条皮肤。基于 RuriWigs 的 Ruri 半高条风格移植，
    纹理路径改为指向本插件的 textures\。

    机制：DBM 官方皮肤 API（DBT:RegisterSkin / DBT:SetSkin），
    配合 hooksecurefunc(DBT, "CreateBar", ...) 覆盖单条计时条外观。

    安全约定：一律使用 hooksecurefunc，不直接覆写 DBM 函数，
    避免产生 taint 扩散到受保护框体。

    改造说明：v3 在文件级直接创建事件帧并初始化；本插件没有 Core/OnInit 驱动，
    改为文件级自驱初始化，逻辑保持不变。
==========================================================================]==]

--- BigWigs / DBM 属于 OptionalDeps，DBT 与 BigWigsAPI 由对方插件运行时写入全局，
--- 静态检查无法解析，仅在本文件屏蔽 undefined-global（不改库、不造假全局）。
---@diagnostic disable: undefined-global
local _, ns = ...

local C_AddOns = C_AddOns

local SKIN_NAME = "ADE Ruri"

local glowTex = [[Interface\AddOns\ade_MediaPack\textures\glow.tga]]
local bgTex = [[Interface\Buttons\WHITE8X8]]

local iconSize = 24
local barHeight = iconSize
local barTextureHeight = iconSize / 2
-- DBM 的 BarYOffset / HugeBarYOffset 是计时条之间的垂直间距
local barSpacing = barHeight / 4

--- 用 glow 描边纹理生成描边层
local function CreateSD(parent, anchor, size)
    if not parent or not anchor then
        return
    end

    local sd = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local frameLevel = parent:GetFrameLevel() or 0

    sd:ClearAllPoints()
    sd:SetPoint("TOPLEFT", anchor, -size, size)
    sd:SetPoint("BOTTOMRIGHT", anchor, size, -size)
    sd:SetFrameLevel(frameLevel == 0 and 0 or frameLevel - 1)
    sd:SetBackdrop({ edgeFile = glowTex, edgeSize = size or 3 })
    sd:SetBackdropBorderColor(0, 0, 0, 1)

    return sd
end

--- 隐藏计时条的 spark
local function HideSpark(bar)
    local frame = bar and bar.frame
    if not frame then
        return
    end

    local name = frame:GetName()
    local spark = name and _G[name .. "BarSpark"]
    if spark then
        spark:SetAlpha(0)
        spark:SetTexture(nil)
    end
end

--- DBM 的图标是 Texture，不能直接套 Backdrop，需用 holder 框体承载描边
local function SkinIcon(icon, tbar, point, relativePoint, xOffset)
    if not icon or not tbar then
        return
    end

    local holder = icon.AdeHolder
    if not holder then
        holder = CreateFrame("Frame", nil, tbar, "BackdropTemplate")
        holder:SetFrameStrata("BACKGROUND")
        holder:SetSize(iconSize, iconSize)
        icon.AdeHolder = holder
    end

    holder:ClearAllPoints()
    holder:SetPoint(point, tbar, relativePoint, xOffset, -2)
    holder:SetSize(iconSize, iconSize)

    icon:ClearAllPoints()
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetPoint("TOPLEFT", holder, 2, -2)
    icon:SetPoint("BOTTOMRIGHT", holder, -2, 2)

    if not holder.Shadow then
        holder.Shadow = CreateSD(holder, icon, 3)
    end
end

--- 按 DBM 选项决定图标显示与否，并同步 holder
local function SetIconShown(icon, shown)
    if not icon then
        return
    end

    if shown then
        icon:Show()
        if icon.AdeHolder then
            icon.AdeHolder:Show()
        end
    else
        icon:Hide()
        if icon.AdeHolder then
            icon.AdeHolder:Hide()
        end
    end
end

--- 应用半高条样式
local function ApplyAdeStyle(bar)
    local frame = bar and bar.frame
    if not frame then
        return
    end

    local frameName = frame:GetName()
    if not frameName then
        return
    end

    local opts = (bar.owner and bar.owner.Options) or (DBT and DBT.Options)
    if not opts then
        return
    end

    local tbar = _G[frameName .. "Bar"]
    local icon1 = _G[frameName .. "BarIcon1"]
    local icon2 = _G[frameName .. "BarIcon2"]
    local name = _G[frameName .. "BarName"]
    local timer = _G[frameName .. "BarTimer"]
    if not tbar or not name or not timer then
        return
    end

    local width = bar.enlarged and opts.HugeWidth or opts.Width

    frame:SetScale(1)
    frame:SetSize(width, barHeight)

    tbar:ClearAllPoints()
    tbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
    tbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    tbar:SetHeight(barTextureHeight)
    tbar:SetStatusBarTexture(bgTex)

    if not tbar.AdeShadow then
        tbar.AdeShadow = CreateSD(tbar, tbar, 3)
    end

    SkinIcon(icon1, tbar, "BOTTOMRIGHT", "BOTTOMLEFT", -5)
    SkinIcon(icon2, tbar, "BOTTOMLEFT", "BOTTOMRIGHT", 5)
    SetIconShown(icon1, opts.IconLeft)
    SetIconShown(icon2, opts.IconRight)

    name:ClearAllPoints()
    name:SetPoint("BOTTOMLEFT", tbar, "TOPLEFT", 2, -iconSize / 4 + 2)
    name:SetWidth(165)
    name:SetShadowOffset(0, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)

    timer:ClearAllPoints()
    timer:SetPoint("BOTTOMRIGHT", tbar, "TOPRIGHT", -2, -iconSize / 4 + 2)
    timer:SetShadowOffset(0, 0)
    timer:SetJustifyH("RIGHT")

    HideSpark(bar)

    frame:SetAlpha(1)
    frame:Show()
end

--- 在 DBT:CreateBar 之后套用样式，每条计时条只 hook 一次以避免重复
local function SkinBars(timerObject)
    if not timerObject or not timerObject.GetBarIterator then
        return
    end

    for bar in timerObject:GetBarIterator() do
        if not bar.AdeInjected then
            hooksecurefunc(bar, "ApplyStyle", ApplyAdeStyle)
            hooksecurefunc(bar, "Update", HideSpark)
            bar.AdeInjected = true
        end

        ApplyAdeStyle(bar)
    end
end

--- 注册 DBM 官方皮肤
local function RegisterAdeSkin()
    if not DBT or not DBT.RegisterSkin or not DBT.SetSkin then
        return false
    end

    local skins = DBT.GetSkins and DBT:GetSkins()
    local skin = skins and skins[SKIN_NAME]
    if not skin then
        skin = DBT:RegisterSkin(SKIN_NAME)
    end
    if not skin or not skin.Defaults or not skin.Options then
        return false
    end

    skin.Defaults.Height = barHeight
    skin.Defaults.HugeHeight = barHeight
    skin.Defaults.Texture = bgTex
    skin.Defaults.FontFlag = "OUTLINE"
    skin.Defaults.Spark = false
    skin.Defaults.BarYOffset = barSpacing
    skin.Defaults.HugeBarYOffset = barSpacing

    skin.Options.Height = barHeight
    skin.Options.HugeHeight = barHeight
    skin.Options.Texture = bgTex
    skin.Options.FontFlag = "OUTLINE"
    skin.Options.Spark = false
    skin.Options.IconLocked = true
    skin.Options.BarYOffset = barSpacing
    skin.Options.HugeBarYOffset = barSpacing
    skin.Options.Scale = 1
    skin.Options.HugeScale = 1

    DBT:SetSkin(SKIN_NAME)
    return true
end

local initialized

--- 等 DBM-Core 与 DBM-StatusBarTimers 就绪后注册，全局只初始化一次
local function EnableAdeDBM()
    if initialized then
        return
    end

    if not C_AddOns.IsAddOnLoaded("DBM-Core") or not DBT then
        return
    end

    if not RegisterAdeSkin() then
        return
    end

    hooksecurefunc(DBT, "CreateBar", SkinBars)
    SkinBars(DBT)

    initialized = true
end

--- 文件级自驱。SetScript 先于 RegisterEvent（12.x 强制）。
local function Init()
    local eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(_, event, addonName)
        if event == "PLAYER_LOGIN" or addonName == "DBM-Core" or addonName == "DBM-StatusBarTimers" then
            EnableAdeDBM()
        end
    end)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")

    -- 处理 LoD（按需加载）场景下 DBM 先于本插件就绪的情况
    EnableAdeDBM()
end

Init()
