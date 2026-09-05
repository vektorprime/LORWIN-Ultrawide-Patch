@echo off
REM Double-click patcher, no Python needed. Close the game first.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0LORWIN_ultrawide_patch.ps1"
echo.
pause
