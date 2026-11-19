----------------------------------------------------------------------------
-- idTipExt 共享核心
-- 架构：idTip 12.1.10（写入管线 / collect 级联防循环）
-- 安全：TDP 单位类排除等策略由各模块落地，本文件只提供共享设施
----------------------------------------------------------------------------

local addonName = ...

local ns = _G[addonName]
if not ns then
	ns = {}
	_G[addonName] = ns
end
ns.addonName = addonName

----------------------------------------------------------------------------
-- API 绑定（gated：缺一个只少一种 ID，调用方自查）
----------------------------------------------------------------------------
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture
local GetItemIconByID = C_Item and C_Item.GetItemIconByID
local GetItemInfo = C_Item and C_Item.GetItemInfo
local GetItemGem = C_Item and C_Item.GetItemGem
local GetItemSpell = C_Item and C_Item.GetItemSpell
local GetItemLinkByGUID = C_Item and C_Item.GetItemLinkByGUID
local GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID
local GetMountFromItem = C_MountJournal and C_MountJournal.GetMountFromItem
local GetMountFromSpell = C_MountJournal and C_MountJournal.GetMountFromSpell
local GetTransmogItemInfo = C_TransmogCollection and C_TransmogCollection.GetItemInfo
local GetPetInfoByItemID = C_PetJournal and C_PetJournal.GetPetInfoByItemID

-- 文案表骨架：Locales/enUS.lua 填充英文默认值，zhCN / zhTW 按 GetLocale() 覆盖
-- 子表先建空表，确保 locale 文件未加载时各模块取到的引用不为 nil
ns.L = { Sections = {}, Tooltips = {}, MountInfo = {} }


----------------------------------------------------------------------------
-- 类型注册表：key -> 标签（各语言文件覆盖值）、分组；各类型默认开关在 InitDB.lua
----------------------------------------------------------------------------
ns.kinds = {
	spell = "SpellID",
	item = "ItemID",
	itemspell = "ItemSpellID",
	unit = "NpcID",
	quest = "QuestID",
	talent = "TalentID",
	achievement = "AchievementID",
	criteria = "CriteriaID",
	ability = "AbilityID",
	artifactpower = "ArtifactPowerID",
	currency = "CurrencyID",
	enchant = "EnchantID",
	bonus = "BonusID",
	gem = "GemID",
	mount = "MountID",
	macro = "MacroID",
	set = "SetID",
	visual = "VisualID",
	source = "SourceID",
	species = "SpeciesID",
	icon = "IconID",
	areapoi = "AreaPoiID",
	vignette = "VignetteID",
	expansion = "ExpansionID",
	object = "ObjectID",
	traitnode = "TraitNodeID",
	traitentry = "TraitEntryID",
	traitdef = "TraitDefinitionID",
	unittoken = "Caster",
	faction = "FactionID",
	questOverlay = "QuestID Overlay",
	cooldown = "CooldownID",
}

-- 设置页分组：每个类型恰好出现一次
ns.kindSections = {
	{ name = "Items", "item", "itemspell", "currency", "enchant", "gem", "bonus", "set", "visual", "source", "icon", "expansion" },
	{ name = "Spells", "spell", "ability", "macro", "talent", "artifactpower", "traitnode", "traitentry", "traitdef" },
	-- unittoken（显示施法者）是法术ID 的附属选项，由 Options.lua 在 Spells 组的 spell 之后单独注册
	{ name = "Units", "unit", "species", "mount" },
	-- 「其它」合并原「世界」与「面板直显」；任务ID叠加紧跟任务ID 之后
	{ name = "Other", "object", "quest", "questOverlay", "achievement", "criteria", "areapoi", "vignette", "faction", "cooldown" },
}

function ns.configKey(key)
	return key .. "Enabled"
end

-- 存档默认值与 ns.ensureDB 已拆到 InitDB.lua（TOC 中在本文件之后加载）

-- ADDON_LOADED 分发：模块经 RegisterOnAddonLoaded(fn) 挂回调，Core 的处理器先注册先执行
ns.onAddonLoaded = {}
function ns.RegisterOnAddonLoaded(fn)
	ns.onAddonLoaded[#ns.onAddonLoaded + 1] = fn
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, addon)
	ns.ensureDB()
	for _, fn in ipairs(ns.onAddonLoaded) do
		fn(addon)
	end
end)

----------------------------------------------------------------------------
-- 工具（源自 idTip 12.1.10）
----------------------------------------------------------------------------
function ns.hook(target, method, callback)
	if callback and target and target[method] then
		hooksecurefunc(target, method, callback)
	end
end

function ns.hookScript(target, script, callback)
	if callback and target and target.HasScript and target:HasScript(script) then
		target:HookScript(script, callback)
	end
end

local function isStringOrNumber(value)
	return type(value) == "string" or type(value) == "number"
end
ns.isStringOrNumber = isStringOrNumber

-- Secret Values：一个值要么是 secret 标量，要么是 secret 表（绑定一次而非每次调用）
local isSecret = issecretvalue and issecrettable and function(value)
	return issecretvalue(value) or (type(value) == "table" and issecrettable(value))
end or function() return false end
ns.isSecret = isSecret

local function isValidId(id)
	if type(id) == "table" then return #id > 0 end
	return isStringOrNumber(id) and id ~= ""
end

local function addUnique(list, value)
	if not value then return end
	for _, existing in ipairs(list) do
		if existing == value then return end
	end
	list[#list + 1] = value
end
ns.addUnique = addUnique

----------------------------------------------------------------------------
-- 公共设施：颜色 / 色码 / 存档 / tooltip 行（各模块共用，格式统一为 |c + 8 位 AARRGGBB + |r）
----------------------------------------------------------------------------
function ns.rgbHex(r, g, b)
	return string.format("ff%02x%02x%02x",
		math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

function ns.colorizeHex(text, hex)
	return "|c" .. hex .. text .. "|r"
end

function ns.colorize(text, r, g, b)
	return ns.colorizeHex(text, ns.rgbHex(r, g, b))
end

-- 单段式行：前缀与值各用一种色码（AddLine 只能整行一色）
function ns.colorizeRow(prefix, value, pr, pg, pb, vr, vg, vb)
	return ns.colorize(prefix, pr, pg, pb) .. " " .. ns.colorize(value, vr, vg, vb)
end

-- CreateColorFromHexString 只接受 8 位 AARRGGBB；异常值返回兜底色对象
function ns.parseHexColor(hex, fr, fg, fb)
	return CreateColorFromHexString(hex) or CreateColor(fr, fg, fb, 1)
end

-- 存档访问统一入口：函数体内延迟解引用，Core 加载时存档可能尚未注入
function ns.db()
	return idTipExtDB
end

-- 纯 Lua clamp，不依赖客户端是否提供 math.clamp
function ns.clamp(value, lo, hi)
	if value < lo then return lo end
	if value > hi then return hi end
	return value
end

local function getTooltipName(tooltip)
	return tooltip:GetName()
end

function ns.tooltipCell(name, side, index)
	local frame = _G[name .. "Text" .. side .. index]
	if not frame then return nil end
	local ok, text = pcall(frame.GetText, frame)
	-- secret 单元格不可读而非致命
	if not ok or isSecret(text) then return nil end
	return text, frame
end
local cellText = ns.tooltipCell

-- 提示框已有指定侧文本则不重复写入（postCall 可能同帧触发多次）
function ns.hasTooltipText(tooltip, name, text, side)
	if not name or not text then return false end
	for index = 1, tooltip:NumLines() do
		if ns.tooltipCell(name, side or "Left", index) == text then return true end
	end
	return false
end

local function inPetBattle()
	return C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle()
end
ns.inPetBattle = inPetBattle

----------------------------------------------------------------------------
-- 写入管线（源自 idTip 12.1.10，去 classic 分支）
----------------------------------------------------------------------------
local function isEnabled(kind)
	return not idTipExtDB or (idTipExtDB.enabled and idTipExtDB[ns.configKey(kind)])
end
ns.isEnabled = isEnabled

-- 所有写入者共用一套策略，避免宠物对战等旁路实现漂移
local function shouldAdd(id, kind)
	return not isSecret(id) and isValidId(id) and isEnabled(kind)
end

-- 职业色：UnitClass(unit) 的第二个返回值是 classFilename
-- （依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_SharedXML/ColorUtil.lua:66-81；Warcraft Wiki: API C_ClassColor.GetClassColor）
function ns.classColor(unit)
	if not unit or not UnitClass then return end
	local ok, _, classFilename = pcall(UnitClass, unit)
	if not ok or not classFilename or isSecret(classFilename) then return end

	local r, g, b
	if C_ClassColor and C_ClassColor.GetClassColor then
		local okColor, color = pcall(C_ClassColor.GetClassColor, classFilename)
		if okColor and color and not isSecret(color.r) then
			r, g, b = color.r, color.g, color.b
		end
	end
	if not r and GetClassColor then
		local okColor, cr, cg, cb = pcall(GetClassColor, classFilename)
		if okColor and not isSecret(cr) then r, g, b = cr, cg, cb end
	end
	if not r then return end

	local hex = ns.rgbHex(r, g, b)
	return r, g, b, hex
end

-- 前缀颜色策略：按职业着色优先（有单位取该单位，否则玩家自身），否则用自定义 hex
function ns.prefixColor(opts)
	if idTipExtDB.prefixClassColorEnabled then
		local r, g, b = ns.classColor(opts and opts.unit or "player")
		if r then return r, g, b end
	end
	-- CreateColorFromHexString 仅接受 8 位 AARRGGBB，异常值兜底白色
	local color = ns.parseHexColor(idTipExtDB.prefixColor or ns.DB_DEFAULTS.prefixColor, 1, 1, 1)
	return color.r, color.g, color.b
end

-- 值着色：两段式用右列独立色；单段式用 |c 色码包裹（AddLine 只能整行一色），
-- 单段式值色默认白色（与两段式右列一致），确保值不与前缀同色
local function valueText(value, opts, style)
	local vr, vg, vb = 1, 1, 1
	if opts and opts.valueRGB then
		vr, vg, vb = opts.valueRGB[1], opts.valueRGB[2], opts.valueRGB[3]
	end
	if style == "single" then
		local hex = (opts and opts.valueColorStr) or ns.rgbHex(vr, vg, vb)
		return ns.colorizeHex(value, hex), vr, vg, vb
	end
	return value, vr, vg, vb
end

-- 同类已有行：两段式左列恰为前缀；单段式左列以前缀开头（前缀 + 空格 + 值串）
local function findKindLine(tooltip, name, prefix)
	for index = tooltip:NumLines(), 1, -1 do
		local text, left = cellText(name, "Left", index)
		if text and string.sub(text, 1, #prefix) == prefix then
			return text, left, index
		end
	end
end

local function trim(text)
	return string.match(text or "", "^%s*(.-)%s*$") or ""
end

-- 剥离 |c 色码与 |r（单段式值带色码，合并解析前需还原纯值）
local function stripColor(text)
	text = string.gsub(text or "", "|c%x%x%x%x%x%x%x%x", "")
	return (string.gsub(text, "|r", ""))
end

-- 本插件是否已在提示框写过行：任意「XXXID:/Caster:」前缀开头的行即算。
-- 提示框每次重设内容都会清空全部行，因此无需额外清零钩子即可区分显示周期
local function hasOwnLine(tooltip, name)
	for index = tooltip:NumLines(), 1, -1 do
		local text = cellText(name, "Left", index)
		if text then
			for _, label in pairs(ns.kinds) do
				local prefix = label .. ":"
				if string.sub(text, 1, #prefix) == prefix then return true end
			end
		end
	end
	return false
end

-- 写入一行 ID。返回提示框是否变化；重复 ID 跳过，同类多值合并进同一行
-- 两段式：tooltip:AddDoubleLine("XXXID:", "nnnnn")；单段式：tooltip:AddLine("XXXID: nnnnn")
function ns.addLine(tooltip, id, kind, opts)
	if not shouldAdd(id, kind) then return false end

	local ok, name = pcall(getTooltipName, tooltip)
	if not ok or not name then return false end

	local prefix = ns.kinds[kind] .. ":"
	local rawValue = type(id) == "table" and table.concat(id, ",") or tostring(id)
	local style = idTipExtDB.style
	local value, vr, vg, vb = valueText(rawValue, opts, style)
	local pr, pg, pb = ns.prefixColor(opts)

	local text, left, lineIndex = findKindLine(tooltip, name, prefix)
	if left then
		local joined
		if text == prefix then
			-- 两段式：已有值在右列
			local rightCell = _G[name .. "TextRight" .. lineIndex]
			joined = rightCell and rightCell:GetText() or ""
			if isSecret(joined) then return false end
			-- 两段式右列重写会丢独立色，着色行不合并、同类只写一个值
			if opts and opts.valueRGB then return false end
		else
			-- 单段式：值跟在前缀后的同一行，可能带 |c 色码
			joined = string.sub(text, #prefix + 1)
		end

		local values = {}
		for existing in string.gmatch(trim(stripColor(joined)), "[^,]+") do
			values[#values + 1] = trim(existing)
		end
		local count = #values
		for item in string.gmatch(rawValue .. ",", "[^,]+") do
			addUnique(values, item)
		end
		if #values == count then return false end

		local updated = table.concat(values, ",")
		if text == prefix then
			local rightCell = _G[name .. "TextRight" .. lineIndex]
			if rightCell then rightCell:SetText(updated) end
		else
			-- 单段式回写按本行值的色码重包，保持值色不与前缀色混同
			local valueHex = string.match(value, "^(|c%x%x%x%x%x%x%x%x)")
			if valueHex then
				local wrapped = {}
				for _, item in ipairs(values) do
					wrapped[#wrapped + 1] = valueHex .. item .. "|r"
				end
				updated = table.concat(wrapped, ",")
			end
			left:SetText(prefix .. " " .. updated)
		end
		return true
	end

	-- 可选：本插件首行信息前补一空行做分隔（该提示框还没有本插件的任何行时）
	if idTipExtDB.blankLineBeforeFirst and not hasOwnLine(tooltip, name) then
		tooltip:AddLine(" ")
	end

	if style == "single" then
		tooltip:AddLine(prefix .. " " .. value, pr, pg, pb)
	else
		tooltip:AddDoubleLine(prefix, value, pr, pg, pb, vr, vg, vb)
	end
	return true
end

-- id 可以是列表；source 是来源类型，用于终止坐骑↔法术互相级联
-- opts 只作用于本行（级联出的其它类型不继承施法者职业色）
function ns.collect(tooltip, id, kind, source, opts)
	if type(id) == "table" and #id == 1 then id = id[1] end
	local changed = ns.addLine(tooltip, id, kind, opts)
	if not isStringOrNumber(id) then return changed end

	if kind == "spell" then
		local iconId = GetSpellTexture and GetSpellTexture(id)
		if iconId then changed = ns.collect(tooltip, iconId, "icon") or changed end

		local mountId = source ~= "mount" and GetMountFromSpell and GetMountFromSpell(id)
		if mountId then changed = ns.collect(tooltip, mountId, "mount", kind) or changed end
	elseif kind == "item" then
		local iconId = GetItemIconByID and GetItemIconByID(id)
		if iconId then changed = ns.collect(tooltip, iconId, "icon") or changed end

		-- 物品法术单独一类，避免与法术ID混淆
		local spellId = GetItemSpell and select(2, GetItemSpell(id))
		if spellId then changed = ns.collect(tooltip, spellId, "itemspell") or changed end

		local speciesId = GetPetInfoByItemID and select(13, GetPetInfoByItemID(id))
		if speciesId then changed = ns.collect(tooltip, speciesId, "species") or changed end

		local mountId = GetMountFromItem and tonumber(id) and GetMountFromItem(tonumber(id))
		if mountId then changed = ns.collect(tooltip, mountId, "mount", kind) or changed end
	elseif kind == "mount" then
		local spellId = source ~= "spell" and GetMountInfoByID and select(2, GetMountInfoByID(id))
		if spellId then changed = ns.collect(tooltip, spellId, "spell", kind) or changed end
	end
	return changed
end

-- 给 Show 之后才挂钩的写入者用：有变化则整帧 Show 重排
function ns.add(tooltip, id, kind, opts)
	if ns.collect(tooltip, id, kind, nil, opts) then tooltip:Show() end
end

----------------------------------------------------------------------------
-- GUID 解析（源自 idTip 12.1.10）
-- NPC GUID 七段：Creature-0-<server>-<instance>-<zoneUID>-<npcID>-<spawnUID>
----------------------------------------------------------------------------
function ns.npcIdFromGUID(guid)
	return tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
end

-- 只有生物形态携带 npc id；Player/BattlePet 的 guid 另有所指
function ns.addNpc(tooltip, guid, fallbackId)
	return not inPetBattle() and ns.collect(tooltip, ns.npcIdFromGUID(guid or "") or fallbackId, "unit")
end

function ns.wildPetSpecies(guid)
	local unit = guid and UnitTokenFromGUID and UnitBattlePetSpeciesID and UnitTokenFromGUID(guid)
	local speciesId = unit and UnitBattlePetSpeciesID(unit)
	if speciesId and not isSecret(speciesId) and speciesId > 0 then return speciesId end
end

----------------------------------------------------------------------------
-- 物品链接展开（源自 idTip 12.1.10）
----------------------------------------------------------------------------
function ns.addItemInfo(tooltip, link)
	local itemString = link and string.match(link, "item:([%-?%d:]+)")
	if not itemString then return end

	local itemSplit = {}
	-- 不会匹配空串，负数与空字段在 Lua 5.1 下仍保持位置
	for value in string.gmatch(itemString .. ":", "([^:]*):") do
		itemSplit[#itemSplit + 1] = value
	end

	local itemId = string.match(link, "item:(%d*)")
	if not itemId or itemId == "" or itemId == "0" then return end
	local changed = ns.collect(tooltip, itemId, "item")

	if GetTransmogItemInfo then
		local appearanceId, sourceId = GetTransmogItemInfo(link)
		changed = ns.collect(tooltip, appearanceId, "visual") or changed
		changed = ns.collect(tooltip, sourceId, "source") or changed
	end

	local enchantId = tonumber(itemSplit[2])
	if enchantId and enchantId ~= 0 then changed = ns.collect(tooltip, itemSplit[2], "enchant") or changed end

	-- bonus 在这里与 addLine 双重检查，关闭时既不建表也不做四次宝石查询
	if isEnabled("bonus") then
		local bonuses = {}
		-- 合成链接可能声称多于实际携带的加成数，数量字段就是上界
		for index = 1, math.min(tonumber(itemSplit[13]) or 0, #itemSplit - 13) do
			bonuses[#bonuses + 1] = itemSplit[13 + index]
		end
		changed = ns.collect(tooltip, bonuses, "bonus") or changed
	end

	if GetItemGem and isEnabled("gem") then
		local gems = {}
		for socket = 1, 4 do
			local gemLink = select(2, GetItemGem(link, socket))
			addUnique(gems, gemLink and string.match(gemLink, "item:(%d+):"))
		end
		changed = ns.collect(tooltip, gems, "gem") or changed
	end

	if GetItemInfo then
		local expansionId, setId = select(15, GetItemInfo(itemId))
		if expansionId and expansionId ~= 254 then -- 经典端恒为 254，无意义（12.x 保留防御）
			changed = ns.collect(tooltip, expansionId, "expansion") or changed
		end
		if setId then changed = ns.collect(tooltip, setId, "set") or changed end
	end

	return changed
end
