----------------------------------------------------------------------------
-- idTipExt 设置模块：暴雪原生 Settings API（零依赖）
-- 所有默认值来自 InitDB.lua 的 ns.DB_DEFAULTS；斜杠命令已拆到 Slash.lua
-- 控件依据（Gethe/wow-ui-source:Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua）：
--   CreateCheckbox(387) / CreateSlider(403,308) / CreateDropdown(409)
--   CreateColorSwatch(397) / RegisterAddOnSetting(173) / SetOnValueChangedCallback(659)
--   下拉 options 必须是返回选项数组的函数（container:GetData()）
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

-- 类型选项的说明文案（其余类型不显示 tooltip）
local tooltipKeys = {
	faction = "faction",
	questOverlay = "questOverlay",
	cooldown = "cooldown",
}

local function varKey(key)
	return addonName .. "_" .. key
end

-- 所有控件共用同一套设置注册；varKey 是 SetOnValueChangedCallback 的唯一键，不可改
local function registerSetting(category, key, settingType, label)
	return Settings.RegisterAddOnSetting(category, varKey(key), key, idTipExtDB,
		settingType, label, ns.DB_DEFAULTS[key])
end

-- 子控件依赖主开关：读取存档当前值决定是否可用
local function dependOn(child, parent, key)
	child:SetParentInitializer(parent, function() return ns.db()[key] end)
end

-- 滑条数值格式
local function numberFormatter(fmt)
	return function(value) return string.format(fmt, value) end
end

local function registerCheckbox(category, key, label, tooltip)
	return Settings.CreateCheckbox(category, registerSetting(category, key, "boolean", label), tooltip)
end

local function registerSlider(category, key, label, minValue, maxValue, step, formatter)
	local options = Settings.CreateSliderOptions(minValue, maxValue, step)
	-- 原生样式：滑条右侧显示当前值
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
		formatter or numberFormatter("%.1f"))
	return Settings.CreateSlider(category, registerSetting(category, key, "number", label), options)
end

local function optionsContainer(items)
	return function()
		local container = Settings.CreateControlTextContainer()
		for _, item in ipairs(items) do container:Add(item[1], item[2]) end
		return container:GetData()
	end
end

local function registerDropdown(category, key, label, items, tooltip)
	return Settings.CreateDropdown(category, registerSetting(category, key, "string", label),
		optionsContainer(items), tooltip)
end

local function registerSwatch(category, key, label, tooltip)
	-- 原生色板：string 类型、8 位 hex（AARRGGBB）
	return Settings.CreateColorSwatch(category, registerSetting(category, key, "string", label), tooltip)
end

-- 面板/风格设置变更后即时刷新（GeoWatcher.lua 提供 ns.OnPanelSettingChanged）
local function watchRefresh(key)
	Settings.SetOnValueChangedCallback(varKey(key), function()
		ns.OnPanelSettingChanged(key)
	end)
end

-- 显示风格变化时面板行也要重算（GeoWatcher 的默认分支会 updateAll）
local refreshKeys = {
	"style", "prefixColor", "prefixClassColorEnabled",
	"gwShowPanel", "gwWorldMapPanel", "gwWorldMapPosition", "gwIsLocked", "gwAutoHideInCombat",
	"gwUseHexadecimal", "gwShowTooltip", "gwGrowDirection", "gwPanelWidth",
	"gwMapNameMode", "gwShowPhase", "gwShowMap", "gwShowWorldMap",
	"gwShowInstance", "gwShowZone", "gwUpdateInterval", "gwFontSize",
	"gwAlpha", "gwBgColor", "gwBorderColor", "gwBgAlpha", "gwBorderAlpha",
}

local function registerOptions()
	local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
	local L, P, M = ns.L, ns.L.Panel, ns.L.MountInfo

	local function addHeader(sectionKey)
		if layout and CreateSettingsListSectionHeaderInitializer then
			layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.Sections[sectionKey]))
		end
	end

	-- 基础：总开关 / 显示风格 / 前缀着色
	registerCheckbox(category, "enabled", L.Enabled)
	registerDropdown(category, "style", L.Style, {
		{ "double", L.StyleDouble }, { "single", L.StyleSingle },
	}, L.Tooltips.style)
	registerCheckbox(category, "blankLineBeforeFirst", L.BlankLineBeforeFirst)
	-- 前缀按职业着色启用时，「前缀颜色」自定义色板禁用
	-- SetParentInitializer 的 modifyPredicate 返回 false 会禁用子控件
	-- （依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingControls.lua:120-131、:520-527、:358-360）
	local prefixClass = registerCheckbox(category, "prefixClassColorEnabled", L.PrefixClassColor)
	local prefixSwatch = registerSwatch(category, "prefixColor", L.PrefixColor, L.Tooltips.prefixColor)
	prefixSwatch:SetParentInitializer(prefixClass, function()
		return not idTipExtDB.prefixClassColorEnabled
	end)

	-- ID 类型分组；法术ID / 坐骑ID 的附属选项紧跟其所在行
	for _, section in ipairs(ns.kindSections) do
		addHeader(section.name)
		for _, kind in ipairs(section) do
			local ck = ns.configKey(kind)
			local tooltipKey = tooltipKeys[kind]
			registerCheckbox(category, ck, ns.kinds[kind],
				tooltipKey and L.Tooltips[tooltipKey] or nil)

			if kind == "spell" then
				-- 显示施法者：独立控制，不设 parent、不与法术ID 开关联动
				local caster = registerCheckbox(category, "unittokenEnabled", L.ShowCaster)
				-- 施法者名称按职业着色：仅当显示施法者启用时可用
				local casterColor = registerCheckbox(category, "casterClassColorEnabled", L.CasterClassColor)
				dependOn(casterColor, caster, "unittokenEnabled")
			elseif kind == "mount" then
				-- 显示坐骑信息（MountInfo.lua）：子项依赖主开关，故事额外依赖来源
				local master = registerCheckbox(category, "mountInfoEnabled", M.ShowMountInfo)
				local collected = registerCheckbox(category, "mountCollectedEnabled", M.ShowCollected)
				local source = registerCheckbox(category, "mountSourceEnabled", M.ShowSource)
				local lore = registerCheckbox(category, "mountLoreEnabled", M.ShowLore)
				dependOn(collected, master, "mountInfoEnabled")
				dependOn(source, master, "mountInfoEnabled")
				lore:SetParentInitializer(source, function()
					return idTipExtDB.mountInfoEnabled and idTipExtDB.mountSourceEnabled
				end)
				local mountBlank = registerCheckbox(category, "mountInfoBlankLine", M.BlankLine)
				dependOn(mountBlank, master, "mountInfoEnabled")
			end
		end
	end

	-- 地理监视面板分组
	addHeader("Panel")
	-- 每类信息单独开关
	registerCheckbox(category, "gwShowPhase", L.ShowPhaseID)
	registerCheckbox(category, "gwUseHexadecimal", P.Hexadecimal)
	registerCheckbox(category, "gwShowMap", L.ShowMapID)
	registerCheckbox(category, "gwShowWorldMap", L.ShowWorldMapID)
	registerCheckbox(category, "gwShowInstance", L.ShowInstanceID)
	registerCheckbox(category, "gwShowZone", L.ShowZoneID)

	registerCheckbox(category, "gwShowPanel", P.ShowPanel)
	-- 独立地图信息面板：不受上面「显示位面监视面板」影响
	local worldMapPanel = registerCheckbox(category, "gwWorldMapPanel", P.WorldMapPanel)
	local worldMapPosition = registerDropdown(category, "gwWorldMapPosition", P.WorldMapPosition, {
		{ "top", P.WorldMapTop }, { "bottom", P.WorldMapBottom },
	})
	dependOn(worldMapPosition, worldMapPanel, "gwWorldMapPanel")
	registerCheckbox(category, "gwIsLocked", P.Lock)
	registerCheckbox(category, "gwAutoHideInCombat", P.AutoHide)
	registerCheckbox(category, "gwShowTooltip", P.DetailedTooltip)
	registerDropdown(category, "gwGrowDirection", L.GrowDirection, {
		{ "down", L.GrowDown }, { "up", L.GrowUp },
	})
	registerDropdown(category, "gwMapNameMode", L.MapNameMode, {
		{ "none", L.MapNameNone }, { "inline", L.MapNameInline }, { "separate", L.MapNameSeparate },
	})

	-- 宽度默认按 8 个中文字符估算，可在设置里调整
	registerSlider(category, "gwPanelWidth", L.PanelWidth, 160, 420, 10,
		numberFormatter("%d"))
	registerSlider(category, "gwUpdateInterval", P.UpdateInterval, 0.1, 2.0, 0.1,
		numberFormatter("%.1f"))
	registerSlider(category, "gwFontSize", P.FontSize, 10, 32, 1,
		numberFormatter("%d"))
	registerSlider(category, "gwAlpha", P.Alpha, 0.1, 1.0, 0.05,
		numberFormatter("%.2f"))
	registerSwatch(category, "gwBgColor", P.BackgroundColor)
	-- 原生色板不支持 alpha（SetupColorPickerAndShow 无 hasOpacity，回写强制 ff），
	-- 透明度用独立滑条，hex 的 alpha 位忽略
	registerSlider(category, "gwBgAlpha", P.BgAlpha, 0, 1.0, 0.05,
		numberFormatter("%.2f"))
	registerSwatch(category, "gwBorderColor", P.BorderColor)
	registerSlider(category, "gwBorderAlpha", P.BorderAlpha, 0, 1.0, 0.05,
		numberFormatter("%.2f"))

	Settings.RegisterAddOnCategory(category)
	return category
end

ns.RegisterOnAddonLoaded(function(addon)
	if addon ~= addonName then return end
	ns.ensureDB()

	-- 各 API 齐备才注册，缺一个则退化为纯 hook 模式
	if Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting
		and Settings.CreateCheckbox and Settings.RegisterAddOnCategory then
		local category = registerOptions()
		ns.settingsCategoryID = category.ID
		for _, key in ipairs(refreshKeys) do
			watchRefresh(key)
		end
	end
end)

