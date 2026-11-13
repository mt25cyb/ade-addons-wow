-- 淡入淡出：共用一支 driver；战斗中只改 alpha（不受保护）。
-- 底本 409:448:z-ref_retail_Interface_AddOns/Combatter/Combatter.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Fade = {}

local fading = setmetatable({}, { __mode = "k" })
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, elapsed)
    local any = false
    for frame, state in pairs(fading) do
        any = true
        state.t = state.t + elapsed
        local p = AF.Clamp(state.t / state.duration, 0, 1)
        frame:SetAlpha(state.from + (state.to - state.from) * p)
        if p >= 1 then
            fading[frame] = nil
            if state.onDone then state.onDone() end
        end
    end
    if not any then driver:Hide() end
end)

function AF.Fade.To(frame, to, duration, onDone)
    fading[frame] = { from = frame:GetAlpha() or 1, to = to or 1, duration = duration or 0.2, t = 0, onDone = onDone }
    driver:Show()
end

function AF.Fade.In(frame, duration) AF.Fade.To(frame, 1, duration) end
function AF.Fade.Out(frame, duration) AF.Fade.To(frame, 0, duration) end
function AF.Fade.Stop(frame) fading[frame] = nil end
