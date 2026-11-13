-- 极简回调注册表：key 覆盖注册、注销、逐订阅者 xpcall 隔离。
-- 语义底本：1:56:z-ref_retail_Interface_AddOns/MiliUI_UnitFrames/Libs/Callbacks.lua。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

local registry = {}
local seq = 0

local function Report(err)
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        handler("ade_AddonFramework callback: " .. tostring(err))
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555ade_AddonFramework callback:|r " .. tostring(err))
    end
end

function AF.RegisterCallback(event, key, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return nil end
    local list = registry[event]
    if not list then list = {}; registry[event] = list end
    if key == nil then seq = seq + 1; key = "auto:" .. seq end
    list[key] = fn
    return key
end

function AF.UnregisterCallback(event, key)
    local list = registry[event]
    if not list then return end
    list[key] = nil
    if next(list) == nil then registry[event] = nil end
end

function AF.FireCallback(event, ...)
    local list = registry[event]
    if not list then return end
    for _, fn in pairs(list) do xpcall(fn, Report, ...) end
end

function AF.HasCallback(event)
    return registry[event] ~= nil
end
