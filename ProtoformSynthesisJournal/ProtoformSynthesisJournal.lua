local addonName, ns = ...
local L = ns

local psj = ProtoformSynthesisJournal
local minimapButton = ProtoformSynthesisJournalMinimapButton
local settings

ProtoformSynthesisJournalSettings = {}

BINDING_HEADER_PROTOFORMSYNTHESISJOURNAL = L["Protoform Synthesis Journal"]
BINDING_NAME_PROTOFORMSYNTHESISJOURNAL_TOGGLE = L["Toggle Protoform Synthesis Journal"]

SLASH_PROTOFORMSYNTHESISJOURNAL1 = "/psj"
SLASH_PROTOFORMSYNTHESISJOURNAL2 = "/psfj"
SlashCmdList["PROTOFORMSYNTHESISJOURNAL"] = function() psj:Toggle() end

psj.tabProperties = ns.Data.tabProperties
psj.data = ns.Data.data
psj.settingsList = ns.Data.settingsList
psj.list = ns.Data.list

function psj:IsMouseOverRegion(region)
    return RegionUtil.IsAnyDescendantOfOrSame(GetMouseFoci(), region)
end

function psj:Toggle()
    psj:SetShown(not psj:IsShown())
end
ProtoformSynthesisJournalToggleWindow = psj.Toggle

function psj:Update()
    psj:UpdateTabs()
    psj.Settings:SetShown(settings.activeTab == 3)
    psj.List:SetShown(settings.activeTab ~= 3)
    psj:PopulateList()
    psj.List:Update()
    if settings.activeTab == 3 then
        psj.Settings:Update()
    end
    psj.ResizeGrip:SetShown(not settings.lockWindowSize)
end

function psj:PLAYER_LOGIN()
    settings = ProtoformSynthesisJournalSettings
    psj.settings = settings

    self.TitleText:SetText(L["Protoform Synthesis Journal"])
    self.TitleText:SetPoint("TOP", -6, -5)
    self:SetResizeBounds(330, 196, 1024, 768)
    if self:GetWidth() < 330 then
        self:SetWidth(330)
    end

    self.List.template = "ProtoformSynthesisJournalListTemplate"
    self.List.callback = self.FillListButton
    self.List.preUpdateFunc = self.GatherButtonData
    self.List.dynamicButtonHeight = self.GetButtonHeight
    self.List.list = self.list

    self.Settings.template = "ProtoformSynthesisJournalSettingsTemplate"
    self.Settings.callback = self.FillSettingsButton
    self.Settings.list = self.settingsList

    self.CloseButton:SetScript("OnKeyDown", function(self, key)
        if (key == GetBindingKey("TOGGLEGAMEMENU") and not DressUpFrame:IsVisible()) or InCombatLockdown() then
            if not InCombatLockdown() then
                self:SetPropagateKeyboardInput(false)
            end
            psj:Toggle()
        elseif not InCombatLockdown() then
            self:SetPropagateKeyboardInput(true)
        end
    end)

    if not settings.activeTab or type(settings.activeTab) ~= "number" or settings.activeTab < 1 or settings.activeTab > #self.PanelTabs.Tabs then
        settings.activeTab = 1
    end
    self.PanelTabs.Tabs[settings.activeTab].isActive = true
    self.PanelTabs.PetTab.Text:SetText(L["Pets"])
    self.PanelTabs.MountTab.Text:SetText(L["Mounts"])
    self.PanelTabs.SettingsTab.Text:SetText(L["Settings"])
    self:UpdateTabs()

    local ldb = LibStub and LibStub.GetLibrary and LibStub:GetLibrary("LibDataBroker-1.1", true)
    if ldb then
        ldb:NewDataObject(addonName, {type="launcher", icon="Interface\\Icons\\inv_progenitor_protoformsynthesis", tooltiptext=L["Protoform Synthesis Journal"], OnClick=psj.Toggle})
    end

    minimapButton:Update()
end

function psj:BAG_UPDATE_DELAYED()
    psj:Update()
end
psj.QUEST_TURNED_IN = psj.BAG_UPDATE_DELAYED
psj.QUEST_LOG_UPDATE = psj.BAG_UPDATE_DELAYED
psj.PLAYERBANKSLOTS_CHANGED = psj.BAG_UPDATE_DELAYED
psj.PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = psj.BAG_UPDATE_DELAYED

function psj:MODIFIER_STATE_CHANGED()
    if settings.activeTab ~= 3 and psj:IsMouseOverRegion(self.List) then
        for _, button in ipairs(self.List.ScrollFrame.Buttons) do
            if psj:IsMouseOverRegion(button) then
                if IsModifiedClick("DRESSUP") then
                    ShowInspectCursor()
                else
                    ResetCursor()
                end
                return
            end
        end
    end
end

function psj:UpdateTabs()
    for _, tab in ipairs(self.PanelTabs.Tabs) do
        self.PanelTabs:UpdateTab(tab)
    end
end

function psj:PopulateList()
    local list = psj.list
    wipe(list)
    local tab = psj.data[settings.activeTab]
    if not tab then
        return
    end
    for itemID, info in pairs(tab) do
        local isUnknown = psj:IsSchematicUnknown(itemID)
        local skip = (info.speciesID and settings.hideCollectedPets and psj:IsInJournal(itemID))
            or (info.mountID and settings.hideCollectedMounts and psj:IsInJournal(itemID))
            or (info.speciesID and settings.hideUnknownPetSchematics and isUnknown)
            or (info.mountID and settings.hideUnknownMountSchematics and isUnknown)
        if not skip then
            info.isUnknown = isUnknown
            tinsert(list, itemID)
        end
    end
    table.sort(list, psj.SortList)
end

function psj.SortList(e1, e2)
    local info1, info2 = psj.data[settings.activeTab][e1], psj.data[settings.activeTab][e2]
    if info1 and not info2 then
        return true
    elseif not info1 and info2 then
        return false
    end
    if info1.isUnknown ~= info2.isUnknown then
        return not info1.isUnknown
    end
    if info1.itemName ~= info2.itemName then
        if info1.itemName and not info2.itemName then
            return true
        elseif not info1.itemName and info2.itemName then
            return false
        end
        return info1.itemName < info2.itemName
    end
    return e1 < e2
end

function psj:GatherButtonData()
    local notCached, needsSorted = false, false
    psj.maxNameWidth, psj.maxMoteWidth, psj.maxGlimmerWidth, psj.maxLatticeWidth = 0, 0, 0, 0

    for itemID, info in pairs(psj.data[settings.activeTab]) do
        if not info.itemName then
            info.itemName = C_Item.GetItemInfo(itemID)
            if info.itemName then
                needsSorted = true
            else
                notCached = true
            end
        end
        if not info.glimmerName then
            info.glimmerName = C_Item.GetItemInfo(info.glimmerID)
            notCached = notCached or not info.glimmerName
        end
        if not info.latticeName then
            info.latticeName = C_Item.GetItemInfo(info.latticeID)
            notCached = notCached or not info.latticeName
        end
        if not info.icon then
            info.icon = select(5, C_Item.GetItemInfoInstant(itemID))
        end
        if not info.glimmerIcon then
            info.glimmerIcon = select(5, C_Item.GetItemInfoInstant(info.glimmerID))
        end
        if not info.latticeIcon then
            info.latticeIcon = select(5, C_Item.GetItemInfoInstant(info.latticeID))
        end

        info.moteCount = psj:GetItemCount(188957)
        info.glimmerCount = psj:GetItemCount(info.glimmerID)
        info.latticeCount = psj:GetItemCount(info.latticeID)
        info.numCraftable = min(floor(info.moteCount / info.moteCost), info.glimmerCount, info.latticeCount)

        info.nameText = info.itemName or ""
        if info.numCraftable > 0 then
            info.nameText = info.nameText .. (info.isUnknown and "" or "\124cffe0e0e0") .. format(" [%d]", info.numCraftable)
        end
        if psj:IsInJournal(itemID) then
            info.nameText = info.nameText .. (info.isUnknown
                and " \124TInterface\\AddOns\\ProtoformSynthesisJournal\\assets\\owned-unknown:0\124t"
                or " \124TInterface\\AddOns\\ProtoformSynthesisJournal\\assets\\owned-known:0\124t")
        end

        info.moteText = format("%d/%d ", info.moteCount, info.moteCost)
        info.glimmerText = format("%d/1 %s", info.glimmerCount, info.glimmerName or "")
        info.latticeText = format("%d/1 %s", info.latticeCount, info.latticeName or "")

        info.nameWidth = psj:UpdateMaxWidth("maxNameWidth", info.nameText)
        info.moteWidth = psj:UpdateMaxWidth("maxMoteWidth", info.moteText)
        info.glimmerWidth = psj:UpdateMaxWidth("maxGlimmerWidth", info.glimmerText)
        info.latticeWidth = psj:UpdateMaxWidth("maxLatticeWidth", info.latticeText)
    end

    local frameWidth = psj:GetWidth()
    local reagentWidth = psj.maxMoteWidth + psj.maxGlimmerWidth + psj.maxLatticeWidth
    psj.alignReagents = (frameWidth - reagentWidth) > 163
    psj.wideMode = (frameWidth - reagentWidth - psj.maxNameWidth) > 148
    local paddingBase = psj.wideMode and (frameWidth - psj.maxNameWidth - reagentWidth - 148) or (frameWidth - reagentWidth - 163)
    psj.padding = max(0, paddingBase / (psj.wideMode and 4 or 3))

    if notCached then
        C_Timer.After(0.5, psj.Update)
    elseif needsSorted then
        table.sort(psj.list, psj.SortList)
    end
end

function psj:GetItemCount(itemID)
    return C_Item.GetItemCount(itemID, true, true, true, true)
end

function psj:IsInJournal(itemID)
    if psj.data[1][itemID] then
        local speciesID = psj.data[1][itemID].speciesID
        return speciesID and C_PetJournal.GetNumCollectedInfo(speciesID) > 0
    elseif psj.data[2][itemID] then
        local mountID = psj.data[2][itemID].mountID
        return mountID and select(11, C_MountJournal.GetMountInfoByID(mountID))
    end
end

function psj:IsSchematicUnknown(itemID)
    for i = 1, 2 do
        local info = psj.data[i][itemID]
        if info then
            if info.achievementID and not select(13, GetAchievementInfo(info.achievementID)) then
                return true
            elseif info.questID and not C_QuestLog.IsQuestFlaggedCompleted(info.questID) then
                return true
            end
            return false
        end
    end
end

function psj:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function psj:OnShow()
    if settings.shareWindowPosition then
        if settings.windowXPos and settings.windowYPos then
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", settings.windowXPos, settings.windowYPos)
        end
        if settings.windowWidth and settings.windowHeight then
            self:SetSize(settings.windowWidth, settings.windowHeight)
        end
    end
    self:Update()
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    self:RegisterEvent("QUEST_TURNED_IN")
    self:RegisterEvent("QUEST_LOG_UPDATE")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
end

function psj:OnHide()
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    self:UnregisterEvent("QUEST_TURNED_IN")
    self:UnregisterEvent("QUEST_LOG_UPDATE")
    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
end
