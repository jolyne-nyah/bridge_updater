:: Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
:: This program comes with ABSOLUTELY NO WARRANTY.
:: See <https://gnu.org> for details.

@echo off
cd /d "%~dp0.."
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] Running as Administrator is not allowed!
    echo Please run this script as a normal user.
    pause
    exit /b
)

:menu
cls
echo ===============================
echo   TORPROXY MANAGEMENT MENU
echo ===============================
echo 1. UP (Start)
echo 2. HALT (Stop)
echo 3. DESTROY (Delete)
echo 4. STATUS
echo 5. SSH (Enter)
echo 6. EXIT
echo ===============================
set /p choice="Enter your choice (1-5): "

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
if "%choice%"=="5" (
    vagrant ssh
    pause
    goto menu
)
if "%choice%"=="6" exit
goto menu
