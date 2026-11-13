--[==[==========================================================================
    ade_MediaPack / StyleWigs.lua

    BigWigs 计时条皮肤。基于 RuriWigs 的 Ruri 半高条风格移植，
    纹理路径改为指向本插件的 textures\。

    机制：BigWigs 官方自定义条样式 API
    https://github.com/BigWigsMods/BigWigs/wiki/Custom-Bar-Styles

    安全约定：操作对象均为 BigWigs 自行创建的计时条（非暴雪原生框体），
    因此可以安全使用 SetParent / SetScript，不受 Forbidden Aspects 限制。

    v4 适配：v3 在文件顶部 `if not BigWigsAPI then return end` 会在 BigWigs 后加载时
    整文件静默退出、皮肤永不注册。此处改为延迟注册：BigWigs 已加载则立即注册，
    否则监听其 ADDON_LOADED 后再注册（BigWigs 多为按需加载）。
==========================================================================]==]

--- BigWigs / DBM 属于 OptionalDeps，DBT 与 BigWigsAPI 由对方插件运行时写入全局，
--- 静态检查无法解析，仅在本文件屏蔽 undefined-global（不改库、不造假全局）。
---@diagnostic disable: undefined-global
local _, ns = ...

local STYLE_NAME = "ADE Ruri"

local glowTex = [[Interface\AddOns\ade_MediaPack\textures\glow.tga]]
local bgTex = [[Interface\Buttons\WHITE8X8]]

local backdropBorder = {
    bgFile = bgTex,
    edgeFile = glowTex,
    tile = false,
    tileSize = 0,
    edgeSize = 3,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

--- 计时条停止时还原 BigWigs 原始外观
local function removeStyle(bar)
    local cbb = bar.candyBarBar

    bar.candyBarBackdrop:Hide()

    local height = bar:Get("bigwigs:restoreheight")
    if height then
        bar:SetHeight(height)
    end

    local tex = bar:Get("bigwigs:restoreicon")
    if tex then
        bar:SetIcon(tex)
        bar:Set("bigwigs:restoreicon", nil)
        bar.candyBarIconFrameBackdrop:Hide()
    end

    local timer = bar.candyBarDuration
    timer:ClearAllPoints()
    timer:SetPoint("TOPLEFT", cbb, "TOPLEFT", 2, 0)
    timer:SetPoint("BOTTOMRIGHT", cbb, "BOTTOMRIGHT", -2, 0)

    local label = bar.candyBarLabel
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", cbb, "TOPLEFT", 2, 0)
    label:SetPoint("BOTTOMRIGHT", cbb, "BOTTOMRIGHT", -2, 0)
end

--- 应用半高条样式
local function styleBar(bar)
    local cbb = bar.candyBarBar

    local height = bar:GetHeight()
    bar:Set("bigwigs:restoreheight", height)
    bar:SetHeight(height / 2)

    local bd = bar.candyBarBackdrop
    bd:SetBackdrop(backdropBorder)
    bd:SetBackdropColor(0, 0, 0, 0.4)
    bd:SetBackdropBorderColor(0, 0, 0, 1)
    bd:ClearAllPoints()
    bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -3, 3)
    bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 3, -3)
    bd:Show()

    local tex = bar:GetIcon()
    if tex then
        local icon = bar.candyBarIconFrame
        bar:SetIcon(nil)
        icon:SetTexture(tex)
        icon:Show()
        if bar.iconPosition == "RIGHT" then
            icon:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", 5, 0)
        else
            icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -5, 0)
        end
        icon:SetSize(height + 2, height + 2)
        bar:Set("bigwigs:restoreicon", tex)

        local iconBd = bar.candyBarIconFrameBackdrop
        iconBd:SetBackdrop(backdropBorder)
        iconBd:SetBackdropColor(0.15, 0.15, 0.15, 0.4)
        iconBd:SetBackdropBorderColor(0, 0, 0, 1)
        iconBd:ClearAllPoints()
        iconBd:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
        iconBd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 3, -3)
        iconBd:Show()
    end

    local label = bar.candyBarLabel
    label:SetShadowOffset(0, 0)
    label:ClearAllPoints()
    label:SetPoint("BOTTOMLEFT", cbb, "TOPLEFT", 2, -height / 4 + 2)

    local timer = bar.candyBarDuration
    timer:SetShadowOffset(0, 0)
    timer:ClearAllPoints()
    timer:SetPoint("BOTTOMRIGHT", cbb, "TOPRIGHT", -2, -height / 4 + 2)

    bar:SetTexture(bgTex)
end

local registered

--- 向 BigWigs 注册自定义条样式（幂等）
local function RegisterStyle()
    if registered or not BigWigsAPI then
        return
    end

    BigWigsAPI:RegisterBarStyle(STYLE_NAME, {
        apiVersion = 1,
        version = 1,
        barHeight = 24,
        GetSpacing = function(bar)
            return bar:GetHeight() + 10
        end,
        fontSizeNormal = 14,
        fontSizeEmphasized = 14,
        fontOutline = "OUTLINE",
        ApplyStyle = styleBar,
        BarStopped = removeStyle,
        GetStyleName = function()
            return STYLE_NAME
        end,
    })

    registered = true
end

--- 文件级自驱：BigWigs 已加载则立即注册，否则等其加载后再注册。
local function Init()
    if BigWigsAPI then
        RegisterStyle()
        return
    end

    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, _, name)
        if name == "BigWigs" then
            RegisterStyle()
            if registered then
                f:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
    f:RegisterEvent("ADDON_LOADED")
end

Init()
