---------------------------------------------------------------------------
-- Cooldown Manager Profiles 简体中文语言包 · 字典
--
-- 本文件只存放「英文原文 -> 简体中文」的映射，不含任何逻辑。
-- 由 LocalesPatch.lua 通过全局表 CMPLang[locale] 读取（同插件内部共享，非 _G 污染）。
--
-- 匹配规则（与 zhCN.lua 的 GetTranslation 一致）：
--   * 先去除颜色码（|cxxxxxxxx / |r）再查表；
--   * StaticPopup 的 text 会先去掉常量前缀 "CM Profiles\n\n" 再查；
--   * 形如 "xxx (n/n)" / "xxx (n)" 的计数串，仅翻译 base 部分。
-- 基准版本：目标插件 CooldownManagerProfiles 2.3.1（2026-11-24 由 2.3.0 字典核对更新：
-- 删除 2 个 2.3.1 已移除/改为动态拼接的键，新增 Delete Template / Paste from Clipboard）。
-- 因此本表的 key 均为「去色后的纯文本」，且弹窗 key 为「去掉前缀后的完整消息」。
---------------------------------------------------------------------------
local L = {
    -- 主窗口与通用
    ["Cooldown Manager Profiles"] = "冷却管理器配置",
    ["CM Profiles"] = "冷却配置",
    ["Profiles"] = "配置方案",
    ["Template Library"] = "模板库",
    ["Profile Contents"] = "配置内容",
    ["Blizzard Layouts"] = "官方布局",
    ["Presets"] = "预设方案",
    ["My Profiles"] = "我的配置",
    ["Preset Contents"] = "预设内容",

    -- 按钮
    ["New"] = "新建",
    ["Import"] = "导入",
    ["Export"] = "导出",
    ["Export Profile"] = "导出配置",
    ["Export Class"] = "导出职业",
    ["Rename"] = "重命名",
    ["Delete"] = "删除",
    ["Edit"] = "编辑",
    ["Save"] = "保存",
    ["Cancel"] = "取消",
    ["Create"] = "创建",
    ["Website"] = "官网",
    ["Manage"] = "管理",
    ["Select All"] = "全选",
    ["Paste"] = "粘贴",
    ["Copy Profile"] = "复制配置",
    ["Sync from Blizzard"] = "上传配置",
    ["Sync from Blizz"] = "上传配置",
    ["Load to Blizzard"] = "下载配置",
    ["Load to Blizz"] = "下载配置",
    ["Import CDM"] = "导入CDM",
    ["+Library"] = "加入库",
    ["+Profile"] = "加入配置",
    ["Open CM Profiles"] = "打开配置面板",
    ["Close"] = "关闭",
    ["Overwrite"] = "覆盖",
    ["Create a Copy"] = "创建副本",
    ["Create Copies"] = "创建副本",

    -- 自动同步
    ["Auto-Sync:"] = "自动同步：",
    ["Disabled"] = "已禁用",
    ["Mute"] = "屏蔽提示",
    ["Auto-Sync"] = "自动同步",
    ["Mute auto-sync"] = "屏蔽自动同步提示",

    -- 标签与说明
    ["Name:"] = "名称：",
    ["Class:"] = "职业：",
    ["Spec:"] = "专精：",
    ["Class (CDM):"] = "职业 (CDM)：",
    ["Spec (CDM):"] = "专精 (CDM)：",
    ["Target profile:"] = "目标配置：",
    ["Layout data:"] = "布局数据：",
    ["Custom"] = "自定义",
    ["(Any Spec)"] = "（任意专精）",
    ["chars"] = "字符",
    ["Active:"] = "当前：",
    ["Profiles:"] = "配置数：",

    -- 导入窗口
    ["Paste a CDM string, template export, or profile export:"] = "粘贴CDM字符串、模板导出码或配置导出码：",
    ["Waiting for input..."] = "等待输入...",
    ["Detected: CDM layout string"] = "识别：CDM 布局字符串",
    ["Detected: Global profile"] = "识别：全局配置",
    ["Detected: Class layouts"] = "识别：职业布局",
    ["Detected: Single layout"] = "识别：单个布局",
    ["Detected: Template"] = "识别：模板",
    ["Invalid string."] = "字符串无效。",

    -- 导出窗口
    ["Export Layout"] = "导出布局",
    ["Export Template"] = "导出模板",
    ["Profile: "] = "配置：",
    ["Layout: "] = "布局：",
    ["Template: "] = "模板：",

    -- 编辑模板
    ["Edit Template"] = "编辑模板",
    ["Template not found."] = "未找到该模板。",
    ["Name cannot be empty."] = "名称不能为空。",
    ["Layout data cannot be empty."] = "布局数据不能为空。",
    ["Template updated: "] = "模板已更新：",

    -- 弹窗通用
    ["Reload Now"] = "立即重载",
    ["Later"] = "稍后",
    ["Apply & Reload"] = "应用并重载",
    ["Don't ask again"] = "不再提示",

    -- 配置操作弹窗
    ["Save current state as profile:"] = "将当前布局保存为配置：",
    ["New profile name:"] = "新配置名称：",
    ["Delete profile '%s'?"] = "确认删除配置「%s」？",
    ["Rename profile '%s':"] = "重命名配置「%s」：",
    ["New global profile name:"] = "新全局配置名称：",
    ["Delete global profile '%s'?\nThis will remove it for all characters."] = "确认删除全局配置「%s」？\n所有角色都将失去该配置。",
    ["Rename global profile '%s':"] = "重命名全局配置「%s」：",
    ["Delete template '%s'?"] = "确认删除模板「%s」？",
    ["Rename template '%s':"] = "重命名模板「%s」：",
    ["Rename layout '%s':"] = "重命名布局「%s」：",

    -- 重载提示（★ 新版为去掉 "CM Profiles\n\n" 前缀后的完整消息，旧的半截 key 已失效）
    ["Profile loaded successfully.\nUI reload is required to apply layout changes.\n\nBlizzard's Cooldown Manager does not support live layout updates from addons. This workaround may be improved in future versions."] =
        "配置加载成功。\n需要重载界面才能使布局生效。\n\n官方冷却管理器不支持插件实时修改布局，该方案后续可能优化。",
    ["Profile \"%s\" has different layouts for your class.\n\nWARNING: Applying will replace ALL current\nCooldown Manager layouts and reload the UI."] =
        "配置「%s」与你当前职业的布局不一致。\n\n警告：应用将覆盖当前所有冷却管理器布局并重载界面。",

    -- 导入冲突
    ["A profile named '%s' already exists."] = "名为「%s」的配置已存在。",
    ["These layers already exist:\n%s"] = "以下布局已存在：\n%s",

    -- 预设相关
    ["'%s' is a read-only preset.\nCopy it to My Profiles and add '%s' to the copy?"] = "「%s」是只读预设。\n是否复制到我的配置并将「%s」加入副本？",
    ["Copy & Add"] = "复制并添加",
    ["(Preset)"] = "（预设）",

    -- 设置面板
    ["Settings"] = "设置",
    ["Manage addon behavior and appearance."] = "管理插件的行为与外观。",
    ["General"] = "常规",
    ["Show minimap icon"] = "显示小地图图标",
    ["Verbose chat notifications"] = "详细聊天通知",
    ["Show detailed messages for profile saves, loads, and syncs."] = "显示配置保存、加载、同步的详细提示。",
    ["Info"] = "信息",
    ["Cooldown Manager Profiles Settings"] = "冷却管理器配置",

    -- 设置面板说明长文本

    ["Made with love in Ukraine"] = "乌克兰制作，充满热爱",

    -- 职业显示
    ["Warrior"] = "战士",
    ["Paladin"] = "圣骑士",
    ["Hunter"] = "猎人",
    ["Rogue"] = "潜行者",
    ["Priest"] = "牧师",
    ["Death Knight"] = "死亡骑士",
    ["Shaman"] = "萨满祭司",
    ["Mage"] = "法师",
    ["Warlock"] = "术士",
    ["Monk"] = "武僧",
    ["Druid"] = "德鲁伊",
    ["Demon Hunter"] = "恶魔猎手",
    ["Evoker"] = "唤魔师",

    -- 其他零散文本
    ["No active layout to export. Use the UI buttons to export specific layouts."] = "无活动布局可导出，请使用界面按钮导出指定布局。",
    ["Select a profile first."] = "请先选择一个配置。",
    ["No layouts. Use Sync or add from Library."] = "暂无布局，使用同步或从模板库添加。",
    ["No data for this layout."] = "该布局无数据。",
    ["No Blizzard layouts to capture."] = "没有可捕获的官方布局。",
    ["Layout manager not available."] = "布局管理器不可用。",
    ["CDM not available."] = "冷却管理器不可用。",
    ["Character not ready."] = "角色尚未就绪。",
    ["CDM data not loaded yet."] = "CDM数据尚未加载。",
    ["No string provided."] = "未提供字符串。",
    ["Empty string."] = "字符串为空。",
    ["Unrecognized format. Paste a CDM string (1|...) or CM Profiles export."] = "格式无法识别，请粘贴CDM字符串（1|...）或配置导出码。",
    ["This export was made with a newer version of CM Profiles. Update the addon."] = "该导出由更高版本的插件生成，请更新插件。",

    -------------------------------------------------------------------------
    -- ★ 新版新增字符串（原汉化包缺失，需重新适配）
    -------------------------------------------------------------------------

    -- 主窗口页脚
    ["Made in Ukraine"] = "乌克兰制造",
    ["Not found"] = "未找到",

    -- 模板库面板 / 自动同步下拉 相关按钮与提示
    ["Add to Profile"] = "加入配置",
    ["Save to Library"] = "保存到库",
    ["Remove from Profile"] = "从配置移除",
    ["Rename Layout"] = "重命名布局",
    ["New Profile"] = "新建配置",
    ["Delete Profile"] = "删除配置",
    ["Rename Profile"] = "重命名配置",
    ["Open Cooldown Manager settings"] = "打开冷却管理器设置",
    ["Import CDM String"] = "导入CDM字符串",

    -- 作者网址弹窗
    ["Author website — copy the URL below:"] = "作者官网 — 复制以下网址：",

    -- 工具提示标题（GameTooltip:SetText，由 zhCN.lua 的 GameTooltip 钩子翻译）
    ["Preset is read-only.\nClick to copy it into My Profiles\nand add this template to the copy."] =
        "预设为只读。\n点击将其复制到我的配置\n并把此模板加入副本。",

    -- 工具提示详情（GameTooltip:AddLine；当前仅作字典储备，AddLine 不便劫持时保留英文）
    ["Remove this profile for all characters."] = "为所有角色移除该配置。",
    ["Change this profile's name."] = "修改此配置的名称。",
    ["Capture current Blizzard CDM layouts\nfor your class into this profile."] = "将当前职业的官方冷却管理器布局\n捕获到此配置中。",
    ["Load this profile's layouts for your\ncurrent class into Blizzard CDM."] = "将此配置中当前职业的布局\n加载到官方冷却管理器。",
    ["Create an editable copy of this\npreset profile."] = "创建此预设配置\n的可编辑副本。",
    ["On login and /reload, compares this profile's layouts with your current Cooldown Manager layouts."] = "登录或重载时，将此配置的布局\n与当前冷却管理器布局比对。",
    ["If they differ, you'll be prompted to apply the profile and reload the UI."] = "若不一致，将提示应用该配置并重载界面。",
    ["Stops the auto-sync prompt for this profile on THIS character."] = "在本角色上停止此配置的自动同步提示。",
    ["Per-character. Un-check to re-enable and check again now."] = "按角色生效。取消勾选可重新启用并立即检查。",
    ["Use 'Re-check' to clear a previous Skip and check again now."] = "使用“重新检查”清除之前的跳过并立即再次检查。",
    ["Shows a copyable link"] = "显示一个可复制的链接",
    ["Open author's website URL"] = "打开作者官网链接",
    ["Click to toggle window"] = "点击切换窗口",

    -- 2.3.1 新增
    ["Delete Template"] = "删除模板",
    ["Paste from Clipboard"] = "从剪贴板粘贴",

    -- 动态拼接中可整串匹配的常量文本（色码在 hook 层已剥离）
    ["None"] = "无",
    ["Select a profile on the left"] = "请先在左侧选择一个配置",
    -- Settings 面板信息段（源码为多行常量拼接，经 SetText 显示，拼接结果整串作 key）
    ["CM Profiles lets you manage Cooldown Manager layouts with a global Template Library and cross-character Profiles.\n\nFeatures:\n  - Template Library: store layouts organized by class\n  - Global Profiles: group layouts for all classes\n  - Load profile layouts for your current class\n  - Export/Import profiles, classes, or individual layouts\n\nCommands:\n  /cm — Toggle the main window\n  /cm save <name> — Save current Blizzard state as profile\n  /cm load <name> — Load a profile\n  /cm list — List all profiles and layouts\n  /cm help — Show all commands"] = "冷却配置让你通过全局模板库与跨角色配置管理冷却管理器的布局。\n\n功能：\n  - 模板库：按职业整理存储布局\n  - 全局配置：为所有职业统一布局\n  - 将配置布局载入当前职业\n  - 导出/导入配置、职业或单个布局\n\n命令：\n  /cm — 打开主窗口\n  /cm save <名称> — 将当前暴雪状态保存为配置\n  /cm load <名称> — 载入一个配置\n  /cm list — 列出全部配置与布局\n  /cm help — 显示全部命令",
}

-- 同插件内部共享给 zhCN.lua（唯一刻意全局，仅供本汉化包使用）
-- 注册到全局 CMPLang（按语种索引，便于后续挂载更多语种，如 Lang_enUS.lua / Lang_deDE.lua）
CMPLang = CMPLang or {}
CMPLang.zhCN = L
