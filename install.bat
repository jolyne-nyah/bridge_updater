:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.


@echo off
set "scriptPath=%~dp0win_install_deps.ps1"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script MUST be run as Administrator!
    pause
    exit /b
)

echo [INFO] Running installation script...
powershell -NoProfile -ExecutionPolicy Bypass -File "%scriptPath%"

pause
