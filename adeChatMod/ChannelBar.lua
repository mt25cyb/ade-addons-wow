-- adeChatMod — 聊天频道快捷条（业务逻辑来自 ChannelBar，未改写行为）。
-- 相对原插件的改动：配置改由 ACM:Get 提供（只读代理，b013 起路由到当前配置档）、废弃 API 迁移、
-- 新增 ACM.RefreshBar / SetBarShown / ToggleBar 供设置界面与小地图按钮调用。
-- 见《_docs/plans/ADE-v6-settings-sys-dev-plan.md》§3.1（版本/InitDB 规范）；adeChatMod 专属见《_docs/plans/adeChatMod-dev-plan.md》§3（数据层）/ §5（小地图）。
local ACM = _G.adeChatMod
local addonName = ACM.name

local ChannelBar = CreateFrame("Frame", nil, UIParent)

-- 配置只读代理：业务代码保持 config.xxx 写法，实际读 ACM:Get（当前配置档；b013 路由）。
local config = setmetatable({}, {
    __index = function(_, key)
        return ACM.Get and ACM:Get(key) or nil
    end,
})

-- 配色模块：两套按钮文字颜色方案，键为按钮文字，值为 {r, g, b}
local colorSchemes = {
    COLORFUL = {
        ["说"] = {1.00, 1.00, 1.00},
        ["喊"] = {1.00, 0.25, 0.25},
        ["队"] = {0.67, 0.67, 1.00},
        ["团"] = {1.00, 0.50, 0.00},
        ["副"] = {1.00, 1.00, 0.00},
        ["会"] = {0.25, 1.00, 0.25},
        ["世"] = {1.00, 0.75, 0.75},
        ["交"] = {0.75, 0.75, 0.00},
        ["就"] = {0.15, 0.70, 0.00},
        ["倒"] = {0.80, 0.30, 0.00},
        ["骰"] = {1.00, 1.00, 1.00},
        ["R"] = {0.00, 0.80, 1.00},
    },

    DEFAULT = {
        ["说"] = {1.00, 0.82, 0.00},
        ["喊"] = {1.00, 0.82, 0.00},
        ["队"] = {1.00, 0.82, 0.00},
        ["团"] = {1.00, 0.82, 0.00},
        ["副"] = {1.00, 0.82, 0.00},
        ["会"] = {1.00, 0.82, 0.00},
        ["世"] = {1.00, 0.82, 0.00},
        ["交"] = {1.00, 0.82, 0.00},
        ["就"] = {1.00, 0.82, 0.00},
        ["倒"] = {1.00, 0.82, 0.00},
        ["骰"] = {1.00, 0.82, 0.00},
        ["R"] = {1.00, 0.82, 0.00},
    }
}

-- 按钮定义模块：按顺序声明每个按钮的文字、发送命令与类型（basic/custom/function）
local buttonDefinitions = {
    {text = "说", cmd = "/s ", type = "basic"},
    {text = "喊", cmd = "/y ", type = "basic"},
    {text = "队", cmd = "/p ", type = "basic"},
    {text = "团", cmd = "/ra ", type = "basic"},
    {text = "副", cmd = "/i ", type = "basic"},
    {text = "会", cmd = "/g ", type = "basic"},
    {text = "世", cmd = "/1 ", type = "custom", channelType = "world"},
    {text = "交", cmd = "/2 ", type = "custom", channelType = "trade"},
    {text = "就", type = "function"},
    {text = "倒", type = "function"},
    {text = "骰", type = "function"},
    {text = "R", type = "function"},
}

-- 工具模块：彩色打印、取当前配色、取配置字号后的字体
local utils = {}

-- 工具.打印彩色文本：用 |cffRRGGBB 转义在聊天框输出带色文字
function utils.printColored(hexColor, message)
    print(string.format("|cff%s%s|r", hexColor, message))
end

-- 工具.取当前配色：按 config.colorScheme 返回 COLORFUL 或 DEFAULT 表
function utils.getCurrentColorScheme()
    return config.colorScheme == "COLORFUL" and colorSchemes.COLORFUL or colorSchemes.DEFAULT
end

-- 工具.取字体：沿用 GameFontNormal 的字体族与 flags，仅字号换成 config.fontSize
function utils.getScaledFont()
    local fontName, _, fontFlags = GameFontNormal:GetFont()
    return fontName, config.fontSize, fontFlags
end

-- 频道管理模块：频道检测、编号查询、打开输入框、加入频道、保存按钮查找表
local channelManager = {
    lookupTables = {},
    initialized = false
}

-- 频道管理.初始化：以按钮文字为键建立 buttonDefinitions 查找表并标记就绪
function channelManager:initialize()
    self.lookupTables = {
        config = {}
    }
    for _, cfg in ipairs(buttonDefinitions) do
        self.lookupTables.config[cfg.text] = cfg
    end
    self.initialized = true
end

-- 频道管理.是否在频道：用 GetChannelName 判断玩家是否处于 world/trade 逻辑频道
function channelManager:isInChannel(channelType)
    local channelName
    if channelType == "world" then
        channelName = config.worldChannel
    elseif channelType == "trade" then
        channelName = config.tradeChannel
    else
        return false
    end

    local num, name = GetChannelName(channelName)
    return num and num > 0 and name ~= nil
end

-- 频道管理.取频道编号：返回 world/trade 频道当前编号，未加入返回 nil
function channelManager:getChannelNum(channelType)
    local channelName
    if channelType == "world" then
        channelName = config.worldChannel
    elseif channelType == "trade" then
        channelName = config.tradeChannel
    else
        return nil
    end

    local channelNum, channelNameResult = GetChannelName(channelName)
    if channelNum and channelNum > 0 and channelNameResult then
        return channelNum
    end
    return nil
end

-- 频道管理.切频道：在当前聊天框打开输入框并预填频道命令，不自动发送
-- 12.1.5：优先用 ChatFrameUtil.OpenChat(text, chatFrame)，旧别名仅兜底。
function channelManager:switchToChannel(channelCmd)
    local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
    local openChat = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
    if chatFrame and openChat then
        openChat(channelCmd, chatFrame)
        return true
    end
    return false
end

-- 频道管理.加入频道：通过 /join 命令把频道名加入并订阅到聊天窗口
function channelManager:joinChannelToChatFrame(channelName)
    if SlashCmdList and SlashCmdList["JOIN"] then
        SlashCmdList["JOIN"](channelName)
        return true
    end
    utils.printColored("ff0000", "无法调用 /join 命令，请检查是否有其它聊天插件冲突")
    return false
end

-- UI 管理模块：创建按钮、设字体与点击事件、按数量计算并设置框体尺寸
local uiManager = {
    buttons = {}
}

-- UI.创建按钮：新建一个按钮并链式锚定到前一个按钮，同时完成字体与事件绑定
function uiManager:createButton(parent, buttonConfig, prevButton)
    local btn = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
    btn:SetSize(config.btnSize, config.btnSize)
    btn:SetText(buttonConfig.text)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self:setupButtonFont(btn, buttonConfig)
    self:setupButtonEvents(btn, buttonConfig)

    if prevButton then
        btn:SetPoint("LEFT", prevButton, "RIGHT", config.btnGap, 0)
    else
        btn:SetPoint("LEFT")
    end

    table.insert(self.buttons, btn)
    return btn
end

-- UI.设按钮字体：居中、设配置字号、按当前配色给文字上色
function uiManager:setupButtonFont(button, buttonConfig)
    local textObj = button:GetFontString()
    if textObj then
        textObj:ClearAllPoints()
        textObj:SetPoint("CENTER")

        local fontName, fontSize, fontFlags = utils.getScaledFont()
        textObj:SetFont(fontName, fontSize, fontFlags)

        local colorScheme = utils.getCurrentColorScheme()
        local color = colorScheme[buttonConfig.text]
        if color then
            textObj:SetTextColor(color[1], color[2], color[3])
        end
    end
end

-- UI.设按钮事件：为按钮绑定 OnClick，按 type（basic/custom/function）分派左右键行为
function uiManager:setupButtonEvents(button, btnConfig)
    button:SetScript("OnClick", function(self, mouseButton)
        if btnConfig.type == "basic" then
            if mouseButton == "LeftButton" then
                channelManager:switchToChannel(btnConfig.cmd)
            end

        elseif btnConfig.type == "custom" then
            if mouseButton == "LeftButton" then
                if btnConfig.channelType == "world" then
                    if channelManager:isInChannel("world") then
                        local channelNum = channelManager:getChannelNum("world")
                        if channelNum then
                            channelManager:switchToChannel("/" .. channelNum .. " ")
                        else
                            utils.printColored("ffd700", "无法获取世界频道编号")
                        end
                    else
                        utils.printColored("ffd700", "你不在大脚世界频道，右键点击以加入")
                    end

                elseif btnConfig.channelType == "trade" then
                    local channelNum = channelManager:getChannelNum("trade")
                    if channelNum then
                        channelManager:switchToChannel("/" .. channelNum .. " ")
                    else
                        channelManager:switchToChannel("/2 ")
                    end
                end

            elseif mouseButton == "RightButton" then
                if btnConfig.channelType == "world" then
                    if channelManager:isInChannel("world") then
                        LeaveChannelByName(config.worldChannel)
                        utils.printColored("d20000", "已离开大脚世界频道")
                    else
                        if channelManager:joinChannelToChatFrame(config.worldChannel) then
                            utils.printColored("00d200", "已加入大脚世界频道")
                        end
                    end
                end
            end

        elseif btnConfig.type == "function" then
            -- "就" 按钮功能：12.0.7 起全局 DoReadyCheck 已废弃。
            if btnConfig.text == "就" then
                if mouseButton == "LeftButton" then
                    C_PartyInfo.DoReadyCheck()
                end

            -- "倒" 按钮功能
            elseif btnConfig.text == "倒" then
                if mouseButton == "LeftButton" then
                    C_PartyInfo.DoCountdown(5, nil)
                elseif mouseButton == "RightButton" then
                    C_PartyInfo.DoCountdown(10, nil)
                end

            -- "骰" 按钮功能
            elseif btnConfig.text == "骰" then
                if mouseButton == "LeftButton" then
                    RandomRoll(1, 100)
                elseif mouseButton == "RightButton" then
                    RandomRoll(1, 1000)
                end

            -- "R" 按钮功能
            elseif btnConfig.text == "R" then
                if mouseButton == "LeftButton" then
                    ReloadUI()
                elseif mouseButton == "RightButton" then
                    if SlashCmdList["MACRO"] then SlashCmdList["MACRO"]("/macro") end
                end
            end
        end
    end)
end

-- UI.初始化按钮：按 buttonDefinitions 顺序创建全部按钮并横向串联
function uiManager:initializeButtons(parent)
    local prevButton = nil
    for _, buttonConfig in ipairs(buttonDefinitions) do
        prevButton = self:createButton(parent, buttonConfig, prevButton)
    end
end

-- UI.设框体尺寸：按按钮数量、单按钮宽与间距计算总宽，高度固定为 btnSize
function uiManager:setupFrameSize(parent)
    local totalWidth = config.btnSize * #buttonDefinitions + config.btnGap * (#buttonDefinitions - 1)
    parent:SetSize(totalWidth, config.btnSize)
end

-- UI.即时刷新：设置界面改动后重设所有按钮尺寸/间距/字体/配色与条宽（不重建控件）
function uiManager:refreshButtons(parent)
    for i, btn in ipairs(self.buttons) do
        btn:SetSize(config.btnSize, config.btnSize)
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("LEFT")
        else
            btn:SetPoint("LEFT", self.buttons[i - 1], "RIGHT", config.btnGap, 0)
        end
        local def = buttonDefinitions[i]
        if def then self:setupButtonFont(btn, def) end
    end
    self:setupFrameSize(parent)
end

-- 自动加入模块：登录后按配置延迟加入大脚世界频道
local autoJoin = {}

-- 自动加入.加世界频道：配置开启且当前不在世界频道时，调用 /join 加入并提示
function autoJoin:autoJoinWorldChannel()
    if not config.autoJoinWorldChannel then
        return
    end

    if not channelManager:isInChannel("world") then
        if channelManager:joinChannelToChatFrame(config.worldChannel) then
            utils.printColored("00d200", "已自动加入大脚世界频道")
        end
    end
end

-- 自动加入.延迟加入：延迟 config.autoJoinDelay 秒后再执行加频道，等频道列表就绪
function autoJoin:delayedAutoJoin()
    C_Timer.After(config.autoJoinDelay, function()
        self:autoJoinWorldChannel()
    end)
end

-- 初始化模块：定位框体、建 UI、按顺序执行总初始化
local initManager = {}

-- 初始化.定位：把 ChannelBar 吸附到 attachTarget，目标不存在则回落 defaultPosition
function initManager:initializePosition()
    ChannelBar:ClearAllPoints()

    -- attachTarget 现在是全局变量名字符串，用 _G 解析为实际 frame
    local targetFrame = config.attachTarget and _G[config.attachTarget]

    -- 设置界面允许填任意全局名，故先确认它是可查询可见性的帧。
    if type(targetFrame) == "table" and type(targetFrame.IsVisible) == "function" and targetFrame:IsVisible() then
        local pos = config.attachPosition
        ChannelBar:SetPoint(pos.point, targetFrame, pos.relativePoint, pos.x, pos.y)
        local parent = targetFrame:GetParent() or targetFrame
        ChannelBar:SetParent(parent)
    else
        local pos = config.defaultPosition
        ChannelBar:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

-- 初始化.建 UI：设定框体防拖出屏幕、可接收鼠标，创建全部按钮并计算总尺寸
function initManager:initializeUI()
    ChannelBar:SetClampedToScreen(true)
    ChannelBar:EnableMouse(true)
    ChannelBar:SetSize(100, config.btnSize)
    uiManager:initializeButtons(ChannelBar)
    uiManager:setupFrameSize(ChannelBar)
end

-- 初始化.总入口：按依赖顺序执行 建查找表 → 建 UI → 定位
function initManager:initializeAll()
    if not ACM.db then ACM:InitDB() end
    channelManager:initialize()
    self:initializeUI()
    self:initializePosition()
end

-- 事件管理模块：分发插件加载与进入世界两个事件到具体处理器
local eventManager = {}

-- 事件.插件加载：命中本插件后注销 ADDON_LOADED、执行初始化、注册 PLAYER_ENTERING_WORLD
function eventManager:handleAddonLoaded(loadedAddon)
    if loadedAddon == addonName then
        ChannelBar:UnregisterEvent("ADDON_LOADED")
        initManager:initializeAll()
        ChannelBar:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
end

-- 事件.进入世界：仅在本次登录（isLogin）时触发延迟自动加入，reload 与切图不触发
function eventManager:handlePlayerEnteringWorld(isLogin, isReload)
    if isLogin then
        autoJoin:delayedAutoJoin()
    end
end

-- 主事件回调：ChannelBar 的统一 OnEvent，按事件名分发给 eventManager
local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        eventManager:handleAddonLoaded(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        eventManager:handlePlayerEnteringWorld(...)
    end
end

-- 注册事件
ChannelBar:SetScript("OnEvent", onEvent)
ChannelBar:RegisterEvent("ADDON_LOADED")

-- 设置界面统一应用入口（对应 PT:ApplyAll）
function ACM:RefreshBar()
    uiManager:refreshButtons(ChannelBar)
    initManager:initializePosition()
end

-- 小地图按钮左键：显示/隐藏快捷条（显隐状态写入 settings.barShown，重载后保留）。
function ACM:SetBarShown(shown)
    ACM:Set("barShown", shown and true or false)
    if ACM:Get("barShown") then ChannelBar:Show() else ChannelBar:Hide() end
end

function ACM:ToggleBar()
    ACM:SetBarShown(not ACM:Get("barShown"))
    if ACM.RefreshOptions then ACM:RefreshOptions() end
end
