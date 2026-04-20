<#
  Скачивание VSIX из Open VSX по списку (строки publisher.extension@version).
  Разбор id: первый '.' отделяет namespace от имени расширения в пути API Open VSX.
  Запуск: .\download-extensions.ps1 [-List path] [-OutDir vsix]
#>
param(
    [string] $List = "vscodium-extensions.txt",
    [string] $OutDir = "vsix"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $List)) {
    throw "Файл списка не найден: $List"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

foreach ($raw in Get-Content -LiteralPath $List -Encoding UTF8) {
    $line = $raw.Trim()
    if (-not $line -or $line.StartsWith("#")) { continue }

    $at = $line.LastIndexOf("@")
    if ($at -lt 1) {
        Write-Warning "Пропуск (нет версии после @): $line"
        continue
    }

    $extId = $line.Substring(0, $at).Trim()
    $ver = $line.Substring($at + 1).Trim()
    $dot = $extId.IndexOf(".")
    if ($dot -lt 1 -or $dot -eq ($extId.Length - 1)) {
        Write-Warning "Пропуск (ожидался publisher.extension): $line"
        continue
    }

    $namespace = $extId.Substring(0, $dot)
    $name = $extId.Substring($dot + 1)
    $metaUrl = "https://open-vsx.org/api/$namespace/$name/$ver"

    try {
        $meta = Invoke-RestMethod -Uri $metaUrl -Method Get
        $dl = $meta.files.download
        $leaf = Split-Path $dl -Leaf
        $dest = Join-Path $OutDir $leaf
        Write-Host "GET $dl"
        Invoke-WebRequest -Uri $dl -OutFile $dest -UseBasicParsing
        Write-Host " -> $dest"
    }
    catch {
        Write-Warning "Ошибка для ${extId}@${ver}: $_"
    }
}

Write-Host "Готово. Каталог: $OutDir"
