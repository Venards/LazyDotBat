@echo off
net session >nul 2>&1
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

echo %CYAN%=== Windows Junk Disabler ===%RESET%
echo.
echo %YELLOW%  [1] Disable - Turn off bloatware temporarily%RESET%
echo %YELLOW%  [2] Restore - Turn everything back on%RESET%
echo.
set /p choice="%YELLOW%Choice (1/2): %RESET%"
echo.

if "%choice%"=="2" goto restore

:: ── DISABLE ──────────────────────────────────────────────────────────────────
:disable

echo %CYAN%[*] Stopping telemetry...%RESET%
net stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul
net stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Stopping Xbox services...%RESET%
net stop XblAuthManager >nul 2>&1
sc config XblAuthManager start= disabled >nul
net stop XblGameSave >nul 2>&1
sc config XblGameSave start= disabled >nul
net stop XboxNetApiSvc >nul 2>&1
sc config XboxNetApiSvc start= disabled >nul
net stop XboxGipSvc >nul 2>&1
sc config XboxGipSvc start= disabled >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Stopping tips and feedback...%RESET%
net stop PcaSvc >nul 2>&1
sc config PcaSvc start= disabled >nul
net stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Disabling telemetry in registry...%RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Killing junk processes...%RESET%
taskkill /f /im SkypeApp.exe >nul 2>&1
taskkill /f /im YourPhone.exe >nul 2>&1
taskkill /f /im Widgets.exe >nul 2>&1
taskkill /f /im WinStore.App.exe >nul 2>&1
echo %GREEN%    Done.%RESET%

echo.
echo %GREEN%[+] Windows junk disabled. Run again and choose Restore to undo.%RESET%
pause
exit /b

:: ── RESTORE ──────────────────────────────────────────────────────────────────
:restore

echo %CYAN%[*] Restoring telemetry services...%RESET%
sc config DiagTrack start= auto >nul & net start DiagTrack >nul 2>&1
sc config dmwappushservice start= auto >nul & net start dmwappushservice >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Restoring Xbox services...%RESET%
sc config XblAuthManager start= auto >nul & net start XblAuthManager >nul 2>&1
sc config XblGameSave start= auto >nul & net start XblGameSave >nul 2>&1
sc config XboxNetApiSvc start= auto >nul & net start XboxNetApiSvc >nul 2>&1
sc config XboxGipSvc start= auto >nul & net start XboxGipSvc >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Restoring tips and feedback services...%RESET%
sc config PcaSvc start= auto >nul & net start PcaSvc >nul 2>&1
sc config WerSvc start= auto >nul & net start WerSvc >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Restoring registry...%RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 1 /f >nul
echo %GREEN%    Done.%RESET%

echo.
echo %GREEN%[+] Everything restored.%RESET%
pause
