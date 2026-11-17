local _, ns = ...
local Addon = ns.Addon
local L = Addon.L

local Options = {}
Addon.Options = Options

Options.category = nil
Options.layout = nil

-- 贴边箭头可选 atlas（均为 12.x 真实存在：NPE_ArrowUp 用于 ArrowCalloutFrame，
-- Navigation-Tracked-Arrow 用于 SuperTrackedFrame，bag-arrow 用于罗盘中心标）。
-- 选项文本前嵌入 atlas 图标（|A / |T 纹理转义，Settings 下拉 FontString 支持），
-- 让「材质」在名字中显示为真实图标，而非仅文字。解析逻辑与 Emphasis.ApplyIcon 一致：
-- 能取到 AtlasInfo 走 |A，否则按贴图路径走 |T。
local function atlasIconMarkup(atlas, size)
	size = size or 16
	if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
		return CreateAtlasMarkup(atlas, size, size)
	end
	return CreateSimpleTextureMarkup(atlas, size, size)
end

local function atlasChoice(text, atlas)
	return { text = string.format("%s %s", atlasIconMarkup(atlas, 16), text), value = atlas }
end

local ATLAS_CHOICES = {
	atlasChoice(L.STAY_ATLAS_NPE, "NPE_ArrowUp"),
	atlasChoice(L.STAY_ATLAS_NAV, "Navigation-Tracked-Arrow"),
	atlasChoice(L.STAY_ATLAS_BAG, "bag-arrow"),
}

-- 罗盘刻度数字（仿 CompassHUD）开关
local SCALE_CHOICES = {
	{ text = L.SHOW_SCALE_ON, value = true },
	{ text = L.SHOW_SCALE_OFF, value = false },
}

local function settingsTbl()
	return Addon.settings
end

local function defaultsTbl()
	return Addon.DEFAULTS and Addon.DEFAULTS.settings or {}
end

-- Settings 的颜色值必须是 8 位 AARRGGBB（ColorUtil.CreateColorFromHexString 会断言 #hex == 8），
-- 6 位 RRGGBB 会让 CreateColorFromHexString 返回 nil，进而触发 ColorSwatch:SetColor 索引 nil 的报错。
local function colorToHex(color)
	color = color or {}
	local function channel(value)
		value = tonumber(value) or 0
		if value < 0 then value = 0 elseif value > 1 then value = 1 end
		return math.floor(value * 255 + 0.5)
	end
	return string.format("ff%02x%02x%02x", channel(color.red), channel(color.green), channel(color.blue))
end

local function hexToColor(hex)
	if type(hex) ~= "string" then return nil end
	hex = hex:gsub("^#", "")
	if #hex == 8 then
		hex = hex:sub(3)
	elseif #hex ~= 6 then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return { red = r / 255, green = g / 255, blue = b / 255 }
end

local function addSection(layout, title)
	if layout and CreateSettingsListSectionHeaderInitializer then
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title))
	end
end

local function addCheckbox(category, key, name, tooltip)
	local setting = Settings.RegisterAddOnSetting(category, "BTE_" .. key:upper(), key, settingsTbl(),
		Settings.VarType.Boolean, name, defaultsTbl()[key] == true)
	Settings.CreateCheckbox(category, setting, tooltip)
	return setting
end

local function addSlider(category, key, name, minValue, maxValue, step, formatter)
	local setting = Settings.RegisterAddOnSetting(category, "BTE_" .. key:upper(), key, settingsTbl(),
		Settings.VarType.Number, name, defaultsTbl()[key])
	-- CreateSliderOptions(minValue, maxValue, rate) 的第三参是「步长」（内部 steps = (max-min)/rate），
	-- 传成步数会让滑条几乎不可调。
	local options = Settings.CreateSliderOptions(minValue, maxValue, step)
	if formatter and MinimalSliderWithSteppersMixin then
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
	end
	Settings.CreateSlider(category, setting, options)
	return setting
end

local function addDropdown(category, key, name, choices)
	local setting = Settings.RegisterAddOnSetting(category, "BTE_" .. key:upper(), key, settingsTbl(),
		Settings.VarType.String, name, defaultsTbl()[key])
	Settings.CreateDropdown(category, setting, function()
		local container = Settings.CreateControlTextContainer()
		for _, choice in ipairs(choices) do
			container:Add(choice.value, choice.text)
		end
		return container:GetData()
	end)
	return setting
end

local function addColorSwatch(category, name)
	local setting = Settings.RegisterProxySetting(category, "BTE_HIGHLIGHT_COLOR", Settings.VarType.String,
		name, colorToHex(defaultsTbl().highlightColor),
		function()
			return colorToHex(settingsTbl().highlightColor)
		end,
		function(value)
			local color = hexToColor(value)
			if color then settingsTbl().highlightColor = color end
		end)
	Settings.CreateColorSwatch(category, setting)
	return setting
end

local function resolveRootCategory()
	local boussole = _G.Boussole
	local internal = boussole and boussole.modules and boussole.modules.Options
		and boussole.modules.Options._internal
	local root = internal and internal.panels and internal.panels.root
	return root and root.category or nil
end

function Options:RegisterPanel()
	if self.category then return self.category end
	if not (_G.Settings and Settings.RegisterVerticalLayoutSubcategory and Settings.CreateCheckbox) then
		return nil
	end
	if not Addon.settings then return nil end

	local ok, category = pcall(function()
		local rootCategory = resolveRootCategory()
		local newCategory, layout
		if rootCategory then
			-- 官方允许 canvas 父分类下挂 vertical 子分类（Blizzard_ImplementationReadme.lua）
			newCategory, layout = Settings.RegisterVerticalLayoutSubcategory(rootCategory, L.ADDON_NAME)
		else
			newCategory, layout = Settings.RegisterVerticalLayoutCategory(L.ADDON_NAME)
			Settings.RegisterAddOnCategory(newCategory)
		end

		addSection(layout, L.SECTIONS_SOURCE)
		addCheckbox(newCategory, "enabled", L.SETTINGS_ENABLE_SOURCE, L.SETTINGS_ENABLE_SOURCE_TIP)
		addCheckbox(newCategory, "trackUserWaypoint", L.SETTINGS_USER_WAYPOINT, L.SETTINGS_USER_WAYPOINT_TIP)

		addSection(layout, L.SECTIONS_EDGE)
		addCheckbox(newCategory, "pointerStay", L.SETTINGS_POINTER_STAY, L.SETTINGS_POINTER_STAY_TIP)
		addDropdown(newCategory, "stayAtlas", L.SETTINGS_STAY_ATLAS, ATLAS_CHOICES)
		addCheckbox(newCategory, "hideFar", L.SETTINGS_HIDE_FAR, L.SETTINGS_HIDE_FAR_TIP)
		addCheckbox(newCategory, "useCurrentMap", L.SETTINGS_USE_CURRENT_MAP, L.SETTINGS_USE_CURRENT_MAP_TIP)

		addSection(layout, L.SECTIONS_EMPHASIS)
		addSlider(newCategory, "scaleMultiplier", L.SETTINGS_SCALE, 0.8, 2.5, 0.05, function(value)
			return string.format("%.2f", value)
		end)
		addColorSwatch(newCategory, L.SETTINGS_HIGHLIGHT_COLOR)
		addSlider(newCategory, "glowAlpha", L.SETTINGS_GLOW_ALPHA, 0, 1, 0.05, function(value)
			return string.format("%d%%", math.floor(value * 100 + 0.5))
		end)
		addCheckbox(newCategory, "useRewardIcon", L.SETTINGS_REWARD_ICON, L.SETTINGS_REWARD_ICON_TIP)

		addSection(layout, L.SECTIONS_LAYOUT)
		addCheckbox(newCategory, "showScale", L.SETTINGS_SHOW_SCALE, L.SETTINGS_SHOW_SCALE_TIP)

		self.category, self.layout = newCategory, layout
		return newCategory
	end)

	if not ok or not category then
		self.category, self.layout = nil, nil
		return nil
	end
	return category
end

function Options:Init()
	self:RegisterPanel()
end

function Options:Open()
	local category = self:RegisterPanel()
	if category and _G.Settings and _G.Settings.OpenToCategory then
		pcall(_G.Settings.OpenToCategory, category:GetID())
	end
end
