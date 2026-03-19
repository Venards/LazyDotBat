@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

echo === GPU Reset ===
echo.

set ps=%TEMP%\gpu_reset.ps1
(
    echo $devices = Get-PnpDevice ^| Where-Object { $_.Class -eq 'Display' }
    echo Write-Host "[*] Detected display adapters:"
    echo foreach ^($d in $devices^) {
    echo     $name = $d.FriendlyName
    echo     $status = $d.Status
    echo     Write-Host "    - $name [$status]"
    echo }
    echo Write-Host ""
    echo Write-Host "[*] Restarting GPU driver..."
    echo foreach ^($d in $devices^) {
    echo     $name = $d.FriendlyName
    echo     $id = $d.InstanceId
    echo     Write-Host "    Resetting: $name"
    echo     pnputil /restart-device "$id" ^| Out-Null
    echo }
    echo Write-Host ""
    echo Write-Host "[+] Done."
) > "%ps%"

echo [!] Your screen may go black for a few seconds. This is normal.
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

echo.
pause
