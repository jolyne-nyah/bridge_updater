:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.

@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b
)

set "TASK_NAME=VagrantHiddenStart"
set "UP_BAT=%~dp0up.bat"

:menu
cls
echo ==================================================
echo       VAGRANT SERVICE MANAGER (OLD SCHOOL)
echo ==================================================
echo  1. Set up autostart (5s delay, Limited User)
echo  2. Remove task
echo  3. Exit
echo ==================================================
set /p choice="Choice (1-3): "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto remove
if "%choice%"=="3" exit
goto menu

:install
echo.
echo [INFO] Setting up task...

set "RUN_CMD=cmd.exe /c timeout /t 5 /nobreak >nul && \"!UP_BAT!\""

powershell -NoProfile -ExecutionPolicy Bypass -Command "$action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c !RUN_CMD!'; $trigger = New-ScheduledTaskTrigger -AtLogon; $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; Register-ScheduledTask -TaskName '!TASK_NAME!' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force"

if %errorlevel% equ 0 (
    echo [OK] Task created. It will show a black window for 5s on login.
) else (
    echo [!] Failed.
)
pause
goto menu

:remove
echo.
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
echo [OK] Task removed.
pause
goto menu
