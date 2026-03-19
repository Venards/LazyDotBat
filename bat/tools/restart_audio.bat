@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

echo === Audio Restart ===
echo.

echo [*] Killing audio processes...
taskkill /f /im audiodg.exe >nul 2>&1
echo     Done.

echo [*] Restarting audio services...
net stop AudioEndpointBuilder /y >nul 2>&1
net stop Audiosrv /y >nul 2>&1
timeout /t 2 /nobreak >nul
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
echo     Done.

echo.
echo [+] Audio restarted. Test your sound now.
pause
