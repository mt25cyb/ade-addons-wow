-- adeBagPack / Core.lua 第 1 段：入口与模块调度（旧 adeBackpack Core 移植，计划 P1）
-- 私有 addon 表入口（statPlus 同款）：零 _G.ADE / 零 ade_Commons。
-- 存档沿用 ADEDB_BACKPACK 旧结构，缺失键由 ade_UIKit DB.MergeDefaults 补全。
-- 名称/版本/图标走 UIKit GetAddonMeta（b024）。
-- 模块调度 MODULE_KEYS = {Config, Rule, Bag, Slot, Item, Group, Pack}
-- P3 追加 Minimap/Blizzard/Baganator 三入口（各自 Init 读 profile 自驱，加载序在 Pack 之后）
-- （旧 Junk/Repair/Settings/JunkFrame/Blizzard/Baganator/Minimap：前四者随功能删除，后三者 P2/P3 接入）
-- /adebp debug 诊断工具拆至 Debug.lua（加载序末尾）。

local addonName = ...
-- statPlus 同款：Locales 先于本文件建表（_G.adeBagPack or {}），此处复用同一表
local ABP = _G.adeBagPack or {}
_G.adeBagPack = ABP
ABP.name = addonName or "adeBagPack"

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end
ABP.GetOF = GetOF

local UIKit = GetOF()
if not UIKit then
    error("adeBagPack: ade_UIKit 未就绪（检查 Dependencies 与加载顺序）")
end
ABP.UIKit = UIKit

local meta = UIKit.GetAddonMeta(addonName)
ABP.title = meta.title
ABP.version = meta.version

ABP.Debug = function() end

ABP.MODULE_KEYS = { "Config", "Rule", "Bag", "Slot", "Item", "Group", "Pack", "External", "Minimap", "Blizzard", "Baganator" }

function ABP:InitModules()
    for _, key in ipairs(self.MODULE_KEYS) do
        local m = self[key]
        if m and m.Init then
            m:Init()
        end
    end
end

ABP.Base = {
    SetParent = function(self, parent) self.parent = parent end,
    GetParent = function(self) return self.parent end,
}
-- ============ 共享数据层（旧 Core.lua 原样移植，12.1.0 容器/物品 API 收口 C_*） ============

local GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local PickupContainerItem = C_Container.PickupContainerItem
local GetContainerItemID = C_Container.GetContainerItemID
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetItemFamily = C_Item.GetItemFamily

function ABP:GetItemID(itemLink)
    if not itemLink then
        return
    end
    if type(itemLink) == "number" then
        return itemLink
    end
    if type(itemLink) == "string" and itemLink:find("battlepet") then
        local id = itemLink:match("battlepet:(%d+)")
        return id and ("battlepet:" .. id) or nil
    end
    if type(itemLink) == "string" then
        return tonumber(itemLink:match("item:(%d+)"))
    end
end

function ABP:GetItemInfo(itemID)
    if type(itemID) == "number" then
        -- 还原为 Item.lua 约定的 7 元组顺序：name, type, subType, equipLoc, quality, level, texture。
        -- C_Item.GetItemInfo 原生顺序为 name,link,quality,level,minLevel,type,subType,stack,equipLoc,texture…，
        -- 直接透传会让 itemLevel 错位成 type 字符串（"消耗品"）→ Rule 排序算术报错。
        local name, _, quality, level, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemID)
        return name, itemType, itemSubType, equipLoc, quality, level, texture
    end
    local species = itemID and itemID:match("battlepet:(%d+)")
    if species then
        local _, _, _, _, _, _, _, _, _, _, _, classID = GetItemInfoInstant(tonumber(species))
        return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, classID
    end
    return nil
end

function ABP:GetBagSlotLink(bag, slot) return GetContainerItemLink(bag, slot) end

-- 取槽位物品 ID：优先 GetContainerItemID（不要求物品数据已缓存），链接仅作回落。
-- 旧实现只用链接 → 未缓存物品漏进待排集合 → 钥石不动/多次整理才完成。
function ABP:GetBagSlotID(bag, slot)
    local id = GetContainerItemID(bag, slot)
    if id ~= nil then
        return id
    end
    local link = GetContainerItemLink(bag, slot)
    if link then
        return self:GetItemID(link)
    end
end

function ABP:GetBagSlotFamily(bag, slot)
    local id = self:GetBagSlotID(bag, slot)
    if not id then
        return 0
    end
    return type(id) == "string" and 0 or (GetItemFamily(id) or 0)
end

function ABP:IsBagSlotEmpty(bag, slot) return not GetContainerItemID(bag, slot) end

function ABP:IsBagSlotFull(bag, slot)
    local id = GetContainerItemID(bag, slot)
    if not id then
        return false
    end
    local _, _, _, _, _, _, _, stackCount = GetItemInfo(id)
    if stackCount == 1 then
        return true
    end
    local info = GetContainerItemInfo(bag, slot)
    return info and stackCount == info.stackCount or false
end

function ABP:IsBagSlotLocked(bag, slot)
    local info = GetContainerItemInfo(bag, slot)
    return info and info.isLocked or false
end

function ABP:PickupBagSlot(bag, slot) PickupContainerItem(bag, slot) end

function ABP:GetBagFamily(bag) return select(2, GetContainerNumFreeSlots(bag)) or 0 end
function ABP:GetBagNumSlots(bag) return GetContainerNumSlots(bag) or 0 end

-- 逆序整理状态：从 profile 读取/写入（设置面板与暴雪右键菜单共用同一持久化档）。
function ABP:IsReversePack()
    local p = self:GetProfile()
    return p and p.desc or false
end
function ABP:SetReversePack(desc)
    local p = self:GetProfile()
    if p then
        p.desc = desc and true or false
    end
end

function ABP:ShowMessage(text, r, g, b)
    local p = self:GetProfile()
    if not p or not p.showmessage then
        return
    end
    (p.messageframe == 1 and DEFAULT_CHAT_FRAME or UIErrorsFrame):AddMessage(text, r or 1, g or 1, b or 1, 1)
end
-- ============ 存档装配 + 初始化（ADDON_LOADED 自驱，statPlus 模式） ============

local initialized = false
function ABP:Init()
    if initialized then return end
    initialized = true

    local db = _G.ADEDB_BACKPACK
    if type(db) ~= "table" then db = {}; _G.ADEDB_BACKPACK = db end
    if type(db.profile) ~= "table" then db.profile = {} end

    -- a12：旧档 junkZone（垃圾钉放区）→ symmetricJunk（垃圾对称整理）迁移。
    -- 必须在 MergeDefaults 之前执行——否则新键默认值 true 会掩盖旧键的关闭意图。
    -- 旧值语义："none" = 关闭垃圾区；其它（auto/front/back）= 开启。
    local legacyProfile = db.profile
    if legacyProfile.junkZone ~= nil then
        if legacyProfile.symmetricJunk == nil then
            legacyProfile.symmetricJunk = legacyProfile.junkZone ~= "none"
        end
        legacyProfile.junkZone = nil
    end

    -- 旧存档缺失键补全（计划 §二决策 1；旧 junk/repair 键残留无害不清理）
    if UIKit.DB and UIKit.DB.MergeDefaults and ABP.defaults then
        UIKit.DB.MergeDefaults(db.profile, ABP.defaults.profile)
    end
    self.db = db

    -- 首启迁移：Orders 为空时填入默认分类顺序（Config.lua 提供）。
    -- a3 修复：DeepCopy——原直接赋共享引用，用户拖动会污染 ABP.DefaultCategoryOrder，
    -- 导致设置页「恢复默认」恢复到被污染的顺序。
    local profile = db.profile
    if #(profile.orders.CustomOrder or {}) == 0 then
        profile.orders.CustomOrder = (UIKit.DB.DeepCopy and UIKit.DB.DeepCopy(self.DefaultCategoryOrder or {})) or {}
    end
    if #(profile.orders.EquipLocOrder or {}) == 0 then
        profile.orders.EquipLocOrder = (UIKit.DB.DeepCopy and UIKit.DB.DeepCopy(self.DefaultEquipLocOrder or {})) or {}
    end

    -- a8 迁移：旧存档 CustomOrder 里残留的 '@category:junk' 一并清除——
    -- 垃圾不再参与用户顺序调整，整理时由 Rule 固定排末尾（配置/UI/规则三处一致）。
    if profile.orders and profile.orders.CustomOrder then
        for i = #profile.orders.CustomOrder, 1, -1 do
            if profile.orders.CustomOrder[i] == '@category:junk' then
                table.remove(profile.orders.CustomOrder, i)
            end
        end
    end

    function self.GetProfile()
        return self.db and self.db.profile or nil
    end

    self:InitModules()

    self.RegisterSlash()

    -- 设置页注册（Options.lua；achDateFormat 同款：Init 内加载期注册 tab + 原生 stub 页）
    self.InitOptionsStub()
end

-- 斜杠命令（/adebp）。空参数 = 打开设置（P2 前提示）；debug = 诊断扫描（Debug.lua）。
function ABP.RegisterSlash()
    SlashCmdList["ADEBAGPACK"] = function(msg)
        msg = strtrim(strlower(msg or ""))
        if msg == "" then
            if ABP.OpenSettings then
                ABP.OpenSettings()
            else
                print("|cff00AAFF[ADE]|r 背包整理: " .. ABP.L["SLASH_NO_SETTINGS"])
            end
        elseif msg == "debug" then
            ABP.DebugScan()
        elseif msg:sub(1, 6) == "debug " then
            local ids = {}
            for id in msg:sub(7):gmatch("%d+") do
                table.insert(ids, id)
            end
            ABP.DebugScan(ids)
        else
            ABP.Pack:Start(msg)
        end
    end
    _G.SLASH_ADEBAGPACK1 = "/adeBackpack"
    _G.SLASH_ADEBAGPACK2 = "/adebp"
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ABP:Init()
        frame:UnregisterEvent("ADDON_LOADED")
        if ABP.db then
            print(("|cff00AAFF[ADE]|r %s v%s 已加载 - /adebp"):format(tostring(ABP.title), tostring(ABP.version)))
        end
    end
end)