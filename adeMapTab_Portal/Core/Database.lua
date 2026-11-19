--[==[ adeMapTab_Portal / Core\Database.lua
v6.5 兼容层：addon.db 由 Core.lua 装配后挂到 profile（UIKit MergeDefaults 补缺失键）。
扁平默认值来自 InitDB.lua；嵌套表用 rawget 判定后显式建表（避免共享 defaults 里的表）。
v4 的四段老档迁移逻辑逐行保留 —— 虽然新 SV 名不读旧档，
这段折算逻辑仍作用于插件内部旧键，不能删（用户 2026-10-29 的「设置改不动」修复）。 ]==]
local _, addon = ...
local MapTab = LibStub("AdeMapTab-1.0")

-- 扁平默认值已由 InitDB.lua 的 ns.defaults.profile 提供，这里只补显式键。
function addon.Database.SetDefault(key, value)
    if rawget(addon.db, key) == nil then addon.db[key] = value end
end

function addon.Database.Initialize()
    for key, value in pairs(addon.defaults.profile) do
        addon.Database.SetDefault(key, value)
    end

    -- 偏好炉石 / 折叠态 / 收藏 / 类型筛选 / 布局偏移 / 最近使用：按 nestedDefaults
    -- 深拷贝建独立表。rawget 判定避免读到 AceDB metatable 回落的共享 defaults 表。
    for key, template in pairs(addon.nestedDefaults) do
        if rawget(addon.db, key) == nil then
            addon.db[key] = MapTab.CopyTable(template)
        end
    end

    -- 「按钮位置」+「排列方向」已合并为 zoneButtonsLayout（用户 2026-10-29）。老档先把
    -- anchor + orientation 折算到最接近的新预设，避免用户改过的位置被默认值覆盖。
    do
        local legacyMap = {
            TOPLEFT = { vertical = "topLeftColumn", horizontal = "topLeftRow" },
            TOPRIGHT = { vertical = "topRightRow", horizontal = "topRightRow" },
            BOTTOMRIGHT = { vertical = "bottomRightColumn", horizontal = "bottomRightRow" },
        }
        local legacy = legacyMap[addon.db.zoneButtonsAnchor]
        if legacy then
            addon.db.zoneButtonsLayout = addon.db.zoneButtonsOrientation == "horizontal" and legacy.horizontal or legacy.vertical
        end
        -- ⚠ 迁移完必须清掉旧键：这段在每次 Initialize 都会执行，只要旧键还在，
        -- 就会把用户新选的 zoneButtonsLayout 覆盖回旧锚角对应的值
        -- （用户 2026-10-29「按钮布局配置无法保存」的根因）。
        addon.db.zoneButtonsAnchor = nil
        addon.db.zoneButtonsOrientation = nil
    end

    -- 老档迁移：旧的全局 zoneButtonsOffsetX/Y 折算到「布局项各自独立」的新结构里。
    if addon.db.zoneButtonsOffsetX ~= nil or addon.db.zoneButtonsOffsetY ~= nil then
        local key = addon.db.zoneButtonsLayout or "topLeftColumn"
        local slot = addon.db.zoneButtonsOffsets[key]
        if type(slot) ~= "table" then slot = {} addon.db.zoneButtonsOffsets[key] = slot end
        if slot.x == nil then slot.x = tonumber(addon.db.zoneButtonsOffsetX) or 0 end
        if slot.y == nil then slot.y = tonumber(addon.db.zoneButtonsOffsetY) or 0 end
        -- 与上面的 anchor / orientation 同理：迁移完必须清掉旧键，否则这段每次 Initialize
        -- 都会重跑（同类「设置改不动」隐患，用户 2026-10-29）。
        addon.db.zoneButtonsOffsetX = nil
        addon.db.zoneButtonsOffsetY = nil
    end

    -- 兼容早期只保存一个炉石 ID 的配置。
    if type(addon.db.teleportsPreferredHearthstone) ~= "table" then
        local legacy = addon.db.teleportsPreferredHearthstone
        local selection = {}
        if type(legacy) == "number" then
            selection[tostring(legacy)] = true
        elseif type(legacy) == "string" and legacy ~= "" and legacy ~= "random" and legacy ~= "0" then
            selection[legacy] = true
        end
        addon.db.teleportsPreferredHearthstone = selection
    end
end
