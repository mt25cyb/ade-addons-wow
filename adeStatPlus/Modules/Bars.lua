--[==[ 行内进度条与材质管理（F8 / D22）
    · 两种显示风格：separate = 条在文本行下方另占一行；embedded = 条铺满整行作为衬底、
      文本浮在条上（条 frameLevel 低于行，见 Panel.Init 的行层级设置）。
    · embedded 时条铺满文本行 → 高度随字号变动、火花随条高（D68）；
      separate 时用 bars.height；条材质与条背景透明度独立（D69）。
    · 阀值刻度：三层 OVERLAY 纹理（阴影 / 主线 / glow），按**实际阀值**定位（D71），
      用 TOPLEFT/BOTTOMLEFT 相对点（StatMarks/StatRow.lua:410-420），并在
      OnSizeChanged 时重定位；是否显示由 bars.showThreshold 与来源是否提供达标值
      共同决定（D22/D28）。
    · 「按满宽填充」已删除（D39），不再存在 fullscreen 配置。
    secret 纪律：填充比例只在 entry.percentPlain 时算术；percent 为 secret 时原值直通
    StatusBar:SetValue 由客户端渲染（§2.3）。
    材质实证：Noodle_StatBars/Noodle_StatBars.lua:12 atrocity.tga；
    StatMarks/StatRow.lua:41 Interface\RaidFrame\Raid-Bar-Hp-Fill。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local Bars = {}
ns.Bars = Bars

-- ADE v6.5：字体/材质走原生 Media 表，不再依赖 LibSharedMedia
local Media = ns.Media

local SPARK_TEX = "Interface\\CastingBar\\UI-CastingBar-Spark"

-- 进度条范围常量
Bars.MAX_ITEM_LEVEL = 344 -- 当前版本的最高装备等级，后续版本更新时此值应该根据实际情况调整
Bars.MIN_ITEM_LEVEL = 1
Bars.SPEED_MIN_PERCENT = 1
Bars.SPEED_MAX_PERCENT = 310 -- 当前已知正常情况下的最高速度（含上坐骑）
local DEFAULT_MIN, DEFAULT_MAX = 0, 100

function Bars.Init()
end

--- 状态条纹理下拉的全量数据源（原生两款，见 Modules/Media.lua）。
function Bars.TextureItems()
    return Media.TextureItems()
end

--- 取材质文件路径。
function Bars.TexturePath(key)
    return Media.TexturePath(key)
end

--- 为一行创建进度条控件（复用：每行只创建一次）。
function Bars.CreateRowBar(parent)
    local visual = {}
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetMinMaxValues(0, 100)
    -- 层级低于父行，使行内文本在 embedded 模式下浮在条之上
    local lvl = parent:GetFrameLevel()
    bar:SetFrameLevel(lvl > 0 and lvl - 1 or 0)
    visual.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0, 0, 0, 0.6)
    visual.bg = bg

    local tickShadow = bar:CreateTexture(nil, "OVERLAY", nil, 1)
    tickShadow:SetColorTexture(0, 0, 0, 0.8)
    tickShadow:SetWidth(3)
    local tick = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    tick:SetColorTexture(1, 1, 1, 0.9)
    tick:SetWidth(1)
    local tickGlow = bar:CreateTexture(nil, "OVERLAY", nil, 3)
    tickGlow:SetTexture(SPARK_TEX)
    tickGlow:SetBlendMode("ADD")
    tickGlow:SetWidth(8)
    visual.tickShadow, visual.tick, visual.tickGlow = tickShadow, tick, tickGlow

    local spark = bar:CreateTexture(nil, "OVERLAY", nil, 4)
    spark:SetTexture(SPARK_TEX)
    spark:SetBlendMode("ADD")
    spark:SetSize(12, 16)
    visual.spark = spark
    -- 阀值刻度在条宽解析完成前可能被定位到错误位置（宽度 0）。
    -- 依 StatMarks/StatRow.lua:239-242 的「OnSizeChanged 重定位」实证，
    -- 尺寸变化时按缓存的阀值重新计算 tickX。
    bar:SetScript("OnSizeChanged", function()
        if visual.threshold then
            Bars.PositionTicks(visual, visual.threshold)
        end
    end)
    return visual
end

--- 按实际阀值定位三层刻度（D71）。
--- 相对点用 TOPLEFT / BOTTOMLEFT 且 x 相同，避免 TOP/BOTTOM 隐含水平居中
--- 与 CENTER 锚点冲突被解析到条中心（旧版 50% 错位根因）。
--- 实证 StatMarks/StatRow.lua:410-420。
function Bars.PositionTicks(visual, threshold)
    local bar = visual.bar
    local w = bar:GetWidth()
    if not w or w <= 0 then return end
    local scale = math.min(1, threshold / 100)
    local tickX = math.min(math.max(scale * w, 1.5), math.max(1.5, w - 1.5))
    -- D73：刻度高度随条高，但只比条略高出一点（±2），不再用旧版 ±3 的过高偏移
    for _, tex in ipairs({ visual.tickShadow, visual.tick, visual.tickGlow }) do
        tex:ClearAllPoints()
        tex:SetPoint("TOP", bar, "TOPLEFT", tickX, 2)
        tex:SetPoint("BOTTOM", bar, "BOTTOMLEFT", tickX, -2)
        tex:Show()
    end
end

--- 应用样式与布局（配置变更后调用）。
---@param visual table
---@param style string separate / embedded
---@param rowHeight number 文本行高（embedded 时使用，随字号变动）
function Bars.ApplyStyle(visual, style, rowHeight)
    local p = ns.db.profile.bars
    local bar = visual.bar
    local embedded = (style == "embedded")
    -- D68：embedded 时条高度跟随文字行高（字号变动时一起变），不再固定
    local height = embedded and rowHeight or p.height

    bar:ClearAllPoints()
    if embedded then
        -- 上下撑满文本行 → 条高度 = 行高，随字号联动
        bar:SetPoint("TOPLEFT", bar:GetParent(), "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", bar:GetParent(), "BOTTOMRIGHT", 0, 0)
    else
        bar:SetPoint("TOPLEFT", bar:GetParent(), "BOTTOMLEFT", 0, -1)
        bar:SetPoint("TOPRIGHT", bar:GetParent(), "BOTTOMRIGHT", 0, -1)
        bar:SetHeight(height)
    end
    bar:SetStatusBarTexture(Bars.TexturePath(p.texture))
    -- D69：条材质透明度（独立于条背景透明度 bgAlpha）
    local fill = bar:GetStatusBarTexture()
    if fill then fill:SetAlpha(p.textureAlpha) end
    visual.bg:SetAlpha(p.bgAlpha)

    -- D68：火花高度跟随条高度（比条明显高出一截，随条高变化；D73 加大）
    visual.spark:SetSize(12, height + 16)
    -- 刻度的锚点与高度全部由 Bars.Update 每轮按实际阀值重设（D71）；
    -- 这里不预设任何 TOP/BOTTOM 锚点，避免相对点落在条的水平中心造成 50% 错位。
end

--- 刷新一行进度条。
---@param showThreshold boolean 是否画阀值刻度
function Bars.Update(visual, entry, threshold, color, showThreshold)
    local bar = visual.bar
    local p = ns.db.profile.bars
    bar:SetStatusBarColor(ns.ColorRGB(color))

    --[==[ 每个属性独立的进度条范围与填充通道（D57 / D64）
        level : 1 .. GetMaxLevelForExpansionLevel(GetServerExpansionLevel())  ← 值通道（动态，不写死）
        ilvl  : 1 .. Bars.MAX_ITEM_LEVEL(344)                                ← 值通道
        speed : 1% .. 310%                                                    ← 百分比通道
        其它  : 0 .. 100                                                       ← 百分比通道
        实证 Blizzard_APIDocumentation：GetServerExpansionLevel() -> number；
        GetMaxLevelForExpansionLevel(expansionLevel:number) -> maxLevel:number。 ]==]
    local key = entry.key
    local minV, maxV = DEFAULT_MIN, DEFAULT_MAX
    local useValue = false
    if key == "level" then
        minV = 1
        maxV = GetMaxLevelForExpansionLevel(GetServerExpansionLevel())
        useValue = true
    elseif key == "ilvl" then
        minV, maxV = Bars.MIN_ITEM_LEVEL, Bars.MAX_ITEM_LEVEL
        useValue = true
    elseif key == "speed" then
        minV, maxV = Bars.SPEED_MIN_PERCENT, Bars.SPEED_MAX_PERCENT
    end
    bar:SetMinMaxValues(minV, maxV)

    local function Frac(v)
        local f = (v - minV) / (maxV - minV)
        if f < 0 then return 0 end
        if f > 1 then return 1 end
        return f
    end

    if showThreshold and threshold and type(threshold) == "number" and threshold > 0 then
        --[==[ D71：阀值刻度按**实际阀值**定位，修正旧版「都定在 50%」。
            旧版同时给刻度设 TOP(相对 bar TOP)、BOTTOM(相对 bar BOTTOM) 与
            CENTER(相对 bar LEFT) 三个锚点，前两者隐含水平居中，水平方向冲突
            被客户端解析到条中心，于是 28%/40%/16%/16% 全画在 50%。
            现依 StatMarks/StatRow.lua:410-420 实证：用 TOPLEFT/BOTTOMLEFT 作
            相对点、x = 阀值比例 × 条宽，两个锚点水平一致，不产生居中冲突。
            阀值语义为百分比(0–100)，与条自身 min/max 解耦（D64）。 ]==]
        visual.threshold = threshold
        Bars.PositionTicks(visual, threshold)
    else
        visual.threshold = nil
        visual.tickShadow:Hide()
        visual.tick:Hide()
        visual.tickGlow:Hide()
    end

    -- 等级/装等取「值」通道；其余取「百分比」通道，无百分比时满宽。
    local fill, plainFill
    if useValue then
        if entry.valueSecret then
            fill = entry.value
            plainFill = false
        elseif entry.valuePlain and type(entry.value) == "number" then
            fill = entry.value
            plainFill = true
        else
            fill = minV
            plainFill = true
        end
    elseif entry.percentSecret then
        fill = entry.percent
        plainFill = false
    elseif entry.percentPlain and type(entry.percent) == "number" then
        fill = entry.percent
        plainFill = true
    elseif entry.percent == nil and entry.valuePlain and entry.value ~= nil then
        fill = maxV
        plainFill = true
    else
        fill = minV
        plainFill = true
    end
    bar:SetValue(fill)

    if p.spark and plainFill and fill > minV then
        local frac = Frac(fill)
        visual.spark:ClearAllPoints()
        visual.spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * frac, 0)
        visual.spark:Show()
    else
        visual.spark:Hide()
    end
end

function Bars.Hide(visual) visual.bar:Hide() end
function Bars.Show(visual) visual.bar:Show() end
