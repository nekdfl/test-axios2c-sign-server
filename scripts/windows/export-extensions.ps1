<#
  Экспорт установленных расширений VSCodium в файл (формат: publisher.name@version).
  Запуск: .\export-extensions.ps1 [-OutFile path] [-Cli path]
#>
param(
    [string] $OutFile = "vscodium-extensions.txt",
    [string] $Cli = ""
)

$ErrorActionPreference = "Stop"

function Find-CodiumExe {
    if ($Cli -and (Test-Path -LiteralPath $Cli)) { return $Cli }
    foreach ($name in @("codium", "vscodium")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    $paths = @(
        "$env:LOCALAPPDATA\Programs\VSCodium\VSCodium.exe",
        "${env:ProgramFiles}\VSCodium\VSCodium.exe",
        "${env:ProgramFiles(x86)}\VSCodium\VSCodium.exe"
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    throw "Не найден VSCodium. Укажите путь через -Cli или добавьте в PATH."
}

$exe = Find-CodiumExe
$lines = & $exe --list-extensions --show-versions 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "CLI завершился с кодом $LASTEXITCODE`: $exe --list-extensions --show-versions"
}
$lines | Set-Content -LiteralPath $OutFile -Encoding utf8
Write-Host "Записано $($lines.Count) строк в $OutFile"
