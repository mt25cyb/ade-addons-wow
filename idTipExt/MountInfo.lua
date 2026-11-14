----------------------------------------------------------------------------
-- idTipExt 坐骑信息子模块（收藏状态 / 来源 / 故事）
-- 只提供「显示坐骑信息」附属选项及其子项；坐骑ID / 法术ID 仍由 Core+Base 提供，本模块不写这两行。
-- API 依据：
--   C_MountJournal.GetMountFromSpell / GetMountFromItem（Warcraft Wiki: API C_MountJournal.GetMountFromSpell / GetMountFromItem）
--   C_MountJournal.GetMountInfoByID 第 11 返回值 isCollected（Warcraft Wiki: API C_MountJournal.GetMountInfoByID）
--   C_MountJournal.GetMountInfoExtraByID 第 2/3 返回值 description / source
--     （Warcraft Wiki: API C_MountJournal.GetMountInfoExtraByID；Gethe/wow-ui-source:Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:736）
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
local L = ns.L.MountInfo

local TD = Enum and Enum.TooltipDataType
local GetMountFromSpell = C_MountJournal and C_MountJournal.GetMountFromSpell
local GetMountFromItem = C_MountJournal and C_MountJournal.GetMountFromItem
local GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID
local GetMountInfoExtraByID = C_MountJournal and C_MountJournal.GetMountInfoExtraByID
local GetAuraDataByAuraInstanceID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
local AURA_TYPE = TD and TD.UnitAura or 7

local mountIDCache = {}  -- [spellID 或 itemID] = mountID 或 false
local mountDataCache = {} -- [mountID] = { collected, source, lore }
local COLOR_COLLECTED = { 0, 1, 0 }     -- 已收藏：绿色
local COLOR_NOT_OWNED = { 1, 0.25, 0.25 } -- 未拥有：红色

local db = ns.db

local prefixRGB = ns.prefixColor

-- 提示框行文本查重统一走 Core 公共设施
local hasLeftText = ns.hasTooltipText

local function addLine(tooltip, name, text, r, g, b, wrap)
	if not text or text == "" or hasLeftText(tooltip, name, text) then return end
	tooltip:AddLine(text, r, g, b, wrap)
end

local function addDoubleLine(tooltip, name, left, right, pr, pg, pb, rr, rg, rb)
	if hasLeftText(tooltip, name, left) then return end
	tooltip:AddDoubleLine(left, right, pr, pg, pb, rr or 1, rg or 1, rb or 1)
end

-- UnitAura 的 data.id 可能是 auraInstanceID，需还原为 spellID
-- （Warcraft Wiki: API C_UnitAuras.GetAuraDataByAuraInstanceID）
local function auraSpellID(tooltip, data)
	if data.spellId and not ns.isSecret(data.spellId) then return tonumber(data.spellId) end
	if data.spellID and not ns.isSecret(data.spellID) then return tonumber(data.spellID) end

	local unit = data.unitToken or data.unit
	if (not unit or ns.isSecret(unit)) and tooltip and tooltip.GetUnit then
		local ok, _, token = pcall(tooltip.GetUnit, tooltip)
		if ok and token and not ns.isSecret(token) and UnitExists and UnitExists(token) then unit = token end
	end
	if not unit and UnitExists and UnitExists("mouseover") then unit = "mouseover" end
	if unit and GetAuraDataByAuraInstanceID and data.id then
		local ok, aura = pcall(GetAuraDataByAuraInstanceID, unit, data.id)
		if ok and type(aura) == "table" and aura.spellId and not ns.isSecret(aura.spellId) then
			return tonumber(aura.spellId)
		end
	end
	return tonumber(data.id)
end

-- 由 tooltip 的 id 解析坐骑ID：物品/玩具走 GetMountFromItem，其余走 GetMountFromSpell；
-- 兼容 data.id 本身已是 mountID 的情况（Core.lua:373 的 mount→spell 级联即把该值当 mountID）
local function resolveMountID(tooltip, data, typeID, itemTypes)
	if not data or ns.isSecret(data.type) or ns.isSecret(data.id) then return nil end
	local id = (typeID == AURA_TYPE) and auraSpellID(tooltip, data) or tonumber(data.id)
	if not id then return nil end

	local cacheKey = (itemTypes[typeID] and "i" or "s") .. id
	local cached = mountIDCache[cacheKey]
	if cached ~= nil then return cached or nil end

	local mountID
	local getter = itemTypes[typeID] and GetMountFromItem or GetMountFromSpell
	if getter then
		local ok, result = pcall(getter, id)
		if ok and type(result) == "number" and result ~= 0 then mountID = result end
	end
	if not mountID and GetMountInfoByID then
		local ok, name = pcall(GetMountInfoByID, id)
		if ok and name then mountID = id end
	end

	mountIDCache[cacheKey] = mountID or false
	return mountID
end

local function getMountData(mountID)
	local cached = mountDataCache[mountID]
	if cached then return cached end

	-- 返回值顺序（Warcraft Wiki: API C_MountJournal.GetMountInfoByID）：name, spellID, icon, isActive, isUsable,
	-- sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, ...
	local ok, name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
		isFactionSpecific, faction, shouldHideOnChar, isCollected = pcall(GetMountInfoByID, mountID)
	if not ok then return nil end

	local source, lore
	if GetMountInfoExtraByID then
		local okExtra, _, description, sourceText = pcall(GetMountInfoExtraByID, mountID)
		if okExtra then
			if type(sourceText) == "string" and sourceText ~= "" then source = sourceText end
			if type(description) == "string" and description ~= "" then lore = description end
		end
	end

	local data = { collected = isCollected and true or false, source = source, lore = lore }
	mountDataCache[mountID] = data
	return data
end

local function process(tooltip, data, typeID, itemTypes)
	if not db().mountInfoEnabled then return end
	if not tooltip or not data then return end
	if InCombatLockdown and InCombatLockdown() then return end -- 战斗中不改提示框
	if not GetMountInfoByID then return end

	local mountID = resolveMountID(tooltip, data, typeID, itemTypes)
	if not mountID then return end
	local info = getMountData(mountID)
	if not info then return end

	local okName, name = pcall(tooltip.GetName, tooltip)
	if not okName then return end
	local pr, pg, pb = prefixRGB()

	-- 可选：坐骑信息前补一空行做分隔（与坐骑ID行隔开；确认至少有一段会显示才加）
	local willShow = db().mountCollectedEnabled
		or (db().mountSourceEnabled and info.source)
		or (db().mountSourceEnabled and db().mountLoreEnabled and info.lore)
	if db().mountInfoBlankLine and willShow then
		tooltip:AddLine(" ")
	end

	-- 收藏状态：跟随全局显示风格；已收藏绿色、未拥有红色
	if db().mountCollectedEnabled then
		local status = info.collected and L.Collected or L.NotOwned
		local color = info.collected and COLOR_COLLECTED or COLOR_NOT_OWNED
		if db().style == "single" then
			-- 单段式整行只支持一个颜色，用色码单独给状态文本着色
			addLine(tooltip, name,
				L.CollectedPrefix .. " " .. ns.colorize(status, color[1], color[2], color[3]), pr, pg, pb)
		else
			addDoubleLine(tooltip, name, L.CollectedPrefix, status,
				pr, pg, pb, color[1], color[2], color[3])
		end
	end

	-- 来源 / 故事：固定单段式显示，前缀与内容分两行；内容不存在时不显示
	if db().mountSourceEnabled and info.source then
		addLine(tooltip, name, L.SourcePrefix, pr, pg, pb)
		addLine(tooltip, name, info.source, 1, 1, 1, true)
	end
	if db().mountSourceEnabled and db().mountLoreEnabled and info.lore then
		addLine(tooltip, name, L.LorePrefix, pr, pg, pb)
		addLine(tooltip, name, info.lore, 1, 1, 1, true)
	end
end

if TooltipDataProcessor and TD then
	local itemTypes = { [TD.Item or 0] = true, [TD.Toy or 19] = true }
	local registered = {}
	for _, typeID in ipairs({ TD.Item or 0, TD.Spell or 1, TD.UnitAura or 7, TD.Mount or 10, TD.Toy or 19 }) do
		if type(typeID) == "number" and not registered[typeID] then
			registered[typeID] = true
			TooltipDataProcessor.AddTooltipPostCall(typeID, function(tooltip, data)
				process(tooltip, data, typeID, itemTypes)
			end)
		end
	end
end
