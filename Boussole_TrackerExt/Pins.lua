local _, ns = ...
local Addon = ns.Addon

-- 呈现层管理：本插件固定使用「刻度下方追踪层」，故此处仅产出统一的 trackedInfo。
-- （接管对应图钉、坐标匹配、SelectPin 选中态管理已在 2026-11-15 的重构中移除：
--  原生 API 图钉固定渲染在刻度上方，无法放到下方；手动选中与路线态交互亦无收益。）
local Pins = {}
Addon.Pins = Pins

function Pins:Update(_res)
	return { mode = "below" }
end
