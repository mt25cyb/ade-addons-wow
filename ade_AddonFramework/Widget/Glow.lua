-- 发光：共用一支 OnUpdate driver，贴图用暴雪 IconAlert / IconAlertAnts 的 UV 坐标（自写复刻，不拷上游源码）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Glow = W

local active = setmetatable({}, { __mode = "k" })
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, elapsed)
    local any = false
    for handle in pairs(active) do
        any = true
        handle.t = (handle.t or 0) + elapsed
        local phase = (handle.t % 1)
        for i, tex in ipairs(handle.textures) do
            tex:SetAlpha(0.35 + 0.65 * math.abs(math.sin(phase * math.pi + i)))
        end
    end
    if not any then driver:Hide() end
end)

local function Handle(frame)
    local h = { frame = frame, textures = {}, t = 0 }
    active[h] = true
    driver:Show()
    function h:Stop()
        for _, t in ipairs(self.textures) do t:Hide() end
        active[self] = nil
    end
    frame._afGlow = h
    if frame._afPrevGlow and frame._afPrevGlow ~= h then frame._afPrevGlow:Stop() end
    frame._afPrevGlow = h
    return h
end

function W.Pixel(frame, opts)
    if type(frame) ~= "table" or not frame.CreateTexture then return nil end
    opts = opts or {}
    local h = Handle(frame)
    local size = math.max(frame:GetWidth() or 32, 16) + (opts.size or 8)
    for i = 1, 4 do
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        t:SetBlendMode("ADD")
        t:SetSize(size, size)
        local a = (i - 1) * math.pi / 2
        t:SetPoint("CENTER", math.cos(a) * 2, math.sin(a) * 2)
        h.textures[i] = t
    end
    return h
end

function W.Button(frame, opts) return W.Pixel(frame, opts) end
function W.Proc(frame, opts) return W.Pixel(frame, opts) end
function W.AutoCast(frame, opts)
    local h = W.Pixel(frame, opts)
    local ants = frame:CreateTexture(nil, "OVERLAY")
    ants:SetTexture("Interface\\SpellActivationOverlay\\IconAlertAnts")
    ants:SetBlendMode("ADD")
    ants:SetSize(math.max(frame:GetWidth() or 32, 16) + 8, math.max(frame:GetHeight() or 32, 16) + 8)
    ants:SetPoint("CENTER")
    h.textures[#h.textures + 1] = ants
    return h
end
