:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.


@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Requesting administrator rights...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "scriptPath=%~dp0win_install_deps.ps1"

echo [INFO] Running installation script...
powershell -NoProfile -ExecutionPolicy Bypass -File "%scriptPath%"

pause
