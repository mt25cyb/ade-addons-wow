-- adeChatMod — 频道名缩写（业务逻辑来自 ChannelBar，未改写）。
-- 相对原插件的唯一改动：addonName 取自核心层，而非硬编码 "ChannelBar"。
local ACM = _G.adeChatMod
local addonName = ACM.name

-- 配置模块：跳过的聊天框、启用延迟、最多扫描的聊天框数量
local Config = {
    skipFrames = { [2] = true },
    initDelay = 2,
    maxChatFrames = 10,
}

-- 频道缩写模块：保存频道名正则→短标签的替换规则表
local ChannelAbbreviation = {
    rawPatterns = {
        -- 中文频道
        { "%[(%d+)%.%s*大脚世界频道[^%]]*%]", "[世界]" },
        { "%[(%d+)%.%s*综合[^%]]*%]", "[综合]" },
        { "%[(%d+)%.%s*交易[^%]]*%]", "[交易]" },
        { "%[(%d+)%.%s*本地防务[^%]]*%]", "[防务]" },
        { "%[(%d+)%.%s*寻求组队[^%]]*%]", "[组队]" },
        { "%[(%d+)%.%s*世界防务[^%]]*%]", "[防务]" },
        { "%[(%d+)%.%s*公会招募[^%]]*%]", "[招募]" },
        -- 英文频道
        { "%[(%d+)%.%s*General[^%]]*%]", "[综合]" },
        { "%[(%d+)%.%s*Trade[^%]]*%]", "[交易]" },
        { "%[(%d+)%.%s*LocalDefense[^%]]*%]", "[防务]" },
        { "%[(%d+)%.%s*LookingForGroup[^%]]*%]", "[组队]" },
        { "%[(%d+)%.%s*GuildRecruitment[^%]]*%]", "[招募]" },
        { "%[(%d+)%.%s*WorldDefense[^%]]*%]", "[防务]" },
    },
}

-- 缩写.处理文本：对单条聊天文本依次应用全部规则，异常时回退原文
function ChannelAbbreviation:Process(text)
    if type(text) ~= "string" then
        return text
    end

    -- 探测是否可以安全操作字符串（防止对 KString/秘密值 进行操作引发报错或污染）
    local canSafelyRead = pcall(string.len, text)
    if not canSafelyRead then
        return text
    end

    local success, result = pcall(function()
        local modified = text
        for _, pattern in ipairs(self.rawPatterns) do
            modified = modified:gsub(pattern[1], pattern[2])
        end
        return modified
    end)

    return success and result or text
end

-- Hook 管理模块：为 ChatFrameN 安装/记录 AddMessage 包装，实现频道名缩写
local HookManager = {
    hookedFrames = {},
}

-- Hook.枚举聊天框：扫描 ChatFrame1..maxChatFrames，返回 {index, frame} 列表
function HookManager:GetChatFrames()
    local frames = {}
    for i = 1, Config.maxChatFrames do
        local frame = _G["ChatFrame" .. i]
        if frame then
            table.insert(frames, { index = i, frame = frame })
        end
    end
    return frames
end

-- Hook.启用：为未 hook 且未跳过的聊天框包装 AddMessage，可重复调用只补新出现的框
function HookManager:Enable()
    local chatFrames = self:GetChatFrames()
    for _, item in ipairs(chatFrames) do
        local index = item.index
        local frame = item.frame

        if not Config.skipFrames[index] and
           frame.AddMessage and
           not self.hookedFrames[index] then
            local originalFunc = frame.AddMessage

            -- 安全的 AddMessage 包装：使用 securecall 调用原函数以降低污染风险
            local function SafeAddMessageWrapper(chatFrame, text, ...)
                if type(text) == "string" then
                    local processSuccess, safeText = pcall(ChannelAbbreviation.Process, ChannelAbbreviation, text)
                    if processSuccess and type(safeText) == "string" then
                        -- 使用 securecall 调用原函数，避免在受保护环境中执行时引发污染
                        return securecall(originalFunc, chatFrame, safeText, ...)
                    end
                end
                -- 若不是字符串或处理失败，原样透传
                return securecall(originalFunc, chatFrame, text, ...)
            end

            frame.AddMessage = SafeAddMessageWrapper
            self.hookedFrames[index] = true
        end
    end
end

-- 初始化模块：监听插件加载与登录事件，延迟启用 Hook
local InitManager = {
    isReady = false,
    frame = nil,
}

-- 初始化.插件加载：命中本插件后置 isReady，表示可以进入后续登录流程
function InitManager:OnAddonLoaded(loadedAddon)
    if loadedAddon == addonName then
        self.isReady = true
    end
end

-- 初始化.登录：就绪时延迟 initDelay 秒启用 Hook，并注销本次不再需要的事件
function InitManager:OnPlayerLogin()
    if not self.isReady then
        return
    end

    C_Timer.After(Config.initDelay, function()
        HookManager:Enable()
    end)

    if self.frame then
        self.frame:UnregisterEvent("ADDON_LOADED")
        self.frame:UnregisterEvent("PLAYER_LOGIN")
    end
end

-- 初始化.启动：创建独立事件帧，注册 ADDON_LOADED 与 PLAYER_LOGIN 并绑定回调
function InitManager:Start()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("PLAYER_LOGIN")

    -- 匿名事件回调：按事件名分发给 OnAddonLoaded / OnPlayerLogin
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            self:OnAddonLoaded(...)
        elseif event == "PLAYER_LOGIN" then
            self:OnPlayerLogin()
        end
    end)
end

-- 插件入口：启动初始化
InitManager:Start()
