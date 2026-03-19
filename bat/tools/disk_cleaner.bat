@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)
echo === Cleanup Script ===
echo.

:: ── Get free space before ────────────────────────────────────────────────────
call :getfreespace before

:: ── 1. Auto-clean junk files ─────────────────────────────────────────────────
echo [*] Removing junk files (*.tmp, *.log, Thumbs.db, desktop.ini)...
del /f /s /q "%USERPROFILE%\*.tmp" >nul 2>&1
del /f /s /q "%USERPROFILE%\*.log" >nul 2>&1
del /f /s /q "%USERPROFILE%\Thumbs.db" >nul 2>&1
del /f /s /q "%USERPROFILE%\desktop.ini" >nul 2>&1
echo     Done.
echo.

:: ── 2. Collect y/n answers (skip if app not installed) ───────────────────────
set /p c_dl="[?] Clean Downloads folder? (y/n): "

set /p c_rb="[?] Clean Recycle Bin? (y/n): "

set c_br=n
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"         set _hasbrowser=1
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"        set _hasbrowser=1
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" set _hasbrowser=1
if exist "%APPDATA%\Opera Software\Opera Stable\Cache"                  set _hasbrowser=1
if exist "%APPDATA%\Opera Software\Opera GX Stable\Cache"               set _hasbrowser=1
if exist "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache"               set _hasbrowser=1
if defined _hasbrowser set /p c_br="[?] Clean browser cache (Chrome, Edge, Firefox, Brave, Opera, Opera GX, Vivaldi, Tor)? (y/n): "

set /p c_tmp="[?] Clean Windows Temp folders? (y/n): "

set /p c_wu="[?] Clean Windows Update cache? (y/n): "

set /p c_pf="[?] Clean Prefetch files? (y/n): "

set c_app=n
if exist "%APPDATA%\discord\Cache"          set _hasapp=1
if exist "%LOCALAPPDATA%\Spotify\Data"      set _hasapp=1
if exist "%LOCALAPPDATA%\Steam\shadercache" set _hasapp=1
if defined _hasapp set /p c_app="[?] Clean app caches (Discord, Spotify, Steam)? (y/n): "

echo.

:: ── 3. Execute ───────────────────────────────────────────────────────────────

if /i "%c_dl%"=="y" (
    rd /s /q "%USERPROFILE%\Downloads" 2>nul & mkdir "%USERPROFILE%\Downloads"
    echo [+] Downloads cleared.
)

if /i "%c_rb%"=="y" (
    powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
    echo [+] Recycle Bin cleared.
)

if /i "%c_br%"=="y" (
    call :clearcache "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
    call :clearcache "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
    call :clearcache "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache"
    call :clearcache "%APPDATA%\Opera Software\Opera Stable\Cache"
    call :clearcache "%APPDATA%\Opera Software\Opera GX Stable\Cache"
    call :clearcache "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache"
    call :clearcache "%LOCALAPPDATA%\Tor Browser\Browser\TorBrowser\Data\Browser\profile.default\cache2"
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do call :clearcache "%%p\cache2"
    echo [+] Browser caches cleared.
)

if /i "%c_tmp%"=="y" (
    rd /s /q "%TEMP%" 2>nul & mkdir "%TEMP%"
    rd /s /q "C:\Windows\Temp" 2>nul & mkdir "C:\Windows\Temp"
    echo [+] Temp folders cleared.
)

if /i "%c_wu%"=="y" (
    net stop wuauserv >nul 2>&1
    rd /s /q "C:\Windows\SoftwareDistribution\Download" 2>nul
    mkdir "C:\Windows\SoftwareDistribution\Download"
    net start wuauserv >nul 2>&1
    echo [+] Windows Update cache cleared.
)

if /i "%c_pf%"=="y" (
    del /f /s /q "C:\Windows\Prefetch\*" >nul 2>&1
    echo [+] Prefetch cleared.
)

if /i "%c_app%"=="y" (
    call :clearcache "%APPDATA%\discord\Cache"
    call :clearcache "%APPDATA%\discord\Code Cache"
    call :clearcache "%LOCALAPPDATA%\Spotify\Data"
    call :clearcache "%LOCALAPPDATA%\Steam\htmlcache"
    call :clearcache "%LOCALAPPDATA%\Steam\shadercache"
    echo [+] App caches cleared.
)

:: ── Show space freed ─────────────────────────────────────────────────────────
call :getfreespace after
set /a freed=after-before
echo.
if %freed% gtr 0 (
    echo [*] Disk space freed: %freed% MB
) else (
    echo [*] Disk space freed: 0 MB
)

echo === All done ===
pause
exit /b

:: ── Helpers ──────────────────────────────────────────────────────────────────
:getfreespace
for /f "tokens=3" %%a in ('powershell -NoProfile -Command "(Get-PSDrive C).Free / 1MB -as [int]"') do set %1=%%a
exit /b

:clearcache
if exist "%~1" (
    rd /s /q "%~1" 2>nul
    mkdir "%~1" 2>nul
)
exit /b
