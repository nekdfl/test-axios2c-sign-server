@echo off
REM Скачивание архива vscodium-server для Linux (удобно вызывать из Git Bash / WSL с тем же репо).
REM Пример: scripts\windows\vscodium-server-download.cmd --arch x64 --flavor reh --outdir .
call "%~dp0_invoke_python.cmd" vscodium_server_download.py %*
