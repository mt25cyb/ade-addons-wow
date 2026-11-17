# ade_UIKit 双形态同步契约

本库可被宿主插件以「独立插件」或「内置形态」两种方式携带。两种形态必须取同一张表，避免行为分叉。

## 形态定义

- **独立形态**：本目录作为一个 AddOn 单独加载，宿主用 `GetBlizzOptionsFrame("ade_UIKit", true)` 取库。
- **内置形态**：宿主把本目录整体拷进自己的 `Libs/` 并在 TOC 中按同样顺序加载；此时不要同时启用独立 AddOn。

## 同步步骤

1. 改本库任一文件后，先递增 `Core/Namespace.lua` 的 `MINOR`（例如 `1` → `2`）。
2. 同步目标目录的全部文件（包括 `Locales/` 与 `assets/`），保持文件名与加载顺序完全一致。
3. 更新本库 `CHANGELOG.md` 与 `README.md` 的版本号；独立形态 TOC 的 `## Version:` 与之保持一致。
4. 两端 `## Interface:` 必须相同（当前 `120105`）。
5. 不要改 `MAJOR`（`ade_UIKit`）；另有插件同时加载时由 `ResolveBOFNamespace` 的 minor 仲裁自动取高版本。

## 与其它库共存

- 本库的全局入口是 `ResolveBOFNamespace` / `GetBlizzOptionsFrame`，**刻意不带 AF 的 `ResolveNamespace` 同名**，避免覆盖 `ade_AddonFramework`。
- 运行环境已有 LibStub 时，本库会把同一张表注册进 LibStub（仅为生态兼容，不构成依赖）；没有 LibStub 时走自带 `BOF_LIBS` 注册表。
- 本库不读取、不修改任何其它插件的全局状态；宿主数据只通过 `RegisterTab({ saved = ... })` 交给库。
