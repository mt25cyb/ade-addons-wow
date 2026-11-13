-- Altoholic_Summary 12.1.007 (zhCN 汉化 / Ade)
local L = AddonFactory:SetLocale("Altoholic", "zhCN")
if not L then return end

L["Calendar"] = "日历"
L["Tooltip"] = "提示"
L["Getting support"] = "获取支持"
L["Memory used"] = "内存占用"
L["Reset all data"] = "重置所有数据"
L["WIPE_DATABASE"] = "清空数据库?"
L["WIPE_WARNING"] = "警告：所有信息都将丢失！"
L["DATABASE_WIPED"] = "数据库中所有存储信息删除完毕！"

L["Account"] = "帐号"
L["Default"] = "默认"
L["Characters"] = "角色"
L["Realms"] = "服务器"
L["%s%d%s characters found : did you set your filters properly ?"] = "发现%s%d%s个角色：你有正确设置过滤吗？"

-- ** Menu **
L["Character Information"] = "角色信息"
L["Account Summary"] = "帐号统计"
L["Experience"] = "经验"
L["Levels"] = "等级" --实际显示的是：等级，装等，名望等级和大米评分
L["Location"] = "位置"
L["Bag Usage"] = "背包用量"
L["Activity"] = "活跃度"
L["Currencies"] = "货币"
L["PATCH_X.0"] = "版本号"
L["PATCH_9.1"] = "统御之链"
L["PATCH_9.2"] = "永恒的终结"
L["PATCH_10.1"] = "奈萨里奥之烬"
L["PATCH_10.2"] = "梦境守护者"

-- ** Filter Icons **
L["FILTER_REALMS"] = "服务器过滤"
L["FILTER_FACTIONS"] = "阵营过滤"
L["FILTER_LEVELS"] = "等级过滤"
L["FILTER_PROFESSIONS"] = "专业过滤"
L["FILTER_CLASSES"] = "职业过滤"
L["FILTER_RACES"] = "种族过滤"
L["FILTER_MISC"] = "混合过滤"
L["FILTER_BANKTYPE"] = "角色库标签过滤"
L["This realm"] = "仅搜索该服务器"
L["All realms"] = "搜索所有服务器"
L["This account"] = "此账户"
L["All accounts"] = "所有账户"
L["This faction"] = "此阵营"
L["Both factions"] = "双方阵营"
L["Any"] = "所有"
L["Allied Races"] = "同盟种族"
L["ACCOUNT_SHARING_BUTTON_TITLE"] = "账户共享请求"
L["ACCOUNT_SHARING_BUTTON_INFO"] = [[点击此按钮来询问玩家
是否共享整个Altoholic数据库
并将其添加到自己的数据库]]

L["FILTER_ALT_GROUPS"] = "角色群组"
L["FILTER_GROUP_CREATE"] = "新建群组"
L["FILTER_GROUP_DELETE"] = "删除角色群组"
L["FILTER_GROUP_RENAME"] = "重命名角色群组"
L["ENTER_GROUP_NAME"] = "输入一个新的群组名称"
L["CHANGE_GROUP_NAME"] = "请输入替换 %s%s|r 的名称"
L["ENTER_GROUP_NAME_WARNING"] = "建议避免输入特殊符号"
L["DELETE_GROUP_NAME"] = "删除此小号分组？"
L["ALT_GROUP_CREATED"] = "角色群组 %s 已成功创建"
L["ALT_GROUP_ALREADY_EXISTS"] = "角色群组 %s 已经存在."
L["ALT_GROUP_RENAMED"] = "%s 成功重命名为 %s"
L["ALT_GROUP_NOT_RENAMED"] = "%s 无法重命名为 %s"
L["ALT_GROUP_DELETED"] = "角色群组 %s 已成功删除"
L["ALT_GROUP_NOT_FOUND"] = "角色群组 %s 未找到..."

L["COLORED_SKILL_LEVELS"] = "为技能等级着色"
L["FILTER_MISC_HAVE_MAILS"] = "有邮件"
L["FILTER_MISC_HAVE_MAILS_EXPIRE_SOON"] = "有快要过期的邮件"
L["FILTER_MISC_HAVE_AUCTIONS_EXPIRE_SOON"] = "拍卖行近期未查阅"
L["FILTER_MISC_GUILD_EXALTED"] = "已加入公会的"
L["FILTER_MISC_GUILD_NOT_EXALTED"] = "尚未有公会的"
L["FILTER_MISC_UPGRADE_RIDING_SKILL"] = "可升级坐骑骑术"


-- *** Character Information / Account Summary ***
-- Column Name
L["Totals"] = "总计"
L["Right-Click for options"] = "右键点击打开选项"
L["Character %s successfully deleted"] = "人物： %s 成功删除！"
L["Realm %s successfully deleted"] = "服务器 %s 删除成功"
L["Cannot delete current character"] = "无法删除当前人物镜像"
L["Cannot delete current realm"] = "无法删除当前服务器内容"
L["Delete this Alt"] = "删除该人物镜像"
L["Delete this Realm"] = "删除此服务器内容"
L["Update from %s%s"] = "从 %s%s 更新"

L["View"] = "浏览"
L["Mark as bank"] = "标记为银行"
L["Mark as profession bank"] = "添加角色库标签为专业"
L["Mark as expansion bank"] = "添加角色库标签为版本名称"
L["Add to group"] = "添加进角色群组"
L["Remove from group"] = "从角色群组删除"



-- Column Level
L["COLUMN_LEVEL_TITLE"] = "角色等级"
L["COLUMN_LEVEL_TITLE_SHORT"] = "等级"
L["COLUMN_LEVEL_SUBTITLE"] = "点击等级切换小数显示"

-- Column Rest XP
L["COLUMN_RESTXP_TITLE"] = "休息经验"
L["COLUMN_RESTXP_TITLE_SHORT"] = "休息XP"
L["COLUMN_RESTXP_SUBTITLE"] = " "
L["COLUMN_RESTXP_DETAIL_1"] = "每8个小时获得当前等级的5%的奖励经验"
L["COLUMN_RESTXP_DETAIL_2"] = "最多获得当前等级的150%的奖励经验"
L["COLUMN_RESTXP_DETAIL_3"] = "休息10天可获得最大奖励经验"
L["COLUMN_RESTXP_DETAIL_4"] = "%d%% 模式 : 充分休息显示为 '%d%%'"
L["Fully rested"] = "已充分休息"
L["Fully rested in"] = "充分休息时长"
L["CHARACTER_NOT_IN_RESTING_AREA"] = "该角色没有在休息区域!"

-- Column Money
L["COLUMN_MONEY_TITLE"] = "金钱"
L["COLUMN_MONEY_TITLE_SHORT"] = "金钱"
L["COLUMN_MONEY_SUBTITLE_1"] = "你的闪亮金币"
L["COLUMN_MONEY_SUBTITLE_2"] = "钱越多麻烦越多"
L["COLUMN_MONEY_SUBTITLE_3"] = "贪婪是好事"
L["COLUMN_MONEY_SUBTITLE_4"] = "买不到幸福……但能买一堆坐骑！"
L["COLUMN_MONEY_SUBTITLE_5"] = "世界之树不会长出金币"

-- Column Played
L["COLUMN_PLAYED_TITLE"] = "总游戏时间"
L["COLUMN_PLAYED_TITLE_SHORT"] = "游戏总时长"
L["COLUMN_PLAYED_SUBTITLE"] = "点击显示/隐藏真实游戏时间"

-- Column iLevel
L["COLUMN_ILEVEL_TITLE"] = "平均物品等级"
L["COLUMN_ILEVEL_TITLE_SHORT"] = "装等"
L["COLUMN_ILEVEL_SUBTITLE"] = "点击等级切换小数显示"

-- Column Last Online
L["COLUMN_LASTONLINE_TITLE"] = "上次在线"
L["COLUMN_LASTONLINE_TITLE_SHORT"] = "最后在线"
L["COLUMN_LASTONLINE_SUBTITLE"] = "角色上次登录的时间"

-- *** Character Information / Experience ***
L["COLUMN_MAXRESTXP_TITLE"] = "最大休息经验"
L["COLUMN_MAXRESTXP_TITLE_SHORT"] = "最大休息XP"
L["COLUMN_MAXRESTXP_SUBTITLE"] = "可累积的最大休息经验"
L["COLUMN_SAVEDRESTXP_TITLE"] = "已保存休息经验"
L["COLUMN_SAVEDRESTXP_TITLE_SHORT"] = "已奖励经验"
L["COLUMN_SAVEDRESTXP_SUBTITLE"] = "登出时未使用的休息经验量"
L["COLUMN_EARNEDRESTXP_TITLE"] = "休息时获得的经验"
L["COLUMN_EARNEDRESTXP_TITLE_SHORT"] = "还可奖励经验"
L["COLUMN_EARNEDRESTXP_SUBTITLE"] = "休息状态下获得的休息经验量"

-- *** Character Information / Guild ***
L["COLUMN_GUILD_TITLE"] = "公会名称"
L["COLUMN_GUILDRANK_TITLE"] = "公会级别"
L["COLUMN_GUILDRANK_TITLE_SHORT"] = "公会内级别"
L["COLUMN_GUILDRANK_SUBTITLE"] = "角色在公会中的等级"
L["COLUMN_GUILDREP_TITLE"] = "公会声望"
L["COLUMN_GUILDREP_SUBTITLE"] = "角色对公会的声望"

-- *** Character Information / Location ***
L["COLUMN_HEARTHSTONE_TITLE"] = "炉石位置"
L["COLUMN_HEARTHSTONE_SUBTITLE"] = "炉石绑定的地方"
L["COLUMN_SUBZONE_TITLE"] = "下线子区域"

-- *** Character Information / Miscellaneous ***
L["COLUMN_CLASS_SUBTITLE"] = "角色的职业和当前激活专精"
L["COLUMN_BANK_TYPE_MARKS"] = "角色库的标签"
L["COLUMN_BANK_TYPE_MARKS_SUBTITLE"] = "为银行角色设置的标记列表"

-- *** Bag Usage ***
L["COLUMN_BAGS_TITLE"] = "角色背包"
L["COLUMN_BAGS_TITLE_SHORT"] = "背包"
L["COLUMN_BAGS_SUBTITLE_1"] = "你的主背包栏位"
L["COLUMN_BAGS_SUBTITLE_2"] = "越大越好"
L["COLUMN_FREEBAGSLOTS_TITLE"] = "剩余背包格子"
L["COLUMN_FREEBAGSLOTS_TITLE_SHORT"] = "空闲"
L["COLUMN_FREEBAGSLOTS_SUBTITLE"] = "空闲栏位与总栏位"
L["COLUMN_BANK_TITLE"] = "角色银行"
L["COLUMN_BANK_TITLE_SHORT"] = "银行"
L["COLUMN_BANK_SUBTITLE_1"] = "你的银行库存栏位"
L["COLUMN_BANK_SUBTITLE_2"] = "旧战利品安息之地"
L["COLUMN_FREEBANKLOTS_TITLE"] = "剩余银行空格"
L["COLUMN_FREEBANKLOTS_TITLE_SHORT"] = "空闲"
L["COLUMN_FREEBANKLOTS_SUBTITLE"] = "总格子数 和 剩余格子数"
L["NUM_SLOTS_AND_FREE"] = "%s%d%s 栏位，%s%d%s 空闲"

L["Bags"] = "背包"
L["Bank"] = "银行"
L["Bank bag"] = "银行背包"
L["Bank not visited yet"] = "尚未访问银行"
L["slots"] = "格"

-- *** Skills ***
L["COLUMN_PROFESSION_1_TITLE"] = "专业 1"
L["COLUMN_PROFESSION_1_TITLE_SHORT"] = "商业技能"
L["COLUMN_PROFESSION_2_TITLE"] = "专业 2"
L["COLUMN_PROFESSION_2_TITLE_SHORT"] = "辅助技能"
L["COLUMN_RIDING_UPGRADEABLE_MALE"] = "该角色可以提升他的骑术技能"
L["COLUMN_RIDING_UPGRADEABLE_FEMALE"] = "该角色可以提升她的骑术技能"
L["COLOR_GREEN"] = "绿色"
L["COLOR_GREY"] = "灰色"
L["COLOR_ORANGE"] = "橙色"
L["COLOR_RED"] = "红色"
L["COLOR_YELLOW"] = "黄色"

L["up to"] = "升到"
L["at"] = "在"
L["and above"] = "及以上"
L["No data"] = "无数据"
L["Suggestion"] = "建议"
L["All cooldowns are up"] = "所有冷却已完成"
L["Riding"] = "骑术"

-- *** Activity ***
L["COLUMN_MAILS_TITLE"] = "邮箱内容"
L["COLUMN_MAILS_TITLE_SHORT"] = "邮件数"
L["COLUMN_MAILS_SUBTITLE"] = "邮箱中的物品数量"
L["COLUMN_MAILS_DETAIL_1"] = "超过一定上限后，邮件会在服务器端排队。"
L["COLUMN_MAILS_DETAIL_2"] = "这些邮件不计入此处。"
L["COLUMN_MAILBOX_VISITED_TITLE"] = "最近邮箱访问时间"
L["COLUMN_MAILBOX_VISITED_TITLE_SHORT"] = "访问于"
L["COLUMN_MAILBOX_VISITED_SUBTITLE"] = "上次检查邮箱内容的时间"
L["COLUMN_MAILS_NUM_RETURNS_TITLE"] = "退回数量"
L["COLUMN_MAILS_NUM_RETURNS_TITLE_SHORT"] = "将退回"
L["COLUMN_MAILS_NUM_RETURNS_SUBTITLE"] = "过期后将退回给发件人的邮件数量"
L["COLUMN_MAILS_CLOSEST_RETURN_TITLE"] = "最近退回"
L["COLUMN_MAILS_CLOSEST_RETURN_TITLE_SHORT"] = "退回倒计时"
L["COLUMN_MAILS_CLOSEST_RETURN_SUBTITLE"] = "角色邮件退回给发件人的最短时间"
L["COLUMN_MAILS_NUM_DELETIONS_TITLE"] = "删除数量"
L["COLUMN_MAILS_NUM_DELETIONS_TITLE_SHORT"] = "将删除"
L["COLUMN_MAILS_NUM_DELETIONS_SUBTITLE"] = "过期后将被删除的邮件数量"
L["COLUMN_MAILS_CLOSEST_DELETION_TITLE"] = "最近删除"
L["COLUMN_MAILS_CLOSEST_DELETION_TITLE_SHORT"] = "删除倒计时"
L["COLUMN_MAILS_CLOSEST_DELETION_SUBTITLE"] = "角色邮件被删除前的最短时间"




L["COLUMN_AUCTIONS_TITLE"] = "拍卖行拍卖"
L["COLUMN_AUCTIONS_TITLE_SHORT"] = "拍卖数"
L["COLUMN_AUCTIONS_SUBTITLE"] = "拍卖行中活跃拍卖的数量"
L["COLUMN_AUCTIONS_LOW_BUYOUT_TITLE"] = "最低一口价"
L["COLUMN_AUCTIONS_LOW_BUYOUT_TITLE_SHORT"] = "最低一口价"
L["COLUMN_AUCTIONS_LOW_BUYOUT_SUBTITLE"] = "所有活跃拍卖设置的最低一口价"
L["COLUMN_AUCTIONS_HIGH_BUYOUT_TITLE"] = "最高一口价"
L["COLUMN_AUCTIONS_HIGH_BUYOUT_TITLE_SHORT"] = "最高一口价"
L["COLUMN_AUCTIONS_HIGH_BUYOUT_SUBTITLE"] = "所有活跃拍卖设置的最高一口价"
L["COLUMN_AUCTIONS_CLOSEST_EXPIRY_TITLE"] = "最近到期"
L["COLUMN_AUCTIONS_CLOSEST_EXPIRY_TITLE_SHORT"] = "下架倒计时"
L["COLUMN_AUCTIONS_CLOSEST_EXPIRY_SUBTITLE"] = "首个拍卖到期前的时间"

L["COLUMN_BIDS_TITLE"] = "拍卖行竞标"
L["COLUMN_BIDS_TITLE_SHORT"] = "竞拍数"
L["COLUMN_BIDS_SUBTITLE"] = "在拍卖行中放置的竞标数量"
L["COLUMN_AUCTIONHOUSE_VISITED_TITLE"] = "上次访问拍卖行"
L["COLUMN_AUCTIONHOUSE_VISITED_TITLE_SHORT"] = "访问于"
L["COLUMN_AUCTIONHOUSE_VISITED_SUBTITLE"] = "上次访问拍卖行的时间"
L["COLUMN_GARRISON_MISSIONS_TITLE"] = "要塞任务"
L["COLUMN_GARRISON_MISSIONS_TITLE_SHORT"] = "大厅任务"
L["COLUMN_GARRISON_MISSIONS_SUBTITLE"] = "上次检查任务状态的时间"
L["COLUMN_GARRISON_MISSIONS_DETAIL_1"] = "至少有一个任务已完成"
L["COLUMN_GARRISON_MISSIONS_DETAIL_2"] = "所有任务均已完成"
L["COLUMN_GARRISON_MISSIONS_DETAIL_3"] = "没有进行中的任务"

L["Visited"] = "已访问"


-- *** Currencies ***
L["Last collected"] = "上次收集"
L["Garrison resources"] = "要塞资源"
L["Uncollected resources"] = "未收集资源"
L["Max. uncollected resources in"] = "最大未收集资源于"


-- *** Expansion Features / Garrison Followers ***
L["COLUMN_FOLLOWERS_LV40_TITLE"] = "40 级追随者"
L["COLUMN_FOLLOWERS_LV40_TITLE_SHORT"] = "等级 40"
L["COLUMN_FOLLOWERS_LV40_SUBTITLE"] = "40 级与追随者总数"
L["COLUMN_FOLLOWERS_RARITY_TITLE"] = "追随者稀有度"
L["COLUMN_FOLLOWERS_RARITY_TITLE_SHORT"] = "稀有度"
L["COLUMN_FOLLOWERS_RARITY_SUBTITLE"] = "精良与史诗稀有度"
L["COLUMN_FOLLOWERS_ILEVEL_TITLE"] = "物品等级 %s 的追随者"
L["COLUMN_FOLLOWERS_ILEVEL_SUBTITLE"] = "物品等级 %s"
L["COLUMN_FOLLOWERS_AIL_TITLE"] = "追随者平均装等"
L["COLUMN_FOLLOWERS_AIL_TITLE_SHORT"] = "装等"
L["COLUMN_FOLLOWERS_AIL_SUBTITLE"] = "所有活跃追随者的平均物品等级"

-- *** Expansion Features / Artifacts ***

-- *** Expansion Features / Covenant ***
L["COLUMN_COVENANT_SUBTITLE"] = "点击查看你的灵魂羁绊"
L["COLUMN_COVENANT_TITLE"] = "所选盟约"
L["COLUMN_COVENANT_TITLE_SHORT"] = "盟约"
L["COLUMN_SOULBIND_SUBTITLE"] = "点击查看你的灵魂羁绊"
L["COLUMN_SOULBIND_TITLE"] = "激活的灵魂羁绊"
L["COLUMN_SOULBIND_TITLE_SHORT"] = "灵魂羁绊"
L["COLUMN_RENOWN_SUBTITLE"] = "点击查看你的盟约声望等级和奖励"
L["COLUMN_RENOWN_TITLE"] = "盟约声望等级"
L["COLUMN_CAMPAIGNPROGRESS_TITLE_SHORT"] = "剧情"
L["COLUMN_CAMPAIGNPROGRESS_TITLE"] = "战役进度"
L["COLUMN_CAMPAIGNPROGRESS_SUBTITLE"] = "盟约战役已完成的章节数"

-- *** Expansion Features / Reservoir ***
L["COLUMN_TRANSPORT_NETWORK_TITLE"] = "运输网络"
L["COLUMN_ANIMA_TITLE"] = "心能导流器"
L["COLUMN_COMMAND_TABLE_TITLE"] = "指挥台"
L["COLUMN_SANCTUM_UNIQUE_TITLE"] = "圣所专属"

L["Overall"] = "总体"
L["Torghast"] = "托加斯特，罪魂之塔"
L["Single target build"] = "单体构建"
L["AOE build"] = "AOE 构建"
L["Recommended Covenant"] = "推荐盟约"
L["Equally viable"] = "同样可行"


-- *** Mythic Keystone ***
L["Mythic+ Keystone"] = "大秘境钥石"
L["COLUMN_KEYNAME_TITLE"] = "当前大秘境钥石"
L["COLUMN_KEYNAME_TITLE_SHORT"] = "钥石"
L["COLUMN_KEYNAME_SUBTITLE"] = "你的下一场冒险"
L["COLUMN_KEYLEVEL_TITLE"] = "当前钥石层数"
L["COLUMN_KEYLEVEL_SUBTITLE"] = "你绝对还没准备好！"
L["COLUMN_WEEKLYBEST_KEYNAME_TITLE"] = "每周最佳"
L["COLUMN_WEEKLYBEST_KEYNAME_SUBTITLE"] = "悬停查看所有地图的每周最佳"
L["COLUMN_WEEKLYBEST_KEYLEVEL_TITLE"] = "最高层数"
L["COLUMN_WEEKLYBEST_KEYLEVEL_SUBTITLE"] = "你敢深入兔洞多深"
L["COLUMN_WEEKLYBEST_KEYTIME_TITLE"] = "赛季最佳"
L["COLUMN_WEEKLYBEST_KEYTIME_SUBTITLE"] = "悬停查看所有地图的赛季最佳"


-- [ADE] 补全缺失 key
L["Equipment"] = "装备"
L["PATCH_11.1"] = "安德麦风云"
L["ALT_GROUP_NOT_GROUPED"] = "未分组"
L["COLUMN_EQUIP_HIGHEST_TITLE"] = "最佳装备部件"
L["COLUMN_EQUIP_HIGHEST_TITLE_SHORT"] = "最佳"
L["COLUMN_EQUIP_HIGHEST_SUBTITLE"] = "你最佳装备部件的物品等级"
L["COLUMN_EQUIP_LOWEST_TITLE"] = "最差装备部件"
L["COLUMN_EQUIP_LOWEST_TITLE_SHORT"] = "最差"
L["COLUMN_EQUIP_LOWEST_SUBTITLE"] = "你最差装备部件的物品等级"
L["COLUMN_EQUIP_NUM_GREENS_TITLE"] = "优秀装备"
L["COLUMN_EQUIP_NUM_GREENS_SUBTITLE"] = "已装备的优秀品质物品数量"
L["COLUMN_EQUIP_NUM_BLUES_TITLE"] = "精良装备"
L["COLUMN_EQUIP_NUM_BLUES_SUBTITLE"] = "已装备的精良品质物品数量"
L["COLUMN_EQUIP_NUM_EPICS_TITLE"] = "史诗装备"
L["COLUMN_EQUIP_NUM_EPICS_SUBTITLE"] = "已装备的史诗品质物品数量"
L["COLUMN_EQUIP_NUM_HEIRLOOMS_TITLE"] = "传家宝装备"
L["COLUMN_EQUIP_NUM_HEIRLOOMS_SUBTITLE"] = "已装备的传家宝物品数量"
L["Not purchased yet"] = "尚未购买"
L["COLUMN_SKILLS_NODATA"] = "打开该角色的专业界面以加载配方"
L["COLUMN_SKILLS_NOT_LEARNED"] = "尚未学习专业"
L["COLUMN_CYPHER_NODATA"] = "前往该角色在扎雷殁提斯的流亡者空洞的研究控制台"
L["COLUMN_SANCTUM_NODATA"] = "前往该角色所属盟约的圣所储备以填充此数值"
L["COLUMN_SOULBIND_NODATA"] = "前往该角色所属盟约的契约熔炉以填充此数值"
L["COLUMN_WEEKLYBEST_DUNGEON_SUBTITLE"] = "本周该地下城完成的最高钥石"
