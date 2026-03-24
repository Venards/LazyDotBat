@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

set ps=%TEMP%\open_ports.ps1

(
    echo $sep = '=' * 50
    echo Write-Host ''
    echo Write-Host $sep
    echo Write-Host '  OPEN PORTS'
    echo Write-Host $sep
    echo.
    echo $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue ^| Sort-Object LocalPort
    echo.
    echo Write-Host ''
    echo Write-Host '[ TCP LISTENING ]'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'ADDRESS', 'PID', 'PROCESS'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f '----', '-------', '---', '-------'
    echo foreach ^($c in $connections^) {
    echo     $proc = try { ^(Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue^).ProcessName } catch { '???' }
    echo     $addr = if ^($c.LocalAddress -eq '::'^) { '0.0.0.0 (all^)' } elseif ^($c.LocalAddress -eq '0.0.0.0'^) { '0.0.0.0 (all^)' } else { $c.LocalAddress }
    echo     Write-Host ^('  {0,-8} {1,-25} {2,-8} {3}' -f $c.LocalPort, $addr, $c.OwningProcess, $proc^)
    echo }
    echo.
    echo $udp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue ^| Sort-Object LocalPort
    echo Write-Host ''
    echo Write-Host '[ UDP ENDPOINTS ]'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'ADDRESS', 'PID', 'PROCESS'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f '----', '-------', '---', '-------'
    echo foreach ^($u in $udp^) {
    echo     $proc = try { ^(Get-Process -Id $u.OwningProcess -ErrorAction SilentlyContinue^).ProcessName } catch { '???' }
    echo     $addr = if ^($u.LocalAddress -eq '::'^) { '0.0.0.0 (all^)' } elseif ^($u.LocalAddress -eq '0.0.0.0'^) { '0.0.0.0 (all^)' } else { $u.LocalAddress }
    echo     Write-Host ^('  {0,-8} {1,-25} {2,-8} {3}' -f $u.LocalPort, $addr, $u.OwningProcess, $proc^)
    echo }
    echo.
    echo $established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue ^| Sort-Object RemotePort
    echo Write-Host ''
    echo Write-Host '[ ESTABLISHED CONNECTIONS ]'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f 'PORT', 'REMOTE ADDRESS', 'PID', 'PROCESS'
    echo Write-Host '  {0,-8} {1,-25} {2,-8} {3}' -f '----', '--------------', '---', '-------'
    echo foreach ^($e in $established^) {
    echo     $proc = try { ^(Get-Process -Id $e.OwningProcess -ErrorAction SilentlyContinue^).ProcessName } catch { '???' }
    echo     $remote = "$($e.RemoteAddress):$($e.RemotePort)"
    echo     Write-Host ^('  {0,-8} {1,-25} {2,-8} {3}' -f $e.LocalPort, $remote, $e.OwningProcess, $proc^)
    echo }
    echo.
    echo Write-Host ''
    echo Write-Host '[ SUMMARY ]'
    echo $listenCount = $connections.Count
    echo $estCount = $established.Count
    echo $udpCount = $udp.Count
    echo Write-Host "  TCP Listening   : $listenCount"
    echo Write-Host "  TCP Established : $estCount"
    echo Write-Host "  UDP Endpoints   : $udpCount"
    echo.
    echo # Flag commonly abused ports
    echo $risky = @(4444, 5555, 1337, 31337, 6666, 6667, 8888, 9999, 4443, 2222^)
    echo $flagged = $connections ^| Where-Object { $_.LocalPort -in $risky }
    echo if ^($flagged^) {
    echo     Write-Host ''
    echo     Write-Host '  [!] WARNING: Suspicious ports detected:'
    echo     foreach ^($f in $flagged^) {
    echo         $proc = try { ^(Get-Process -Id $f.OwningProcess -ErrorAction SilentlyContinue^).ProcessName } catch { '???' }
    echo         Write-Host "      Port $($f.LocalPort) - PID $($f.OwningProcess) ($proc)"
    echo     }
    echo }
    echo.
    echo Write-Host ''
    echo Write-Host $sep
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

pause
