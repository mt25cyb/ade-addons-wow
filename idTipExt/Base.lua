----------------------------------------------------------------------------
-- idTipExt 基础模块：TDP 数据驱动 + SetX 钩子 + 声望面板直显 + 任务面板叠加
-- 基底：idTip 12.1.10（写入管线）；单位类排除策略：规避 secret 值污染处理链
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

local function add(tooltip, id, kind, opts)
	return ns.add(tooltip, id, kind, opts)
end

-- 单值 ID setter 钩子：统一 SetX → add 的样板
local function hookIdSetter(target, method, kind)
	ns.hook(target, method, function(tooltip, id) add(tooltip, id, kind) end)
end

local function addItemInfo(tooltip, link)
	return ns.addItemInfo(tooltip, link)
end

----------------------------------------------------------------------------
-- TooltipDataProcessor：逐类型注册，排除单位类
-- 单位/尸体/宠物类的 TDP 处理链与暴雪血条同链执行且无隔离，插件回调
-- 一旦运行即污染整链（"secret number tainted by ..." → 专业面板 ADDON_ACTION_BLOCKED）。
-- 这些类型的 ID 由下方 OnTooltipSetUnit 脚本钩子负责。
----------------------------------------------------------------------------

if TooltipDataProcessor then
	local kindsByID = {
		[0]  = "item",        -- Item
		[1]  = "spell",       -- Spell
		[2]  = "unit",        -- Unit（不注册，走 OnTooltipSetUnit）
		[3]  = "unit",        -- Corpse（不注册）
		[4]  = "object",      -- Object
		[5]  = "currency",    -- Currency
		[7]  = "spell",       -- UnitAura
		[8]  = "spell",       -- AzeriteEssence
		[9]  = "species",     -- CompanionPet（不注册，SetCompanionPet 钩子负责）
		[10] = "mount",       -- Mount
		[11] = "spell",       -- PetAction
		[12] = "achievement", -- Achievement
		[13] = "spell",       -- EnhancedConduit
		[14] = "set",         -- EquipmentSet
		[17] = "spell",       -- RecipeRankInfo
		[18] = "spell",       -- Totem
		[19] = "item",        -- Toy
		[23] = "quest",       -- Quest
		[24] = "quest",       -- QuestPartyProgress
		[25] = "macro",       -- Macro
	}

	local function postCall(tooltip, data)
		if not data or not data.type then return end
		if ns.isSecret(data.type) or ns.isSecret(data.guid) then return end -- 索引 secret 会报错
		local kind = kindsByID[tonumber(data.type)]
		if not kind then return end

		if kind == "item" then
			-- 链接携带 data.id 缺失的 id，guid 解析真实物品实例，优先级同 TooltipUtil.GetDisplayedItem
			local link = (data.guid and GetItemLinkByGUID and GetItemLinkByGUID(data.guid)) or data.hyperlink
			if not link and tooltip.GetItem then link = select(2, tooltip:GetItem()) end
			if addItemInfo(tooltip, link) == nil then add(tooltip, data.id, kind) end
		else
			add(tooltip, data.id, kind)
		end
	end

	local TD = Enum and Enum.TooltipDataType
	if TD then
		local skip = {
			[TD.Unit] = true,
			[TD.Corpse] = true,
			[TD.BattlePet] = true,
			[TD.CompanionPet] = true,
			[TooltipDataProcessor.AllTypes] = true,
		}
		for _, typeID in pairs(TD) do
			-- Enum 为双向表，只取数字方向；跳过单位类与 AllTypes 哨兵
			if type(typeID) == "number" and not skip[typeID] then
				TooltipDataProcessor.AddTooltipPostCall(typeID, postCall)
			end
		end
	else
		TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, postCall)
	end
end

----------------------------------------------------------------------------
-- OnTooltipSetUnit：NPC ID + 野生宠物物种 ID
-- 经典脚本钩子用 UnitGUID 解析最可靠
----------------------------------------------------------------------------

ns.hookScript(GameTooltip, "OnTooltipSetUnit", function(tooltip)
	local unit = select(2, tooltip:GetUnit())
	if unit and UnitGUID then
		local guid = UnitGUID(unit)
		if ns.addNpc(tooltip, guid) then tooltip:Show() end
		if ns.collect(tooltip, ns.wildPetSpecies(guid), "species") then tooltip:Show() end
	end
end)

----------------------------------------------------------------------------
-- SetX 钩子（12.x 修正版）
----------------------------------------------------------------------------

-- 超链接：enchant/trade 实为法术，equipmentset 实为套装
local function onSetHyperlink(tooltip, link)
	local kind, id = string.match(link, "^(%a+):(%d+)")
	if not kind then return end
	if kind == "enchant" or kind == "trade" then kind = "spell" end
	if kind == "equipmentset" then kind = "set" end
	if ns.kinds[kind] then add(tooltip, id, kind) end
end
ns.hook(GameTooltip, "SetHyperlink", onSetHyperlink)
ns.hook(ItemRefTooltip, "SetHyperlink", onSetHyperlink)

-- 对比提示框：走链接还原真实物品实例
ns.hook(ItemRefTooltip, "SetHyperlinkCompareItem", function(tooltip, link)
	if link then addItemInfo(tooltip, link) end
end)

if GetActionInfo then
	ns.hook(GameTooltip, "SetAction", function(tooltip, slot)
		local kind, id = GetActionInfo(slot)
		if kind == "macro" then
			-- 宏提示解析真实法术ID；12.x 的 GetMacroSpell 直接返回 spellID
			-- （依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_ActionBar/WoWLabs/ActionButtonOverrides.lua:115）
			if id then
				local spellID = GetMacroSpell and GetMacroSpell(id)
				if type(spellID) == "number" then
					add(tooltip, spellID, "spell")
					return
				end
			end
			if tooltip.GetPrimaryTooltipData then
				local data = tooltip:GetPrimaryTooltipData()
				if data and data.lines and data.lines[1] and data.lines[1].tooltipID then
					add(tooltip, data.lines[1].tooltipID, "spell")
					return
				end
			end
			if tooltip.GetSpell then
				local spellID = select(2, tooltip:GetSpell())
				if spellID then add(tooltip, spellID, "spell") end
			end
		elseif ns.kinds[kind] then
			add(tooltip, id, kind) -- 其余动作类型不携带我们标注的 ID
		end
	end)
end

if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink then
	ns.hook(GameTooltip, "SetCurrencyToken", function(tooltip, index)
		local link = C_CurrencyInfo.GetCurrencyListLink(index)
		add(tooltip, link and tonumber(link:match("currency:(%d+)")), "currency")
	end)
end

-- SetCurrencyToken 只覆盖代币界面，其他货币入口无脚本触发
hookIdSetter(GameTooltip, "SetCurrencyByID", "currency")

hookIdSetter(GameTooltip, "SetCurrencyTokenByID", "currency")

-- 法术：SetSpellByID / 法术书
hookIdSetter(GameTooltip, "SetSpellByID", "spell")

-- 显示施法者：法术ID 的附属选项（unittokenEnabled，独立控制，不与法术ID 开关联动）
-- 12.x 光环数据由 C_UnitAuras.GetAuraDataByIndex 返回，施法者字段为 auraData.sourceUnit
-- （依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua:129、Gethe/wow-ui-source:Interface/AddOns/Blizzard_UnitFrame/Shared/TargetFrameAuraContainer.lua:395）
if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
	local function addCaster(tooltip, unit, index, filter)
		if not ns.isEnabled("unittoken") then return end
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
		if not ok or type(aura) ~= "table" then return end
		local source = aura.sourceUnit
		if not source or ns.isSecret(source) then return end
		local okName, name = pcall(UnitName, source)
		if not okName or type(name) ~= "string" or name == "" then name = source end
		if type(name) == "string" and not ns.isSecret(name) then
			-- 前缀按职业着色时，施法者行用施法者自身职业；值色由独立开关控制
			local opts = { unit = source }
			if idTipExtDB.casterClassColorEnabled then
				local r, g, b, hex = ns.classColor(source)
				if r then
					opts.valueRGB = { r, g, b }
					opts.valueColorStr = hex
				end
			end
			add(tooltip, name, "unittoken", opts)
		end
	end

	local function hookCaster(method)
		ns.hook(GameTooltip, method, function(tooltip, unit, index, filter)
			addCaster(tooltip, unit, index, filter)
		end)
	end
	hookCaster("SetUnitAura")
	hookCaster("SetUnitBuff")
	hookCaster("SetUnitDebuff")
end

if GetSpellBookItemInfo then
	ns.hook(GameTooltip, "SetSpellBookItem", function(tooltip, slot, bookType)
		local spellType, spellID = GetSpellBookItemInfo(slot, bookType)
		if spellID and spellType ~= "FUTURESPELL" then
			add(tooltip, spellID, "spell")
		end
	end)
end

if SpellBook_GetSpellBookSlot then
	ns.hook(_G, "SpellButton_OnEnter", function(btn)
		local slot = SpellBook_GetSpellBookSlot(btn)
		if not slot then return end
		local spellType, spellID = GetSpellBookItemInfo and GetSpellBookItemInfo(slot, SpellBookFrame.bookType)
		if spellID and spellType ~= "FUTURESPELL" then
			add(GameTooltip, spellID, "spell")
		end
	end)
end

-- 配方：结果物品带 Item 数据，法术只能从这里拿
hookIdSetter(GameTooltip, "SetRecipeResultItem", "spell")

hookIdSetter(GameTooltip, "SetRecipeRankInfo", "spell")

hookIdSetter(GameTooltip, "SetRecipeReagentItem", "item")

-- 神器能量：无 TooltipDataType 覆盖，setter 是唯一来源；顺带取法术ID
if C_ArtifactUI and C_ArtifactUI.GetPowerInfo then
	ns.hook(GameTooltip, "SetArtifactPowerByID", function(tooltip, powerID)
		local powerInfo = C_ArtifactUI.GetPowerInfo(powerID)
		add(tooltip, powerID, "artifactpower")
		add(tooltip, powerInfo and powerInfo.spellID, "spell")
	end)
end

-- 天赋：正式服天赋是特质树（TalentDisplayMixin 覆盖），SetTalent/SetPvpTalent 仍存在
hookIdSetter(GameTooltip, "SetTalent", "talent")

hookIdSetter(GameTooltip, "SetPvpTalent", "talent")

-- 玩具 / 任务奖励物品（12.x 参数捕获修正）
hookIdSetter(GameTooltip, "SetToyByItemID", "item")

if GetQuestItemLink then
	ns.hook(GameTooltip, "SetQuestItem", function(tooltip, itemType, index)
		local link = GetQuestItemLink(itemType, index)
		if link then addItemInfo(tooltip, link) end
	end)
end

if GetQuestLogItemLink then
	ns.hook(GameTooltip, "SetQuestLogItem", function(tooltip, itemType, index)
		local link = GetQuestLogItemLink(itemType, index)
		if link then addItemInfo(tooltip, link) end
	end)
end

-- 嵌入式任务奖励提示框：参数布局各版本不一，双重取法兜底
if EmbeddedItemTooltip and EmbeddedItemTooltip.SetItemByQuestReward and GetQuestItemLink then
	ns.hook(EmbeddedItemTooltip, "SetItemByQuestReward", function(tooltip, questID, index)
		local link
		if type(index) == "number" then
			link = GetQuestItemLink("reward", index)
		elseif type(questID) == "number" then
			link = GetQuestItemLink("reward", questID)
		end
		if link then addItemInfo(tooltip, link) end
	end)
end

-- 小宠物
if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
	ns.hook(GameTooltip, "SetCompanionPet", function(_tooltip, petId)
		local speciesId = C_PetJournal.GetPetInfoByPetID(petId)
		if not speciesId then return end
		add(GameTooltip, speciesId, "species")
		if C_PetJournal.GetPetInfoBySpeciesID then
			add(GameTooltip, select(4, C_PetJournal.GetPetInfoBySpeciesID(speciesId)), "unit")
		end
	end)
end

-- 特质树：entryID / definitionID / nodeID
if TalentDisplayMixin then
	ns.hook(TalentDisplayMixin, "SetTooltipInternal", function(button)
		if not button then return end
		add(GameTooltip, button.entryID, "traitentry")
		add(GameTooltip, button.definitionID, "traitdef")
		local nodeInfo = button.GetNodeInfo and button:GetNodeInfo()
		add(GameTooltip, nodeInfo and nodeInfo.ID, "traitnode")
	end)
end

-- 任务地图 POI / 任务日志标题
ns.hook(_G, "TaskPOI_OnEnter", function(button)
	if button and button.questID then add(GameTooltip, button.questID, "quest") end
end)

if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
	ns.hook(_G, "QuestMapLogTitleButton_OnEnter", function(button)
		add(GameTooltip, C_QuestLog.GetQuestIDForLogIndex(button.questLogIndex), "quest")
	end)
end

-- 地图图钉：空图钉不弹提示框，所有权是唯一信号；同时覆盖世界地图与小说地图
local function pinTooltip(pin)
	if not pin then return end
	for _, tooltip in ipairs({ GameTooltip, WorldMapTooltip }) do
		if tooltip:IsShown() and tooltip:IsOwned(pin) then return tooltip end
	end
end

ns.hook(AreaPOIPinMixin, "TryShowTooltip", function(pin)
	local tooltip = pinTooltip(pin)
	if tooltip then
		add(tooltip, pin.areaPoiID or pin.poiInfo and pin.poiInfo.areaPoiID, "areapoi")
	end
end)

ns.hook(VignettePinMixin, "OnMouseEnter", function(pin)
	local tooltip = pinTooltip(pin)
	if tooltip and pin.vignetteInfo then add(tooltip, pin.vignetteInfo.vignetteID, "vignette") end
end)

-- 幻化外观（收藏界面 / 幻化 NPC，无需 Blizzard_Collections）
ns.hook(CollectionWardrobeUtil, "SetAppearanceTooltip", function(_tooltip, appearanceData)
	local sources = appearanceData and appearanceData.sources
	if not sources then return end

	local visualIDs, sourceIDs, itemIDs = {}, {}, {}
	for _, source in ipairs(sources) do
		ns.addUnique(visualIDs, source.visualID)
		ns.addUnique(sourceIDs, source.sourceID)
		ns.addUnique(itemIDs, source.itemID)
	end

	add(GameTooltip, visualIDs, "visual")
	add(GameTooltip, sourceIDs, "source")
	add(GameTooltip, itemIDs, "item")
end)

-- 宠物对战技能：主提示框是裸 Frame，无行与单元格，只能追加到字体串
if C_PetBattles then
	local ally = Enum and Enum.BattlePetOwner and Enum.BattlePetOwner.Ally

	local function addPetBattleAbility(id)
		if not id then return end
		if not (ns.isStringOrNumber(id) and ns.isEnabled("ability")) then return end
		local description = PetBattlePrimaryAbilityTooltip and PetBattlePrimaryAbilityTooltip.Description
		if not description then return end
		description:SetText((description:GetText() or "") .. "\r\r" .. ns.kinds.ability .. ns.colorize(" " .. id, 1, 1, 1))
	end

	if C_PetBattles.GetAbilityInfo and C_PetBattles.GetActivePet then
		ns.hook(_G, "PetBattleAbilityButton_OnEnter", function(button)
			if button:GetEffectiveAlpha() > 0 then
				addPetBattleAbility(C_PetBattles.GetAbilityInfo(ally, C_PetBattles.GetActivePet(ally), button:GetID()))
			end
		end)
	end

	if C_PetBattles.GetAuraInfo then
		ns.hook(_G, "PetBattleAura_OnEnter", function(frame)
			local parent = frame:GetParent()
			addPetBattleAbility(C_PetBattles.GetAuraInfo(parent.petOwner, parent.petIndex, frame.auraIndex))
		end)
	end
end

----------------------------------------------------------------------------
-- 成就与条件（按条件类型反查真实序号）
----------------------------------------------------------------------------

local function achievementOnEnter(button)
	if not button or not button.id then return end
	if not ns.isEnabled("achievement") then return end
	GameTooltip:SetOwner(button, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
	ns.collect(GameTooltip, button.id, "achievement")
	GameTooltip:Show()
end

-- 暴雪按条件类型分池复用 frame，池序号只在成就不混类型时等于条件序号
local function criteriaIndex(achievementId, kind, poolIndex)
	if not GetAchievementNumCriteria or not GetAchievementCriteriaInfo then return end
	for index = 1, GetAchievementNumCriteria(achievementId) do
		local _, criteriaType, _, _, _, _, flags, assetId = GetAchievementCriteriaInfo(achievementId, index)
		local frameKind = criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetId and "metas"
			or bit.band(flags or 0, EVALUATION_TREE_FLAG_PROGRESS_BAR or 0) ~= 0 and "progressBars"
			or "criterias"
		if frameKind == kind then
			poolIndex = poolIndex - 1
			if poolIndex == 0 then return index end
		end
	end
end

local function criteriaOnEnter(frame)
	if not (ns.isEnabled("achievement") or ns.isEnabled("criteria")) then return end
	local button = frame:GetParent()
	while button and not button.id do button = button:GetParent() end
	if not button then return end
	local index = criteriaIndex(button.id, frame.idTipKind, frame.idTipIndex)
	if not index then return end -- 已释放的池 frame 带着成就已没有的序号
	local criteriaId = select(10, GetAchievementCriteriaInfo(button.id, index))
	if not criteriaId then return end
	if not GameTooltip:IsVisible() then GameTooltip:SetOwner(button:GetParent(), "ANCHOR_NONE") end
	GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
	ns.collect(GameTooltip, button.id, "achievement")
	ns.collect(GameTooltip, criteriaId, "criteria")
	GameTooltip:Show()
end

local function hookCriteria(frame, kind, index)
	if not frame then return end
	-- 11.2.0 起 tooltip 挂到条件的 Name 字体串，鼠标被行抢占；经典端无此键
	for _, target in ipairs({ frame, frame.Name }) do
		target.idTipIndex = index -- 池 frame 会以不同序号复用
		target.idTipKind = kind
		if not target.idTipHooked then
			-- 条件行默认可能关闭鼠标；只开 motion，点击继续落到成就按钮
			if target.SetMouseMotionEnabled then target:SetMouseMotionEnabled(true) end
			ns.hookScript(target, "OnEnter", criteriaOnEnter)
			ns.hookScript(target, "OnLeave", GameTooltip_Hide)
			target.idTipHooked = true
		end
	end
end

-- 按需加载的 UI：成就界面 / 要塞随从
ns.RegisterOnAddonLoaded(function(addon)
	if addon == "Blizzard_GarrisonUI" then
		ns.hook(_G, "AddAutoCombatSpellToTooltip", function(tooltip, info)
			if info and info.autoCombatSpellID then
				add(tooltip, info.autoCombatSpellID, "ability")
			end
		end)
	elseif addon == "Blizzard_AchievementUI" then
		if AchievementTemplateMixin then
			ns.hook(AchievementTemplateMixin, "OnEnter", achievementOnEnter)
			ns.hook(AchievementTemplateMixin, "OnLeave", GameTooltip_Hide)

			-- miniAchievements 是成就链更早的链接而非条件，不携带 ID
			local objectives = AchievementTemplateMixin.GetObjectiveFrame and AchievementTemplateMixin:GetObjectiveFrame()
			for method, kind in pairs({ GetCriteria = "criterias", GetMeta = "metas", GetProgressBar = "progressBars" }) do
				ns.hook(objectives, method, function(self, index)
					if self and self[kind] then hookCriteria(self[kind][index], kind, index) end
				end)
			end
		end
	elseif addon == "Blizzard_LegacySystem" then
		-- Forever 的成就卡片，除非它在其挂钩之后复制了 AchievementTemplateMixin
		local legacyMixin = LegacyChallengeTemplateMixin
		if legacyMixin and AchievementTemplateMixin and legacyMixin.OnEnter ~= AchievementTemplateMixin.OnEnter then
			ns.hook(legacyMixin, "OnEnter", achievementOnEnter)
			ns.hook(legacyMixin, "OnLeave", GameTooltip_Hide)
		end
	end
end)

----------------------------------------------------------------------------
-- 附加提示框扫描：兼容插件自建的 GameTooltip
----------------------------------------------------------------------------

local hookedTooltips = { [GameTooltip] = true }

local function hookAddonTooltip(tooltip)
	if not tooltip or hookedTooltips[tooltip] then return end
	hookedTooltips[tooltip] = true
	ns.hook(tooltip, "SetSpellBookItem", function(tt, slot, bookType)
		if GetSpellBookItemInfo then
			local spellType, spellID = GetSpellBookItemInfo(slot, bookType)
			if spellID and spellType ~= "FUTURESPELL" then add(tt, spellID, "spell") end
		end
	end)
	hookIdSetter(tooltip, "SetSpellByID", "spell")
	ns.hookScript(tooltip, "OnTooltipSetItem", function(tip)
		if tip.GetItem then addItemInfo(tip, select(2, tip:GetItem())) end
	end)
	ns.hookScript(tooltip, "OnTooltipSetSpell", function(tip)
		if tip.GetSpell then add(tip, select(2, tip:GetSpell()), "spell") end
	end)
	ns.hookScript(tooltip, "OnTooltipSetUnit", function(tip)
		if ns.inPetBattle() then return end
		local unit = select(2, tip:GetUnit())
		if unit and UnitGUID then ns.addNpc(tip, UnitGUID(unit)) end
	end)
end

local function scanAddonTooltips()
	local f = EnumerateFrames()
	while f do
		-- 受保护帧在安全代码路径下调 IsObjectType 会污染，pcall 失败即跳过该帧
		local ok, isTip = pcall(f.IsObjectType, f, "GameTooltip")
		if ok and isTip and not hookedTooltips[f] then
			hookAddonTooltip(f)
		end
		f = EnumerateFrames(f)
	end
end

local loggedIn = false
ns.RegisterOnAddonLoaded(function(addon)
	if addon == addonName then
		loggedIn = true
		scanAddonTooltips()
	elseif loggedIn then
		scanAddonTooltips()
	end
end)

----------------------------------------------------------------------------
-- 声望面板直显（12.x 新版滚动列表）
-- 挂载点依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ReputationFrame.lua:254
-- ReputationEntryMixin:Initialize(elementData)，self.factionID = elementData.factionID
-- 旧版 _G["ReputationBar"..i] 帧在 12.x 已不存在
----------------------------------------------------------------------------

local factionLabels = setmetatable({}, { __mode = "k" })

local function getFactionLabel(entry)
	local label = factionLabels[entry]
	if not label then
		label = entry:CreateFontString(nil, "OVERLAY")
		label:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
		label:SetTextColor(1, 1, 1)
		-- 锚到声望条左侧；条在 self.Content.ReputationBar
		local bar = entry.Content and entry.Content.ReputationBar
		if bar then
			label:SetPoint("RIGHT", bar, "LEFT", -6, 0)
		else
			label:SetPoint("RIGHT", entry, "RIGHT", -40, 0)
		end
		factionLabels[entry] = label
	end
	return label
end

local function updateFactionLabel(entry)
	local label = getFactionLabel(entry)
	if ns.isEnabled("faction") and entry.factionID then
		label:SetText(tostring(entry.factionID))
		label:Show()
	else
		label:Hide()
	end
end

local function hookReputationFrame()
	if not ReputationEntryMixin or ReputationEntryMixin.idTipHooked then return end
	ReputationEntryMixin.idTipHooked = true
	-- Initialize 在滚动复用/每次刷新时重跑，正好覆盖懒加载行
	ns.hook(ReputationEntryMixin, "Initialize", function(self)
		updateFactionLabel(self)
	end)
end

----------------------------------------------------------------------------
-- 任务面板叠加（12.x）
-- 挂载点依据：
-- 1) 全局函数 QuestMapFrame_ShowQuestDetails(questID)
--    （Gethe/wow-ui-source:Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua:993）
-- 2) NPC 任务对话框 GetQuestID()（Gethe/wow-ui-source:Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua）
----------------------------------------------------------------------------

local detailLabelFrame  -- 任务日志详情面板叠加
local dialogLabelFrame  -- NPC 任务对话框叠加

local function questOverlayEnabled()
	return ns.isEnabled("questOverlay")
end

local function createOverlayLabel(parent, anchorFrame, point, x, y)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(1, 1)
	local label = frame:CreateFontString(nil, "OVERLAY")
	label:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	label:SetTextColor(1, 1, 1)
	label:SetPoint("CENTER", anchorFrame, point, x, y)
	frame.label = label
	frame:Hide()
	return frame
end

-- 任务ID叠加：有效 ID 写入标签，否则隐藏
local function updateQuestLabel(overlay, id)
	if type(id) == "number" and id > 0 then
		overlay.label:SetText("QuestID: " .. id)
		overlay:Show()
	else
		overlay:Hide()
	end
end

local function hookQuestOverlay()
	-- 面板叠加走独立开关 questOverlay（默认关），不占用 quest 类型的提示框开关
	if QuestMapFrame and QuestMapFrame.DetailsFrame and not detailLabelFrame then
		detailLabelFrame = createOverlayLabel(QuestMapFrame.DetailsFrame, QuestMapFrame.DetailsFrame, "TOPRIGHT", -10, -8)
		ns.hook(_G, "QuestMapFrame_ShowQuestDetails", function(questID)
			if not questOverlayEnabled() then
				detailLabelFrame:Hide()
				return
			end
			updateQuestLabel(detailLabelFrame, questID)
		end)
	end

	if QuestFrame and not dialogLabelFrame then
		dialogLabelFrame = createOverlayLabel(QuestFrame, QuestFrame, "TOPLEFT", 100, -45)
		ns.hookScript(QuestFrame, "OnShow", function()
			if not questOverlayEnabled() or not GetQuestID then return end
			local qid = GetQuestID()
			updateQuestLabel(dialogLabelFrame, qid)
		end)
	end
end

-- 声望/任务叠加挂载：UIPanels_Game 启动即载，CharacterFrame 按需打开时兜底再挂一次
ns.RegisterOnAddonLoaded(function(addon)
	if addon == addonName or addon == "Blizzard_CharacterFrame" or addon == "Blizzard_UIPanels_Game" then
		hookReputationFrame()
		hookQuestOverlay()
	end
end)
