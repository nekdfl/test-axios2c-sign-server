@echo off
REM Офлайн-установка всех .vsix из каталога (см. vscodium_desktop_install_vsix.py).
REM Пример: scripts\windows\install-extensions.cmd vsix
call "%~dp0_invoke_python.cmd" vscodium_desktop_install_vsix.py %*
