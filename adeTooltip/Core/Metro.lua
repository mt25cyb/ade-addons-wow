------------------------------------------------------------
-- 共用輪詢：一張 ticker 服務所有項目，沒項目時根本不存在
--
-- 基礎心跳 0.05s，比任何一個 interval 短。SetEnabled(false) 時 ticker 直接停掉
-- （登入到登出即使畫面沒任何提示也不會每幀進 Lua）。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

ns.Metro = {}
local Metro = ns.Metro

local BASE = 0.05

function Metro.New(baseInterval, onError)
    local items = {}      -- name -> { interval, fn, last }
    local ticker
    local enabled = false
    local report = onError or function() end

    local function Tick()
        local now = GetTime()
        for name, it in pairs(items) do
            if it.interval <= 0 or (now - it.last) >= it.interval then
                it.last = now
                local ok, err = pcall(it.fn)
                if not ok then report(err) end
            end
        end
    end

    local function Rebuild()
        if enabled and next(items) and not ticker then
            ticker = C_Timer.NewTicker(baseInterval or BASE, Tick)
        elseif (not enabled or not next(items)) and ticker then
            ticker:Cancel()
            ticker = nil
        end
    end

    local ctrl = {}
    function ctrl.Add(name, interval, fn)
        items[name] = { interval = interval or 0, fn = fn, last = 0 }
        Rebuild()
    end
    function ctrl.Remove(name)
        items[name] = nil
        Rebuild()
    end
    function ctrl.SetEnabled(on)
        enabled = not not on
        Rebuild()
    end
    return ctrl
end
