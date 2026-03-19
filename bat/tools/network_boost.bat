@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)
echo === Network Optimization ===
echo.

:: ── 1. Flush DNS ─────────────────────────────────────────────────────────────
echo [*] Flushing DNS cache...
ipconfig /flushdns >nul
echo     Done.
echo.

:: ── 2. Reset network stack ───────────────────────────────────────────────────
echo [*] Resetting network stack...
netsh winsock reset >nul
netsh int ip reset >nul
echo     Done.
echo.

:: ── 3. DNS server ────────────────────────────────────────────────────────────
echo Which DNS would you like to use?
echo   [1] Cloudflare  (1.1.1.1)  - fastest
echo   [2] Google      (8.8.8.8)  - most reliable
echo   [3] Keep current
echo.
set /p dns="Choice (1/2/3): "

if "%dns%"=="3" (
    echo     Skipped.
    goto done
)

:: Get active network interface name
for /f "tokens=*" %%i in ('powershell -NoProfile -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name"') do set iface=%%i

if "%dns%"=="1" (
    netsh interface ip set dns name="%iface%" static 1.1.1.1 >nul
    netsh interface ip add dns name="%iface%" 1.0.0.1 index=2 >nul
    echo     Set to Cloudflare (1.1.1.1 / 1.0.0.1)
) else if "%dns%"=="2" (
    netsh interface ip set dns name="%iface%" static 8.8.8.8 >nul
    netsh interface ip add dns name="%iface%" 8.8.4.4 index=2 >nul
    echo     Set to Google (8.8.8.8 / 8.8.4.4)
) else (
    echo     Invalid choice, skipped.
)

:done
echo.
echo === All done - restart recommended ===
pause
