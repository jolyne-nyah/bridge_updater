:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.

@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] Running as Administrator is not allowed!
    echo Please run this script as a normal user.
    pause
    exit /b
)

echo [VAGRANT] Stopping the virtual machine...
vagrant halt
echo.
echo [STATUS] Current status:
vagrant status
timeout /t 5
