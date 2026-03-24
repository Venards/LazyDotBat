$sep = '=' * 50
$connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort

Write-Host ''
Write-Host $sep
Write-Host '  OPEN PORTS'
Write-Host $sep

Write-Host ''
Write-Host '[ TCP LISTENING ]'
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'ADDRESS', 'PID', 'PROCESS')
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f '----', '-------', '---', '-------')
foreach ($c in $connections) {
    $proc = try { (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
    $addr = if ($c.LocalAddress -eq '::' -or $c.LocalAddress -eq '0.0.0.0') { '0.0.0.0 (all)' } else { $c.LocalAddress }
    Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f $c.LocalPort, $addr, $c.OwningProcess, $proc)
}

$udp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Sort-Object LocalPort
Write-Host ''
Write-Host '[ UDP ENDPOINTS ]'
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'ADDRESS', 'PID', 'PROCESS')
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f '----', '-------', '---', '-------')
foreach ($u in $udp) {
    $proc = try { (Get-Process -Id $u.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
    $addr = if ($u.LocalAddress -eq '::' -or $u.LocalAddress -eq '0.0.0.0') { '0.0.0.0 (all)' } else { $u.LocalAddress }
    Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f $u.LocalPort, $addr, $u.OwningProcess, $proc)
}

$established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Sort-Object RemotePort
Write-Host ''
Write-Host '[ ESTABLISHED CONNECTIONS ]'
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'REMOTE ADDRESS', 'PID', 'PROCESS')
Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f '----', '--------------', '---', '-------')
foreach ($e in $established) {
    $proc = try { (Get-Process -Id $e.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
    $remote = "$($e.RemoteAddress):$($e.RemotePort)"
    Write-Host ('  {0,-8} {1,-25} {2,-8} {3}' -f $e.LocalPort, $remote, $e.OwningProcess, $proc)
}

Write-Host ''
Write-Host '[ SUMMARY ]'
$listenCount = @($connections).Count
$estCount = @($established).Count
$udpCount = @($udp).Count
Write-Host "  TCP Listening   : $listenCount"
Write-Host "  TCP Established : $estCount"
Write-Host "  UDP Endpoints   : $udpCount"

# Flag commonly abused ports
$risky = @(4444, 5555, 1337, 31337, 6666, 6667, 8888, 9999, 4443, 2222)
$flagged = $connections | Where-Object { $_.LocalPort -in $risky }
if ($flagged) {
    Write-Host ''
    Write-Host '  [!] WARNING: Suspicious ports detected:'
    foreach ($f in $flagged) {
        $proc = try { (Get-Process -Id $f.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
        Write-Host "      Port $($f.LocalPort) - PID $($f.OwningProcess) ($proc)"
    }
}

Write-Host ''
Write-Host $sep
