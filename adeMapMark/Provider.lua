--[[
adeMapMark - Provider（外挂坐标数据包 API）
定位：自建 Provider 注册表、标记归一化、子插件 DB、汇总与刷新链路
体系：ADE v6.5
来源：_temp/_map/old_dev/BDmap_ade/BDmap.lua:154-281（已验证的旧版实现）
计划：_docs/plans/adeMapMark-dev-plan.md §2、§八
]]

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L

-- 注册表（对外可见，供 debug 命令读取）
ns.markProviders = ns.markProviders or {}

-- 子插件独立配置库（每个数据包在自己的 TOC 声明同名 SavedVariables）
function ns.GetSubDB(name)
    if type(name) ~= "string" or name == "" then return nil end
    local globalName = name .. "DB"
    local db = _G[globalName]
    if type(db) ~= "table" then db = {} end
    if db.enabled == nil then db.enabled = true end
    db.favorites = db.favorites or {}
    db.visibility = db.visibility or {}
    db.collapsed = db.collapsed or {}
    db.overrides = db.overrides or {}
    _G[globalName] = db
    return db
end

-- 稳定收藏键：用 providerName（而非 TOC Title），标题改动不丢收藏
local function GetProviderFavKey(data)
    return (data.providerName or "?") .. "|" .. tostring(data.mapID) .. "|" .. tostring(data.coord) .. "|" .. tostring(data.title)
end
ns.GetProviderFavKey = GetProviderFavKey

-- 数据包短名：由子插件自己声明，主插件直接取值，不做 TOC Title 解析。
-- 优先用注册表里的 shortName；子插件也可只放全局常量 <包名>_SHORT_NAME。
ns.providerShortNames = ns.providerShortNames or {}
function ns.GetProviderDisplayName(providerName)
    local name = tostring(providerName or "")
    return ns.providerShortNames[name]
        or _G[name .. "_SHORT_NAME"]
        or name
end

-- 把外部原始坐标规范为内部标记结构
-- raw: { mapID, coord 或 x/y, title, note, color, icon,
--        iconSize（图标/标记基准尺寸）, textSize（大地图文字字号）, isVisible }
-- 归一化后的内部标记结构与 raw 字段同名（iconSize/textSize），全链路统一命名。
-- 颜色/尺寸/备注/图标等默认值来自数据包；若子插件 DB 有单标覆写则以覆写为准。
local function NormalizeMark(raw, providerName, ignoreOverrides)
    if type(raw) ~= "table" or not raw.mapID then return nil end
    local x, y
    if raw.coord then
        x, y = ns.decodeCoord(raw.coord)
    else
        x, y = tonumber(raw.x) or 0, tonumber(raw.y) or 0
    end
    if x > 1 then x = x / 100 end
    if y > 1 then y = y / 100 end
    x, y = ns.clamp(x), ns.clamp(y)

    local title = tostring(raw.title or "")
    local source = ns.GetProviderDisplayName(providerName)
    local m = {
        mapID      = raw.mapID,
        coord      = ns.encodeCoord(x, y),
        title      = title,
        note       = tostring(raw.note or ""),
        color      = ns.cloneColor(raw.color),
        icon       = raw.icon,
        iconSize   = raw.iconSize,
        textSize   = raw.textSize,
        isVisible  = (raw.isVisible ~= false),
        isExternal = true,
        source     = source,
        providerName = providerName,
    }
    if not ignoreOverrides then
        local db = ns.GetSubDB(providerName)
        local ov = db and db.overrides and db.overrides[GetProviderFavKey(m)]
        if type(ov) == "table" then
            if ov.color then m.color = ns.cloneColor(ov.color) end
            if ov.iconSize then m.iconSize = ov.iconSize end
            if ov.textSize then m.textSize = ov.textSize end
            if ov.note then m.note = tostring(ov.note) end
            if ov.icon then m.icon = ov.icon end
            if ov.iconRotation then m.iconRotation = ov.iconRotation end
            if ov.iconCrop then m.iconCrop = ov.iconCrop end
            if ov.isGrayscale ~= nil then m.isGrayscale = ov.isGrayscale end
        end
    end
    return m
end
ns.NormalizeMark = NormalizeMark

-- 单标覆写读写：所有持久化都落在子插件自己的 DB，主插件不保存外挂自定义数据
function ns.SetProviderMarkOverride(data, field, value)
    if not data or not field then return end
    local db = ns.GetSubDB(data.providerName)
    if not db then return end
    db.overrides = db.overrides or {}
    local key = GetProviderFavKey(data)
    db.overrides[key] = db.overrides[key] or {}
    db.overrides[key][field] = value
    data[field] = value
end

-- 该标记是否存在单标自定义覆写：主面板「还原」图标的显示条件
function ns.HasProviderMarkOverrides(data)
    if not data or not data.providerName then return false end
    local db = ns.GetSubDB(data.providerName)
    local ov = db and db.overrides and db.overrides[GetProviderFavKey(data)]
    return type(ov) == "table" and next(ov) ~= nil
end

-- 清除该标记的全部自定义，恢复数据包内置数据（不碰收藏/可见性）
function ns.ClearProviderMarkOverrides(data)
    if not data or not data.providerName then return false end
    local db = ns.GetSubDB(data.providerName)
    if not db or not db.overrides then return false end
    local key = GetProviderFavKey(data)
    if not db.overrides[key] then return false end
    db.overrides[key] = nil
    return true
end

-- 只删一个字段的覆写；该标记再无覆写时把整个 key 清掉，避免留下"空自定义"
function ns.RemoveProviderMarkOverride(data, field)
    if not data or not field then return end
    local db = ns.GetSubDB(data.providerName)
    if not db or not db.overrides then return end
    local key = GetProviderFavKey(data)
    local ov = db.overrides[key]
    if type(ov) ~= "table" then return end
    ov[field] = nil
    if next(ov) == nil then db.overrides[key] = nil end
end

-- 取该标记的数据包内置原值（忽略子插件 DB 的单标覆写），供主面板判断表单值是否真的被自定义过
function ns:GetProviderOriginalMark(data)
    if not data or not data.providerName then return nil end
    local key = GetProviderFavKey(data)
    for _, p in ipairs(self.markProviders) do
        if p.name == data.providerName then
            local marks = ns.safecall(p.GetMarks, p)
            if type(marks) == "table" then
                for _, raw in ipairs(marks) do
                    local m = NormalizeMark(raw, p.name, true)
                    if m and GetProviderFavKey(m) == key then return m end
                end
            end
        end
    end
    return nil
end

function ns.IsProviderFavorited(data)
    local db = ns.GetSubDB(data.providerName)
    return db and db.favorites and db.favorites[GetProviderFavKey(data)] or false
end

function ns.ToggleProviderFavorite(data)
    local db = ns.GetSubDB(data.providerName)
    if not db then return end
    db.favorites = db.favorites or {}
    local key = GetProviderFavKey(data)
    db.favorites[key] = not db.favorites[key]
end

function ns.SetProviderFavorite(data, value)
    if not data then return end
    local db = ns.GetSubDB(data.providerName)
    if not db then return end
    db.favorites = db.favorites or {}
    db.favorites[GetProviderFavKey(data)] = value == true
    if ns.RefreshRecentList then ns.RefreshRecentList() end
end

-- 逐标可见性：勾选框直接读写子插件 DB 的 visibility，主插件不落盘
function ns.IsProviderVisible(data)
    if not data then return true end
    local db = ns.GetSubDB(data.providerName)
    if not db then return true end
    return db.visibility[GetProviderFavKey(data)] ~= false
end

function ns.SetProviderVisibility(data, visible)
    if not data then return end
    local db = ns.GetSubDB(data.providerName)
    if not db then return end
    db.visibility = db.visibility or {}
    db.visibility[GetProviderFavKey(data)] = visible == true
    data.isVisible = visible == true
    ns:RefreshExternal()
    if ns.RefreshRecentList then ns.RefreshRecentList() end
end

-- 刷新链路必须自包含：只调用已声明的全局表方法，避免前向引用 local 导致 nil 崩溃
function ns.RefreshExternal()
    if _G.adeMapMarkDataProvider and _G.adeMapMarkDataProvider:GetMap() then
        _G.adeMapMarkDataProvider:RefreshAllData()
    end
    if ns.Plus and ns.Plus.RefreshMinimapPins then
        pcall(ns.Plus.RefreshMinimapPins)
    end
end

-- 注册外挂坐标包
function ns:RegisterMarkProvider(provider)
    if type(provider) ~= "table" or not provider.name then
        ns.Print("|cffff4444" .. L.ERR_PROVIDER_NO_NAME .. "|r")
        return
    end
    if provider.shortName then ns.providerShortNames[provider.name] = provider.shortName end
    for _, p in ipairs(self.markProviders) do
        if p.name == provider.name then
            p.GetMarks, p.title, p.version, p.readOnly, p.shortName = provider.GetMarks, provider.title, provider.version, provider.readOnly, provider.shortName
            self:RefreshExternal()
            return
        end
    end
    tinsert(self.markProviders, provider)
    ns.Print("|cff00ff00" .. string.format(L.PROVIDER_REGISTERED, provider.title or provider.name) .. "|r")
    self:RefreshExternal()
end

function ns:UnregisterMarkProvider(name)
    for i, p in ipairs(self.markProviders) do
        if p.name == name then
            tremove(self.markProviders, i)
            self:RefreshExternal()
            return
        end
    end
end

-- 汇总所有外挂标记（受包级开关过滤）
-- includeHidden=true 时连同被隐藏的标记一并返回，供清单勾选框显示/恢复；
-- 每个 m.isVisible 反映逐标可见性，地图渲染仍由调用方按该字段过滤。
function ns:GetProviderMarkers(includeHidden)
    local result = {}
    for _, p in ipairs(self.markProviders) do
        local subDB = ns.GetSubDB(p.name)
        if subDB and subDB.enabled ~= false then
            -- safecall 契约：直接返回结果或 nil（不是 ok, result）
            local marks = ns.safecall(p.GetMarks, p)
            if type(marks) == "table" then
                for _, raw in ipairs(marks) do
                    local m = NormalizeMark(raw, p.name)
                    if m then
                        local visible = subDB.visibility[GetProviderFavKey(m)] ~= false
                        m.isVisible = visible
                        if includeHidden or visible then tinsert(result, m) end
                    end
                end
            end
        end
    end
    return result
end

-- 获取外挂包列表（供设置面板展示）
function ns:GetProviderList()
    local list = {}
    for _, p in ipairs(self.markProviders) do
        local subDB = ns.GetSubDB(p.name)
        local marks = ns.safecall(p.GetMarks, p)
        local count = (type(marks) == "table") and #marks or 0
        tinsert(list, {
            name = p.name,
            title = p.title or p.name,
            version = p.version,
            readOnly = p.readOnly,
            count = count,
            db = subDB,
        })
    end
    return list
end
