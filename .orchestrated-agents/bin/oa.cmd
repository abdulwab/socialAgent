@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0oa.ps1" %*
exit /b %ERRORLEVEL%
