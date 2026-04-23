@echo off
REM Последний релиз VSCodium для Windows: zip + Setup + UserSetup (см. vscodium_desktop_download.py).
REM Пример: scripts\windows\vscodium-desktop-download.cmd --arch x64 --outdir .
call "%~dp0_invoke_python.cmd" vscodium_desktop_download.py %*
