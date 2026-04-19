:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.

@echo off
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] Running as Administrator is not allowed!
    echo Please run this script as a normal user.
    pause
    exit /b
)

echo [VAGRANT] Starting the virtual machine...
vagrant up
echo.
echo [STATUS] Current status:
vagrant status
pause
