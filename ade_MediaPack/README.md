# ade_MediaPack

ADE 套件共享材质库（v6 移植版，`v6-r001-b001`）。向 LibSharedMedia-3.0 注册状态条 / 边框 / 背景 / 音效素材，并附带 BigWigs 与 DBM 计时条皮肤；**自带 LSM 副本，可独立运行**。字体位于独立插件 [`ade_FontPack`](../ade_FontPack/README.md)。客户端版本 **12.1.5**（TOC `## Interface: 120105`）。

## 独立运行机制

- LSM 由本插件 `Libs\` 下的 LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0 自行注册，经全局 `LibStub` 共享；`Core.lua` 取不到 LSM 即静默返回，各来源文件同样守卫，不注册假数据。
- BigWigs / DBM 皮肤走 `## OptionalDeps` + `ADDON_LOADED` 延迟注册（BigWigs 多为按需加载，文件级 `if not BigWigsAPI then return end` 会永久失效，故改为事件驱动）；装没装 BigWigs/DBM 都不影响本插件运行。皮肤操作对象均为 BigWigs/DBM 自建计时条（非暴雪原生框体），DBM 侧一律 `hooksecurefunc` 防 taint。

## 来源与注册前缀

| 前缀 | 来源 | 素材 |
|---|---|---|
| `-mMT- ` | !mMT_MediaPack：statusbar 340（编号体系循环生成，`n15.tga` 磁盘缺失已跳过）+ border 32 + background 23 + sound 25 | 420 |
| `-ToriWhite- ` | ToriWhite_SharedMedia：statusbar 1 + sound 143（沿用原包短语后缀，去彩色转义名） | 144 |
| `-Blizzlike- ` | BlizzlikeTextures：statusbar 12（11 .blp + 1 .tga，只引用 .blp 不引入冗余 .png）+ border 2 | 14 |
| `-ElvUI- ` | ElvUI_CustomMedia statusbar 18（原插件硬依赖 ElvUI，此处不依赖） | 18 |
| `-TBD- ` | SharedMedia_TBD statusbar `Line.tga`（仅引入用户指定的一条） | 1 |
| 皮肤专用 | `textures\glow.tga`（RuriWigs Ruri 半高条描边），不注册进 LSM，由 StyleWigs/StyleDBM 直接引用 | 1 |

BigWigs / DBM 皮肤注册名统一 `ADE Ruri`（两条皮肤链路各自独立注册，互不影响）。

## 目录结构

```
ade_MediaPack/
├── ade_MediaPack.toc
├── LICENSE                        # MIT（插件代码本体；第三方素材版权归各自作者）
├── assets/ade_128.tga             # ADE v6 统一图标（自 wow-textures 拷贝）
├── Libs/                          # LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0（12.0.0 v5，与 z-ref 权威源逐字节一致）
├── Core.lua                       # 主入口：取 LSM、暴露 ns.Register
├── MediaPack_<来源>.lua ×5        # 素材注册（mMT / Blizzlike / ToriWhite / TBD / ElvUI）
├── StyleWigs.lua                  # BigWigs 计时条皮肤（BigWigsAPI:RegisterBarStyle）
├── StyleDBM.lua                   # DBM 计时条皮肤（DBT:RegisterSkin + hooksecurefunc）
├── background/ border/ sound/ statusbar/   # 自有素材预留槽位（当前为空，目录约定见 Core.lua 头注）
├── material_3rd-party/<来源>/     # 第三方素材（597 个文件）
└── textures/glow.tga              # 皮肤描边纹理
```

## 验证清单（进游戏）

1. 单独安装本插件（不含其它 ADE 插件）可正常加载，无 Lua 报错。
2. 任意可换材质的插件下拉可见 `-mMT-`、`-ToriWhite-` 等前缀状态条/边框/背景/音效。
3. 装 BigWigs：插件设置 → 计时条样式可选 `ADE Ruri`，选中后半高条 + glow 描边 + 图标外置显示正常；未装 BigWigs 时无报错。
4. 装 DBM：DBM 计时条皮肤可选 `ADE Ruri`，显示正常；未装 DBM 时无报错。
5. 同时安装 ade_FontPack 时两包条目互不冲突（前缀隔离）。
