@echo off
REM Скачивание и установка расширений vscodium-server по списку (Python; см. scripts\vscodium_install_extensions_from_list.py).
call "%~dp0_invoke_python.cmd" vscodium_install_extensions_from_list.py %*
