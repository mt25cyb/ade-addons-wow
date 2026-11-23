-- TaxiCatalog 1.3.7 · zhCN 本地化（基准 enUS 1.3.7）
-- 多语言表注入模式：仅保存 local STR 表（含 ZH，STR 为本插件的多语言表名）+ 行级补丁段
-- （--@@ 标记）。安装时整块替换镜像文件中的表定义，并按补丁段重打代码分支
-- （见 zhcn_sync.py TABLE_INJECT，补丁从本文件解析）。
-- 目标：镜像 TaxiCatalog_Ace3.lua；STR 插 ZH/CHINESE + EffectiveLang 与下拉 values 加 ZH
local STR = {
  EN = {
    GENERAL = "General",
    DESIGN = "Design",
    LANGUAGE = "Language",
    LANGUAGE_DESC = "AUTO uses the WoW client language (deDE/enUS).",
    AUTO = "Auto",
    GERMAN = "German",
    ENGLISH = "English",
    CHINESE = "Chinese",
    SIDE = "Side",
    LEFT = "Left",
    RIGHT = "Right",
    ONLY_REACHABLE = "Only reachable destinations",
    WIDTH = "Width",
    HEIGHT = "Height",
    START_COLLAPSED = "Start collapsed",

    OPACITY = "Opacity",
    BG_COLOR = "Background color",
    BG_LSM = "Background (SharedMedia)",
    USE_CUSTOM_BG = "Use custom background",
    USE_CUSTOM_BG_DESC = "If enabled, the path below is used (instead of SharedMedia).",
    CUSTOM_BG_PATH = "Custom background (path)",
    CUSTOM_BG_PATH_DESC = "Path inside WoW/AddOns. WoW reliably loads .tga or .blp. JPG/PNG usually do not work (convert first). Example: Interface\\AddOns\\TaxiCatalog\\Media\\bg.tga",

    FONT = "Font (SharedMedia)",
    OUTLINE = "Font outline",
    TITLE_SIZE = "Title size",
    ZONE_SIZE = "Zone size",
    ROW_SIZE = "Entry size",
    LOGO_PATH = "Logo (path)",
    LOGO_SIZE = "Logo/Tab size",

    OUT_NONE = "None",
    OUT_OUTLINE = "Outline",
    OUT_THICK = "ThickOutline",
    OUT_MONO = "Monochrome",
    OUT_MONO_OUT = "Mono+Outline",
    OUT_MONO_THICK = "Mono+Thick",

    TIP = "Tip:\n- Left click a destination = fly\n- Right click a destination = favorite\n- Round logo button on the flight map toggles the panel\n- Search is at the bottom",
  },
  DE = {
    GENERAL = "Allgemein",
    DESIGN = "Design",
    LANGUAGE = "Sprache",
    LANGUAGE_DESC = "AUTO nutzt die WoW-Sprache (deDE/enUS).",
    AUTO = "Auto",
    GERMAN = "Deutsch",
    ENGLISH = "Englisch",
    CHINESE = "Chinesisch",
    SIDE = "Seite",
    LEFT = "Links",
    RIGHT = "Rechts",
    ONLY_REACHABLE = "Nur erreichbare Ziele",
    WIDTH = "Breite",
    HEIGHT = "Höhe",
    START_COLLAPSED = "Start eingeklappt",

    OPACITY = "Transparenz",
    BG_COLOR = "Hintergrundfarbe",
    BG_LSM = "Hintergrundbild (SharedMedia)",
    USE_CUSTOM_BG = "Eigenes Hintergrundbild verwenden",
    USE_CUSTOM_BG_DESC = "Wenn aktiv, wird der Pfad unten genutzt (statt SharedMedia).",
    CUSTOM_BG_PATH = "Eigenes Hintergrundbild (Pfad)",
    CUSTOM_BG_PATH_DESC = "Pfad innerhalb von WoW/AddOns. Blizzard lädt zuverlässig nur .tga oder .blp. JPG/PNG funktionieren in der Regel nicht (vorher konvertieren). Beispiel: Interface\\AddOns\\TaxiCatalog\\Media\\bg.tga",

    FONT = "Schriftart (SharedMedia)",
    OUTLINE = "Schrift-Outline",
    TITLE_SIZE = "Titel Größe",
    ZONE_SIZE = "Zone Größe",
    ROW_SIZE = "Eintrag Größe",
    LOGO_PATH = "Logo (Pfad)",
    LOGO_SIZE = "Logo/Tab Größe",

    OUT_NONE = "Keine",
    OUT_OUTLINE = "Outline",
    OUT_THICK = "ThickOutline",
    OUT_MONO = "Monochrome",
    OUT_MONO_OUT = "Mono+Outline",
    OUT_MONO_THICK = "Mono+Thick",

    TIP = "Tipp:\n- Linksklick auf Ziel = fliegen\n- Rechtsklick auf Ziel = Favorit\n- Runder Logo-Button auf der Karte klappt das Panel ein/aus\n- Suche ist unten",
  },
  ZH = {
    GENERAL = "常规",
    DESIGN = "外观",
    LANGUAGE = "语言",
    LANGUAGE_DESC = "AUTO 使用魔兽客户端语言（deDE/enUS/zhCN）。",
    AUTO = "自动",
    GERMAN = "德语",
    ENGLISH = "英语",
    CHINESE = "中文",
    SIDE = "侧边",
    LEFT = "左侧",
    RIGHT = "右侧",
    ONLY_REACHABLE = "仅显示可到达的目标",
    WIDTH = "宽度",
    HEIGHT = "高度",
    START_COLLAPSED = "启动时折叠",

    OPACITY = "透明度",
    BG_COLOR = "背景颜色",
    BG_LSM = "背景（SharedMedia）",
    USE_CUSTOM_BG = "使用自定义背景",
    USE_CUSTOM_BG_DESC = "启用后使用下方路径（替代 SharedMedia）。",
    CUSTOM_BG_PATH = "自定义背景（路径）",
    CUSTOM_BG_PATH_DESC = "WoW/AddOns 内的路径。WoW 仅可靠加载 .tga 或 .blp。JPG/PNG 通常无效（需先转换）。示例：Interface\\AddOns\\TaxiCatalog\\Media\\bg.tga",

    FONT = "字体（SharedMedia）",
    OUTLINE = "字体描边",
    TITLE_SIZE = "标题字号",
    ZONE_SIZE = "区域字号",
    ROW_SIZE = "条目字号",
    LOGO_PATH = "Logo（路径）",
    LOGO_SIZE = "Logo/标签大小",

    OUT_NONE = "无",
    OUT_OUTLINE = "描边",
    OUT_THICK = "粗描边",
    OUT_MONO = "单色",
    OUT_MONO_OUT = "单色+描边",
    OUT_MONO_THICK = "单色+粗描边",

    TIP = "提示：\n- 左键点击目标 = 飞行\n- 右键点击目标 = 收藏\n- 飞行地图上的圆形 Logo 按钮可开合面板\n- 搜索框在底部",
  },
}

-- ---------------- 行级补丁 ----------------
-- 安装时将镜像功能代码中的 old 整段替换为 new；new 已存在视为已打（幂等）。
-- 格式：--@@ patch（标题）/ --@@ old / --@@ new / --@@ end；内容行以 -- 开头，其后文本原样保留。
--@@ patch EffectiveLang AUTO：zhCN 优先分支
--@@ old
--    if loc == "deDE" then return "DE" end
--@@ new
--    if loc == "zhCN" then return "ZH" end
--    if loc == "deDE" then return "DE" end
--@@ end
--@@ patch EffectiveLang 手动选择：ZH/CHINESE 分支
--@@ old
--  if v == "EN" or v == "ENGLISH" then return "EN" end
--@@ new
--  if v == "EN" or v == "ENGLISH" then return "EN" end
--  if v == "ZH" or v == "CHINESE" then return "ZH" end
--@@ end
--@@ patch 语言下拉 values：加 ZH 项
--@@ old
--  return { AUTO = T("AUTO"), DE = T("GERMAN"), EN = T("ENGLISH") }
--@@ new
--  return { AUTO = T("AUTO"), DE = T("GERMAN"), EN = T("ENGLISH"), ZH = T("CHINESE") }
--@@ end
