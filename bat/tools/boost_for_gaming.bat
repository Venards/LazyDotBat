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

echo %CYAN%=== Game Boost ===%RESET%
echo.
echo %YELLOW%  [1] Boost  - Optimize for gaming%RESET%
echo %YELLOW%  [2] Restore - Undo all changes%RESET%
echo.
set /p choice="%YELLOW%Choice (1/2): %RESET%"
echo.

if "%choice%"=="2" goto restore

:: ── BOOST ────────────────────────────────────────────────────────────────────
:boost

:: Save current power plan so we can restore it later
powershell -NoProfile -Command "(powercfg /getactivescheme) -match '[0-9a-f-]{36}'" >nul
for /f "tokens=4" %%a in ('powercfg /getactivescheme') do set oldplan=%%a
echo %oldplan% > "%TEMP%\gameboost_oldplan.txt"

echo %CYAN%[*] Setting power plan to High Performance...%RESET%
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Killing background processes...%RESET%
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im SearchIndexer.exe >nul 2>&1
taskkill /f /im SearchApp.exe >nul 2>&1
taskkill /f /im WidgetService.exe >nul 2>&1
taskkill /f /im Widgets.exe >nul 2>&1
taskkill /f /im YourPhone.exe >nul 2>&1
taskkill /f /im WinStore.App.exe >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Disabling Xbox Game Bar...%RESET%
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Setting GPU to prefer maximum performance...%RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Disabling unnecessary services temporarily...%RESET%
sc config "SysMain" start= disabled >nul & net stop SysMain >nul 2>&1
sc config "DiagTrack" start= disabled >nul & net stop DiagTrack >nul 2>&1
echo %GREEN%    Done.%RESET%

echo.
echo %GREEN%[+] Boost applied. Happy gaming!%RESET%
echo %CYAN%    Run this script again and choose Restore when done.%RESET%
pause
exit /b

:: ── RESTORE ──────────────────────────────────────────────────────────────────
:restore

echo %CYAN%[*] Restoring power plan...%RESET%
if exist "%TEMP%\gameboost_oldplan.txt" (
    set /p oldplan=<"%TEMP%\gameboost_oldplan.txt"
    powercfg /setactive %oldplan% >nul
    del "%TEMP%\gameboost_oldplan.txt"
) else (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul
)
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Re-enabling Xbox Game Bar...%RESET%
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Restoring GPU setting...%RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul 2>&1
echo %GREEN%    Done.%RESET%

echo %CYAN%[*] Re-enabling services...%RESET%
sc config "SysMain" start= auto >nul & net start SysMain >nul 2>&1
sc config "DiagTrack" start= auto >nul & net start DiagTrack >nul 2>&1
echo %GREEN%    Done.%RESET%

echo.
echo %GREEN%[+] Everything restored.%RESET%
pause
