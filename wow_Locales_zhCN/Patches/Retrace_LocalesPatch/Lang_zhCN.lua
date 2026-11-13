---------------------------------------------------------------------------
-- Retrace 简体中文语言包 · 字典
--
-- 本文件只存放「英文原文 -> 简体中文」的映射，不含任何逻辑。
-- 由 LocalesPatch.lua 通过全局表 RetraceLang[locale] 读取（同插件内部共享，非 _G 污染）。
--
-- 匹配规则（与 LocalesPatch.lua 的 GetTranslation 一致）：
--   * 先去除颜色码（|cxxxxxxxx / |r）再查表；
--   * StaticPopup 的 text 直接查表；
--   * "Lv 12" / "Speed x2" / "Level 12  ·  ..." 等动态串由 PrefixRules 处理；
-- 因此本表的 key 均为「原样整串（含换行与颜色码）」——Retrace 大量文案自带 |cff 色码与 \n，
-- 必须逐字节一致，不能用去色后的形式。
---------------------------------------------------------------------------
local L = {
    ---------------------------------------------------------------------
    -- 设置面板（Esc > 选项 > 插件 > Retrace）
    ---------------------------------------------------------------------
    ["Records where you travel and replays it on the world map. Type |cffffd200/rtrace|r to open the replay."] =
        "记录你的旅程并在世界地图上回放。输入 |cffffd200/rtrace|r 打开回放。",
    ["Open replay"] = "打开回放",
    ["Replay"] = "回放",
    ["Trail shown when the replay opens:"] = "打开回放时显示的轨迹：",
    ["Distances:"] = "距离单位：",
    ["Metric (m, km)"] = "公制（米、千米）",
    ["Imperial (yd, mi)"] = "英制（码、英里）",
    ["On the map"] = "地图上",
    ["Kill marks"] = "击杀标记",
    ["A red cross where each mob you killed died."] = "每个被你击杀的怪物死亡处显示红色十字。",
    ["Friends' tracks (when grouped)"] = "好友轨迹（组队时）",
    ["The paths of friends you group with, in their class colour."] = "你组队好友的路径，按其职业颜色显示。",
    ["Weapon & defense skill-ups (replay text)"] = "武器与防御技能提升（回放文字）",
    ["Orange \"+1 Swords (42)\" text during replays. Profession skill-ups always show."] =
        "回放时显示橙色的“+1 剑类武器（42）”文字。专业技能提升始终显示。",
    ["Terrain detail"] = "地形细节",
    ["Blend in the minimap's ground art as you zoom in."] = "放大时融入小地图的地面美术。",
    ["Minimap button"] = "小地图按钮",
    ["The Retrace button on the minimap's rim."] = "小地图边缘上的 Retrace 按钮。",
    ["Keeping your journeys safe"] = "保护你的旅程数据",
    [ [[Your journeys are saved by the game in its WTF folder, not in the addon folder, so reinstalling Retrace never touches them. To back them up or move them to another computer, exit the game and copy:

|cffffd200Each character|r   <game>\WTF\Account\<ACCOUNT>\<Realm>\<Character>\SavedVariables\Retrace.lua
|cffffd200Settings|r   <game>\WTF\Account\<ACCOUNT>\SavedVariables\Retrace.lua

<game> is the game's folder under World of Warcraft (_classic_era_, _forever_, _retail_...). To restore, log each character in once, exit, put the files back in the same places and start the game. Details are in the addon's README.]] ] =
        [[你的旅程由游戏保存在其 WTF 目录中，而非插件目录，因此重装 Retrace 不会影响它们。要备份或迁移到另一台电脑，请退出游戏后复制：

|cffffd200每个角色|r   <游戏目录>\WTF\Account\<账号>\<服务器>\<角色>\SavedVariables\Retrace.lua
|cffffd200设置|r   <游戏目录>\WTF\Account\<账号>\SavedVariables\Retrace.lua

<游戏目录> 指 World of Warcraft 下的游戏文件夹（_classic_era_、_forever_、_retail_……）。恢复时，让每个角色登录一次后退出，把文件放回原处再启动游戏。详见插件自带的 README。]],

    ---------------------------------------------------------------------
    -- 轨迹筛选（设置面板单选 + 回放窗口）
    ---------------------------------------------------------------------
    ["Whole journey"] = "整个旅程",
    ["Current level"] = "当前等级",
    ["Current session"] = "当前游戏会话",
    ["Current session  |cff808080(default)|r"] = "当前游戏会话  |cff808080（默认）|r",
    ["Last 10 hours"] = "最近 10 小时",
    ["Last hour"] = "最近 1 小时",
    ["Last 10 minutes"] = "最近 10 分钟",
    ["On foot"] = "徒步",
    ["Mounted"] = "骑乘",
    ["Flight path"] = "飞行路线",
    ["Flight paths"] = "飞行路线",
    ["Swimming"] = "游泳",
    ["Ghost"] = "灵魂",
    ["As a ghost"] = "以灵魂状态",

    ---------------------------------------------------------------------
    -- 回放窗口
    ---------------------------------------------------------------------
    ["Pause"] = "暂停",
    ["Play"] = "播放",
    ["Now"] = "现在",
    ["Distance travelled"] = "已旅行距离",
    ["Measured along your recorded trail. Hearthstones, portals and other teleports don't count as travel."] =
        "沿已记录轨迹测量。炉石、传送门与其他传送不计入旅行。",
    ["Jump to where you are right now and follow live."] = "跳转到你当前所在位置并实时跟随。",
    ["Switch to the detailed map of where the traveller is now. The map stays there until they leave."] =
        "切换到旅行者当前所在位置的详细地图。地图会保持在那里，直到其离开。",
    ["Resume recording"] = "继续录制",
    ["Pause recording"] = "暂停录制",
    ["Resume Retrace recording?"] = "继续 Retrace 录制？",
    ["Pause Retrace recording?"] = "暂停 Retrace 录制？",
    ["Journal\n|cffffffffYour adventures so far. Click one to relive it.|r"] =
        "日志\n|cffffffff你至今的冒险。点击一条即可重温。|r",
    ["Follow the traveller\n|cffffffffDragging the map turns this off.|r"] =
        "跟随旅行者\n|cffffffff拖动地图会关闭此功能。|r",
    ["Terrain detail\n|cffffffffZoom in to blend in the minimap's ground art.|r"] =
        "地形细节\n|cffffffff放大以融入小地图地面美术。|r",
    ["the zone map"] = "区域地图",

    ---------------------------------------------------------------------
    -- 日志（Journal）
    ---------------------------------------------------------------------
    ["Search the journal"] = "搜索日志",
    ["Names (including everyone you grouped with), places, items, killers, friends, categories or a level (\"lv 12\"). Every word must match. Searches all categories, even ones switched off in Show."] =
        "名称（包括你组过队的每个人）、地点、物品、击杀者、好友、分类或等级（“lv 12”）。每个词都必须匹配。会搜索所有分类，包括在「显示」中关闭的分类。",
    ["Enter jumps to the first result; Esc clears."] = "回车跳转到第一个结果；Esc 清除。",
    ["Deselect all"] = "全部取消选择",
    ["Show"] = "显示",
    ["Everything"] = "全部",
    ["Major events"] = "重要事件",
    ["Click to relive this moment"] = "点击重温这一时刻",
    ["Right-click to remove it from the journal"] = "右键从日志中移除",
    ["Remove from journal"] = "从日志中移除",

    ---------------------------------------------------------------------
    -- 事件分类（Journal 的「显示」列表）
    ---------------------------------------------------------------------
    ["Level ups"] = "升级",
    ["Deaths"] = "死亡",
    ["New friends"] = "新好友",
    ["Groups and raids"] = "小队与团队",
    ["Dungeons"] = "地下城",
    ["Rares and bosses"] = "稀有与首领",
    ["Loot"] = "战利品",
    ["Discoveries"] = "发现",
    ["Flights"] = "飞行",
    ["Professions"] = "专业",
    ["Guild"] = "公会",
    ["Guild members coming and going"] = "公会成员进出",
    ["PvP"] = "PvP",
    ["Quests"] = "任务",
    ["Zone changes"] = "区域变化",

    ---------------------------------------------------------------------
    -- 地图事件气泡 / 地下城档案（Atlas）
    ---------------------------------------------------------------------
    ["Bosses defeated"] = "已击败首领",
    ["  Runs / time inside"] = "  次数 / 内部时长",
    ["  Bosses defeated / deaths"] = "  已击败首领 / 死亡数",
    ["Fastest / longest run"] = "最快 / 最长一次",
    ["Deaths inside"] = "内部死亡数",
    ["Click to relive your last visit"] = "点击重温上次到访",
    ["Ran back to the corpse"] = "跑尸返回",
    ["Revived by the spirit healer"] = "被灵魂医者复活",
    ["Killing blow"] = "致命一击",
    ["Not yet visited"] = "尚未到访",
    ["Not yet entered"] = "尚未进入",
    ["Players killed"] = "击杀玩家数",
    ["Experience earned"] = "获得经验",
    ["Quests completed"] = "完成任务数",
    ["Areas discovered"] = "发现区域数",
    ["Graveyard\n|cffffffffShow every tombstone. Normally a tombstone only stays until you're back on your feet.|r"] =
        "墓地\n|cffffffff显示所有墓碑。通常墓碑只保留到你站起来为止。|r",
    ["Dungeon entrances\n|cffffffffBlue: still to complete. Faded blue: final boss beaten. Hover for your history there.|r"] =
        "副本入口\n|cffffffff蓝色：尚未完成。淡蓝：最终首领已被击败。悬停查看你在该处的历史。|r",

    ---------------------------------------------------------------------
    -- 小地图按钮提示
    ---------------------------------------------------------------------
    ["|cffffd200Left-click|r  open the replay"] = "|cffffd200左键点击|r  打开回放",
    ["|cffffd200Drag|r  move this button"] = "|cffffd200拖动|r  移动此按钮",
    ["|cffffd200Ctrl+Shift+Right-click|r  resume recording"] = "|cffffd200Ctrl+Shift+右键点击|r  继续录制",

    ---------------------------------------------------------------------
    -- 经验追踪
    ---------------------------------------------------------------------
    ["Inside a dungeon (shown at its entrance)"] = "副本内（显示在其入口处）",
    ["Experience history starts later in this journey"] = "经验记录从本次旅程稍后开始",
    ["Kills\n|cffffffffMark every mob you've killed with a red cross. Hover one to see what it was.|r"] =
        "击杀\n|cffffffff用红色十字标记你击杀的每个怪物。悬停可查看其身份。|r",

    ---------------------------------------------------------------------
    -- 队友轨迹
    ---------------------------------------------------------------------
    ["Friend in your group"] = "队伍中的好友",
}

-- 注册到全局 RetraceLang（按语种索引，便于后续挂载更多语种，如 Lang_enUS.lua）
RetraceLang = RetraceLang or {}
RetraceLang.zhCN = L
