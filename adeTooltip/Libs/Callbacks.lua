------------------------------------------------------------
-- 極簡 callback 註冊表（設定／狀態通知；對照 MiliUI Libs/Callbacks.lua:1-30）
-- key 讓同一事件的重複註冊可被覆蓋（分頁懶初始化重進不會疊 handler）。
-- ⚠ 逐一隔離：任一訂閱者拋錯不能連坐後面的（pairs 順序不保證）。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local callbacks = {}

function ns.RegisterCallback(event, key, fn)
    if type(event) ~= "string" or type(key) ~= "string" or type(fn) ~= "function" then return end
    if not callbacks[event] then callbacks[event] = {} end
    callbacks[event][key] = fn
end

function ns.UnregisterCallback(event, key)
    if callbacks[event] then callbacks[event][key] = nil end
end

function ns.Fire(event, ...)
    if not callbacks[event] then return end
    local report = ns.ReportError or function(err) end
    for _, fn in pairs(callbacks[event]) do
        xpcall(fn, report, ...)
    end
end
