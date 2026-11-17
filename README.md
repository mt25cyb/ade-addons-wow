# wow-ade-addons

**ADE v6 插件开发**仓库（World of Warcraft 12.x）。设置界面视觉与控件规范称为 **ADE 风格**（源自 PrimeTooltip 一比一复用规格的沉淀与改名）。

## 项目目录说明

- **wow-textures**：软链接目录，插件开发可能使用到的自备素材，可自由拷贝使用
- **z-ref_wow-addons-libs**：软链接目录，魔兽世界插件第三方库本地副本，会固定周期更新以保持这些库是最新版本，开发过程中如要用到第三方库，可从这里拷贝使用
- **z-ref_retail_Interface_AddOns**：软链接目录，游戏端实际加载的插件镜像目录
- **z-ref_retail_WTF**：软链接目录，游戏端本地配置存储镜像目录
- **z-ref_wow-dev-doc**：软链接目录，魔兽世界插件开发的文档，其下的 wow_API_wiki.gg 目录是从 wiki.gg 提取到的 API 信息
- **z-ref_wow-dev-git**：软链接目录，Github 上对魔兽世界插件开发有帮助的项目本地克隆
- **_backup**：备份文件夹，用于在开发过程中需要备份时，保存在此处
- **_temp**：临时文件夹，存放一些临时文件
- **_tools**：仓库级工具脚本目录（zhCN 本地化同步三件套 `zhcn_*.py`、`wow_dict/` 英中词典库工具——权威 db 在外部数据目录 `D:\Dev-Workspace\_wow_dict\_wow_dict.db`）
- **wow_Locales_zhCN**：子项目，为第三方插件的简体中文语言包（见 [`wow_Locales_zhCN/_Locales_zhCN_README.md`](wow_Locales_zhCN/_Locales_zhCN_README.md)）

## 开发依据与规范

- **ADE 风格设置系统规范**：[`_docs/plans/ADE-v6-settings-sys-dev-plan.md`](_docs/plans/ADE-v6-settings-sys-dev-plan.md)（控件工厂中文名、下拉/滑条/颜色控件、全局色可调、方形与脱库约束、版本与图标规范）。
- **adeChatMod 开发规划**：[`_docs/plans/adeChatMod-dev-plan.md`](_docs/plans/adeChatMod-dev-plan.md)（专属适配与完整变更记录）。
- **API 技术依据**：[`_docs/api/README.md`](_docs/api/README.md)（查证工作流与原始文档索引）、[`_docs/api/api-changes-overview-12.x.md`](_docs/api/api-changes-overview-12.x.md)（12.x 逐版本变更与迁移对照，新补丁持续追加同一文档）。客户端目标版本 **12.1.5**（TOC 120105）。
- **本地化术语与词典更新流程**：[`_docs/Localization-Terminology-Workflow.md`](_docs/Localization-Terminology-Workflow.md)（数据源分层 L0–L3、7 步标准工序、`_wow_dict` 词典库维护）；涉及本地化的工作（含 `wow_Locales_zhCN` 子项目）一律遵守。
- **开发规则 / 技能 / 代理协作规范**：见 `.codebuddy/rules/`、`.codebuddy/skills/`、`.codebuddy/agents/`（规划 → API 查证 → 开发 三关流程）。
- **行为规范（最高优先级）**：一切分析、修改必须基于真实代码与文档，禁止臆想；结论须能给出「文件:行号」，查不到依据就停下来报告。
- **举例非穷举**：任务或文档中举的例子只覆盖部分情况，不能当成全部；须主动全量挖掘同类情况（同类文件/目录、同类 API 及变体、所有引用点与调用点）后再动手。
- 以上目录（`wow-textures`、`z-ref_*`）在开发过程中一律**只读**，摘录与整理产物写入 `_docs/`。
  **唯一例外**：`wow_Locales_zhCN` 子项目按其同步规则把语言文件写入
  `z-ref_retail_Interface_AddOns`（游戏端实际加载镜像），详见其 README；该例外仅限此子项目。

> 以上软链接/辅助目录均为开发工作区内容，**不入版本库**（已在 `.gitignore` 中排除）。

## 插件目录结构

每个插件 = 一个顶层目录，目录名与 TOC 文件名一致：

```
<AddonName>/
├── <AddonName>.toc
├── CHANGELOG.md
├── README.md
├── Core/ / Modules/ / Locales/ ...
└── ...
```

当前插件：

| 插件 | 版本 | 说明 |
|---|---|---|
| [`adeChatBar`](adeChatBar/README.md) | `v6.5-r001` | 聊天频道快捷条（原 `adeChatMod` 去掉频道名缩写）；设置界面基于 `ade_UIKit` v6.5 |
| [`ade_FontPack`](ade_FontPack/README.md) | `v6-r001-b001` | 共享字体库（LibSharedMedia-3.0，自有精选 + mMT/Blizzlike/ToriWhite/Visitor/Mono/ElvUI 六方来源；自带 LSM，独立运行） |
| [`ade_MediaPack`](ade_MediaPack/README.md) | `v6-r001-b001` | 共享材质库（状态条/边框/背景/音效 + BigWigs/DBM 计时条皮肤；自带 LSM，独立运行） |
| [`ade_UIKit`](ade_UIKit/README.md) | `v6.5-r001-b014` | ADE 系列共享控件库 + 样式库 + 公共函数库（当前实现：从 KAF `Krowi_Options` 2.0 复刻的原生选项窗口，两栏 / 多插件 Tab / 原生控件 / 双层行池 / KAF 特色标记），零第三方与零 AF 依赖；唯一开发计划见 [`ade_UIKit-dev-plan.md`](_docs/plans/ade_UIKit-dev-plan.md) |
| [`adeBlizzDemo`](adeBlizzDemo/README.md) | `v6.5-r001-b014` | `ade_UIKit` 控件画廊与功能自测（`/bofdemo`），双 Tab、双分组、真实键位绑定 |

> v6 线的 `ade_AddonFramework`、`ade_Demo`、未完成开发的 `adeTooltip`，以及改造前的 `adeChatMod` 已移入 `_backup/`（2026-11-17），工作区不再保留原目录。

## 同步流程（手动）

1. 在 dev 工作区完成开发，确认插件内版本四件套已更新（TOC 版本号、CHANGELOG、README、DevPlan）。
2. 仅复制该插件自身的目录（如 `adeFoo/`）到本仓库根目录，覆盖旧版本。
3. 核对本仓库内 `CHANGELOG.md` 与 `.toc` 中 `## Version:` 严格一致（ADE 约定格式 `12.1.0-4-MM.nn`）。
4. 提交并推送：

```powershell
git add .
git commit -m "feat(adeFoo): <本次发布摘要>"
git push
```

## 发布约定

- **手动发布**：`.toc` 内 `## Version:` 写死版本号；不引入 `.pkgmeta`，不使用 GitHub Actions 自动打包。
- **依赖声明**：框架等共享插件以 `## Dependencies` 声明，不 vendored 进各插件。
- **CHANGELOG**：随插件发布，采用「版本头 + 粗体摘要一行」的精简格式；完整修复记录保留在开发计划文档中，不入本仓库。

## License

[MIT](LICENSE)
