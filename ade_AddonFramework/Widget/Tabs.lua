-- 两级页签：一级为分组，二级为页；只有选中页签的边框与字着色。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Tabs = W

function W.Create(parent, opts)
    opts = opts or {}
    local tabs = CreateFrame("Frame", nil, parent)
    tabs:SetSize(opts.width or AF.LAYOUT.contentW, 26)
    tabs.groups, tabs.entries, tabs.active = {}, {}, nil

    local function MakeButton(group, id, label, level)
        local b = AF.Widget.Button.Create(tabs, {
            text = label, width = opts.tabWidth or 90, height = 22,
            onClick = function()
                tabs:Select(group .. ":" .. id, true)
                if opts.onSelect then opts.onSelect(group, id) end
            end,
        })
        AF.Widget.Button.FitButton(b, opts.tabWidth or 90, 22)
        b:SetFrameLevel(level or 1)
        return b
    end

    function tabs:AddPage(group, id, label, level)
        local key = group .. ":" .. id
        local b = MakeButton(group, id, label, level)
        self.entries[key] = { button = b, group = group, id = id, level = level or 2 }
        return b
    end

    function tabs:AddGroup(group, label)
        local b = MakeButton(group, "group", label, 1)
        self.groups[group] = b
        return b
    end

    function tabs:Layout()
        local x = 0
        for _, group in ipairs(self.order or {}) do
            local g = self.groups[group]
            if g then g:ClearAllPoints(); g:SetPoint("TOPLEFT", x, 0); x = x + g:GetWidth() + 4 end
        end
        local y = -26
        for _, e in pairs(self.entries) do
            if e.level == 2 and self.active and self.active:match("^([^:]+)") == e.group then
                e.button:ClearAllPoints()
                e.button:SetPoint("TOPLEFT", x, y)
                e.button:Show()
                x = x + e.button:GetWidth() + 4
            else
                e.button:Hide()
            end
        end
    end

    function tabs:Select(key, fire)
        if not self.entries[key] then return end
        self.active = key
        for k, e in pairs(self.entries) do
            AF.Widget.Button.SetVariant(e.button, k == key and "primary" or "normal")
        end
        self:Layout()
        if fire and opts.onSelect then
            local group, id = key:match("^([^:]+):(.+)$")
            opts.onSelect(group, id)
        end
    end
    return tabs
end
