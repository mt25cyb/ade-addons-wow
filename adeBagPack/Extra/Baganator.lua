-- adeBagPack / Extra / Baganator.lua — Baganator 官方 API 整合（计划 §二决策 4，P3）
-- ① RegisterContainerSort：本插件排序注册进 Baganator 容器排序下拉
--    （容器枚举 Backpack/CharacterBank/WarbandBank，API/Main.lua:277-282；id 不得重名 :290）
-- ② a17：整理按钮改为「标题栏排序按钮左侧」的透明材质图标按钮（不再走 RegisterRegion 底部区域）。
--    依据镜像源码：
--      · BackpackView.lua:31  self.ButtonsManager = InitFrameWithMixin(self, ButtonsMixin)
--        → Utilities.lua:9-13 CreateFrame("Frame", nil, parent) —— ButtonsManager 的 parent = 视图帧
--      · BackpackView.lua:54-58 AddButton("topRight", "sort", ...)
--      · Buttons.lua:53-59   GetButton(kind) 懒创建于 self:GetParent() = 视图帧
--      · Buttons.lua:61-145  Arrange() 每次重排 topRight 锚点，链序（右→左）：
--        customise → sort → transfer → swap → toggleGrouping（positions.topRight 倒序遍历）
--      · Initialize.lua:150-151 视图帧名 Baganator_SingleView/CategoryViewBackpackViewFrame<group>
--      · ContainerFrame.xml:312-315 原生整理按钮 NormalTexture=bags-button-autosort-up /
--        PushedTexture=bags-button-autosort-down（即用户指定材质）
--    实现：hooksecurefunc(mgr,"Arrange") 在本插件按钮该显示时，锚到 sort 左侧并把原左邻
--    改锚到本按钮左侧；开关 baganatorButton 关闭时直接 return，不触碰 Baganator 自身按钮链。
-- ③ a18：注入扩展到银行/战团银行视图（Initialize.lua:224-228
--    Baganator_SingleView/CategoryViewBankViewFrame<group>）。银行是**单帧双 tab**——
--    BankView.lua:40 currentTab=self.Character、:75-80 InitializeWarband 建 self.Warband
--    （Syndicator.Constants.WarbandBankActive 时），角色银行/战团银行共用一帧。
--    银行视图按钮链与背包同构（BankView.lua:211-218 customise→sort→transfer，
--    sort 激活回调 = currentTab.isLive and not currentTab.isLocked）→ ReflowButtons 原样适用；
--    tab 切换广播 BankViewChanged（BankView.lua:71，Constants.lua:107）。
--    按钮行为参考旧版 buttonDefs（_temp/_old_ADE_1/adeBackpack/Extra/Baganator.lua:35-46）：
--      背包    = 整理 bag（Shift+左 bag2bank）
--      角色银行 = 整理 bank（Shift+左 bank2bag）
--      战团 tab = 整理 accountbank（Shift+左 abank2bag / Shift+右 abank2bank）
--    设计上不照抄旧版「bank 视图挂两按钮按 tab 显隐重挂」（切换跳动），沿用 a17 单按钮注入，
--    OnClick / tooltip 按 GetActiveBankTab(view) 动态生成（tooltip OnEnter 实时读 tab）。
-- junk 回调剔除（决策 7：判定不接管 Baganator）。
-- ④ a19：修复本按钮随 Baganator sort 按钮显隐的问题——Baganator 设置可单独设每个按钮
--    show/hide/alt（Buttons.lua:72-110 读 BUTTONS 配置），原 ReflowButtons 把 sortBtn:IsShown()
--    当隐藏条件，sort 设为 hide 时本按钮一并消失；改为只由本插件开关决定显隐，sort 隐藏时
--    锚点回退到可见按钮链首（active.topRight[1]），照 Extra/Blizzard.lua:103-132 的解耦模式。
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
local callbacksRegistered
local warned
-- 已注入的视图帧：view → { btn = Button, viewType = "backpack"|"bank" }
local injected = {}

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

------ a17/a18：标题栏排序按钮左侧的材质整理按钮

-- 银行视图激活 tab：currentTab == Warband → 战团银行，否则角色银行。
-- （BankView.lua:40/:75-80；WarbandBankActive=false 时 Warband 子帧不存在恒 bank。
--   判定逻辑同旧版 _old_ADE_1/adeBackpack/Extra/Baganator.lua:122-127）
local function GetActiveBankTab(view)
    if view.Warband and view.currentTab == view.Warband then
        return "warband"
    end
    return "bank"
end

local function CreatePackButton(view, viewType)
    local btn = CreateFrame("Button", nil, view)
    btn:SetSize(28, 26)  -- 与暴雪原生 BagItemAutoSortButton 同尺寸（ContainerFrame.xml:313）

    -- 材质取原生整理按钮同款 atlas（ContainerFrame.xml:314-315）。Lua 侧须用
    -- Texture:SetAtlas，不能直接把 atlas 名塞进 SetNormalTexture（那会被当文件路径）。
    local normal = btn:CreateTexture(nil, "ARTWORK")
    normal:SetAtlas("bags-button-autosort-up")
    normal:SetAllPoints(btn)
    btn:SetNormalTexture(normal)

    local pushed = btn:CreateTexture(nil, "ARTWORK")
    pushed:SetAtlas("bags-button-autosort-down")
    pushed:SetAllPoints(btn)
    btn:SetPushedTexture(pushed)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetSize(24, 23)
    highlight:SetPoint("CENTER")
    btn:SetHighlightTexture(highlight)

    btn:SetScript("OnClick", function(_, mouseButton)
        if viewType == "backpack" then
            if IsShiftKeyDown() and mouseButton == "LeftButton" then
                ABP.Pack:SetTransfer("bag2bank")
                ABP.Pack:Start()
            else
                ABP.Pack:SetTransfer(nil)
                ABP.Pack:Start("bag")
            end
            return
        end
        -- 银行视图：按激活 tab 动态（旧版 buttonDefs bank/warband 两条，:40-45）
        local warband = GetActiveBankTab(view) == "warband"
        if IsShiftKeyDown() then
            local dir = warband and (mouseButton == "RightButton" and "abank2bank" or "abank2bag")
                or "bank2bag"
            ABP.Pack:SetTransfer(dir)
            ABP.Pack:Start()
        else
            ABP.Pack:SetTransfer(nil)
            ABP.Pack:Start(warband and "accountbank" or "bank")
        end
    end)
    -- tooltip 动态生成：银行 tab 切换后 OnEnter 实时读 tab，无需重挂按钮
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["BAGANATOR_LABEL"])
        if viewType == "backpack" then
            GameTooltip:AddLine(L["TIP_CLICK_SORT"] .. L["BAGANATOR_BTN_BAG"])
            GameTooltip:AddLine(L["TIP_SHIFT_LEFT"] .. L["TRANSFER_BAG2BANK"])
        elseif GetActiveBankTab(view) == "warband" then
            GameTooltip:AddLine(L["TIP_CLICK_SORT"] .. L["BAGANATOR_BTN_WARBAND"])
            GameTooltip:AddLine(L["TIP_SHIFT_LEFT"] .. L["TRANSFER_ABANK2BAG"])
            GameTooltip:AddLine(L["TIP_SHIFT_RIGHT"] .. L["TRANSFER_ABANK2BANK"])
        else
            GameTooltip:AddLine(L["TIP_CLICK_SORT"] .. L["BAGANATOR_BTN_BANK"])
            GameTooltip:AddLine(L["TIP_SHIFT_LEFT"] .. L["TRANSFER_BANK2BAG"])
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:Hide()
    return btn
end

-- Arrange() 每次都会重设 topRight 全部锚点 → 在此之后重新插入本按钮。
-- a19：显隐只由本插件开关决定，**不再跟随 Baganator sort 按钮显隐**
-- （用户 2026-11-21：Baganator 可单独设置每个按钮 show/hide/alt，把 sort 设为 hide 后
-- 本按钮曾一并消失）。照 Extra/Blizzard.lua:103-132 的解耦模式：sort 隐藏只回退锚点，
-- 不隐藏本按钮。Baganator 侧回退锚 = mgr.active.topRight[1]（当前可见链最右按钮，
-- 通常 customise，即 sort 原位置）；无可见按钮时照 Buttons.lua:125-128 锚 CloseButton。
-- Baganator 设置变更 → SettingChanged("buttons.*") → Arrange（Buttons.lua:157-161）
-- → 本 hook 重排，锚点自动适配。
local function ReflowButtons(view)
    local state = injected[view]
    if not state then return end
    local mgr = view.ButtonsManager
    if not mgr or type(mgr.GetButton) ~= "function" then return end

    local p = ABP:GetProfile()
    local enabled = p and p.external and p.external.baganatorButton
    if not enabled then
        state.btn:Hide()
        return
    end

    -- 显式设 700，与 Baganator Arrange() 给可见按钮的 FrameLevel 一致（Buttons.lua:82/113），
    -- 不再从可能隐藏的 sortBtn 取值。
    state.btn:SetFrameLevel(700)
    local active = mgr.active and mgr.active.topRight
    local sortBtn = mgr:GetButton("sort")  -- 懒创建，parent = view（Buttons.lua:55）
    local anchor = (sortBtn and sortBtn:IsShown() and sortBtn) or (active and active[1])
    state.btn:ClearAllPoints()
    if anchor then
        state.btn:SetPoint("RIGHT", anchor, "LEFT", 0, 0)
    elseif view.CloseButton then
        state.btn:SetPoint("RIGHT", view.CloseButton, "LEFT", 0, 0)
    else
        state.btn:SetPoint("TOPRIGHT", view, "TOPRIGHT", -5, 0)
    end

    -- 原左邻（transfer/swap/…）改锚到本按钮左侧：按钮链从「…→左邻→sort→customise」
    -- 变为「…→左邻→[ADE]→sort→customise」，不遮挡原生按钮；sort 隐藏时按实际 anchor 插入。
    if active then
        for i, b in ipairs(active) do
            if b == anchor then
                local left = active[i + 1]
                if left then
                    left:ClearAllPoints()
                    left:SetPoint("RIGHT", state.btn, "LEFT", 0, 0)
                end
                break
            end
        end
    end
    state.btn:Show()
end

local function InjectView(view, viewType)
    if injected[view] then return end
    local mgr = view.ButtonsManager
    if not mgr or type(mgr.GetButton) ~= "function" or type(mgr.Arrange) ~= "function" then return end
    injected[view] = { btn = CreatePackButton(view, viewType), viewType = viewType }
    hooksecurefunc(mgr, "Arrange", function() ReflowButtons(view) end)
    -- 视图可能已显示过（Arrange 早于本插件注入）→ 主动触发一次建立按钮链与锚点
    pcall(mgr.Arrange, mgr)
    ReflowButtons(view)
end

-- 视图帧在皮肤切换 / FrameGroup 切换时才创建，帧名后缀（frameGroup）不确定 → 扫描 _G 前缀。
-- 背包帧名实证 Initialize.lua:150-151；银行帧名实证 Initialize.lua:224-228（a18）。
local viewScanDefs = {
    { pattern = "^Baganator_SingleViewBackpackViewFrame",   viewType = "backpack" },
    { pattern = "^Baganator_CategoryViewBackpackViewFrame", viewType = "backpack" },
    { pattern = "^Baganator_SingleViewBankViewFrame",       viewType = "bank" },
    { pattern = "^Baganator_CategoryViewBankViewFrame",     viewType = "bank" },
}

local function InjectAll()
    local found = false
    for name, frame in pairs(_G) do
        if type(name) == "string" and type(frame) == "table" and frame.ButtonsManager then
            for _, def in ipairs(viewScanDefs) do
                if name:match(def.pattern) then
                    found = true
                    InjectView(frame, def.viewType)
                    break
                end
            end
        end
    end
    local p = ABP:GetProfile()
    if not found and not warned and p and p.external and p.external.baganatorButton then
        warned = true
        print("|cff00AAFF[ADE]|r " .. tostring(L["BAGANATOR_NOT_FOUND"] or
            "未找到 Baganator 背包/银行视图标题栏，整理按钮未注入（版本过旧？）"))
    end
end

local function RegisterAll()
    RegisterSort()

    -- 视图帧在皮肤切换 / FrameGroup 切换时才创建，回调到达后延迟重扫（幂等）；
    -- BankViewChanged = 银行 tab 切换（BankView.lua:71 SetTab 后广播）→ 重排银行视图按钮
    -- （tab 切换可能改变可见按钮链，防 Arrange 未触发的边缘情况）
    local reg = _G.Baganator and _G.Baganator.CallbackRegistry
    if reg and reg.RegisterCallback and not callbacksRegistered then
        reg:RegisterCallback("BackpackFrameChanged", function() C_Timer.After(0, InjectAll) end)
        reg:RegisterCallback("FrameGroupSwapped", function() C_Timer.After(0, InjectAll) end)
        reg:RegisterCallback("BankViewChanged", function()
            C_Timer.After(0, function()
                for view, state in pairs(injected) do
                    if state.viewType == "bank" then ReflowButtons(view) end
                end
            end)
        end)
        callbacksRegistered = true
    end

    InjectAll()
    -- Baganator 的 skin/frameGroup 初始化可能晚于其 ADDON_LOADED，延迟再扫一次
    C_Timer.After(0, InjectAll)
end

function Baganator:Init()
    if type(_G.Baganator) == "table" and _G.Baganator.API then
        RegisterAll()
        return
    end
    -- Baganator 可能晚于本插件加载 → 延迟到其 ADDON_LOADED / PLAYER_LOGIN
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(_, event, name)
        if event == "ADDON_LOADED" and name ~= "Baganator" then return end
        if type(_G.Baganator) == "table" and _G.Baganator.API then
            RegisterAll()
            f:UnregisterEvent("ADDON_LOADED")
            f:UnregisterEvent("PLAYER_LOGIN")
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
    if btnOn and next(injected) == nil then
        InjectAll()      -- 加载后开启时补注入
    end
    for view in pairs(injected) do
        if btnOn then
            ReflowButtons(view)
        else
            -- 关闭时主动重排一次：Arrange 会先把全部按钮 ClearAllPoints+Hide 再按原生链
            -- 重锚，ReflowButtons 因开关关闭直接 return → 左邻恢复紧贴 sort、不留空隙。
            local mgr = view.ButtonsManager
            if mgr and type(mgr.Arrange) == "function" then
                pcall(mgr.Arrange, mgr)
            end
            ReflowButtons(view)
        end
    end
end
