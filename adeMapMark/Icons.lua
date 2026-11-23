--[[
adeMapMark - Icons（图标字典 / CAT:KEY ref 解析 / 选择器 / 旋转器）
体系：ADE v6.5；来源 BDmapPlus.lua 图标段（1-922）
--]]

-- 作者: LengKu  更新日期: 0425
-- 功能: 依赖 adeMapMark 运行。若不加载本文件，adeMapMark 为正常可用的纯文字大地图标记插件。

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L
ns.Plus = ns.Plus or {}
local DEFAULT_ICON_SIZE = ns.DEFAULT_ICON_SIZE

-- ===== 图标库数据（字典化重构：tex 路径仅此处定义一次，单一来源）=====
local ICON_DIR = "Interface/AddOns/" .. addonName .. "/Art/CustomICON/"

-- ── A.1 图标库数据（字典格式：[KEY] = { name, tex }）────────────────────────────

local MAP_ICONS = {
    ["RAID_ICON_STAR"]     = { name = "星星", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_1" },
    ["RAID_ICON_CIRCLE"]   = { name = "圆圈", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_2" },
    ["RAID_ICON_DIAMOND"]  = { name = "菱形", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_3" },
    ["RAID_ICON_TRIANGLE"] = { name = "三角", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_4" },
    ["RAID_ICON_MOON"]     = { name = "月亮", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_5" },
    ["RAID_ICON_SQUARE"]   = { name = "方块", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_6" },
    ["RAID_ICON_CROSS"]    = { name = "红叉", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_7" },
    ["RAID_ICON_SKULL"]    = { name = "骷髅", tex = "Interface/TargetingFrame/UI-RaidTargetingIcon_8" },
}

local MAP_ICONS_ORDER = { "RAID_ICON_STAR", "RAID_ICON_CIRCLE", "RAID_ICON_DIAMOND", "RAID_ICON_TRIANGLE", "RAID_ICON_MOON", "RAID_ICON_SQUARE", "RAID_ICON_CROSS", "RAID_ICON_SKULL" }

local MAP_ICONS_SERVICE = {
    ["INNKEEPER"]        = { name = "旅店",    tex = ICON_DIR .. "Innkeeper.tga" },
    ["TRACK_BANKER"]     = { name = "银行",    tex = "Interface/Minimap/Tracking/Banker" },
    ["TRACK_AUCTIONEER"] = { name = "拍卖行",  tex = "Interface/Minimap/Tracking/Auctioneer" },
    ["WORLD_ORDERS"]     = { name = "订单",    tex = ICON_DIR .. "Worldorders.tga" },
    ["TRACK_MAILBOX"]    = { name = "邮箱",    tex = "Interface/Minimap/Tracking/Mailbox" },
    ["TRACK_BARBER"]     = { name = "理发店",  tex = "Interface/Minimap/Tracking/BarberShop" },
    ["TRANSMOGRIFY"]     = { name = "幻化师",  tex = ICON_DIR .. "Transmogrify2.tga" },
    ["DRAGON_ROSTRUM"]   = { name = "驭龙幻形",tex = ICON_DIR .. "DragonRostrum.tga" },
    ["REVIVAL_CATALYST"] = { name = "化生台",  tex = ICON_DIR .. "RevivalCatalyst.tga" },
    ["REFORGE"]          = { name = "物品升级",tex = ICON_DIR .. "Reforge.tga" },
    ["TRAINING_DUMMY"]   = { name = "训练木桩",tex = ICON_DIR .. "TrainingDummy.tga" },
    ["STABLE_MASTER"]    = { name = "兽栏",    tex = ICON_DIR .. "StableMaster.tga" },
    ["PET"]              = { name = "宠物",    tex = ICON_DIR .. "Pet.tga" },
    ["TRACK_FOOD"]       = { name = "餐饮",    tex = "Interface/Minimap/Tracking/Food" },
    ["TRACK_REPAIR"]     = { name = "修理",    tex = "Interface/Minimap/Tracking/Repair" },
    ["FLIGHTMASTER"]     = { name = "飞行点",  tex = ICON_DIR .. "Flightmaster.tga" },
    ["PORTAL_1"]         = { name = "传送1",   tex = ICON_DIR .. "Portal_1.tga" },
    ["PORTAL_2"]         = { name = "传送2",   tex = ICON_DIR .. "Portal_2.tga" },
    ["TRAINER"]          = { name = "训练师",  tex = ICON_DIR .. "Trainer.tga" },
    ["TRACK_REAGENTS"]   = { name = "材料商",  tex = "Interface/Minimap/Tracking/Reagents" },
}

local MAP_ICONS_SERVICE_ORDER = { "INNKEEPER", "TRACK_BANKER", "TRACK_AUCTIONEER", "WORLD_ORDERS", "TRACK_MAILBOX", "TRACK_BARBER", "TRANSMOGRIFY", "DRAGON_ROSTRUM", "REVIVAL_CATALYST", "REFORGE", "TRAINING_DUMMY", "STABLE_MASTER", "PET", "TRACK_FOOD", "TRACK_REPAIR", "FLIGHTMASTER", "PORTAL_1", "PORTAL_2", "TRAINER", "TRACK_REAGENTS" }

local MAP_ICONS_PROFESSION = {
    ["PROF_HERBALISM"]            = { name = "草药",       tex = 4620675 },
    ["PROF_INSCRIPTION"]          = { name = "铭文",       tex = 4620676 },
    ["PROF_ALCHEMY"]              = { name = "炼金",       tex = 4620669 },
    ["PROF_ALCHEMY_LEGACY"]       = { name = "炼金（旧）", tex = "Interface/Icons/Trade_Alchemy" },
    ["PROF_MINING"]               = { name = "采矿",       tex = 4620679 },
    ["PROF_BLACKSMITHING"]        = { name = "锻造",       tex = 4620670 },
    ["PROF_ENGINEERING"]          = { name = "工程",       tex = 4620673 },
    ["PROF_ENGINEERING_LEGACY"]   = { name = "工程（旧）", tex = "Interface/Icons/Trade_Engineering" },
    ["PROF_JEWELCRAFTING"]        = { name = "珠宝",       tex = 4620677 },
    ["PROF_SKINNING"]             = { name = "剥皮",       tex = 4620680 },
    ["PROF_LEATHERWORKING"]       = { name = "制皮",       tex = 4620678 },
    ["PROF_TAILORING"]            = { name = "裁缝",       tex = 4620681 },
    ["PROF_ENCHANTING"]           = { name = "附魔",       tex = 4620672 },
    ["PROF_COOKING"]              = { name = "烹饪",       tex = 4620671 },
    ["PROF_COOKING_LEGACY"]       = { name = "烹饪（旧）", tex = "Interface/Icons/INV_Misc_Food_15" },
    ["PROF_FISHING"]              = { name = "钓鱼",       tex = 4620674 },
    ["PROF_FIRSTAID"]             = { name = "急救",       tex = "Interface/Icons/Spell_Holy_Sealofsacrifice" },
}

local MAP_ICONS_PROFESSION_ORDER = { "PROF_HERBALISM", "PROF_INSCRIPTION", "PROF_ALCHEMY", "PROF_ALCHEMY_LEGACY", "PROF_MINING", "PROF_BLACKSMITHING", "PROF_ENGINEERING", "PROF_ENGINEERING_LEGACY", "PROF_JEWELCRAFTING", "PROF_SKINNING", "PROF_LEATHERWORKING", "PROF_TAILORING", "PROF_ENCHANTING", "PROF_COOKING", "PROF_COOKING_LEGACY", "PROF_FISHING", "PROF_FIRSTAID" }

local MAP_ICONS_OTHER = {
    ["PURPLE_STAR"]      = { name = "紫星",     tex = ICON_DIR .. "PurpleStar.tga" },
    ["BILLBOARD"]        = { name = "布告牌",   tex = ICON_DIR .. "Billboard.tga" },
    ["GOLDEN_CHEST"]     = { name = "宝箱",     tex = ICON_DIR .. "GoldenChest.tga" },
    ["MAIL"]             = { name = "信",       tex = ICON_DIR .. "Mail.tga" },
    ["NEWPLAYER_GUIDE"]  = { name = "绿旗子",   tex = ICON_DIR .. "Newplayer_guide.tga" },
    ["NEWPLAYER_COMER"]  = { name = "新鱼人",   tex = ICON_DIR .. "Newplayer_comer.tga" },
    ["ATTACK"]           = { name = "攻击",     tex = ICON_DIR .. "Attack.tga" },
    ["DEFENSE"]          = { name = "防御",     tex = ICON_DIR .. "Defense.tga" },
    ["DIRECTIONS"]       = { name = "路点",     tex = ICON_DIR .. "Directions.tga" },
    ["MARKER_RED"]       = { name = "红标记",   tex = ICON_DIR .. "P-Marker.tga" },
    ["PORTRAIT_SKULL"]   = { name = "大精英",   tex = ICON_DIR .. "Portraitskullbadge.tga" },
    ["COMBAT"]           = { name = "交战",     tex = ICON_DIR .. "Combat.tga" },
    ["CROSSHAIRS"]       = { name = "准星",     tex = ICON_DIR .. "crosshairs.tga" },
    ["CASH"]             = { name = "钞票",     tex = ICON_DIR .. "Cash.tga" },
    ["SPEAK"]            = { name = "对话",     tex = ICON_DIR .. "Speak.tga" },
    ["ALLIANCE_LOGO"]    = { name = "联盟LOGO", tex = ICON_DIR .. "AllianceLogo.tga" },
    ["HORDE_LOGO"]       = { name = "部落LOGO", tex = ICON_DIR .. "HordeLogo.tga" },
    ["POINT_RED"]        = { name = "红钉",     tex = ICON_DIR .. "PointRed.tga" },
    ["POINT_GREEN"]      = { name = "绿钉",     tex = ICON_DIR .. "PointGreen.tga" },
    ["ARROW1"]           = { name = "箭头1",    tex = ICON_DIR .. "arrow1.tga" },
    ["ARROW2"]           = { name = "箭头2",    tex = ICON_DIR .. "arrow2.tga" },
    ["ARROW3"]           = { name = "箭头3",    tex = ICON_DIR .. "arrow3.tga" },
    ["ARROW_BLUE"]       = { name = "指蓝",     tex = ICON_DIR .. "arrow_blue.tga" },
    ["ARROW_RED"]        = { name = "指红",     tex = ICON_DIR .. "arrow_red.tga" },
    ["ARROW_YELLOW"]     = { name = "指黄",     tex = ICON_DIR .. "arrow_yellow.tga" },
    ["ARROW_GREEN"]      = { name = "指绿",     tex = ICON_DIR .. "arrow_green.tga" },
    ["QUEST_NEWFEATURE"] = { name = "感叹号",   tex = "Interface/OptionsFrame/UI-OptionsFrame-NewFeatureIcon" },
    ["QUEST_ACTIVE"]     = { name = "问号",     tex = "Interface/GossipFrame/ActiveQuestIcon" },
}

local MAP_ICONS_OTHER_ORDER = { "PURPLE_STAR", "BILLBOARD", "GOLDEN_CHEST", "MAIL", "NEWPLAYER_GUIDE", "NEWPLAYER_COMER", "ATTACK", "DEFENSE", "DIRECTIONS", "MARKER_RED", "PORTRAIT_SKULL", "COMBAT", "CROSSHAIRS", "CASH", "SPEAK", "ALLIANCE_LOGO", "HORDE_LOGO", "POINT_RED", "POINT_GREEN", "ARROW1", "ARROW2", "ARROW3", "ARROW_BLUE", "ARROW_RED", "ARROW_YELLOW", "ARROW_GREEN", "QUEST_NEWFEATURE", "QUEST_ACTIVE" }

local MAP_ICONS_GAMEINICON = {}

local MAP_ICONS_CUSTOMICON = {
    ["QUEST_ACTIVE"] = { name = "方式见Lua", tex = "Interface/GossipFrame/ActiveQuestIcon" },
    -- 自定义图标：格式 [tex路径] = { name = "显示名", tex = "纹理路径" }
    --{ ["Interface\\XXX\\XXX\\XXX"] = { name = "？", tex = "Interface\\XXX\\XXX\\XXX" } },
    --{ ["XXX"] = { name = "？", tex = ICON_DIR .. "XXX.tga" } },
}

-- 动态分类的 _ORDER 数组（运行时按需重建，此处声明为空占位）
local MAP_ICONS_GAMEINICON_ORDER = {}
local MAP_ICONS_CUSTOMICON_ORDER = {}

-- ── 注册表（仅引用、零纹理复制、兼白名单）───────────────────────────────────

local MAP_ICONS_TABLES = {
    BASE       = MAP_ICONS,
    SERVICE    = MAP_ICONS_SERVICE,
    PROFESSION = MAP_ICONS_PROFESSION,
    OTHER      = MAP_ICONS_OTHER,
    GAME       = MAP_ICONS_GAMEINICON,
    CUSTOM     = MAP_ICONS_CUSTOMICON,
}

-- 有序 Key 数组注册表（与 MAP_ICONS_TABLES 一一对应，供有序遍历使用）
local MAP_ICONS_ORDER_TABLES = {
    BASE       = MAP_ICONS_ORDER,
    SERVICE    = MAP_ICONS_SERVICE_ORDER,
    PROFESSION = MAP_ICONS_PROFESSION_ORDER,
    OTHER      = MAP_ICONS_OTHER_ORDER,
    GAME       = MAP_ICONS_GAMEINICON_ORDER,
    CUSTOM     = MAP_ICONS_CUSTOMICON_ORDER,
}

-- ── ResolveIcon(ref)：CAT:KEY → tex（O(1) 字典查找）─────────────────────────
--   ref 格式：
--     "CAT:KEY"  如 "SERVICE:FLIGHTMASTER"、"OTHER:P_MARKER"
--     "ATLAS:xx" 暴雪 atlas（拆成 file + tCoord，供 HandyNotes 等外源数据包直接使用）
--     无 ":"     当作裸 tex 路径兜底（兼容导入/外源数据）
--   未知 CAT → 返回 nil（白名单拦截）
local function GetAtlasName(ref)
    if type(ref) ~= "string" then return nil end
    return ref:match("^ATLAS:(.+)$") or ref:match("^[%w_]+:ATLAS:(.+)$")
end

function ns.ResolveIcon(ref)
    if type(ref) ~= "string" then return nil end
    local atlasName = GetAtlasName(ref)
    if atlasName then
        local info = C_Texture.GetAtlasInfo(atlasName)
        return info and info.file or nil
    end
    local cat, key = ref:match("^([%w_]+):(.+)$")
    if not cat then return ref end         -- 无 ":" 视为裸路径兜底
    local t = MAP_ICONS_TABLES[cat]
    if not t then return nil end           -- 未知 CAT，白名单拦截
    local e = t[key]
    return e and e.tex or nil
end

-- atlas 图标返回其 tCoord；非 atlas 返回 nil，调用方回退到 iconCrop 裁切
function ns.ResolveIconTexCoord(ref)
    local atlasName = GetAtlasName(ref)
    if not atlasName then return nil end
    local info = C_Texture.GetAtlasInfo(atlasName)
    if not info then return nil end
    return info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
end

-- 统一应用图标：atlas 用原生 tCoord，普通贴图用 iconCrop 裁切
function ns.ApplyIconTexture(texture, ref, crop)
    if not texture then return end
    texture:SetTexture(ns.ResolveIcon(ref))
    ns.ApplyIconTexCoord(texture, ref, crop)
end

function ns.ApplyIconTexCoord(texture, ref, crop)
    if not texture then return end
    local l, r, t, b = ns.ResolveIconTexCoord(ref)
    if l then
        texture:SetTexCoord(l, r, t, b)
        return
    end
    local m = (1 - 1 / (crop or 1)) / 2
    texture:SetTexCoord(m, 1 - m, m, 1 - m)
end

-- ── FindIconName(ref)：CAT:KEY → name（O(1)，替代原按 tex 的 O(n) 扫描）─────
function ns.Plus.FindIconName(ref)
    if type(ref) ~= "string" then return nil end
    local atlasName = GetAtlasName(ref)
    if atlasName then return atlasName end
    local cat, key = ref:match("^([%w_]+):(.+)$")
    if not cat then return ref end        -- 无 ":" 视为裸路径兜底（与 ResolveIcon 对齐）
    local t = MAP_ICONS_TABLES[cat]
    if not t then return nil end
    local e = t[key]
    return e and e.name or nil
end

-- ============================================================================
-- [A] 图标功能
--     包含：大地图 Pin 钩子、图标相关公开钩子、图标选择器 UI + 旋转器
--     （图标库数据 MAP_ICONS* 字典已在文件顶部定义）
-- ============================================================================

-- ── A.2 大地图 Pin 旋转钩子（Hook adeMapMarkWorldMapPinMixin）────────────────────

local _currentEditPin = nil

do
    -- Hook OnAcquired：Pin 被（重）创建时，补回存储的旋转角度
    local _origAcq = adeMapMarkWorldMapPinMixin.OnAcquired
    adeMapMarkWorldMapPinMixin.OnAcquired = function(self, dataIndex, data, x, y)
        _origAcq(self, dataIndex, data, x, y)
        if data and data.icon and self.icon then
            self.icon:SetRotation(-math.rad(data.iconRotation or 0))
            local wp = _G["adeMapMark_WorldMapPanel"]
            if wp and wp.editingData == data then
                _currentEditPin = self
            end
        end
    end

    -- Hook OnMouseUp：左键点击时记录 Pin 引用（仅图标 Pin 跟踪）
    local _origUp = adeMapMarkWorldMapPinMixin.OnMouseUp
    adeMapMarkWorldMapPinMixin.OnMouseUp = function(self, button)
        if button == "LeftButton" then
            _currentEditPin = (self.data and self.data.icon) and self or nil
        end
        _origUp(self, button)
    end
end


-- ── A.4 图标相关公开钩子（经 ns.Plus 供 Pin 渲染层调用）────────────────────

-- FindIconName 已在文件顶部定义为 O(1) CAT:KEY 查找，此处不重复定义

-- Pin_OnEnter 钩子：纯图标标记（无标题无备注）不弹提示框，返回 true 表示已处理
function ns.Plus.OnPinEnter(self, data)
    local hasIcon  = data.icon ~= nil
    local hasTitle = data.title and data.title:trim() ~= ""
    local hasNote  = data.note  and data.note:trim()  ~= ""
    if hasIcon and not hasTitle and not hasNote then
        GameTooltip:Hide()
        return true
    end
    return false
end

-- 大地图 Pin 渲染钩子：有图标时接管渲染并返回 true，否则返回 false
function ns.Plus.OnPinAcquired(self, data, iconSize, zoomAdj)
    if not data.icon then
        if self.icon then self.icon:Hide() end
        return false
    end
    if not self.icon then
        self.icon = self:CreateTexture(nil, "ARTWORK")
        self.icon:SetAllPoints()
    end
    self.text:Hide()
    self.icon:Show()
    ns.ApplyIconTexture(self.icon, data.icon, data.iconCrop)
    self.icon:SetVertexColor(1, 1, 1)
    self.icon:SetAlpha(data.color.a or 1)
    self.icon:SetDesaturated(data.isGrayscale == true)
    local iconSizeWM = math.max(iconSize * zoomAdj, 1)          -- 大地图图标尺寸：设置值即像素，随画布缩放自适应
    self:SetSize(iconSizeWM, iconSizeWM)
    return true
end

-- Pin 左键点击钩子：恢复图标选择器状态及旋转器指示点
function ns.Plus.OnPinLeftClick(data, panel)
    panel.selectedIcon = data.icon or nil
    panel.iconRotation = math.rad(data.iconRotation or 0)
    
    if panel.SetIconBtnIcon then
        panel.SetIconBtnIcon(panel.selectedIcon)   -- 先调这个（内部会重置TexCoord和Crop为1.0）
    end
    
    -- ↓ 然后再从 data 中读取并覆盖裁切比例，必须在SetIconBtnIcon之后
    panel.iconCrop = data.iconCrop or 1.0

end

-- 保存标记前钩子：注入图标路径与旋转角度
function ns.Plus.OnBeforeSaveMarker(newData, panel)
    local icon = panel.selectedIcon
    newData.icon         = icon
    newData.iconRotation = math.deg(panel.iconRotation or 0)
    newData.iconCrop = panel.iconCrop or 1.0
    -- 纯图标点位（用户未填标题）清空默认的"未命名"
    if icon and (not newData.title or newData.title == "未命名") then
        newData.title = ""
    end
end


-- ── A.5 图标选择器 UI + 旋转器 ───────────────────────────────────────────────

function ns.Plus.SetupIconSelector(panel, titleBg)

    -- ===== 图标选择器按钮（32×32）=====

    local iconSelectorBtn = CreateFrame("Button", "adeMapMark_IconSelectorBtn", panel, "BackdropTemplate")
    iconSelectorBtn:SetSize(32, 32)
    iconSelectorBtn:SetPoint("LEFT", titleBg, "RIGHT", 12, 0)
    iconSelectorBtn:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    iconSelectorBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    iconSelectorBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    iconSelectorBtn.tex = iconSelectorBtn:CreateTexture(nil, "ARTWORK")
    iconSelectorBtn.tex:SetPoint("TOPLEFT",      2, -2)
    iconSelectorBtn.tex:SetPoint("BOTTOMRIGHT", -2,  2)
    iconSelectorBtn.tex:Hide()

    iconSelectorBtn.label = iconSelectorBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    iconSelectorBtn.label:SetPoint("CENTER", 0, 0)
    iconSelectorBtn.label:SetText(L.ICON_LABEL)
    iconSelectorBtn.label:Show()

    local function SetIconBtnIcon(loc)
        if loc then
            panel.iconCrop = 1.0
            ns.ApplyIconTexture(iconSelectorBtn.tex, loc, panel.iconCrop)
            iconSelectorBtn.tex:Show()
            iconSelectorBtn.label:Hide()
            -- Item 4：新建标记（非编辑既有）选中图标时，尺寸滑块设为默认图标尺寸
            if not panel.editingData and panel.sizeSlider then
                panel.sizeSlider:SetValue(DEFAULT_ICON_SIZE)
            end
        else
            iconSelectorBtn.tex:SetTexture(nil)
            iconSelectorBtn.tex:Hide()
            iconSelectorBtn.label:Show()
            -- Item 4：新建标记清除图标时，尺寸滑块设回默认图标尺寸
            if not panel.editingData and panel.sizeSlider then
                panel.sizeSlider:SetValue(DEFAULT_ICON_SIZE)
            end
        end
    end

    panel.selectedIcon    = nil
    panel.iconRotation    = 0
    panel.iconSelectorBtn = iconSelectorBtn
    panel.SetIconBtnIcon  = SetIconBtnIcon
    panel.iconCrop = 1.0
    
    -- ===== 子面板（二级悬停菜单）=====

    local subPanel = CreateFrame("Frame", "adeMapMark_IconSubPanel", UIParent, "BackdropTemplate")
    subPanel:SetSize(140, 160)
    subPanel:SetFrameStrata("TOOLTIP")
    subPanel:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    subPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    subPanel:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    subPanel:Hide()
    subPanel.rows = {}

    -- ===== 主下拉菜单 =====

    local customMenuFrame = CreateFrame("Frame", "adeMapMark_CustomIconMenu", UIParent, "BackdropTemplate")
    customMenuFrame:SetSize(130, 10)
    customMenuFrame:SetFrameStrata("DIALOG")
    customMenuFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    customMenuFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    customMenuFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    customMenuFrame:Hide()
    customMenuFrame.widgets = {}

    -- ===== 离开延迟隐藏 =====

    local hideTimer = nil
    local function CancelHideTimer()
        if hideTimer then hideTimer:Cancel(); hideTimer = nil end
    end
    local function StartHideTimer()
        CancelHideTimer()
        hideTimer = C_Timer.NewTimer(0.1, function()
            hideTimer    = nil
            local inBtn  = iconSelectorBtn:IsMouseOver()
            local inMenu = customMenuFrame:IsShown() and customMenuFrame:IsMouseOver()
            local inSub  = subPanel:IsShown() and subPanel:IsMouseOver()
            if not inBtn and not inMenu and not inSub then
                customMenuFrame:Hide(); subPanel:Hide()
            elseif not inSub then
                subPanel:Hide()
            end
        end)
    end
    customMenuFrame:SetScript("OnLeave", StartHideTimer)
    subPanel:SetScript("OnLeave",        StartHideTimer)
    customMenuFrame:SetScript("OnEnter", CancelHideTimer)
    subPanel:SetScript("OnEnter",        CancelHideTimer)

    -- ===== 填充子面板 =====

    local SUBPANEL_MAX_ROWS_PER_COL = 15
    local SUBPANEL_COL_WIDTH        = 120

    local function PopulateSubPanel(iconList, cat, anchorFrame)
        local rowH     = 22
        local padding  = 6

        -- 获取有序 Key 数组（动态分类在每次弹出时重建顺序，确保与字典同步）
        local orderList = MAP_ICONS_ORDER_TABLES[cat]
        if cat == "GAME" then
            -- 游戏内提取：按 tex 路径排序保持稳定
            wipe(MAP_ICONS_GAMEINICON_ORDER)
            for key in pairs(iconList) do
                tinsert(MAP_ICONS_GAMEINICON_ORDER, key)
            end
            table.sort(MAP_ICONS_GAMEINICON_ORDER)
        elseif cat == "CUSTOM" then
            -- 自定义制作：按 tex 路径排序保持稳定
            wipe(MAP_ICONS_CUSTOMICON_ORDER)
            for key in pairs(iconList) do
                tinsert(MAP_ICONS_CUSTOMICON_ORDER, key)
            end
            table.sort(MAP_ICONS_CUSTOMICON_ORDER)
        end
        -- 静态分类直接使用预定义的 _ORDER 数组（orderList 已在上面获取）

        local totalItems = #orderList
        local colCount = math.ceil(totalItems / SUBPANEL_MAX_ROWS_PER_COL)

        -- 先把所有行隐藏
        for _, row in ipairs(subPanel.rows) do row:Hide() end

        local i = 0  -- 行索引计数器（用于布局和对象池）
        if orderList then
            for _, key in ipairs(orderList) do
                local item = iconList[key]
                -- 防御：_ORDER 与字典不同步时跳过（Lua 5.1 无 goto，用 if 包裹）
                if item then
                    i = i + 1
                    local row = subPanel.rows[i]  -- 优先复用
                    if not row then
                        -- 池里不够用时才新建
                        row = CreateFrame("Button", nil, subPanel)
                        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
                        row:GetHighlightTexture():SetAlpha(0.15)
                        row.ico = row:CreateTexture(nil, "ARTWORK")
                        row.ico:SetSize(16, 16)
                        row.ico:SetPoint("LEFT", 2, 0)
                        row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        row.lbl:SetPoint("LEFT", row.ico, "RIGHT", 4, 0)
                        row.lbl:SetTextColor(1, 1, 1)
                        row.lbl:SetJustifyH("LEFT")
                        row:SetScript("OnLeave", StartHideTimer)
                        subPanel.rows[i] = row
                    end

                    local colIdx = math.floor((i-1) / SUBPANEL_MAX_ROWS_PER_COL)
                    local rowIdx = (i-1) % SUBPANEL_MAX_ROWS_PER_COL
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", padding + colIdx * SUBPANEL_COL_WIDTH, -padding - rowIdx * rowH)
                    row:SetWidth(SUBPANEL_COL_WIDTH - padding)
                    row:SetHeight(rowH)
                    ns.ApplyIconTexture(row.ico, item.tex, 1)
                    row.lbl:SetText(item.name)
                    -- 限制文字宽度，超出部分自动显示省略号
                    row.lbl:SetWidth(SUBPANEL_COL_WIDTH - 30)
                    row.lbl:SetWordWrap(false)

                    -- 构建 ref：CAT:KEY（用于存档和渲染）
                    local ref = cat .. ":" .. key
                    -- 左键选择，右键删除（仅限"游戏内提取"和"自定义制作"列表）
                    row:SetScript("OnClick", function(self, button)
                        if button == "RightButton" then
                            if iconList == MAP_ICONS_GAMEINICON then
                                -- 1. 从内存字典中删除（KEY = tex 路径）
                                MAP_ICONS_GAMEINICON[key] = nil
                                -- 2. 从数据库彻底抹除，防止重载后复活
                                local dbNow = _G["adeMapMarkDB"]
                                if dbNow and dbNow.gameInIcons then
                                    for k, v in ipairs(dbNow.gameInIcons) do
                                        if v.tex == item.tex and v.name == item.name then
                                            table.remove(dbNow.gameInIcons, k)
                                            break
                                        end
                                    end
                                end
                                -- 3. 实时刷新悬浮面板
                                PopulateSubPanel(iconList, cat, anchorFrame)
                            elseif iconList == MAP_ICONS_CUSTOMICON then
                                -- 从自定义字典中删除
                                MAP_ICONS_CUSTOMICON[key] = nil
                                PopulateSubPanel(iconList, cat, anchorFrame)
                            else
                                print("|cffffff00[adeMapMark]|r " .. L.ICON_DELETE_FORBID)
                            end
                        else
                            -- 左键：正常选择图标，存 ref 字符串
                            SetIconBtnIcon(ref)
                            panel.selectedIcon = ref
                            subPanel:Hide()
                            customMenuFrame:Hide()
                        end
                    end)

                    row:Show()
                end
            end
        end

        subPanel:SetWidth(colCount * SUBPANEL_COL_WIDTH + padding * 2)
        local rowsInTallestCol = math.min(totalItems, SUBPANEL_MAX_ROWS_PER_COL)
        subPanel:SetHeight(math.max(rowsInTallestCol * rowH + padding * 2, 40))
        subPanel:ClearAllPoints()
        subPanel:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 2, 0)
        subPanel:Show()
    end

    -- 从数据库加载"游戏内提取"图标库（字典格式，KEY = tex 路径）
    local db = _G["adeMapMarkDB"]
    if db then
        db.gameInIcons = db.gameInIcons or {}
        wipe(MAP_ICONS_GAMEINICON)
        for _, item in ipairs(db.gameInIcons) do
            MAP_ICONS_GAMEINICON[item.tex] = { name = item.name, tex = item.tex }
        end
    end

    local BuildCustomMenu  -- 提前声明

    -- 暴露给 BDmap.lua 的全局刷新接口
    ns.Plus.RefreshCustomMenu = function()
        local dbNow = _G["adeMapMarkDB"]
        if dbNow then
            wipe(MAP_ICONS_GAMEINICON)
            for _, item in ipairs(dbNow.gameInIcons or {}) do
                MAP_ICONS_GAMEINICON[item.tex] = { name = item.name, tex = item.tex }
            end
        end
        if BuildCustomMenu then BuildCustomMenu() end
    end

    -- ===== 构建主菜单 =====

    BuildCustomMenu = function()
        for _, row in ipairs(customMenuFrame.widgets) do row:Hide() end
        wipe(customMenuFrame.widgets)
        local rowH   = 22
        local padding = 4
        local yOff   = -padding
        local menuW  = 130

        local function AddNormalRow(key, item, cat)
            local row = CreateFrame("Button", nil, customMenuFrame)
            row:SetPoint("TOPLEFT", padding, yOff)
            row:SetSize(menuW - padding*2, rowH)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
            row:GetHighlightTexture():SetAlpha(0.15)
            local ico = row:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16)
            ico:SetPoint("LEFT", 2, 0)
            ns.ApplyIconTexture(ico, item.tex, 1)
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", ico, "RIGHT", 4, 0)
            lbl:SetText(item.name)
            lbl:SetTextColor(1, 1, 1)
            lbl:SetJustifyH("LEFT")
            lbl:SetWidth(menuW - 40)   -- 限制主菜单文字宽度，超出变...
            lbl:SetWordWrap(false)
            local ref = cat .. ":" .. key
            row:SetScript("OnClick", function()
                SetIconBtnIcon(ref)
                panel.selectedIcon = ref
                customMenuFrame:Hide()
                subPanel:Hide()
            end)
            row:SetScript("OnEnter", function() CancelHideTimer(); subPanel:Hide() end)
            row:SetScript("OnLeave", StartHideTimer)
            tinsert(customMenuFrame.widgets, row)
            yOff = yOff - rowH
        end

        -- BASE 分类主菜单条目（按有序数组遍历，保证渲染顺序稳定）
        for _, key in ipairs(MAP_ICONS_ORDER) do
            local item = MAP_ICONS[key]
            if item then AddNormalRow(key, item, "BASE") end
        end

        -- 分隔线
        local sep = customMenuFrame:CreateTexture(nil, "ARTWORK")
        sep:SetAtlas("Options_HorizontalDivider", true)
        sep:SetPoint("TOPLEFT", padding, yOff - 8)
        sep:SetPoint("RIGHT", customMenuFrame, "RIGHT", -padding, 0)
        sep:SetAlpha(0.85)
        yOff = yOff - 12
        tinsert(customMenuFrame.widgets, sep)

        -- 二级子菜单入口（每项加 cat 短名）
        local subMenuDefs = {
            { name = "服务 >",       list = MAP_ICONS_SERVICE,    cat = "SERVICE" },
            { name = "专业 >",       list = MAP_ICONS_PROFESSION, cat = "PROFESSION" },
            { name = "其它 >",       list = MAP_ICONS_OTHER,      cat = "OTHER" },
            { name = "游戏内提取 >", list = MAP_ICONS_GAMEINICON, cat = "GAME" },
            { name = "自定义制作 >", list = MAP_ICONS_CUSTOMICON, cat = "CUSTOM" },
        }
        for _, def in ipairs(subMenuDefs) do
            local row = CreateFrame("Button", nil, customMenuFrame)
            row:SetPoint("TOPLEFT", padding, yOff)
            row:SetSize(menuW - padding*2, rowH)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
            row:GetHighlightTexture():SetAlpha(0.2)
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", 6, 0)
            lbl:SetText(def.name)
            lbl:SetTextColor(0.9, 0.85, 0.6)
            local listRef = def.list
            local catRef  = def.cat
            row:SetScript("OnEnter", function(self) CancelHideTimer(); PopulateSubPanel(listRef, catRef, self) end)
            row:SetScript("OnLeave", StartHideTimer)
            row:SetScript("OnClick", function() end)
            tinsert(customMenuFrame.widgets, row)
            yOff = yOff - rowH
        end
        customMenuFrame:SetHeight(math.max(math.abs(yOff) + padding, 40))
    end

    BuildCustomMenu()

    -- ===== 图标选择器事件 =====

    -- 1. 单击：左键打开/关闭菜单，右键清除当前选中图标
    iconSelectorBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            SetIconBtnIcon(nil)
            panel.selectedIcon = nil
            customMenuFrame:Hide()
            subPanel:Hide()
            if self:IsMouseOver() then
                self:GetScript("OnEnter")(self)
            end
        else
            if customMenuFrame:IsShown() then
                customMenuFrame:Hide(); subPanel:Hide()
            else
                customMenuFrame:ClearAllPoints()
                customMenuFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
                customMenuFrame:Show()
            end
        end
    end)
    
    -- 2. 滚轮：缩放以裁切显示区域
    iconSelectorBtn:EnableMouseWheel(true)
    iconSelectorBtn:SetScript("OnMouseWheel", function(self, delta)
        if not panel.selectedIcon then return end
        local step = 0.05
        panel.iconCrop = math.max(1, math.min(3.0, panel.iconCrop + delta * step)) 
        ns.ApplyIconTexCoord(iconSelectorBtn.tex, panel.selectedIcon, panel.iconCrop)
        -- 实时同步大地图预览
        if panel.editingData then
            panel.editingData.iconCrop = panel.iconCrop
            -- 触发大地图 pin 刷新（如有 _currentEditPin）
            if _currentEditPin and _currentEditPin.icon then
                ns.ApplyIconTexCoord(_currentEditPin.icon, panel.editingData.icon, panel.iconCrop)
            end
            ns.Plus.ApplyRotToMinimap(panel.editingData, panel.iconRotation)
        end
    end)

    -- 3. 双击：呼出原生输入弹窗（手动输入 ID 添加提取图标）
    iconSelectorBtn:SetScript("OnDoubleClick", function(self, button)
        if button == "LeftButton" then
            StaticPopup_Show("BDMAP_ADD_CUSTOM_ICON")
            customMenuFrame:Hide(); subPanel:Hide()
        end
    end)

    -- 4. 悬停提示：仅在未选择图标时显示
    iconSelectorBtn:SetScript("OnEnter", function(self)
        CancelHideTimer()
        if panel.selectedIcon then return end  -- 已选图标时不弹提示
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.ICON_SELECTOR_TITLE, 1, 0.85, 0)
        GameTooltip:AddLine(L.ICON_SELECTOR_HELP, 0.85, 0.85, 0.85)
        GameTooltip:Show()
    end)
    iconSelectorBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        StartHideTimer()  -- 鼠标离开按钮时启动倒计时，否则菜单不会自动关闭
    end)

    -- 5. 拖拽获取
    iconSelectorBtn:SetScript("OnReceiveDrag", function(self)

        local cursorType, id, _, spellID = GetCursorInfo()
        local tex, name = nil, nil

        if cursorType == "item" then
            tex  = C_Item.GetItemIconByID(id)
            name = C_Item.GetItemNameByID(id) or L.ICON_ITEM
        elseif cursorType == "spell" then
            tex  = C_Spell.GetSpellTexture(spellID)
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            name = spellInfo and spellInfo.name or L.ICON_SPELL
        elseif cursorType == "macro" then
            local macroName, iconFileID = GetMacroInfo(id)
            tex  = iconFileID
            name = macroName or L.ICON_MACRO
        end

        if tex then
            ClearCursor()
            -- 字典格式：KEY = tex 路径
            MAP_ICONS_GAMEINICON[tex] = { name = name, tex = tex }
            local dbNow = _G["adeMapMarkDB"]
            if dbNow then
                dbNow.gameInIcons = dbNow.gameInIcons or {}
                tinsert(dbNow.gameInIcons, { name = name, tex = tex })
            end
            if BuildCustomMenu then BuildCustomMenu() end
            print("|cff88ff88[adeMapMark]|r " .. string.format(L.ICON_EXTRACT_OK, name))
        end
    end)

    -- 6. 原生简陋弹窗（支持空格分离自定义名字）
    StaticPopupDialogs["BDMAP_ADD_CUSTOM_ICON"] = {
        text       = L.ICON_EXTRACT_HINT,
        button1    = L.ICON_EXTRACT_BTN,
        button2    = L.ICON_EXTRACT_CANCEL,
        hasEditBox = true,
        OnAccept   = function(self)
            local eBox   = self.EditBox or self.editBox
            local input  = eBox:GetText()
            -- 用空格分离 ID / ATLAS 定义名和自定义名称
            local valueStr, nameStr = input:match("^(%S+)%s*(.*)$")
            local tex, defaultName
            local id = tonumber(valueStr)

            if id then
                tex, defaultName = id, "ID:" .. id
                if C_Spell and C_Spell.GetSpellInfo then
                    local sInfo = C_Spell.GetSpellInfo(id)
                    if sInfo then
                        defaultName = sInfo.name
                        tex         = C_Spell.GetSpellTexture(id) or tex
                    end
                end
                if C_Item and C_Item.GetItemNameByID(id) then
                    defaultName = C_Item.GetItemNameByID(id)
                    tex         = C_Item.GetItemIconByID(id) or tex
                end
            else
                -- ATLAS 定义名（可带 ATLAS: 前缀），用客户端 atlas 信息验证
                local atlasName = valueStr and valueStr:match("^ATLAS:(.+)$") or valueStr
                if atlasName and C_Texture.GetAtlasInfo(atlasName) then
                    tex = "ATLAS:" .. atlasName
                    defaultName = atlasName
                end
            end

            if tex then
                -- 玩家写了自定义名则用玩家的，否则用系统原名/ATLAS 名
                local finalName = (nameStr and nameStr ~= "") and nameStr or defaultName
                -- 字典格式：KEY = tex（ATLAS:xxx 由 ResolveIcon 拆成 file + tCoord）
                MAP_ICONS_GAMEINICON[tex] = { name = finalName, tex = tex }
                local dbNow = _G["adeMapMarkDB"]
                if dbNow then
                    dbNow.gameInIcons = dbNow.gameInIcons or {}
                    tinsert(dbNow.gameInIcons, { name = finalName, tex = tex })
                end
                if BuildCustomMenu then BuildCustomMenu() end
                print("|cff88ff88[adeMapMark]|r " .. string.format(L.ICON_EXTRACT_OK, finalName))
            elseif input and input ~= "" then
                print("|cffff4444[adeMapMark]|r " .. L.ICON_EXTRACT_FAIL)
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            StaticPopupDialogs[parent.which].OnAccept(parent)
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        OnShow = function(self)
            local eBox = self.EditBox or self.editBox
            if eBox then
                eBox:SetWidth(220)
                eBox:SetText("")
                eBox:SetAutoFocus(false)
                eBox:ClearFocus()
            end
        end,
        timeout      = 0,
        hideOnEscape = true,
    }


    -- ===== 角度旋转器 =====

    local RING_R   = 25                   -- 轨道半径（px）
    local ROTOR_SZ = RING_R * 2 + 16      -- 框体尺寸（留出箭头旋转时的溢出空间）

    local rotFrame = CreateFrame("Frame", "adeMapMark_RotatorFrame", panel)
    rotFrame:SetSize(ROTOR_SZ, ROTOR_SZ)
    rotFrame:SetPoint("CENTER", iconSelectorBtn, "CENTER", 0, 0)
    rotFrame:SetFrameLevel(math.max(0, iconSelectorBtn:GetFrameLevel() - 1))
    rotFrame:EnableMouse(true)
    rotFrame:Hide()
    panel.rotatorFrame = rotFrame

    -- ── 旋转小把手 ──────────────────────────────────────────────────────────

    local dot = rotFrame:CreateTexture(nil, "OVERLAY")
    dot:SetSize(18, 18)
    dot:SetTexture(ICON_DIR .. "handle5.tga")
    dot:SetPoint("CENTER", rotFrame, "CENTER", 0, RING_R)

    -- ── 更新 UI：移动指示点并同时旋转图标 ──────────────────────────────────

    local function UpdateRotatorUI(angle)
        local dx = math.sin(angle) * RING_R
        local dy = math.cos(angle) * RING_R
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", rotFrame, "CENTER", dx, dy)
        dot:SetRotation(-angle)
        if iconSelectorBtn.tex then
            iconSelectorBtn.tex:SetRotation(-angle)
        end
    end

    -- 对外暴露：让 OnPinLeftClick 能从外部同步旋转器 UI
    rotFrame.SetAngle = UpdateRotatorUI

    -- ── 计算鼠标相对于旋转器圆心的角度（顺时针+，0 = 12 点钟）──────────────

    local function GetMouseAngle()
        local cx, cy = rotFrame:GetCenter()
        if not cx then return panel.iconRotation end
        local scale = rotFrame:GetEffectiveScale()
        local mx, my = GetCursorPosition()
        return math.atan2(mx / scale - cx, my / scale - cy)
    end

    local function SnapAngle(angle)
        local deg     = math.deg(angle)
        local nearest = math.floor(deg / 45 + 0.5) * 45
        if math.abs(deg - nearest) <= 3 then
            return math.rad(nearest)
        end
        return angle
    end

    -- ── 写入旋转角度并实时预览大地图/小地图 ────────────────────────────────

    local function ApplyRotation(angle)
        panel.iconRotation = angle
        UpdateRotatorUI(angle)
        if panel.editingData then
            if _currentEditPin and _currentEditPin:IsShown() and _currentEditPin.icon then
                _currentEditPin.icon:SetRotation(-angle)
            end
            panel.editingData.iconRotation = math.deg(angle)
            ns.Plus.ApplyRotToMinimap(panel.editingData, angle)
        end
    end

    -- ── 鼠标事件 ────────────────────────────────────────────────────────────

    local isDragging = false

    rotFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            ApplyRotation(SnapAngle(GetMouseAngle()))
        elseif button == "RightButton" then
            ApplyRotation(0)    -- 右键一键归零
        end
    end)

    rotFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then isDragging = false end
    end)

    rotFrame:SetScript("OnUpdate", function(self)
        if not isDragging then return end
        if not IsMouseButtonDown("LeftButton") then isDragging = false; return end
        ApplyRotation(SnapAngle(GetMouseAngle()))
    end)

    UpdateRotatorUI(0)

    -- 覆盖 SetIconBtnIcon：同步控制旋转器的显示/隐藏
    local _origSIBI = SetIconBtnIcon
    SetIconBtnIcon = function(texPath)
        _origSIBI(texPath)
        rotFrame:SetShown(texPath ~= nil)
        if texPath then
            ns.ApplyIconTexCoord(iconSelectorBtn.tex, texPath, panel.iconCrop)
        else
            panel.selectedIcon = nil    -- 强制同步清空底层数据
            panel.iconRotation = 0
            panel.iconCrop = 1.0
            UpdateRotatorUI(0)
        end
    end
    panel.SetIconBtnIcon = SetIconBtnIcon

    -- 地图关闭时收起所有菜单
    WorldMapFrame:HookScript("OnHide", function()
        customMenuFrame:Hide()
        subPanel:Hide()
        CancelHideTimer()
    end)

    -- ===== 重置函数：供 BDmap.lua 在"结束编辑/新建完成"时显式调用 =====
    -- isFullReset = true  → 彻底清空图标数据
    -- isFullReset = false → 仅同步旋转器 UI（用于切换标签页）
    function ns.Plus.ResetIconAndRotator(isFullReset)
        -- 无论如何都关闭 UI 菜单
        if customMenuFrame then customMenuFrame:Hide() end
        if subPanel        then subPanel:Hide()        end
        CancelHideTimer()

        if isFullReset then
            SetIconBtnIcon(nil)
            panel.selectedIcon = nil
            panel.iconRotation = 0
            panel.iconCrop = 1.0
            if panel.rotatorFrame and panel.rotatorFrame.SetAngle then
                panel.rotatorFrame.SetAngle(0)
            end
            _currentEditPin = nil
        else
            -- 仅同步旋转器 UI，不清除选中图标
            if panel.rotatorFrame and panel.rotatorFrame.SetAngle then
                panel.rotatorFrame.SetAngle(panel.iconRotation or 0)
            end
        end
    end

end  -- SetupIconSelector 结束


