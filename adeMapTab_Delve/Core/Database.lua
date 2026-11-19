--[==[ adeMapTab_Delve / Core\Database.lua
v6.5 兼容层：addon.db 由 Core.lua 装配后挂到 profile（UIKit MergeDefaults 补缺失键）。
扁平默认值来自 InitDB.lua；嵌套表必须 rawget 判定后显式建表，
否则读取会拿到 defaults 里的共享表（原先切 profile 会串数据）。 ]==]
local _, addon = ...
local MapTab = LibStub("AdeMapTab-1.0")

-- 扁平默认值已由 InitDB.lua 的 ns.defaults.profile 提供，这里只补 AceDB 未覆盖的显式键。
function addon.Database.SetDefault(key, value)
    if rawget(addon.db, key) == nil then addon.db[key] = value end
end

-- 角色键与 EverythingDelves 的格式一致：名字 - 服务器。
function addon.Database.CharKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Unknown"
    return name .. " - " .. realm
end

function addon.Database.Initialize()
    for key, value in pairs(addon.defaults.profile) do
        addon.Database.SetDefault(key, value)
    end

    -- 跨角色快照（账号级 SavedVariables，见 Services/Roster.lua）、资料片折叠态、
    -- 过滤器、小地图位置：全部按 nestedDefaults 深拷贝建独立表。
    -- rawget 判定避免读到 AceDB metatable 回落的共享 defaults 表。
    for key, template in pairs(addon.nestedDefaults) do
        if rawget(addon.db, key) == nil then
            addon.db[key] = MapTab.CopyTable(template)
        end
    end
    if type(addon.db.filters.expansion) ~= "table" then
        addon.db.filters.expansion = MapTab.CopyTable(addon.nestedDefaults.filters.expansion)
    end
    -- 第二阶段 9.4.1：类型过滤收敛为三类（地下堡 / 丰饶区域 / 仪式场地）。
    if type(addon.db.filters.kind) ~= "table" then
        addon.db.filters.kind = MapTab.CopyTable(addon.nestedDefaults.filters.kind)
    end
end

function addon.Database.GetFilter(group, key)
    local bucket = addon.db and addon.db.filters and addon.db.filters[group]
    if type(bucket) ~= "table" then return true end
    return bucket[key] ~= false
end

function addon.Database.SetFilter(group, key, value)
    if not (addon.db and addon.db.filters) then return end
    addon.db.filters[group] = addon.db.filters[group] or {}
    addon.db.filters[group][key] = value
end
