-- adeBagPack / Extra / Blizzard.lua（计划 §二决策 5：hook 保留原样，ns→ABP）
-- 原生背包整合（形态 B：接管原生整理按钮）。
-- 12.x 原生背包整理按钮为全局 BagItemAutoSortButton（挂在合并背包 ContainerFrame1 右上，
-- 由 Blizzard_Bags 加载期创建）。将其 OnClick 改为触发 ns:Pack('bag')。
--   useBlizzardSort 开启 → 退化为原生 SortBags()（兼容回退）。
-- 银行帧 12.x 有原生 AutoSortButton（BankFrame.xml:617 BankAutoSortButtonTemplate），
-- 本文件只处理背包；银行整理由 Baganator 注册式或斜杠命令 /adebp bank 提供。
--
-- a16：形态 A —— 自建整理按钮「外挂」到原生背包界面（独立于形态 B 的原生按钮接管）。
-- 依据 12.x 暴雪源码（z-ref_wow-dev-git/wow-ui-source/.../Blizzard_UIPanels_Game/Mainline）：
--   · 合并背包 = ContainerFrameCombinedBags，单袋 = ContainerFrame1..6（ContainerFrame.xml:283-290）
--   · 原生整理按钮 BagItemAutoSortButton 的 parent 会随当前容器帧切换（ContainerFrame.lua:977-985），
--     锚 TOPRIGHT -9,-34；自建按钮锚其左侧避免重叠。
--   · 按钮 parent 直接设容器帧（同源插件商人框按钮范式 ADE.CreateButton(MerchantFrame,...)），
--     普通 Button 不触发 secure taint。显隐用 HookScript(OnShow/OnHide) + 事件重扫（同 Baganator.lua）。
local ns = _G.adeBagPack
if not ns then return end
local L = ns.L

local Blizzard = {}
ns.Blizzard = Blizzard

local hooked
local originalOnClick
local packButton
local hookedFrames = {}
local reanchorPending = false

local function DoSort(target)
    -- a11：不再因 Baganator 在场而静默 return——用户点原生整理按钮时，
    -- adeBagPack 必须执行（此前 Baganator 在场 = 按钮完全无动作，表现为
    -- 「调整顺序后整理不生效」）。Baganator 注册式排序与其注入按钮仍各自可用，
    -- 三条入口都收敛到 Pack:Start → BeginPacking → Rule:OnProfileUpdate。
    local p = ns:GetProfile()
    if p and p.useBlizzardSort then
        if target == "bank" then
            pcall(SortBankBags)
        else
            pcall(SortBags)
        end
    else
        ns.Pack:Start(target)
    end
end

local function OnClick()
    DoSort("bag")
end

local function TryHook()
    if hooked then
        return
    end
    local p = ns:GetProfile()
    if not p or not p.overrideNativeSort then
        return
    end
    local btn = _G.BagItemAutoSortButton
    if not btn then
        return
    end
    if not originalOnClick then
        originalOnClick = btn:GetScript("OnClick")
    end
    btn:SetScript("OnClick", OnClick)
    hooked = true
end

local function Restore()
    if not hooked then
        return
    end
    local btn = _G.BagItemAutoSortButton
    if btn and originalOnClick then
        btn:SetScript("OnClick", originalOnClick)
    end
    hooked = false
end

-- 设置面板开关实时切换接管/还原原生按钮
function Blizzard:ApplyOverride()
    local p = ns:GetProfile()
    if p and p.overrideNativeSort then
        TryHook()
    else
        Restore()
    end
end

------ 形态 A：自建整理按钮外挂到原生背包界面

-- 取当前显示的背包容器帧：合并背包优先，否则单袋 ContainerFrame1
-- （ContainerFrame.lua:2029-2032 GetBackpackFrame 同款判定；:2071-2074 合并/单袋切换）
local function GetVisibleContainer()
    local combined = _G.ContainerFrameCombinedBags
    if combined and combined:IsShown() then return combined end
    local single = _G.ContainerFrame1
    if single and single:IsShown() then return single end
    return nil
end

-- 按开关与容器显隐刷新按钮位置/可见性
local function RefreshPackButton()
    if not packButton then return end
    local p = ns:GetProfile()
    local enabled = p and p.nativeSortButton
    local container = GetVisibleContainer()
    if not enabled or not container then
        packButton:Hide()
        return
    end
    packButton:ClearAllPoints()
    -- 原生整理按钮锚 TOPRIGHT -9,-34（ContainerFrame.lua:978）；自建按钮锚其左侧，
    -- 避免遮挡原生按钮与搜索框。原生按钮未显示时回落到容器右上偏左固定位。
    local sortBtn = _G.BagItemAutoSortButton
    if sortBtn and sortBtn:IsShown() and sortBtn:GetParent() == container then
        packButton:SetPoint("RIGHT", sortBtn, "LEFT", -4, 0)
    else
        packButton:SetPoint("TOPRIGHT", container, "TOPRIGHT", -44, -34)
    end
    packButton:Show()
    -- OnShow/BAG_OPEN 触发时暴雪可能尚未把 BagItemAutoSortButton SetParent 到当前帧
    -- （ContainerFrame.lua:977 在后续布局中执行），延迟一帧按真实 parent 重锚一次。
    -- reanchorPending 防递归：延迟回调里若再次调度就跳过。
    if not reanchorPending then
        reanchorPending = true
        C_Timer.After(0, function()
            reanchorPending = false
            RefreshPackButton()
        end)
    end
end

local function CreatePackButton()
    if packButton then return end
    packButton = CreateFrame("Button", "AdeBagPackNativeSortButton", UIParent, "UIPanelButtonTemplate")
    packButton:SetSize(84, 22)
    packButton:SetText(L["NATIVE_SORT_BUTTON"] or "整理背包")
    packButton:SetFrameStrata("HIGH")
    packButton:SetScript("OnClick", function()
        DoSort("bag")
    end)
    packButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["NATIVE_SORT_BUTTON"] or "整理背包", 1, 1, 1)
        GameTooltip:AddLine(L["NATIVE_SORT_BUTTON_TIP"] or "按 adeBagPack 规则整理背包", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    packButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    packButton:Hide()
end

-- HookScript 而非 SetScript：不覆盖暴雪原生的 OnShow/OnHide 逻辑
local function HookContainer(frame)
    if not frame or hookedFrames[frame] then return end
    frame:HookScript("OnShow", RefreshPackButton)
    frame:HookScript("OnHide", RefreshPackButton)
    hookedFrames[frame] = true
end

local function SetupPackButton()
    CreatePackButton()
    HookContainer(_G.ContainerFrameCombinedBags)
    HookContainer(_G.ContainerFrame1)
    RefreshPackButton()
end

-- 设置页开关即时生效
function Blizzard:ApplyNativeButton()
    RefreshPackButton()
end

function Blizzard:Init()
    -- a16：不能用旧逻辑「hooked 成功就 return」——自建按钮与原生按钮接管是两个
    -- 独立开关，必须都完成初始化。
    TryHook()
    SetupPackButton()

    -- 背包 UI 随首次打开按需加载，容器帧/按钮全局未必在插件 OnInit 时存在
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("BAG_OPEN")
    f:RegisterEvent("BAG_CLOSED")
    f:SetScript("OnEvent", function(_, event, name)
        if event == "ADDON_LOADED" then
            if name == "Blizzard_Bags" or name == "Blizzard_UIPanels_Game" then
                TryHook()
                SetupPackButton()
            end
        else
            -- 容器帧 parent 可能随 BAG_OPEN 切换，重扫锚点
            RefreshPackButton()
        end
    end)
end
