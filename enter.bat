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

title Vagrant SSH Terminal
echo [VAGRANT] Connecting to the machine...
echo.
vagrant ssh
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Could not connect to Vagrant. 
    echo Check if the machine is running using status.bat
    pause
)

