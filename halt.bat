REM Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
REM This program comes with ABSOLUTELY NO WARRANTY.
REM See <https://gnu.org> for details.

@echo off
echo [VAGRANT] Stopping the virtual machine...
vagrant halt
echo.
echo [STATUS] Current status:
vagrant status
timeout /t 5
