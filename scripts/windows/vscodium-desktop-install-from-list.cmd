@echo off
REM Установка расширений десктопного VSCodium по списку (см. scripts\vscodium_install_extensions_from_list.py --desktop).
REM Пример из корня репозитория:
REM   scripts\windows\vscodium-desktop-install-from-list.cmd scripts\windows\vscodium-extensions.txt
REM С Open VSX (скачать .vsix, затем установить):
REM   scripts\windows\vscodium-desktop-install-from-list.cmd --openvsx scripts\windows\vscodium-extensions.txt
call "%~dp0_invoke_python.cmd" vscodium_install_extensions_from_list.py --desktop %*
