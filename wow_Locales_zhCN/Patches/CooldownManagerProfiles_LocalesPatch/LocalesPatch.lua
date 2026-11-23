---------------------------------------------------------------------------
-- Cooldown Manager Profiles 简体中文语言包 · 工具层
--
-- 仅负责「运行时劫持文本输出并整串替换为中文」，不含任何字典数据。
-- 字典见 Lang_<locale>.lua（通过 CMPLang[locale] 读取，未命中回退 zhCN）。
--
-- 适配说明（针对新版 CooldownManagerProfiles 重新适配）：
--   1. 新版每个 StaticPopup 的 text 都带常量前缀 "CM Profiles\n\n"，
--      且把多段拼成一条 -> TranslateStaticPopups 先去前缀再查表。
--   2. 主窗口 frame 名 "CooldownManagerProfilesFrame" 仍可被识别；
--      设置面板 frame 名 "Cooldown Manager ProfilesSettingsPanel"（带空格）
--      旧判定漏掉 -> IsCMFrame 增加 "Cooldown Manager Profiles" 命中。
--   3. 新增大量工具提示（GameTooltip 标题）-> 增加 GameTooltip:SetText 钩子，
--      仅当 tooltip 拥有者是 CM 框架内对象时才翻译（不影响其他插件）。
---------------------------------------------------------------------------
local locale = GetLocale()
local L = (CMPLang and CMPLang[locale]) or (CMPLang and CMPLang.zhCN) or {}

---------------------------------------------------------------------------
-- 安全工具函数（保密值防护 + 异常捕获）
---------------------------------------------------------------------------
-- 安全去除颜色码，遇到保密值直接返回nil
local function SafeStripColor(text)
    if type(text) ~= "string" then return nil end
    if issecretvalue and issecretvalue(text) then return nil end
    local ok, result = pcall(function()
        return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end)
    return ok and result or nil
end

-- 安全获取翻译，异常直接返回nil
local function GetTranslation(str)
    if type(str) ~= "string" or str == "" then return nil end
    if issecretvalue and issecretvalue(str) then return nil end

    local stripped = SafeStripColor(str)
    if not stripped then return nil end

    -- 精确匹配
    local trans = L[stripped]
    if trans then
        local ok, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
        if ok and prefix then
            return prefix .. trans .. "|r"
        end
        return trans
    end

    -- 匹配 "xxx (n/n)" 计数格式
    local ok2, base, cur, total = pcall(string.match, stripped, "^(.-)%s*%((%d+)/(%d+)%)$")
    if ok2 and base and cur then
        local transBase = L[base]
        if transBase then
            local result = transBase .. " (" .. cur .. "/" .. total .. ")"
            local ok3, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
            if ok3 and prefix then
                return prefix .. result .. "|r"
            end
            return result
        end
    end

    -- 匹配 "xxx (n)" 格式
    local ok4, base2, count = pcall(string.match, stripped, "^(.-)%s*%((%d+)%)$")
    if ok4 and base2 and count then
        local transBase = L[base2]
        if transBase then
            local result = transBase .. " (" .. count .. ")"
            local ok5, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
            if ok5 and prefix then
                return prefix .. result .. "|r"
            end
            return result
        end
    end

    return nil
end

-- 判断是否属于本插件的框架（只操作框架对象，不碰字符串）
local function IsCMFrame(frame)
    if not frame then return false end
    local ok, name = pcall(frame.GetName, frame)
    if not ok then return false end
    name = name or ""
    -- 命名规律：CooldownManagerProfiles* / "Cooldown Manager Profiles"* / ^CM / ^CMP_
    if name:find("CooldownManager") or name:find("Cooldown Manager Profiles")
        or name:find("^CM") or name:find("^CMP_") then
        return true
    end
    -- 向上遍历父级
    local ok2, parent = pcall(frame.GetParent, frame)
    while ok2 and parent do
        local ok3, pname = pcall(parent.GetName, parent)
        if ok3 and pname and (pname:find("CooldownManager")
                or pname:find("Cooldown Manager Profiles") or pname:find("^CM")) then
            return true
        end
        ok2, parent = pcall(parent.GetParent, parent)
    end
    return false
end

---------------------------------------------------------------------------
-- 静态弹窗汉化（先去掉常量前缀 "CM Profiles\n\n" 或 "CM Profiles\n" 再查表；
-- 2.3.1 中两种前缀形态并存：长提示弹窗用双换行，输入类弹窗用单换行）
---------------------------------------------------------------------------
local POPUP_PREFIXES = { "CM Profiles\n\n", "CM Profiles\n" }

local function TranslateStaticPopups()
    if not StaticPopupDialogs then return end
    for key, dialog in pairs(StaticPopupDialogs) do
        if type(key) == "string" and key:find("^CMP_") and type(dialog) == "table" then
            if dialog.text and type(dialog.text) == "string" and not (issecretvalue and issecretvalue(dialog.text)) then
                -- 去掉常量前缀（含换行，不能用 . 模式，直接按长度截取；命中后拼回原前缀）
                local msg = dialog.text
                local prefix = ""
                for _, p in ipairs(POPUP_PREFIXES) do
                    if msg:sub(1, #p) == p then
                        prefix = p
                        msg = msg:sub(#p + 1)
                        break
                    end
                end
                local trans = GetTranslation(msg)
                if trans then dialog.text = prefix .. trans end
            end
            for i = 1, 3 do
                local btn = dialog["button"..i]
                if btn and type(btn) == "string" and L[btn] then
                    dialog["button"..i] = L[btn]
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- 全局文本 Hook（全链路安全防护）
---------------------------------------------------------------------------
local function InstallHooks()
    -- 拦截 FontString:SetText
    local dummyFS = UIParent:CreateFontString()
    local fsMeta = getmetatable(dummyFS).__index
    local inFSHook = false
    hooksecurefunc(fsMeta, "SetText", function(self, text)
        if inFSHook then return end
        -- 第一道防护：保密值直接跳过
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        -- 第二道防护：非本插件框架跳过
        if not IsCMFrame(self) then return end

        local trans = GetTranslation(text)
        if trans then
            inFSHook = true
            pcall(self.SetText, self, trans)
            inFSHook = false
        end
    end)

    -- 拦截 Button:SetText
    local dummyBtn = CreateFrame("Button")
    local btnMeta = getmetatable(dummyBtn).__index
    local inBtnHook = false
    hooksecurefunc(btnMeta, "SetText", function(self, text)
        if inBtnHook then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        if not IsCMFrame(self) then return end

        local trans = GetTranslation(text)
        if trans then
            inBtnHook = true
            pcall(self.SetText, self, trans)
            inBtnHook = false
        end
    end)

    -- 拦截工具提示标题 GameTooltip:SetText（仅翻译 CM 框架内对象的 tooltip）
    -- 注意：SetText 为覆盖式写入，重设不会重复；AddLine 为追加式，不便劫持。
    local inTipHook = false
    hooksecurefunc(GameTooltip, "SetText", function(self, text)
        if inTipHook then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local ok, owner = pcall(self.GetOwner, self)
        if not ok or not owner then return end
        if not IsCMFrame(owner) then return end

        local trans = GetTranslation(text)
        if trans then
            inTipHook = true
            pcall(self.SetText, self, trans)
            inTipHook = false
        end
    end)
end

---------------------------------------------------------------------------
-- 设置面板汉化
---------------------------------------------------------------------------
local function TranslateSettingsPanel()
    if not Settings or not Settings.GetCategory then return end
    local ok, category = pcall(Settings.GetCategory, Settings, "Cooldown Manager Profiles")
    if ok and category and category.Name and not (issecretvalue and issecretvalue(category.Name)) then
        category.Name = L["Cooldown Manager Profiles"] or category.Name
    end
end

---------------------------------------------------------------------------
-- 小地图 LDB 汉化
---------------------------------------------------------------------------
local function TranslateLDB()
    if not LibStub then return end
    local ok, LDB = pcall(LibStub.GetLibrary, LibStub, "LibDataBroker-1.1", true)
    if not ok or not LDB then return end
    local ok2, obj = pcall(LDB.GetDataObjectByName, LDB, "Cooldown Manager Profiles")
    if ok2 and obj then
        obj.label = L["CM Profiles"] or obj.label
    end
end

---------------------------------------------------------------------------
-- 初始化入口
---------------------------------------------------------------------------
C_Timer.After(0.2, function()
    TranslateStaticPopups()
    InstallHooks()
    TranslateSettingsPanel()
    TranslateLDB()
    print("|cFF00CCFF[CM汉化]|r 简体中文语言包已加载（安全模式）")
end)
