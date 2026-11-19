-- adeMacroAssistant / Locales/zhCN.lua
-- ADE v6.5：私有 locale 表（不再经 ADE:RegisterLocale / AceLocale）。
local AM = _G.adeMacroAssistant or {}
_G.adeMacroAssistant = AM
AM.Loc = AM.Loc or {}
AM.Loc.zhCN = {
    MACRO_ASSISTANT = "宏助手",

    -- ---- Settings 窗口 ----
    SETTINGS_SUFFIX = " 设置",
    BTN_CLOSE = "关闭",
    ENABLE_AUTOMACRO = "启用自动宏",
    SECTION_PREFIX = "宏名前缀",
    ENABLE_PREFIX = "启用宏名前缀",
    PREFIX_CHAR = "前缀字符（如 ' ）",
    HINT_PREFIX = "前缀与基名分离存储：最终宏名 = 前缀字符 + (自定义基名 或 类型默认名)。\n改动后点「立即刷新宏」生效。",
    ENABLE_PREFIX_DESC = "为宏名加前缀可避免与其他插件或手动宏重名冲突。",
    SECTION_TYPES = "宏类型设置",
    SPELLTYPE_CLEANSE = "净化（友方）",
    SPELLTYPE_PURGE = "清除（敌方）",
    SPELLTYPE_DISPEL = "驱散（友/敌双方）",
    SPELLTYPE_INTERRUPT = "打断",
    SPELLTYPE_RESURRECTION = "战复 / 复活",
    SPELLTYPE_SPRINT = "疾跑 / 加速",
    SPELLTYPE_TAUNT = "嘲讽",
    ENABLE = "启用",
    BASE_NAME = "自定义基名（留空用默认）",
    MACRO_BODY = "宏体（每行一条命令）",
    SECTION_RESIZE = "宏界面尺寸调整",
    ENABLE_RESIZE = "启用界面尺寸调整",
    RESIZE_COLS = "每行宏数",
    RESIZE_ROWS = "图标行数",
    RESIZE_TEXT = "文本区额外高度（垂直布局）",
    RESIZE_RIGHTW = "文本区宽度（水平布局）",
    RESIZE_RIGHTW_DESC = "水平布局下宏内容区域宽度（%d–%d，步进 %d，默认 %d）。垂直布局下宏内容区宽度由窗口尺寸决定，此项不起作用，故切换到垂直布局时置灰。",
    -- 两项的取值在两种布局下不同，故描述同时列出两种（标题不再写值，避免随布局过期）
    RESIZE_COLS_DESC = "宏面板每行排布的宏数量：垂直布局 %d–%d（默认 %d），水平布局 %d–%d（默认 %d）；两种布局各自独立保存。",
    RESIZE_ROWS_DESC = "宏面板显示的图标行数：垂直布局 %d–%d（默认 %d），水平布局 %d–%d（默认 %d）；两种布局各自独立保存。",
    RESIZE_TEXT_DESC = "文本区在图标下方的额外高度（%d–%d，步进 %d，默认 %d）。水平布局的内容区高度由「图标行数」撑满，此项不起作用，故切换到水平布局时置灰。",
    HINT_RESIZE = "调整仅在宏界面（Macro Frame）打开时实时预览；关闭后还原。",
    BTN_REFRESH = "立即刷新宏",
    BTN_APPLY_RESIZE = "应用界面尺寸",
    BTN_RESET_LAYOUT = "重置当前布局",
    BTN_RESET_NATIVE = "重置为原生宏界面",

    -- ---- 布局模式 / 搜索栏 ----
    RESIZE_LAYOUT = "布局模式",
    LAYOUT_VERTICAL = "垂直（宏按钮在上，宏内容在下）",
    LAYOUT_HORIZONTAL = "水平（宏按钮在左，宏内容在右）",
    SECTION_SEARCH = "搜索栏",
    SEARCH_ENABLE = "启用搜索栏",
    SEARCH_BODY = "同时搜索宏内容",
    SWITCH_TO_HORIZONTAL = "切换到水平布局",
    SWITCH_TO_VERTICAL = "切换到垂直布局",
    OPEN_SETTINGS = "打开设置",
    SEARCH_HINT = "按名称过滤宏列表；搜索栏位于标签下方、宏按钮上方。战斗中禁用输入。",
    SEARCH_NO_RESULT = "未找到匹配的宏",

    -- ---- AutoMacro 消息 ----
    MSG_MACRO_UPDATED = "已更新宏 '%s'（%s）",
    MSG_MACRO_CREATED = "已创建宏 '%s'（%s）",
    MSG_IN_COMBAT = "战斗中：前缀变更将在退战后应用",
    MSG_PREFIX_ENABLED = "自动宏前缀已启用",
    MSG_PREFIX_DISABLED = "自动宏前缀已停用",
    MSG_PREFIX_CHAR_UPDATED = "自动宏前缀字符已更新",

    -- ---- 默认宏名称 ----
    DEFAULT_NAME_CLEANSE = "净化",
    DEFAULT_NAME_PURGE = "清除",
    DEFAULT_NAME_DISPEL = "驱散",
    DEFAULT_NAME_INTERRUPT = "打断",
    DEFAULT_NAME_RESURRECTION = "战复",
    DEFAULT_NAME_SPRINT = "疾跑",
    DEFAULT_NAME_TAUNT = "嘲讽",

    -- ---- Tab 标签 ----
    TAB_AUTOMACRO = "自动宏",
    TAB_RESIZE = "宏界面",
    TAB_IMPORTEXPORT = "导入/导出宏",
    TAB_CONFIG = "配置管理",   -- 与 adeBackpack 对齐；v5 配置管理页 = 基座 BuildConfigPage

    -- ---- 标题栏 / 关于窗口 ----
    UI_SCALE = "缩放",
    ABOUT_TITLE = "关于",
    ABOUT_AUTHOR = "作者",
    ABOUT_VERSION = "版本",
    ABOUT_TRANSLATOR = "翻译",
    ABOUT_TRANSLATOR_DESC = "简体中文 由 Martin Good (mt25cyb) 提供",
    ABOUT_NOTES = "简介",
    ABOUT_COMMANDS = "命令",
    ABOUT_COMMANDS_DESC = "/adeMacroAssistant 或 /adema 打开本窗口",
    UNKNOWN = "未知",

    -- 占位符 -> 实际法术含义说明（按类型展示于设置界面）
    TOKEN_CLEANSE_SPELL = "友方驱散法术",
    TOKEN_PURGE_SPELL = "敌方进攻驱散法术",
    TOKEN_INTERRUPT_SPELL = "打断法术",
    TOKEN_RESURRECTION_SPELL = "战复 / 复活法术",
    TOKEN_SPRINT_SPELL = "疾跑 / 加速法术",
    TOKEN_TAUNT_SPELL = "嘲讽法术",
    HINT_TOKEN_ONE = "使用 %s 作为实际 %s 名称的占位符。",

    -- ---- 各类型格式化标签（%s 填入类型名）----
    ENABLE_TYPE = "启用%s",
    NAME_TYPE = "宏名称",
    BODY_TYPE = "宏体",
    DESC_TYPE = "%s 宏",

    -- ---- 导入 / 导出宏（仅自动宏的宏名称与宏体） ----
    SECTION_EXPORT = "导出自动宏",
    EXPORT_HINT = "点击下方按钮生成分享字符串（仅含自动宏的宏名称与宏体），Ctrl+C 复制。",
    SECTION_IMPORT = "导入自动宏",
    IMPORT_HINT = "将分享字符串粘贴到下方，解析成功后「导入宏」按钮才会启用；仅更新自动宏。",
    BTN_EXPORT = "导出",
    BTN_IMPORT = "导入",
    BTN_EXPORT_GEN = "生成导出字符串",
    BTN_IMPORT_DO = "导入宏",
    EXPORT_OK = "导出字符串已生成（Ctrl+C 复制）。",
    IMPORT_BOX_LABEL = "导入字符串",
    IMPORT_VALID = "字符串有效",
    IMPORT_INVALID = "无效字符串",
    SHARE_NO_CODEC = "当前客户端不支持 C_EncodingUtil",
    SHARE_BAD_PREFIX = "前缀错误（非 ADE 导出字符串）",
    SHARE_BAD_PAYLOAD = "数据结构错误",
    SHARE_EMPTY = "字符串为空",
    SHARE_SERIALIZE_FAILED = "序列化失败",
    SHARE_COMPRESS_FAILED = "压缩失败",
    SHARE_ENCODE_FAILED = "编码失败",
    SHARE_DECODE_FAILED = "Base64 解码失败",
    SHARE_DECOMPRESS_FAILED = "解压失败",
    SHARE_DESERIALIZE_FAILED = "反序列化失败",
    SHARE_VALIDATE_FAILED = "字符串内容无效",
    MSG_IMPORT_OK = "自动宏已导入。",
    MSG_IMPORT_ERR = "自动宏导入失败。",

    -- ---- 宏界面布局标签（b018 修复） ----
    RESIZE_COLS_V = "每行宏数（垂直布局）",
    RESIZE_ROWS_V = "图标行数（垂直布局）",
    RESIZE_COLS_H = "每行宏数（水平布局）",
    RESIZE_ROWS_H = "图标行数（水平布局）",

    -- 小地图
    MENU_SETTINGS = "设置",
    MENU_REFRESH = "立即刷新宏",
    TIP_LEFT = "左键",
    TIP_RIGHT = "右键",
    TIP_LEFT_SETTINGS = "打开设置",
    TIP_RIGHT_FUNCS = "功能菜单",
    MINIMAP_LIB_MISSING = "LibDBIcon/LibDataBroker 不可用。",
}
