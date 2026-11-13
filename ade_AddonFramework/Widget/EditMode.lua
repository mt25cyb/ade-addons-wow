-- 编辑模式选中层：一律自绘，绝不以 UIParent 为父级实例化 EditModeSystemSelectionTemplate。
-- 该模板 XML 带 parentKey="Selection"，会写 UIParent.Selection，导致暴雪 GetCombinedSelectionOffset
-- 调用 UIParent:GetSelectionOffset（nil）报错，连带保存/撤销/重设位置失效（实机事故，规划 §六）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.EditMode = W

local attached = setmetatable({}, { __mode = "k" })
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
-- EDIT_MODE_LAYOUTS_UPDATED 在 _2-4_Events.md 有记录；注册本身不依赖可选 C_* 判定接口
pcall(events.RegisterEvent, events, "EDIT_MODE_LAYOUTS_UPDATED")

local function IsActive()
    return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive() or false
end

local function Update()
    for frame, data in pairs(attached) do data.overlay:SetShown(IsActive()) end
end
events:SetScript("OnEvent", Update)

function W.Attach(frame, opts)
    opts = opts or {}
    if attached[frame] then return attached[frame].overlay end

    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetAllPoints(frame)
    overlay:EnableMouse(true)
    local fill = AF.Fill(overlay, { 0, 0, 0, 0.12 }, "BACKGROUND", 0)
    fill:SetVertexColor(AF.Color("accent", 0.12))
    AF.Tint(fill, "accent", 0.12)
    local skin = AF.Edges(overlay, AF.ColorTable("accent"), "OVERLAY")
    overlay.skin = skin
    if opts.label then
        local fs = overlay:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject(AF.fontNormal)
        fs:SetPoint("CENTER")
        fs:SetText(opts.label)
    end
    overlay:Hide()

    attached[frame] = { overlay = overlay, opts = opts }
    Update()
    return overlay
end

function W.Detach(frame)
    local data = attached[frame]
    if not data then return end
    data.overlay:Hide()
    attached[frame] = nil
end

function W.SavePosition(frame, key, store)
    local x, y = frame:GetLeft(), frame:GetTop()
    if store then store[key or "pos"] = { x = x, y = y } end
    return x, y
end

function W.RestorePosition(frame, key, store)
    local p = store and store[key or "pos"]
    if not p then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p.x, p.y)
end
