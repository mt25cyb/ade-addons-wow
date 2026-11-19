-- adeAchDateFormat — Prat 3.0 成就日期扩展（Ext_Prat.lua，v6.5-r004）。
-- Prat 的「成就 -> 显示完成日期」模块给聊天成就链接尾缀固定 mm/dd/yy 完成日期，
-- 如 `获得了成就[<成就>] (已完成 11/17/26)`。该串由 Prat Achievements 模块的
-- module:addDate(day, month, year) 拼接（Prat-3.0/modules/Achievements.lua:177-183），
-- 且处理链 ShowOurCompletion 以动态查找调用它（Achievements.lua:148）——
-- 包装 module.addDate 字段即精准切入，Prat 模块 toggle 重启不重建 module 表，替换一次持久。
-- 日期格式不可配置：模块 options 只有 showCompletedDate 开关（:57-62），无 dateFormat。
--
-- 包装体复用 Prat 的三语文案与白色外壳，仅把 FormatShortDate 换成 ADF.FormatDate：
-- - 文案：module.PL.completed（PL 挂在模块表上，Achievements.lua:31）；
-- - 外壳：white("(")..white(")") 等价 Prat.CLR:Colorize("ffffff", ...)（Achievements.lua:112-114，CLR 全局可达）；
-- - 参数序：Prat 的 (day, month, year) 与 ADF.FormatDate 一致（Format.lua:21-30），无需调序。
-- 开关 dateFormat.enablePrat（默认 false）关闭时卸下包装恢复原函数；ADF.FormatDate
-- 异常时回退原实现。Prat 未装则静默闲置（可选扩展，非硬依赖）。
local ADF = _G.adeAchDateFormat
if not ADF then return end
local L = ADF.L or {}

local PRAT_MODULE_NAME = "Achievements"

local origAddDate   -- 原实现引用（卸下包装时恢复）
local hooked        -- 防重包装

local function White(colorizeAvailable, text)
	if colorizeAvailable then
		return Prat.CLR:Colorize("ffffff", text)
	end
	return text
end

--- 包装 module.addDate：守卫与输出结构对齐原实现（Achievements.lua:177-183）。
local function Wrap(module)
	local orig = origAddDate
	-- Prat.CLR 缺失（版本漂移）属契约破坏：error 暴露，不做静默降级
	if not (Prat.CLR and Prat.CLR.Colorize) then
		error("adeAchDateFormat: Prat CLR 不可用，无法接管成就日期（Ext_Prat）")
	end
	-- module.PL.completed 缺失同样契约破坏
	if not (type(module.PL) == "table" and module.PL.completed) then
		error("adeAchDateFormat: Prat 成就模块本地化文案缺失（PL.completed），无法接管日期（Ext_Prat）")
	end

	module.addDate = function(self, day, month, year)
		if not self.db.profile.showCompletedDate then
			return ""
		end
		local text = ADF.FormatDate(day, month, year)
		if not text then
			return orig(self, day, month, year)
		end
		return " " .. White(true, "(") .. self.PL.completed:format(text) .. White(true, ")")
	end
	hooked = true
end

local function Unwrap(module)
	if origAddDate then
		module.addDate = origAddDate
	end
	hooked = false
end

--- 开关应用：enablePrat 开则挂包装、关则恢复原函数；Prat 未加载/模块未就绪时静默闲置。
local function ApplyPratHook()
	if not (Prat and Prat.GetModule) then return end
	-- Prat 的 GetModule 覆盖版（addon/modules.lua:240-248）不透传 silent：模块不存在时
	-- 仍会 module:IsEnabled() 直接抛错（实证 _debug.log）。pcall 保护，模块未注册或未
	-- 启用（GetModule 对已禁用模块返回 nil）时静默闲置——「可选接管」语义。
	local ok, module = pcall(Prat.GetModule, Prat, PRAT_MODULE_NAME, true)
	if not ok or type(module) ~= "table" then return end
	if not ADF:Get("enablePrat") then
		-- 开关关闭：仅在已包装时卸下，不检查 Prat 模块契约（未开启接管不因 Prat 版本漂移报错）
		if hooked then
			Unwrap(module)
			ADF:Print(L.MSG_PRAT_UNHOOKED or "Prat achievements date hook removed.")
		end
		return
	end
	if type(module.addDate) ~= "function" then
		-- 模块存在但 addDate 缺失（版本漂移）且用户已要求接管：error 暴露，不做静默降级
		error("adeAchDateFormat: Prat 成就模块缺 addDate 方法（版本漂移），无法接管日期（Ext_Prat）")
	end
	if not hooked then
		origAddDate = module.addDate
	end
	Wrap(module)
	ADF:Print(L.MSG_PRAT_HOOKED or "Prat achievements date hook installed.")
end

ADF.RegisterRefresh(ApplyPratHook)

-- Prat 可能先于本插件加载：加载时立即试挂一次，并注册 ADDON_LOADED 兜底
-- （Krowi_AF_Ext 同款模式）。enablePrat 默认 false，默认态不会实际包装。
ApplyPratHook()

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Prat-3.0" then
		f:UnregisterEvent("ADDON_LOADED")
		ApplyPratHook()
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Prat 的模块经 Prat:AddModuleToLoad 工厂延迟创建（achievements 模块在
		-- Prat 初始化完成后才 NewModule），ADDON_LOADED 时可能尚未注册——
		-- 进世界再试挂一次（此时 Prat 必已就绪；ApplyPratHook 幂等）
		f:UnregisterEvent("PLAYER_ENTERING_WORLD")
		ApplyPratHook()
	end
end)
