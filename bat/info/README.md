# Info

Read-only scripts that display system information. All scripts require Administrator.

---

### `system_info.bat`
Full system overview in one place.
- OS version, build, architecture, uptime, install date
- Motherboard manufacturer, model, serial
- CPU name, cores, threads, speed, current usage
- RAM total, used, free, and per-slot details
- GPU name, VRAM, resolution, refresh rate, driver version
- Storage drives with usage breakdown
- Active network adapters with IP, MAC, DNS, speed
- BIOS version, date, serial
- HWID: UUID, Machine GUID, Windows product key

---

### `disk_health.bat`
Checks the health and usage of your drives.
- Physical disk health status and type (SSD/HDD)
- Logical drive usage with warning if over 90% full
- Volume health and operational status

---

### `network_info.bat`
Detailed network information and connectivity test.
- All active adapters with IP, gateway, MAC, DNS, speed
- Your current public IP
- Ping test to 8.8.8.8, 1.1.1.1, and google.com

> Requires `network_info.ps1` to be in the same folder.
