# Changelog

| 版本 | 日期 | 要点 |
| --- | --- | --- |
| v6.5-r003 | 2026-11-23 | 地图信息面板新增「Y 轴偏移」设置：顶部/底部两种位置各自独立保存（gwWorldMapOffsetTop/Bottom，默认值即原锚点偏移 top=2/bottom=-4，旧档缺键回退默认行为不变）；设置页只显示一个滑块，get/set 动态读写「当前布局」那份（位置下拉切换后 UIKit 的 OnOptionChanged → Window:Refresh 重跑行 get，滑块值自动跟随）；存档校验只接受数字；sectionKeys 覆盖两键（分段重置/变更计数完整）；三语文案 WorldMapOffsetY |
| v6.5-r002 | 2026-11-18 | 修复外观页三个颜色按钮（前缀/背景/边框）点击无反应：根因 = KeySpec 无条件塞 set，而 UIKit MakeOption 的 Set 分支 set 优先于 onClick → execute+onClick 组合永不被执行、点击反而把颜色键写成布尔 true（UIKit b034 改为 execute 点击 onClick 优先，程序化 Set/Reset 仍走 set）；颜色行同步升级为 UIKit b034 的 kind="color" 色块控件（显示当前颜色、点击弹官方 ColorPickerFrame），存档仍为 8 位 hex 无迁移；InitDB 补 gwBgColor/gwBorderColor 非字符串值清洗 |
| v6.5-r001 | 2026-11-18 | 首发：自 idTipExt 1.3.0 拆出「地理监视面板 + 世界地图信息面板」（GeoWatcher.lua 整文件迁入为 Panel.lua，零功能损失）；接入 ade_UIKit 设置页（panel/appearance/behavior 三分区 + 加载期 stub）；新增面板前缀色独立选项（gwPrefix*）与自带 style 键；首启一次性迁移 idTipExtDB 的 pw*/gw* 键（含面板位置与运行时缓存），迁移后不回读；后续地图增强功能在此插件挂载 |
