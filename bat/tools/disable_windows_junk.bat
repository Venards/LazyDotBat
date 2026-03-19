@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

echo === Windows Junk Disabler ===
echo.
echo   [1] Disable - Turn off bloatware temporarily
echo   [2] Restore - Turn everything back on
echo.
set /p choice="Choice (1/2): "
echo.

if "%choice%"=="2" goto restore

:: ── DISABLE ──────────────────────────────────────────────────────────────────
:disable

echo [*] Stopping telemetry...
net stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul
net stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul
echo     Done.

echo [*] Stopping Xbox services...
net stop XblAuthManager >nul 2>&1
sc config XblAuthManager start= disabled >nul
net stop XblGameSave >nul 2>&1
sc config XblGameSave start= disabled >nul
net stop XboxNetApiSvc >nul 2>&1
sc config XboxNetApiSvc start= disabled >nul
net stop XboxGipSvc >nul 2>&1
sc config XboxGipSvc start= disabled >nul
echo     Done.

echo [*] Stopping tips and feedback...
net stop PcaSvc >nul 2>&1
sc config PcaSvc start= disabled >nul
net stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul
echo     Done.

echo [*] Disabling telemetry in registry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul
echo     Done.

echo [*] Killing junk processes...
taskkill /f /im SkypeApp.exe >nul 2>&1
taskkill /f /im YourPhone.exe >nul 2>&1
taskkill /f /im Widgets.exe >nul 2>&1
taskkill /f /im WinStore.App.exe >nul 2>&1
echo     Done.

echo.
echo [+] Windows junk disabled. Run again and choose Restore to undo.
pause
exit /b

:: ── RESTORE ──────────────────────────────────────────────────────────────────
:restore

echo [*] Restoring telemetry services...
sc config DiagTrack start= auto >nul & net start DiagTrack >nul 2>&1
sc config dmwappushservice start= auto >nul & net start dmwappushservice >nul 2>&1
echo     Done.

echo [*] Restoring Xbox services...
sc config XblAuthManager start= auto >nul & net start XblAuthManager >nul 2>&1
sc config XblGameSave start= auto >nul & net start XblGameSave >nul 2>&1
sc config XboxNetApiSvc start= auto >nul & net start XboxNetApiSvc >nul 2>&1
sc config XboxGipSvc start= auto >nul & net start XboxGipSvc >nul 2>&1
echo     Done.

echo [*] Restoring tips and feedback services...
sc config PcaSvc start= auto >nul & net start PcaSvc >nul 2>&1
sc config WerSvc start= auto >nul & net start WerSvc >nul 2>&1
echo     Done.

echo [*] Restoring registry...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 1 /f >nul
echo     Done.

echo.
echo [+] Everything restored.
pause
