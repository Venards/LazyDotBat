function Write-Good  ($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Bad   ($msg) { Write-Host $msg -ForegroundColor Red }
function Write-Warn  ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Label ($msg) { Write-Host $msg -ForegroundColor Cyan }

$sep = '=' * 50
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

Write-Host ''
Write-Host $sep
Write-Label '  NETWORK INFO'
Write-Host $sep

foreach ($adapter in $adapters) {
    $ip      = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    $gateway = (Get-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop
    $dns     = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ', '
    $mac     = $adapter.MacAddress
    $name    = $adapter.Name
    $desc    = $adapter.InterfaceDescription
    $speed   = $adapter.LinkSpeed
    Write-Host ''
    Write-Label "[ $name ]"
    Write-Host "  Description : $desc"
    Write-Host "  IP          : $ip"
    Write-Host "  Gateway     : $gateway"
    Write-Host "  MAC         : $mac"
    Write-Host "  DNS         : $dns"
    Write-Host "  Speed       : $speed"
}

Write-Host ''
Write-Label '[ PUBLIC IP ]'
try {
    $pub = Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5
    Write-Good "  Public IP   : $pub"
} catch {
    Write-Bad '  Public IP   : (could not reach internet)'
}

Write-Host ''
Write-Label '[ PING TEST ]'
$targets = @('8.8.8.8', '1.1.1.1', 'google.com')
foreach ($t in $targets) {
    $result = ping $t -n 2 | Select-String 'Average'
    if ($result) {
        $ms = ($result -split 'Average = ')[1].Trim().TrimEnd('ms')
        Write-Good "  $t - $ms ms"
    } else {
        Write-Bad "  $t - unreachable"
    }
}

Write-Host ''
Write-Host $sep
