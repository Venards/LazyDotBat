@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

echo === Game Boost ===
echo.
echo   [1] Boost  - Optimize for gaming
echo   [2] Restore - Undo all changes
echo.
set /p choice="Choice (1/2): "
echo.

if "%choice%"=="2" goto restore

:: ── BOOST ────────────────────────────────────────────────────────────────────
:boost

:: Save current power plan so we can restore it later
powershell -NoProfile -Command "(powercfg /getactivescheme) -match '[0-9a-f-]{36}'" >nul
for /f "tokens=4" %%a in ('powercfg /getactivescheme') do set oldplan=%%a
echo %oldplan% > "%TEMP%\gameboost_oldplan.txt"

echo [*] Setting power plan to High Performance...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul
echo     Done.

echo [*] Killing background processes...
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im SearchIndexer.exe >nul 2>&1
taskkill /f /im SearchApp.exe >nul 2>&1
taskkill /f /im WidgetService.exe >nul 2>&1
taskkill /f /im Widgets.exe >nul 2>&1
taskkill /f /im YourPhone.exe >nul 2>&1
taskkill /f /im WinStore.App.exe >nul 2>&1
echo     Done.

echo [*] Disabling Xbox Game Bar...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
echo     Done.

echo [*] Setting GPU to prefer maximum performance...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
echo     Done.

echo [*] Disabling unnecessary services temporarily...
sc config "SysMain" start= disabled >nul & net stop SysMain >nul 2>&1
sc config "DiagTrack" start= disabled >nul & net stop DiagTrack >nul 2>&1
echo     Done.

echo.
echo [+] Boost applied. Happy gaming!
echo     Run this script again and choose Restore when done.
pause
exit /b

:: ── RESTORE ──────────────────────────────────────────────────────────────────
:restore

echo [*] Restoring power plan...
if exist "%TEMP%\gameboost_oldplan.txt" (
    set /p oldplan=<"%TEMP%\gameboost_oldplan.txt"
    powercfg /setactive %oldplan% >nul
    del "%TEMP%\gameboost_oldplan.txt"
) else (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul
)
echo     Done.

echo [*] Re-enabling Xbox Game Bar...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul
echo     Done.

echo [*] Restoring GPU setting...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul 2>&1
echo     Done.

echo [*] Re-enabling services...
sc config "SysMain" start= auto >nul & net start SysMain >nul 2>&1
sc config "DiagTrack" start= auto >nul & net start DiagTrack >nul 2>&1
echo     Done.

echo.
echo [+] Everything restored.
pause
