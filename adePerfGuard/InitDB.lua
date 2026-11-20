--[==[ adePerfGuard / InitDB.lua
独立存档装配（脱库：不依赖 ade_UIKit.DB）。settings.* 扁平结构：
  ADEDB_PERF_GUARD = { settings = { enabled = true } }
defaults 语义与 adeMapTab_Portal/InitDB.lua 一致（缺失键补全、已有键不覆盖）；
本插件 settings 仅一层标量，无嵌套表，无需深拷贝。 ]==]
local _, addon = ...

addon.defaults = {
	settings = {
		enabled = true, -- /adeperf on|off；默认开（功能本身零常驻成本）
	},
}

-- 缺失键补全（递归），已有键不覆盖——与 ade_UIKit.DB.MergeDefaults 同语义。
local function MergeDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if tbl[k] == nil then
			tbl[k] = v
		elseif type(v) == "table" and type(tbl[k]) == "table" then
			MergeDefaults(tbl[k], v)
		end
	end
end

-- ADDON_LOADED(自身) 时调用；PLAYER_ENTERING_WORLD 兜底重入（幂等）。
function addon.InitDB()
	ADEDB_PERF_GUARD = ADEDB_PERF_GUARD or {}
	MergeDefaults(ADEDB_PERF_GUARD, addon.defaults)
end
