@echo off
setlocal
cd /d "%~dp0..\.."
where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python -u "%~dp0web.py" %*
  exit /b %ERRORLEVEL%
)
py -3 -u "%~dp0web.py" %*
exit /b %ERRORLEVEL%
