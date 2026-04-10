@echo off
:: WinClean Pro v4.0 - One-Click Launcher
:: Automatically elevates to Admin and bypasses execution policy

:: Check if already running as Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Unblock the script file (clears "downloaded from internet" flag)
powershell -Command "Unblock-File -Path '%~dp0winclean.v4.ps1' -ErrorAction SilentlyContinue"

:: Launch the GUI app
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0winclean.v4.ps1"
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Script failed with exit code: %errorLevel%
    pause
)
