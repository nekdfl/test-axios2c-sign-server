@echo off
REM Скачать архив vscodium-server для Linux в scripts\linux (OUTDIR по умолчанию — этот каталог).
REM Запуск из cmd.exe на машине с интернетом. Пример:
REM   scripts\linux\vscodium-server-download.cmd --arch x64 --flavor reh
REM См. также: set OUTDIR=D:\dist (если уже задано, не перезаписывается).
if not defined OUTDIR set "OUTDIR=%~dp0"
call "%~dp0_invoke_python.cmd" vscodium_server_download.py %*
