@echo off
fsutil dirty query %systemdrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)

set ps=%TEMP%\security_audit.ps1

(
    echo $sep = '=' * 50
    echo $warn = 0
    echo Write-Host ''
    echo Write-Host $sep
    echo Write-Host '  SECURITY AUDIT'
    echo Write-Host $sep
    echo.
    echo # ── Firewall ────────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ FIREWALL ]'
    echo $profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    echo foreach ^($p in $profiles^) {
    echo     $status = if ^($p.Enabled^) { 'ON' } else { 'OFF' }
    echo     Write-Host "  $($p.Name): $status"
    echo     if ^(-not $p.Enabled^) { $warn++ }
    echo }
    echo.
    echo # ── Antivirus ───────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ ANTIVIRUS ]'
    echo $av = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    echo if ^($av^) {
    echo     foreach ^($a in $av^) {
    echo         $state = switch ^([int]('0x' + '{0:X6}' -f $a.productState^).Substring^(2,2^)^) {
    echo             0  { 'OFF'; $script:warn++ }
    echo             1  { 'ON' }
    echo             default { 'UNKNOWN' }
    echo         }
    echo         Write-Host "  $($a.displayName): $state"
    echo     }
    echo } else {
    echo     Write-Host '  No antivirus detected'
    echo     $warn++
    echo }
    echo.
    echo # ── Windows Defender specifics ──────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ WINDOWS DEFENDER ]'
    echo try {
    echo     $def = Get-MpComputerStatus -ErrorAction Stop
    echo     $rt = if ^($def.RealTimeProtectionEnabled^) { 'ON' } else { 'OFF'; $script:warn++ }
    echo     Write-Host "  Real-Time Protection : $rt"
    echo     $tamper = if ^($def.IsTamperProtected^) { 'ON' } else { 'OFF'; $script:warn++ }
    echo     Write-Host "  Tamper Protection    : $tamper"
    echo     $lastScan = $def.QuickScanEndTime.ToString^('yyyy-MM-dd HH:mm'^)
    echo     Write-Host "  Last Quick Scan      : $lastScan"
    echo     $sigAge = $def.AntivirusSignatureAge
    echo     Write-Host "  Signature Age        : $sigAge days"
    echo     if ^($sigAge -gt 7^) { Write-Host '  [!] Signatures are stale'; $warn++ }
    echo } catch {
    echo     Write-Host '  Defender not available'
    echo }
    echo.
    echo # ── UAC ─────────────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ UAC ]'
    echo $uac = ^(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue^)
    echo $level = switch ^($uac.ConsentPromptBehaviorAdmin^) {
    echo     0 { 'Disabled (no prompt^)'; $script:warn++ }
    echo     1 { 'High (secure desktop^)' }
    echo     2 { 'High (secure desktop^)' }
    echo     5 { 'Default' }
    echo     default { 'Unknown' }
    echo }
    echo $enabled = if ^($uac.EnableLUA -eq 1^) { 'ON' } else { 'OFF'; $script:warn++ }
    echo Write-Host "  UAC Enabled  : $enabled"
    echo Write-Host "  Prompt Level : $level"
    echo.
    echo # ── RDP ─────────────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ REMOTE DESKTOP ]'
    echo $rdp = ^(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -ErrorAction SilentlyContinue^).fDenyTSConnections
    echo if ^($rdp -eq 0^) {
    echo     Write-Host '  RDP: ENABLED'
    echo     Write-Host '  [!] Remote Desktop is open'
    echo     $warn++
    echo     $nla = ^(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction SilentlyContinue^).UserAuthentication
    echo     if ^($nla -eq 1^) { Write-Host '  NLA: Required (good^)' } else { Write-Host '  NLA: Not required [!]'; $warn++ }
    echo } else {
    echo     Write-Host '  RDP: Disabled'
    echo }
    echo.
    echo # ── Guest account ───────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ LOCAL ACCOUNTS ]'
    echo $guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
    echo if ^($guest -and $guest.Enabled^) {
    echo     Write-Host '  Guest Account: ENABLED [!]'
    echo     $warn++
    echo } else {
    echo     Write-Host '  Guest Account: Disabled'
    echo }
    echo $admins = Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue
    echo Write-Host '  Administrators:'
    echo foreach ^($a in $admins^) { Write-Host "    - $($a.Name)" }
    echo.
    echo # ── AutoLogin ───────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ AUTOLOGIN ]'
    echo $autoLogin = ^(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue^)
    echo if ^($autoLogin.AutoAdminLogon -eq '1'^) {
    echo     Write-Host '  Auto Login: ENABLED [!]'
    echo     $warn++
    echo     if ^($autoLogin.DefaultPassword^) { Write-Host '  [!] Password stored in plaintext in registry'; $warn++ }
    echo } else {
    echo     Write-Host '  Auto Login: Disabled'
    echo }
    echo.
    echo # ── SMB ─────────────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ SMB ]'
    echo $smb1 = ^(Get-SmbServerConfiguration -ErrorAction SilentlyContinue^).EnableSMB1Protocol
    echo if ^($smb1^) { Write-Host '  SMBv1: ENABLED [!] (vulnerable to EternalBlue^)'; $warn++ } else { Write-Host '  SMBv1: Disabled' }
    echo $shares = Get-SmbShare -ErrorAction SilentlyContinue ^| Where-Object { $_.Name -notlike '*$' }
    echo if ^($shares^) {
    echo     Write-Host '  Non-default shares:'
    echo     foreach ^($s in $shares^) { Write-Host "    - $($s.Name) -> $($s.Path)" }
    echo } else {
    echo     Write-Host '  No non-default shares'
    echo }
    echo.
    echo # ── BitLocker ───────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ BITLOCKER ]'
    echo $bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
    echo if ^($bl^) {
    echo     foreach ^($v in $bl^) {
    echo         $status = $v.ProtectionStatus
    echo         Write-Host "  $($v.MountPoint) - Protection: $status"
    echo         if ^($status -eq 'Off'^) { $warn++ }
    echo     }
    echo } else {
    echo     Write-Host '  BitLocker not available'
    echo }
    echo.
    echo # ── Listening ports (quick view) ────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ EXPOSED PORTS (quick view) ]'
    echo $listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue ^| Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' } ^| Sort-Object LocalPort -Unique
    echo if ^($listening^) {
    echo     foreach ^($l in $listening^) {
    echo         $proc = try { ^(Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue^).ProcessName } catch { '???' }
    echo         Write-Host "  Port $($l.LocalPort) - $proc"
    echo     }
    echo } else {
    echo     Write-Host '  No ports exposed on all interfaces'
    echo }
    echo.
    echo # ── Windows Update ──────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host '[ WINDOWS UPDATE ]'
    echo $hotfix = Get-HotFix -ErrorAction SilentlyContinue ^| Sort-Object InstalledOn -Descending ^| Select-Object -First 1
    echo if ^($hotfix^) {
    echo     $lastPatch = $hotfix.InstalledOn.ToString^('yyyy-MM-dd'^)
    echo     $daysSince = ^([datetime]::Now - $hotfix.InstalledOn^).Days
    echo     Write-Host "  Last Patch  : $lastPatch ($daysSince days ago)"
    echo     if ^($daysSince -gt 30^) { Write-Host '  [!] System may be missing patches'; $warn++ }
    echo } else {
    echo     Write-Host '  Could not retrieve update history'
    echo }
    echo.
    echo # ── Summary ─────────────────────────────────────────────────────────────
    echo Write-Host ''
    echo Write-Host $sep
    echo if ^($warn -eq 0^) {
    echo     Write-Host '  [+] No issues found.'
    echo } else {
    echo     Write-Host "  [!] $warn issue(s) found. Review items marked with [!] above."
    echo }
    echo Write-Host $sep
    echo Write-Host ''
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

pause
