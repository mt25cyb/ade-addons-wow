-- adeBagPack / Extra / Blizzard.lua（计划 §二决策 5：hook 保留原样，ns→ABP）
-- 原生背包整合（形态 B：接管原生整理按钮）。
-- 12.x 原生背包整理按钮为全局 BagItemAutoSortButton（挂在合并背包 ContainerFrame1 右上，
-- 由 Blizzard_Bags 加载期创建）。将其 OnClick 改为触发 ns:Pack('bag')。
--   useBlizzardSort 开启 → 退化为原生 SortBags()（兼容回退）。
-- 银行帧 12.x 无原生整理按钮（已核 FrameXML 无 AutoSortButton/Sort），
-- 银行整理由 Baganator 注册式（Extra/Baganator.lua）或斜杠命令 /adebp bank 提供。
local ns = _G.adeBagPack
if not ns then return end

local Blizzard = {}
ns.Blizzard = Blizzard

local hooked
local originalOnClick

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

function Blizzard:Init()
    TryHook()
    if hooked then
        return
    end
    -- 背包 UI 随首次打开按需加载，按钮全局未必在插件 OnInit 时存在 → 延迟到 ADDON_LOADED 再接
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, _, name)
        if name == "Blizzard_Bags" then
            TryHook()
            if hooked then
                f:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
end
