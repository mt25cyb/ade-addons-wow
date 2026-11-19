-- adeBagPack / External.lua — 外部插件对接（计划 §二决策 4/7 + §1.6 API 表，P3.5）
-- junkSource="dejunk"：排序侧 junk 判定接管（DejunkApi:IsJunk(bag,slot)，1s 缓存、未就绪返回
--   false）+ AddListener 监听过滤器变更重算 Rule 排序键缓存。出售不接管（Dejunk Seller 无公开入口）。
-- infoSource="itemera"：/adebp debug 扫描输出的资料片/专业文本（隐式 API 只读；子表存在性校验
--   + 返回值域校验，缺失/版本漂移回退 nil——纯显示，排序键仍是内置 ID）。
-- baganatorSort/baganatorButton：挂/卸随开关（排序回调运行时查开关；按钮显隐即时切换），
--   实现委托 Extra/Baganator.lua:ApplySettings。
local ABP = _G.adeBagPack
if not ABP then return end

local External = {}
ABP.External = External

-- ============ Dejunk（唯一全局 DejunkApi；DejunkApi.lua:56,81-98,57-66） ============

local dejunkListener   -- AddListener 返回的移除函数

local function IsDejunkActive()
    local p = ABP:GetProfile()
    return p and p.external and p.external.junkSource == "dejunk"
        and type(_G.DejunkApi) == "table" and type(_G.DejunkApi.IsJunk) == "function"
end

function External:IsDejunkActive()
    return IsDejunkActive() and true or false
end

function External:IsJunkSlot(bag, slot)
    if not IsDejunkActive() then return false end
    -- pcall 双保险（规范：运行时守卫保留）；Dejunk 状态未就绪自身返回 false
    local ok, result = pcall(_G.DejunkApi.IsJunk, _G.DejunkApi, bag, slot)
    return ok and result or false
end

local function ClearRuleCache()
    if ABP.Rule and ABP.Rule.ClearSortKeyCache then
        ABP.Rule:ClearSortKeyCache()
    end
end

local function AttachDejunkListener()
    if dejunkListener then return end
    local api = _G.DejunkApi
    if not (type(api) == "table" and type(api.AddListener) == "function") then return end
    -- 事件枚举 DejunkApi.Events = {BagsUpdated, StateUpdated}：任意过滤器/背包状态变更均需重算
    local function OnChanged()
        ClearRuleCache()
    end
    dejunkListener = api:AddListener(OnChanged)
end

local function DetachDejunkListener()
    if type(dejunkListener) == "function" then
        pcall(dejunkListener)
    end
    dejunkListener = nil
end

-- ============ ItemEra（隐式 API 只读；ItemData.lua:83 / Utils.lua:21-34,236,302） ============

-- 资料片名称（显示用）：GetItemExpansionID → {expansionID=数字} → Utils.ExpansionNames[id]
function External:GetExpansionText(itemID)
    local era = _G.ItemEra
    if not (era and era.ItemData and era.ItemData.GetItemExpansionID
            and era.Utils and type(era.Utils.ExpansionNames) == "table") then
        return nil
    end
    if type(itemID) ~= "number" then return nil end
    local ok, info = pcall(era.ItemData.GetItemExpansionID, era.ItemData, itemID)
    local eid = ok and type(info) == "table" and info.expansionID or nil
    if type(eid) ~= "number" then return nil end
    local name = era.Utils.ExpansionNames[eid]
    return type(name) == "string" and name or nil
end

-- 专业文本（富文本，显示用）：Utils:GetProfessionTextByItemID(itemID) 或 nil
function External:GetProfessionText(itemID)
    local era = _G.ItemEra
    if not (era and era.Utils and type(era.Utils.GetProfessionTextByItemID) == "function") then
        return nil
    end
    if type(itemID) ~= "number" then return nil end
    local ok, text = pcall(era.Utils.GetProfessionTextByItemID, era.Utils, itemID)
    return ok and type(text) == "string" and text or nil
end

-- ============ 开关变更应用（Options.lua external.* / 消费端即时挂卸） ============

function External:Apply()
    local p = ABP:GetProfile()
    if p and p.external and p.external.junkSource == "dejunk" then
        AttachDejunkListener()
        -- 接管生效瞬间旧缓存（内置判定产物）全部失效
        ClearRuleCache()
    else
        DetachDejunkListener()
    end
    if ABP.Baganator and ABP.Baganator.ApplySettings then
        ABP.Baganator:ApplySettings()
    end
end

function External:Init()
    self:Apply()
end