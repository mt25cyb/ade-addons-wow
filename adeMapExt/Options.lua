-- adeMapExt — 设置窗口：基于 ade_UIKit（v6.5）原生 RegisterTab。
-- 三分区：panel（显示与格式）/ appearance（外观）/ behavior（行为），单组「面板」。
-- 颜色用官方 ColorPickerFrame（12.x 契约 SetupColorPickerAndShow，
-- 实证 adeStatPlus/Options.lua:185-205 同款）。
local AME = _G.adeMapExt
if not AME then return end
local ns = AME
local L = ns.L or {}

-- 库解析延迟到命令/构建时，避免加载顺序导致顶层 return 后连 slash 都没注册。
local function GetOF()
	local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
	if lib then return lib end
	return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function CopyValue(v)
	if type(v) ~= "table" then return v end
	local copy = {}
	for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
	return copy
end

--- 补上 BOF 行契约：get/set/default 直接从存档读写转发；
--- set 后调 ns.OnPanelSettingChanged(key) 让面板即时生效（Panel.lua 联动）。
local function KeySpec(spec, key)
	spec.key = key
	spec.get = function() return ns.db()[key] end
	spec.set = function(value)
		ns.db()[key] = value
		if ns.OnPanelSettingChanged then ns.OnPanelSettingChanged(key) end
	end
	if spec.default == nil then spec.default = ns.DB_DEFAULTS[key] end
	return spec
end

-- 颜色行：UIKit b034 的 kind="color" 色块控件（显示当前颜色，点击弹官方
-- ColorPickerFrame）。存档格式 8 位 hex（alpha 位忽略，透明度由独立
-- gwBgAlpha/gwBorderAlpha 滑条控制，同 idTipExt 1.3.0 口径）；
-- KeySpec 的 get/set/default 与 hex 存档直接兼容。
-- 旧实现（execute+onClick）存在静默失效坑：KeySpec 无条件塞 set，MakeOption
-- 的 Set 分支 set 优先 → onClick 永不执行（用户 2026-11-18 实测点击无反应）。
local function ColorExecute(key, label)
	return { kind = "color", label = label }
end

local P = L.Panel

local sections = {
	panel = {
		KeySpec({ kind = "toggle", label = L.ShowPhaseID }, "gwShowPhase"),
		KeySpec({ kind = "toggle", label = P.Hexadecimal }, "gwUseHexadecimal"),
		KeySpec({ kind = "toggle", label = L.ShowMapID }, "gwShowMap"),
		KeySpec({ kind = "toggle", label = L.ShowWorldMapID }, "gwShowWorldMap"),
		KeySpec({ kind = "toggle", label = L.ShowInstanceID }, "gwShowInstance"),
		KeySpec({ kind = "toggle", label = L.ShowZoneID }, "gwShowZone"),
		KeySpec({ kind = "select", label = L.MapNameMode,
			items = { { value = "none", text = L.MapNameNone },
				{ value = "inline", text = L.MapNameInline },
				{ value = "separate", text = L.MapNameSeparate } } }, "gwMapNameMode"),
		KeySpec({ kind = "toggle", label = P.ShowPanel }, "gwShowPanel"),
		KeySpec({ kind = "toggle", label = P.WorldMapPanel }, "gwWorldMapPanel"),
		KeySpec({ kind = "select", label = P.WorldMapPosition,
			items = { { value = "top", text = P.WorldMapTop },
				{ value = "bottom", text = P.WorldMapBottom } },
			disabled = function() return not ns.db().gwWorldMapPanel end }, "gwWorldMapPosition"),
	},
	appearance = {
		KeySpec({ kind = "select", label = L.Style,
			items = { { value = "double", text = L.StyleDouble },
				{ value = "single", text = L.StyleSingle } }, desc = L.StyleTip }, "style"),
		KeySpec({ kind = "toggle", label = L.PrefixClassColor }, "gwPrefixClassColorEnabled"),
		KeySpec(ColorExecute("gwPrefixColor", L.PrefixColor), "gwPrefixColor"),
		KeySpec({ kind = "range", label = L.PanelWidth, min = 160, max = 420, step = 10 }, "gwPanelWidth"),
		KeySpec({ kind = "range", label = P.FontSize, min = 10, max = 32, step = 1 }, "gwFontSize"),
		KeySpec({ kind = "range", label = P.Alpha, min = 0.1, max = 1.0, step = 0.05 }, "gwAlpha"),
		KeySpec(ColorExecute("gwBgColor", P.BackgroundColor), "gwBgColor"),
		KeySpec({ kind = "range", label = P.BgAlpha, min = 0, max = 1.0, step = 0.05 }, "gwBgAlpha"),
		KeySpec(ColorExecute("gwBorderColor", P.BorderColor), "gwBorderColor"),
		KeySpec({ kind = "range", label = P.BorderAlpha, min = 0, max = 1.0, step = 0.05 }, "gwBorderAlpha"),
	},
	behavior = {
		KeySpec({ kind = "toggle", label = P.Lock }, "gwIsLocked"),
		KeySpec({ kind = "toggle", label = P.AutoHide }, "gwAutoHideInCombat"),
		KeySpec({ kind = "toggle", label = P.DetailedTooltip }, "gwShowTooltip"),
		KeySpec({ kind = "select", label = L.GrowDirection,
			items = { { value = "down", text = L.GrowDown },
				{ value = "up", text = L.GrowUp } } }, "gwGrowDirection"),
		KeySpec({ kind = "range", label = P.UpdateInterval, min = 0.1, max = 2.0, step = 0.1 }, "gwUpdateInterval"),
	},
}

local sectionNames = {
	panel = L.Sections.Panel,
	appearance = L.Sections.Appearance,
	behavior = L.Sections.Behavior,
}

local sectionKeys = {
	panel = { "gwShowPhase", "gwUseHexadecimal", "gwShowMap", "gwShowWorldMap", "gwShowInstance",
		"gwShowZone", "gwMapNameMode", "gwShowPanel", "gwWorldMapPanel", "gwWorldMapPosition" },
	appearance = { "style", "gwPrefixClassColorEnabled", "gwPrefixColor", "gwPanelWidth", "gwFontSize",
		"gwAlpha", "gwBgColor", "gwBgAlpha", "gwBorderColor", "gwBorderAlpha" },
	behavior = { "gwIsLocked", "gwAutoHideInCombat", "gwShowTooltip", "gwGrowDirection", "gwUpdateInterval" },
}

local function SameValue(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for key, value in pairs(a) do if not SameValue(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end

local function CountChanged()
	local count = 0
	for _, keys in pairs(sectionKeys) do
		for _, key in ipairs(keys) do
			if not SameValue(ns.db()[key], ns.DB_DEFAULTS[key]) then count = count + 1 end
		end
	end
	return count
end

local function ResetSection(id)
	local keys = sectionKeys[id]
	if not keys then return false end
	local changed = false
	for _, key in ipairs(keys) do
		local value = ns.db()[key]
		local def = ns.DB_DEFAULTS[key]
		if not SameValue(value, def) then
			ns.db()[key] = CopyValue(def)
			changed = true
		end
	end
	if changed and ns.OnPanelSettingChanged then
		for _, key in ipairs(keys) do ns.OnPanelSettingChanged(key) end
	end
	return changed
end

local tab

local function Build()
	if tab then return tab end
	local lib = GetOF()
	if not lib then return nil end
	tab = lib.RegisterTab({
		name = AME.title,
		saved = adeMapExtDB or {},
		groups = {
			{ name = L.Sections.PanelGroup, sections = { "panel", "appearance", "behavior" } },
		},
		sectionName = function(id) return sectionNames[id] or id end,
		elements = function(id) return sections[id] end,
		landing = function() return "panel" end,
		changedCount = CountChanged,
		resetSection = ResetSection,
		onCreated = function() end,
	})
	-- 原生「设置 > 插件」里注册「打开选项」入口页（KAF Stub 同款）
	if lib.RegisterOptionsStub then
		lib.RegisterOptionsStub({
			title = AME.title,
			version = AME.version,
			tab = tab,
		})
	end
	return tab
end

--- 加载期注册 tab 与 stub 页（Core ADDON_LOADED 调用；KAF Stub 同款时点）。
--- ade_UIKit 为 ## Dependencies 硬依赖，失败直接 error 暴露，不做静默降级。
function ns.InitOptionsStub()
	if not Build() then
		error("adeMapExt: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
	end
end

function ns:ToggleOptions()
	local registered = Build()
	if not registered then
		ns.PrintPanelMsg("ade_UIKit 未加载：请确认该插件已勾选。")
		return
	end
	registered:Toggle("panel")
end
