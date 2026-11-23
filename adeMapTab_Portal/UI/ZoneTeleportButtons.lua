local _, addon = ...

-- ADE v6.5：基座样式按钮内联（逐字照抄 ade_BaseFramework/widget/StyledButton.lua，
-- 基座已退场；来源 EQoLPlus/API.lua CreateStyledButton 241-269，注释见各函数）。
-- 暗色边缘虚影：图标内缩 edgeShadow px，背后垫同形状黑色底板，露出一圈暗边。
local function SetStyledButtonEdgeShadow(button, edgeShadow)
    if not button or not button.Icon then return end
    edgeShadow = edgeShadow or 0
    button.edgeShadow = edgeShadow
    local maskTex = (button.shape == "circle")
        and "Interface\\Common\\commonmaskcircle"
        or "Interface\\Common\\common-iconmask"
    if edgeShadow <= 0 then
        if button.EdgeShadow then button.EdgeShadow:Hide() end
        button.Icon:ClearAllPoints()
        button.Icon:SetAllPoints()
        return
    end
    local shadow = button.EdgeShadow
    if not shadow then
        shadow = button:CreateTexture(nil, "BACKGROUND")
        shadow:SetColorTexture(0, 0, 0, 1)
        button.EdgeShadow = shadow
    end
    shadow:SetAllPoints()
    shadow:SetColorTexture(0, 0, 0, 1)
    local smask = button.EdgeShadowMask
    if not smask then
        smask = button:CreateMaskTexture()
        shadow:AddMaskTexture(smask)
        button.EdgeShadowMask = smask
    end
    smask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    smask:SetAllPoints(shadow)
    shadow:Show()
    local e = edgeShadow
    button.Icon:ClearAllPoints()
    button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", e, -e)
    button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -e, e)
end

local function CreateStyledButton(parent, size, template, name, shape, edgeShadow)
    if not parent then return nil end
    local button = CreateFrame("Button", name, parent, template)
    button:SetSize(size or 28, size or 28)
    button.shape = (shape == "circle") and "circle" or "square"
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local maskTex = (button.shape == "circle")
        and "Interface\\Common\\commonmaskcircle"
        or "Interface\\Common\\common-iconmask"
    local mask = button:CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(icon)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    local hmask = button:CreateMaskTexture(nil, "ARTWORK")
    hmask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    hmask:SetAllPoints(highlight)
    highlight:AddMaskTexture(hmask)
    button.Icon = icon
    button.Highlight = highlight
    button.Mask = mask
    button.HighlightMask = hmask
    local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    button.cooldownFrame = cd
    SetStyledButtonEdgeShadow(button, edgeShadow or 1)
    return button
end

-- 地图左上角「当前查看区域可用传送」按钮组。
-- 条目直接取自传送标签页本身（addon.Catalog.BuildSections），因此玩具、道具、法术、炉石都在内，
-- 与标签页看到的是同一份数据、同一套拥有判定。
-- 施法属性、冷却、提示、右键定位全部复用 UI/WorldMapPanel.lua 的导出（addon.MapPanel.*），
-- 本文件只负责「筛选当前区域 + 布局」。
-- 布局参考 WeakAura「ZachLT3 + Eathox Map Teleports 11.0.7.1」（_docs/_WA-Profile.txt）：
-- 挂在 WorldMapFrame.ScrollContainer（Blizzard_WorldMap.xml:12）左上角，
-- 切图（WorldMapMixin:OnMapChanged，Blizzard_WorldMap.lua:332）时重建。

local BUTTON_SIZE = 28
local DEFAULT_SIZE = BUTTON_SIZE
local GAP = 2
local MIN_ROWS = 4

-- 按钮大小固定 28px（用户 2026-10-29 去掉「按钮尺寸」选项，避免尺寸与布局互相打架）。
--
-- 「按钮位置」与「排列方向」合并为单一预设（用户 2026-10-29）：每项同时给出锚角、排列方向
-- 与基准偏移。这里的 x/y 是新的起始位置；设置面板里的「水平/垂直偏移」是在它之上叠加的量，
-- 所以最后返回 base + offset。
local LAYOUTS = {
    topLeftRow = { anchor = "TOPLEFT", orientation = "horizontal", x = 4, y = -4 },
    topLeftColumn = { anchor = "TOPLEFT", orientation = "vertical", x = 4, y = -4 },
    topRightRow = { anchor = "TOPRIGHT", orientation = "horizontal", x = -64, y = -4 },
    bottomRightRow = { anchor = "BOTTOMRIGHT", orientation = "horizontal", x = -36, y = 2 },
    bottomRightColumn = { anchor = "BOTTOMRIGHT", orientation = "vertical", x = -4, y = 36 },
}
-- 默认值沿用旧的「左上 + 纵向」，老配置升级后观感不变。
local DEFAULT_LAYOUT = "topLeftColumn"

-- 每个布局预设各有一份独立的偏移（用户 2026-10-29）：切换布局项时，
-- 「水平/垂直偏移」显示/修改的都是该布局自己那份值，互不干扰。
local function OffsetSlot(layoutKey)
    local db = addon.db
    if type(db) ~= "table" then return nil end
    if type(db.zoneButtonsOffsets) ~= "table" then db.zoneButtonsOffsets = {} end
    local slot = db.zoneButtonsOffsets[layoutKey]
    if type(slot) ~= "table" then
        slot = { x = 0, y = 0 }
        db.zoneButtonsOffsets[layoutKey] = slot
    end
    return slot
end

local function CurrentLayoutKey()
    local db = addon.db or {}
    local key = db["zoneButtonsLayout"]
    return LAYOUTS[key] and key or DEFAULT_LAYOUT
end

local function LayoutConfig()
    local layoutKey = CurrentLayoutKey()
    local layout = LAYOUTS[layoutKey]
    local offset = OffsetSlot(layoutKey) or { x = 0, y = 0 }
    return BUTTON_SIZE, layout.anchor, layout.x + (offset.x or 0), layout.y + (offset.y or 0), layout.orientation
end

local f = CreateFrame("Frame")
local rootFrame
local pool = {}
local poolSize = 0
local used = 0
local relatedCache = {}
local pendingUpdate = false
local sizeChangePending = false

local function InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

-- 战斗中不触碰受保护的显示状态，只改透明度，等脱战后重排。
local function SetVisible(button, visible)
    if InCombat() then
        button:SetAlpha(visible and 1 or 0)
        return
    end
    button:SetAlpha(1)
    button:SetShown(visible and true or false)
end

-- 当前查看地图的相关地图集合：自己 + 全部子地图 + 父链。
-- 这样查看区域能命中落在副本内的传送，查看副本也能命中落在区域上的传送。
local function RelatedMaps(mapID)
    local cached = relatedCache[mapID]
    if cached then return cached end
    local set = { [mapID] = true }
    if C_Map.GetMapChildrenInfo then
        local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
        for _, info in ipairs(children or {}) do
            if info.mapID then set[info.mapID] = true end
        end
    end
    if C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(mapID)
        local guard = 0
        while info and info.parentMapID and info.parentMapID > 0 and guard < 8 do
            set[info.parentMapID] = true
            info = C_Map.GetMapInfo(info.parentMapID)
            guard = guard + 1
        end
    end
    relatedCache[mapID] = set
    return set
end

local function ShowUnknownEnabled()
    return addon.db and addon.db.zoneButtonsShowUnknown == true or false
end

-- 「显示角色传送按钮」（用户 2026-10-29）：启用后角色分组（首页）的传送在所有地图都出现，
-- 不再要求「能传送到当前查看的区域」。
local function ShowCharacterEnabled()
    return addon.db and addon.db.zoneButtonsShowCharacter == true or false
end

--- 角色分组传送的归类：炉石 / 职业 / 种族 / 住宅区。
--- 归不到这四类的（普通道具、玩具传送）返回 nil，始终放行。
local function CharacterKind(entry)
    if entry.isRandomHearthstone then return "hearthstone" end
    if entry.isClassTP then return "class" end
    if entry.isRaceTP then return "race" end
    if entry.housingFaction then return "housing" end
    return nil
end

--- 补充表里额外指定的地图（如光帷召回道标 = 瓦尔 2599 / 奈格塔尔 2600）：数据里
--- 没有 destination，但区域按钮在这两张地图上也该出现（用户 2026-10-29）。
local function OverrideMapsHit(item, related)
    local override = addon.DestinationOverrides and addon.DestinationOverrides[item.spellID]
    if not (override and override.maps) then return false end
    for _, map in ipairs(override.maps) do
        if related[map] then return true end
    end
    return false
end

local function CharacterKindAllowed(kind)
    local filters = addon.db and addon.db.zoneButtonsCharacterFilters
    -- 没配过筛选表、或该条目不属于四类之一，都按放行处理。
    if type(filters) ~= "table" or kind == nil then return true end
    return filters[kind] == true
end

-- Tab 表达不了多目的地的补充项（德鲁伊梦境行走的其余落点）。
local function SupplementEntry(spellID)
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    -- 与 Services/Catalog.lua 的拥有判定保持一致（C_SpellBook.IsSpellInSpellBook）
    local known = C_SpellBook and C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spellID) or false
    return {
        spellID = spellID,
        iconID = info and info.iconID or 136121,
        isKnown = known,
        isToy = false,
        isItem = false,
        entryKey = "spell:" .. spellID,
    }
end

--- 收集按钮条目。
--- allowRegular=false 时不收集「区域传送」（非角色）条目，只留角色分组的传送
--- ——大陆地图且未启用「在大陆地图显示传送按钮」就是这个情况（用户 2026-10-29）。
local function CollectEntries(mapID, allowRegular)
    local related = RelatedMaps(mapID)
    local entries, bySpell = {}, {}
    -- includeUnavailable = true：拿到全部条目（含其他职业/未拥有），是否显示由本文件的 zoneButtonsShowUnknown 决定
    local sections = addon.Catalog and addon.Catalog.BuildSections and addon.Catalog.BuildSections(true) or {}
    local showCharacter = ShowCharacterEnabled()
    for _, section in ipairs(sections) do
        -- 角色分组（首页）：开了「显示角色传送按钮」就整组加入，不受当前地图限制。
        local isHome = (section.key == "home")
        for _, item in ipairs(section.items or {}) do
                    if showCharacter and isHome then
            -- 家宅联盟/部落共用 spellID(1233637)，按裸 spellID 去重会把第二个阵营剔掉
            -- （用户 2026-11-17：区域按钮只显示联盟家宅）。housing 条目改按阵营去重，
            -- 键风格对齐 RecentHistory 的 "housing:" .. faction。
            local dedupeKey = item.housingFaction and ("housing:" .. item.housingFaction) or item.spellID
            if not bySpell[dedupeKey] and (item.isKnown or ShowUnknownEnabled())
                and CharacterKindAllowed(CharacterKind(item)) then
                bySpell[dedupeKey] = true
                entries[#entries + 1] = item
            end
            -- 随机炉石的目的地不固定，不参与区域匹配
            elseif allowRegular and not item.isRandomHearthstone and not bySpell[item.spellID]
                and (item.isKnown or ShowUnknownEnabled())
                and ((item.locID ~= nil and related[item.locID]) or OverrideMapsHit(item, related)) then
                bySpell[item.spellID] = true
                entries[#entries + 1] = item
            end
        end
    end
    -- 补充条目同样属于「区域传送」，allowRegular=false 时一并排除。
    for _, extra in ipairs(allowRegular and (addon.ZoneTeleportExtraMaps or {}) or {}) do
        if not bySpell[extra.spellID] then
            for _, map in ipairs(extra.maps or {}) do
                if related[map] then
                    local entry = SupplementEntry(extra.spellID)
                    if entry.isKnown or ShowUnknownEnabled() then
                        bySpell[extra.spellID] = true
                        entries[#entries + 1] = entry
                    end
                    break
                end
            end
        end
    end
    return entries
end

-- 区域按钮形状：圆形（默认，commonmaskcircle 真圆）或方形（圆角矩形，common-iconmask）。
-- 形状由设置项 portalButtonSquare 控制（与 EQoLPlusMapExt 对齐：circle 用 commonmaskcircle、
-- square 用 common-iconmask；参考 EQoLPlus/API.lua CreateStyledButton 241-269）。
-- 图标与高亮用同一形状遮罩；边框由 ButtonSkin 按 button.shape 同步（圆形时禁用 Masque、改自带圆环描边）。
--- r003：形状+虚影程度组成样式键，按钮池复用时只在变化后才重跑 ApplyZoneButtonStyle。
local function CurrentStyleKey()
    local db = addon.db
    return ((db and db.portalButtonSquare) and "square" or "circle")
        .. "|" .. ((db and db.portalButtonEdgeShadow) or 0)
end

local function ApplyZoneButtonStyle(button)
    local square = addon.db and addon.db.portalButtonSquare
    button.shape = square and "square" or "circle"
    local maskTex = square and "Interface/Common/common-iconmask" or "Interface/Common/commonmaskcircle"
    if button.Mask then button.Mask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") end
    if button.HighlightMask then button.HighlightMask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") end
    -- 暗色边缘虚影：程度由 portalButtonEdgeShadow 控制（按 button.shape 重设底板遮罩，圆形/方形切换无需重建）。
    SetStyledButtonEdgeShadow(button, (addon.db and addon.db.portalButtonEdgeShadow) or 0)
    -- CD swipe 暗色遮罩与图标同形状裁切（圆形 commonmaskcircle / 方形 common-iconmask；
    -- 用户 2026-11-17：圆形按钮的 CD 阴影之前是方形的）。按钮池化复用、shape 可热切换，
    -- 所以放在 ApplyZoneButtonStyle 里随 shape 每次重设。
    if button.cooldownFrame and addon.MapPanel.StyleCooldown then
        addon.MapPanel.StyleCooldown(button.cooldownFrame, maskTex)
    end
    -- 形状影响边框（圆形时禁用 Masque、改自带圆环描边），每次都重算边框以保证切换即时生效。
    if addon.ButtonSkin and addon.ButtonSkin.ApplyGroup then addon.ButtonSkin:ApplyGroup(button, addon.ButtonSkin.GROUP_ZONE) end
end

local function Acquire()
    used = used + 1
    if used <= poolSize then return pool[used] end
    local square = addon.db and addon.db.portalButtonSquare
    -- 图标创建统一走本文件内联的 CreateStyledButton（圆形 commonmaskcircle / 方形 common-iconmask，
    -- 同形状高亮遮罩 + 冷却框；原 ade_BaseFramework/widget/StyledButton.lua 逐字内联）。
    local button = CreateStyledButton(rootFrame, DEFAULT_SIZE, "InsecureActionButtonTemplate", nil,
        square and "square" or "circle", addon.db and addon.db.portalButtonEdgeShadow or 1)
    -- 12.x 实证（z-ref_wow-dev-git SecureTemplates.xml:13-18）：InsecureActionButtonTemplate 模板
    -- 只带内联 OnClick、不带 RegisterForClicks，Lua CreateFrame 继承的按钮必须显式注册，
    -- 否则点击根本不派发 OnClick（旧引擎对模板脚本自动注册，12.x 已移除——区域按钮失效根因）。
    -- down/up 都注册：SecureActionButton_OnClick 由 cvar「ActionButtonUseKeyDown」决定在按下或抬起
    -- 分支执行，两分支互斥不会双施法，且兼容开启该 cvar 的用户（对齐 WorldMapPanel:889 主按钮池）。
    button:RegisterForClicks("AnyDown", "AnyUp")
    -- 家宅传送额外标识（移植自 EQoLPlusMapExt）：右上角 homestone 图标，尺寸约图标 1/2、动态（Configure 内定）。
    local badge = button:CreateTexture(nil, "OVERLAY", nil, 3)
    badge:SetAtlas("homestone-minimap-icon")
    badge:Hide()
    button.HousingBadge = badge
    -- CD 初始样式（含 swipe 形状遮罩）统一由 ApplyZoneButtonStyle 按 shape 重设；此处不再单独调。
    button:SetScript("OnEnter", function(self)
        if self.entry and addon.MapPanel.ShowTooltip then addon.MapPanel.ShowTooltip(self, self.entry) end
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- 形状与边框在 ApplyZoneButtonStyle 内按当前设置统一处理（含 ButtonSkin 注册）；
    -- 记录 styleKey，复用时 Configure 只在参数变化后才重跑（r003）。
    ApplyZoneButtonStyle(button)
    button._styleKey = CurrentStyleKey()
    poolSize = poolSize + 1
    pool[poolSize] = button
    return button
end

local function Configure(button, entry)
    button.entry = entry
    -- r003：形状/虚影参数没变就不重跑 ApplyZoneButtonStyle——它内部反复 Icon:ClearAllPoints
    -- + 重设遮罩/EdgeShadow，OnSizeChanged 高频触发（侧边日志栏开合动画）时与布局 pass
    -- 时序冲突，图标额外材质会轻微变大变小闪烁。
    local styleKey = CurrentStyleKey()
    if button._styleKey ~= styleKey then
        ApplyZoneButtonStyle(button)
        button._styleKey = styleKey
    end
    -- 家宅标识：家宅条目在按钮上方叠加 homestone 小图标（约图标 1/2），不可用同步置灰（照 EQoLPlusMapExt）。
    local badge = button.HousingBadge
    if badge then
        if entry.housingFaction then
            local s = math.max(8, math.floor((button:GetWidth() or DEFAULT_SIZE) / 2))
            badge:SetSize(s, s)
            badge:ClearAllPoints()
            badge:SetPoint("TOP", button, "TOP", 0, math.floor(s * 0.5))
            if entry.isKnown then badge:SetDesaturated(false); badge:SetAlpha(1) else badge:SetDesaturated(true); badge:SetAlpha(0.5) end
            badge:Show()
        else
            badge:Hide()
        end
    end
    button.Icon:SetTexture(entry.iconID or 136121)
    if addon.MapPanel.ConfigureAction then addon.MapPanel.ConfigureAction(button, entry) end
    if entry.isKnown then
        button.Icon:SetDesaturated(false)
        button.Icon:SetAlpha(1)
    else
        button.Icon:SetDesaturated(true)
        button.Icon:SetAlpha(0.5)
    end
    if addon.MapPanel.ApplyCooldown then addon.MapPanel.ApplyCooldown(button) end
end

local function ReleaseAll()
    for i = 1, poolSize do
        SetVisible(pool[i], false)
    end
    used = 0
end

local function Update()
    if not rootFrame then return end
    if not addon.db or not addon.db.zoneButtonsEnabled then
        ReleaseAll()
        return
    end
    -- r003：rootFrame 是 SetAllPoints 容器，rect 尚未重排完成时 GetWidth/GetHeight 可能读到
    -- 旧值甚至 0——横向布局按它算 maxCols 会退化成每行 1 个（BOTTOMRIGHT 锚下向上堆，
    -- 观感 = 横排变纵排；用户实测点侧边日志栏关闭按钮后触发）。保留现状等下一次触发重排。
    local rootW, rootH = rootFrame:GetWidth(), rootFrame:GetHeight()
    if not rootW or rootW <= 0 or not rootH or rootH <= 0 then return end
    if addon.MapPanel and addon.MapPanel.IsSuppressed and addon.MapPanel.IsSuppressed() then
        ReleaseAll()
        return
    end
    if InCombat() then
        pendingUpdate = true
        return
    end

    local mapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    -- mapType：0=Cosmic、1=World 永远不显示；2=Continent 由「在大陆地图显示传送按钮」选项控制
    -- （用户 2026-10-28）。选项存于 addon.db.zoneButtonsShowContinent。
    -- 大陆地图（mapType 2）且未启用选项时：非角色的区域传送一律不出，
    -- 只保留角色传送按钮（若开了「显示角色传送按钮」）——之前这里是整体 ReleaseAll，
    -- 角色按钮也被一起清掉了，而用户观察到的是「非角色按钮还在」（用户 2026-10-29）。
    local allowRegular = true
    if mapID then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        local mapType = info and info.mapType
        if mapType == 0 or mapType == 1 then
            ReleaseAll()
            return
        end
        if mapType == 2 and not (addon.db and addon.db.zoneButtonsShowContinent) then
            allowRegular = false
            if not ShowCharacterEnabled() then
                ReleaseAll()
                return
            end
        end
    end
    local entries = mapID and CollectEntries(mapID, allowRegular) or {}
    if #entries == 0 then
        ReleaseAll()
        return
    end

    used = 0
    local size, anchor, offsetX, offsetY, orientation = LayoutConfig()
    local step = size + GAP
    local horizontalRight = (anchor == "TOPRIGHT" or anchor == "BOTTOMRIGHT")
    local verticalBottom = (anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT")
    local dirX = horizontalRight and -1 or 1
    local dirY = verticalBottom and 1 or -1
    for index, entry in ipairs(entries) do
        local col, row
        if orientation == "horizontal" then
            -- 横向：从左到右排满一行后换行
            local width = (rootFrame:GetWidth() or 0) - math.abs(offsetX)
            local maxCols = math.max(1, math.floor(width / step))
            col = (index - 1) % maxCols
            row = math.floor((index - 1) / maxCols)
        else
            -- 纵向：从上到下排满一列后换列（原行为）
            local height = (rootFrame:GetHeight() or 0) - math.abs(offsetY)
            local maxRows = math.floor(height / step)
            if maxRows < MIN_ROWS then maxRows = MIN_ROWS end
            col = math.floor((index - 1) / maxRows)
            row = (index - 1) % maxRows
        end
        local button = Acquire()
        button:SetSize(size, size)
        button:ClearAllPoints()
        button:SetPoint(anchor, rootFrame, anchor, offsetX + col * step * dirX, offsetY + row * step * dirY)
        Configure(button, entry)
        SetVisible(button, true)
    end
    for i = used + 1, poolSize do
        SetVisible(pool[i], false)
    end
end

local function RefreshCooldowns()
    if not addon.MapPanel or not addon.MapPanel.ApplyCooldown then return end
    for i = 1, used do
        local button = pool[i]
        if button and button:IsVisible() then addon.MapPanel.ApplyCooldown(button) end
    end
end

--- r003：WorldMapFrame 尺寸变化（侧边日志栏开合动画会连续触发 OnSizeChanged）时，
--- 同帧内 SetAllPoints 的 rootFrame rect 还没重排完，必须等一帧再按新尺寸算布局；
--- pending 去抖避免动画期间每帧整场重排。
local function UpdateAfterLayout()
    if sizeChangePending then return end
    sizeChangePending = true
    C_Timer.After(0, function()
        sizeChangePending = false
        Update()
    end)
end

local function EnsureRoot()
    if rootFrame or not WorldMapFrame then return end
    local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
    rootFrame = CreateFrame("Frame", nil, parent)
    rootFrame:SetAllPoints()
    rootFrame:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
end

local function HookMap()
    if not WorldMapFrame or WorldMapFrame._adePortalTabZoneButtonsHooked then return end
    WorldMapFrame._adePortalTabZoneButtonsHooked = true
    WorldMapFrame:HookScript("OnShow", function() Update() end)
    WorldMapFrame:HookScript("OnHide", function() ReleaseAll() end)
    -- r003：尺寸变化延迟一帧重排（同帧 rect 未稳定，横向 maxCols 会算错退化成纵排观感）。
    WorldMapFrame:HookScript("OnSizeChanged", function() UpdateAfterLayout() end)
    if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", function() Update() end) end
end

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_WorldMap" then
            EnsureRoot()
            HookMap()
            Update()
            f:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingUpdate then
            pendingUpdate = false
            Update()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
        RefreshCooldowns()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "ZONE_CHANGED_INDOORS" or event == "LOADING_SCREEN_DISABLED" then
        -- 传送到家宅 / 从家宅返回原地后，住宅区按钮要在「传送家宅」和「返回原地」
        -- 之间切换（文本、图标、CD 都变），必须重建条目而不是只刷 CD（用户 2026-10-29）。
        Update()
    end
end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
f:RegisterEvent("BAG_UPDATE_COOLDOWN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("LOADING_SCREEN_DISABLED")

--- 地图与配置就绪后重建按钮；由 Core.lua 在登录后调用，设置改动时再次调用。
function addon.ZoneButtons.Initialize()
    if C_AddOns and C_AddOns.IsAddOnLoaded and not C_AddOns.IsAddOnLoaded("Blizzard_WorldMap") then return end
    EnsureRoot()
    HookMap()
    Update()
end

function addon.ZoneButtons.Refresh()
    Update()
end

--- 供设置面板读写偏移：同一组滑块在不同布局下指向不同的存档位置。
--- OffsetFor 返回的 {x, y} 是「叠加在布局基准偏移之上」的量，默认 0/0。
function addon.ZoneButtons.OffsetFor(layoutKey)
    return OffsetSlot(layoutKey or CurrentLayoutKey())
end

function addon.ZoneButtons.CurrentLayout()
    return CurrentLayoutKey()
end
