# wow-ade-addons

ADE 系 World of Warcraft 插件的发布仓库。

> 开发工作区为 `ade-wow-addons-dev`（私有开发仓库）。本仓库只放对外发布的插件源码，**不包含**参考库（`z-ref_*`）、辅助工具（`_tools/`）、开发文档（`_docs/`）等非发布内容。

## 仓库结构

每个插件 = 一个顶层目录，目录名与 TOC 文件名一致：

```
<AddonName>/
├── <AddonName>.toc
├── CHANGELOG.md
├── README.md
├── Core/ / Modules/ / Locales/ ...
└── ...
```

（插件列表待首个插件入库后补充）

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
