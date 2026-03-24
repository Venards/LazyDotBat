@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\open_ports.ps1"
pause
