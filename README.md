# LazyDotBat

A collection of Windows batch scripts for system maintenance, optimization, and information gathering. Run them instead of digging through Windows settings.

> All scripts require **Run as Administrator**.

## Scripts

### `bat/tools/`
| Script | What it does |
|---|---|
| `disk_cleaner.bat` | Remove junk files, cache, and temp folders |
| `ram_flush.bat` | Free up RAM held by Windows |
| `network_boost.bat` | Flush DNS, reset network stack, switch DNS provider |
| `boost_for_gaming.bat` | Optimize PC for gaming (with restore option) |
| `disable_windows_junk.bat` | Disable Windows bloatware and telemetry (with restore option) |
| `gpu_reset.bat` | Restart GPU driver to fix display issues |
| `restart_audio.bat` | Restart audio service to fix sound issues |

### `bat/info/`
| Script | What it does |
|---|---|
| `system_info.bat` | Full system overview: OS, CPU, RAM, GPU, storage, BIOS, HWID |
| `disk_health.bat` | Disk health, drive usage, volume status |
| `network_info.bat` | Active adapters, public IP, ping test |
| `open_ports.bat` | TCP/UDP listening ports with owning processes, flags suspicious ports |
| `security_audit.bat` | Firewall, antivirus, UAC, RDP, SMBv1, BitLocker, and more |

## Usage

1. Download or clone the repo
2. Right-click any `.bat` file
3. Select **Run as administrator**

## Requirements

- Windows 10 / 11
- Administrator privileges
- PowerShell 5.1+ (included with Windows)
