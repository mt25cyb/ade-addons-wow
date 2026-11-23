local _, addon = ...
local L = addon.L

-- 列表服务：将静态传送数据转成界面条目，不创建任何 Frame。
-- 统一处理名称、职业/种族、阵营、专业、拥有情况。
local teleportMapNameCache = {} -- 仅在本次登录内缓存，避免旧翻译跨会话残留。
local faction = select(2, UnitFactionGroup("player"))
local toyUsableCache, toyUsableCacheTime = {}, {}
local TOY_USABLE_CACHE_TTL = 2
local function cachedMapName(id)
	if not id then return nil end
	local cached = teleportMapNameCache[id]
	if cached then return cached end
	local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
	local name = info and info.name
	if name and name ~= "" then
		teleportMapNameCache[id] = name
		return name
	end
end
local function clearToyUsableCache()
	if wipe then
		wipe(toyUsableCache)
		wipe(toyUsableCacheTime)
	else
		for key in pairs(toyUsableCache) do
			toyUsableCache[key] = nil
		end
		for key in pairs(toyUsableCacheTime) do
			toyUsableCacheTime[key] = nil
		end
	end
end

function addon.Catalog.InvalidateCaches() clearToyUsableCache() end

-- 收藏与最近记录共用同一套条目键：各玩具/物品变体各自独立，整炉石池合并为一个键。
local HEARTHSTONE_KEY = "hearthstone:random"
local hearthstoneKeys
-- 懒构造：炉石数据在测试中晚于 Catalog 加载，提前构造会得到空表。
function addon.Catalog.GetHearthstoneKeys()
    if hearthstoneKeys then return hearthstoneKeys end
    hearthstoneKeys = {}
    for _, stone in ipairs(addon.HearthstoneData or {}) do
        hearthstoneKeys[(stone.isToy and "toy:" or "item:") .. tostring(stone.id)] = true
    end
    return hearthstoneKeys
end
addon.Catalog.HearthstoneKey = HEARTHSTONE_KEY

function addon.Catalog.EntryKey(entry)
    if entry.isRandomHearthstone then return HEARTHSTONE_KEY end
    if entry.isToy then return "toy:" .. tostring(entry.toyID) end
    if entry.isItem then return "item:" .. tostring(entry.itemID) end
    return "spell:" .. tostring(entry.spellID)
end

local function Favorites()
    if type(addon.db) ~= "table" then return nil end
    if type(addon.db.teleportFavorites) ~= "table" then addon.db.teleportFavorites = {} end
    return addon.db.teleportFavorites
end

function addon.Catalog.IsFavorite(entry)
    local favs = Favorites()
    if not favs or not entry then return false end
    return favs[addon.Catalog.EntryKey(entry)] == true
end

--- 切换条目的收藏状态，返回切换后是否为收藏。
function addon.Catalog.ToggleFavorite(entry)
    local favs = Favorites()
    if not favs or not entry then return false end
    local key = addon.Catalog.EntryKey(entry)
    if favs[key] then
        favs[key] = nil
    else
        favs[key] = true
    end
    return favs[key] == true
end

local pendingItemNames = {}
local loadedItemNames = {}
local function OriginalItemName(itemID, isToy)
	if not itemID then return UNKNOWNOBJECT or "Unknown" end
	local name = loadedItemNames[itemID] or C_Item.GetItemNameByID(itemID) or C_Item.GetItemInfo(itemID)
	if not name and isToy then
		local _, toyName = C_ToyBox.GetToyInfo(itemID)
		name = toyName
	end
	if name and name ~= "" then return name end
	if not pendingItemNames[itemID] then
		pendingItemNames[itemID] = true
		Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
			local loadedName = C_Item.GetItemNameByID(itemID) or C_Item.GetItemInfo(itemID)
			if loadedName and loadedName ~= "" then
				loadedItemNames[itemID] = loadedName
				if addon.MapPanel.Refresh then addon.MapPanel.Refresh() end
			end
		end)
	end
	return RETRIEVING_ITEM_INFO or UNKNOWNOBJECT or "Unknown"
end

local function isToyUsable(id)
	if id == nil then return false end
	local now = GetTime and GetTime() or 0

	local cached = toyUsableCache[id]
	if cached ~= nil then
		local cachedAt = toyUsableCacheTime[id] or 0
		if now == 0 or (cachedAt > 0 and (now - cachedAt) <= TOY_USABLE_CACHE_TTL) then return cached end
	end

	if not PlayerHasToy(id) then
		toyUsableCache[id] = false
		toyUsableCacheTime[id] = now
		return false
	end

	local tipData = C_TooltipInfo.GetToyByItemID(id)
	local lines = tipData and tipData.lines
	if lines then
		for i = 1, #lines do
			local line = lines[i]
			if line and line.type == 23 then
				local color = line.leftColor
				local usable = color and color.r == 1 and color.g == 1 and color.b == 1
				toyUsableCache[id] = usable and true or false
				toyUsableCacheTime[id] = now
				return toyUsableCache[id]
			end
		end
	end

	-- No requirement line means the toy is usable.
	toyUsableCache[id] = true
	toyUsableCacheTime[id] = now
	return true
end

local function checkProfession()
	-- Capture all profession slots into a table
	local professionIndices = { GetProfessions() }
	for _, profIndex in ipairs(professionIndices) do
		-- Only valid indices
		if profIndex and profIndex > 0 then
			local _, _, _, _, _, _, skillLine = GetProfessionInfo(profIndex)
			if skillLine == 202 then return true end
		end
	end
	return false
end

local GNOMISH = 20219
local GOBLIN = 20222
local function GetEngineeringBranch()
	if C_SpellBook.IsSpellKnown(GNOMISH, Enum.SpellBookSpellBank.Player) or C_SpellBook.IsSpellInSpellBook(GNOMISH, Enum.SpellBookSpellBank.Player, false) then
		return true, false -- Gnomish Engineering
	elseif C_SpellBook.IsSpellKnown(GOBLIN, Enum.SpellBookSpellBank.Player) or C_SpellBook.IsSpellInSpellBook(GOBLIN, Enum.SpellBookSpellBank.Player, false) then
		return false, true -- Goblin Engineering
	else
		return false, false -- 没有工程专精或没有学习工程学
	end
end

-- 数据目录只描述 action/destination/requirements；这里统一生成界面条目。
local function Destination(data)
 local destination = data.destination or {}
 return destination.mapID, destination.openMapID or destination.mapID, destination.x, destination.y
end

local function OriginalName(action, itemID)
 if action.type == "toy" or action.type == "item" then
  return OriginalItemName(itemID, action.type == "toy")
 end
 local info = C_Spell.GetSpellInfo(action.id)
 return info and info.name or UNKNOWNOBJECT or "Unknown"
end

local function DisplayName(data, itemID, mapID)
 local display = data.display or {}
 if type(display.forceName) == "string" then return display.forceName end
 if display.originName == true then return OriginalName(data.action, itemID) end
 if mapID then
  local name = cachedMapName(mapID)
  if name then return name end
 end
 return OriginalName(data.action, itemID)
end

local function Context()
 local engineering = checkProfession()
 local gnomish, goblin = false, false
 if engineering then gnomish, goblin = GetEngineeringBranch() end
 return {
  engineering = engineering, gnomish = gnomish, goblin = goblin,
 }
end

local function RequirementsMet(data, context)
 local r = data.requirements or {}
 if r.class and r.class ~= addon.Player.unitClass then return false end
 if r.race and r.race ~= addon.Player.unitRace then return false end
 if r.faction and r.faction ~= faction then return false end
 if r.engineering and not context.engineering then return false end
 if r.specialization and not context[r.specialization] then return false end
 return true
end

-- 收藏置顶：稳定分组，收藏条目提到本分类最前，两组内部各自保持数据库顺序。
local function FavoritesFirst(items)
 local favorites, others = {}, {}
 for _, item in ipairs(items) do
  if item.favorite then favorites[#favorites + 1] = item else others[#others + 1] = item end
 end
 for _, item in ipairs(others) do favorites[#favorites + 1] = item end
 return favorites
end

local function BuildEntries(section, context, includeUnavailable)
 local items = {}
 for _, data in ipairs(section.spells or {}) do
  local spellID = data.spellID
  local action = data.action
  local eligible = RequirementsMet(data, context)
  local ids = action.type == "item" and type(action.id) == "table" and action.id or { action.id }
  if action.classItems and not includeUnavailable then
   local classID = action.classItems[addon.Player.unitClass]
   ids = classID and { classID } or {}
  end
  local allIDs = ids
  if action.ownedVariantsOnly and not includeUnavailable then
   local owned = {}
   for _, id in ipairs(ids) do
    if C_Item.GetItemCount(id) > 0 then owned[#owned + 1] = id end
   end
   ids = #owned > 0 and owned or (#ids > 0 and { ids[1] } or {})
  end
  for _, id in ipairs(ids) do
   local owned
   if action.type == "toy" then owned = isToyUsable(id)
   elseif action.type == "item" then owned = C_Item.GetItemCount(id) > 0
   elseif action.type == "pet" then owned = (C_PetJournal.GetNumCollectedInfo(id) or 0) > 0
		else owned = C_SpellBook.IsSpellInSpellBook(id) end
  -- 家宅不看技能书，看房屋列表（异步返回）——用户 2026-10-28。
  if action.housing then owned = addon.Housing and addon.Housing.IsAvailable(action.housing) or false end
   local classAllowed = not action.classItems or action.classItems[addon.Player.unitClass] == id
   local known = owned and eligible and classAllowed or false
   if includeUnavailable or (eligible and classAllowed and (not addon.db.portalHideMissing or known)) then
    local nameMap, openMap, x, y = Destination(data)
    local icon = data.icon
    if not icon then
     if action.type == "toy" then local _, _, texture = C_ToyBox.GetToyInfo(id); icon = texture
     elseif action.type == "item" then local _, _, texture = C_Item.GetItemInfoInstant(id); icon = texture
     elseif action.type == "pet" then icon = select(2, C_PetJournal.GetPetInfoBySpeciesID(id))
		else local info = C_Spell.GetSpellInfo(id); icon = info and info.iconID end
    end
    local requirements = data.requirements or {}
    local item = {
     spellID = spellID, text = DisplayName(data, id, nameMap), iconID = icon, isKnown = known,
     isToy = action.type == "toy", toyID = action.type == "toy" and id or false,
     isItem = action.type == "item", itemID = action.type == "item" and id or false,
     equipSlot = action.equipSlot,
     isClassTP = requirements.class or false,
     -- 种族传送：与 isClassTP 对仗，供「区域传送按钮」的角色传送筛选使用（用户 2026-10-29）。
     isRaceTP = requirements.race or false,
     isRandomHearthstone = action.randomHearthstone or false,
     variantOtherCount = action.ownedVariantsOnly and #allIDs > #ids and (#allIDs - #ids) or nil,
     locID = openMap, x = x, y = y,
     -- 所属分组标题（如资料片名、首页），tooltip 里要显示「传送到 {分组} - {地图}」。
     sectionTitle = section and section.headline or nil,
     -- 角色分组（首页）标记为 true：tooltip 的目的地不拼分组前缀。
     isHomeSection = section and section.isHome or false,
    }
    -- 家宅标题跟着状态走：人在家就显示「离家归来」，否则显示阵营家宅
  -- （用户 2026-10-28，移植自 AstralGate Catalog.lua:203-206）。
  if action.housing then
    item.housingFaction = action.housing
    local canReturn = addon.Housing and addon.Housing.CanReturn(action.housing)
    item.text = canReturn and L["housingReturn"]
     or (action.housing == "Alliance" and L["housingAlliance"] or L["housingHorde"])
    -- 「在家」时这个按钮点下去是「返回原地」，换用返回原地的图标；
    -- 没在家（或另一个阵营的按钮）保持各自的家宅图标（用户 2026-10-29）。
    if canReturn then item.iconID = 236372 end
  end
  item.entryKey = addon.Catalog.EntryKey(item)
    item.favorite = addon.Catalog.IsFavorite(item)
	if action.type == "pet" then
		item.petSpeciesID = id
		item.text = C_PetJournal.GetPetInfoBySpeciesID(id)
		item.spellID = data.spellID or 0
		item.destinations = data.destinations   -- 宠物可召唤至的目的地（如熊猫人各副本入口）
	end
    items[#items + 1] = item
   end
  end
 end
 return FavoritesFirst(items)
end

--[[ 传送播报的单一查询入口（v6.5-r004）。
返回 nil 表示该 spellID 不可播报（既不在主表也不在补充表）；否则返回：
  { destination = 本地化目的地名, item = 物品ID 或 nil,
    keystone = bool, heartstone = bool }
来源优先级（与 UI tooltip 的 DestinationName 一致）：
  extras 自带双语文案 > DestinationOverrides(name/nameFn) > 主表 destination.mapID 地图名。
可播报集合 = 主表 TeleportData 全部 spellID + extras（主表未收录的老传送）。
不纳入 HearthstoneData：随机炉石池原本就不在原播报白名单（仅要塞/达拉然两个
固定目的地炉石在 TeleportData 里，靠 flags.heartstone 过滤），全量纳入会扩大播报范围。
这样新增传送只要写进 TeleportData 即自动进入播报，无需再维护独立白名单。 ]]
local announceIndex
local function BuildAnnounceIndex()
	if announceIndex then return announceIndex end
	announceIndex = {}
	for _, section in ipairs(addon.TeleportData or {}) do
		for _, data in ipairs(section.spells or {}) do
			-- spellID 0 是宠物等无施法条目的占位（BuildEntries 里 data.spellID or 0），不可播报。
			if data.spellID and data.spellID > 0 then
				local entry = announceIndex[data.spellID]
				if not entry then entry = {}; announceIndex[data.spellID] = entry end
				entry.data = data
			end
		end
	end
	for spellID, extra in pairs(addon.TeleportAnnouncerExtras or {}) do
		local entry = announceIndex[spellID]
		if not entry then entry = {}; announceIndex[spellID] = entry end
		entry.extra = extra
	end
	return announceIndex
end

function addon.Catalog.InvalidateAnnounceIndex()
	announceIndex = nil
end

local function AnnounceItemID(entry)
	local extra = entry.extra
	if extra and extra.item then return extra.item end
	local data = entry.data
	if not data then return nil end
	local action = data.action or {}
	if type(action.id) == "number" and (action.type == "item" or action.type == "toy") then
		return action.id
	end
	-- 多物品变体（如传送戒指）取第一项，与原白名单展示策略一致。
	if type(action.id) == "table" and action.id[1] and (action.type == "item" or action.type == "toy") then
		return action.id[1]
	end
	return nil
end

local function AnnounceDestination(entry, spellID)
	local extra = entry.extra
	if extra then
		local name = (GetLocale() == "zhCN") and extra.zhCN or extra.enUS
		if name and name ~= "" then return name end
	end
	local override = addon.DestinationOverrides and addon.DestinationOverrides[spellID]
	if override then
		if override.hide then return "" end
		if override.nameFn then
			-- nameFn 期望的是 Catalog entry（读 housingFaction 等）；这里按主表数据构一个最小 entry。
			local data = entry.data or {}
			local action = data.action or {}
			local proxy = { spellID = spellID, housingFaction = action.housing }
			local ok, name = pcall(override.nameFn, proxy)
			if ok and name and name ~= "" then return name end
		end
		if override.name then return L[override.name] or override.name end
	end
	local data = entry.data
	if data then
		local mapID = Destination(data)
		if mapID then
			local name = cachedMapName(mapID)
			if name and name ~= "" then return name end
		end
	end
	return ""
end

function addon.Catalog.AnnounceInfo(spellID)
	if not spellID then return nil end
	local entry = BuildAnnounceIndex()[spellID]
	if not entry then return nil end
	local flags = addon.TeleportAnnounceFlags or {}
	local keystone = (flags.keystone and flags.keystone[spellID]) or (entry.extra and entry.extra.keystone) or false
	local heartstone = (flags.heartstone and flags.heartstone[spellID]) or (entry.extra and entry.extra.heartstone) or false
	return {
		destination = AnnounceDestination(entry, spellID),
		item = AnnounceItemID(entry),
		keystone = keystone,
		heartstone = heartstone,
	}
end

function addon.Catalog.BuildSections(includeUnavailable)
 local context = Context()
 addon.Hearthstones.UpdateHomeEntry()
 -- isHome：标记这是角色分组（首页），tooltip 的目的地只显示地图名、不带分组前缀
 -- （用户 2026-10-29）；这个表是合成出来的，Teleports 里没有对应的 key。
 local home, buckets = {headline = CHARACTER, isHome = true, spells = {}}, {{}, {}, {}, {}, {}, {}}
 -- 首页合并职业/种族能力与动态炉石，按同样的六组顺序放置；组内保持数据库顺序。
 for _, section in ipairs(addon.TeleportData) do
  if section.key == 10 or section.key == 9999 then
   for _, data in ipairs(section.spells or {}) do
    local base = ({spell = 1, toy = 3, item = 5})[data.action.type]
    local restricted = (data.requirements and next(data.requirements)) or data.action.classItems
    local bucket = buckets[base + (restricted and 1 or 0)]
    bucket[#bucket + 1] = data
   end
  end
 end
 for index = #buckets, 1, -1 do
  for _, data in ipairs(buckets[index]) do home.spells[#home.spells + 1] = data end
 end
 local result = {}
 for _, source in ipairs(addon.TeleportData) do
 	local key = source.key
 	if key ~= 10 then
 		local section = key == 9999 and home or source
 		local items = BuildEntries(section, context, includeUnavailable)
 		-- 角色组排序（用户 2026-11-17）：统一炉石按钮固定最前，地下堡机器人固定最后；
 		-- 其余条目保持六桶 + 收藏置顶的原序。重排在 FavoritesFirst 之后，收藏不改变这两个锚位。
 		if section.isHome then
 			local hearth, digs, rest = {}, {}, {}
 			for _, item in ipairs(items) do
 				if item.isRandomHearthstone then hearth[#hearth + 1] = item
 				elseif item.spellID == 467470 then digs[#digs + 1] = item
 				else rest[#rest + 1] = item end
 			end
 			local ordered = {}
 			for _, item in ipairs(hearth) do ordered[#ordered + 1] = item end
 			for _, item in ipairs(rest) do ordered[#ordered + 1] = item end
 			for _, item in ipairs(digs) do ordered[#ordered + 1] = item end
 			items = ordered
 		end
 		if #items > 0 then
 			result[#result + 1] = {key = key == 9999 and "home" or "expansion:" .. key, title = section.headline, items = items}
 		end
 	end
 end
 return result
end

