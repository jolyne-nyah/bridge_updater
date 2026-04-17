REM Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
REM This program comes with ABSOLUTELY NO WARRANTY.
REM See <https://gnu.org> for details.

@echo off
echo [VAGRANT] Starting the virtual machine...
vagrant up
echo.
echo [STATUS] Current status:
vagrant status
pause
