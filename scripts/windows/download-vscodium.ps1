<#
  Скачивание последнего релиза VSCodium для Windows (ZIP).
  Архитектура: -Arch x64 | arm64
  Запуск: .\download-vscodium.ps1 [-Arch x64] [-OutDir .]
#>
param(
    [ValidateSet("x64", "arm64")]
    [string] $Arch = "x64",
    [string] $OutDir = "."
)

$ErrorActionPreference = "Stop"

$api = "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
$rel = Invoke-RestMethod -Uri $api -Method Get
$pattern = "^VSCodium-win32-$Arch-.*\.zip$"
$asset = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
if (-not $asset) {
    throw "Не найден asset по шаблону $pattern в релизе $($rel.tag_name)"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$dest = Join-Path $OutDir $asset.name
Write-Host "Скачивание $($asset.browser_download_url)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing
Write-Host "Сохранено: $dest (релиз $($rel.tag_name))"
