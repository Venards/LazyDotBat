@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

:: ── Colors ──
for /f %%a in ('echo prompt $E ^| cmd') do set ESC=%%a
set GREEN=%ESC%[32m
set RED=%ESC%[31m
set YELLOW=%ESC%[33m
set CYAN=%ESC%[36m
set RESET=%ESC%[0m

echo %CYAN%=== Audio Restart ===%RESET%
echo.

echo %CYAN%[*] Killing audio processes...%RESET%
taskkill /f /im audiodg.exe >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Restarting audio services...%RESET%
net stop AudioEndpointBuilder /y >nul 2>&1
net stop Audiosrv /y >nul 2>&1
timeout /t 2 /nobreak >nul
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
echo %GREEN%    Done.%RESET%

echo.
echo %GREEN%[+] Audio restarted. Test your sound now.%RESET%
pause
