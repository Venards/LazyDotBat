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

echo %CYAN%=== GPU Reset ===%RESET%
echo.

set ps=%TEMP%\gpu_reset.ps1
(
    echo $esc = [char]27
    echo $cyan = "$esc[36m"; $green = "$esc[32m"; $red = "$esc[31m"; $reset = "$esc[0m"
    echo $devices = Get-PnpDevice ^| Where-Object { $_.Class -eq 'Display' }
    echo Write-Host "${cyan}[*] Detected display adapters:${reset}"
    echo foreach ^($d in $devices^) {
    echo     $name = $d.FriendlyName
    echo     $status = $d.Status
    echo     Write-Host "${cyan}    - $name [$status]${reset}"
    echo }
    echo Write-Host ""
    echo Write-Host "${cyan}[*] Restarting GPU driver...${reset}"
    echo foreach ^($d in $devices^) {
    echo     $name = $d.FriendlyName
    echo     $id = $d.InstanceId
    echo     Write-Host "${cyan}    Resetting: $name${reset}"
    echo     pnputil /restart-device "$id" ^| Out-Null
    echo }
    echo Write-Host ""
    echo Write-Host "${green}[+] Done.${reset}"
) > "%ps%"

echo %YELLOW%[!] Your screen may go black for a few seconds. This is normal.%RESET%
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

echo.
pause
