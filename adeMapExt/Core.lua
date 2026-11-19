----------------------------------------------------------------------------
-- adeMapExt 核心
-- 定位：地图增强宿主插件（后续地图增强功能以新文件挂载，TOC 追加即插）
-- 当前承载：地理监视面板 + 世界地图信息面板（自 idTipExt 1.3.0 GeoWatcher.lua 迁入，
--   见 _docs/plans/adeMapExt-dev-plan.md）
-- 体系：ADE v6.5，ade_UIKit 硬依赖（设置窗口），零 Ace 依赖
----------------------------------------------------------------------------

local addonName = ...

local AME = _G.adeMapExt or {}
_G.adeMapExt = AME
-- Panel.lua 自 idTipExt 迁移而来，沿用 ns 局部名；两者同一张表
local ns = AME
ns.addonName = addonName

-- 名称/版本/图标统一经 UIKit GetAddonMeta 取 TOC 元数据
local OF = GetBlizzOptionsFrame("ade_UIKit", true)
local addonMeta = OF.GetAddonMeta(addonName)
AME.title = addonMeta.title
AME.version = addonMeta.version
AME.iconSpec = addonMeta.icon

-- 文案表骨架：Locales/enUS.lua 填充英文默认值，zhCN / zhTW 按 GetLocale() 覆盖
ns.L = { Panel = {}, Sections = {} }

----------------------------------------------------------------------------
-- API 绑定
----------------------------------------------------------------------------
-- Secret Values：标量与表绑定一次而非每次调用（idTipExt Core.lua:126-129 原样）
local isSecret = issecretvalue and issecrettable and function(value)
	return issecretvalue(value) or (type(value) == "table" and issecrettable(value))
end or function() return false end
ns.isSecret = isSecret

----------------------------------------------------------------------------
-- 工具（自 idTipExt Core.lua 迁入；面板渲染所需的 9 个共享设施）
----------------------------------------------------------------------------
-- 单段式行：前缀与值各用一种色码
function ns.rgbHex(r, g, b)
	return string.format("ff%02x%02x%02x",
		math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

function ns.colorizeHex(text, hex)
	return "|c" .. hex .. text .. "|r"
end

-- 前缀与值同串混色
function ns.colorizeRow(prefix, value, pr, pg, pb, vr, vg, vb)
	return ns.colorizeHex(prefix, ns.rgbHex(pr, pg, pb)) .. " " .. ns.colorizeHex(value, ns.rgbHex(vr, vg, vb))
end

-- CreateColorFromHexString 只接受 8 位 AARRGGBB；异常值返回兜底色对象
function ns.parseHexColor(hex, fr, fg, fb)
	return CreateColorFromHexString(hex) or CreateColor(fr, fg, fb, 1)
end

-- 纯 Lua clamp，不依赖客户端是否提供 math.clamp
function ns.clamp(value, lo, hi)
	if value < lo then return lo end
	if value > hi then return hi end
	return value
end

function ns.hookScript(target, script, callback)
	if callback and target and target.HasScript and target:HasScript(script) then
		target:HookScript(script, callback)
	end
end

-- 存档访问统一入口：函数体内延迟解引用，Core 加载时存档可能尚未注入
function ns.db()
	return adeMapExtDB
end

-- ADDON_LOADED 分发：模块经 RegisterOnAddonLoaded(fn) 挂回调（Blizzard_WorldMap 晚加载补挂用）
ns.onAddonLoaded = {}
function ns.RegisterOnAddonLoaded(fn)
	ns.onAddonLoaded[#ns.onAddonLoaded + 1] = fn
end

-- 职业色：UnitClass(unit) 的第二个返回值是 classFilename
-- （依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_SharedXML/ColorUtil.lua:66-81）
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

	return r, g, b, ns.rgbHex(r, g, b)
end

-- 面板前缀颜色策略：按职业着色优先（玩家自身），否则用自定义 hex。
-- 键名 gw 前缀——面板外观独立于任何 tooltip 设置（拆分后本插件无 tooltip 功能）
function ns.prefixColor(opts)
	local db = ns.db()
	if db.gwPrefixClassColorEnabled then
		local r, g, b = ns.classColor(opts and opts.unit or "player")
		if r then return r, g, b end
	end
	local color = ns.parseHexColor(db.gwPrefixColor or ns.DB_DEFAULTS.gwPrefixColor, 1, 1, 1)
	return color.r, color.g, color.b
end

-- 面板消息（带插件名蓝色前缀）
function ns.PrintPanelMsg(msg)
	if msg and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00BFFF[" .. addonName .. "]|r " .. msg)
	end
end

ns.Print = ns.PrintPanelMsg

-- 右键菜单 / 命令的设置入口委托给 Options.lua 的 ToggleOptions（UIKit Tab 打开）
ns.OpenSettings = function()
	ns:ToggleOptions()
end

----------------------------------------------------------------------------
-- ADDON_LOADED：ensureDB（含 idTipExtDB 一次性迁移）→ stub 注册 → 模块回调
----------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, addon)
	ns.ensureDB()
	-- 原生「设置 > 插件」的「打开选项」入口页在加载期注册（KAF Stub 同款时点）；
	-- ade_UIKit 为硬依赖，失败直接 error 暴露，不做静默降级。
	if addon == addonName and ns.InitOptionsStub then
		ns:InitOptionsStub()
	end
	for _, fn in ipairs(ns.onAddonLoaded) do
		fn(addon)
	end
end)
