# adeBagPack（ADE 背包整理）

v6.5 体系独立插件（旧 adeBackpack 移植重构）：背包 / 银行（含战团银行）分类整理与排序，可选接入 Dejunk / ItemEra / Baganator。不包含垃圾出售 / 摧毁与一键修理（旧功能已裁剪）。

## 功能

- **分类整理**：背包、银行、战团银行、材料袋按可配置分类顺序与排序键整理（钥石 / 装备方案 / 消耗品 / 材料 / 配方 / 任务等 20+ 分类）。
- **分类顺序可编辑**：支持按物品 / 按类型（`#主类##子类`）/ 按主类子类 / 按分类四类规则，设置页清单内用按钮调整顺序，改动即时生效；清单顺序即物理排序顺序。精确规则优先于宽泛规则（指定 ItemID > 类型 > 分类），所以把某物品规则拖到末尾即真正排末尾；删除条目回落默认位置。垃圾不参与顺序编辑、固定沉底（关闭对称整理时排在最后）。
- **逆序整理 / 垃圾对称整理**：支持从末槽反向填充；可选 Baganator 同款对称整理——非垃圾从首格正向排、垃圾从末格逆向排、**两段之间留空**（如 100 格时非垃圾占格 1 起、垃圾占格 100 起，中间空），开启逆序时整体镜像（替代旧「垃圾钉放区」）。旧档 `junkZone` 升级时自动迁移为新开关。

> 说明：a11 的对称整理只反排物品列表、未改槽位分配，物理上无法留空；a12 改为显式「物品→目标槽」双端游标映射（对齐 Baganator `OrderBags.lua`），对称整理才真正生效。
- **原生整合**：接管暴雪原生背包整理按钮（`Extra/Blizzard.lua`，可开关）。
- **Baganator 集成**：注册为 Baganator 官方容器排序 + 背包视图注入整理按钮（`Extra/Baganator.lua`，官方 API `RegisterContainerSort` / `RegisterRegion`）。
- **外部插件支持**（`External.lua`，选项随目标插件加载状态禁用/启用）：
  - Dejunk —— 垃圾判定来源接管（仅排序侧判定，不出售）；
  - ItemEra —— 资料片 / 专业文本显示（仅显示，排序键不变）。
- **小地图按钮**：左键设置、右键快捷菜单（UIKit 自绘，零第三方库依赖）。

## 依赖

- `ade_UIKit`（设置页 / 小地图按钮 / 存档合并，硬依赖）

存档沿用旧 `ADEDB_BACKPACK`，缺失键自动补全，旧安装可直接升级。

## 命令

- `/adeBackpack` 或 `/adebp`：打开设置窗口。
- `/adebp <目标>`：直接整理，`bag`（背包）/ `bank`（银行）/ `accountbank`（战团银行）/ `reagent`（材料袋）。
- `/adebp debug [itemID...]`：诊断扫描（全背包逐槽分类报告 / 指定物品查询）。逐槽 `SORTKEY` 为排序键前 4 值（分类序、部位/资料片、装等/资料片、绑定/品质），末行「模拟整理…待搬移=0」表示当前布局已符合规则。

## 目录结构

```
adeBagPack/
├── adeBagPack.toc        元数据与文件清单
├── Core.lua              入口、模块调度、斜杠命令、共享数据层
├── InitDB.lua            默认配置
├── Locales/              enUS(基) / zhCN / zhTW
├── Options.lua           设置页（ade_UIKit RegisterTab 四分组）
├── Minimap.lua           小地图按钮
├── UI/
│   └── RuleDialog.lua    添加排序规则对话框（分类/物品/类型四类规则）
├── Modules/
│   ├── Config.lua        分类规则与配置（junk 判定可接 Dejunk）
│   ├── Rule.lua          排序规则与排序键
│   ├── Slot.lua          槽位抽象
│   ├── Item.lua          物品抽象
│   ├── Bag.lua           背包容器
│   ├── Group.lua         分组
│   └── Pack.lua          整理 / 转移主逻辑
├── Extra/
│   ├── Blizzard.lua      原生整理按钮接管
│   └── Baganator.lua     Baganator 官方 API 集成
├── External.lua          Dejunk / ItemEra 对接
└── Debug.lua             /adebp debug 诊断
```

## 开发

- 计划与阶段进度：`_docs/plans/adeBagPack-dev-plan.md`；变更记录见 `CHANGELOG.md`。
- API 契约遵循 ade_UIKit b0xx 编号注释体系；外部插件选项统一口径见 `_docs/External-Addon-Support-Convention.md`。
