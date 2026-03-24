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

echo %CYAN%=== Network Optimization ===%RESET%
echo.

:: ── 1. Flush DNS ─────────────────────────────────────────────────────────────
echo %CYAN%[*] Flushing DNS cache...%RESET%
ipconfig /flushdns >nul
echo %GREEN%    Done.%RESET%
echo.

:: ── 2. Reset network stack ───────────────────────────────────────────────────
echo %CYAN%[*] Resetting network stack...%RESET%
netsh winsock reset >nul
netsh int ip reset >nul
echo %GREEN%    Done.%RESET%
echo.

:: ── 3. DNS server ────────────────────────────────────────────────────────────
echo %YELLOW%Which DNS would you like to use?%RESET%
echo %YELLOW%  [1] Cloudflare  (1.1.1.1)  - fastest%RESET%
echo %YELLOW%  [2] Google      (8.8.8.8)  - most reliable%RESET%
echo %YELLOW%  [3] Keep current%RESET%
echo.
set /p dns="%YELLOW%Choice (1/2/3): %RESET%"

if "%dns%"=="3" (
    echo %CYAN%    Skipped.%RESET%
    goto done
)

:: Get active network interface name
for /f "tokens=*" %%i in ('powershell -NoProfile -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name"') do set iface=%%i

if "%dns%"=="1" (
    netsh interface ip set dns name="%iface%" static 1.1.1.1 >nul
    netsh interface ip add dns name="%iface%" 1.0.0.1 index=2 >nul
    echo %GREEN%    Set to Cloudflare (1.1.1.1 / 1.0.0.1)%RESET%
) else if "%dns%"=="2" (
    netsh interface ip set dns name="%iface%" static 8.8.8.8 >nul
    netsh interface ip add dns name="%iface%" 8.8.4.4 index=2 >nul
    echo %GREEN%    Set to Google (8.8.8.8 / 8.8.4.4)%RESET%
) else (
    echo %RED%    Invalid choice, skipped.%RESET%
)

:done
echo.
echo %CYAN%=== All done - restart recommended ===%RESET%
pause
