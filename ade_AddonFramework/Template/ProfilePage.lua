-- 可复用配置页模板：以 MiliUI_Tooltip/Options/Tab_Share.lua 为蓝本。
-- 用户要求（2026-11-14）：除「配置操作按钮、重置部分」外照抄 MiliUI——布局/控件/判断逻辑。
--   档案区：新建/复制 = accent（MiliUI Tab_Share.lua:254,259）；重命名/重置/删除 = red（用户要求：
--   三者同为危险操作）；重命名/删除在共用档禁用（:233 同款，MiliUI 仅禁删除）。
--   导出/导入区：列间隔 24（MiliUI COL_W=470/COL2_X=506/FULL_W=964 的间隔）、
--   按钮锚在框 BOTTOMLEFT (0,-8)（:307,355）、导出成功标题换「Ctrl+C 复制」+ OnChar 全选防改
--   （:314,321:323）、导入实时校验 pendingData + 标题提示（:331,336:352）、导入确认弹窗（:357:366）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Options = AF.Options or {}
local W = {}
AF.Template.ProfilePage = W  -- 组合模板：配置档管理页
AF.Options.ProfilePage = W  -- 别名兼容

local MARGIN, COL_GAP, ROW_H = 12, 24, 26
local BOX_H = 150   -- MiliUI 228@964 宽，等比到 648 内容宽取 150

--- ctx = { db = ProfileDB, L = 本地化表, notify = function(msg) end }
function W.Build(parent, ctx)
    ctx = ctx or {}
    local db, L = ctx.db, ctx.L or AF.L
    local notify = ctx.notify or AF.Print
    local fullW = AF.LAYOUT.contentW - MARGIN * 2
    local colW = math.floor((fullW - COL_GAP) / 2)
    local col2X = MARGIN + colW + COL_GAP
    local y = MARGIN

    local function Error(why)
        local key = (why == "exists" and "AF_NAME_EXISTS")
            or (why == "shared" and "AF_PROFILE_SHARED")
            or "AF_NAME_EMPTY"
        notify(L[key])
    end

    local dd = AF.Widget.Dropdown.Create(parent, {
        width = fullW,
        items = {},
        onSelect = function(value)
            db.Switch(value)
            if ctx.onSwitch then ctx.onSwitch(value) end
        end,
    })
    dd:SetPoint("TOPLEFT", MARGIN, -y)

    local function SyncDD()
        local items = {}
        for _, name in ipairs(db.List()) do items[#items + 1] = { text = name, value = name } end
        dd:SetItems(items)
        dd:SetValue(db.Current())
    end

    -- 第 2 行：nameBox + 5 颗按钮（链式锚点，禁用绝对 x）
    y = y + ROW_H + 4
    local nameBox = AF.Widget.Editbox.CreateSingle(parent, 150, 20)
    nameBox:SetPoint("TOPLEFT", MARGIN, -y)

    local baseW = math.floor((fullW - 150 - 6 - 4 * 8) / 5)
    -- 新建/复制 = accent（MiliUI :254,259）；重命名/重置/删除 = red（用户要求：同为危险操作）
    local labels = {
        { L["AF_NEW"], "accent" }, { L["AF_COPY"], "accent" },
        { L["AF_RENAME"], "red" }, { L["AF_RESET"], "red" }, { L["AF_DELETE"], "red" },
    }
    local buttons, prev = {}, nameBox
    -- renamePopup 同样先被下方 OnClick 闭包引用，必须在此声明（勿留全局）
    local confirm, renamePopup, renameBtn, deleteBtn
    for i, entry in ipairs(labels) do
        local b = AF.Widget.Button.Create(parent, {
            text = entry[1], width = baseW, height = 20, variant = entry[2],
        })
        AF.Widget.Button.FitButton(b, baseW, 20)
        b:SetPoint("LEFT", prev, "RIGHT", i == 1 and 6 or 8, 0)
        buttons[i], prev = b, b
        if entry[1] == L["AF_RENAME"] then renameBtn = b end
        if entry[1] == L["AF_DELETE"] then deleteBtn = b end
    end

    local function Refresh()
        SyncDD()
        -- 共用档：重命名/删除禁用（MiliUI :233 仅禁删除；重命名按用户要求一并禁）
        local shared = db.Current() == db.Default()
        if renameBtn then renameBtn:SetEnabled(not shared) end
        if deleteBtn then deleteBtn:SetEnabled(not shared) end
        if ctx.onRefresh then ctx.onRefresh() end
    end
    local function Make(action)
        local ok, why = action()
        if not ok then Error(why); return end
        nameBox:SetText("")
        Refresh()
    end
    buttons[1]:SetScript("OnClick", function() Make(function() return db.Create(nameBox:GetText()) end) end)
    buttons[2]:SetScript("OnClick", function() Make(function() return db.Copy(nameBox:GetText()) end) end)
    buttons[3]:SetScript("OnClick", function()
        if db.Current() == db.Default() then notify(L["AF_PROFILE_SHARED"]); return end
        if not renamePopup then
            renamePopup = AF.Widget.Popup.Input({
                text = L["AF_RENAME_PROMPT"],
                onAccept = function(newName)
                    local ok, why = db.Rename(db.Current(), newName)
                    if not ok then Error(why); return end
                    Refresh()
                end,
            })
        end
        renamePopup:SetText(db.Current())
        renamePopup:Open()
    end)
    buttons[4]:SetScript("OnClick", function()
        if not confirm then
            confirm = AF.Widget.Popup.Confirm({
                text = L["AF_RESET_ALL"],
                onAccept = function() db.Reset(); Refresh() end,
            })
        end
        confirm:Open()
    end)
    buttons[5]:SetScript("OnClick", function()
        local name = db.Current()
        local popup = AF.Widget.Popup.Confirm({
            text = L["AF_DELETE_CONFIRM"],
            onAccept = function()
                local ok, why = db.Delete(name)
                if not ok then Error(why); return end
                db.Switch(db.Default())
                Refresh()
            end,
        })
        popup:Open()
    end)

    y = y + ROW_H
    local hint = AF.Widget.Text.Desc(parent, L["AF_PROFILE_HINT"], fullW)
    hint:SetPoint("TOPLEFT", MARGIN, -y)

    ---------------------------------------------------------
    -- 导出（照抄 Tab_Share.lua:296:323）
    ---------------------------------------------------------
    y = y + ROW_H + 10
    local exportTitle = AF.Widget.Text.SectionTitle(parent, L["AF_EXPORT"], colW)
    exportTitle:SetPoint("TOPLEFT", MARGIN, -y)

    y = y + 32
    local exportBox = AF.Widget.Editbox.CreateMulti(parent, colW, BOX_H)
    exportBox:SetPoint("TOPLEFT", MARGIN, -y)

    local exportBtn = AF.Widget.Button.Create(parent, {
        text = L["AF_EXPORT"], width = 130, variant = "accent",
        onClick = function()
            -- db.Export 无失败路径（MiliUI :309:317 的失败分支因 C_EncodingUtil 缺失才有）
            exportBox.editBox:SetText(tostring(db.Export()))
            exportBox.editBox:HighlightText()
            exportBox.editBox:SetFocus()
            exportTitle.text:SetText(L["AF_EXPORT_COPY"])
        end,
    })
    AF.Widget.Button.FitButton(exportBtn, 130, 22)
    exportBtn:SetPoint("TOPLEFT", exportBox, "BOTTOMLEFT", 0, -8)

    -- 导出框内容防改：一改就重新全选，方便复制（MiliUI :321:323）
    exportBox.editBox:SetScript("OnChar", function(self) self:HighlightText() end)

    ---------------------------------------------------------
    -- 导入（照抄 Tab_Share.lua:325:366，含 pendingData 判断逻辑）
    ---------------------------------------------------------
    local importTitle = AF.Widget.Text.SectionTitle(parent, L["AF_IMPORT"], colW)
    importTitle:SetPoint("TOPLEFT", col2X, -y + 32)

    -- ⚠ importBtn 必须先声明：下面的 onTextChanged 闭包会引用它，
    --   若在其 local 声明之前定义闭包，捕获的是全局变量（nil）→ 校验回调一跑就报错，
    --   「前缀不符」提示永远不出现（2026-11-14 用户截图实证的 bug）
    local importBtn
    local pendingData

    local importBox = AF.Widget.Editbox.CreateMulti(parent, colW, BOX_H, {
        onTextChanged = function(eb, userChanged)
            if not userChanged then return end
            local ok, dataOrErr = db.Validate(eb:GetText())
            if ok then
                pendingData = dataOrErr
                importTitle.text:SetText(L["AF_IMPORT_VALID"])
                importBtn:SetEnabled(true)
            else
                pendingData = nil
                importBtn:SetEnabled(false)
                if eb:GetText() ~= "" then
                    local msg = dataOrErr == "wrong prefix" and L["AF_PREFIX_MISMATCH"] or L["AF_IMPORT_INVALID"]
                    importTitle.text:SetText(L["AF_IMPORT_COLON"] .. "|cffff2222" .. msg .. "|r")
                else
                    importTitle.text:SetText(L["AF_IMPORT"])
                end
            end
        end,
    })
    importBox:SetPoint("TOPLEFT", col2X, -y)

    importBtn = AF.Widget.Button.Create(parent, {
        text = L["AF_IMPORT"], width = 130, variant = "green",
        onClick = function()
            if not pendingData then return end
            local popup = AF.Widget.Popup.Confirm({
                text = L["AF_IMPORT_CONFIRM"],
                onAccept = function()
                    db.ImportData(pendingData)  -- 用校验时存下的 data，不二次解码
                    pendingData = nil
                    importBox.editBox:SetText("")
                    Refresh()
                end,
            })
            popup:Open()
        end,
    })
    AF.Widget.Button.FitButton(importBtn, 130, 22)
    importBtn:SetPoint("TOPLEFT", importBox, "BOTTOMLEFT", 0, -8)
    importBtn:SetEnabled(false) -- 无有效字符串前不可点（MiliUI :334）

    ---------------------------------------------------------
    -- 底部说明（照抄 Tab_Share.lua:368:373）
    ---------------------------------------------------------
    y = y + BOX_H + 8 + 22 + 12
    local note = AF.Widget.Text.Desc(parent, L["AF_EXPORT_NOTE"], fullW)
    note:SetPoint("TOPLEFT", MARGIN, -y)

    y = y + ROW_H
    parent:SetHeight(y)
    Refresh()
    return { dropdown = dd, buttons = buttons, refresh = Refresh, height = y }
end
