------------------------------------------------------------
-- 简版回调注册表：key 覆盖注册、注销、逐订阅者 xpcall 隔离。
-- 语义底本：ade_AddonFramework/Function/Callbacks.lua（仅参考，不依赖、不调用 AF）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local registry = {}
local seq = 0

local function Report(err)
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        handler("ade_UIKit callback: " .. tostring(err))
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555ade_UIKit callback:|r " .. tostring(err))
    end
end

local Callbacks = {}

function Callbacks.Register(event, key, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return nil end
    local list = registry[event]
    if not list then list = {}; registry[event] = list end
    if key == nil then seq = seq + 1; key = "auto:" .. seq end
    list[key] = fn
    return key
end

function Callbacks.Unregister(event, key)
    local list = registry[event]
    if not list then return end
    list[key] = nil
    if next(list) == nil then registry[event] = nil end
end

function Callbacks.Fire(event, ...)
    local list = registry[event]
    if not list then return end
    for _, fn in pairs(list) do xpcall(fn, Report, ...) end
end

function Callbacks.Has(event)
    return registry[event] ~= nil
end

lib.Callbacks = Callbacks
lib.RegisterCallback = Callbacks.Register
lib.UnregisterCallback = Callbacks.Unregister
lib.FireCallback = Callbacks.Fire
lib.HasCallback = Callbacks.Has
