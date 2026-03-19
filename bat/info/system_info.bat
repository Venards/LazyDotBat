@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

set ps=%TEMP%\sysinfo.ps1

:: Write PowerShell script to temp file
(
echo $sep = '=' * 50
echo $os = Get-CimInstance Win32_OperatingSystem
echo $uptime = (Get-Date^) - $os.LastBootUpTime
echo Write-Host ''
echo Write-Host $sep
echo Write-Host '  SYSTEM INFO'
echo Write-Host $sep
echo.
echo Write-Host ''
echo Write-Host '[ OS ]'
echo $val = $os.Caption; Write-Host "  Name        : $val"
echo $val = $os.Version; Write-Host "  Version     : $val"
echo $val = $os.BuildNumber; Write-Host "  Build       : $val"
echo $val = $os.OSArchitecture; Write-Host "  Architecture: $val"
echo $d = [math]::Floor($uptime.TotalDays^); $h = $uptime.Hours; $m = $uptime.Minutes; Write-Host "  Uptime      : $d d $h h $m m"
echo $val = $os.InstallDate.ToString('yyyy-MM-dd'^); Write-Host "  Install Date: $val"
echo.
echo $mb = Get-CimInstance Win32_BaseBoard
echo Write-Host ''
echo Write-Host '[ MOTHERBOARD ]'
echo $val = $mb.Manufacturer; Write-Host "  Manufacturer: $val"
echo $val = $mb.Product; Write-Host "  Model       : $val"
echo $val = $mb.SerialNumber; Write-Host "  Serial      : $val"
echo.
echo $cpu = Get-CimInstance Win32_Processor
echo $cpuLoad = $cpu.LoadPercentage
echo Write-Host ''
echo Write-Host '[ CPU ]'
echo $val = $cpu.Name.Trim(^); Write-Host "  Name        : $val"
echo $c = $cpu.NumberOfCores; $t = $cpu.NumberOfLogicalProcessors; Write-Host "  Cores       : $c cores / $t threads"
echo $val = [math]::Round($cpu.MaxClockSpeed / 1000, 2^); Write-Host "  Base Speed  : $val GHz"
echo Write-Host "  Usage       : $cpuLoad%%"
echo.
echo $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1^)
echo $freeRam  = [math]::Round($os.FreePhysicalMemory / 1MB, 1^)
echo $usedRam  = [math]::Round($totalRam - $freeRam, 1^)
echo $ramPct   = [math]::Round(($usedRam / $totalRam^) * 100, 1^)
echo Write-Host ''
echo Write-Host '[ RAM ]'
echo Write-Host "  Total       : $totalRam GB"
echo Write-Host "  Used        : $usedRam GB ($ramPct%%)"
echo Write-Host "  Free        : $freeRam GB"
echo $sticks = Get-CimInstance Win32_PhysicalMemory
echo foreach ($stick in $sticks^) {
echo     $loc = $stick.DeviceLocator
echo     $size = [math]::Round($stick.Capacity / 1GB, 0^)
echo     $speed = $stick.Speed
echo     Write-Host "  Slot        : $loc - $size GB @ $speed MHz"
echo }
echo.
echo $gpus = Get-CimInstance Win32_VideoController
echo Write-Host ''
echo Write-Host '[ GPU ]'
echo foreach ($gpu in $gpus^) {
echo     $name = $gpu.Name
echo     $vram = if ($gpu.AdapterRAM^) { [math]::Round($gpu.AdapterRAM / 1GB, 1^) } else { 'N/A' }
echo     $resH = $gpu.CurrentHorizontalResolution
echo     $resV = $gpu.CurrentVerticalResolution
echo     $hz = $gpu.CurrentRefreshRate
echo     $drv = $gpu.DriverVersion
echo     Write-Host "  Name        : $name"
echo     Write-Host "  VRAM        : $vram GB"
echo     Write-Host "  Resolution  : $resH x $resV @ $hz Hz"
echo     Write-Host "  Driver      : $drv"
echo }
echo.
echo $disks = Get-CimInstance Win32_LogicalDisk ^| Where-Object { $_.DriveType -eq 3 }
echo Write-Host ''
echo Write-Host '[ STORAGE ]'
echo foreach ($disk in $disks^) {
echo     $total = [math]::Round($disk.Size / 1GB, 1^)
echo     $free  = [math]::Round($disk.FreeSpace / 1GB, 1^)
echo     $used  = [math]::Round($total - $free, 1^)
echo     $pct   = [math]::Round(($used / $total^) * 100, 1^)
echo     $id    = $disk.DeviceID
echo     Write-Host "  $id  Total: $total GB  Used: $used GB  Free: $free GB  ($pct%%)"
echo }
echo.
echo $adapters = Get-NetAdapter ^| Where-Object { $_.Status -eq 'Up' }
echo Write-Host ''
echo Write-Host '[ NETWORK ]'
echo foreach ($adapter in $adapters^) {
echo     $ip  = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue^).IPAddress
echo     $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue^).ServerAddresses -join ', '
echo     $aname = $adapter.Name
echo     $mac  = $adapter.MacAddress
echo     $spd  = $adapter.LinkSpeed
echo     Write-Host "  Adapter     : $aname"
echo     Write-Host "  IP          : $ip"
echo     Write-Host "  MAC         : $mac"
echo     Write-Host "  DNS         : $dns"
echo     Write-Host "  Speed       : $spd Mbps"
echo }
echo.
echo $bios = Get-CimInstance Win32_BIOS
echo Write-Host ''
echo Write-Host '[ BIOS ]'
echo $val = $bios.Manufacturer; Write-Host "  Manufacturer: $val"
echo $val = $bios.SMBIOSBIOSVersion; Write-Host "  Version     : $val"
echo $val = $bios.ReleaseDate.ToString('yyyy-MM-dd'^); Write-Host "  Release Date: $val"
echo $val = $bios.SerialNumber; Write-Host "  Serial      : $val"
echo.
echo $uuid = (Get-CimInstance Win32_ComputerSystemProduct^).UUID
echo $machineGuid = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid^).MachineGuid
echo $hwid = (Get-CimInstance SoftwareLicensingService^).OA3xOriginalProductKey
echo Write-Host ''
echo Write-Host '[ HWID ]'
echo Write-Host "  UUID        : $uuid"
echo Write-Host "  Machine GUID: $machineGuid"
echo if ($hwid^) { Write-Host "  Product Key : $hwid" } else { Write-Host "  Product Key : (not retrievable^)" }
echo.
echo Write-Host $sep
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

pause
