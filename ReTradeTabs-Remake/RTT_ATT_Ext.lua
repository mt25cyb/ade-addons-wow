-- ReTradeTabs-Remake: ATT extension (RTT_ATT_Ext.lua)
--
-- AllTheThings integration:
--   * ATT creates its profession tab (app.TradeskillTab, template AllTheThings_Tab ->
--     QuestLogTabButtonTemplate) inside the shared side bar ProfessionsFrameTabSideBar
--     the FIRST time a professions window opens (not at login).
--   * When ATT's attached window (ATTWindowTradeskills) opens, ATT moves the whole side
--     bar next to its window; when it closes, the bar moves back to ProfessionsFrame.
--     Our tabs are parented to that side bar, so the right-shift follow is automatic.
--   * What this extension has to do: detect when the ATT tab appears, then re-anchor
--     our tabs below it (ReTradeTabs.lua handles the anchoring on rebuild).

local frame = CreateFrame("Frame", "ReTradeTabsRemakeATTExtFrame")

local attTabSeen = false

local function GetATTTab()
	local sidebar = ProfessionsFrameTabSideBar
	if not sidebar or not sidebar.Tabs then
		return nil
	end
	local first = sidebar.Tabs[1]
	-- whatever sits in Tabs[1] that is not one of our tabs is the ATT tab
	if first and ReTradeTabsRemakeAPI and not ReTradeTabsRemakeAPI.IsOwnTab(first) then
		return first
	end
	return nil
end

local function CheckATT()
	local seen = GetATTTab() ~= nil
	if seen ~= attTabSeen then
		attTabSeen = seen
		-- ATT tab appeared/disappeared -> re-anchor our tabs (below it / to the bar top)
		if ReTradeTabsRemakeAPI then
			ReTradeTabsRemakeAPI.ForceRebuild()
		end
	end
end

frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		CheckATT()
	elseif event == "TRADE_SKILL_SHOW" then
		-- ATT creates its tab inside its own TRADE_SKILL_SHOW handler; event handler
		-- order between addons is not guaranteed, so check again after a short delay.
		C_Timer.After(0.3, CheckATT)
	elseif event == "SKILL_LINES_CHANGED" then
		-- ATT (forever mode) re-anchors tabs on this event as well
		C_Timer.After(0.3, CheckATT)
	end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("SKILL_LINES_CHANGED")
