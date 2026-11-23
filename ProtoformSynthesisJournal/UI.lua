local addonName, ns = ...
local L = ns

local psj = ProtoformSynthesisJournal
local minimapButton = ProtoformSynthesisJournalMinimapButton

function psj.PanelTabs:UpdateTab(tab)
    tab.properties = psj.tabProperties[tab.isActive and "active" or "inactive"]
    tab.Highlight:SetPoint(unpack(tab.properties.highlightTopLeft))
    tab.Highlight:SetPoint(unpack(tab.properties.highlightBottomRight))
    tab.Highlight:SetTexCoord(unpack(tab.properties.highlightTexCoord))
    tab.Text:SetPoint(unpack(tab.properties.textCenter))
    tab.Text:SetTextColor(unpack(tab.properties.textColor))
    tab.Left:SetTexCoord(unpack(tab.properties.leftTexCoord))
    tab.Right:SetTexCoord(unpack(tab.properties.rightTexCoord))
    tab.Middle:SetTexCoord(unpack(tab.properties.midTexCoord))
end

function psj.PanelTabs:OnClick()
    for _, tab in ipairs(psj.PanelTabs.Tabs) do
        tab.isActive = tab == self
    end
    psj.settings.activeTab = self:GetID()
    psj:Update()
    psj.List:ScrollToIndex(1)
end

function psj:FillSettingsButton(info)
    self.Text:SetText(info.text)
    self.CheckButton:SetShown(info.var and true)
    if info.var then
        self.Text:SetTextColor(1, 0.82, 0)
        self.Text:SetPoint("LEFT", 30, 0)
        self.CheckButton:SetHitRectInsets(-2, -self:GetWidth() + 28, -8, -8)
        self.CheckButton.var = info.var
        self.CheckButton:SetChecked(psj.settings[info.var] and true)
    else
        self.Text:SetTextColor(info.isHeader and 0.5 or 0.65, info.isHeader and 0.75 or 0.65, info.isHeader and 1 or 0.65)
        self.Text:SetPoint("LEFT", 6, 0)
        self.CheckButton.var = nil
    end
    if psj:IsMouseOverRegion(self.CheckButton) then
        self.CheckButton:GetScript("OnEnter")(self.CheckButton)
    end
end

function psj:SettingsCheckButtonOnClick()
    if self.var then
        psj.settings[self.var] = not psj.settings[self.var]
        if self.var == "showMinimapButton" then
            minimapButton:Update()
        else
            psj:Update()
        end
    end
end

function psj:FillListButton(itemID)
    local info = psj.data[psj.settings.activeTab][itemID]
    local enableMouse = psj.settings.showReagentTooltips and true
    local isUnknown = info.isUnknown
    self.itemID = itemID
    self.speciesID = info.speciesID
    self.mountID = info.mountID
    self.MoteButton.reagentID = 188957
    self.GlimmerButton.reagentID = info.glimmerID
    self.LatticeButton.reagentID = info.latticeID
    self.MoteButton.guideLabel = L["Mote source"]
    self.GlimmerButton.guideLabel = L["Rare reagent source"]
    self.LatticeButton.guideLabel = L["Lattice source"]
    local schematicGuide = ns.Guides.SCHEMATICS[itemID]
    self.PinButton.entry = schematicGuide
    self.PinButton:SetShown(ns.Guides.HasPin(schematicGuide))
    self.MoteButton.Pin.entry = ns.Guides.MATERIALS[188957]
    self.GlimmerButton.Pin.entry = ns.Guides.MATERIALS[info.glimmerID]
    self.LatticeButton.Pin.entry = ns.Guides.MATERIALS[info.latticeID]
    self.MoteButton.Pin:SetShown(ns.Guides.HasPin(self.MoteButton.Pin.entry))
    self.GlimmerButton.Pin:SetShown(ns.Guides.HasPin(self.GlimmerButton.Pin.entry))
    self.LatticeButton.Pin:SetShown(ns.Guides.HasPin(self.LatticeButton.Pin.entry))
    self.MoteButton:EnableMouse(enableMouse)
    self.GlimmerButton:EnableMouse(enableMouse)
    self.LatticeButton:EnableMouse(enableMouse)

    self.Icon:SetTexture(info.icon)
    self.Name:SetText(info.nameText)
    self.MoteButton.Text:SetText(info.moteText)
    self.GlimmerButton.Icon:SetTexture(info.glimmerIcon)
    self.GlimmerButton.Text:SetText(info.glimmerText)
    self.LatticeButton.Icon:SetTexture(info.latticeIcon)
    self.LatticeButton.Text:SetText(info.latticeText)

    self.Icon:SetDesaturated(isUnknown)
    self.MoteButton.Icon:SetDesaturated(isUnknown)
    self.GlimmerButton.Icon:SetDesaturated(isUnknown)
    self.LatticeButton.Icon:SetDesaturated(isUnknown)
    self.MoteButton.Border:SetDesaturated(isUnknown)
    self.GlimmerButton.Border:SetDesaturated(isUnknown)
    self.LatticeButton.Border:SetDesaturated(isUnknown)
    self.Name:SetTextColor(psj:GetButtonTextColor(isUnknown))
    self.MoteButton.Text:SetTextColor(psj:GetButtonTextColor(isUnknown, info.moteCount, info.moteCost))
    self.GlimmerButton.Text:SetTextColor(psj:GetButtonTextColor(isUnknown, info.glimmerCount, 1))
    self.LatticeButton.Text:SetTextColor(psj:GetButtonTextColor(isUnknown, info.latticeCount, 1))

    self.Name:SetWidth(psj.maxNameWidth + psj.padding)
    if psj.alignReagents then
        self.MoteButton:SetWidth(psj.maxMoteWidth + 38 + psj.padding)
        self.GlimmerButton:SetWidth(psj.maxGlimmerWidth + 38 + psj.padding)
        self.LatticeButton:SetWidth(psj.maxLatticeWidth + 38 + psj.padding)
    else
        self.MoteButton:SetWidth(info.moteWidth + 38)
        self.GlimmerButton:SetWidth(info.glimmerWidth + 38)
        self.LatticeButton:SetWidth(info.latticeWidth + 38)
    end

    self.MoteButton:ClearAllPoints()
    if psj.wideMode then
        self.Icon:SetSize(18, 18)
        self.IconMask:SetSize(18, 18)
        self.Name:SetPoint("LEFT", 26, 0)
        self.MoteButton:SetPoint("LEFT", self.Name, "RIGHT", 4, 0)
    else
        self.Icon:SetSize(42, 42)
        self.IconMask:SetSize(42, 42)
        self.Name:SetPoint("LEFT", 48, 9)
        self.MoteButton:SetPoint("BOTTOMLEFT", 48, 7)
    end
    if psj:IsMouseOverRegion(self) then
        self:GetScript("OnEnter")(self)
    end
end

function psj:UpdateMaxWidth(element, text)
    if not text then
        return 0
    end
    local fontString = element == "maxNameWidth" and self.HiddenNameFontString or self.HiddenReagentFontString
    fontString:SetText(text)
    local width = fontString:GetStringWidth()
    self[element] = max(self[element], width)
    return width
end

function psj:GetButtonTextColor(unknown, count, minCount)
    if unknown then
        return 0.5, 0.5, 0.5
    elseif not count then
        return 1, 0.82, 0
    elseif minCount and count >= minCount then
        return 0.9, 0.9, 0.9
    end
    return 0.5, 0.5, 0.5
end

function psj:GetButtonHeight()
    return psj.wideMode and 24 or 48
end

function psj:GetTooltipAnchor()
    local fx = psj:GetCenter() * psj:GetEffectiveScale()
    local ux = UIParent:GetCenter() * UIParent:GetEffectiveScale()
    return fx < ux and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
end

function psj:PinButtonOnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Pin this location"])
    local entry = self.entry
    if ns.Guides.HasPin(entry) then
        GameTooltip:AddLine(format(L["Location: %.1f, %.1f"], entry.x, entry.y), 0.6, 0.75, 1)
    else
        GameTooltip:AddLine(L["No map pin available"], 0.5, 0.5, 0.5)
    end
    GameTooltip:Show()
end

function psj:PinButtonOnClick()
    local entry = self.entry
    if not ns.Guides.HasPin(entry) then
        return
    end
    local mapID = ns.Guides.MAP_ID
    if C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, entry.x / 100, entry.y / 100))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
end

function psj:AppendGuide(entry, label)
    local text = ns.Guides.Get(entry)
    if not text then
        return
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(label, 1, 0.82, 0)
    GameTooltip:AddLine(text, 0.85, 0.85, 0.85, true)
    if ns.Guides.HasPin(entry) then
        GameTooltip:AddLine(format(L["Location: %.1f, %.1f"], entry.x, entry.y), 0.6, 0.75, 1)
    end
end

function psj:ListButtonOnEnter()
    self:SetBackdropBorderColor(0, 0.75, 1)
    if IsModifiedClick("DRESSUP") then
        ShowInspectCursor()
    else
        ResetCursor()
    end
    if self.itemID then
        GameTooltip:SetOwner(self, psj:GetTooltipAnchor())
        GameTooltip:SetItemByID(self.itemID)
        psj:AppendGuide(ns.Guides.SCHEMATICS[self.itemID], L["Schematic source"])
        GameTooltip:Show()
    end
end

function psj:ListButtonOnLeave()
    self:SetBackdropBorderColor(0.3, 0.3, 0.3)
    ResetCursor()
    GameTooltip:Hide()
end

function psj:ListButtonOnClick()
    if not IsModifiedClick("DRESSUP") then
        return
    end
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_AFFECTING_COMBAT, 1, 0, 0)
    elseif self.speciesID then
        local petInfo = {C_PetJournal.GetPetInfoBySpeciesID(self.speciesID)}
        DressUpBattlePet(petInfo[4], petInfo[12], self.speciesID)
    elseif self.mountID then
        DressUpMount(self.mountID)
    end
end

function psj:ReagentButtonOnEnter()
    if not self.reagentID then
        return
    end
    GameTooltip:SetOwner(self:GetParent(), psj:GetTooltipAnchor())
    GameTooltip:SetItemByID(self.reagentID)
    psj:AppendGuide(ns.Guides.MATERIALS[self.reagentID], self.guideLabel)
    if C_AddOns.IsAddOnLoaded("Stash") and _stash and _stash.tooltips and _stash.tooltips.AddLocationsToAnyTooltip then
        _stash.tooltips:AddLocationsToAnyTooltip(GameTooltip, self.reagentID)
    end
    GameTooltip:Show()
    self.Highlight:Show()
    self:GetParent():SetBackdropBorderColor(0, 0.75, 1)
end

function psj:ReagentButtonOnLeave()
    GameTooltip:Hide()
    self.Highlight:Hide()
    self:GetParent():SetBackdropBorderColor(0.3, 0.3, 0.3)
end

function psj:OnMouseDown()
    if not psj.settings.lockWindowPosition or IsShiftKeyDown() then
        self:StartMoving()
    end
end

function psj:OnMouseUp()
    self:StopMovingOrSizing()
    psj.settings.windowXPos = self:GetLeft()
    psj.settings.windowYPos = self:GetBottom()
    psj.settings.windowWidth = self:GetWidth()
    psj.settings.windowHeight = self:GetHeight()
end

function minimapButton:Update()
    local angle = psj.settings.minimapPosition or 160
    self:SetPoint("CENTER", Minimap, "CENTER", 105 * cos(angle), 105 * sin(angle))
    self:SetShown(psj.settings.showMinimapButton and true)
end

function minimapButton:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["Protoform Synthesis Journal"])
    GameTooltip:Show()
end

function minimapButton:OnLeave()
    GameTooltip:Hide()
end

function minimapButton:OnMouseDown()
    self.Icon:SetPoint("CENTER", -1, -2)
    self.Icon:SetVertexColor(0.65, 0.65, 0.65)
end

function minimapButton:OnMouseUp()
    self.Icon:SetPoint("CENTER")
    self.Icon:SetVertexColor(1, 1, 1)
end

function minimapButton:OnClick()
    psj:Toggle()
end

function minimapButton:OnDragStart()
    self:SetScript("OnUpdate", self.OnDragUpdate)
end

function minimapButton:OnDragStop()
    self:OnMouseUp()
    self:SetScript("OnUpdate", nil)
end

function minimapButton:OnDragUpdate()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local minX, minY = Minimap:GetCenter()
    psj.settings.minimapPosition = math.deg(math.atan2(y / scale - minY, x / scale - minX))
    self:Update()
end
