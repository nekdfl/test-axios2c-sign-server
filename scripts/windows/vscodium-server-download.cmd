@echo off
REM Скачивание архива vscodium-server для Linux (удобно вызывать из Git Bash / WSL с тем же репо).
REM Пример: scripts\windows\vscodium-server-download.cmd --arch x64 --flavor reh --outdir .
setlocal enableextensions

REM Добавляем git-id (короткий hash HEAD) в имя скачанного файла.
set "ROOT=%~dp0..\.."
set "GIT_ID=nogit"
for /f "usebackq delims=" %%i in (`git -C "%ROOT%" rev-parse --short HEAD 2^>NUL`) do set "GIT_ID=%%i"

set "DEMO_SIGN_GIT_ID=%GIT_ID%"
call "%~dp0_invoke_python.cmd" vscodium_server_download.py %*
