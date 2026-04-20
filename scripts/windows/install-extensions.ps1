<#
  Установка всех .vsix из каталога в VSCodium (офлайн).
  Запуск: .\install-extensions.ps1 [-VsixDir vsix] [-Cli path]
#>
param(
    [string] $VsixDir = "vsix",
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
    throw "Не найден VSCodium. Укажите путь через -Cli."
}

if (-not (Test-Path -LiteralPath $VsixDir)) {
    throw "Каталог не найден: $VsixDir"
}

$exe = Find-CodiumExe
Get-ChildItem -LiteralPath $VsixDir -Filter "*.vsix" -File | ForEach-Object {
    Write-Host "Установка:" $_.FullName
    & $exe --install-extension $_.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Код $LASTEXITCODE для $($_.Name)"
    }
}
Write-Host "Готово."
