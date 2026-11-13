----------------------------------------------------------------------------
-- idTipExt 存档默认值（唯一权威源）
-- 每一项行末注释注明它对应设置页的哪个选项；非选项的内部字段单独标注。
-- 运行时缓存（gwPosX / gwPosY / gwLastPhaseID / gwLastPhaseSource）不入表，按需写入存档。
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

-- key 顺序与设置页控件显示顺序一致（分组见 Core.lua 的 ns.kindSections 与 Options.lua）
ns.DB_DEFAULTS = {
	-- 基础
	enabled = true,                    -- 启用（总开关）
	style = "double",                  -- 显示风格：两段式显示 "double" / 单段式显示 "single"
	blankLineBeforeFirst = true,       -- 首行信息前加一空行做分隔（提示框中本插件的第一行）
	prefixClassColorEnabled = true,    -- 前缀按职业着色（启用时「前缀颜色」禁用）
	prefixColor = "ff17C864",        -- 前缀颜色（按职业着色启用时禁用）
	version = 4,                       -- 内部字段：存档版本（非选项）

	-- 物品装备
	itemEnabled = true,                -- 物品ID
	itemspellEnabled = true,           -- 物品法术ID
	currencyEnabled = true,            -- 货币ID
	enchantEnabled = true,             -- 附魔ID
	gemEnabled = true,                 -- 宝石ID
	bonusEnabled = false,              -- 加成ID
	setEnabled = true,                 -- 套装ID
	visualEnabled = true,              -- 外观ID
	sourceEnabled = true,              -- 来源ID
	iconEnabled = true,                -- 图标ID
	expansionEnabled = false,          -- 资料片ID

	-- 法术技能（施法者及其职业色是法术ID 的附属选项，紧跟法术ID）
	spellEnabled = true,               -- 法术ID
	unittokenEnabled = true,           -- 显示施法者（法术ID 下的附属选项，独立控制）
	casterClassColorEnabled = true,    -- 施法者名称按职业着色（显示施法者的附属选项）
	abilityEnabled = true,             -- 技能ID
	macroEnabled = true,               -- 宏ID
	talentEnabled = true,              -- 天赋ID
	artifactpowerEnabled = true,       -- 神器能量ID
	traitnodeEnabled = false,          -- 特质节点ID
	traitentryEnabled = false,         -- 特质条目ID
	traitdefEnabled = false,           -- 特质定义ID

	-- 单位与藏品（坐骑信息子模块附属选项紧跟坐骑ID）
	unitEnabled = true,                -- NPC ID
	speciesEnabled = true,             -- 物种ID
	mountEnabled = true,               -- 坐骑ID
	mountInfoEnabled = true,           -- 显示坐骑信息（坐骑ID 下的附属选项）
	mountCollectedEnabled = true,      -- 显示收藏状态
	mountSourceEnabled = true,         -- 显示坐骑来源
	mountLoreEnabled = false,          -- 显示坐骑故事（仅当「显示坐骑来源」启用时可用）
	mountInfoBlankLine = true,         -- 坐骑信息前加一空行做分隔

	-- 其它（原「世界」+「面板直显」合并；任务ID叠加紧跟任务ID）
	objectEnabled = true,              -- 物体ID
	questEnabled = true,               -- 任务ID
	questOverlayEnabled = true,        -- 任务ID叠加
	achievementEnabled = true,         -- 成就ID
	criteriaEnabled = true,            -- 条件ID
	areapoiEnabled = true,             -- 区域兴趣点ID
	vignetteEnabled = true,            -- 小插曲ID
	factionEnabled = true,             -- 声望ID
	cooldownEnabled = false,           -- 冷却ID

	-- 地理监视面板（GeoWatcher.lua，按设置页控件顺序）
	gwShowPhase = true,                -- 显示位面ID
	gwUseHexadecimal = false,          -- 位面ID使用十六进制显示
	gwShowMap = true,                  -- 显示地图ID
	gwShowWorldMap = true,             -- 显示世界地图ID
	gwShowInstance = true,             -- 显示副本ID
	gwShowZone = true,                 -- 显示区域ID
	gwShowPanel = true,                -- 显示地理监视面板
	gwWorldMapPanel = true,            -- 在世界地图显示（独立地图信息面板，不受上面总开关影响）
	gwWorldMapPosition = "bottom",     -- 地图信息面板位置：top 顶部 / bottom 底部
	gwIsLocked = false,                -- 锁定面板位置
	gwAutoHideInCombat = true,         -- 战斗中自动隐藏
	gwShowTooltip = true,              -- 悬停面板时显示详细信息
	gwGrowDirection = "up",            -- 生长方向：向下生长 down / 向上生长 up
	gwMapNameMode = "inline",          -- 地图名称：不显示 none / 同行显示 inline / 单独一行 separate
	gwPanelWidth = 240,                -- 面板宽度（默认按 8 个中文字符估算，可调）
	gwUpdateInterval = 0.5,            -- 更新间隔
	gwFontSize = 14,                   -- 字体大小
	gwAlpha = 1.0,                     -- 面板透明度
	gwBgColor = "ff000000",          -- 背景颜色（hex 的 alpha 位忽略，透明度由 gwBgAlpha 控制）
	gwBgAlpha = 0.4,                   -- 背景透明度（原生色板不支持 alpha，见 Options.lua）
	gwBorderColor = "ff666666",      -- 边框颜色（hex 的 alpha 位忽略，透明度由 gwBorderAlpha 控制）
	gwBorderAlpha = 0.2,               -- 边框透明度
}

-- 存档初始化：旧存档迁移 + 已存在值校验 + 缺失键按 DB_DEFAULTS 补齐（幂等，ADDON_LOADED 每次都跑）
-- 关键约束：迁移与校验不得写入「缺失键」，否则会抢在补齐之前把硬编码旧默认值写进全新存档
function ns.ensureDB()
	if not idTipExtDB then idTipExtDB = {} end
	local DB = idTipExtDB
	local DEFAULTS = ns.DB_DEFAULTS
	-- 只有带版本号的旧存档才跑迁移；全新存档一律走默认值补齐
	local isOldDB = type(DB.version) == "number"

	-- 旧「单行显示」布尔开关一次性迁移为显示风格（仅旧存档带 compact 时）
	if DB.compact ~= nil then
		if DB.style ~= "single" and DB.style ~= "double" then
			DB.style = DB.compact and "single" or "double"
		end
		DB.compact = nil
	end
	DB.pwWindowStyle = nil -- v1.1.1 起窗口风格固定扁平
	-- v1.2.0 起 pwPosX/pwPosY 由「面板中心偏移」改为「生长方向对应的固定角偏移」，旧值失效
	if isOldDB and DB.version < 2 then
		DB.pwPosX = nil
		DB.pwPosY = nil
	end
	-- v1.3.0：原「打开世界地图时锚定到世界地图」改为独立的「在世界地图显示」信息面板
	if DB.pwAnchorToWorldMap ~= nil then
		DB.pwWorldMapPanel = DB.pwAnchorToWorldMap
		DB.pwAnchorToWorldMap = nil
	end
	-- v1.3.0：面板存档键 pw* 统一改名 gw*
	if isOldDB and DB.version < 4 then
		for key in pairs(DB) do
			if string.sub(key, 1, 2) == "pw" then
				local gwKey = "gw" .. string.sub(key, 3)
				DB[gwKey] = DB[key]
				DB[key] = nil
			end
		end
	end

	-- 已存在的键才做合法性校验；非法值一律回退到当前默认值，不再硬编码旧默认值
	DB.version = DEFAULTS.version
	if DB.style ~= nil and DB.style ~= "single" and DB.style ~= "double" then
		DB.style = DEFAULTS.style
	end
	if DB.enabled ~= nil and type(DB.enabled) ~= "boolean" then DB.enabled = DEFAULTS.enabled end
	if DB.prefixColor ~= nil and type(DB.prefixColor) ~= "string" then DB.prefixColor = DEFAULTS.prefixColor end
	if DB.gwWorldMapPosition ~= nil
		and DB.gwWorldMapPosition ~= "top" and DB.gwWorldMapPosition ~= "bottom" then
		DB.gwWorldMapPosition = DEFAULTS.gwWorldMapPosition
	end
	if DB.gwMapNameMode ~= nil
		and DB.gwMapNameMode ~= "none" and DB.gwMapNameMode ~= "inline" and DB.gwMapNameMode ~= "separate" then
		DB.gwMapNameMode = DEFAULTS.gwMapNameMode
	end
	if DB.gwGrowDirection ~= nil
		and DB.gwGrowDirection ~= "up" and DB.gwGrowDirection ~= "down" then
		DB.gwGrowDirection = DEFAULTS.gwGrowDirection
	end

	-- 最后补齐所有缺失键：全新存档的每个默认值都从这里来
	for key, value in pairs(DEFAULTS) do
		if DB[key] == nil then DB[key] = value end
	end
end

-- 打开设置页（右键菜单与斜杠命令共用）
function ns.OpenSettings()
	local categoryID = ns.settingsCategoryID
	if categoryID and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(categoryID)
	end
end
