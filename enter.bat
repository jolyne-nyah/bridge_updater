REM Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
REM This program comes with ABSOLUTELY NO WARRANTY.
REM See <https://gnu.org> for details.

@echo off
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

