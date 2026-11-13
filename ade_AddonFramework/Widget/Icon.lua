-- 图标三态收敛：FilePath / FileID / Atlas 全支持；控件 Texture 与 FontString 转义两个出口。
-- 底本 139:182:z-ref_retail_Interface_AddOns/Mapzeroth/UI/Theme.lua、262:301:REF/HidingBar/HidingBar.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Icon = W

local COMMON_MASK_ROUND = "Interface\\Common\\commonmaskcircle"
local COMMON_MASK_ROUNDED = "Interface\\Common\\common-iconmask"

--- 判定来源：{ atlas = "..." } / 数字 = FileID / 字符串 = FilePath。
function AF.ResolveIcon(tex, icon, opts)
    if not tex or not icon then return nil end
    opts = opts or {}
    if type(icon) == "table" then
        if icon.atlas then
            tex:SetAtlas(icon.atlas, opts.useAtlasSize and true or false)
        elseif icon.fileID then
            tex:SetTexture(icon.fileID)
        elseif icon.file then
            tex:SetTexture(icon.file)
        elseif icon.filePath then
            tex:SetTexture(icon.filePath)
        end
    elseif type(icon) == "number" then
        tex:SetTexture(icon) -- FileID
    elseif type(icon) == "string" then
        if opts.atlas then tex:SetAtlas(icon) else tex:SetTexture(icon) end
    end
    if opts.desaturated then tex:SetDesaturated(true) end
    if opts.color then tex:SetVertexColor(unpack(opts.color)) end
    return tex
end

--- FontString 出口：|T…|t（FilePath / FileID）与 |A…|t（Atlas）。
function AF.IconEscape(icon, w, h)
    w, h = w or 16, h or 16
    local kind, value
    if type(icon) == "table" then
        if icon.atlas then kind, value = "atlas", icon.atlas
        elseif icon.fileID then kind, value = "file", icon.fileID
        elseif icon.file then kind, value = "file", icon.file end
    elseif type(icon) == "number" then
        kind, value = "file", icon
    elseif type(icon) == "string" then
        kind, value = "file", icon
    end
    if not value then return "" end
    if kind == "atlas" then
        return string.format("|A:%s:%d:%d|a", value, h, w)
    end
    return string.format("|T%s:%d:%d|t", tostring(value), h, w)
end

local function AttachMask(tex, shape)
    if not tex.CreateMaskTexture then return end
    if shape ~= "round" and shape ~= "rounded" then return end
    local ok = pcall(function()
        local mask = tex:GetParent():CreateMaskTexture()
        mask:SetTexture(shape == "round" and COMMON_MASK_ROUND or COMMON_MASK_ROUNDED)
        mask:SetAllPoints(tex)
        tex:AddMaskTexture(mask)
    end)
    return ok
end

function W.Create(parent, opts)
    opts = opts or {}
    local size = opts.size or 32
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)
    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    icon.texture = tex
    AF.ResolveIcon(tex, opts.icon, opts)
    AttachMask(tex, opts.shape)

    if opts.border then
        local skin = AF.Edges(icon, opts.borderColor or AF.C.EDGE, "OVERLAY")
        icon.border = skin
    end
    function icon:SetIcon(newIcon, newOpts)
        AF.ResolveIcon(tex, newIcon, newOpts or opts)
    end
    function icon:SetDesaturated(on) tex:SetDesaturated(on and true or false) end
    function icon:SetBorderColor(t) if icon.border then icon.border:SetColor(t) end end
    function icon:AddBadge(badge)
        if not badge or not badge.icon then return end
        local s = math.max(8, math.floor(size * (badge.scale or 0.5)))
        local b = icon:CreateTexture(nil, "OVERLAY", nil, 3)
        b:SetSize(s, s)
        local point = badge.point or "TOP"
        b:SetPoint(point, badge.offset or 0, point == "TOP" and -(badge.offset or 0) or (badge.offset or 0))
        AF.ResolveIcon(b, badge.icon, badge)
        icon.badge = b
        return b
    end
    function icon:RemoveBadge()
        if icon.badge then icon.badge:Hide(); icon.badge = nil end
    end
    return icon
end

--- 原生 Atlas 图标按钮：替代字符图标，规避字体缺字形乱码。
function W.CreateButton(parent, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    local size = opts.size or 16
    b:SetSize(size, size)
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    AF.ResolveIcon(tex, opts.icon or { atlas = opts.atlas }, { atlas = true })
    if opts.tint then AF.Tint(tex, opts.tint) end
    b.texture = tex
    b:SetScript("OnClick", function(_, button) if opts.onClick then opts.onClick(button) end end)
    if opts.tooltip then
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    function b:SetAtlas(name) AF.ResolveIcon(tex, { atlas = name }, { atlas = true }) end
    return b
end
