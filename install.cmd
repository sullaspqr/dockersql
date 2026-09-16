@echo off
title PHP fejlesztoi kornyezet telepitese

net session >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo Rendszergazdai jogosultsag szukseges.
    echo UAC ablak fog megjelenni.
    echo.
    powershell.exe -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

pause