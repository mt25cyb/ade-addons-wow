# ade_AddonFramework

ADE v6 的控件库 + 样式库 + 公共函数库。以 **MiliUI 自写库元素风格**为视觉基线，黑白灰固定、强调色只染「勾 / 滑块 / ▼ / 标题类 / hover 边框」；引入 ADE 的单选项页 720 / 多选项页 860 双布局（b009 起按 ADE-v6-FrameDesign：单布局页按钮在标题栏右侧、多布局左栏页脚区放复选框与「打开预览」；b010 起预览区为独立组件 `Template/PreviewPanel`，双布局只留开关位，另有 `onPageChanged` 页切换回调、`Form.enabled` 禁用态与 `ScrollToRow/HighlightRow` 行定位）与 `#EEE4AE` 可调主题色。零第三方依赖。

- 版本：`v6-r001-b001`
- 客户端：12.1.5（`## Interface: 120105`）
- 规划：`_docs/plans/ade_AddonFramework-dev-plan.md`
- 演示插件：`../ade_Demo/`
- 双形态同步契约：`SYNC.md`

## 快速取用

```lua
local AF = GetFramework("ade_AddonFramework", true) -- 或 LibStub("ade_AddonFramework", true)
if not AF then return end
AF.ApplyAccent(settings.globalColor or AF.DEFAULT_ACCENT)
local btn = AF.Widget.Button.Create(parent, { text = AF.L["AF_OK"] })
```

独立形态：宿主 TOC 写 `## Dependencies: ade_AddonFramework`。内置形态：把库放进宿主 `Libs/ade_AddonFramework/`，按 `SYNC.md` 列加载清单并覆盖 `AF.ADDON_DIR`。

## 目录

| 目录 | 内容 |
|---|---|
| `Core/Namespace.lua` | 自写注册表 `ResolveNamespace` / `GetFramework`，minor 版本仲裁 |
| `Core/Env.lua` | 宿主接点、双布局常量、字体、`MediaPath` |
| `Core/Style.lua` | 固定黑白灰色阶 `AF.C`、`WHITE8X8` 纯色纹理 + 四条 1px 边、`AF.Tint` |
| `Core/Theme.lua` | `AF.T` 强调色系、`ApplyAccent` 原地更新 + 广播、`AccentHex` |
| `Function/` | `Callbacks`、`DB`（`settings.*`，颜色 `{red,green,blue}`） |
| `Locales/` | enUS / zhCN / zhTW，按 `GetLocale()` 隔离 |
| `Widget/` / `Options/` | 控件与可复用页模板（随阶段落地） |
| `assets/textures/` | 从只读源真实拷贝的素材，逐文件清单见 `assets/MANIFEST.txt` |
| `assets/sounds/` | 音效（预留） |

## 着色纪律

`AF.C` 里的黑白灰是固定常量，**不参与主题派生**；只有调用 `AF.Tint()` 的纹理会随 `ApplyAccent` 变色。逐控件着色部位见规划文档 §一。绘制后端一律 `WHITE8X8` + 四条 1px 边，不使用 `BackdropTemplate` / `SetBackdrop*`。

## 素材来源

只读源（禁止修改）：`wow-textures/ade_128.tga`、`z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Media/`、`GoodRange/media/`、`Dejunk/assets/`、`Mapzeroth/Media/`、`PrettyTooltip/art/`。用户已确认素材可自由拷贝（2026-11-12）。逐文件与来源登记在 `assets/MANIFEST.txt`。

目录约定（2026-11-13 用户指定）：插件图标在 `assets/` 根、字体在 `assets/fonts/`（当前代码用暴雪 `STANDARD_TEXT_FONT`，字体文件暂未引用、仅归档）、贴图在 `assets/textures/`。

## 控件与模板清单

| 层 | 已落地 |
|---|---|
| 核心表单 | `Widget/Text|Icon|Button|Checkbox|Switch|Editbox|Slider|Dropdown|Color.lua` |
| 容器与弹层 | `Widget/Scroll|TitleBar|Popup|Row|List|InfoBar|Tabs|Preview|ContextMenu.lua`、`Widget/Form.lua` |
| 选项页模板 | `Options/OptionsFrame.lua`（720/860 双布局）、`Options/ProfilePage.lua`（5 按钮 + 重命名 + 重置移位）、`Options/AboutPage.lua`、`Options/ProfileDB.lua` |
| 拖拽与集成 | `Widget/RowDrag.lua`（行首移动控件）、`SoundPicker|PreviewButton|AnchorGrid|SearchBar|Hint|PositionNudge|Glow|MinimapButton|Snap|EditMode.lua` |
| 函数层 | `Function/Callbacks|DB|Masque|Fade.lua` |

图标三态由 `AF.ResolveIcon`（Texture 侧）与 `AF.IconEscape`（FontString 侧）收敛；控件图标一律用暴雪原生 Atlas，无字符图标。

## 进游戏验证清单

- 插件列表图标（`## IconTexture`）显示正常；`/reload` 后 `GetFramework()` 返回非空。
- 独立与内置两种形态同时存在时，取到同一张表且 `MINOR` 为较高值（内置试点步骤见 `../ade_Demo/Libs/ade_AddonFramework/TESTING.md`，尚未实机执行）。
- `ApplyAccent` 改色后：勾 / 滑块 / 下拉箭头 / 标题线变色，控件底色与正文仍为固定黑白灰。
- 三语客户端下 Locales 互不覆盖；配置页 5 颗按钮在长译文语系不溢出 `contentW=672`。
- 8 个用户已验证的原生 Atlas 在实机可取到纹理；逐项重置三态、行首移动控件拖拽、ESC 关闭均正常。
