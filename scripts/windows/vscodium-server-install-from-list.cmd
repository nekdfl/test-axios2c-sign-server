@echo off
REM Скачивание и установка расширений vscodium-server по списку (см. scripts\vscodium_install_extensions_from_list.py).
REM Пример из корня репозитория:
REM   scripts\windows\vscodium-server-install-from-list.cmd scripts\windows\vscodium-extensions.txt
REM С Open VSX (скачать .vsix, затем установить):
REM   scripts\windows\vscodium-server-install-from-list.cmd --openvsx scripts\windows\vscodium-extensions.txt
REM Десктопный VSCodium по списку — отдельный сценарий vscodium-desktop-install-from-list.cmd
call "%~dp0_invoke_python.cmd" vscodium_install_extensions_from_list.py %*
