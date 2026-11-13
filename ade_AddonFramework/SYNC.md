# 双形态同步契约（Ace3 / LSM 式）

权威源码：`ade_AddonFramework/`。内置形态是把库文件逐字拷贝到宿主的 `Libs/ade_AddonFramework/`，**库源码零改动**；差异只允许落在加载清单层。

## 1. 版本仲裁

- `Core/Namespace.lua` 的 `MINOR` 是唯一版本源；每次把库同步进宿主并发布时递增 1。
- `ResolveNamespace(MAJOR, MINOR)` 按 minor 仲裁：同版 / 低版副本静默退出（`AF_LOAD_ALLOWED = false`），其后每个库文件的 `if not AF then return end` 会让整份副本跳过，因此多副本共存时始终只有最高版本生效，且所有宿主取到同一张表。
- 运行环境已有 `LibStub` 时，注册表会把同一张表注册进去；宿主可用 `GetFramework()` 或 `LibStub("ade_AddonFramework", true)` 软探测。

## 2. 独立形态

`ade_AddonFramework.toc` 逐行列出全部库文件；宿主用 `## Dependencies: ade_AddonFramework`（硬）或 `## OptionalDeps`（软）。按需加载走 `C_AddOns.LoadAddOn("ade_AddonFramework")`，取用 `GetFramework("ade_AddonFramework", true)`。

## 3. 内置形态

宿主内建 `Libs/ade_AddonFramework/`，并在宿主 TOC 或 `Libs.xml` 按**与库 TOC 相同的顺序**列出同一批相对路径。宿主只需在加载库之前设置：

```lua
AF.ADDON_DIR = "<宿主插件目录名>"   -- 让 AF.MediaPath() 指向宿主 assets；此项属宿主接点，不修改库源码
```

同时把 `ade_AddonFramework/assets/textures/` 拷贝到宿主 `assets/textures/`。若宿主完全不用自带素材（图标全走暴雪原生 Atlas / FileID），也可不设置 `ADDON_DIR`，只要不调用 `AF.MediaPath()`。

## 4. 同步方式（手动清单）

1. 拷贝 `Core/`、`Function/`、`Widget/`、`Options/`、`Locales/`、`assets/` 到宿主 `Libs/ade_AddonFramework/`。
2. 把 `Core/Namespace.lua` 的 `MINOR` 递增 1（仅宿主副本，权威源码同步递增）。
3. 按库 TOC 的文件顺序生成宿主 `Libs.xml`（或宿主 TOC 中的逐行清单）。
4. 用 `GetFramework()` 自检：独立形态与内置形态同时启用时，两者应返回同一张表且 `MINOR` 为较高值。

不引入第三方库；本仓库没有自动同步脚本，按上述清单手工执行并记入 CHANGELOG。
