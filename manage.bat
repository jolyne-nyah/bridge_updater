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
    set "m_title=VAGRANT MANAGEMENT MENU"
    set "m_prompt=Enter your choice (1-5): "
    set "m_err_admin=[!] ERROR: Run AS ADMINISTRATOR to manage Vagrant/Symlinks."
) else if "%lang_choice%"=="2" (
    chcp 65001 >nul
    set "m_title=МЕНЮ УПРАВЛЕНИЯ VAGRANT"
    set "m_prompt=Выберите пункт (1-5): "
    set "m_err_admin=[!] ОШИБКА: Запустите от имени АДМИНИСТРАТОРА для работы с Vagrant и ссылками."
) else (
    goto lang_select
)

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo %m_err_admin%
    pause
    exit /b
)

:menu
cls
echo ===============================
echo   %m_title%
echo ===============================
echo 1. UP (Start)
echo 2. HALT (Stop)
echo 3. DESTROY (Delete)
echo 4. STATUS
echo 5. EXIT
echo ===============================
set /p choice="%m_prompt%"

if "%choice%"=="1" (
    vagrant up
    pause
    goto menu
)
if "%choice%"=="2" (
    vagrant halt
    goto menu
)
if "%choice%"=="3" (
    vagrant destroy -f
    pause
    goto menu
)
if "%choice%"=="4" (
    vagrant status
    pause
    goto menu
)
if "%choice%"=="5" exit
goto menu
