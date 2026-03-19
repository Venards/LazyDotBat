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
    echo Write-Host "[*] Flushing standby RAM..."
    echo $code = @"
    echo using System;
    echo using System.Runtime.InteropServices;
    echo public class RamFlush {
    echo     [DllImport^("psapi.dll"^)] public static extern bool EmptyWorkingSet^(IntPtr h^);
    echo     [DllImport^("kernel32.dll"^)] public static extern IntPtr OpenProcess^(int a, bool b, int c^);
    echo }
    echo "@
    echo Add-Type $code
    echo Get-Process ^| ForEach-Object { try { [RamFlush]::EmptyWorkingSet^([RamFlush]::OpenProcess^(0x1F0FFF, $false, $_.Id^)^) ^| Out-Null } catch {} }
    echo [System.GC]::Collect^(^)
    echo [System.GC]::WaitForPendingFinalizers^(^)
    echo [System.GC]::Collect^(^)
    echo $after = [math]::Round^((Get-CimInstance Win32_OperatingSystem^).FreePhysicalMemory / 1MB, 1^)
    echo $freed = [math]::Round^($after - $before, 1^)
    echo Write-Host "[*] Free RAM after:  $after GB"
    echo if ^($freed -gt 0^) { Write-Host "[+] RAM freed: $freed GB" } else { Write-Host "[*] No significant RAM freed (already clean^)" }
) > "%ps%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps%"
del /f /q "%ps%"

echo.
echo === Done ===
pause
