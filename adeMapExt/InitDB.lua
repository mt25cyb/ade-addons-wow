----------------------------------------------------------------------------
-- adeMapExt 存档默认值（唯一权威源）
-- 迁移自 idTipExt 1.3.0（gw* 22 键原样）；新增 gwPrefix* 两键（面板前缀色独立）
-- 与 style（面板行显示风格，原版跟随 tooltip 设置，拆分后自带）。
-- 运行时缓存（gwPosX / gwPosY / gwLastPhaseID / gwLastPhaseSource）不入表，按需写入存档。
-- 一次性迁移：读 idTipExtDB 的 pw*/gw* 键与 style 复制进本档（用户 2026-11-18 决策：
--   迁移后不回读——之后修改 idTipExt 存档不再影响本插件）。
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

ns.DB_DEFAULTS = {
	style = "double",                  -- 行显示风格：两段式 "double" / 单段式 "single"（自 idTipExt 迁移）

	-- 地理监视面板（Panel.lua，按设置页控件顺序）
	gwShowPhase = true,                -- 显示位面ID
	gwUseHexadecimal = false,          -- 位面ID使用十六进制显示
	gwShowMap = true,                  -- 显示地图ID
	gwShowWorldMap = true,             -- 显示世界地图ID
	gwShowInstance = true,             -- 显示副本ID
	gwShowZone = true,                 -- 显示区域ID
	gwShowPanel = true,                -- 显示地理监视面板
	gwWorldMapPanel = true,            -- 在世界地图显示（独立地图信息面板，不受上面总开关影响）
	gwWorldMapPosition = "bottom",     -- 地图信息面板位置：top 顶部 / bottom 底部
	gwWorldMapOffsetTop = 2,           -- 地图信息面板 Y 轴偏移（顶部位置专用；默认 = 原锚点偏移，行为不变）
	gwWorldMapOffsetBottom = -4,       -- 地图信息面板 Y 轴偏移（底部位置专用；默认 = 原锚点偏移，行为不变）
	gwIsLocked = false,                -- 锁定面板位置
	gwAutoHideInCombat = true,         -- 战斗中自动隐藏
	gwShowTooltip = true,              -- 悬停面板时显示详细信息
	gwGrowDirection = "up",            -- 生长方向：向下生长 down / 向上生长 up
	gwMapNameMode = "inline",          -- 地图名称：不显示 none / 同行显示 inline / 单独一行 separate
	gwPanelWidth = 240,                -- 面板宽度（默认按 8 个中文字符估算，可调）
	gwUpdateInterval = 0.5,            -- 更新间隔
	gwFontSize = 14,                   -- 字体大小
	gwAlpha = 1.0,                     -- 面板透明度
	gwBgColor = "ff000000",            -- 背景颜色（hex 的 alpha 位忽略，透明度由 gwBgAlpha 控制）
	gwBgAlpha = 0.4,                   -- 背景透明度
	gwBorderColor = "ff666666",        -- 边框颜色（hex 的 alpha 位忽略，透明度由 gwBorderAlpha 控制）
	gwBorderAlpha = 0.2,               -- 边框透明度
	gwPrefixClassColorEnabled = true,  -- 行前缀按职业着色（启用时「前缀颜色」禁用；拆分后新增）
	gwPrefixColor = "ff17C864",        -- 行前缀颜色（按职业着色启用时禁用；拆分后新增）

	version = 1,                       -- 内部字段：存档版本（非选项）
}

-- 存档初始化：一次性迁移 + 已存在值校验 + 缺失键按 DB_DEFAULTS 补齐（幂等）
function ns.ensureDB()
	if not adeMapExtDB then adeMapExtDB = {} end
	local DB = adeMapExtDB
	local DEFAULTS = ns.DB_DEFAULTS

	-- 一次性迁移自 idTipExtDB（含 pw*→gw* 历史改名段，InitDB.lua:113-127 语义）；
	-- 迁移标记落档后不再回读旧档。style 与运行时键（gwPosX 等）一并带走。
	if not DB.migratedFromIdTipExt and type(idTipExtDB) == "table" then
		for key, value in pairs(idTipExtDB) do
			if string.sub(key, 1, 2) == "pw" then
				DB["gw" .. string.sub(key, 3)] = value
			elseif string.sub(key, 1, 2) == "gw" or key == "style" then
				DB[key] = value
			end
		end
		DB.migratedFromIdTipExt = true
	end

	-- 已存在的键才做合法性校验；非法值一律回退到当前默认值
	DB.version = DEFAULTS.version
	if DB.style ~= nil and DB.style ~= "single" and DB.style ~= "double" then
		DB.style = DEFAULTS.style
	end
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
	-- Y 轴偏移只接受数字（旧档迁移/异常写入防护）
	for _, key in ipairs({ "gwWorldMapOffsetTop", "gwWorldMapOffsetBottom" }) do
		if DB[key] ~= nil and type(DB[key]) ~= "number" then DB[key] = DEFAULTS[key] end
	end
	if DB.gwPrefixColor ~= nil and type(DB.gwPrefixColor) ~= "string" then
		DB.gwPrefixColor = DEFAULTS.gwPrefixColor
	end
	-- 旧版 execute+KeySpec bug 会把布尔 true 写进颜色键（用户 2026-11-18 实测），
	-- 非字符串一律还原默认。
	for _, key in ipairs({ "gwBgColor", "gwBorderColor" }) do
		if DB[key] ~= nil and type(DB[key]) ~= "string" then DB[key] = DEFAULTS[key] end
	end

	-- 最后补齐所有缺失键：全新存档的每个默认值都从这里来
	for key, value in pairs(DEFAULTS) do
		if DB[key] == nil then DB[key] = value end
	end
end
