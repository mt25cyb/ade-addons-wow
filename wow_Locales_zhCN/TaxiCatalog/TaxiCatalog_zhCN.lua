-- TaxiCatalog 1.3.7 · zhCN 本地化（基准 enUS 1.3.7）
-- 多语言表注入模式：仅保存 local STR 表（含 ZH，STR 为本插件的多语言表名）+ 行级补丁段
-- （--@@ 标记）。安装时整块替换镜像文件中的表定义，并按补丁段重打代码分支
-- （见 zhcn_sync.py TABLE_INJECT，补丁从本文件解析）。
-- 目标：镜像 TaxiCatalog.lua；STR 插 ZH 表 + GetLang 加 zhCN 分支
local STR = {
  DE = {
    TITLE = "Flugziele",
    ONLY_REACHABLE = "Nur erreichbare",
    TIP_FLY = "Linksklick: fliegen",
    TIP_FAV = "Rechtsklick: Favorit umschalten",
    HDR_FAV = "★ Favoriten",
    HDR_HIST = "⟲ Letzte Ziele",
    UNKNOWN = "Unbekannt",
    OTHER = "Sonstige",
  },
  EN = {
    TITLE = "Flight destinations",
    ONLY_REACHABLE = "Reachable only",
    TIP_FLY = "Left click: fly",
    TIP_FAV = "Right click: toggle favorite",
    HDR_FAV = "★ Favorites",
    HDR_HIST = "⟲ Recent",
    UNKNOWN = "Unknown",
    OTHER = "Other",
  },
  ZH = {
    TITLE = "飞行目标",
    ONLY_REACHABLE = "仅可到达",
    TIP_FLY = "左键点击：飞行",
    TIP_FAV = "右键点击：切换收藏",
    HDR_FAV = "★ 收藏",
    HDR_HIST = "⟲ 最近目标",
    UNKNOWN = "未知",
    OTHER = "其他",
  },
}

-- ---------------- 行级补丁 ----------------
-- 安装时将镜像功能代码中的 old 整段替换为 new；new 已存在视为已打（幂等）。
-- 格式：--@@ patch（标题）/ --@@ old / --@@ new / --@@ end；内容行以 -- 开头，其后文本原样保留。
--@@ patch GetLang：zhCN 优先分支
--@@ old
--  if loc:lower():find("^de") then return "DE" end
--@@ new
--  if loc == "zhCN" then return "ZH" end
--  if loc:lower():find("^de") then return "DE" end
--@@ end
