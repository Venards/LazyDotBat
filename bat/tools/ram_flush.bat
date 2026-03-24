@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo     Right-click the file and select "Run as administrator".
    pause
    exit /b
)
echo === RAM Flush ===
echo.

:: ── Write PowerShell script to temp file ─────────────────────────────────────
set ps=%TEMP%\ramflush.ps1
(
    echo $before = [math]::Round^((Get-CimInstance Win32_OperatingSystem^).FreePhysicalMemory / 1MB, 1^)
    echo Write-Host "[*] Free RAM before: $before GB"
    echo Write-Host ""
    echo.
    echo $code = @"
    echo using System;
    echo using System.Runtime.InteropServices;
    echo public class MemoryPurge {
    echo     [DllImport^("ntdll.dll"^)]
    echo     public static extern int NtSetSystemInformation^(int infoClass, ref int info, int length^);
    echo     [DllImport^("kernel32.dll"^)]
    echo     public static extern bool SetProcessWorkingSetSizeEx^(IntPtr proc, IntPtr min, IntPtr max, int flags^);
    echo }
    echo "@
    echo Add-Type $code
    echo.
    echo # Acquire SeProfileSingleProcessPrivilege (required for memory list commands^)
    echo $priv = @"
    echo using System;
    echo using System.Runtime.InteropServices;
    echo public class Privilege {
    echo     [DllImport^("advapi32.dll", SetLastError=true^)]
    echo     public static extern bool OpenProcessToken^(IntPtr h, uint access, out IntPtr token^);
    echo     [DllImport^("advapi32.dll", SetLastError=true^)]
    echo     public static extern bool LookupPrivilegeValue^(string sys, string name, out long luid^);
    echo     [DllImport^("advapi32.dll", SetLastError=true^)]
    echo     public static extern bool AdjustTokenPrivileges^(IntPtr token, bool disableAll, ref TOKEN_PRIVILEGES tp, uint len, IntPtr prev, IntPtr retLen^);
    echo     [StructLayout^(LayoutKind.Sequential^)]
    echo     public struct TOKEN_PRIVILEGES {
    echo         public uint Count;
    echo         public long Luid;
    echo         public uint Attributes;
    echo     }
    echo     public static void Enable^(string privilege^) {
    echo         IntPtr token;
    echo         OpenProcessToken^(System.Diagnostics.Process.GetCurrentProcess^(^).Handle, 0x0028, out token^);
    echo         TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES^(^);
    echo         tp.Count = 1;
    echo         tp.Attributes = 0x00000002;
    echo         LookupPrivilegeValue^(null, privilege, out tp.Luid^);
    echo         AdjustTokenPrivileges^(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero^);
    echo     }
    echo }
    echo "@
    echo Add-Type $priv
    echo [Privilege]::Enable^('SeProfileSingleProcessPrivilege'^)
    echo [Privilege]::Enable^('SeIncreaseQuotaPrivilege'^)
    echo.
    echo # 1. Trim working sets (moves pages to standby list^)
    echo Write-Host "[*] Trimming process working sets..."
    echo [MemoryPurge]::SetProcessWorkingSetSizeEx^([System.Diagnostics.Process]::GetCurrentProcess^(^).Handle, [IntPtr]-1, [IntPtr]-1, 0^) ^| Out-Null
    echo Get-Process ^| ForEach-Object {
    echo     try { [MemoryPurge]::SetProcessWorkingSetSizeEx^($_.Handle, [IntPtr]-1, [IntPtr]-1, 0^) ^| Out-Null } catch {}
    echo }
    echo Write-Host "    Done."
    echo.
    echo # 2. Flush modified page list to disk (so pages become standby^)
    echo Write-Host "[*] Flushing modified page list..."
    echo $cmd = 4
    echo [MemoryPurge]::NtSetSystemInformation^(80, [ref]$cmd, [System.Runtime.InteropServices.Marshal]::SizeOf^($cmd^)^) ^| Out-Null
    echo Write-Host "    Done."
    echo.
    echo # 3. Purge standby list (actually frees the memory^)
    echo Write-Host "[*] Purging standby list..."
    echo $cmd = 4
    echo [MemoryPurge]::NtSetSystemInformation^(80, [ref]$cmd, [System.Runtime.InteropServices.Marshal]::SizeOf^($cmd^)^) ^| Out-Null
    echo Start-Sleep -Milliseconds 500
    echo $cmd = 4
    echo [MemoryPurge]::NtSetSystemInformation^(80, [ref]$cmd, [System.Runtime.InteropServices.Marshal]::SizeOf^($cmd^)^) ^| Out-Null
    echo Write-Host "    Done."
    echo.
    echo $after = [math]::Round^((Get-CimInstance Win32_OperatingSystem^).FreePhysicalMemory / 1MB, 1^)
    echo $freed = [math]::Round^($after - $before, 1^)
    echo Write-Host ""
    echo Write-Host "[*] Free RAM after:  $after GB"
    echo if ^($freed -gt 0^) { Write-Host "[+] RAM freed: $freed GB" } else { Write-Host "[*] No significant RAM freed (already clean^)" }
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

echo.
echo === Done ===
pause
