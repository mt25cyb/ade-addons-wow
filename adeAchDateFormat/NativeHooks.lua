-- adeAchDateFormat — 暴雪原生成就 UI 的日期 hook。
-- 移植自 Z_AchievementDateFormat（只读镜像），所有格式写入统一走 ADF.FormatDate。
-- 语言策略（已确认）：直接写文本的路径全语言开放；成就链接 tooltip 的中文正则仍限 zhCN。
local ADF = _G.adeAchDateFormat
if not ADF then return end
local L = ADF.L or {}
local FD = function(d, m, y) return ADF.FormatDate(d, m, y) end

local function NativeEnabled()
    return ADF.db == nil or ADF:Get("enableNative") ~= false
end

local function AchievementTemplateMixinInitHook(self, elementData)
    if not self.completed then return end
    local id, name, points, completed, month, day, year
    if self.index then
        id, name, points, completed, month, day, year = GetAchievementInfo(elementData.category, self.index)
    else
        id, name, points, completed, month, day, year = GetAchievementInfo(self.id)
    end
    local text = FD(day, month, year)
    if text and self.DateCompleted then self.DateCompleted:SetText(text) end
end

local function SetDate4ProgressiveAchievement(objectivesFrame, index, achievementID)
    local _, _, _, _, month, day, year = GetAchievementInfo(achievementID)
    if not month then return end
    local miniAchievement = objectivesFrame:GetMiniAchievement(index)
    local text = FD(day, month, year)
    if text then miniAchievement.date = text end
end

local function AchievementObjectives_DisplayProgressiveAchievement_Hook(objectivesFrame, id)
    local baseAchievementID = id
    local achievementList = {}
    tinsert(achievementList, 1, baseAchievementID)
    while GetPreviousAchievement(baseAchievementID) do
        tinsert(achievementList, 1, GetPreviousAchievement(baseAchievementID))
        baseAchievementID = GetPreviousAchievement(baseAchievementID)
    end
    for index, achievementID in ipairs(achievementList) do
        SetDate4ProgressiveAchievement(objectivesFrame, index, achievementID)
    end
end

local function SetDate4AchievementCriteria(objectivesFrame, id, i, metas)
    local _, criteriaType, completed, _, _, _, _, assetID = GetAchievementCriteriaInfo(id, i)
    if not (criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID) then return metas end
    local metas = metas + 1
    local metaCriteria = objectivesFrame:GetMeta(metas)
    local _, _, _, _, month, day, year = GetAchievementInfo(assetID)
    local text = FD(day, month, year)
    if text then metaCriteria.date = text end
    return metas
end

local function AchievementObjectives_DisplayCriteria_Hook(objectivesFrame, id)
    if not id then return end
    local numCriteria = GetAchievementNumCriteria(id)
    local requiresRep
    if not objectivesFrame.completed then requiresRep = GetAchievementGuildRep(id) end
    if numCriteria == 0 and not requiresRep then return end
    local metas = 0
    for i = 1, numCriteria do
        metas = SetDate4AchievementCriteria(objectivesFrame, id, i, metas)
    end
end

local function SetDate4AchievementSummary(button)
    if not button.id then return end
    local _, _, _, _, month, day, year = GetAchievementInfo(button.id)
    local text = FD(day, month, year)
    if text and button.DateCompleted then button.DateCompleted:SetText(text) end
end

local function AchievementFrameSummary_UpdateAchievements_Hook()
    if not AchievementFrameSummaryAchievements then return end
    for _, button in ipairs(AchievementFrameSummaryAchievements.buttons) do
        SetDate4AchievementSummary(button)
    end
end

local function AchievementComparisonTemplateMixinInitHook(self)
    local player, friend = self.Player, self.Friend
    if player and player.completed then
        local _, _, _, _, month, day, year = GetAchievementInfo(self.id)
        local text = FD(day, month, year)
        if text and player.DateCompleted then player.DateCompleted:SetText(text) end
    end
    if friend and friend.completed then
        local friendCompleted, friendMonth, friendDay, friendYear = GetAchievementComparisonInfo(self.id)
        local text = FD(friendDay, friendMonth, friendYear)
        if text and friend.Status then friend.Status:SetText(text) end
    end
end

local HookedAchievementFramePool = {}
local HookedAchievementComparisonFramePool = {}

local function HookNewAchievementFrame(view, hook4init, pool)
    if not view.factoryFrameIsNew then return end
    local frame = view.factoryFrame
    if pool then
        if pool[frame] then return end
        pool[frame] = true
    end
    hooksecurefunc(frame, "Init", hook4init)
end

local function HookScrollBoxListViewMixinFactory(view, hook4init, pool)
    local function FactoryHook()
        HookNewAchievementFrame(view, hook4init, pool)
    end
    hooksecurefunc(view, "factory", FactoryHook)
end

local function InvokeHook4PostInit(frame, initializer, hook4init)
    if not initializer then return end
    local elementData = frame:GetElementData()
    hook4init(frame, elementData)
end

local function HookScrollBoxListViewInvokeInitializer(view, hook4init)
    local function InvokeInitializerHook(_, frame, initializer)
        InvokeHook4PostInit(frame, initializer, hook4init)
    end
    hooksecurefunc(view, "InvokeInitializer", InvokeInitializerHook)
end

local nativeHooked = false
local function HookAchievementUI()
    if nativeHooked or not NativeEnabled() then return end
    if not AchievementFrameAchievements or not AchievementFrameComparison then return end
    nativeHooked = true

    HookScrollBoxListViewMixinFactory(AchievementFrameAchievements.ScrollBox.view,
        AchievementTemplateMixinInitHook, HookedAchievementFramePool)
    hooksecurefunc("AchievementObjectives_DisplayProgressiveAchievement",
        AchievementObjectives_DisplayProgressiveAchievement_Hook)
    hooksecurefunc("AchievementObjectives_DisplayCriteria", AchievementObjectives_DisplayCriteria_Hook)
    hooksecurefunc("AchievementFrameSummary_UpdateAchievements", AchievementFrameSummary_UpdateAchievements_Hook)
    HookScrollBoxListViewInvokeInitializer(AchievementFrameComparison.AchievementContainer.ScrollBox.view,
        AchievementComparisonTemplateMixinInitHook)
    ADF:Print(L.MSG_NATIVE_HOOKED or "Blizzard achievement UI date hooks installed.")
end

local AlliedRacesObjectivesFramePool = {}

local function AchievementDisplayOverviewBulletMixinOnEnterHook(self)
    local achievementID = self.achievementID
    local _, _, _, overallAchievementCompleted, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achievementID)
    local criteriaCompleted, assetID
    if self.criteriaIndex then
        _, _, criteriaCompleted, _, _, _, _, assetID = GetAchievementCriteriaInfo(self.achievementID, self.criteriaIndex)
    end
    local check = criteriaCompleted or (overallAchievementCompleted and wasEarnedByMe)
    if not check then return end
    if self.criteriaIndex and AchievementUtil.IsCriteriaAchievementEarned(achievementID, self.criteriaIndex) then
        achievementID = assetID
    end
    local _, _, _, completed, month, day, year = GetAchievementInfo(achievementID)
    if not completed then return end
    local text = FD(day, month, year)
    if not text then return end
    local str = CRITERIA_COMPLETED_DATE:format(text)
    local tooltipLine = GameTooltip.TextLeft1
    if tooltipLine then
        tooltipLine:SetText(str)
        GameTooltip:Show()
    end
end

local function AchievementDisplayMixinSetupBulletAnchoringHook(self)
    local bullet = self.lastBullet
    local pool = AlliedRacesObjectivesFramePool
    if not bullet or pool[bullet] then return end
    pool[bullet] = true
    bullet:HookScript("OnEnter", AchievementDisplayOverviewBulletMixinOnEnterHook)
end

local alliedHooked = false
local function HookAlliedRacesUI()
    if alliedHooked or not NativeEnabled() then return end
    if not AlliedRacesFrame then return end
    alliedHooked = true
    local frame = AlliedRacesFrame.RaceInfoFrame.ScrollFrame.Child.ObjectivesFrame
    hooksecurefunc(frame, "SetupBulletAnchoring", AchievementDisplayMixinSetupBulletAnchoringHook)
end

local ACHIEVEMENT_STR_PATTERN_TBL = {
    "^(.+在)(%d+)/(%d+)/(%d%d%d%d)(获得了这个成就.*)$",
    "^(.*完成于)(%d+)/(%d+)/(%d%d%d%d)(.*)$",
}

local function ProcAchievementString(str, pattern, textName)
    if not str then return false end
    local head, m, d, y, tail = string.match(str, pattern)
    local result = ADF.FormatAchievementString(head, m, d, y, tail)
    if not result then return false end
    local txt = _G[textName]
    if txt then txt:SetText(result) end
    return true
end

local function ItemRefTooltipHook(self)
    local data = self.processingInfo and self.processingInfo.tooltipData
    if not data or data.type ~= Enum.TooltipDataType.Achievement then return end
    local lines = data.lines
    local idxTbl = { 3, #lines }
    for j, i in ipairs(idxTbl) do
        if lines[i] then
            ProcAchievementString(lines[i].leftText, ACHIEVEMENT_STR_PATTERN_TBL[j], "ItemRefTooltipTextLeft" .. i)
        end
    end
end

local linkHooked = false
local function HookLinkTooltip()
    if linkHooked or not NativeEnabled() or GetLocale() ~= "zhCN" then return end
    linkHooked = true
    hooksecurefunc(ItemRefTooltip, "ProcessLines", ItemRefTooltipHook)
    ADF:Print(L.MSG_LINK_HOOKED or "achievement link tooltip hook installed.")
end

local f = CreateFrame("Frame", ADF.name .. "NativeHooksFrame")
f.XEventHandlerTbl = {}
f.XAddonHandlerTbl = {}
function f:XRegisterEventAndHandler(event, func)
    self.XEventHandlerTbl[event] = func
    self:RegisterEvent(event)
end
function f:EventHandlerForAddonLoaded(_, addOnName)
    local func = self.XAddonHandlerTbl[addOnName]
    if func then func(self) end
end
function f:XRegisterForAddonLoaded(addOnName, func)
    if not self.XEventHandlerTbl["ADDON_LOADED"] then
        self:XRegisterEventAndHandler("ADDON_LOADED", self.EventHandlerForAddonLoaded)
    end
    self.XAddonHandlerTbl[addOnName] = func
end
function f:XHandleEvent(event, ...)
    local func = self.XEventHandlerTbl[event]
    if func then func(self, event, ...) end
end
f:SetScript("OnEvent", f.XHandleEvent)
f:XRegisterForAddonLoaded("Blizzard_AchievementUI", HookAchievementUI)
f:XRegisterForAddonLoaded("Blizzard_AlliedRacesUI", HookAlliedRacesUI)
f:XRegisterEventAndHandler("PLAYER_LOGIN", HookLinkTooltip)

--- 设置变更后的即时重绘：能直接拿到的可见行才重跑，隐藏模块等待下次原生刷新。
local function RefreshVisible()
    if not NativeEnabled() then return end
    pcall(function()
        local scrollBox = AchievementFrameAchievements and AchievementFrameAchievements.ScrollBox
        if scrollBox and scrollBox.GetFrames then
            for _, frame in ipairs(scrollBox:GetFrames()) do
                if frame.Init then AchievementTemplateMixinInitHook(frame, frame:GetElementData()) end
            end
        end
    end)
    pcall(AchievementFrameSummary_UpdateAchievements_Hook)
    pcall(function()
        local scrollBox = AchievementFrameComparison and AchievementFrameComparison.AchievementContainer
            and AchievementFrameComparison.AchievementContainer.ScrollBox
        if scrollBox and scrollBox.GetFrames then
            for _, frame in ipairs(scrollBox:GetFrames()) do
                if frame.Init then AchievementComparisonTemplateMixinInitHook(frame) end
            end
        end
    end)
end
ADF.RegisterRefresh(RefreshVisible)
