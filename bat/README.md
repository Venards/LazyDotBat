# Windows Batch Scripts

A collection of Windows batch scripts for system maintenance, optimization, and information gathering.

> **Note:** All scripts require running as Administrator. Right-click -> Run as administrator.

## Structure

```
tools/    Action scripts (clean, optimize, fix)
info/     Read-only system information scripts
ps1/      PowerShell scripts used by info/
```

## Folders

### `tools/`
Action scripts for cleaning, optimizing, and fixing your system.

| Script | Description |
|---|---|
| `disk_cleaner.bat` | Remove junk files, browser cache, temp folders, and more |
| `ram_flush.bat` | Purge standby memory list to actually free RAM |
| `network_boost.bat` | Flush DNS, reset network stack, and switch DNS provider |
| `boost_for_gaming.bat` | Optimize your PC for gaming, with a restore option |
| `disable_windows_junk.bat` | Temporarily disable Windows bloatware and telemetry |
| `gpu_reset.bat` | Restart your GPU driver to fix display issues |
| `restart_audio.bat` | Restart the Windows audio service to fix sound issues |

### `info/`
Read-only scripts that display system information.

| Script | Description |
|---|---|
| `system_info.bat` | Full system overview: OS, CPU, RAM, GPU, storage, BIOS, HWID |
| `disk_health.bat` | Physical disk health, drive usage, and volume status |
| `network_info.bat` | Active adapters, public IP, and ping test |
| `open_ports.bat` | TCP/UDP listening ports with owning processes, flags suspicious ports |
| `security_audit.bat` | Firewall, antivirus, UAC, RDP, SMBv1, BitLocker, and more |
