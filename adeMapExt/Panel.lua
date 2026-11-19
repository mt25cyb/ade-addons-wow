----------------------------------------------------------------------------
-- adeMapExt 地理监视面板子模块（Panel.lua）
-- 自 idTipExt 1.3.0 GeoWatcher.lua 整文件迁入（零功能损失，_docs/plans/adeMapExt-dev-plan.md）。
-- 位面ID 检测，以及地图/副本/区域ID、世界地图ID（世界地图打开时）、世界地图信息面板。
-- 面板选项只对本面板生效；行显示风格跟随本插件的单段式/两段式（style 键自带），
-- 前缀与值颜色跟随面板前缀色规则（gwPrefix*，值白色，单段式 |c 色码分色），
-- 仅位面ID 值色保留既有配色规则（青绿/浅绿/灰/橙/黄/红）。
-- 窗口风格精简为唯一扁平风格（WHITE8X8），保留背景/边框颜色调整。
-- 存档默认值统一在 InitDB.lua（ns.DB_DEFAULTS），本文件只读写。
-- 设置页基于 ade_UIKit（Options.lua），本文件暴露 ns.OnPanelSettingChanged 供即时联动。
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
local L = ns.L.Panel

-- 值配色：跟随面板值色规则（白色，与两段式右列默认一致）；
-- 位面ID 保留既有配色规则（青绿/浅绿/灰/橙/黄/红）
local COLOR_VALUE = { 1, 1, 1 }        -- 白色：值默认色（地图/副本/区域等）
local COLOR_MAIN = { 0, 1, 0.5 }       -- 青绿：位面ID 检测到
local COLOR_PLAYER = { 0.5, 1, 0.5 }   -- 浅绿：玩家自身来源
local COLOR_CACHED = { 0.7, 0.7, 0.7 } -- 灰色：缓存值
local COLOR_SECRET = { 1, 0.5, 0 }     -- 橙色：secret 受限
local COLOR_WARN = { 1, 1, 0 }         -- 黄色：副本内未检测
local COLOR_ERROR = { 1, 0.3, 0.3 }    -- 红色：未检测

-- 颜色/色码/存档访问统一由 Core.lua 的 ns.rgbHex / ns.colorizeRow / ns.db 提供

-- 前向声明（互相引用的局部函数）
local resizePanelToContent
local restartUpdateTimer
local updateAll
local updateMapInfoPanel

local db = ns.db

----------------------------------------------------------------------------
-- 检测核心（GUID 位面ID 解析）
----------------------------------------------------------------------------
local currentPhaseID, currentPhaseSource, currentSecret = nil, nil, false

-- GUID 第 5 段是 ZoneUID（位面ID），仅 Creature/Vehicle/GameObject 携带
local function extractPhaseFromGUID(guid)
	-- 受限环境下 GUID 可能是 secret，任何操作都可能抛错，整体 pcall 保护
	local ok, phaseID = pcall(function()
		if type(guid) ~= "string" or guid == "" then return nil end
		local guidType, _, _, _, zoneUID = strsplit("-", guid)
		if not guidType then return nil end
		-- 玩家与宠物 GUID 不含位面信息
		if guidType ~= "Creature" and guidType ~= "Vehicle" and guidType ~= "GameObject" then
			return nil
		end
		if zoneUID and zoneUID ~= "" and zoneUID ~= "0" then
			local id = tonumber(zoneUID)
			-- 必须为正数且小于合理上限（1 亿），排除异常极大值
			if id and id > 0 and id < 1e8 then return id end
		end
		return nil
	end)
	if ok and phaseID then return phaseID end
	if not ok then currentSecret = true end -- 解析抛错 = secret 受限
	return nil
end

local function getPhaseFromUnit(unit)
	if not unit or not UnitExists or not UnitExists(unit) then return nil end
	local ok, guid = pcall(UnitGUID, unit)
	if ok then return extractPhaseFromGUID(guid) end
end

-- 检测优先级：mouseover > target > player > focus > 上次缓存
local function detectPhase()
	currentSecret = false
	local phaseID, source = nil, nil

	for _, unit in ipairs({ "mouseover", "target", "player", "focus" }) do
		if not phaseID then
			phaseID = getPhaseFromUnit(unit)
			if phaseID then source = unit end
		end
	end

	if not phaseID and db().gwLastPhaseID then
		phaseID = db().gwLastPhaseID
		source = "cached"
	end

	if phaseID and source ~= "cached" then
		db().gwLastPhaseID = phaseID
		db().gwLastPhaseSource = source
	end

	currentPhaseID = phaseID
	currentPhaseSource = source
end

-- 十六进制格式仅作用于位面ID
local function formatPhaseID(id)
	if db().gwUseHexadecimal then
		return string.format("0x%X", id)
	end
	return tostring(id)
end

----------------------------------------------------------------------------
-- 地图 / 副本 / 区域 / 世界地图
----------------------------------------------------------------------------

-- 副本实例ID：仅在真正处于副本/战场内才有，野外第 8 返回值是区域老ID，必须先判 inInstance
local function getCurrentInstanceID()
	if not GetInstanceInfo then return nil end
	if not (IsInInstance and IsInInstance()) then return nil end
	local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
	if instanceID and instanceID ~= 0 then return instanceID end
	return nil
end

-- 地图ID：玩家当前所在的整张地图主层级（副本内为当前分图）
local function getCurrentMapID()
	if C_Map and C_Map.GetBestMapForUnit then
		local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
		if ok and mapID then return mapID end
	end
	if GetCurrentMapAreaID then
		local ok, areaID = pcall(GetCurrentMapAreaID)
		if ok and areaID and areaID ~= 0 then return areaID end
	end
	return nil
end

-- 区域ID：玩家当前所在的具体地点（营地、副本分区等）。
-- 绝大多数子区域只有 AreaTable 地名条目、没有独立子地图，用 C_Map.GetAreaInfo 反向扫描建地名表。
local areaNameToID
local function getAreaNameToID()
	if areaNameToID then return areaNameToID end
	local map = {}
	if C_Map and C_Map.GetAreaInfo then
		for i = 1, 6000 do
			local ok, name = pcall(C_Map.GetAreaInfo, i)
			if ok and type(name) == "string" and name ~= "" and not map[name] then
				map[name] = i
			end
		end
		areaNameToID = map -- 完整扫描后才缓存，中途出错保留 nil 供下次重试
	end
	return areaNameToID
end

local function getCurrentZoneID()
	local subName = GetSubZoneText and GetSubZoneText() or ""
	if subName == "" and GetMinimapZoneText then subName = GetMinimapZoneText() end
	local zoneName = GetZoneText and GetZoneText() or ""
	-- 有独立地名、且地名与整张地图名不同，才算具体子区域
	if subName ~= "" and subName ~= zoneName then
		local lookup = getAreaNameToID()
		local id = lookup and lookup[subName]
		if id then return id end
	end
	-- 兜底：拥有独立子地图的区域（如大型副本的分图），用坐标处的子地图编号
	if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and C_Map.GetMapInfoAtPosition then
		local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
		if ok and mapID then
			local posOk, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
			if posOk and pos and pos.x then
				local infoOk, info = pcall(C_Map.GetMapInfoAtPosition, mapID, pos.x, pos.y)
				if infoOk and info and info.mapID and info.mapID ~= mapID then return info.mapID end
			end
		end
	end
	return nil
end

-- 世界地图当前显示的地图ID（依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.lua:338 走 GetMapID）
local function getCurrentWorldMapID()
	if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() and WorldMapFrame.GetMapID then
		local ok, mapID = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
		if ok and mapID and mapID ~= 0 then return mapID end
	end
	return nil
end

----------------------------------------------------------------------------
-- 地图名称（Warcraft Wiki: API C_Map.GetMapInfo，name 字段）
-- 建议规格：按 8 个中文字符估算面板默认宽度；超过 8 字符截前 6 字符 + "..."
----------------------------------------------------------------------------
local MAX_NAME_CHARS = 8
local TRUNCATE_CHARS = 6

-- 按 UTF-8 字符边界截前 n 个字符（strlenutf8 只负责计数；Warcraft Wiki: API strlenutf8）
local function utf8Prefix(text, chars)
	local index, count = 1, 0
	while index <= #text and count < chars do
		local byte = string.byte(text, index)
		local width = 1
		if byte >= 0xF0 then width = 4
		elseif byte >= 0xE0 then width = 3
		elseif byte >= 0xC0 then width = 2 end
		index = index + width
		count = count + 1
	end
	return string.sub(text, 1, index - 1)
end

local function formatMapName(name)
	if type(name) ~= "string" or name == "" or ns.isSecret(name) then return nil end
	local count = strlenutf8 and strlenutf8(name) or #name
	if count <= MAX_NAME_CHARS then return name end
	return utf8Prefix(name, TRUNCATE_CHARS) .. "..."
end

-- 地图名称：C_Map.GetMapInfo 返回 UiMapDetails，name 字段（Gethe/wow-ui-source:Interface/AddOns/Blizzard_PTRFeedback/Blizzard_PTRFeedback.lua:428）
local function getMapName(mapID)
	if not mapID or not (C_Map and C_Map.GetMapInfo) then return nil end
	local ok, info = pcall(C_Map.GetMapInfo, mapID)
	if not ok or type(info) ~= "table" then return nil end
	return formatMapName(info.name)
end

----------------------------------------------------------------------------
-- 面板框架
----------------------------------------------------------------------------
local panel     -- 主面板
local dragHint  -- 拖动提示
local rows = {} -- key -> { frame, prefix, value }
-- mapName / worldMapName 用于「地图名称单独一行」模式，排在对应 ID 行之前
local ROW_KEYS = { "phase", "mapName", "map", "worldMapName", "worldmap", "instance", "zone" }

local function growUp()
	return db().gwGrowDirection == "up"
end

-- 扁平风格：唯一窗口风格，1px 发丝边框，背景/边框颜色由设置控制
local FLAT_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	tile = false, edgeSize = 1,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- 主面板与世界地图信息面板共用同一套扁平外观；hex 的 alpha 位忽略，透明度走独立滑条
local function applyPanelBackdrop(frame)
	local data = db()
	local bg = ns.parseHexColor(data.gwBgColor or ns.DB_DEFAULTS.gwBgColor, 0, 0, 0)
	local border = ns.parseHexColor(data.gwBorderColor or ns.DB_DEFAULTS.gwBorderColor, 0.4, 0.4, 0.4)
	frame:SetBackdrop(FLAT_BACKDROP)
	frame:SetBackdropColor(bg.r, bg.g, bg.b, data.gwBgAlpha or ns.DB_DEFAULTS.gwBgAlpha)
	frame:SetBackdropBorderColor(border.r, border.g, border.b, data.gwBorderAlpha or ns.DB_DEFAULTS.gwBorderAlpha)
end

-- 两个面板的整体透明度统一 clamp 到 0.1 ~ 1.0
local function panelAlpha()
	return ns.clamp(db().gwAlpha or ns.DB_DEFAULTS.gwAlpha, 0.1, 1.0)
end

function resizePanelToContent()
	if not panel then return end
	local height = 0
	for _, key in ipairs(ROW_KEYS) do
		local row = rows[key]
		if row and row.frame:IsShown() then
			height = height + row.frame:GetHeight()
		end
	end
	-- 宽度固定（默认按 8 个中文字符估算，可在设置页调整），高度随内容增长
	panel:SetSize(db().gwPanelWidth or ns.DB_DEFAULTS.gwPanelWidth, math.max(height + 36, 50))
end

local function applyRowFont(row)
	local fontSize = db().gwFontSize or ns.DB_DEFAULTS.gwFontSize
	row.frame:SetHeight(fontSize + 6)
	row.prefix:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
	row.value:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
end

local function applyAppearance()
	if not panel then return end
	panel:SetAlpha(panelAlpha())

	for _, key in ipairs(ROW_KEYS) do
		if rows[key] then applyRowFont(rows[key]) end
	end
	if dragHint then
		dragHint:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	end

	applyPanelBackdrop(panel)

	resizePanelToContent()
end

-- 行宽跟随面板：没有宽度的行 Frame 会让右列字体串整体落到面板外
local function anchorRowWidth(frame)
	frame:SetPoint("LEFT", panel, "LEFT", 0, 0)
	frame:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
end

local function ensureRow(key)
	local row = rows[key]
	if not row then
		local frame = CreateFrame("Frame", nil, panel)
		frame:SetHeight((db().gwFontSize or ns.DB_DEFAULTS.gwFontSize) + 6)
		frame:SetFrameLevel(panel:GetFrameLevel() + 2)
		anchorRowWidth(frame)

		local prefix = frame:CreateFontString(nil, "OVERLAY")
		prefix:SetPoint("LEFT", frame, "LEFT", 8, 0)
		prefix:SetJustifyH("LEFT")

		local value = frame:CreateFontString(nil, "OVERLAY")
		value:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
		value:SetJustifyH("RIGHT")

		frame:Hide()
		row = { frame = frame, prefix = prefix, value = value }
		rows[key] = row
	end
	return row
end

-- 行渲染：前缀与值颜色跟随面板前缀色规则（前缀 ns.prefixColor、值白色；
-- 位面ID 值色按既有配色规则传入）；单段式用 |c 色码分色，值不与前缀同色
local function setRow(key, prefix, valueText, color)
	local row = ensureRow(key)
	applyRowFont(row)

	local pr, pg, pb = ns.prefixColor()

	if db().style == "single" then
		-- 单段式：前缀与前缀色、值与值色（|c 色码混色，AddLine 单色做不到）
		row.prefix:SetText(ns.colorizeRow(prefix, valueText, pr, pg, pb, color[1], color[2], color[3]))
		row.value:Hide()
	else
		row.prefix:SetTextColor(pr, pg, pb, 1)
		row.value:SetTextColor(color[1], color[2], color[3], 1)
		row.prefix:SetText(prefix)
		row.value:SetText(valueText)
		row.value:Show()
	end
	row.frame:Show()
end

-- 行重排：向下生长时自 TOP 向下堆叠；向上生长时最末行贴底、其余依次向上堆叠
local function relayoutRows()
	local visible = {}
	for _, key in ipairs(ROW_KEYS) do
		local row = rows[key]
		if row and row.frame:IsShown() then visible[#visible + 1] = row end
	end

	for _, row in ipairs(visible) do
		row.frame:ClearAllPoints()
		-- ClearAllPoints 会清掉宽度锚点，每次重排都要重设
		anchorRowWidth(row.frame)
	end

	if growUp() then
		for index = #visible, 1, -1 do
			if index == #visible then
				visible[index].frame:SetPoint("BOTTOM", panel, "BOTTOM", 0, 20)
			else
				visible[index].frame:SetPoint("BOTTOM", visible[index + 1].frame, "TOP", 0, 0)
			end
		end
	else
		for index, row in ipairs(visible) do
			if index == 1 then
				row.frame:SetPoint("TOP", panel, "TOP", 0, -12)
			else
				row.frame:SetPoint("TOP", visible[index - 1].frame, "BOTTOM", 0, 0)
			end
		end
	end
	resizePanelToContent()
end

-- 主面板锚定：向下生长固定左上点（TOPLEFT），向上生长固定左下点（BOTTOMLEFT）
-- 世界地图信息面板是独立 frame，主面板不再随世界地图移动
local function updatePanelAnchor()
	if not panel then return end
	panel:ClearAllPoints()
	-- gwPosX/gwPosY 是运行时位置缓存，不入 DB_DEFAULTS，缺省按屏幕中心 0 处理
	local x, y = db().gwPosX or 0, db().gwPosY or 0
	if growUp() then
		panel:SetPoint("BOTTOMLEFT", UIParent, "CENTER", x, y)
	else
		panel:SetPoint("TOPLEFT", UIParent, "CENTER", x, y)
	end
end

----------------------------------------------------------------------------
-- 刷新（位面状态行文案与配色照原 idTipExt UI.lua:185-225）
----------------------------------------------------------------------------

local function phaseDisplay()
	if currentSecret then
		return L.SecretValue, COLOR_SECRET
	end
	if currentPhaseID then
		local color = COLOR_MAIN
		if currentPhaseSource == "cached" then
			color = COLOR_CACHED
		elseif currentPhaseSource == "player" then
			color = COLOR_PLAYER
		end
		return formatPhaseID(currentPhaseID), color
	end
	if IsInInstance and IsInInstance() then
		return L.InstanceLimitation, COLOR_WARN
	end
	return L.NotDetected, COLOR_ERROR
end

-- 同行地图行：有名称时「名称 (ID)」，否则仅 ID（地图信息面板的 separate 也退化为同行）
local function inlineMapRow(id, idPrefix, namePrefix, name)
	if name then return namePrefix, name .. " (" .. id .. ")" end
	return idPrefix, tostring(id)
end

-- 统一构建行数据：面板与悬停详细提示共用，保证逐项开关与显示风格一致
-- 每行 { key, prefix, value, color }；prefix 由调用处按名称模式决定
local function buildRows()
	local list = {}
	local mode = db().gwMapNameMode or ns.DB_DEFAULTS.gwMapNameMode
	local function push(key, prefix, value, color)
		if value ~= nil and value ~= "" then
			-- 值色默认白色；位面ID 由 phaseDisplay 传入既有配色
			list[#list + 1] = { key = key, prefix = prefix, value = tostring(value), color = color or COLOR_VALUE }
		end
	end

	if db().gwShowPhase then
		local phaseText, phaseColor = phaseDisplay()
		push("phase", L.PhasePrefix, phaseText, phaseColor)
	end

	-- 地图名称三模式：none = 仅 ID；inline = 地图: 名称 (ID)；separate = 地图: 名称 + 地图ID: ID
	local function pushMap(keyName, keyID, id, idPrefix, namePrefix)
		if not id then return end
		local name = mode ~= "none" and getMapName(id) or nil
		if mode == "separate" and name then
			push(keyName, namePrefix, name)
			push(keyID, idPrefix, id)
		else
			local prefix, value = inlineMapRow(id, idPrefix, namePrefix, name)
			push(keyID, prefix, value)
		end
	end

	if db().gwShowMap then pushMap("mapName", "map", getCurrentMapID(), L.MapPrefix, L.MapLabel) end
	if db().gwShowWorldMap then pushMap("worldMapName", "worldmap", getCurrentWorldMapID(), L.WorldMapPrefix, L.WorldMapLabel) end
	if db().gwShowInstance then push("instance", L.InstancePrefix, getCurrentInstanceID()) end
	if db().gwShowZone then push("zone", L.ZonePrefix, getCurrentZoneID()) end

	return list
end

local function updateUI()
	if not panel then return end
	local shown = {}
	for _, item in ipairs(buildRows()) do
		setRow(item.key, item.prefix, item.value, item.color)
		shown[item.key] = true
	end
	for _, key in ipairs(ROW_KEYS) do
		if not shown[key] then ensureRow(key).frame:Hide() end
	end
	relayoutRows()
end

function updateAll()
	detectPhase()
	updateUI()
	if updateMapInfoPanel then updateMapInfoPanel() end
end

----------------------------------------------------------------------------
-- 面板可见性 / 锁定 / 位置 / 快捷操作
----------------------------------------------------------------------------

local function updatePanelVisibility()
	if not panel then return end
	local shouldShow = db().gwShowPanel
	if shouldShow and db().gwAutoHideInCombat and InCombatLockdown and InCombatLockdown() then
		shouldShow = false
	end
	if shouldShow then
		panel:Show()
	else
		panel:Hide()
	end
end

local function updatePanelLock()
	if not panel then return end
	if db().gwIsLocked then
		panel:SetMovable(false)
		if dragHint then dragHint:Hide() end
	else
		panel:SetMovable(true)
		if dragHint then dragHint:Show() end
	end
end

-- 保存固定角相对屏幕中心的偏移：向上生长记左下角，向下生长记左上角
local function savePosition()
	if not panel then return end
	local left, top, bottom = panel:GetLeft(), panel:GetTop(), panel:GetBottom()
	local parentCenterX, parentCenterY = UIParent:GetCenter()
	if not left or not parentCenterX then return end
	local anchorY = growUp() and bottom or top
	if not anchorY then return end
	db().gwPosX = left - parentCenterX
	db().gwPosY = anchorY - parentCenterY
end

local function resetPosition()
	db().gwPosX = nil
	db().gwPosY = nil
	updatePanelAnchor()
	ns.PrintPanelMsg(L.WindowReset)
end

local function clearCache()
	db().gwLastPhaseID = nil
	db().gwLastPhaseSource = nil
	currentPhaseID = nil
	currentPhaseSource = nil
	updateAll()
	ns.PrintPanelMsg(L.CacheCleared)
end

local function toggleFormat(forceHex)
	if forceHex ~= nil then
		db().gwUseHexadecimal = forceHex
	else
		db().gwUseHexadecimal = not db().gwUseHexadecimal
	end
	updateUI()
	ns.PrintPanelMsg(db().gwUseHexadecimal and L.FormatSwitchedHex or L.FormatSwitchedDec)
end

local function toggleLock()
	db().gwIsLocked = not db().gwIsLocked
	updatePanelLock()
	ns.PrintPanelMsg(db().gwIsLocked and L.WindowLocked or L.WindowUnlocked)
end

-- 面板显隐命令共用：写存档、刷新可见性、打印消息
local function setPanelShown(show)
	db().gwShowPanel = show
	updatePanelVisibility()
	ns.PrintPanelMsg(show and L.WindowShown or L.WindowHidden)
end

local function toggleFrame()
	setPanelShown(not db().gwShowPanel)
end

----------------------------------------------------------------------------
-- 悬停面板的详细提示
----------------------------------------------------------------------------

local function sourceLabel(source)
	if source == "mouseover" then return L.SourceMouseover end
	if source == "target" then return L.SourceTarget end
	if source == "player" then return L.SourcePlayer end
	if source == "focus" then return L.SourceFocus end
	if source == "cached" then return L.SourceCached end
	return source or ""
end

local function showDetailedTooltip(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_TOP")
	GameTooltip:ClearLines()

	GameTooltip:AddLine(L.PhaseMonitor, 1, 1, 1)
	GameTooltip:AddLine(" ")

	-- 与面板同一份行数据，遵循逐项开关与单段式/两段式风格；颜色跟随面板前缀色规则
	local pr, pg, pb = ns.prefixColor()
	local function addRowLine(item)
		if db().style == "single" then
			GameTooltip:AddLine(ns.colorizeRow(item.prefix, item.value, pr, pg, pb,
				item.color[1], item.color[2], item.color[3]))
		else
			GameTooltip:AddDoubleLine(item.prefix, item.value, pr, pg, pb,
				item.color[1], item.color[2], item.color[3])
		end
	end

	-- 位面ID 行抽出，放到「格式 / 来源」之前，三者同一区块保持连贯
	local phaseRow
	for _, item in ipairs(buildRows()) do
		if item.key == "phase" then
			phaseRow = item
		else
			addRowLine(item)
		end
	end

	if phaseRow or currentPhaseID then
		GameTooltip:AddLine(" ")
		if phaseRow then addRowLine(phaseRow) end
		if currentPhaseID then
			GameTooltip:AddDoubleLine(L.Format, db().gwUseHexadecimal and L.HexadecimalFmt or L.DecimalFmt, pr, pg, pb, 1, 1, 1)
			GameTooltip:AddDoubleLine(L.Source, sourceLabel(currentPhaseSource), pr, pg, pb, 1, 1, 1)
		end
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L.RightClickHint, 0.5, 0.5, 0.5)
	GameTooltip:Show()
end

----------------------------------------------------------------------------
-- 右键菜单（11.0+ MenuUtil）
----------------------------------------------------------------------------

local function openSettings()
	ns.OpenSettings()
end

local function showContextMenu(owner)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:CreateTitle(L.PhaseMonitor)
		rootDescription:CreateDivider()

		rootDescription:CreateCheckbox(
			L.Hexadecimal,
			function() return db().gwUseHexadecimal end,
			function() toggleFormat() end
		)
		rootDescription:CreateCheckbox(
			L.Lock,
			function() return db().gwIsLocked end,
			function() toggleLock() end
		)
		rootDescription:CreateCheckbox(
			L.DetailedTooltip,
			function() return db().gwShowTooltip end,
			function() db().gwShowTooltip = not db().gwShowTooltip end
		)

		rootDescription:CreateDivider()

		rootDescription:CreateButton(L.ButtonClearCache, function() clearCache() end)
		rootDescription:CreateButton(L.ButtonResetPosition, function() resetPosition() end)
		rootDescription:CreateButton(L.ButtonOpenSettings, function() openSettings() end)
	end)
end

----------------------------------------------------------------------------
-- 创建面板
----------------------------------------------------------------------------

local function createPanel()
	panel = CreateFrame("Frame", "adeMapExtGeoPanel", UIParent, "BackdropTemplate")
	panel:SetSize(220, 60)
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetFrameStrata("MEDIUM")
	panel:SetFrameLevel(10)
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetClampedToScreen(true)

	dragHint = panel:CreateFontString(nil, "OVERLAY")
	dragHint:SetPoint("BOTTOM", panel, "BOTTOM", 0, 4)
	dragHint:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE") -- SetText 前必须先设字体，否则 "Font not set"
	dragHint:SetText(L.DragToMove)
	dragHint:SetTextColor(0.5, 0.5, 0.5, 0.7)

	panel:SetScript("OnEnter", function(self)
		if db().gwShowTooltip then
			showDetailedTooltip(self)
		end
	end)
	panel:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	panel:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			showContextMenu(self)
		end
	end)
	panel:SetScript("OnDragStart", function(self, button)
		if button == "LeftButton" and self:IsMovable() then
			self:StartMoving()
		end
	end)
	panel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		savePosition()
	end)

	applyAppearance()
end

----------------------------------------------------------------------------
-- 世界地图信息面板（独立 frame，由 gwWorldMapPanel 单独管控，与 gwShowPanel 无关）
-- 锚点目标：WorldMapFrame.ScrollContainer（Gethe/wow-ui-source:Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.xml:12）
----------------------------------------------------------------------------
local mapInfoPanel
local mapCells = {}
local MAP_INFO_KEYS = { "phase", "map", "worldmap" }
local MAP_INFO_ALIGN = { phase = "LEFT", map = "CENTER", worldmap = "RIGHT" }

local function anchorMapInfoPanel(ws)
	mapInfoPanel:ClearAllPoints()
	if db().gwWorldMapPosition == "bottom" then
		mapInfoPanel:SetPoint("TOPLEFT", ws, "BOTTOMLEFT", 0, -4)
		mapInfoPanel:SetPoint("TOPRIGHT", ws, "BOTTOMRIGHT", 0, -4)
	else
		mapInfoPanel:SetPoint("TOPLEFT", ws, "TOPLEFT", 0, 2)
		mapInfoPanel:SetPoint("TOPRIGHT", ws, "TOPRIGHT", 0, 2)
	end
end

local function createMapInfoPanel()
	-- parent 用 UIParent + 手动显隐：WorldMapFrame 有 frameBuffer，子帧锚到 ScrollContainer 外可能被裁
	mapInfoPanel = CreateFrame("Frame", "adeMapExtMapInfoPanel", UIParent, "BackdropTemplate")
	-- WorldMapFrame 的 strata 由 GameRule 动态设置（Gethe/wow-ui-source:Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.lua:349-351），
	-- 其 BorderFrame 固定 HIGH；信息面板用更高的固定层避免被地图边框盖住
	mapInfoPanel:SetFrameStrata("FULLSCREEN_DIALOG")
	mapInfoPanel:SetFrameLevel(100)
	mapInfoPanel:EnableMouse(false)

	for _, key in ipairs(MAP_INFO_KEYS) do
		local cell = CreateFrame("Frame", nil, mapInfoPanel)
		local prefix = cell:CreateFontString(nil, "OVERLAY")
		prefix:SetPoint("LEFT", cell, "LEFT", 0, 0)
		prefix:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
		prefix:SetJustifyH(MAP_INFO_ALIGN[key])
		prefix:SetWordWrap(false)
		prefix:SetMaxLines(1)
		mapCells[key] = { frame = cell, prefix = prefix }
	end
end

local function layoutMapInfoCells(wsWidth)
	local fontSize = db().gwFontSize or ns.DB_DEFAULTS.gwFontSize
	-- 三组宽度跟随地理监视面板设定值，且不超过面板三分之一避免重叠
	local available = (wsWidth and wsWidth > 0) and wsWidth or (mapInfoPanel:GetWidth() or 0)
	local cellWidth = math.min(db().gwPanelWidth or ns.DB_DEFAULTS.gwPanelWidth, math.max(available / 3, 80))
	mapInfoPanel:SetHeight(fontSize + 10)
	mapInfoPanel:SetAlpha(panelAlpha())
	for _, key in ipairs(MAP_INFO_KEYS) do
		local cell = mapCells[key]
		cell.frame:SetSize(cellWidth, fontSize + 6)
		cell.frame:ClearAllPoints()
		if key == "phase" then
			cell.frame:SetPoint("LEFT", mapInfoPanel, "LEFT", 4, 0)
		elseif key == "map" then
			cell.frame:SetPoint("CENTER", mapInfoPanel, "CENTER", 0, 0)
		else
			cell.frame:SetPoint("RIGHT", mapInfoPanel, "RIGHT", -4, 0)
		end
		cell.prefix:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
	end
end

-- 只取位面 / 地图 / 世界地图三组；地图信息面板单行，名称模式 separate 退化为同行
local function mapInfoCellData(key)
	if key == "phase" then
		if not db().gwShowPhase then return nil end
		local text, color = phaseDisplay()
		return L.PhasePrefix, text, color
	elseif key == "map" then
		if not db().gwShowMap then return nil end
		local id = getCurrentMapID()
		if not id then return nil end
		local name = db().gwMapNameMode ~= "none" and getMapName(id) or nil
		local prefix, value = inlineMapRow(id, L.MapPrefix, L.MapLabel, name)
		return prefix, value, COLOR_VALUE
	elseif key == "worldmap" then
		if not db().gwShowWorldMap then return nil end
		local id = getCurrentWorldMapID()
		if not id then return nil end
		local name = db().gwMapNameMode ~= "none" and getMapName(id) or nil
		local prefix, value = inlineMapRow(id, L.WorldMapPrefix, L.WorldMapLabel, name)
		return prefix, value, COLOR_VALUE
	end
end

function updateMapInfoPanel()
	local wf = WorldMapFrame
	local ws = wf and wf.ScrollContainer
	if not ws or not db().gwWorldMapPanel or not wf:IsShown() then
		if mapInfoPanel then mapInfoPanel:Hide() end
		return
	end
	if not mapInfoPanel then createMapInfoPanel() end

	anchorMapInfoPanel(ws)
	layoutMapInfoCells(ws:GetWidth())

	applyPanelBackdrop(mapInfoPanel)

	local pr, pg, pb = ns.prefixColor()
	for _, key in ipairs(MAP_INFO_KEYS) do
		local cell = mapCells[key]
		local prefix, value, color = mapInfoCellData(key)
		if not prefix then
			cell.frame:Hide()
		else
			cell.frame:Show()
			-- 固定单段式：前缀与前缀色、值与行值色分色（|c 色码，AddLine 单色做不到）
			cell.prefix:SetText(ns.colorizeRow(prefix, value, pr, pg, pb, color[1], color[2], color[3]))
		end
	end
	mapInfoPanel:Show()
end

-- Blizzard_WorldMap 可能后于本插件加载，用 ADDON_LOADED 分发补挂开合事件
local worldMapHooked = false
local function setupWorldMapPanel()
	local wf = WorldMapFrame
	if not wf or worldMapHooked then return end
	worldMapHooked = true
	ns.hookScript(wf, "OnShow", function() updateMapInfoPanel() end)
	ns.hookScript(wf, "OnHide", function()
		if mapInfoPanel then mapInfoPanel:Hide() end
	end)
	updateMapInfoPanel()
end

ns.RegisterOnAddonLoaded(function(addon)
	if addon == "Blizzard_WorldMap" or addon == addonName then
		setupWorldMapPanel()
	end
end)

----------------------------------------------------------------------------
-- 设置页联动：gw* 设置变更即时生效（Options.lua 调入）
----------------------------------------------------------------------------

function ns.OnPanelSettingChanged(key)
	-- 地图信息面板独立管控，不受主面板状态影响
	if key == "gwWorldMapPanel" or key == "gwWorldMapPosition" then
		updateMapInfoPanel()
		return
	end
	if not panel then return end
	if key == "gwShowPanel" or key == "gwAutoHideInCombat" then
		updatePanelVisibility()
	elseif key == "gwIsLocked" then
		updatePanelLock()
	elseif key == "gwGrowDirection" then
		updatePanelAnchor()
		updatePanelLock()
		updateAll()
	elseif key == "gwPanelWidth" or key == "gwFontSize" or key == "gwAlpha"
		or key == "gwBgColor" or key == "gwBorderColor"
		or key == "gwBgAlpha" or key == "gwBorderAlpha" then
		applyAppearance()
		updateAll()
	elseif key == "gwUpdateInterval" then
		restartUpdateTimer()
	else
		-- 逐项显示开关 / 地图名称模式 / 十六进制 / 详细提示开关 / style / 前缀色：重算行数据
		updateAll()
	end
end

----------------------------------------------------------------------------
-- 定时器与事件
----------------------------------------------------------------------------

local updateTimer

function restartUpdateTimer()
	if updateTimer then
		updateTimer:Cancel()
		updateTimer = nil
	end
	if not C_Timer or not C_Timer.NewTicker then return end
	local interval = db().gwUpdateInterval or ns.DB_DEFAULTS.gwUpdateInterval
	if interval < 0.1 then interval = 0.1 end
	updateTimer = C_Timer.NewTicker(interval, updateAll)
end

local function initPanel()
	ns.ensureDB() -- 默认值与迁移统一由 InitDB.lua 提供
	if not panel then
		createPanel()
	end
	updatePanelAnchor()
	updatePanelLock()
	updatePanelVisibility()
	applyAppearance()
	restartUpdateTimer()
	updateAll()

	-- 延迟预建区域地名反查表并刷新一次，避免登录瞬间卡顿
	if C_Timer and C_Timer.After then
		C_Timer.After(1, function()
			pcall(getAreaNameToID)
			updateAll()
		end)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")     -- 进世界/切换场景
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")     -- 目标改变
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")     -- 鼠标指向单位改变
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")     -- 进战斗（配合战斗自动隐藏）
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")      -- 脱离战斗
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == addonName then
			initPanel()
		end
	elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		updatePanelVisibility()
	else
		updateAll()
	end
end)

----------------------------------------------------------------------------
-- 面板命令接口：斜杠命令统一放到 Slash.lua，本文件只暴露操作
----------------------------------------------------------------------------

ns.GeoCmd = {
	Toggle = toggleFrame,
	Show = function() setPanelShown(true) end,
	Hide = function() setPanelShown(false) end,
	Reset = resetPosition,
	Clear = clearCache,
	Hex = function() toggleFormat(true) end,
	Dec = function() toggleFormat(false) end,
	Lock = toggleLock,
	Config = openSettings,
	Debug = function()
		ns.debug = not ns.debug
		ns.PrintPanelMsg("Debug mode: " .. (ns.debug and "ON" or "OFF"))
	end,
}
