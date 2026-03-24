$sep = '=' * 50
$warn = 0

function Write-Good  ($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Bad   ($msg) { Write-Host $msg -ForegroundColor Red }
function Write-Warn  ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Label ($msg) { Write-Host $msg -ForegroundColor Cyan }

Write-Host ''
Write-Host $sep
Write-Label '  SECURITY AUDIT'
Write-Host $sep

# -- Firewall --
Write-Host ''
Write-Label '[ FIREWALL ]'
$profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
foreach ($p in $profiles) {
    if ($p.Enabled) {
        Write-Good "  $($p.Name): ON"
    } else {
        Write-Bad "  $($p.Name): OFF [!]"
        $warn++
    }
}

# -- Antivirus --
Write-Host ''
Write-Label '[ ANTIVIRUS ]'
$av = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
if ($av) {
    foreach ($a in $av) {
        $hex = '{0:X6}' -f $a.productState
        $code = [int]('0x' + $hex.Substring(2,2))
        if ($code -eq 1) {
            Write-Good "  $($a.displayName): ON"
        } else {
            Write-Bad "  $($a.displayName): OFF [!]"
            $warn++
        }
    }
} else {
    Write-Bad '  No antivirus detected [!]'
    $warn++
}

# -- Windows Defender --
Write-Host ''
Write-Label '[ WINDOWS DEFENDER ]'
try {
    $def = Get-MpComputerStatus -ErrorAction Stop
    if ($def.RealTimeProtectionEnabled) {
        Write-Good '  Real-Time Protection : ON'
    } else {
        Write-Bad '  Real-Time Protection : OFF [!]'
        $warn++
    }
    if ($def.IsTamperProtected) {
        Write-Good '  Tamper Protection    : ON'
    } else {
        Write-Bad '  Tamper Protection    : OFF [!]'
        $warn++
    }
    $lastScan = $def.QuickScanEndTime.ToString('yyyy-MM-dd HH:mm')
    Write-Host "  Last Quick Scan      : $lastScan"
    $sigAge = $def.AntivirusSignatureAge
    if ($sigAge -gt 7) {
        Write-Bad "  Signature Age        : $sigAge days [!] Stale"
        $warn++
    } else {
        Write-Good "  Signature Age        : $sigAge days"
    }
} catch {
    Write-Warn '  Defender not available'
}

# -- UAC --
Write-Host ''
Write-Label '[ UAC ]'
$uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue
if ($uac.EnableLUA -eq 1) {
    Write-Good '  UAC Enabled  : ON'
} else {
    Write-Bad '  UAC Enabled  : OFF [!]'
    $warn++
}
$level = switch ($uac.ConsentPromptBehaviorAdmin) {
    0 { 'Disabled (no prompt)' }
    1 { 'High (secure desktop)' }
    2 { 'High (secure desktop)' }
    5 { 'Default' }
    default { 'Unknown' }
}
if ($uac.ConsentPromptBehaviorAdmin -eq 0) {
    Write-Bad "  Prompt Level : $level [!]"
    $warn++
} else {
    Write-Host "  Prompt Level : $level"
}

# -- RDP --
Write-Host ''
Write-Label '[ REMOTE DESKTOP ]'
$rdp = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -ErrorAction SilentlyContinue).fDenyTSConnections
if ($rdp -eq 0) {
    Write-Bad '  RDP: ENABLED [!]'
    $warn++
    $nla = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction SilentlyContinue).UserAuthentication
    if ($nla -eq 1) {
        Write-Good '  NLA: Required'
    } else {
        Write-Bad '  NLA: Not required [!]'
        $warn++
    }
} else {
    Write-Good '  RDP: Disabled'
}

# -- Guest Account --
Write-Host ''
Write-Label '[ LOCAL ACCOUNTS ]'
$guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
if ($guest -and $guest.Enabled) {
    Write-Bad '  Guest Account: ENABLED [!]'
    $warn++
} else {
    Write-Good '  Guest Account: Disabled'
}
$admins = Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue
Write-Host '  Administrators:'
foreach ($a in $admins) { Write-Host "    - $($a.Name)" }

# -- AutoLogin --
Write-Host ''
Write-Label '[ AUTOLOGIN ]'
$autoLogin = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue
if ($autoLogin.AutoAdminLogon -eq '1') {
    Write-Bad '  Auto Login: ENABLED [!]'
    $warn++
    if ($autoLogin.DefaultPassword) {
        Write-Bad '  [!] Password stored in plaintext in registry'
        $warn++
    }
} else {
    Write-Good '  Auto Login: Disabled'
}

# -- SMB --
Write-Host ''
Write-Label '[ SMB ]'
$smb1 = (Get-SmbServerConfiguration -ErrorAction SilentlyContinue).EnableSMB1Protocol
if ($smb1) {
    Write-Bad '  SMBv1: ENABLED [!] (vulnerable to EternalBlue)'
    $warn++
} else {
    Write-Good '  SMBv1: Disabled'
}
$shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*$' }
if ($shares) {
    Write-Warn '  Non-default shares:'
    foreach ($s in $shares) { Write-Host "    - $($s.Name) -> $($s.Path)" }
} else {
    Write-Good '  No non-default shares'
}

# -- BitLocker --
Write-Host ''
Write-Label '[ BITLOCKER ]'
$bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
if ($bl) {
    foreach ($v in $bl) {
        if ($v.ProtectionStatus -eq 'On') {
            Write-Good "  $($v.MountPoint) - Protection: On"
        } else {
            Write-Bad "  $($v.MountPoint) - Protection: Off [!]"
            $warn++
        }
    }
} else {
    Write-Warn '  BitLocker not available'
}

# -- Exposed Ports --
Write-Host ''
Write-Label '[ EXPOSED PORTS (quick view) ]'
$listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' } | Sort-Object LocalPort -Unique
if ($listening) {
    foreach ($l in $listening) {
        $proc = try { (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '???' }
        Write-Warn "  Port $($l.LocalPort) - $proc"
    }
} else {
    Write-Good '  No ports exposed on all interfaces'
}

# -- Windows Update --
Write-Host ''
Write-Label '[ WINDOWS UPDATE ]'
$hotfix = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($hotfix) {
    $lastPatch = $hotfix.InstalledOn.ToString('yyyy-MM-dd')
    $daysSince = ([datetime]::Now - $hotfix.InstalledOn).Days
    if ($daysSince -gt 30) {
        Write-Bad "  Last Patch  : $lastPatch ($daysSince days ago) [!]"
        $warn++
    } else {
        Write-Good "  Last Patch  : $lastPatch ($daysSince days ago)"
    }
} else {
    Write-Warn '  Could not retrieve update history'
}

# -- Summary --
Write-Host ''
Write-Host $sep
if ($warn -eq 0) {
    Write-Good '  [+] No issues found.'
} else {
    Write-Bad "  [!] $warn issue(s) found. Review items marked with [!] above."
}
Write-Host $sep
Write-Host ''
