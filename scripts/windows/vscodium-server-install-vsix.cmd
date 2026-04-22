@echo off
REM Установка VSIX в vscodium-server (см. vscodium_server_install_vsix.py).
call "%~dp0_invoke_python.cmd" vscodium_server_install_vsix.py %*
