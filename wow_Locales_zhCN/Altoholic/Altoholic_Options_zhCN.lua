-- Altoholic_Options 12.1.007 (zhCN 汉化 / Ade)
local L = AddonFactory:SetLocale("Altoholic", "zhCN")
if not L then return end

-- ** Menu **
L["Settings"] = "设置"
L["Calendar"] = "日历"
L["Tooltip"] = "提示信息"
L["Enabled"] = "启用"
L["Disabled"] = "禁用"
L["Character"] = "角色"
L["Characters"] = "多个角色"
L["Bank characters"] = "银行角色"
L["Account Sharing"] = "账户共享"
L["How to"] = "使用说明"
L["Saved Variables"] = "存档变量"
L["Getting support"] = "获取支持"
L["About"] = "关于"

L["CTRL_C_TO_COPY"] = "|cFF1CFAFECTRL+C|r 复制此地址，|cFF1CFAFEESC|r 隐藏"
L["WOWI_ICON_ON_ENTER"] = "点击显示该插件在 WoW Interface 上的主页"
L["CURSE_ICON_ON_ENTER"] = "点击显示该插件在 Curseforge 上的主页"
L["DISCORD_ICON_ON_ENTER"] = "点击显示 Discord 服务器地址"
L["EMAIL_ICON_ON_ENTER"] = "点击显示 Thaoky 的电子邮件地址"
L["GITHUB_ICON_ON_ENTER"] = "点击显示 Thaoky 的 Github 地址"
L["TAB_NOT_LOADED_YET"] = "标签页尚未加载"

-- ** Settings / Altoholic / General **
L["General Options"] = "通用设置"
L["Minimap Icon Angle"] = "迷你地图图标角度"
L["Minimap Icon Radius"] = "迷你地图图标半径"
L["Transparency"] = "透明度"

L["BANK_AUTO_UPDATE_TEXT"] = "自动授权公会仓库更新"
L["BANK_AUTO_UPDATE_TITLE"] = "公会银行更新"
L["BANK_AUTO_UPDATE_ENABLED"] = "同样使用 Altoholic 的公会成员，若其公会银行信息更新，将能自动与你的同步。"
L["BANK_AUTO_UPDATE_DISABLED"] = "发送任何信息前都需要你的确认。"

L["CLAMP_TO_SCREEN_TEXT"] = "窗口始终在屏幕内"
L["CLAMP_TO_SCREEN_TITLE"] = "窗口始终在屏幕内"
L["CLAMP_TO_SCREEN_ENABLED"] = "Altoholic 的界面不会超出屏幕边界"
L["CLAMP_TO_SCREEN_DISABLED"] = "Altoholic 的界面可移动到任意位置，部分可移出屏幕"

L["SHOW_ICON_TEXT"] = "显示迷你地图图标"
L["SHOW_ICON_TITLE"] = "显示迷你地图图标"
L["SHOW_ICON_ENABLED"] = "Altoholic 的图标会显示在迷你地图周围"
L["SHOW_ICON_DISABLED"] = "Altoholic 的图标将被隐藏"

L["Move to change the angle of the minimap icon"] = "移动迷你地图图标的角度"
L["Move to change the radius of the minimap icon"] = "移动迷你地图图标的半径"
L["UI_SCALE_TOOLTIP"] = "拖动以更改界面缩放"
L["UI_TRANSPARENCY_TOOLTIP"] = "拖动以使界面透明"


-- ** Settings / Altoholic / Mail **
L["Mail Options"] = "邮件设置"

L["AUTO_COMPLETE_PRIORITY"] = "自动补全优先级"
L["AUTO_COMPLETE_BY_NAME"] = "字母顺序"
L["AUTO_COMPLETE_BY_MOST_PLAYED"] = "最长游戏时间"
L["AUTO_COMPLETE_BY_LAST_PLAYED"] = "最近游玩"

L["GUILD_WARNING_TEXT"] = "新邮件通知"
L["GUILD_WARNING_TITLE"] = "公会邮件通知"
L["GUILD_WARNING_ENABLED"] = "当公会成员给你的某个小号发送邮件时，你会收到通知。\n\n无需重新登录该小号即可直接查看邮件内容。"
L["GUILD_WARNING_DISABLED"] = "邮件仍会直接放入你小号的邮箱，但你不会收到通知。"

L["AUTO_COMPLETE_TEXT"] = "自动补全收件人名称"
L["AUTO_COMPLETE_TITLE"] = "自动补全收件人名称"
L["AUTO_COMPLETE_ENABLED"] = "在邮箱填写收件人名称时，会建议使用你小号的名字。"
L["AUTO_COMPLETE_DISABLED"] = "不会使用你小号的名字作为建议。"

L["TIME_TO_NEXT_WARNING_TEXT"] = "距下次警告的时间"
L["TIME_TO_NEXT_WARNING_TOOLTIP"] = "收到下次邮件过期警告前的最短间隔。"


-- ** Settings / Altoholic / Tooltip **
L["Tooltip Options"] = "提示信息设置"

L["TT_SHOW_ITEMSOURCE_TEXT"] = "显示物品来源"
L["TT_SHOW_ITEMSOURCE_TITLE"] = "物品来源"
L["TT_SHOW_ITEMSOURCE_ENABLED"] = [[
显示物品的来源信息，例如其所属专业或掉落的地下城。

例如：

 |cFFFFD700信息：|r |cFF00FF9A炼金术，65|r
 |cFFFFD700归入：|r |cFF00FF9A宝石袋|r

或

 |cFFFFD700团队副本：|r |cFF00FF9A熔火之心|r
 |cFFFFD700首领：|r |cFF00FF9ARagnaros|r]]
L["TT_SHOW_ITEMSOURCE_DISABLED"] = "不显示任何信息。"

L["TT_SHOW_ITEMCOUNT_TEXT"] = "显示每个角色的物品数量"
L["TT_SHOW_ITEMCOUNT_TITLE"] = "每个角色的物品数量"
L["TT_SHOW_ITEMCOUNT_ENABLED"] = [[
为拥有至少一件所指向物品的角色各显示一行信息。

例如：

    |cFF69CCF0Thaoky|r     |cFFFF7F003|r |cFFFFFFFF(背包：|cFF00FF9A3|r)|r
    |cFFABD473Sira|r           |cFFFF7F006|r |cFFFFFFFF(背包：|cFF00FF9A6|r)|r]]
L["TT_SHOW_ITEMCOUNT_DISABLED"] = "不显示任何信息。"

L["TT_SHOW_SIMPLECOUNT_TEXT"] = "显示物品总数量但不具体显示存放在哪"
L["TT_SHOW_SIMPLECOUNT_TITLE"] = "物品数量（无详情）"
L["TT_SHOW_SIMPLECOUNT_ENABLED"] = [[
仅显示角色拥有的物品数量，不包含位置。

例如：

    |cFF69CCF0Thaoky|r     |cFFFF7F003|r]]
L["TT_SHOW_SIMPLECOUNT_DISABLED"] = [[
位置信息将正常显示。

注意，此选项与
|cFFFF7F00按角色显示物品数量|r
相关联]]

L["TT_SHOW_TOTALCOUNT_TEXT"] = "显示所有角色的物品总计数量"
L["TT_SHOW_TOTALCOUNT_TITLE"] = "物品总数"
L["TT_SHOW_TOTALCOUNT_ENABLED"] = [[
显示提示信息中所列所有角色拥有的物品总数。

注意，此总数受多个其他提示信息选项影响，并取决于你选择显示哪些小号。

例如：

 |cFFFFD700拥有总数：|r |cFF00FF9A217|r]]
L["TT_SHOW_TOTALCOUNT_DISABLED"] = "不显示总计行。"

L["TT_SHOW_RECIPES_TEXT"] = "显示已学/可学的配方"
L["TT_SHOW_RECIPES_TITLE"] = "显示已学会/可学习的配方"
L["TT_SHOW_RECIPES_ENABLED"] = [[
显示哪些小号已经学会、可以学会或将来能够学会某配方。

例如：

    |cFF00FF9A已学会：|r |cFF69CCF0Thaoky|r
    |cFFFFFF00可学会：|r |cFFABD473Sira|r]]
L["TT_SHOW_RECIPES_DISABLED"] = "不显示任何信息。"

L["TT_SHOW_GUILDBANKCOUNT_TEXT"] = "显示公会银行计数"
L["TT_SHOW_GUILDBANKCOUNT_TITLE"] = "公会银行数量"
L["TT_SHOW_GUILDBANKCOUNT_ENABLED"] = [[
显示存储在公会银行中的物品总数。

例如：

    |cFF00FF00Odysseûs|r     |cFFFF7F0084|r |cFFFFFFFF(公会银行：|cFF00FF9A84|r)|r]]
L["TT_SHOW_GUILDBANKCOUNT_DISABLED"] = "不显示任何信息。"

L["TT_INCLUDE_GUILDBANKCOUNT_TEXT"] = "物品总计数量包含公会银行计数"
L["TT_INCLUDE_GUILDBANKCOUNT_TITLE"] = "在总数中包含公会银行数量"
L["TT_INCLUDE_GUILDBANKCOUNT_ENABLED"] = "存储在公会银行中的物品数量将计入总数。"
L["TT_INCLUDE_GUILDBANKCOUNT_DISABLED"] = "存储在公会银行中的物品数量将被忽略。"

L["TT_DETAILED_BANKCOUNT_TEXT"] = "公会银行计数显示具体标签页名字"
L["TT_DETAILED_BANKCOUNT_TITLE"] = "详细的公会银行数量"
L["TT_DETAILED_BANKCOUNT_ENABLED"] = [[
按分页显示存储在公会银行中的物品数量。

例如：

    |cFF00FF00Odysseûs|r     |cFFFF7F0084|r |cFFFFFFFF(消耗品：|cFF00FF9A84|r)|r]]
L["TT_DETAILED_BANKCOUNT_DISABLED"] = "显示“公会银行”而非分页名称。"

L["TT_SHOW_GUILDBANKREALM_TEXT"] = "显示公会银行所在的服务器"
L["TT_SHOW_GUILDBANKREALM_TITLE"] = "公会银行服务器"
L["TT_SHOW_GUILDBANKREALM_ENABLED"] = [[
显示公会银行所在的服务器。

例如：

    |cFF00FF00Odysseûs|r |cFFFFFF00(赞加沼泽)|r    |cFFFF7F0084|r |cFFFFFFFF(公会银行：|cFF00FF9A84|r)|r]]
L["TT_SHOW_GUILDBANKREALM_DISABLED"] = "仅显示公会名称"


L["TT_SHOW_ACCOUNTBANKCOUNT_TEXT"] = "显示战团银行计数"
L["TT_SHOW_ACCOUNTBANKCOUNT_TITLE"] = "战团银行数量"
L["TT_SHOW_ACCOUNTBANKCOUNT_ENABLED"] = "显示存储在战团银行中的物品总数。\n\n例如：\n\n    |cFF00FF00Account Bank|r     |cFFFF7F0084|r |cFFFFFFFF(战团银行 1: |cFF00FF9A84|r)|r"
L["TT_SHOW_ACCOUNTBANKCOUNT_DISABLED"] = "不显示任何信息。"


L["TT_SHOW_ITEMID_TEXT"] = "显示物品ID和物品等级"
L["TT_SHOW_ITEMID_TITLE"] = "物品 ID 与物品等级"
L["TT_SHOW_ITEMID_ENABLED"] = [[
在提示信息底部显示物品 ID 与物品等级。

例如：

    |cFFFFD700物品 ID：|r |cFF00FF00140192|r             |cFFFFD700装等：|r |cFF00FF0035|r]]
L["TT_SHOW_ITEMID_DISABLED"] = "不显示任何信息。"

L["TT_SHOW_ITEMXPACK_TEXT"] = "显示物品所属的内容版本等扩展信息"
L["TT_SHOW_ITEMXPACK_TITLE"] = "扩展物品信息"
L["TT_SHOW_ITEMXPACK_ENABLED"] = [[
显示物品的扩展信息，例如其所属资料片。

例如：

 |cFFFFD700信息：|r |cFF00FF9A炼金术，65|r
 |cFFFFD700归入：|r |cFF00FF9A宝石袋|r
 |cFFFFD700资料片：|r |cFF00FF9A燃烧的远征|r |cFFFFFF00(2.0)|r]]
L["TT_SHOW_ITEMXPACK_DISABLED"] = [[
不显示任何信息。

注意，此选项与
|cFFFF7F00显示物品来源|r
相关联]]


L["TT_SHOW_COULDBESTORED_TEXT"] = "显示可替代存储的位置"
L["TT_SHOW_COULDBESTORED_TITLE"] = "显示备用存储位置"
L["TT_SHOW_COULDBESTORED_ENABLED"] = "显示往期资料片的材料可存放在哪个银行小号。\n\n例如：\n\n |cFFFFD700可存放在：|r |cFF69CCF0Thaoky|r"
L["TT_SHOW_COULDBESTORED_DISABLED"] = "不显示任何信息。"


L["TT_SHOW_NODES_TEXT"] = "鼠标滑过草药矿点时显示该物品的已有数量"
L["TT_SHOW_NODES_TITLE"] = "在采集节点上显示计数"
L["TT_SHOW_NODES_ENABLED"] = "鼠标悬停在采集节点（草药、矿脉）上时，显示拥有的相关物品数量。"
L["TT_SHOW_NODES_DISABLED"] = "不显示任何信息。"

L["TT_SHOW_BOTHFACTIONS_TEXT"] = "显示双方阵营的计数"
L["TT_SHOW_BOTHFACTIONS_TITLE"] = "显示双阵营计数"
L["TT_SHOW_BOTHFACTIONS_ENABLED"] = "显示对立阵营角色拥有的物品数量。"
L["TT_SHOW_BOTHFACTIONS_DISABLED"] = "仅显示当前阵营的信息。"

L["TT_SHOW_MERGEDREALMS_TEXT"] = "显示当前服务器的计数"
L["TT_SHOW_MERGEDREALMS_TITLE"] = "显示连通服务器计数"
L["TT_SHOW_MERGEDREALMS_ENABLED"] = "显示与当前服务器连通的服务器上角色拥有的物品数量。"
L["TT_SHOW_MERGEDREALMS_DISABLED"] = "仅显示当前服务器的信息。"

L["TT_SHOW_ALLREALMS_TEXT"] = "显示所有服务器的计数"
L["TT_SHOW_ALLREALMS_TITLE"] = "显示所有服务器计数"
L["TT_SHOW_ALLREALMS_ENABLED"] = "账号绑定物品也会显示来自所有服务器的信息。"
L["TT_SHOW_ALLREALMS_DISABLED"] = [[
仅显示当前服务器的信息。

注意：对于账号绑定物品，此选项优先于 |cFFFF7F00显示连通服务器的计数|r。]]

L["TT_SHOW_ALLACCOUNTS_TEXT"] = "显示所有帐号的计数"
L["TT_SHOW_ALLACCOUNTS_TITLE"] = "显示所有账号计数"
L["TT_SHOW_ALLACCOUNTS_ENABLED"] = "也会显示所有已导入账号的信息。"
L["TT_SHOW_ALLACCOUNTS_DISABLED"] = "仅显示当前账号的信息。"

L["TT_SHOW_HEARTHSTONE_TEXT"] = "显示炉石的计数"
L["TT_SHOW_HEARTHSTONE_TITLE"] = "显示炉石计数"
L["TT_SHOW_HEARTHSTONE_ENABLED"] = "鼠标悬停在炉石、海军上将的罗盘或飞行管理员的哨子上时显示计数。"
L["TT_SHOW_HEARTHSTONE_DISABLED"] = "悬停在这些物品上时隐藏计数。"



-- ** Settings / Altoholic / Calendar **
L["Calendar Options"] = "日历选项"
L["Week starts on Monday"] = "每周从周一开始"
L["Profession Cooldowns"] = "专业冷却"
L["Dungeon Resets"] = "地下城重置"
L["Calendar Events"] = "日历事件"
L["Item Timers"] = "物品计时器"

-- ** Settings / Altoholic / Miscellaneous **
L["Miscellaneous Options"] = "杂项选项"
L["Use color-coding for recipes at the AH"] = "对拍卖行配方使用色调配置"
L["Use color-coding for recipes at vendors"] = "对商人内配方使用色调配置"


-- ** Settings / DataStore / Auctions **
L["DataStore_Auctions' Options"] = "DataStore_Auctions 选项"

L["LAST_VISIT_SLIDER_LABEL"] = "上次访问警告"
L["LAST_VISIT_SLIDER_TITLE"] = "上次访问拍卖行警告"
L["LAST_VISIT_SLIDER_TOOLTIP"] = "当拍卖行超过此天数未被访问时发出警告"

L["LAST_VISIT_CHECK_DISABLED"] = "不会检查上次访问拍卖行的时间。"
L["LAST_VISIT_CHECK_ENABLED"] = "将检查每个角色上次访问拍卖行的时间。超过此天数的角色会向客户端插件发送通知。"
L["LAST_VISIT_CHECK_LABEL"] = "上次访问拍卖行"
L["LAST_VISIT_CHECK_TITLE"] = "检查上次访问时间"

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "过期物品会保留在数据库中，直到玩家下次访问拍卖行。"
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "过期物品会从数据库中自动删除。"
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "自动清理过期拍卖与竞标"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "清理拍卖行物品"

-- ** Settings / DataStore / Characters **
L["DataStore_Characters' Options"] = "DataStore_Characters 选项"
L["HIDE_PLAYTIME_DISABLED"] = "将显示真实游戏时间。"
L["HIDE_PLAYTIME_ENABLED"] = "将显示为零天的游戏时间。"
L["HIDE_PLAYTIME_TEXT"] = "隐藏真实游戏时间。"
L["HIDE_PLAYTIME_TITLE"] = "隐藏真实游戏时间"

L["REQUEST_PLAYTIME_DISABLED"] = "登录时不会查询游戏时间。将向客户端插件发送上次已知值。"
L["REQUEST_PLAYTIME_ENABLED"] = "每次登录时都会查询游戏时间。"
L["REQUEST_PLAYTIME_TEXT"] = "登录时请求游戏时间。"
L["REQUEST_PLAYTIME_TITLE"] = "请求游戏时间"


-- ** Settings / DataStore / Garrisons **
L["DataStore_Garrisons' Options"] = "DataStore_Garrisons 选项"
L["REPORT_LEVEL_LABEL"] = "在 %s%s 处报告"
L["REPORT_LEVEL_TITLE"] = "报告等级阈值"
L["REPORT_LEVEL_TOOLTIP"] = "当未收集资源的等级高于此值时发出报告"

L["REPORT_UNCOLLECTED_LABEL"] = "报告未收集资源"
L["REPORT_UNCOLLECTED_TITLE"] = "报告未收集资源"
L["REPORT_UNCOLLECTED_ENABLED"] = "登录时，未收集资源超过 400 的小号将报告到聊天框。"
L["REPORT_UNCOLLECTED_DISABLED"] = "不会报告任何内容。"
L["UNCOLLECTED_RESOURCES_ALERT"] = "%s 有 %s 个未收集资源"

-- ** Settings / DataStore / Inventory **
L["DataStore_Inventory's Options"] = "DataStore_Inventory 选项"
L["CLEAR_INVENTORY_TEXT"] = "自动清理公会成员的装备"
L["CLEAR_INVENTORY_TITLE"] = "清理公会成员装备"
L["CLEAR_INVENTORY_ENABLED"] = "为节省内存，本地公会成员的背包会在每次登录时清空。"
L["CLEAR_INVENTORY_DISABLED"] = "公会成员的装备会保留在数据库中，即使离线也可见。"

L["BROADCAST_AIL_TEXT"] = "登录时向公会广播我的平均物品等级"
L["BROADCAST_AIL_TITLE"] = "广播平均物品等级"
L["BROADCAST_AIL_ENABLED"] = "登录时，你小号的平均物品等级会发送到公会频道。"
L["BROADCAST_AIL_DISABLED"] = "完全不发送任何内容。"

L["EQUIP_REQ_TEXT"] = "当有人查看我某个小号的装备时收到通知。"
L["EQUIP_REQ_TITLE"] = "装备请求通知"
L["EQUIP_REQ_ENABLED"] = "聊天消息会告知你哪位公会成员正在查看哪个小号。"
L["EQUIP_REQ_DISABLED"] = "完全不会显示任何内容。"

-- ** Settings / DataStore / Mails **
L["DataStore_Mails' Options"] = "DataStore_Mails 选项"

L["SLIDER_EXPIRY_TITLE"] = "邮件过期阈值"
L["SLIDER_EXPIRY_TOOLTIP"] = "当邮件在少于此天数的时间内过期时发出警告"

L["EXPIRY_CHECK_LABEL"] = "邮件过期警告"
L["EXPIRY_CHECK_TITLE"] = "检查邮件过期"
L["EXPIRY_CHECK_ENABLED"] = "登录 5 秒后检查邮件过期。若发现至少一封过期邮件，客户端插件会收到通知。"
L["EXPIRY_CHECK_DISABLED"] = "不执行任何过期检查。"

L["REPORT_EXPIRED_MAILS_LABEL"] = "邮件过期警告（聊天框）"
L["REPORT_EXPIRED_MAILS_TITLE"] = "邮件过期警告（聊天框）"
L["REPORT_EXPIRED_MAILS_ENABLED"] = "邮件过期检查期间，过期邮件的角色列表也会显示在聊天框中。"
L["REPORT_EXPIRED_MAILS_DISABLED"] = "聊天框中不显示任何内容。"

L["SCAN_MAIL_BODY_LABEL"] = "扫描邮件内容(标记为已读)"
L["SCAN_MAIL_BODY_TITLE"] = "扫描邮件正文"
L["SCAN_MAIL_BODY_ENABLED"] = "扫描邮箱时会读取每封邮件的正文。所有邮件都会被标记为已读。"
L["SCAN_MAIL_BODY_DISABLED"] = "仅读取邮件附件。邮件会保持未读状态。"

L["EXPIRY_ALL_ACCOUNTS_LABEL"] = "检查所有已知账号的邮件过期"
L["EXPIRY_ALL_ACCOUNTS_TITLE"] = "检查所有账号"
L["EXPIRY_ALL_ACCOUNTS_ENABLED"] = "过期检查例程会查找所有已知账号上的过期邮件。"
L["EXPIRY_ALL_ACCOUNTS_DISABLED"] = "仅考虑当前账号；导入的账号将被忽略。"

L["EXPIRY_ALL_REALMS_LABEL"] = "检查所有已知服务器的邮件过期"
L["EXPIRY_ALL_REALMS_TITLE"] = "检查所有服务器"
L["EXPIRY_ALL_REALMS_ENABLED"] = "过期检查例程会查找所有已知服务器上的过期邮件。"
L["EXPIRY_ALL_REALMS_DISABLED"] = "仅考虑当前服务器；其他服务器将被忽略。"

L["EXPIRED_EMAILS_WARNING"] = "%s (%s) 有已过期（或即将过期）的邮件"

-- ** Settings / DataStore / Quests **
L["DataStore_Quests' Options"] = "DataStore_Quests 选项"

L["TRACK_TURNINS_LABEL"] = "追踪任务交付"
L["TRACK_TURNINS_TITLE"] = "追踪任务交付"
L["TRACK_TURNINS_ENABLED"] = "已交付的任务会保存到历史记录中，以确保其始终保持有效。"
L["TRACK_TURNINS_DISABLED"] = "任务历史将保持当前状态，可能为空或过期。"

L["AUTO_UPDATE_LABEL"] = "自动更新历史"
L["AUTO_UPDATE_TITLE"] = "自动更新任务历史"
L["AUTO_UPDATE_ENABLED"] = "每次以该角色登录时，其任务历史都会刷新。"
L["AUTO_UPDATE_DISABLED"] = "任务历史将保持当前状态，可能为空或过期。"

L["DAILY_QUESTS_RESET_LABEL"] = "每日任务重置于"


-- ** Sharing / Authorizations **
L["Authorizations"] = "授权"
L["Ask"] = "询问"
L["Auto"] = "自动"

L["ACCOUNT_SHARING_ACTIVE_LABEL"] = "账户共享已启用"
L["ACCOUNT_SHARING_ACTIVE_TITLE"] = "账户共享已启用"
L["ACCOUNT_SHARING_ACTIVE_ENABLED"] = [[
其他用户将被允许向你发送账户共享请求。

无论何时有人请求你的信息，仍然需要你的确认。]]
L["ACCOUNT_SHARING_ACTIVE_DISABLED"] = [[
所有请求都将被自动拒绝。

|cFF1CFAFE安全提示|r：仅在确实需要传输数据时才启用，否则请禁用。]]

L["ACCOUNT_SHARING_AUTH_INFO"] = [[
此列表允许你自动响应账户共享请求。
你可以选择自动|cFF00FF00接受|r或|cFFFF0000拒绝|r请求，或在请求到来时被|cFFFFFF00询问|r。
如果账户共享完全禁用，此列表将被忽略，所有请求都会被拒绝。]]

L["ACCOUNT_SHARING_AUTH_ASK"] = "当该玩家发送账户共享请求时询问我"
L["ACCOUNT_SHARING_AUTH_AUTO"] = "自动授权该玩家发送的账户共享请求"
L["ACCOUNT_SHARING_AUTH_NEVER"] = "自动拒绝该玩家发送的账户共享请求"

-- ** Sharing / Content **
L["Shared Content"] = "共享内容"


L["SHARED_CONTENT_INFO"] = "选择将对你发送账户共享请求的玩家可见的内容。"

-- ** Sharing / Share ! **
L["Share"] = "共享"
L["Account Name"] = "账号名称"
L["Send account sharing request to:"] = "发送账户共享请求给："
L["Send Request"] = "发送请求"
L["Request Content"] = "请求内容"

L["ACCOUNT_NAME_INFO"] = [[
输入一个仅用于|cFF00FF00显示|r的账户名称。

此名称可以是你喜欢的任意内容，并|cFFFF0000不|r需要是真实账户名。此字段|cFFFF0000不能|r留空。]]

L["EMPTY_ACCOUNT_WARNING"] = "[账号名称] 此字段 |cFF00FF00不能|r 留空。"



-- ** Help **
L["HELP_SHARING_HOWTO"] = [[
|cFF00FF00Q:|cFFFFFFFF 如何在两个账号之间共享数据？|r|r

要使用该功能，两个账号必须同时在线。如果你同时拥有两个账号，需要运行两个并行的 WoW 客户端实例。

|cFF00FF00Q:|cFFFFFFFF 信息传递是双向的吗？|r|r

不是。传输使用游戏的通信频道，因此吞吐量受到限制。如果你希望两边都有相同的数据，必须将过程重复两次。

|cFF00FF00Q:|cFFFFFFFF 共享数据前需要做任何设置吗？|r|r

需要。出于安全考虑，账户共享默认禁用，因此第一步是在两边都启用它，这可以在|cFF1CFAFE2|r|cFFFFFFFF. 授权|r中完成。

下一步是设置授权。接收信息的账号必须确定谁可以向其发送请求。任何不在列表中的请求者都会看到自己的请求被拒绝。

最后一步是确定共享哪些信息，这可以在|cFF1CFAFE3|r|cFFFFFFFF. 共享内容|r中完成。

|cFF00FF00Q:|cFFFFFFFF 传输看起来很慢，有时甚至停滞，这是什么问题？|r|r

如上所述，传输使用游戏的通信频道，这意味着所有信息都是通过暴雪服务器从账号 A 发送到账号 B。这需要时间，请耐心等待。只要没有 Lua 错误，你就没问题，数据终将送达。

|cFF00FF00Q:|cFFFFFFFF 这个过程能优化吗？|r|r

不能。数据在发送前会经过压缩以尽量减小网络流量，但你共享的信息越多，耗时就越长。如果你对此过程有疑虑，先用一个角色测试以验证其正常运作，然后再尝试更多角色。]]

L["HELP_ALTOHOLIC_GENERAL"] = [[
|cFF00FF00Q:|cFFFFFFFF 这个插件是如何工作的？|r|r

当你的某个小号进入世界时，尽可能多的信息会自动填入插件的数据库。
然而，其中部分信息除非你触发使其可用的事件，否则无法读取。这是游戏施加的限制，而非插件的局限。

|cFF00FF00Q:|cFFFFFFFF 是哪类信息？|r|r

邮箱、拍卖行以及你的个人银行和公会银行都受此限制。
你的角色必须亲自出现在这些地点，插件才能读取相关信息。

专业信息也受影响，你必须打开每个专业的面板才能充分享受插件的功能。

|cFF00FF00Q:|cFFFFFFFF Altoholic 支持命令行选项吗？|r|r

支持，输入|cFFFF7F00/alto|r或|cFFFF7F00/altoholic|r可获取命令行选项列表。

|cFF00FF00Q:|cFFFFFFFF 我的迷你地图图标不见了，怎么恢复？|r|r

停留在“选项”标签页，点击|cFFFF7F00设置 => Altoholic => 通用|r，然后勾选“显示迷你地图图标”选项。

|cFF00FF00Q:|cFFFFFFFF 我可以把 Altoholic 绑定到特定按键吗？|r|r

可以。使用游戏的|cFFFF7F00按键绑定|r菜单选择你最喜欢的按键。

我个人将它绑定到|cFF1CFAFEJ|r键，因为键脊让它很容易找到。]]

L["HELP_ALTOHOLIC_CHARACTERS"] = [[
|cFF00FF00Q:|cFFFFFFFF 为什么我只能看到一个角色？|r|r

如果你是第一次使用本插件，这是正常的。插件只能获取你当前所玩角色的信息。这是游戏的又一项限制。

|cFF00FF00Q:|cFFFFFFFF 你是说我得把 37 个小号一个个登录一遍？？？|r|r

是的，别无他法。

|cFF00FF00Q:|cFFFFFFFF 我删除了一个角色，或把它转移到了另一个服务器，为什么插件看不到它？|r|r

插件仅在游戏运行且你的角色处于游戏世界中时才处于活动状态。在那之外发生的一切都超出了所有插件的能力范围。
如果你有一个残留的小号，可以直接在插件中删除它。

|cFF00FF00Q:|cFFFFFFFF 如何从插件的数据库中删除一个角色？|r|r

前往|cFFFF7F00摘要|r标签页，|cFF1CFAFE右键|r点击该角色的名字，选择|cFFFF7F00删除此角色|r。

|cFF00FF00Q:|cFFFFFFFF 我一个角色都看不到，这是怎么回事？|r|r

可能有两个原因：

- 你可能在|cFFFF7F00账号摘要|r中组合了某些筛选器，导致没有任何角色被显示，因此请检查你的筛选设置。

- 可能存在一个未显示的 Lua 错误。

请务必用以下命令启用 Lua 错误显示：|cFFFFFFFF/console scriptErrors|r |cFF00FF001|r

如果你想之后禁用 Lua 错误：|cFFFFFFFF/console scriptErrors|r |cFF00FF000|r]]

L["HELP_DATASTORE_GENERAL"] = [[
|cFF00FF00Q:|cFFFFFFFF 什么是 DataStore？|r|r

DataStore 是一系列插件的核心组件，这些插件在游戏中充当数据存储库。它们各自的目的是为其他插件提供扫描和存储服务。

|cFF00FF00Q:|cFFFFFFFF 为什么要这么做？现在光是这个就有 17 个文件夹了！|r|r

这对玩家和开发者都有多重好处：

- 数据对所有客户端插件只|cFFFF7F00扫描|r一次（|cFF00FF00性能提升|r）。

- 数据对所有客户端插件只|cFFFF7F00存储|r一次（|cFF00FF00内存节省|r）。

- 插件作者可以把更多时间花在编写高层功能上。

- 每个模块都是一个独立的插件，因此拥有自己的 SavedVariables 文件，意味着你可以清理某个模块的数据而不影响其他模块。

|cFF00FF00Q:|cFFFFFFFF 这些模块都是做什么的？我需要全部启用吗？|r|r

|cFFFF7F00DataStore|r是主模块，客户端插件应当对它有依赖，因此它应当始终保持启用，因为它是用于访问各模块数据的接口。
其他模块在技术上都是可选的，可以根据你的需要启用或禁用。不过，其中一些模块（如|cFFFF7F00DataStore_Characters|r）在 Altoholic 中扮演重要角色，必须保持启用。

|cFF00FF00Q:|cFFFFFFFF 我应该如何更新 DataStore 及其模块？|r|r

|cFF1CFAFEAltoholic|r始终随最新版本一同打包，大多数用户应当用这种方式升级。请参阅|cFFFF7F00关于|r面板中插件的官网主页。]]

L["HELP_DATASTORE_SAVEDVARS"] = [[
|cFF00FF00Q:|cFFFFFFFF 如何清除 DataStore 中的数据？|r|r

角色和公会可以从 Altoholic 的界面中擦除。
如果你希望对要删除的信息有更多掌控，可以|cFF1CFAFE编辑|r或|cFF1CFAFE移除|r|cFFFF7F00存档变量|r文件夹中的文件。

|cFF00FF00Q:|cFFFFFFFF 存档变量在哪里？|r|r

数据库位于 |cFFFF7F00WTF \\ Account \\ |cFF1CFAFE你的账号|r \\ SavedVariables|r。

|cFF00FF00Q:|cFFFFFFFF 相关文件有哪些？|r|r

文件为|cFFFF7F00DataStore.lua|r以及所有|cFFFF7F00DataStore_*.lua|r。

|cFF00FF00Q:|cFFFFFFFF 我何时可以|cFF1CFAFE修改|r或|cFF1CFAFE删除|r那些文件？|r|r

|cFFFF0000切勿|r在游戏运行时|cFFFF0000修改|r这些文件，这一点|cFFFF0000极为关键|r。
有人试过，结果遇到了问题。

不要试图比游戏更聪明。
关掉它，做出你的更改，然后再启动它。

|cFF00FF00Q:|cFFFFFFFF 我该如何编辑那些文件？|r|r

使用合适的文本编辑器，例如|cFF1CFAFENotepad++|r。

传统的记事本和写字板不推荐使用。]]

L["HELP_GETTING_SUPPORT"] = [[
|cFF00FF00Q:|cFFFFFFFF 我发现了错误，如何/在哪里报告？|r|r

使用 CurseForge 的工单板块，我也会阅读评论并尽可能频繁地回复，欢迎在这些地方之一报告。

|cFF00FF00Q:|cFFFFFFFF 报告前我应该做什么？|r|r

几件事：

|cFF1CFAFE1)|r 确保你拥有插件的最新版本。

|cFF1CFAFE2)|r 如果你怀疑与其他插件冲突，尝试仅启用 Altoholic 来复现问题。由于本插件涉及众多功能，冲突总是有可能的。

|cFF1CFAFE3)|r 确保你的问题尚未被其他人报告过。

|cFF1CFAFE4)|r 永远、永远不要报告“它不工作”，这是世界上最无用的话！
要|cFFFF7F00具体|r说明哪里不工作。

|cFF1CFAFE5)|r |cFFFF0000切勿|r在 Lua 错误时复制整个调用栈。前 5-6 行就足够了。

|cFF00FF00Q:|cFFFFFFFF 我遇到多个错误，应该全部报告吗？|r|r

不，只需报告列表中的第一个，其余通常是第一个引发的后果。

|cFF00FF00Q:|cFFFFFFFF 我在哪里可以获得实时支持？|r|r

加入|cFF1CFAFEDiscord|r服务器。我通常在傍晚（比利时时间）在线，即便我不在，我们也有一个友善的社区随时准备在出现问题时提供帮助。]]

L["ABOUT_ALTOHOLIC"] = [[
|cFF00FF00Q:|cFFFFFFFF Altoholic 是什么时候开始的？|r|r

开发始于|cFF1CFAFE2007 年 12 月|r，首个公开发布的版本是|cFFFF7F002.4.001|r，发布于|cFF1CFAFE2008 年 3 月 29 日|r。

|cFF00FF00Q:|cFFFFFFFF 有多少人参与开发 Altoholic？|r|r

一个人。我有一份全职工作，可投入的时间时多时少。不过我偶尔会获得社区的帮助，我想感谢这些年来伸出援手的所有人。
没有你们的帮助和建议，这个插件不会是今天的样子。

|cFF00FF00Q:|cFFFFFFFF 插件支持多少种语言？|r|r

十一种：deDE、enUS、esES、esMX、frFR、itIT、koKR、ptBR、ruRU、zhCN、zhCW。

|cFF00FF00Q:|cFFFFFFFF 我可以帮忙做本地化吗？|r|r

可以！非常欢迎你的帮助，加入我们的|cFF1CFAFEDiscord|r并提供翻译文件。

|cFF1CFAFENote|r：翻译现在分散在多个 Altoholic* 插件中（每个标签页一个）。

|cFF00FF00Q:|cFFFFFFFF 我在哪里获取更新？|r|r

唯二官方来源是|cFFFF7F00Curse Forge|r和|cFFFF7F00WoW Interface|r。

任何其他来源都意味着你在使用非官方版本，且没有支持为开发所投入的巨大努力。

对于任何此类版本，绝对|cFFFF0000不予|r支持。]]

L["ABOUT_DATASTORE"] = [[
|cFF00FF00Q:|cFFFFFFFF DataStore 为何而创建？|r|r

DataStore 发布于|cFF1CFAFE2009 年 8 月|r，作为|cFFFF7F003.2|r版本的一部分。

在约 18 个月学习 WoW 开发、为 Altoholic 添加功能并管理一个单体数据库之后，我觉得是时候采用更专业的方式，于是创建了一个适当的层来管理所有数据。

|cFF00FF00Q:|cFFFFFFFF 为什么要分离数据与界面？|r|r

因为这是正确的做法，也因为当时以及至今，我心中仍有多个插件打算利用这些信息。

此外，它提供了一个干净的接口来管理角色、公会、服务器和账号。

|cFF00FF00Q:|cFFFFFFFF 未来会有更多模块吗？|r|r

我对目前的模块感到满意，但如果有真实需求出现，也不排除添加更多。

|cFF00FF00Q:|cFFFFFFFF 我是一名开发者，想更多了解 DataStore！|r|r

代码注释详尽、结构清晰，基本不言自明。

如果仍有疑问，加入|cFF1CFAFEDiscord|r服务器来问我！]]

L["HELP_ALTOHOLIC_BANKCHARACTERS"] = [[
|cFF00FF00Q:|cFFFFFFFF 什么是银行角色？|r|r

如果你玩很多角色，很可能你正把其中一些当作银行使用。
Altoholic 现在有了在|cFFFF7F00摘要|r标签页中跟踪这一点的方法。

|cFF00FF00Q:|cFFFFFFFF 如何将一个角色标记为银行角色？|r|r

在|cFFFF7F00摘要|r标签页的任意面板中，|cFF1CFAFE右键|r点击该角色的名字，选择|cFFFF7F00标记为银行|r，然后选择该角色应作为的银行类型。

|cFF00FF00Q:|cFFFFFFFF 我能将一个银行角色标记为多种类型吗？|r|r

可以。

|cFF00FF00Q:|cFFFFFFFF 我在哪里可以总览我的银行角色？|r|r

在|cFFFF7F00摘要|r标签页，选择|cFFFF7F00杂项|r面板。

|cFF00FF00Q:|cFFFFFFFF 将角色标记为银行对我管理小号有什么帮助？|r|r

如果你愿意，某个提示信息选项将允许你查看是否可以将某物品发送给一个银行角色。]]

L["HELP_ALTOHOLIC_ALTGROUPS"] = [[
|cFF00FF00Q:|cFFFFFFFF 什么是小号分组？|r|r

小号分组是一种简单的方式，可根据与游戏无关的标准轻松管理你的小号。例如，我把 12 个主力小号放在一个组，把同一服务器上的 12 个银行小号放在另一个组。

|cFF00FF00Q:|cFFFFFFFF 一个组里的角色数量有限制吗？|r|r

没有。你也可以将来自另一个服务器、另一个阵营甚至另一个账号的小号加入同一组。

|cFF00FF00Q:|cFFFFFFFF 我能创建的组数量有限制吗？|r|r

没有，你可以创建任意多个组，尽管创建太多可能会违背分组的目的。你说了算，可以按你喜欢的方式组织分组。

|cFF00FF00Q:|cFFFFFFFF 如何将角色加入一个组？|r|r

在|cFFFF7F00摘要|r标签页的任意面板中，|cFF1CFAFE右键|r点击该角色的名字，选择|cFFFF7F00加入分组|r，然后选择该角色应加入的组。

|cFF00FF00Q:|cFFFFFFFF 如何将角色从一个组中移除？|r|r

在|cFFFF7F00摘要|r标签页的任意面板中，|cFF1CFAFE右键|r点击该角色的名字，选择|cFFFF7F00移出分组|r，然后选择该角色应被移除的组。

|cFF00FF00Q:|cFFFFFFFF 一个角色可以属于多个组吗？|r|r

可以。]]


L["HELP_ALTOHOLIC_SEARCH"] = [[
|cFF00FF00Q:|cFFFFFFFF 搜索过程是如何工作的？|r|r

该过程会查找所有激活的筛选器，并尝试找到匹配这些筛选器的物品和/或已知的专业配方。搜索只会发生在|cFFFF7F00搜索位置|r图标所设定的位置中。

|cFF00FF00Q:|cFFFFFFFF 筛选器只通过顶部图标设置吗？|r|r

不是，左侧的分类也充当筛选器。当你点击某个分类时，会立即触发对该分类匹配物品的搜索，然后你可以通过在编辑框中输入数值，或按稀有度等进一步筛选。如果你只输入文本并开始搜索，你会得到名称包含你所输入值的所有结果。

|cFF00FF00Q:|cFFFFFFFF 我对看到的结果感到困惑，这是怎么回事？|r|r

请记住，结果受你所设筛选器的影响。务必查看状态消息，了解搜索过程中考虑了哪些筛选器。
如有疑问，点击|cFF1CFAFEReset|r按钮清除所有筛选器再试一次。

|cFF00FF00Q:|cFFFFFFFF 有些结果缺失，为什么？|r|r

结果可能受游戏客户端已知物品的影响，你可能需要执行第二次搜索才能看到正确的结果。搜索过程所需的信息并不总是可用，等到它从服务器返回时，搜索已经结束了。

|cFF00FF00Q:|cFFFFFFFF 按稀有度或物品等级排序似乎不起作用，为什么？|r|r

按稀有度排序确实有效，但在可升级物品的情况下，它们可能拥有|cFF0070DD蓝色|r稀有度，而你实际拥有的是|cFFA335EE史诗|r版本，因为你有升级后的版本。]]


-- [ADE] 补全缺失 key
L["Alt groups"] = "小号分组"
L["TT_SHOW_CURRENCIES_TEXT"] = "显示货币计数"
L["TT_SHOW_CURRENCIES_TITLE"] = "显示货币计数"
L["TT_SHOW_CURRENCIES_ENABLED"] = "鼠标悬停在货币上时显示计数。"
L["TT_SHOW_CURRENCIES_DISABLED"] = "鼠标悬停在货币上时隐藏计数。"
L["CALENDAR_WEEKSTART_MONDAY_TEXT"] = "每周从周一开始"
L["CALENDAR_WEEKSTART_MONDAY_TITLE"] = "每周从周一开始"
L["CALENDAR_WEEKSTART_MONDAY_ENABLED"] = "待完成。"
L["CALENDAR_WEEKSTART_MONDAY_DISABLED"] = "待完成。"
L["CALENDAR_WARNINGS_DIALOG_TEXT"] = "在对话框中显示警告"
L["CALENDAR_WARNINGS_DIALOG_TITLE"] = "在对话框中显示警告"
L["CALENDAR_WARNINGS_DIALOG_ENABLED"] = "警告将在对话框中显示，而非聊天框。"
L["CALENDAR_WARNINGS_DIALOG_DISABLED"] = "警告仅在聊天框中显示。"
L["CALENDAR_WARNINGS_ENABLED_TEXT"] = "启用警告"
L["CALENDAR_WARNINGS_ENABLED_TITLE"] = "启用警告"
L["CALENDAR_WARNINGS_ENABLED_ENABLED"] = "当特定事件发生时，Altoholic 会触发警告。"
L["CALENDAR_WARNINGS_ENABLED_DISABLED"] = "Altoholic 不会触发任何警告。"
L["Up-to-date"] = "已是最新"
L["ADDON_MEMORY_USED"] = "已用内存 %s%d|r |4character:characters;:"
