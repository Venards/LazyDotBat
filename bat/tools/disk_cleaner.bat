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

echo %CYAN%=== Cleanup Script ===%RESET%
echo.

:: ── Get free space before ────────────────────────────────────────────────────
call :getfreespace before

:: ── 1. Auto-clean junk files ─────────────────────────────────────────────────
echo %CYAN%[*] Removing junk files (*.tmp, *.log, Thumbs.db, desktop.ini)...%RESET%
del /f /s /q "%USERPROFILE%\*.tmp" >nul 2>&1
del /f /s /q "%USERPROFILE%\*.log" >nul 2>&1
del /f /s /q "%USERPROFILE%\Thumbs.db" >nul 2>&1
del /f /s /q "%USERPROFILE%\desktop.ini" >nul 2>&1
echo %GREEN%    Done.%RESET%
echo.

:: ── 2. Collect y/n answers (skip if app not installed) ───────────────────────
set /p c_dl="%YELLOW%[?] Clean Downloads folder? (y/n): %RESET%"

set /p c_rb="%YELLOW%[?] Clean Recycle Bin? (y/n): %RESET%"

set c_br=n
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"         set _hasbrowser=1
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"        set _hasbrowser=1
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" set _hasbrowser=1
if exist "%APPDATA%\Opera Software\Opera Stable\Cache"                  set _hasbrowser=1
if exist "%APPDATA%\Opera Software\Opera GX Stable\Cache"               set _hasbrowser=1
if exist "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache"               set _hasbrowser=1
if defined _hasbrowser set /p c_br="%YELLOW%[?] Clean browser cache (Chrome, Edge, Firefox, Brave, Opera, Opera GX, Vivaldi, Tor)? (y/n): %RESET%"

set /p c_tmp="%YELLOW%[?] Clean Windows Temp folders? (y/n): %RESET%"

set /p c_wu="%YELLOW%[?] Clean Windows Update cache? (y/n): %RESET%"

set /p c_pf="%YELLOW%[?] Clean Prefetch files? (y/n): %RESET%"

set c_app=n
if exist "%APPDATA%\discord\Cache"          set _hasapp=1
if exist "%LOCALAPPDATA%\Spotify\Data"      set _hasapp=1
if exist "%LOCALAPPDATA%\Steam\shadercache" set _hasapp=1
if defined _hasapp set /p c_app="%YELLOW%[?] Clean app caches (Discord, Spotify, Steam)? (y/n): %RESET%"

echo.

:: ── 3. Execute ───────────────────────────────────────────────────────────────

if /i "%c_dl%"=="y" (
    rd /s /q "%USERPROFILE%\Downloads" 2>nul & mkdir "%USERPROFILE%\Downloads"
    echo %GREEN%[+] Downloads cleared.%RESET%
)

if /i "%c_rb%"=="y" (
    powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
    echo %GREEN%[+] Recycle Bin cleared.%RESET%
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
    echo %GREEN%[+] Browser caches cleared.%RESET%
)

if /i "%c_tmp%"=="y" (
    rd /s /q "%TEMP%" 2>nul & mkdir "%TEMP%"
    rd /s /q "C:\Windows\Temp" 2>nul & mkdir "C:\Windows\Temp"
    echo %GREEN%[+] Temp folders cleared.%RESET%
)

if /i "%c_wu%"=="y" (
    net stop wuauserv >nul 2>&1
    rd /s /q "C:\Windows\SoftwareDistribution\Download" 2>nul
    mkdir "C:\Windows\SoftwareDistribution\Download"
    net start wuauserv >nul 2>&1
    echo %GREEN%[+] Windows Update cache cleared.%RESET%
)

if /i "%c_pf%"=="y" (
    del /f /s /q "C:\Windows\Prefetch\*" >nul 2>&1
    echo %GREEN%[+] Prefetch cleared.%RESET%
)

if /i "%c_app%"=="y" (
    call :clearcache "%APPDATA%\discord\Cache"
    call :clearcache "%APPDATA%\discord\Code Cache"
    call :clearcache "%LOCALAPPDATA%\Spotify\Data"
    call :clearcache "%LOCALAPPDATA%\Steam\htmlcache"
    call :clearcache "%LOCALAPPDATA%\Steam\shadercache"
    echo %GREEN%[+] App caches cleared.%RESET%
)

:: ── Show space freed ─────────────────────────────────────────────────────────
call :getfreespace after
set /a freed=after-before
echo.
if %freed% gtr 0 (
    echo %CYAN%[*] Disk space freed: %freed% MB%RESET%
) else (
    echo %CYAN%[*] Disk space freed: 0 MB%RESET%
)

echo %CYAN%=== All done ===%RESET%
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
