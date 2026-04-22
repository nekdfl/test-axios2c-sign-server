@echo off
REM Скачать VSIX с Open VSX (обёртка над openvsx_download_vsix.py).
REM Без аргументов: список scripts\linux\vscodium-extensions.txt и каталог scripts\linux\vsix\
REM Примеры:
REM   scripts\linux\download-extensions.cmd
REM   scripts\linux\download-extensions.cmd my-list.txt D:\vsix-out
set "HERE=%~dp0"
if "%~1"=="" goto :defaults
if "%~2"=="" goto :onelist
goto :both

:defaults
call "%HERE%_invoke_python.cmd" openvsx_download_vsix.py "%HERE%vscodium-extensions.txt" "%HERE%vsix"
exit /b %ERRORLEVEL%

:onelist
call "%HERE%_invoke_python.cmd" openvsx_download_vsix.py "%~1" "%HERE%vsix"
exit /b %ERRORLEVEL%

:both
call "%HERE%_invoke_python.cmd" openvsx_download_vsix.py "%~1" "%~2"
exit /b %ERRORLEVEL%
