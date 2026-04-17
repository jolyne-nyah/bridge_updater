REM Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
REM This program comes with ABSOLUTELY NO WARRANTY.
REM See <https://gnu.org> for details.

@echo off
echo [VAGRANT] Destroying the virtual machine... 
vagrant destroy -f
echo.
echo [STATUS] Current status:
vagrant status
pause
