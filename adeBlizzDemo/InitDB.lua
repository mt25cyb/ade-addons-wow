------------------------------------------------------------
-- 默认设置与存档初始化。全局表供 Demo.lua 引用：
--   AdeBlizzDemoDefaults —— 默认值（恢复默认统计的对比基准）
--   AdeBlizzDemoDB       —— 玩家存档（缺省键按 defaults 填充）
------------------------------------------------------------
AdeBlizzDemoDefaults = {
    enable = true, scale = 1, mode = "A", note = "", key = "",
    alphaEnabled = true, alpha = 0.8, autoClean = false, dual = { "", "" }, subToggle = false, secondToggle = false,
    view = { [1] = true, [2] = false, [3] = true, [4] = false, [5] = false, [6] = false },
    reload = false,
    tabs = {
        { name = "常规", show = true },
        { name = "事件", show = true },
        { name = "其它", show = false },
    },
}

AdeBlizzDemoDB = AdeBlizzDemoDB or {}
for key, value in pairs(AdeBlizzDemoDefaults) do
    if AdeBlizzDemoDB[key] == nil then AdeBlizzDemoDB[key] = value end
end

-- 键位槽的值必须是字符串：历史版本可能把非字符串写进存档（显示为 table: 0x...），
-- 载入时清洗为未绑定。库写入的键位 combo 一定是字符串，正常存档不受影响。
local function CleanKey(value)
    if type(value) ~= "string" then return "" end
    return value
end
AdeBlizzDemoDB.key = CleanKey(AdeBlizzDemoDB.key)
AdeBlizzDemoDB.dual = { CleanKey(AdeBlizzDemoDB.dual and AdeBlizzDemoDB.dual[1]), CleanKey(AdeBlizzDemoDB.dual and AdeBlizzDemoDB.dual[2]) }
