# CompassHUD zhCN 多语言化一键应用脚本
# 位置：_tools\CompassHUD_zhCN_Locations-apply.ps1（zhCN 子项目统一脚本目录）
# 用途：插件重装 / 更新后，把 wow_Locales_zhCN\CompassHUD 成果覆盖回游戏端插件目录。
# 用法：powershell -ExecutionPolicy Bypass -File _tools\CompassHUD_zhCN_Locations-apply.ps1 [-Target <插件目录>] [-Force]
#   默认 Target = 项目镜像 z-ref_retail_Interface_AddOns\CompassHUD
#   wow_Locales_zhCN\CompassHUD\ 目录即插件目录镜像，可整目录直接覆盖游戏插件安装目录。

param(
    [string]$Target = "d:\Dev-Workspace\ade-addons-wow\z-ref_retail_Interface_AddOns\CompassHUD",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$LocalesRoot = "d:\Dev-Workspace\ade-addons-wow\wow_Locales_zhCN"
$Overlay = Join-Path $LocalesRoot "CompassHUD"                            # 成果目录 = 插件目录镜像
$Master  = Join-Path $LocalesRoot "_Locales_CompassHUD_zhCN.lua"          # zhCN 词条主档（中英对照）

if (-not (Test-Path $Target)) {
    Write-Error "目标插件目录不存在：$Target（插件已卸载？）"
    exit 1
}
if (-not (Test-Path $Overlay)) {
    Write-Error "成果目录不存在：$Overlay"
    exit 1
}
if (-not (Test-Path $Master)) {
    Write-Error "找不到词条主档：$Master"
    exit 1
}

# --- 版本基线核对：成果基于 2.1.1 制作 ---
$tocPath = Join-Path $Target "CompassHUD.toc"
$version = (Select-String -Path $tocPath -Pattern "^## Version:\s*(.+)$").Matches[0].Groups[1].Value.Trim()
if ($version -ne "2.1.1" -and -not $Force) {
    Write-Warning "目标插件版本为 $version，而成果基于 2.1.1 制作。上游更新可能已改动措辞/结构，"
    Write-Warning "直接覆盖可能造成功能异常或词条 key 失效。请先阅读 wow_Locales_zhCN\_Locales_CompassHUD_zhCN_Modification-Locations.md 复核差异，"
    Write-Warning "确认无冲突后加 -Force 继续；或按文档对上游新版重新应用包裹修改。"
    exit 2
}

# --- 1. 词条主档 → 成果目录（保持主档唯一权威，成果目录始终自洽完整） ---
Copy-Item -Path $Master -Destination (Join-Path $Overlay "Locales\zhCN.lua") -Force
Write-Host "同步词条主档 -> CompassHUD\Locales\zhCN.lua"

# --- 2. 覆盖成果目录全部文件到插件目录（保留插件目录结构） ---
$copied = 0
Get-ChildItem $Overlay -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Overlay.Length + 1)
    $dest = Join-Path $Target $rel
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item -Path $_.FullName -Destination $dest -Force
    $copied++
    Write-Host "覆盖 $rel"
}

# --- 3. 结果核对：哨兵行确认覆盖成功 ---
$sentinel = Select-String -Path (Join-Path $Target "Init.lua") -Pattern "Addon\.env\.L = CompassHUDLocale"
if ($sentinel) {
    Write-Host "`n完成：共写入 $copied 个文件。哨兵行确认通过，进游戏 /reload 验证中文生效。"
} else {
    Write-Error "覆盖后未在 Init.lua 找到哨兵行（Addon.env.L = CompassHUDLocale），请人工检查。"
    exit 3
}
