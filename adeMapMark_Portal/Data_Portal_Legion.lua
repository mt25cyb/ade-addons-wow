--[[
adeMapMark_Portal - 7.x 军团再临（Legion）标记数据库
内容：职业大厅•德鲁伊传送点（10 点，来源旧版 BDmap_ade_Portal）
说明：只存各记录特有字段；颜色/可见性/尺寸由 Core.lua 补默认值，
      仅梦境林地 2 点指定 icon/note 例外
]]

local addonName = ...
local Data = _G[addonName].Data
local C = Data.Common

Data.LegionMarks = {
	-- 职业大厅•德鲁伊 (7.x)
	{ mapID = 747, coord = 56614306, title = "达拉然" },
	{ mapID = 715, coord = 31752645, title = "灰熊丘陵" },
	{ mapID = 715, coord = 23503900, title = "菲拉斯" },
	{ mapID = 715, coord = 19545948, title = "阿梅达希尔" },
	{ mapID = 715, coord = 26237995, title = "月光林地" },
	{ mapID = 715, coord = 39726926, title = "暮色森林" },
	{ mapID = 715, coord = 50446527, title = "辛特兰" },
	{ mapID = 715, coord = 53365272, title = "海加尔山" },
	{ mapID = 47,  coord = 46583595, title = "梦境林地", note = "职业大厅•德鲁伊", icon = C.ICON_RIFT },
	{ mapID = 198, coord = 59072614, title = "梦境林地", note = "职业大厅•德鲁伊", icon = C.ICON_RIFT },
}
