function Write-Good  ($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Bad   ($msg) { Write-Host $msg -ForegroundColor Red }
function Write-Warn  ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Label ($msg) { Write-Host $msg -ForegroundColor Cyan }

$sep = '=' * 50

Write-Host ''
Write-Host $sep
Write-Label '  DISK HEALTH'
Write-Host $sep

$disks = Get-PhysicalDisk
foreach ($disk in $disks) {
    $model       = $disk.FriendlyName
    $status      = $disk.HealthStatus
    $opStatus    = $disk.OperationalStatus
    $size        = [math]::Round($disk.Size / 1GB, 1)
    $mediaType   = $disk.MediaType
    $busType     = $disk.BusType
    Write-Host ''
    Write-Label "[ $model ]"
    if ($status -eq 'Healthy') {
        Write-Good "  Health      : $status"
    } else {
        Write-Bad "  Health      : $status"
    }
    if ($opStatus -eq 'OK') {
        Write-Good "  Status      : $opStatus"
    } else {
        Write-Bad "  Status      : $opStatus"
    }
    Write-Host "  Size        : $size GB"
    Write-Host "  Type        : $mediaType ($busType)"
}

Write-Host ''
Write-Label '[ LOGICAL DRIVES ]'
$drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($drive in $drives) {
    $id    = $drive.DeviceID
    $total = [math]::Round($drive.Size / 1GB, 1)
    $free  = [math]::Round($drive.FreeSpace / 1GB, 1)
    $used  = [math]::Round($total - $free, 1)
    $pct   = [math]::Round(($used / $total) * 100, 1)
    $fs    = $drive.FileSystem
    $label = if ($drive.VolumeName) { $drive.VolumeName } else { 'No Label' }
    Write-Host ''
    Write-Host "  Drive       : $id ($label)"
    Write-Host "  File System : $fs"
    Write-Host "  Total       : $total GB"
    if ($pct -gt 90) {
        Write-Bad "  Used        : $used GB ($pct%)"
    } elseif ($pct -gt 80) {
        Write-Warn "  Used        : $used GB ($pct%)"
    } else {
        Write-Host "  Used        : $used GB ($pct%)"
    }
    Write-Host "  Free        : $free GB"
    if ($pct -gt 90) { Write-Bad "  [!] WARNING: Drive is almost full!" }
}

Write-Host ''
Write-Label '[ VOLUME HEALTH ]'
$volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' }
foreach ($vol in $volumes) {
    $letter = if ($vol.DriveLetter) { $vol.DriveLetter } else { '?' }
    $health = $vol.HealthStatus
    $opstat = $vol.OperationalStatus
    if ($health -eq 'Healthy') {
        Write-Good "  $letter - Health: $health  Status: $opstat"
    } else {
        Write-Bad "  $letter - Health: $health  Status: $opstat"
    }
}

Write-Host ''
Write-Host $sep
