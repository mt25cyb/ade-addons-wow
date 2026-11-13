# 内置形态试点说明

`ade_Demo` 目前通过 `## Dependencies: ade_AddonFramework` 验证**独立形态**。内置形态的验证按 `../../../ade_AddonFramework/SYNC.md` 执行，本目录不重复存放库源码（避免仓库内出现两份权威源码）。

## 试点步骤（进游戏前手工执行）

1. 把 `ade_AddonFramework/` 下的 `Core/`、`Function/`、`Widget/`、`Options/`、`Locales/`、`assets/` 逐字拷贝到本目录 `Libs/ade_AddonFramework/`。
2. 把库 `ade_AddonFramework.toc` 中的文件清单按相同顺序生成本目录的 `Libs.xml`（XML `<Script file="..."/>` 或宿主 `.toc` 逐行列出）。
3. 宿主加载库之前设置 `AF.ADDON_DIR = "ade_Demo"`（宿主接点，不改库源码），并把 `assets/textures/` 拷进宿主 `assets/textures/`。
4. 按 `SYNC.md` 递增 `Core/Namespace.lua` 的 `MINOR`。
5. 同时启用独立库插件与宿主，进游戏后由宿主调用 `DEMO.VerifyDualForm()`（可在初始化时调用一次），并运行 `/afdemo test` 做基础自测。

## 验收

- `DEMO.VerifyDualForm()` 输出 `same=true`，且 `MINOR` 等于两份副本中较高值。
- 低版本副本整体跳过（`AF_LOAD_ALLOWED=false`），不会出现两套同名字体对象或两份控件实现互相覆盖。
- 若环境存在 LibStub，`LibStub("ade_AddonFramework", true)` 与 `GetFramework()` 返回同一张表。

**当前状态**：本试点尚未实机执行，不标记为已验证；进游戏验证清单见 `../../../ade_AddonFramework/README.md`。
