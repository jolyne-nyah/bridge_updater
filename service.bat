REM Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
REM This program comes with ABSOLUTELY NO WARRANTY.
REM See <https://gnu.org> for details.

@echo off
setlocal enabledelayedexpansion

:lang_select
cls
echo Choose language / Выберите язык:
echo 1. English
echo 2. Russian
set /p lang_choice="> "

if "%lang_choice%"=="1" (
    set "m_title=VAGRANT SERVICE MANAGER"
    set "m_opt1=Set up hidden autostart (20s delay)"
    set "m_opt2=Remove task"
    set "m_opt3=Vagrant status"
    set "m_opt4=Exit"
    set "m_prompt=Choice (1-4): "
    set "m_err_admin=[!] ERROR: Run AS ADMINISTRATOR."
    set "m_info_setup=[INFO] Setting up task with 20s delay..."
    set "m_ok_created=[OK] Task created. 20s delay is active."
    set "m_err_failed=[!] Failed to create task."
    set "m_ok_removed=[OK] Task removed."
) else if "%lang_choice%"=="2" (
    chcp 65001 >nul
    set "m_title=VAGRANT SERVICE MANAGER"
    set "m_opt1=Настроить скрытый автозапуск (задержка 20с)"
    set "m_opt2=Удалить задачу"
    set "m_opt3=Статус Vagrant"
    set "m_opt4=Выход"
    set "m_prompt=Выберите пункт (1-4): "
    set "m_err_admin=[!] ОШИБКА: Запустите от имени АДМИНИСТРАТОРА."
    set "m_info_setup=[ИНФО] Настройка задачи с задержкой 20с..."
    set "m_ok_created=[OK] Задача создана. Задержка 20с активна."
    set "m_err_failed=[!] Не удалось создать задачу."
    set "m_ok_removed=[OK] Задача удалена."
) else (
    goto lang_select
)

set "TASK_NAME=VagrantHiddenStart"
set "VAGRANT_DIR=%~dp0"
set "UP_BAT=%VAGRANT_DIR%up.bat"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %m_err_admin%
    pause & exit /b
)

:menu
cls
echo ==================================================
echo       %m_title%
echo ==================================================
echo  1. %m_opt1%
echo  2. %m_opt2%
echo  3. %m_opt3%
echo  4. %m_opt4%
echo ==================================================
set /p choice="%m_prompt%"

if "%choice%"=="1" goto install
if "%choice%"=="2" goto remove
if "%choice%"=="3" goto status
if "%choice%"=="4" exit
goto menu

:install
echo.
echo %m_info_setup%

set "RUN_CMD=cmd.exe /c timeout /t 20 /nobreak >nul && \"!UP_BAT!\""

powershell -NoProfile -Command "$action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c !RUN_CMD!'; $trigger = New-ScheduledTaskTrigger -AtLogon; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; Register-ScheduledTask -TaskName '!TASK_NAME!' -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force" >nul 2>&1

if %errorlevel% equ 0 (
    echo %m_ok_created%
) else (
    echo %m_err_failed%
)
pause
goto menu

:remove
echo.
schtasks /delete /tn %TASK_NAME% /f >nul 2>&1
echo %m_ok_removed%
pause
goto menu

:status
echo.
cd /d "%VAGRANT_DIR%"
vagrant status
pause
goto menu
