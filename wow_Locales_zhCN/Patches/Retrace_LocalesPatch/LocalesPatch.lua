---------------------------------------------------------------------------
-- Retrace 简体中文语言包 · 工具层
--
-- 仅负责「运行时劫持文本输出并整串替换为本地化文本」，不含字典数据。
-- 字典见 Lang_<locale>.lua（通过 RetraceLang[locale] 读取，未命中回退 zhCN）。
--
-- 适配说明（依据 Retrace 1.0.0 真实源码）：
--   1. 具名锚点：RetraceReplayFrame（Replay/Journal/Atlas 所在窗口）、RetraceMinimapButton；
--      另有两个无全局名的根帧，通过插件表取引用：Retrace.xpBarFrame（经验条）、
--      Retrace._BuildOptions() 返回的设置面板（首次构建后缓存，可安全调用）。
--   2. 设置面板与回放窗口内多数 FontString 无名，故判定走「父链比对已知根引用」，
--      不用 frame 名 pattern。
--   3. 设置面板文案在 Build() 后固定不变，加载时遍历子树整批替换；
--      回放/日志的文本随交互变化，必须靠 SetText 钩子持续覆盖。
--   4. 动态拼接串（"Lv 12"/"Speed x2"/"Level 12  ·  ..."）走 PrefixRules；
--      其余运行时格式化描述（日期、事件叙述、统计行）无法整串匹配，保留英文。
---------------------------------------------------------------------------
local locale = GetLocale()
local L = (RetraceLang and RetraceLang[locale]) or (RetraceLang and RetraceLang.zhCN) or {}

local optionsPanel  -- 设置面板引用（可能是 nil，延迟到 Build 后取得）

---------------------------------------------------------------------------
-- 动态串前缀规则（按顺序匹配，%1.. 为捕获组）
---------------------------------------------------------------------------
local PrefixRules = {
    { "^Lv (%d+)$", "等级 %1" },                          -- 地图事件气泡的等级标记
    { "^Speed x(%d+)$", "速度 x%1" },                      -- 回放倍速按钮
    { "^Level (%d+)(%s+·.*)$", "等级 %1%2" },              -- "Level 12  ·  区域 / 区域"
    { "^Restore removed entries %((%d+)%)$", "恢复已移除的条目（%1）" },
    { "^Notable loot %((%d+)%)$", "值得注意的战利品（%1）" },
    -- 回放底部状态行（日期 + "  ·  |cffff4040recording paused|r"，日期在左侧动态）
    { "|cffff4040recording paused|r", "|cffff4040录制已暂停|r" },
    -- 轨迹窗口说明（后半段是筛选名，随选项变化）
    { "^|cff9fd8ff%(blue%)|r = within the Trail window: (.*)$",
      "|cff9fd8ff（蓝色）|r = 在轨迹时间范围内：%1" },
}

---------------------------------------------------------------------------
-- 安全工具函数（保密值防护 + 异常捕获）
---------------------------------------------------------------------------
local function SafeStripColor(text)
    if type(text) ~= "string" then return nil end
    if issecretvalue and issecretvalue(text) then return nil end
    local ok, result = pcall(function()
        return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end)
    return ok and result or nil
end

local function GetTranslation(str)
    if type(str) ~= "string" or str == "" then return nil end
    if issecretvalue and issecretvalue(str) then return nil end

    local direct = L[str]
    if direct then return direct end

    -- 去色后精确匹配（少数只带颜色码差异的串）
    local stripped = SafeStripColor(str)
    if stripped and stripped ~= str then
        local hit = L[stripped]
        if hit then return hit end
    end

    -- 动态串前缀规则
    for _, rule in ipairs(PrefixRules) do
        local ok, result = pcall(string.gsub, str, rule[1], rule[2])
        if ok and result and result ~= str then return result end
    end

    return nil
end

---------------------------------------------------------------------------
-- 归属判定：只处理 Retrace 自己的控件
---------------------------------------------------------------------------
local function IsRetraceFrame(obj)
    if not obj then return false end
    local root1 = _G.RetraceReplayFrame
    local root2 = _G.RetraceMinimapButton
    local root3 = _G.Retrace and _G.Retrace.xpBarFrame
    local root4 = optionsPanel
    if obj == root1 or obj == root2 or obj == root3 or obj == root4 then return true end

    local p = obj
    for _ = 1, 14 do
        local ok, parent = pcall(p.GetParent, p)
        if not ok or not parent then return false end
        p = parent
        if p == root1 or p == root2 or p == root3 or p == root4 then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- 静态弹窗汉化（Retrace 用固定 key，直接按字典替换 text）
---------------------------------------------------------------------------
local function TranslateStaticPopups()
    if not StaticPopupDialogs then return end
    for _, dialog in pairs(StaticPopupDialogs) do
        if type(dialog) == "table" then
            local text = dialog.text
            if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
                local trans = L[text] or GetTranslation(text)
                if trans then dialog.text = trans end
            end
            for i = 1, 3 do
                local btn = dialog["button" .. i]
                if type(btn) == "string" then
                    local t = L[btn]
                    if t then dialog["button" .. i] = t end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- 设置面板整批替换（Build 后文本不再变化，遍历一次即可）
---------------------------------------------------------------------------
local function ReplaceRegionText(region)
    if not region then return end
    local ok, kind = pcall(region.GetObjectType, region)
    if not ok or not kind then return end
    if kind == "FontString" then
        local ok2, text = pcall(region.GetText, region)
        if ok2 and type(text) == "string" then
            local trans = L[text] or GetTranslation(text)
            if trans then pcall(region.SetText, region, trans) end
        end
    elseif kind == "Button" or kind == "CheckButton" then
        local ok2, text = pcall(region.GetText, region)
        if ok2 and type(text) == "string" then
            local trans = L[text] or GetTranslation(text)
            if trans then pcall(region.SetText, region, trans) end
        end
    end
    local ok3, scrollChild = pcall(region.GetScrollChild, region)
    if ok3 and scrollChild then ReplaceRegionText(scrollChild) end
    local ok4, children = pcall(region.GetChildren, region)
    if ok4 and children then
        for i = 1, #children do ReplaceRegionText(children[i]) end
    end
    local ok5, regions = pcall(region.GetRegions, region)
    if ok5 and regions then
        for i = 1, #regions do ReplaceRegionText(regions[i]) end
    end
end

local function TranslateOptionsPanel()
    local R = _G.Retrace
    if not (R and R._BuildOptions) then return end
    local ok, panel = pcall(R._BuildOptions, R)
    if ok and panel then
        optionsPanel = panel
        ReplaceRegionText(panel)
    end
end

---------------------------------------------------------------------------
-- 全局文本 Hook（全链路安全防护 + 归属过滤）
---------------------------------------------------------------------------
local function IsTooltipOwnerRetrace(tooltip)
    local ok, owner = pcall(tooltip.GetOwner, tooltip)
    if not ok or not owner then return false end
    return IsRetraceFrame(owner)
end

local function InstallHooks()
    -- FontString:SetText（用一次性 dummy 取元表方法，不重包装 CreateFrame）
    local dummyFS = UIParent:CreateFontString(nil, "ARTWORK")
    dummyFS:Hide()
    local fsMeta = getmetatable(dummyFS).__index
    local inFS = false
    hooksecurefunc(fsMeta, "SetText", function(self, text)
        if inFS then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local trans = GetTranslation(text)
        if not trans then return end
        if not IsRetraceFrame(self) then return end
        inFS = true
        pcall(self.SetText, self, trans)
        inFS = false
    end)

    -- Button:SetText
    local dummyBtn = CreateFrame("Button")
    local btnMeta = getmetatable(dummyBtn).__index
    local inBtn = false
    hooksecurefunc(btnMeta, "SetText", function(self, text)
        if inBtn then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local trans = GetTranslation(text)
        if not trans then return end
        if not IsRetraceFrame(self) then return end
        inBtn = true
        pcall(self.SetText, self, trans)
        inBtn = false
    end)

    -- GameTooltip：标题 SetText + 详情 AddLine（仅 owner 属于 Retrace 时）
    local inTip = false
    hooksecurefunc(GameTooltip, "SetText", function(self, text)
        if inTip then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local trans = GetTranslation(text)
        if not trans then return end
        if not IsTooltipOwnerRetrace(self) then return end
        inTip = true
        pcall(self.SetText, self, trans)
        inTip = false
    end)
    hooksecurefunc(GameTooltip, "AddLine", function(self, text, r, g, b, wrap)
        if inTip then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local trans = GetTranslation(text)
        if not trans then return end
        if not IsTooltipOwnerRetrace(self) then return end
        inTip = true
        pcall(self.AddLine, self, trans, r, g, b, wrap)
        inTip = false
    end)

    -- 设置面板里的描述类长文本（FontString）由 ReplaceRegionText 处理，无需额外通道
end

---------------------------------------------------------------------------
-- 初始化入口
---------------------------------------------------------------------------
C_Timer.After(0.2, function()
    TranslateStaticPopups()
    InstallHooks()
    TranslateOptionsPanel()
    print("|cFF00CCFF[Retrace 汉化]|r 简体中文语言包已加载")
end)
