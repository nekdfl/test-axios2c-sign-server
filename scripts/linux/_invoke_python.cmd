@echo off
setlocal EnableDelayedExpansion
REM Runs Python script from scripts\ (parent of scripts\linux).
REM Save %%~dp0 before SHIFT: after SHIFT, %%0 is the first arg, so %%~dp0 is wrong.
REM Do not use %%* after SHIFT — in cmd.exe it still lists all original args including the script name.

set "WINSCR=%~dp0"
set "PYFILE=%~1"
if "%PYFILE%"=="" (
  echo Usage: _invoke_python.cmd script.py [args...] 1>&2
  exit /b 1
)
shift

set "ARGS="
:collectargs
if "%~1"=="" goto :haveargs
set "ARGS=!ARGS! "%~1""
shift
goto :collectargs

:haveargs
pushd "%WINSCR%" >nul 2>&1
cd ..
set "FULL=!CD!\%PYFILE%"
popd >nul 2>&1

if not exist "!FULL!" (
  echo Script not found: !FULL! 1>&2
  exit /b 1
)

where py >nul 2>&1
if not errorlevel 1 (
  py -3 "!FULL!" !ARGS!
  exit /b !errorlevel!
)
where python >nul 2>&1
if not errorlevel 1 (
  python "!FULL!" !ARGS!
  exit /b !errorlevel!
)

echo Python 3 not found ^(install Python or add py launcher to PATH^). 1>&2
exit /b 1
