@echo off
REM Экспорт списка расширений десктопного VSCodium (см. vscodium_desktop_export_extensions.py).
REM Пример: scripts\windows\export-extensions.cmd vscodium-extensions.txt
call "%~dp0_invoke_python.cmd" vscodium_desktop_export_extensions.py %*
