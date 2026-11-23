# LibWMT_LeatrixMaps_Patch — CHANGELOG

## v6.5-r002 - 2026-11-23（顶栏再下沉：解决「溢出修好后标题等顶栏控件被遮盖」）

**用户反馈：r001 把面板改到 -50 后控件溢出消失，但原先在顶栏的标题等控件仍被遮盖，建议把 LibWMT 创建的框体再下沉。根因（全部磁盘实证）：各插件顶栏外扩到面板上方 4~30px——`adeMapTab/Public/MapTab.lua:273-282` `CreateTopBar` 锚 panel `+30`、高 26（Portal `:586` / Delve `:135` 均用默认值）；`WorldQuestTab.xml:650-658` WQT TopBar `BOTTOM→父 TOP y=4` + `Size y=26` = 同样 +30；齿轮按钮 `MapTab.lua:217` / `WorldQuestTab.xml:418,771` / `adeMapMark/Settings.lua:446` 均 `TOPRIGHT panel +25`；边框 `WorldMapPanel.lua:658` +7、滚动条 `MapTab.lua:309` +2。panel 在 -50 时顶栏落在距内容区顶部 20~46px，正压在 Leatrix 标题栏（原生内容被下移到 -50 让出的 0~50px，`Leatrix_Maps.lua:737-740`）内；且第三方面板 FrameLevel = qmf+200（`MapTab.lua:194`）远高于标题栏，于是盖住标题栏里的地图标题 / 搜索框 / 设置按钮。r002：目标 y 由 -50 再下沉 30px 到 **-80**（顶栏顶边恰好落到 50px 标题栏底线、底边 76px，与 panel 内容区 80px 保留原设计 4px 间隙，且与原生内容起始线 -50 对齐）；`SnapTop` 同时识别 -29 源值与上一版目标 -50（兼容 r001 已应用状态），已是目标值的帧不再无谓重锚；`appliedTopY` 在 ApplyAll 末尾同步。新增 `/lwmtlmp offset <n>`（29~160，默认 80）会话内微调下沉量、`status` 显示目标 y；`/reload` 复位。BOTTOMRIGHT 保持，仅顶部下移（与 Leatrix 对 QuestScrollFrame 的处理同构）。**

## v6.5-r001 - 2026-11-23

**首发：修复 Leatrix Maps「使用简易地图框体」下 LibWorldMapTabs 系 Tab 面板 21px 偏移。实证根因：暴雪原生 QuestMapFrame.xml:490/848/937 与全部第三方（adeMapTab/Public/MapTab.lua:43,186；adeMapMark/Settings.lua:404；WorldQuestTab.xml:621）统一用 TOPLEFT y=-29，而 Leatrix_Maps.lua:739/749 把原生内容改为 -50 却不认识库动态创建的 contentFrame（LibWorldMapTabs.lua:294-296）。补丁以独立插件形式取 LibStub 单例，扫描 lib.contentFrames 及其子帧/QuestMapFrame 子帧，把 -29 重锚为 -50（全铺型容器不动，避免 WQT 叠加成 -79）；生效判据 = C_AddOns.IsAddOnLoaded + LeaMapsDB["SimpleMapFrame"]=="On" + QuestScrollFrame 行为确认 -50（LeaMapsLC/LeaLockList 为 Leatrix local，外部不可读）；两阶段延迟应用 + 帧级 SetPoint 钩子 + LinkTabToContentFrame 钩子覆盖全部重锚路径；覆盖 WQT / adeMapTab_Portal / adeMapTab_Delve / adeMapMark；/lwmtlmp status|apply 诊断；不改任何库副本与第三方插件。**
