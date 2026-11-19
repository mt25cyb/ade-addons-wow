local _, addon = ...
local L = addon.L
-- 地基（Tab / 内容框架 / 设置页骨架 / 生命周期）统一走主插件公共函数库。
local MapTab = LibStub("AdeMapTab-1.0")

-- 世界地图界面。阅读顺序：刷新队列 -> 传送操作 -> 面板/按钮 -> 列表布局 -> 页签与事件。
local f = CreateFrame("Frame")
-- v5 目录改名，两张 Tab 状态材质随子插件一同复制，视觉与 v4 一致（开发计划 D10）。
local ICON_ACTIVE = "Interface\\AddOns\\adeMapTab_Portal\\Art\\teleport_active.tga"
local ICON_INACTIVE = "Interface\\AddOns\\adeMapTab_Portal\\Art\\teleport_inactive.tga"

-- 整块面板在「列表」与「设置」之间切换（WorldQuestTab 的做法）。
local currentMode = "list" -- "list" | "settings"
local settingsFrame

-- 默认标签页：只有开启设置时才自动选中，命令与按键始终显式打开。
-- 同一 LibWorldMapTabs 实例被多个插件共用，WorldQuestTab 也提供同名功能，因此这里检测并让位。
-- 判定逻辑已抽到主插件公共函数库，两个子插件共用同一份实现。
local function IsDefaultTabClaimedByOthers()
    return MapTab.IsDefaultTabClaimed()
end

--- 供设置菜单判断默认标签页是否已被其他插件占用。
function addon.MapPanel.IsDefaultTabClaimed()
    return IsDefaultTabClaimedByOthers()
end

local function ShouldAutoSelectDefaultTab()
    return addon.db and addon.db.defaultTab == true and not IsDefaultTabClaimedByOthers() or false
end

local function GetPlayerMapID()
	if C_Map and C_Map.GetBestMapForUnit then return C_Map.GetBestMapForUnit("player") end
	return nil
end

-- Cache some frequently used API
local FirstOwnedItemID
do
	local GetItemCountFn = C_Item.GetItemCount
	function FirstOwnedItemID(itemID)
		if type(itemID) == "table" then
			for _, id in ipairs(itemID) do
				if GetItemCountFn(id) > 0 then return id end
			end
			return itemID[1]
		end
		return itemID
	end
end

local function IsToyUsable(id)
	if not id or not PlayerHasToy(id) then return false end
	local tips = C_TooltipInfo.GetToyByItemID(id)
	if not tips or not tips.lines then return true end
	for _, line in pairs(tips.lines) do
		if line.type == 23 then -- requirement text; white = usable
			local c = line.leftColor
			if c and c.r == 1 and c.g == 1 and c.b == 1 then return true end
			return false
		end
	end
	return true
end

local spellEntriesCache
local spellEntriesCacheTime = 0
local compendiumCacheDirty = true
local refreshQueued = false
local queuedFullRefresh = false
local queuedCooldownRefresh = false
local queuedInvalidateCache = false
local COMPENDIUM_CACHE_TTL = 1
local restrictionStateEnum = Enum and Enum.AddOnRestrictionState
local RESTRICTION_STATE_INACTIVE = restrictionStateEnum and restrictionStateEnum.Inactive or 0
local RESTRICTION_STATE_ACTIVATING = restrictionStateEnum and restrictionStateEnum.Activating or 1
local RESTRICTION_STATE_ACTIVE = restrictionStateEnum and restrictionStateEnum.Active or 2
local RESTRICTION_TYPE_MAP = Enum and Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.Map or 4

local function isCacheExpired(cachedAt)
	if not cachedAt or cachedAt <= 0 then return true end
	local now = GetTime and GetTime() or 0
	if now <= 0 then return false end
	return (now - cachedAt) > COMPENDIUM_CACHE_TTL
end

local function InvalidateCompendiumCache()
	spellEntriesCache = nil
	spellEntriesCacheTime = 0
	compendiumCacheDirty = true
	if addon and addon.Catalog.InvalidateCaches then
		addon.Catalog.InvalidateCaches()
	end
end

local function BuildSpellEntries()
	if not addon.Catalog then return {} end
	if not addon.Catalog.BuildSections then return {} end
	if compendiumCacheDirty or not spellEntriesCache or isCacheExpired(spellEntriesCacheTime) then
		spellEntriesCache = addon.Catalog.BuildSections() or {}
		spellEntriesCacheTime = GetTime and GetTime() or 0
	end
	compendiumCacheDirty = false
	return spellEntriesCache
end

-- 刷新队列：合并短时间内的请求；冷却更新不重建按钮，战斗中延后处理。
local function QueuePanelRefresh(opts)
	opts = opts or {}
	local delay = opts.delay or 0.05

	if opts.invalidate then queuedInvalidateCache = true end
	if opts.cooldownOnly then
		if not queuedFullRefresh then queuedCooldownRefresh = true end
	else
		queuedFullRefresh = true
		queuedCooldownRefresh = false
	end

	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(delay, function()
		refreshQueued = false
		local doFullRefresh = queuedFullRefresh
		local doCooldownRefresh = queuedCooldownRefresh and not doFullRefresh
		local doInvalidate = queuedInvalidateCache

		queuedFullRefresh = false
		queuedCooldownRefresh = false
		queuedInvalidateCache = false

		if doInvalidate then InvalidateCompendiumCache() end
		if not addon.db or not addon.db["teleportsWorldMapEnabled"] then return end
		if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

		if doCooldownRefresh then
			f:UpdateCooldowns()
		else
			f:RefreshPanel()
		end
	end)
end

local function IsConsolePortLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("ConsolePort") or C_AddOns.IsAddOnLoaded("ConsolePort_Cursor") end
	if IsAddOnLoaded then return IsAddOnLoaded("ConsolePort") or IsAddOnLoaded("ConsolePort_Cursor") end
	return false
end

local function AddVariantTooltipLine(entry)
	if not entry or not entry.variantOtherCount or entry.variantOtherCount <= 0 then return end
	local fmt = L["teleportOtherVariants"] or "%d other variants available"
	GameTooltip:AddLine(string.format(fmt, entry.variantOtherCount), 0.7, 0.7, 0.7, true)
end

-- Re-equip support for teleport items that temporarily replace worn gear.
-- 装备型传送物品：使用前临时装备，施法成功或切图后恢复原装备。
local pendingReequipSlots = {}
local pendingReequipSpellIDs = {}
local pendingReequipExpireAt = 0
local REEQUIP_TIMEOUT_SECONDS = 60

local function clearTable(tbl)
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

local function clearPendingReequipState()
	clearTable(pendingReequipSlots)
	clearTable(pendingReequipSpellIDs)
	pendingReequipExpireAt = 0
end

local function hasPendingReequip() return next(pendingReequipSlots) ~= nil end

local function queueReequipRestore(slot, equippedItemID, teleportItemID, spellID)
	if not slot or not teleportItemID then return end
	if equippedItemID == teleportItemID then return end

	pendingReequipSlots[slot] = {
		restoreItemID = equippedItemID or 0,
		teleportItemID = teleportItemID,
	}
	if spellID then pendingReequipSpellIDs[spellID] = true end
	pendingReequipExpireAt = (GetTime and GetTime() or 0) + REEQUIP_TIMEOUT_SECONDS
end

local function isPendingReequipSpell(spellID) return spellID and pendingReequipSpellIDs[spellID] == true end

local function moveItemFromSlotToBag(slot)
	if not slot then return end
	if not (PickupInventoryItem and PutItemInBackpack) then return end
	PickupInventoryItem(slot)
	PutItemInBackpack()
	if ClearCursor then ClearCursor() end
end

local function tryRestorePendingReequip()
	if not hasPendingReequip() then return end
	if InCombatLockdown and InCombatLockdown() then return end

	local now = GetTime and GetTime() or 0
	if pendingReequipExpireAt > 0 and now > pendingReequipExpireAt then
		clearPendingReequipState()
		return
	end

	for slot, state in pairs(pendingReequipSlots) do
		local restoreItemID = state and state.restoreItemID or 0
		local currentID = GetInventoryItemID("player", slot)
		if restoreItemID > 0 then
			if currentID ~= restoreItemID then C_Item.EquipItemByName(restoreItemID, slot) end
		else
			if currentID and currentID ~= 0 then moveItemFromSlotToBag(slot) end
		end
	end

	for slot, state in pairs(pendingReequipSlots) do
		local restoreItemID = state and state.restoreItemID or 0
		local currentID = GetInventoryItemID("player", slot)
		local restored = false
		if restoreItemID > 0 then
			restored = (currentID == restoreItemID)
		else
			restored = (not currentID or currentID == 0)
		end
		if restored then pendingReequipSlots[slot] = nil end
	end

	if not hasPendingReequip() then clearPendingReequipState() end
end

-- 统一配置法术、玩具和物品的左键行为；右键用于定位或重新选择炉石。
-- 宠物召唤/解散：左键召唤、右键解散（移植自 AstralGate）。宠物召唤需在非战斗且非按下阶段执行。
local function HandlePetClick(entry, btn, down)
	if down or InCombatLockdown() then return end
	local active = C_PetJournal.GetSummonedPetGUID()
	if btn == "LeftButton" then
		-- 已召唤该宠物则不做重复操作；否则按物种名找到已拥有的 GUID 召唤。
		if active and C_PetJournal.GetPetInfoByPetID(active) == entry.petSpeciesID then return end
		local name = C_PetJournal.GetPetInfoBySpeciesID(entry.petSpeciesID)
		local speciesID, guid = C_PetJournal.FindPetIDByName(name or entry.text)
		if speciesID == entry.petSpeciesID and type(guid) == "string" then
			C_PetJournal.SummonPetByGUID(guid)
		end
	elseif btn == "RightButton" then
		-- 仅在该宠物正被召唤时，再次召唤即解散。
		if active and C_PetJournal.GetPetInfoByPetID(active) == entry.petSpeciesID then
			C_PetJournal.SummonPetByGUID(active)
		end
	end
end

local function ConfigureButtonTeleportAction(button, entry)
	button.itemID = nil
	button.equipSlot = nil
	button:SetScript("PreClick", nil)

	-- 宠物：左键/右键交给 HandlePetClick 处理，不设置任何安全施法属性。
	if entry.petSpeciesID then return end

	-- 家宅：左键动作不在这里写死，交给 Housing 按「在家 / 不在家」切成
	-- returnhome 或 teleporthome（用户 2026-10-28，移植自 AstralGate）。
	-- 它内部会自己判断战斗中不能改安全属性的情况。
	if entry.housingFaction then
		if addon.Housing then addon.Housing.ConfigureButton(button, entry.housingFaction) end
		-- 每次左键点击前重评 CanReturn 并重设安全属性（AstralGate WorldMapPanel.lua:223-228，
		-- 移植时曾遗漏）：传送回家后即使列表尚未刷新，下一次点击也立即按「返回原地」执行；
		-- lastClickedFaction 供 RecentHistory 在施法成功时记录最近使用。
		if addon.Housing then
			button:SetScript("PreClick", function(self, mouseButton)
				if mouseButton == "LeftButton" and not InCombatLockdown() then
					addon.Housing.ConfigureButton(self, entry.housingFaction)
					addon.Housing.lastClickedFaction = entry.housingFaction
				end
			end)
		end
		return
	end

	if entry.isToy then
		if entry.isKnown then
			button:SetAttribute("type1", "macro")
			button:SetAttribute("macrotext1", "/use item:" .. entry.toyID)
		end
	elseif entry.isItem then
		if entry.isKnown then
			button.itemID = entry.itemID
			button.equipSlot = entry.equipSlot
			button:SetAttribute("type1", "macro")
			button:SetAttribute("macrotext1", "/use item:" .. entry.itemID)
			if entry.equipSlot then
				button:SetScript("PreClick", function(self, mouseButton)
					if mouseButton and mouseButton ~= "LeftButton" then return end
					local slot = self.equipSlot
					local itemID = self.itemID
					if not slot or not itemID then return end
					local equippedID = GetInventoryItemID("player", slot)
					if equippedID ~= itemID then
						queueReequipRestore(slot, equippedID, itemID, self.entry and self.entry.spellID)
						self:SetAttribute("type1", "macro")
						self:SetAttribute("macrotext1", "/equipslot " .. slot .. " item:" .. itemID)
					else
						self:SetAttribute("type1", "macro")
						self:SetAttribute("macrotext1", "/use item:" .. itemID)
					end
				end)
			end
		end
	else
		button:SetAttribute("type1", "spell")
		button:SetAttribute("spell1", entry.spellID)
		button:SetAttribute("unit", "player")
		button:SetAttribute("checkselfcast", true)
	end
end

-- Open World Map to a mapID and create a user waypoint pin at x,y (0..1)
local function OpenMapAndCreatePin(mapID, x, y)
	if not mapID then return end
	if WorldMapFrame and WorldMapFrame.SetMapID then
		if not WorldMapFrame:IsShown() then
			if ToggleWorldMap then
				ToggleWorldMap()
			else
				ShowUIPanel(WorldMapFrame)
			end
		end
		WorldMapFrame:SetMapID(mapID)
	end
	if x and y and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
		local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
		if point then
			C_Map.SetUserWaypoint(point)
			if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
		end
	end
end

-- Cooldown helpers ---------------------------------------------------------
local function SetCompactCountdownFont(cooldown)
	local text = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if not text then return end
	local font, size, flags = text:GetFont()
	if font then text:SetFont(font, 12, flags) end
end

local function ApplyCooldownToButton(b)
	if not b or not b.cooldownFrame or not b.entry then return end
	local entry = b.entry
	-- 宠物：召唤/解散没有法术 CD，清掉冷却显示。
	if entry.petSpeciesID then
		if b.cooldownFrame.Clear then b.cooldownFrame:Clear() end
		b.cooldownFrame:SetCooldown(0, 0, 0)
		return
	end
	-- 家宅：「离家归来」实际没有 CD，不能跟着传送技能的 CD 走（用户 2026-10-28）。
	-- 两个条目共用一个 spellID(1233637)，直接读技能冷却会把传送的 CD 也套到返回上。
	if entry.housingFaction and addon.Housing and addon.Housing.CanReturn(entry.housingFaction) then
		-- 两种清除方式都走一遍：只调 Cooldown:Clear 时有可能清不掉（返回原地又跟着
		-- 家宅的 CD 走了，用户 2026-10-29 复现），SetCooldown(0,0,0) 兜底。
		if b.cooldownFrame.Clear then b.cooldownFrame:Clear() end
		b.cooldownFrame:SetCooldown(0, 0, 0)
		return
	end
	local startTime, duration, modRate, enabled, durationObj
	if entry.isToy and entry.toyID then
		local st, dur, en = C_Item.GetItemCooldown(entry.toyID)
		startTime, duration, modRate, enabled = st, dur, 1, en
	elseif entry.isItem and entry.itemID then
		local st, dur, en = C_Item.GetItemCooldown(entry.itemID)
		startTime, duration, modRate, enabled = st, dur, 1, en
	else
		durationObj = C_Spell.GetSpellCooldownDuration(entry.spellID)
	end

	if nil ~= durationObj then
		b.cooldownFrame:SetCooldownFromDurationObject(durationObj)
	elseif issecretvalue and issecretvalue(enabled) then
		b.cooldownFrame:SetCooldown(startTime or 0, duration or 0, modRate or 1)
	elseif enabled and duration and duration > 0 then
		b.cooldownFrame:SetCooldown(startTime or 0, duration or 0, modRate or 1)
	else
		if b.cooldownFrame.Clear then b.cooldownFrame:Clear() end
		b.cooldownFrame:SetCooldown(0, 0, 0)
	end
end

-- Panel creation -----------------------------------------------------------
local panel -- content frame
local scrollBox
local tabButton -- forward-declare for SafeSetVisible
-- Safe visibility toggles (avoid Show/Hide taint during combat)
local function SafeSetVisible(frame, visible)
	if not frame then return end
	if (frame == panel or frame == tabButton) and f.tabLib and not (InCombatLockdown and InCombatLockdown()) then
		frame._adePortalTabPendingVisible = nil
		frame:SetAlpha(1)
		frame:SetShown(visible and true or false)
		return
	end
	-- During combat, defer protected visibility changes and mirror the requested state via alpha.
	if frame == panel or frame == tabButton then
		frame._adePortalTabPendingVisible = visible and true or false
		frame:SetAlpha(visible and 1 or 0)
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		frame._adePortalTabPendingVisible = visible and true or false
		frame:SetAlpha(visible and 1 or 0)
		return
	end
	if visible then
		frame:Show()
	else
		if not InCombatLockdown() then frame:Hide() end
	end
end
local function isRestrictedContent()
	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	local restrictedActions = _G.C_RestrictedActions
	if not (restrictionTypes and restrictedActions and restrictedActions.GetAddOnRestrictionState) then return false end
	for _, v in pairs(restrictionTypes) do
		if v ~= 4 then
			if restrictedActions.GetAddOnRestrictionState(v) == 2 then return true end
		end
	end
	return false
end

local function SetCombatScrolling(enabled)
	if not panel or not panel.Scroll then return end
	local s = panel.Scroll
	if enabled then
		s:EnableMouse(true)
		s:EnableMouseWheel(true)
		if s.ScrollBar then
			s.ScrollBar.allowScroll = true
			if s.ScrollBar.Back then s.ScrollBar.Back:Enable() end
			if s.ScrollBar.Forward then s.ScrollBar.Forward:Enable() end
		end
	else
		-- In combat, suppress any scrolling to avoid protected SetVerticalScroll taint
		s:EnableMouse(false)
		s:EnableMouseWheel(false)
		if s.ScrollBar then
			s.ScrollBar.allowScroll = false
			if s.ScrollBar.Back then s.ScrollBar.Back:Disable() end
			if s.ScrollBar.Forward then s.ScrollBar.Forward:Disable() end
		end
	end
end

-- Reset only when the panel becomes visible, never on routine data refreshes.
-- 仅在重新显示面板后归顶；普通冷却/记录刷新保持滚动位置，战斗中暂缓。
local function ResetPendingScrollToTop()
 if not panel or not panel._adePortalTabResetScroll or not panel:IsShown() then return end
 if InCombatLockdown and InCombatLockdown() then return end
 local scroll = panel.Scroll
 if not scroll then return end
 local bar = scroll.ScrollBar
 if bar and bar.SetScrollPercentage then
  bar:SetScrollPercentage(0)
 elseif bar and bar.SetValue then
  bar:SetValue(0)
 end
 scroll:SetVerticalScroll(0)
 panel._adePortalTabResetScroll = nil
end

local function SetButtonsInteractable(enabled)
	if not panel or not panel._allButtons then return end
	for _, b in ipairs(panel._allButtons) do
		if b and b.EnableMouse then b:EnableMouse(enabled and true or false) end
	end
end

local function SetBlockerEnabled(enabled)
	if panel and panel.Blocker then
		panel.Blocker:SetAlpha(enabled and 1 or 0)
		panel.Blocker:EnableMouse(enabled and true or false)
		panel.Blocker:EnableMouseWheel(enabled and true or false)
	end
end

local function IsPanelSuppressed() return isRestrictedContent() end

local function IsTeleportDisplayModeActive()
	return f.tabLib and tabButton and f.tabLib.activeDisplayMode == tabButton.displayMode
end

local function SetTeleportDisplayMode()
	if not (f.tabLib and tabButton and tabButton.displayMode) then return false end
	-- 只走主插件公共函数（内部调库 SetDisplayMode，禁止绕过库传自定义值给官方函数）。
	MapTab.SetDisplayMode(tabButton)
	return true
end

local function LeaveDisplayModeIfNeeded()
	if not QuestMapFrame or not IsTeleportDisplayModeActive() then return end
	if InCombatLockdown and InCombatLockdown() then return end

	local questLogDisplayMode = _G.QuestLogDisplayMode
	if QuestMapFrame.SetDisplayMode and questLogDisplayMode and questLogDisplayMode.MapLegend then
		QuestMapFrame:SetDisplayMode(questLogDisplayMode.MapLegend)
		return
	end
	if QuestMapFrame.MapLegendTab and QuestMapFrame.MapLegendTab.Click then
		QuestMapFrame.MapLegendTab:Click()
	elseif QuestMapFrame.QuestsTab and QuestMapFrame.QuestsTab.Click then
		QuestMapFrame.QuestsTab:Click()
	end
end

local function ApplySuppressedPanelState()
	SetCombatScrolling(false)
	SetButtonsInteractable(false)
	SetBlockerEnabled(true)
	if panel then SafeSetVisible(panel, false) end
	if tabButton then SafeSetVisible(tabButton, false) end
	LeaveDisplayModeIfNeeded()
end

local function ApplyNormalPanelState()
	SetCombatScrolling(true)
	SetButtonsInteractable(true)
	SetBlockerEnabled(false)
end

local function ApplyUnsuppressedPanelState()
	ApplyNormalPanelState()
	if panel and panel._adePortalTabPendingVisible ~= nil then
		SafeSetVisible(panel, panel._adePortalTabPendingVisible)
		panel._adePortalTabPendingVisible = nil
	end
	if tabButton and tabButton._adePortalTabPendingVisible ~= nil then
		SafeSetVisible(tabButton, tabButton._adePortalTabPendingVisible)
		tabButton._adePortalTabPendingVisible = nil
	end

	local modeActive = IsTeleportDisplayModeActive()
	if tabButton then SafeSetVisible(tabButton, true) end
	if tabButton and tabButton.SetChecked then tabButton:SetChecked(modeActive and true or false) end
	if panel then SafeSetVisible(panel, modeActive and true or false) end
end

local function IsRelevantRestrictionType(restrictionType) return restrictionType ~= RESTRICTION_TYPE_MAP end


local function EnsurePanel(parent)
	if panel then return panel end

	-- 地基统一由主插件公共函数创建：库 CreateContentFrameForTab（自动 Link）、
	-- parent 覆盖回 ContentsAnchor（Mapster 拖动层）、三次锚定兜底、
	-- HIGH / +200 / Toplevel / Mouse、背景。所有实证 hack 都在公共库内。
	-- 本面板的边框 / 齿轮在 Scroll 创建之后才建（v4 顺序），故不传 addBorder /
	-- onSettingsClick；SafeSetVisible 战斗保护仍由本文件在下方执行。
	panel = MapTab.CreateContentFrame(tabButton, "ADEMapTabPortalWorldMapPanel")
	SafeSetVisible(panel, false)

	-- Border & Title are positioned after Scroll creation

	-- 老式 ScrollFrameTemplate + 12.x MinimalScrollBar 的创建 / 重锚 / Update 统一走主插件
	-- 公共函数 MapTab.CreateScrollFrame（内部不碰范围 / 步进 / 值，只调 bar:Update()）。
	-- Portal 的边距是 0,-4 / 0,0（与设置页的 2,-5 / -2,14 不同），显式传参覆盖默认值。
	local s, content = MapTab.CreateScrollFrame(panel, {
		name = "ADEMapTabPortalScrollFrame",
		contentName = "ADEMapTabPortalScrollChild",
		left = 0, topY = -4, rightX = 0, bottomRightY = 0,
	})

	-- 背景铺满整块面板（WQT WorldQuestTab.xml:640-646 只给两个锚、无内缩）。
	-- 背景已由 CreateContentFrame 建在 panel 上，这里保留 s.Background 引用供后续代码使用。
	panel.Background:ClearAllPoints()
	panel.Background:SetAllPoints(panel)
	s.Background = panel.Background

	panel.Content = content
	panel.Scroll = s

	-- TopBar：容纳标题 / 搜索框 / 搜索开关，对齐 WQT 的弹性布局（WorldQuestTab.xml:645-665）。
	-- 之前这些控件直接挂在 panel 上、y 落在内容区视觉范围，现在统一收进 bar。
	-- WQT 26px 顶栏容器（TOPLEFT 2,30 / TOPRIGHT -2,30 / 层级 +4）由主插件公共函数创建，
	-- 锚点与层级与 v4 逐像素一致；标题 / 搜索框 / 放大镜仍由本文件挂在其上。
	local bar = MapTab.CreateTopBar(panel)
	panel.TopBar = bar

	local search = CreateFrame("EditBox", nil, bar, "SearchBoxTemplate")
	-- 搜索框纳入 TopBar（bar）内，填充标题右侧到放大镜左侧（对齐 WQT UpdateTopBar）；
	-- 默认隐藏，点放大镜才展开并隐藏标题（用户 2026-10-28）。
	search:SetPoint("LEFT", bar, "LEFT", 12, 0)
	search:SetPoint("RIGHT", bar, "RIGHT", -34, 0)
	search:SetHeight(20) -- 对齐 WQT SearchBox 的 Size y=20（WorldQuestTab.xml:717）
	search:SetAutoFocus(false)
	search:SetMaxLetters(100)
	if search.Instructions then search.Instructions:SetText(L["searchTeleports"]) end
	search:SetScript("OnTextChanged", function(self)
		if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
		panel._adePortalTabResetScroll = true
		QueuePanelRefresh({ delay = 0.1 })
	end)
	search:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	panel.Search = search
	-- 默认隐藏，点搜索按钮才展开（WQT 行为：WorldQuestTab.lua:1461-1468）；平时显示标题。
	search:Hide()

    panel:HookScript("OnShow", function()
     panel._adePortalTabResetScroll = true
     QueuePanelRefresh({ delay = 0 })
    end)

	-- 切到其它标签页或关地图时回到列表页，否则下次点回来仍停在设置页。
	-- 落点必须是面板自身 OnHide（库 SetDisplayMode 直接 SetShown(false)，WorldMapOnShow 不触发），
	-- 由主插件公共函数 MapTab.HookOnHideReset 固化。
	MapTab.HookOnHideReset(panel, function()
		if currentMode ~= "list" then
			currentMode = "list"
			if settingsFrame then settingsFrame:Hide() end
		end
	end)

	-- Combat click blocker overlay (prevents any interaction while in combat)
	if not panel.Blocker then
		local blocker = CreateFrame("Frame", nil, panel, "BackdropTemplate")
		blocker:SetAllPoints(s)
		blocker:EnableMouse(false)
		blocker:EnableMouseWheel(false)
		blocker:SetAlpha(0)
		panel.Blocker = blocker
	end

	-- Ensure our interactive content renders above any sibling art
	local baseLevel = panel:GetFrameLevel() or 1
	s:SetFrameLevel(baseLevel + 1)
	content:SetFrameLevel(baseLevel + 2)

	-- Respect combat lockdown: prevent scrolling interactions during combat
	if InCombatLockdown and InCombatLockdown() then
		SetCombatScrolling(false)
		if panel.Blocker then
			panel.Blocker:SetAlpha(1)
			panel.Blocker:EnableMouse(true)
			panel.Blocker:EnableMouseWheel(true)
		end
	end

	-- Now that Scroll exists, create/anchor the border precisely around it
	if not panel.BorderFrame then
		local bf = CreateFrame("Frame", nil, panel, "QuestLogBorderFrameTemplate")
		bf:ClearAllPoints()
		-- 用模板自带的外扩锚（QuestMapFrame.xml:249-252：TOPLEFT -3,7 / BOTTOMRIGHT 3,-6）。
		-- 面板已缩进 29/22，外扩后边框上沿在 ca.top-22、右沿在 ca.right-19，都还在窗口内。
		bf:SetPoint("TOPLEFT", panel, "TOPLEFT", -3, 7)
		bf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 3, -6)
		bf:SetFrameStrata(panel:GetFrameStrata())
		bf:SetFrameLevel((panel:GetFrameLevel() or 2) + 3)
		bf:EnableMouse(false) -- ensure border never blocks clicks to our content
		panel.BorderFrame = bf
	else
		local bf = panel.BorderFrame
		bf:ClearAllPoints()
		bf:SetPoint("TOPLEFT", panel, "TOPLEFT", -3, 7)
		bf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 3, -6)
		bf:SetFrameStrata(panel:GetFrameStrata())
		bf:SetFrameLevel((panel:GetFrameLevel() or 2) + 3)
		bf:EnableMouse(false)
	end

	-- 标题落在面板内 TopBar 区（与搜索栏互斥替换，用户 2026-10-28），不再压在边框上沿。
	if not panel.Title then
		local title = bar:CreateFontString(nil, "OVERLAY", "Game15Font_Shadow")
		-- 标题在顶栏水平居中（用户 2026-10-28：之前 LEFT 12 贴在左侧）。
		title:SetPoint("CENTER", bar, "CENTER", 0, 0)
		-- 与 Tab 的 tooltip 同一个 key（用户 2026-10-27：页面标题要和 Tab tip 一致）。
		title:SetText(L["TAB_TITLE"] or L["DungeonCompendium"] or "Dungeon Portals")
		panel.Title = title
	else
		panel.Title:ClearAllPoints()
		panel.Title:SetPoint("CENTER", bar, "CENTER", 0, 0)
		panel.Title:SetText(L["TAB_TITLE"] or L["DungeonCompendium"] or "Dungeon Portals")
	end

	-- 设置按钮（齿轮）：点击切换整块面板到设置，WorldQuestTab.lua:970-973 的做法。
	local settings = CreateFrame("Button", nil, panel)
	settings:SetSize(15, 16)
	-- 与设置页关闭按钮严格一致（adePortalTab/UI/SettingsPanel.lua：15x16、TOPRIGHT parent TOPRIGHT 19,25）。
	-- 之前曾对齐原生 questScroll.SettingsDropdown（CENTER），位置和关闭按钮不重合（用户 2026-10-29）。
	-- panel 与 settingsFrame 同尺寸同位置，二者等价，统一为固定 TOPRIGHT 即可严格对齐。
	settings:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 19, 25)
	settings:SetFrameLevel(panel.BorderFrame:GetFrameLevel() + 1)
	local gear = settings:CreateTexture(nil, "ARTWORK")
	gear:SetSize(16, 16)
	gear:SetAtlas("questlog-icon-setting", false)
	gear:SetPoint("CENTER", 0, 0)
	-- 悬停高亮照 WQT（WorldQuestTab.xml:781-787）：HIGHLIGHT 层用同一图集 + 叠加混合，
	-- 效果是齿轮自身发亮，而不是多出一块方块底。
	local gearHighlight = settings:CreateTexture(nil, "HIGHLIGHT")
	gearHighlight:SetAtlas("questlog-icon-setting", false)
	gearHighlight:SetAllPoints(gear)
	gearHighlight:SetBlendMode("ADD")
	settings:SetScript("OnClick", function()
		addon.MapPanel:ToggleSettings()
	end)
	panel.SettingsButton = settings
	panel.GearIcon = gear

	-- 搜索按钮（放大镜）：WQT 风格（WorldQuestTab.xml:729-749 + WowStyle2IconButtonTemplate）。
	-- 点击展开搜索栏、隐藏标题（互斥替换，WorldQuestTab.lua:1461-1468）。
	local toggle = CreateFrame("CheckButton", nil, bar, "WowStyle2IconButtonTemplate")
	toggle:SetSize(26, 25)
	toggle:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
	toggle.normalAtlas = "common-search-magnifyingglass"
	toggle.iconWidth = 14
	toggle.iconHeight = 14
	if toggle.Background then toggle.Background:Hide() end
	local toggleHighlight = toggle:CreateTexture(nil, "HIGHLIGHT")
	toggleHighlight:SetPoint("CENTER", toggle, "CENTER", 2, -1)
	toggle.Highlight = toggleHighlight
	-- 照 WQT 的 OnButtonStateChanged（WorldQuestTab.lua:2340-2357）：常规灰、搜索白。
	function toggle:OnButtonStateChanged()
		local icon = self.normalAtlas
		if not icon then return end
		local width, height = self.iconWidth or 14, self.iconHeight or 14
		if self.Icon then
			self.Icon:SetAtlas(icon, false)
			self.Icon:SetSize(width, height)
			self.Icon:ClearAllPoints()
			self.Icon:SetPoint("CENTER", self, "CENTER", 2, -1)
			local saturation = self:GetChecked() and 1 or 0.5
			self.Icon:SetVertexColor(saturation, saturation, saturation)
		end
		if self.Highlight then
			self.Highlight:SetAtlas(icon, false)
			self.Highlight:SetSize(width, height)
		end
	end
	toggle:OnButtonStateChanged()
	toggle:HookScript("OnShow", function(self) self:OnButtonStateChanged() end)
	toggle:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		panel.Search:SetShown(checked)
		if panel.Title then panel.Title:SetShown(not checked) end
		if checked then
			panel.Search:SetFocus()
		else
			if SearchBoxTemplate_ClearText then SearchBoxTemplate_ClearText(panel.Search) end
		end
	end)
	panel.SearchToggle = toggle

	if not settingsFrame then
		settingsFrame = addon.Settings:Create(panel)
		settingsFrame:Hide()
	end

	scrollBox = content
	-- Integrate with QuestLog display system

	-- Keep content up-to-date if the scroll area changes size after layout
	if not s._adePortalTabSizeHook then
		s:HookScript("OnSizeChanged", function()
			if panel and panel:IsShown() then QueuePanelRefresh({ delay = 0.05 }) end
		end)
		s._adePortalTabSizeHook = true
	end
	return panel
end

-- 收藏星标：与 EnhanceQoL 一致，使用拍卖行的收藏图集。
local function AttachFavoriteOverlay(button, entry)
	local fav = button:CreateTexture(nil, "OVERLAY")
	fav:SetPoint("TOPRIGHT", button.Icon or button, "TOPRIGHT", 4, 4)
	fav:SetSize(14, 14)
	if fav.SetAtlas then
		fav:SetAtlas("auctionhouse-icon-favorite")
	else
		fav:SetColorTexture(1, 0.82, 0)
	end
	fav:SetShown(entry.favorite == true)
	button.FavoriteOverlay = fav
	return fav
end

-- Shift+右键切换收藏；返回 true 表示这次右键已被收藏操作消费。
local function ToggleFavoriteOnRightClick(entry)
	if not IsShiftKeyDown() then return false end
	addon.Catalog.ToggleFavorite(entry)
	GameTooltip:Hide()
	QueuePanelRefresh({ invalidate = true, delay = 0 })
	return true
end

--- 地图名：entry.locID 是 Catalog 里的 openMapID（Services/Catalog.lua:267）。
local function MapName(mapID)
	if not mapID then return nil end
	if not (C_Map and C_Map.GetMapInfo) then return nil end
	local info = C_Map.GetMapInfo(mapID)
	return info and info.name or nil
end

--- 「地图名称」那一段的文字；返回 nil 表示整行都不显示。
--- 优先取补充表（Data/DestinationOverrides.lua），取不到再读 locID 的地图名。
local function DestinationName(entry)
	-- 炉石条目是动态生成的（没有固定目的地），用它显示绑定的旅店。
	if entry.isRandomHearthstone then return L["DEST_INN"] end
	local override = addon.DestinationOverrides and addon.DestinationOverrides[entry.spellID]
	if override then
		if override.hide then return nil end
		if override.nameFn then return override.nameFn(entry) end
		if override.name then return L[override.name] or override.name end
	end
	return MapName(entry.locID)
end

--- 目的地一行：传送到「{分组} - {地图名称}」，金色（用户 2026-10-29）。
--- 角色分组（首页）与补充表里标了 whole 的只显示地图名，不拼分组前缀。
-- 在提示中添加传送目的地（受 portalTooltipDestination 控制；关闭「在传送按钮上显示提示」时整体不显示）。
-- 宠物等带多个目的地时逐条列出（用户 2026-11-10：熊猫人之谜各副本入口）。
local function AddDestinationTooltipLine(entry)
	if not entry then return end
	if not addon.db["portalTooltipDestination"] then return end
	-- 宠物等多目的地：各副本入口逐条列出。
	if entry.destinations then
		for _, mapID in ipairs(entry.destinations) do
			local dname = MapName(mapID)
			if dname and dname ~= "" then
				GameTooltip:AddLine(string.format(L["TELEPORT_DESTINATION_SECTION_ONLY"], dname), 0.60, 0.86, 0.76, true)
			end
		end
		return
	end
	local name = DestinationName(entry)
	if not name or name == "" then return end
	local override = addon.DestinationOverrides and addon.DestinationOverrides[entry.spellID]
	local whole = entry.isRandomHearthstone or entry.isHomeSection
		or (override and override.whole) or false
	local section = (not whole) and entry.sectionTitle or nil
	if section and section ~= "" then
		GameTooltip:AddLine(string.format(L["TELEPORT_DESTINATION"], section, name), 0.60, 0.86, 0.76, true) -- 1, 0.82, 0
	else
		GameTooltip:AddLine(string.format(L["TELEPORT_DESTINATION_SECTION_ONLY"], name), 0.60, 0.86, 0.76, true)
	end
end

local function AddFavoriteTooltipLine()
	if L["TELEPORT_FAVORITE_HINT"] then GameTooltip:AddLine(L["TELEPORT_FAVORITE_HINT"], 0.7, 0.7, 0.7, true) end
end

local function ClearContent()
	if not scrollBox then return end
	for _, child in ipairs({ scrollBox:GetChildren() }) do
		child:Hide()
		child:SetParent(nil)
	end
end

local function CreateSecureSpellButton(parent, entry)
	local b = CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate, UIPanelButtonTemplate")
	b:SetSize(28, 28)
	b.entry = entry
	-- ConsolePort fires clicks as typerelease; force release-based casting for compatibility
	if IsConsolePortLoaded() then b:SetAttribute("useOnKeyDown", false) end

	-- Keep buttons above any background art
	if panel then
		b:SetFrameStrata(panel:GetFrameStrata())
		b:SetFrameLevel((panel:GetFrameLevel() or 1) + 10)
	end

	local tex = b:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(b)
	if entry.iconID then
		tex:SetTexture(entry.iconID)
	else
		tex:SetTexture(136121)
	end
	b.Icon = tex

	local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	cd:SetAllPoints(tex) -- restrict overlay strictly to the icon
	cd:SetSwipeColor(0, 0, 0, 0.35)
	cd:SetUseCircularEdge(true)
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false) -- prevent golden flare from bleeding outside
	SetCompactCountdownFont(cd)
	b.cooldownFrame = cd

	-- Casting setup (Left click) — mirror compendium logic
	ConfigureButtonTeleportAction(b, entry)

	-- favorite star overlay
	AttachFavoriteOverlay(b, entry)

	-- Right click after the action resolves
	b:RegisterForClicks("AnyDown", "AnyUp")
	b:SetScript("PostClick", function(self, btn, down)
		if self.entry and self.entry.petSpeciesID then
			HandlePetClick(self.entry, btn, down)
			return
		end
		if btn == "RightButton" and not down then
			if ToggleFavoriteOnRightClick(self.entry) then return end
			if self.entry.isRandomHearthstone then
				if addon.Hearthstones.Reroll() then
					GameTooltip:Hide()
					QueuePanelRefresh({ invalidate = true, delay = 0 })
				end
				return
			end
			local entry = self.entry or {}
			local locID = entry.locID
			local x, y = entry.x, entry.y
			if locID then OpenMapAndCreatePin(locID, x, y) end
		end
	end)

	b:SetScript("OnEnter", function(self)
		if not addon.db["portalShowTooltip"] then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if entry.isToy then
			GameTooltip:SetToyByItemID(entry.toyID)
		elseif entry.isItem then
			GameTooltip:SetItemByID(entry.itemID)
		elseif entry.petSpeciesID then
			GameTooltip:SetText(entry.text)
			GameTooltip:AddLine("左键召唤，右键解散", 1, 1, 1)
		else
			GameTooltip:SetSpellByID(entry.spellID)
		end
		AddVariantTooltipLine(entry)
		-- 目的地一行放在收藏提示的上面（用户 2026-10-29）。
		AddDestinationTooltipLine(entry)
		AddFavoriteTooltipLine()
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- initial cooldown state
	ApplyCooldownToButton(b)

	-- 紧凑图标按钮：注册到「清单传送」Masque 组（可与区域传送分别单独设置）。
	if addon.ButtonSkin and addon.ButtonSkin.ApplyGroup then addon.ButtonSkin:ApplyGroup(b, addon.ButtonSkin.GROUP_LIST) end

	return b
end

-- MapLegend-style row button: left icon (its own Masque-themed button) + right text.
-- 图标是独立按钮，可单独被 Masque 主题；整行容器承接全部交互，文字区点击也生效。
local function CreateLegendRowButton(parent, entry, width, height)
	-- 整行容器：承载布局与全部交互（左键传送 / 右键收藏·地图 / tooltip / 高亮）
	local row = CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate")
	row:SetSize(width, height)
	row.entry = entry
	if IsConsolePortLoaded() then row:SetAttribute("useOnKeyDown", false) end

	-- 图标按钮（独立按钮，注册 Masque；不接收鼠标，点击穿透到 row 由整行统一处理）
	local iconBtn = CreateFrame("Button", nil, row, "InsecureActionButtonTemplate")
	iconBtn:SetSize(height - 6, height - 6)
	iconBtn:SetPoint("LEFT", 4, 0)
	iconBtn:EnableMouse(false)  -- 交互全交给 row（文字点击也生效）
	iconBtn.entry = entry

	local icon = iconBtn:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(iconBtn)
	icon:SetTexture(entry.iconID or 136121)
	iconBtn.Icon = icon

	-- cooldown overlay on icon only
	local cd = CreateFrame("Cooldown", nil, iconBtn, "CooldownFrameTemplate")
	cd:SetAllPoints(icon)
	cd:SetSwipeColor(0, 0, 0, 0.35)
	cd:SetUseCircularEdge(true)
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)
	SetCompactCountdownFont(cd)
	iconBtn.cooldownFrame = cd

	-- favorite star overlay (on icon)
	AttachFavoriteOverlay(iconBtn, entry)

	-- 图标注册到「清单传送」Masque 组（可与区域传送分别单独设置）
	if addon.ButtonSkin and addon.ButtonSkin.ApplyGroup then addon.ButtonSkin:ApplyGroup(iconBtn, addon.ButtonSkin.GROUP_LIST) end

	-- 让整行容器也暴露 Icon / cooldownFrame：兼容池复用时的 Configure 与 UpdateCooldowns
	row.Icon = icon
	row.cooldownFrame = cd

	-- label to the right of the icon
	local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("LEFT", iconBtn, "RIGHT", 8, 0)
	label:SetPoint("RIGHT", -6, 0)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(false)
	label:SetText(entry.text or "")
	row.Label = label

	-- full-row highlight (lockable) using the same atlas as MapLegend
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(row)
	if hl.SetAtlas then
		hl:SetAtlas("Options_List_Active", true)
		if hl.SetBlendMode then hl:SetBlendMode("ADD") end
	else
		hl:SetColorTexture(1, 1, 1, 0.08)
	end
	row:SetHighlightTexture(hl)

	-- Casting setup (Left click) — whole row carries it, so clicking the text also casts
	ConfigureButtonTeleportAction(row, entry)

	-- Right click: locate destination or choose another hearthstone
	row:RegisterForClicks("AnyDown", "AnyUp")
	row:SetScript("PostClick", function(self, btn, down)
		if self.entry and self.entry.petSpeciesID then
			HandlePetClick(self.entry, btn, down)
			return
		end
		if btn == "RightButton" and not down then
			if ToggleFavoriteOnRightClick(self.entry) then return end
			if self.entry.isRandomHearthstone then
				if addon.Hearthstones.Reroll() then
					GameTooltip:Hide()
					QueuePanelRefresh({ invalidate = true, delay = 0 })
				end
				return
			end
			local entry = self.entry or {}
			local locID = entry.locID
			local x, y = entry.x, entry.y
			if locID then OpenMapAndCreatePin(locID, x, y) end
		end
	end)

	-- Tooltip + highlight lock on hover (mirrors MapLegend feel)
	row:SetScript("OnEnter", function(self)
		if self.SetHighlightLocked then
			self:SetHighlightLocked(true)
		else
			self:LockHighlight()
		end
		if addon.db["portalShowTooltip"] then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if entry.isToy then
				GameTooltip:SetToyByItemID(entry.toyID)
			elseif entry.isItem then
				GameTooltip:SetItemByID(entry.itemID)
			elseif entry.petSpeciesID then
				GameTooltip:SetText(entry.text)
				GameTooltip:AddLine("左键召唤，右键解散", 1, 1, 1)
			else
				GameTooltip:SetSpellByID(entry.spellID)
			end
			AddVariantTooltipLine(entry)
			-- 目的地一行放在收藏提示的上面（用户 2026-10-29）。
			AddDestinationTooltipLine(entry)
			AddFavoriteTooltipLine()
			GameTooltip:Show()
		end
	end)
	row:SetScript("OnLeave", function(self)
		if self.SetHighlightLocked then
			self:SetHighlightLocked(false)
		else
			self:UnlockHighlight()
		end
		GameTooltip:Hide()
	end)

	-- Unknown visual state: keep hover for tooltip, but block casting
	if not entry.isKnown then
		if iconBtn.Icon then
			iconBtn.Icon:SetDesaturated(true)
			iconBtn.Icon:SetAlpha(0.5)
		end
		-- Make label clearly appear unavailable
		if row.Label and row.Label.SetTextColor then row.Label:SetTextColor(0.6, 0.6, 0.6) end
		row:EnableMouse(true)
		row:SetAttribute("type1", nil)
		row:SetAttribute("spell1", nil)
		row:SetAttribute("macrotext1", nil)
	else
		if iconBtn.Icon then
			iconBtn.Icon:SetDesaturated(false)
			iconBtn.Icon:SetAlpha(1)
		end
		-- Restore normal label color for known/owned teleports (gold-like)
		if row.Label and row.Label.SetTextColor then row.Label:SetTextColor(1.0, 0.82, 0.0) end
		row:EnableMouse(true)
	end

	-- Set frame strata above background art
	if panel then
		row:SetFrameStrata(panel:GetFrameStrata())
		row:SetFrameLevel((panel:GetFrameLevel() or 1) + 10)
	end

	-- initial cooldown state
	ApplyCooldownToButton(row)

	return row
end

-- 列表顺序：最近使用、收藏、首页，再到各资料片。
local function PopulatePanel()
	if not panel then return end
	ClearContent()

	-- keep references for lightweight cooldown refresh
	panel._allButtons = {}

	-- Combine sections with preferred order: CHARACTER, then others
	local combined = {}
	local query = strlower(panel.Search and panel.Search:GetText() or ""):match("^%s*(.-)%s*$")
	local searching = query ~= ""
	local comp = BuildSpellEntries() or {}
	if not searching and addon.Recent.BuildSection then
		local recent = addon.Recent.BuildSection(comp)
		if recent then table.insert(combined, recent) end
	end
	local homeSec
	local others = {}
	for _, sec in ipairs(comp) do
		local t = sec and sec.title
		if t == CHARACTER then
			homeSec = sec
		else
			table.insert(others, sec)
		end
	end

	-- 收藏分组：聚合所有 favorite==true 的传送，位于「最近使用」与「角色」两组之间；
	-- 关闭「显示收藏的传送」或收藏个数为 0 时不显示（用户 2026-10-29 / 2026-11-10）。每个条目上的收藏星标仍照常显示。
	if not searching and (addon.db.showFavorites ~= false) then
		local favItems = {}
		for _, sec in ipairs(comp) do
			for _, entry in ipairs(sec.items or {}) do
				if entry.favorite == true then
					favItems[#favItems + 1] = entry
				end
			end
		end
		if #favItems > 0 then
			table.insert(combined, { key = "favorites", title = L["FAVORITES"] or "收藏", items = favItems })
		end
	end

	if homeSec then table.insert(combined, homeSec) end

	for _, sec in ipairs(others) do
		table.insert(combined, sec)
	end

	if searching then
		local matches = {}
		for _, section in ipairs(combined) do
			local items = {}
			for _, entry in ipairs(section.items or {}) do
				local title = strlower(entry.text or "")
				local matched = true
				for word in query:gmatch("%S+") do
					if not title:find(word, 1, true) then matched = false; break end
				end
				if matched then items[#items + 1] = entry end
			end
			if #items > 0 then
				matches[#matches + 1] = { key = section.key, title = section.title, items = items }
			end
		end
		combined = matches
	end

	if not combined or #combined == 0 then
		local msg = L[searching and "noTeleportSearchResults" or "noTeleportsAvailable"]
		local empty = CreateFrame("Frame", nil, scrollBox)
		empty:SetPoint("TOPLEFT", 10, -10)
		empty:SetSize(260, 24)
		local label = empty:CreateFontString(nil, "OVERLAY", "GameFontDisable")
		label:SetAllPoints(empty)
		label:SetJustifyH("LEFT")
		label:SetText(msg)
		scrollBox:SetHeight(40)
		if panel.Scroll.UpdateScrollChildRect then panel.Scroll:UpdateScrollChildRect() end
		return
	end

	-- Layout metrics similar to MapLegendScrollFrame
	local leftPadding = 12
	local topPadding = 10
	local categorySpacing = 10
	local buttonSpacingY = 5
	local stride = 2 -- 2 columns
	local rowHeight = 28

	-- compute available width per column
	local scrollW = panel.Scroll:GetWidth() or 330
	-- 滚动条已移到面板外侧（WorldMapPanel.lua:592），不占用内容宽度，故不再扣减。
	-- 之前仍按 18 扣，导致内容右侧空出约 26px（用户 2026-10-28）。
	local scrollbarWidth = 0
	local usableWidth = math.max(120, scrollW - scrollbarWidth - 20)
	local colWidth = math.floor((usableWidth - 0) / stride) -- no horizontal spacing requested

	local yOffset = -topPadding
	for _, section in ipairs(combined) do
		-- category container
		local category = CreateFrame("Frame", nil, scrollBox)
		category:SetPoint("TOPLEFT", leftPadding, yOffset)
		category:SetSize(usableWidth, 10) -- temporary height; will expand below

  -- 分类标题既是折叠开关，也提供固定高度；普通刷新不改动保存的状态。
  local header = addon.SectionHeaders.Create(category, section, usableWidth, function()
   QueuePanelRefresh({ delay = 0 })
  end, searching)
  local headerHeight = header:GetHeight()
  local buttons = {}
  if searching or not addon.SectionHeaders.IsCollapsed(section.key) then
   for _, entry in ipairs(section.items or {}) do
    local b = CreateLegendRowButton(category, entry, colWidth, rowHeight)
    table.insert(buttons, b)
    table.insert(panel._allButtons, b)
   end
  end

		-- grid layout with 2 columns, xSpacing=0, ySpacing=5
		if #buttons > 0 then
			local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.TopLeftToBottomRight, stride, 0, buttonSpacingY)
			local anchor = CreateAnchor("TOPLEFT", category, "TOPLEFT", 0, -3 - headerHeight)
			AnchorUtil.GridLayout(buttons, anchor, layout)

			-- adjust button widths to column width
			for _, b in ipairs(buttons) do
				b:SetWidth(colWidth)
			end
		end

		-- compute category height: title + rows*rowHeight + spacing
		local rows = math.ceil(#buttons / stride)
		local catHeight = headerHeight + 3 + (rows > 0 and ((rows - 1) * (rowHeight + buttonSpacingY) + rowHeight) or 0)
		category:SetHeight(catHeight)

		yOffset = yOffset - catHeight - categorySpacing
	end

	-- update scroll child extents
	scrollBox:SetHeight(math.abs(yOffset) + topPadding)
	if panel.Scroll and panel.Scroll.UpdateScrollChildRect then panel.Scroll:UpdateScrollChildRect() end

	-- 滑块大小/位置由 ScrollControllerMixin 依 OnScrollRangeChanged 自动算（ScrollUtil.lua:240-257），
	-- 这里只需在内容高度变化后请它重算一次（首帧高度常为 0，自动回调算不出 visibleExtentPercentage）。
	if panel.Scroll and panel.Scroll.ScrollBar then
		panel.Scroll.ScrollBar:Update()
	end

	-- Respect combat: disable all button interactions while in combat
	if InCombatLockdown and InCombatLockdown() then SetButtonsInteractable(false) end
end

-- Tab creation -------------------------------------------------------------
-- tabButton declared above for forward reference

-- 地图页签由 LibWorldMapTabs 接入，不修改暴雪任务页签的数据结构。
local function EnsureTab()
	if tabButton then return tabButton end
	-- 库实例由主插件唯一提供；CreateTab 内部已处理 12.x SetChecked 图标尺寸 / 裁边修复。
	f.tabLib = MapTab.GetLib()

	tabButton = MapTab.CreateTab({
		name = "ADEMapTabPortalWorldMapTab",
		-- Tab 名与 EnhanceQoL 的传送页签一致（EnhanceQoL/Locales/zhCN.lua:2292）。
		tooltipText = L["TAB_TITLE"] or L["DungeonCompendium"] or "Teleport Compendium",
		activeTexture = ICON_ACTIVE,
		inactiveTexture = ICON_INACTIVE,
		iconSize = 20,
		texCoord = { 0.1, 0.9, 0.1, 0.9 },
		selectedAlpha = 1,
		autoShow = false, -- 由下方 SafeSetVisible 在 tabButton 赋值完成后显隐
		onMouseUp = function()
			if IsPanelSuppressed() then
				ApplySuppressedPanelState()
				return
			end
			QueuePanelRefresh({ delay = 0 })
		end,
	})

	-- 面板与 Tab 的绑定不再在这里手动做：EnsurePanel 用库自己的
	-- CreateContentFrameForTab(tabButton, ...) 创建面板（WQT 同款写法，
	-- WorldQuestTab.lua:523-525），库在创建时已经 LinkTabToContentFrame 并登记进
	-- lib.contentFrames，显示/隐藏也由 SetDisplayMode 统一管理
	-- （LibWorldMapTabs.lua:288-298、328-330），不会出现「内容区全空」。

	-- 战斗中通过 SafeSetVisible 的 alpha 镜像显隐（v4 战斗保护）。
	-- 必须在 tabButton 赋值完成之后调用，SafeSetVisible 的专用分支依赖它。
	SafeSetVisible(tabButton, true)

	return tabButton
end

-- Glue into World Map ------------------------------------------------------
function f:TryInit()
	-- Only ensure injection when enabled
	if not QuestMapFrame then return end
	if not addon.db or not addon.db["teleportsWorldMapEnabled"] then
		if panel then SafeSetVisible(panel, false) end
		if tabButton then SafeSetVisible(tabButton, false) end
		return
	end
	if IsPanelSuppressed() then
		ApplySuppressedPanelState()
		return
	end

	-- WQT 顺序（WorldQuestTab.lua:523-525）：先拿 Tab，再由库按 Tab 造内容框架，
	-- 这样 CreateContentFrameForTab 才能把面板登记进 lib.contentFrames。
	local tab = EnsureTab()
	if not tab then return end
	EnsurePanel(QuestMapFrame)

	-- ⚠ 这里以前还给 QuestMapFrame 和 QuestMapFrame.ContentsAnchor 各挂了一个
	-- OnSizeChanged 钩子，尺寸一变就 ClearAllPoints 重锚。点 QuestMapFrame 的空白区
	-- 会触发尺寸变化，于是整个世界地图窗口跳到新位置（用户 2026-10-28 反馈）。
	-- 加 IsShown 判断也没用——面板可见时照样会重锚，而且不切到本插件的 Tab 也会犯。
	-- 实际上面板创建时 anchorPanel() 已经锚过（506-522 行），并且本来就有
	-- 「立即 + RunNextFrame + C_Timer 0.1s」三次兜底，足以覆盖布局未就绪的情况。
	-- AstralGate 就是只有这三次、从没挂过钩子，所以它没有这个问题。钩子删掉。

	-- Proactively build content once; subsequent tab/display changes will refresh as needed
	QueuePanelRefresh({ delay = 0, invalidate = true })
end

-- 设置模式下藏起列表相关帧，让设置面板占满整块面板。
-- 边框二选一：设置页自带 BorderFrame（WQT Settings.xml:769），两个外扩 3px 的边框叠在一起
-- 会互相啃掉一截，看起来就是「外边框被背景盖住」。
local function ApplySettingsMode(active)
	if not panel then return end
	if panel.Scroll then panel.Scroll:SetShown(not active) end
	-- 搜索框与标题互斥：搜索框只在「列表模式 + 放大镜已勾选」时显示，否则回到标题。
	-- 之前这里无条件 SetShown(not active)，列表模式下会把搜索框显示出来、盖住标题，
	-- 初始显示与切换 Tab 后都会重现（用户 2026-10-28）。
	local searchExpanded = panel.SearchToggle and panel.SearchToggle:GetChecked() and true or false
	if panel.Search then panel.Search:SetShown(not active and searchExpanded) end
	if panel.Title then panel.Title:SetShown(not active and not searchExpanded) end
	-- TopBar 现在位于面板之外的上方，设置页覆盖不到它，必须显式隐藏搜索按钮，
	-- 否则设置页上方会浮着一个孤立的放大镜（用户 2026-10-28）。
	if panel.SearchToggle then panel.SearchToggle:SetShown(not active) end
	if panel.BorderFrame then panel.BorderFrame:SetShown(not active) end
	-- 齿轮也一起隐藏：设置页自带 WQT 同款关闭按钮，两个入口并存会让人不知道该点哪个。
	if panel.SettingsButton then panel.SettingsButton:SetShown(not active) end
	if settingsFrame then settingsFrame:SetShown(active) end
end

function addon.MapPanel:ToggleSettings()
	currentMode = (currentMode == "settings") and "list" or "settings"
	ApplySettingsMode(currentMode == "settings")
	f:RefreshPanel()
end

function f:RefreshPanel()
	if InCombatLockdown and InCombatLockdown() then return end
	-- 设置面板在标签页关闭时仍然可达，否则关掉开关就再也打不开设置。
	local settingsActive = (currentMode == "settings")
	if not addon.db or (not addon.db["teleportsWorldMapEnabled"] and not settingsActive) then
		if panel then SafeSetVisible(panel, false) end
		if tabButton then SafeSetVisible(tabButton, false) end
		return
	end
	if IsPanelSuppressed() then
		ApplySuppressedPanelState()
		return
	end
	ApplyUnsuppressedPanelState()
	if not panel then return end
	ApplySettingsMode(settingsActive)
	if settingsActive then
		if settingsFrame then addon.Settings:Refresh(settingsFrame) end
		return
	end
	PopulatePanel()
	ResetPendingScrollToTop()
end

-- Only recompute and apply cooldowns for existing buttons
function f:UpdateCooldowns()
	if not panel or not panel:IsShown() then return end
	for _, b in ipairs(panel._allButtons or {}) do
		if b and b:IsVisible() and b.cooldownFrame and b.entry then ApplyCooldownToButton(b) end
	end
end

-- Events to build/refresh --------------------------------------------------
local function setWorldMapTeleportEventsEnabled(enabled)
	if not f then return end
	if enabled then
		if f._adePortalTabEventsRegistered then return end
		f:RegisterEvent("ADDON_LOADED")
		f:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
		f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:RegisterEvent("ZONE_CHANGED")
		f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		f:RegisterEvent("ZONE_CHANGED_INDOORS")
		f:RegisterEvent("LOADING_SCREEN_DISABLED")
		f:RegisterEvent("SPELLS_CHANGED")
		f:RegisterEvent("BAG_UPDATE_DELAYED")
		f:RegisterEvent("TOYS_UPDATED")
		f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		f:RegisterEvent("BAG_UPDATE_COOLDOWN")
		f._adePortalTabEventsRegistered = true
	else
		if not f._adePortalTabEventsRegistered then return end
		f:UnregisterAllEvents()
		clearPendingReequipState()
		f._adePortalTabEventsRegistered = false
	end
end

-- 生命周期：地图延迟加载、战斗保护、切图恢复装备、数据与冷却更新。
local function worldMapEventHandler(self, event, arg1, arg2, arg3)
	if not addon.db or not addon.db["teleportsWorldMapEnabled"] then return end
	if event == "PLAYER_REGEN_DISABLED" then
		SetCombatScrolling(false)
		SetButtonsInteractable(false)
		SetBlockerEnabled(true)
		-- Avoid Show/Hide while in combat
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		local suppressed = IsPanelSuppressed()
		if suppressed then
			ApplySuppressedPanelState()
		else
			ApplyUnsuppressedPanelState()
		end
		if f._pendingOpen and not IsPanelSuppressed() then
			f._pendingOpen = nil
			if addon.MapPanel.Open then addon.MapPanel.Open(true) end
		end
		if hasPendingReequip() then RunNextFrame(tryRestorePendingReequip) end
		if WorldMapFrame and WorldMapFrame:IsShown() and addon.db and addon.db["teleportsWorldMapEnabled"] then QueuePanelRefresh({ delay = 0, invalidate = true }) end
		-- fall through to allow refresh if map is visible
	elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
		if not IsRelevantRestrictionType(arg1) then return end
		if arg2 == RESTRICTION_STATE_ACTIVATING or arg2 == RESTRICTION_STATE_ACTIVE then
			ApplySuppressedPanelState()
			return
		end
		if arg2 ~= RESTRICTION_STATE_INACTIVE or not WorldMapFrame or not WorldMapFrame:IsShown() then return end

		RunNextFrame(function()
			if not addon.db or not addon.db["teleportsWorldMapEnabled"] then return end
			if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
			if IsPanelSuppressed() then
				ApplySuppressedPanelState()
				return
			end
			if not panel or not tabButton then
				f:TryInit()
				return
			end
			ApplyUnsuppressedPanelState()
			QueuePanelRefresh({ delay = 0, invalidate = true })
		end)
		return
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if arg1 == "player" and hasPendingReequip() and isPendingReequipSpell(arg3) then RunNextFrame(tryRestorePendingReequip) end
	elseif event == "LOADING_SCREEN_DISABLED" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
		if hasPendingReequip() then C_Timer.After(0.1, tryRestorePendingReequip) end
		-- 家宅按钮在「传送回家 / 返回原地」之间切换，取决于当前是否在自家社区
		-- （Housing.CanReturn → C_HousingNeighborhood.CanReturnAfterVisitingHouse）。
		-- 传送进出住宅区只触发 ZONE_CHANGED(_NEW_AREA)，不会重走面板 OnShow，
		-- 若不在这里重配，按钮安全属性仍停在旧动作，下一次点击「返回原地」就按旧动作执行、
		-- 表现为初次点击失效（用户 2026-10-30）。延迟 0.2s 等服务器侧社区状态落定。
		if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
			if WorldMapFrame and WorldMapFrame:IsShown() then QueuePanelRefresh({ delay = 0.2 }) end
		end
	end
	if event == "ADDON_LOADED" and arg1 == "Blizzard_WorldMap" then
		-- Late-load: attach our OnShow hook once the World Map exists
		if WorldMapFrame and not WorldMapFrame._adePortalTabTeleportHook then
			WorldMapFrame:HookScript("OnShow", function()
				if addon.db and addon.db["teleportsWorldMapEnabled"] then
					f:TryInit()
					if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end
					if f._selectOnNextShow and not IsPanelSuppressed() and SetTeleportDisplayMode() then f._selectOnNextShow = nil end
					QueuePanelRefresh({ delay = 0, invalidate = true })
				else
					if panel then SafeSetVisible(panel, false) end
					if tabButton then SafeSetVisible(tabButton, false) end
				end
			end)
			WorldMapFrame._adePortalTabTeleportHook = true
		end
		return
	end

	-- Only refresh when the map is actually visible; avoid work while hidden
	if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
	if event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
		QueuePanelRefresh({ cooldownOnly = true, delay = 0.03 })
	elseif event == "SPELLS_CHANGED" or event == "BAG_UPDATE_DELAYED" or event == "TOYS_UPDATED" then
		if addon.db and addon.db["teleportsWorldMapEnabled"] then QueuePanelRefresh({ invalidate = true, delay = 0.1 }) end
	end
end

function addon.MapPanel.Initialize()
	if addon.State.worldMapTeleportInitialized then return end
	if not addon.db then return end
	addon.State.worldMapTeleportInitialized = true

	f:SetScript("OnEvent", worldMapEventHandler)
	setWorldMapTeleportEventsEnabled(addon.db["teleportsWorldMapEnabled"])

	-- make sure we also initialize when the WorldMap opens
	if WorldMapFrame and not WorldMapFrame._adePortalTabTeleportHook then
		WorldMapFrame:HookScript("OnShow", function()
			if addon.db and addon.db["teleportsWorldMapEnabled"] then
				f:TryInit()
				if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end
				if f._selectOnNextShow and not IsPanelSuppressed() and SetTeleportDisplayMode() then f._selectOnNextShow = nil end
				QueuePanelRefresh({ delay = 0, invalidate = true })
			else
				if panel then SafeSetVisible(panel, false) end
				if tabButton then SafeSetVisible(tabButton, false) end
			end
		end)
		WorldMapFrame._adePortalTabTeleportHook = true
	end
end

-- Export a small helper so options code can trigger a live refresh
function addon.MapPanel.Refresh()
	if not addon or not addon.db then return end
	setWorldMapTeleportEventsEnabled(addon.db["teleportsWorldMapEnabled"])
	InvalidateCompendiumCache()

	-- Proactively load the World Map addon so our hooks exist
	-- 12.x 已移除 UIParentLoadAddOn；改用命名空间 API（实证 ade_BaseFramework/function/AddonStatus.lua:121）。
	if not WorldMapFrame then pcall(C_AddOns.LoadAddOn, "Blizzard_WorldMap") end

	if WorldMapFrame then
		-- Ensure our OnShow hook is installed even if we missed initial load timing
		if not WorldMapFrame._adePortalTabTeleportHook then
			WorldMapFrame:HookScript("OnShow", function()
				if addon.db and addon.db["teleportsWorldMapEnabled"] then
					f:TryInit()
					if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end
					if f._selectOnNextShow and not IsPanelSuppressed() and SetTeleportDisplayMode() then f._selectOnNextShow = nil end
					QueuePanelRefresh({ delay = 0, invalidate = true })
				else
					if panel then SafeSetVisible(panel, false) end
					if tabButton then SafeSetVisible(tabButton, false) end
				end
			end)
			WorldMapFrame._adePortalTabTeleportHook = true
		end

		-- Always ensure our UI is injected and tabs validated, even if hidden
		f:TryInit()
		if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end

		if not addon.db["teleportsWorldMapEnabled"] then
			if IsTeleportDisplayModeActive() then
				if QuestMapFrame.MapLegendTab and QuestMapFrame.MapLegendTab.Click then
					QuestMapFrame.MapLegendTab:Click()
				elseif QuestMapFrame.QuestsTab and QuestMapFrame.QuestsTab.Click then
					QuestMapFrame.QuestsTab:Click()
				end
			end
			if panel then SafeSetVisible(panel, false) end
			if tabButton then SafeSetVisible(tabButton, false) end
			return
		end

		if WorldMapFrame:IsShown() then
			if IsPanelSuppressed() then
				ApplySuppressedPanelState()
				return
			end
			if tabButton then SafeSetVisible(tabButton, true) end
			if ShouldAutoSelectDefaultTab() then SetTeleportDisplayMode() end
			QueuePanelRefresh({ delay = 0, invalidate = true })
		else
			f._selectOnNextShow = ShouldAutoSelectDefaultTab()
		end
	end
end

-- 供地图左上角区域传送按钮复用：施法属性、冷却、提示、右键定位都只保留一份实现。
function addon.MapPanel.ConfigureAction(button, entry)
	ConfigureButtonTeleportAction(button, entry)
end

function addon.MapPanel.ApplyCooldown(button)
	ApplyCooldownToButton(button)
end

function addon.MapPanel.StyleCooldown(cooldown, swipeFile)
	if not cooldown then return end
	cooldown:SetSwipeColor(0, 0, 0, 0.35)
	cooldown:SetUseCircularEdge(true)
	cooldown:SetDrawEdge(false)
	cooldown:SetDrawBling(false) -- 避免金色闪光溢出图标
	SetCompactCountdownFont(cooldown)
	-- swipe 暗区形状由所传纹理的 alpha 通道决定（默认 star4 即方形——用户 2026-11-17：
	-- 圆形按钮的 CD 阴影仍是方形的）。区域按钮换用同形状遮罩纹理（commonmaskcircle /
	-- common-iconmask，白形+透明外围）。注意 swipe 是引擎内部纹理，GetRegions 取不到、
	-- AddMaskTexture 无效（首轮方案实测无效），只能换纹理：SetSwipeTexture（API 实证
	-- FrameAPICooldownDocumentation:526，SecretArguments AllowedWhenUntainted，插件上下文可调）。
	if swipeFile then
		cooldown:SetSwipeTexture(swipeFile, 0, 0, 0, 0.35)
	end
end

function addon.MapPanel.ShowTooltip(button, entry)
	if not addon.db["portalShowTooltip"] then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	if entry.isToy then
		GameTooltip:SetToyByItemID(entry.toyID)
	elseif entry.isItem then
		GameTooltip:SetItemByID(entry.itemID)
	else
		GameTooltip:SetSpellByID(entry.spellID)
	end
	AddVariantTooltipLine(entry)
	-- 目的地一行放在收藏提示的上面（用户 2026-10-29）。
	AddDestinationTooltipLine(entry)
	AddFavoriteTooltipLine()
	GameTooltip:Show()
end

function addon.MapPanel.IsSuppressed()
	return isRestrictedContent()
end

function addon.MapPanel.Open(force)
	if not addon or not addon.db or not addon.db["teleportsWorldMapEnabled"] then return end
	if not force and InCombatLockdown and InCombatLockdown() then
		f._pendingOpen = true
		return
	end
	if IsPanelSuppressed() then
		ApplySuppressedPanelState()
		return
	end

	-- 12.x 已移除 UIParentLoadAddOn；改用命名空间 API（实证 ade_BaseFramework/function/AddonStatus.lua:121）。
	if not WorldMapFrame then pcall(C_AddOns.LoadAddOn, "Blizzard_WorldMap") end
	if f and f.TryInit then f:TryInit() end

	if not WorldMapFrame then return end

	local playerMapID = GetPlayerMapID()
	local function shouldOpenQuestLog()
		if not WorldMapFrame then return false end
		if not WorldMapFrame:IsShown() then return true end
		if WorldMapFrame.IsMinimized and WorldMapFrame:IsMinimized() then
			if WorldMapFrame.IsSidePanelShown and not WorldMapFrame:IsSidePanelShown() then return true end
		end
		return false
	end

	if WorldMapFrame and WorldMapFrame.HandleUserActionOpenQuestLog and shouldOpenQuestLog() then
		WorldMapFrame:HandleUserActionOpenQuestLog(playerMapID)
	elseif not WorldMapFrame:IsShown() then
		if ToggleWorldMap then
			ToggleWorldMap()
		else
			ShowUIPanel(WorldMapFrame)
		end
	end

	if not SetTeleportDisplayMode() then f._selectOnNextShow = true end

	if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end
	if f and f.RefreshPanel then QueuePanelRefresh({ delay = 0 }) end
end
