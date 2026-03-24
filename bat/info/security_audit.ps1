$sep = '=' * 50
$warn = 0
Write-Host ''
Write-Host $sep
Write-Host '  SECURITY AUDIT'
Write-Host $sep

# -- Firewall --
Write-Host ''
Write-Host '[ FIREWALL ]'
$profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
foreach ($p in $profiles) {
    $status = if ($p.Enabled) { 'ON' } else { 'OFF' }
    Write-Host "  $($p.Name): $status"
    if (-not $p.Enabled) { $warn++ }
}

# -- Antivirus --
Write-Host ''
Write-Host '[ ANTIVIRUS ]'
$av = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
if ($av) {
    foreach ($a in $av) {
        $hex = '{0:X6}' -f $a.productState
        $state = switch ([int]('0x' + $hex.Substring(2,2))) {
            0  { 'OFF'; $script:warn++ }
            1  { 'ON' }
            default { 'UNKNOWN' }
        }
        Write-Host "  $($a.displayName): $state"
    }
} else {
    Write-Host '  No antivirus detected'
    $warn++
}

# -- Windows Defender --
Write-Host ''
Write-Host '[ WINDOWS DEFENDER ]'
try {
    $def = Get-MpComputerStatus -ErrorAction Stop
    $rt = if ($def.RealTimeProtectionEnabled) { 'ON' } else { 'OFF'; $script:warn++ }
    Write-Host "  Real-Time Protection : $rt"
    $tamper = if ($def.IsTamperProtected) { 'ON' } else { 'OFF'; $script:warn++ }
    Write-Host "  Tamper Protection    : $tamper"
    $lastScan = $def.QuickScanEndTime.ToString('yyyy-MM-dd HH:mm')
    Write-Host "  Last Quick Scan      : $lastScan"
    $sigAge = $def.AntivirusSignatureAge
    Write-Host "  Signature Age        : $sigAge days"
    if ($sigAge -gt 7) { Write-Host '  [!] Signatures are stale'; $warn++ }
} catch {
    Write-Host '  Defender not available'
}

# -- UAC --
Write-Host ''
Write-Host '[ UAC ]'
$uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue
$level = switch ($uac.ConsentPromptBehaviorAdmin) {
    0 { 'Disabled (no prompt)'; $script:warn++ }
    1 { 'High (secure desktop)' }
    2 { 'High (secure desktop)' }
    5 { 'Default' }
    default { 'Unknown' }
}
$enabled = if ($uac.EnableLUA -eq 1) { 'ON' } else { 'OFF'; $script:warn++ }
Write-Host "  UAC Enabled  : $enabled"
Write-Host "  Prompt Level : $level"

# -- RDP --
Write-Host ''
Write-Host '[ REMOTE DESKTOP ]'
$rdp = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -ErrorAction SilentlyContinue).fDenyTSConnections
if ($rdp -eq 0) {
    Write-Host '  RDP: ENABLED'
    Write-Host '  [!] Remote Desktop is open'
    $warn++
    $nla = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction SilentlyContinue).UserAuthentication
    if ($nla -eq 1) { Write-Host '  NLA: Required (good)' } else { Write-Host '  NLA: Not required [!]'; $warn++ }
} else {
    Write-Host '  RDP: Disabled'
}

# -- Guest Account --
Write-Host ''
Write-Host '[ LOCAL ACCOUNTS ]'
$guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
if ($guest -and $guest.Enabled) {
    Write-Host '  Guest Account: ENABLED [!]'
    $warn++
} else {
    Write-Host '  Guest Account: Disabled'
}
$admins = Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue
Write-Host '  Administrators:'
foreach ($a in $admins) { Write-Host "    - $($a.Name)" }

# -- AutoLogin --
Write-Host ''
Write-Host '[ AUTOLOGIN ]'
$autoLogin = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue
if ($autoLogin.AutoAdminLogon -eq '1') {
    Write-Host '  Auto Login: ENABLED [!]'
    $warn++
    if ($autoLogin.DefaultPassword) { Write-Host '  [!] Password stored in plaintext in registry'; $warn++ }
} else {
    Write-Host '  Auto Login: Disabled'
}

# -- SMB --
Write-Host ''
Write-Host '[ SMB ]'
$smb1 = (Get-SmbServerConfiguration -ErrorAction SilentlyContinue).EnableSMB1Protocol
if ($smb1) { Write-Host '  SMBv1: ENABLED [!] (vulnerable to EternalBlue)'; $warn++ } else { Write-Host '  SMBv1: Disabled' }
$shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*$' }
if ($shares) {
    Write-Host '  Non-default shares:'
    foreach ($s in $shares) { Write-Host "    - $($s.Name) -> $($s.Path)" }
} else {
    Write-Host '  No non-default shares'
}

# -- BitLocker --
Write-Host ''
Write-Host '[ BITLOCKER ]'
$bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
if ($bl) {
    foreach ($v in $bl) {
        $status = $v.ProtectionStatus
        Write-Host "  $($v.MountPoint) - Protection: $status"
        if ($status -eq 'Off') { $warn++ }
    }
} else {
    Write-Host '  BitLocker not available'
}

# -- Exposed Ports --
Write-Host ''
Write-Host '[ EXPOSED PORTS (quick view) ]'
$listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' } | Sort-Object LocalPort -Unique
if ($listening) {
    foreach ($l in $listening) {
        $proc = try { (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
        Write-Host "  Port $($l.LocalPort) - $proc"
    }
} else {
    Write-Host '  No ports exposed on all interfaces'
}

# -- Windows Update --
Write-Host ''
Write-Host '[ WINDOWS UPDATE ]'
$hotfix = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($hotfix) {
    $lastPatch = $hotfix.InstalledOn.ToString('yyyy-MM-dd')
    $daysSince = ([datetime]::Now - $hotfix.InstalledOn).Days
    Write-Host "  Last Patch  : $lastPatch ($daysSince days ago)"
    if ($daysSince -gt 30) { Write-Host '  [!] System may be missing patches'; $warn++ }
} else {
    Write-Host '  Could not retrieve update history'
}

# -- Summary --
Write-Host ''
Write-Host $sep
if ($warn -eq 0) {
    Write-Host '  [+] No issues found.'
} else {
    Write-Host "  [!] $warn issue(s) found. Review items marked with [!] above."
}
Write-Host $sep
Write-Host ''
