-- adeMapMark - 简体中文
local addonName = ...
if GetLocale() ~= "zhCN" then return end
local ns = _G.adeMapMark
local L = ns.L

L.ADDON_TAG = "ADE"

L.MARK_TITLE = "标题"
L.MARK_NOTE = "备注"
L.MARK_COORDS = "坐标"
L.MARK_SIZE = "尺寸"
L.MARK_COLOR = "颜色"
L.MARK_GRAYSCALE = "灰度"
L.MARK_FAVORITE = "收藏"
L.MARK_ADD = "添加标记"
L.MARK_UPDATE = "更新"
L.MARK_DELETE = "删除"
L.MARK_EDIT = "编辑标记"
L.MARK_GOTO = "导航"
L.MARK_BIG_EDITOR = "大编辑器"
L.MARK_FAVORITES = "收藏列表"
L.MARK_ALL = "全部标记"
L.MARK_NO_MARKS = "当前地图没有标记。"
L.MARK_HINT_CLICK = "点击地图拾取坐标"
L.MARK_DEFAULT_TITLE = "新标记"

L.PROVIDER_SOURCE = "外挂来源"
L.RESET_PROVIDER_OVERRIDE = "还原为数据包内置数据（立即生效，无需再点「更新标记」）"
L.PROVIDER_SECTION = "外挂数据包"
L.PROVIDER_ENABLE = "启用数据包"
L.PROVIDER_EXPAND = "展开"
L.PROVIDER_MARKS = "%d 个标记"
L.PROVIDER_NO_MARKS = "未注册任何外挂数据包。"

L.SETTINGS = "设置"
L.SETTINGS_GENERAL = "常规"
L.SETTINGS_MARKERS = "标记"
L.SETTINGS_TOMTOM = "使用 TomTom 导航"
L.SETTINGS_LEFT_CLICK = "左键打开编辑器"
L.SETTINGS_MINIMAP = "在小地图上显示标记"
L.SETTINGS_ARROW = "显示玩家箭头"
L.SETTINGS_PROVIDERS = "外挂数据包"
L.SETTINGS_CLOSE = "关闭"

L.COMMAND_USAGE = "用法：/amm [io|debug|config]"
L.IMPORT_TITLE = "导入 / 导出"
L.IMPORT_PROMPT = "粘贴数据"
L.EXPORT_TITLE = "导出数据（Ctrl+C）"
L.IMPORT_OK = "导入完成：%d 个标记"
L.IMPORT_FAIL = "数据格式无效"

-- 主面板
L.PANEL_TITLE = "地图标记"
L.MARK_ICON_SIZE = "图标大小"
L.MARK_TEXT_SIZE = "文本字体"
L.SIZE_LOW = "小"
L.SIZE_HIGH = "大"
L.COORD_HINT = "留空取当前位置"
L.MARK_COLOR_LABEL = "调色"
L.MARK_GRAYSCALE_BTN = "灰度化"
L.MARK_ADD_POINT = "添加点位"
L.MARK_UPDATE_EXTERNAL = "更新标记"
L.MARK_UPDATE_POINT = "更新点位"
L.MARK_UNNAMED = "未命名"
L.EMPTY_LIST_TEXT = "暂无收藏的点位\n使用上方表单添加，点星星可收藏\n\n当前坐标快捷添加：/amm"

-- 备注大编辑框
L.BIGNOTE_TITLE = "详细信息编辑（支持颜色代码）"
L.BIGNOTE_TITLE_LABEL = "标题 (最多2行)："
L.BIGNOTE_NOTE_LABEL = "备注："
L.BIGNOTE_OK = "保存并关闭（仍需确认更新）"

-- 提示与错误
L.ERR_NAV_UNSUPPORTED = "当前地图不支持导航"
L.ERR_NO_POSITION = "无法获取当前位置，请手动输入坐标"
L.ERR_COORD_FORMAT = "坐标格式错误，应为：50 50 或 0.50 0.50"
L.ERR_NO_SELECTION = "没有选中的点位"
L.ERR_QUICKMARK_FAIL = "快捷标记失败，当前环境无法自动获取坐标"
L.QUICKMARK_OK = "快捷标记成功：[%s] (%.0f, %.0f)"
L.MINIMAP_ARROW_CHECK = "使用插件版玩家箭头以显示在标记上层（需重载）"

-- 导入 / 导出
L.IO_TITLE = "[ADE]标记数据  导出 / 导入"
L.IO_HINT = "【导出】复制下方代码。\n【导入】覆盖原文本，粘贴他人代码后点击导入。"
L.IO_IMPORT_BTN = "导入 (跳过已存在)"
L.IO_REFRESH_EXPORT = "刷新导出代码"
L.IO_ERR_FORMAT = "导入失败：数据格式错误或代码为空"
L.IO_DONE = "导入完毕！新增点位:|cffffd100%d|r个，新增图标:|cffffd100%d|r个。"
L.IO_NO_NEW = "导入完成，但没有发现新的点位或图标（已跳过重复项）"

-- 图标选择器
L.ICON_LABEL = "图标"
L.ICON_SELECTOR_TITLE = "图标选择器"
L.ICON_SELECTOR_HELP = "\n【左键】弹出下拉列表\n【右键】取消当前的图标选择\n\n【红色小把手】旋转图标。右击把手回正\n【滚轮】缩放以裁切显示区域\n\n【双击】手动输入 ID 添加提取图标\n【拖拽】将物品/法术拖到此处直接添加\n\n <游戏内提取>  列表里的图标可右键删除"
L.ICON_EXTRACT_OK = "成功提取游戏内图标：%s"
L.ICON_EXTRACT_FAIL = "提取失败：请输入正确的 ID ！"
L.ICON_DELETE_FORBID = "只能删除自己提取的图标哦"

-- 数据包注册
L.ERR_PROVIDER_NO_NAME = "RegisterMarkProvider 失败：provider 缺少 name 字段"
L.PROVIDER_REGISTERED = "已注册外挂坐标包：%s"

-- 杂项兜底文案
L.CROSS_MAP = "跨地图"
L.ICON_ITEM = "物品"
L.ICON_SPELL = "法术"
L.ICON_MACRO = "宏"
