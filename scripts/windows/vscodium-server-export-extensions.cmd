@echo off
REM Экспорт расширений vscodium-server (см. vscodium_server_export_extensions.py).
call "%~dp0_invoke_python.cmd" vscodium_server_export_extensions.py %*
