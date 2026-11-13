-- 磁吸：阈值对齐到 UIParent 中心与边缘。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Snap = W

local registered = setmetatable({}, { __mode = "k" })

function W.Register(frame, opts)
    opts = opts or {}
    local threshold = opts.threshold or 8
    registered[frame] = threshold
    frame:HookScript("OnDragStop", function(self)
        local t = registered[self]
        if not t then return end
        local cx = UIParent:GetWidth() / 2
        local left = self:GetLeft() or 0
        local width = self:GetWidth() or 0
        local centerX = left + width / 2
        if math.abs(centerX - cx) <= t then
            self:ClearAllPoints()
            self:SetPoint("TOP", UIParent, "TOP", 0, -(self:GetTop() and (UIParent:GetTop() - self:GetTop()) or 0))
        end
        if opts.onSnapped then opts.onSnapped(self) end
    end)
end

function W.Unregister(frame) registered[frame] = nil end
function W.Apply(frame)
    local t = registered[frame]
    if not t then return end
    local cx = UIParent:GetWidth() / 2
    local centerX = (frame:GetLeft() or 0) + (frame:GetWidth() or 0) / 2
    if math.abs(centerX - cx) <= t then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, (frame:GetBottom() or 0) - UIParent:GetHeight() / 2)
    end
end
