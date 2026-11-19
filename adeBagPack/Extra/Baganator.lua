-- adeBagPack / Extra / Baganator.lua — Baganator 官方 API 整合（计划 §二决策 4，P3）
-- ① RegisterContainerSort：本插件排序注册进 Baganator 容器排序下拉
--    （容器枚举 Backpack/CharacterBank/WarbandBank，API/Main.lua:277-282；id 不得重名 :290）
-- ② RegisterRegion：背包视图注入整理按钮（官方入口 bottom_left；旧自建挂帧路径废弃；
--    §1.6 tdPack2 范例 API/Sorting.lua:16-43）
-- junk 回调剔除（决策 7：判定不接管 Baganator）；银行/战团整理走 Baganator 排序下拉或斜杠命令。
-- 开关 external.baganatorSort / baganatorButton 消费（注册时读档，P3.5 External.lua 提供即时挂/卸）。
local ABP = _G.adeBagPack
if not ABP then return end
local L = ABP.L

local Baganator = {}
ABP.Baganator = Baganator

-- Baganator ContainerType → 本插件整理目标（API/Main.lua:277-282）
local targetMap = {
    ["backpack"]       = "bag",
    ["character_bank"] = "bank",
    ["warband_bank"]   = "accountbank",
}

local sortRegistered
local regionAdded
local regionButton

-- Baganator 排序下拉触发（a11：不再用 Baganator 传入的 isReverse 覆盖本插件存档）——
-- 方向只认 adeBagPack 的 desc 开关（设置页「逆序整理」），避免 Baganator 每次排序
-- 都把方向改掉，使用户改动的分类顺序在物理上看起来「没生效」。
local function RegisterSort()
    if sortRegistered then return end
    local api = _G.Baganator and _G.Baganator.API
    if not (api and api.RegisterContainerSort) then return end
    local p = ABP:GetProfile()
    if not (p and p.external and p.external.baganatorSort) then return end
    api.RegisterContainerSort(L["BAGANATOR_LABEL"], "adebagpack", function(_, containerType)
        -- P3.5：baganatorSort 无反注册 API → 运行时查开关实现「挂/卸随开关」
        local p = ABP:GetProfile()
        if not (p and p.external and p.external.baganatorSort) then return end
        -- a11：忽略 Baganator 的 isReverse——方向由本插件 desc 决定（见上方注释）
        ABP.Pack:Start(targetMap[containerType] or "bag")
    end)
    sortRegistered = true
end

local function CreatePackButton()
    local btn = CreateFrame("Button", nil, UIParent, "UIPanelButtonNoTooltipTemplate")
    btn:SetSize(110, 20)
    btn:SetText(L["BAGANATOR_BTN_BAG"])
    btn:SetFrameStrata("HIGH")
    btn:SetScript("OnClick", function(_, mouseButton)
        if IsShiftKeyDown() and mouseButton == "LeftButton" then
            ABP.Pack:SetTransfer("bag2bank")
            ABP.Pack:Start()
        else
            ABP.Pack:SetTransfer(nil)
            ABP.Pack:Start("bag")
        end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["BAGANATOR_LABEL"])
        GameTooltip:AddLine(L["TIP_CLICK_SORT"] .. L["BAGANATOR_BTN_BAG"])
        GameTooltip:AddLine(L["TIP_SHIFT_LEFT"] .. L["TRANSFER_BAG2BANK"])
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return btn
end

local function RegisterRegion()
    if regionAdded then return end
    local api = _G.Baganator and _G.Baganator.API
    if not (api and api.RegisterRegion) then return end
    local p = ABP:GetProfile()
    if not (p and p.external and p.external.baganatorButton) then return end
    local btn = CreatePackButton()
    regionButton = btn
    local ok = api.RegisterRegion(L["BAGANATOR_LABEL"], "adebagpack", "backpack", "bottom_left", btn)
    -- 不静默：旧版 v822 该入口实测未生效，失败提示便于区分「开关未开」与「宿主不支持」
    -- （ShowMessage 受 showmessage 开关约束，致命性提示走 print 保证可见）
    if ok == false then
        print("|cff00AAFF[ADE]|r Baganator RegisterRegion 不支持（版本过旧），背包内按钮未注入")
    end
    if api.RequestLayoutUpdate then
        pcall(api.RequestLayoutUpdate)
    end
    regionAdded = true
end

local function RegisterAll()
    RegisterSort()
    RegisterRegion()
end

function Baganator:Init()
    if type(_G.Baganator) == "table" and _G.Baganator.API then
        RegisterAll()
        return
    end
    -- Baganator 可能晚于本插件加载 → 延迟到其 ADDON_LOADED
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, _, name)
        if name == "Baganator" then
            RegisterAll()
            f:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

-- P3.5：开关变更即时挂/卸（External.lua:Apply 调用；Options external.* AfterSet 触发）
function Baganator:ApplySettings()
    local p = ABP:GetProfile()
    local sortOn = p and p.external and p.external.baganatorSort
    if sortOn then
        RegisterSort()   -- 加载后开启时补注册；回调内查开关，关闭即 no-op
    end
    local btnOn = p and p.external and p.external.baganatorButton
    if regionButton then
        if btnOn then regionButton:Show() else regionButton:Hide() end
    elseif btnOn then
        RegisterRegion() -- 加载后开启时补注入
    end
end
