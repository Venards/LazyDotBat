@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

set ps=%TEMP%\diskhealth.ps1

(
echo $sep = '=' * 50
echo Write-Host ''
echo Write-Host $sep
echo Write-Host '  DISK HEALTH'
echo Write-Host $sep
echo.
echo $disks = Get-PhysicalDisk
echo foreach ($disk in $disks^) {
echo     $model       = $disk.FriendlyName
echo     $status      = $disk.HealthStatus
echo     $opStatus    = $disk.OperationalStatus
echo     $size        = [math]::Round($disk.Size / 1GB, 1^)
echo     $mediaType   = $disk.MediaType
echo     $busType     = $disk.BusType
echo     Write-Host ''
echo     Write-Host "[ $model ]"
echo     Write-Host "  Health      : $status"
echo     Write-Host "  Status      : $opStatus"
echo     Write-Host "  Size        : $size GB"
echo     Write-Host "  Type        : $mediaType ($busType)"
echo }
echo.
echo Write-Host ''
echo Write-Host '[ LOGICAL DRIVES ]'
echo $drives = Get-CimInstance Win32_LogicalDisk ^| Where-Object { $_.DriveType -eq 3 }
echo foreach ($drive in $drives^) {
echo     $id    = $drive.DeviceID
echo     $total = [math]::Round($drive.Size / 1GB, 1^)
echo     $free  = [math]::Round($drive.FreeSpace / 1GB, 1^)
echo     $used  = [math]::Round($total - $free, 1^)
echo     $pct   = [math]::Round(($used / $total^) * 100, 1^)
echo     $fs    = $drive.FileSystem
echo     $label = if ($drive.VolumeName^) { $drive.VolumeName } else { 'No Label' }
echo     Write-Host ''
echo     Write-Host "  Drive       : $id ($label)"
echo     Write-Host "  File System : $fs"
echo     Write-Host "  Total       : $total GB"
echo     Write-Host "  Used        : $used GB ($pct%%)"
echo     Write-Host "  Free        : $free GB"
echo     if ($pct -gt 90^) { Write-Host "  [!] WARNING: Drive is almost full!" }
echo }
echo.
echo Write-Host ''
echo Write-Host '[ VOLUME HEALTH ]'
echo $volumes = Get-Volume ^| Where-Object { $_.DriveType -eq 'Fixed' }
echo foreach ($vol in $volumes^) {
echo     $letter = if ($vol.DriveLetter^) { $vol.DriveLetter } else { '?' }
echo     $health = $vol.HealthStatus
echo     $opstat = $vol.OperationalStatus
echo     Write-Host "  $letter - Health: $health  Status: $opstat"
echo }
echo.
echo Write-Host $sep
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

pause
