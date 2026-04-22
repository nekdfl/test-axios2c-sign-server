@echo off
REM Скачивание VSIX с Open VSX по списку (см. scripts/openvsx_download_vsix.py).
REM Пример из корня репозитория:
REM   scripts\windows\download-extensions.cmd scripts\windows\vscodium-extensions.txt vsix
call "%~dp0_invoke_python.cmd" openvsx_download_vsix.py %*
