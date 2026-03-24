function Write-Good  ($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Bad   ($msg) { Write-Host $msg -ForegroundColor Red }
function Write-Warn  ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Label ($msg) { Write-Host $msg -ForegroundColor Cyan }

$sep = '=' * 50
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime

Write-Host ''
Write-Host $sep
Write-Label '  SYSTEM INFO'
Write-Host $sep

Write-Host ''
Write-Label '[ OS ]'
$val = $os.Caption; Write-Host "  Name        : $val"
$val = $os.Version; Write-Host "  Version     : $val"
$val = $os.BuildNumber; Write-Host "  Build       : $val"
$val = $os.OSArchitecture; Write-Host "  Architecture: $val"
$d = [math]::Floor($uptime.TotalDays); $h = $uptime.Hours; $m = $uptime.Minutes; Write-Host "  Uptime      : $d d $h h $m m"
$val = $os.InstallDate.ToString('yyyy-MM-dd'); Write-Host "  Install Date: $val"

$mb = Get-CimInstance Win32_BaseBoard
Write-Host ''
Write-Label '[ MOTHERBOARD ]'
$val = $mb.Manufacturer; Write-Host "  Manufacturer: $val"
$val = $mb.Product; Write-Host "  Model       : $val"
$val = $mb.SerialNumber; Write-Host "  Serial      : $val"

$cpu = Get-CimInstance Win32_Processor
$cpuLoad = $cpu.LoadPercentage
Write-Host ''
Write-Label '[ CPU ]'
$val = $cpu.Name.Trim(); Write-Host "  Name        : $val"
$c = $cpu.NumberOfCores; $t = $cpu.NumberOfLogicalProcessors; Write-Host "  Cores       : $c cores / $t threads"
$val = [math]::Round($cpu.MaxClockSpeed / 1000, 2); Write-Host "  Base Speed  : $val GHz"
if ($cpuLoad -gt 90) {
    Write-Bad "  Usage       : $cpuLoad%"
} elseif ($cpuLoad -gt 70) {
    Write-Warn "  Usage       : $cpuLoad%"
} else {
    Write-Host "  Usage       : $cpuLoad%"
}

$totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeRam  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRam  = [math]::Round($totalRam - $freeRam, 1)
$ramPct   = [math]::Round(($usedRam / $totalRam) * 100, 1)
Write-Host ''
Write-Label '[ RAM ]'
Write-Host "  Total       : $totalRam GB"
if ($ramPct -gt 90) {
    Write-Bad "  Used        : $usedRam GB ($ramPct%)"
} elseif ($ramPct -gt 70) {
    Write-Warn "  Used        : $usedRam GB ($ramPct%)"
} else {
    Write-Host "  Used        : $usedRam GB ($ramPct%)"
}
Write-Host "  Free        : $freeRam GB"
$sticks = Get-CimInstance Win32_PhysicalMemory
foreach ($stick in $sticks) {
    $loc = $stick.DeviceLocator
    $size = [math]::Round($stick.Capacity / 1GB, 0)
    $speed = $stick.Speed
    Write-Host "  Slot        : $loc - $size GB @ $speed MHz"
}

$gpus = Get-CimInstance Win32_VideoController
Write-Host ''
Write-Label '[ GPU ]'
foreach ($gpu in $gpus) {
    $name = $gpu.Name
    $vram = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 1) } else { 'N/A' }
    $resH = $gpu.CurrentHorizontalResolution
    $resV = $gpu.CurrentVerticalResolution
    $hz = $gpu.CurrentRefreshRate
    $drv = $gpu.DriverVersion
    Write-Host "  Name        : $name"
    Write-Host "  VRAM        : $vram GB"
    Write-Host "  Resolution  : $resH x $resV @ $hz Hz"
    Write-Host "  Driver      : $drv"
}

$disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
Write-Host ''
Write-Label '[ STORAGE ]'
foreach ($disk in $disks) {
    $total = [math]::Round($disk.Size / 1GB, 1)
    $free  = [math]::Round($disk.FreeSpace / 1GB, 1)
    $used  = [math]::Round($total - $free, 1)
    $pct   = [math]::Round(($used / $total) * 100, 1)
    $id    = $disk.DeviceID
    if ($pct -gt 90) {
        Write-Bad "  $id  Total: $total GB  Used: $used GB  Free: $free GB  ($pct%)"
    } elseif ($pct -gt 80) {
        Write-Warn "  $id  Total: $total GB  Used: $used GB  Free: $free GB  ($pct%)"
    } else {
        Write-Host "  $id  Total: $total GB  Used: $used GB  Free: $free GB  ($pct%)"
    }
}

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
Write-Host ''
Write-Label '[ NETWORK ]'
foreach ($adapter in $adapters) {
    $ip  = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ', '
    $aname = $adapter.Name
    $mac  = $adapter.MacAddress
    $spd  = $adapter.LinkSpeed
    Write-Host "  Adapter     : $aname"
    Write-Host "  IP          : $ip"
    Write-Host "  MAC         : $mac"
    Write-Host "  DNS         : $dns"
    Write-Host "  Speed       : $spd"
}

$bios = Get-CimInstance Win32_BIOS
Write-Host ''
Write-Label '[ BIOS ]'
$val = $bios.Manufacturer; Write-Host "  Manufacturer: $val"
$val = $bios.SMBIOSBIOSVersion; Write-Host "  Version     : $val"
$val = $bios.ReleaseDate.ToString('yyyy-MM-dd'); Write-Host "  Release Date: $val"
$val = $bios.SerialNumber; Write-Host "  Serial      : $val"

$uuid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
$machineGuid = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid).MachineGuid
$hwid = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
Write-Host ''
Write-Label '[ HWID ]'
Write-Host "  UUID        : $uuid"
Write-Host "  Machine GUID: $machineGuid"
if ($hwid) { Write-Host "  Product Key : $hwid" } else { Write-Host "  Product Key : (not retrievable)" }

Write-Host ''
Write-Host $sep
