local _, addon = ...
addon.DelveEntry = addon.DelveEntry or {}
local Entry = addon.DelveEntry
local L = addon.L

-- 条目：仿 WorldQuestTab 的 WQT_QuestTemplate（高 38、左右键分离、主标题 + 子标题 + 右下进度）。
local ENTRY_HEIGHT = 38
local ICON_SIZE = 26
-- 两行文本的固定高度：38 高里 Title 17 + 间距 3 + 子行 16，上下各留 1px。
-- 中文字体行高比 enUS 大，必须显式给高度，否则两行会互相压（2026-10-27 实机截图）。
local TITLE_HEIGHT = 17
local SUBTITLE_HEIGHT = 16
local PROGRESS_ICON_SIZE = 16
local PROGRESS_GAP = 8

-- 图标材质（用户 2026-10-27 定稿）：
--   地下堡              atlas "delves-regular"
--   丰裕地下堡           atlas "delves-bountiful"
--   迷宫                atlas "overworld-active-64x64"
--   仪式场地            atlas "Ritual-Sites-Map-Icon"
--   任务                atlas "QuestNormal"（未接红 / 已接未完成黄 / 已完成绿，走 SetVertexColor）
--   宿敌地下堡 当前赛季   atlas "GM-icon-difficulty-mythicSelected-hover"
--   宿敌地下堡 过期赛季   atlas "GM-icon-difficulty-mythic-disabled"
--   成就                GetAchievementInfo 的文件 ID（DelveCompanion 同源做法）
local ATLAS = {
    regular = "delves-regular", -- 30x30
    bountiful = "delves-bountiful",  -- 25x25
    labyrinth = "overworld-active-64x64",  -- 26x26
    ritual = "Ritual-Sites-Map-Icon",  -- 21x21
    abundance = "UI-EventPoi-abundance",  -- 26x26（第二阶段 9.3 普通态）
    abundanceBountiful = "UI-EventPoi-abundancebountiful",  -- 26x26（第二阶段 9.3 丰饶收获态）
    quest = "QuestNormal",  -- 32x32
    seasonCurrent = "GM-icon-difficulty-mythicSelected-hover",  -- 40x40
    seasonPast = "GM-icon-difficulty-mythic-disabled",  -- 40x40
}

-- 各 atlas 的原始尺寸（用户 2026-10-28 提供）。
-- 原生做法是 SetAtlas(atlas, TextureKitConstants.UseAtlasSize)——按 atlas 原始尺寸显示，
-- 只有少数条目才另外用 fixedWidth/fixedHeight 覆盖（MapLegendFrame.lua:105-108）。
-- 之前这里统一 SetSize(ICON_SIZE) 把所有 atlas 都拉成 26x26，21x21 的仪式场地被放大，
-- 看上去就比别的图标大（用户 2026-10-28）。现在改成按原始尺寸显示，
-- 超过 ICON_SIZE 的才缩回来，否则会撑破条目布局（ICON_SIZE 同时决定标题的左边距）。
local ATLAS_SIZE = {
    [ATLAS.regular] = 30,
    [ATLAS.bountiful] = 25,
    [ATLAS.labyrinth] = 26,
    [ATLAS.ritual] = 21,
    [ATLAS.abundance] = 26,
    [ATLAS.abundanceBountiful] = 26,
    [ATLAS.quest] = 32,
    [ATLAS.seasonCurrent] = 40,
    [ATLAS.seasonPast] = 40,
}

local USE_ATLAS_SIZE = (TextureKitConstants and TextureKitConstants.UseAtlasSize) or true

--- 按原生的「先用 atlas 原始尺寸」贴图，太大再压回 ICON_SIZE。
local function ApplyAtlas(texture, atlas)
    texture:SetTexture(nil)
    texture:SetAtlas(atlas, USE_ATLAS_SIZE)
    local native = ATLAS_SIZE[atlas]
    if native and native > ICON_SIZE then
        texture:SetSize(ICON_SIZE, ICON_SIZE)
    end
    texture:SetVertexColor(1, 1, 1)
    -- 池复用复位：避免上一轮未激活仪式场地的灰态残留（第二阶段 9.2）。
    texture:SetDesaturated(false)
end

local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local GRAY = { 0.72, 0.72, 0.72 }
local BLUE = { 0.4, 0.7, 1 }
local GREEN = { 0.1, 0.9, 0.1 } -- 丰饶收获 [丰饶收获] 标签 / 仪式场地「激活中」（第二阶段 9.1.1）
local LABYRINTH_GOLD = { 0.9, 0.8, 0.5 } -- E6CC80：迷宫 tag 与 tooltip（第二阶段 9.1.1）
local ABUNDANCE_ACTIVE = { 0.1, 0.1, 0.9 } -- #1919E6：丰饶收获子标题中自身激活的专业（第二阶段 9.3.4）
local PURPLE = { 0.75, 0.35, 1 } -- 仪式场地专用紫
local ORANGE = { 1, 0.5, 0 }
local RED = { 1, 0.25, 0.2 }
local YELLOW = { 1, 0.85, 0.2 }

--- 丰饶剩余时间格式化（第二阶段 9.3.5）：秒 → 「x天x小时」/「x小时x分」/「x分」。
local function FormatTimeLeft(secs)
    secs = secs or 0
    local d = math.floor(secs / 86400)
    local h = math.floor((secs % 86400) / 3600)
    local m = math.floor((secs % 3600) / 60)
    if d > 0 then return string.format("%d天%d小时", d, h) end
    if h > 0 then return string.format("%d小时%d分", h, m) end
    return string.format("%d分", m)
end

local function Colorize(text, color)
    return string.format("|cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, text)
end

local function SetEntryIcon(texture, entry)
    local atlas
    if entry.kind == "ritual" then
        atlas = ATLAS.ritual
    elseif entry.kind == "labyrinth" then
        atlas = ATLAS.labyrinth
    elseif entry.kind == "nemesis" then
        -- 宿敌从普通地下堡拆出来单独给图标（用户 2026-10-28）：
        -- 当前赛季用高亮态，过期赛季用按下态。这两个 atlas 原先放在子标题里，
        -- 现在子标题改成整行文本，赛季就由这里的主图标表达。
        atlas = addon.Stats:IsCurrentNemesis(entry) and ATLAS.seasonCurrent or ATLAS.seasonPast
    elseif entry.kind == "abundance" then
        -- 第二阶段 9.3：丰饶收获态用带 bountiful 的 atlas，普通态用普通 atlas（丰饶不暗化）。
        atlas = entry.abundanceActive and ATLAS.abundanceBountiful or ATLAS.abundance
    elseif entry.bountiful then
        atlas = ATLAS.bountiful
    else
        atlas = ATLAS.regular
    end
    ApplyAtlas(texture, atlas)
end

--- 一次性构建条目结构。
function Entry:Build(button)
    if button.adeBuilt then return end
    button.adeBuilt = true

    button:SetHeight(ENTRY_HEIGHT)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    -- ⚠ 锚在占位格的中心，不能用单锚点 LEFT：图标现在按 atlas 原始尺寸显示（21~26 不等），
    -- 单锚点在尺寸变化后不再保证垂直居中，仪式场地 21x21 看着就偏左上（用户 2026-10-28）。
    -- 占位格中心 = 左边距 6 + ICON_SIZE/2，标题的左边距仍按 6 + ICON_SIZE + 4 算，不受影响。
    icon:SetPoint("CENTER", button, "LEFT", 6 + ICON_SIZE / 2, 0)
    button.Icon = icon

    -- 两行文本照 WQT_QuestTemplate 的两段结构（CenterContent 纵向 flex + spacing 3）：
    -- Title 占上半、justifyV BOTTOM，子行贴它下方、justifyV TOP。给 FontString 显式高度，
    -- 行高随字体变化也不会互相压。锚点全部走「标题的 BOTTOMLEFT」，不再依赖图标位置。
    local title = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetJustifyH("LEFT")
    title:SetJustifyV("BOTTOM")
    title:SetMaxLines(1)
    title:SetWordWrap(false)
    title:SetHeight(TITLE_HEIGHT)
    title:SetPoint("TOPLEFT", button, "TOPLEFT", 6 + ICON_SIZE + 4, -1)
    -- 主标题只留右边距（WQT 的 CenterContent.flexSize=1 也是「先占满再让位」）：
    -- 之前预留 -110 给右下角状态区，导致长名字被截成「金多赞的迷宫 - 永…」。
    -- 状态区在子行右侧，与主标题不同行，不需要主标题让宽度。
    title:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -1)
    button.Title = title

    -- 子标题只有一段（左对齐），宽度在 Update 里按状态区实际宽度回填。
    local subtitleLeft = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    subtitleLeft:SetJustifyH("LEFT")
    subtitleLeft:SetJustifyV("TOP")
    subtitleLeft:SetMaxLines(1)
    subtitleLeft:SetWordWrap(false)
    subtitleLeft:SetHeight(SUBTITLE_HEIGHT)
    subtitleLeft:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    button.SubtitleLeft = subtitleLeft

    -- 宿敌专用三段：`[宿敌] MN S1` → 赛季图标 → BOSS 名。
    -- 用户 2026-10-27：图标要加在 BOSS 名称前面，而不是塞进右下角状态区。
    local subtitleSeasonIcon = button:CreateTexture(nil, "ARTWORK")
    subtitleSeasonIcon:SetSize(SUBTITLE_HEIGHT, SUBTITLE_HEIGHT)
    subtitleSeasonIcon:Hide()
    button.SubtitleSeasonIcon = subtitleSeasonIcon

    local subtitleBoss = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    subtitleBoss:SetJustifyH("LEFT")
    subtitleBoss:SetJustifyV("TOP")
    subtitleBoss:SetMaxLines(1)
    subtitleBoss:SetWordWrap(false)
    subtitleBoss:SetHeight(SUBTITLE_HEIGHT)
    subtitleBoss:Hide()
    button.SubtitleBoss = subtitleBoss

    -- 字号比 WQT 小 1 号（用户 2026-10-27）：主标题 12→11、子标题 10→9。
    -- 取实际字体族与 flags 再减 1，避免换字体对象丢掉阴影。
    -- 分组标题**不缩字号**，所以把主标题原始字号存下来，UpdateHeader 时还原。
    local titleFont, titleSize, titleFlags = title:GetFont()
    if titleFont and titleSize then
        button.TitleBaseFont = { titleFont, titleSize, titleFlags }
    end
    for _, fontString in ipairs({ title, subtitleLeft, subtitleBoss }) do
        local fontPath, size, flags = fontString:GetFont()
        if fontPath and size then fontString:SetFont(fontPath, size - 1, flags) end
    end

    -- 右下角状态区：赛季图标 → 任务图标 → 成就图标 x/x（最多两组）。
    -- 整体右对齐、宽度按内容收缩，与子标题左段互不干涉。
    local progress = CreateFrame("Frame", nil, button)
    progress:SetHeight(PROGRESS_ICON_SIZE)
    progress:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 2)
    progress:SetWidth(1)
    button.Progress = progress

    local seasonIcon = progress:CreateTexture(nil, "ARTWORK")
    seasonIcon:SetSize(PROGRESS_ICON_SIZE, PROGRESS_ICON_SIZE)
    seasonIcon:Hide()
    button.SeasonIcon = seasonIcon

    local questIcon = progress:CreateTexture(nil, "ARTWORK")
    questIcon:SetSize(PROGRESS_ICON_SIZE, PROGRESS_ICON_SIZE)
    questIcon:SetAtlas(ATLAS.quest, false)
    questIcon:Hide()
    button.QuestIcon = questIcon

    button.AchPairs = {}
    for index = 1, 2 do
        local pair = {}
        pair.icon = progress:CreateTexture(nil, "ARTWORK")
        pair.icon:SetSize(PROGRESS_ICON_SIZE, PROGRESS_ICON_SIZE)
        pair.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        pair.icon:Hide()
        pair.text = progress:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        pair.text:SetJustifyH("LEFT")
        pair.text:SetText("")
        button.AchPairs[index] = pair
    end

    local separator = button:CreateTexture(nil, "BACKGROUND")
    separator:SetHeight(2)
    separator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 0)
    separator:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 0)
    separator:SetColorTexture(0, 0, 0, 0.14)
    button.Separator = separator

    -- 悬停高亮：完整复刻 WQT——模板 `WQT_QuestHighlightTemplate`（WorldQuestTab.xml:24-62）
    -- + 实例 `Highlight`（:359-368）+ `WQT_ListButtonMixin`（WorldQuestTab.lua:1150-1153、1206-1222）。
    -- 结构是「一个子 Frame + ARTWORK 层三张纹理」：Left / Right 各 46 宽，Center 横铺填中间。
    -- ⚠ texcoord 的 top/bottom 必须用 **实例** 的 KeyValue（0.1748046875 / 0.2197265625）。
    --   模板里的 topCoord/bottomCoord 只是默认值 0/1，实例会覆盖——按默认值写会取到整幅图集，
    --   高亮变成一团乱（2026-10-27 实测：我第一版就这么改过，比原来更糟）。
    local HL_OUTER_LEFT, HL_INNER_LEFT = 0.498046875, 0.591796875
    local HL_INNER_RIGHT, HL_OUTER_RIGHT = 0.814453125, 0.90625
    local HL_TOP, HL_BOTTOM = 0.1748046875, 0.2197265625

    -- 实例是 `hidden="true"` + alpha 0.75（:359），锚到 TrackedBorder（:365-366，即 x=1 / x=-1）
    local highlight = CreateFrame("Frame", nil, button)
    highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 1, 0)
    highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
    highlight:SetAlpha(0.75)
    highlight:Hide()
    -- `WQT_ListButtonMixin:OnLoad`（:1152）：高亮帧级别 +2，明确压在标题文字之上。
    -- 少了这句，三张纹理与文字同层、绘制顺序随创建顺序漂，看起来就是「乱」。
    highlight:SetFrameLevel(button:GetFrameLevel() + 2)

    -- 三张纹理都照模板用锚点定尺寸（宽 46 / 满高），不用 SetSize，行高变化时自动跟随。
    local hlLeft = highlight:CreateTexture(nil, "ARTWORK")
    hlLeft:SetTexture("Interface\\PETBATTLES\\PETJOURNAL")
    hlLeft:SetTexCoord(HL_OUTER_LEFT, HL_INNER_LEFT, HL_TOP, HL_BOTTOM)
    hlLeft:SetPoint("TOPLEFT", highlight, "TOPLEFT")
    hlLeft:SetPoint("BOTTOMRIGHT", highlight, "BOTTOMLEFT", 46, 0)

    local hlRight = highlight:CreateTexture(nil, "ARTWORK")
    hlRight:SetTexture("Interface\\PETBATTLES\\PETJOURNAL")
    hlRight:SetTexCoord(HL_INNER_RIGHT, HL_OUTER_RIGHT, HL_TOP, HL_BOTTOM)
    hlRight:SetPoint("TOPRIGHT", highlight, "TOPRIGHT")
    hlRight:SetPoint("BOTTOMLEFT", highlight, "BOTTOMRIGHT", -46, 0)

    -- ⚠ 不要给 Center 加 SetHorizTile——WQT 的 Center 只有两个锚点（WorldQuestTab.xml:47-52）。
    -- 开了 HorizTile 会按 texcoord 宽度**平铺**而不是拉伸：中间那块图集是横向渐变的，
    -- 平铺后就出现明暗重复的暗块，把两端的蓝色高亮框截成两段（用户 2026-10-28 实测）。
    local hlMiddle = highlight:CreateTexture(nil, "ARTWORK")
    hlMiddle:SetTexture("Interface\\PETBATTLES\\PETJOURNAL")
    hlMiddle:SetTexCoord(HL_INNER_LEFT, HL_INNER_RIGHT, HL_TOP, HL_BOTTOM)
    hlMiddle:SetPoint("TOPLEFT", hlLeft, "TOPRIGHT")
    hlMiddle:SetPoint("BOTTOMRIGHT", hlRight, "BOTTOMLEFT")

    -- 命名与 WQT 一致（`self.Highlight`），显隐照 OnEnter / OnLeave（:1208 / :1222）。
    button.Highlight = highlight

    button:SetScript("OnClick", Entry.OnClick)
    button:SetScript("OnEnter", Entry.OnEnter)
    button:SetScript("OnLeave", Entry.OnLeave)
end

--- 主标题：`{名称（金）}{ - 所在地图（灰白）}`。
local function BuildTitle(entry)
    local text = Colorize(entry.name or "", GOLD)
    if entry.zoneName and entry.zoneName ~= "" then
        text = text .. Colorize(" - " .. entry.zoneName, GRAY)
    end
    return text
end

local SHORT_EXPANSION = {
    tww = "TWW",
    midnight = "MN",
}

--- 子标题左段：返回富文本 + 赛季图标 atlas（宿敌专用，其余 nil）。
-- 空格规则（用户 2026-10-27）：`[迷宫|丰裕|宿敌]` 与后文之间固定一个半角空格；
-- 没有 tag 时故事变种文本顶格（不补前导空格）。
-- 返回 `左段文本, 宿敌 BOSS 名（可 nil）, 赛季图标 atlas（可 nil）`。
-- 宿敌拆三段是为了把赛季图标插在 tag 与 BOSS 名之间（用户 2026-10-27）。
local function BuildSubtitle(entry)
    if entry.kind == "nemesis" then
        local short = SHORT_EXPANSION[entry.expansion] or ""
        local boss = (entry.bossKey and L[entry.bossKey]) or ""
        local current = addon.Stats:IsCurrentNemesis(entry)
        local color = current and ORANGE or WHITE
        -- 合成一行：`{资料片} {赛季} 宿敌: {BOSS}`（用户 2026-10-28）。
        -- 之前拆成「[宿敌] 缩写 赛季」+ 赛季图标 + BOSS 名三段，而 BOSS 名的本地化键
        -- NEMESIS_BOSS_* 在语言文件里根本没有，第三段一直为空，看上去就像子标题被截断。
        -- 现在合成一段；赛季改由主图标（SetEntryIcon）表达，这里不再放图标。
        -- BOSS 名拿不到时不带冒号，避免出现一个光秃秃的「宿敌:」。
        local tag = string.format("%s S%d %s", short, entry.season or 0, L["NEMESIS"])
        if boss ~= "" then tag = tag .. ": " .. boss end
        return Colorize(tag, color), nil, nil
    end

    if entry.kind == "abundance" then
        -- 用户 2026-10-30：赋色的判据是「**自身专业是否在 professions 中**」，
        -- 不再用静态的 activeProfession（那会把玩家根本不会学的专业也标成激活色）；
        -- 且**只在「丰饶收获」状态才着色**，普通状态的丰饶区域三个专业一律保持常色。
        -- 比对走专业 ID、显示名走 locale，因此不同语种客户端都成立。
        local parts = entry.professions or {}
        local list = {}
        for _, professionID in ipairs(parts) do
            local name = addon.Professions and addon.Professions:GetProfessionName(professionID)
                or tostring(professionID)
            local matchesOwn = addon.Professions and addon.Professions:HasProfession(professionID)
            if entry.abundanceActive and matchesOwn then
                list[#list + 1] = Colorize(name, ABUNDANCE_ACTIVE)
            else
                list[#list + 1] = Colorize(name, WHITE)
            end
        end
        local nodes = Colorize(L["ABUNDANCE_NODES"] .. ": " .. table.concat(list, ", "), WHITE)
        if entry.abundanceActive then
            return Colorize("[" .. L["ABUNDANCE_HARVEST"] .. "] ", GREEN) .. nodes, nil, nil
        end
        return nodes, nil, nil
    end

    local story = (addon.db and addon.db.showStoryVariant == false) and nil or entry.storyVariant
    if story == "" then story = nil end

    local tag, tagColor
    if entry.kind == "labyrinth" then
        tag, tagColor = "[" .. L["LABYRINTH"] .. "]", LABYRINTH_GOLD
    elseif entry.kind == "ritual" then
        -- 激活显示「[仪式场地] 已激活」（已激活绿色），未激活显示「*未激活*」（灰白）。
        if entry.ritualActive then
            return Colorize("[" .. L["RITUAL_SITE"] .. "] ", PURPLE)
                .. Colorize(L["RITUAL_ACTIVE"], GREEN), nil, nil
        end
        return Colorize("*" .. L["RITUAL_INACTIVE"] .. "*", GRAY), nil, nil
    elseif entry.bountiful then
        tag, tagColor = "[" .. L["BOUNTIFUL"] .. "]", BLUE
    end

    local text = ""
    if tag then
        text = Colorize(tag, tagColor)
    end
    if story then
        -- 故事变种在成就「{地下堡}故事」里未完成时标红（用户 2026-10-28）。
        local storyColor = WHITE
        if entry.achStory and addon.Stats then
            if addon.Stats:IsStoryVariantCompleted(entry.achStory, story) == false then
                storyColor = RED
            end
        end
        -- 第二阶段 9.4.4：故事变种统一加前缀「故事:」（列表与 tooltip 共用 L["STORY_PREFIX"]）。
        local storyText = Colorize(L["STORY_PREFIX"] .. ": " .. story, storyColor)
        text = (text == "") and storyText or (text .. " " .. storyText)
    end
    return text, nil
end

--- 右下角排布：从左到右依次追加，容器宽度按实际占用收缩，返回占用宽度。
-- `showTasks` / `showAchievements` 分别控制任务图标与成就块（用户 2026-10-27 要求可单独关）；
-- 都关掉时这里返回 0，调用方会把整个 Progress 收成 0 宽。
local function LayoutProgress(button, questColor, achievements, seasonAtlas, showTasks, showAchievements)
    local progress = button.Progress
    local x = 0

    local seasonIcon = button.SeasonIcon
    if seasonAtlas then
        seasonIcon:ClearAllPoints()
        seasonIcon:SetPoint("LEFT", progress, "LEFT", 0, 0)
        seasonIcon:SetAtlas(seasonAtlas, false)
        seasonIcon:Show()
        x = x + PROGRESS_ICON_SIZE + 4
    else
        seasonIcon:Hide()
    end

    local questIcon = button.QuestIcon
    if questColor and showTasks ~= false then
        questIcon:ClearAllPoints()
        questIcon:SetPoint("LEFT", progress, "LEFT", x, 0)
        questIcon:SetVertexColor(questColor[1], questColor[2], questColor[3])
        questIcon:Show()
        x = x + PROGRESS_ICON_SIZE + PROGRESS_GAP
    else
        questIcon:Hide()
    end

    for index, pair in ipairs(button.AchPairs) do
        local data = (showAchievements ~= false) and achievements[index] or nil
        if data then
            pair.icon:ClearAllPoints()
            pair.icon:SetPoint("LEFT", progress, "LEFT", x, 0)
            -- 池复用会残留上一次的着色/透明度，成就图标"发暗看不清"多半是这个。
            pair.icon:SetVertexColor(1, 1, 1)
            pair.icon:SetAlpha(1)
            pair.icon:SetTexture(data.icon)
            pair.icon:SetShown(true)
            pair.text:ClearAllPoints()
            pair.text:SetPoint("LEFT", pair.icon, "RIGHT", 2, 0)
            pair.text:SetText(data.text)
            pair.text:SetTextColor(data.color[1], data.color[2], data.color[3])
            x = x + PROGRESS_ICON_SIZE + 2 + math.max(1, pair.text:GetStringWidth())
            if index < #button.AchPairs and achievements[index + 1] then
                x = x + PROGRESS_GAP
            end
        else
            pair.icon:Hide()
            pair.text:SetText("")
        end
    end

    progress:SetWidth(math.max(1, x))
    return x
end

--- 任务图标颜色：未接红、已接未完成黄、已完成绿；无任务数据时不显示。
local function QuestColorFor(entry)
    local state = addon.Stats:GetCallState(entry.callQuestID)
    if state == nil then return nil end
    if state == "done" then return GREEN end
    if state == "turnin" or state == "active" then return YELLOW end
    return RED
end

--- 成就对：宿敌只有一个（nemesisSolo），其余取宝箱 + 故事两个。
local function CollectAchievements(entry)
    local result = {}
    local function push(achID)
        if not achID then return end
        local done, total, complete = addon.Stats:GetAchievementProgress(achID)
        if not total or total <= 0 then return end
        local icon = addon.Stats:GetAchievementIcon(achID)
        if not icon then return end
        result[#result + 1] = {
            icon = icon,
            text = string.format("%d/%d", done or 0, total),
            -- 列表里的成就块沿用原来的配色。tooltip 另按「未开始红 / 进行中黄 /
            -- 已完成绿」取色（用户 2026-10-28），两处要求不同，所以分开存。
            color = complete and GREEN or WHITE,
            name = addon.Stats:GetAchievementName(achID) or tostring(achID),
            stateColor = complete and GREEN or ((done or 0) > 0 and YELLOW or RED),
        }
    end
    if entry.kind == "nemesis" then
        push(entry.achNemesis)
    else
        push(entry.achChest)
        push(entry.achStory)
    end
    return result
end

function Entry:Update(button, entry)
    Entry:Build(button)
    button.entry = entry
    -- 按钮池在分组标题与条目之间复用，脚本每次都要重新挂上。
    button:SetScript("OnClick", Entry.OnClick)
    button:SetScript("OnEnter", Entry.OnEnter)
    button:SetScript("OnLeave", Entry.OnLeave)

    button.Icon:Show()
    SetEntryIcon(button.Icon, entry)
    -- 第二阶段 9.2：未激活的仪式场地图标暗化（SetDesaturated 与 AddMaskTexture 两套机制可叠加）。
    -- ApplyAtlas 已复位 false，这里只在未激活仪式场地置真。
    if entry.kind == "ritual" and not entry.ritualActive then
        button.Icon:SetDesaturated(true)
    end
    button.Separator:Show()
    -- 池复用：高亮默认是隐藏的（只有 OnEnter 会显示），进来先清一次残留，
    -- 否则上一次悬停没走 OnLeave 时会留着一条高亮。
    if button.Highlight then button.Highlight:Hide() end

    -- ⚠ 池复用第一件事：把分组标题留下的材质关掉。
    -- 否则 HeaderBG（260x26 的 ObjectiveTracker 标题底图）会盖在本条目上，
    -- 就是用户看到的「分组标题背景跑到了别的条目里」。
    if button.HeaderBG then button.HeaderBG:Hide() end
    if button.HeaderMinimize then button.HeaderMinimize:Hide() end

    -- ⚠ 池复用：UpdateHeader 会改 Title 的锚与 justifyV，这里必须整段重建，
    -- 否则新旧锚点叠加 → 文本错位重叠（2026-10-27）。
    button.Title:ClearAllPoints()
    button.Title:SetPoint("TOPLEFT", button, "TOPLEFT", 6 + ICON_SIZE + 4, -1)
    button.Title:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -1)
    button.Title:SetJustifyH("LEFT")
    button.Title:SetJustifyV("BOTTOM")
    button.Title:SetWordWrap(false)
    button.Title:SetHeight(TITLE_HEIGHT)
    button.Title:SetText(BuildTitle(entry))

    local subtitle, bossText, seasonAtlas = BuildSubtitle(entry)
    button.SubtitleLeft:SetJustifyV("TOP")
    button.SubtitleLeft:SetWordWrap(false)
    button.SubtitleLeft:SetHeight(SUBTITLE_HEIGHT)
    button.SubtitleLeft:SetText(subtitle)

    -- 状态区先排（尺寸由内容决定），再按它的实际宽度回填子标题左段宽度，
    -- 这样左段与右侧状态互不干涉，也不会压住主标题（主标题是独立一行）。
    -- 赛季图标已移到子行内（宿敌），这里不再传给状态区。
    local progressWidth = 0
    -- 「显示进度图标」总开关已于 2026-10-28 删除（与任务、成就两个开关功能重叠），
    -- 现在直接由那两个开关决定：都不开就整个状态区隐藏。
    if addon.db and (addon.db.showTasks or addon.db.showAchievements) then
        button.Progress:Show()
        progressWidth = LayoutProgress(button, QuestColorFor(entry), CollectAchievements(entry), nil,
            addon.db.showTasks, addon.db.showAchievements)
    else
        button.Progress:Hide()
        button.SeasonIcon:Hide()
    end

    -- 宿敌：`[宿敌] MN S1` 后接赛季图标，再接 BOSS 名（用户 2026-10-27：图标在 BOSS 名前）。
    if bossText and seasonAtlas then
        button.SubtitleSeasonIcon:ClearAllPoints()
        button.SubtitleSeasonIcon:SetPoint("LEFT", button.SubtitleLeft, "RIGHT", 3, 0)
        button.SubtitleSeasonIcon:SetAtlas(seasonAtlas, false)
        button.SubtitleSeasonIcon:Show()
        button.SubtitleBoss:ClearAllPoints()
        button.SubtitleBoss:SetPoint("LEFT", button.SubtitleSeasonIcon, "RIGHT", 3, 0)
        button.SubtitleBoss:SetText(bossText)
        button.SubtitleBoss:Show()
    else
        button.SubtitleSeasonIcon:Hide()
        button.SubtitleBoss:Hide()
        button.SubtitleBoss:SetText("")
    end

    button.SubtitleLeft:ClearAllPoints()
    button.SubtitleLeft:SetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -3)
    if not (bossText and seasonAtlas) then
        button.SubtitleLeft:SetPoint("RIGHT", button, "RIGHT", -(progressWidth > 1 and progressWidth + 12 or 8), 0)
    end
end

function Entry:OnClick(mouseButton)
    local entry = self.entry
    if not entry then return end
    if mouseButton == "RightButton" then
        -- r003 重设计：右键统一委托 /way 占用者（原生/TomTom 修饰键区分已删）。
        addon.MapPanel:SetWaypointAt(entry)
        return
    end
    addon.MapPanel:ShowOnMap(entry)
end

function Entry:OnEnter()
    local entry = self.entry
    if not entry then return end
    -- 悬停高亮由脚本控制（WQT 同款）。分组标题的 entry 是 nil，上面已经 return，
    -- 所以组标题永远不会亮；条目这里才显示。
    if self.Highlight then self.Highlight:Show() end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.name or "", 1, 0.82, 0)

    if entry.bountiful then
        GameTooltip:AddLine(L["BOUNTIFUL"], 0.4, 0.7, 1)
    end
    if entry.kind == "abundance" then
        if entry.abundanceActive then
            GameTooltip:AddLine(L["ABUNDANCE_HARVEST"], GREEN[1], GREEN[2], GREEN[3])
        else
            GameTooltip:AddLine(L["ABUNDANCE"], GRAY[1], GRAY[2], GRAY[3])
        end
        if entry.timeLeft and (not addon.db or addon.db.showTimeLeft ~= false) then
            GameTooltip:AddLine(L["TIME_LEFT"] .. ": " .. FormatTimeLeft(entry.timeLeft), 0.7, 0.7, 0.7)
        end
    end
    if entry.kind == "labyrinth" then
        GameTooltip:AddLine(L["LABYRINTH"], LABYRINTH_GOLD[1], LABYRINTH_GOLD[2], LABYRINTH_GOLD[3])
    elseif entry.kind == "ritual" then
        GameTooltip:AddLine(L["RITUAL_SITE"], PURPLE[1], PURPLE[2], PURPLE[3])
        -- 第二阶段 9.2：tooltip 同步激活 / 未激活文案。
        if entry.ritualActive then
            GameTooltip:AddLine(L["RITUAL_ACTIVE"], GREEN[1], GREEN[2], GREEN[3])
        else
            GameTooltip:AddLine(L["RITUAL_INACTIVE"], GRAY[1], GRAY[2], GRAY[3])
        end
    end
    if entry.zoneName then
        GameTooltip:AddLine(entry.zoneName, 0.7, 0.7, 0.7)
    end
    if entry.kind == "nemesis" then
        local boss = (entry.bossKey and L[entry.bossKey]) or ""
        -- `]` 与资料片缩写之间一个半角空格，与子标题保持一致（用户 2026-10-27）。
        GameTooltip:AddLine(string.format("[%s] %s S%d", L["NEMESIS"],
            SHORT_EXPANSION[entry.expansion] or "", entry.season or 0), 1, 0.5, 0)
        if boss ~= "" then GameTooltip:AddLine(boss, 1, 1, 1) end
    elseif entry.storyVariant then
        -- 前缀黄色；内容按完成状态取色（未完成红），未完成时同行右侧追加红色「未完成」
        -- （用户 2026-10-28）。
        local storyDone = entry.achStory and addon.Stats
            and addon.Stats:IsStoryVariantCompleted(entry.achStory, entry.storyVariant)
        local storyColor = (storyDone == false) and RED or WHITE
        -- 第二阶段 9.4.4：tooltip 同样用「故事:」前缀（与列表子标题一致）。
        local left = Colorize(L["STORY_PREFIX"] .. ": ", YELLOW)
            .. Colorize(entry.storyVariant, storyColor)
        if storyDone == false then
            GameTooltip:AddDoubleLine(left, Colorize(L["STORY_VARIANT_INCOMPLETE"], RED),
                1, 1, 1, 1, 1, 1)
        else
            GameTooltip:AddLine(left, 1, 1, 1)
        end
    end

    -- 左「成就: {成就名}」右「x/x」，两侧同色，按进度红/黄/绿（用户 2026-10-28）。
    -- AddDoubleLine 的行颜色会被文本里的 |c 覆盖，所以这里只传白色兜底。
    for _, data in ipairs(CollectAchievements(entry)) do
        GameTooltip:AddDoubleLine(
            Colorize(L["PROGRESS_ACHIEVEMENT"] .. ": ", YELLOW) .. Colorize(data.name or "", data.stateColor),
            Colorize(data.text, data.stateColor),
            1, 1, 1, 1, 1, 1)
    end

    local state = addon.Stats:GetCallState(entry.callQuestID)
    if state then
        -- 左列固定是任务名，右列才是状态：未接红 / 已接未完成黄 / 已完成绿
        -- （用户 2026-10-28）。
        local label, stateColor
        if state == "done" then
            label, stateColor = L["QUEST_STATE_DONE"], GREEN
        elseif state == "turnin" then
            label, stateColor = L["QUEST_STATE_ACCEPTED"], YELLOW
        else
            label, stateColor = L["QUEST_STATE_NOT_ACCEPTED"], RED
        end
        GameTooltip:AddDoubleLine(
            Colorize(L["PROGRESS_QUEST"] .. ": ", YELLOW) .. Colorize(L["PROGRESS_CALL"], stateColor),
            Colorize(label, stateColor),
            1, 1, 1, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["HINT_LEFT_CLICK"], 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["HINT_RIGHT_CLICK"], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function Entry:OnLeave()
    if self.Highlight then self.Highlight:Hide() end
    GameTooltip:Hide()
end

--- 资料片分组标题：整行背景 + 展开/收起，复用同一条目按钮池。
-- 背景与折叠按钮照暴雪原生 ObjectiveTracker 模块标题（Blizzard_ObjectiveTrackerModule.xml:4-51）：
--   背景 UI-QuestTracker-Secondary-Objective-Header（useAtlasSize，锚 CENTER，260x26）
--   按钮 ui-questtrackerbutton-secondary-collapse / -expand（16x16，锚 RIGHT 1）
-- 展开状态用 collapse 图标、收起状态用 expand 图标（原生 Module.lua:790-800 同逻辑）。
function Entry:UpdateHeader(button, title, count, expanded)
    Entry:Build(button)
    button.entry = nil
    button.Icon:Hide()
    button.SubtitleLeft:SetText("")
    button.SubtitleBoss:SetText("")
    button.SubtitleBoss:Hide()
    button.SubtitleSeasonIcon:Hide()
    button.Progress:Hide()
    button.SeasonIcon:Hide()
    button.QuestIcon:Hide()
    for _, pair in ipairs(button.AchPairs) do
        pair.icon:Hide()
        pair.text:SetText("")
    end
    button.Separator:Hide()
    -- 分组标题不要行高亮：三张纹理一律隐藏。它们现在是 ARTWORK 层（WQT 同款），
    -- 只有 OnEnter 会 Show，而 OnEnter 开头就是 `if not self.entry then return end`、
    -- 组标题的 entry 为 nil → 永远不亮。这里只是清掉池复用带过来的残留。
    if button.Highlight then button.Highlight:Hide() end

    if not button.HeaderBG then
        local background = button:CreateTexture(nil, "BACKGROUND")
        -- useAtlasSize=true：保持图集原始 260x26，不再拉伸到行高 38（之前尺寸失真的原因）。
        background:SetAtlas("UI-QuestTracker-Secondary-Objective-Header", true)
        background:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.HeaderBG = background

        local minimize = button:CreateTexture(nil, "ARTWORK")
        minimize:SetSize(16, 16)
        minimize:SetPoint("RIGHT", button, "RIGHT", -4, 0)
        button.HeaderMinimize = minimize
    end
    -- ⚠ 池复用：条目分支会把这两个 Hide 掉，这里必须显式 Show，
    -- 否则「先当过条目的按钮再当分组标题」时背景就没了（用户 2026-10-27：时有时无）。
    button.HeaderBG:Show()
    button.HeaderMinimize:Show()
    button.HeaderMinimize:SetAtlas(expanded and "ui-questtrackerbutton-secondary-collapse"
        or "ui-questtrackerbutton-secondary-expand", true)

    -- 分组标题用原始字号（缩小 1 号只针对条目）
    if button.TitleBaseFont then
        button.Title:SetFont(button.TitleBaseFont[1], button.TitleBaseFont[2], button.TitleBaseFont[3])
    end

    button.Title:ClearAllPoints()
    button.Title:SetPoint("LEFT", button, "LEFT", 16, 0)
    button.Title:SetPoint("RIGHT", button, "RIGHT", -26, 0)
    button.Title:SetJustifyH("CENTER")
    button.Title:SetJustifyV("MIDDLE")
    button.Title:SetHeight(ENTRY_HEIGHT)
    button.Title:SetText(Colorize(string.format("%s (%d)", title or "", count or 0), GOLD))

    button:SetScript("OnClick", nil)
    button:SetScript("OnEnter", nil)
    button:SetScript("OnLeave", nil)
end


