# ade_FontPack

ADE 套件共享字体库（v6 移植版，`v6-r001-b001`）。向 LibSharedMedia-3.0 注册共享字体，供任何读取 LSM 字体列表的插件选用；**自带 LSM 副本，可独立运行**（不依赖任何其它 ADE 插件或第三方插件）。客户端版本 **12.1.5**（TOC `## Interface: 120105`）。

## 独立运行机制

- LSM 由本插件 `Libs\` 下的 LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0 按 TOC 顺序自行注册，统一经全局 `LibStub` 取用；其它插件（含宿主自己 vendored 的 LSM 副本）通过 LibStub 的 minor 仲裁共享同一实例。
- `Core.lua` 取 `LibStub("LibSharedMedia-3.0", true)`，失败即整文件静默返回；各来源文件检测 `ns.Register` 后同样跳过——LSM 缺失时不注册任何假数据、不报错。
- 字体统一传 `zhALL` 区域掩码（`LOCALE_BIT_zhCN + LOCALE_BIT_zhTW + LOCALE_BIT_western`），zhCN/zhTW 客户端也能取到；不含中文字形的拉丁字体显示名带 `(无中文)` 后缀提示，避免被误用于中文文本。

## 来源与注册前缀

| 前缀 | 来源 | 数量 |
|---|---|---|
| `-ade- ` | 自有精选（`font\`，18 个：暗黑破坏神 Light/Medium、原神、守望先锋、塔瑞斯世界、方正粗圆/楷体、源界明朝等，拉丁字体标注无中文） | 18 |
| `-mMT- ` | !mMT_MediaPack `media\fonts\` | 23 |
| `-Blizzlike- ` | BlizzlikeTextures `front\expressway.ttf`（原包注册路径失效，按真实目录注册） | 1 |
| `-ToriWhite- ` | ToriWhite_SharedMedia `Media\Fonts\`（原注册名带彩色转义、langmask 无中文，此处改纯文本名 + zhALL） | 3 |
| `-Visitor- ` | LSM-Visitor 点阵字体 TT1/TT2 | 2 |
| `-Mono- ` | SharedMediaFontsMono 等宽字体（原插件自定义 `font-mono` 媒体类型非 LSM 标准，此处只按标准 `font` 注册；Noto CJK 每文件只注册一次） | 9 |
| `-ElvUI- ` | ElvUI_CustomMedia（Atwood）`Fonts\`（原插件硬依赖 ElvUI，此处去品牌词后缀、不依赖 ElvUI） | 14 |

## 目录结构

```
ade_FontPack/
├── ade_FontPack.toc
├── LICENSE                       # MIT（插件代码本体；第三方字体版权归各自作者）
├── assets/ade_128.tga            # ADE v6 统一图标（自 wow-textures 拷贝）
├── Libs/                         # LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0（12.0.0 v5，与 z-ref 权威源逐字节一致）
├── Locales/                      # enUS / zhCN / zhTW（字体显示名）
├── Core.lua                      # 主入口：取 LSM、暴露 ns.Register、注册自有精选
├── FontPack_<来源>.lua ×6        # 第三方来源注册（mMT / Blizzlike / ToriWhite / Visitor / Mono / ElvUI）
├── font/                         # 自有精选字体（18）
└── font_3rd-party/<来源>/        # 第三方字体（mMT 23 / ElvUI 14 / Mono 9 / ToriWhite 3 / Visitor 2 / Blizzlike 1）
```

## 待办

- 大体积 CJK 等宽字库（Noto Sans Mono CJK sc/tc/kr，单个约 16MB）目前登录全量加载；后续评估 `## LoadOnDemand` 子插件拆分（见 `_docs/plans/ade_FontPack-dev-plan.md` 待办节）。

## 验证清单（进游戏）

1. 单独安装本插件（不含其它 ADE 插件）可正常加载，无 Lua 报错。
2. 任意可换字体的插件（如 LSB/ElvUI 类）字体下拉可见 `-ade-`、`-mMT-` 等前缀字体；zhCN 客户端可见全部条目。
3. 选用 `-ade- 暗黑破坏神` 等含中文字库显示正常；选用 `(无中文)` 拉丁字体显示英文正常、中文回退默认字体。
4. 同时安装 ade_MediaPack 时两包字体/材质条目互不冲突（前缀隔离）。
