-- ade_Demo 控件画廊：验证库独立形态、双布局、主题色、逐项重置、行拖拽与原生 Atlas 图标。
local _, DEMO = ...
local AF, L, db = DEMO.AF, DEMO.L, DEMO.db
if not AF then return end

local frame, layoutMode = nil, "multi"

local function Get(key, fallback)
    local v = db.settings.demo[key]
    if v == nil then return fallback end
    return v
end
local function Set(key, value) db.settings.demo[key] = value end

local function BuildBasic(page)
    local y = 0
    local title = AF.Widget.Text.SectionTitle(page, L["DEMO_SECTION_BASIC"], AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0); y = y + 32

    local variants = {
        { "normal", AF.L["AF_OK"] }, { "primary", AF.L["AF_NEW"] },
        { "accent", AF.L["AF_COPY"] }, { "red", AF.L["AF_DELETE"] },
    }
    local x = 0
    for _, v in ipairs(variants) do
        local b = AF.Widget.Button.Create(page, { text = v[2], width = 90, variant = v[1] })
        AF.Widget.Button.FitButton(b, 90, 22)
        b:SetPoint("TOPLEFT", x, -y); x = x + b:GetWidth() + 8
    end
    y = y + 32

    local cb = AF.Widget.Checkbox.Create(page, { label = L["DEMO_LABEL_ENABLED"], checked = Get("enabled", true),
        onChange = function(v) Set("enabled", v) end })
    cb:SetPoint("TOPLEFT", 0, -y); y = y + 28
    local sw = AF.Widget.Switch.Create(page, { label = L["DEMO_LABEL_ENABLED"], checked = Get("enabled", true) })
    sw:SetPoint("TOPLEFT", 0, -y); y = y + 28

    local color = AF.Widget.Color.Create(page, {
        label = L["DEMO_LABEL_COLOR"],
        color = db.settings.globalColor,
        onChange = function(r, g, b) DEMO.SetGlobalColor({ red = r, green = g, blue = b }) end,
    })
    color:SetPoint("TOPLEFT", 6, -y); y = y + 30

    -- 图标三态 + badge
    local shapes = { "square", "round", "rounded" }
    for i, shape in ipairs(shapes) do
        local icon = AF.Widget.Icon.Create(page, {
            size = 40, icon = "Interface\\Icons\\INV_Misc_QuestionMark", shape = shape,
            badge = i == 1 and { icon = { atlas = "GM-icon-visible" }, scale = 0.5 } or nil,
        })
        icon:SetPoint("TOPLEFT", (i - 1) * 56, -y)
    end
    local fileID = AF.Widget.Icon.Create(page, { size = 40, icon = 134400, shape = "round" })
    fileID:SetPoint("TOPLEFT", 180, -y)
    y = y + 56
    page:SetHeight(y)
end

local function BuildForm(page)
    -- 示例文本走 locale（勿硬编码中文，2026-11-14 用户提醒）
    local ML_SAMPLE = L["DEMO_ML_LONG"]
    local spec = {
        { type = "header", label = L["DEMO_SECTION_FORM"] },
        { type = "toggle", label = L["DEMO_LABEL_ENABLED"], key = "enabled", default = true, reset = "changed" },
        { type = "slider", label = L["DEMO_LABEL_VOLUME"], key = "volume", min = 0, max = 100, step = 1,
          default = 50, suffix = "editbox", reset = true },
        { type = "slider", label = L["DEMO_LABEL_VOLUME"], key = "volume", min = 0, max = 1, step = 0.05,
          default = 0.5, suffix = "value", reset = false },
        { type = "dropdown", label = L["DEMO_LABEL_CHOICE"], key = "choice", default = "a", reset = "changed",
          items = { { text = "The War Within", value = "a" }, { text = "Midnight", value = "b" } } },
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "text", default = "ade_Demo", reset = true },
        -- 第一个多行框调矮到 60：测试「未达滑块最小高度」时滚动条隐藏、滚动仍可用（2026-11-14 用户要求）
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "text", default = "", multiline = true,
          width = 300, height = 60, reset = false },
        -- 多种多行编辑框情况（2026-11-14）：长文本触发滚动条、空/短文本自动隐藏滚动条、宽框
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "mlLong", default = ML_SAMPLE, multiline = true,
          width = 300, height = 120, reset = false },
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "mlEmpty", default = "", multiline = true,
          width = 300, height = 120, reset = false },
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "mlShort", default = L["DEMO_ML_SHORT"], multiline = true,
          width = 300, height = 120, reset = false },
        { type = "input", label = L["DEMO_LABEL_TEXT"], key = "mlWide", default = ML_SAMPLE, multiline = true,
          width = 500, height = 120, reset = false },
        { type = "color", label = L["DEMO_LABEL_COLOR"], key = "color",
          default = { red = 238 / 255, green = 228 / 255, blue = 174 / 255 }, reset = true },
    }
    AF.Form.Build(page, spec, { get = Get, set = Set, width = AF.LAYOUT.contentW, labelW = 160 })
end

local function BuildDisplay(page)
    local y = 0
    local title = AF.Widget.Text.SectionTitle(page, L["DEMO_SECTION_DISPLAY"], AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0); y = y + 32

    local bars = AF.Widget.InfoBar.Create(page, {
        width = 500,
        items = {
            { text = "Reputation", value = "4200/6000", progress = 0.7, showBar = true,
              icon = "Interface\\Icons\\INV_Misc_QuestionMark", tooltip = "Progress 70%" },
            { text = "Currency", value = "35%", progress = 0.35, showBar = true },
            { text = "Quests", value = "3/8", progress = 0.375 },
        },
    })
    bars:SetPoint("TOPLEFT", 0, -y); y = y + 100

    local pane = AF.Widget.Preview.CreatePane(page, { width = 300, height = 110 })
    pane:SetPoint("TOPLEFT", 0, -y)
    pane:AddPage("a", "Portrait", function(p)
        local t = AF.Widget.Preview.CreateTile(p, { width = 100, height = 60, text = "A" })
        t:SetPoint("TOPLEFT", 0, 0)
    end)
    pane:AddPage("b", "Landscape", function(p)
        local t = AF.Widget.Preview.CreateTile(p, { width = 160, height = 40, text = "B" })
        t:SetPoint("TOPLEFT", 0, 0)
    end)

    local glowBtn = AF.Widget.Button.Create(page, {
        text = "Glow", width = 90,         onClick = function(self)
            if self._afGlow then
                self._afGlow:Stop()
                self._afGlow = nil
            else
                self._afGlow = AF.Widget.Glow.Pixel(self, {})
            end
        end,
    })
    glowBtn:SetPoint("TOPLEFT", 320, -y)
    y = y + 120
    page:SetHeight(y)
end

local function BuildList(page)
    local y = 0
    local title = AF.Widget.Text.SectionTitle(page, L["DEMO_SECTION_LIST"], AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0); y = y + 32

    local list = AF.Widget.List.Create(page, {
        width = 300, height = 120,
        draggable = true,
        items = {
            { text = "Item one", value = "12", icon = 134400 },
            { text = "Item two", value = "7", icon = { atlas = "GM-icon-visible" } },
            { text = "Item three", value = "3", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
        },
        onReorder = function(items) Set("listOrder", items) end,
    })
    list:SetPoint("TOPLEFT", 0, -y)
    y = y + 130

    -- 行看板：样式对齐 MiliUI_Tooltip「玩家 → 显示元素」——每行多个元素方块、超宽换行，
    -- 每行左侧外部一个移动控件拖整行调序（2026-11-13 用户要求的多行多元素拖拽测试）。
    local C = function(key) return { text = L[key] } end
    local drag = AF.Widget.RowDrag.Create(page, {
        width = AF.LAYOUT.contentW - 26,
        rows = {
            { C("DEMO_CHIP_FRIEND"), C("DEMO_CHIP_RAIDMARK"), C("DEMO_CHIP_ROLE"), C("DEMO_CHIP_PVP"),
              C("DEMO_CHIP_FACTION"), C("DEMO_CHIP_CLASS"), C("DEMO_CHIP_TITLE"), C("DEMO_CHIP_NAME"), C("DEMO_CHIP_REALM") },
            { C("DEMO_CHIP_AFK"), C("DEMO_CHIP_DND"), C("DEMO_CHIP_OFFLINE") },
            { C("DEMO_CHIP_GUILD"), C("DEMO_CHIP_GUILDRANK") },
            { C("DEMO_CHIP_LEVEL"), C("DEMO_CHIP_RACE"), C("DEMO_CHIP_SPEC") },
            { C("DEMO_CHIP_MOUNT") },
            { C("DEMO_CHIP_MPLUS") },
            { C("DEMO_CHIP_ILVL") },
            { C("DEMO_CHIP_ACHIEVEMENT") },
        },
        onReorder = function(rows) Set("rowOrder", rows) end,
    })
    drag:SetPoint("TOPLEFT", 0, -y)
    y = y + (drag:GetHeight() or 100) + 8
    local hint = AF.Widget.Text.Desc(page, L["DEMO_LABEL_DRAG"], AF.LAYOUT.contentW)
    hint:SetPoint("TOPLEFT", 0, -y)
    y = y + 26
    page:SetHeight(y)
end

local function BuildFrame(page)
    local y = 0
    local title = AF.Widget.Text.SectionTitle(page, L["DEMO_SECTION_FRAME"], AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0); y = y + 32

    local confirm = AF.Widget.Button.Create(page, {
        text = AF.L["AF_OK"], width = 100, variant = "primary",
        onClick = function()
            local p = AF.Widget.Popup.Confirm({ text = AF.L["AF_RESET_ALL"], onAccept = function() end })
            p:Open()
        end,
    })
    confirm:SetPoint("TOPLEFT", 0, -y)
    local menu = AF.Widget.Button.Create(page, {
        text = AF.L["AF_ABOUT"], width = 100,
        onClick = function(self)
            AF.Widget.ContextMenu.Show({
                { text = AF.L["AF_PROFILES"], isTitle = true },
                { text = AF.L["AF_NEW"], checked = true, keepOpen = true },
                { isDivider = true },
                { text = AF.L["AF_CLOSE"], onClick = function() AF.Widget.ContextMenu.Hide() end },
            }, self)
        end,
    })
    menu:SetPoint("TOPLEFT", 110, -y)
    y = y + 32

    local search = AF.Widget.SearchBar.Create(page, {
        width = 220,
        items = { { label = L["DEMO_TAB_BASIC"], keywords = "basic" }, { label = L["DEMO_TAB_FORM"], keywords = "form" } },
        onGoto = function(item) AF.Print(item.label) end,
    })
    search:SetPoint("TOPLEFT", 0, -y)
    y = y + 36

    local nudge = AF.Widget.PositionNudge.Create(page, { onNudge = function() end, onReset = function() end })
    nudge:SetPoint("TOPLEFT", 0, -y)
    local grid = AF.Widget.AnchorGrid.Create(page, { value = "CENTER" })
    grid:SetPoint("TOPLEFT", 220, -y)
    y = y + 90
    page:SetHeight(y)
end

local function BuildIntegration(page)
    local y = 0
    local title = AF.Widget.Text.SectionTitle(page, L["DEMO_SECTION_INTEGRATION"], AF.LAYOUT.contentW)
    title:SetPoint("TOPLEFT", 0, 0); y = y + 32

    local accent = AF.Widget.Button.Create(page, {
        text = L["DEMO_LABEL_ACCENT"], width = 140,
        onClick = function() DEMO.SetGlobalColor({ red = math.random(), green = math.random(), blue = math.random() }) end,
    })
    accent:SetPoint("TOPLEFT", 0, -y)

    local preview = AF.Widget.PreviewButton.Create(page, { tooltip = "Preview" })
    preview:SetPoint("LEFT", accent, "RIGHT", 12, 0)
    local sound = AF.Widget.SoundPicker.Create(page, {
        width = 220, items = { { text = AF.L["AF_NONE"], value = "" } },
        onPlay = function() end,
    })
    sound:SetPoint("TOPLEFT", 0, -y - 30)

    local hint = AF.Widget.Hint.Create(page, { text = L["DEMO_LABEL_SEARCH"] })
    hint:SetPoint("LEFT", sound, "RIGHT", 12, 0)
    y = y + 80
    page:SetHeight(y)
end

local function BuildProfiles(page)
    db.settings.profiles = db.settings.profiles or { current = "Shared", list = {} }
    db.settings.profiles.current = db.settings.profiles.current or "Shared"
    db.settings.profiles.list = db.settings.profiles.list or {}
    -- 让导出/导入测试有真实数据：共享档指向当前 demo 设置（ProfileDB.New 仅在缺省时写 {}，不会覆盖这里）
    if not next(db.settings.profiles.list) then
        db.settings.profiles.list[db.settings.profiles.current] = db.settings.demo
    end
    local profileDB = AF.Options.ProfileDB.New(db.settings.profiles, {
        onSwitch = function() end, onReset = function() end,
        onImport = function() AF.Print(L["DEMO_TEST_OK"]) end,
        serialize = function(t) return AF.DB.Encode(t) end,
        deserialize = function(s) return AF.DB.Decode(s) end,
    })
    AF.Options.ProfilePage.Build(page, {
        db = profileDB, L = AF.L,
        notify = function(msg) AF.Print(msg) end,
    })
end

local function BuildAbout(page)
    DEMO.BuildAbout(page)
end

local function SelfTest()
    local checks = {
        { "Namespace", function() return AF.MAJOR == "ade_AddonFramework" end },
        { "MINOR", function() return type(AF.MINOR) == "number" end },
        { "Theme", function() local r = AF.Color("accent"); return type(r) == "number" end },
        { "AccentHex", function() return AF.AccentHex():match("^|cff%x%x%x%x%x%x$") ~= nil end },
        { "DB.DeepCopy", function() local t = AF.DB.DeepCopy({ a = { b = 1 } }); return t.a.b == 1 end },
        { "Callbacks", function()
            local n = 0
            AF.RegisterCallback("AF_TEST", "k", function() n = n + 1 end)
            AF.FireCallback("AF_TEST"); AF.UnregisterCallback("AF_TEST", "k")
            return n == 1
        end },
        { "ResolveIcon/Atlas", function() return type(AF.IconEscape({ atlas = "common-icon-undo" }, 16, 16)) == "string" end },
        { "ResolveIcon/FileID", function() return AF.IconEscape(134400, 16, 16):find("134400", 1, true) ~= nil end },
        { "Masque probe", function() return type(AF.Masque.Available()) == "boolean" end },
        { "Widget count", function() local n = 0; for _ in pairs(AF.Widget) do n = n + 1 end; return n >= 20 end },
    }
    local failed = {}
    for _, c in ipairs(checks) do
        local ok, result = pcall(c[2])
        if not ok or not result then failed[#failed + 1] = c[1] .. (ok and "" or " (error)") end
    end
    if #failed == 0 then
        AF.Print(L["DEMO_TEST_OK"])
    else
        AF.Print(L["DEMO_TEST_FAIL"]:format(table.concat(failed, ", ")))
    end
end

local function Open(layout)
    layoutMode = layout or layoutMode
    if frame then frame:Hide(); frame = nil end
    frame = AF.Options.Frame.Create({
        title = L["DEMO_TITLE"], layout = layoutMode,
        icon = "Interface\\AddOns\\ade_Demo\\assets\\ade_128.tga",
    })
    -- b010：预览区迁移为独立组件（Template/PreviewPanel），双布局只留开关位——
    -- 单布局开关放标题栏（AddRightButton），多布局放左栏页脚（AddSidebarFooterButton）。
    local previewPageText
    local preview = AF.Template.PreviewPanel.New({
        width = 340,
        build = function(content)
            local title = AF.Widget.Text.SectionTitle(content, L["DEMO_PREVIEW_TITLE"], 300)
            title:SetPoint("TOPLEFT", 0, 0)
            local tile = AF.Widget.Preview.CreateTile(content, { width = 160, height = 40, text = "P" })
            tile:SetPoint("TOPLEFT", 0, -40)
            local desc = AF.Widget.Text.Desc(content, L["DEMO_PREVIEW_NOTE"], 300)
            desc:SetPoint("TOPLEFT", 0, -96)
            previewPageText = AF.Widget.Text.Desc(content, "", 300)
            previewPageText:SetPoint("TOPLEFT", 0, -160)
        end,
    })
    preview:AttachTo(frame)
    frame.previewPanel = preview
    local pb
    if layoutMode == "single" then
        pb = AF.Widget.Button.Create(frame.titleBar, { text = AF.L["AF_PREVIEW_OPEN"], width = 88, height = 20 })
        AF.Widget.Button.FitButton(pb, 72, 20)
        frame.titleBar:AddRightButton(pb, 20)
    else
        pb = frame:AddSidebarFooterButton(AF.L["AF_PREVIEW_OPEN"])
    end
    preview:BindButton(pb)
    -- 页切换联动演示（TabbedFrame onPageChanged）：预览区显示当前页名
    frame:SetOnPageChanged(function(id, page)
        if previewPageText then
            previewPageText:SetText(L["DEMO_PREVIEW_PAGE"]:format(page and page.label or tostring(id)))
        end
    end)
    frame:AddPage("basic", L["DEMO_TAB_BASIC"], BuildBasic)
    frame:AddPage("form", L["DEMO_TAB_FORM"], BuildForm)
    frame:AddPage("display", L["DEMO_TAB_DISPLAY"], BuildDisplay)
    frame:AddPage("list", L["DEMO_TAB_LIST"], BuildList)
    frame:AddPage("frame", L["DEMO_TAB_FRAME"], BuildFrame)
    frame:AddPage("integration", L["DEMO_TAB_INTEGRATION"], BuildIntegration)
    frame:AddPage("profiles", L["DEMO_TAB_PROFILES"], BuildProfiles)
    frame:AddPage("about", L["DEMO_TAB_ABOUT"], BuildAbout)
    -- 多布局页脚演示：复选框固定最底槽位（ADE-v6-FrameDesign 的「小地图图标」槽位）
    if layoutMode == "multi" and frame.AddSidebarFooterCheckbox then
        frame:AddSidebarFooterCheckbox(L["DEMO_FOOTER_SAMPLE"],
            function() return Get("footerSample", false) end,
            function(v) Set("footerSample", v and true or false) end)
    end
    frame:Show()
end

SLASH_AFDEMO1 = "/afdemo"
SlashCmdList["AFDEMO"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "test" then SelfTest(); return end
    if msg == "single" or msg == "multi" then Open(msg); return end
    if frame and frame:IsShown() then frame:Hide() else Open() end
end
