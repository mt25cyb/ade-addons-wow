-- 位置微调：四向 + 水平/垂直居中 + 重设，全部用原生 Atlas。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.PositionNudge = W

local function Arrow(parent, size, rotation, onClick, tooltip)
    local b = AF.Widget.Icon.CreateButton(parent, {
        size = size, atlas = "common-dropdown-icon-next", tooltip = tooltip, onClick = onClick,
    })
    b.texture:SetRotation(rotation)
    return b
end

function W.Create(parent, opts)
    opts = opts or {}
    local f = CreateFrame("Frame", nil, parent)
    local s = opts.size or 18
    f:SetSize(s * 5 + 16, s * 2 + 8)

    local L = AF.L
    local function Nudge(dx, dy) if opts.onNudge then opts.onNudge(dx, dy) end end
    Arrow(f, s, math.rad(90), function() Nudge(0, 1) end, L["AF_NUDGE_UP"]):SetPoint("TOPLEFT", s + 4, 0)
    Arrow(f, s, math.rad(-90), function() Nudge(0, -1) end, L["AF_NUDGE_DOWN"]):SetPoint("TOPLEFT", s + 4, -(s + 4))
    Arrow(f, s, math.rad(180), function() Nudge(-1, 0) end, L["AF_NUDGE_LEFT"]):SetPoint("TOPLEFT", 0, -(s + 4))
    Arrow(f, s, 0, function() Nudge(1, 0) end, L["AF_NUDGE_RIGHT"]):SetPoint("TOPLEFT", (s + 4) * 2, -(s + 4))

    local centerH = AF.Widget.Icon.CreateButton(f, {
        size = s, atlas = "GM-icon-settings", tooltip = L["AF_CENTER_H"],
        onClick = function() if opts.onCenter then opts.onCenter("H") end end,
    })
    centerH:SetPoint("TOPLEFT", (s + 4) * 3, -(s + 4))
    local centerV = AF.Widget.Icon.CreateButton(f, {
        size = s, atlas = "GM-icon-settings", tooltip = L["AF_CENTER_V"],
        onClick = function() if opts.onCenter then opts.onCenter("V") end end,
    })
    centerV:SetPoint("TOPLEFT", (s + 4) * 4, -(s + 4))
    local reset = AF.Widget.Icon.CreateButton(f, {
        size = s, atlas = "common-icon-undo", tooltip = AF.L["AF_RESET"],
        onClick = function() if opts.onReset then opts.onReset() end end,
    })
    reset:SetPoint("TOPLEFT", (s + 4) * 3, 0)
    return f
end
